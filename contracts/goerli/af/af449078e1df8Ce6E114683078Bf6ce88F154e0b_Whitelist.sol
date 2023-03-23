// SPDX-License-Identifier: MIT
import "./Context.sol";

// File: contracts/Whitelist.sol


pragma solidity ^0.8.4;

contract Whitelist is Ownable {
    address founderAddress;

    mapping(address => uint256) public whitelist;
    mapping(uint256 => bool) public publicCollection;

    function addToWhitelist(address[] calldata _toAddAddresses, uint256[] calldata _allowedType) 
    external onlyOwner
    {
        require(_toAddAddresses.length == _allowedType.length, "Invalid inputs");
        for (uint i = 0; i < _toAddAddresses.length; i++) {
            whitelist[_toAddAddresses[i]] = _allowedType[i];
        }
    }

    function removeFromWhitelist(address[] calldata toRemoveAddresses)
    external onlyOwner
    {
        for (uint i = 0; i < toRemoveAddresses.length; i++) {
            delete whitelist[toRemoveAddresses[i]];
        }
    }

    function setFounderAddress(address _founder) external onlyOwner {
        require(founderAddress == address(0), "Founder already set");
        founderAddress = _founder;
        whitelist[_founder] = 99;
    }

    function getFounderAddress() external view returns(address) {
        return founderAddress;
    }

    function setPublicCollection(uint256 _collection, bool _public) external onlyOwner {
        publicCollection[_collection] = _public;
    }
}