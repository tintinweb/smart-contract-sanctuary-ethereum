/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Foo {
    function foo() external pure returns (uint256) {
        return 123;
    }    
}

contract Factory {
    event Deployed(address);

    function deploy() external {
        Foo a = new Foo();
        emit Deployed(address(a));
    }
}