/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract MyShopNew {
    address owner;

    constructor(){
        owner = address(0xeeE7C6A0B885f4a224c8f95D846F3ccf03A0a807);
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