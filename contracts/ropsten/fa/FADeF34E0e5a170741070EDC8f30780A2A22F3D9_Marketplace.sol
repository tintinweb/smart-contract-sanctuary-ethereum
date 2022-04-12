/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// Sources flattened with hardhat v2.9.2 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]
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


// File @openzeppelin/contracts/token/ERC1155/[email protected]

// 
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/math/[email protected]

// 
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File @openzeppelin/contracts/utils/[email protected]

// 
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


// File @openzeppelin/contracts/utils/cryptography/[email protected]

// 
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

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


// File contracts/interfaces/Exchange.sol

pragma solidity ^0.8.0;
// 


abstract contract Exchange {
    using SafeMath for uint;

    enum SaleType{ FIXED, AUCTION }
    struct Sale {
        uint amount;
        uint price;
    }

    // Token address -> tokenId -> seller -> SaleType
    mapping(address => mapping(uint => mapping(address => SaleType))) public saleType;
    mapping(address => mapping(uint => mapping(address => Sale))) public fixedItems;

    event ItemUpdated(address _address, uint256 _id, address _seller, uint256 _amount, uint256 _price, SaleType _type, uint256 _endTime);
    event Bought(address _address, uint256 _id, address _seller, uint256 _amount, uint256 _price, address _buyer);

    modifier HasEnoughToken(address tokenAddress, uint256 tokenId, uint256 quantity) {
        IERC1155 tokenContract = IERC1155(tokenAddress);
        require(tokenContract.balanceOf(msg.sender, tokenId) >= quantity, "Not enough token supply");
        _;
    }

    modifier HasTransferApproval(address tokenAddress, uint256 tokenId, address seller) {
        IERC1155 tokenContract = IERC1155(tokenAddress);
        require(tokenContract.isApprovedForAll(seller, address(this)), "Market not have approval of token");
        _;
    }

    function putOnSale(address _address, uint _id, uint _amount, uint _price) 
    HasEnoughToken(_address, _id, _amount) HasTransferApproval(_address, _id, msg.sender) virtual public {
        saleType[_address][_id][msg.sender] = SaleType.FIXED;
        fixedItems[_address][_id][msg.sender] = Sale(_amount, _price);
        emit ItemUpdated(_address, _id, msg.sender, _amount, _price, SaleType.FIXED, 0);
    }

    function buy(address _address, uint _id, address _seller, uint _amount) external payable {
        IERC1155 tokenContract = IERC1155(_address);
        require(saleType[_address][_id][_seller] == SaleType.FIXED, "Sale type is not fixed");
        require(fixedItems[_address][_id][_seller].amount >= _amount, "Not enough items in sale");
        require(fixedItems[_address][_id][_seller].price.mul(_amount) == msg.value, "Not enough fund to send");
        require(tokenContract.balanceOf(_seller, _id) >= _amount, "Seller not enough token supply");

        tokenContract.safeTransferFrom(_seller, msg.sender, _id, _amount, "");
        fixedItems[_address][_id][_seller].amount = fixedItems[_address][_id][_seller].amount.sub(_amount);
        payout(_address, _id, payable(_seller), msg.value);

        emit Bought(
            _address, 
            _id,
            _seller,
            _amount,
            fixedItems[_address][_id][_seller].price,
            msg.sender
        );
    }

    function takeOffSale(address _address, uint _id) virtual public {
        require(fixedItems[_address][_id][msg.sender].amount >= 0, "Item is not on sale");
        fixedItems[_address][_id][msg.sender].amount = 0;
        emit ItemUpdated(_address, _id, msg.sender, 0, fixedItems[_address][_id][msg.sender].price, SaleType.FIXED, 0);
    }

    function payout(address _collection, uint _id, address payable _seller, uint _value) internal virtual;
}


// File contracts/interfaces/AuctionExchange.sol

pragma solidity ^0.8.0;
// 


abstract contract AuctionExchange is Exchange {
    using SafeMath for uint;


    struct Auction {
        uint amount;
        uint maxBid;
        address maxBidder;
        uint endTime;
        bool ended;
    }

    // token address => token ID => seller => value
    mapping(address => mapping(uint => mapping(address => Auction))) public auctionItems;

    mapping(address => uint) public pendingWithdraws;

    event BidAdded(address _address, uint256 _id, address _seller, address _bidder, uint256 _value);
    event Withdrawn(address _bidder, uint256 _value);
    event AuctionEnded(address _address, uint256 _id, address _seller, address _maxBidder, uint256 _maxBid, uint256 _amount, bool _success);

    function putOnAuction(address _address, uint _id, uint _amount, uint _minPrice, uint _endTime)
    HasEnoughToken(_address, _id, _amount) HasTransferApproval(_address, _id, msg.sender) external {
        require(fixedItems[_address][_id][msg.sender].amount == 0, "Token is in fixed sale");
        saleType[_address][_id][msg.sender] = SaleType.AUCTION;

        auctionItems[_address][_id][msg.sender] = Auction(_amount, _minPrice.sub(1), address(0), _endTime, false);
        emit ItemUpdated(_address, _id, msg.sender, _amount, _minPrice, SaleType.AUCTION, _endTime);
    }

    function putOnSale(address _address, uint _id, uint _amount, uint _price)
    HasEnoughToken(_address, _id, _amount) HasTransferApproval(_address, _id, msg.sender) public override {
        bool isInAuction = (auctionItems[_address][_id][msg.sender].ended != true) && (auctionItems[_address][_id][msg.sender].amount > 0);
        require(isInAuction == false, "Token is in auction sale");
        super.putOnSale(_address, _id, _amount, _price);
    }

    function bid(address _address, uint _id, address _seller) external payable {
        require(saleType[_address][_id][_seller] == SaleType.AUCTION, "Token not in auction");
        require(auctionItems[_address][_id][_seller].ended != true, "Auction ended");
        require(block.timestamp <= auctionItems[_address][_id][_seller].endTime, "Auction expired");

        require(auctionItems[_address][_id][_seller].maxBid < msg.value, "There already is a higher bid");

        pendingWithdraws[auctionItems[_address][_id][_seller].maxBidder] = pendingWithdraws[auctionItems[_address][_id][_seller].maxBidder].add(auctionItems[_address][_id][_seller].maxBid);

        auctionItems[_address][_id][_seller].maxBid = msg.value;
        auctionItems[_address][_id][_seller].maxBidder = msg.sender;

        emit BidAdded(_address, _id, _seller, msg.sender, msg.value);
    }

    function endAuction(address _address, uint _id, address _seller) external {
        IERC1155 tokenContract = IERC1155(_address);
        require(saleType[_address][_id][_seller] == SaleType.AUCTION, "Token not in auction");
        require(auctionItems[_address][_id][_seller].ended != true, "Auction ended");
        require(tokenContract.balanceOf(_seller, _id) >= auctionItems[_address][_id][_seller].amount, "Seller not enough token supply"); // TODO: if not enough, refund

        tokenContract.safeTransferFrom(_seller, auctionItems[_address][_id][_seller].maxBidder, _id, auctionItems[_address][_id][_seller].amount, "");
        payout(_address, _id, payable(_seller), auctionItems[_address][_id][_seller].maxBid);
        auctionItems[_address][_id][_seller].ended = true;
        emit AuctionEnded(_address, _id, _seller, auctionItems[_address][_id][_seller].maxBidder, auctionItems[_address][_id][_seller].maxBid, auctionItems[_address][_id][_seller].amount, true);
    }

    function withdraw() external {
        payable(msg.sender).transfer(pendingWithdraws[msg.sender]);
        emit Withdrawn(msg.sender, pendingWithdraws[msg.sender]);
        pendingWithdraws[msg.sender] = 0;
    }

    function takeOffAuction(address _address, uint _id) public {
        require(auctionItems[_address][_id][msg.sender].ended == false, "Item is not on auction");
        auctionItems[_address][_id][msg.sender].ended = true;
        pendingWithdraws[auctionItems[_address][_id][msg.sender].maxBidder] = pendingWithdraws[auctionItems[_address][_id][msg.sender].maxBidder].add(auctionItems[_address][_id][msg.sender].maxBid);
        emit AuctionEnded(_address, _id, msg.sender, address(0), 0, 0, false);
    }
}


// File contracts/interfaces/ICollectionRoyalty.sol

pragma solidity ^0.8.0;
// 

interface ICollectionRoyalty {
    function setRoyalty(uint256 _id, uint256 royalty) external;
    
    function getRoyalty(uint256 _id) external view returns(uint256);

    function getCreator(uint256 _id) external view returns(address);

    function getDecimal() external view returns(uint256);
}


// File contracts/interfaces/IERC1155Tradable.sol

pragma solidity ^0.8.0;
// 

interface IERC1155Tradable {
    function create(
        address _initialOwner,
        uint256 _initialSupply,
        string calldata _uri
    ) external payable returns (uint256);

    function burn(address account, uint id, uint value) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}


// File contracts/Marketplace.sol

pragma solidity ^0.8.0;
// 






contract Marketplace is AuctionExchange {
    using SafeMath for uint;

    address public marketPayee;
    uint public marketPercent;

    constructor(address _payee, uint _percent) Exchange() {
        marketPercent = _percent;
        marketPayee = _payee;
    }

    function setMarketPayee(address _payee) public {
        require(msg.sender == marketPayee, 'Only the market payee change the payee');
        marketPayee = _payee;
    }

    function setMarketPercent(uint _percent) public {
        require(msg.sender == marketPayee, 'Only the market payee change the payee');
        marketPercent = _percent;
    }

    function payout(address _collection, uint _id, address payable _seller, uint _value) internal override {
        ICollectionRoyalty collection = ICollectionRoyalty(_collection);
        address payable creator = payable(collection.getCreator(_id));

        uint balance = _value;

        if (creator != address(0)) {
            uint royalty = collection.getRoyalty(_id);
            uint decimal = collection.getDecimal();
            uint creatorRevenue = _value.mul(royalty).div(100 ** decimal);
            creator.transfer(creatorRevenue);
            balance = balance.sub(creatorRevenue);
        }

        uint marketRevenue = _value.mul(marketPercent).div(100 ** 2);
        payable(marketPayee).transfer(marketRevenue);
        balance = balance.sub(marketRevenue);

        _seller.transfer(balance);
    }
}


// File contracts/LazyMaketplace.sol

pragma solidity ^0.8.0;
// 







contract LazyMarketplace is Marketplace {
    using SafeMath for uint;
    using ECDSA for bytes32;

    event LazyAuctionEnded(address _address, uint256 _auctionId, address _seller, address _maxBidder, uint256 _maxBid, uint256 _amount, bool _success, uint256 _tokenId);
    event LazyBidAdded(address _address, uint256 _auctionId, address _seller, address _bidder, uint256 _value);

    mapping(uint256 => Auction) public lazyAuctions;
    mapping(uint256 => bool) public auctionExists;

    constructor(address _payee, uint _percent) Marketplace(_payee, _percent) {}

    function buyLazy(address _tokenAddress, uint256 _amount, address _creator, uint256 _unitPrice, string calldata _uri, bytes calldata _signature, uint256 _buyAmount)
    external payable {
        bytes32 msgHash = keccak256(
            abi.encode(_tokenAddress, _amount, _creator, _unitPrice, _uri)
        );
        require(_validSignature(_signature, msgHash, _creator), "INVALID_SIGNATURE");
        require(msg.value == _unitPrice * _buyAmount, "INSUFFICIENT_FUNDS");

        // mint token
        IERC1155Tradable collection = IERC1155Tradable(_tokenAddress);
        uint256 tokenId = collection.create(_creator, _amount, _uri);

        // transfer token
        fixedItems[_tokenAddress][tokenId][_creator].amount = _amount - _buyAmount;
        collection.safeTransferFrom(_creator, msg.sender, tokenId, _buyAmount, "");

        // payout
        uint marketRevenue = msg.value.mul(marketPercent).div(100 ** 2);
        payable(marketPayee).transfer(marketRevenue);
        payable(_creator).transfer(msg.value.sub(marketRevenue));

        emit Bought(
            _tokenAddress,
            tokenId,
            _creator,
            _buyAmount,
            _unitPrice,
            msg.sender
        );
    }

    function bidLazy(address _tokenAddress, uint256 _amount, address _creator, uint256 _minBid, uint256 _endTime, string calldata _uri, uint256 _auctionId, bytes calldata _signature)
    external payable {
        bytes32 msgHash = keccak256(
            abi.encode(_tokenAddress, _amount, _creator, _minBid, _endTime, _uri, _auctionId)
        );
        require(_validSignature(_signature, msgHash, _creator), "INVALID_SIGNATURE");
        require(msg.value >= _minBid, "INSUFFICIENT_FUNDS");
        require(block.timestamp <= _endTime, "AUCTION_EXPIRED");

        // check if auction exists, create new
        if (!auctionExists[_auctionId]) {
            auctionExists[_auctionId] = true;
            lazyAuctions[_auctionId] = Auction(
                _amount,
                msg.value,
                msg.sender,
                _endTime,
                false
            );
        } else {
            require(msg.value > lazyAuctions[_auctionId].maxBid, "There already is a higher bid");

            pendingWithdraws[lazyAuctions[_auctionId].maxBidder] = pendingWithdraws[lazyAuctions[_auctionId].maxBidder].add(lazyAuctions[_auctionId].maxBid);

            lazyAuctions[_auctionId].maxBid = msg.value;
            lazyAuctions[_auctionId].maxBidder = msg.sender;
        }

        emit LazyBidAdded(_tokenAddress, _auctionId, _creator, msg.sender, msg.value);
    }


    function endAuctionLazy(address _tokenAddress, uint256 _amount, address _creator, uint256 _minBid, uint256 _endTime, string calldata _uri, uint256 _auctionId, bytes calldata _signature)
    external payable {
        bytes32 msgHash = keccak256(
            abi.encode(_tokenAddress, _amount, _creator, _minBid, _endTime, _uri, _auctionId)
        );
        require(_validSignature(_signature, msgHash, _creator), "INVALID_SIGNATURE");
        require(auctionExists[_auctionId], "AUCTION_DOES_NOT_EXIST");
        require(lazyAuctions[_auctionId].ended == false, "AUCTION_ALREADY_ENDED");

        // mint token
        IERC1155Tradable collection = IERC1155Tradable(_tokenAddress);
        uint256 tokenId = collection.create(_creator, _amount, _uri);
        // transfer token
        collection.safeTransferFrom(_creator, lazyAuctions[_auctionId].maxBidder, tokenId, lazyAuctions[_auctionId].amount, "");
        lazyAuctions[_auctionId].ended = true;

        uint256 maxBid = lazyAuctions[_auctionId].maxBid;
        // payout
        uint marketRevenue = maxBid.mul(marketPercent).div(100 ** 2);
        payable(marketPayee).transfer(marketRevenue);
        payable(_creator).transfer(maxBid.sub(marketRevenue));

        emit LazyAuctionEnded(_tokenAddress, tokenId, _creator, lazyAuctions[_auctionId].maxBidder, maxBid, lazyAuctions[_auctionId].amount, true, tokenId);
    }

    function takeOffAuctionLazy(address _tokenAddress, uint256 _amount, address _creator, uint256 _minBid, uint256 _endTime, string calldata _uri, uint256 _auctionId, bytes calldata _signature)
    public {
        bytes32 msgHash = keccak256(
            abi.encode(_tokenAddress, _amount, _creator, _minBid, _endTime, _uri, _auctionId)
        );
        require(_validSignature(_signature, msgHash, _creator), "INVALID_SIGNATURE");
        require(auctionExists[_auctionId], "AUCTION_DOES_NOT_EXIST");
        require(lazyAuctions[_auctionId].ended == false, "AUCTION_ALREADY_ENDED");

        pendingWithdraws[lazyAuctions[_auctionId].maxBidder] = pendingWithdraws[lazyAuctions[_auctionId].maxBidder].add(lazyAuctions[_auctionId].maxBid);

        emit LazyAuctionEnded(_tokenAddress, _auctionId, _creator, lazyAuctions[_auctionId].maxBidder, lazyAuctions[_auctionId].maxBid, _amount, false, 0);
    }

    function _validSignature(bytes memory signature, bytes32 msgHash, address signerAddress) internal pure returns (bool) {
        return msgHash.toEthSignedMessageHash().recover(signature) == signerAddress;
    }

}