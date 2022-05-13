// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../interfaces/IFinalizeAuctionController.sol";
import "./utils/EnglishAuctionStorage.sol";
import "./utils/EIP712.sol";
import "./SafeEthSender.sol";

contract EnglishAuction is EnglishAuctionStorage, SafeEthSender, EIP712 {
    bytes32 immutable BID_TYPEHASH =
        keccak256("Bid(uint32 auctionId,address bidder,uint256 value)");

    event AuctionCreated(uint32 auctionId);
    event AuctionCanceled(uint32 auctionId);
    event AuctionCanceledByAdmin(uint32 auctionId, string reason);
    event AuctionFinalized(uint32 auctionId, uint256 auctionBalance);
    event AuctionBidPlaced(uint32 auctionId, address bidder, uint256 amount);

    constructor(
        address _accessManangerAddress,
        address payable _withdrawalAddress
    ) EIP712("Place Bid", "1") {
        accessManager = IAccessManager(_accessManangerAddress);
        withdrawalAddress = _withdrawalAddress;
        initializeAuction();
    }

    modifier isOperationalAddress() {
        require(
            accessManager.isOperationalAddress(msg.sender) == true,
            "English Auction: You are not allowed to use this function"
        );
        _;
    }

    function setWithdrawalAddress(address payable _newWithdrawalAddress)
        public
        isOperationalAddress
    {
        withdrawalAddress = _newWithdrawalAddress;
    }

    function createAuction(
        uint32 _tokenId,
        uint32 _timeStart,
        uint32 _timeEnd,
        uint8 _minBidPercentage,
        uint256 _initialPrice,
        uint256 _minBidValue,
        address _nftContractAddress,
        address _finalizeAuctionControllerAddress,
        bytes memory _additionalDataForFinalizeAuction
    ) public isOperationalAddress {
        require(
            _initialPrice > 0,
            "English Auction: Initial price have to be bigger than zero"
        );

        uint32 currentAuctionId = incrementAuctionId();
        auctionIdToAuction[currentAuctionId] = AuctionStruct(
            _tokenId,
            _timeStart,
            _timeEnd,
            _minBidPercentage,
            _initialPrice,
            _minBidValue,
            0, //auctionBalance
            _nftContractAddress,
            _finalizeAuctionControllerAddress,
            payable(address(0)),
            _additionalDataForFinalizeAuction
        );

        emit AuctionCreated(currentAuctionId);
    }

    function incrementAuctionId() private returns (uint32) {
        return lastAuctionId++;
    }

    /**
     * @notice Returns auction details for a given auctionId.
     */
    function getAuction(uint32 _auctionId)
        public
        view
        returns (AuctionStruct memory)
    {
        return auctionIdToAuction[_auctionId];
    }

    function initializeAuction() private {
        lastAuctionId = 1;
    }

    function placeBid(uint32 _auctionId, bytes memory _signature)
        public
        payable
    {
        placeBid(_auctionId, _signature, msg.sender);
    }

    function placeBid(
        uint32 _auctionId,
        bytes memory _signature,
        address _bidder
    ) public payable {
        bytes32 _hash = _hashTypedDataV4(
            keccak256(abi.encode(BID_TYPEHASH, _auctionId, _bidder, msg.value))
        );
        address recoverAddress = ECDSA.recover(_hash, _signature);

        require(
            accessManager.isOperationalAddress(recoverAddress) == true,
            "Incorrect bid permission signature"
        );

        AuctionStruct storage auction = auctionIdToAuction[_auctionId];

        require(auction.initialPrice > 0, "English Auction: Auction not found");

        if (auction.timeStart == 0) {
            auction.timeStart = uint32(block.timestamp);
            auction.timeEnd += auction.timeStart;
        }

        require(
            auction.timeStart <= block.timestamp,
            "English Auction: Auction is not active yet"
        );

        require(
            auction.timeEnd > block.timestamp,
            "English Auction: Auction has been finished"
        );

        uint256 requiredBalance = auction.auctionBalance == 0
            ? auction.initialPrice
            : auction.auctionBalance + auction.minBidValue;

        uint256 requiredPercentageValue = (auction.auctionBalance *
            (auction.minBidPercentage + 100)) / 100;

        require(
            msg.value >= requiredBalance &&
                msg.value >= requiredPercentageValue,
            "English Auction: Bid amount was too low"
        );

        uint256 prevBalance = auction.auctionBalance;
        address payable prevBidder = auction.bidder;

        auction.bidder = payable(_bidder);
        auction.auctionBalance = msg.value;
        if ((auction.timeEnd - uint32(block.timestamp)) < 15 minutes) {
            auction.timeEnd = uint32(block.timestamp) + 15 minutes;
        }

        if (prevBalance > 0) {
            sendEthWithLimitedGas(prevBidder, prevBalance, 2300);
        }
        emit AuctionBidPlaced(_auctionId, _bidder, msg.value);
    }

    /**
     * @notice Once the countdown has expired for an auction, anyone can settle the auction.
     * This will send the NFT to the highest bidder and distribute funds.
     */
    function finalizeAuction(uint32 _auctionId) external {
        AuctionStruct memory auction = auctionIdToAuction[_auctionId];

        uint256 auctionBalance = auction.auctionBalance;

        require(auction.timeEnd > 0, "English Auction: Auction not found");

        require(
            auction.timeEnd <= block.timestamp,
            "English Auction: Auction is still in progress"
        );

        IFinalizeAuctionController finalizeAuctionController = IFinalizeAuctionController(
                auction.finalizeAuctionControllerAddress
            );

        (bool success, ) = auction
            .finalizeAuctionControllerAddress
            .delegatecall(
                abi.encodeWithSelector(
                    finalizeAuctionController.finalize.selector,
                    _auctionId
                )
            );

        require(success, "FinalizeAuction: DelegateCall failed");

        delete auctionIdToAuction[_auctionId];

        emit AuctionFinalized(_auctionId, auctionBalance);
    }

    /**
     * @notice If an auction has been created but has not yet received bids, it may be canceled by the seller.
     */
    function cancelAuction(uint32 _auctionId) external {
        AuctionStruct memory auction = auctionIdToAuction[_auctionId];

        IFinalizeAuctionController finalizeAuctionController = IFinalizeAuctionController(
                auction.finalizeAuctionControllerAddress
            );

        (bool success, ) = auction
            .finalizeAuctionControllerAddress
            .delegatecall(
                abi.encodeWithSelector(
                    finalizeAuctionController.cancel.selector,
                    _auctionId
                )
            );

        require(success, "CancelAuction: DelegateCall failed");

        delete auctionIdToAuction[_auctionId];

        emit AuctionCanceled(_auctionId);
    }

    /**
     * @notice Allows Nifties to cancel an auction, refunding the bidder and returning the NFT to the seller.
     * This should only be used for extreme cases such as DMCA takedown requests. The reason should always be provided.
     */
    function adminCancelAuction(uint32 _auctionId, string memory _reason)
        public
        isOperationalAddress
    {
        AuctionStruct memory auction = auctionIdToAuction[_auctionId];

        IFinalizeAuctionController finalizeAuctionController = IFinalizeAuctionController(
                auction.finalizeAuctionControllerAddress
            );

        (bool success, ) = auction
            .finalizeAuctionControllerAddress
            .delegatecall(
                abi.encodeWithSelector(
                    finalizeAuctionController.adminCancel.selector,
                    _auctionId,
                    _reason
                )
            );

        require(success, "AdminCancelAuction: DelegateCall failed");

        if (auction.bidder != address(0)) {
            uint256 bidderAmount = auction.auctionBalance;
            auction.auctionBalance -= auction.auctionBalance;

            sendEthWithLimitedGas(auction.bidder, bidderAmount, 2300);
        }

        delete auctionIdToAuction[_auctionId];

        emit AuctionCanceledByAdmin(_auctionId, _reason);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./utils/CallHelpers.sol";

abstract contract SafeEthSender is ReentrancyGuard {
    mapping(address => uint256) private withdrawRegistry;

    event PendingWithdraw(address _user, uint256 _amount);
    event Withdrawn(address _user, uint256 _amount);

    constructor() ReentrancyGuard() {}

    function sendEthWithLimitedGas(
        address payable _user,
        uint256 _amount,
        uint256 _gasLimit
    ) internal {
        if (_amount == 0) {
            return;
        }

        (bool success, ) = _user.call{value: _amount, gas: _gasLimit}("");
        if (!success) {
            withdrawRegistry[_user] += _amount;

            emit PendingWithdraw(_user, _amount);
        }
    }

    function getAmountToWithdrawForUser(address user)
        public
        view
        returns (uint256)
    {
        return withdrawRegistry[user];
    }

    function withdrawPendingEth() external {
        this.withdrawPendingEthFor(payable(msg.sender));
    }

    function withdrawPendingEthFor(address payable _user)
        external
        nonReentrant
    {
        uint256 amount = withdrawRegistry[_user];
        require(amount > 0, "SafeEthSender: no funds to withdraw");
        withdrawRegistry[_user] = 0;
        (bool success, bytes memory response) = _user.call{value: amount}("");

        if (!success) {
            string memory message = CallHelpers.getRevertMsg(response);
            revert(message);
        }

        emit Withdrawn(_user, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library CallHelpers {
    function getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;

        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash)
        internal
        view
        virtual
        returns (bytes32)
    {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../../interfaces/IAccessManager.sol";

abstract contract EnglishAuctionStorage {
    uint32 lastAuctionId;
    address payable public withdrawalAddress;
    IAccessManager accessManager;

    struct AuctionStruct {
        uint32 tokenId;
        uint32 timeStart;
        uint32 timeEnd;
        uint8 minBidPercentage;
        uint256 initialPrice;
        uint256 minBidValue;
        uint256 auctionBalance;
        address nftContractAddress;
        address finalizeAuctionControllerAddress;
        address payable bidder;
        bytes additionalDataForFinalizeAuction;
    }

    mapping(uint32 => AuctionStruct) auctionIdToAuction;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IAccessManager {
    function isOperationalAddress(address _address)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IFinalizeAuctionController {
    function finalize(uint32 _auctionId) external;

    function cancel(uint32 _auctionId) external;

    function adminCancel(uint32 _auctionId, string memory _reason) external;

    function getAuctionType() external view returns (string memory);
}