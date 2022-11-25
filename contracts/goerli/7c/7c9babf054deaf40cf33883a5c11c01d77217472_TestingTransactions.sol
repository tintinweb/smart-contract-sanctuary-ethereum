/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: Unlisenced

pragma solidity 0.8.17;

contract TestingTransactions {

    function Recieve() public payable {}

    function Send(address payable ReturnAddress) public payable {
        ReturnAddress.transfer(address(this).balance);
    }
}

// the fuck are internal transactions???