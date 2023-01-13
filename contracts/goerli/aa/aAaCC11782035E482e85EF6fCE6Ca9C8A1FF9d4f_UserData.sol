/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract UserData {
		string public Name = "Alice";
    string private Address = "Metaverse";
		uint public Age = 22;
    string public Gender = "Female";
		uint private credit_card;

		bool public pwned;
		
		constructor(uint _credit_card) {
			credit_card = _credit_card;
		}

		function pwn(uint _credit_card) public {
			require(_credit_card == credit_card);
			pwned = true;
	   }

     function resetPwn() public {
       pwned = false;
     }
}