// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.25 <0.9.0;

import "./lib/Signing.sol";

contract PricingConfigValidator {

    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }

    struct PricingConfiguration {
        address poolAddress;
        uint256 premiumMultiplierPercent;
        uint256 blockNumber;
    }

    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 constant TYPEHASH = keccak256("PricingConfiguration(address poolAddress,uint256 premiumMultiplierPercent,uint256 block)");

    function hashDomain(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }

    function hash(PricingConfiguration memory config) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            TYPEHASH,
            config.poolAddress,
            config.premiumMultiplierPercent,
            config.blockNumber
        ));
    }

    function getSigner(PricingConfiguration memory pricingConfig, bytes memory _signature) public view returns (address) {
        bytes32 domainSeparator = hashDomain(EIP712Domain({
            name: "PricingConfigValidator",
            version: '1',
            chainId: 5,
            verifyingContract: address(this)
        }));
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            domainSeparator,
            hash(pricingConfig)
        ));
        return Signing.recoverSigner(digest, _signature);
    }

    function verify(PricingConfiguration calldata pricingConfig, bytes memory _signature, address _signer) external view returns (bool) {
        return getSigner(pricingConfig, _signature) == _signer;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.25 <0.9.0;

library WasabiStructs {
    enum OptionType { CALL, PUT }

    struct OptionData {
        OptionType optionType;
        uint256 strikePrice;
        uint256 premium;
        uint256 expiry;
        uint256 tokenId; // Tokens to deposit for CALL options
    }

    struct OptionRequest {
        address poolAddress;
        OptionType optionType;
        uint256 strikePrice;
        uint256 premium;
        uint256 duration;
        uint256 tokenId; // Tokens to deposit for CALL options
        uint256 maxBlockToExecute;
    }

    struct PoolConfiguration {
        uint256 minStrikePrice;
        uint256 maxStrikePrice;
        uint256 minDuration;
        uint256 maxDuration;
    }

    struct Bid {
        uint256 id;
        uint256 price;
        address tokenAddress;
        address collection;
        uint256 orderExpiry;
        address buyer;
        OptionType optionType;
        uint256 strikePrice;
        uint256 expiry;
        uint256 expiryAllowance;
    }

    struct Ask {
        uint256 id;
        uint256 price;
        address tokenAddress;
        uint256 orderExpiry;
        address seller;
        uint256 optionId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.9.0;

import {WasabiStructs} from "./WasabiStructs.sol";

/**
 * @dev Signature Verification
 */
library Signing {

    /**
     * @dev Returns the message hash for the given request
     */
    function getMessageHash(WasabiStructs.OptionRequest calldata _request) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _request.poolAddress,
                _request.optionType,
                _request.strikePrice,
                _request.premium,
                _request.duration,
                _request.tokenId,
                _request.maxBlockToExecute));
    }

    /**
     * @dev Returns the message hash for the given request
     */
    function getAskHash(WasabiStructs.Ask calldata _ask) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _ask.id,
                _ask.price,
                _ask.tokenAddress,
                _ask.orderExpiry,
                _ask.seller,
                _ask.optionId));
    }

    function getBidHash(WasabiStructs.Bid calldata _bid) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _bid.id,
                _bid.price,
                _bid.tokenAddress,
                _bid.collection,
                _bid.orderExpiry,
                _bid.buyer,
                _bid.optionType,
                _bid.strikePrice,
                _bid.expiry,
                _bid.expiryAllowance));
    }

    /**
     * @dev creates an ETH signed message hash
     */
    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function getSigner(
        WasabiStructs.OptionRequest calldata _request,
        bytes memory signature
    ) public pure returns (address) {
        bytes32 messageHash = getMessageHash(_request);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature);
    }

    function getAskSigner(
        WasabiStructs.Ask calldata _ask,
        bytes memory signature
    ) public pure returns (address) {
        bytes32 messageHash = getAskHash(_ask);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature);
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}