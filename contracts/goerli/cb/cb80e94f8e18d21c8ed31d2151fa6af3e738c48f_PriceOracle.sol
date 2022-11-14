// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ReservoirOracle} from "oracle/ReservoirOracle.sol";

// In order to enforce the proper payout of royalties, we need an oracle
// attesting the price of the token for which royalties are paid. It can
// be the floor price or the appraised price (or even something else).
contract PriceOracle is ReservoirOracle {
    // Constructor

    constructor(address reservoirSigner) ReservoirOracle(reservoirSigner) {}

    // Public methods

    function getPrice(
        // On-chain data
        address token,
        uint256 tokenId,
        uint256 maxAge,
        // Off-chain data
        bytes calldata offChainData
    ) external view returns (uint256) {
        // Decode the off-chain data
        ReservoirOracle.Message memory message = abi.decode(
            offChainData,
            (ReservoirOracle.Message)
        );

        // Construct the wanted message id
        bytes32 id = keccak256(
            abi.encode(
                // keccak256("CollectionPriceByToken(uint8 kind,uint256 twapSeconds,address token,uint256 tokenId)")
                0x4163bce510ba405523529cf23054a8ff50e064fa158d7a8a76df334bfcfad6ef,
                uint8(0), // PriceKind.SPOT
                uint256(0),
                token,
                tokenId
            )
        );

        // Validate the message
        if (!_verifyMessage(id, maxAge, message)) {
            revert InvalidMessage();
        }

        // Decode the message's payload
        (address currency, uint256 price) = abi.decode(
            message.payload,
            (address, uint256)
        );

        // The currency should be ETH
        if (currency != address(0)) {
            revert InvalidMessage();
        }

        return price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Inspired by https://github.com/ZeframLou/trustus
abstract contract ReservoirOracle {
    // --- Structs ---

    struct Message {
        bytes32 id;
        bytes payload;
        // The UNIX timestamp when the message was signed by the oracle
        uint256 timestamp;
        // ECDSA signature or EIP-2098 compact signature
        bytes signature;
    }

    // --- Errors ---

    error InvalidMessage();

    // --- Fields ---

    address immutable RESERVOIR_ORACLE_ADDRESS;

    // --- Constructor ---

    constructor(address reservoirOracleAddress) {
        RESERVOIR_ORACLE_ADDRESS = reservoirOracleAddress;
    }

    // --- Internal methods ---

    function _verifyMessage(
        bytes32 id,
        uint256 validFor,
        Message memory message
    ) internal view virtual returns (bool success) {
        // Ensure the message matches the requested id
        if (id != message.id) {
            return false;
        }

        // Ensure the message timestamp is valid
        if (
            message.timestamp > block.timestamp ||
            message.timestamp + validFor < block.timestamp
        ) {
            return false;
        }

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Extract the individual signature fields from the signature
        bytes memory signature = message.signature;
        if (signature.length == 64) {
            // EIP-2098 compact signature
            bytes32 vs;
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
                s := and(
                    vs,
                    0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                )
                v := add(shr(255, vs), 27)
            }
        } else if (signature.length == 65) {
            // ECDSA signature
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else {
            return false;
        }

        address signerAddress = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    // EIP-712 structured-data hash
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Message(bytes32 id,bytes payload,uint256 timestamp)"
                            ),
                            message.id,
                            keccak256(message.payload),
                            message.timestamp
                        )
                    )
                )
            ),
            v,
            r,
            s
        );

        // Ensure the signer matches the designated oracle address
        return signerAddress == RESERVOIR_ORACLE_ADDRESS;
    }
}