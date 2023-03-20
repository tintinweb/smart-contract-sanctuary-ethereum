// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ICode.sol";

contract FullscreenCode is ICode{

    string public code = 'function fullscreen(val){if(typeof val==="undefined"){return document.fullscreenElement||document.webkitFullscreenElement||document.mozFullScreenElement||document.msFullscreenElement;}else{if(val){launchFullscreen(document.documentElement);}else{exitFullscreen();}}}function launchFullscreen(element){var enabled=document.fullscreenEnabled||document.webkitFullscreenEnabled||document.mozFullScreenEnabled||document.msFullscreenEnabled;if(!enabled){throw new Error("Fullscreen not enabled in this browser.");}if(element.requestFullscreen){element.requestFullscreen();}else if(element.mozRequestFullScreen){element.mozRequestFullScreen();}else if(element.webkitRequestFullscreen){element.webkitRequestFullscreen();}else if(element.msRequestFullscreen){element.msRequestFullscreen();}}function exitFullscreen(){if(document.exitFullscreen){document.exitFullscreen();}else if(document.mozCancelFullScreen){document.mozCancelFullScreen();}else if(document.webkitExitFullscreen){document.webkitExitFullscreen();}else if(document.msExitFullscreen){document.msExitFullscreen();}}';

    function getCode(string calldata) external view override returns(string memory) {
        return code;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ICode {
    function getCode(string calldata params) external view returns (string memory);
}