// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Utils.sol";

contract Kenomi is Ownable, Utils {
    uint256 public nonce = 0;
    // 7 days
    uint256 public itemsRemoveTime = 3600;

    function setItemRemoveTime(uint256 time) external onlyOwnerOrAdmin {
        itemsRemoveTime = time;
    }

    event WhiteListItemAdded(WhiteListItem item);
    event WhiteListItemUpdated(uint256 itemIndex, WhiteListItem item);
    event WhiteListItemBuyed(WhiteListItem item, address owner);
    event WhiteListItemDeleted(uint256 itemIndex, WhiteListItem item);

    event AuctionItemAdded(AuctionItem item);
    event AuctionItemUpdated(uint256 itemIndex, AuctionItem item);
    event AuctionBidPlaced(AuctionItem item, address bidder);
    event AuctionItemDeleted(uint256 itemIndex, AuctionItem item);

    struct WhiteListItem {
        uint256 index;
        uint8 supply;
        uint8 supplyLeft;
        uint256 pricePerItem;
        uint256 endTime;
    }

    struct AuctionItem {
        uint256 index;
        address highestBidder;
        uint256 highestBid;
        uint256 endTime;
    }

    //  <-  Admin Functions  ->  //
    mapping(address => bool) public adminMapping;

    function addAdmin(address _address) external onlyOwner {
        adminMapping[_address] = true;
    }

    function removeAdmin(address _address) external onlyOwner {
        adminMapping[_address] = false;
    }

    modifier onlyOwnerOrAdmin() {
        require(
            msg.sender == owner() || adminMapping[msg.sender],
            "Function only accessible to Admin and Owner"
        );
        _;
    }

    //  <-  Storage  ->  //
    WhiteListItem[] public whiteListItems;
    mapping(uint256 => address[]) whiteListItemBuyers;
    mapping(address => WhiteListItem[]) public ownedItems;

    AuctionItem[] public auctionItems;
    mapping(address => AuctionItem[]) public ownedAuctionItems;

    modifier requireSignature(bytes memory signature) {
        require(
            _getSigner(_hashTx(msg.sender, nonce), signature) == signerAddress,
            "Invalid Signature"
        );
        nonce += 1;
        _;
    }

    function addWhiteListItem(
        bytes memory signature,
        WhiteListItem memory whiteListItem,
        uint256 endTime
    ) external onlyOwnerOrAdmin requireSignature(signature) {
        whiteListItem.endTime = block.timestamp + endTime;
        whiteListItems.push(whiteListItem);
        emit WhiteListItemAdded(whiteListItem);
    }

    function addAuctionItem(
        bytes memory signature,
        AuctionItem memory auctionItem,
        uint256 endTime
    ) external onlyOwnerOrAdmin requireSignature(signature) {
        auctionItem.endTime = block.timestamp + endTime;
        auctionItems.push(auctionItem);
        emit AuctionItemAdded(auctionItem);
    }

    function updateWhiteListItem(
        bytes memory signature,
        uint256 itemIndex,
        WhiteListItem memory whiteListItem,
        uint256 endTime
    ) external onlyOwnerOrAdmin requireSignature(signature) {
        whiteListItem.endTime = block.timestamp + endTime;
        whiteListItems[itemIndex] = whiteListItem;
        emit WhiteListItemUpdated(itemIndex, whiteListItem);
    }

    function updateAuctionItem(
        bytes memory signature,
        uint256 itemIndex,
        AuctionItem memory auctionItem,
        uint256 endTime
    ) external onlyOwnerOrAdmin requireSignature(signature) {
        auctionItem.endTime = block.timestamp + endTime;
        auctionItems[itemIndex] = auctionItem;
        emit AuctionItemUpdated(itemIndex, auctionItem);
    }

    function buyWhiteListItem(
        bytes memory signature,
        uint256 itemIndex,
        uint8 amount
    ) external payable requireSignature(signature) {
        WhiteListItem memory item = whiteListItems[itemIndex];

        require(amount > 0, "Invalid Buy Amount");
        require(item.endTime >= block.timestamp, "Participation time ends");
        require(item.supplyLeft >= amount, "Not enough supply");
        require(msg.value == item.pricePerItem * amount, "Not enough value");

        whiteListItems[itemIndex].supplyLeft -= amount;

        WhiteListItem memory owned = WhiteListItem(
            itemIndex,
            amount,
            amount,
            item.pricePerItem,
            block.timestamp
        );
        ownedItems[msg.sender].push(owned);
        whiteListItemBuyers[itemIndex].push(msg.sender);
        emit WhiteListItemBuyed(item, msg.sender);
    }

    function placeBid(bytes memory signature, uint256 itemIndex)
        external
        payable
        requireSignature(signature)
    {
        AuctionItem memory item = auctionItems[itemIndex];

        require(msg.value > item.highestBid, "Bid Amount Low than highest Bid");
        require(item.endTime >= block.timestamp, "Bid time ends");

        require(address(this).balance >= auctionItems[itemIndex].highestBid, "Not enough fund in the contract");
        payable(auctionItems[itemIndex].highestBidder).transfer(auctionItems[itemIndex].highestBid);

        auctionItems[itemIndex].highestBid = msg.value;
        auctionItems[itemIndex].highestBidder = msg.sender;
        emit AuctionBidPlaced(item, msg.sender);
    }

    function deleteWhiteListItem(bytes memory signature, uint256 itemIndex)
        external
        onlyOwnerOrAdmin
        requireSignature(signature)
    {
        WhiteListItem memory item = whiteListItems[itemIndex];
        uint256 lastIndex = whiteListItems.length - 1;

        whiteListItems[itemIndex] = whiteListItems[lastIndex];
        whiteListItems.pop();

        whiteListItemBuyers[itemIndex] = whiteListItemBuyers[lastIndex];
        delete whiteListItemBuyers[lastIndex];

        emit WhiteListItemDeleted(itemIndex, item);
    }

    function deleteAuctionItem(
        bytes memory signature,
        uint256 itemIndex,
        bool returnBidAmount
    ) external onlyOwnerOrAdmin requireSignature(signature) {
        AuctionItem memory item = auctionItems[itemIndex];
        uint256 lastIndex = auctionItems.length - 1;

        auctionItems[itemIndex] = auctionItems[lastIndex];
        auctionItems.pop();

        if (returnBidAmount && item.highestBid > 0) {
            require(
                address(this).balance >= item.highestBid,
                "Not enough fund available"
            );
            payable(item.highestBidder).transfer(item.highestBid);
        }
        emit AuctionItemDeleted(itemIndex, item);
    }

    enum UpKeepFor{ WhiteListRemove, AuctionRemove, AuctionTimeEnd }

    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory performData, bytes memory unkeepType) {
        for (uint256 i = 0; i < auctionItems.length; i++) {
            AuctionItem memory item = auctionItems[i];
            bool timePassed = block.timestamp > item.endTime;
            bool removeTimePassed = block.timestamp > item.endTime + itemsRemoveTime;

            if (timePassed) {
                upkeepNeeded = (timePassed);
                // 0 => Auction Time End
                return (upkeepNeeded, abi.encodePacked(i), abi.encodePacked(uint8(0)));
            }
            if (removeTimePassed) {
                upkeepNeeded = (removeTimePassed);
                // 1 => Auction Remove
                return (upkeepNeeded, abi.encodePacked(i), abi.encodePacked(uint8(1)));
            }
        }
        for (uint256 i = 0; i < whiteListItems.length; i++) {
            WhiteListItem memory item = whiteListItems[i];
            // Time Passed true => after 7 days of Item EndTime
            bool timePassed = block.timestamp > item.endTime + itemsRemoveTime;

            if (timePassed) {
                upkeepNeeded = (timePassed);
                // 2 => WhiteList remove
                return (upkeepNeeded, abi.encodePacked(i), abi.encodePacked(uint8(2)));
            }
        }
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external {
        (bool upkeepNeeded, bytes memory data, bytes memory upkeepType) = checkUpkeep("");
        require(upkeepNeeded, "Raffle Upkeep Not Needed");

        if(uint256(bytes32(upkeepType)) == 2) {
            uint256 whiteListItemIndex = uint256(bytes32(data));
            removeWhiteListItem(whiteListItemIndex);
        } else if(uint256(bytes32(upkeepType)) == 1) {
            uint256 auctionItemIndex = uint256(bytes32(data));
            removeAuctionItem(auctionItemIndex);
        } else {
            uint256 auctionItemIndex = uint256(bytes32(data));
            AuctionItem memory item = auctionItems[auctionItemIndex];
            ownedAuctionItems[item.highestBidder].push(item);
        }
    }

    function removeAuctionItem(uint256 auctionItemIndex) internal {
        uint256 lastIndex = auctionItems.length - 1;

        auctionItems[auctionItemIndex] = auctionItems[lastIndex];
        auctionItems.pop();
    }

    function removeWhiteListItem(uint256 whiteListItemIndex) internal {
        uint256 lastIndex = whiteListItems.length - 1;

        whiteListItems[whiteListItemIndex] = whiteListItems[lastIndex];
        whiteListItems.pop();
    }

    //  <- Getter Functions  ->  //
    function getAllWhiteListItems()
        external
        view
        returns (WhiteListItem[] memory)
    {
        return whiteListItems;
    }

    function getAllWhiteListItemBuyers(uint256 index)
        external
        view
        returns (address[] memory)
    {
        return whiteListItemBuyers[index];
    }

    function getAllAuctionItems() external view returns (AuctionItem[] memory) {
        return auctionItems;
    }

    function getWhiteListOwnedItems(address _address)
        external
        view
        returns (WhiteListItem[] memory)
    {
        return ownedItems[_address];
    }

    function getAuctionOwnedItems(address _address)
        external
        view
        returns (AuctionItem[] memory)
    {
        return ownedAuctionItems[_address];
    }

    function getNextWhiteListItemIndex() external view returns (uint256) {
        return whiteListItems.length;
    }

    function getNextAuctionItemIndex() external view returns (uint256) {
        return auctionItems.length;
    }

    function getKenomiBalance() external view returns(uint256){
        return address(this).balance;
    }

    function withDraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Utils is Ownable {

    using ECDSA for bytes32;

    bytes32 zeroByte = 0x0000000000000000000000000000000000000000000000000000000000000000;
    address public signerAddress = address(0xA6088E933E4698169F45b61FA3592288aA36DfDb);

    function setSignerAddress(address _address) external onlyOwner {
        signerAddress = _address;
    }

    function _hashTx(address _address, uint256 _nonce) internal pure returns(bytes32 _hash) {
        _hash = keccak256(abi.encodePacked(_address, _nonce));
    }

    function _getSigner(bytes32 uhash, bytes memory signature) internal pure returns(address _signer) {
        _signer = uhash.toEthSignedMessageHash().recover(signature);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

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
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}