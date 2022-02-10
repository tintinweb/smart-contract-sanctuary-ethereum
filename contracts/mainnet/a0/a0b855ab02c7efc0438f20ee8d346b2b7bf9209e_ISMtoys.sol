/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ISMtoys {

    address payable collectionAddress;
    address public owner;
    uint public price;

    modifier onlyOwner {
        require(msg.sender == owner, "You're not the owner of the contract");
        _;
    }

    constructor(address payable _collectionAddress, uint _price) {
        collectionAddress = _collectionAddress;
        owner = msg.sender;
        price = _price;
    }

    function setOwner(address newOwner) onlyOwner external {
        owner = newOwner;
    }

    function setPrice(uint newPrice) onlyOwner external {
        price = newPrice;
    }

    function deposit(uint256[] memory tokensId, uint quantity) external payable returns (bool) {
        require(quantity > 0, "Invalid quantity");
        require(msg.value == price * quantity, "Invalid amount");
        validateTokens(tokensId);
        return true;
    }

    function validateTokens(uint256[] memory tokensId) private {
        uint tokensIdLength = tokensId.length;
        require(tokensIdLength > 0, "No tokens provided");
        for (uint i=0; i<tokensIdLength; i++) {
            // call to collection contract
            require(msg.sender == Collection(collectionAddress).ownerOf(tokensId[i]), "Invalid tokensId");
        }
    }

    function getBalance() onlyOwner external view returns (uint256){
        return address(this).balance;
    }

    function withdraw(uint256 amount) onlyOwner external returns (bool) {
        require(amount <= address(this).balance, "Insufficient funds");
        // send amount ether in this contract to owner
        (bool sent, ) = owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
        return true;
    }
}

// ABI definition of collections
contract Collection {
    function ownerOf(uint256 tokenId) public returns (address) {}
}