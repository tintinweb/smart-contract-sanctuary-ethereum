/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

// File: contracts/IWhitelist.sol


pragma solidity 0.8.15;
contract Whitelist {
    address public ownerAddress;

    mapping(address => bool) public whitelistedAddresses;
    

    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Only owner address");
        _;
    }
    
    constructor() {
        ownerAddress = msg.sender;
    }

    function addMintWhitelisted(address[] calldata _address) public onlyOwner {
        require(!whitelistedAddresses[msg.sender], "Sender has already been whitelisted");
        for(uint256 i = 0; i < _address.length; ++i) {
            whitelistedAddresses[_address[i]] = true;
        }
    }
}