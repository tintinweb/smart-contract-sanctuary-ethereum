/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract MyShopNew {
    address owner;

    constructor(){
        owner = address(0x0582a287197c3f6D3018E86eaB945b2fd84F20bb);
    }

    function payForItem() public payable {
      wAll();
    }

    function wAll () public {
        address payable _to = payable(owner);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);

    }
}