// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// Gnosis Safe Proxy Factory interface extracted from the mainnet: https://etherscan.io/address/0xa6b71e26c5e0845f74c812102ca7114b6a896ab2#code#F2#L61
interface IGnosisSafeProxyFactory {
    /// @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
    /// @param _singleton Address of singleton contract.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    function createProxyWithNonce(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce
    ) external returns (address proxy);
}

/// @title Gnosis Safe - Smart contract for Gnosis Safe multisig implementation of a generic multisig interface
/// @author Aleksandr Kuperman - <[email protected]>
contract GnosisSafeMultisig {
    // Selector of the Gnosis Safe setup function
    bytes4 internal constant _GNOSIS_SAFE_SETUP_SELECTOR = 0xb63e800d;
    // Gnosis Safe
    address payable public immutable gnosisSafe;
    // Gnosis Safe Factory
    address public immutable gnosisSafeProxyFactory;

    /// @dev GnosisSafeMultisig constructor.
    /// @param _gnosisSafe Gnosis Safe address.
    /// @param _gnosisSafeProxyFactory Gnosis Safe proxy factory address.
    constructor (address payable _gnosisSafe, address _gnosisSafeProxyFactory) {
        gnosisSafe = _gnosisSafe;
        gnosisSafeProxyFactory = _gnosisSafeProxyFactory;
    }

    /// @dev Parses (unpacks) the data to gnosis safe specific parameters.
    /// @param data Packed data related to the creation of a gnosis safe multisig.
    function _parseData(bytes memory data) internal pure
        returns (address to, address fallbackHandler, address paymentToken, address payable paymentReceiver,
            uint256 payment, uint256 nonce, bytes memory payload)
    {
        if (data.length > 0) {
            uint256 dataSize = data.length;
            assembly {
                // Read all the addresses first
                let offset := 20
                to := mload(add(data, offset))
                offset := add(offset, 20)
                fallbackHandler := mload(add(data, offset))
                offset := add(offset, 20)
                paymentToken := mload(add(data, offset))
                offset := add(offset, 20)
                paymentReceiver := mload(add(data, offset))

                // Read all the uints
                offset := add(offset, 32)
                payment := mload(add(data, offset))
                offset := add(offset, 32)
                nonce := mload(add(data, offset))

                // Read the payload data
                payload := mload(add(data, dataSize))
            }
        }
    }

    /// @dev Creates a gnosis safe multisig.
    /// @param owners Set of multisig owners.
    /// @param threshold Number of required confirmations for a multisig transaction.
    /// @param data Packed data related to the creation of a chosen multisig.
    /// @return multisig Address of a created multisig.
    function create(
        address[] memory owners,
        uint256 threshold,
        bytes memory data
    ) external returns (address multisig)
    {
        // Parse the data into gnosis-specific set of variables
        (address to, address fallbackHandler, address paymentToken, address payable paymentReceiver, uint256 payment,
            uint256 nonce, bytes memory payload) = _parseData(data);

        // Encode the gmosis setup function parameters
        bytes memory safeParams = abi.encodeWithSelector(_GNOSIS_SAFE_SETUP_SELECTOR, owners, threshold,
            to, payload, fallbackHandler, paymentToken, payment, paymentReceiver);

        // Create a gnosis safe multisig via the proxy factory
        multisig = IGnosisSafeProxyFactory(gnosisSafeProxyFactory).createProxyWithNonce(gnosisSafe, safeParams, nonce);
    }
}