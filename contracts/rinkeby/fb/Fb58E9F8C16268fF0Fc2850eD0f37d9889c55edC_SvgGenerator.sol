// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../structs/TokenInfo.sol";
import "./Base64.sol";

library SvgGenerator {
    string private constant UNIFORM_PIXEL_SVG = '<path d="M15 24H8V22V21H7V24H5H3V25H1V26H0V32H1H27V28H26V27H24V26H22V25H20V24H16V22H15V23V24Z" fill="#AAAA94"/><path d="M3 24V25H2V27H3V28H1V27H0V29H1V30H4V31H5V30H7V31H8V32H11V30H10V29H9V28H8V27H10V26H7V24H6V26H5V25H4V24H3Z" fill="#454539"/><path d="M12 28V29H13V30H14V29H15V30H17V31H15V32H21V31H23V30H25V29H23V26H22V25H21V26H19V24H16V25H15V26H14V28H12Z" fill="#454539"/><path d="M8 21H9V23H14V22H15V24H8V21Z" fill="#7B7862"/><path d="M8 26V25H9V27H8V29H7V28H4V27H7V26H8Z" fill="#7B7862"/><path d="M18 29L19 29V28H20V27H21V26L18 26L18 25H17V27H18L18 29Z" fill="#7B7862"/><path d="M14 24H10V25H11V27H13V28H16V27H15V26H13V25H14V24Z" fill="#CDCDBA"/><path d="M24 27H26V28H27V31H26V29H25V32H24V31H23V29H22V30H20V29H21V28H24V27Z" fill="#CDCDBA"/><path d="M0 31H3V32H7V31H6V29H5V31H4V30H1V29H0V31Z" fill="#CDCDBA"/><path d="M6 21H8V22H7V24H3V23H6V21Z" fill="#020202"/><path d="M1 25V24H3V25H1Z" fill="#020202"/><path d="M1 25V26H0V25H1Z" fill="#020202"/><path d="M16 23H20V24H16V23Z" fill="#020202"/><path d="M22 25H20V24H22V25Z" fill="#020202"/><path d="M24 26H22V25H24V26Z" fill="#020202"/><path d="M26 27H24V26H26V27Z" fill="#020202"/><path d="M27 28H26V27H27V28Z" fill="#020202"/><path d="M27 28H28V32H27V28Z" fill="#020202"/><path d="M20 28H21V32H20V28Z" fill="#020202"/><path d="M3 28H2V32H3V28Z" fill="#020202"/>';
    string private constant UNIFORM_PIXEL_WITH_GREEN_SVG = '<path d="M15 24H8V22V21H7V24H5H3V25H1V26H0V32H1H27V28H26V27H24V26H22V25H20V24H16V22H15V23V24Z" fill="#AAAA94"/><path d="M14 24H10V25H11V27H13V28H16V27H15V26H13V25H14V24Z" fill="#CDCDBA"/><path d="M24 27H26V28H27V31H26V29H25V32H24V31H23V29H22V30H20V29H21V28H24V27Z" fill="#CDCDBA"/><path d="M0 31H3V32H7V31H6V29H5V31H4V30H1V29H0V31Z" fill="#CDCDBA"/><path d="M8 21H9V23H14V22H15V24H8V21Z" fill="#7B7862"/><path d="M9 27H14V26H15V25H16V24H20V25H21V32H2V25H3V24H7V25H9V27Z" fill="#7B7862"/><path d="M6 21V23H3V24H1V25H0V26H1V25H2V32H3V24H6V25H7V26H8V27H9V28H14V27H15V26H16V25H17V24H20V32H21V25H22V26H24V27H26V28H27V32H28V28H27V27H26V26H24V25H22V24H20V23H16V25H15V26H14V27H9V26H8V25H7V22H8V21H6Z" fill="#020202"/><path d="M21 25H22V26H23V28H21V25Z" fill="#454539"/><path d="M10 26H9V27H10V26Z" fill="#454539"/><path d="M0 27H1V28H2V30H1V29H0V27Z" fill="#454539"/><path d="M4 29H7V32H4V29Z" fill="#454539"/><path d="M11 29H8V32H11V29Z" fill="#454539"/><path d="M12 29H15V32H12V29Z" fill="#454539"/><path d="M19 29H16V32H19V29Z" fill="#454539"/><path d="M22 29H23V31H21V30H22V29Z" fill="#454539"/>';
    string private constant UNIFORM_PIXEL_WITH_BLACK_SVG = '<path d="M15 24H8V22V21H7V24H5H3V25H1V26H0V32H1H27V28H26V27H24V26H22V25H20V24H16V22H15V23V24Z" fill="#AAAA94"/><path d="M8 21H9V23H14V22H15V24H8V21Z" fill="#7B7862"/><path d="M14 24H10V25H11V27H13V28H16V27H15V26H13V25H14V24Z" fill="#CDCDBA"/><path d="M24 27H26V28H27V31H26V29H25V32H24V31H23V29H22V30H20V29H21V28H24V27Z" fill="#CDCDBA"/><path d="M0 31H3V32H7V31H6V29H5V31H4V30H1V29H0V31Z" fill="#CDCDBA"/><path d="M21 25H22V26H23V28H21V25Z" fill="#454539"/><path d="M10 26H9V27H10V26Z" fill="#454539"/><path d="M0 27H1V28H2V30H1V29H0V27Z" fill="#454539"/><path d="M22 29H23V31H21V30H22V29Z" fill="#454539"/><path d="M6 21V23H3V24H1V25H0V26H1V25H2V32H21V25H22V26H24V27H26V28H27V32H28V28H27V27H26V26H24V25H22V24H20V23H16V25H15V26H14V27H9V26H8V25H7V22H8V21H6Z" fill="#020202"/><path d="M7 29H4V32H7V29Z" fill="#4F4F4F"/><path d="M11 29H8V32H11V29Z" fill="#4F4F4F"/><path d="M12 29H15V32H12V29Z" fill="#4F4F4F"/><path d="M19 29H16V32H19V29Z" fill="#4F4F4F"/>';
    string private constant UNIFORM_BLACK_WITH_GREEN_SVG = '<path d="M15 24H8V21H6V23H3V24H1V25H0V32H28V28H27V27H26V26H24V25H22V24H20V23H16V22H15V24Z" fill="#020202"/><path d="M9 21H8V24H15V22H14V23H9V21Z" fill="#7B7862"/><path d="M6 24H3V32H20V24H17V25H16V26H15V27H14V28H9V27H8V26H7V25H6V24Z" fill="#7B7862"/><path d="M7 29H4V32H7V29Z" fill="#454539"/><path d="M11 29H8V32H11V29Z" fill="#454539"/><path d="M12 29H15V32H12V29Z" fill="#454539"/><path d="M19 29H16V32H19V29Z" fill="#454539"/>';
    string private constant UNIFORM_T_WITH_GREEN_SVG = '<path d="M15 24H8V23H7V24H5H3V25H1V26H0V32H1H27V28H26V27H24V26H22V25H20V24H16V23H15V24Z" fill="#7B7862"/><path d="M15 25H16V23H7V25H8V26H9V27H14V26H15V25Z" fill="#D0AC98"/><path d="M21 31H27V32H21V31Z" fill="#D0AC98"/><path d="M2 31H0V32H2V31Z" fill="#D0AC98"/><path d="M7 29H4V32H7V29Z" fill="#454539"/><path d="M11 29H8V32H11V29Z" fill="#454539"/><path d="M12 29H15V32H12V29Z" fill="#454539"/><path d="M19 29H16V32H19V29Z" fill="#454539"/><path d="M3 23H9V24H7V25H6V24H3V23Z" fill="#020202"/><path d="M1 25V24H3V32H2V25H1Z" fill="#020202"/><path d="M1 25V26H0V25H1Z" fill="#020202"/><path d="M8 26H7V25H8V26Z" fill="#020202"/><path d="M9 27H8V26H9V27Z" fill="#020202"/><path d="M14 27V28H9V27H14Z" fill="#020202"/><path d="M15 26V27H14V26H15Z" fill="#020202"/><path d="M16 25V26H15V25H16Z" fill="#020202"/><path d="M20 24H17V25H16V24H14V23H20V24Z" fill="#020202"/><path d="M22 25H21V32H20V24H22V25Z" fill="#020202"/><path d="M24 26H22V25H24V26Z" fill="#020202"/><path d="M26 27H24V26H26V27Z" fill="#020202"/><path d="M27 28H26V27H27V28Z" fill="#020202"/><path d="M27 28H28V32H27V28Z" fill="#020202"/>';
    string private constant UNIFORM_T_WITH_BLACK_SVG = '<path d="M15 24H8V23H7V24H5H3V25H1V26H0V32H1H27V28H26V27H24V26H22V25H20V24H16V23H15V24Z" fill="#7B7862"/><path d="M15 25H16V23H7V25H8V26H9V27H14V26H15V25Z" fill="#D0AC98"/><path d="M21 31H27V32H21V31Z" fill="#D0AC98"/><path d="M2 31H0V32H2V31Z" fill="#D0AC98"/><path d="M3 23H9V24H7V25H8V26H9V27H14V26H15V25H16V24H14V23H20V24H22V25H21V32H2V25H1V24H3V23Z" fill="#020202"/><path d="M1 25V26H0V25H1Z" fill="#020202"/><path d="M24 26V25H22V26H24Z" fill="#020202"/><path d="M26 27V26H24V27H26Z" fill="#020202"/><path d="M27 28V27H26V28H27Z" fill="#020202"/><path d="M27 28V32H28V28H27Z" fill="#020202"/><path d="M7 29H4V32H7V29Z" fill="#4F4F4F"/><path d="M11 29H8V32H11V29Z" fill="#4F4F4F"/><path d="M12 29H15V32H12V29Z" fill="#4F4F4F"/><path d="M19 29H16V32H19V29Z" fill="#4F4F4F"/>';
    string private constant UNIFORM_T_SVG = '<path d="M15 24H8V23H7V24H5H3V25H1V26H0V32H1H27V28H26V27H24V26H22V25H20V24H16V23H15V24Z" fill="#7B7862"/><path d="M15 25H16V23H7V25H8V26H9V27H14V26H15V25Z" fill="#D0AC98"/><path d="M21 31H27V32H21V31Z" fill="#D0AC98"/><path d="M2 31H0V32H2V31Z" fill="#D0AC98"/><path d="M9 23H3V24H1V25H0V26H1V25H3V24H6V25H7V26H8V27H9V28H14V27H15V26H16V25H17V24H20V25H22V26H24V27H26V28H27V32H28V28H27V27H26V26H24V25H22V24H20V23H14V24H16V25H15V26H14V27H9V26H8V25H7V24H9V23Z" fill="#020202"/><path d="M3 28H2V32H3V28Z" fill="#020202"/><path d="M21 28H20V32H21V28Z" fill="#020202"/>';

    string private constant NLAW_SVG = '<path d="M21 24H22V25H23V28H22V30H21V32H18V30H19V28H20V26H21V24Z" fill="#795F3C"/><path d="M23 19H24V20H25V21H26V22H27V23H28V24H27V25H25V26H24V25H22V24H20V22H21V21H22V20H23V19Z" fill="#454539"/><path d="M25 15V16H24V17H23V19H24V20H25V21H26V22H27V23H28V24H30V23H31V22H32V20H31V19H30V18H29V17H28V16H27V15H25Z" fill="#020202"/><path d="M21 21H22V22H21V21Z" fill="#F8D347"/><path d="M23 23H22V22H23V23Z" fill="#F8D347"/><path d="M24 24H23V23H24V24Z" fill="#F8D347"/><path d="M25 25V24H24V25H25Z" fill="#F8D347"/><path d="M25 25V26H26V25H25Z" fill="#F8D347"/>';

    string private constant FACE_SHAVEN_SVG = '<path d="M10 8V7H11V6H12V5H18V6H19V7H20V8H21V19H20V20H19V21H18V22H14V23H9V16H8V14H7V13H8V12H9V8H10Z" fill="#D0AC98"/><rect opacity="0.6" x="18" y="12" width="1" height="1" fill="#020202"/><rect opacity="0.6" x="13" y="12" width="1" height="1" fill="#020202"/><path d="M12 6H14V7H15V8H16V9H17V6H18V7H19V8H20V11H17V12H20V19H19V20H18V21H13V20H12V19H11V20H12V21H13V23H14V22H18V21H19V20H20V19H21V8H20V7H19V6H18V5H17V4H14V5H12V6Z" fill="#020202"/><path d="M11 7V6H12V7H11Z" fill="#020202"/><path d="M10 8H11V7H10V8Z" fill="#020202"/><path d="M8 13H10V8H9V12H8V13Z" fill="#020202"/><path d="M8 14V13H7V14H8Z" fill="#020202"/><path d="M8 14V16H9V23H10V15H9V14H8Z" fill="#020202"/><path d="M18 19V18H14V19H18Z" fill="#020202"/><path d="M15 16H16V14H17V17H15V16Z" fill="#020202"/><path d="M12 11H15V12H12V11Z" fill="#020202"/>';
    string private constant FACE_UNSHAVEN_SVG = '<path d="M10 8V7H11V6H12V5H18V6H19V7H20V8H21V19H20V20H19V21H18V22H14V23H9V16H8V14H7V13H8V12H9V8H10Z" fill="#D0AC98"/><path opacity="0.5" d="M20 19V16H19V17H12V16H11V15H10V19H11V20H12H13V21H18V20H19V19H20Z" fill="#020202"/><rect opacity="0.6" x="18" y="12" width="1" height="1" fill="#020202"/><rect opacity="0.6" x="13" y="12" width="1" height="1" fill="#020202"/><path d="M12 6H14V7H15V8H16V9H17V6H18V7H19V8H20V11H17V12H20V19H19V20H18V21H13V20H12V19H11V20H12V21H13V23H14V22H18V21H19V20H20V19H21V8H20V7H19V6H18V5H17V4H14V5H12V6Z" fill="#020202"/><path d="M11 7V6H12V7H11Z" fill="#020202"/><path d="M10 8H11V7H10V8Z" fill="#020202"/><path d="M8 13H10V8H9V12H8V13Z" fill="#020202"/><path d="M8 14V13H7V14H8Z" fill="#020202"/><path d="M8 14V16H9V23H10V15H9V14H8Z" fill="#020202"/><path d="M18 19V18H14V19H18Z" fill="#020202"/><path d="M15 16H16V14H17V17H15V16Z" fill="#020202"/><path d="M12 11H15V12H12V11Z" fill="#020202"/>';
    string private constant FACE_MOUSTACHE_SVG = '<path fill-rule="evenodd" clip-rule="evenodd" d="M10 8V7H11V6H12V5H18V6H19V7H20V8H21V9V19H20V20H19V21H18V22H14V23H9V16H8V14H7V13H8V12H9V9V8H10Z" fill="#D0AC98"/><rect opacity="0.6" x="18" y="12" width="1" height="1" fill="#020202"/><rect opacity="0.6" x="13" y="12" width="1" height="1" fill="#020202"/><path opacity="0.5" d="M19 17H16H13V19V20H14V18H18V20H19V17Z" fill="#020202"/><path d="M12 6H14V7H15V8H16V9H17V6H18V7H19V8H20V11H17V12H20V19H19V20H18V21H13V20H12V19H11V20H12V21H13V23H14V22H18V21H19V20H20V19H21V8H20V7H19V6H18V5H17V4H14V5H12V6Z" fill="#020202"/><path d="M11 7V6H12V7H11Z" fill="#020202"/><path d="M10 8H11V7H10V8Z" fill="#020202"/><path d="M8 13H10V8H9V12H8V13Z" fill="#020202"/><path d="M8 14V13H7V14H8Z" fill="#020202"/><path d="M8 14V16H9V23H10V15H9V14H8Z" fill="#020202"/><path d="M18 19V18H14V19H18Z" fill="#020202"/><path d="M15 16H16V14H17V17H15V16Z" fill="#020202"/><path d="M12 11H15V12H12V11Z" fill="#020202"/>';
    string private constant FACE_BEARD_SVG = '<path d="M10 8V7H11V6H12V5H18V6H19V7H20V8H21V19H20V20H19V21H18V22H14V23H9V16H8V14H7V13H8V12H9V8H10Z" fill="#D0AC98"/><rect opacity="0.6" x="18" y="12" width="1" height="1" fill="#020202"/><rect opacity="0.6" x="13" y="12" width="1" height="1" fill="#020202"/><path d="M12 11H15V12H12V11Z" fill="#020202"/><path fill-rule="evenodd" clip-rule="evenodd" d="M12 6H11V7H10V8H9V12H8V13H7V14H8V16H9V23H10V21H11V22H13V23H18V22H19V21H20V19H21V8H20V7H19V6H18V5H17V4H14V5H12V6ZM12 6H14V7H15V8H16V9H17V6H18V7H19V8H20V11H17V12H20V16H19V17H17V14H16V16H15V17H12V16H11V15H9V14H8V13H10V8H11V7H12V6Z" fill="#020202"/><rect x="14" y="18" width="4" height="1" fill="#D0AC98"/>';
    string private constant FACE_GOATEE_SVG = '<path d="M10 8V7H11V6H12V5H18V6H19V7H20V8H21V19H20V20H19V21H18V22H14V23H9V16H8V14H7V13H8V12H9V8H10Z" fill="#D0AC98"/><rect opacity="0.6" x="18" y="12" width="1" height="1" fill="#020202"/><rect opacity="0.6" x="13" y="12" width="1" height="1" fill="#020202"/><path d="M12 6H14V7H15V8H16V9H17V6H18V7H19V8H20V11H17V12H20V18H19V17H17V14H16V16H15V17H13V18H12V19H11V20H12V21H13V23H14V22H18V21H19V20H20V19H21V8H20V7H19V6H18V5H17V4H14V5H12V6Z" fill="#020202"/><path d="M11 7V6H12V7H11Z" fill="#020202"/><path d="M10 8H11V7H10V8Z" fill="#020202"/><path d="M8 13H10V8H9V12H8V13Z" fill="#020202"/><path d="M8 14V13H7V14H8Z" fill="#020202"/><path d="M8 14V16H9V23H10V15H9V14H8Z" fill="#020202"/><path d="M12 11H15V12H12V11Z" fill="#020202"/><rect x="14" y="18" width="4" height="1" fill="#D0AC98"/>';
    string private constant FACE_MASKED_SVG = '<path d="M10 8V7H11V6H12V5H18V6H19V7H20V8H21V19H20V20H19V21H18V22H14V23H9V16H8V14H7V13H8V12H9V8H10Z" fill="#D0AC98"/><path d="M9 23H14V22H18V21H19V20H20V19H21V13H20V14H11V13H10V12H9H8V13H7V14H8V16H9V23Z" fill="#454539"/><rect opacity="0.5" x="16" y="14" width="1" height="3" fill="#020202"/><rect opacity="0.5" x="15" y="16" width="1" height="1" fill="#020202"/><rect opacity="0.5" x="14" y="18" width="4" height="1" fill="#020202"/><rect opacity="0.6" x="18" y="12" width="1" height="1" fill="#020202"/><rect opacity="0.6" x="13" y="12" width="1" height="1" fill="#020202"/><path d="M12 6H14V7H15V8H16V9H17V6H18V7H19V8H20V11H17V12H20V14H21V8H20V7H19V6H18V5H17V4H14V5H12V6Z" fill="#020202"/><path d="M11 7V6H12V7H11Z" fill="#020202"/><path d="M10 8V7H11V8H10Z" fill="#020202"/><path d="M10 8V13H9V8H10Z" fill="#020202"/><path d="M15 11H12V12H15V11Z" fill="#020202"/>';
    string private constant FACE_BALACLAVA_SVG = '<rect x="12" y="11" width="8" height="2" fill="#D0AC98"/><rect opacity="0.6" x="18" y="12" width="1" height="1" fill="#020202"/><rect opacity="0.6" x="13" y="12" width="1" height="1" fill="#020202"/><path d="M15 11H12V12H15V11Z" fill="#020202"/><path d="M20 11H17V12H20V11Z" fill="#020202"/><path fill-rule="evenodd" clip-rule="evenodd" d="M9 7H10V6H11V5H12V4H18V5H19V6H20V7H21V19H20V20H19V21H18V22H14V23H9V16H8V14H7V13H8V12H9V7ZM20 11H12V13H20V11Z" fill="#454539"/><rect opacity="0.5" x="16" y="14" width="1" height="3" fill="#020202"/><rect opacity="0.5" x="15" y="16" width="1" height="1" fill="#020202"/><rect opacity="0.5" x="14" y="18" width="4" height="1" fill="#020202"/>';
    string private constant FACE_WHITE_SVG = '<path d="M10 8V7H11V6H12V5H18V6H19V7H20V8H21V19H20V20H19V21H18V22H14V23H9V16H8V14H7V13H8V12H9V8H10Z" fill="#D0AC98"/><rect opacity="0.6" x="18" y="12" width="1" height="1" fill="#020202"/><rect opacity="0.6" x="13" y="12" width="1" height="1" fill="#020202"/><path d="M18 5H12V6H11V7H10V8H9V12H8V13H7V14H8V16H9V23H10V15H9V14H8V13H10V8H11V7H12V6H18V7H19V8H20V19H21V8H20V7H19V6H18V5Z" fill="#020202"/><path d="M13 22H14V23H13V22Z" fill="#020202"/><path d="M16 16H15V17H17V14H16V16Z" fill="#020202"/><path d="M12 11H15V12H12V11Z" fill="#646464"/><path d="M20 20V19H21V15H20V16H19V17H12V16H11V15H9V19H10V20H11V21H13V22H18V21H19V20H20Z" fill="#646464"/><path d="M20 11H17V12H20V11Z" fill="#646464"/><path d="M9 16H10V17H9V16Z" fill="#868686"/><path d="M10 17H11V19H10V17Z" fill="#868686"/><path d="M21 17H20V18H19V19H20V18H21V17Z" fill="#868686"/><path d="M12 18H13V19H12V18Z" fill="#868686"/><path d="M13 19H14V20H13V19Z" fill="#868686"/><path d="M12 20H11V21H12V20Z" fill="#868686"/><path d="M16 20H15V21H14V22H15V21H16V20Z" fill="#868686"/><path d="M19 20H17V21H19V20Z" fill="#868686"/><rect x="14" y="18" width="4" height="1" fill="#D0AC98"/>';
    string private constant FACE_OLD_SVG = '<path d="M10 8V7H11V6H12V5H18V6H19V7H20V8H21V19H20V20H19V21H18V22H14V23H9V16H8V14H7V13H8V12H9V8H10Z" fill="#D0AC98"/><rect opacity="0.6" x="18" y="12" width="1" height="1" fill="#020202"/><rect opacity="0.6" x="13" y="12" width="1" height="1" fill="#020202"/><rect x="12" y="11" width="3" height="1" fill="#D0D0D0"/><rect x="17" y="11" width="3" height="1" fill="#D0D0D0"/><path d="M18 17H16H13V19H12V18H11V20H14V18H18V20H21V18H20V19H19V17H18Z" fill="#D0D0D0"/><path d="M18 5H12V6H11V7H10V8H9V12H8V13H7V14H8V16H9V23H10V15H9V14H8V13H10V8H11V7H12V6H18V7H19V8H20V19H21V8H20V7H19V6H18V5Z" fill="#020202"/><path d="M19 20H18V21H13V20H12V21H13V23H14V22H18V21H19V20Z" fill="#020202"/><path d="M18 19V18H14V19H18Z" fill="#020202"/><path d="M15 16H16V14H17V17H15V16Z" fill="#020202"/>';
    string private constant FACE_GHOST_SVG = '<rect x="12" y="11" width="8" height="2" fill="#D0AC98"/><rect opacity="0.6" x="18" y="12" width="1" height="1" fill="#020202"/><rect opacity="0.6" x="13" y="12" width="1" height="1" fill="#020202"/><rect x="12" y="11" width="3" height="1" fill="#020202"/><rect x="17" y="11" width="3" height="1" fill="#020202"/><path fill-rule="evenodd" clip-rule="evenodd" d="M9 7H10V6H11V5H12V4H18V5H19V6H20V7H21V19H20V20H19V21H18V22H14V24H9V16H8V14H7V13H8V12H9V7ZM20 11H12V13H20V11Z" fill="#020202"/><path fill-rule="evenodd" clip-rule="evenodd" d="M16 15H13V16H12V17H14V18H15V19H13V18H12V19H13V20H14V21H18V20H19V19H18V18H19V17H20V15H17V16H18V17H15V16H16V15ZM17 19H18V20H17V19ZM16 19V18H17V19H16ZM16 20V19H15V20H16Z" fill="white"/>';
    string private constant FACE_ZELENSKYY_SVG = '<path d="M10 8V7H11V6H12V5H18V6H19V7H20V8H21V19H20V20H19V21H18V22H14V23H9V16H8V14H7V13H8V12H9V8H10Z" fill="#D0AC98"/><rect opacity="0.6" x="18" y="13" width="1" height="1" fill="#020202"/><rect opacity="0.6" x="13" y="13" width="1" height="1" fill="#020202"/><path d="M13 9H12V10H11V11H10V13H8V12H9V7H10V6H11V5H19V6H20V7H21V19H20V13H17V12H20V9H19V8H13V9Z" fill="#020202"/><path d="M19 20V19H20V20H19Z" fill="#020202"/><path d="M18 21V20H19V21H18Z" fill="#020202"/><path d="M13 21H18V22H14V23H13V21Z" fill="#020202"/><path d="M12 20H13V21H12V20Z" fill="#020202"/><path d="M12 20H11V19H12V20Z" fill="#020202"/><path d="M8 14H7V13H8V14Z" fill="#020202"/><path d="M8 14H9V15H10V23H9V16H8V14Z" fill="#020202"/><path d="M18 19V18H14V19H18Z" fill="#020202"/><path d="M15 16H16V14H17V17H15V16Z" fill="#020202"/><path d="M12 12H15V13H12V12Z" fill="#020202"/><path opacity="0.5" fill-rule="evenodd" clip-rule="evenodd" d="M20 18V19H19V20H18V21H13V20H11V19H10V16H11V17H12V18H13V17H19V18H20ZM17 19H15V20H17V19Z" fill="#020202"/>';

    string private constant HAT_HAT_SVG = '<path d="M9 5V7H8V10H22V7H21V5H20V4H19V3H11V4H10V5H9Z" fill="#454539"/><path opacity="0.5" d="M8 10V8.5V7H22V10H8Z" fill="#020202"/>';
    string private constant HAT_PANAMA_SVG = '<path d="M19 3H15H11V4H10V5H9V8H8V9H7V10H6V11H9V10H21V11H24V10H23V9H22V8H21V5H20V4H19V3Z" fill="#AAAA94"/><path d="M16 5H14V6H16V7H15V8H18V7H17V6H16V5Z" fill="#CDCDBA"/><path d="M9 7H10V8H11V6H9V7Z" fill="#CDCDBA"/><path d="M11 3V4H10V5H11V6H12V7H14V6H13V5H12V4H14V3H11Z" fill="#7B7862"/><path d="M17 3V4H16V5H17V7H18V5H19V6H20V4H19V3H17Z" fill="#7B7862"/><path d="M19 7H21V8H20V9H19V7Z" fill="#7B7862"/>';
    string private constant HAT_CAP_SVG = '<path d="M10 6H9V9H25V8H24V7H20V6V5H19V4H18H12H11V5H10V6Z" fill="#AAAA94"/><path d="M19 7H24V8H25V9H18V8H19V7Z" fill="#454539"/><path d="M11 4H14V5H13V6H12V5H11V4Z" fill="#7B7862"/><path d="M12 8V6H11V7H10V8H12Z" fill="#7B7862"/><path d="M18 4H19V5H20V6H16V5H18V4Z" fill="#7B7862"/><path d="M19 7V8H18V9H16V8H17V7H19Z" fill="#7B7862"/><path d="M13 5H14V6H16V7H15V8H14V7H13V5Z" fill="#CDCDBA"/><path d="M10 7H9V8H10V7Z" fill="#CDCDBA"/>';
    string private constant HAT_PIXEL_SVG = '<path d="M7 5V7H6V12V13H7V14H8H9V11H11V10H21V12V14H22V13H23V12H24V7H23V5H22V4H21V3H19V2H11V3H9V4H8V5H7Z" fill="#7B7862"/><path d="M17 4H16V5H14V6H13V7H15V6H16V7H17V5H19V4H18V3H17V4Z" fill="#AAAA94"/><path d="M11 6H10V7H8V8H9V9H10V8H12V7H11V6Z" fill="#AAAA94"/><path d="M13 2V3H15V4H14V6H13V4H12V5H11V6H9V5H10V4H11V2H13Z" fill="#454539"/><path d="M20 3V5H19V6H18V7H20V8H21V6H22V8H24V7H23V5H22V4H21V3H20Z" fill="#454539"/><g opacity="0.5"><path d="M21 9H11V10H9V11H11V10H21V9Z" fill="#020202"/><path d="M24 11H23V12H22V13H21V14H22V13H23V12H24V11Z" fill="#020202"/><path fill-rule="evenodd" clip-rule="evenodd" d="M6 12H7V13H6V12ZM7 13H9V14H7V13Z" fill="#020202"/></g>';
    string private constant HAT_KEVLAR_SVG = '<path d="M7 5V7H6V12V13H7V14H8H9V11H11V10H21V12V14H22V13H23V12H24V7H23V5H22V4H21V3H19V2H11V3H9V4H8V5H7Z" fill="#454539"/><g opacity="0.5"><path d="M21 9H11V10H9V11H11V10H21V9Z" fill="#020202"/><path d="M24 11H23V12H22V13H21V14H22V13H23V12H24V11Z" fill="#020202"/><path fill-rule="evenodd" clip-rule="evenodd" d="M6 12H7V13H6V12ZM7 13H9V14H7V13Z" fill="#020202"/></g>';
    string private constant HAT_TACTICAL_SVG = '<path d="M7 5V7H6V12V13H7V14H8H9V11H11V10H21V12V14H22V13H23V12H24V7H23V5H22V4H21V3H19V2H11V3H9V4H8V5H7Z" fill="#7B7862"/><path d="M20 4V3H21V4H22V5H23V7H24V8H22V6H21V8H20V7H18V6H19V5H20V4Z" fill="#454539"/><path d="M13 3V2H11V3V4H10V5H9V6H11V5H12V4H13V6H14V4H15V3H13Z" fill="#454539"/><g opacity="0.5"><path d="M21 9H11V10H9V11H11V10H21V9Z" fill="#020202"/><path d="M24 11H23V12H22V13H21V14H22V13H23V12H24V11Z" fill="#020202"/><path fill-rule="evenodd" clip-rule="evenodd" d="M6 12H7V13H6V12ZM7 13H9V14H7V13Z" fill="#020202"/></g><path d="M9 5H8V9H9V10H13V9H14V8H15V7H17V8H18V9H19V10H22V9H23V5H22V4H20V3H11V4H9V5Z" fill="#020202"/><path d="M9 5V6V9H10H11H13V8H14V7H15V6H17V7H18V8H19V9H22V7.5V6V5H20V4H12H11V5H9Z" fill="#A6A96C"/>';

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

    function getBackgroundSvgPart(uint8 face) private pure returns (string memory) {
        bool isZelenskyy = face == 10;

        return string(
            abi.encodePacked(
                '<rect width="32" height="32" fill="url(#', isZelenskyy ? 'b' : 'a', ')"/>',
                '<defs>',
                '<radialGradient id="', isZelenskyy ? 'b' : 'a', '" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(16 16) rotate(90) scale(35.854)">', // background
                '<stop stop-color="#', isZelenskyy ? 'E3CC4F' : '497165', '"/>',
                '<stop offset="1" stop-color="#', isZelenskyy ? 'CB8B3F' : '3C534C', '"/>',
                '</radialGradient>',
                '</defs>'
            )
        );
    }

    function getGlassesSvgPart(bool glasses, uint8 face) private pure returns (string memory) {
        if (!glasses) return '';
        string memory color = face == 9 ? '4F4F4F' : '020202';
        string memory path = face == 10 ? '13V14H15V15H12V14H11V13H10V12H22V14H21V15H18V14H17V13H16Z' : '12V13H15V14H12V13H11V12H10V11H22V13H21V14H18V13H17V12H16Z';

        return string(
            abi.encodePacked(
                '<path d="#M16 ', path, '" fill="#', color, '"/>'
            )
        );
    }

    function getTokenImage(TokenInfo memory info) external pure returns (string memory) {
        return string(
            abi.encodePacked(
                'data:image/svg+xml;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="350px" height="350px" shape-rendering="crispEdges">',
                            getBackgroundSvgPart(info.face), // background
                            getUniformSvgPart(info.uniform), // uniform
                            info.NLAW ? NLAW_SVG : '', // NLAW
                            getFaceSvgPart(info.face), // face
                            getHatSvgPart(info.hat), // hat
                            getGlassesSvgPart(info.glasses, info.face), // glasses
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
    // The owner of token
    address owner;
    // The identifier of token
    uint256 tokenId;
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