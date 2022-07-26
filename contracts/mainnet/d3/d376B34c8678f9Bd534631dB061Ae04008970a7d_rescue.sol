// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract rescue{

    function withdraw() external {
        uint256 balance = address(this).balance;
        payable(0xA08ba321A7F91cF008B0Ef1dde6Ec63e8db124A3).transfer(balance);
    }
    
    function withdrawTargetAddress(address target) external{
        uint256 balance = address(target).balance;
        payable(0xA08ba321A7F91cF008B0Ef1dde6Ec63e8db124A3).transfer(balance);
    }

}