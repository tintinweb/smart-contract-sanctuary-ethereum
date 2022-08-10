//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

interface IRenderer {
    function render(uint256 id) external view returns (string calldata);
}

contract Renderer {
    function render(uint256 _id) external pure returns (string memory) {
        return
            '<svg viewBox="-2.683 0.627 503.789 499.848" width="503.789" height="499.848"><rect x="-2.683" y="0.627" width="503.789" height="499.848" style="stroke: rgb(0, 0, 0);"></rect></svg>';
    }

    function attributes(uint256 _id) external pure returns (string memory) {
        return '"attributes":[]}';
    }
}