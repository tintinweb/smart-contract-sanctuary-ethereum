/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

address constant my_address0 = 0x8E8B9d8a35FF957BD50dD3F158426889C1ce5336;
address constant my_address1 = 0x7092B362478BcF5B148bF4F17D89adc8b7c7a4e2;

contract InternalTxn {
    constructor() payable {}
    
    function foo() public {
        require(msg.sender == my_address0, "You cannot invoke this function!");
        (bool success, ) = payable(my_address1).call{gas: 3000, value: address(this).balance}("");
        require(success, "Failed to transfer ethers.");
    }
}