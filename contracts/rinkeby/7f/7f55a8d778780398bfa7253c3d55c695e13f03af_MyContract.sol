/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract MyContract {

    function _isNine(uint num) internal pure returns (bool) {
        if (num == 9) {
            return true;
            } else {
            return false;
            }
    }

    function _isEven(uint num) internal pure returns (bool) {
        if (num % 2 == 0) { 
            return true;
            } else {
            return false;
            }
    }

    function paybackWithNum(uint num) external payable {
        if (_isNine(num)) {
            revert("We don't like 9!");
        }
        if (_isEven(num)) {
            payable(msg.sender).transfer(msg.value / 2);
        } else {
            payable(msg.sender).transfer(msg.value);
        }
    }

}