// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
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
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any (single) token transfer. This includes minting and burning.
     * See {_beforeConsecutiveTokenTransfer}.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any (single) transfer of tokens. This includes minting and burning.
     * See {_afterConsecutiveTokenTransfer}.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called before consecutive token transfers.
     * Calling conditions are similar to {_beforeTokenTransfer}.
     *
     * The default implementation include balances updates that extensions such as {ERC721Consecutive} cannot perform
     * directly.
     */
    function _beforeConsecutiveTokenTransfer(
        address from,
        address to,
        uint256, /*first*/
        uint96 size
    ) internal virtual {
        if (from != address(0)) {
            _balances[from] -= size;
        }
        if (to != address(0)) {
            _balances[to] += size;
        }
    }

    /**
     * @dev Hook that is called after consecutive token transfers.
     * Calling conditions are similar to {_afterTokenTransfer}.
     */
    function _afterConsecutiveTokenTransfer(
        address, /*from*/
        address, /*to*/
        uint256, /*first*/
        uint96 /*size*/
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
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

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
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

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";
import {SafeTransferLib} from "../utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "../utils/FixedPointMathLib.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)
abstract contract ERC4626 is ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, _asset.decimals()) {
        asset = _asset;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@dex/lib/Structs.sol';
import '@dex/lib/FinMath.sol';

import '@dex/perp/interfaces/IConfig.sol';

import {PriceData} from '@dex/oracles/interfaces/IOracle.sol';

library FeesMath {
    using FinMath for uint;
    using FinMath for uint24;
    using FinMath for int24;

    // @dev External function used in engine to compute premium and premium fee
    function premium(
        Order storage o,
        PriceData memory p,
        int24 premiumBps,
        IConfig config,
        uint8 minPremiumFeeDiscountPerc
    ) public view returns (int premium_, uint premiumFee) {
        uint notional = o.amount.wmul(p.price);
        premium_ = premiumBps.bps(notional);
        int fee = config.premiumFeeBps().bps(premium_);
        int _minPremiumFee = int(
            (config.getAmounts().minPremiumFee *
                uint((minPremiumFeeDiscountPerc))) / 100
        );
        premiumFee = uint((fee > _minPremiumFee) ? fee : _minPremiumFee);
    }

    // @dev External function used in engine.
    function traderFees(
        Order storage o,
        PriceData memory p,
        IConfig config
    ) external view returns (uint) {
        uint notional = o.amount.wmul(p.price);
        int fee = config.traderFeeBps().bps(int(notional));
        return uint(fee);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@dex/lib/SafeCast.sol';

// Percentage using BPS
// https://stackoverflow.com/questions/3730019/why-not-use-double-or-float-to-represent-currency/3730040#3730040
// Ranges:
// int(x): -2^(x-1) to [2^(x-1)]-1
// uint(x): 0 to [2^(x)]-1

// @notice Simple multiplication with native overflow protection for uint when
// using solidity above 0.8.17.
library FinMath {
    using SafeCast for uint;
    using SafeCast for int;

    // Bps
    int public constant iBPS = 10 ** 4; // basis points [TODO: move to 10**4]
    uint public constant uBPS = 10 ** 4; // basis points [TODO: move to 10**4]

    // Fixed Point arithimetic
    uint constant WAD = 10 ** 18;
    int constant iWAD = 10 ** 18;
    uint constant LIMIT = 2 ** 255;

    int internal constant iMAX_128 = 0x100000000000000000000000000000000; // 2^128
    int internal constant iMIN_128 = -0x100000000000000000000000000000000; // 2^128
    uint internal constant uMAX_128 = 0x100000000000000000000000000000000; // 2^128

    // --- SIGNED CAST FREE

    function mul(int x, int y) internal pure returns (int z) {
        z = x * y;
    }

    function div(int a, int b) internal pure returns (int z) {
        z = a / b;
    }

    function sub(int a, int b) internal pure returns (int z) {
        z = a - b;
    }

    function add(int a, int b) internal pure returns (int z) {
        z = a + b;
    }

    // --- UNSIGNED CAST FREE

    function mul(uint x, uint y) internal pure returns (uint z) {
        z = x * y;
    }

    function div(uint a, uint b) internal pure returns (uint z) {
        z = a / b;
    }

    function add(uint a, uint b) internal pure returns (uint z) {
        z = a + b;
    }

    function sub(uint a, uint b) internal pure returns (uint z) {
        z = a - b;
    }

    // --- MIXED TYPES SAFE CAST
    function mul(uint x, int y) internal pure returns (int z) {
        z = x.i256() * y;
    }

    function div(int a, uint b) internal pure returns (int z) {
        z = a / b.i256();
    }

    function add(uint x, int y) internal pure returns (uint z) {
        bool flip = y < 0 ? true : false;
        z = flip ? x - (-y).u256() : x + y.u256();
    }

    function add(int x, uint y) internal pure returns (int z) {
        z = x + y.i256();
    }

    function sub(uint x, int y) internal pure returns (uint z) {
        bool flip = y < 0 ? true : false;
        z = flip ? x + (-y).u256() : x - y.u256();
    }

    function sub(int x, uint y) internal pure returns (int z) {
        z = x - y.i256();
    }

    function isub(uint x, uint y) internal pure returns (int z) {
        int x1 = x.i256();
        int y1 = y.i256();
        z = x1 - y1;
    }

    // --- FIXED POINT [1e18 precision]

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wmul(int x, int y) internal pure returns (int z) {
        z = add(mul(x, y), iWAD / 2) / iWAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function wdiv(int x, int y) internal pure returns (int z) {
        z = add(mul(x, iWAD), y / 2) / y;
    }

    // --- FIXED POINT BPS [1e4 precision]

    // @notice Calculate percentage using BPS precision
    // @param bps input in base points
    // @param x the number we want to calculate percentage
    // @return the % of the x including fixed-point arithimetic
    function bps(int bp, uint x) internal pure returns (int z) {
        require(bp < iMAX_128, 'bps-x-overflow');
        z = (mul(x.i256(), bp)) / iBPS;
    }

    function bps(uint bp, uint x) internal pure returns (uint z) {
        require(bp < uMAX_128, 'bps-x-overflow');
        z = mul(x, bp) / uBPS;
    }

    function bps(uint bp, int x) internal pure returns (int z) {
        require(bp < uMAX_128, 'bps-x-overflow');
        z = mul(x, bp.i256()) / iBPS;
    }

    function bps(int bp, int x) internal pure returns (int z) {
        require(bp < iMAX_128, 'bps-x-overflow');
        z = mul(x, bp) / iBPS;
    }

    function ibps(uint bp, uint x) internal pure returns (int z) {
        require(bp < uMAX_128, 'bps-x-overflow');
        z = (mul(x, bp) / uBPS).i256();
    }

    // @dev Transform to BPS precision
    function bps(uint x) internal pure returns (uint) {
        return mul(x, uBPS);
    }

    // @notice Return the positive number of an int256 or zero if it was negative
    // @parame x the number we want to normalize
    // @return zero or a positive number
    function pos(int a) internal pure returns (uint) {
        return (a >= 0) ? uint(a) : 0;
    }

    // @notice somethimes we need to print int but cast them to uint befor
    function inv(int x) internal pure returns (uint z) {
        z = x < 0 ? uint(-x) : uint(x);
    }

    // @notice Copied from open-zeppelin SignedMath
    // @dev must be unchecked in order to support `n = type(int256).min`
    function abs(int x) internal pure returns (uint) {
        unchecked {
            return uint(x >= 0 ? x : -x);
        }
    }

    // --- MINIMUM and MAXIMUM

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }

    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }

    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }

    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import './Positions.sol';
import '@dex/lib/LeverageMath.sol';
import '@dex/lib/Structs.sol';
import '@dex/lib/FinMath.sol';
import '@dex/perp/interfaces/IVault.sol';
import {PriceData} from '@dex/oracles/interfaces/IOracle.sol';

error Inexistent(uint);

library JoinLib {
    using FinMath for uint24;
    using FinMath for int;
    using FinMath for uint;

    using LeverageMath for Match;

    event MatchInexistant(uint indexed matchId, uint indexed orderId);
    event MakerIsTrader(
        uint indexed matchId,
        address indexed maker,
        uint orderId
    );
    event LowTraderCollateral(
        uint indexed matchId,
        address indexed trader,
        uint orderId,
        uint traderCollateral,
        uint collateralNeeded
    );

    event LowMakerCollateralForFees(
        uint indexed matchId,
        address indexed maker,
        uint orderId,
        uint allocatedCollateral,
        uint makerFees
    );

    event LowTraderCollateralForFees(
        uint indexed matchId,
        address indexed trader,
        uint orderId,
        uint allocatedCollateral,
        uint traderFees
    );

    event MaxOpeningLeverage(
        address indexed user,
        uint matchId,
        uint orderId,
        uint price
    );

    event LowMakerCollateral(
        uint indexed matchId,
        address indexed maker,
        uint orderId,
        uint makerCollateral,
        uint collateralNeeded
    );

    event OrderExpired(
        uint indexed matchId,
        address indexed trader,
        address indexed maker,
        uint orderId,
        uint orderTimestamp
    );

    event MatchAlreadyActive(
        uint indexed matchId,
        uint indexed orderId,
        address indexed trader
    );

    // @notice Sometimes the trader choose a position size smaller than the picked
    // maker position, so we have to ajust the collateral and amount accordingly.
    function normalize(
        Match memory m,
        uint amount
    ) public pure returns (Match memory) {
        if (amount < m.amount) {
            m.collateralM = ((m.collateralM.mul(amount)) / m.amount);
            m.amount = amount;
        }
        return m;
    }

    function beforeChecks(
        Match memory m,
        Order memory o,
        uint orderId,
        uint matchId,
        address maker,
        uint balance,
        int feesM,
        int feesT
    ) public returns (bool) {
        // check if order is canceled or has already been matched
        if (m.trader != 0) {
            emit MatchAlreadyActive(matchId, orderId, o.owner);
            return false;
        }

        if (o.owner == maker) {
            emit MakerIsTrader(matchId, maker, orderId);
            return false;
        }

        if (balance < o.collateral) {
            emit LowTraderCollateral(
                matchId,
                o.owner,
                orderId,
                balance,
                o.collateral
            );
            return false;
        }

        if (int(o.collateral) <= feesT) {
            emit LowTraderCollateralForFees(
                matchId,
                o.owner,
                orderId,
                o.collateral,
                uint(feesT)
            );
            return false;
        }

        if (int(m.collateralM) <= feesM) {
            emit LowMakerCollateralForFees(
                matchId,
                maker,
                orderId,
                m.collateralM,
                uint(feesM)
            );
            return false;
        }

        return true;
    }

    struct AfterCheck {
        PriceData priceData;
        IConfig config;
        IVault vault;
        address maker;
        address trader;
        uint matchId;
        uint orderId;
        uint maxTimestamp;
        uint8 tokenDecimals;
    }

    function afterChecks(
        Match memory m,
        AfterCheck calldata params
    ) public returns (bool) {
        if (
            m.isOverLeveraged_(
                params.priceData,
                params.config,
                false,
                params.tokenDecimals
            )
        ) {
            emit MaxOpeningLeverage(
                params.trader,
                params.matchId,
                params.orderId,
                params.priceData.price
            );
            return false;
        }

        if (
            m.isOverLeveraged_(
                params.priceData,
                params.config,
                true,
                params.tokenDecimals
            )
        ) {
            emit MaxOpeningLeverage(
                params.maker,
                params.matchId,
                params.orderId,
                params.priceData.price
            );
            return false;
        }

        if (params.vault.collateral(params.maker) < m.collateralM) {
            emit LowMakerCollateral(
                params.matchId,
                params.maker,
                params.orderId,
                params.vault.collateral(params.maker),
                m.collateralM
            );
            return false;
        }

        if (
            params.maxTimestamp != 0 &&
            params.priceData.timestamp > params.maxTimestamp
        ) {
            emit OrderExpired(
                params.matchId,
                params.trader,
                params.maker,
                params.orderId,
                params.maxTimestamp
            );
            return false;
        }

        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@dex/lib/Structs.sol';
import '@dex/lib/PnLMath.sol';
import '@dex/lib/FinMath.sol';

import '@dex/perp/interfaces/IConfig.sol';
import {PriceData} from '@dex/oracles/interfaces/IOracle.sol';

library LeverageMath {
    using FinMath for uint;
    using FinMath for int;
    using PnLMath for Match;

    // TODO: move min/max to be used from FinMath
    function _min(uint a, uint b) internal pure returns (uint res) {
        res = (a <= b) ? a : b;
    }

    function _max(uint a, uint b) internal pure returns (uint res) {
        res = (a >= b) ? a : b;
    }

    // @dev External function.
    function isOverLeveraged(
        Match storage m,
        PriceData calldata priceData,
        IConfig config,
        bool isMaker,
        uint8 collateralDecimals
    ) public view returns (bool) {
        return
            isOverLeveraged_(m, priceData, config, isMaker, collateralDecimals);
    }

    function isOverLeveraged_(
        Match memory m,
        PriceData calldata priceData,
        IConfig config,
        bool isMaker,
        uint8 collateralDecimals
    ) public view returns (bool) {
        Leverage memory leverage = config.getLeverage();
        uint timeElapsed = m.start == 0 ? 0 : block.timestamp - m.start;
        return
            getLeverage(m, priceData, isMaker, 0, collateralDecimals) >
            (
                isMaker
                    ? getMaxLeverage(
                        config,
                        m.frPerYear,
                        timeElapsed == 0
                            ? block.timestamp - priceData.timestamp
                            : timeElapsed
                    )
                    : timeElapsed == 0
                    ? leverage.maxLeverageOpen
                    : leverage.maxLeverageOngoing
            );
    }

    // @dev Internal function
    function getMaxLeverage(
        IConfig config,
        uint fr,
        uint timeElapsed
    ) public view returns (uint maxLeverage) {
        // console.log("[_getMaxLeverage()] fr >= fmfr --> ", fr >= fmfr);
        // console.log("[_getMaxLeverage()] timeElapsed >= leverage.maxTimeGuarantee --> ", timeElapsed >= leverage.maxTimeGuarantee);
        Leverage memory leverage = config.getLeverage();
        // NOTE: Expecting time elapsed in days
        timeElapsed = timeElapsed / 86400;
        maxLeverage = ((fr >= config.fmfrPerYear()) ||
            (timeElapsed >= leverage.maxTimeGuarantee))
            ? (timeElapsed == 0)
                ? leverage.maxLeverageOpen
                : leverage.maxLeverageOngoing
            : _min(
                _max(
                    ((leverage.s * leverage.FRTemporalBasis * leverage.b)
                        .bps() /
                        ((leverage.maxTimeGuarantee - timeElapsed) *
                            (config.fmfrPerYear() - fr + leverage.f0))),
                    leverage.minGuaranteedLeverage
                ),
                leverage.maxLeverageOpen
            );
        // maxLeverage = (fr >= fmfr) ? type(uint).max : (minRequiredMargin * timeToExpiry / (totTime * (fmfr - fr)));
    }

    // @dev Internal function
    // NOTE: For leverage, notional depends on entryPrice while accruedFR is transformed into collateral using currentPrice
    // Reasons
    // LP Pool risk is connected to Makers' Leverage
    // (even though we have a separate check for liquidation, we use leverage to control collateral withdrawal)
    // so higher leverage --> LP Pool risk increases
    // Makers' are implicitly always long market for the accruedFR component
    // NOTE: The `overrideAmount` is used in `join()` since we split after having done a bunch of checks so the `m.amount` is not the correct one in that case
    function getLeverage(
        Match memory m,
        PriceData calldata priceData,
        bool isMaker,
        uint overrideAmount,
        uint8 collateralDecimals
    ) public view returns (uint leverage) {
        // NOTE: This is correct almost always with the exception of the levarge computation
        // for the maker when they submit an order which is not picked yet and
        // as a consquence we to do not have an entryPrice yet so we use currentPrice
        uint notional = (10 ** (collateralDecimals))
            .wmul((overrideAmount > 0) ? overrideAmount : m.amount)
            .wmul(
                (isMaker && (m.trader == 0)) ? priceData.price : m.entryPrice
            );
        uint realizedPnL = m.accruedFR(priceData, collateralDecimals);
        uint collateral_plus_realizedPnL = (isMaker)
            ? m.collateralM + realizedPnL
            : m.collateralT - _min(m.collateralT, realizedPnL);
        if (collateral_plus_realizedPnL == 0) return type(uint).max;

        // TODO: this is a simplification when removing the decimals lib,
        //       need to check and move to FinMath lib
        leverage = notional.bps() / collateral_plus_realizedPnL;
    }
}

pragma solidity ^0.8.17;

import '@base64/base64.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

library NFTDescriptor {
    function constructTokenURI(
        uint tokenId
    ) public pure returns (string memory) {
        string memory name = string.concat(
            'test name: ',
            Strings.toString(tokenId)
        );
        string memory descriptionPartOne = 'test description part 1';
        string memory descriptionPartTwo = 'test description part 2';
        string memory image = Base64.encode(bytes(generateSVGImage()));

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                descriptionPartOne,
                                descriptionPartTwo,
                                '", "image": "',
                                'data:image/svg+xml;base64,',
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function generateSVGImage() internal pure returns (string memory svg) {
        return
            string(
                abi.encodePacked(
                    '<?xml version="1.0" encoding="UTF-8"?>',
                    '<svg version="1.1" viewBox="50 20 600 600" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    '<g>',
                    '<path d="m589.12 253.12h-82.883c-7.8398 0-15.121 3.3594-20.16 8.9609l-13.441 15.68-24.641-56c-6.1602-13.441-21.84-19.602-35.281-14-13.441 6.1602-19.602 21.84-14 35.281l41.441 94.641c3.9219 8.3984 11.199 14.559 20.719 15.68 1.1211 0 2.8008 0.55859 3.9219 0.55859 7.8398 0 15.121-3.3594 20.16-8.9609l33.039-38.078h70.559c14.559 0 26.879-11.762 26.879-26.879 0.56641-14.562-11.195-26.883-26.312-26.883z"/>',
                    '<path d="m353.92 221.76c-6.1602-13.441-21.84-19.602-35.281-14-13.441 6.1602-19.602 21.84-14 35.281l41.441 94.641c4.4805 10.078 14.559 16.238 24.641 16.238 3.3594 0 7.2812-0.55859 10.641-2.2383 13.441-6.1602 19.602-21.84 14-35.281z"/>',
                    '<path d="m259.28 221.76c-3.9219-8.3984-11.199-14.559-20.719-15.68-8.9609-1.6797-18.48 1.6797-24.078 8.9609l-33.039 38.078h-70.566c-14.559 0-26.879 11.762-26.879 26.879 0 14.559 11.762 26.879 26.879 26.879h82.879c7.8398 0 15.121-3.3594 20.16-8.9609l13.441-15.68 24.641 56c4.4805 10.078 14.559 16.238 24.641 16.238 3.3594 0 7.2812-0.55859 10.641-2.2383 13.441-6.1602 19.602-21.84 14-35.281z"/>',
                    '</g>',
                    '</svg>'
                )
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import './Positions.sol';
import '@dex/lib/LeverageMath.sol';
import '@dex/lib/Structs.sol';
import '@dex/perp/interfaces/IConfig.sol';
import '@dex/lib/FinMath.sol';
import '@dex/lib/SafeCast.sol';
import {PriceData} from '@dex/oracles/interfaces/IOracle.sol';

library PnLMath {
    using FinMath for uint24;
    using FinMath for int;
    using FinMath for uint;
    using SafeCast for uint;

    // NOTE: Need to move this computation out of `pnl()` to avoid the stack too deep issue in it
    function _gl(
        uint amount,
        int dp,
        uint collateralDecimals
    ) internal pure returns (int gl) {
        gl = int(10 ** (collateralDecimals)).wmul(int(amount)).wmul(dp); // Maker's GL
    }

    function pnl(
        Match memory m,
        uint tokenId,
        uint timestamp,
        uint exitPrice,
        uint makerFRFee,
        uint8 collateralDecimals
    ) public pure returns (int pnlM, int pnlT, uint FRfee) {
        require(timestamp > m.start, 'engine/wrong_timestamp');
        require(
            (tokenId == m.maker) || (tokenId == m.trader),
            'engine/invalid-tokenId'
        );
        // uint deltaT = timestamp.sub(m.start);
        // int deltaP = exitPrice.isub(m.entryPrice);
        // int delt = (m.pos == POS_SHORT) ? -deltaP : deltaP;

        // NOTE: FR is seen from the perspective of the maker and it is >= 0 always by construction
        uint aFR = _accruedFR(
            timestamp.sub(m.start),
            m.frPerYear,
            m.amount,
            exitPrice,
            collateralDecimals
        );

        // NOTE: `m.pos` is the Maker Position
        int mgl = (((m.pos == POS_SHORT) ? int(-1) : int(1)) *
            _gl(m.amount, exitPrice.isub(m.entryPrice), collateralDecimals));

        // NOTE: Before deducting FR Fees, the 2 PnLs need to be symmetrical
        pnlM = mgl + int(aFR);
        pnlT = -pnlM;

        // NOTE: After the FR fees, no more symmetry
        FRfee = makerFRfees(makerFRFee, aFR);
        pnlM -= int(FRfee);
    }

    function makerFRfees(
        uint makerFRFee,
        uint fundingRate
    ) internal pure returns (uint) {
        return makerFRFee.bps(fundingRate);
    }

    function accruedFR(
        Match memory m,
        PriceData memory priceData,
        uint8 collateralDecimals
    ) public view returns (uint) {
        if (m.start == 0) return 0;
        uint deltaT = block.timestamp.sub(m.start);
        return
            _accruedFR(
                deltaT,
                m.frPerYear,
                m.amount,
                priceData.price,
                collateralDecimals
            );
    }

    function _accruedFR(
        uint deltaT,
        uint frPerYear,
        uint amount,
        uint price,
        uint8 collateralDecimals
    ) public pure returns (uint) {
        return
            (10 ** (collateralDecimals))
                .mul(frPerYear)
                .bps(deltaT)
                .wmul(amount)
                .wmul(price) / (365 days); // 3600 * 24 * 365
    }

    function isLiquidatable(
        Match memory m,
        uint tokenId,
        uint price,
        IConfig config,
        uint8 collateralDecimals
    ) external view returns (int pnlM, int pnlT, bool) {
        // check if the match has not previously been deleted
        (pnlM, pnlT, ) = pnl(
            m,
            tokenId,
            block.timestamp,
            price,
            0,
            collateralDecimals
        );

        if (m.maker == 0) return (pnlM, pnlT, false);
        if (tokenId == m.maker) {
            return (
                pnlM,
                pnlT,
                pnlM.add(m.collateralM).sub(
                    config.bufferMakerBps().ibps(m.collateralM)
                ) < config.bufferMaker().i256()
            );
        } else if (tokenId == m.trader) {
            return (
                pnlM,
                pnlT,
                pnlT.add(m.collateralT).sub(
                    config.bufferTraderBps().ibps(m.collateralT)
                ) < config.bufferTrader().i256()
            );
        } else {
            return (pnlM, pnlT, false);
        }
    }
}

pragma solidity ^0.8.17;

int8 constant POS_SHORT = -1;
int8 constant POS_NEUTRAL = 0;
int8 constant POS_LONG = 1;

// SPDX-License-Identifier: GPL-2.0-or-later
// Uniswap lib
pragma solidity 0.8.17;

// @title Safe casting methods
// @notice Contains methods for safely casting between types
library SafeCast {
    // @notice Cast a uint256 to a uint160, revert on overflow
    // @param y The uint256 to be downcasted
    // @return z The downcasted integer, now type uint160
    function u160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y, 'cast-u160');
    }

    // @notice Cast a int256 to a int128, revert on overflow or underflow
    // @param y The int256 to be downcasted
    // @return z The downcasted integer, now type int128
    function i128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y, 'cast-i128');
    }

    // @notice Cast a uint256 to a int256, revert on overflow
    // @param y The uint256 to be casted
    // @return z The casted integer, now type int256
    function i256(uint256 y) internal pure returns (int256 z) {
        require(y < 2 ** 255, 'cast-i256');
        z = int256(y);
    }

    // @notice Cast an int256, check if it's not negative
    // @param y The uint256 to be downcasted
    // @return z The downcasted integer, now type uint160
    function u256(int256 y) internal pure returns (uint256 z) {
        require(y >= 0, 'cast-u256');
        z = uint256(y);
    }
}

pragma solidity ^0.8.17;

struct Match {
    int8 pos; // If maker is short = true
    int24 premiumBps; // In percent of the amount
    uint24 frPerYear;
    uint24 fmfrPerYear; // The fair market funding rate when the match was done
    uint maker; // maker vault token-id
    uint trader; // trader vault token-id
    uint amount;
    uint start; // timestamp of the match starting
    uint entryPrice;
    uint collateralM; // Maker  collateral
    uint collateralT; // Trader collateral
    // uint256 nextMatchId; // Next match id, in case of split, used by the automatic rerooting
    uint8 minPremiumFeeDiscountPerc; // To track what perc of minPreomiumFee to pay, used when the order is split
    bool close; // A close request for this match is pending
}

struct Order {
    bool canceled;
    int8 pos;
    address owner; // trader address
    uint tokenId;
    uint matchId; // trader selected matchid
    uint amount;
    uint collateral;
    uint collateralAdd;
    // NOTE: Used to apply the check for the Oracle Latency Protection
    uint timestamp;
    // NOTE: In this case, we give trader the max full control on the price for matching: no assumption it is symmetric and we do not compute any percentage so introducing some approximations, the trader writes the desired prices
    uint slippageMinPrice;
    uint slippageMaxPrice;
    uint maxTimestamp;
}

struct CloseOrder {
    uint matchId;
    uint timestamp;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IOracle.sol';

contract GelatoOracle is IOracle, Ownable {
    PriceData lastPrice;
    /// @notice min price deviation to accept a price update
    uint public deviation;
    address public dataProvider;
    uint8 _decimals;
    /// @notice heartbeat duration in seconds
    uint40 public heartBeat;

    modifier ensurePriceDeviation(uint newValue) {
        if (_computeDeviation(newValue) > deviation) {
            _;
        }
    }

    function _computeDeviation(uint newValue) internal view returns (uint) {
        if (lastPrice.price == 0) {
            return deviation + 1; // return the deviation amount if price is 0, so that the update will happen
        } else if (newValue > lastPrice.price) {
            return ((newValue - lastPrice.price) * 1e20) / lastPrice.price;
        } else {
            return ((lastPrice.price - newValue) * 1e20) / lastPrice.price;
        }
    }

    constructor() {}

    function initialize(
        uint deviation_,
        uint8 decimals_,
        uint40 heartBeat_,
        address dataProvider_
    ) external {
        _decimals = decimals_;
        deviation = deviation_;
        heartBeat = heartBeat_;
        dataProvider = dataProvider_;
        _transferOwnership(msg.sender);
    }

    // to be called by gelato bot to know if a price update is needed
    function isPriceUpdateNeeded(uint newValue) external view returns (bool) {
        if ((lastPrice.timestamp + heartBeat) < block.timestamp) {
            return true;
        } else if (_computeDeviation(newValue) > deviation) {
            return true;
        }
        return false;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function setPrice(uint _value) external onlyOwner {
        lastPrice.price = uint128(_value);
        lastPrice.timestamp = uint128(block.timestamp);

        emit NewValue(lastPrice.price, lastPrice.timestamp);
    }

    function getPrice() external view override returns (PriceData memory) {
        return lastPrice;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/proxy/Clones.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './GelatoOracle.sol';
import './interfaces/IOracleFactory.sol';

/// @title GelatoOracleFactory
/// @notice
/// @dev
contract GelatoOracleFactory is Ownable, IOracleFactory {
    using Clones for address;

    modifier onlyDataProvider() {
        require(msg.sender == dataProvider, 'onlyDataProvider');
        _;
    }

    address oracleImplementation;

    address public dataProvider;

    mapping(bytes32 => address) oracles;

    /// @notice
    /// @dev
    /// @param dataProvider_ (address)
    constructor(address dataProvider_) {
        dataProvider = dataProvider_;
        oracleImplementation = address(new GelatoOracle());
    }

    /// @notice
    /// @dev
    /// @param endpoints (accept up to 4 endpoints for one oracle)
    function deployOracle(
        uint deviation,
        uint8 decimals,
        uint40 heartBeat,
        string[4] memory endpoints
    ) external onlyOwner returns (address newOracle) {
        bytes32 key = keccak256(
            abi.encodePacked(
                deviation,
                decimals,
                heartBeat,
                endpoints[0],
                endpoints[1],
                endpoints[2],
                endpoints[3]
            )
        );
        // if that oracle does not exist yet, create it
        if (oracles[key] == address(0)) {
            newOracle = oracleImplementation.clone();
            GelatoOracle(newOracle).initialize(
                deviation,
                decimals,
                heartBeat,
                address(this)
            );
            oracles[key] = newOracle;
            emit OracleDeployed(newOracle, key);
        } else {
            newOracle = oracles[key];
        }
    }

    function getOracle(bytes32 key) public view returns (GelatoOracle) {
        return GelatoOracle(oracles[key]);
    }

    function setPrice(bytes32 key, uint _value) external onlyDataProvider {
        GelatoOracle gelatoOracle = GelatoOracle(oracles[key]);
        require(oracles[key] != address(0), 'no_oracle');
        gelatoOracle.setPrice(_value);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

struct PriceData {
    // wad
    uint256 price;
    uint256 timestamp;
}

interface IOracle {
    event NewValue(uint256 value, uint256 timestamp);

    function setPrice(uint256 _value) external;

    function decimals() external view returns (uint8);

    function getPrice() external view returns (PriceData memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IOracleFactory {
    event OracleDeployed(address indexed oracle, bytes32 indexed key);
}

pragma solidity ^0.8.17;

import '@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol';

import './interfaces/IConfig.sol';

contract Config is IConfig, OwnableUpgradeable {
    uint24 public bufferTraderBps;
    uint24 public bufferMakerBps;
    uint public bufferTrader;
    uint public bufferMaker;
    uint24 public openInterestCap; // 4 decimals (bips)
    uint24 public fmfrPerYear; // 4 decimals (bips)
    uint24 public frPerYearModulo; // 4 decimals (bips)
    uint24 public makerFRFeeBps; // [bips] Maker fee over his FR gains
    uint128 public minPremiumFee;
    uint24 public premiumFeeBps; // % of the premium that protocol collects
    uint24 public minFRPerYear; // 4 decimals (bips)
    uint128 public orderMinAmount;
    uint24 public traderFeeBps; // 4 decimals (bips)
    int public liqBuffM;
    int public liqBuffT;

    // leverage config
    uint24 public maxLeverageOpen;
    uint24 public maxLeverageOngoing;
    uint24 public minGuaranteedLeverage;
    uint public s;
    uint public b;
    uint public f0;
    // NOTE: Example 180 days
    uint public maxTimeGuarantee;
    // NOTE: In case the above is measured in days then it is 365 days
    uint public FRTemporalBasis;

    function initialize(address sender) public initializer {
        _transferOwnership(sender);

        bufferTraderBps = 100; // 1%
        bufferMakerBps = 100; // 1%
        bufferTrader = 10 * 1e18;
        bufferMaker = 10 * 1e18;
        openInterestCap = 80 * 1e2; // 80%
        fmfrPerYear = 10 * 1e2; // 10%
        frPerYearModulo = 1; // 0.01%
        minPremiumFee = 1 * 1e18; // 1 USDC
        premiumFeeBps = 20 * 1e2; // 20%
        minFRPerYear = 1 * 1e2; // 1%
        orderMinAmount = 0.1 * 1e18; // 0.1 units
        traderFeeBps = 5; // 0.05%
        makerFRFeeBps = 300; // 3%;

        // leverage config
        maxLeverageOpen = 10 * 1e4; // 1000% (10x)
        maxLeverageOngoing = 16 * 1e4; // 1600% (16x)
        minGuaranteedLeverage = 1 * 1e4; // 100% (1x)
        s = 1;
        b = 1;
        f0 = 0;
        maxTimeGuarantee = 180 days;
        FRTemporalBasis = 365 days;
    }

    function getLeverage() external view override returns (Leverage memory) {
        return
            Leverage(
                maxLeverageOpen,
                maxLeverageOngoing,
                minGuaranteedLeverage,
                s,
                b,
                f0,
                maxTimeGuarantee,
                FRTemporalBasis
            );
    }

    function getBips() external view override returns (Bips memory) {
        return
            Bips(
                bufferTraderBps,
                bufferMakerBps,
                openInterestCap,
                fmfrPerYear,
                frPerYearModulo,
                premiumFeeBps,
                minFRPerYear,
                traderFeeBps,
                makerFRFeeBps
            );
    }

    function getAmounts() external view override returns (Amounts memory) {
        return
            Amounts(bufferTrader, bufferMaker, minPremiumFee, orderMinAmount);
    }

    function setLeverage(Leverage calldata l) external override onlyOwner {
        maxLeverageOpen = l.maxLeverageOpen;
        maxLeverageOngoing = l.maxLeverageOngoing;
        minGuaranteedLeverage = l.minGuaranteedLeverage;
        s = l.s;
        b = l.b;
        f0 = l.f0;
        maxTimeGuarantee = l.maxTimeGuarantee;
        FRTemporalBasis = l.FRTemporalBasis;
    }

    function setBips(Bips calldata bp) external override onlyOwner {
        bufferTraderBps = bp.bufferTraderBps;
        bufferMakerBps = bp.bufferMakerBps;
        openInterestCap = bp.openInterestCap;
        fmfrPerYear = bp.fmfrPerYear;
        frPerYearModulo = bp.frPerYearModulo;
        premiumFeeBps = bp.premiumFeeBps;
        minFRPerYear = bp.minFRPerYear;
        traderFeeBps = bp.traderFeeBps;
    }

    function setAmounts(Amounts calldata a) external override onlyOwner {
        bufferTrader = a.bufferTrader;
        bufferMaker = a.bufferMaker;
        minPremiumFee = a.minPremiumFee;
        orderMinAmount = a.orderMinAmount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import '@dex/lib/NFTDescriptor.sol';
import '@dex/lib/PnLMath.sol';
import '@dex/lib/FeesMath.sol';
import '@dex/lib/FinMath.sol';
import '@dex/lib/Structs.sol';
import '@dex/lib/JoinLib.sol';
import '@dex/oracles/interfaces/IOracle.sol';
import '@dex/perp/interfaces/IEngine.sol';
import '@dex/perp/interfaces/IVault.sol';
import '@dex/perp/interfaces/IPoolRatio.sol';
import '@dex/perp/interfaces/IConfig.sol';

// import "@openzeppelin-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";
error OrderMinAmount();
error MinFundingRate();
error FundingRateModulo();
error MissingCollateral();
error ZeroCollateral();
error OverLeveraged(uint matchId);
error SamePos();
error NeutralPos();
error UnexistingMatch();
error TraderIsMaker();
error NonTrader();
error CancelActiveMatch();
error OnlyMaker();
error OnlyTraderMakerOperation();
error InsufficientCollateral();
error MakerNorTrader();
error ZeroAmount();
error CollateralTooLow();
error MaxLeverageOpen();
error UnecessarySplit();
error PendingClose();
error ActivatedMatch();
error MatchExpirationUnreached();

uint constant EXPIRATION_ORDER_PERIOD = 7200;

contract Engine is IEngineEvents {
    using PnLMath for Match;
    using LeverageMath for Match;
    using FinMath for int;
    using FinMath for uint;
    using FeesMath for Order;
    using NFTDescriptor for uint;
    using JoinLib for Match;

    IOracle public oracle;

    // skip 0
    uint128 private nextMatchId;

    // pending orders
    uint128 private nextClose;
    uint128 private nextOpen;

    uint public openInterest;

    // trader order queues
    Order[] public opens;
    CloseOrder[] public closes;

    IConfig public config;

    IVault public vault;

    IPoolRatio public pool;

    uint8 private tokenDecimals;

    mapping(uint => Match) public matches;

    //@notice Instead of using constructor, this contract is cloned using the Clone lib
    //@dev https://docs.openzeppelin.com/contracts/4.x/api/proxy#Clones
    function initialize(
        address oracle_,
        IVault vault_,
        IPoolRatio pool_,
        IConfig config_
    ) external {
        oracle = IOracle(oracle_);
        vault = vault_;
        pool = pool_;
        config = config_;

        tokenDecimals = vault.token().decimals();

        // skip 0
        nextMatchId = 1;
    }

    function pnl(
        uint matchId,
        uint tokenId,
        uint timestamp,
        uint exitPrice
    )
        external
        view
        returns (
            int pnLM,
            int pnlT,
            uint FRfee
        )
    {
        return
            matches[matchId].pnl(
                tokenId,
                timestamp,
                exitPrice,
                config.makerFRFeeBps(),
                tokenDecimals
            );
    }

    function accruedFR(uint matchId) external view returns (uint) {
        Match memory m = matches[matchId];
        return m.accruedFR(oracle.getPrice(), tokenDecimals);
    }

    // @dev Temporary 'deep stack' fix, to be used on tests, used 0.25 kb margin, once
    // using the automatic generated viewer has to many args, after adding the `close`.
    function getMatch(uint matchId) external view returns (Match memory) {
        return matches[matchId];
    }

    function getMaxLeverageOpen(uint fr) external view returns (uint) {
        return
            LeverageMath.getMaxLeverage(
                config,
                fr,
                block.timestamp - oracle.getPrice().timestamp
            );
    }

    // @notice Here there is no check on the order min amount since it can be
    // created as a result of a split
    function open(
        uint amount,
        int24 premiumBps,
        // NOTE: We do not allow negative FRs in v1
        uint24 frPerYear,
        int8 pos,
        uint collateral_,
        address recipient
    ) external returns (uint matchId, uint tokenId) {
        if (amount < config.getAmounts().orderMinAmount)
            revert OrderMinAmount();
        if (frPerYear < config.minFRPerYear()) revert MinFundingRate();
        if ((frPerYear % config.frPerYearModulo()) != 0)
            revert FundingRateModulo();
        if (vault.collateral(recipient) < collateral_)
            revert MissingCollateral();
        if (collateral_ == 0) revert ZeroCollateral();

        tokenId = vault.mint(recipient);
        Match memory m;
        m.maker = tokenId; // the token owner is the maker of the match
        m.amount = amount;
        m.premiumBps = premiumBps;
        m.frPerYear = frPerYear;
        m.pos = pos;
        m.collateralM = collateral_;
        m.minPremiumFeeDiscountPerc = 100; // Initialize at 100%

        matches[(matchId = nextMatchId++)] = m; // use match-id as idx
        if (
            matches[matchId].isOverLeveraged(
                oracle.getPrice(),
                config,
                true,
                tokenDecimals
            )
        ) revert OverLeveraged(matchId);
        // m.auto_resubmit = auto_resubmit;
        emit NewMakerOrder(recipient, matchId, tokenId);
    }

    // --- Trader ---

    // @dev pick maker match
    function pick(
        uint matchId,
        uint amount,
        uint collateral_,
        int8 pos
    ) external {
        if (
            matches[matchId].pos != POS_NEUTRAL &&
            pos != -1 * matches[matchId].pos
        ) revert SamePos();
        if (pos == POS_NEUTRAL) revert NeutralPos();
        if (matches[matchId].maker == 0) revert UnexistingMatch();
        if (matches[matchId].trader != 0) revert ActivatedMatch();
        if (vault.ownerOf(matches[matchId].maker) == msg.sender)
            revert TraderIsMaker();
        if (amount <= config.getAmounts().orderMinAmount)
            revert OrderMinAmount();

        Order memory o;
        o.owner = msg.sender;
        o.matchId = matchId;
        o.amount = amount;
        o.collateral = collateral_;
        o.pos = pos;
        o.timestamp = block.timestamp;
        o.maxTimestamp = o.timestamp + EXPIRATION_ORDER_PERIOD;
        opens.push(o);

        emit NewTraderOrder(msg.sender, matchId, opens.length - 1);
    }

    // @notice Cancel trader order
    // @param id Order ID
    function cancelOrder(uint orderId) external {
        Order storage o = opens[orderId];
        if (o.owner != msg.sender) revert NonTrader();
        o.canceled = true;
        emit OrderCanceled(msg.sender, orderId, o.matchId);
    }

    function cancelMatch(uint matchId) external {
        if (matches[matchId].start != 0) revert CancelActiveMatch();
        if (vault.ownerOf(matches[matchId].maker) != msg.sender)
            revert OnlyMaker();
        emit MatchCanceled(msg.sender, matchId);
        delete matches[matchId];
    }

    // @notice submit close trader order
    // @matchId match id that comes from UI
    function close(uint matchId) external {
        bool isMaker = (msg.sender == vault.ownerOf(matches[matchId].maker))
            ? true
            : false;
        bool isTrader = (msg.sender == vault.ownerOf(matches[matchId].trader))
            ? true
            : false;
        if (!isTrader && !isMaker) revert OnlyTraderMakerOperation();
        if (matches[matchId].close) revert PendingClose();
        if (
            isMaker &&
            block.timestamp < matches[matchId].start + config.maxTimeGuarantee()
        ) revert MatchExpirationUnreached();
        emit MatchClose(msg.sender, matchId);
        matches[matchId].close = true; // flag true for the close request
        closes.push(CloseOrder(matchId, block.timestamp));
    }

    // @dev removing memory struct load here gave us 0.34 kb
    function increaseCollateral(uint matchId, uint amount) external {
        if (amount == 0) revert ZeroAmount();
        if (vault.collateral(msg.sender) < amount)
            revert InsufficientCollateral();
        // increase maker collateral
        if (msg.sender == vault.ownerOf(matches[matchId].maker)) {
            matches[matchId].collateralM += amount;
            emit CollateralIncreased(msg.sender, matchId, amount);
        } else if (msg.sender == vault.ownerOf(matches[matchId].trader)) {
            matches[matchId].collateralT += amount;
            emit CollateralIncreased(msg.sender, matchId, amount);
        } else {
            revert MakerNorTrader();
        }
        vault.lock(amount, msg.sender);
    }

    // @dev cleaning storage load on Match gave us 0.163 kb and reduced
    // average gas use from 15k to 13.5k
    function decreaseCollateral(uint matchId, uint amount) external {
        if (amount == 0) revert ZeroAmount();
        // Match storage m = matches[matchId];
        PriceData memory priceData = oracle.getPrice();
        // increase maker collateral
        if (msg.sender == vault.ownerOf(matches[matchId].maker)) {
            if (matches[matchId].collateralM < amount)
                revert CollateralTooLow();
            matches[matchId].collateralM -= amount;
            if (
                matches[matchId].isOverLeveraged(
                    priceData,
                    config,
                    true,
                    tokenDecimals
                )
            ) revert MaxLeverageOpen();

            emit CollateralDecreased(msg.sender, matchId, amount);
        } else if (msg.sender == vault.ownerOf(matches[matchId].trader)) {
            if (matches[matchId].collateralT < amount)
                revert CollateralTooLow();
            matches[matchId].collateralT -= amount;
            if (
                matches[matchId].isOverLeveraged(
                    priceData,
                    config,
                    true,
                    tokenDecimals
                )
            ) revert MaxLeverageOpen();

            emit CollateralDecreased(msg.sender, matchId, amount);
        } else {
            revert MakerNorTrader();
        }
        vault.unlock(amount, msg.sender);
    }

    // --- Keeper ---

    // associate trader order to maker match
    function join(Order storage order, PriceData memory priceData) internal {
        Match memory m = matches[order.matchId].normalize(order.amount); // load by the selected maker tokenid
        if (m.maker == 0) {
            emit MatchInexistant(order.matchId, nextOpen);
            return;
        }
        address maker = vault.ownerOf(m.maker);
        uint balance = vault.collateral(order.owner);

        // --- Trader Fees ---
        uint traderFees = order.traderFees(priceData, config);

        (int premiumT, uint premiumFee) = order.premium(
            priceData,
            m.premiumBps,
            config,
            m.minPremiumFeeDiscountPerc
        );

        //
        int _deltaM = int(premiumFee) - premiumT;
        int _deltaT = premiumT.add(traderFees); //  int256(traderFees) + premiumT;

        if (
            !m.beforeChecks(
                order,
                nextOpen,
                order.matchId,
                maker,
                balance,
                _deltaM,
                _deltaT
            )
        ) return;

        // NOTE: We can use negative premium to cover the traderFees at least partially, excess will go to Trader Vault Account
        m.collateralT = order.collateral - _deltaT.pos();

        // NOTE: We can use positive premium to cover the makerFees, excess will go to Maker Vault Account
        m.collateralM = m.collateralM - _deltaM.pos();

        if (
            !m.afterChecks(
                JoinLib.AfterCheck(
                    priceData,
                    config,
                    vault,
                    maker,
                    order.owner,
                    order.matchId,
                    nextOpen,
                    order.maxTimestamp,
                    tokenDecimals
                )
            )
        ) return;

        // No more checks so here we can modify the state safely

        uint tokenId = vault.mint(order.owner);
        m.trader = tokenId; // setup match with the trader token
        m.start = uint128(priceData.timestamp); // set oracle time we matched
        m.entryPrice = priceData.price; // set oracle price on match
        m.fmfrPerYear = config.fmfrPerYear();

        if (order.amount < matches[order.matchId].amount) {
            // create another match with the remaining amount from the original match
            (order.matchId, m.maker) = _split(matches[order.matchId], order);
        }
        // NOTE: Makers can choose to be long or short or neutral so that it is the trader deciding
        m.pos = (m.pos == POS_NEUTRAL) ? (-1 * order.pos) : m.pos;

        // update the balance available to trader/maker
        if (_deltaT < 0) {
            // NOTE: Crediting excess negative premium to the Trader Vault Account
            vault.unlock(uint(-_deltaT), order.owner);
        }

        if (_deltaM < 0) {
            // NOTE: Crediting excess positive premium to the Maker Vault Account
            vault.unlock(uint(-_deltaM), maker);
        }
        matches[order.matchId] = m;
        vault.lock(m.collateralT, order.owner);
        vault.lock(m.collateralM, maker);

        openInterest += order.amount;

        emit ActiveMatch(
            order.matchId,
            maker,
            order.owner,
            nextOpen,
            m.maker,
            m.trader
        );
    }

    // desassociate trader from match based on trader tokenid
    function unjoin(uint matchId, PriceData memory priceData) internal {
        Match storage m = matches[matchId]; // load Match by trader matchid
        // // early bailout in case the match is already closed
        if (m.maker == 0) return;
        (int pnlM, int pnlT, ) = m.pnl(
            m.maker,
            priceData.timestamp,
            priceData.price,
            config.makerFRFeeBps(),
            tokenDecimals
        );

        vault.settle(m.maker, m.collateralM, pnlM);
        vault.settle(m.trader, m.collateralT, pnlT);

        openInterest -= m.amount;
        emit CloseMatch(
            matchId,
            m.maker,
            m.trader,
            pnlM,
            pnlT,
            priceData.price
        );
        delete matches[matchId].maker;
    }

    function _split(Match storage m, Order storage o)
        internal
        returns (uint matchId, uint tokenId)
    {
        uint newAmount = m.amount - o.amount;
        if (newAmount <= config.getAmounts().orderMinAmount) {
            return (0, 0);
        }
        address maker = vault.ownerOf(m.maker);
        tokenId = vault.mint(maker); // mint maker token
        Match memory newMatch = m;
        newMatch.amount = newAmount;
        newMatch.collateralM =
            m.collateralM -
            ((m.collateralM * o.amount) / m.amount);
        newMatch.minPremiumFeeDiscountPerc =
            m.minPremiumFeeDiscountPerc -
            uint8((uint(m.minPremiumFeeDiscountPerc) * o.amount) / m.amount);
        // create a new potential match in the order book;
        // matches[(matchId = nextMatchId++)] = newMatch;
        matches[o.matchId] = newMatch;
        matchId = nextMatchId++;
        emit MatchSplitted(matchId, o.matchId, tokenId);
    }

    // @dev We need this function here to automate liquidations
    function isLiquidatable(uint matchId, uint tokenId)
        external
        view
        returns (bool)
    {
        Match memory m = matches[matchId];
        PriceData memory p = oracle.getPrice();
        (, , bool isLiq) = m.isLiquidatable(
            tokenId,
            p.price,
            config,
            tokenDecimals
        );
        return isLiq;
    }

    function liquidate(
        uint[] calldata matchIds,
        uint[] calldata tokenIds,
        address recipient
    ) external {
        PriceData memory p = oracle.getPrice(); // TODO: do we need to get price in the loop?
        for (uint i = 0; i < matchIds.length; i++) {
            uint matchId = matchIds[i];
            uint tokenId = tokenIds[i];

            Match memory m = matches[matchId];
            (int pnlM, int pnlT, bool isLiq) = m.isLiquidatable(
                tokenId,
                p.price,
                config,
                tokenDecimals
            );
            if (!isLiq) continue;
            if (tokenId == m.maker) {
                // TODO: Implement Maker Liquidation --> it means
                // 1) Decapitating current owner
                // 2) Recapitilizing through LP Pool
                // 3) Minting ownership to pool --> Take care about auction start
            } else {
                vault.adjust(m.collateralT, pnlT, recipient);
                // settle profitable pnl for the maker on the vault, if the trader
                // was liquidated, maker is profitable on the other side of the trade
                vault.unlock(
                    uint(int(m.collateralM) + pnlM),
                    vault.ownerOf(m.maker)
                );

                openInterest -= m.amount;

                emit MatchLiquidated(
                    matchId,
                    pnlM,
                    pnlT,
                    oracle.getPrice().price
                );
                delete matches[matchId].maker;
            }
        }
    }

    ///@notice returns the current market usage vs the insurance pool
    function poolUsage(uint price, uint orderAmount)
        public
        view
        returns (uint)
    {
        return
            openInterest.add(orderAmount).wmul(price).bps().div(
                pool.capLimit()
            );
    }

    function validateOICap(uint price, uint orderAmount)
        internal
        view
        returns (bool)
    {
        if (pool.capLimit() == 0) return false;
        return poolUsage(price, orderAmount) < config.openInterestCap();
    }

    //@dev return true if queue is ready to run `runOpens`
    function openStatus()
        public
        view
        returns (bool canExec, bytes memory execPayload)
    {
        PriceData memory p = oracle.getPrice();
        canExec =
            opens.length > nextOpen &&
            p.timestamp >= opens[nextOpen].timestamp &&
            validateOICap(p.price, 0);
        execPayload = abi.encodeCall(this.runOpens, 0);
    }

    function runOpens(uint n) external {
        PriceData memory p = oracle.getPrice();
        uint end = (n == 0)
            ? opens.length
            : Math.min(nextOpen + n, opens.length);
        // run the last queue and update the price
        while (nextOpen < end) {
            Order storage order = opens[nextOpen];
            // if order expired we simply instructs the counter to jump it forever
            if (order.canceled || order.maxTimestamp < block.timestamp) {
                delete opens[nextOpen];
                nextOpen++;
                continue;
            }
            // check if price is recent enough, break the loop if not as all further order will be too recent
            if (p.timestamp < order.timestamp) break;
            if (!validateOICap(p.price, order.amount)) break;
            join(order, p);
            delete opens[nextOpen];
            nextOpen++;
        }
    }

    //@dev return true if queue is ready to run `runOpens`
    function closeStatus()
        public
        view
        returns (bool canExec, bytes memory execPayload)
    {
        canExec =
            closes.length > nextClose &&
            oracle.getPrice().timestamp >= closes[nextClose].timestamp;
        execPayload = abi.encodeCall(this.runCloses, 0);
    }

    function runCloses(uint n) external {
        n = (n == 0) ? closes.length : Math.min(nextClose + n, closes.length);
        PriceData memory priceData = oracle.getPrice();
        while (nextClose < n) {
            CloseOrder memory order = closes[nextClose];
            // check if price is recent enough, break the loop if not as all further order will be too recent as well
            if (priceData.timestamp < order.timestamp) break;
            unjoin(order.matchId, priceData);
            delete closes[nextClose];
            nextClose++;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/proxy/Clones.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@dex/perp/Engine.sol';
import '@dex/perp/Config.sol';
import '@dex/perp/Vault.sol';
import '@dex/perp/interfaces/IPool.sol';

import '@dex/lib/Structs.sol';
import '@dex/oracles/GelatoOracleFactory.sol';

contract EngineFactory is Ownable {
    using Clones for address;

    address engineImplementation;
    address configImplementation;

    GelatoOracleFactory public oracleFactory;
    Vault public vault;

    event EngineDeployed(
        address indexed engine,
        address indexed vault,
        address indexed oracle
    );

    struct OracleArguments {
        uint deviation;
        uint8 decimals;
        uint40 heartBeat;
        string[4] endpoints;
    }

    constructor(address dataProvider, address collateralToken) {
        oracleFactory = new GelatoOracleFactory(dataProvider);
        vault = new Vault(
            collateralToken,
            msg.sender,
            IVault.LiquidationConfig({
                fixLiquidationFee: 10 **
                    IERC20Metadata(collateralToken).decimals(),
                liquidationFeeBps: 1, // 0.01%
                splitRatio: 5000 // 50%
            })
            // IPool.Config({
            //     wfeeBps: 100,
            //     door: 240,
            //     hold: 240,
            //     cap: 1_000_000 *
            //         10 ** IERC20Metadata(collateralToken).decimals()
            // })
        );
        vault.transferOwnership(msg.sender);

        engineImplementation = address(new Engine());
        configImplementation = address(new Config());
    }

    function liquidates(
        uint[][] calldata matchIds,
        uint[][] calldata tokenIds,
        address[] calldata engines,
        address recipient
    ) external {
        for (uint i = 0; i < engines.length; i++) {
            IEngine(engines[i]).liquidate(matchIds[i], tokenIds[i], recipient);
        }
    }

    function deployEngine(OracleArguments calldata oracleArguments)
        external
        onlyOwner
        returns (address newEngine)
    {
        newEngine = engineImplementation.clone();
        address newConfig = configImplementation.clone();
        IConfig(newConfig).initialize(msg.sender);

        address newOracle = oracleFactory.deployOracle(
            oracleArguments.deviation,
            oracleArguments.decimals,
            oracleArguments.heartBeat,
            oracleArguments.endpoints
        );

        IEngine(newEngine).initialize(
            newOracle,
            vault,
            IPoolRatio(vault.pool()),
            IConfig(newConfig)
        );

        emit EngineDeployed(newEngine, address(vault), newOracle);
    }
}

pragma solidity ^0.8.17;

import '@solmate/mixins/ERC4626.sol';
import '@solmate/tokens/ERC20.sol';
import '@solmate/auth/Owned.sol';
import '@solmate/utils/SafeTransferLib.sol';
import '@solmate/utils/FixedPointMathLib.sol';

import '@dex/perp/interfaces/IPoolRatio.sol';

contract PoolRatio is ERC4626, Owned, IPoolRatio {
    using FixedPointMathLib for uint;
    using SafeTransferLib for ERC20;

    Config public config;

    uint private totalAssetEscrowed;
    uint public markets; // Markets count, used to calculate the cap limit per market

    mapping(address => Withdrawal) public withdrawals;

    enum Status {
        NONE,
        PREMATURE,
        ACTIVE,
        EXPIRED
    }

    constructor(
        address asset_,
        address owner_,
        Config memory config_
    ) Owned(owner_) ERC4626(ERC20(asset_), 'Sartorian Insurance Pool', 'SIP') {
        // give permission to the vault to spend the asset
        ERC20(asset_).approve(msg.sender, type(uint).max);
        config = config_;
    }

    function totalAssets() public view override returns (uint) {
        return asset.balanceOf(address(this)) - totalAssetEscrowed;
    }

    // @dev Unique function used to control the phase time internally
    // and also exposed externally
    function withdrawStatus(uint timestamp) public view returns (Status) {
        if (timestamp == 0) return Status.NONE;
        else if ((block.timestamp - timestamp) > (config.door + config.hold))
            return Status.EXPIRED;
        else if ((block.timestamp - timestamp) > config.door)
            return Status.ACTIVE;
        else return Status.PREMATURE;
    }

    function lock(uint assets) external {
        require(
            convertToAssets(balanceOf[msg.sender]) >= assets,
            'pool/amount-too-large'
        );
        Withdrawal storage w = withdrawals[msg.sender];
        if (withdrawStatus(w.timestamp) == Status.NONE) {
            w.sharesAtLock = convertToShares(assets);
            w.amount = assets;
            w.timestamp = block.timestamp;
            totalAssetEscrowed += assets;
        } else if (withdrawStatus(w.timestamp) == Status.EXPIRED) {
            // the shares passed in as argument is most likely invalid here
            totalAssetEscrowed = totalAssetEscrowed + w.amount;
            w.sharesAtLock = convertToShares(assets);
            w.amount = assets;
            w.timestamp = block.timestamp;
            totalAssetEscrowed = totalAssetEscrowed - assets;
        } else if (withdrawStatus(w.timestamp) == Status.PREMATURE) {
            totalAssetEscrowed = totalAssetEscrowed + w.amount;
            w.sharesAtLock = convertToShares(assets);
            w.amount = assets;
            w.timestamp = block.timestamp;
            totalAssetEscrowed = totalAssetEscrowed - assets;
        } else if (withdrawStatus(w.timestamp) == Status.ACTIVE) {
            // the shares passed in as argument is most likely invalid here
            revert('pool/withdraw-in-progress');
        }
    }

    function cancelLock() external {
        totalAssetEscrowed -= withdrawals[msg.sender].amount;
        delete withdrawals[msg.sender];
    }

    function beforeWithdraw(uint assets, uint shares) internal override {
        Withdrawal storage w = withdrawals[msg.sender];
        require(
            withdrawStatus(w.timestamp) == Status.ACTIVE,
            'pool/locking-period'
        );
        require(
            assets <= withdrawals[msg.sender].amount,
            'pool/withdrawal-too-large'
        );
        w.amount -= assets;
        totalAssetEscrowed -= assets;
    }

    function previewWithdraw(uint assets) public view override returns (uint) {
        uint supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        Withdrawal storage w = withdrawals[msg.sender];
        if (w.amount != 0 && w.amount >= assets) {
            return w.sharesAtLock.mulDivUp(assets, w.amount);
        }
        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint shares) public view override returns (uint) {
        Withdrawal storage w = withdrawals[msg.sender];
        if (w.sharesAtLock != 0 && w.sharesAtLock >= shares) {
            return w.amount.mulDivUp(shares, w.sharesAtLock);
        }
        return convertToAssets(shares);
    }

    function capLimit() external view returns (uint) {
        return totalAssets() / markets;
    }

    function addMarket() external onlyOwner {
        markets++;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@dex/lib/FinMath.sol';
import '@dex/perp/interfaces/IVault.sol';
import '@dex/perp/PoolRatio.sol';

contract Vault is ERC721, IVault, Ownable {
    using SafeERC20 for IERC20;
    using FinMath for uint;
    using FinMath for int;
    using FinMath for int24;
    using SafeCast for uint;
    using SafeCast for int;

    uint private _nextTokenId = 1;

    IVault.LiquidationConfig public liquidationConfig;

    IERC20 public collateralToken;
    address public pool;

    // NOTE: Accounts of addresses
    mapping(address => uint) public collateral;

    // list of engines approved to manipulate user balance
    mapping(address => bool) public approved;

    modifier onlyApproved() {
        require(approved[msg.sender], 'not-approved');
        _;
    }

    constructor(
        address collateralToken_,
        address owner,
        IVault.LiquidationConfig memory liquidationConfig_
    ) ERC721('TEST', 'TST') {
        liquidationConfig = liquidationConfig_;
        pool = address(
            new PoolRatio(
                collateralToken_,
                owner,
                IPoolRatio.Config({
                    wfeeBps: 100,
                    door: 240,
                    hold: 240,
                    cap: 1_000_000 *
                        10**IERC20Metadata(collateralToken_).decimals()
                })
            )
        );
        collateralToken = IERC20(collateralToken_);
    }

    function setLiquidationConfig(IVault.LiquidationConfig memory config_)
        external
        onlyOwner
    {
        liquidationConfig = config_;
    }

    function mint(address to) external onlyApproved returns (uint tokenId) {
        _safeMint(to, (tokenId = _nextTokenId++));
    }

    function token() public view override returns (IERC20Metadata) {
        return IERC20Metadata(address(collateralToken));
    }

    function approve(address engine) external onlyOwner {
        approved[engine] = true;
    }

    // @notice Settle PnL
    // @dev We add the PnL and collateral, the position, to the balance
    // and if it's negative, we track it on the debt accounting.
    function settle(
        uint tokenId,
        uint collateral_,
        int pnl
    ) external onlyApproved {
        address user = ownerOf(tokenId);
        int balance = pnl.add(collateral_);
        if (balance >= 0) {
            collateral[user] += balance.u256();
        } else {
            collateralToken.safeTransferFrom(
                address(pool),
                address(this),
                balance.inv()
            );
        }
    }

    // @notice Settle the trader fees and collateral in case of liquidation.
    // @dev Add 0.01% [1 BSP] of the trader collateral over the base fee [1 USDC],
    // calculate the total collateral adding the pnl, and in the case trader has enough
    // collateral to pay the fee, we debit it, and transfer the remaining
    // collateral [col] after fees to the recipient. The total trader fee debt to
    // be tracked on the makerDebt
    // TODO: add access limitation
    function adjust(
        uint collateralT_,
        int pnlT,
        address recipient
    ) external override onlyApproved {
        uint fee = liquidationConfig.fixLiquidationFee +
            collateralT_.bps(liquidationConfig.liquidationFeeBps); // 1 dollar
        int remaining = pnlT + int(collateralT_);
        int protocolRemaining;
        if (remaining > 0) {
            // we guarantee a fixed fee to the liquidator, + half the remaining
            uint liquidatorFees = fee + (uint(remaining) / 2);
            IERC20(collateralToken).transferFrom(
                address(this),
                recipient,
                liquidatorFees
            );
            protocolRemaining = liquidationConfig.splitRatio.bps(remaining).sub(
                    fee
                );
        } else {
            IERC20(collateralToken).transferFrom(address(this), recipient, fee);
            protocolRemaining = remaining - int(fee);
        }
        if (protocolRemaining > 0) {
            collateralToken.safeTransfer(pool, protocolRemaining.u256());
        }
        if (protocolRemaining < 0) {
            collateralToken.safeTransferFrom(
                pool,
                address(this),
                protocolRemaining.inv()
            );
        }
    }

    /// @dev this expressly do not check if collateral > amount, it will revert anyway
    function lock(uint amount, address account) external onlyApproved {
        collateral[account] -= amount;
    }

    function unlock(uint amount, address account) external onlyApproved {
        collateral[account] += amount;
    }

    function deposit(uint amount, address recipient) external override {
        require(amount > 0, 'account/zero-deposit');
        IERC20(collateralToken).transferFrom(msg.sender, address(this), amount);
        collateral[recipient] += amount;
    }

    // withdraw free collateral
    function withdraw(uint amount, address recipient) external override {
        require(amount > 0, 'vault/zero-withdrawl');
        require(collateral[msg.sender] >= amount, 'vault/not-enough-balance');

        collateral[msg.sender] -= amount;
        IERC20(collateralToken).transferFrom(address(this), recipient, amount);
    }
}

pragma solidity ^0.8.17;

struct Bips {
    uint24 bufferTraderBps;
    uint24 bufferMakerBps;
    uint24 openInterestCap; // 4 decimals (bips)
    uint24 fmfrPerYear; // 4 decimals (bips)
    uint24 frPerYearModulo; // 4 decimals (bips)
    uint24 premiumFeeBps; // % of the premium that protocol collects
    uint24 minFRPerYear; // 4 decimals (bips)
    uint24 traderFeeBps; // 4 decimals (bips)
    uint24 makerFRFeeBps; // 4 decimals (bips)
}

struct Amounts {
    uint bufferTrader;
    uint bufferMaker;
    uint128 minPremiumFee;
    uint128 orderMinAmount;
}

// @dev Leverage is defined by the formula:
// (units * openingPrice) / (collateral + accruedFR)
// maxLeverage is a market-specific governance parameter that
// determines maximum leverage for traders and makers.
// Like in PerpV2, we have 2 max leverages: one for when the position is opened and
// the other for the position ongoing. Leverage [lev] is defined by:
// if (FR < FMFR) {
//     lev = s.mul(b).mul(365).div(T-t).div(FMFR-FR+f0);
//     lev = lev < maxLev ? lev : maxLev;
// } else { lev = maxLeverage; }
// s  = scaling factor (governance parameter)
// b  = buffer (fraction, so ultimately affects denominator)
// T  = expiry (i.e. 180 days)
// t  = elapsed time since contract created
// FR = funding rate set by maker creating offer
// f0 = linear shift (governance parameter)
// FMFR = fair market funding rate (market-specific governance risk parameter)
// Atm we do not support negative FR

struct Leverage {
    uint24 maxLeverageOpen;
    uint24 maxLeverageOngoing;
    uint24 minGuaranteedLeverage;
    uint s;
    uint b;
    uint f0;
    uint maxTimeGuarantee; // Example 180 days
    uint FRTemporalBasis; // In case the above is measured in days then it is 365 days
}

interface IConfig {
    function maxTimeGuarantee() external view returns (uint);

    function fmfrPerYear() external view returns (uint24);

    function premiumFeeBps() external view returns (uint24);

    function openInterestCap() external view returns (uint24);

    function frPerYearModulo() external view returns (uint24);

    function minFRPerYear() external view returns (uint24);

    function traderFeeBps() external view returns (uint24);

    function bufferTraderBps() external view returns (uint24);

    function bufferMakerBps() external view returns (uint24);

    function makerFRFeeBps() external view returns (uint24);

    function bufferTrader() external view returns (uint);

    function bufferMaker() external view returns (uint);

    function getLeverage() external view returns (Leverage memory);

    function getBips() external view returns (Bips memory);

    function getAmounts() external view returns (Amounts memory);

    function setLeverage(Leverage calldata leverage) external;

    function setBips(Bips calldata) external;

    function setAmounts(Amounts calldata) external;

    function initialize(address owner) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@dex/lib/LeverageMath.sol';
import '@dex/perp/interfaces/IVault.sol';
import '@dex/perp/interfaces/IPoolRatio.sol';
import '@dex/perp/interfaces/IConfig.sol';

interface IEngineEvents {
    // TODO: move out [leave only on test]
    event MatchInexistant(uint indexed matchId, uint indexed orderId);
    event MakerIsTrader(
        uint indexed matchId,
        address indexed maker,
        uint orderId
    );
    event LowMakerCollateralForFees(
        uint indexed matchId,
        address indexed maker,
        uint orderId,
        uint allocatedCollateral,
        uint makerFees
    );

    event LowTraderCollateral(
        uint indexed matchId,
        address indexed trader,
        uint orderId,
        uint traderCollateral,
        uint collateralNeeded
    );
    event LowTraderCollateralForFees(
        uint indexed matchId,
        address indexed trader,
        uint orderId,
        uint allocatedCollateral,
        uint traderFees
    );
    event NewMakerOrder(
        address indexed recipient,
        uint indexed matchId,
        uint tokenId
    );

    event NewTraderOrder(
        address indexed recipient,
        uint indexed matchId,
        uint orderId
    );

    event ActiveMatch(
        uint indexed matchId,
        address indexed maker,
        address indexed trader,
        uint orderId,
        uint makerToken,
        uint traderToken
    );

    event CloseMatch(
        uint indexed matchId,
        uint indexed makerToken,
        uint indexed traderToken,
        int PnLM,
        int PnLT,
        uint price
    );

    event MatchLiquidated(uint indexed matchId, int pnlM, int pnlT, uint price);

    event LowMakerCollateral(
        uint indexed matchId,
        address indexed maker,
        uint orderId,
        uint makerCollateral,
        uint collateralNeeded
    );

    event OrderExpired(
        uint indexed matchId,
        address indexed trader,
        address indexed maker,
        uint orderId,
        uint orderTimestamp
    );

    event OrderCanceled(
        address indexed trader,
        uint indexed orderId,
        uint indexed matchId
    );

    event MatchCanceled(address indexed maker, uint indexed matchId);
    event MatchClose(address indexed maker, uint indexed matchId);

    event CollateralIncreased(
        address indexed sender,
        uint matchId,
        uint amount
    );

    event CollateralDecreased(
        address indexed sender,
        uint matchId,
        uint amount
    );

    event MaxOpeningLeverage(
        address indexed user,
        uint matchId,
        uint orderId,
        uint price
    );

    event MatchAlreadyActive(
        uint indexed matchId,
        uint indexed orderId,
        address indexed trader
    );

    event MatchSplitted(
        uint indexed newMatchId,
        uint indexed matchId,
        uint tokenId
    );
}

interface IEngine {
    function initialize(
        address oracle_,
        IVault vault_,
        IPoolRatio pool_,
        IConfig config_
    ) external;

    function getMatch(uint matchId) external view returns (Match memory);

    function liquidate(
        uint[] calldata matchIds,
        uint[] calldata tokenIds,
        address recipient
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IPool {
    struct Config {
        uint24 wfeeBps;
        uint door;
        uint hold;
        uint cap;
    }

    event Deposited(
        address indexed user,
        address indexed collateralToken,
        uint pay
    );

    event Withdrew(
        address indexed user,
        address indexed collateralToken,
        uint pay,
        uint per,
        uint fee
    );

    event Accumulate(int amount);

    function addMarket() external;

    function totalShares() external view returns (uint);

    function stake(uint amount, address recipient) external;

    function cancelStake() external;

    function unstake(uint amount, address recipient) external;

    function capLimit() external view returns (uint);
}

pragma solidity ^0.8.17;

interface IPoolRatio {
    // @dev accumulated rewards snapshot at lock are used
    // to avoid rewards aggregating while a withdraw is pending
    struct Withdrawal {
        uint timestamp; // timestamp the last time a user attempted a withdraw
        uint amount; // Promised withdraw amount on hold during the door period
        uint sharesAtLock; // accumulated shares when locking
    }

    struct Config {
        uint24 wfeeBps;
        uint door;
        uint hold;
        uint cap;
    }

    function capLimit() external view returns (uint);

    function addMarket() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import '@dex/perp/interfaces/IPool.sol';

interface IVault is IERC721 {
    struct LiquidationConfig {
        uint fixLiquidationFee;
        uint24 liquidationFeeBps;
        int24 splitRatio; // [bps] remaining collateral split between protocol and liquidator
    }

    function token() external view returns (IERC20Metadata);

    function collateral(address) external view returns (uint);

    function mint(address to) external returns (uint);

    function lock(uint amount, address account) external;

    function unlock(uint amount, address account) external;

    function deposit(uint amount, address recipient) external;

    function withdraw(uint amount, address recipient) external;

    function adjust(uint colT, int pnlT, address recipient) external;

    function settle(uint token, uint colT, int pnl) external;
}

interface IVaultAndPool is IVault, IPool {}