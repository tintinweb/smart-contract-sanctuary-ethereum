//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './RedCatTemplate.sol';

contract RedCatCreate {

    event ContractAddress(address createAddress, address contractAddress);

    function createContract(string memory name, string memory symbol, uint _maxMint, uint _porfit, uint _maxTotal, uint _price, uint _mintTime, string memory _baseTokenURI) public {
        address contractAddress = address(new RedCatTemplate(name, symbol, _maxMint, _porfit, _maxTotal, _price, _mintTime, _baseTokenURI));
        emit ContractAddress(tx.origin, contractAddress);
    }
}