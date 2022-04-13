// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/* Copyright Metallicus 2022 - All Rights Reserved */

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import { INFTBridge } from "./interfaces/INFTBridge.sol";

/*
 * @dev {NFTBridge} contract allows depositing of NFTs (ERC721/ERC1155 standard tokens)
 * for bridging them across EOSIO chain.
 *
 * Bridging of NFTs to and from EOSIO chain is facilitated by the quorum of
 * {oracles} where each of them sign the data representing locking (teleporting)
 * and unlocking of NFTs.
 *
 * A user can transfer its NFT to the {NFTBridge} contract's address and the {from} and {id/tokenId}
 * parameters of functions {onERC721Received}, {onERC1155Received} and {onERC1155BatchReceived}
 * are used to keep track of who deposited the token along with its {id/tokenId}.
 *
 * A user can lock their NFTs for bridging it cross chain by calling {teleport} function
 * which emits {Teleported} event. If an invalid EOSIO name is provided then the NFT
 * is locked in the contract which can only be unlocked by the quorum of oracles signed
 * signatures passed to the {unlock} function. The user can later call {claim} function
 * to get back their NFT.
 *
 * If a user's NFTs is successfully bridged across chain and locked then unlocking requires
 * quorum of oracles signed signatures passed to the {unlock} function.
 * The user can later call {claim} function to get back their NFT.
 *
 * If a user's token is neither locked nor teleported then they are able to get back
 * their NFT by simply calling {claim} function.
 **/
contract NFTBridge is
    INFTBridge,
    IERC721Receiver,
    IERC1155Receiver,
    Ownable
{
    // Linking signature verifying library with {bytes32} type.
    using ECDSA for bytes32;

    /*
     * @dev {TokenData} represents data about the deposited NFT.
     * owner: Address representing owner of NFT.
     * locked: If the NFT is currently locked or not.
     * isERC721: True if the NFT is from the contract implementing standard ERC721
     * and false if it implements standard ERC1155.
     **/
    struct TokenData {
        address owner;
        bool locked;
    }

    // Mapping of (nft address => token id => token data)
    mapping(address => mapping(uint256 => TokenData)) public nftDeposit;

    // Mapping of (nft address => approve status)
    mapping(address => bool) public approvedNFT;

    // Mapping of (requestId => execution status)
    mapping(uint256 => bool) public executed;

    // List of addresses of {oracles}.
    address[] public oracles;

    // Minimum number of valid signatures required to reach quorum.
    uint256 public threshold;

    /*
     * @dev {supportsInterface} function allows successful receiving of
     * NFTs from token contracts implementing ERC721 or ERC1155 standard.
     *
     * @param interfaceId The interface id to check for implementation.
     * @return bool to show if the provided {interfaceId} is implemented.
     **/
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        returns (bool)
    {
        return
            interfaceId == this.onERC721Received.selector
            || interfaceId == this.onERC1155Received.selector
            || interfaceId == this.onERC1155BatchReceived.selector;
    }

    /*
     * @dev {initConsensus} function allows initializing the contract with
     * the list of {oracles} and {threshold}.
     *
     * @param initialOracles List of oracles.
     * @param initialThreshold Minimum number of signatures required for quorum.
     *
     * Requirements:
     * - Can only be called by the contract {owner}.
     **/
    function initConsensus(
        address[] calldata initialOracles,
        uint256 initialThreshold
    )
        onlyOwner
        external
        returns (bool success)
    {
        return _setConsensus(initialOracles, initialThreshold);
    }

    /*
     * @dev {setNFTApprovalStatus} function allows setting the status of an NFT
     * contract address. {true} being approved and {false} being not approved.
     *
     * @param nft The address of NFT contract.
     * @param approve The status to set for the NFT contract.
     *
     * Requirements:
     * - Can only be called by the contract {owner}.
     * - Cannot set an already set status.
     **/
    function setNFTApprovalStatus(
        address nft,
        bool approve
    ) external onlyOwner {
        require(
            approvedNFT[nft] != approve,
            "NFTBridge::setNFTApprovalStatus: NFT status is already set"
        );
        approvedNFT[nft] = approve;

        emit NFTApprovalStatusSet(nft, approve);
    }

    /*
     * @dev {updateConsensus} function allows updating the list of {oracles}
     * and {threshold} through the quorum of signatures from the current list
     * of {oracles}.
     *
     * @param newOracles The list of new {oracles}.
     * @param newThreshold The new {threshold} required to reach consensus.
     * @param signatures The list of signatures.
     * @param signers The list of signer addresses corresponding to the {signatures}.
     *
     * Requirements:
     * - The {oracles} list is already initialized.
     * - The provided list of {signatures} reach quorum.
     **/
    function updateConsensus(
        uint256 requestId,
        address[] calldata newOracles,
        uint256 newThreshold,
        bytes[] calldata signatures
    )
        external
        returns (bool success)
    {
        require(
            oracles.length != 0,
            "NFTBridge::updateConsensus: consensus is not initialized"
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                hex'0001',
                requestId,
                newOracles,
                newThreshold
            )
        );
        
        require(
            _validateSignaturesAndTx(signatures, hash, requestId),
            "NFTBridge::updateConsensus: consensus failed"
        );

        return _setConsensus(newOracles, newThreshold);
    }

    /*
     * @dev {claim} function allows claiming of NFTs.
     * It transfers the NFT from contract's ownership to the actual
     * owner retrieved from the mapping {nftDeposit.}
     *
     * The function is publicly callable but the recipient of the NFT
     * is always the owner from {nftDeposit} mapping.
     *
     * @param tokenContract The address of token contract of which the NFTs
     * are being claimed.
     * @param tokenIds The Ids of the tokens to be claimed from contract {tokenContract}.
     *
     * Requirements:
     * - The token/s being claimed must not be locked.
     **/
    function claim(
        address tokenContract,
        uint256[] calldata tokenIds
    )
        external
        returns (bool success)
    {
        mapping(uint256 => TokenData) storage idToTokenData
            = nftDeposit[tokenContract];

        bool is721 = ERC165(tokenContract)
            .supportsInterface(type(IERC721).interfaceId);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            TokenData storage tokenData = idToTokenData[tokenIds[i]];
            require(
                !tokenData.locked,
                "NFTBridge::claim: token is locked"
            );

            if (is721)
                IERC721(tokenContract).transferFrom(
                    address(this),
                    tokenData.owner,
                    tokenIds[i]
                );
            else
                IERC1155(tokenContract).safeTransferFrom(
                    address(this),
                    tokenData.owner,
                    tokenIds[i],
                    1,
                    ""
                );

            delete idToTokenData[tokenIds[i]];
        }

        emit NFTClaimed(tokenContract, tokenIds);
        return true;
    }

    /*
     * @dev {teleport} function allows bridging of NFT across the chain.
     * It locks the NFT being teleported and emit the {Teleported} event.
     *
     * The NFT contract address {tokenContract} must be approved for successfully
     * teleporting the NFT otherwise the NFT is locked and emit {NFTLocked} event.
     *
     * A locked NFT can be only be unlocked by the quorum of {oracles}.
     *
     * @param tokenContract The address of NFT contract.
     * @param tokenIds The list of Ids of tokens from {tokenContract}.
     * @param to The name of EOSIO account.
     *
     * Requirements:
     * - The {msg.sender} must be the owner of NFT/s in {nftDeposit} mapping.
     **/
    function teleport(
        address tokenContract,
        uint256[] calldata tokenIds,
        string calldata to
    )
        external
        returns (bool success)
    {
        mapping(uint256 => TokenData) storage idToTokenData
            = nftDeposit[tokenContract];

        for (uint256 i = 0; i < tokenIds.length; i++) {
            TokenData storage tokenData = idToTokenData[tokenIds[i]];
            require(
                tokenData.owner == msg.sender,
                "NFTBridge::teleport: unauthorized"
            );

            require(
                !tokenData.locked,
                "NFTBridge::teleport: token is locked"
            );

            tokenData.locked = true;
        }

        if (approvedNFT[tokenContract])
            emit Teleported(
                tokenContract,
                tokenIds,
                to
            );
        else
            emit NFTLocked(
                tokenContract,
                tokenIds
            );

        return true;
    }

    /*
     * @dev {unlock} function allows unlocking of NFT by the quorum of signatures
     * from {oracles}.
     *
     * Upon unlocking it unlocks the token and sets {newOwner} as the owner NFT
     * that receives this NFT upon the {claim} function call.
     *
     * @param requestId unique request identifier, must never repeat.
     * @param tokenContract The address of NFT contract.
     * @param tokenId The id of NFT token.
     * @param newOwner The new owner of the NFT.
     * @param signatures The list of signatures from oracles that are checked to decide consensus.
     * @param signers The list of addresses corresponding to the {signatures}.
     *
     * Requirements:
     * - The provided list of {signatures} reach quorum.
     * - The token must be locked.
     **/
    function unlock(
        uint256 requestId,
        address tokenContract,
        uint256[] calldata tokenIds,
        address newOwner,
        bytes[] calldata signatures
    )
        external
        returns (bool success)
    {
        for (uint256 i = 0; i < tokenIds.length; i++)
            require(
                nftDeposit[tokenContract][tokenIds[i]].locked,
                "NFTBridge::unlock: token is not locked"
            );

        bytes32 hash = keccak256(
            abi.encodePacked(
                hex'0101',
                requestId,
                tokenContract,
                tokenIds,
                newOwner
            )
        );

        require(
            _validateSignaturesAndTx(signatures, hash, requestId),
            "NFTBridge::unlock: consensus failed"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            nftDeposit[tokenContract][tokenIds[i]].owner = newOwner;
            nftDeposit[tokenContract][tokenIds[i]].locked = false;
        }

        emit NFTUnlocked(tokenContract, tokenIds, newOwner);
        return true;
    }

    /*
     * @dev {onERC721Received} function is called by the ERC721 contract on
     * the recipient of the NFT if the recipient is a contract.
     *
     * The user must call {safeTransferFrom} function on the ERC721 contract
     * to transfer NFT otherwise this function will not be called essentially
     * locking the user's NFT that can only be unlocked by oracles.
     *
     * It populates the {nftDeposit} mapping with the data of NFT transfer.
     **/
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    )
        external
        returns (bytes4)
    {
        nftDeposit[msg.sender][tokenId] = TokenData(from, false);

        return IERC721Receiver.onERC721Received.selector;
    }

    /*
     * @dev {onERC1155Received} function is called by the ERC1155 contract on
     * the recipient of the NFT if the recipient is a contract.
     *
     * It populates the {nftDeposit} mapping with the data of NFT transfer.
     **/
    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256,
        bytes calldata
    )
        external
        returns (bytes4)
    {
        nftDeposit[msg.sender][id] = TokenData(
            from,
            false
        );

        return IERC1155Receiver.onERC1155Received.selector;
    }

    /*
     * @dev {onERC1155BatchReceived} function is called by the ERC1155 contract on
     * the recipient of the NFT if the recipient is a contract.
     *
     * It populates the {nftDeposit} mapping with the data of NFT transfer.
     **/
    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] calldata ids,
        uint256[] calldata,
        bytes calldata
    )
        external
        returns (bytes4)
    {
        for (uint256 i = 0; i < ids.length; i++) {
            nftDeposit[msg.sender][ids[i]] = TokenData(
                from,
                false
            );
        }

        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    /*
     * @dev {_setConsensus} function is internally called to set the consensus mechanism
     * of the contract.
     *
     * @param _oracles The list of oracles.
     * @param _threshold The minimum count signatures required to reach quorum.
     *
     * Requirements:
     * - {_oracles} length must not be zero.
     * - {_threshold} must be greater than half of {_oracles}'s length.
     **/
    function _setConsensus(
        address[] calldata _oracles,
        uint256 _threshold
    ) private returns (bool success) {
        require(
            _oracles.length >= 3,
            "NFTBridge::_setConsensus: invalid length for initialOracles"
        );

        require(
            _threshold > (_oracles.length / 2),
            "NFTBridge::_setConsensus: not enough quorum threshold value"
        );

        address[] memory validOracles = new address[](_oracles.length);
        uint256 c;
        for (uint256 i = 0; i < _oracles.length; i++) {
            for (uint256 q = 0; q < c; q++)
                require(
                    validOracles[q] != _oracles[i],
                    "NFTBridge::_setConsensus: duplicate oracles addresses provided"
                );

            validOracles[c++] = _oracles[i];
        }

        oracles = _oracles;
        threshold = _threshold;

        emit ConsensusUpdated(_oracles, _threshold);
        return true;
    }

    /*
     * @dev {_validateSignaturesAndTx} function allows validating the signatures such that
     * they are valid and are reaching the quorum.
     *
     * @param _signatures The list of signatures.
     * @param _hashes The list of message hashes corresponding to {_signatures}.
     *
     * Requirements:
     * - Each recovered account from any signature is a valid oracle.
     * - Two signatures must not belong to a single oracle.
     **/
    function _validateSignaturesAndTx(
        bytes[] calldata _signatures,
        bytes32 _hash,
        uint256 requestId
    )
        private
        returns (bool success)
    {
        require(
            !executed[requestId],
            "NFTBridge::_validateSignaturesAndTx: transaction is already executed"
        );
        
        address[] memory _oracles = oracles;
        address[] memory verified = new address[](_oracles.length);
        uint256 c;

        for (uint256 i = 0; i < _signatures.length; i++) {
            address recovered = _hash.recover(_signatures[i]);

            bool isOracle;
            for (uint256 q = 0; q < _oracles.length; q++) {
                isOracle = (recovered == _oracles[q]);

                if (isOracle) break;
            }

            require(
                isOracle,
                "NFTBridge::_validateSignaturesAndTx: unregistered oracle"
            );

            for (uint256 q = 0; q < c; q++)
                require(
                    verified[q] != recovered,
                    "NFTBridge::_validateSignaturesAndTx: duplicate signatures"
                );

            verified[c++] = recovered;
        }

        if (c >= threshold) {
            executed[requestId] = true;
            emit Executed(requestId);
            return true;
        }
        
        return false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface INFTBridge {
    event ConsensusUpdated(address[] oracles, uint256 threshold);

    event Teleported(
        address tokenContract,
        uint256[] tokenIds,
        string to
    );

    event Executed(uint256 requestId);

    event NFTApprovalStatusSet(address nft, bool approved);

    event NFTClaimed(address tokenContract, uint256[] tokenIds);

    event NFTLocked(address tokenContract, uint256[] tokenIds);

    event NFTUnlocked(
        address tokenContract,
        uint256[] tokenIds,
        address owner
    );

    function initConsensus(
        address[] calldata initialOracles,
        uint256 initialThreshold
    ) external returns (bool success);

    function updateConsensus(
        uint256 requestId,
        address[] calldata newOracles,
        uint256 newThreshold,
        bytes[] calldata signatures
    ) external returns (bool success);

    function claim(
        address tokenContract,
        uint256[] calldata tokenIds
    ) external returns (bool success);

    function teleport(
        address tokenContract,
        uint256[] calldata tokenIds,
        string calldata to
    ) external returns (bool success);

    function unlock(
        uint256 requestId,
        address tokenContract,
        uint256[] calldata tokenIds,
        address newOwner,
        bytes[] calldata signatures
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}