// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Strings.sol";

interface iUtils {
    function random(bytes memory input) external pure returns (uint256);
    function get_seed_phrase() external view returns (string memory);
    function get_rand_in_range_toStr(uint256 rand, uint256 min, uint256 range) external pure returns (string memory);
    function get_blur_data(bool blur) pure external returns (string[2] memory);
    function add_trait(bytes memory json, string memory trait_type, string memory trait_value) external pure returns (bytes memory);
    function get_cell_path(uint256 tokenId, uint64 _type) view external returns (bytes memory);
    function add_stop(string memory offset, string memory rgbs, bool open) external pure returns (bytes memory);
}

contract svgManip {
    // Parameters to animate svg elements
    struct AnimateParams {
        uint32 start_min;
        uint32 start_range;
        uint32 end_min;
        uint32 end_range;
        uint64 dur_min;
        uint64 dur_range;
        string attribute;
        string value_prefix1;
        string value_prefix2;
    }

    address utils_address;
    string _seed_phrase;

    iUtils Utils;
    
    constructor(address _utils_address) {
        utils_address = _utils_address;
        Utils = iUtils(utils_address);
        _seed_phrase = Utils.get_seed_phrase();
    }

    function _get_scale_value(uint256 tokenId, uint64 _type, uint64 eukaryote) internal view returns (bytes memory) {
        if (eukaryote == 0) {
            uint256 rand_x = Utils.random(abi.encodePacked("STRETCH PROK X STRETCH", _seed_phrase, tokenId));
            uint256 rand_y = Utils.random(abi.encodePacked("PROK Y STRETCH", _seed_phrase, tokenId));
            return abi.encodePacked(
                "scale(0.", Utils.get_rand_in_range_toStr(rand_x, 40, 20), 
                ", 0.", Utils.get_rand_in_range_toStr(rand_y, 40, 20), ")"
            );
        } else if (_type == 2) {
            // Stretch out the muscle cells
            uint256 rand = Utils.random(abi.encodePacked("STRETCH MUSCLE STRETCH", _seed_phrase, tokenId));
            return abi.encodePacked(
                "scale(", Strings.toString(rand % 2 + 1), 
                ".", Utils.get_rand_in_range_toStr(rand, 0, 999), "1)"
            );
        } else {
            return abi.encodePacked("scale(1,1)");
        }
    }

    function get_rand_rgb(uint256 rgb_idx, string memory prefix, uint256 tokenId, uint256 min, uint256 range) view internal returns (string memory) {
        if (rgb_idx == 0) {
            return Utils.get_rand_in_range_toStr(Utils.random(abi.encodePacked(prefix, "RED", _seed_phrase, tokenId)), min, range);
        } else if (rgb_idx == 1) {
            return Utils.get_rand_in_range_toStr(Utils.random(abi.encodePacked("GREEN", prefix, _seed_phrase, tokenId)), min, range);
        } else {
            return Utils.get_rand_in_range_toStr(Utils.random(abi.encodePacked(_seed_phrase, "BLUE", tokenId, prefix)), min, range);
        }
    }

    function get_values_and_dur_for_animate(uint256 tokenId, string memory prefix, AnimateParams memory a) internal view returns (bytes memory) {
        // Create element tag with a random start point, end point and duration for the animation given constraints for each in the AnimateParams object
        // value_prefix1 and 2 allow for floating point output
        bytes memory output = abi.encodePacked('\n<animate repeatCount="indefinite" attributeName="', a.attribute, '" values="', 
            a.value_prefix1, Utils.get_rand_in_range_toStr(Utils.random(abi.encodePacked(prefix, a.attribute, _seed_phrase, "1 One 1", tokenId)), a.start_min, a.start_range), ';', 
            a.value_prefix2, Utils.get_rand_in_range_toStr(Utils.random(abi.encodePacked(prefix, a.attribute, _seed_phrase, "TWOOOOO", tokenId)), a.end_min, a.end_range), ';'
        );

        output = abi.encodePacked(output, 
            a.value_prefix1, Utils.get_rand_in_range_toStr(Utils.random(abi.encodePacked(prefix, a.attribute, _seed_phrase, "1 One 1", tokenId)), a.start_min, a.start_range),
            '" dur="', Utils.get_rand_in_range_toStr(Utils.random(abi.encodePacked(prefix, a.attribute, _seed_phrase, "DURATION", tokenId)), a.dur_min, a.dur_range), 's" begin="-', 
            Utils.get_rand_in_range_toStr(Utils.random(abi.encodePacked(prefix, a.attribute, _seed_phrase, "BEGIN", tokenId)), 1, 100), 's" '
        );

        return abi.encodePacked(output, 'calcMode="spline" keySplines="0.7 0 0.3 1; 0.7 0 0.3 1"/>');
    }

    function add_rand_rgb_combo(string memory prefix, uint256 tokenId, uint256 min, uint256 range) view internal returns (string memory) {
        // Get a random RGB combination
        return string.concat(
            get_rand_rgb(0, prefix, tokenId, min, range), ', ', 
            get_rand_rgb(1, prefix, tokenId, min, range), ', ', 
            get_rand_rgb(2, prefix, tokenId, min, range)
        );
    }

    function _get_cell_core_color(uint256 tokenId) internal view returns (uint256){
        // Give ~1/10 cells a dark core + nucleus
        return (Utils.random(abi.encodePacked(_seed_phrase, "CELL CORE COLOR", tokenId)) % 10 == 9) ? 1 : 0;
    }

    function _get_cell_entropy(uint256 tokenId, uint64 entropy) internal view returns (uint64){
        if (entropy > 0) {
            return entropy;
        }
        // Give ~1/10 cells a dark core + nucleus
        uint256 rand = Utils.random(abi.encodePacked(_seed_phrase, "CELL COLOR ANIMATION VALUE", tokenId)) % 100;
        if (rand == 42) {
            return 2;
        } else if (rand > 90) {
            return 1;
        } else {
            return 0;
        }
    }

    function _add_filters(uint256 tokenId, bytes memory output, uint64 eukaryote, uint64 _type, uint64 generation, uint64 entropy, bool blur) view internal returns (bytes memory) {
        if ((blur == true) && (eukaryote == 0)) {return output;}
        
        uint64[2] memory dur_vals;

        if (entropy == 2) {
            dur_vals = [uint64(5), 10];
        } else if (entropy == 1) {
            dur_vals = [uint64(20), 20];
        } else {
            dur_vals = [uint64(50), 100];
        }

        output = abi.encodePacked(output, '\n<filter id="', Utils.get_blur_data(blur)[0], '">\n<feTurbulence result="turbulence" numOctaves="', Strings.toString(1 + (generation / 5)), '" type="turbulence" baseFrequency="0">');
        if (_type == 3) {
            output = abi.encodePacked(
                output, 
                get_values_and_dur_for_animate(tokenId, string.concat("NOISE GRADIeNTTTTT TURBULANCE", Utils.get_blur_data(blur)[1]),
                    AnimateParams({start_min: 3, start_range: 6, end_min: 10, end_range: 8, dur_min: dur_vals[0], dur_range: dur_vals[1], attribute:"baseFrequency", value_prefix1:"0.0", value_prefix2:"0."})),
                '\n</feTurbulence>', Utils.get_blur_data(blur)[1], '\n<feDisplacementMap in2="turbulence" in="SourceGraphic" scale="45">', 
                get_values_and_dur_for_animate(tokenId, "ANIMATE SCALE", 
                    AnimateParams({start_min: 40, start_range: 10, end_min: 60, end_range: 20, dur_min: dur_vals[0], dur_range: dur_vals[1], attribute:"scale", value_prefix1:"", value_prefix2:""})), 
                '\n</feDisplacementMap>\n</filter>'
            );
        } else if (_type != 0) {
            output = abi.encodePacked(
                output, 
                get_values_and_dur_for_animate(tokenId, string.concat("NOISE GRADIeNTTTTT TURBULANCE", Utils.get_blur_data(blur)[1]),
                    AnimateParams({start_min: 3, start_range: 6, end_min: 10, end_range: 8, dur_min: dur_vals[0], dur_range: dur_vals[1], attribute:"baseFrequency", value_prefix1:"0.00", value_prefix2:"0.0"})),
                '\n</feTurbulence>', Utils.get_blur_data(blur)[1], '\n<feDisplacementMap in2="turbulence" in="SourceGraphic" scale="45">', 
                get_values_and_dur_for_animate(tokenId, "ANIMATE SCALE", 
                    AnimateParams({start_min: 40, start_range: 10, end_min: 60, end_range: 20, dur_min: dur_vals[0], dur_range: dur_vals[1], attribute:"scale", value_prefix1:"", value_prefix2:""})),
                '\n</feDisplacementMap>\n</filter>'
            );
        } else {
            output = abi.encodePacked(output, get_values_and_dur_for_animate(tokenId, "NOISE GRADIeNTTTTT TURBULANCE",
                AnimateParams({start_min: 3, start_range: 6, end_min: 10, end_range: 8, dur_min: dur_vals[0], dur_range: dur_vals[1], attribute:"baseFrequency", value_prefix1:"0.00", value_prefix2:"0.0"})),
                '\n</feTurbulence><feDisplacementMap in2="turbulence" in="SourceGraphic" scale="200">', 
                get_values_and_dur_for_animate(tokenId, "ANIMATE SCALE", 
                    AnimateParams({start_min: 80, start_range: 20, end_min: 150, end_range: 20, dur_min: dur_vals[0], dur_range: dur_vals[1], attribute:"scale", value_prefix1:"", value_prefix2:""})),
                '\n</feDisplacementMap>\n</filter>'
            );
        }
        return output;
    }
    function get_cell_core_color(uint256 tokenId) external view returns (uint256){return _get_cell_core_color(tokenId);}
    function get_cell_entropy(uint256 tokenId, uint64 entropy) external view returns (uint64) {return _get_cell_entropy(tokenId, entropy);}

    function add_cell_body(uint256 tokenId, bytes memory output, uint64 _type) external view returns (bytes memory) {
        output = abi.encodePacked(output, 
            '\n<g style="fill: url(#radial_grad); filter: url(#displacementFilter);">', 
            Utils.get_cell_path(tokenId, _type), '\n</g>'
        );
        return output;
    }

    function _add_mild_stop_color_animation(string memory dur, string memory rgb_1, string memory rgb_2) internal view returns (bytes memory) {
        return abi.encodePacked(
            '\n<animate repeatCount="indefinite" attributeName="stop-color" dur="',
            dur, 's" values="rgb(', rgb_1, '); rgb(', rgb_2, '); rgb(', rgb_1, '" begin="-', 
            Utils.get_rand_in_range_toStr(Utils.random(abi.encodePacked(rgb_1, rgb_2, dur, "BEGIN")), 1, 100), 's" ',
            'calcMode="spline" keySplines="0.7 0 0.3 1; 0.7 0 0.3 1"/>'
        );
    }

    function _add_intense_stop_color_animation(string memory dur, string[5] memory rgbs) internal view returns (bytes memory) {
        bytes memory output = abi.encodePacked(
            '\n<animate repeatCount="indefinite" attributeName="stop-color" dur="',
            dur, 's" values="rgb(', rgbs[0], '); rgb(', rgbs[1], '); rgb(', rgbs[2], '); rgb(', rgbs[3], '); rgb(', rgbs[4], '); rgb('
        );

        return abi.encodePacked(output, 
            rgbs[0], ')" begin="-', 
            Utils.get_rand_in_range_toStr(Utils.random(abi.encodePacked(rgbs[0], rgbs[1], rgbs[2], rgbs[3], rgbs[4], dur, "BEGIN")), 1, 100), 's" ',
            'calcMode="paced"/>'
        );
    }

    function _add_first_gradient_stop(uint256 tokenId, uint64 entropy) view internal returns (bytes memory) {
        bytes memory output = abi.encodePacked(Utils.add_stop("0", (_get_cell_core_color(tokenId) == 1) ? '69, 69, 69' : '255, 255, 255', true));


        if (entropy == 2) {
            output = abi.encodePacked(output, '\n<animate repeatCount="indefinite" attributeName="stop-color" dur="',
                Utils.get_rand_in_range_toStr(Utils.random(abi.encodePacked(_seed_phrase, "nucleUs color anim dur ", tokenId)), 5, 10),
                's" values="rgb(255, 255, 255); rgb(69, 69, 69); rgb(255, 255, 255)" begin="-', 
                Utils.get_rand_in_range_toStr(Utils.random(abi.encodePacked(_seed_phrase, "nucleUs color anim begin ", tokenId)), 1, 100), 's" ',
                'calcMode="spline" keySplines="0.7 0 0.3 1; 0.7 0 0.3 1"/>'
            );
        }

        return abi.encodePacked(output, '\n</stop>');
    }

    function _add_second_gradient_stop(uint256 tokenId, uint64 entropy) view internal returns (bytes memory) {
        bytes memory output;

        output = abi.encodePacked(
            Utils.add_stop("0.3", add_rand_rgb_combo('GRADIENT NUMBER ONE!!!!!', tokenId, 30, 200), true),
            '\n<animate repeatCount="indefinite" attributeName="offset" dur="',
            Utils.get_rand_in_range_toStr(Utils.random(abi.encodePacked(_seed_phrase, "BREAHTING GRADIENT DURATIONNNNNN ", tokenId)), 10, 30),
            's" values="0.15;0.25;0.15" begin="-', 
            Utils.get_rand_in_range_toStr(Utils.random(abi.encodePacked(_seed_phrase, "BEGIN BREAHTING GRADIENT!", tokenId)), 1, 100), 's" ',
            'calcMode="spline" keySplines="0.7 0 0.3 1; 0.7 0 0.3 1"/>'
        );
        // Animate colors on 0.3 stop
        if (entropy == 2) {
            output = abi.encodePacked(output, 
                _add_intense_stop_color_animation(
                    Utils.get_rand_in_range_toStr(Utils.random(abi.encodePacked(_seed_phrase, "GRADIENt FIRST STEP ", tokenId)), 5, 10), 
                    [add_rand_rgb_combo('0 - GRADIENT ONE!!!!!', tokenId, 30, 200), 
                    add_rand_rgb_combo('1 : GRADIENT ONE!!!!!', tokenId, 30, 200),
                    add_rand_rgb_combo('2 -- GRADIENT ONE!!!!!', tokenId, 30, 200),
                    add_rand_rgb_combo('3 !! GRADIENT ONE!!!!!', tokenId, 30, 200),
                    add_rand_rgb_combo('4 ?? GRADIENT ONE!!!!!', tokenId, 30, 200)]
                )
            );
        } else if (entropy == 1) {
            output = abi.encodePacked(output, 
                _add_mild_stop_color_animation(
                    Utils.get_rand_in_range_toStr(Utils.random(abi.encodePacked(_seed_phrase, "GRADIENt FIRST STEP ", tokenId)), 30, 50),
                    add_rand_rgb_combo('GRADIENT NUMBER ONE!!!!!', tokenId, 30, 200), 
                    add_rand_rgb_combo('PARTT TWO OF GRADIENT NUMBER ONE!!!!!', tokenId, 30, 200)
                )
            );
        }

        return abi.encodePacked(output, '\n</stop>');
    }

    function _add_third_gradient_stop(uint256 tokenId, uint64 entropy) view internal returns (bytes memory) {
        bytes memory output;

        // 0.7 stop - linear gradient
        output = abi.encodePacked(
            Utils.add_stop("0.7", add_rand_rgb_combo('SECOND STOP OF GRADIENT', tokenId, 60, 195), true),
            get_values_and_dur_for_animate(tokenId, "ANIMATE SECOND STOP", 
                AnimateParams({start_min: 41, start_range: 10, end_min: 65, end_range: 10, dur_min: 20, dur_range: 40, attribute:"offset", value_prefix1:"0.", value_prefix2:"0."}))
        );

        if (entropy == 2) {
            output = abi.encodePacked(output, 
                _add_intense_stop_color_animation(
                    Utils.get_rand_in_range_toStr(Utils.random(abi.encodePacked(_seed_phrase, "GRADIENt SECOND STEP ", tokenId)), 5, 10), 
                    [add_rand_rgb_combo('GRADIENT 0 - TWO!!!!!', tokenId, 30, 200), 
                    add_rand_rgb_combo('GRADIENT 1 :  TWO!!!!!', tokenId, 30, 200),
                    add_rand_rgb_combo('GRADIENT 2 --  TWO!!!!!', tokenId, 30, 200),
                    add_rand_rgb_combo('GRADIENT 3 !!  TWO!!!!!', tokenId, 30, 200),
                    add_rand_rgb_combo('GRADIENT 4 ??  TWO!!!!!', tokenId, 30, 200)]
                )
            );
        } else if (entropy == 1) {
            output = abi.encodePacked(output, 
                _add_mild_stop_color_animation(
                    Utils.get_rand_in_range_toStr(Utils.random(abi.encodePacked(_seed_phrase, "SECOND STEP ", tokenId)), 30, 50),
                    add_rand_rgb_combo('SECOND STOP OF GRADIENT??', tokenId, 30, 200),
                    add_rand_rgb_combo('SECOND STOP OF GRADIENT?? PART TWO!!', tokenId, 30, 200)
                )
            );
        }
        return abi.encodePacked(output, '\n</stop>');

    }

    function add_gradients(uint256 tokenId, bytes memory output, uint64 eukaryote, uint256 _type, uint64 entropy) view external returns (bytes memory) {
        // Make the gradients
        output = abi.encodePacked(output, '\n<defs>\n<linearGradient id="line_grad" spreadMethod="pad" x1="1" x2="0" y1="0" y2="0">');
        
        // Moving this stop makes the cell center pulse
        output = abi.encodePacked(output, _add_first_gradient_stop(tokenId, entropy));
        output = abi.encodePacked(output, _add_second_gradient_stop(tokenId, entropy));
        output = abi.encodePacked(output, _add_third_gradient_stop(tokenId, entropy));
        output = abi.encodePacked(output, Utils.add_stop("0.95", "0,0,0", false), '\n</linearGradient>');
        output = abi.encodePacked(output, '\n<radialGradient cx="175" cy="175" r="200" id="radial_grad" gradientUnits="userSpaceOnUse" xlink:href="#rad_lin_grad">');
        
        // Animate radial gradient center
        output = abi.encodePacked(output, 
            get_values_and_dur_for_animate(tokenId, "CENTER POINT X COORD", 
                AnimateParams({start_min: 145, start_range: 30, end_min: 155, end_range: 30, dur_min: 20, dur_range: 100, attribute:"cx", value_prefix1:"", value_prefix2:""})),
            get_values_and_dur_for_animate(tokenId, "Y COORD CENTER POINTTTTT", 
                AnimateParams({start_min: 145, start_range: 30, end_min: 155, end_range: 30, dur_min: 20, dur_range: 100, attribute:"cy", value_prefix1:"", value_prefix2:""})));
        
        // Animate radial gradient radius
        if (_type != 0) {
            output = abi.encodePacked(output, get_values_and_dur_for_animate(tokenId, "RADIUSSSSS", 
                AnimateParams({start_min: 100, start_range: 80, end_min: 180, end_range: 220, dur_min: 45, dur_range: 50, attribute:"r", value_prefix1:"", value_prefix2:""})));
        } else if (eukaryote == 1) {
            output = abi.encodePacked(output, get_values_and_dur_for_animate(tokenId, "RADIUSSSSS", 
                AnimateParams({start_min: 130, start_range: 40, end_min: 160, end_range: 40, dur_min: 45, dur_range: 50, attribute:"r", value_prefix1:"", value_prefix2:""})));
        } else {
            output = abi.encodePacked(output, get_values_and_dur_for_animate(tokenId, "RADIUSSSSS", 
                AnimateParams({start_min: 80, start_range: 20, end_min: 110, end_range: 20, dur_min: 45, dur_range: 50, attribute:"r", value_prefix1:"", value_prefix2:""})));
        }
        
        // Make this gradient the same as the other
        output = abi.encodePacked(output, '\n</radialGradient>\n<linearGradient id="rad_lin_grad">');
        output = abi.encodePacked(output, _add_first_gradient_stop(tokenId, entropy));
        output = abi.encodePacked(output, _add_second_gradient_stop(tokenId, entropy));
        output = abi.encodePacked(output, _add_third_gradient_stop(tokenId, entropy));
        output = abi.encodePacked(output, Utils.add_stop("0.95", "0,0,0", false), '\n</linearGradient></defs>');
        return output;
    }

    function add_filters(uint256 tokenId, bytes memory output, uint64 eukaryote, uint64 _type, uint64 generation, uint64 entropy, bool blur) view external returns (bytes memory) {
        return _add_filters(tokenId, output, eukaryote, _type, generation, entropy, blur);
    }
    function get_scale_value(uint256 tokenId, uint64 _type, uint64 eukaryote) external view returns (bytes memory) {return _get_scale_value(tokenId, _type, eukaryote);}

    function add_nucleus(uint256 tokenId, bytes memory output, uint64 _type) view external returns (bytes memory) {
        // Specialized cells are larger than unspecialized so their nuclei will look smaller in comparison
        output = abi.encodePacked(output, '\n<ellipse style="fill: rgb(', 
            (_get_cell_core_color(tokenId) == 1) ? '69, 69, 69' : '255, 255, 255', ');" '
        );
        // Muscle cells get a small nucleus
        if (_type == 2) {
            output = abi.encodePacked(output, 'cx="175" cy="175" rx="20" ry="20">\n</ellipse>'
            );
        } else if (_type != 0) {
            // Other specialized cells get a moving, slightly larger nucleus
            output = abi.encodePacked(output, 'cx="175" cy="175" rx="35" ry="35">',
                get_values_and_dur_for_animate(tokenId, "CENTER POINT X COORD", 
                    AnimateParams({start_min: 145, start_range: 30, end_min: 155, end_range: 30, dur_min: 20, dur_range: 100, attribute:"cx", value_prefix1:"", value_prefix2:""})),
                get_values_and_dur_for_animate(tokenId, "Y COORD CENTER POINTTTTT", 
                    AnimateParams({start_min: 145, start_range: 30, end_min: 155, end_range: 30, dur_min: 20, dur_range: 100, attribute:"cy", value_prefix1:"", value_prefix2:""})),
                '\n</ellipse>'
            );

        } else {
            // Unspecialized eukaryotes get the largest nucleus
            output = abi.encodePacked(output, 'cx="100" cy="100" rx="45" ry="45">', 
                get_values_and_dur_for_animate(tokenId, "CENTER POINT X COORD", 
                    AnimateParams({start_min: 215, start_range: 5, end_min: 230, end_range: 5, dur_min: 20, dur_range: 100, attribute:"cx", value_prefix1:"", value_prefix2:""})),
                get_values_and_dur_for_animate(tokenId, "Y COORD CENTER POINTTTTT", 
                    AnimateParams({start_min: 215, start_range: 5, end_min: 230, end_range: 5, dur_min: 20, dur_range: 100, attribute:"cy", value_prefix1:"", value_prefix2:""})),
                '\n</ellipse>'
            );
        }
        return output;
    }

    function add_spooky_overlay(uint256 tokenId, bytes memory output, uint64 _type) view external returns (bytes memory) {
        // Who doesn't want a spooky overlay
        if (_type != 0) {
            output = abi.encodePacked(output, 
                '\n<g style="transform: scale(1.05, 1.05); transform-origin 170px 170px; fill-opacity:0.6; fill: url(#radial_grad); filter: url(#displacementFilter_blur)">', 
                Utils.get_cell_path(tokenId, _type), '\n</g>'
            );
        } else {
            output = abi.encodePacked(output, 
                '\n<ellipse style="fill: url(#radial_grad); filter: url(#displacementFilter); fill-opacity: 0.6;" cx="175" cy="175" rx="200" ry="200"/>'
            );
        }
        return output;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}