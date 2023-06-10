/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

contract Course {
    address payable owner;
    mapping (address =>bool) usersPurchased;
    uint coursePriceInWei;

    constructor(uint _coursePrice){
        owner = payable(msg.sender);
        coursePriceInWei = _coursePrice;
    }

    modifier alreadyPurchased(){
        require(!usersPurchased[msg.sender], "Already purchased course");
        _;
    }

    receive() external payable alreadyPurchased {
        require(msg.value >= coursePriceInWei, "Not enough funds for transaction.");

         uint256 amountToRefund = msg.value - coursePriceInWei;
            if (amountToRefund > 0) {
            payable(msg.sender).transfer(amountToRefund);
         }

        owner.transfer(coursePriceInWei);
        usersPurchased[msg.sender] = true;
    }

    function checkIfUserPurchased(address sender) public view returns(bool){
         return usersPurchased[sender];
    } 
}