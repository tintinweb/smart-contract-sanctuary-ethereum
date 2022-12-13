/**
 *Submitted for verification at Etherscan.io on 2022-12-13
*/

// SPDX-License-Identifier: MIT
pragma solidity  >=0.5.0 <0.8.0; 

contract MyContract {

    function _getRandomNumber(uint eth) private pure returns(uint) {
        return eth;
    }

    function payMe() external payable {
        uint256 etherRefund;
        uint256 givenNumber = _getRandomNumber(msg.value);
        require(givenNumber != 9, "We hate fucking 9 number.");
        if (givenNumber % 2 == 0 ){
            etherRefund = msg.value / 2;
        } else {
            etherRefund = msg.value;
        }
        payable(msg.sender).transfer(etherRefund);
    }
}