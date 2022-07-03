/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Something {
    function _createRandomNumber() private pure returns(uint) {
        return 2;
    }

    function payBackLess() public payable {
        uint randomNumber = _createRandomNumber();
        
        // if (randomNumber > 1) {
        //     revert("mivan");
        // }
        require(randomNumber < 1, "miafaszvan");

        uint received = msg.value;
        uint refund = received / randomNumber;
        payable(msg.sender).transfer(refund);
    }
}