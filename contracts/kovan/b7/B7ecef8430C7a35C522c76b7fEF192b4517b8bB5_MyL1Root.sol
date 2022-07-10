// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {ICrossDomainMessenger} from "@eth-optimism/contracts/libraries/bridge/ICrossDomainMessenger.sol";

contract MyL1Root {
    address public crossDomainAddress =
        0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;

    address public l2Address;

    event MintFromL2(address indexed sender, address indexed to);
    event L2AddressSet(address indexed prevAddress, address indexed newAddress);
    event CrossDomainAddressSet(
        address indexed prevAddress,
        address indexed newAddress
    );

    constructor() {}

    function mintFromL2(address to, uint32 _gasLimit) external {
        require(
            l2Address != address(0),
            "MyL1Root: The l2Address is not yet set."
        );

        ICrossDomainMessenger(crossDomainAddress).sendMessage(
            l2Address,
            abi.encodeWithSignature("mintFromL1(address)", to),
            _gasLimit
        );
        emit MintFromL2(msg.sender, to);
    }

    function setL2Address(address _l2Address) external {
        emit L2AddressSet(l2Address, _l2Address);
        l2Address = _l2Address;
    }

    function setCrossDomainAddress(address _crossDomainAddress) external {
        emit CrossDomainAddressSet(crossDomainAddress, _crossDomainAddress);
        crossDomainAddress = _crossDomainAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.9.0;

/**
 * @title ICrossDomainMessenger
 */
interface ICrossDomainMessenger {
    /**********
     * Events *
     **********/

    event SentMessage(
        address indexed target,
        address sender,
        bytes message,
        uint256 messageNonce,
        uint256 gasLimit
    );
    event RelayedMessage(bytes32 indexed msgHash);
    event FailedRelayedMessage(bytes32 indexed msgHash);

    /*************
     * Variables *
     *************/

    function xDomainMessageSender() external view returns (address);

    /********************
     * Public Functions *
     ********************/

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
}