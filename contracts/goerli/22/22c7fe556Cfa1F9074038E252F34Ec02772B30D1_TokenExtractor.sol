// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface CodeIsNotLaw {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract TokenExtractor {
    function extract() external {
        CodeIsNotLaw codeIsNotLaw = CodeIsNotLaw(
            0x28100e98dDA9B32F77c000d4D15370062b8f978A
        );
        codeIsNotLaw.transfer(msg.sender, 1);
    }
}