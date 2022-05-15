/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract MyContract {
    function _isEven(uint256 number) private pure returns (bool) {
        if(number % 2 == 0) {
            return true;
        }

        return false;
    }

    function payMeBack(uint256 number) external payable {
        require(number != 9, "We dont want 9");
        bool result = _isEven(number);

        if(result) {
            uint256 ethRefund = msg.value / 2;
            payable(msg.sender).transfer(ethRefund);
        } else {
            payable(msg.sender).transfer(msg.value);
        }

    }
}