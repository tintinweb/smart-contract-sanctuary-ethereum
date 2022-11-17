//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC1155 is IERC165 {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

interface IERC1155Supply is IERC1155 {
    function totalSupply(uint256 id)
        external
        view
        returns (uint256);
}

interface IERC2981Royalties is IERC165 {
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

interface ISKCollection {
    function mintItem(
        address account,
        uint256 tokenId,
        uint256 supply,
        string memory tokenURI_
    ) external;
    function setMarketplaceAddress (
        address _marketplaceAddress
    ) external;
    function setTokenURI(uint256 tokenId, string memory tokenURI_) external;
}

interface ISKReveal {
    event SetRevealURI(
        string newRevealURI
    );    

    function setRevealURI(string memory revealURI_) external;
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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
    function tryRecover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address, RecoverError)
    {
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
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
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
        bytes32 s = vs &
            bytes32(
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
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
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
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
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    Strings.toString(s.length),
                    s
                )
            );
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "SKMarketPlace(Address): insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "SKMarketPlace(Address): unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCall(
                target,
                data,
                "SKMarketPlace(Address): low-level call failed"
            );
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
                "SKMarketPlace(Address): low-level call with value failed"
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
            "SKMarketPlace(Address): insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(
            isContract(target),
            "SKMarketPlace(Address): call to non-contract"
        );

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );

        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SKMarketPlace(SafeERC20): approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SKMarketPlace(SafeERC20): decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SKMarketPlace(SafeERC20): low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SKMarketPlace(SafeERC20): ERC20 operation did not succeed"
            );
        }
    }
}

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

struct CollectionInfo {
    address collection;
    bool batch;
    uint256[] tokenIds;
    uint256[] quantities;
}
struct Receiver {
    address receiver;
    CollectionInfo[] collections;
}

struct CartCollection {
    address collection;
    bool batch;
    address[] creators;
    uint256[] tokenIds;
    uint256[] quantities;
    uint256[] prices;
    uint256[] royaltyAmounts;
}
struct CartSeller {
    address seller;
    uint256 price;
    CartCollection[] collections;
}

contract SKMarketPlace is Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 private vxlToken; // Voxel Token Address

    uint256 private constant feeDecimals = 2;
    uint256 private serviceFee = 150; // decimal 2
    address private skTeamWallet;

    address private signer; // Marketplace public key
    address private timeLockController;

    mapping(address => bool) public skCollection;
    mapping(address => uint256) public nonces;

    mapping(address => uint256) public userRoyalties;  

    bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;
    bytes4 private constant InterfaceId_ERC1155 = 0xd9b67a26;
    bytes4 private constant InterfaceId_ERC2981 = 0x2a55205a;
    bytes4 private constant InterfaceId_Reveal = 0xa811a37b;

    event SetVxlTokenAddress(address indexed newVxlToken);

    event AddSKCollection(address newCollection);
    event RemoveSKCollection(address collection);
    event AddItem(
        address collection,
        address from,
        uint256 tokenId,
        uint256 quantity,
        string tokenURI,
        uint256 timestamp
    );
    event BuyItem(
        address collection,
        address buyer,
        address seller,
        uint256 tokenId,
        uint256 quantity,
        uint256 price,
        uint256 timestamp
    );
    event AcceptItem(
        address collection,
        address seller,
        address buyer,
        uint256 tokenId,
        uint256 quantity,
        uint256 price,
        uint256 timestamp
    );
    event UpdateItemMetaData(
        address collection,
        address from,
        uint256 tokenId,
        string tokenURI,
        uint256 timestamp
    );
    event SetReveal(
        address _collection,
        address from,
        string revealURI,
        uint256 timestamp
    );
    event TransferBundle(
        address from,
        uint256 timestamp
    );
    event BuyCart(
        address buyer,
        uint256 payload,
        uint256 timestamp
    );

    constructor(
        address _vxlToken,
        address _signer,
        address _skTeamWallet,
        address _timeLockController
    ) {
        vxlToken = IERC20(_vxlToken);
        timeLockController = _timeLockController;
        skTeamWallet = _skTeamWallet;
        signer = _signer;
    }

    modifier collectionCheck(address _collection) {
        require(
            IERC721(_collection).supportsInterface(InterfaceId_ERC721) ||
                IERC1155(_collection).supportsInterface(InterfaceId_ERC1155),
            "SKMarketPlace: This is not ERC721/ERC1155 collection"
        );
        _;
    }

    modifier onlyTimeLockController() {
        require(
            timeLockController == msg.sender,
            "only timeLock contract can access SKMarketPlace Contract"
        );
        _;
    }

    function getSigner() external view returns (address) {
        return signer;
    }

    function getServiceFee() external view returns (uint256) {
        return serviceFee;
    }

    function getSKTeamWallet() external view returns (address) {
        return skTeamWallet;
    }

    function getClaimRoyalty() external view returns (uint256) {
        return userRoyalties[_msgSender()];
    }

    function getUserNonce(address _account) external view returns (uint256) {
        return nonces[_account];
    }

    function getAddItemMessageHash(
        address _collection,
        address _account,
        uint256 _tokenId,
        uint256 _supply,
        string memory _tokenURI,
        uint256 _nonce,
        uint256 _deadline
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _collection,
                    _account,
                    _tokenId,
                    _supply,
                    _tokenURI,
                    _nonce,
                    _deadline
                )
            );
    }

    function getBuyAcceptItemMessageHash(
        address _collection,
        address _addr1,
        address _addr2,
        address _addr3,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _price,
        uint256 _royaltyAmount,
        uint256 _nonce,
        uint256 _deadline
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _collection,
                    _addr1,
                    _addr2,
                    _addr3,
                    _tokenId,
                    _quantity,
                    _price,
                    _royaltyAmount,
                    _nonce,
                    _deadline
                )
            );
    }

    function getMetaDataMessageHash(
        address _collection,
        address _account,
        uint256 _tokenId,
        string memory _tokenURI,
        uint256 _nonce,
        uint256 _deadline
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _collection,
                    _account,
                    _tokenId,
                    _tokenURI,
                    _nonce,
                    _deadline
                )
            );
    }

    function addItem(
        address _collection,
        uint256 _tokenId,
        uint256 _supply,
        string memory _tokenURI,
        uint256 deadline,
        bytes memory _signature
    ) external whenNotPaused nonReentrant {
        require(
            _collection != address(0x0),
            "SKMarketPlace: Invalid collection address"
        );
        require(
            skCollection[_collection],
            "SKMarketPlace: This collection is not SKCollection"
        );
        require(
            block.timestamp <= deadline,
            "SKMarketPlace: Invalid expiration in addItem"
        );

        bytes32 messageHash = getAddItemMessageHash(
            _collection,
            _msgSender(),
            _tokenId,
            _supply,
            _tokenURI,
            nonces[_msgSender()],
            deadline
        );

        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(
            messageHash
        );

        require(
            ECDSA.recover(ethSignedMessageHash, _signature) == signer,
            "SKMarketPlace: Invalid Signature in addItem"
        );

        nonces[_msgSender()] ++;
        
        ISKCollection(_collection).mintItem(
            _msgSender(),
            _tokenId,
            _supply,
            _tokenURI
        );

        emit AddItem(
            _collection,
            _msgSender(),
            _tokenId,
            _supply,
            _tokenURI,
            block.timestamp
        );
    }

    function bundleTransfer(
        Receiver[] memory _receivers
    ) external whenNotPaused nonReentrant {
        require(
            _receivers.length > 0,
            "SKMarketPlace: Invalid receiver list"
        );

        for(uint256 i = 0; i < _receivers.length; i = unsafe_inc(i)) {
            require(
                _receivers[i].receiver != address(0x0) && _receivers[i].collections.length > 0,
                "SKMarketPlace: Invalid receiver address or collection list"
            );
            for(uint256 j = 0; j < _receivers[i].collections.length; j = unsafe_inc(j)) {
                require(
                    _receivers[i].collections[j].collection != address(0x0),
                    "SKMarketPlace: Invalid receiver's collection address"
                );
                if(_receivers[i].collections[j].batch) {
                    IERC1155(_receivers[i].collections[j].collection).safeBatchTransferFrom(
                        _msgSender(),
                        _receivers[i].receiver,
                        _receivers[i].collections[j].tokenIds,
                        _receivers[i].collections[j].quantities,
                        ""
                    );
                }
                else {
                    for(uint256 k = 0; k < _receivers[i].collections[j].tokenIds.length; k = unsafe_inc(k)) {
                        IERC721( _receivers[i].collections[j].collection).safeTransferFrom(
                            _msgSender(),
                            _receivers[i].receiver,
                            _receivers[i].collections[j].tokenIds[k]
                        );       
                    }
                }
            }
        }

        emit TransferBundle(_msgSender(), block.timestamp);
    }

    function buyCart(
        CartSeller[] calldata _sellers,
        uint256 _cartPrice,
        uint256 _payload,
        uint256 deadline,
        bytes memory _signature
    ) external whenNotPaused nonReentrant {
        require(
            _sellers.length > 0,
            "SKMarketPlace: Invalid seller list"
        );

        bytes memory data;
        for(uint i = 0; i < _sellers.length; i = unsafe_inc(i)) {
            for(uint j = 0; j < _sellers[i].collections.length; j = unsafe_inc(j)) {
                for(uint k = 0; k < _sellers[i].collections[j].tokenIds.length; k = unsafe_inc(k)) {
                    data = abi.encodePacked(data,
                        _sellers[i].collections[j].creators[k],
                        _sellers[i].collections[j].tokenIds[k],
                        _sellers[i].collections[j].quantities[k],
                        _sellers[i].collections[j].prices[k],
                        _sellers[i].collections[j].royaltyAmounts[k]
                    );
                }
                data = abi.encodePacked(data, _sellers[i].collections[j].collection, _sellers[i].collections[j].batch);
            }
            data = abi.encodePacked(data, _sellers[i].seller, _sellers[i].price);
        }
        bytes32 messageHash = keccak256(abi.encodePacked(data, _msgSender(), _cartPrice, _payload, nonces[_msgSender()], deadline));

        require(
            ECDSA.recover(ECDSA.toEthSignedMessageHash(messageHash), _signature) == signer,
            "SKMarketPlace: Invalid Signature in buyCart"
        );

        nonces[_msgSender()] ++;

        vxlToken.safeTransferFrom(_msgSender(), address(this), _cartPrice);

        uint256 totalFeeAmount;

        for(uint i = 0; i < _sellers.length; i = unsafe_inc(i)) {
            uint256 tokenAmount = _sellers[i].price;
            uint256 feeAmount;

            if (serviceFee > 0) {
                feeAmount = (tokenAmount * serviceFee) / (100 * 10**feeDecimals);
                tokenAmount = tokenAmount - feeAmount;
                totalFeeAmount = totalFeeAmount + feeAmount;
            }
            CartSeller memory sellerInfo = _sellers[i];
            for(uint j = 0; j < sellerInfo.collections.length; j = unsafe_inc(j)) {
                if(IERC165(sellerInfo.collections[j].collection).supportsInterface(InterfaceId_ERC2981)) {
                    address[] memory receivers = new address[](sellerInfo.collections[j].tokenIds.length);
                    uint256[] memory royaltyAmounts = new uint256[](sellerInfo.collections[j].tokenIds.length);
                    address collectionElm = sellerInfo.collections[j].collection;
                    for(uint k = 0; k < sellerInfo.collections[j].tokenIds.length; k = unsafe_inc(k)) {
                        (address _receiver, uint256 royaltyAmount) = IERC2981Royalties(
                            collectionElm
                        ).royaltyInfo(sellerInfo.collections[j].tokenIds[k], sellerInfo.collections[j].prices[k]);
                        royaltyAmount = royaltyAmount * sellerInfo.collections[j].quantities[k];
                        
                        receivers[k] = _receiver;
                        royaltyAmounts[k] = royaltyAmount;
                    }   

                    tokenAmount = _multiRoyaltyProcess(receivers, royaltyAmounts, tokenAmount);
                }
                else {
                    tokenAmount = _multiRoyaltyProcess(sellerInfo.collections[j].creators, sellerInfo.collections[j].royaltyAmounts, tokenAmount);
                }

                if(sellerInfo.collections[j].batch) {
                    IERC1155(sellerInfo.collections[j].collection).safeBatchTransferFrom(
                        sellerInfo.seller,
                        _msgSender(),
                        sellerInfo.collections[j].tokenIds,
                        sellerInfo.collections[j].quantities,
                        ""
                    );
                }
                else {
                    for(uint k = 0; k < sellerInfo.collections[j].tokenIds.length; k = unsafe_inc(k)) {
                        IERC721(sellerInfo.collections[j].collection).safeTransferFrom(
                            sellerInfo.seller,
                            _msgSender(),
                            sellerInfo.collections[j].tokenIds[k]
                        );
                    }
                }
            }
            vxlToken.safeTransfer(sellerInfo.seller, tokenAmount);
        }
        
        if (totalFeeAmount > 0) {
            vxlToken.safeTransfer(skTeamWallet, totalFeeAmount);
        }

        emit BuyCart(_msgSender(), _payload, block.timestamp);
    }

    function buyItem(
        address _collection,
        address _seller,
        address _creator,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _price,
        uint256 _royaltyAmount,
        uint256 deadline,
        bytes memory _signature
    ) external whenNotPaused nonReentrant collectionCheck(_collection) {
        require(
            _collection != address(0x0),
            "SKMarketPlace: Invalid collection address"
        );
        require(
            _seller != address(0x0),
            "SKMarketPlace: Invalid seller address"
        );
        require(
            _royaltyAmount == 0 || _creator != address(0x0),
            "SKMarketPlace: Invalid royalty receiver address"
        );
        require(
            _quantity > 0,
            "SKMarketPlace: Quantity should be greater than zero"
        );
        require(
            block.timestamp <= deadline,
            "SKMarketPlace: Invalid expiration in buyItem"
        );

        bytes32 messageHash = getBuyAcceptItemMessageHash(
            _collection,
            _msgSender(),
            _seller,
            _creator,
            _tokenId,
            _quantity,
            _price,
            _royaltyAmount,
            nonces[_msgSender()],
            deadline
        );

        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(
            messageHash
        );

        require(
            ECDSA.recover(ethSignedMessageHash, _signature) == signer,
            "SKMarketPlace: Invalid Signature in buyItem"
        );

        nonces[_msgSender()] ++;

        uint256 tokenAmount = _price * _quantity;
        uint256 feeAmount = 0;

        if (serviceFee > 0) {
            feeAmount = (tokenAmount * serviceFee) / (100 * 10**feeDecimals);
            tokenAmount = tokenAmount - feeAmount;
        }

        if(IERC165(_collection).supportsInterface(InterfaceId_ERC2981)) {
            (address _receiver, uint256 royaltyAmount) = IERC2981Royalties(
                _collection
            ).royaltyInfo(_tokenId, _price);
            royaltyAmount = royaltyAmount * _quantity;
            if(royaltyAmount > 0) {
                tokenAmount = _royaltyProcess(_msgSender(), _receiver, royaltyAmount, tokenAmount);
            }
        }
        else if(_royaltyAmount > 0) {
            tokenAmount = _royaltyProcess(_msgSender(), _creator, _royaltyAmount, tokenAmount);
        }

        vxlToken.safeTransferFrom(_msgSender(), _seller, tokenAmount);

        if (feeAmount > 0) {
            vxlToken.safeTransferFrom(_msgSender(), skTeamWallet, feeAmount);
        }

        //ERC721
        if (IERC721(_collection).supportsInterface(InterfaceId_ERC721)) {
            IERC721(_collection).safeTransferFrom(
                _seller,
                _msgSender(),
                _tokenId
            );
        } else {
            IERC1155(_collection).safeTransferFrom(
                _seller,    
                _msgSender(),
                _tokenId,
                _quantity,
                ""
            );
        }

        emit BuyItem(
            _collection,
            _msgSender(),
            _seller,
            _tokenId,
            _quantity,
            _price,
            block.timestamp
        );
    }
    
    function acceptItem(
        address _collection,
        address _buyer,
        address _creator,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _price,
        uint256 _royaltyAmount,
        uint256 deadline,
        bytes memory _signature
    ) external whenNotPaused nonReentrant collectionCheck(_collection) {
        require(
            _collection != address(0x0),
            "SKMarketPlace: Invalid collection address"
        );
        require(_buyer != address(0x0), "SKMarketPlace: Invalid buyer address");
        require(
            _royaltyAmount == 0 || _creator != address(0x0),
            "SKMarketPlace: Invalid royalty receiver address"
        );
        require(
            _quantity > 0,
            "SKMarketPlace: Quantity should be greater than zero"
        );
        require(
            block.timestamp <= deadline,
            "SKMarketPlace: Invalid expiration in acceptItem"
        );

        bytes32 messageHash = getBuyAcceptItemMessageHash(
            _collection,
            _buyer,
            _msgSender(),
            _creator,
            _tokenId,
            _quantity,
            _price,
            _royaltyAmount,
            nonces[_msgSender()],
            deadline
        );

        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(
            messageHash
        );

        require(
            ECDSA.recover(ethSignedMessageHash, _signature) == signer,
            "SKMarketPlace: Invalid Signature in acceptItem"
        );

        nonces[_msgSender()] ++;

        uint256 tokenAmount = _price * _quantity;
        uint256 feeAmount = 0;

        if (serviceFee > 0) {
            feeAmount = (tokenAmount * serviceFee) / (100 * 10**feeDecimals);
            tokenAmount = tokenAmount - feeAmount;
        }

        if(IERC165(_collection).supportsInterface(InterfaceId_ERC2981)) {
            (address _receiver, uint256 royaltyAmount) = IERC2981Royalties(
                _collection
            ).royaltyInfo(_tokenId, _price);
            royaltyAmount = royaltyAmount * _quantity;

            if(royaltyAmount > 0) {
                tokenAmount = _royaltyProcess(_buyer, _receiver, royaltyAmount, tokenAmount);
            }
        }
        else if(_royaltyAmount > 0) {
            tokenAmount = _royaltyProcess(_buyer, _creator, _royaltyAmount, tokenAmount);
        }

        vxlToken.safeTransferFrom(_buyer, _msgSender(), tokenAmount);

        if (feeAmount > 0) {
            vxlToken.safeTransferFrom(_buyer, skTeamWallet, feeAmount);
        }

        //ERC721
        if (IERC721(_collection).supportsInterface(InterfaceId_ERC721)) {
            IERC721(_collection).safeTransferFrom(
                _msgSender(),
                _buyer,
                _tokenId
            );
        } else {
            IERC1155(_collection).safeTransferFrom(
                _msgSender(),
                _buyer,
                _tokenId,
                _quantity,
                ""
            );
        }

        emit AcceptItem(
            _collection,
            _msgSender(),
            _buyer,
            _tokenId,
            _quantity,
            _price,
            block.timestamp
        );
    }

    function claimRoyalty(address account) external whenNotPaused nonReentrant {
        require(account != address(0x0), "Royalty claim address is invalid");

        uint256 balance = userRoyalties[_msgSender()];
        vxlToken.safeTransfer(account, balance);
        userRoyalties[_msgSender()] = 0;
    }

    function setReveal(
        address _collection,
        string memory _revealURI,
        uint256 deadline,
        bytes memory _signature
    ) external
    whenNotPaused
    collectionCheck(_collection) {
        require(IERC165(_collection).supportsInterface(InterfaceId_Reveal), "SKMarketPlace: not support reveal");

        require(
            block.timestamp <= deadline,
            "SKMarketPlace: Invalid expiration in setReveal"
        );

        bytes32 messageHash = getMetaDataMessageHash(
            _collection,
            _msgSender(),
            0,
            _revealURI,
            nonces[_msgSender()],
            deadline
        );

        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(
            messageHash
        );

        require(
            ECDSA.recover(ethSignedMessageHash, _signature) == signer,
            "SKMarketPlace: Invalid Signature in updateItemMetaData"
        );

        nonces[_msgSender()] ++;
        
        ISKReveal(_collection).setRevealURI(_revealURI);

        emit SetReveal(_collection, _msgSender(), _revealURI, block.timestamp);
    }

    function updateItemMetaData(
        address _collection,
        uint256 _tokenId,
        string memory _tokenURI,
        uint256 deadline,
        bytes memory _signature
    ) external
     whenNotPaused
     collectionCheck(_collection) 
      {
        require(
            _collection != address(0x0),
            "SKMarketPlace: Invalid collection address"
        );

        if (IERC721(_collection).supportsInterface(InterfaceId_ERC721)) {
            require(
                IERC721(_collection).ownerOf(_tokenId) == _msgSender(),
                "SKMarketPlace: update of token that is not own"
            );
        } else {
            require(
                IERC1155Supply(_collection).totalSupply(_tokenId) == IERC1155Supply(_collection).balanceOf(_msgSender(), _tokenId),
                "SKMarketPlace: update of token that is not own"
            );
        }

        require(
            block.timestamp <= deadline,
            "SKMarketPlace: Invalid expiration in updateItemMetaData"
        );

        bytes32 messageHash = getMetaDataMessageHash(
            _collection,
            _msgSender(),
            _tokenId,
            _tokenURI,
            nonces[_msgSender()],
            deadline
        );

        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(
            messageHash
        );

        require(
            ECDSA.recover(ethSignedMessageHash, _signature) == signer,
            "SKMarketPlace: Invalid Signature in updateItemMetaData"
        );

        nonces[_msgSender()] ++;

        // update metadata
        ISKCollection(_collection).setTokenURI(_tokenId, _tokenURI);

        emit UpdateItemMetaData(
            _collection,
            _msgSender(),
            _tokenId,
            _tokenURI,
            block.timestamp
        );
    }

    function changeVxlToken(address _newVxlToken)
        external
        onlyTimeLockController
    {
        require(
            _newVxlToken != address(0x0),
            "SKMarketPlace: Invalid new vxltoken address"
        );
        vxlToken = IERC20(_newVxlToken);
        emit SetVxlTokenAddress(_newVxlToken);
    }

    function addSKCollection(address _newCollection)
        external
        whenNotPaused
        collectionCheck(_newCollection)
        onlyTimeLockController
    {
        require(
            _newCollection != address(0x0),
            "SKMarketPlace: Invalid new collection address"
        );
        skCollection[_newCollection] = true;

        emit AddSKCollection(_newCollection);
    }

    function removeSKCollection(address _collection)
        external
        whenNotPaused
        onlyTimeLockController
    {
        require(
            _collection != address(0x0),
            "SKMarketPlace: Invalid collection address"
        );
        require(
            skCollection[_collection],
            "SKMarketPlace: This collection is not included in SKCollection"
        );

        delete skCollection[_collection];

        emit RemoveSKCollection(_collection);
    }

    function setTimeLockController(address _timeLockController)
        external
        onlyTimeLockController
    {
        require(
            _timeLockController != address(0x0),
            "SKMarketPlace: Invalid TimeLockController"
        );
        timeLockController = _timeLockController;
    }

    function setSigner(address _signer) external onlyTimeLockController {
        require(_signer != address(0x0), "SKMarketPlace: Invalid signer");
        signer = _signer;
    }

    function setServiceFee(uint256 _serviceFee)
        external
        onlyTimeLockController
    {
        require(
            _serviceFee < 10000,
            "SKMarketPlace: ServiceFee should not reach 100 percent"
        );
        serviceFee = _serviceFee;
    }

    function setSKTeamWallet(address _skTeamWallet)
        external
        onlyTimeLockController
    {
        require(
            _skTeamWallet != address(0x0),
            "SKMarketPlace: Invalid admin team wallet address"
        );
        skTeamWallet = _skTeamWallet;
    }

    function setMarketAddressforNFTCollection(address _collection, address _newMarketplaceAddress)
        external
        whenNotPaused
        collectionCheck(_collection) 
        onlyTimeLockController
    {
        ISKCollection(_collection).setMarketplaceAddress(_newMarketplaceAddress);
    }

    function withdrawRemainingVXLToken(address account) external onlyTimeLockController {
        uint256 balance = vxlToken.balanceOf(address(this));
        vxlToken.safeTransfer(account, balance);
    }

    function pause() external onlyTimeLockController {
        _pause();
    }

    function unpause() external onlyTimeLockController {
        _unpause();
    }

    function unsafe_inc(uint x) private pure returns (uint) {
        unchecked { return x + 1; }
    }

    function _multiRoyaltyProcess(
        address[] memory receivers,
        uint256[] memory royaltyAmounts,
        uint256 tokenAmount
    ) private returns (uint256) {

        uint256 totalRoyaltyAmount = 0;

        for(uint256 i = 0; i < receivers.length; i ++) {
            if(receivers[i] != address(0x0) && royaltyAmounts[i] > 0) {
                userRoyalties[receivers[i]] += royaltyAmounts[i];
                totalRoyaltyAmount += royaltyAmounts[i];
            }
        }
        if(totalRoyaltyAmount > 0) {
            require(
                totalRoyaltyAmount < tokenAmount,
                "SKMarketPlace: RoyaltyAmount exceeds than tokenAmount"
            );

            unchecked {
                tokenAmount = tokenAmount - totalRoyaltyAmount;
            }
        }
        return tokenAmount;
    }

    function _royaltyProcess(
        address _sender, address receiver, uint256 royaltyAmount, uint256 tokenAmount
    ) private returns (uint256) {
        require(
            royaltyAmount < tokenAmount,
            "SKMarketPlace: RoyaltyAmount exceeds than tokenAmount"
        );
        vxlToken.safeTransferFrom(_sender, address(this), royaltyAmount);
        userRoyalties[receiver] += royaltyAmount;
        unchecked {
            tokenAmount = tokenAmount - royaltyAmount;
        }
        return tokenAmount;
    }
}