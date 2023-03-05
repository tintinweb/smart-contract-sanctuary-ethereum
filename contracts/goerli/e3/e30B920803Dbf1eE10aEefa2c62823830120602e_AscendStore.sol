// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

/*
 * Contract for the Ascend the End store, where users pay NEON coins to receive items, and can redeem credits for coins
 */

// Author: Github: @bill-noto
contract AscendStore {
	// Sets owner address as payable
	address payable public owner;

	// Assigns the contract owner to be the one who "posted it"
	constructor() payable {
		owner = payable(msg.sender);
	}

	/**
	 * @dev Neon transfer event, with data about the transaction
	 */
	event TransferOfNeon(
		address indexed from,
		address indexed to,
		uint256 amount
	);

	/**
	 * @dev Modifier so only the owner of the contract can call certain function
	 */
	modifier onlyOwner() {
		require(msg.sender == owner, 'Caller is not the owner');
		_;
	}

	/**
	 * @dev Function to check which address is the current owner of the contract
	 */
	function currentOwner() public view returns (address) {
		return owner;
	}

	/**
	 * @dev Transfer ownership of contract to a new address, subsequently changing the target of transactions
	 */
	function transferOwnership(address payable newOwner) public onlyOwner {
		require(newOwner != owner, 'This address is already the current owner');
		owner = newOwner;
	}

	/**
	 * @dev Handle the transfer of Neon to owner address in the recommended method
	 */
	function payToOwner() public payable returns (bool) {
		(bool success, ) = payable(owner).call{ value: msg.value }('');
		require(success, 'Payment failed');
		emit TransferOfNeon(msg.sender, owner, msg.value);
		return true;
	}

	/**
	 * @dev Handle the transfer of Neon to recieving address in the recommended method
	 */
	function payToUser(
		address payable targetAddress
	) public payable returns (bool) {
		(bool success, ) = payable(targetAddress).call{ value: msg.value }('');
		require(success, 'Payment failed');
		emit TransferOfNeon(msg.sender, targetAddress, msg.value);
		return true;
	}

	/**
	 * @dev Withdraw any NEON possible present in the contract to the owner
	 */
	function withdraw() public onlyOwner {
		uint256 contractBalance = address(this).balance;
		require(contractBalance > 0, 'No NEON present in contract');
		(bool sucess, ) = msg.sender.call{ value: address(this).balance }('');
		require(sucess, 'Failed to withdraw');
	}
}