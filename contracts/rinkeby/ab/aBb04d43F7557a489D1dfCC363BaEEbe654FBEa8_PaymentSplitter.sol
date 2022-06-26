// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PaymentSplitter  {
    address payable[] public recepients;

    constructor(address payable[] memory _addresses){
        for(uint i=0; i < _addresses.length; i++){
            recepients.push(_addresses[i]);
        }
    }

    receive() payable external {
        uint256 share = msg.value / recepients.length;
        for(uint i=0; i < recepients.length; i++){
            recepients[i].transfer(share);
        }
    }
}