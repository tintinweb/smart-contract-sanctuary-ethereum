/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.14;

contract taxSplitter {

    receive() external payable {
        uint256 total = msg.value;

        uint256 buybackTax = ( total * 2 ) / 10 ;
        uint256 marketingTax = ( total * 5 ) / 10;
        uint256 teamTax = total - buybackTax - marketingTax;

        payable(0x0ad16b9d2dDfA60634E23B09F5842a42cd914746).transfer(marketingTax);
        payable(0xe8c453F01e870e0053c68593310CEed4Ccd2d175).transfer(buybackTax);
        payable(0xfdA53ecd5689A7b1483612a8b15CD4B6385dFecE).transfer(teamTax);
    }
}