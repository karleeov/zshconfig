#!/usr/bin/env python3
"""Validate or filter hosts against a declared authorized-testing scope.

This enforces a text-file boundary; it does not establish authorization.
"""

from __future__ import annotations

import argparse
import ipaddress
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import urlsplit

_LABEL = re.compile(r"^[a-z0-9_](?:[a-z0-9_-]{0,61}[a-z0-9_])?$")


class ScopeError(ValueError):
    pass


@dataclass(frozen=True)
class Rule:
    excluded: bool
    domain: str | None = None
    wildcard: bool = False
    network: ipaddress.IPv4Network | ipaddress.IPv6Network | None = None

    def matches(self, host: str, address: ipaddress.IPv4Address | ipaddress.IPv6Address | None) -> bool:
        if self.network is not None:
            return address is not None and address.version == self.network.version and address in self.network
        if address is not None or self.domain is None:
            return False
        if self.wildcard:
            return host.endswith("." + self.domain) and len(host) > len(self.domain) + 1
        return host == self.domain


def normalize_domain(value: str, line_no: int | None = None) -> str:
    where = f" on line {line_no}" if line_no is not None else ""
    value = value.strip().rstrip(".").lower()
    if not value or len(value) > 253 or any(c in value for c in "/:@[]"):
        raise ScopeError(f"invalid domain{where}: {value!r}")
    try:
        value = value.encode("idna").decode("ascii")
    except UnicodeError as exc:
        raise ScopeError(f"invalid internationalized domain{where}: {value!r}") from exc
    labels = value.split(".")
    if any(not _LABEL.fullmatch(label) for label in labels):
        raise ScopeError(f"invalid domain{where}: {value!r}")
    return value


def parse_target(raw: str) -> tuple[str, ipaddress.IPv4Address | ipaddress.IPv6Address | None]:
    value = raw.strip()
    if not value or any(ord(c) < 32 for c in value) or any(c.isspace() for c in value):
        raise ScopeError(f"invalid target: {raw!r}")
    if "@" in value:
        raise ScopeError("userinfo is not accepted in targets")
    if "://" not in value:
        try:
            address = ipaddress.ip_address(value)
            return str(address), address
        except ValueError:
            pass
    try:
        parsed = urlsplit(value if "://" in value else "//" + value)
        raw_host = parsed.hostname
    except ValueError as exc:
        raise ScopeError(f"invalid target: {raw!r}") from exc
    if not raw_host:
        raise ScopeError(f"target has no host: {raw!r}")
    host = raw_host.rstrip(".").lower()
    try:
        return host, ipaddress.ip_address(host)
    except ValueError:
        return normalize_domain(host), None


def parse_rule(raw: str, line_no: int) -> Rule:
    value = raw.strip()
    excluded = value.startswith("!")
    if excluded:
        value = value[1:].strip()
    if not value:
        raise ScopeError(f"empty scope rule on line {line_no}")
    if "://" in value or "@" in value:
        raise ScopeError(f"scope rules must be hosts, IPs, or CIDRs on line {line_no}: {raw!r}")
    if "/" in value:
        try:
            return Rule(excluded=excluded, network=ipaddress.ip_network(value, strict=True))
        except ValueError as exc:
            raise ScopeError(f"invalid CIDR on line {line_no}: {value!r}") from exc
    try:
        address = ipaddress.ip_address(value)
        return Rule(excluded=excluded, network=ipaddress.ip_network(f"{address}/{address.max_prefixlen}"))
    except ValueError:
        pass
    wildcard = value.startswith("*.")
    domain = normalize_domain(value[2:] if wildcard else value, line_no)
    return Rule(excluded=excluded, domain=domain, wildcard=wildcard)


def load_scope(path: Path) -> list[Rule]:
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as exc:
        raise ScopeError(f"cannot read scope file {path}: {exc}") from exc
    rules: list[Rule] = []
    for line_no, raw in enumerate(text.splitlines(), 1):
        line = raw.split("#", 1)[0].strip()
        if line:
            rules.append(parse_rule(line, line_no))
    if not any(not rule.excluded for rule in rules):
        raise ScopeError("scope must contain at least one allow rule")
    return rules


def allowed(raw: str, rules: list[Rule]) -> bool:
    host, address = parse_target(raw)
    if any(rule.excluded and rule.matches(host, address) for rule in rules):
        return False
    return any(not rule.excluded and rule.matches(host, address) for rule in rules)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target", nargs="?", help="URL, hostname, or IP address")
    parser.add_argument("--scope", required=True, type=Path, help="scope text file")
    parser.add_argument("--filter", action="store_true", help="read candidates from stdin and print only allowed lines")
    args = parser.parse_args()
    if args.filter == bool(args.target):
        parser.error("provide TARGET, or use --filter without TARGET")

    try:
        rules = load_scope(args.scope)
        if not args.filter:
            host, _ = parse_target(args.target)
            if allowed(args.target, rules):
                print(f"ALLOW {host}")
                return 0
            print(f"DENY {host}", file=sys.stderr)
            return 1

        kept = skipped = 0
        for raw in sys.stdin:
            line = raw.rstrip("\r\n")
            if not line.strip():
                continue
            candidate = line.split(None, 1)[0]
            try:
                if allowed(candidate, rules):
                    print(line)
                    kept += 1
                else:
                    skipped += 1
            except ScopeError:
                skipped += 1
        print(f"scope filter: kept {kept}, skipped {skipped}", file=sys.stderr)
        return 0
    except ScopeError as exc:
        print(f"scope error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
