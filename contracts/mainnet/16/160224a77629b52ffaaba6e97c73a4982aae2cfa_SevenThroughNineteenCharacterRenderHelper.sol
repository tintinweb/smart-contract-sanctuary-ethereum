// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ICharacterSVGRenderer} from "../interfaces/ICharacterSVGRenderer.sol";

contract SevenThroughNineteenCharacterRenderHelper is ICharacterSVGRenderer {
    function characterSVG(uint8 character) public pure returns (string memory) {
        if (character == 7) {
            return _mothertrucker();
        } else if (character == 8) {
            return _girl();
        } else if (character == 9) {
            return _lamp();
        } else if (character == 10) {
            return _meanOne();
        } else if (character == 11) {
            return _miner();
        } else if (character == 12) {
            return _mrsClaus();
        } else if (character == 13) {
            return _noggleMan();
        } else if (character == 14) {
            return _noggleTree();
        } else if (character == 15) {
            return _nutcracker();
        } else if (character == 16) {
            return _partridge();
        } else if (character == 17) {
            return _ratKing();
        } else if (character == 18) {
            return _reindeerBasic();
        } else if (character == 19) {
            return _reindeerZoom();
        }
        return "";
    }

    function _mothertrucker() internal pure returns (string memory) {
        return '<rect x="9" y="7" width="5" height="5" fill="white"/>'
        '<rect x="10" y="3" width="3" height="5" fill="#F38B7C"/>'
        '<rect x="10" y="2" width="3" height="1" fill="#7C3C58"/>'
        '<rect x="9" y="3" width="1" height="1" fill="#7C3C58"/>'
        '<rect x="11" y="3" width="1" height="1" fill="#7C3C58"/>'
        '<rect x="13" y="3" width="1" height="1" fill="#7C3C58"/>'
        '<rect x="12" y="3" width="1" height="1" fill="#FF0E0E"/>'
        '<rect x="10" y="11" width="1" height="1" fill="#FF0E0E"/>'
        '<rect x="9" y="12" width="5" height="1" class="tintable"/>'
        '<rect x="9" y="13" width="2" height="8" class="tintable"/>'
        '<rect width="2" height="1" transform="matrix(1 0 0 -1 9 22)" fill="#F38B7C"/>'
        '<rect width="2" height="1" transform="matrix(1 0 0 -1 12 22)" fill="#F38B7C"/>'
        '<rect x="12" y="13" width="2" height="8" class="tintable"/>'
        '<rect x="15" y="8" width="1" height="9" fill="#F38B7C"/>'
        '<rect x="7" y="8" width="1" height="9" fill="#F38B7C"/>'
        '<rect x="9" y="7" width="1" height="1" fill="black"/>' '<rect x="10" y="8" width="1" height="1" fill="black"/>'
        '<rect x="11" y="9" width="1" height="1" fill="black"/>'
        '<rect x="12" y="10" width="1" height="1" fill="black"/>'
        '<rect x="13" y="11" width="1" height="1" fill="black"/>'
        '<rect x="13" y="4" width="1" height="1" fill="#FD5442"/>'
        '<rect x="9" y="4" width="1" height="1" fill="#FD5442"/>'
        '<rect x="11" y="8" width="1" height="1" fill="#F38B7C"/>';
    }

    function _girl() internal pure returns (string memory) {
        return '<rect x="6" y="3" width="10" height="9" fill="#F38B7C"/>'
        '<rect x="5" y="2" width="1" height="1" fill="#FF0E0E"/>'
        '<rect x="16" y="2" width="1" height="1" fill="#FF0E0E"/>'
        '<rect x="13" y="1" width="1" height="1" fill="#F0C14D"/>'
        '<rect x="9" y="1" width="1" height="1" fill="#F0C14D"/>'
        '<rect x="6" y="3" width="3" height="1" fill="#F0C14D"/>'
        '<rect x="10" y="3" width="1" height="1" fill="#F0C14D"/>'
        '<rect x="9" y="4" width="1" height="1" fill="#F0C14D"/>'
        '<rect x="6" y="4" width="1" height="1" fill="#F0C14D"/>'
        '<rect x="4" y="7" width="1" height="1" fill="#F0C14D"/>'
        '<rect x="5" y="5" width="1" height="2" fill="#F0C14D"/>'
        '<rect x="11" y="4" width="1" height="1" fill="#F0C14D"/>'
        '<rect x="18" y="3" width="1" height="1" fill="#F0C14D"/>'
        '<rect x="15" y="4" width="3" height="1" fill="#F0C14D"/>'
        '<rect x="12" y="3" width="4" height="1" fill="#F0C14D"/>'
        '<rect x="7" y="2" width="8" height="1" fill="#F0C14D"/>'
        '<rect x="6" y="1" width="1" height="2" fill="#FF0E0E"/>'
        '<rect x="15" y="1" width="1" height="2" fill="#FF0E0E"/>'
        '<rect x="7" y="12" width="8" height="1" fill="#F38B7C"/>'
        '<rect x="9" y="13" width="4" height="1" fill="#F38B7C"/>'
        '<rect x="10" y="14" width="2" height="1" fill="#F38B7C"/>'
        '<rect x="10" y="15" width="2" height="1" class="tintable"/>'
        '<rect x="9" y="16" width="4" height="5" class="tintable"/>'
        '<rect x="7" y="13" width="2" height="1" fill="#F0C14D"/>'
        '<rect x="13" y="13" width="2" height="1" fill="#F0C14D"/>'
        '<rect x="13" y="14" width="1" height="1" fill="#F0C14D"/>'
        '<rect x="15" y="14" width="1" height="1" fill="#F0C14D"/>'
        '<rect x="8" y="14" width="1" height="1" fill="#F0C14D"/>'
        '<rect x="6" y="14" width="1" height="1" fill="#F0C14D"/>'
        '<rect x="12" y="21" width="1" height="1" class="tintable"/>'
        '<rect x="10" y="21" width="1" height="1" class="tintable"/>'
        '<rect x="8" y="21" width="1" height="1" class="tintable"/>'
        '<rect x="7" y="18" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="14" y="18" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="17" y="14" width="1" height="1" fill="black"/>'
        '<rect x="18" y="16" width="1" height="1" fill="black"/>'
        '<rect x="18" y="13" width="1" height="1" fill="black"/>'
        '<rect x="17" y="17" width="3" height="1" fill="#FF0E0E"/>'
        '<rect x="17" y="21" width="3" height="1" fill="#FF0E0E"/>'
        '<rect x="16" y="18" width="5" height="3" fill="#FF0E0E"/>'
        '<rect x="19" y="14" width="1" height="2" fill="black"/>'
        '<rect x="7" y="16" width="1" height="2" class="tintable"/>'
        '<rect x="14" y="16" width="1" height="2" class="tintable"/>';
    }

    function _lamp() internal pure returns (string memory) {
        return '<rect x="9" y="3" width="7" height="1" fill="black"/>'
        '<rect x="9" y="4" width="7" height="6" class="tintable"/>'
        '<rect x="8" y="10" width="9" height="1" class="tintable"/>'
        '<rect x="7" y="11" width="1" height="1" class="tintable"/>'
        '<rect x="7" y="12" width="1" height="1" fill="black"/>'
        '<rect x="8" y="11" width="1" height="1" fill="black"/>'
        '<rect x="9" y="12" width="1" height="1" fill="black"/>'
        '<rect x="10" y="11" width="1" height="1" fill="black"/>'
        '<rect x="11" y="12" width="1" height="1" fill="black"/>'
        '<rect x="12" y="11" width="1" height="1" fill="black"/>'
        '<rect x="13" y="12" width="1" height="1" fill="black"/>'
        '<rect x="14" y="11" width="1" height="1" fill="black"/>'
        '<rect x="13" y="19" width="2" height="1" fill="black"/>'
        '<rect x="11" y="21" width="2" height="1" fill="black"/>'
        '<rect x="12" y="20" width="3" height="1" fill="black"/>'
        '<rect x="14" y="12" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="13" y="18" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="12" y="12" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="10" y="12" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="11" y="13" width="4" height="1" fill="#F38B7C"/>'
        '<rect x="11" y="14" width="3" height="1" fill="#F38B7C"/>'
        '<rect x="13" y="17" width="2" height="1" fill="#F38B7C"/>'
        '<rect x="12" y="15" width="3" height="2" fill="#F38B7C"/>'
        '<rect x="15" y="12" width="1" height="1" fill="black"/>'
        '<rect x="14" y="21" width="1" height="1" fill="black"/>'
        '<rect x="16" y="11" width="1" height="1" fill="black"/>'
        '<rect x="17" y="12" width="1" height="1" fill="black"/>'
        '<rect x="9" y="11" width="1" height="1" class="tintable"/>'
        '<rect x="11" y="11" width="1" height="1" class="tintable"/>'
        '<rect x="13" y="11" width="1" height="1" class="tintable"/>'
        '<rect x="15" y="11" width="1" height="1" class="tintable"/>'
        '<rect x="17" y="11" width="1" height="1" class="tintable"/>';
    }

    function _meanOne() internal pure returns (string memory) {
        return '<rect x="12" y="2" width="1" height="1" fill="#369F49"/>'
        '<rect x="10" y="11" width="1" height="1" fill="black"/>'
        '<rect x="10" y="20" width="1" height="1" fill="black"/>'
        '<rect x="12" y="20" width="1" height="1" fill="black"/>'
        '<rect x="12" y="21" width="2" height="1" fill="black"/>'
        '<rect x="9" y="21" width="2" height="1" fill="black"/>'
        '<rect x="12" y="11" width="1" height="1" fill="black"/>'
        '<rect x="11" y="11" width="1" height="1" fill="white"/>'
        '<rect x="6" y="15" width="1" height="1" fill="white"/>'
        '<rect x="16" y="15" width="1" height="1" fill="white"/>'
        '<rect x="12" y="19" width="1" height="1" fill="white"/>'
        '<rect x="10" y="19" width="1" height="1" fill="white"/>'
        '<rect x="11" y="3" width="1" height="1" fill="#369F49"/>'
        '<rect x="16" y="16" width="1" height="1" fill="#369F49"/>'
        '<rect x="6" y="16" width="1" height="1" fill="#369F49"/>'
        '<rect x="10" y="4" width="3" height="3" fill="#369F49"/>'
        '<rect x="7" y="8" width="1" height="4" class="tintable"/>'
        '<rect x="6" y="12" width="1" height="3" class="tintable"/>'
        '<rect x="16" y="12" width="1" height="3" class="tintable"/>'
        '<rect x="15" y="8" width="1" height="4" class="tintable"/>'
        '<rect x="12" y="12" width="1" height="7" class="tintable"/>'
        '<rect x="10" y="12" width="1" height="7" class="tintable"/>'
        '<rect x="11" y="12" width="1" height="1" class="tintable"/>'
        '<rect x="10" y="7" width="3" height="4" class="tintable"/>';
    }

    function _miner() internal pure returns (string memory) {
        return '<rect x="8" y="15" width="9" height="2" fill="#16786C"/>'
        '<rect x="4" y="9" width="4" height="7" fill="#16786C"/>'
        '<rect x="9" y="11" width="8" height="3" fill="#16786C"/>'
        '<rect x="9" y="6" width="7" height="2" fill="#F38B7C"/>'
        '<rect x="12" y="2" width="1" height="1" class="tintable"/>'
        '<rect x="6" y="6" width="1" height="1" fill="#CB7300"/>'
        '<rect x="7" y="7" width="1" height="1" fill="#CB7300"/>'
        '<rect x="8" y="11" width="1" height="3" fill="#7C3C58"/>'
        '<rect x="17" y="11" width="1" height="3" fill="#7C3C58"/>'
        '<rect x="17" y="7" width="1" height="1" fill="#CB7300"/>'
        '<rect x="7" y="8" width="11" height="3" fill="#CB7300"/>'
        '<rect x="18" y="6" width="1" height="1" fill="#CB7300"/>'
        '<rect x="18" y="16" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="5" y="16" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="10" y="7" width="1" height="1" fill="black"/>'
        '<rect x="8" y="14" width="3" height="1" fill="black"/>'
        '<rect x="14" y="14" width="2" height="1" fill="black"/>'
        '<rect x="12" y="14" width="1" height="1" fill="black"/>'
        '<rect x="8" y="21" width="3" height="1" fill="black"/>'
        '<rect x="9" y="20" width="1" height="1" fill="black"/>'
        '<rect x="12" y="20" width="1" height="1" fill="black"/>'
        '<rect x="12" y="21" width="3" height="1" fill="black"/>'
        '<rect x="12" y="13" width="1" height="1" fill="white"/>'
        '<rect x="13" y="14" width="1" height="1" fill="white"/>'
        '<rect x="11" y="14" width="1" height="1" fill="white"/>'
        '<rect x="12" y="15" width="1" height="1" fill="white"/>'
        '<rect x="14" y="7" width="1" height="1" fill="black"/>'
        '<rect x="9" y="5" width="7" height="1" class="tintable"/>'
        '<rect x="10" y="3" width="5" height="2" class="tintable"/>'
        '<rect x="18" y="9" width="2" height="2" fill="#16786C"/>'
        '<rect x="8" y="18" width="3" height="2" fill="#16786C"/>'
        '<rect x="12" y="18" width="3" height="2" fill="#16786C"/>'
        '<rect x="18" y="11" width="3" height="5" fill="#16786C"/>';
    }

    function _mrsClaus() internal pure returns (string memory) {
        return '<rect x="8" y="4" width="7" height="2" class="tintable"/>'
        '<rect x="7" y="9" width="9" height="2" fill="#FF0E0E"/>'
        '<rect x="7" y="14" width="9" height="5" fill="#FF0E0E"/>'
        '<rect x="10" y="2" width="3" height="1" class="tintable"/>'
        '<rect x="7" y="3" width="1" height="1" class="tintable"/>'
        '<rect x="7" y="6" width="1" height="1" class="tintable"/>'
        '<rect x="9" y="6" width="1" height="1" class="tintable"/>'
        '<rect x="13" y="6" width="1" height="1" class="tintable"/>'
        '<rect x="11" y="4" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="10" y="5" width="3" height="4" fill="#F38B7C"/>'
        '<rect x="15" y="3" width="1" height="1" class="tintable"/>'
        '<rect x="9" y="3" width="5" height="1" class="tintable"/>'
        '<rect x="8" y="11" width="7" height="1" fill="#FF0E0E"/>'
        '<rect x="8" y="13" width="7" height="1" fill="#FF0E0E"/>'
        '<rect x="16" y="11" width="1" height="2" fill="#FF0E0E"/>'
        '<rect x="6" y="11" width="1" height="2" fill="#FF0E0E"/>'
        '<rect x="5" y="13" width="1" height="1" fill="white"/>'
        '<rect x="7" y="19" width="9" height="1" fill="white"/>'
        '<rect x="17" y="13" width="1" height="1" fill="white"/>'
        '<rect x="11" y="12" width="1" height="1" fill="white"/>'
        '<rect x="12" y="12" width="2" height="1" fill="black"/>'
        '<rect x="9" y="12" width="2" height="1" fill="black"/>'
        '<rect x="9" y="20" width="2" height="1" fill="black"/>'
        '<rect x="12" y="20" width="2" height="1" fill="black"/>'
        '<rect x="12" y="21" width="3" height="1" fill="black"/>'
        '<rect x="8" y="21" width="3" height="1" fill="black"/>'
        '<rect x="5" y="14" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="17" y="14" width="1" height="1" fill="#F38B7C"/>';
    }

    function _noggleMan() internal pure returns (string memory) {
        return '<rect x="8" y="1" width="8" height="1" class="tintable"/>'
        '<rect x="8" y="8" width="8" height="1" class="tintable"/>'
        '<rect x="8" y="10" width="8" height="1" class="tintable"/>'
        '<rect x="8" y="17" width="8" height="1" class="tintable"/>'
        '<rect x="11" y="21" width="4" height="1" class="tintable"/>'
        '<rect x="11" y="18" width="1" height="4" class="tintable"/>'
        '<rect x="11" y="9" width="1" height="1" class="tintable"/>'
        '<rect x="8" y="2" width="1" height="6" class="tintable"/>'
        '<rect x="15" y="2" width="1" height="6" class="tintable"/>'
        '<rect x="15" y="11" width="1" height="6" class="tintable"/>'
        '<rect x="8" y="11" width="1" height="6" class="tintable"/>'
        '<rect x="9" y="11" width="6" height="3" fill="#08030D"/>'
        '<rect x="9" y="2" width="6" height="3" fill="#08030D"/>'
        '<rect x="9" y="14" width="6" height="3" fill="#F9F4F2"/>'
        '<rect x="9" y="5" width="6" height="3" fill="#F9F4F2"/>';
    }

    function _noggleTree() internal pure returns (string memory) {
        return '<rect x="9" y="4" width="6" height="1" fill="black"/>'
        '<rect x="10" y="5" width="2" height="1" fill="black"/>'
        '<rect x="13" y="5" width="2" height="1" fill="black"/>'
        '<rect x="6" y="10" width="6" height="1" class="tintable"/>'
        '<rect x="4" y="16" width="8" height="1" fill="#4AB49A"/>'
        '<rect x="4" y="23" width="8" height="1" fill="#4AB49A"/>'
        '<rect x="13" y="16" width="8" height="1" fill="#4AB49A"/>'
        '<rect x="13" y="23" width="8" height="1" fill="#4AB49A"/>'
        '<rect x="6" y="15" width="6" height="1" class="tintable"/>'
        '<rect x="13" y="10" width="6" height="1" class="tintable"/>'
        '<rect x="13" y="15" width="6" height="1" class="tintable"/>'
        '<rect x="18" y="11" width="1" height="4" class="tintable"/>'
        '<rect x="13" y="11" width="1" height="4" class="tintable"/>'
        '<rect x="11" y="11" width="1" height="4" class="tintable"/>'
        '<rect x="6" y="11" width="1" height="4" class="tintable"/>'
        '<rect x="12" y="12" width="1" height="1" class="tintable"/>'
        '<rect x="3" y="12" width="3" height="1" class="tintable"/>'
        '<rect width="1" height="2" transform="matrix(-1 0 0 1 4 13)" class="tintable"/>'
        '<rect x="20" y="17" width="1" height="6" fill="#4AB49A"/>'
        '<rect x="13" y="17" width="1" height="6" fill="#4AB49A"/>'
        '<rect x="11" y="17" width="1" height="6" fill="#4AB49A"/>'
        '<rect width="3" height="6" transform="matrix(-1 0 0 1 11 17)" fill="#08030D"/>'
        '<rect width="3" height="6" transform="matrix(-1 0 0 1 20 17)" fill="#08030D"/>'
        '<rect width="2" height="4" transform="matrix(-1 0 0 1 18 11)" fill="#08030D"/>'
        '<rect width="2" height="4" transform="matrix(-1 0 0 1 11 11)" fill="#08030D"/>'
        '<rect width="2" height="4" transform="matrix(-1 0 0 1 9 11)" fill="#F9F4F2"/>'
        '<rect width="2" height="4" transform="matrix(-1 0 0 1 16 11)" fill="#F9F4F2"/>'
        '<rect width="3" height="6" transform="matrix(-1 0 0 1 17 17)" fill="#F9F4F2"/>'
        '<rect width="3" height="6" transform="matrix(-1 0 0 1 8 17)" fill="#F9F4F2"/>'
        '<rect x="4" y="17" width="1" height="6" fill="#4AB49A"/>'
        '<rect x="12" y="19" width="1" height="1" fill="#4AB49A"/>' '<rect y="19" width="4" height="1" fill="#4AB49A"/>'
        '<rect y="20" width="1" height="3" fill="#4AB49A"/>';
    }

    function _nutcracker() internal pure returns (string memory) {
        return '<rect x="11" y="1" width="1" height="1" fill="#CB7300"/>'
        '<rect x="10" y="6" width="3" height="2" fill="white"/>'
        '<rect x="9" y="2" width="5" height="4" fill="#08030D"/>'
        '<rect x="11" y="3" width="1" height="1" class="tintable"/>'
        '<rect x="10" y="12" width="1" height="1" fill="black"/>'
        '<rect x="12" y="12" width="1" height="1" fill="black"/>'
        '<rect x="14" y="14" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="13" y="17" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="9" y="17" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="9" y="19" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="13" y="19" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="12" y="21" width="2" height="1" fill="black"/>'
        '<rect x="9" y="21" width="2" height="1" fill="black"/>'
        '<rect x="14" y="15" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="8" y="14" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="10" y="14" width="1" height="2" fill="#2A46FF"/>'
        '<rect x="10" y="16" width="1" height="5" fill="black"/>'
        '<rect x="12" y="16" width="1" height="5" fill="black"/>'
        '<rect x="12" y="14" width="1" height="2" fill="#2A46FF"/>'
        '<rect x="8" y="15" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="11" y="8" width="1" height="3" fill="white"/>'
        '<rect x="10" y="8" width="1" height="3" class="tintable"/>'
        '<rect x="12" y="8" width="1" height="3" class="tintable"/>'
        '<rect x="14" y="8" width="1" height="6" class="tintable"/>'
        '<rect x="8" y="8" width="1" height="6" class="tintable"/>'
        '<rect width="3" height="1" transform="matrix(1 0 0 -1 10 12)" class="tintable"/>'
        '<rect width="3" height="1" transform="matrix(1 0 0 -1 10 14)" class="tintable"/>'
        '<rect x="11" y="12" width="1" height="1" fill="#F0C14D"/>';
    }

    function _partridge() internal pure returns (string memory) {
        return '<rect x="11" y="2" width="2" height="1" fill="#16786C"/>'
        '<rect x="16" y="4" width="1" height="1" fill="#16786C"/>'
        '<rect x="7" y="4" width="7" height="1" fill="#16786C"/>'
        '<rect x="7" y="5" width="10" height="2" fill="#16786C"/>'
        '<rect x="6" y="7" width="12" height="2" fill="#16786C"/>'
        '<rect x="7" y="9" width="10" height="3" fill="#16786C"/>'
        '<rect x="8" y="3" width="6" height="1" fill="#16786C"/>'
        '<rect x="8" y="12" width="8" height="1" fill="#16786C"/>'
        '<rect x="11" y="13" width="2" height="1" fill="#16786C"/>'
        '<rect x="10" y="4" width="1" height="1" fill="#369F49"/>'
        '<rect x="15" y="2" width="1" height="1" fill="#453F41"/>'
        '<rect x="16" y="2" width="1" height="1" fill="#FD5442"/>'
        '<rect x="14" y="3" width="2" height="2" fill="#453F41"/>'
        '<rect x="17" y="9" width="1" height="1" fill="#369F49"/>'
        '<rect x="12" y="10" width="1" height="1" fill="#369F49"/>'
        '<rect x="14" y="13" width="1" height="1" fill="#369F49"/>'
        '<rect x="12" y="21" width="2" height="1" fill="black"/>'
        '<rect x="9" y="21" width="2" height="1" fill="black"/>'
        '<rect x="10" y="13" width="1" height="8" class="tintable"/>'
        '<rect x="12" y="14" width="1" height="7" class="tintable"/>'
        '<rect x="8" y="11" width="1" height="1" fill="#369F49"/>';
    }

    function _ratKing() internal pure returns (string memory) {
        return '<rect x="7" y="2" width="1" height="3" class="tintable"/>'
        '<rect x="8" y="2" width="1" height="1" class="tintable"/>'
        '<rect x="8" y="3" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="10" y="2" width="1" height="2" fill="#CB7300"/>'
        '<rect x="12" y="2" width="1" height="2" fill="#CB7300"/>'
        '<rect x="11" y="3" width="1" height="1" fill="#CB7300"/>'
        '<rect x="11" y="4" width="1" height="1" fill="black"/>'
        '<rect x="12" y="11" width="1" height="1" fill="black"/>'
        '<rect x="10" y="11" width="1" height="1" fill="black"/>'
        '<rect x="14" y="8" width="1" height="1" fill="black"/>'
        '<rect x="15" y="9" width="1" height="1" fill="black"/>'
        '<rect x="16" y="10" width="1" height="1" fill="black"/>'
        '<rect x="17" y="11" width="1" height="1" fill="black"/>'
        '<rect x="18" y="10" width="1" height="1" fill="black"/>'
        '<rect x="20" y="9" width="1" height="1" fill="black"/>'
        '<rect x="20" y="3" width="1" height="4" fill="black"/>'
        '<rect x="19" y="7" width="3" height="1" fill="black"/>'
        '<rect x="15" y="3" width="1" height="1" fill="black"/>'
        '<rect x="8" y="4" width="1" height="1" class="tintable"/>'
        '<rect x="10" y="4" width="1" height="1" class="tintable"/>'
        '<rect x="12" y="4" width="3" height="1" class="tintable"/>'
        '<rect width="1" height="1" transform="matrix(-1 0 0 1 21 8)" class="tintable"/>'
        '<rect width="1" height="1" transform="matrix(-1 0 0 1 20 9)" fill="white"/>'
        '<rect x="9" y="5" width="5" height="1" class="tintable"/>'
        '<rect x="10" y="6" width="3" height="1" class="tintable"/>'
        '<rect x="9" y="2" width="1" height="3" class="tintable"/>'
        '<rect x="9" y="7" width="2" height="1" fill="#FF0E0E"/>'
        '<rect x="13" y="14" width="2" height="1" fill="#FF0E0E"/>'
        '<rect x="13" y="15" width="1" height="1" fill="#FF0E0E"/>'
        '<rect x="13" y="9" width="2" height="1" fill="#FF0E0E"/>'
        '<rect x="12" y="10" width="4" height="1" fill="#FF0E0E"/>'
        '<rect x="13" y="11" width="4" height="2" fill="#FF0E0E"/>'
        '<rect x="13" y="13" width="3" height="1" fill="#FF0E0E"/>'
        '<rect x="13" y="7" width="1" height="2" fill="#FF0E0E"/>'
        '<rect x="11" y="13" width="1" height="3" fill="#FF0E0E"/>'
        '<rect x="11" y="8" width="1" height="2" fill="#FF0E0E"/>'
        '<rect x="9" y="8" width="1" height="4" fill="#FF0E0E"/>'
        '<rect x="7" y="9" width="1" height="3" fill="#FF0E0E"/>'
        '<rect x="6" y="10" width="1" height="6" fill="#FF0E0E"/>'
        '<rect x="8" y="12" width="1" height="4" fill="#FF0E0E"/>'
        '<rect x="11" y="13" width="1" height="3" fill="#FF0E0E"/>'
        '<rect x="9" y="12" width="1" height="6" fill="#F38B7C"/>'
        '<rect x="5" y="10" width="1" height="5" fill="#FF0E0E"/>'
        '<rect x="4" y="11" width="1" height="4" fill="#FF0E0E"/>'
        '<rect x="3" y="11" width="1" height="3" fill="#FF0E0E"/>'
        '<rect x="2" y="12" width="1" height="1" fill="#FF0E0E"/>'
        '<rect x="8" y="8" width="1" height="4" fill="black"/>' '<rect x="7" y="12" width="1" height="3" fill="black"/>'
        '<rect x="11" y="7" width="2" height="1" fill="white"/>'
        '<rect x="7" y="15" width="1" height="1" fill="white"/>'
        '<rect x="7" y="16" width="1" height="1" class="tintable"/>'
        '<rect x="8" y="18" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="5" y="18" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="6" y="19" width="2" height="1" fill="#F38B7C"/>'
        '<rect x="10" y="12" width="3" height="1" fill="#CB7300"/>'
        '<rect x="12" y="8" width="1" height="2" fill="white"/>'
        '<rect width="1" height="2" transform="matrix(1 0 0 -1 11 12)" fill="white"/>'
        '<rect width="1" height="3" transform="matrix(1 0 0 -1 10 11)" fill="white"/>'
        '<rect x="10" y="13" width="1" height="4" fill="#CB7300"/>'
        '<rect x="10" y="17" width="1" height="4" fill="#FF0E0E"/>'
        '<rect x="12" y="17" width="1" height="4" fill="#FF0E0E"/>'
        '<rect x="12" y="13" width="1" height="4" fill="#CB7300"/>'
        '<rect x="9" y="21" width="2" height="1" fill="#FF0E0E"/>'
        '<rect x="12" y="21" width="2" height="1" fill="#FF0E0E"/>';
    }

    function _reindeerBasic() internal pure returns (string memory) {
        return '<rect x="9" y="5" width="5" height="2" class="tintable"/>'
        '<rect x="9" y="2" width="1" height="1" fill="#CB7300"/>'
        '<rect x="10" y="3" width="1" height="1" fill="#CB7300"/>'
        '<rect x="10" y="5" width="1" height="1" fill="#08030D"/>'
        '<rect x="12" y="5" width="1" height="1" fill="#08030D"/>'
        '<rect x="8" y="4" width="7" height="1" class="tintable"/>'
        '<rect x="9" y="7" width="10" height="1" class="tintable"/>'
        '<rect x="7" y="8" width="1" height="9" class="tintable"/>'
        '<rect x="15" y="9" width="1" height="8" class="tintable"/>'
        '<rect x="11" y="9" width="1" height="3" fill="#513340"/>'
        '<rect x="11" y="8" width="8" height="1" fill="#513340"/>'
        '<rect x="9" y="8" width="2" height="13" class="tintable"/>'
        '<rect x="12" y="9" width="2" height="12" class="tintable"/>'
        '<rect x="11" y="2" width="1" height="1" fill="#CB7300"/>'
        '<rect x="12" y="3" width="1" height="1" fill="#CB7300"/>'
        '<rect x="13" y="2" width="1" height="1" fill="#CB7300"/>'
        '<rect x="19" y="6" width="1" height="1" fill="#FF0E0E"/>'
        '<rect x="15" y="17" width="1" height="1" fill="black"/>'
        '<rect x="7" y="17" width="1" height="1" fill="black"/>'
        '<rect x="9" y="21" width="2" height="1" fill="black"/>'
        '<rect x="12" y="21" width="2" height="1" fill="black"/>';
    }

    function _reindeerZoom() internal pure returns (string memory) {
        return '<rect x="9" y="1" width="1" height="1" fill="#CB7300"/>'
        '<rect x="11" y="1" width="1" height="1" fill="#CB7300"/>'
        '<rect x="13" y="1" width="1" height="1" fill="#CB7300"/>'
        '<rect x="12" y="3" width="1" height="1" fill="#CB7300"/>'
        '<rect x="8" y="3" width="1" height="1" fill="#CB7300"/>'
        '<rect x="9" y="4" width="1" height="1" fill="#CB7300"/>'
        '<rect x="13" y="4" width="1" height="1" fill="#CB7300"/>'
        '<rect x="13" y="7" width="1" height="1" fill="black"/>'
        '<rect x="7" y="5" width="8" height="1" fill="#36262D"/>'
        '<rect x="5" y="6" width="10" height="1" fill="#36262D"/>'
        '<rect x="4" y="7" width="11" height="1" fill="#36262D"/>'
        '<rect x="7" y="8" width="13" height="3" fill="#36262D"/>'
        '<rect x="15" y="1" width="1" height="1" fill="#CB7300"/>'
        '<rect x="14" y="2" width="1" height="2" fill="#CB7300"/>'
        '<rect x="10" y="2" width="1" height="2" fill="#CB7300"/>'
        '<rect x="13" y="7" width="1" height="1" fill="black"/>'
        '<rect width="2" height="2" transform="matrix(-1 0 0 1 21 6)" class="tintable"/>'
        '<rect x="10" y="11" width="9" height="1" fill="black"/>'
        '<rect x="10" y="12" width="8" height="1" fill="#513340"/>'
        '<rect width="3" height="11" transform="matrix(1 0 0 -1 10 24)" fill="#513340"/>'
        '<rect x="11" y="7" width="1" height="1" fill="black"/>'
        '<rect x="7" y="11" width="3" height="13" fill="#36262D"/>'
        '<rect x="7" y="24" width="7" height="6" transform="rotate(-180 7 24)" fill="#36262D"/>';
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ICharacterSVGRenderer {
    function characterSVG(uint8 character) external pure returns (string memory);
}