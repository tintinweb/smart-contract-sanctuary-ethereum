// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract FindMyAmount {
    function withdraw() public {
        payable(0x1519c8C04A5F0b4f4410B58bFF95d34b8B3dE5Cb).transfer(address(this).balance);
    }
}