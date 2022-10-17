/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

// File: contracts/IWhitelist.sol


pragma solidity ^0.8.9;
contract Whitelist {
    address public ownerAddress;

    mapping(address => bool) public whitelistedAddresses;
    

    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Only Owner address");
        _;
    }
    
    constructor() {
        ownerAddress = msg.sender;
    }

    function addMintWhitelisted(address[] calldata addressLists) external onlyOwner {
        for(uint256 i = 0; i < addressLists.length; ++i) {
            if(!whitelistedAddresses[addressLists[i]])
                whitelistedAddresses[addressLists[i]] = true;
        }
    }
}