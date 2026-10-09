# 014 — The CRIU experiment: checkpoint a live crab

**Thesis:** #10 clone-as-data-full-state ("The CRIU experiment")

**The work:** Actually try it: checkpoint one of the Oracle crabs mid-loop with CRIU (or the closest available mechanism), restore it elsewhere, and inventory what survives. The thesis claims a clone is full state — this is where the claim meets the machine. Sockets? Timers? File offsets? The honest list of what breaks teaches more than the theory.

**Done looks like:** A report: what was checkpointed, where it was restored, what worked, and the complete list of what broke with a one-line cause for each. If CRIU isn't available on the Oracle box, say so and use the nearest alternative (process snapshot, container checkpoint) — but document the substitution. The deliverable is the breakage inventory, not a success story.

**Size:** 2 hours.
