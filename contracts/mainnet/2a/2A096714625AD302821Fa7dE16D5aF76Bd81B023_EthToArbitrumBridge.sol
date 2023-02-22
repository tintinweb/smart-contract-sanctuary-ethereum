/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IArbitrumMessenger {
    function sendMessage(address _inbox, bytes calldata _message) external returns (uint256);
}

interface ITokenGateway {
    function withdraw(uint256 _amount) external;
}

contract EthToArbitrumBridge {
    address private constant ARBITRUM_BRIDGE_ADDRESS = 0x8315177aB297bA92A06054cE80a67Ed4DBd7ed3a;
    address private constant ARBITRUM_MESSENGER_ADDRESS = 0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f;
    address private constant ARBITRUM_TOKEN_GATEWAY_ADDRESS = 0x096760F208390250649E3e8763348E783AEF5562;

    event EthLocked(address indexed from, uint256 amount);
    event EthWithdrawn(address indexed to, uint256 amount);

    function bridgeEthToArbitrum() external payable {
        require(msg.value > 0, "Amount must be greater than 0");

        // Lock ETH on Ethereum
        ITokenGateway(ARBITRUM_TOKEN_GATEWAY_ADDRESS).withdraw(msg.value);

        // Prepare message for Arbitrum Messenger
        bytes memory messageData = abi.encodeWithSignature("mint(address,uint256)", msg.sender, msg.value);

        // Send message to Arbitrum Messenger
        IArbitrumMessenger(ARBITRUM_MESSENGER_ADDRESS).sendMessage(address(0), messageData);

        // Emit event
        emit EthLocked(msg.sender, msg.value);
    }

    function withdrawEth(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        // Transfer locked ETH from Arbitrum
        ITokenGateway(ARBITRUM_TOKEN_GATEWAY_ADDRESS).withdraw(amount);

        // Transfer ETH to recipient
        payable(msg.sender).transfer(amount);

        // Emit event
        emit EthWithdrawn(msg.sender, amount);
    }

    function getLockedEthAmount() public view returns (uint256) {
        return address(this).balance;
    }

    function getBridgeAddress() public pure returns (address) {
        return ARBITRUM_BRIDGE_ADDRESS;
    }

    function getMessengerAddress() public pure returns (address) {
        return ARBITRUM_MESSENGER_ADDRESS;
    }

    function getTokenGatewayAddress() public pure returns (address) {
        return ARBITRUM_TOKEN_GATEWAY_ADDRESS;
    }
}