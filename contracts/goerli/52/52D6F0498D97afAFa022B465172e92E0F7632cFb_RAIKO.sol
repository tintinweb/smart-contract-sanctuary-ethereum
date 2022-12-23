/// SPDX-License-Identifier: MIT
/// @title Raiko Token
/// @author Kimi Development

pragma solidity ^0.8.17;

import "./ERC20.sol";

contract RAIKO is ERC20 {
    constructor() {
        setNameAndSymbol("RAIKO Token", "RAIKO");
        uint intitialTotalSupply = 3000000000000000000000000000000; //3T Tokens x 18 Decimals
        _mint(msg.sender, intitialTotalSupply);
    }

    receive()
    payable
    external
    {
        uint256 fbfail = 1;
        require(fbfail == 0, string(abi.encodePacked(name(), ": You can not send ETH to this contract!")));
    }

    fallback() external {}
}