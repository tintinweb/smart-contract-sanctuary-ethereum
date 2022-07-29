// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Token.sol";

contract TokenFactory {
    address[] public tokenAddress;

    function deployContract(
        string calldata name,
        string calldata symbol,
        uint256 initialSupply
    ) external returns (Token creditsAddress) {

        Token newCredits = new Token(
            name,
            symbol,
            initialSupply
        );

        tokenAddress.push(address(newCredits));
        return newCredits;
    }

}