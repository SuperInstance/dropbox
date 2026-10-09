# 012 — The gate dashboard: assumptions, not numbers

**Thesis:** #2 decompose-assumptions-not-predictions ("The dashboard")

**The work:** Build the zero agent's dashboard — and the rule is absolute: it shows gate status, never raw numbers. Pick a real subsystem (Oracle crabs, fleet tunnels, dropbox inbox depth — your choice) and decompose its big vague assumption into 2–3 gates with trip thresholds. Render green/yellow/red per gate. The question the dashboard answers is "are your assumptions holding," not "what's happening."

**Done looks like:** A script that probes the chosen subsystem, evaluates the gates, and renders the board (markdown is fine). Run it against the live system, confirm the colors are true, and trip one gate deliberately to watch it go red. Commit the script and a short note on where the gate boundaries came from (manual, scar, guess — the pedigree matters less than the recalibration procedure).

**Size:** 1–2 hours.
