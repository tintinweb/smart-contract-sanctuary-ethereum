/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Splitter
 * @dev Splits all received payments in two
 */
contract Splitter {

    address payable address1 = payable(0xa58B2ad34401D31bc31B8c869F480FB4A05EBCa0);
    address payable address2 = payable(0x4Adb431014D0fBD3d4D6f778e1019bc20F4cc050);
    uint splitPercent = 60;

    /**
     * @dev Splits received payment in two accounts
     */
     receive() external payable {

         uint256 totalAmount = msg.value;
         uint256 amount1 = msg.value * splitPercent / 100;
         uint256 amount2 = totalAmount - amount1;

         address1.transfer(amount1);
         address2.transfer(amount2);
     }

}