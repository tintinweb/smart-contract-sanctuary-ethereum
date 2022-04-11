// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ECDSA.sol";
import "../Ownable.sol";
import "../IERC721.sol";

contract MonaGallery is Ownable {

    struct OnChainListing {
        uint expirationTimestamp;
        uint artistId;
        uint tokenId;
        uint price;
        // uint nonce;
    }

    struct Artist {
        address tokenContract;
        address addr;
        uint percentage;
    }

    struct OnChainExternalNFTListing {
        address tokenContract;
        address artistAddr;
        uint tokenId;
        uint price;
        uint expirationTimestamp;
    }

    mapping(bytes => bool) usedSigs;
    mapping(uint => bool) _onChainListingsCompleted;
    mapping(uint => bool) _ExternalOnChainListingsCompleted;


    Artist[] public artists;
    OnChainListing[] public onChainListings;
    OnChainExternalNFTListing[] public onChainExternalNFTListings;

    uint public activeOnChainListings;
    uint public activeExternalOnChainListings;


    event NewArtist(address tokenContract, address addr, uint percentage, uint artistId);
    event NewOnChainListing(uint expirationTimestamp, uint artistId, uint tokenId, uint price, uint listingId);
    event NewExternalOnChainListing(address tokenContract, address artistAddr, uint tokenId, uint price, uint expirationTimestamp, uint externalListingId);

    function buyNFT(uint onChainListingId) external payable {
        require(!_onChainListingsCompleted[onChainListingId], "Listing was completed or canceled!");
        OnChainListing memory listing = onChainListings[onChainListingId];
        require(uint(listing.expirationTimestamp) >= block.timestamp, "Listing expired!");
        require(listing.price == msg.value, "Ether amount incorrect!");

        Artist memory artist = artists[listing.artistId];

        // split payments
        uint eth = msg.value - ((msg.value * 25) / 1000);
        uint artistAmount = (eth * artist.percentage) / 10_000;
        bool success;

        (success, ) = payable(artist.addr).call{value: artistAmount, gas: 2600}(""); // artist
        require(success, "Failed To Send Ether to artist! User has reverted!");

        eth = msg.value - artistAmount;
        (success, ) = payable(0xAF2992d490E78B94113D44d63E10D1E668b69984).call{value: eth / 4, gas: 2600}(""); // F5
        require(success, "Failed To Send Ether to F5! User has reverted!");
        (success, ) = payable(0x077b813889659Ad54E1538A380584E7a9399ff8F).call{value: (eth / 4) * 3, gas: 2600}(""); // Mona
        require(success, "Failed To Send Ether to Mona! User has reverted!");

        // complete listing and transfer token
        _onChainListingsCompleted[onChainListingId] = true;
        activeOnChainListings--;
        IERC721(artist.tokenContract).safeTransferFrom(address(this), msg.sender, listing.tokenId);
    }

    function buyExternalNFT(uint externalOnChainListingId) external payable {
        require(!_ExternalOnChainListingsCompleted[externalOnChainListingId], "Listing was completed or canceled!");
        OnChainExternalNFTListing memory listing = onChainExternalNFTListings[externalOnChainListingId];
        require(listing.expirationTimestamp >= block.timestamp, "Listing expired!");
        require(listing.price == msg.value, "Ether amount incorrect!");

        // split payments
        uint eth = msg.value - ((msg.value * 25) / 1000);
        uint artistAmount = (eth * 85) / 100;
        bool success;

        (success, ) = payable(listing.artistAddr).call{value: artistAmount, gas: 2600}(""); // artist
        require(success, "Failed To Send Ether to artist! User has reverted!");

        eth = msg.value - artistAmount;
        (success, ) = payable(0xAF2992d490E78B94113D44d63E10D1E668b69984).call{value: eth / 4, gas: 2600}(""); // F5
        require(success, "Failed To Send Ether to F5! User has reverted!");
        (success, ) = payable(0x077b813889659Ad54E1538A380584E7a9399ff8F).call{value: (eth / 4) * 3, gas: 2600}(""); // Mona
        require(success, "Failed To Send Ether to Mona! User has reverted!");

        // complete listing and transfer token
        _ExternalOnChainListingsCompleted[externalOnChainListingId] = true;
        activeExternalOnChainListings--;
        IERC721(listing.tokenContract).safeTransferFrom(address(this), msg.sender, listing.tokenId);
    }

    function cancelOnChainListing(uint onChainListingId) external onlyOwner {
        require(onChainListingId < onChainListings.length, "On chain listing does not exist!");
        require(!_onChainListingsCompleted[onChainListingId], "Already Completed Or Canceled!");
        _onChainListingsCompleted[onChainListingId] = true;
        activeOnChainListings--;
    }

    function cancelOnChainExternalListing(uint onChainExternalListingId) external onlyOwner {
        require(onChainExternalListingId < onChainListings.length, "On chain listing does not exist!");
        require(!_ExternalOnChainListingsCompleted[onChainExternalListingId], "Already Completed Or Canceled!");
        _ExternalOnChainListingsCompleted[onChainExternalListingId] = true;
        activeExternalOnChainListings--;
    }

    function onChainListNFT(uint expirationTimestamp, uint artistId, uint tokenId, uint price) external onlyOwner {
        onChainListings.push(OnChainListing(expirationTimestamp, artistId, tokenId, price));
        activeOnChainListings++;
        emit NewOnChainListing(expirationTimestamp, artistId, tokenId, price, onChainListings.length - 1);
    }

    function onChainListExternalNFT(address tokenContract, address artistAddr, uint tokenId, uint price, uint expirationTimestamp) external onlyOwner {
        onChainExternalNFTListings.push(OnChainExternalNFTListing(tokenContract, artistAddr, tokenId, price, expirationTimestamp));
        activeExternalOnChainListings++;
        emit NewExternalOnChainListing(tokenContract, artistAddr, tokenId, price, expirationTimestamp, onChainExternalNFTListings.length - 1);
    }

    function addArtist(address tokenContract, address addr, uint percentage) external onlyOwner {
        artists.push(Artist(tokenContract, addr, percentage));
        emit NewArtist(tokenContract, addr, percentage, artists.length - 1);
    }

    function getArtist(uint id) external view returns (address tokenContract, address addr, uint percentage) {
        Artist memory artist = artists[id];
        return (artist.tokenContract, artist.addr, artist.percentage);
    }

    function getOnChainListing(uint id) external view returns(uint expirationTimestamp, uint artistId, uint tokenId, uint price) {
        OnChainListing memory listing = onChainListings[id];
        return (listing.expirationTimestamp, listing.artistId, listing.tokenId, listing.price);
    }

    function getOnChainExternalNFTListing(uint id) external view returns(address tokenContract, address artistAddr, uint tokenId, uint price, uint expirationTimestamp) {
        OnChainExternalNFTListing memory listing = onChainExternalNFTListings[id];
        return (listing.tokenContract, listing.artistAddr, listing.tokenId, listing.price, listing.expirationTimestamp);
    }

    function getAllActiveOnChainListingIds() external view returns(uint[] memory) {
        uint[] memory listings = new uint[](activeOnChainListings);
        uint x;

        for (uint i; i < onChainListings.length; i++) {
            if (!_onChainListingsCompleted[i]) {
                listings[x] = i;
                x++;
            }
        }
        return listings;
    }

    function getAllActiveOnChainExternalListingIds() external view returns(uint[] memory) {
        uint[] memory listings = new uint[](activeExternalOnChainListings);
        uint x;

        for (uint i; i < onChainExternalNFTListings.length; i++) {
            if (!_ExternalOnChainListingsCompleted[i]) {
                listings[x] = i;
                x++;
            }
        }
        return listings;
    }
    
    // function hashStruct(Order memory order) private pure returns (bytes32 hash) {
    //     return keccak256(abi.encode(
    //         /* ORDER_TYPEHASH */ keccak256("Order(address tokenContract,uint expirationTimestamp,uint tokenId,uint price)"),
    //         order.tokenContract,
    //         order.expirationTimestamp,
    //         order.tokenId,
    //         order.price
    //     ));
    // }

    function transferNFT(address tokenContract, uint id, address to) external onlyOwner {
        IERC721(tokenContract).safeTransferFrom(address(this), to, id);
    }

/*
    function getMsgOrderHash(Order calldata order) external pure returns(bytes32) {
        return keccak256(abi.encodePacked(order.tokenContract, order.expirationTimestamp, order.tokenId, order.price, order.nonce));
    }
*/

    function withdraw() external onlyOwner {
        uint bal = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: bal, gas: 2600}("");
        require(success, "Failed To Send Ether! User has reverted!");
    }
}

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

/**
 * Source: Openzeppelin
 */

/**
 * @dev String operations.
 */
library Strings {

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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

// https://eips.ethereum.org/EIPS/eip-721, http://erc721.org/ 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 is IERC165 {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// https://eips.ethereum.org/EIPS/eip-165 
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "./Strings.sol";

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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
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

}