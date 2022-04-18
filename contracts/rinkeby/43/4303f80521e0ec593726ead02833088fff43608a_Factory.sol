//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./OwnBafNft721.sol";

contract Factory {
	event Deployed(address owner, address contractAddress);

	function deploy(bytes32 _salt, string memory name, string memory symbol, string memory tokenURIPrefix) external returns(address addr) {
		addr = address(new BAFUserToken721{salt: _salt}(name, symbol, tokenURIPrefix));
		BAFUserToken721 token = BAFUserToken721(address(addr));
		token.transferOwnership(msg.sender);
		emit Deployed(msg.sender, addr);
	}
}