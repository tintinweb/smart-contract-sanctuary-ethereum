// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct Chain {
    string network;
    uint256 id;
}

interface IOwner {
    function owner() external view returns (address owner);
}

contract TokenRegistry {

    mapping(address => mapping(string => mapping(uint256 => address))) private _secondaryTokenAddrRegistry;

    event SecondaryTokenAddressChanged(
        address indexed primaryAddr,
        Chain indexed secondaryChain,
        address indexed newSecondaryAddr
    );

    modifier validAddress(address addr) {
        require(addr != address(0), "Invalid address");
        _;
    }

    modifier onlyContractOwner(address addr) {
        require(msg.sender == IOwner(addr).owner());
        _;
    }

    function getSecondaryTokenAddress(
        address primaryAddr,
        Chain memory secondaryChain
    ) external view validAddress(primaryAddr) returns (address) {
        return _secondaryTokenAddrRegistry[primaryAddr][secondaryChain.network][secondaryChain.id];
    }

    function setSecondaryTokenAddress(
        address primaryAddr,
        Chain memory secondaryChain,
        address newSecondaryAddr
    ) external validAddress(primaryAddr) onlyContractOwner(primaryAddr) {
        _secondaryTokenAddrRegistry[primaryAddr][secondaryChain.network][secondaryChain.id] = newSecondaryAddr;
        emit SecondaryTokenAddressChanged(primaryAddr, secondaryChain, newSecondaryAddr);
    }

}