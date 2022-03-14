// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract SVGFiles{
    string[12] public svgFiles;
    function setSVGFiles(uint256[] memory seq,string[] memory _svg) public {
        for (uint256 i=0; i < seq.length; ++i) {
            svgFiles[seq[i]] = _svg[i];
        }
    }
}