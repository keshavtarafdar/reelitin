# Architecture context

The canonical current architecture is documented in the **Architecture direction** sections of [`../ROADMAP.md`](../ROADMAP.md). In summary, the shipping game remains Godot 4.5/GDScript, native iOS responsibilities remain in Swift, and the Firebase replacement is an ASP.NET Core API with MySQL behind it.

Use this folder for durable system-boundary, data-flow, integration, and build/export documentation that multiple phases need. Link to the source ADR or roadmap section instead of copying a second conflicting version of a decision.

Before adding detail, check the existing repository instructions and the applicable ADRs. Mark proposed architecture as proposed until the user accepts it.
