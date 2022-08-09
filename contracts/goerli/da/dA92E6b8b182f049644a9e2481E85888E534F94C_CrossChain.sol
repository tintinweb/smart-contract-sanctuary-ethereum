/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

// contracts/NFTMarketplace.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage)
        private
        pure
    {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC2981 is IERC721 {
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

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
            /// @solidity memory-safe-assembly
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
            /// @solidity memory-safe-assembly
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

contract CrossChain is ReentrancyGuard, Ownable {
    using ECDSA for bytes32;

    address marketOperator;

    enum CrossState {
        Created,
        Release,
        Inactive,
        InSwap
    }

    struct CrossSwapItem {
        uint256 id;
        uint256 sellerBlockchain;
        address[] sellerNFTContracts;
        uint256[] sellerTokenIds;
        bool sellerLocked;
        uint256 buyerBlockchain;
        address[] buyerNFTContracts;
        uint256[] buyerTokenIds;
        bool buyerLocked;
        uint256 expiry;
        address seller;
        address buyer;
        CrossState state;
    }

    mapping(uint256 => CrossSwapItem) public crossSwapItems;

    event CrossSwapItemCreated(
        uint256 indexed id,
        uint256 sellerBlockchain,
        address[] sellerNFTContracts,
        uint256[] sellerTokenIds,
        uint256 buyerBlockchain,
        address[] buyerNFTContracts,
        uint256[] buyerTokenIds,
        address seller,
        address buyer,
        uint256 expiry,
        CrossState state
    );

    event CrossSwapSuccessful(
        uint256 indexed id,
        uint256 sellerBlockchain,
        address[] sellerNFTContracts,
        uint256[] sellerTokenIds,
        uint256 buyerBlockchain,
        address[] buyerNFTContracts,
        uint256[] buyerTokenIds,
        address seller,
        address buyer,
        CrossState state
    );


    /// @dev View functions

    function getAllCrossSwaps(uint256 lastItemId)
        external
        view
        returns (CrossSwapItem[] memory)
    {
        uint256 index;
        CrossSwapItem[] memory items = new CrossSwapItem[](lastItemId);
        for (uint256 i = 1; i <= lastItemId; i++) {
            items[index] = crossSwapItems[i];
        }
        return items;
    }

    function getActiveCrossSwaps(uint256 lastItemId)
        external
        view
        returns (CrossSwapItem[] memory)
    {
        uint256 itemCount;
        for (uint256 i = 1; i <= lastItemId; i++) {
            if (
                (crossSwapItems[i].state == CrossState.Created ||
                    crossSwapItems[i].state == CrossState.InSwap) &&
                crossSwapItems[i].expiry >= block.timestamp
            ) {
                itemCount++;
            }
        }

        uint256 index;
        CrossSwapItem[] memory items = new CrossSwapItem[](itemCount);
        for (uint256 i = 1; i < lastItemId; i++) {
            if (
                (crossSwapItems[i].state == CrossState.Created ||
                    crossSwapItems[i].state == CrossState.InSwap) &&
                crossSwapItems[i].expiry >= block.timestamp
            ) {
                items[index] = crossSwapItems[i];
                index++;
            }
        }
        return items;
    }

    /// @dev Public write functions

    function createCrossSwapItem(
        uint256 id,
        address seller,
        uint256 sellerBlockchain,
        address[] memory _sellerNFTContracts,
        uint256[] memory _sellerTokenIds,
        uint256 buyerBlockchain,
        address[] memory _buyerNFTContracts,
        uint256[] memory _buyerTokenIds,
        uint256 _expiry,
        bytes memory data
    ) external {
        require(
            verifySwap2(
                id,
                seller,
                sellerBlockchain,
                _sellerNFTContracts,
                _sellerTokenIds,
                buyerBlockchain,
                _buyerNFTContracts,
                _buyerTokenIds,
                _expiry,
                data
            ),
            "StormSpace: Not authorised"
        );
        require(
            crossSwapItems[id].seller == address(0) &&
                crossSwapItems[id].buyer == address(0),
            "StormSpace: id already exists"
        );
        require(_expiry > block.timestamp, "StormSpace: Invalid expiry");
        require(
            _sellerNFTContracts.length == _sellerTokenIds.length,
            "StormSpace: Seller lengths mismatch"
        );
        require(
            _buyerNFTContracts.length == _buyerTokenIds.length,
            "StormSpace: Buyer lengths mismatch"
        );
        for (uint256 i; i < _buyerNFTContracts.length; i++) {
            require(
                IERC721(_sellerNFTContracts[i]).ownerOf(_sellerTokenIds[i]) ==
                    _msgSender(),
                "StormSpace: Token not owned by seller"
            );
            require(
                _checkAllowance(
                    _msgSender(),
                    _buyerNFTContracts[i],
                    _buyerTokenIds[i]
                ),
                "StormSpace: Buyer NFT is not approved to the market"
            );
        }

        crossSwapItems[id] = CrossSwapItem(
            id,
            sellerBlockchain,
            _sellerNFTContracts,
            _sellerTokenIds,
            false,
            buyerBlockchain,
            _buyerNFTContracts,
            _buyerTokenIds,
            false,
            _expiry,
            seller,
            _msgSender(),
            CrossState.Created
        );

        // emit CrossSwapItemCreated(
        //     id,
        //     sellerBlockchain,
        //     _sellerNFTContracts,
        //     _sellerTokenIds,
        //     buyerBlockchain,
        //     _buyerNFTContracts,
        //     _buyerTokenIds,
        //     seller,
        //     _msgSender(),
        //     _expiry,
        //     CrossState.Created
        // );
    }

    function completeCrossSwapForSellerOrigin(
        uint256 id,
        address seller,
        uint256 sellerBlockchain,
        address[] memory _sellerNFTContracts,
        uint256[] memory _sellerTokenIds,
        bool transferred,
        uint256 buyerBlockchain,
        address[] memory _buyerNFTContracts,
        uint256[] memory _buyerTokenIds,
        uint256 _expiry,
        bytes memory data
    ) external {
        require(
            verifySwap3(
                id,
                seller,
                sellerBlockchain,
                _sellerNFTContracts,
                _sellerTokenIds,
                transferred,
                buyerBlockchain,
                _buyerNFTContracts,
                _buyerTokenIds,
                _expiry,
                data
            ),
            "StormSpace: Not authorised"
        );
        require(_msgSender() == seller, "StormSpace: Not authorised");
        for (uint256 i; i < _sellerNFTContracts.length; i++) {
            require(
                IERC721(_sellerNFTContracts[i]).ownerOf(_sellerTokenIds[i]) ==
                    _msgSender(),
                "StormSpace: Token not owned by seller"
            );
            require(
                _checkAllowance(
                    _msgSender(),
                    _sellerNFTContracts[i],
                    _sellerTokenIds[i]
                ),
                "StormSpace: Buyer NFT is not approved to the market"
            );
            IERC721(_sellerNFTContracts[i]).safeTransferFrom(
                _msgSender(),
                address(this),
                _sellerTokenIds[i]
            );
            require(
                IERC721(_sellerNFTContracts[i]).ownerOf(_sellerTokenIds[i]) ==
                    address(this),
                "StormSpace: Something went wrong during transfer"
            );
        }
        crossSwapItems[id] = CrossSwapItem(
            id,
            sellerBlockchain,
            _sellerNFTContracts,
            _sellerTokenIds,
            true,
            buyerBlockchain,
            _buyerNFTContracts,
            _buyerTokenIds,
            false,
            _expiry,
            seller,
            _msgSender(),
            CrossState.InSwap
        );
    }

    function completeCrossSwapForSellerDestination(
        uint256 itemId,
        bytes memory data
    ) external {
        CrossSwapItem storage item = crossSwapItems[itemId];
        require(
            item.state == CrossState.Created,
            "StormSpace: Item must be on market"
        );
        require(
            verifySwap3(
                item.id,
                item.seller,
                item.sellerBlockchain,
                item.sellerNFTContracts,
                item.sellerTokenIds,
                true,
                item.buyerBlockchain,
                item.buyerNFTContracts,
                item.buyerTokenIds,
                item.expiry,
                data
            ),
            "StormSpace: Not authorised"
        );
        require(_msgSender() == item.seller, "StormSpace: Not authorised");
        item.state = CrossState.InSwap;
        item.sellerLocked = true;
        for (uint256 i; i < item.buyerNFTContracts.length; i++) {
            IERC721(item.buyerNFTContracts[i]).safeTransferFrom(
                item.buyer,
                item.seller,
                item.buyerTokenIds[i]
            );
            require(
                IERC721(item.buyerNFTContracts[i]).ownerOf(
                    item.buyerTokenIds[i]
                ) == item.seller,
                "StormSpace: Something went wrong during transfer"
            );
        }
        item.buyerLocked = true;
    }

    function getFromCrossSwap(uint256 itemId) external {
        CrossSwapItem storage item = crossSwapItems[itemId];
        require(
            item.state == CrossState.InSwap,
            "StormSpace: Item must be on market"
        );
        require(item.sellerLocked, "StormSpace: wrong order");
        require(item.buyerLocked, "StormSpace: wrong order");
        for (uint256 i; i < item.sellerNFTContracts.length; i++) {
            IERC721(item.sellerNFTContracts[i]).safeTransferFrom(
                item.seller,
                item.buyer,
                item.sellerTokenIds[i]
            );
            require(
                IERC721(item.sellerNFTContracts[i]).ownerOf(
                    item.sellerTokenIds[i]
                ) == item.buyer,
                "StormSpace: Something went wrong during transfer"
            );
        }
        item.state = CrossState.Release;
        emit CrossSwapSuccessful(
            itemId,
            item.sellerBlockchain,
            item.sellerNFTContracts,
            item.sellerTokenIds,
            item.buyerBlockchain,
            item.buyerNFTContracts,
            item.buyerTokenIds,
            item.seller,
            item.buyer,
            item.state
        );
    }

    function deleteCrossSwapItem(uint256 itemId) external {
        CrossSwapItem storage item = crossSwapItems[itemId];
        require(
            item.state == CrossState.Created,
            "StormSpace: Item must be on market"
        );
        require(item.expiry >= block.timestamp, "StormSpace: Item has expired");
        require(
            item.buyer == _msgSender(),
            "StormSpace: Caller is not authorised"
        );
        item.state = CrossState.Inactive;
        emit CrossSwapSuccessful(
            itemId,
            item.sellerBlockchain,
            item.sellerNFTContracts,
            item.sellerTokenIds,
            item.buyerBlockchain,
            item.buyerNFTContracts,
            item.buyerTokenIds,
            item.seller,
            item.buyer,
            item.state
        );
    }

    /// @dev Internal Functions

    function _checkAllowance(
        address user,
        address nftContract,
        uint256 tokenId
    ) internal view returns (bool) {
        return
            (IERC721(nftContract).getApproved(tokenId) == address(this) ||
                IERC721(nftContract).isApprovedForAll(user, address(this)))
                ? true
                : false;
    }

    function changeMarketOperator(address newOp) external onlyOwner {
        marketOperator = newOp;
    }

    /// @dev Bytes verification

    function verifySwap2(
        uint256 id,
        address seller,
        uint256 sellerBlockchain,
        address[] memory _sellerNFTContracts,
        uint256[] memory _sellerTokenIds,
        uint256 buyerBlockchain,
        address[] memory _buyerNFTContracts,
        uint256[] memory _buyerTokenIds,
        uint256 _expiry,
        bytes memory data
    ) internal view returns (bool) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                id,
                seller,
                sellerBlockchain,
                _sellerNFTContracts,
                _sellerTokenIds,
                buyerBlockchain,
                _buyerNFTContracts,
                _buyerTokenIds,
                _expiry
            )
        );
        bytes32 ethHash = ECDSA.toEthSignedMessageHash(messageHash);
        (address rec, ) = ECDSA.tryRecover(ethHash, data);
        return rec == marketOperator;
    }

    function verifySwap3(
        uint256 id,
        address seller,
        uint256 sellerBlockchain,
        address[] memory _sellerNFTContracts,
        uint256[] memory _sellerTokenIds,
        bool transferred,
        uint256 buyerBlockchain,
        address[] memory _buyerNFTContracts,
        uint256[] memory _buyerTokenIds,
        uint256 _expiry,
        bytes memory data
    ) internal view returns (bool) {
        require(transferred == true, "StormSpace: NFTs not transferred");
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                id,
                seller,
                sellerBlockchain,
                _sellerNFTContracts,
                _sellerTokenIds,
                transferred,
                buyerBlockchain,
                _buyerNFTContracts,
                _buyerTokenIds,
                _expiry
            )
        );
        bytes32 ethHash = ECDSA.toEthSignedMessageHash(messageHash);
        (address rec, ) = ECDSA.tryRecover(ethHash, data);
        return rec == marketOperator;
    }

    function getMessageHashCrossInit(
        uint256 id,
        address seller,
        uint256 sellerBlockchain,
        address[] memory _sellerNFTContracts,
        uint256[] memory _sellerTokenIds,
        uint256 buyerBlockchain,
        address[] memory _buyerNFTContracts,
        uint256[] memory _buyerTokenIds,
        uint256 _expiry
        ) external pure returns (bytes32) {
            return keccak256(
            abi.encodePacked(
                id,
                seller,
                sellerBlockchain,
                _sellerNFTContracts,
                _sellerTokenIds,
                buyerBlockchain,
                _buyerNFTContracts,
                _buyerTokenIds,
                _expiry
            )
        );
    }

    function getMessageHashCross3(
        uint256 id,
        address seller,
        uint256 sellerBlockchain,
        address[] memory _sellerNFTContracts,
        uint256[] memory _sellerTokenIds,
        bool transferred,
        uint256 buyerBlockchain,
        address[] memory _buyerNFTContracts,
        uint256[] memory _buyerTokenIds,
        uint256 _expiry
    ) external pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                id,
                seller,
                sellerBlockchain,
                _sellerNFTContracts,
                _sellerTokenIds,
                transferred,
                buyerBlockchain,
                _buyerNFTContracts,
                _buyerTokenIds,
                _expiry
            )
        );
    }
}