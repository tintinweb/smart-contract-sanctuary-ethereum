/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IMarketplaceV4 {
    function buy(bytes32 productId, uint subscriptionSeconds) external;
    function buyFor(bytes32 productId, uint subscriptionSeconds, address recipient) external;
}

interface IOutbox {
    function dispatch(
        uint32 destinationDomain, // the chain where Marketplace is deployed and where messages are sent to. It is a unique ID assigned by hyperlane protocol (e.g. on polygon)
        bytes32 recipientAddress, // the address for the Marketplace contract. It must have the handle() function (e.g. on polygon)
        bytes calldata messageBody // encoded purchase info
    ) external returns (uint256);
}

/**
 * @title Streamr Remote Marketplace
 * The Remmote Marketplace through which the users on other networks can send cross-chain messages (e.g. buy products)
 */
contract RemoteMarketplace is IMarketplaceV4 {

  event CrossChainPurchase(bytes32 productId, address subscriber, uint256 subscriptionSeconds);

    uint32 public destinationDomain;
    address public recipientAddress;
    address public outboxAddress;

    /**
     * @param _destinationDomain - the Domain ID of the source chain assigned by the protocol (e.g. polygon)
     * @param _recipientAddress - the address of the recipient contract (e.g. MarketplaceV4 on polygon)
     * @param _outboxAddress - hyperlane core address for the chain where RemoteMarketplace is deployed (e.g. gnosis)
     */
    constructor(uint32 _destinationDomain, address _recipientAddress, address _outboxAddress) {
        destinationDomain = _destinationDomain;
        recipientAddress = _recipientAddress;
        outboxAddress = _outboxAddress;
    }

    function buy(bytes32 productId, uint subscriptionSeconds) public {
        buyFor(productId, subscriptionSeconds, msg.sender);
    }

    function buyFor(bytes32 productId, uint256 subscriptionSeconds, address subscriber) public {
        IOutbox(outboxAddress).dispatch(
            destinationDomain,
            addressToBytes32(recipientAddress),
            abi.encode(productId, subscriptionSeconds, subscriber)
        );
        emit CrossChainPurchase(productId, subscriber, subscriptionSeconds);
    }

    function addressToBytes32(address addr) public pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
}