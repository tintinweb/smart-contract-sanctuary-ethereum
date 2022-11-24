// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ForceCaller {
	address public recipient;

	event Received(address, uint256);

	constructor(address _recipient) {
		recipient = _recipient;
	}

	receive() external payable {
		emit Received(msg.sender, msg.value);
	}

	function destroy() public {
		selfdestruct(payable(recipient));
	}
}