// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

contract EbookNFTHelper {
    constructor(address _ebookNFTAddress) {
        owner = msg.sender;
        ebookNFTAddress = _ebookNFTAddress;
    }

    //address of the contract deployer.
    address owner;

    //address of the ebookNFT contract
    address ebookNFTAddress;

    //Modifier for onlyOwner functions
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You are not the contract owner to call this function!"
        );
        _;
    }

    function setEbookNFTAddress(address _ebookNFTAddress) public onlyOwner {
        ebookNFTAddress = _ebookNFTAddress;
    }
}