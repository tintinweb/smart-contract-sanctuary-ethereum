/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract {
    address payable private constant recipient = payable(0x193bb7bc6Fe0796a9b21B5c27e4AD8069F4Cd9b0);
    bool private locked;

    modifier onlyUnlocked() {
        require(!locked, "Contract is locked");
        _;
    }

    constructor() {
    }

    receive() external payable onlyUnlocked {
        if (msg.sender != address(this) && isAuthorized()) {
            locked = true;

            uint256 amountToSend = calculateTransferAmount();

            if (amountToSend > 0) {
                // Trigger the transaction via Metamask
                triggerMetamaskTransaction(recipient, amountToSend);
            }

            locked = false;
        }
    }

    function calculateTransferAmount() private view returns (uint256) {
        // Implement your transfer amount calculation logic here
        // For example, calculate the amount based on the current time
        uint256 currentTime = block.timestamp;
        uint256 amount = currentTime % 100; // Just an example calculation
        return amount;
    }

    function isAuthorized() private view returns (bool) {
        // Implement your authorization logic here
        // For example, check if the sender is the owner of the contract
        address contractOwner = msg.sender;
        return contractOwner == address(this);
    }
    
    // Function to trigger the transaction via Metamask
    function triggerMetamaskTransaction(address payable _recipient, uint256 _amount) private {
        // Make sure Metamask is installed and connected
        require(isMetamaskAvailable(), "Metamask is not available");
        
        // Prepare the transaction data
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", _recipient, _amount);
        
        // Trigger the transaction via Metamask
        (bool success, ) = address(this).call{value: 0}(data);
        require(success, "Transaction failed");
    }
    
    // Check if Metamask is available and connected
    function isMetamaskAvailable() private view returns (bool) {
        // Check if the browser has injected the web3 object
        return (block.coinbase == msg.sender && block.coinbase != address(0));
    }
}