# Oldbridge interface direction

The interface should feel like a contemporary settlement builder: clear, tactile and welcoming, with enough character to belong to Oldbridge.

## References and decisions

- [Foundation's interface update](https://www.polymorph.games/foundation/news/2021/06/) separates its action bar, settlement information, building panels and tracked quests. Borrow the clear grouping and readable panels, while keeping our existing keyboard controls.
- [Against the Storm's UI retrospective](https://eremitegames.com/rationing-update/) describes combining cleaner information structure with warmth after an overly minimal redesign lost character. Borrow that balance rather than copying its ornaments or frames.
- [Against the Storm screenshot reference](https://interfaceingame.com/games/against-the-storm/) provides visual examples of its menu hierarchy. Reference only; no artwork was copied.

The chosen palette is charcoal and slate, warm ivory text, copper for a main action or selection, and sage for supportive status. Panels have crisp four-pixel corners and modest depth. The bridge-and-sapling mark ties the interface to reconstruction.

## Shared components

UIStyle owns color tokens, the Manrope font, heading weights, panels, primary actions, tabs, status badges and cached item surfaces. Typography uses weight 500 for body text and 700 for headings. The font is bundled locally; no network connection is needed.

Use primary actions selectively (for example, Craft 1 or loading ingredients). Tabs and quantity selectors have a distinct selected state. Do not communicate selection or availability by color alone: retain borders, text, counters and disabled states.

The HUD has inset panels, a compact identity area, readable keyboard badges and a quieter supporting text hierarchy. Machine inspection has a dedicated building icon and title. The inventory empty selection provides three short guides instead of a long explanatory paragraph.

Existing interaction tint/fade feedback and menu sounds remain in place. Reduced motion continues to cancel presentation tweens; no layout movement was added.

## Layout and performance

Always reserve vertical scrollbar width for wrapped text inside the workspace and crafting panels. Keep the camp-inspector layout regression passing. Never animate control size or change minimum size on hover.

Shared font variations and four item surface variants are cached. The emblem is a tiny vector drawing. The new theme requires no blur pass, shaders or large textures, and changes no simulation or save data.

## Visual review and verification

Run:

    godot --path . --script res://tests/capture_ui.gd -- --prefix=ui_review
    godot --path . --script res://tests/verify_workspace_layout.gd
    godot --headless --path . --script res://verify_factory.gd

Captures go to .godot/verification/ui_review_*.png and cover the HUD, crafting, live queue, completed output, inventory, machine inspection, technology, restoration and equipment. The native layout check covers repeated Crafting -> inspector transitions at the minimum window size and fullscreen.

Manrope attribution and the complete SIL Open Font License are included with Windows packages; see FONT-CREDITS.txt and assets/fonts/OFL-Manrope.txt.

See [the illustrated workbench and reward contracts](workbench-presentation.md) for the next presentation pass and its model-event boundaries.

See [project navigation](project-navigation.md) for the prerequisite tree, restoration overview cards and quieter HUD.

See [machine inspection](machine-inspection.md) for production diagrams and actionable blocker guidance.

See [recent updates](notification-history.md) for bounded reward/unlock history, unread counts and menu shortcuts.

See [HUD hierarchy and milestone art](hud-art-motion.md) for dedicated civic portraits, field objectives and bounded milestone accents.
