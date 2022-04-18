//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./OwnBafNft1155.sol";

contract Factory {
	event Deployed(address owner, address contractAddress);

	function deploy(bytes32 _salt, string memory name, string memory symbol, string memory tokenURIPrefix) external returns(address addr) {
		addr = address(new BAFUserToken1155{salt: _salt}(name, symbol, tokenURIPrefix));
		BAFUserToken1155 token = BAFUserToken1155(address(addr));
		token.transferOwnership(msg.sender);
		emit Deployed(msg.sender, addr);
	}
}