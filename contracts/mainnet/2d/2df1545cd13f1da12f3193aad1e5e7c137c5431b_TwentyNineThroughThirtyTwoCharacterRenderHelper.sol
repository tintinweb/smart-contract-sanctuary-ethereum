// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ICharacterSVGRenderer} from "../interfaces/ICharacterSVGRenderer.sol";

contract TwentyNineThroughThirtyTwoCharacterRenderHelper is ICharacterSVGRenderer {
    function characterSVG(uint8 character) public pure returns (string memory) {
        if (character == 29) {
            return _train();
        } else if (character == 30) {
            return _tree();
        } else if (character == 31) {
            return _yetiBasic();
        } else if (character == 32) {
            return _yetiZoom();
        }
        return "";
    }

    function _train() internal pure returns (string memory) {
        return '<rect y="3" width="1" height="1" fill="white"/>' '<rect x="3" y="3" width="2" height="1" fill="white"/>'
        '<rect x="7" y="3" width="5" height="1" fill="white"/>' '<rect y="14" width="24" height="1" fill="white"/>'
        '<rect y="16" width="24" height="8" fill="white"/>' '<rect x="19" y="5" width="1" height="1" fill="#F0C14D"/>'
        '<rect x="4" y="8" width="1" height="1" fill="#F0C14D"/>'
        '<rect x="20" y="8" width="1" height="1" fill="#F0C14D"/>'
        '<rect x="21" y="7" width="1" height="3" fill="#F0C14D"/>'
        '<rect x="22" y="6" width="1" height="5" fill="#F0C14D"/>'
        '<rect x="23" y="5" width="1" height="7" fill="#F0C14D"/>'
        '<rect x="12" y="4" width="2" height="2" class="tintable"/>'
        '<rect x="19" y="4" width="1" height="1" class="tintable"/>'
        '<rect x="18" y="5" width="1" height="1" class="tintable"/>'
        '<rect x="1" y="13" width="1" height="1" class="tintable"/>'
        '<rect x="3" y="13" width="1" height="1" class="tintable"/>'
        '<rect x="5" y="13" width="1" height="1" class="tintable"/>'
        '<rect x="7" y="13" width="1" height="1" class="tintable"/>'
        '<rect x="9" y="13" width="1" height="1" class="tintable"/>'
        '<rect x="11" y="13" width="1" height="1" class="tintable"/>'
        '<rect x="13" y="13" width="1" height="1" class="tintable"/>'
        '<rect x="15" y="13" width="1" height="1" class="tintable"/>'
        '<rect x="21" y="13" width="1" height="1" class="tintable"/>'
        '<rect x="20" y="12" width="1" height="1" class="tintable"/>'
        '<rect x="17" y="13" width="2" height="1" class="tintable"/>'
        '<rect x="17" y="6" width="1" height="1" class="tintable"/>'
        '<rect x="6" y="7" width="1" height="1" class="tintable"/>'
        '<rect x="2" y="7" width="1" height="1" class="tintable"/>'
        '<rect x="12" y="6" width="1" height="2" class="tintable"/>'
        '<rect x="7" y="6" width="1" height="2" class="tintable"/>'
        '<rect y="6" width="2" height="2" class="tintable"/>' '<rect y="8" width="4" height="1" class="tintable"/>'
        '<rect x="5" y="8" width="15" height="1" class="tintable"/>'
        '<rect x="3" y="6" width="3" height="2" class="tintable"/>'
        '<rect x="17" y="7" width="3" height="1" class="tintable"/>'
        '<rect y="9" width="20" height="1" class="tintable"/>' '<rect y="10" width="19" height="1" class="tintable"/>'
        '<rect y="12" width="19" height="1" class="tintable"/>' '<rect y="11" width="20" height="1" class="tintable"/>';
    }

    function _tree() internal pure returns (string memory) {
        return '<rect x="9" y="21" width="5" height="1" class="tintable"/>'
        '<rect x="10" y="20" width="3" height="1" fill="#513340"/>'
        '<rect x="11" y="19" width="1" height="1" fill="#513340"/>'
        '<rect x="10" y="19" width="1" height="1" fill="#369F49"/>'
        '<rect x="14" y="19" width="1" height="1" fill="#369F49"/>'
        '<rect x="17" y="17" width="1" height="1" fill="#369F49"/>'
        '<rect x="13" y="15" width="2" height="1" fill="#369F49"/>'
        '<rect x="9" y="15" width="3" height="1" fill="#369F49"/>'
        '<rect x="14" y="16" width="3" height="1" fill="#369F49"/>'
        '<rect x="8" y="19" width="1" height="1" fill="#369F49"/>'
        '<rect x="5" y="17" width="1" height="1" fill="#369F49"/>'
        '<rect x="6" y="15" width="1" height="1" fill="#369F49"/>'
        '<rect x="8" y="14" width="1" height="1" fill="#369F49"/>'
        '<rect x="16" y="13" width="1" height="1" fill="#369F49"/>'
        '<rect x="15" y="11" width="1" height="1" fill="#369F49"/>'
        '<rect x="14" y="10" width="1" height="1" fill="#369F49"/>'
        '<rect x="11" y="11" width="3" height="1" fill="#369F49"/>'
        '<rect x="7" y="13" width="1" height="1" fill="#369F49"/>'
        '<rect x="7" y="10" width="1" height="1" fill="#369F49"/>'
        '<rect x="9" y="4" width="1" height="1" fill="#369F49"/>'
        '<rect x="13" y="4" width="1" height="1" fill="#369F49"/>'
        '<rect x="11" y="2" width="1" height="3" fill="#369F49"/>'
        '<rect x="10" y="5" width="3" height="1" fill="#369F49"/>'
        '<rect x="9" y="10" width="4" height="1" fill="#369F49"/>'
        '<rect x="11" y="6" width="2" height="4" fill="#369F49"/>'
        '<rect x="8" y="11" width="2" height="1" fill="#369F49"/>'
        '<rect x="9" y="13" width="5" height="1" fill="#369F49"/>'
        '<rect x="10" y="12" width="5" height="1" fill="#369F49"/>'
        '<rect x="10" y="14" width="6" height="1" fill="#369F49"/>'
        '<rect x="7" y="16" width="6" height="1" fill="#369F49"/>'
        '<rect x="6" y="18" width="11" height="1" fill="#369F49"/>'
        '<rect x="8" y="17" width="7" height="1" fill="#369F49"/>'
        '<rect x="12" y="19" width="1" height="1" fill="#369F49"/>';
    }

    function _yetiBasic() internal pure returns (string memory) {
        return '<rect x="12" y="2" width="1" height="1" class="tintable"/>'
        '<rect x="10" y="3" width="5" height="1" class="tintable"/>'
        '<rect x="10" y="4" width="1" height="1" class="tintable"/>'
        '<rect x="12" y="4" width="1" height="1" class="tintable"/>'
        '<rect x="14" y="4" width="1" height="1" class="tintable"/>'
        '<rect x="9" y="5" width="1" height="1" class="tintable"/>'
        '<rect x="15" y="5" width="1" height="1" class="tintable"/>'
        '<rect x="9" y="6" width="7" height="1" class="tintable"/>'
        '<rect x="9" y="7" width="1" height="1" class="tintable"/>'
        '<rect x="15" y="7" width="1" height="1" class="tintable"/>'
        '<rect x="8" y="8" width="9" height="1" class="tintable"/>'
        '<rect x="9" y="9" width="8" height="2" class="tintable"/>'
        '<rect x="18" y="9" width="2" height="5" class="tintable"/>'
        '<rect x="9" y="11" width="1" height="1" class="tintable"/>'
        '<rect x="16" y="11" width="1" height="1" class="tintable"/>'
        '<rect x="9" y="12" width="8" height="2" class="tintable"/>'
        '<rect x="4" y="9" width="4" height="5" class="tintable"/>'
        '<rect x="4" y="14" width="3" height="4" class="tintable"/>'
        '<rect x="8" y="14" width="8" height="2" class="tintable"/>'
        '<rect x="17" y="14" width="3" height="4" class="tintable"/>'
        '<rect x="8" y="16" width="7" height="1" class="tintable"/>'
        '<rect x="8" y="17" width="3" height="4" class="tintable"/>'
        '<rect x="12" y="17" width="3" height="4" class="tintable"/>'
        '<rect x="11" y="4" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="5" y="18" width="2" height="1" fill="#2A46FF"/>'
        '<rect x="17" y="18" width="3" height="1" fill="#2A46FF"/>'
        '<rect x="12" y="21" width="3" height="1" fill="#2A46FF"/>'
        '<rect x="8" y="21" width="3" height="1" fill="#2A46FF"/>'
        '<rect x="11" y="5" width="1" height="1" fill="black"/>'
        '<rect x="13" y="5" width="1" height="1" fill="black"/>'
        '<rect x="13" y="4" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="12" y="5" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="14" y="5" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="10" y="7" width="5" height="1" fill="#2A46FF"/>'
        '<rect x="10" y="5" width="1" height="1" fill="#2A46FF"/>';
    }

    function _yetiZoom() internal pure returns (string memory) {
        return '<rect x="8" y="2" width="7" height="1" class="tintable"/>'
        '<rect x="6" y="3" width="11" height="1" class="tintable"/>'
        '<rect x="5" y="4" width="13" height="1" class="tintable"/>'
        '<rect x="5" y="5" width="2" height="1" class="tintable"/>'
        '<rect x="8" y="5" width="1" height="1" class="tintable"/>'
        '<rect x="10" y="5" width="1" height="1" class="tintable"/>'
        '<rect x="12" y="5" width="1" height="1" class="tintable"/>'
        '<rect x="14" y="5" width="1" height="1" class="tintable"/>'
        '<rect x="16" y="5" width="2" height="1" class="tintable"/>'
        '<rect x="4" y="6" width="2" height="3" class="tintable"/>'
        '<rect x="17" y="6" width="2" height="3" class="tintable"/>'
        '<rect x="3" y="9" width="2" height="1" class="tintable"/>'
        '<rect x="18" y="9" width="2" height="1" class="tintable"/>'
        '<rect x="2" y="10" width="19" height="1" class="tintable"/>'
        '<rect x="3" y="11" width="1" height="1" class="tintable"/>'
        '<rect x="19" y="11" width="1" height="1" class="tintable"/>'
        '<rect x="2" y="12" width="2" height="1" class="tintable"/>'
        '<rect x="19" y="12" width="2" height="1" class="tintable"/>'
        '<rect x="3" y="13" width="1" height="1" class="tintable"/>'
        '<rect x="7" y="14" width="1" height="1" class="tintable"/>'
        '<rect x="9" y="14" width="1" height="1" class="tintable"/>'
        '<rect x="11" y="14" width="1" height="1" class="tintable"/>'
        '<rect x="13" y="14" width="1" height="1" class="tintable"/>'
        '<rect x="15" y="14" width="1" height="1" class="tintable"/>'
        '<rect x="17" y="14" width="7" height="1" class="tintable"/>'
        '<rect x="19" y="13" width="1" height="1" class="tintable"/>'
        '<rect y="14" width="6" height="1" class="tintable"/>' '<rect y="15" width="24" height="3" class="tintable"/>'
        '<rect y="18" width="3" height="6" class="tintable"/>'
        '<rect x="3" y="20" width="1" height="4" class="tintable"/>'
        '<rect x="4" y="18" width="3" height="6" class="tintable"/>'
        '<rect x="7" y="21" width="1" height="3" class="tintable"/>'
        '<rect x="7" y="18" width="4" height="1" class="tintable"/>'
        '<rect x="8" y="19" width="3" height="5" class="tintable"/>'
        '<rect x="11" y="20" width="1" height="4" class="tintable"/>'
        '<rect x="12" y="18" width="3" height="6" class="tintable"/>'
        '<rect x="15" y="18" width="4" height="1" class="tintable"/>'
        '<rect x="16" y="19" width="3" height="1" class="tintable"/>'
        '<rect x="16" y="20" width="8" height="1" class="tintable"/>'
        '<rect x="20" y="18" width="4" height="2" class="tintable"/>'
        '<rect x="15" y="21" width="9" height="3" class="tintable"/>'
        '<rect x="7" y="5" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="18" y="12" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="16" y="14" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="14" y="14" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="12" y="14" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="10" y="14" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="8" y="14" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="6" y="14" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="5" y="12" width="1" height="1" fill="white"/>'
        '<rect x="7" y="12" width="1" height="1" fill="white"/>'
        '<rect x="9" y="12" width="1" height="1" fill="white"/>'
        '<rect x="11" y="12" width="1" height="1" fill="white"/>'
        '<rect x="13" y="12" width="1" height="1" fill="white"/>'
        '<rect x="15" y="12" width="1" height="1" fill="white"/>'
        '<rect x="17" y="12" width="1" height="1" fill="white"/>'
        '<rect x="6" y="12" width="1" height="1" fill="black"/>'
        '<rect x="8" y="12" width="1" height="1" fill="black"/>'
        '<rect x="10" y="12" width="1" height="1" fill="black"/>'
        '<rect x="12" y="12" width="1" height="1" fill="black"/>'
        '<rect x="14" y="12" width="1" height="1" fill="black"/>'
        '<rect x="16" y="12" width="1" height="1" fill="black"/>'
        '<rect x="3" y="18" width="1" height="2" fill="#2A46FF"/>'
        '<rect x="7" y="19" width="1" height="2" fill="#2A46FF"/>'
        '<rect x="11" y="18" width="1" height="2" fill="#2A46FF"/>'
        '<rect x="15" y="19" width="1" height="2" fill="#2A46FF"/>'
        '<rect x="19" y="18" width="1" height="2" fill="#2A46FF"/>'
        '<rect x="4" y="12" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="5" y="9" width="13" height="1" fill="#2A46FF"/>'
        '<rect x="4" y="11" width="15" height="1" fill="#2A46FF"/>'
        '<rect x="4" y="13" width="15" height="1" fill="#2A46FF"/>'
        '<rect x="9" y="5" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="11" y="5" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="13" y="5" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="15" y="5" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="6" y="6" width="11" height="3" fill="#2A46FF"/>';
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ICharacterSVGRenderer {
    function characterSVG(uint8 character) external pure returns (string memory);
}