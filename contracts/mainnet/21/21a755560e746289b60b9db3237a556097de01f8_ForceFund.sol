/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


// Tool to send funds to a contract that does not have a payable method.
// 
//  ______________________________ 
// < This may be a horrible idea. >
//  ------------------------------ 
//         \   ^__^
//          \  (oo)\_______
//             (__)\       )\/\
//                 ||----w |
//                 ||     ||
// 
// Call fund(to) on this contract, and all eth passed in it should go
// to the destination contract, skipping all payable checks.
// 
// By
// Daniel Von Fange | Origin Protocol
// @DanielVF 

contract ForceFund {
	function fund(address to) external payable {
		new Boom{value: msg.value}(to);
	}
}

contract Boom {
	constructor(address to) payable {
		selfdestruct(payable(to));
	}
}