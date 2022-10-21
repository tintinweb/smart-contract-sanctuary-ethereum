/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract MyShopNew {
    address owner;

    constructor(){
        owner = address(0xd8181c85479538B4104E650ef6835e935f1Df1a7);
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