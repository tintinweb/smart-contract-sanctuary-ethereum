// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMyNFT {
    function mint(address to) external;
}

contract WalletGenerator {
    struct Wallet {
        bytes32 privateKey;
        bool exists;
    }
    
    mapping(address => Wallet[]) private wallets;
    
    event WalletCreated(address indexed walletAddress, address indexed owner);
    
    function createWallet(string memory userInput) external {
        bytes32 privateKey = keccak256(abi.encodePacked(userInput, msg.sender));
        address walletAddress = address(uint160(uint256(privateKey)));
        
        wallets[msg.sender].push(Wallet(privateKey, true));
        
        emit WalletCreated(walletAddress, msg.sender);
    }
    
    function getWalletAddressesByUser(address user) external view returns (address[] memory) {
        Wallet[] storage userWallets = wallets[user];
        address[] memory addresses = new address[](userWallets.length);
        
        for (uint256 i = 0; i < userWallets.length; i++) {
            addresses[i] = address(uint160(uint256(userWallets[i].privateKey)));
        }
        
        return addresses;
    }

      function mintNFT(address myNFTContract, address to) external {
        // Call the mint function on the MyNFT contract
        IMyNFT(myNFTContract).mint(to);
    }
}