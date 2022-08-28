// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./StorageUtils.sol";
import "./SponsorshipUtils.sol";
import "./WithdrawalUtils.sol";
import "../utils/ExtendedMulticall.sol";
import "./interfaces/IAirnodeProtocol.sol";

/// @title Airnode request–response protocol (RRP) and its relayed version
/// @notice Similar to HTTP, RRP allows the requester to specify a one-off
/// request that the Airnode is expected to respond to as soon as possible.
/// The relayed version allows the requester to specify an Airnode that will
/// sign the fulfillment data and a relayer that will report the signed
/// fulfillment.
/// @dev This contract inherits Multicall for Airnodes to be able to make batch
/// static calls to read sponsorship states, and template and subscription
/// details.
/// StorageUtils, SponsorshipUtils and WithdrawalUtils also implement some
/// auxiliary functionality for PSP.
contract AirnodeProtocol is
    StorageUtils,
    SponsorshipUtils,
    WithdrawalUtils,
    ExtendedMulticall,
    IAirnodeProtocol
{
    using ECDSA for bytes32;

    /// @notice Number of requests the requester made
    /// @dev This can be used to calculate the ID of the next request that the
    /// requester will make
    mapping(address => uint256) public override requesterToRequestCount;

    mapping(bytes32 => bytes32) private requestIdToFulfillmentParameters;

    /// @notice Called by the requester to make a request
    /// @param templateId Template ID
    /// @param parameters Parameters provided by the requester in addition to
    /// the parameters in the template
    /// @param sponsor Sponsor address
    /// @param fulfillFunctionId Selector of the function to be called for
    /// fulfillment
    /// @return requestId Request ID
    function makeRequest(
        address airnode,
        bytes32 templateId,
        bytes calldata parameters,
        address sponsor,
        bytes4 fulfillFunctionId
    ) external override returns (bytes32 requestId) {
        require(airnode != address(0), "Airnode address zero");
        require(templateId != bytes32(0), "Template ID zero");
        require(
            parameters.length <= MAXIMUM_PARAMETER_LENGTH,
            "Parameters too long"
        );
        require(sponsor != address(0), "Sponsor address zero");
        require(fulfillFunctionId != bytes4(0), "Fulfill function ID zero");
        uint256 requesterRequestCount = ++requesterToRequestCount[msg.sender];
        requestId = keccak256(
            abi.encodePacked(
                block.chainid,
                address(this),
                msg.sender,
                requesterRequestCount,
                airnode,
                templateId,
                parameters,
                sponsor,
                fulfillFunctionId
            )
        );
        requestIdToFulfillmentParameters[requestId] = keccak256(
            abi.encodePacked(airnode, msg.sender, fulfillFunctionId)
        );
        emit MadeRequest(
            airnode,
            requestId,
            msg.sender,
            requesterRequestCount,
            templateId,
            parameters,
            sponsor,
            fulfillFunctionId
        );
    }

    /// @notice Called by the Airnode using the sponsor wallet to fulfill the
    /// request
    /// @dev Airnodes attest to controlling their respective sponsor wallets by
    /// signing a message with the address of the sponsor wallet. A timestamp
    /// is added to this signature for it to act as an expiring token if the
    /// requester contract checks for freshness.
    /// This will not revert depending on the external call. However, it will
    /// return `false` if the external call reverts or if there is no function
    /// with a matching signature at `fulfillAddress`. On the other hand, it
    /// will return `true` if the external call returns successfully or if
    /// there is no contract deployed at `fulfillAddress`.
    /// If `callSuccess` is `false`, `callData` can be decoded to retrieve the
    /// revert string.
    /// This function emits its event after an untrusted low-level call,
    /// meaning that the log indices of these events may be off.
    /// @param requestId Request ID
    /// @param airnode Airnode address
    /// @param requester Requester address
    /// @param fulfillFunctionId Selector of the function to be called for
    /// fulfillment
    /// @param timestamp Timestamp used in the signature
    /// @param data Fulfillment data, encoded in contract ABI
    /// @param signature Request ID, a timestamp and the sponsor wallet address
    /// signed by the Airnode wallet
    /// @return callSuccess If the fulfillment call succeeded
    /// @return callData Data returned by the fulfillment call (if there is
    /// any)
    function fulfillRequest(
        bytes32 requestId,
        address airnode,
        address requester,
        bytes4 fulfillFunctionId,
        uint256 timestamp,
        bytes calldata data,
        bytes calldata signature
    ) external override returns (bool callSuccess, bytes memory callData) {
        require(
            keccak256(
                abi.encodePacked(airnode, requester, fulfillFunctionId)
            ) == requestIdToFulfillmentParameters[requestId],
            "Invalid request fulfillment"
        );
        require(
            (
                keccak256(abi.encodePacked(requestId, timestamp, msg.sender))
                    .toEthSignedMessageHash()
            ).recover(signature) == airnode,
            "Signature mismatch"
        );
        delete requestIdToFulfillmentParameters[requestId];
        (callSuccess, callData) = requester.call( // solhint-disable-line avoid-low-level-calls
            abi.encodeWithSelector(
                fulfillFunctionId,
                requestId,
                timestamp,
                data
            )
        );
        if (callSuccess) {
            emit FulfilledRequest(airnode, requestId, timestamp, data);
        } else {
            // We do not bubble up the revert string from `callData`
            emit FailedRequest(
                airnode,
                requestId,
                timestamp,
                "Fulfillment failed unexpectedly"
            );
        }
    }

    /// @notice Called by the Airnode using the sponsor wallet if the request
    /// cannot be fulfilled
    /// @dev The Airnode should fall back to this if a request cannot be
    /// fulfilled because of an error, including the static call to `fulfill()`
    /// returning `false` for `callSuccess`.
    /// @param requestId Request ID
    /// @param airnode Airnode address
    /// @param requester Requester address
    /// @param fulfillFunctionId Selector of the function to be called for
    /// fulfillment
    /// @param timestamp Timestamp used in the signature
    /// @param errorMessage A message that explains why the request has failed
    /// @param signature Request ID, a timestamp and the sponsor wallet address
    /// signed by the Airnode address
    function failRequest(
        bytes32 requestId,
        address airnode,
        address requester,
        bytes4 fulfillFunctionId,
        uint256 timestamp,
        string calldata errorMessage,
        bytes calldata signature
    ) external override {
        require(
            keccak256(
                abi.encodePacked(airnode, requester, fulfillFunctionId)
            ) == requestIdToFulfillmentParameters[requestId],
            "Invalid request fulfillment"
        );
        require(
            (
                keccak256(abi.encodePacked(requestId, timestamp, msg.sender))
                    .toEthSignedMessageHash()
            ).recover(signature) == airnode,
            "Signature mismatch"
        );
        delete requestIdToFulfillmentParameters[requestId];
        emit FailedRequest(airnode, requestId, timestamp, errorMessage);
    }

    /// @notice Called by the requester to make a request to be fulfilled by a
    /// relayer
    /// @dev The relayer address indexed in the relayed protocol logs because
    /// it will be the relayer that will be listening to these logs
    /// @param templateId Template ID
    /// @param parameters Parameters provided by the requester in addition to
    /// the parameters in the template
    /// @param relayer Relayer address
    /// @param sponsor Sponsor address
    /// @param fulfillFunctionId Selector of the function to be called for
    /// fulfillment
    /// @return requestId Request ID
    function makeRequestRelayed(
        address airnode,
        bytes32 templateId,
        bytes calldata parameters,
        address relayer,
        address sponsor,
        bytes4 fulfillFunctionId
    ) external override returns (bytes32 requestId) {
        require(airnode != address(0), "Airnode address zero");
        require(templateId != bytes32(0), "Template ID zero");
        require(
            parameters.length <= MAXIMUM_PARAMETER_LENGTH,
            "Parameters too long"
        );
        require(relayer != address(0), "Relayer address zero");
        require(sponsor != address(0), "Sponsor address zero");
        require(fulfillFunctionId != bytes4(0), "Fulfill function ID zero");
        uint256 requesterRequestCount = ++requesterToRequestCount[msg.sender];
        requestId = keccak256(
            abi.encodePacked(
                block.chainid,
                address(this),
                msg.sender,
                requesterRequestCount,
                airnode,
                templateId,
                parameters,
                relayer,
                sponsor,
                fulfillFunctionId
            )
        );
        requestIdToFulfillmentParameters[requestId] = keccak256(
            abi.encodePacked(airnode, msg.sender, relayer, fulfillFunctionId)
        );
        emit MadeRequestRelayed(
            relayer,
            requestId,
            airnode,
            msg.sender,
            requesterRequestCount,
            templateId,
            parameters,
            sponsor,
            fulfillFunctionId
        );
    }

    /// @notice Called by the relayer using the sponsor wallet to fulfill the
    /// request with the Airnode-signed response
    /// @dev The Airnode must verify the integrity of the request details,
    /// template details, sponsor address–sponsor wallet address consistency
    /// before signing the response
    /// @param requestId Request ID
    /// @param airnode Airnode address
    /// @param requester Requester address
    /// @param relayer Relayer address
    /// @param fulfillFunctionId Selector of the function to be called for
    /// fulfillment
    /// @param timestamp Timestamp used in the signature
    /// @param data Fulfillment data
    /// @param signature Request ID, a timestamp, the sponsor wallet address
    /// and the fulfillment data signed by the Airnode address
    /// @return callSuccess If the fulfillment call succeeded
    /// @return callData Data returned by the fulfillment call (if there is
    /// any)
    function fulfillRequestRelayed(
        bytes32 requestId,
        address airnode,
        address requester,
        address relayer,
        bytes4 fulfillFunctionId,
        uint256 timestamp,
        bytes calldata data,
        bytes calldata signature
    ) external override returns (bool callSuccess, bytes memory callData) {
        require(
            keccak256(
                abi.encodePacked(airnode, requester, relayer, fulfillFunctionId)
            ) == requestIdToFulfillmentParameters[requestId],
            "Invalid request fulfillment"
        );
        require(
            (
                keccak256(
                    abi.encodePacked(requestId, timestamp, msg.sender, data)
                ).toEthSignedMessageHash()
            ).recover(signature) == airnode,
            "Signature mismatch"
        );
        delete requestIdToFulfillmentParameters[requestId];
        (callSuccess, callData) = requester.call( // solhint-disable-line avoid-low-level-calls
            abi.encodeWithSelector(
                fulfillFunctionId,
                requestId,
                timestamp,
                data
            )
        );
        if (callSuccess) {
            emit FulfilledRequestRelayed(
                relayer,
                requestId,
                airnode,
                timestamp,
                data
            );
        } else {
            // We do not bubble up the revert string from `callData`
            emit FailedRequestRelayed(
                relayer,
                requestId,
                airnode,
                timestamp,
                "Fulfillment failed unexpectedly"
            );
        }
    }

    /// @notice Called by the relayer using the sponsor wallet if the request
    /// cannot be fulfilled
    /// @dev Since failure may also include problems at the Airnode end (such
    /// as it being unavailable), we are content with a signature from the
    /// relayer to validate failures. This is acceptable because explicit
    /// failures are mainly for easy debugging of issues, and the requester
    /// should always consider denial of service from a relayer or an Airnode
    /// to be a possibility.
    /// @param requestId Request ID
    /// @param airnode Airnode address
    /// @param requester Requester address
    /// @param relayer Relayer address
    /// @param timestamp Timestamp used in the signature
    /// @param errorMessage A message that explains why the request has failed
    /// @param signature Request ID, a timestamp and the sponsor wallet address
    /// signed by the relayer address
    function failRequestRelayed(
        bytes32 requestId,
        address airnode,
        address requester,
        address relayer,
        bytes4 fulfillFunctionId,
        uint256 timestamp,
        string calldata errorMessage,
        bytes calldata signature
    ) external override {
        require(
            keccak256(
                abi.encodePacked(airnode, requester, relayer, fulfillFunctionId)
            ) == requestIdToFulfillmentParameters[requestId],
            "Invalid request fulfillment"
        );
        require(
            (
                keccak256(abi.encodePacked(requestId, timestamp, msg.sender))
                    .toEthSignedMessageHash()
            ).recover(signature) == relayer,
            "Signature mismatch"
        );
        delete requestIdToFulfillmentParameters[requestId];
        emit FailedRequestRelayed(
            relayer,
            requestId,
            airnode,
            timestamp,
            errorMessage
        );
    }

    /// @notice Returns if the request with the ID is made but not
    /// fulfilled/failed yet
    /// @dev If a requester has made a request, received a request ID but did
    /// not hear back, it can call this method to check if the Airnode/relayer
    /// called back `failRequest()`/`failRequestRelayed()` instead.
    /// @param requestId Request ID
    /// @return If the request is awaiting fulfillment
    function requestIsAwaitingFulfillment(bytes32 requestId)
        external
        view
        override
        returns (bool)
    {
        return requestIdToFulfillmentParameters[requestId] != bytes32(0);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/IStorageUtils.sol";

/// @title Contract that can be used to store template and subscriptions
/// details on-chain
/// @notice The Airnode protocol does not depend on the templates or
/// subscriptions to be stored on-chain, which means using this functionality
/// is entirely optional. However, if you are not storing your templates or
/// subscriptions on-chain, you should make sure that the respective Airnode
/// already knows about them (e.g., their details are hardcoded in the
/// Airnode configuration file).
/// @dev Templates and subscriptions need to persist, which is why we do not
/// depend on storing them in logs and the respective Airnode being able to
/// retrieve them from there. Compared to that, storage is a much safer bet.
/// However, this may end up being prohibitively expensive on some chains, in
/// which case the user should consider off-chain channels to pass the details.
contract StorageUtils is IStorageUtils {
    struct Template {
        bytes32 endpointId;
        bytes parameters;
    }

    struct Subscription {
        uint256 chainId;
        address airnode;
        bytes32 templateId;
        bytes parameters;
        bytes conditions;
        address relayer;
        address sponsor;
        address requester;
        bytes4 fulfillFunctionId;
    }

    /// @notice Maximum parameter length for byte strings that Airnodes will
    /// need to read from storage or logs
    /// @dev A very generous limit is applied, under the assumption that
    /// anything larger than this is a grief attempt. If the user needs to use
    /// longer parameters, they will need to use off-chain channels to pass
    /// the respective template/subscription details to the Airnode operator
    /// for them to be specified in the configuration file.
    uint256 public constant override MAXIMUM_PARAMETER_LENGTH = 4096;

    /// @notice Template details with the ID
    mapping(bytes32 => Template) public override templates;

    /// @notice Subscription details with the ID
    mapping(bytes32 => Subscription) public override subscriptions;

    /// @notice Stores template details
    /// @dev Templates fully or partially define requests. By referencing a
    /// template, requesters can omit specifying the "boilerplate" sections of
    /// requests.
    /// A zero endpoint ID means the Airnode does not need to use one of its
    /// endpoints, and can move directly on to fulfillment. This is
    /// particularly useful for defining traditional keeper jobs that do not
    /// require off-chain data.
    /// @param endpointId Endpoint ID (allowed to be `bytes32(0)`)
    /// @param parameters Template parameters, encoded in Airnode ABI
    /// @return templateId Template ID
    function storeTemplate(bytes32 endpointId, bytes calldata parameters)
        external
        override
        returns (bytes32 templateId)
    {
        require(
            parameters.length <= MAXIMUM_PARAMETER_LENGTH,
            "Parameters too long"
        );
        templateId = keccak256(abi.encodePacked(endpointId, parameters));
        templates[templateId] = Template({
            endpointId: endpointId,
            parameters: parameters
        });
        emit StoredTemplate(templateId, endpointId, parameters);
    }

    /// @notice Stores subscription details
    /// @dev `airnode` should make the query specified by `templateId` and
    /// `parameters`. If the returned data satisfies `conditions`, it should
    /// call `requester`'s `fulfillFunctionId` on `chainId` with the returned
    /// data, using the wallet dedicated to `sponsor`.
    /// If `relayer` is not `airnode`, the relayer is responsible with checking
    /// `condition` and using the wallet dedicated to `sponsor` to deliver the
    /// data.
    /// In most cases, `conditions` will specify a static call to a function on
    /// `chainId` with the data. The extent of its flexibility depends on the
    /// node implementation and is outside the scope of the on-chain protocol.
    /// Similarly, `conditions` can specify with what frequency it should be
    /// verified, and the details of this is outside the scope.
    /// `templateId` being zero is similar to the endpoint ID being zero for
    /// templates, means the endpoint query can be skipped. In this case,
    /// `parameters` will be treated as the data that is returned by the
    /// endpoint while verifying `conditions`.
    /// @param chainId Chain ID
    /// @param airnode Airnode address
    /// @param templateId Template ID (allowed to be `bytes32(0)`)
    /// @param parameters Parameters provided by the subscription in addition
    /// to the parameters in the template, encoded in Airnode ABI
    /// @param conditions Conditions under which the subscription is requested
    /// to be fulfilled, encoded in Airnode ABI
    /// @param relayer Relayer address
    /// @param sponsor Sponsor address
    /// @param requester Requester address
    /// @param fulfillFunctionId Selector of the function to be called for
    /// fulfillment
    /// @return subscriptionId Subscription ID
    function storeSubscription(
        uint256 chainId,
        address airnode,
        bytes32 templateId,
        bytes calldata parameters,
        bytes calldata conditions,
        address relayer,
        address sponsor,
        address requester,
        bytes4 fulfillFunctionId
    ) external override returns (bytes32 subscriptionId) {
        require(chainId != 0, "Chain ID zero");
        require(airnode != address(0), "Airnode address zero");
        require(
            parameters.length <= MAXIMUM_PARAMETER_LENGTH,
            "Parameters too long"
        );
        require(
            conditions.length <= MAXIMUM_PARAMETER_LENGTH,
            "Conditions too long"
        );
        require(relayer != address(0), "Relayer address zero");
        require(sponsor != address(0), "Sponsor address zero");
        require(requester != address(0), "Requester address zero");
        require(fulfillFunctionId != bytes4(0), "Fulfill function ID zero");
        subscriptionId = keccak256(
            abi.encode(
                chainId,
                airnode,
                templateId,
                parameters,
                conditions,
                relayer,
                sponsor,
                requester,
                fulfillFunctionId
            )
        );
        subscriptions[subscriptionId] = Subscription({
            chainId: chainId,
            airnode: airnode,
            templateId: templateId,
            parameters: parameters,
            conditions: conditions,
            relayer: relayer,
            sponsor: sponsor,
            requester: requester,
            fulfillFunctionId: fulfillFunctionId
        });
        emit StoredSubscription(
            subscriptionId,
            chainId,
            airnode,
            templateId,
            parameters,
            conditions,
            relayer,
            sponsor,
            requester,
            fulfillFunctionId
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/ISponsorshipUtils.sol";

/// @title Contract that sponsors can use to announce their willingness to
/// sponsor a particular RRP requester or PSP subscription
/// @notice The sponsorship status is not checked during requests or
/// fulfillments, which means the respective Airnode is trusted to make this
/// check through a static call to this contract. The Airnode may skip this
/// check if it has received an off-chain assurance.
/// @dev An Airnode (or relayer) has a "sponsor wallet" dedicated for each
/// account through an HD wallet. When a requester makes a request specifying a
/// sponsor, the Airnode verifies the sponsorship my making a static call to
/// this contract, and uses the respective sponsor wallet to fulfill the
/// request. This allows the sponsor to cover the gas costs of the
/// fulfillments, as they know that funds they have deposited in the respective
/// sponsor wallet will only be used for use-cases they have sponsored.
contract SponsorshipUtils is ISponsorshipUtils {
    /// @notice Sponsorship status for a sponsor–RRP requester pair
    mapping(address => mapping(address => bool))
        public
        override sponsorToRequesterToRrpSponsorshipStatus;

    /// @notice Sponsorship status for a sponsor–PSP subscription pair
    mapping(address => mapping(bytes32 => bool))
        public
        override sponsorToSubscriptionIdToPspSponsorshipStatus;

    /// @notice Called by the sponsor to set the sponsorship status of an RRP
    /// requester
    /// @dev This applies for both regular and relayed RRP requests.
    /// In all contracts, we use the "set" verb to refer to setting a value
    /// without considering its previous value, and emitting an event whether
    /// a state change has occurred or not.
    /// @param requester RRP requester address
    /// @param status Sponsorship status
    function setRrpSponsorshipStatus(address requester, bool status)
        external
        override
    {
        require(requester != address(0), "Requester address zero");
        sponsorToRequesterToRrpSponsorshipStatus[msg.sender][
            requester
        ] = status;
        emit SetRrpSponsorshipStatus(msg.sender, requester, status);
    }

    /// @notice Called by the sponsor to set the sponsorship status of a PSP
    /// subscription
    /// @param subscriptionId Subscription ID
    /// @param status Sponsorship status
    function setPspSponsorshipStatus(bytes32 subscriptionId, bool status)
        external
        override
    {
        require(subscriptionId != bytes32(0), "Subscription ID zero");
        sponsorToSubscriptionIdToPspSponsorshipStatus[msg.sender][
            subscriptionId
        ] = status;
        emit SetPspSponsorshipStatus(msg.sender, subscriptionId, status);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IWithdrawalUtils.sol";

/// @title Contract that can be used by sponsors to request withdrawals from
/// sponsor wallets and Airnodes/relayers to fulfill these
/// @notice The respective Airnode/relayer may not support withdrawals for the
/// specified protocol, or at all. Similarly, an Airnode/relayer may deposit
/// funds directly to the sponsor address without being prompted, e.g., because
/// they are ceasing operations. In general, no guarantee is provided for the
/// funds deposited to sponsor wallets at the protocol level. Therefore, the
/// sponsors should limit their deposits to the minimum amount required for
/// their operations, and assume they will not receive these funds back.
/// @dev Withdrawals are implemented in the form of pull payments. The sponsor
/// requests a withdrawal from a sponsor wallet, and the Airnode/relayer uses
/// the specified sponsor wallet to deposit the entire balance at this
/// contract. Then, the sponsor claims/pulls the payment from this contract.
/// Different protocols (RRP, PSP, etc.) use different sponsor wallets for a
/// particular Airnode/relayer–sponsor pair, which is why sponsor wallet
/// derivation includes a protocol ID. Refer to the node documentation for what
/// these protocol IDs are.
contract WithdrawalUtils is IWithdrawalUtils {
    using ECDSA for bytes32;

    /// @notice Sponsor balance that is withdrawn but not claimed
    mapping(address => uint256) public override sponsorToBalance;

    /// @notice Number of withdrawal requests the sponsor made
    /// @dev This can be used to calculate the ID of the next withdrawal
    /// request the sponsor will make
    mapping(address => uint256) public override sponsorToWithdrawalRequestCount;

    mapping(bytes32 => bytes32) private withdrawalRequestIdToParameters;

    /// @notice Called by a sponsor to request a withdrawal
    /// @param airnodeOrRelayer Airnode/relayer address
    /// @param protocolId Protocol ID
    function requestWithdrawal(address airnodeOrRelayer, uint256 protocolId)
        external
        override
    {
        require(airnodeOrRelayer != address(0), "Airnode/relayer address zero");
        require(protocolId != 0, "Protocol ID zero");
        bytes32 withdrawalRequestId = keccak256(
            abi.encodePacked(
                block.chainid,
                address(this),
                msg.sender,
                ++sponsorToWithdrawalRequestCount[msg.sender]
            )
        );
        withdrawalRequestIdToParameters[withdrawalRequestId] = keccak256(
            abi.encodePacked(airnodeOrRelayer, protocolId, msg.sender)
        );
        emit RequestedWithdrawal(
            airnodeOrRelayer,
            msg.sender,
            withdrawalRequestId,
            protocolId
        );
    }

    /// @notice Called by the Airnode/relayer using the sponsor wallet to
    /// fulfill the withdrawal request made by the sponsor
    /// @param withdrawalRequestId Withdrawal request ID
    /// @param airnodeOrRelayer Airnode/relayer address
    /// @param protocolId Protocol ID
    /// @param sponsor Sponsor address
    function fulfillWithdrawal(
        bytes32 withdrawalRequestId,
        address airnodeOrRelayer,
        uint256 protocolId,
        address sponsor,
        uint256 timestamp,
        bytes calldata signature
    ) external payable override {
        require(
            withdrawalRequestIdToParameters[withdrawalRequestId] ==
                keccak256(
                    abi.encodePacked(airnodeOrRelayer, protocolId, sponsor)
                ),
            "Invalid withdrawal fulfillment"
        );
        require(
            timestamp + 1 hours > block.timestamp &&
                timestamp < block.timestamp + 15 minutes,
            "Timestamp not valid"
        );
        require(
            (
                keccak256(
                    abi.encodePacked(withdrawalRequestId, timestamp, msg.sender)
                ).toEthSignedMessageHash()
            ).recover(signature) == airnodeOrRelayer,
            "Signature mismatch"
        );
        delete withdrawalRequestIdToParameters[withdrawalRequestId];
        sponsorToBalance[sponsor] += msg.value;
        emit FulfilledWithdrawal(
            airnodeOrRelayer,
            sponsor,
            withdrawalRequestId,
            protocolId,
            msg.sender,
            msg.value
        );
    }

    /// @notice Called by the sponsor to claim the withdrawn funds
    /// @dev The sponsor must be able to receive funds. For example, if the
    /// sponsor is a contract without a default `payable` function, this will
    /// revert.
    function claimBalance() external override {
        uint256 sponsorBalance = sponsorToBalance[msg.sender];
        require(sponsorBalance != 0, "Sender balance zero");
        sponsorToBalance[msg.sender] = 0;
        emit ClaimedBalance(msg.sender, sponsorBalance);
        (bool success, ) = msg.sender.call{value: sponsorBalance}(""); // solhint-disable-line avoid-low-level-calls
        require(success, "Transfer failed");
    }

    /// @notice Returns if the withdrawal request with the ID is made but not
    /// fulfilled yet
    /// @param withdrawalRequestId Withdrawal request ID
    /// @return isAwaitingFulfillment If the withdrawal request is awaiting
    /// fulfillment
    function withdrawalRequestIsAwaitingFulfillment(bytes32 withdrawalRequestId)
        external
        view
        override
        returns (bool)
    {
        return
            withdrawalRequestIdToParameters[withdrawalRequestId] != bytes32(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Multicall.sol";

/// @notice Contract that extends the functionality of Multicall to cover the
/// retrieval of some globally available variables
contract ExtendedMulticall is Multicall {
    /// @notice Returns the chain ID
    /// @return Chain ID
    function getChainId() external view returns (uint256) {
        return block.chainid;
    }

    /// @notice Returns the account balance
    /// @param account Account address
    /// @return Account balance
    function getBalance(address account) external view returns (uint256) {
        return account.balance;
    }

    /// @notice Returns the current block number
    /// @return Current block number
    function getBlockNumber() external view returns (uint256) {
        return block.number;
    }

    /// @notice Returns the current block timestamp
    /// @return Current block timestamp
    function getBlockTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    /// @notice Returns the current block basefee
    /// @return Current block basefee
    function getBlockBasefee() external view returns (uint256) {
        return block.basefee;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IStorageUtils.sol";
import "./ISponsorshipUtils.sol";
import "./IWithdrawalUtils.sol";

interface IAirnodeProtocol is
    IStorageUtils,
    ISponsorshipUtils,
    IWithdrawalUtils
{
    event MadeRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        address requester,
        uint256 requesterRequestCount,
        bytes32 templateId,
        bytes parameters,
        address sponsor,
        bytes4 fulfillFunctionId
    );

    event FulfilledRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 timestamp,
        bytes data
    );

    event FailedRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 timestamp,
        string errorMessage
    );

    event MadeRequestRelayed(
        address indexed relayer,
        bytes32 indexed requestId,
        address indexed airnode,
        address requester,
        uint256 requesterRequestCount,
        bytes32 templateId,
        bytes parameters,
        address sponsor,
        bytes4 fulfillFunctionId
    );

    event FulfilledRequestRelayed(
        address indexed relayer,
        bytes32 indexed requestId,
        address indexed airnode,
        uint256 timestamp,
        bytes data
    );

    event FailedRequestRelayed(
        address indexed relayer,
        bytes32 indexed requestId,
        address indexed airnode,
        uint256 timestamp,
        string errorMessage
    );

    function makeRequest(
        address airnode,
        bytes32 templateId,
        bytes calldata parameters,
        address sponsor,
        bytes4 fulfillFunctionId
    ) external returns (bytes32 requestId);

    function fulfillRequest(
        bytes32 requestId,
        address airnode,
        address requester,
        bytes4 fulfillFunctionId,
        uint256 timestamp,
        bytes calldata data,
        bytes calldata signature
    ) external returns (bool callSuccess, bytes memory callData);

    function failRequest(
        bytes32 requestId,
        address airnode,
        address requester,
        bytes4 fulfillFunctionId,
        uint256 timestamp,
        string calldata errorMessage,
        bytes calldata signature
    ) external;

    function makeRequestRelayed(
        address airnode,
        bytes32 templateId,
        bytes calldata parameters,
        address relayer,
        address sponsor,
        bytes4 fulfillFunctionId
    ) external returns (bytes32 requestId);

    function fulfillRequestRelayed(
        bytes32 requestId,
        address airnode,
        address requester,
        address relayer,
        bytes4 fulfillFunctionId,
        uint256 timestamp,
        bytes calldata data,
        bytes calldata signature
    ) external returns (bool callSuccess, bytes memory callData);

    function failRequestRelayed(
        bytes32 requestId,
        address airnode,
        address requester,
        address relayer,
        bytes4 fulfillFunctionId,
        uint256 timestamp,
        string calldata errorMessage,
        bytes calldata signature
    ) external;

    function requestIsAwaitingFulfillment(bytes32 requestId)
        external
        view
        returns (bool);

    function requesterToRequestCount(address requester)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStorageUtils {
    event StoredTemplate(
        bytes32 indexed templateId,
        bytes32 endpointId,
        bytes parameters
    );

    event StoredSubscription(
        bytes32 indexed subscriptionId,
        uint256 chainId,
        address airnode,
        bytes32 templateId,
        bytes parameters,
        bytes conditions,
        address relayer,
        address sponsor,
        address requester,
        bytes4 fulfillFunctionId
    );

    function storeTemplate(bytes32 endpointId, bytes calldata parameters)
        external
        returns (bytes32 templateId);

    function storeSubscription(
        uint256 chainId,
        address airnode,
        bytes32 templateId,
        bytes calldata parameters,
        bytes calldata conditions,
        address relayer,
        address sponsor,
        address requester,
        bytes4 fulfillFunctionId
    ) external returns (bytes32 subscriptionId);

    // solhint-disable-next-line func-name-mixedcase
    function MAXIMUM_PARAMETER_LENGTH() external view returns (uint256);

    function templates(bytes32 templateId)
        external
        view
        returns (bytes32 endpointId, bytes memory parameters);

    function subscriptions(bytes32 subscriptionId)
        external
        view
        returns (
            uint256 chainId,
            address airnode,
            bytes32 templateId,
            bytes memory parameters,
            bytes memory conditions,
            address relayer,
            address sponsor,
            address requester,
            bytes4 fulfillFunctionId
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISponsorshipUtils {
    event SetRrpSponsorshipStatus(
        address indexed sponsor,
        address indexed requester,
        bool status
    );

    event SetPspSponsorshipStatus(
        address indexed sponsor,
        bytes32 indexed subscriptionId,
        bool status
    );

    function setRrpSponsorshipStatus(address requester, bool status) external;

    function setPspSponsorshipStatus(bytes32 subscriptionId, bool status)
        external;

    function sponsorToRequesterToRrpSponsorshipStatus(
        address sponsor,
        address requester
    ) external view returns (bool status);

    function sponsorToSubscriptionIdToPspSponsorshipStatus(
        address sponsor,
        bytes32 subscriptionId
    ) external view returns (bool status);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWithdrawalUtils {
    event RequestedWithdrawal(
        address indexed airnodeOrRelayer,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        uint256 protocolId
    );

    event FulfilledWithdrawal(
        address indexed airnodeOrRelayer,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        uint256 protocolId,
        address sponsorWallet,
        uint256 amount
    );

    event ClaimedBalance(address indexed sponsor, uint256 amount);

    function requestWithdrawal(address airnodeOrRelayer, uint256 protocolId)
        external;

    function fulfillWithdrawal(
        bytes32 withdrawalRequestId,
        address airnodeOrRelayer,
        uint256 protocolId,
        address sponsor,
        uint256 timestamp,
        bytes calldata signature
    ) external payable;

    function claimBalance() external;

    function withdrawalRequestIsAwaitingFulfillment(bytes32 withdrawalRequestId)
        external
        view
        returns (bool);

    function sponsorToBalance(address sponsor) external view returns (uint256);

    function sponsorToWithdrawalRequestCount(address sponsor)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}