/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;
contract A {
    uint a;
    uint b;
    uint c;

    function getData() public view returns(uint,uint,uint) {
        return (a,b,c);
    }

    function addA(uint k) external {
        a= k;
    }

    function addB(uint k) external {
        b= k;
    }

    function addc(uint k) payable external {
        c= k;
    }

     function addK(uint k) payable external {
        c= k;
    }

    receive() external payable {
        // React to receiving ether
    }
}