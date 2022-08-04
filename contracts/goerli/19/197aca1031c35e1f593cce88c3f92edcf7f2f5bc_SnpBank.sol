/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// SPDX-License-Identifire:UNLICENSED

pragma solidity ^0.7.0;

contract SnpBank {
    // mapping from a user to its balance
    mapping (address => uint256) private funds;
    // total funds in the bank
	uint256  totalFunds;

    // deposit amount into snpbank and update the user's balance in the bank accordingly
    function deposit(uint256 amount) public payable {
		funds[msg.sender] += amount;
		totalFunds += amount;
    }

    // 
    function transfer(address to, uint256 amount) public {
		require(funds[msg.sender] > amount);
		uint256 fundsTo = funds[to];
		funds[msg.sender] -= amount;
		funds[to] = fundsTo + amount;		
    }

    // withdraw the total balance of user into its personal wallet address
    function withdraw() public returns (bool success)  {
		uint256 amount = getFunds(msg.sender);
		funds[msg.sender] = 0;
		success = msg.sender.send(amount);
		totalFunds -=amount;
    }

    // retrieves the user's recorded balance in the bank
	function getFunds(address account) public view returns (uint256) {
		return funds[account];
	}

    // retrieves the total funds that the bank stores
	function getTotalFunds() public view returns (uint256) {
		return totalFunds;
	}

    // retrieves the account's ETH balance in its personal wallet address
	function getEthBalance(address account) public view returns (uint256){
		return account.balance;
	}
}