/*
	REGEX System Ported from Aurorastation, includes chat-markup like bolding and italicizing, as well as converting urls into actual clickable url elements.area
*/

// Global REGEX datums for regular use without recompiling

// The lazy URL finder. Lazy in that it matches the bare minimum
// Replicates BYOND's own URL parser in functionality.
var/global/regex/url_find_lazy

GLOBAL_DATUM_INIT(is_color, /regex, regex("^#\[0-9a-fA-F]{6}$"))
