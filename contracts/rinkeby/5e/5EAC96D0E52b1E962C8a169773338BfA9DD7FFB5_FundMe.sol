/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error NotOwner();

contract FundMe {
	address public i_contractOwner;

	constructor() {
		i_contractOwner = msg.sender;
	}

	// funders tracking
	address[] public funders;
	mapping(address => uint256) public addressToAmountFunded;

	// Minimum ETH per transfer
	uint256 public constant MIN_VALUE = 1 * 1e18;

	// fund Function
	function fund() public payable {
		require(msg.value >= MIN_VALUE, "Not enough eth send");

		// add funder to the tracker
		funders.push(msg.sender);
		addressToAmountFunded[msg.sender] =
			uint256(addressToAmountFunded[msg.sender]) +
			msg.value;
	}

	// Retrieve contract ETH Balance
	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function withdraw() public onlyOwner {
		// delete all fund registries
		for (uint256 i = 0; i < funders.length; i++) {
			address funder = funders[i];
			addressToAmountFunded[funder] = 0;
		}

		// Transfer the eth to the contractOwner
		(bool callSuccess, ) = payable(i_contractOwner).call{
			value: address(this).balance
		}("");
		require(callSuccess, "Ha ocurrido un error al transferir los fondos");
	}

	// Modifiers
	modifier onlyOwner() {
		if (msg.sender != i_contractOwner) {
			revert NotOwner();
		}
		_;
	}

	receive() external payable {
		fund();
	}

	fallback() external payable {
		fund();
	}
}