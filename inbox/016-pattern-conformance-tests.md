# 016 — Pattern conformance: LAN instance vs cloud instance

**Thesis:** #16 agent-as-pattern-not-server ("Conformance tests")

**The work:** If "the pattern" is a real spec, write the test suite. Spin up an instance of the agent pattern on a LAN-only machine (no WAN), run it through a fixed sequence (claim a task, do it, report, sync), and diff its behavior against the cloud instance doing the same sequence. What counts as passing? Define it before running: which differences are acceptable (latency, timestamps) and which are failures (divergent ledger entries, lost tasks).

**Done looks like:** A conformance script plus a `CONFORMANCE.md` defining pass/fail, and one real run with the diff. The interesting output is the failure list — every behavioral difference between LAN and WAN is either a bug or a documented property of the pattern. This is the test that proves the agent is the pattern, not the server.

**Size:** 2 hours.
