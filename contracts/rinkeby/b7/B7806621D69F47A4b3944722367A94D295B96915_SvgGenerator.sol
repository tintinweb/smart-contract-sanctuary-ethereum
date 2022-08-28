// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../structs/TokenInfo.sol";
import "./Base64.sol";

library SvgGenerator {
    enum SpecialVariants {
        Usual,
        Zelenskyy,
        GhostBalaclava
    }

    string private constant UNIFORM_PIXEL_SVG = '<path stroke="#020202" d="M6 21h2m-2 1h1m-4 1h4m9 0h4M1 24h2m17 0h2M0 25h1m21 0h2m0 1h2m0 1h1M2 28h1m17 0h1m6 0h1M2 29h1m17 0h1m6 0h1M2 30h1m17 0h1m6 0h1M2 31h1m17 0h1m6 0h1"/><path stroke="#7b7862" d="M8 21h1m-1 1h1m5 0h1m-7 1h7m-7 2h1m8 0h1M7 26h2m8 0h4M4 27h4m10 0h2M7 28h1m10 0h1"/><path stroke="#aaaa94" d="M7 22h1m7 0h1m-9 1h1m7 0h1M4 24h2m1 0h3m4 0h2m3 0h1M1 25h1m3 0h1m1 0h1m1 0h2m2 0h2m4 0h2M0 26h2m8 0h1m12 0h1M1 27h2m5 0h5m10 0h1M9 28h3m-2 1h3m1 0h1m10 0h1M6 30h1m4 0h6m8 0h1M0 31h2m5 0h1m3 0h4m6 0h3m1 0h2"/><path stroke="#454539" d="M3 24h1m2 0h1m9 0h3M2 25h3m1 0h1m8 0h2m1 0h1m2 0h1M2 26h5m2 0h1m5 0h2m4 0h2M0 27h1m2 0h1m12 0h2m2 0h3M0 28h2m1 0h4m1 0h1m3 0h6m1 0h1M1 29h1m1 0h2m1 0h4m3 0h1m1 0h5m2 0h1M4 30h1m2 0h4m6 0h3m1 0h2M8 31h3m4 0h5"/><path stroke="#cdcdba" d="M10 24h4m-3 1h2m-2 1h4m-2 1h3m8 0h2m-5 1h6M0 29h1m4 0h1m15 0h1m1 0h2m1 0h1M0 30h2m1 0h1m1 0h1m17 0h2m1 0h1M3 31h4m17 0h1"/>';
    string private constant UNIFORM_PIXEL_WITH_GREEN_SVG = '<path stroke="#020202" d="M6 21h2m-2 1h1m-4 1h4m9 0h4M1 24h2m3 0h1m9 0h1m3 0h2M0 25h1m1 0h1m4 0h1m7 0h1m4 0h1m1 0h2M2 26h1m5 0h1m5 0h1m5 0h1m3 0h2M2 27h1m6 0h5m6 0h1m5 0h1M2 28h1m17 0h1m6 0h1M2 29h1m17 0h1m6 0h1M2 30h1m17 0h1m6 0h1M2 31h1m17 0h1m6 0h1"/><path stroke="#7b7862" d="M8 21h1m-1 1h1m5 0h1m-7 1h7M3 24h3m11 0h3M3 25h4m1 0h1m7 0h4M3 26h5m7 0h5M3 27h6m5 0h6M3 28h17M3 29h1m3 0h1m3 0h1m3 0h1m3 0h1M3 30h1m3 0h1m3 0h1m3 0h1m3 0h1M3 31h1m3 0h1m3 0h1m3 0h1m3 0h1"/><path stroke="#aaaa94" d="M7 22h1m7 0h1m-9 1h1m7 0h1m-9 1h3m4 0h2M1 25h1m7 0h2m2 0h2M0 26h2m8 0h1m12 0h1M1 27h1m21 0h1m1 2h1m-1 1h1M0 31h2m19 0h3m1 0h2"/><path stroke="#cdcdba" d="M10 24h4m-3 1h2m-2 1h3m10 1h2m-5 1h6M0 29h1m20 0h1m1 0h2m1 0h1M0 30h2m21 0h2m1 0h1m-3 1h1"/><path stroke="#454539" d="M21 25h1M9 26h1m11 0h2M0 27h1m20 0h2M0 28h2m-1 1h1m2 0h3m1 0h3m1 0h3m1 0h3m3 0h1M4 30h3m1 0h3m1 0h3m1 0h3m2 0h2M4 31h3m1 0h3m1 0h3m1 0h3"/>';
    string private constant UNIFORM_PIXEL_WITH_BLACK_SVG = '<path stroke="#020202" d="M6 21h2m-2 1h1m-4 1h4m9 0h4M1 24h6m9 0h6M0 25h1m1 0h6m7 0h6m1 0h2M2 26h7m5 0h7m3 0h2M2 27h19m5 0h1M2 28h19m6 0h1M2 29h2m3 0h1m3 0h1m3 0h1m3 0h2m6 0h1M2 30h2m3 0h1m3 0h1m3 0h1m3 0h2m6 0h1M2 31h2m3 0h1m3 0h1m3 0h1m3 0h2m6 0h1"/><path stroke="#7b7862" d="M8 21h1m-1 1h1m5 0h1m-7 1h7"/><path stroke="#aaaa94" d="M7 22h1m7 0h1m-9 1h1m7 0h1m-9 1h3m4 0h2M1 25h1m6 0h3m2 0h2M0 26h2m8 0h1m12 0h1M1 27h1m21 0h1m1 2h1m-1 1h1M0 31h2m19 0h3m1 0h2"/><path stroke="#cdcdba" d="M10 24h4m-3 1h2m-2 1h3m10 1h2m-5 1h6M0 29h1m20 0h1m1 0h2m1 0h1M0 30h2m21 0h2m1 0h1m-3 1h1"/><path stroke="#454539" d="M21 25h1M9 26h1m11 0h2M0 27h1m20 0h2M0 28h2m-1 1h1m20 0h1m-2 1h2"/><path stroke="#4f4f4f" d="M4 29h3m1 0h3m1 0h3m1 0h3M4 30h3m1 0h3m1 0h3m1 0h3M4 31h3m1 0h3m1 0h3m1 0h3"/>';
    string private constant UNIFORM_BLACK_WITH_GREEN_SVG = '<path stroke="#020202" d="M6 21h2m-2 1h2m7 0h1M3 23h5m7 0h5M1 24h2m3 0h11m3 0h2M0 25h3m4 0h9m4 0h4M0 26h3m5 0h7m5 0h6M0 27h3m6 0h5m6 0h7M0 28h3m17 0h8M0 29h3m17 0h8M0 30h3m17 0h8M0 31h3m17 0h8"/><path stroke="#7b7862" d="M8 21h1m-1 1h1m5 0h1m-7 1h7M3 24h3m11 0h3M3 25h4m9 0h4M3 26h5m7 0h5M3 27h6m5 0h6M3 28h17M3 29h1m3 0h1m3 0h1m3 0h1m3 0h1M3 30h1m3 0h1m3 0h1m3 0h1m3 0h1M3 31h1m3 0h1m3 0h1m3 0h1m3 0h1"/><path stroke="#454539" d="M4 29h3m1 0h3m1 0h3m1 0h3M4 30h3m1 0h3m1 0h3m1 0h3M4 31h3m1 0h3m1 0h3m1 0h3"/>';
    string private constant UNIFORM_T_WITH_GREEN_SVG = '<path stroke="#020202" d="M3 23h6m5 0h6M1 24h2m3 0h1m9 0h1m3 0h2M0 25h1m1 0h1m4 0h1m7 0h1m4 0h1m1 0h2M2 26h1m5 0h1m5 0h1m5 0h1m3 0h2M2 27h1m6 0h5m6 0h1m5 0h1M2 28h1m17 0h1m6 0h1M2 29h1m17 0h1m6 0h1M2 30h1m17 0h1m6 0h1M2 31h1m17 0h1m6 0h1"/><path stroke="#d0ac98" d="M9 23h5m-7 1h9m-8 1h7m-6 1h5M0 31h2m19 0h6"/><path stroke="#7b7862" d="M3 24h3m11 0h3M1 25h1m1 0h4m9 0h4m1 0h1M0 26h2m1 0h5m7 0h5m1 0h3M0 27h2m1 0h6m5 0h6m1 0h5M0 28h2m1 0h17m1 0h6M0 29h2m1 0h1m3 0h1m3 0h1m3 0h1m3 0h1m1 0h6M0 30h2m1 0h1m3 0h1m3 0h1m3 0h1m3 0h1m1 0h6M3 31h1m3 0h1m3 0h1m3 0h1m3 0h1"/><path stroke="#454539" d="M4 29h3m1 0h3m1 0h3m1 0h3M4 30h3m1 0h3m1 0h3m1 0h3M4 31h3m1 0h3m1 0h3m1 0h3"/>';
    string private constant UNIFORM_T_WITH_BLACK_SVG = '<path stroke="#020202" d="M3 23h6m5 0h6M1 24h6m9 0h6M0 25h1m1 0h6m7 0h6m1 0h2M2 26h7m5 0h7m3 0h2M2 27h19m5 0h1M2 28h19m6 0h1M2 29h2m3 0h1m3 0h1m3 0h1m3 0h2m6 0h1M2 30h2m3 0h1m3 0h1m3 0h1m3 0h2m6 0h1M2 31h2m3 0h1m3 0h1m3 0h1m3 0h2m6 0h1"/><path stroke="#d0ac98" d="M9 23h5m-7 1h9m-8 1h7m-6 1h5M0 31h2m19 0h6"/><path stroke="#7b7862" d="M1 25h1m19 0h1M0 26h2m19 0h3M0 27h2m19 0h5M0 28h2m19 0h6M0 29h2m19 0h6M0 30h2m19 0h6"/><path stroke="#4f4f4f" d="M4 29h3m1 0h3m1 0h3m1 0h3M4 30h3m1 0h3m1 0h3m1 0h3M4 31h3m1 0h3m1 0h3m1 0h3"/>';
    string private constant UNIFORM_T_SVG = '<path stroke="#020202" d="M3 23h6m5 0h6M1 24h2m3 0h1m9 0h1m3 0h2M0 25h1m6 0h1m7 0h1m6 0h2M8 26h1m5 0h1m9 0h2M9 27h5m12 0h1M2 28h1m17 0h1m6 0h1M2 29h1m17 0h1m6 0h1M2 30h1m17 0h1m6 0h1M2 31h1m17 0h1m6 0h1"/><path stroke="#d0ac98" d="M9 23h5m-7 1h9m-8 1h7m-6 1h5M0 31h2m19 0h6"/><path stroke="#7b7862" d="M3 24h3m11 0h3M1 25h6m9 0h6M0 26h8m7 0h9M0 27h9m5 0h12M0 28h2m1 0h17m1 0h6M0 29h2m1 0h17m1 0h6M0 30h2m1 0h17m1 0h6M3 31h17"/>';

    string private constant NLAW_SVG = '<path stroke="#020202" d="M25 15h2m-3 1h4m-5 1h6m-6 1h7m-6 1h7m-6 1h7m-6 1h6m-5 1h4m-3 1h2"/><path stroke="#454539" d="M23 19h1m-2 1h3m-3 1h4m-6 1h2m1 0h4m-7 1h3m1 0h4m-6 1h2m1 0h2m-3 1h1"/><path stroke="#f8d347" d="M21 21h1m0 1h1m0 1h1m0 1h1m0 1h1"/><path stroke="#795f3c" d="M21 24h1m-1 1h2m-3 1h3m-3 1h3m-4 1h3m-3 1h3m-4 1h3m-3 1h3"/>';

    string private constant FACE_SHAVEN_SVG = '<path stroke="#020202" d="M14 4h3m-5 1h6m-7 1h1m2 0h3m1 0h1m-9 1h1m4 0h2m2 0h1M9 8h1m6 0h1m3 0h1M9 9h1m10 0h1M9 10h1m10 0h1M9 11h1m2 0h3m2 0h4M8 12h2m10 0h1M7 13h1m12 0h1M8 14h1m7 0h1m3 0h1M8 15h2m6 0h1m3 0h1M9 16h1m5 0h2m3 0h1M9 17h1m10 0h1M9 18h1m4 0h4m2 0h1M9 19h1m1 0h1m7 0h1M9 20h1m2 0h1m5 0h1M9 21h1m3 0h5m-9 1h1m3 0h1"/><path stroke="#d0ac98" d="M12 6h2m3 0h1m-7 1h4m2 0h2m-9 1h6m1 0h3M10 9h10m-10 1h10m-10 1h2m3 0h2m-7 1h3m1 0h4m1 0h1M8 13h12M9 14h7m1 0h3m-10 1h6m1 0h3m-10 1h5m2 0h3m-10 1h10m-10 1h4m4 0h2m-10 1h1m1 0h7m-9 1h2m1 0h5m-8 1h3m-3 1h3"/><path stroke="#54463e" d="M13 12h1m4 0h1"/>';
    string private constant FACE_UNSHAVEN_SVG = '<path stroke="#020202" d="M14 4h3m-5 1h6m-7 1h1m2 0h3m1 0h1m-9 1h1m4 0h2m2 0h1M9 8h1m6 0h1m3 0h1M9 9h1m10 0h1M9 10h1m10 0h1M9 11h1m2 0h3m2 0h4M8 12h2m10 0h1M7 13h1m12 0h1M8 14h1m7 0h1m3 0h1M8 15h2m6 0h1m3 0h1M9 16h1m5 0h2m3 0h1M9 17h1m10 0h1M9 18h1m4 0h4m2 0h1M9 19h1m1 0h1m7 0h1M9 20h1m2 0h1m5 0h1M9 21h1m3 0h5m-9 1h1m3 0h1"/><path stroke="#d0ac98" d="M12 6h2m3 0h1m-7 1h4m2 0h2m-9 1h6m1 0h3M10 9h10m-10 1h10m-10 1h2m3 0h2m-7 1h3m1 0h4m1 0h1M8 13h12M9 14h7m1 0h3m-9 1h5m1 0h3m-8 1h3m2 0h2m-9 3h1m-1 1h2m-2 1h3m-3 1h3"/><path stroke="#54463e" d="M13 12h1m4 0h1"/><path stroke="#69574d" d="M10 15h1m-1 1h2m7 0h1m-10 1h10m-10 1h4m4 0h2m-8 1h7m-6 1h5"/>';
    string private constant FACE_MOUSTACHE_SVG = '<path stroke="#020202" d="M14 4h3m-5 1h6m-7 1h1m2 0h3m1 0h1m-9 1h1m4 0h2m2 0h1M9 8h1m6 0h1m3 0h1M9 9h1m10 0h1M9 10h1m10 0h1M9 11h1m2 0h3m2 0h4M8 12h2m10 0h1M7 13h1m12 0h1M8 14h1m7 0h1m3 0h1M8 15h2m6 0h1m3 0h1M9 16h1m5 0h2m3 0h1M9 17h1m10 0h1M9 18h1m4 0h4m2 0h1M9 19h1m1 0h1m7 0h1M9 20h1m2 0h1m5 0h1M9 21h1m3 0h5m-9 1h1m3 0h1"/><path stroke="#d0ac98" d="M12 6h2m3 0h1m-7 1h4m2 0h2m-9 1h6m1 0h3M10 9h10m-10 1h10m-10 1h2m3 0h2m-7 1h3m1 0h4m1 0h1M8 13h12M9 14h7m1 0h3m-10 1h6m1 0h3m-10 1h5m2 0h3m-10 1h3m6 0h1m-10 1h3m6 0h1m-10 1h1m1 0h1m1 0h4m-8 1h2m1 0h5m-8 1h3m-3 1h3"/><path stroke="#54463e" d="M13 12h1m4 0h1"/><path stroke="#69574d" d="M13 17h6m-6 1h1m4 0h1m-6 1h1m4 0h1"/>';
    string private constant FACE_BEARD_SVG = '<path stroke="#020202" d="M14 4h3m-5 1h6m-7 1h1m2 0h3m1 0h1m-9 1h1m4 0h2m2 0h1M9 8h1m6 0h1m3 0h1M9 9h1m10 0h1M9 10h1m10 0h1M9 11h1m2 0h3m2 0h4M8 12h2m10 0h1M7 13h1m12 0h1M8 14h1m7 0h1m3 0h1M8 15h3m5 0h1m3 0h1M9 16h3m3 0h2m2 0h2M9 17h12M9 18h5m4 0h3M9 19h11M9 20h11M9 21h1m1 0h8M9 22h1m3 0h5"/><path stroke="#d0ac98" d="M12 6h2m3 0h1m-7 1h4m2 0h2m-9 1h6m1 0h3M10 9h10m-10 1h10m-10 1h2m3 0h2m-7 1h3m1 0h4m1 0h1M8 13h12M9 14h7m1 0h3m-9 1h5m1 0h3m-8 1h3m2 0h2m-5 2h4m-8 3h1m-1 1h3"/><path stroke="#54463e" d="M13 12h1m4 0h1"/>';
    string private constant FACE_GOATEE_SVG = '<path stroke="#020202" d="M14 4h3m-5 1h6m-7 1h1m2 0h3m1 0h1m-9 1h1m4 0h2m2 0h1M9 8h1m6 0h1m3 0h1M9 9h1m10 0h1M9 10h1m10 0h1M9 11h1m2 0h3m2 0h4M8 12h2m10 0h1M7 13h1m12 0h1M8 14h1m7 0h1m3 0h1M8 15h2m6 0h1m3 0h1M9 16h1m5 0h2m3 0h1M9 17h1m3 0h6m1 0h1M9 18h1m2 0h2m4 0h3M9 19h1m1 0h9M9 20h1m2 0h7M9 21h1m3 0h5m-9 1h1m3 0h1"/><path stroke="#d0ac98" d="M12 6h2m3 0h1m-7 1h4m2 0h2m-9 1h6m1 0h3M10 9h10m-10 1h10m-10 1h2m3 0h2m-7 1h3m1 0h4m1 0h1M8 13h12M9 14h7m1 0h3m-10 1h6m1 0h3m-10 1h5m2 0h3m-10 1h3m6 0h1m-10 1h2m2 0h4m-8 1h1m-1 1h2m-2 1h3m-3 1h3"/><path stroke="#54463e" d="M13 12h1m4 0h1"/>';
    string private constant FACE_MASKED_SVG = '<path stroke="#020202" d="M14 4h3m-5 1h6m-7 1h1m2 0h3m1 0h1m-9 1h1m4 0h2m2 0h1M9 8h1m6 0h1m3 0h1M9 9h1m10 0h1M9 10h1m10 0h1M9 11h1m2 0h3m2 0h4M9 12h1m10 0h1m-1 1h1"/><path stroke="#d0ac98" d="M12 6h2m3 0h1m-7 1h4m2 0h2m-9 1h6m1 0h3M10 9h10m-10 1h10m-10 1h2m3 0h2m-7 1h3m1 0h4m1 0h1m-9 1h9"/><path stroke="#454539" d="M8 12h1m-2 1h4m-3 1h8m1 0h4M8 15h8m1 0h4M9 16h6m2 0h4M9 17h12M9 18h5m4 0h3M9 19h11M9 20h10M9 21h9m-9 1h5"/><path stroke="#54463e" d="M13 12h1m4 0h1"/><path stroke="#23231d" d="M16 14h1m-1 1h1m-2 1h2m-3 2h4"/>';
    string private constant FACE_BALACLAVA_SVG = '<path stroke="#454539" d="M12 4h6m-7 1h8m-9 1h10M9 7h12M9 8h12M9 9h12M9 10h12M9 11h3m8 0h1M8 12h4m8 0h1M7 13h14M8 14h8m1 0h4M8 15h8m1 0h4M9 16h6m2 0h4M9 17h12M9 18h5m4 0h3M9 19h11M9 20h10M9 21h9m-9 1h5"/><path stroke="#020202" d="M12 11h3m2 0h3"/><path stroke="#d0ac98" d="M15 11h2m-5 1h1m1 0h4m1 0h1"/><path stroke="#54463e" d="M13 12h1m4 0h1"/><path stroke="#23231d" d="M16 14h1m-1 1h1m-2 1h2m-3 2h4"/>';
    string private constant FACE_WHITE_SVG = '<path stroke="#020202" d="M12 5h6m-7 1h1m6 0h1m-9 1h1m8 0h1M9 8h1m10 0h1M9 9h1m10 0h1M9 10h1m10 0h1M9 11h1m10 0h1M8 12h2m10 0h1M7 13h1m12 0h1M8 14h1m7 0h1m3 0h1M8 15h1m7 0h1m-2 1h2m-8 3h1m-1 1h1m-1 1h1m-1 1h1m3 0h1"/><path stroke="#d0ac98" d="M12 6h6m-7 1h8m-9 1h10M10 9h10m-10 1h10m-10 1h2m3 0h2m-7 1h3m1 0h4m1 0h1M8 13h12M9 14h7m1 0h3m-9 1h5m1 0h3m-8 1h3m2 0h2m-5 2h4m-8 2h1m-1 1h3m-3 1h3"/><path stroke="#646464" d="M12 11h3m2 0h3M9 15h2m9 0h1m-11 1h2m7 0h2M9 17h1m1 0h9M9 18h1m1 0h1m1 0h1m4 0h1m1 0h1m-11 1h3m1 0h6m-8 1h3m1 0h1m-4 1h1m1 0h3"/><path stroke="#54463e" d="M13 12h1m4 0h1"/><path stroke="#868686" d="M9 16h1m0 1h1m9 0h1m-11 1h1m1 0h1m6 0h1m-7 1h1m-3 1h1m3 0h1m1 0h2m-5 1h1"/>';
    string private constant FACE_OLD_SVG = '<path stroke="#020202" d="M12 5h6m-7 1h1m6 0h1m-9 1h1m8 0h1M9 8h1m10 0h1M9 9h1m10 0h1M9 10h1m10 0h1M9 11h1m10 0h1M8 12h2m10 0h1M7 13h1m12 0h1M8 14h1m7 0h1m3 0h1M8 15h2m6 0h1m3 0h1M9 16h1m5 0h2m3 0h1M9 17h1m10 0h1M9 18h1m4 0h4m2 0h1M9 19h1m-1 1h1m2 0h1m5 0h1M9 21h1m3 0h5m-9 1h1m3 0h1"/><path stroke="#d0ac98" d="M12 6h6m-7 1h8m-9 1h10M10 9h10m-10 1h10m-10 1h2m3 0h2m-7 1h3m1 0h4m1 0h1M8 13h12M9 14h7m1 0h3m-10 1h6m1 0h3m-10 1h5m2 0h3m-10 1h3m6 0h1m-10 1h1m1 0h1m6 0h1m-10 1h1m3 0h4m-8 1h2m1 0h5m-8 1h3m-3 1h3"/><path stroke="#d0d0d0" d="M12 11h3m2 0h3m-7 6h6m-8 1h1m1 0h1m4 0h1m-8 1h3m4 0h3"/><path stroke="#54463e" d="M13 12h1m4 0h1"/>';
    string private constant FACE_GHOST_SVG = '<path stroke="#020202" d="M12 4h6m-7 1h8m-9 1h10M9 7h12M9 8h12M9 9h12M9 10h12M9 11h6m2 0h4M8 12h4m8 0h1M7 13h14M8 14h13M8 15h5m3 0h1m3 0h1M9 16h3m3 0h3m2 0h1M9 17h5m5 0h2M9 18h3m1 0h2m1 0h1m1 0h3M9 19h4m2 0h1m1 0h1m1 0h1M9 20h5m4 0h1M9 21h9m-9 1h5m-5 1h5"/><path stroke="#d0ac98" d="M15 11h2m-5 1h1m1 0h4m1 0h1"/><path stroke="#54463e" d="M13 12h1m4 0h1"/><path stroke="#fff" d="M13 15h3m1 0h3m-8 1h3m3 0h2m-6 1h5m-7 1h1m2 0h1m1 0h1m-5 1h2m1 0h1m1 0h1m-5 1h4"/>';
    string private constant FACE_ZELENSKYY_SVG = '<path stroke="#020202" d="M11 5h8m-9 1h10M9 7h12M9 8h4m6 0h2M9 9h3m8 0h1M9 10h2m9 0h1M9 11h1m10 0h1M8 12h2m2 0h3m2 0h4M7 13h1m12 0h1M8 14h1m7 0h1m3 0h1M8 15h2m6 0h1m3 0h1M9 16h1m5 0h2m3 0h1M9 17h1m10 0h1M9 18h1m4 0h4m2 0h1M9 19h1m1 0h1m7 0h1M9 20h1m2 0h1m5 0h1M9 21h1m3 0h5m-9 1h1m3 0h1"/><path stroke="#d0ac98" d="M13 8h6m-7 1h8m-9 1h9m-10 1h10m-10 1h2m3 0h2m-9 1h5m1 0h4m1 0h1M9 14h7m1 0h3m-10 1h6m1 0h3m-9 1h4m2 0h3m-8 1h1m6 0h1m-10 2h1m4 0h2m-7 1h2m-2 1h3m-3 1h3"/><path stroke="#54463e" d="M13 13h1m4 0h1"/><path stroke="#69574d" d="M10 16h1m-1 1h2m1 0h6m-9 1h4m4 0h2m-8 1h3m2 0h2m-6 1h5"/>';

    string private constant HAT_HAT_SVG = '<path stroke="#454539" d="M11 3h8m-9 1h10M9 5h12M9 6h12"/><path stroke="#23231d" d="M8 7h14M8 8h14M8 9h14"/>';
    string private constant HAT_PANAMA_SVG = '<path stroke="#7b7862" d="M11 3h3m3 0h2m-9 1h2m4 0h4m-9 1h2m4 0h1m1 0h1m-8 1h2m3 0h1m1 1h2m-2 1h1"/><path stroke="#aaaa94" d="M14 3h3m-5 1h4M9 5h2m2 0h1m2 0h1m1 0h1m1 0h1M11 6h1m2 0h2m2 0h3M9 7h1m1 0h4m3 0h1M8 8h11m1 0h2M7 9h16M6 10h3m12 0h3"/><path stroke="#cdcdba" d="M14 5h2M9 6h2m5 0h1m-7 1h1m4 0h3"/>';
    string private constant HAT_CAP_SVG = '<path stroke="#7b7862" d="M11 4h3m4 0h1m-7 1h1m3 0h4m-9 1h1m-2 1h2m5 0h2m-3 1h2"/><path stroke="#aaaa94" d="M14 4h4m-8 1h2m2 0h2M9 6h2m1 0h1m3 0h4m-8 1h2m1 0h2M9 8h7"/><path stroke="#cdcdba" d="M13 5h1m-1 1h3M9 7h1m4 0h1"/><path stroke="#454539" d="M19 7h5m-6 1h7"/>';
    string private constant HAT_PIXEL_SVG = '<path stroke="#454539" d="M11 2h2m-2 1h4m5 0h1M10 4h2m1 0h1m6 0h2M9 5h2m2 0h1m5 0h4m-5 1h3m1 0h1m-3 1h1m1 0h2"/><path stroke="#7b7862" d="M13 2h6M9 3h2m4 0h2m1 0h2M8 4h2m2 0h1m1 0h2m3 0h1M7 5h2m2 0h2m4 0h2M7 6h3m1 0h2m2 0h1m1 0h1m3 0h1M6 7h2m4 0h8m1 0h1M6 8h3m1 0h14M6 9h5m10 0h3M6 10h3m12 0h3M6 11h3m12 0h2M7 12h2m12 0h1"/><path stroke="#aaaa94" d="M17 3h1m-2 1h3m-5 1h3m-7 1h1m2 0h2m1 0h1M8 7h4M9 8h1"/><path stroke="#3e3d32" d="M11 9h10M9 10h2m12 1h1M6 12h1m15 0h1M7 13h2m12 0h1"/>';
    string private constant HAT_KEVLAR_SVG = '<path stroke="#454539" d="M11 2h8M9 3h12M8 4h14M7 5h16M7 6h16M6 7h18M6 8h18M6 9h5m10 0h3M6 10h3m12 0h3M6 11h3m12 0h2M7 12h2m12 0h1"/><path stroke="#23231d" d="M11 9h10M9 10h2m12 1h1M6 12h1m15 0h1M7 13h2m12 0h1"/>';
    string private constant HAT_TACTICAL_SVG = '<path stroke="#454539" d="M11 2h2m7 1h1m2 4h1"/><path stroke="#7b7862" d="M13 2h6M9 3h2M8 4h1M7 5h1M7 6h1M6 7h2m7 0h2M6 8h2m6 0h4m5 0h1M6 9h3m13 0h2M6 10h3m12 0h3M6 11h3m12 0h2M7 12h2m12 0h1"/><path stroke="#020202" d="M11 3h9M9 4h2m9 0h2M8 5h1m13 0h1M8 6h1m6 0h2m5 0h1M8 7h1m5 0h1m2 0h1m4 0h1M8 8h1m4 0h1m4 0h1m3 0h1M9 9h4m6 0h3"/><path stroke="#a6a96c" d="M11 4h9M9 5h13M9 6h6m2 0h5M9 7h5m4 0h4M9 8h4m6 0h3"/><path stroke="#3e3d32" d="M13 9h6M9 10h2m12 1h1M6 12h1m15 0h1M7 13h2m12 0h1"/>';

    function getUniformSvgPart(uint8 uniform) private pure returns (string memory) {
        if (uniform == 6) {
            return UNIFORM_T_SVG;
        } else if (uniform == 5) {
            return UNIFORM_T_WITH_BLACK_SVG;
        } else if (uniform == 4) {
            return UNIFORM_T_WITH_GREEN_SVG;
        } else if (uniform == 3) {
            return UNIFORM_BLACK_WITH_GREEN_SVG;
        } else if (uniform == 2) {
            return UNIFORM_PIXEL_WITH_BLACK_SVG;
        } else if (uniform == 1) {
            return UNIFORM_PIXEL_WITH_GREEN_SVG;
        } else {
            return UNIFORM_PIXEL_SVG;
        }
    }

    function getFaceSvgPart(uint8 face) private pure returns (string memory) {
        if (face == 10) {
            return FACE_ZELENSKYY_SVG;
        } else if (face == 9) {
            return FACE_GHOST_SVG;
        } else if (face == 8) {
            return FACE_OLD_SVG;
        } else if (face == 7) {
            return FACE_WHITE_SVG;
        } else if (face == 6) {
            return FACE_BALACLAVA_SVG;
        } else if (face == 5) {
            return FACE_MASKED_SVG;
        } else if (face == 4) {
            return FACE_GOATEE_SVG;
        } else if (face == 3) {
            return FACE_BEARD_SVG;
        } else if (face == 2) {
            return FACE_MOUSTACHE_SVG;
        } else if (face == 1) {
            return FACE_UNSHAVEN_SVG;
        } else {
            return FACE_SHAVEN_SVG;
        }
    }

    function getHatSvgPart(uint8 hat) private pure returns (string memory) {
        if (hat == 6) {
            return HAT_TACTICAL_SVG;
        } else if (hat == 5) {
            return HAT_KEVLAR_SVG;
        } else if (hat == 4) {
            return HAT_PIXEL_SVG;
        } else if (hat == 3) {
            return HAT_CAP_SVG;
        } else if (hat == 2) {
            return HAT_PANAMA_SVG;
        } else if (hat == 1) {
            return HAT_HAT_SVG;
        } else {
            return '';
        }
    }

    function getGlassesSvgPart(bool glasses, SpecialVariants variant) private pure returns (string memory) {
        if (!glasses) return '';
        string memory color = variant == SpecialVariants.GhostBalaclava ? '4f4f4f' : '020202';
        string memory start = variant == SpecialVariants.Zelenskyy ? '12h12m-11' : '11h12m-11';

        return string(
            abi.encodePacked(
                '<path stroke="#', color, '" d="M10 ', start, ' 1h5m1 0h5m-10 1h3m3 0h3"/>'
            )
        );
    }

    function getTokenImage(TokenInfo memory info) external pure returns (string memory) {
        SpecialVariants variant = info.face == 10 ? SpecialVariants.Zelenskyy : info.face == 9 ? SpecialVariants.GhostBalaclava : SpecialVariants.Usual;

        string memory background = string(abi.encodePacked(
                '<radialGradient id="a" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="rotate(90 0 16) scale(35.854)">',
                '<stop stop-color="#', variant == SpecialVariants.Zelenskyy ? 'E3CC4F' : '497165', '"/>',
                '<stop offset="1" stop-color="#', variant == SpecialVariants.Zelenskyy ? 'CB8B3F' : '3C534C', '"/>',
                '</radialGradient>'
            )
        );

        return string(
            abi.encodePacked(
                'data:image/svg+xml;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -0.5 32 32" shape-rendering="crispEdges">',
                            '<path fill="url(#a)" d="M0 0h32v32H0z"/>', // background
                            getUniformSvgPart(info.uniform), // uniform
                            info.NLAW ? NLAW_SVG : '', // NLAW
                            getFaceSvgPart(info.face), // face
                            getHatSvgPart(info.hat), // hat
                            getGlassesSvgPart(info.glasses, variant), // glasses
                            '<defs>', background, '</defs>',
                            '</svg>'
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

struct TokenInfo {
    // The face of CryptoDefender (base type)
    uint8 face;
    // The uniform of CryptoDefender
    uint8 uniform;
    // The hat of CryptoDefender
    uint8 hat;
    // Is CryptoDefender wearing glasses
    bool glasses;
    // Is CryptoDefender having NLAW
    bool NLAW;
    // The edition of token of current base type
    uint16 edition;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// Modified from https://gist.github.com/Chmarusso/045ee79fa9a1fae55928a613044c9067 (only encode)
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
}