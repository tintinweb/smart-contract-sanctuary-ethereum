// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Token.sol";

contract Bridge {
    event BRIDGE(
        address indexed from,
        uint256 indexed amount,
        uint256 indexed chainName
    );

    address public toAdd;
    IERC20 public token;

    constructor(address _toAdd, address _tokenAddress) {
        toAdd = _toAdd;
        token = IERC20(_tokenAddress);
    }

    function bridgeToken(uint256 amount, uint256 chainName)
        public
        returns (bool)
    {
        require(token.balanceOf(msg.sender) >= amount, "Insufficient balance");
        token.transferFrom(msg.sender, toAdd, amount);
        emit BRIDGE(msg.sender, amount, chainName);
        return true;
    }
}