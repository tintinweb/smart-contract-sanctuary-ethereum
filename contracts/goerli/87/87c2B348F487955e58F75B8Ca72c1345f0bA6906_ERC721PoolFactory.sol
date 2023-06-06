// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { ClonesWithImmutableArgs } from '@clones/ClonesWithImmutableArgs.sol';
import { IERC165 }                 from '@openzeppelin/contracts/utils/introspection/IERC165.sol';

import { IERC721PoolFactory } from './interfaces/pool/erc721/IERC721PoolFactory.sol';
import { IPoolFactory }       from './interfaces/pool/IPoolFactory.sol';
import { PoolType }           from './interfaces/pool/IPool.sol';

import { ERC721Pool }   from './ERC721Pool.sol';
import { PoolDeployer } from './base/PoolDeployer.sol';

/**
 *  @title  ERC721 Pool Factory
 *  @notice Pool factory contract for creating `ERC721` pools. If a list with token ids is provided then a subset `ERC721` pool is created for the `NFT`.
 *  @notice Pool factory contract for creating `ERC20` pools.  If a list with token ids is provided then a subset `ERC721` pool is created for the `NFT`. Actors actions:
 *          - `Pool creators`: create pool by providing a fungible token for quote, a non fungible token for collateral and an interest rate between `1%-10%`.
 *  @dev    Reverts if pool is already created or if params to deploy new pool are invalid.
 */
contract ERC721PoolFactory is PoolDeployer, IERC721PoolFactory {

    using ClonesWithImmutableArgs for address;

    /// @dev `ERC721` clonable pool contract used to deploy the new pool.
    ERC721Pool public implementation;

    /// @dev Default `bytes32` hash used by `ERC721` `Non-NFTSubset` pool types
    bytes32 public constant ERC721_NON_SUBSET_HASH = keccak256("ERC721_NON_SUBSET_HASH");

    constructor(address ajna_) {
        if (ajna_ == address(0)) revert DeployWithZeroAddress();

        ajna = ajna_;

        implementation = new ERC721Pool();
    }

    /**
     *  @inheritdoc IERC721PoolFactory
     *  @dev  immutable args: pool type; ajna, collateral and quote address; quote scale; number of token ids in subset
     *  @dev    === Write state ===
     *  @dev    - `deployedPools` mapping
     *  @dev    - `deployedPoolsList` array
     *  @dev    === Reverts on ===
     *  @dev    - `0x` address provided as quote or collateral `DeployWithZeroAddress()`
     *  @dev    - quote lacks `decimals()` method `DecimalsNotCompliant()`
     *  @dev    - pool with provided quote / collateral pair already exists `PoolAlreadyExists()`
     *  @dev    - invalid interest rate provided `PoolInterestRateInvalid()`
     *  @dev    - not supported `NFT` provided `NFTNotSupported()`
     *  @dev    === Emit events ===
     *  @dev    - `PoolCreated`
     */
    function deployPool(
        address collateral_, address quote_, uint256[] memory tokenIds_, uint256 interestRate_
    ) external canDeploy(collateral_, quote_, interestRate_) returns (address pool_) {
        bytes32 subsetHash = getNFTSubsetHash(tokenIds_);

        address existingPool = deployedPools[subsetHash][collateral_][quote_];
        if (existingPool != address(0)) revert IPoolFactory.PoolAlreadyExists(existingPool);

        uint256 quoteTokenScale = _getTokenScale(quote_);

        try IERC165(collateral_).supportsInterface(0x80ac58cd) returns (bool supportsERC721Interface) {
            if (!supportsERC721Interface) revert NFTNotSupported();
        } catch {
            revert NFTNotSupported();
        }

        bytes memory data = abi.encodePacked(
            PoolType.ERC721,
            ajna,
            collateral_,
            quote_,
            quoteTokenScale,
            tokenIds_.length
        );

        ERC721Pool pool = ERC721Pool(address(implementation).clone(data));

        pool_ = address(pool);

        // Track the newly deployed pool
        deployedPools[subsetHash][collateral_][quote_] = pool_;
        deployedPoolsList.push(pool_);

        emit PoolCreated(pool_);

        pool.initialize(tokenIds_, interestRate_);
    }

    /**
     *  @dev                Create a new pool that accepts any token in a NFT collection
     *  @param collateral_  The NFT collateral token address
     *  @param quote_       The borrower quote token address
     *  @return pool_       The address of the new pool
     */
    function deployPool(address collateral_, address quote_, uint256 interestRate_) public returns (address pool_) {
        pool_ = this.deployPool(collateral_, quote_, new uint256[](0), interestRate_);
    }

    /*******************************/
    /*** Pool Creation Functions ***/
    /*******************************/

    /**
     *  @notice Get the hash of the subset of `NFT`s that will be used to create the pool.
     *  @dev    If no `tokenIds` are provided, the default `ERC721_NON_SUBSET_HASH` is returned.
     *  @param  tokenIds_ The array of token ids that will be used to create the pool.
     *  @return The hash of the subset of `NFT`s that will be used to create the pool.
     */
    function getNFTSubsetHash(uint256[] memory tokenIds_) public pure returns (bytes32) {
        if (tokenIds_.length == 0) return ERC721_NON_SUBSET_HASH;
        else {
            // check the array of token ids is sorted in ascending order
            // revert if not sorted
            _checkTokenIdSortOrder(tokenIds_);

            // hash the sorted array of tokenIds
            return keccak256(abi.encode(tokenIds_));
        }
    }

    /**
     *  @notice Check that the array of token ids is sorted in ascending order, else revert.
     *  @dev    The counters are modified in unchecked blocks due to being bounded by array length.
     *  @param  tokenIds_ The array of token ids to check for sorting.
     */
    function _checkTokenIdSortOrder(uint256[] memory tokenIds_) internal pure {
        for (uint256 i = 0; i < tokenIds_.length - 1; ) {
            if (tokenIds_[i] >= tokenIds_[i + 1]) revert TokenIdSubsetInvalid();
            unchecked {
                ++i;
            }
        }
    }

}

// SPDX-License-Identifier: BSD
pragma solidity ^0.8.4;

/// @title Clone
/// @author zefram.eth
/// @notice Provides helper functions for reading immutable args from calldata
contract Clone {
    /// @notice Reads an immutable arg with type address
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgAddress(uint256 argOffset)
        internal
        pure
        returns (address arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0x60, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint256
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint256(uint256 argOffset)
        internal
        pure
        returns (uint256 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @notice Reads a uint256 array stored in the immutable args.
    /// @param argOffset The offset of the arg in the packed data
    /// @param arrLen Number of elements in the array
    /// @return arr The array
    function _getArgUint256Array(uint256 argOffset, uint64 arrLen)
        internal
        pure
      returns (uint256[] memory arr)
    {
      uint256 offset = _getImmutableArgsOffset();
      uint256 el;
      arr = new uint256[](arrLen);
      for (uint64 i = 0; i < arrLen; i++) {
        assembly {
          // solhint-disable-next-line no-inline-assembly
          el := calldataload(add(add(offset, argOffset), mul(i, 32)))
        }
        arr[i] = el;
      }
      return arr;
    }

    /// @notice Reads an immutable arg with type uint64
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint64(uint256 argOffset)
        internal
        pure
        returns (uint64 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xc0, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint8
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint8(uint256 argOffset) internal pure returns (uint8 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xf8, calldataload(add(offset, argOffset)))
        }
    }

    /// @return offset The offset of the packed immutable args in calldata
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            offset := sub(
                calldatasize(),
                add(shr(240, calldataload(sub(calldatasize(), 2))), 2)
            )
        }
    }
}

// SPDX-License-Identifier: BSD

pragma solidity ^0.8.4;

/// @title ClonesWithImmutableArgs
/// @author wighawag, zefram.eth
/// @notice Enables creating clone contracts with immutable args
library ClonesWithImmutableArgs {
    error CreateFail();

    /// @notice Creates a clone proxy of the implementation contract, with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @return instance The address of the created clone
    function clone(address implementation, bytes memory data)
        internal
        returns (address payable instance)
    {
        // unrealistic for memory ptr or data length to exceed 256 bits
        unchecked {
            uint256 extraLength = data.length + 2; // +2 bytes for telling how much data there is appended to the call
            uint256 creationSize = 0x41 + extraLength;
            uint256 runSize = creationSize - 10;
            uint256 dataPtr;
            uint256 ptr;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                ptr := mload(0x40)

                // -------------------------------------------------------------------------------------------------------------
                // CREATION (10 bytes)
                // -------------------------------------------------------------------------------------------------------------

                // 61 runtime  | PUSH2 runtime (r)     | r                       | –
                mstore(
                    ptr,
                    0x6100000000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x01), shl(240, runSize)) // size of the contract running bytecode (16 bits)

                // creation size = 0a
                // 3d          | RETURNDATASIZE        | 0 r                     | –
                // 81          | DUP2                  | r 0 r                   | –
                // 60 creation | PUSH1 creation (c)    | c r 0 r                 | –
                // 3d          | RETURNDATASIZE        | 0 c r 0 r               | –
                // 39          | CODECOPY              | 0 r                     | [0-runSize): runtime code
                // f3          | RETURN                |                         | [0-runSize): runtime code

                // -------------------------------------------------------------------------------------------------------------
                // RUNTIME (55 bytes + extraLength)
                // -------------------------------------------------------------------------------------------------------------

                // 3d          | RETURNDATASIZE        | 0                       | –
                // 3d          | RETURNDATASIZE        | 0 0                     | –
                // 3d          | RETURNDATASIZE        | 0 0 0                   | –
                // 3d          | RETURNDATASIZE        | 0 0 0 0                 | –
                // 36          | CALLDATASIZE          | cds 0 0 0 0             | –
                // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | –
                // 3d          | RETURNDATASIZE        | 0 0 cds 0 0 0 0         | –
                // 37          | CALLDATACOPY          | 0 0 0 0                 | [0, cds) = calldata
                // 61          | PUSH2 extra           | extra 0 0 0 0           | [0, cds) = calldata
                mstore(
                    add(ptr, 0x03),
                    0x3d81600a3d39f33d3d3d3d363d3d376100000000000000000000000000000000
                )
                mstore(add(ptr, 0x13), shl(240, extraLength))

                // 60 0x37     | PUSH1 0x37            | 0x37 extra 0 0 0 0      | [0, cds) = calldata // 0x37 (55) is runtime size - data
                // 36          | CALLDATASIZE          | cds 0x37 extra 0 0 0 0  | [0, cds) = calldata
                // 39          | CODECOPY              | 0 0 0 0                 | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 36          | CALLDATASIZE          | cds 0 0 0 0             | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 61 extra    | PUSH2 extra           | extra cds 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x37) = extraData
                mstore(
                    add(ptr, 0x15),
                    0x6037363936610000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x1b), shl(240, extraLength))

                // 01          | ADD                   | cds+extra 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 73 addr     | PUSH20 0x123…         | addr 0 cds 0 0 0 0      | [0, cds) = calldata, [cds, cds+0x37) = extraData
                mstore(
                    add(ptr, 0x1d),
                    0x013d730000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x20), shl(0x60, implementation))

                // 5a          | GAS                   | gas addr 0 cds 0 0 0 0  | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // f4          | DELEGATECALL          | success 0 0             | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 3d          | RETURNDATASIZE        | rds success 0 0         | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 3d          | RETURNDATASIZE        | rds rds success 0 0     | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 93          | SWAP4                 | 0 rds success 0 rds     | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 80          | DUP1                  | 0 0 rds success 0 rds   | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 3e          | RETURNDATACOPY        | success 0 rds           | [0, rds) = return data (there might be some irrelevant leftovers in memory [rds, cds+0x37) when rds < cds+0x37)
                // 60 0x35     | PUSH1 0x35            | 0x35 sucess 0 rds       | [0, rds) = return data
                // 57          | JUMPI                 | 0 rds                   | [0, rds) = return data
                // fd          | REVERT                | –                       | [0, rds) = return data
                // 5b          | JUMPDEST              | 0 rds                   | [0, rds) = return data
                // f3          | RETURN                | –                       | [0, rds) = return data
                mstore(
                    add(ptr, 0x34),
                    0x5af43d3d93803e603557fd5bf300000000000000000000000000000000000000
                )
            }

            // -------------------------------------------------------------------------------------------------------------
            // APPENDED DATA (Accessible from extcodecopy)
            // (but also send as appended data to the delegatecall)
            // -------------------------------------------------------------------------------------------------------------

            extraLength -= 2;
            uint256 counter = extraLength;
            uint256 copyPtr = ptr + 0x41;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                dataPtr := add(data, 32)
            }
            for (; counter >= 32; counter -= 32) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    mstore(copyPtr, mload(dataPtr))
                }

                copyPtr += 32;
                dataPtr += 32;
            }
            uint256 mask = ~(256**(32 - counter) - 1);
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, and(mload(dataPtr), mask))
            }
            copyPtr += counter;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, shl(240, extraLength))
            }
            // solhint-disable-next-line no-inline-assembly
            assembly {
                instance := create(0, ptr, creationSize)
            }
            if (instance == address(0)) {
                revert CreateFail();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

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
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

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

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathSD59x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with int256 numbers considered to have 18
/// trailing decimals. We call this number representation signed 59.18-decimal fixed-point, since the numbers can have
/// a sign and there can be up to 59 digits in the integer part and up to 18 decimals in the fractional part. The numbers
/// are bound by the minimum and the maximum values permitted by the Solidity type int256.
library PRBMathSD59x18 {
    /// @dev log2(e) as a signed 59.18-decimal fixed-point number.
    int256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev Half the SCALE number.
    int256 internal constant HALF_SCALE = 5e17;

    /// @dev The maximum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728_792003956564819967;

    /// @dev The maximum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_WHOLE_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev The minimum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728_792003956564819968;

    /// @dev The minimum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_WHOLE_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    int256 internal constant SCALE = 1e18;

    /// INTERNAL FUNCTIONS ///

    /// @notice Calculate the absolute value of x.
    ///
    /// @dev Requirements:
    /// - x must be greater than MIN_SD59x18.
    ///
    /// @param x The number to calculate the absolute value for.
    /// @param result The absolute value of x.
    function abs(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x == MIN_SD59x18) {
                revert PRBMathSD59x18__AbsInputTooSmall();
            }
            result = x < 0 ? -x : x;
        }
    }

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The arithmetic average as a signed 59.18-decimal fixed-point number.
    function avg(int256 x, int256 y) internal pure returns (int256 result) {
        // The operations can never overflow.
        unchecked {
            int256 sum = (x >> 1) + (y >> 1);
            if (sum < 0) {
                // If at least one of x and y is odd, we add 1 to the result. This is because shifting negative numbers to the
                // right rounds down to infinity.
                assembly {
                    result := add(sum, and(or(x, y), 1))
                }
            } else {
                // If both x and y are odd, we add 1 to the result. This is because if both numbers are odd, the 0.5
                // remainder gets truncated twice.
                result = sum + (x & y & 1);
            }
        }
    }

    /// @notice Yields the least greatest signed 59.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as a signed 58.18-decimal fixed-point number.
    function ceil(int256 x) internal pure returns (int256 result) {
        if (x > MAX_WHOLE_SD59x18) {
            revert PRBMathSD59x18__CeilOverflow(x);
        }
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x > 0) {
                    result += SCALE;
                }
            }
        }
    }

    /// @notice Divides two signed 59.18-decimal fixed-point numbers, returning a new signed 59.18-decimal fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDiv".
    /// - None of the inputs can be MIN_SD59x18.
    /// - The denominator cannot be zero.
    /// - The result must fit within int256.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDiv".
    ///
    /// @param x The numerator as a signed 59.18-decimal fixed-point number.
    /// @param y The denominator as a signed 59.18-decimal fixed-point number.
    /// @param result The quotient as a signed 59.18-decimal fixed-point number.
    function div(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__DivInputTooSmall();
        }

        // Get hold of the absolute values of x and y.
        uint256 ax;
        uint256 ay;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
        }

        // Compute the absolute value of (x*SCALE)÷y. The result must fit within int256.
        uint256 rAbs = PRBMath.mulDiv(ax, uint256(SCALE), ay);
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__DivOverflow(rAbs);
        }

        // Get the signs of x and y.
        uint256 sx;
        uint256 sy;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
        }

        // XOR over sx and sy. This is basically checking whether the inputs have the same sign. If yes, the result
        // should be positive. Otherwise, it should be negative.
        result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns Euler's number as a signed 59.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (int256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// Caveats:
    /// - All from "exp2".
    /// - For any x less than -41.446531673892822322, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp(int256 x) internal pure returns (int256 result) {
        // Without this check, the value passed to "exp2" would be less than -59.794705707972522261.
        if (x < -41_446531673892822322) {
            return 0;
        }

        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathSD59x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            int256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - For any x less than -59.794705707972522261, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp2(int256 x) internal pure returns (int256 result) {
        // This works because 2^(-x) = 1/2^x.
        if (x < 0) {
            // 2^59.794705707972522262 is the maximum number whose inverse does not truncate down to zero.
            if (x < -59_794705707972522261) {
                return 0;
            }

            // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
            unchecked {
                result = 1e36 / exp2(-x);
            }
        } else {
            // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
            if (x >= 192e18) {
                revert PRBMathSD59x18__Exp2InputTooBig(x);
            }

            unchecked {
                // Convert x to the 192.64-bit fixed-point format.
                uint256 x192x64 = (uint256(x) << 64) / uint256(SCALE);

                // Safe to convert the result to int256 directly because the maximum input allowed is 192.
                result = int256(PRBMath.exp2(x192x64));
            }
        }
    }

    /// @notice Yields the greatest signed 59.18 decimal fixed-point number less than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be greater than or equal to MIN_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as a signed 58.18-decimal fixed-point number.
    function floor(int256 x) internal pure returns (int256 result) {
        if (x < MIN_WHOLE_SD59x18) {
            revert PRBMathSD59x18__FloorUnderflow(x);
        }
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x < 0) {
                    result -= SCALE;
                }
            }
        }
    }

    /// @notice Yields the excess beyond the floor of x for positive numbers and the part of the number to the right
    /// of the radix point for negative numbers.
    /// @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
    /// @param x The signed 59.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as a signed 59.18-decimal fixed-point number.
    function frac(int256 x) internal pure returns (int256 result) {
        unchecked {
            result = x % SCALE;
        }
    }

    /// @notice Converts a number from basic integer form to signed 59.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be greater than or equal to MIN_SD59x18 divided by SCALE.
    /// - x must be less than or equal to MAX_SD59x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in signed 59.18-decimal fixed-point representation.
    function fromInt(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x < MIN_SD59x18 / SCALE) {
                revert PRBMathSD59x18__FromIntUnderflow(x);
            }
            if (x > MAX_SD59x18 / SCALE) {
                revert PRBMathSD59x18__FromIntOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_SD59x18, lest it overflows.
    /// - x * y cannot be negative.
    ///
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function gm(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            int256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathSD59x18__GmOverflow(x, y);
            }

            // The product cannot be negative.
            if (xy < 0) {
                revert PRBMathSD59x18__GmNegativeProduct(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = int256(PRBMath.sqrt(uint256(xy)));
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as a signed 59.18-decimal fixed-point number.
    function inv(int256 x) internal pure returns (int256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as a signed 59.18-decimal fixed-point number.
    function ln(int256 x) internal pure returns (int256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 195205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as a signed 59.18-decimal fixed-point number.
    function log10(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly mul operation, not the "mul" function defined in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            default {
                result := MAX_SD59x18
            }
        }

        if (result == MAX_SD59x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than zero.
    ///
    /// Caveats:
    /// - The results are not perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as a signed 59.18-decimal fixed-point number.
    function log2(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }
        unchecked {
            // This works because log2(x) = -log2(1/x).
            int256 sign;
            if (x >= SCALE) {
                sign = 1;
            } else {
                sign = -1;
                // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
                assembly {
                    x := div(1000000000000000000000000000000000000, x)
                }
            }

            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(uint256(x / SCALE));

            // The integer part of the logarithm as a signed 59.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255, SCALE is 1e18 and sign is either 1 or -1.
            result = int256(n) * SCALE;

            // This is y = x * 2^(-n).
            int256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result * sign;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (int256 delta = int256(HALF_SCALE); delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
            result *= sign;
        }
    }

    /// @notice Multiplies two signed 59.18-decimal fixed-point numbers together, returning a new signed 59.18-decimal
    /// fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers and employs constant folding, i.e. the denominator is
    /// always 1e18.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - None of the inputs can be MIN_SD59x18
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    ///
    /// @param x The multiplicand as a signed 59.18-decimal fixed-point number.
    /// @param y The multiplier as a signed 59.18-decimal fixed-point number.
    /// @return result The product as a signed 59.18-decimal fixed-point number.
    function mul(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__MulInputTooSmall();
        }

        unchecked {
            uint256 ax;
            uint256 ay;
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);

            uint256 rAbs = PRBMath.mulDivFixedPoint(ax, ay);
            if (rAbs > uint256(MAX_SD59x18)) {
                revert PRBMathSD59x18__MulOverflow(rAbs);
            }

            uint256 sx;
            uint256 sy;
            assembly {
                sx := sgt(x, sub(0, 1))
                sy := sgt(y, sub(0, 1))
            }
            result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
        }
    }

    /// @notice Returns PI as a signed 59.18-decimal fixed-point number.
    function pi() internal pure returns (int256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    /// - z cannot be zero.
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as a signed 59.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as a signed 59.18-decimal fixed-point number.
    /// @return result x raised to power y, as a signed 59.18-decimal fixed-point number.
    function pow(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : int256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (signed 59.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - All from "abs" and "PRBMath.mulDivFixedPoint".
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as a signed 59.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function powu(int256 x, uint256 y) internal pure returns (int256 result) {
        uint256 xAbs = uint256(abs(x));

        // Calculate the first iteration of the loop in advance.
        uint256 rAbs = y & 1 > 0 ? xAbs : uint256(SCALE);

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        uint256 yAux = y;
        for (yAux >>= 1; yAux > 0; yAux >>= 1) {
            xAbs = PRBMath.mulDivFixedPoint(xAbs, xAbs);

            // Equivalent to "y % 2 == 1" but faster.
            if (yAux & 1 > 0) {
                rAbs = PRBMath.mulDivFixedPoint(rAbs, xAbs);
            }
        }

        // The result must fit within the 59.18-decimal fixed-point representation.
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__PowuOverflow(rAbs);
        }

        // Is the base negative and the exponent an odd number?
        bool isNegative = x < 0 && y & 1 == 1;
        result = isNegative ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns 1 as a signed 59.18-decimal fixed-point number.
    function scale() internal pure returns (int256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x cannot be negative.
    /// - x must be less than MAX_SD59x18 / SCALE.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as a signed 59.18-decimal fixed-point .
    function sqrt(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x < 0) {
                revert PRBMathSD59x18__SqrtNegativeInput(x);
            }
            if (x > MAX_SD59x18 / SCALE) {
                revert PRBMathSD59x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two signed
            // 59.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = int256(PRBMath.sqrt(uint256(x * SCALE)));
        }
    }

    /// @notice Converts a signed 59.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The signed 59.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toInt(int256 x) internal pure returns (int256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathUD60x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with uint256 numbers considered to have 18
/// trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
/// digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
/// maximum values permitted by the Solidity type uint256.
library PRBMathUD60x18 {
    /// @dev Half the SCALE number.
    uint256 internal constant HALF_SCALE = 5e17;

    /// @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
    uint256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_584007913129639935;

    /// @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_WHOLE_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The arithmetic average as an unsigned 60.18-decimal fixed-point number.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            result = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /// @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_UD60x18.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function ceil(uint256 x) internal pure returns (uint256 result) {
        if (x > MAX_WHOLE_UD60x18) {
            revert PRBMathUD60x18__CeilOverflow(x);
        }
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "SCALE - remainder" but faster.
            let delta := sub(SCALE, remainder)

            // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
            result := add(x, mul(delta, gt(remainder, 0)))
        }
    }

    /// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
    ///
    /// @dev Uses mulDiv to enable overflow-safe multiplication and division.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    ///
    /// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
    /// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
    /// @param result The quotient as an unsigned 60.18-decimal fixed-point number.
    function div(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(x, SCALE, y);
    }

    /// @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (uint256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp(uint256 x) internal pure returns (uint256 result) {
        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathUD60x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            uint256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_UD60x18.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
        if (x >= 192e18) {
            revert PRBMathUD60x18__Exp2InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x192x64 = (x << 64) / SCALE;

            // Pass x to the PRBMath.exp2 function, which uses the 192.64-bit fixed-point number representation.
            result = PRBMath.exp2(x192x64);
        }
    }

    /// @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    /// @param x The unsigned 60.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function floor(uint256 x) internal pure returns (uint256 result) {
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
            result := sub(x, mul(remainder, gt(remainder, 0)))
        }
    }

    /// @notice Yields the excess beyond the floor of x.
    /// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
    /// @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
    function frac(uint256 x) internal pure returns (uint256 result) {
        assembly {
            result := mod(x, SCALE)
        }
    }

    /// @notice Converts a number from basic integer form to unsigned 60.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be less than or equal to MAX_UD60x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in unsigned 60.18-decimal fixed-point representation.
    function fromUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__FromUintOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_UD60x18, lest it overflows.
    ///
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function gm(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            uint256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathUD60x18__GmOverflow(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = PRBMath.sqrt(xy);
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as an unsigned 60.18-decimal fixed-point number.
    function inv(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2.718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
    function ln(uint256 x) internal pure returns (uint256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
    function log10(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly multiplication operation, not the "mul" function defined
        // in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 59) }
            default {
                result := MAX_UD60x18
            }
        }

        if (result == MAX_UD60x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }
        unchecked {
            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(x / SCALE);

            // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255 and SCALE is 1e18.
            result = n * SCALE;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
        }
    }

    /// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @dev See the documentation for the "PRBMath.mulDivFixedPoint" function.
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The product as an unsigned 60.18-decimal fixed-point number.
    function mul(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDivFixedPoint(x, y);
    }

    /// @notice Returns PI as an unsigned 60.18-decimal fixed-point number.
    function pi() internal pure returns (uint256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as an unsigned 60.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as an unsigned 60.18-decimal fixed-point number.
    /// @return result x raised to power y, as an unsigned 60.18-decimal fixed-point number.
    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - The result must fit within MAX_UD60x18.
    ///
    /// Caveats:
    /// - All from "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as an unsigned 60.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function powu(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // Calculate the first iteration of the loop in advance.
        result = y & 1 > 0 ? x : SCALE;

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            x = PRBMath.mulDivFixedPoint(x, x);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                result = PRBMath.mulDivFixedPoint(result, x);
            }
        }
    }

    /// @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
    function scale() internal pure returns (uint256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x must be less than MAX_UD60x18 / SCALE.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as an unsigned 60.18-decimal fixed-point .
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
            // 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = PRBMath.sqrt(x * SCALE);
        }
    }

    /// @notice Converts a unsigned 60.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The unsigned 60.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import {
    IERC721Token,
    IPoolErrors,
    IPoolLenderActions,
    IPoolKickerActions,
    IPoolTakerActions,
    IPoolSettlerActions
}                           from './interfaces/pool/IPool.sol';
import {
    DrawDebtResult,
    RepayDebtResult,
    SettleParams,
    SettleResult,
    TakeResult
}                           from './interfaces/pool/commons/IPoolInternals.sol';
import { PoolState }        from './interfaces/pool/commons/IPoolState.sol';

import {
    IERC721Pool,
    IERC721PoolBorrowerActions,
    IERC721PoolImmutables,
    IERC721PoolLenderActions
}                               from './interfaces/pool/erc721/IERC721Pool.sol';
import { IERC721Taker }         from './interfaces/pool/erc721/IERC721Taker.sol';
import { IERC721PoolState }     from './interfaces/pool/erc721/IERC721PoolState.sol';

import { FlashloanablePool } from './base/FlashloanablePool.sol';
import { _roundToScale }     from './libraries/helpers/PoolHelper.sol';

import {
    _revertIfAuctionClearable,
    _revertAfterExpiry
}                               from './libraries/helpers/RevertsHelper.sol';

import { Maths }    from './libraries/internal/Maths.sol';
import { Deposits } from './libraries/internal/Deposits.sol';
import { Loans }    from './libraries/internal/Loans.sol';

import { LenderActions }   from './libraries/external/LenderActions.sol';
import { BorrowerActions } from './libraries/external/BorrowerActions.sol';
import { SettlerActions }  from './libraries/external/SettlerActions.sol';
import { TakerActions }    from './libraries/external/TakerActions.sol';

/**
 *  @title  ERC721 Pool contract
 *  @notice Entrypoint of `ERC721` Pool actions for pool actors:
 *          - `Lenders`: add, remove and move quote tokens; transfer `LP`
 *          - `Borrowers`: draw and repay debt
 *          - `Traders`: add, remove and move quote tokens; add and remove collateral
 *          - `Kickers`: auction undercollateralized loans; settle auctions; claim bond rewards
 *          - `Bidders`: take auctioned collateral
 *          - `Reserve purchasers`: start auctions; take reserves
 *          - `Flash borrowers`: initiate flash loans on ERC20 quote tokens
 *  @dev    Contract is `FlashloanablePool` with flashloan logic.
 *  @dev    Contract is base `Pool` with logic to handle `ERC721` collateral.
 *  @dev    Calls logic from external `PoolCommons`, `LenderActions`, `BorrowerActions` and `Auction` actions libraries.
 */
contract ERC721Pool is FlashloanablePool, IERC721Pool {

    /*****************/
    /*** Constants ***/
    /*****************/

    /// @dev Immutable NFT subset pool arg offset.
    uint256 internal constant SUBSET = 93;

    /***********************/
    /*** State Variables ***/
    /***********************/

    /// @dev Borrower `address => array` of tokenIds pledged by borrower mapping.
    mapping(address => uint256[]) public borrowerTokenIds;
    /// @dev Array of `tokenIds` in pool buckets (claimable from pool).
    uint256[]                     public bucketTokenIds;

    /// @dev Mapping of `tokenIds` allowed in `NFT` Subset type pool.
    mapping(uint256 => bool)      internal tokenIdsAllowed_;

    /****************************/
    /*** Initialize Functions ***/
    /****************************/

    /// @inheritdoc IERC721Pool
    function initialize(
        uint256[] memory tokenIds_,
        uint256 rate_
    ) external override {
        if (isPoolInitialized) revert AlreadyInitialized();

        inflatorState.inflator       = uint208(1e18);
        inflatorState.inflatorUpdate = uint48(block.timestamp);

        interestState.interestRate       = uint208(rate_);
        interestState.interestRateUpdate = uint48(block.timestamp);

        uint256 noOfTokens = tokenIds_.length;

        if (noOfTokens != 0) {
            // add subset of tokenIds allowed in the pool
            for (uint256 id = 0; id < noOfTokens;) {
                tokenIdsAllowed_[tokenIds_[id]] = true;

                unchecked { ++id; }
            }
        }

        Loans.init(loans);

        // increment initializations count to ensure these values can't be updated
        isPoolInitialized = true;
    }

    /******************/
    /*** Immutables ***/
    /******************/

    /// @inheritdoc IERC721PoolImmutables
    function isSubset() external pure override returns (bool) {
        return _getArgUint256(SUBSET) != 0;
    }

    /***********************************/
    /*** Borrower External Functions ***/
    /***********************************/

    function tokenIdsAllowed(uint256 tokenId_) public view returns (bool) {
        return (_getArgUint256(SUBSET) == 0 || tokenIdsAllowed_[tokenId_]);
    }

    /**
     *  @inheritdoc IERC721PoolBorrowerActions
     *  @dev    === Write state ===
     *  @dev    - decrement `poolBalances.t0DebtInAuction` accumulator
     *  @dev    - increment `poolBalances.pledgedCollateral` accumulator
     *  @dev    - increment `poolBalances.t0Debt` accumulator
     *  @dev    - update `t0Debt2ToCollateral` ratio only if loan not in auction, debt and collateral pre action are considered 0 if auction settled
     *  @dev    - update `borrowerTokenIds` and `bucketTokenIds` arrays
     *  @dev    === Emit events ===
     *  @dev    - `DrawDebtNFT`
     */
    function drawDebt(
        address borrowerAddress_,
        uint256 amountToBorrow_,
        uint256 limitIndex_,
        uint256[] calldata tokenIdsToPledge_
    ) external nonReentrant {
        PoolState memory poolState = _accruePoolInterest();

        // ensure the borrower is not charged for additional debt that they did not receive
        amountToBorrow_ = _roundToScale(amountToBorrow_, poolState.quoteTokenScale);

        DrawDebtResult memory result = BorrowerActions.drawDebt(
            auctions,
            buckets,
            deposits,
            loans,
            poolState,
            _availableQuoteToken(),
            borrowerAddress_,
            amountToBorrow_,
            limitIndex_,
            Maths.wad(tokenIdsToPledge_.length)
        );

        emit DrawDebtNFT(borrowerAddress_, amountToBorrow_, tokenIdsToPledge_, result.newLup);

        // update in memory pool state struct
        poolState.debt       = result.poolDebt;
        poolState.t0Debt     = result.t0PoolDebt;
        if (result.t0DebtInAuctionChange != 0) poolState.t0DebtInAuction -= result.t0DebtInAuctionChange;
        poolState.collateral = result.poolCollateral;

        // adjust t0Debt2ToCollateral ratio if loan not in auction
        if (!result.inAuction) {
            _updateT0Debt2ToCollateral(
                result.settledAuction ? 0 : result.debtPreAction,       // debt pre settle (for loan in auction) not taken into account
                result.debtPostAction,
                result.settledAuction ? 0 : result.collateralPreAction, // collateral pre settle (for loan in auction) not taken into account
                result.collateralPostAction
            );
        }

        // update pool interest rate state
        _updateInterestState(poolState, result.newLup);

        if (tokenIdsToPledge_.length != 0) {
            // update pool balances state
            if (result.t0DebtInAuctionChange != 0) {
                poolBalances.t0DebtInAuction = poolState.t0DebtInAuction;
            }
            poolBalances.pledgedCollateral = poolState.collateral;

            // move collateral from sender to pool
            _transferFromSenderToPool(borrowerTokenIds[borrowerAddress_], tokenIdsToPledge_);
        }

        if (result.settledAuction) _rebalanceTokens(borrowerAddress_, result.remainingCollateral);

        // move borrowed amount from pool to sender
        if (amountToBorrow_ != 0) {
            // update pool balances state
            poolBalances.t0Debt = poolState.t0Debt;

            // move borrowed amount from pool to sender
            _transferQuoteToken(msg.sender, amountToBorrow_);
        }
    }

    /**
     *  @inheritdoc IERC721PoolBorrowerActions
     *  @dev    === Write state ===
     *  @dev    - decrement `poolBalances.t0Debt accumulator`
     *  @dev    - decrement `poolBalances.t0DebtInAuction accumulator`
     *  @dev    - decrement `poolBalances.pledgedCollateral accumulator`
     *  @dev    - update `t0Debt2ToCollateral` ratio only if loan not in auction, debt and collateral pre action are considered 0 if auction settled
     *  @dev    - update `borrowerTokenIds` and `bucketTokenIds` arrays
     *  @dev    === Emit events ===
     *  @dev    - `RepayDebt`
     */
    function repayDebt(
        address borrowerAddress_,
        uint256 maxQuoteTokenAmountToRepay_,
        uint256 noOfNFTsToPull_,
        address collateralReceiver_,
        uint256 limitIndex_
    ) external nonReentrant {
        PoolState memory poolState = _accruePoolInterest();

        // ensure accounting is performed using the appropriate token scale
        if (maxQuoteTokenAmountToRepay_ != type(uint256).max)
            maxQuoteTokenAmountToRepay_ = _roundToScale(maxQuoteTokenAmountToRepay_, poolState.quoteTokenScale);

        RepayDebtResult memory result = BorrowerActions.repayDebt(
            auctions,
            buckets,
            deposits,
            loans,
            poolState,
            borrowerAddress_,
            maxQuoteTokenAmountToRepay_,
            Maths.wad(noOfNFTsToPull_),
            limitIndex_
        );

        emit RepayDebt(borrowerAddress_, result.quoteTokenToRepay, noOfNFTsToPull_, result.newLup);

        // update in memory pool state struct
        poolState.debt       = result.poolDebt;
        poolState.t0Debt     = result.t0PoolDebt;
        if (result.t0DebtInAuctionChange != 0) poolState.t0DebtInAuction -= result.t0DebtInAuctionChange;
        poolState.collateral = result.poolCollateral;

        if (result.settledAuction) _rebalanceTokens(borrowerAddress_, result.remainingCollateral);

        // adjust t0Debt2ToCollateral ratio if loan not in auction
        if (!result.inAuction) {
            _updateT0Debt2ToCollateral(
                result.settledAuction ? 0 : result.debtPreAction,       // debt pre settle (for loan in auction) not taken into account
                result.debtPostAction,
                result.settledAuction ? 0 : result.collateralPreAction, // collateral pre settle (for loan in auction) not taken into account
                result.collateralPostAction
            );
        }

        // update pool interest rate state
        _updateInterestState(poolState, result.newLup);

        // update pool balances state
        poolBalances.pledgedCollateral = poolState.collateral;

        if (result.quoteTokenToRepay != 0) {
            // update pool balances state
            poolBalances.t0Debt = poolState.t0Debt;
            if (result.t0DebtInAuctionChange != 0) {
                poolBalances.t0DebtInAuction = poolState.t0DebtInAuction;
            }

            // move amount to repay from sender to pool
            _transferQuoteTokenFrom(msg.sender, result.quoteTokenToRepay);
        }
        if (noOfNFTsToPull_ != 0) {
            // move collateral from pool to address specified as collateral receiver
            _transferFromPoolToAddress(collateralReceiver_, borrowerTokenIds[msg.sender], noOfNFTsToPull_);
        }
    }

    /*********************************/
    /*** Lender External Functions ***/
    /*********************************/

    /**
     *  @inheritdoc IERC721PoolLenderActions
     *  @dev    === Write state ===
     *  @dev    - update `bucketTokenIds` arrays
     *  @dev    === Emit events ===
     *  @dev    - `AddCollateralNFT`
     */
    function addCollateral(
        uint256[] calldata tokenIds_,
        uint256 index_,
        uint256 expiry_
    ) external override nonReentrant returns (uint256 bucketLP_) {
        _revertAfterExpiry(expiry_);
        PoolState memory poolState = _accruePoolInterest();

        bucketLP_ = LenderActions.addCollateral(
            buckets,
            deposits,
            Maths.wad(tokenIds_.length),
            index_
        );

        emit AddCollateralNFT(msg.sender, index_, tokenIds_, bucketLP_);

        // update pool interest rate state
        _updateInterestState(poolState, Deposits.getLup(deposits, poolState.debt));

        // move required collateral from sender to pool
        _transferFromSenderToPool(bucketTokenIds, tokenIds_);
    }

    /**
     *  @inheritdoc IERC721PoolLenderActions
     *  @dev    === Write state ===
     *  @dev    - update `bucketTokenIds` arrays
     *  @dev    === Emit events ===
     *  @dev    - `MergeOrRemoveCollateralNFT`
     */
    function mergeOrRemoveCollateral(
        uint256[] calldata removalIndexes_,
        uint256 noOfNFTsToRemove_,
        uint256 toIndex_
    ) external override nonReentrant returns (uint256 collateralMerged_, uint256 bucketLP_) {
        _revertIfAuctionClearable(auctions, loans);

        PoolState memory poolState = _accruePoolInterest();
        uint256 collateralAmount = Maths.wad(noOfNFTsToRemove_);

        (
            collateralMerged_,
            bucketLP_
        ) = LenderActions.mergeOrRemoveCollateral(
            buckets,
            deposits,
            removalIndexes_,
            collateralAmount,
            toIndex_
        );

        emit MergeOrRemoveCollateralNFT(msg.sender, collateralMerged_, bucketLP_);

        // update pool interest rate state
        _updateInterestState(poolState, Deposits.getLup(deposits, poolState.debt));

        if (collateralMerged_ == collateralAmount) {
            // Total collateral in buckets meets the requested removal amount, noOfNFTsToRemove_
            _transferFromPoolToAddress(msg.sender, bucketTokenIds, noOfNFTsToRemove_);
        }

    }

    /**
     *  @inheritdoc IPoolLenderActions
     *  @dev    === Write state ===
     *  @dev    - update `bucketTokenIds` arrays
     *  @dev    === Emit events ===
     *  @dev    - `RemoveCollateral`
     *  @param noOfNFTsToRemove_ Number of `NFT` tokens to remove.
     */
    function removeCollateral(
        uint256 noOfNFTsToRemove_,
        uint256 index_
    ) external override nonReentrant returns (uint256 removedAmount_, uint256 redeemedLP_) {
        _revertIfAuctionClearable(auctions, loans);

        PoolState memory poolState = _accruePoolInterest();

        removedAmount_ = Maths.wad(noOfNFTsToRemove_);
        redeemedLP_ = LenderActions.removeCollateral(
            buckets,
            deposits,
            removedAmount_,
            index_
        );

        emit RemoveCollateral(msg.sender, index_, noOfNFTsToRemove_, redeemedLP_);

        // update pool interest rate state
        _updateInterestState(poolState, Deposits.getLup(deposits, poolState.debt));

        _transferFromPoolToAddress(msg.sender, bucketTokenIds, noOfNFTsToRemove_);
    }

    /*******************************/
    /*** Pool Auctions Functions ***/
    /*******************************/

    /**
     *  @inheritdoc IPoolSettlerActions
     *  @dev    === Write state ===
     *  @dev    - decrement `poolBalances.t0Debt` accumulator
     *  @dev    - decrement `poolBalances.t0DebtInAuction` accumulator
     *  @dev    - decrement `poolBalances.pledgedCollateral` accumulator
     *  @dev    - no update of `t0Debt2ToCollateral` ratio as debt and collateral pre settle are not taken into account (pre debt and pre collateral = 0)
     */
    function settle(
        address borrowerAddress_,
        uint256 maxDepth_
    ) external nonReentrant override {
        PoolState memory poolState = _accruePoolInterest();

        SettleParams memory params = SettleParams({
            borrower:    borrowerAddress_,
            poolBalance: _getNormalizedPoolQuoteTokenBalance(),
            bucketDepth: maxDepth_
        });

        SettleResult memory result = SettlerActions.settlePoolDebt(
            auctions,
            buckets,
            deposits,
            loans,
            reserveAuction,
            poolState,
            params
        );

        _updatePostSettleState(result, poolState);

        // move token ids from borrower array to pool claimable array if any collateral used to settle bad debt
        _rebalanceTokens(params.borrower, result.collateralRemaining);
    }

    /**
     *  @inheritdoc IPoolTakerActions
     *  @dev    === Write state ===
     *  @dev    - decrement `poolBalances.t0Debt` accumulator
     *  @dev    - decrement `poolBalances.t0DebtInAuction` accumulator
     *  @dev    - decrement `poolBalances.pledgedCollateral` accumulator
     *  @dev    - update `t0Debt2ToCollateral` ratio only if auction settled, debt and collateral pre action are considered 0
     */
    function take(
        address        borrowerAddress_,
        uint256        collateral_,
        address        callee_,
        bytes calldata data_
    ) external override nonReentrant {
        PoolState memory poolState = _accruePoolInterest();

        TakeResult memory result = TakerActions.take(
            auctions,
            buckets,
            deposits,
            loans,
            poolState,
            borrowerAddress_,
            Maths.wad(collateral_),
            1
        );

        _updatePostTakeState(result, poolState);

        // transfer rounded collateral from pool to taker
        uint256[] memory tokensTaken = _transferFromPoolToAddress(
            callee_,
            borrowerTokenIds[borrowerAddress_],
            result.collateralAmount / 1e18
        );

        uint256 totalQuoteTokenAmount = result.quoteTokenAmount + result.excessQuoteToken;

        if (data_.length != 0) {
            IERC721Taker(callee_).atomicSwapCallback(
                tokensTaken,
                totalQuoteTokenAmount  / poolState.quoteTokenScale,
                data_
            );
        }

        // move borrower token ids to bucket claimable token ids after taking / reducing borrower collateral
        _rebalanceTokens(borrowerAddress_, result.remainingCollateral);

        // transfer from taker to pool the amount of quote tokens needed to cover collateral auctioned (including excess for rounded collateral)
        _transferQuoteTokenFrom(msg.sender, totalQuoteTokenAmount);

        // transfer from pool to borrower the excess of quote tokens after rounding collateral auctioned
        if (result.excessQuoteToken != 0) _transferQuoteToken(borrowerAddress_, result.excessQuoteToken);
    }

    /**
     *  @inheritdoc IPoolTakerActions
     *  @dev    === Write state ===
     *  @dev    - decrement `poolBalances.t0Debt` accumulator
     *  @dev    - decrement `poolBalances.t0DebtInAuction` accumulator
     *  @dev    - decrement `poolBalances.pledgedCollateral` accumulator
     *  @dev    - update `t0Debt2ToCollateral` ratio only if auction settled, debt and collateral pre action are considered 0
     */
    function bucketTake(
        address borrowerAddress_,
        bool    depositTake_,
        uint256 index_
    ) external override nonReentrant {

        PoolState memory poolState = _accruePoolInterest();

        TakeResult memory result = TakerActions.bucketTake(
            auctions,
            buckets,
            deposits,
            loans,
            poolState,
            borrowerAddress_,
            depositTake_,
            index_,
            1
        );

        _updatePostTakeState(result, poolState);

        // move borrower token ids to bucket claimable token ids after taking / reducing borrower collateral
        _rebalanceTokens(borrowerAddress_, result.remainingCollateral);
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    /**
     *  @notice Rebalance `NFT` token and transfer difference to floor collateral from borrower to pool claimable array.
     *  @dev    === Write state ===
     *  @dev    - update `borrowerTokens` and `bucketTokenIds` arrays
     *  @param  borrowerAddress_    Address of borrower.
     *  @param  borrowerCollateral_ Current borrower collateral to be rebalanced.
     */
    function _rebalanceTokens(
        address borrowerAddress_,
        uint256 borrowerCollateral_
    ) internal {
        // rebalance borrower's collateral, transfer difference to floor collateral from borrower to pool claimable array
        uint256[] storage borrowerTokens = borrowerTokenIds[borrowerAddress_];

        uint256 noOfTokensPledged    = borrowerTokens.length;
        /*
            eg1. borrowerCollateral_ = 4.1, noOfTokensPledged = 6; noOfTokensToTransfer = 1
            eg2. borrowerCollateral_ = 4, noOfTokensPledged = 6; noOfTokensToTransfer = 2
        */
        uint256 borrowerCollateralRoundedUp = (borrowerCollateral_ + 1e18 - 1) / 1e18;
        uint256 noOfTokensToTransfer = noOfTokensPledged - borrowerCollateralRoundedUp;

        for (uint256 i = 0; i < noOfTokensToTransfer;) {
            uint256 tokenId = borrowerTokens[--noOfTokensPledged]; // start with moving the last token pledged by borrower
            borrowerTokens.pop();                                  // remove token id from borrower
            bucketTokenIds.push(tokenId);                          // add token id to pool claimable tokens

            unchecked { ++i; }
        }
    }

    /**
     *  @notice Helper function for transferring multiple `NFT` tokens from msg.sender to pool.
     *  @dev    Reverts in case token id is not supported by subset pool.
     *  @param  poolTokens_ Array in pool that tracks `NFT` ids (could be tracking `NFT`s pledged by borrower or `NFT`s added by a lender in a specific bucket).
     *  @param  tokenIds_   Array of `NFT` token ids to transfer from `msg.sender` to pool.
     */
    function _transferFromSenderToPool(
        uint256[] storage poolTokens_,
        uint256[] calldata tokenIds_
    ) internal {
        for (uint256 i = 0; i < tokenIds_.length;) {
            uint256 tokenId = tokenIds_[i];
            if (!tokenIdsAllowed(tokenId)) revert OnlySubset();
            poolTokens_.push(tokenId);

            _transferNFT(msg.sender, address(this), tokenId);

            unchecked { ++i; }
        }
    }

    /**
     *  @notice Helper function for transferring multiple `NFT` tokens from pool to given address.
     *  @dev    It transfers `NFT`s from the most recent one added into the pool (pop from array tracking `NFT`s in pool).
     *  @param  toAddress_      Address where pool should transfer tokens to.
     *  @param  poolTokens_     Array in pool that tracks `NFT` ids (could be tracking `NFT`s pledged by borrower or `NFT`s added by a lender in a specific bucket).
     *  @param  amountToRemove_ Number of `NFT` tokens to transfer from pool to given address.
     *  @return Array containing token ids that were transferred from pool to address.
     */
    function _transferFromPoolToAddress(
        address toAddress_,
        uint256[] storage poolTokens_,
        uint256 amountToRemove_
    ) internal returns (uint256[] memory) {
        uint256[] memory tokensTransferred = new uint256[](amountToRemove_);

        uint256 noOfNFTsInPool = poolTokens_.length;

        for (uint256 i = 0; i < amountToRemove_;) {
            uint256 tokenId = poolTokens_[--noOfNFTsInPool]; // start with transferring the last token added in bucket
            poolTokens_.pop();

            _transferNFT(address(this), toAddress_, tokenId);

            tokensTransferred[i] = tokenId;

            unchecked { ++i; }
        }

        return tokensTransferred;
    }

    /**
     *  @notice Helper function to transfer an `NFT` from owner to target address (reused in code to reduce contract deployment bytecode size).
     *  @dev    Since `transferFrom` is used instead of `safeTransferFrom`, calling smart contracts must be careful to check that they support any received `NFT`s.
     *  @param  from_    `NFT` owner address.
     *  @param  to_      New `NFT` owner address.
     *  @param  tokenId_ `NFT` token id to be transferred.
     */
    function _transferNFT(address from_, address to_, uint256 tokenId_) internal {
        // slither-disable-next-line calls-loop
        IERC721Token(_getArgAddress(COLLATERAL_ADDRESS)).transferFrom(from_, to_, tokenId_);
    }

    /*******************************/
    /*** External View Functions ***/
    /*******************************/

    /// @inheritdoc IERC721PoolState
    function totalBorrowerTokens(address borrower_) external view override returns(uint256) {
        return borrowerTokenIds[borrower_].length;
    }

    /// @inheritdoc IERC721PoolState
    function totalBucketTokens() external view override returns(uint256) {
        return bucketTokenIds.length;
    }

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 }    from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Pool }                  from './Pool.sol';
import { IERC3156FlashBorrower } from '../interfaces/pool/IERC3156FlashBorrower.sol';

/**
 *  @title  Flashloanable Pool Contract
 *  @notice Pool contract with `IERC3156` flashloans capabilities.
 *  @notice No fee is charged for taking flashloans from pool.
 *  @notice Flashloans can be taking in `ERC20` quote and `ERC20` collateral tokens.
 */
abstract contract FlashloanablePool is Pool {
    using SafeERC20 for IERC20;

    /**
     *  @notice Called by flashloan borrowers to borrow liquidity which must be repaid in the same transaction.
     *  @param  receiver_ Address of the contract which implements the appropriate interface to receive tokens.
     *  @param  token_    Address of the `ERC20` token caller wants to borrow.
     *  @param  amount_   The denormalized amount (dependent upon token precision) of tokens to borrow.
     *  @param  data_     User-defined calldata passed to the receiver.
     *  @return success_  `True` if flashloan was successful.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver_,
        address token_,
        uint256 amount_,
        bytes calldata data_
    ) external virtual override nonReentrant returns (bool success_) {
        if (!_isFlashloanSupported(token_)) revert FlashloanUnavailableForToken();

        IERC20 tokenContract = IERC20(token_);

        uint256 initialBalance = tokenContract.balanceOf(address(this));

        tokenContract.safeTransfer(
            address(receiver_),
            amount_
        );

        if (receiver_.onFlashLoan(msg.sender, token_, amount_, 0, data_) != 
            keccak256("ERC3156FlashBorrower.onFlashLoan")) revert FlashloanCallbackFailed();

        tokenContract.safeTransferFrom(
            address(receiver_),
            address(this),
            amount_
        );

        if (tokenContract.balanceOf(address(this)) != initialBalance) revert FlashloanIncorrectBalance();

        success_ = true;

        emit Flashloan(address(receiver_), token_, amount_);
    }

    /**
     *  @notice Returns `0`, as no fee is charged for flashloans.
     */
    function flashFee(
        address token_,
        uint256
    ) external virtual view override returns (uint256) {
        if (!_isFlashloanSupported(token_)) revert FlashloanUnavailableForToken();
        return 0;
    }

    /**
     *  @notice Returns the amount of tokens available to be lent.
     *  @param  token_   Address of the `ERC20` token to be lent.
     *  @return maxLoan_ The amount of `token_` that can be lent.
     */
     function maxFlashLoan(
        address token_
    ) external virtual view override returns (uint256 maxLoan_) {
        if (_isFlashloanSupported(token_)) maxLoan_ = IERC20(token_).balanceOf(address(this));
    }

    /**
     *  @notice Returns `true` if pool allows flashloans for given token address, `false` otherwise.
     *  @dev    Allows flashloans for quote token, overriden in pool implementation to allow flashloans for other tokens.
     *  @param  token_   Address of the `ERC20` token to be lent.
     *  @return `True` if token can be flashloaned, `false` otherwise.
     */
    function _isFlashloanSupported(
        address token_
    ) internal virtual view returns (bool) {
        return token_ == _getArgAddress(QUOTE_ADDRESS);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { Clone }           from '@clones/Clone.sol';
import { ReentrancyGuard } from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import { Multicall }       from '@openzeppelin/contracts/utils/Multicall.sol';
import { SafeERC20 }       from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 }          from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {
    IPool,
    IPoolImmutables,
    IPoolBorrowerActions,
    IPoolLPActions,
    IPoolLenderActions,
    IPoolKickerActions,
    IPoolTakerActions,
    IPoolSettlerActions,
    IPoolState,
    IPoolDerivedState,
    IERC20Token
}                                    from '../interfaces/pool/IPool.sol';
import {
    PoolState,
    AuctionsState,
    DepositsState,
    LoansState,
    InflatorState,
    EmaState,
    InterestState,
    PoolBalancesState,
    ReserveAuctionState,
    Bucket,
    BurnEvent,
    Liquidation
}                                   from '../interfaces/pool/commons/IPoolState.sol';
import {
    KickResult,
    SettleResult,
    TakeResult,
    RemoveQuoteParams,
    MoveQuoteParams,
    AddQuoteParams,
    KickReserveAuctionParams
}                                   from '../interfaces/pool/commons/IPoolInternals.sol';

import {
    _priceAt,
    _roundToScale
}                               from '../libraries/helpers/PoolHelper.sol';
import {
    _revertIfAuctionDebtLocked,
    _revertIfAuctionClearable,
    _revertAfterExpiry
}                               from '../libraries/helpers/RevertsHelper.sol';

import { Buckets }  from '../libraries/internal/Buckets.sol';
import { Deposits } from '../libraries/internal/Deposits.sol';
import { Loans }    from '../libraries/internal/Loans.sol';
import { Maths }    from '../libraries/internal/Maths.sol';

import { BorrowerActions } from '../libraries/external/BorrowerActions.sol';
import { LenderActions }   from '../libraries/external/LenderActions.sol';
import { LPActions }       from '../libraries/external/LPActions.sol';
import { KickerActions }   from '../libraries/external/KickerActions.sol';
import { TakerActions }    from '../libraries/external/TakerActions.sol';
import { PoolCommons }     from '../libraries/external/PoolCommons.sol';

/**
 *  @title  Pool Contract
 *  @dev    Base contract and entrypoint for commong logic of both `ERC20` and `ERC721` pools.
 */
abstract contract Pool is Clone, ReentrancyGuard, Multicall, IPool {
    using SafeERC20 for IERC20;

    /*****************/
    /*** Constants ***/
    /*****************/

    /// @dev Immutable pool type arg offset.
    uint256 internal constant POOL_TYPE          = 0;
    /// @dev Immutable `Ajna` token address arg offset.
    uint256 internal constant AJNA_ADDRESS       = 1;
    /// @dev Immutable collateral token address arg offset.
    uint256 internal constant COLLATERAL_ADDRESS = 21;
    /// @dev Immutable quote token address arg offset.
    uint256 internal constant QUOTE_ADDRESS      = 41;
    /// @dev Immutable quote token scale arg offset.
    uint256 internal constant QUOTE_SCALE        = 61;

    /***********************/
    /*** State Variables ***/
    /***********************/

    AuctionsState       internal auctions;
    DepositsState       internal deposits;
    LoansState          internal loans;
    InflatorState       internal inflatorState;
    EmaState            internal emaState;
    InterestState       internal interestState;
    PoolBalancesState   internal poolBalances;
    ReserveAuctionState internal reserveAuction;

    /// @dev deposit index -> bucket mapping
    mapping(uint256 => Bucket) internal buckets;

    bool internal isPoolInitialized;

    /// @dev owner address -> new owner address -> deposit index -> allowed amount mapping
    mapping(address => mapping(address => mapping(uint256 => uint256))) private _lpAllowances;

    /// @dev owner address -> transferor address -> approved flag mapping
    mapping(address => mapping(address => bool)) public override approvedTransferors;

    /******************/
    /*** Immutables ***/
    /******************/

    /// @inheritdoc IPoolImmutables
    function poolType() external pure override returns (uint8) {
        return _getArgUint8(POOL_TYPE);
    }

    /// @inheritdoc IPoolImmutables
    function collateralAddress() external pure override returns (address) {
        return _getArgAddress(COLLATERAL_ADDRESS);
    }

    /// @inheritdoc IPoolImmutables
    function quoteTokenAddress() external pure override returns (address) {
        return _getArgAddress(QUOTE_ADDRESS);
    }

    /// @inheritdoc IPoolImmutables
    function quoteTokenScale() external pure override returns (uint256) {
        return _getArgUint256(QUOTE_SCALE);
    }


    /*********************************/
    /*** Lender External Functions ***/
    /*********************************/

    /// @inheritdoc IPoolLenderActions
    function addQuoteToken(
        uint256 amount_,
        uint256 index_,
        uint256 expiry_
    ) external override nonReentrant returns (uint256 bucketLP_) {
        _revertAfterExpiry(expiry_);
        PoolState memory poolState = _accruePoolInterest();

        // round to token precision
        amount_ = _roundToScale(amount_, poolState.quoteTokenScale);

        uint256 newLup;
        (bucketLP_, newLup) = LenderActions.addQuoteToken(
            buckets,
            deposits,
            poolState,
            AddQuoteParams({
                amount: amount_,
                index:  index_
            })
        );

        // update pool interest rate state
        _updateInterestState(poolState, newLup);

        // move quote token amount from lender to pool
        _transferQuoteTokenFrom(msg.sender, amount_);
    }

    /// @inheritdoc IPoolLenderActions
    function moveQuoteToken(
        uint256 maxAmount_,
        uint256 fromIndex_,
        uint256 toIndex_,
        uint256 expiry_
    ) external override nonReentrant returns (uint256 fromBucketLP_, uint256 toBucketLP_, uint256 movedAmount_) {
        _revertAfterExpiry(expiry_);
        PoolState memory poolState = _accruePoolInterest();

        _revertIfAuctionDebtLocked(deposits, poolState.t0DebtInAuction, fromIndex_, poolState.inflator);

        uint256 newLup;
        (
            fromBucketLP_,
            toBucketLP_,
            movedAmount_,
            newLup
        ) = LenderActions.moveQuoteToken(
            buckets,
            deposits,
            poolState,
            MoveQuoteParams({
                maxAmountToMove: maxAmount_,
                fromIndex:       fromIndex_,
                toIndex:         toIndex_,
                thresholdPrice:  Loans.getMax(loans).thresholdPrice
            })
        );

        // update pool interest rate state
        _updateInterestState(poolState, newLup);
    }

    /// @inheritdoc IPoolLenderActions
    function removeQuoteToken(
        uint256 maxAmount_,
        uint256 index_
    ) external override nonReentrant returns (uint256 removedAmount_, uint256 redeemedLP_) {
        _revertIfAuctionClearable(auctions, loans);

        PoolState memory poolState = _accruePoolInterest();

        _revertIfAuctionDebtLocked(deposits, poolState.t0DebtInAuction, index_, poolState.inflator);

        uint256 newLup;
        (
            removedAmount_,
            redeemedLP_,
            newLup
        ) = LenderActions.removeQuoteToken(
            buckets,
            deposits,
            poolState,
            RemoveQuoteParams({
                maxAmount:      Maths.min(maxAmount_, _availableQuoteToken()),
                index:          index_,
                thresholdPrice: Loans.getMax(loans).thresholdPrice
            })
        );

        // update pool interest rate state
        _updateInterestState(poolState, newLup);

        // move quote token amount from pool to lender
        _transferQuoteToken(msg.sender, removedAmount_);
    }

    /// @inheritdoc IPoolLenderActions
    function updateInterest() external override nonReentrant {
        PoolState memory poolState = _accruePoolInterest();
        _updateInterestState(poolState, Deposits.getLup(deposits, poolState.debt));
    }

    /***********************************/
    /*** Borrower External Functions ***/
    /***********************************/

    /// @inheritdoc IPoolBorrowerActions
    function stampLoan() external override nonReentrant {
        PoolState memory poolState = _accruePoolInterest();

        uint256 newLup = BorrowerActions.stampLoan(
            auctions,
            deposits,
            loans,
            poolState
        );

        _updateInterestState(poolState, newLup);
    }

    /*****************************/
    /*** Liquidation Functions ***/
    /*****************************/

    /**
     *  @inheritdoc IPoolKickerActions
     *  @dev    === Write state ===
     *  @dev    increment `poolBalances.t0DebtInAuction` and `poolBalances.t0Debt` accumulators
     *  @dev    update `t0Debt2ToCollateral` ratio, debt and collateral post action are considered 0
     */
    function kick(
        address borrower_,
        uint256 npLimitIndex_
    ) external override nonReentrant {
        PoolState memory poolState = _accruePoolInterest();

        // kick auction
        KickResult memory result = KickerActions.kick(
            auctions,
            deposits,
            loans,
            poolState,
            borrower_,
            npLimitIndex_
        );

        // update in memory pool state struct
        poolState.debt            =  Maths.wmul(result.t0PoolDebt, poolState.inflator);
        poolState.t0Debt          =  result.t0PoolDebt;
        poolState.t0DebtInAuction += result.t0KickedDebt;

        // adjust t0Debt2ToCollateral ratio
        _updateT0Debt2ToCollateral(
            result.debtPreAction,
            0, // debt post kick (for loan in auction) not taken into account
            result.collateralPreAction,
            0  // collateral post kick (for loan in auction) not taken into account
        );

        // update pool balances state
        poolBalances.t0Debt          = poolState.t0Debt;
        poolBalances.t0DebtInAuction = poolState.t0DebtInAuction;
        // update pool interest rate state
        _updateInterestState(poolState, result.lup);

        if (result.amountToCoverBond != 0) _transferQuoteTokenFrom(msg.sender, result.amountToCoverBond);
    }

    /**
     *  @inheritdoc IPoolKickerActions
     *  @dev    === Write state ===
     *  @dev    increment `poolBalances.t0DebtInAuction` and `poolBalances.t0Debt` accumulators
     *  @dev    update `t0Debt2ToCollateral` ratio, debt and collateral post action are considered 0
     */
    function kickWithDeposit(
        uint256 index_,
        uint256 npLimitIndex_
    ) external override nonReentrant {
        PoolState memory poolState = _accruePoolInterest();

        // kick auctions
        KickResult memory result = KickerActions.kickWithDeposit(
            auctions,
            deposits,
            buckets,
            loans,
            poolState,
            index_,
            npLimitIndex_
        );

        // update in memory pool state struct
        poolState.debt            =  Maths.wmul(result.t0PoolDebt, poolState.inflator);
        poolState.t0Debt          =  result.t0PoolDebt;
        poolState.t0DebtInAuction += result.t0KickedDebt;

        // adjust t0Debt2ToCollateral ratio
        _updateT0Debt2ToCollateral(
            result.debtPreAction,
            0, // debt post kick (for loan in auction) not taken into account
            result.collateralPreAction,
            0 // collateral post kick (for loan in auction) not taken into account
        );

        // update pool balances state
        poolBalances.t0Debt          = poolState.t0Debt;
        poolBalances.t0DebtInAuction = poolState.t0DebtInAuction;

        // update pool interest rate state
        _updateInterestState(poolState, result.lup);

        // transfer from kicker to pool the difference to cover bond
        if (result.amountToCoverBond != 0) _transferQuoteTokenFrom(msg.sender, result.amountToCoverBond);
    }

    /**
     *  @inheritdoc IPoolKickerActions
     *  @dev    === Write state ===
     *  @dev    decrease kicker's `claimable` accumulator
     *  @dev    decrease auctions `totalBondEscrowed` accumulator
     */
    function withdrawBonds(
        address recipient_,
        uint256 maxAmount_
    ) external override nonReentrant {
        uint256 claimable = auctions.kickers[msg.sender].claimable;

        // the amount to claim is constrained by the claimable balance of sender
        // claiming escrowed bonds is not constraiend by the pool balance
        maxAmount_ = Maths.min(maxAmount_, claimable);

        // revert if no amount to claim
        if (maxAmount_ == 0) revert InsufficientLiquidity();

        // decrement total bond escrowed
        auctions.totalBondEscrowed             -= maxAmount_;
        auctions.kickers[msg.sender].claimable -= maxAmount_;

        emit BondWithdrawn(msg.sender, recipient_, maxAmount_);

        _transferQuoteToken(recipient_, maxAmount_);
    }

    /*********************************/
    /*** Reserve Auction Functions ***/
    /*********************************/

    /**
     *  @inheritdoc IPoolKickerActions
     *  @dev    === Write state ===
     *  @dev    increment `latestBurnEpoch` counter
     *  @dev    update `reserveAuction.latestBurnEventEpoch` and burn event `timestamp` state
     *  @dev    === Reverts on ===
     *  @dev    2 weeks not passed `ReserveAuctionTooSoon()`
     *  @dev    === Emit events ===
     *  @dev    - `KickReserveAuction`
     */
    function kickReserveAuction() external override nonReentrant {
        // start a new claimable reserve auction, passing in relevant parameters such as the current pool size, debt, balance, and inflator value
        uint256 kickerAward = KickerActions.kickReserveAuction(
            auctions,
            reserveAuction,
            KickReserveAuctionParams({
                poolSize:    Deposits.treeSum(deposits),
                t0PoolDebt:  poolBalances.t0Debt,
                poolBalance: _getNormalizedPoolQuoteTokenBalance(),
                inflator:    inflatorState.inflator
            })
        );

        // transfer kicker award to msg.sender
        _transferQuoteToken(msg.sender, kickerAward);
    }

    /**
     *  @inheritdoc IPoolTakerActions
     *  @dev    === Write state ===
     *  @dev    increment `reserveAuction.totalAjnaBurned` accumulator
     *  @dev    update burn event `totalInterest` and `totalBurned` accumulators
     */
    function takeReserves(
        uint256 maxAmount_
    ) external override nonReentrant returns (uint256 amount_) {
        uint256 ajnaRequired;
        (amount_, ajnaRequired) = TakerActions.takeReserves(
            reserveAuction,
            maxAmount_
        );

        // burn required number of ajna tokens to take quote from reserves
        IERC20(_getArgAddress(AJNA_ADDRESS)).safeTransferFrom(msg.sender, address(this), ajnaRequired);

        IERC20Token(_getArgAddress(AJNA_ADDRESS)).burn(ajnaRequired);

        // transfer quote token to caller
        _transferQuoteToken(msg.sender, amount_);
    }

    /*****************************/
    /*** Transfer LP Functions ***/
    /*****************************/

    /// @inheritdoc IPoolLPActions
    function increaseLPAllowance(
        address spender_,
        uint256[] calldata indexes_,
        uint256[] calldata amounts_
    ) external override nonReentrant {
        LPActions.increaseLPAllowance(
            _lpAllowances[msg.sender][spender_],
            spender_,
            indexes_,
            amounts_
        );
    }

    /// @inheritdoc IPoolLPActions
    function decreaseLPAllowance(
        address spender_,
        uint256[] calldata indexes_,
        uint256[] calldata amounts_
    ) external override nonReentrant {
        LPActions.decreaseLPAllowance(
            _lpAllowances[msg.sender][spender_],
            spender_,
            indexes_,
            amounts_
        );
    }

    /// @inheritdoc IPoolLPActions
    function revokeLPAllowance(
        address spender_,
        uint256[] calldata indexes_
    ) external override nonReentrant {
        LPActions.revokeLPAllowance(
            _lpAllowances[msg.sender][spender_],
            spender_,
            indexes_
        );
    }

    /// @inheritdoc IPoolLPActions
    function approveLPTransferors(
        address[] calldata transferors_
    ) external override {
        LPActions.approveLPTransferors(
            approvedTransferors[msg.sender],
            transferors_
        );
    }

    /// @inheritdoc IPoolLPActions
    function revokeLPTransferors(
        address[] calldata transferors_
    ) external override {
        LPActions.revokeLPTransferors(
            approvedTransferors[msg.sender],
            transferors_
        );
    }

    /// @inheritdoc IPoolLPActions
    function transferLP(
        address owner_,
        address newOwner_,
        uint256[] calldata indexes_
    ) external override nonReentrant {
        LPActions.transferLP(
            buckets,
            _lpAllowances,
            approvedTransferors,
            owner_,
            newOwner_,
            indexes_
        );
    }

    /*****************************/
    /*** Pool Helper Functions ***/
    /*****************************/

    /**
     *  @notice Accrues pool interest in current block and returns pool details.
     *  @dev    external libraries call: `PoolCommons.accrueInterest`
     *  @dev    === Write state ===
     *  @dev    - `PoolCommons.accrueInterest` - `Deposits.mult` (scale `Fenwick` tree with new interest accrued):
     *  @dev      update scaling array state 
     *  @dev    - increment `reserveAuction.totalInterestEarned` accumulator
     *  @return poolState_ Struct containing pool details.
     */
    function _accruePoolInterest() internal returns (PoolState memory poolState_) {
        poolState_.t0Debt          = poolBalances.t0Debt;
        poolState_.t0DebtInAuction = poolBalances.t0DebtInAuction;
        poolState_.collateral      = poolBalances.pledgedCollateral;
        poolState_.inflator        = inflatorState.inflator;
        poolState_.rate            = interestState.interestRate;
        poolState_.poolType        = _getArgUint8(POOL_TYPE);
        poolState_.quoteTokenScale = _getArgUint256(QUOTE_SCALE);

	    // check if t0Debt is not equal to 0, indicating that there is debt to be tracked for the pool
        if (poolState_.t0Debt != 0) {
            // Calculate prior pool debt
            poolState_.debt = Maths.wmul(poolState_.t0Debt, poolState_.inflator);

	        // calculate elapsed time since inflator was last updated
            uint256 elapsed = block.timestamp - inflatorState.inflatorUpdate;

	        // set isNewInterestAccrued field to true if elapsed time is not 0, indicating that new interest may have accrued
            poolState_.isNewInterestAccrued = elapsed != 0;

            // if new interest may have accrued, call accrueInterest function and update inflator and debt fields of poolState_ struct
            if (poolState_.isNewInterestAccrued) {
                (uint256 newInflator, uint256 newInterest) = PoolCommons.accrueInterest(
                    emaState,
                    deposits,
                    poolState_,
                    Loans.getMax(loans).thresholdPrice,
                    elapsed
                );
                poolState_.inflator = newInflator;
                // After debt owed to lenders has accrued, calculate current debt owed by borrowers
                poolState_.debt = Maths.wmul(poolState_.t0Debt, poolState_.inflator);

                // update total interest earned accumulator with the newly accrued interest
                reserveAuction.totalInterestEarned += newInterest;
            }
        }
    }

    /**
     *  @notice Helper function to update pool state post take and bucket take actions.
     *  @param result_    Struct containing details of take result.
     *  @param poolState_ Struct containing pool details.
     */
    function _updatePostTakeState(
        TakeResult memory result_,
        PoolState memory poolState_
    ) internal {
        // update in memory pool state struct
        poolState_.debt            =  result_.poolDebt;
        poolState_.t0Debt          =  result_.t0PoolDebt;
        poolState_.t0DebtInAuction += result_.t0DebtPenalty;
        poolState_.t0DebtInAuction -= result_.t0DebtInAuctionChange;
        poolState_.collateral      -= (result_.collateralAmount + result_.compensatedCollateral); // deduct collateral taken plus collateral compensated if NFT auction settled

        // adjust t0Debt2ToCollateral ratio if auction settled by take action
        if (result_.settledAuction) {
            _updateT0Debt2ToCollateral(
                0, // debt pre take (for loan in auction) not taken into account
                result_.debtPostAction,
                0, // collateral pre take (for loan in auction) not taken into account
                result_.collateralPostAction
            );
        }

        // update pool balances state
        poolBalances.t0Debt            = poolState_.t0Debt;
        poolBalances.t0DebtInAuction   = poolState_.t0DebtInAuction;
        poolBalances.pledgedCollateral = poolState_.collateral;
        // update pool interest rate state
        _updateInterestState(poolState_, result_.newLup);
    }

    /**
     *  @notice Helper function to update pool state post settle action.
     *  @param result_    Struct containing details of settle result.
     *  @param poolState_ Struct containing pool details.
     */
    function _updatePostSettleState(
        SettleResult memory result_,
        PoolState memory poolState_
    ) internal {
        // update in memory pool state struct
        poolState_.debt            -= Maths.wmul(result_.t0DebtSettled, poolState_.inflator);
        poolState_.t0Debt          -= result_.t0DebtSettled;
        poolState_.t0DebtInAuction -= result_.t0DebtSettled;
        poolState_.collateral      -= result_.collateralSettled;

        // update pool balances state
        poolBalances.t0Debt            = poolState_.t0Debt;
        poolBalances.t0DebtInAuction   = poolState_.t0DebtInAuction;
        poolBalances.pledgedCollateral = poolState_.collateral;
        // update pool interest rate state
        _updateInterestState(poolState_, Deposits.getLup(deposits, poolState_.debt));
    }

    /**
     *  @notice Adjusts the `t0` debt 2 to collateral ratio, `interestState.t0Debt2ToCollateral`.
     *  @dev    Anytime a borrower's debt or collateral changes, the `interestState.t0Debt2ToCollateral` must be updated.
     *  @dev    === Write state ===
     *  @dev    update `interestState.t0Debt2ToCollateral` accumulator
     *  @param debtPreAction_  Borrower's debt before the action
     *  @param debtPostAction_ Borrower's debt after the action
     *  @param colPreAction_   Borrower's collateral before the action
     *  @param colPostAction_  Borrower's collateral after the action
     */
    function _updateT0Debt2ToCollateral(
        uint256 debtPreAction_,
        uint256 debtPostAction_,
        uint256 colPreAction_,
        uint256 colPostAction_
    ) internal {
        uint256 debt2ColAccumPreAction  = colPreAction_  != 0 ? debtPreAction_  ** 2 / colPreAction_  : 0;
        uint256 debt2ColAccumPostAction = colPostAction_ != 0 ? debtPostAction_ ** 2 / colPostAction_ : 0;

        if (debt2ColAccumPreAction != 0 || debt2ColAccumPostAction != 0) {
            uint256 curT0Debt2ToCollateral = interestState.t0Debt2ToCollateral;
            curT0Debt2ToCollateral += debt2ColAccumPostAction;
            curT0Debt2ToCollateral -= debt2ColAccumPreAction;

            interestState.t0Debt2ToCollateral = curT0Debt2ToCollateral;
        }
    }

    /**
     *  @notice Update interest rate and inflator of the pool.
     *  @dev    external libraries call: `PoolCommons.updateInterestState`
     *  @dev    === Write state ===
     *  @dev    - `PoolCommons.updateInterestState`
     *  @dev      `EMA`s accumulators
     *  @dev      interest rate accumulator and `interestRateUpdate` state
     *  @dev      pool inflator and `inflatorUpdate` state
     *  @dev    === Emit events ===
     *  @dev    `PoolCommons.updateInterestState`: `UpdateInterestRate`
     *  @param  poolState_ Struct containing pool details.
     *  @param  lup_       Current `LUP` in pool.
     */
    function _updateInterestState(
        PoolState memory poolState_,
        uint256 lup_
    ) internal {

        PoolCommons.updateInterestState(interestState, emaState, deposits, poolState_, lup_);

        // update pool inflator
        if (poolState_.isNewInterestAccrued) {
            inflatorState.inflator       = uint208(poolState_.inflator);
            inflatorState.inflatorUpdate = uint48(block.timestamp);
        // if the debt in the current pool state is 0, also update the inflator and inflatorUpdate fields in inflatorState
        // slither-disable-next-line incorrect-equality
        } else if (poolState_.debt == 0) {
            inflatorState.inflator       = uint208(Maths.WAD);
            inflatorState.inflatorUpdate = uint48(block.timestamp);
        }
    }

    /**
     *  @notice Helper function to transfer amount of quote tokens from sender to pool contract.
     *  @param  from_    Sender address.
     *  @param  amount_  Amount to transfer from sender (`WAD` precision). Scaled to quote token precision before transfer.
     */
    function _transferQuoteTokenFrom(address from_, uint256 amount_) internal {
        // Transfer amount in favour of the pool
        uint256 transferAmount = Maths.ceilDiv(amount_, _getArgUint256(QUOTE_SCALE));
        IERC20(_getArgAddress(QUOTE_ADDRESS)).safeTransferFrom(from_, address(this), transferAmount);
    }

    /**
     *  @notice Helper function to transfer amount of quote tokens from pool contract.
     *  @param  to_     Receiver address.
     *  @param  amount_ Amount to transfer to receiver (`WAD` precision). Scaled to quote token precision before transfer.
     */
    function _transferQuoteToken(address to_, uint256 amount_) internal {
        IERC20(_getArgAddress(QUOTE_ADDRESS)).safeTransfer(to_, amount_ / _getArgUint256(QUOTE_SCALE));
    }

    /**
     *  @notice Returns the quote token amount available to take loans or to be removed from pool.
     *          Ensures claimable reserves and auction bonds are not used when taking loans.
     */
    function _availableQuoteToken() internal view returns (uint256 quoteAvailable_) {
        uint256 poolBalance     = _getNormalizedPoolQuoteTokenBalance();
        uint256 escrowedAmounts = auctions.totalBondEscrowed + reserveAuction.unclaimed;

        if (poolBalance > escrowedAmounts) quoteAvailable_ = poolBalance - escrowedAmounts;
    }

    /**
     *  @notice Returns the pool quote token balance normalized to `WAD` to be used for calculating pool reserves.
     */
    function _getNormalizedPoolQuoteTokenBalance() internal view returns (uint256) {
        return IERC20(_getArgAddress(QUOTE_ADDRESS)).balanceOf(address(this)) * _getArgUint256(QUOTE_SCALE);
    }

    /*******************************/
    /*** External View Functions ***/
    /*******************************/

    /// @inheritdoc IPoolState
    function auctionInfo(
        address borrower_
    ) external
    view override returns (
        address kicker_,
        uint256 bondFactor_,
        uint256 bondSize_,
        uint256 kickTime_,
        uint256 kickMomp_,
        uint256 neutralPrice_,
        address head_,
        address next_,
        address prev_,
        bool alreadyTaken_
    ) {
        Liquidation memory liquidation = auctions.liquidations[borrower_];
        return (
            liquidation.kicker,
            liquidation.bondFactor,
            liquidation.bondSize,
            liquidation.kickTime,
            liquidation.kickMomp,
            liquidation.neutralPrice,
            auctions.head,
            liquidation.next,
            liquidation.prev,
            liquidation.alreadyTaken
        );
    }

    /// @inheritdoc IPoolState
    function borrowerInfo(
        address borrower_
    ) external view override returns (uint256, uint256, uint256) {
        return (
            loans.borrowers[borrower_].t0Debt,
            loans.borrowers[borrower_].collateral,
            loans.borrowers[borrower_].t0Np
        );
    }

    /// @inheritdoc IPoolState
    function bucketInfo(
        uint256 index_
    ) external view override returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 scale = Deposits.scale(deposits, index_);
        return (
            buckets[index_].lps,
            buckets[index_].collateral,
            buckets[index_].bankruptcyTime,
            Maths.wmul(scale, Deposits.unscaledValueAt(deposits, index_)),
            scale
        );
    }

    /// @inheritdoc IPoolDerivedState
    function bucketExchangeRate(
        uint256 index_
    ) external view returns (uint256 exchangeRate_) {
        Bucket storage bucket = buckets[index_];

        exchangeRate_ = Buckets.getExchangeRate(
            bucket.collateral,
            bucket.lps,
            Deposits.valueAt(deposits, index_),
            _priceAt(index_)
        );
    }

    /// @inheritdoc IPoolState
    function currentBurnEpoch() external view returns (uint256) {
        return reserveAuction.latestBurnEventEpoch;
    }

    /// @inheritdoc IPoolState
    function burnInfo(uint256 burnEventEpoch_) external view returns (uint256, uint256, uint256) {
        BurnEvent memory burnEvent = reserveAuction.burnEvents[burnEventEpoch_];

        return (
            burnEvent.timestamp,
            burnEvent.totalInterest,
            burnEvent.totalBurned
        );
    }

    /// @inheritdoc IPoolState
    function debtInfo() external view returns (uint256, uint256, uint256, uint256) {
        uint256 pendingInflator = PoolCommons.pendingInflator(
            inflatorState.inflator,
            inflatorState.inflatorUpdate,
            interestState.interestRate
        );
        return (
            Maths.ceilWmul(poolBalances.t0Debt, pendingInflator),
            Maths.ceilWmul(poolBalances.t0Debt, inflatorState.inflator),
            Maths.ceilWmul(poolBalances.t0DebtInAuction, inflatorState.inflator),
            interestState.t0Debt2ToCollateral
        );
    }


    /// @inheritdoc IPoolDerivedState
    function depositUpToIndex(uint256 index_) external view override returns (uint256) {
        return Deposits.prefixSum(deposits, index_);
    }
    
    /// @inheritdoc IPoolDerivedState
    function depositIndex(uint256 debt_) external view override returns (uint256) {
        return Deposits.findIndexOfSum(deposits, debt_);
    }

    /// @inheritdoc IPoolDerivedState
    function depositSize() external view override returns (uint256) {
        return Deposits.treeSum(deposits);
    }

    /// @inheritdoc IPoolDerivedState
    function depositUtilization() external view override returns (uint256) {
        return PoolCommons.utilization(emaState);
    }

    /// @inheritdoc IPoolDerivedState
    function depositScale(uint256 index_) external view override returns (uint256) {
        return deposits.scaling[index_];
    }

    /// @inheritdoc IPoolState
    function emasInfo() external view override returns (uint256, uint256, uint256, uint256) {
        return (
            emaState.debtColEma,
            emaState.lupt0DebtEma,
            emaState.debtEma,
            emaState.depositEma
        );
    }

    /// @inheritdoc IPoolState
    function inflatorInfo() external view override returns (uint256, uint256) {
        return (
            inflatorState.inflator,
            inflatorState.inflatorUpdate
        );
    }

    /// @inheritdoc IPoolState
    function interestRateInfo() external view returns (uint256, uint256) {
        return (
            interestState.interestRate,
            interestState.interestRateUpdate
        );
    }

    /// @inheritdoc IPoolState
    function kickerInfo(
        address kicker_
    ) external view override returns (uint256, uint256) {
        return(
            auctions.kickers[kicker_].claimable,
            auctions.kickers[kicker_].locked
        );
    }

    /// @inheritdoc IPoolState
    function lenderInfo(
        uint256 index_,
        address lender_
    ) external view override returns (uint256 lpBalance_, uint256 depositTime_) {
        depositTime_ = buckets[index_].lenders[lender_].depositTime;
        if (buckets[index_].bankruptcyTime < depositTime_) lpBalance_ = buckets[index_].lenders[lender_].lps;
    }

    /// @inheritdoc IPoolState
    function lpAllowance(
        uint256 index_,
        address spender_,
        address owner_
    ) external view override returns (uint256 allowance_) {
        allowance_ = _lpAllowances[owner_][spender_][index_];
    }

    /// @inheritdoc IPoolState
    function loanInfo(
        uint256 loanId_
    ) external view override returns (address, uint256) {
        return (
            Loans.getByIndex(loans, loanId_).borrower,
            Loans.getByIndex(loans, loanId_).thresholdPrice
        );
    }

    /// @inheritdoc IPoolState
    function loansInfo() external view override returns (address, uint256, uint256) {
        return (
            Loans.getMax(loans).borrower,
            Maths.wmul(Loans.getMax(loans).thresholdPrice, inflatorState.inflator),
            Loans.noOfLoans(loans)
        );
    }

    /// @inheritdoc IPoolState
    function pledgedCollateral() external view override returns (uint256) {
        return poolBalances.pledgedCollateral;
    }

    /// @inheritdoc IPoolState
    function reservesInfo() external view override returns (uint256, uint256, uint256, uint256) {
        return (
            auctions.totalBondEscrowed,
            reserveAuction.unclaimed,
            reserveAuction.kicked,
            reserveAuction.totalInterestEarned
        );
    }

    /// @inheritdoc IPoolState
    function totalAuctionsInPool() external view override returns (uint256) {
        return auctions.noOfAuctions;
    }

    /// @inheritdoc IPoolState
    function totalT0Debt() external view override returns (uint256) {
        return poolBalances.t0Debt;
    }

    /// @inheritdoc IPoolState
    function totalT0DebtInAuction() external view override returns (uint256) {
        return poolBalances.t0DebtInAuction;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { IPoolFactory } from '../interfaces/pool/IPoolFactory.sol';
import { IERC20Token }  from '../interfaces/pool/IPool.sol';

/**
 *  @title  Pool Deployer base contract
 *  @notice Base contract for Pool Deployer, contains logic used by both ERC20 and ERC721 Pool Factories.
 */
abstract contract PoolDeployer {

    /// @dev Min interest rate value allowed for deploying the pool (1%)
    uint256 public constant MIN_RATE = 0.01 * 1e18;
    /// @dev Max interest rate value allowed for deploying the pool (10%)
    uint256 public constant MAX_RATE = 0.1  * 1e18;

    /// @dev `Ajna` token address
    address public ajna; // Ajna token contract address on a network.

    /***********************/
    /*** State Variables ***/
    /***********************/

    /// @dev SubsetHash => CollateralAddress => QuoteAddress => Pool Address mapping
    // slither-disable-next-line uninitialized-state
    mapping(bytes32 => mapping(address => mapping(address => address))) public deployedPools;

    /// @notice List of all deployed pools. Separate list is maintained for each factory.
    // slither-disable-next-line uninitialized-state
    address[] public deployedPoolsList;

    /*****************/
    /*** Modifiers ***/
    /*****************/

    /**
     * @notice Ensures that pools are deployed according to specifications.
     * @dev    Used by both `ERC20` and `ERC721` pool factories.
     */
    modifier canDeploy(address collateral_, address quote_, uint256 interestRate_) {
        if (collateral_ == quote_)                                  revert IPoolFactory.DeployQuoteCollateralSameToken();
        if (collateral_ == address(0) || quote_ == address(0))      revert IPoolFactory.DeployWithZeroAddress();
        if (MIN_RATE > interestRate_ || interestRate_ > MAX_RATE)   revert IPoolFactory.PoolInterestRateInvalid();
        _;
    }

    /*********************************/
    /*** Internal Helper Functions ***/
    /*********************************/

    /**
     * @notice Calculates `ERC20` token scale based on token decimals.
     * @dev    Reverts with `DecimalsNotCompliant` if token decimals are more than 18 or token contract lacks `decimals` method.
     * @param  token_  `ERC20` token address.
     * @return scale_  Calculated token scale. 
     */
    function _getTokenScale(address token_) internal view returns (uint256 scale_) {
        try IERC20Token(token_).decimals() returns (uint8 tokenDecimals_) {
            // revert if token decimals is more than 18
            if (tokenDecimals_ > 18) revert IPoolFactory.DecimalsNotCompliant();

            // scale calculated at pool precision (18)
            scale_ = 10 ** (18 - tokenDecimals_);
        } catch {
            // revert if token contract lack `decimals` method
            revert IPoolFactory.DecimalsNotCompliant();
        }
    }

    /*******************************/
    /*** External View Functions ***/
    /*******************************/

    /**
     * @notice Returns the list of all deployed pools.
     * @dev    This function is used by integrations to access deployed pools.
     * @dev    Each factory implementation maintains its own list of deployed pools.
     * @return List of all deployed pools.
     */
    function getDeployedPoolsList() external view returns (address[] memory) {
        return deployedPoolsList;
    }

    /**
     * @notice Returns the number of deployed pools that have been deployed by a factory.
     * @return Length of `deployedPoolsList` array.
     */
    function getNumberOfDeployedPools() external view returns (uint256) {
        return deployedPoolsList.length;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IERC3156FlashBorrower {

    /**
     * @dev    Receive a flash loan.
     * @param  initiator The initiator of the loan.
     * @param  token     The loan currency.
     * @param  amount    The amount of tokens lent (token precision).
     * @param  fee       The additional amount of tokens to repay.
     * @param  data      Arbitrary data structure, intended to contain user-defined parameters.
     * @return The `keccak256` hash of `ERC3156FlashBorrower.onFlashLoan`
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes   calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;
import { IERC3156FlashBorrower } from "./IERC3156FlashBorrower.sol";


interface IERC3156FlashLender {

    /**
     * @dev    The amount of currency available to be lent.
     * @param  token_ The loan currency.
     * @return The amount of `token` that can be borrowed (token precision).
     */
    function maxFlashLoan(
        address token_
    ) external view returns (uint256);

    /**
     * @dev    The fee to be charged for a given loan.
     * @param  token_    The loan currency.
     * @param  amount_   The amount of tokens lent (token precision).
     * @return The amount of `token` to be charged for the loan (token precision), on top of the returned principal .
     */
    function flashFee(
        address token_,
        uint256 amount_
    ) external view returns (uint256);

    /**
     * @dev    Initiate a flash loan.
     * @param  receiver_ The receiver of the tokens in the loan, and the receiver of the callback.
     * @param  token_    The loan currency.
     * @param  amount_   The amount of tokens lent (token precision).
     * @param  data_     Arbitrary data structure, intended to contain user-defined parameters.
     * @return `True` when successful flashloan, `false` otherwise.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver_,
        address token_,
        uint256 amount_,
        bytes   calldata data_
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { IPoolBorrowerActions } from './commons/IPoolBorrowerActions.sol';
import { IPoolLPActions }       from './commons/IPoolLPActions.sol';
import { IPoolLenderActions }   from './commons/IPoolLenderActions.sol';
import { IPoolKickerActions }   from './commons/IPoolKickerActions.sol';
import { IPoolTakerActions }    from './commons/IPoolTakerActions.sol';
import { IPoolSettlerActions }  from './commons/IPoolSettlerActions.sol';

import { IPoolImmutables }      from './commons/IPoolImmutables.sol';
import { IPoolState }           from './commons/IPoolState.sol';
import { IPoolDerivedState }    from './commons/IPoolDerivedState.sol';
import { IPoolEvents }          from './commons/IPoolEvents.sol';
import { IPoolErrors }          from './commons/IPoolErrors.sol';
import { IERC3156FlashLender }  from './IERC3156FlashLender.sol';

/**
 * @title Base Pool Interface
 */
interface IPool is
    IPoolBorrowerActions,
    IPoolLPActions,
    IPoolLenderActions,
    IPoolKickerActions,
    IPoolTakerActions,
    IPoolSettlerActions,
    IPoolImmutables,
    IPoolState,
    IPoolDerivedState,
    IPoolEvents,
    IPoolErrors,
    IERC3156FlashLender
{

}

/// @dev Pool type enum - `ERC20` and `ERC721`
enum PoolType { ERC20, ERC721 }

/// @dev `ERC20` token interface.
interface IERC20Token {
    function balanceOf(address account) external view returns (uint256);
    function burn(uint256 amount) external;
    function decimals() external view returns (uint8);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

/// @dev `ERC721` token interface.
interface IERC721Token {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 *  @title Pool Factory Interface.
 *  @dev   Used to deploy both funigible and non fungible pools.
 */
interface IPoolFactory {

    /**************/
    /*** Errors ***/
    /**************/
    /**
     *  @notice Can't deploy if quote and collateral are the same token.
     */
    error DeployQuoteCollateralSameToken();

    /**
     *  @notice Can't deploy with one of the args pointing to the `0x` address.
     */
    error DeployWithZeroAddress();

    /**
     *  @notice Can't deploy with token that has no decimals method or decimals greater than 18
     */
    error DecimalsNotCompliant();

    /**
     *  @notice Pool with this combination of quote and collateral already exists.
     *  @param  pool_ The address of deployed pool.
     */
    error PoolAlreadyExists(address pool_);

    /**
     *  @notice Pool starting interest rate is invalid.
     */
    error PoolInterestRateInvalid();

    /**************/
    /*** Events ***/
    /**************/

    /**
     *  @notice Emitted when a new pool is created.
     *  @param  pool_ The address of the new pool.
     */
    event PoolCreated(address pool_);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool Borrower Actions
 */
interface IPoolBorrowerActions {

    /**
     *  @notice Called by fully colalteralized borrowers to restamp the `Neutral Price` of the loan (only if loan is fully collateralized and not in auction).
     *          The reason for stamping the neutral price on the loan is to provide some certainty to the borrower as to at what price they can expect to be liquidated.
     *          This action can restamp only the loan of `msg.sender`.
     */
    function stampLoan() external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool Derived State
 */
interface IPoolDerivedState {

    /**
     *  @notice Returns the exchange rate for a given bucket index.
     *  @param  index_        The bucket index.
     *  @return exchangeRate_ Exchange rate of the bucket (`WAD` precision).
     */
    function bucketExchangeRate(
        uint256 index_
    ) external view returns (uint256 exchangeRate_);

    /**
     *  @notice Returns the prefix sum of a given bucket.
     *  @param  index_   The bucket index.
     *  @return The deposit up to given index (`WAD` precision).
     */
    function depositUpToIndex(
        uint256 index_
    ) external view returns (uint256);

    /**
     *  @notice Returns the bucket index for a given debt amount.
     *  @param  debt_  The debt amount to calculate bucket index for (`WAD` precision).
     *  @return Bucket index.
     */
    function depositIndex(
        uint256 debt_
    ) external view returns (uint256);

    /**
     *  @notice Returns the total amount of quote tokens deposited in pool.
     *  @return Total amount of deposited quote tokens (`WAD` precision).
     */
    function depositSize() external view returns (uint256);

    /**
     *  @notice Returns the meaningful actual utilization of the pool.
     *  @return Deposit utilization (`WAD` precision).
     */
    function depositUtilization() external view returns (uint256);

    /**
     *  @notice Returns the scaling value of deposit at given index.
     *  @param  index_  Deposit index.
     *  @return Deposit scaling (`WAD` precision).
     */
    function depositScale(
        uint256 index_
    ) external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool Errors.
 */
interface IPoolErrors {
    /**************************/
    /*** Common Pool Errors ***/
    /**************************/

    /**
     *  @notice `LP` allowance is already set by the owner.
     */
    error AllowanceAlreadySet();

    /**
     *  @notice The action cannot be executed on an active auction.
     */
    error AuctionActive();

    /**
     *  @notice Attempted auction to clear doesn't meet conditions.
     */
    error AuctionNotClearable();

    /**
     *  @notice Head auction should be cleared prior of executing this action.
     */
    error AuctionNotCleared();

    /**
     *  @notice The auction price is greater than the arbed bucket price.
     */
    error AuctionPriceGtBucketPrice();

    /**
     *  @notice Pool already initialized.
     */
    error AlreadyInitialized();

    /**
     *  @notice Borrower is attempting to create or modify a loan such that their loan's quote token would be less than the pool's minimum debt amount.
     */
    error AmountLTMinDebt();

    /**
     *  @notice Recipient of borrowed quote tokens doesn't match the caller of the `drawDebt` function.
     */
    error BorrowerNotSender();

    /**
     *  @notice Borrower has a healthy over-collateralized position.
     */
    error BorrowerOk();

    /**
     *  @notice Borrower is attempting to borrow more quote token than they have collateral for.
     */
    error BorrowerUnderCollateralized();

    /**
     *  @notice Operation cannot be executed in the same block when bucket becomes insolvent.
     */
    error BucketBankruptcyBlock();

    /**
     *  @notice User attempted to merge collateral from a lower price bucket into a higher price bucket.
     */
    error CannotMergeToHigherPrice();

    /**
     *  @notice User attempted an operation which does not exceed the dust amount, or leaves behind less than the dust amount.
     */
    error DustAmountNotExceeded();

    /**
     *  @notice Callback invoked by `flashLoan` function did not return the expected hash (see `ERC-3156` spec).
     */
    error FlashloanCallbackFailed();

    /**
     *  @notice Balance of pool contract before flashloan is different than the balance after flashloan.
     */
    error FlashloanIncorrectBalance();

    /**
     *  @notice Pool cannot facilitate a flashloan for the specified token address.
     */
    error FlashloanUnavailableForToken();

    /**
     *  @notice User is attempting to move or pull more collateral than is available.
     */
    error InsufficientCollateral();

    /**
     *  @notice Lender is attempting to move or remove more collateral they have claim to in the bucket.
     *  @notice Lender is attempting to remove more collateral they have claim to in the bucket.
     *  @notice Lender must have enough `LP` to claim the desired amount of quote from the bucket.
     */
    error InsufficientLP();

    /**
     *  @notice Bucket must have more quote available in the bucket than the lender is attempting to claim.
     */
    error InsufficientLiquidity();

    /**
     *  @notice When increasing / decreasing `LP` allowances indexes and amounts arrays parameters should have same length.
     */
    error InvalidAllowancesInput();

    /**
     *  @notice When transferring `LP` between indices, the new index must be a valid index.
     */
    error InvalidIndex();

    /**
     *  @notice The amount used for performed action should be greater than `0`.
     */
    error InvalidAmount();

    /**
     *  @notice Borrower is attempting to borrow more quote token than is available before the supplied `limitIndex`.
     */
    error LimitIndexExceeded();

    /**
     *  @notice When moving quote token `HTP` must stay below `LUP`.
     *  @notice When removing quote token `HTP` must stay below `LUP`.
     */
    error LUPBelowHTP();

    /**
     *  @notice Liquidation must result in `LUP` below the borrowers threshold price.
     */
    error LUPGreaterThanTP();

    /**
     *  @notice From index and to index arguments to move are the same.
     */
    error MoveToSameIndex();

    /**
     *  @notice Owner of the `LP` must have approved the new owner prior to transfer.
     */
    error NoAllowance();

    /**
     *  @notice Actor is attempting to take or clear an inactive auction.
     */
    error NoAuction();

    /**
     *  @notice No pool reserves are claimable.
     */
    error NoReserves();

    /**
     *  @notice Actor is attempting to take or clear an inactive reserves auction.
     */
    error NoReservesAuction();

    /**
     *  @notice Lender must have non-zero `LP` when attemptign to remove quote token from the pool.
     */
    error NoClaim();

    /**
     *  @notice Borrower has no debt to liquidate.
     *  @notice Borrower is attempting to repay when they have no outstanding debt.
     */
    error NoDebt();

    /**
     *  @notice Borrower is attempting to borrow an amount of quote tokens that will push the pool into under-collateralization.
     */
    error PoolUnderCollateralized();

    /**
     *  @notice Actor is attempting to remove using a bucket with price below the `LUP`.
     */
    error PriceBelowLUP();

    /**
     *  @notice Lender is attempting to remove quote tokens from a bucket that exists above active auction debt from top-of-book downward.
     */
    error RemoveDepositLockedByAuctionDebt();

    /**
     * @notice User attempted to kick off a new auction less than `2` weeks since the last auction completed.
     */
    error ReserveAuctionTooSoon();

    /**
     *  @notice Take was called before `1` hour had passed from kick time.
     */
    error TakeNotPastCooldown();

    /**
     *  @notice Current block timestamp has reached or exceeded a user-provided expiration.
     */
    error TransactionExpired();

    /**
     *  @notice The address that transfer `LP` is not approved by the `LP` receiving address.
     */
    error TransferorNotApproved();

    /**
     *  @notice Owner of the `LP` attemps to transfer `LP` to same address.
     */
    error TransferToSameOwner();

    /**
     *  @notice The threshold price of the loan to be inserted in loans heap is zero.
     */
    error ZeroThresholdPrice();

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool Events
 */
interface IPoolEvents {

    /*********************/
    /*** Lender events ***/
    /*********************/

    /**
     *  @notice Emitted when lender adds quote token to the pool.
     *  @param  lender    Recipient that added quote tokens.
     *  @param  index     Index at which quote tokens were added.
     *  @param  amount    Amount of quote tokens added to the pool (`WAD` precision).
     *  @param  lpAwarded Amount of `LP` awarded for the deposit (`WAD` precision).
     *  @param  lup       `LUP` calculated after deposit.
     */
    event AddQuoteToken(
        address indexed lender,
        uint256 indexed index,
        uint256 amount,
        uint256 lpAwarded,
        uint256 lup
    );

    /**
     *  @notice Emitted when lender moves quote token from a bucket price to another.
     *  @param  lender         Recipient that moved quote tokens.
     *  @param  from           Price bucket from which quote tokens were moved.
     *  @param  to             Price bucket where quote tokens were moved.
     *  @param  amount         Amount of quote tokens moved (`WAD` precision).
     *  @param  lpRedeemedFrom Amount of `LP` removed from the `from` bucket (`WAD` precision).
     *  @param  lpAwardedTo    Amount of `LP` credited to the `to` bucket (`WAD` precision).
     *  @param  lup            `LUP` calculated after removal.
     */
    event MoveQuoteToken(
        address indexed lender,
        uint256 indexed from,
        uint256 indexed to,
        uint256 amount,
        uint256 lpRedeemedFrom,
        uint256 lpAwardedTo,
        uint256 lup
    );

    /**
     *  @notice Emitted when lender removes quote token from the pool.
     *  @param  lender     Recipient that removed quote tokens.
     *  @param  index      Index at which quote tokens were removed.
     *  @param  amount     Amount of quote tokens removed from the pool (`WAD` precision).
     *  @param  lpRedeemed Amount of `LP` exchanged for quote token (`WAD` precision).
     *  @param  lup        `LUP` calculated after removal.
     */
    event RemoveQuoteToken(
        address indexed lender,
        uint256 indexed index,
        uint256 amount,
        uint256 lpRedeemed,
        uint256 lup
    );

    /**
     *  @notice Emitted when lender claims collateral from a bucket.
     *  @param  claimer    Recipient that claimed collateral.
     *  @param  index      Index at which collateral was claimed.
     *  @param  amount     The amount of collateral (`WAD` precision for `ERC20` pools, number of `NFT` tokens for `ERC721` pools) transferred to the claimer.
     *  @param  lpRedeemed Amount of `LP` exchanged for quote token (`WAD` precision).
     */
    event RemoveCollateral(
        address indexed claimer,
        uint256 indexed index,
        uint256 amount,
        uint256 lpRedeemed
    );

    /***********************/
    /*** Borrower events ***/
    /***********************/

    /**
     *  @notice Emitted when borrower repays quote tokens to the pool and/or pulls collateral from the pool.
     *  @param  borrower         `msg.sender` or on behalf of sender.
     *  @param  quoteRepaid      Amount of quote tokens repaid to the pool (`WAD` precision).
     *  @param  collateralPulled The amount of collateral (`WAD` precision for `ERC20` pools, number of `NFT` tokens for `ERC721` pools) transferred to the claimer.
     *  @param  lup              `LUP` after repay.
     */
    event RepayDebt(
        address indexed borrower,
        uint256 quoteRepaid,
        uint256 collateralPulled,
        uint256 lup
    );

    /**********************/
    /*** Auction events ***/
    /**********************/

    /**
     *  @notice Emitted when a liquidation is initiated.
     *  @param  borrower   Identifies the loan being liquidated.
     *  @param  debt       Debt the liquidation will attempt to cover (`WAD` precision).
     *  @param  collateral Amount of collateral up for liquidation (`WAD` precision for `ERC20` pools, number of `NFT` tokens for `ERC721` pools).
     *  @param  bond       Bond amount locked by kicker (`WAD` precision).
     */
    event Kick(
        address indexed borrower,
        uint256 debt,
        uint256 collateral,
        uint256 bond
    );

    /**
     *  @notice Emitted when kickers are withdrawing funds posted as auction bonds.
     *  @param  kicker   The kicker withdrawing bonds.
     *  @param  reciever The address receiving withdrawn bond amount.
     *  @param  amount   The bond amount that was withdrawn (`WAD` precision).
     */
    event BondWithdrawn(
        address indexed kicker,
        address indexed reciever,
        uint256 amount
    );

    /**
     *  @notice Emitted when an actor uses quote token to arb higher-priced deposit off the book.
     *  @param  borrower    Identifies the loan being liquidated.
     *  @param  index       The index of the `Highest Price Bucket` used for this take.
     *  @param  amount      Amount of quote token used to purchase collateral (`WAD` precision).
     *  @param  collateral  Amount of collateral purchased with quote token (`WAD` precision).
     *  @param  bondChange  Impact of this take to the liquidation bond (`WAD` precision).
     *  @param  isReward    `True` if kicker was rewarded with `bondChange` amount, `false` if kicker was penalized.
     *  @dev    amount / collateral implies the auction price.
     */
    event BucketTake(
        address indexed borrower,
        uint256 index,
        uint256 amount,
        uint256 collateral,
        uint256 bondChange,
        bool    isReward
    );

    /**
     *  @notice Emitted when `LP` are awarded to a taker or kicker in a bucket take.
     *  @param  taker           Actor who invoked the bucket take.
     *  @param  kicker          Actor who started the auction.
     *  @param  lpAwardedTaker  Amount of `LP` awarded to the taker (`WAD` precision).
     *  @param  lpAwardedKicker Amount of `LP` awarded to the actor who started the auction (`WAD` precision).
     */
    event BucketTakeLPAwarded(
        address indexed taker,
        address indexed kicker,
        uint256 lpAwardedTaker,
        uint256 lpAwardedKicker
    );

    /**
     *  @notice Emitted when an actor uses quote token outside of the book to purchase collateral under liquidation.
     *  @param  borrower   Identifies the loan being liquidated.
     *  @param  amount     Amount of quote token used to purchase collateral (`WAD` precision).
     *  @param  collateral Amount of collateral purchased with quote token (for `ERC20` pool, `WAD` precision) or number of `NFT`s purchased (for `ERC721` pool).
     *  @param  bondChange Impact of this take to the liquidation bond (`WAD` precision).
     *  @param  isReward   `True` if kicker was rewarded with `bondChange` amount, `false` if kicker was penalized.
     *  @dev    amount / collateral implies the auction price.
     */
    event Take(
        address indexed borrower,
        uint256 amount,
        uint256 collateral,
        uint256 bondChange,
        bool    isReward
    );

    /**
     *  @notice Emitted when an actor settles debt in a completed liquidation
     *  @param  borrower    Identifies the loan under liquidation.
     *  @param  settledDebt Amount of pool debt settled in this transaction (`WAD` precision).
     *  @dev    When `amountRemaining_ == 0`, the auction has been completed cleared and removed from the queue.
     */
    event Settle(
        address indexed borrower,
        uint256 settledDebt
    );

    /**
     *  @notice Emitted when auction is completed.
     *  @param  borrower   Address of borrower that exits auction.
     *  @param  collateral Borrower's remaining collateral when auction completed (`WAD` precision).
     */
    event AuctionSettle(
        address indexed borrower,
        uint256 collateral
    );

    /**
     *  @notice Emitted when `NFT` auction is completed.
     *  @param  borrower   Address of borrower that exits auction.
     *  @param  collateral Borrower's remaining collateral when auction completed.
     *  @param  lp         Amount of `LP` given to the borrower to compensate fractional collateral (if any, `WAD` precision).
     *  @param  index      Index of the bucket with `LP` to compensate fractional collateral.
     */
    event AuctionNFTSettle(
        address indexed borrower,
        uint256 collateral,
        uint256 lp,
        uint256 index
    );

    /**
     *  @notice Emitted when a `Claimaible Reserve Auction` is started.
     *  @param  claimableReservesRemaining Amount of claimable reserves which has not yet been taken (`WAD` precision).
     *  @param  auctionPrice               Current price at which `1` quote token may be purchased, denominated in `Ajna`.
     *  @param  currentBurnEpoch           Current burn epoch.
     */
    event KickReserveAuction(
        uint256 claimableReservesRemaining,
        uint256 auctionPrice,
        uint256 currentBurnEpoch
    );

    /**
     *  @notice Emitted when a `Claimaible Reserve Auction` is taken.
     *  @param  claimableReservesRemaining Amount of claimable reserves which has not yet been taken (`WAD` precision).
     *  @param  auctionPrice               Current price at which `1` quote token may be purchased, denominated in `Ajna`.
     *  @param  currentBurnEpoch           Current burn epoch.
     */
    event ReserveAuction(
        uint256 claimableReservesRemaining,
        uint256 auctionPrice,
        uint256 currentBurnEpoch
    );

    /**************************/
    /*** LP transfer events ***/
    /**************************/

    /**
     *  @notice Emitted when owner increase the `LP` allowance of a spender at specified indexes with specified amounts.
     *  @param  owner     `LP` owner.
     *  @param  spender   Address approved to transfer `LP`.
     *  @param  indexes   Bucket indexes of `LP` approved.
     *  @param  amounts   `LP` amounts added (ordered by indexes, `WAD` precision).
     */
    event IncreaseLPAllowance(
        address indexed owner,
        address indexed spender,
        uint256[] indexes,
        uint256[] amounts
    );

    /**
     *  @notice Emitted when owner decrease the `LP` allowance of a spender at specified indexes with specified amounts.
     *  @param  owner     `LP` owner.
     *  @param  spender   Address approved to transfer `LP`.
     *  @param  indexes   Bucket indexes of `LP` approved.
     *  @param  amounts   `LP` amounts removed (ordered by indexes, `WAD` precision).
     */
    event DecreaseLPAllowance(
        address indexed owner,
        address indexed spender,
        uint256[] indexes,
        uint256[] amounts
    );

    /**
     *  @notice Emitted when lender removes the allowance of a spender for their `LP`.
     *  @param  owner   `LP` owner.
     *  @param  spender Address that is having it's allowance revoked.
     *  @param  indexes List of bucket index to remove the allowance from.
     */
    event RevokeLPAllowance(
        address indexed owner,
        address indexed spender,
        uint256[] indexes
    );

    /**
     *  @notice Emitted when lender whitelists addresses to accept `LP` from.
     *  @param  lender      Recipient that approves new owner for `LP`.
     *  @param  transferors List of addresses that can transfer `LP` to lender.
     */
    event ApproveLPTransferors(
        address indexed lender,
        address[] transferors
    );

    /**
     *  @notice Emitted when lender removes addresses from the `LP` transferors whitelist.
     *  @param  lender      Recipient that approves new owner for `LP`.
     *  @param  transferors List of addresses that won't be able to transfer `LP` to lender anymore.
     */
    event RevokeLPTransferors(
        address indexed lender,
        address[] transferors
    );

    /**
     *  @notice Emitted when a lender transfers their `LP` to a different address.
     *  @dev    Used by `PositionManager.memorializePositions()`.
     *  @param  owner    The original owner address of the position.
     *  @param  newOwner The new owner address of the position.
     *  @param  indexes  Array of price bucket indexes at which `LP` were transferred.
     *  @param  lp       Amount of `LP` transferred (`WAD` precision).
     */
    event TransferLP(
        address owner,
        address newOwner,
        uint256[] indexes,
        uint256 lp
    );

    /**************************/
    /*** Pool common events ***/
    /**************************/

    /**
     *  @notice Emitted when `LP` are forfeited as a result of the bucket losing all assets.
     *  @param  index       The index of the bucket.
     *  @param  lpForfeited Amount of `LP` forfeited by lenders (`WAD` precision).
     */
    event BucketBankruptcy(
        uint256 indexed index,
        uint256 lpForfeited
    );

    /**
     *  @notice Emitted when a flashloan is taken from pool.
     *  @param  receiver The address receiving the flashloan.
     *  @param  token    The address of token flashloaned from pool.
     *  @param  amount   The amount of tokens flashloaned from pool (token precision).
     */
    event Flashloan(
        address indexed receiver,
        address indexed token,
        uint256 amount
    );

    /**
     *  @notice Emitted when a loan `Neutral Price` is restamped.
     *  @param  borrower Identifies the loan to update the `Neutral Price`.
     */
    event LoanStamped(
        address indexed borrower
    );

    /**
     *  @notice Emitted when pool interest rate is reset. This happens when `interest rate > 10%` and `debtEma < 5%` of `depositEma`
     *  @param  oldRate Old pool interest rate.
     *  @param  newRate New pool interest rate.
     */
    event ResetInterestRate(
        uint256 oldRate,
        uint256 newRate
    );

    /**
     *  @notice Emitted when pool interest rate is updated.
     *  @param  oldRate Old pool interest rate.
     *  @param  newRate New pool interest rate.
     */
    event UpdateInterestRate(
        uint256 oldRate,
        uint256 newRate
    );

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool Immutables
 */
interface IPoolImmutables {

    /**
     *  @notice Returns the type of the pool (`0` for `ERC20`, `1` for `ERC721`).
     */
    function poolType() external pure returns (uint8);

    /**
     *  @notice Returns the address of the pool's collateral token.
     */
    function collateralAddress() external pure returns (address);

    /**
     *  @notice Returns the address of the pool's quote token.
     */
    function quoteTokenAddress() external pure returns (address);

    /**
     *  @notice Returns the `quoteTokenScale` state variable.
     *  @notice Token scale is also the minimum amount a lender may have in a bucket (dust amount).
     *  @return The precision of the quote `ERC20` token based on decimals.
     */
    function quoteTokenScale() external pure returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Internal structs used by the pool / libraries
 */

/*****************************/
/*** Auction Param Structs ***/
/*****************************/

/// @dev Struct used to return result of `KickerAction.kick` action.
struct KickResult {
    uint256 amountToCoverBond;    // [WAD] amount of bond that needs to be covered
    uint256 t0PoolDebt;           // [WAD] t0 debt in pool after kick
    uint256 t0KickedDebt;         // [WAD] new t0 debt after kick
    uint256 lup;                  // [WAD] current lup
    uint256 debtPreAction;        // [WAD] The amount of borrower t0 debt before kick
    uint256 collateralPreAction;  // [WAD] The amount of borrower collateral before kick, same as the one after kick
}

/// @dev Struct used to hold parameters for `SettlerAction.settlePoolDebt` action.
struct SettleParams {
    address borrower;    // borrower address to settle
    uint256 bucketDepth; // number of buckets to use when settle debt
    uint256 poolBalance; // current pool quote token balance
}

/// @dev Struct used to return result of `SettlerAction.settlePoolDebt` action.
struct SettleResult {
    uint256 debtPreAction;       // [WAD] The amount of borrower t0 debt before settle
    uint256 debtPostAction;      // [WAD] The amount of borrower t0 debt remaining after settle
    uint256 collateralPreAction; // [WAD] The amount of borrower collateral before settle
    uint256 collateralRemaining; // [WAD] The amount of borrower collateral left after settle
    uint256 collateralSettled;   // [WAD] The amount of borrower collateral settled
    uint256 t0DebtSettled;       // [WAD] The amount of t0 debt settled
}

/// @dev Struct used to return result of `TakerAction.take` and `TakerAction.bucketTake` actions.
struct TakeResult {
    uint256 collateralAmount;      // [WAD] amount of collateral taken
    uint256 compensatedCollateral; // [WAD] amount of borrower collateral that is compensated with LP
    uint256 quoteTokenAmount;      // [WAD] amount of quote tokens paid by taker for taken collateral, used in take action
    uint256 t0DebtPenalty;         // [WAD] t0 penalty applied on first take
    uint256 excessQuoteToken;      // [WAD] (NFT only) amount of quote tokens to be paid by taker to borrower for fractional collateral, used in take action
    uint256 remainingCollateral;   // [WAD] amount of borrower collateral remaining after take
    uint256 poolDebt;              // [WAD] current pool debt
    uint256 t0PoolDebt;            // [WAD] t0 pool debt
    uint256 newLup;                // [WAD] current lup
    uint256 t0DebtInAuctionChange; // [WAD] the amount of t0 debt recovered by take action
    bool    settledAuction;        // true if auction is settled by take action
    uint256 debtPreAction;         // [WAD] The amount of borrower t0 debt before take
    uint256 debtPostAction;        // [WAD] The amount of borrower t0 debt after take
    uint256 collateralPreAction;   // [WAD] The amount of borrower collateral before take
    uint256 collateralPostAction;  // [WAD] The amount of borrower collateral after take
}

/// @dev Struct used to hold parameters for `KickerAction.kickReserveAuction` action.
struct KickReserveAuctionParams {
    uint256 poolSize;    // [WAD] total deposits in pool (with accrued debt)
    uint256 t0PoolDebt;  // [WAD] current t0 pool debt
    uint256 poolBalance; // [WAD] pool quote token balance
    uint256 inflator;    // [WAD] pool current inflator
}

/******************************************/
/*** Liquidity Management Param Structs ***/
/******************************************/

/// @dev Struct used to hold parameters for `LenderAction.addQuoteToken` action.
struct AddQuoteParams {
    uint256 amount;          // [WAD] amount to be added
    uint256 index;           // the index in which to deposit
}

/// @dev Struct used to hold parameters for `LenderAction.moveQuoteToken` action.
struct MoveQuoteParams {
    uint256 fromIndex;       // the deposit index from where amount is moved
    uint256 maxAmountToMove; // [WAD] max amount to move between deposits
    uint256 toIndex;         // the deposit index where amount is moved to
    uint256 thresholdPrice;  // [WAD] max threshold price in pool
}

/// @dev Struct used to hold parameters for `LenderAction.removeQuoteToken` action.
struct RemoveQuoteParams {
    uint256 index;           // the deposit index from where amount is removed
    uint256 maxAmount;       // [WAD] max amount to be removed
    uint256 thresholdPrice;  // [WAD] max threshold price in pool
}

/*************************************/
/*** Loan Management Param Structs ***/
/*************************************/

/// @dev Struct used to return result of `BorrowerActions.drawDebt` action.
struct DrawDebtResult {
    bool    inAuction;             // true if loan still in auction after pledge more collateral, false otherwise
    uint256 newLup;                // [WAD] new pool LUP after draw debt
    uint256 poolCollateral;        // [WAD] total amount of collateral in pool after pledge collateral
    uint256 poolDebt;              // [WAD] total accrued debt in pool after draw debt
    uint256 remainingCollateral;   // [WAD] amount of borrower collateral after draw debt (for NFT can be diminished if auction settled)
    bool    settledAuction;        // true if collateral pledged settles auction
    uint256 t0DebtInAuctionChange; // [WAD] change of t0 pool debt in auction after pledge collateral
    uint256 t0PoolDebt;            // [WAD] amount of t0 debt in pool after draw debt
    uint256 debtPreAction;         // [WAD] The amount of borrower t0 debt before draw debt
    uint256 debtPostAction;        // [WAD] The amount of borrower t0 debt after draw debt
    uint256 collateralPreAction;   // [WAD] The amount of borrower collateral before draw debt
    uint256 collateralPostAction;  // [WAD] The amount of borrower collateral after draw debt
}

/// @dev Struct used to return result of `BorrowerActions.repayDebt` action.
struct RepayDebtResult {
    bool    inAuction;             // true if loan still in auction after repay, false otherwise
    uint256 newLup;                // [WAD] new pool LUP after draw debt
    uint256 poolCollateral;        // [WAD] total amount of collateral in pool after pull collateral
    uint256 poolDebt;              // [WAD] total accrued debt in pool after repay debt
    uint256 remainingCollateral;   // [WAD] amount of borrower collateral after pull collateral
    bool    settledAuction;        // true if repay debt settles auction
    uint256 t0DebtInAuctionChange; // [WAD] change of t0 pool debt in auction after repay debt
    uint256 t0PoolDebt;            // [WAD] amount of t0 debt in pool after repay
    uint256 quoteTokenToRepay;     // [WAD] quote token amount to be transferred from sender to pool
    uint256 debtPreAction;         // [WAD] The amount of borrower t0 debt before repay debt
    uint256 debtPostAction;        // [WAD] The amount of borrower t0 debt after repay debt
    uint256 collateralPreAction;   // [WAD] The amount of borrower collateral before repay debt
    uint256 collateralPostAction;  // [WAD] The amount of borrower collateral after repay debt
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool Kicker Actions
 */
interface IPoolKickerActions {

    /********************/
    /*** Liquidations ***/
    /********************/

    /**
     *  @notice Called by actors to initiate a liquidation.
     *  @param  borrower_     Identifies the loan to liquidate.
     *  @param  npLimitIndex_ Index of the lower bound of `NP` tolerated when kicking the auction.
     */
    function kick(
        address borrower_,
        uint256 npLimitIndex_
    ) external;

    /**
     *  @notice Called by lenders to liquidate the top loan using their deposits.
     *  @param  index_        The deposit index to use for kicking the top loan.
     *  @param  npLimitIndex_ Index of the lower bound of `NP` tolerated when kicking the auction.
     */
    function kickWithDeposit(
        uint256 index_,
        uint256 npLimitIndex_
    ) external;

    /**
     *  @notice Called by kickers to withdraw their auction bonds (the amount of quote tokens that are not locked in active auctions).
     *  @param  recipient_ Address to receive claimed bonds amount.
     *  @param  maxAmount_ The max amount to withdraw from auction bonds (`WAD` precision). Constrained by claimable amounts and liquidity.
     */
    function withdrawBonds(
        address recipient_,
        uint256 maxAmount_
    ) external;

    /***********************/
    /*** Reserve Auction ***/
    /***********************/

    /**
     *  @notice Called by actor to start a `Claimable Reserve Auction` (`CRA`).
     */
    function kickReserveAuction() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool `LP` Actions
 */
interface IPoolLPActions {

    /**
     *  @notice Called by `LP` owners to approve transfer of an amount of `LP` to a new owner.
     *  @dev    Intended for use by the `PositionManager` contract.
     *  @param  spender_ The new owner of the `LP`.
     *  @param  indexes_ Bucket indexes from where `LP` are transferred.
     *  @param  amounts_ The amounts of `LP` approved to transfer (`WAD` precision).
     */
    function increaseLPAllowance(
        address spender_,
        uint256[] calldata indexes_,
        uint256[] calldata amounts_
    ) external;

    /**
     *  @notice Called by `LP` owners to decrease the amount of `LP` that can be spend by a new owner.
     *  @dev    Intended for use by the `PositionManager` contract.
     *  @param  spender_ The new owner of the `LP`.
     *  @param  indexes_ Bucket indexes from where `LP` are transferred.
     *  @param  amounts_ The amounts of `LP` disapproved to transfer (`WAD` precision).
     */
    function decreaseLPAllowance(
        address spender_,
        uint256[] calldata indexes_,
        uint256[] calldata amounts_
    ) external;

    /**
     *  @notice Called by `LP` owners to decrease the amount of `LP` that can be spend by a new owner.
     *  @param  spender_ Address that is having it's allowance revoked.
     *  @param  indexes_ List of bucket index to remove the allowance from.
     */
    function revokeLPAllowance(
        address spender_,
        uint256[] calldata indexes_
    ) external;

    /**
     *  @notice Called by `LP` owners to allow addresses that can transfer LP.
     *  @dev    Intended for use by the `PositionManager` contract.
     *  @param  transferors_ Addresses that are allowed to transfer `LP` to new owner.
     */
    function approveLPTransferors(
        address[] calldata transferors_
    ) external;

    /**
     *  @notice Called by `LP` owners to revoke addresses that can transfer `LP`.
     *  @dev    Intended for use by the `PositionManager` contract.
     *  @param  transferors_ Addresses that are revoked to transfer `LP` to new owner.
     */
    function revokeLPTransferors(
        address[] calldata transferors_
    ) external;

    /**
     *  @notice Called by `LP` owners to transfers their `LP` to a different address. `approveLpOwnership` needs to be run first.
     *  @dev    Used by `PositionManager.memorializePositions()`.
     *  @param  owner_    The original owner address of the position.
     *  @param  newOwner_ The new owner address of the position.
     *  @param  indexes_  Array of price buckets index at which `LP` were moved.
     */
    function transferLP(
        address owner_,
        address newOwner_,
        uint256[] calldata indexes_
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool Lender Actions
 */
interface IPoolLenderActions {

    /*********************************************/
    /*** Quote/collateral management functions ***/
    /*********************************************/

    /**
     *  @notice Called by lenders to add an amount of credit at a specified price bucket.
     *  @param  amount_   The amount of quote token to be added by a lender (`WAD` precision).
     *  @param  index_    The index of the bucket to which the quote tokens will be added.
     *  @param  expiry_   Timestamp after which this transaction will revert, preventing inclusion in a block with unfavorable price.
     *  @return bucketLP_ The amount of `LP` changed for the added quote tokens (`WAD` precision).
     */
    function addQuoteToken(
        uint256 amount_,
        uint256 index_,
        uint256 expiry_
    ) external returns (uint256 bucketLP_);

    /**
     *  @notice Called by lenders to move an amount of credit from a specified price bucket to another specified price bucket.
     *  @param  maxAmount_    The maximum amount of quote token to be moved by a lender (`WAD` precision).
     *  @param  fromIndex_    The bucket index from which the quote tokens will be removed.
     *  @param  toIndex_      The bucket index to which the quote tokens will be added.
     *  @param  expiry_       Timestamp after which this transaction will revert, preventing inclusion in a block with unfavorable price.
     *  @return fromBucketLP_ The amount of `LP` moved out from bucket (`WAD` precision).
     *  @return toBucketLP_   The amount of `LP` moved to destination bucket (`WAD` precision).
     *  @return movedAmount_  The amount of quote token moved (`WAD` precision).
     */
    function moveQuoteToken(
        uint256 maxAmount_,
        uint256 fromIndex_,
        uint256 toIndex_,
        uint256 expiry_
    ) external returns (uint256 fromBucketLP_, uint256 toBucketLP_, uint256 movedAmount_);

    /**
     *  @notice Called by lenders to claim collateral from a price bucket.
     *  @param  maxAmount_     The amount of collateral (`WAD` precision for `ERC20` pools, number of `NFT` tokens for `ERC721` pools) to claim.
     *  @param  index_         The bucket index from which collateral will be removed.
     *  @return removedAmount_ The amount of collateral removed (`WAD` precision).
     *  @return redeemedLP_    The amount of `LP` used for removing collateral amount (`WAD` precision).
     */
    function removeCollateral(
        uint256 maxAmount_,
        uint256 index_
    ) external returns (uint256 removedAmount_, uint256 redeemedLP_);

    /**
     *  @notice Called by lenders to remove an amount of credit at a specified price bucket.
     *  @param  maxAmount_     The max amount of quote token to be removed by a lender (`WAD` precision).
     *  @param  index_         The bucket index from which quote tokens will be removed.
     *  @return removedAmount_ The amount of quote token removed (`WAD` precision).
     *  @return redeemedLP_    The amount of `LP` used for removing quote tokens amount (`WAD` precision).
     */
    function removeQuoteToken(
        uint256 maxAmount_,
        uint256 index_
    ) external returns (uint256 removedAmount_, uint256 redeemedLP_);

    /********************************/
    /*** Interest update function ***/
    /********************************/

    /**
     *  @notice Called by actors to update pool interest rate (can be updated only once in a `12` hours period of time).
     */
    function updateInterest() external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool Settler Actions
 */
interface IPoolSettlerActions {

    /**
     *  @notice Called by actors to settle an amount of debt in a completed liquidation.
     *  @param  borrowerAddress_ Address of the auctioned borrower.
     *  @param  maxDepth_        Measured from `HPB`, maximum number of buckets deep to settle debt.
     *  @dev    `maxDepth_` is used to prevent unbounded iteration clearing large liquidations.
     */
    function settle(
        address borrowerAddress_,
        uint256 maxDepth_
    ) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool State
 */
interface IPoolState {

    /**
     *  @notice Returns details of an auction for a given borrower address.
     *  @param  borrower_     Address of the borrower that is liquidated.
     *  @return kicker_       Address of the kicker that is kicking the auction.
     *  @return bondFactor_   The factor used for calculating bond size.
     *  @return bondSize_     The bond amount in quote token terms.
     *  @return kickTime_     Time the liquidation was initiated.
     *  @return kickMomp_     Price where the average loan utilizes deposit, at the time when the loan is liquidated (kicked).
     *  @return neutralPrice_ `Neutral Price` of auction.
     *  @return head_         Address of the head auction.
     *  @return next_         Address of the next auction in queue.
     *  @return prev_         Address of the prev auction in queue.
     *  @return alreadyTaken_ True if take has been called on auction
     */
    function auctionInfo(address borrower_)
        external
        view
        returns (
            address kicker_,
            uint256 bondFactor_,
            uint256 bondSize_,
            uint256 kickTime_,
            uint256 kickMomp_,
            uint256 neutralPrice_,
            address head_,
            address next_,
            address prev_,
            bool alreadyTaken_
        );

    /**
     *  @notice Returns pool related debt values.
     *  @return debt_                Current amount of debt owed by borrowers in pool.
     *  @return accruedDebt_         Debt owed by borrowers based on last inflator snapshot.
     *  @return debtInAuction_       Total amount of debt in auction.
     *  @return t0Debt2ToCollateral_ t0debt accross all borrowers divided by their collateral, used in determining a collateralization weighted debt.
     */
    function debtInfo()
        external
        view
        returns (
            uint256 debt_,
            uint256 accruedDebt_,
            uint256 debtInAuction_,
            uint256 t0Debt2ToCollateral_
        );

    /**
     *  @notice Mapping of borrower addresses to `Borrower` structs.
     *  @dev    NOTE: Cannot use appended underscore syntax for return params since struct is used.
     *  @param  borrower_   Address of the borrower.
     *  @return t0Debt_     Amount of debt borrower would have had if their loan was the first debt drawn from the pool.
     *  @return collateral_ Amount of collateral that the borrower has deposited, in collateral token.
     *  @return t0Np_       t0 `Neutral Price`
     */
    function borrowerInfo(address borrower_)
        external
        view
        returns (
            uint256 t0Debt_,
            uint256 collateral_,
            uint256 t0Np_
        );

    /**
     *  @notice Mapping of buckets indexes to `Bucket` structs.
     *  @dev    NOTE: Cannot use appended underscore syntax for return params since struct is used.
     *  @param  index_               Bucket index.
     *  @return lpAccumulator_       Amount of `LP` accumulated in current bucket.
     *  @return availableCollateral_ Amount of collateral available in current bucket.
     *  @return bankruptcyTime_      Timestamp when bucket become insolvent, `0` if healthy.
     *  @return bucketDeposit_       Amount of quote tokens in bucket.
     *  @return bucketScale_         Bucket multiplier.
     */
    function bucketInfo(uint256 index_)
        external
        view
        returns (
            uint256 lpAccumulator_,
            uint256 availableCollateral_,
            uint256 bankruptcyTime_,
            uint256 bucketDeposit_,
            uint256 bucketScale_
        );

    /**
     *  @notice Mapping of burnEventEpoch to `BurnEvent` structs.
     *  @dev    Reserve auctions correspond to burn events.
     *  @param  burnEventEpoch_  Id of the current reserve auction.
     *  @return burnBlock_       Block in which a reserve auction started.
     *  @return totalInterest_   Total interest as of the reserve auction.
     *  @return totalBurned_     Total ajna tokens burned as of the reserve auction.
     */
    function burnInfo(uint256 burnEventEpoch_) external view returns (uint256, uint256, uint256);

    /**
     *  @notice Returns the latest `burnEventEpoch` of reserve auctions.
     *  @dev    If a reserve auction is active, it refers to the current reserve auction. If no reserve auction is active, it refers to the last reserve auction.
     *  @return Current `burnEventEpoch`.
     */
    function currentBurnEpoch() external view returns (uint256);

    /**
     *  @notice Returns information about the pool `EMA (Exponential Moving Average)` variables.
     *  @return debtColEma_   Debt squared to collateral Exponential, numerator to `TU` calculation.
     *  @return lupt0DebtEma_ Exponential of `LUP * t0 debt`, denominator to `TU` calculation
     *  @return debtEma_      Exponential debt moving average.
     *  @return depositEma_   sample of meaningful deposit Exponential, denominator to `MAU` calculation.
     */
    function emasInfo()
        external
        view
        returns (
            uint256 debtColEma_,
            uint256 lupt0DebtEma_,
            uint256 debtEma_,
            uint256 depositEma_
    );

    /**
     *  @notice Returns information about pool inflator.
     *  @return inflator_   Pool inflator value.
     *  @return lastUpdate_ The timestamp of the last `inflator` update.
     */
    function inflatorInfo()
        external
        view
        returns (
            uint256 inflator_,
            uint256 lastUpdate_
    );

    /**
     *  @notice Returns information about pool interest rate.
     *  @return interestRate_       Current interest rate in pool.
     *  @return interestRateUpdate_ The timestamp of the last interest rate update.
     */
    function interestRateInfo()
        external
        view
        returns (
            uint256 interestRate_,
            uint256 interestRateUpdate_
        );


    /**
     *  @notice Returns details about kicker balances.
     *  @param  kicker_    The address of the kicker to retrieved info for.
     *  @return claimable_ Amount of quote token kicker can claim / withdraw from pool at any time.
     *  @return locked_    Amount of quote token kicker locked in auctions (as bonds).
     */
    function kickerInfo(address kicker_)
        external
        view
        returns (
            uint256 claimable_,
            uint256 locked_
        );

    /**
     *  @notice Mapping of buckets indexes and owner addresses to `Lender` structs.
     *  @param  index_       Bucket index.
     *  @param  lender_      Address of the liquidity provider.
     *  @return lpBalance_   Amount of `LP` owner has in current bucket.
     *  @return depositTime_ Time the user last deposited quote token.
     */
    function lenderInfo(
        uint256 index_,
        address lender_
    )
        external
        view
        returns (
            uint256 lpBalance_,
            uint256 depositTime_
    );

    /**
     *  @notice Return the `LP` allowance a `LP` owner provided to a spender.
     *  @param  index_     Bucket index.
     *  @param  spender_   Address of the `LP` spender.
     *  @param  owner_     The initial owner of the `LP`.
     *  @return allowance_ Amount of `LP` spender can utilize.
     */
    function lpAllowance(
        uint256 index_,
        address spender_,
        address owner_
    ) external view returns (uint256 allowance_);

    /**
     *  @notice Returns information about a loan in the pool.
     *  @param  loanId_         Loan's id within loan heap. Max loan is position `1`.
     *  @return borrower_       Borrower address at the given position.
     *  @return thresholdPrice_ Borrower threshold price in pool.
     */
    function loanInfo(
        uint256 loanId_
    )
        external
        view
        returns (
            address borrower_,
            uint256 thresholdPrice_
    );

    /**
     *  @notice Returns information about pool loans.
     *  @return maxBorrower_       Borrower address with highest threshold price.
     *  @return maxThresholdPrice_ Highest threshold price in pool.
     *  @return noOfLoans_         Total number of loans.
     */
    function loansInfo()
        external
        view
        returns (
            address maxBorrower_,
            uint256 maxThresholdPrice_,
            uint256 noOfLoans_
    );

    /**
     *  @notice Returns information about pool reserves.
     *  @return liquidationBondEscrowed_ Amount of liquidation bond across all liquidators.
     *  @return reserveAuctionUnclaimed_ Amount of claimable reserves which has not been taken in the `Claimable Reserve Auction`.
     *  @return reserveAuctionKicked_    Time a `Claimable Reserve Auction` was last kicked.
     *  @return totalInterestEarned_     Total interest earned by all lenders in the pool
     */
    function reservesInfo()
        external
        view
        returns (
            uint256 liquidationBondEscrowed_,
            uint256 reserveAuctionUnclaimed_,
            uint256 reserveAuctionKicked_,
            uint256 totalInterestEarned_
    );

    /**
     *  @notice Returns the `pledgedCollateral` state variable.
     *  @return The total pledged collateral in the system, in WAD units.
     */
    function pledgedCollateral() external view returns (uint256);

    /**
     *  @notice Returns the total number of active auctions in pool.
     *  @return totalAuctions_ Number of active auctions.
     */
    function totalAuctionsInPool() external view returns (uint256);

     /**
     *  @notice Returns the `t0Debt` state variable.
     *  @dev    This value should be multiplied by inflator in order to calculate current debt of the pool.
     *  @return The total `t0Debt` in the system, in `WAD` units.
     */
    function totalT0Debt() external view returns (uint256);

    /**
     *  @notice Returns the `t0DebtInAuction` state variable.
     *  @dev    This value should be multiplied by inflator in order to calculate current debt in auction of the pool.
     *  @return The total `t0DebtInAuction` in the system, in `WAD` units.
     */
    function totalT0DebtInAuction() external view returns (uint256);

    /**
     *  @notice Mapping of addresses that can transfer `LP` to a given lender.
     *  @param  lender_     Lender that receives `LP`.
     *  @param  transferor_ Transferor that transfers `LP`.
     *  @return True if the transferor is approved by lender.
     */
    function approvedTransferors(
        address lender_,
        address transferor_
    ) external view returns (bool);

}

/*********************/
/*** State Structs ***/
/*********************/

/******************/
/*** Pool State ***/
/******************/

/// @dev Struct holding inflator state.
struct InflatorState {
    uint208 inflator;       // [WAD] pool's inflator
    uint48  inflatorUpdate; // [SEC] last time pool's inflator was updated
}

/// @dev Struct holding pool interest state.
struct InterestState {
    uint208 interestRate;        // [WAD] pool's interest rate
    uint48  interestRateUpdate;  // [SEC] last time pool's interest rate was updated (not before 12 hours passed)
    uint256 debt;                // [WAD] previous update's debt
    uint256 meaningfulDeposit;   // [WAD] previous update's meaningfulDeposit
    uint256 t0Debt2ToCollateral; // [WAD] utilization weight accumulator, tracks debt and collateral relationship accross borrowers 
    uint256 debtCol;             // [WAD] previous debt squared to collateral
    uint256 lupt0Debt;           // [WAD] previous LUP * t0 debt
}

/// @dev Struct holding pool EMAs state.
struct EmaState {
    uint256 debtEma;             // [WAD] sample of debt EMA, numerator to MAU calculation
    uint256 depositEma;          // [WAD] sample of meaningful deposit EMA, denominator to MAU calculation
    uint256 debtColEma;          // [WAD] debt squared to collateral EMA, numerator to TU calculation
    uint256 lupt0DebtEma;        // [WAD] EMA of LUP * t0 debt, denominator to TU calculation
    uint256 emaUpdate;           // [SEC] last time pool's EMAs were updated
}

/// @dev Struct holding pool balances state.
struct PoolBalancesState {
    uint256 pledgedCollateral; // [WAD] total collateral pledged in pool
    uint256 t0DebtInAuction;   // [WAD] Total debt in auction used to restrict LPB holder from withdrawing
    uint256 t0Debt;            // [WAD] Pool debt as if the whole amount was incurred upon the first loan
}

/// @dev Struct holding pool params (in memory only).
struct PoolState {
    uint8   poolType;             // pool type, can be ERC20 or ERC721
    uint256 t0Debt;               // [WAD] t0 debt in pool
    uint256 t0DebtInAuction;      // [WAD] t0 debt in auction within pool
    uint256 debt;                 // [WAD] total debt in pool, accrued in current block
    uint256 collateral;           // [WAD] total collateral pledged in pool
    uint256 inflator;             // [WAD] current pool inflator
    bool    isNewInterestAccrued; // true if new interest already accrued in current block
    uint256 rate;                 // [WAD] pool's current interest rate
    uint256 quoteTokenScale;      // [WAD] quote token scale of the pool. Same as quote token dust.
}

/*********************/
/*** Buckets State ***/
/*********************/

/// @dev Struct holding lender state.
struct Lender {
    uint256 lps;         // [WAD] Lender LP accumulator
    uint256 depositTime; // timestamp of last deposit
}

/// @dev Struct holding bucket state.
struct Bucket {
    uint256 lps;                        // [WAD] Bucket LP accumulator
    uint256 collateral;                 // [WAD] Available collateral tokens deposited in the bucket
    uint256 bankruptcyTime;             // Timestamp when bucket become insolvent, 0 if healthy
    mapping(address => Lender) lenders; // lender address to Lender struct mapping
}

/**********************/
/*** Deposits State ***/
/**********************/

/// @dev Struct holding deposits (Fenwick) values and scaling.
struct DepositsState {
    uint256[8193] values;  // Array of values in the FenwickTree.
    uint256[8193] scaling; // Array of values which scale (multiply) the FenwickTree accross indexes.
}

/*******************/
/*** Loans State ***/
/*******************/

/// @dev Struct holding loans state.
struct LoansState {
    Loan[] loans;
    mapping (address => uint)     indices;   // borrower address => loan index mapping
    mapping (address => Borrower) borrowers; // borrower address => Borrower struct mapping
}

/// @dev Struct holding loan state.
struct Loan {
    address borrower;       // borrower address
    uint96  thresholdPrice; // [WAD] Loan's threshold price.
}

/// @dev Struct holding borrower state.
struct Borrower {
    uint256 t0Debt;     // [WAD] Borrower debt time-adjusted as if it was incurred upon first loan of pool.
    uint256 collateral; // [WAD] Collateral deposited by borrower.
    uint256 t0Np;       // [WAD] Neutral Price time-adjusted as if it was incurred upon first loan of pool.
}

/**********************/
/*** Auctions State ***/
/**********************/

/// @dev Struct holding pool auctions state.
struct AuctionsState {
    uint96  noOfAuctions;                         // total number of auctions in pool
    address head;                                 // first address in auction queue
    address tail;                                 // last address in auction queue
    uint256 totalBondEscrowed;                    // [WAD] total amount of quote token posted as auction kick bonds
    mapping(address => Liquidation) liquidations; // mapping of borrower address and auction details
    mapping(address => Kicker)      kickers;      // mapping of kicker address and kicker balances
}

/// @dev Struct holding liquidation state.
struct Liquidation {
    address kicker;       // address that initiated liquidation
    uint96  bondFactor;   // [WAD] bond factor used to start liquidation
    uint96  kickTime;     // timestamp when liquidation was started
    address prev;         // previous liquidated borrower in auctions queue
    uint96  kickMomp;     // [WAD] Momp when liquidation was started
    address next;         // next liquidated borrower in auctions queue
    uint160 bondSize;     // [WAD] liquidation bond size
    uint96  neutralPrice; // [WAD] Neutral Price when liquidation was started
    bool    alreadyTaken; // true if take has been called on auction
}

/// @dev Struct holding kicker state.
struct Kicker {
    uint256 claimable; // [WAD] kicker's claimable balance
    uint256 locked;    // [WAD] kicker's balance of tokens locked in auction bonds
}

/******************************/
/*** Reserve Auctions State ***/
/******************************/

/// @dev Struct holding reserve auction state.
struct ReserveAuctionState {
    uint256 kicked;                            // Time a Claimable Reserve Auction was last kicked.
    uint256 unclaimed;                         // [WAD] Amount of claimable reserves which has not been taken in the Claimable Reserve Auction.
    uint256 latestBurnEventEpoch;              // Latest burn event epoch.
    uint256 totalAjnaBurned;                   // [WAD] Total ajna burned in the pool.
    uint256 totalInterestEarned;               // [WAD] Total interest earned by all lenders in the pool.
    mapping (uint256 => BurnEvent) burnEvents; // Mapping burnEventEpoch => BurnEvent.
}

/// @dev Struct holding burn event state.
struct BurnEvent {
    uint256 timestamp;     // time at which the burn event occured
    uint256 totalInterest; // [WAD] current pool interest accumulator `PoolCommons.accrueInterest().newInterest`
    uint256 totalBurned;   // [WAD] burn amount accumulator
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool Taker Actions
 */
interface IPoolTakerActions {

    /**
     *  @notice Called by actors to use quote token to arb higher-priced deposit off the book.
     *  @param  borrowerAddress_  Address of the borower take is being called upon.
     *  @param  depositTake_      If `true` then the take will happen at an auction price equal with bucket price. Auction price is used otherwise.
     *  @param  index_            Index of a bucket, likely the `HPB`, in which collateral will be deposited.
     */
    function bucketTake(
        address borrowerAddress_,
        bool    depositTake_,
        uint256 index_
    ) external;

    /**
     *  @notice Called by actors to purchase collateral from the auction in exchange for quote token.
     *  @param  borrowerAddress_  Address of the borower take is being called upon.
     *  @param  maxAmount_        Max amount of collateral that will be taken from the auction (`WAD` precision for `ERC20` pools, max number of `NFT`s for `ERC721` pools).
     *  @param  callee_           Identifies where collateral should be sent and where quote token should be obtained.
     *  @param  data_             If provided, take will assume the callee implements `IERC*Taker`.  Take will send collateral to 
     *                            callee before passing this data to `IERC*Taker.atomicSwapCallback`.  If not provided, 
     *                            the callback function will not be invoked.
     */
    function take(
        address        borrowerAddress_,
        uint256        maxAmount_,
        address        callee_,
        bytes calldata data_
    ) external;

    /***********************/
    /*** Reserve Auction ***/
    /***********************/

    /**
     *  @notice Purchases claimable reserves during a `CRA` using `Ajna` token.
     *  @param  maxAmount_ Maximum amount of quote token to purchase at the current auction price (`WAD` precision).
     *  @return amount_    Actual amount of reserves taken (`WAD` precision).
     */
    function takeReserves(
        uint256 maxAmount_
    ) external returns (uint256 amount_);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { IPool } from '../IPool.sol';

import { IERC721PoolBorrowerActions } from './IERC721PoolBorrowerActions.sol';
import { IERC721PoolLenderActions }   from './IERC721PoolLenderActions.sol';
import { IERC721PoolImmutables }      from './IERC721PoolImmutables.sol';
import { IERC721PoolState }           from './IERC721PoolState.sol';
import { IERC721PoolEvents }          from './IERC721PoolEvents.sol';
import { IERC721PoolErrors }          from './IERC721PoolErrors.sol';

/**
 * @title ERC721 Pool
 */
interface IERC721Pool is
    IPool,
    IERC721PoolLenderActions,
    IERC721PoolBorrowerActions,
    IERC721PoolState,
    IERC721PoolImmutables,
    IERC721PoolEvents,
    IERC721PoolErrors
{

    /**
     *  @notice Initializes a new pool, setting initial state variables.
     *  @param  tokenIds_  Enumerates `tokenIds_` to be allowed in the pool.
     *  @param  rate_      Initial interest rate of the pool.
     */
    function initialize(
        uint256[] memory tokenIds_,
        uint256 rate_
    ) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title ERC721 Pool Borrower Actions
 */
interface IERC721PoolBorrowerActions {

    /**
     *  @notice Called by borrowers to add collateral to the pool and/or borrow quote from the pool.
     *  @dev    Can be called by borrowers with either `0` `amountToBorrow_` or `0` `collateralToPledge`_, if borrower only wants to take a single action. 
     *  @param  borrower_         The address of borrower to drawDebt for.
     *  @param  amountToBorrow_   The amount of quote tokens to borrow (`WAD` precision).
     *  @param  limitIndex_       Lower bound of `LUP` change (if any) that the borrower will tolerate from a creating or modifying position.
     *  @param  tokenIdsToPledge_ Array of token ids to be pledged to the pool.
     */
    function drawDebt(
        address borrower_,
        uint256 amountToBorrow_,
        uint256 limitIndex_,
        uint256[] calldata tokenIdsToPledge_
    ) external;

    /**
     *  @notice Called by borrowers to repay borrowed quote to the pool, and/or pull collateral form the pool.
     *  @dev    Can be called by borrowers with either `0` `maxQuoteTokenAmountToRepay_` or `0` `collateralAmountToPull_`, if borrower only wants to take a single action. 
     *  @param  borrowerAddress_            The borrower whose loan is being interacted with.
     *  @param  maxQuoteTokenAmountToRepay_ The max amount of quote tokens to repay (`WAD` precision).
     *  @param  noOfNFTsToPull_             The integer number of `NFT` collateral to be puled from the pool.
     *  @param  recipient_                  The address to receive amount of pulled collateral.
     *  @param  limitIndex_                 Ensures `LUP` has not moved far from state when borrower pulls collateral.
     */
    function repayDebt(
        address borrowerAddress_,
        uint256 maxQuoteTokenAmountToRepay_,
        uint256 noOfNFTsToPull_,
        address recipient_,
        uint256 limitIndex_
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title ERC721 Pool Errors
 */
interface IERC721PoolErrors {

    /**
     *  @notice User attempted to add an `NFT` to the pool with a `tokenId` outside of the allowed subset.
     */
    error OnlySubset();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title ERC721 Pool Events
 */
interface IERC721PoolEvents {

    /**
     *  @notice Emitted when actor adds claimable collateral to a bucket.
     *  @param  actor     Recipient that added collateral.
     *  @param  index     Index at which collateral were added.
     *  @param  tokenIds  Array of tokenIds to be added to the pool.
     *  @param  lpAwarded Amount of LP awarded for the deposit (`WAD` precision).
     */
    event AddCollateralNFT(
        address indexed actor,
        uint256 indexed index,
        uint256[] tokenIds,
        uint256   lpAwarded
    );

    /**
     *  @notice Emitted when actor adds claimable collateral to a bucket.
     *  @param  actor            Recipient that added collateral.
     *  @param  collateralMerged Amount of collateral merged (`WAD` precision).
     *  @param  toIndexLps       If non-zero, amount of LP in toIndex when collateral is merged into bucket (`WAD` precision). If 0, no collateral is merged.
     */
    event MergeOrRemoveCollateralNFT(
        address indexed actor,
        uint256 collateralMerged,
        uint256 toIndexLps
    );

    /**
     *  @notice Emitted when borrower draws debt from the pool or adds collateral to the pool.
     *  @param  borrower          `msg.sender`.
     *  @param  amountBorrowed    Amount of quote tokens borrowed from the pool (`WAD` precision).
     *  @param  tokenIdsPledged   Array of tokenIds to be added to the pool.
     *  @param  lup               LUP after borrow.
     */
    event DrawDebtNFT(
        address indexed borrower,
        uint256   amountBorrowed,
        uint256[] tokenIdsPledged,
        uint256   lup
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { IPoolFactory } from '../IPoolFactory.sol';

/**
 *  @title ERC721 Pool Factory
 *  @dev   Used to deploy non fungible pools.
 */
interface IERC721PoolFactory is IPoolFactory {

    /**************/
    /*** Errors ***/
    /**************/

    /**
     *  @notice User tried to deploy a pool with an array of `tokenIds` that weren't sorted, or contained duplicates.
     */
    error TokenIdSubsetInvalid();

    /**************************/
    /*** External Functions ***/
    /**************************/

    /**
     *  @notice Deploys a cloned pool for the given collateral and quote token.
     *  @dev    Pool must not already exist, and must use `WETH` instead of `ETH`.
     *  @param  collateral_   Address of `NFT` collateral token.
     *  @param  quote_        Address of `NFT` quote token.
     *  @param  tokenIds_     Ids of subset `NFT` tokens.
     *  @param  interestRate_ Initial interest rate of the pool.
     *  @return pool_         Address of the newly created pool.
     */
    function deployPool(
        address collateral_,
        address quote_,
        uint256[] memory tokenIds_,
        uint256 interestRate_
    ) external returns (address pool_);

    /**
     *  @notice User attempted to make pool with non supported `NFT` contract as collateral.
     */
    error NFTNotSupported();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title ERC721 Pool Immutables
 */
interface IERC721PoolImmutables{

    /**
     *  @notice Returns the type of `NFT` pool.
     *  @return `True` if `NTF` pool is a subset pool.
     */
    function isSubset() external view returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title ERC721 Pool Lender Actions
 */
interface IERC721PoolLenderActions {

    /**
     *  @notice Deposit claimable collateral into a specified bucket.
     *  @param  tokenIds_ Array of token ids to deposit.
     *  @param  index_    The bucket index to which collateral will be deposited.
     *  @param  expiry_   Timestamp after which this transaction will revert, preventing inclusion in a block with unfavorable price.
     *  @return bucketLP_ The amount of `LP `changed for the added collateral.
     */
    function addCollateral(
        uint256[] calldata tokenIds_,
        uint256 index_,
        uint256 expiry_
    ) external returns (uint256 bucketLP_);

    /**
     *  @notice Merge collateral accross a number of buckets, `removalIndexes_` reconstitute an `NFT`.
     *  @param  removalIndexes_   Array of bucket indexes to remove all collateral that the caller has ownership over.
     *  @param  noOfNFTsToRemove_ Intergral number of `NFT`s to remove if collateral amount is met `noOfNFTsToRemove_`, else merge at bucket index, `toIndex_`.
     *  @param  toIndex_          The bucket index to which merge collateral into.
     *  @return collateralMerged_ Amount of collateral merged into `toIndex_` (`WAD` precision).
     *  @return bucketLP_         If non-zero, amount of `LP` in `toIndex_` when collateral is merged into bucket (`WAD` precision). If `0`, no collateral is merged.
     */
    function mergeOrRemoveCollateral(
        uint256[] calldata removalIndexes_,
        uint256 noOfNFTsToRemove_,
        uint256 toIndex_
    ) external returns (uint256 collateralMerged_, uint256 bucketLP_);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title ERC721 Pool State
 */
interface IERC721PoolState {

    /**
     *  @notice Check if a token id is allowed as collateral in pool.
     *  @param  tokenId The token id to check.
     *  @return allowed `True` if token id is allowed in pool.
     */
    function tokenIdsAllowed(
        uint256 tokenId
    ) external view returns (bool allowed);

    /**
     *  @notice Returns the token id of an `NFT` pledged by a borrower with a given index.
     *  @param  borrower The address of borrower that pledged the `NFT`.
     *  @param  nftIndex `NFT` index in borrower's pledged token ids array.
     *  @return tokenId  Token id of the `NFT`.
     */
    function borrowerTokenIds(
        address borrower,
        uint256 nftIndex
    ) external view returns (uint256 tokenId);

    /**
     *  @notice Returns the token id of an `NFT` added in pool bucket (claimable from pool).
     *  @param  nftIndex `NFT` index in bucket's token ids array.
     *  @return tokenId  Token id of the `NFT`.
     */
    function bucketTokenIds(
        uint256 nftIndex
    ) external view returns (uint256 tokenId);

    /**
     *  @notice Returns the total `NFT` pledged by a borrower.
     *  @param  borrower_ The address of borrower that pledged the `NFT`.
     *  @return Total number of `NFT`s pledged by borrower.
     */
    function totalBorrowerTokens(
        address borrower_
    ) external view returns (uint256);

    /**
     *  @notice Returns the total `NFT` added in pool bucket.
     *  @return Total number of `NFT`s in buckets (claimable from pool).
     */
    function totalBucketTokens() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IERC721Taker {
    /**
     *  @notice Called by `Pool.take` allowing a taker to externally swap collateral for quote token.
     *  @param  tokenIds       Identifies the `NFT`s being taken.
     *  @param  quoteAmountDue Denormalized amount of quote token required to purchase `collateralAmount` at the 
     *                         current auction price (`WAD` precision).
     *  @param  data           Taker-provided calldata passed from taker's invocation to their callback.
     */
    function atomicSwapCallback(
        uint256[] memory tokenIds, 
        uint256          quoteAmountDue,
        bytes calldata   data
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import {
    AuctionsState,
    Borrower,
    Bucket,
    DepositsState,
    LoansState,
    PoolState
}                   from '../../interfaces/pool/commons/IPoolState.sol';
import {
    DrawDebtResult,
    RepayDebtResult
}                   from '../../interfaces/pool/commons/IPoolInternals.sol';

import {
    _borrowFeeRate,
    _priceAt,
    _isCollateralized
}                           from '../helpers/PoolHelper.sol';
import { 
    _revertIfPriceDroppedBelowLimit,
    _revertOnMinDebt
}                           from '../helpers/RevertsHelper.sol';

import { Buckets }  from '../internal/Buckets.sol';
import { Deposits } from '../internal/Deposits.sol';
import { Loans }    from '../internal/Loans.sol';
import { Maths }    from '../internal/Maths.sol';

import { SettlerActions } from './SettlerActions.sol';

/**
    @title  BorrowerActions library
    @notice External library containing logic for for pool actors:
            - `Borrowers`: pledge collateral and draw debt; repay debt and pull collateral
 */
library BorrowerActions {

    /*************************/
    /*** Local Var Structs ***/
    /*************************/

    /// @dev Struct used for `drawDebt` function local vars.
    struct DrawDebtLocalVars {
        bool    borrow;                // true if borrow action
        uint256 borrowerDebt;          // [WAD] borrower's accrued debt
        uint256 compensatedCollateral; // [WAD] amount of borrower collateral that is compensated with LP (NFTs only)
        uint256 t0BorrowAmount;        // [WAD] t0 amount to borrow
        uint256 t0DebtChange;          // [WAD] additional t0 debt resulted from draw debt action
        bool    pledge;                // true if pledge action
        bool    stampT0Np;             // true if loan's t0 neutral price should be restamped (when drawing debt or pledge settles auction)
    }

    /// @dev Struct used for `repayDebt` function local vars.
    struct RepayDebtLocalVars {
        uint256 borrowerDebt;          // [WAD] borrower's accrued debt
        uint256 compensatedCollateral; // [WAD] amount of borrower collateral that is compensated with LP (NFTs only)
        bool    pull;                  // true if pull action
        bool    repay;                 // true if repay action
        bool    stampT0Np;             // true if loan's t0 neutral price should be restamped (when repay settles auction or pull collateral)
        uint256 t0DebtInAuctionChange; // [WAD] t0 change amount of debt after repayment
        uint256 t0RepaidDebt;          // [WAD] t0 debt repaid
    }

    /**************/
    /*** Events ***/
    /**************/

    // See `IPoolEvents` for descriptions
    event LoanStamped(address indexed borrowerAddress);

    /**************/
    /*** Errors ***/
    /**************/

    // See `IPoolErrors` for descriptions
    error AuctionActive();
    error BorrowerNotSender();
    error BorrowerUnderCollateralized();
    error InsufficientLiquidity();
    error InsufficientCollateral();
    error InvalidAmount();
    error LimitIndexExceeded();
    error NoDebt();

    /***************************/
    /***  External Functions ***/
    /***************************/

    /**
     *  @notice See `IERC20PoolBorrowerActions` and `IERC721PoolBorrowerActions` for descriptions
     *  @dev    === Write state ===
     *  @dev    - `SettlerActions._settleAuction` (`_removeAuction`):
     *  @dev      decrement kicker locked accumulator, increment kicker claimable accumumlator
     *  @dev      decrement auctions count accumulator
     *  @dev      update auction queue state
     *  @dev    - `Loans.update` (`_upsert`):
     *  @dev      insert or update loan in loans array
     *  @dev      remove loan from loans array
     *  @dev      update borrower in `address => borrower` mapping
     *  @dev    === Reverts on ===
     *  @dev    not enough quote tokens available `InsufficientLiquidity()`
     *  @dev    borrower not sender `BorrowerNotSender()`
     *  @dev    borrower debt less than pool min debt `AmountLTMinDebt()`
     *  @dev    limit price reached `LimitIndexExceeded()`
     *  @dev    borrower cannot draw more debt `BorrowerUnderCollateralized()`
     *  @dev    === Emit events ===
     *  @dev    - `SettlerActions._settleAuction`: `AuctionNFTSettle` or `AuctionSettle`
     */
    function drawDebt(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        LoansState    storage loans_,
        PoolState calldata poolState_,
        uint256 maxAvailable_,
        address borrowerAddress_,
        uint256 amountToBorrow_,
        uint256 limitIndex_,
        uint256 collateralToPledge_
    ) external returns (
        DrawDebtResult memory result_
    ) {
        // revert if not enough pool balance to borrow
        if (amountToBorrow_ > maxAvailable_) revert InsufficientLiquidity();

        DrawDebtLocalVars memory vars;
        vars.pledge = collateralToPledge_ != 0;
        vars.borrow = amountToBorrow_ != 0;

        // revert if no amount to pledge or borrow
        if (!vars.pledge && !vars.borrow) revert InvalidAmount();

        Borrower memory borrower = loans_.borrowers[borrowerAddress_];

        vars.borrowerDebt = Maths.wmul(borrower.t0Debt, poolState_.inflator);

        result_.inAuction           = _inAuction(auctions_, borrowerAddress_);
        result_.debtPreAction       = borrower.t0Debt;
        result_.collateralPreAction = borrower.collateral;
        result_.t0PoolDebt          = poolState_.t0Debt;
        result_.poolDebt            = poolState_.debt;
        result_.poolCollateral      = poolState_.collateral;
        result_.remainingCollateral = borrower.collateral;

        if (vars.pledge) {
            // add new amount of collateral to pledge to borrower balance
            borrower.collateral  += collateralToPledge_;

            result_.remainingCollateral += collateralToPledge_;
            result_.newLup              = Deposits.getLup(deposits_, result_.poolDebt);

            // if loan is auctioned and becomes collateralized by newly pledged collateral then settle auction
            if (
                result_.inAuction &&
                _isCollateralized(vars.borrowerDebt, borrower.collateral, result_.newLup, poolState_.poolType)
            ) {
                // stamp borrower t0Np when exiting from auction
                vars.stampT0Np = true;

                // borrower becomes re-collateralized, entire borrower debt is removed from pool auctions debt accumulator
                result_.inAuction             = false;
                result_.settledAuction        = true;
                result_.t0DebtInAuctionChange = borrower.t0Debt;

                // settle auction and update borrower's collateral with value after settlement
                (
                    result_.remainingCollateral,
                    vars.compensatedCollateral
                ) = SettlerActions._settleAuction(
                    auctions_,
                    buckets_,
                    deposits_,
                    borrowerAddress_,
                    borrower.collateral,
                    poolState_.poolType
                );
                result_.poolCollateral -= vars.compensatedCollateral;

                borrower.collateral = result_.remainingCollateral;                
            }

            // add new amount of collateral to pledge to pool balance
            result_.poolCollateral += collateralToPledge_;
        }

        if (vars.borrow) {
            // only intended recipient can borrow quote
            if (borrowerAddress_ != msg.sender) revert BorrowerNotSender();

            // an auctioned borrower in not allowed to draw more debt (even if collateralized at the new LUP) if auction is not settled
            if (result_.inAuction) revert AuctionActive();

            vars.t0BorrowAmount = Maths.ceilWdiv(amountToBorrow_, poolState_.inflator);

            // t0 debt change is t0 amount to borrow plus the origination fee
            vars.t0DebtChange = Maths.wmul(vars.t0BorrowAmount, _borrowFeeRate(poolState_.rate) + Maths.WAD);

            borrower.t0Debt += vars.t0DebtChange;

            vars.borrowerDebt = Maths.wmul(borrower.t0Debt, poolState_.inflator);

            // check that drawing debt doesn't leave borrower debt under pool min debt amount
            _revertOnMinDebt(
                loans_,
                result_.poolDebt,
                vars.borrowerDebt,
                poolState_.quoteTokenScale
            );

            // add debt change to pool's debt
            result_.t0PoolDebt += vars.t0DebtChange;
            result_.poolDebt   = Maths.wmul(result_.t0PoolDebt, poolState_.inflator);
            result_.newLup     = Deposits.getLup(deposits_, result_.poolDebt);

            // revert if borrow drives LUP price under the specified price limit
            _revertIfPriceDroppedBelowLimit(result_.newLup, limitIndex_);

            // use new lup to check borrow action won't push borrower into a state of under-collateralization
            // this check also covers the scenario when loan is already auctioned
            if (!_isCollateralized(vars.borrowerDebt, borrower.collateral, result_.newLup, poolState_.poolType)) {
                revert BorrowerUnderCollateralized();
            }

            // stamp borrower t0Np when draw debt
            vars.stampT0Np = true;
        }

        // update loan state
        Loans.update(
            loans_,
            auctions_,
            deposits_,
            borrower,
            borrowerAddress_,
            result_.poolDebt,
            poolState_.rate,
            result_.newLup,
            result_.inAuction,
            vars.stampT0Np
        );

        result_.debtPostAction       = borrower.t0Debt;
        result_.collateralPostAction = borrower.collateral;
    }

    /**
     *  @notice See `IERC20PoolBorrowerActions` and `IERC721PoolBorrowerActions` for descriptions
     *  @dev    === Write state ===
     *  @dev    - `SettlerActions._settleAuction` (`_removeAuction`):
     *  @dev      decrement kicker locked accumulator, increment kicker claimable accumumlator
     *  @dev      decrement auctions count accumulator
     *  @dev      update auction queue state
     *  @dev    - `Loans.update` (`_upsert`):
     *  @dev      insert or update loan in loans array
     *  @dev      remove loan from loans array
     *  @dev      update borrower in `address => borrower` mapping
     *  @dev    === Reverts on ===
     *  @dev    no debt to repay `NoDebt()`
     *  @dev    borrower debt less than pool min debt `AmountLTMinDebt()`
     *  @dev    borrower not sender `BorrowerNotSender()`
     *  @dev    not enough collateral to pull `InsufficientCollateral()`
     *  @dev    limit price reached `LimitIndexExceeded()`
     *  @dev    === Emit events ===
     *  @dev    - `SettlerActions._settleAuction`: `AuctionNFTSettle` or `AuctionSettle`
     */
    function repayDebt(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        LoansState    storage loans_,
        PoolState calldata poolState_,
        address borrowerAddress_,
        uint256 maxQuoteTokenAmountToRepay_,
        uint256 collateralAmountToPull_,
        uint256 limitIndex_
    ) external returns (
        RepayDebtResult memory result_
    ) {
        RepayDebtLocalVars memory vars;
        vars.repay = maxQuoteTokenAmountToRepay_ != 0;
        vars.pull  = collateralAmountToPull_     != 0;

        // revert if no amount to pull or repay
        if (!vars.repay && !vars.pull) revert InvalidAmount();

        Borrower memory borrower = loans_.borrowers[borrowerAddress_];

        vars.borrowerDebt = Maths.wmul(borrower.t0Debt, poolState_.inflator);

        result_.inAuction           = _inAuction(auctions_, borrowerAddress_);
        result_.debtPreAction       = borrower.t0Debt;
        result_.collateralPreAction = borrower.collateral;
        result_.t0PoolDebt          = poolState_.t0Debt;
        result_.poolDebt            = poolState_.debt;
        result_.poolCollateral      = poolState_.collateral;
        result_.remainingCollateral = borrower.collateral;

        if (vars.repay) {
            if (borrower.t0Debt == 0) revert NoDebt();

            if (maxQuoteTokenAmountToRepay_ == type(uint256).max) {
                vars.t0RepaidDebt = borrower.t0Debt;
            } else {
                vars.t0RepaidDebt = Maths.min(
                    borrower.t0Debt,
                    Maths.floorWdiv(maxQuoteTokenAmountToRepay_, poolState_.inflator)
                );
            }

            result_.t0PoolDebt        -= vars.t0RepaidDebt;
            result_.poolDebt          = Maths.wmul(result_.t0PoolDebt, poolState_.inflator);
            result_.quoteTokenToRepay = Maths.ceilWmul(vars.t0RepaidDebt,  poolState_.inflator);

            vars.borrowerDebt = Maths.wmul(borrower.t0Debt - vars.t0RepaidDebt, poolState_.inflator);

            // check that paying the loan doesn't leave borrower debt under min debt amount
            _revertOnMinDebt(
                loans_,
                result_.poolDebt,
                vars.borrowerDebt,
                poolState_.quoteTokenScale
            );

            result_.newLup = Deposits.getLup(deposits_, result_.poolDebt);

            // if loan is auctioned and becomes collateralized by repaying debt then settle auction
            if (result_.inAuction) {
                if (_isCollateralized(vars.borrowerDebt, borrower.collateral, result_.newLup, poolState_.poolType)) {
                     // stamp borrower t0Np when exiting from auction
                    vars.stampT0Np = true;

                    // borrower becomes re-collateralized, entire borrower debt is removed from pool auctions debt accumulator
                    result_.inAuction             = false;
                    result_.settledAuction        = true;
                    result_.t0DebtInAuctionChange = borrower.t0Debt;

                    // settle auction and update borrower's collateral with value after settlement
                    (
                        result_.remainingCollateral,
                        vars.compensatedCollateral
                    ) = SettlerActions._settleAuction(
                        auctions_,
                        buckets_,
                        deposits_,
                        borrowerAddress_,
                        borrower.collateral,
                        poolState_.poolType
                    );
                    result_.poolCollateral -= vars.compensatedCollateral;

                    borrower.collateral = result_.remainingCollateral;
                } else {
                    // partial repay, remove only the paid debt from pool auctions debt accumulator
                    result_.t0DebtInAuctionChange = vars.t0RepaidDebt;
                }
            }

            borrower.t0Debt -= vars.t0RepaidDebt;
        }

        if (vars.pull) {
            // only intended recipient can pull collateral
            if (borrowerAddress_ != msg.sender) revert BorrowerNotSender();

            // an auctioned borrower in not allowed to pull collateral (even if collateralized at the new LUP) if auction is not settled
            if (result_.inAuction) revert AuctionActive();

            // calculate LUP only if it wasn't calculated in repay action
            if (!vars.repay) result_.newLup = Deposits.getLup(deposits_, result_.poolDebt);

            _revertIfPriceDroppedBelowLimit(result_.newLup, limitIndex_);

            uint256 encumberedCollateral = Maths.wdiv(vars.borrowerDebt, result_.newLup);
            if (
                borrower.t0Debt != 0 && encumberedCollateral == 0 || // case when small amount of debt at a high LUP results in encumbered collateral calculated as 0
                borrower.collateral < encumberedCollateral ||
                borrower.collateral - encumberedCollateral < collateralAmountToPull_
            ) revert InsufficientCollateral();

            // stamp borrower t0Np when pull collateral action
            vars.stampT0Np = true;

            borrower.collateral -= collateralAmountToPull_;

            result_.poolCollateral -= collateralAmountToPull_;
        }

        // update loan state
        Loans.update(
            loans_,
            auctions_,
            deposits_,
            borrower,
            borrowerAddress_,
            result_.poolDebt,
            poolState_.rate,
            result_.newLup,
            result_.inAuction,
            vars.stampT0Np
        );

        result_.debtPostAction       = borrower.t0Debt;
        result_.collateralPostAction = borrower.collateral;
    }

    /**
     *  @notice See `IPoolBorrowerActions` for descriptions
     *  @dev    === Write state ===
     *  @dev    - `Loans.update` (`_upsert`):
     *  @dev      insert or update loan in loans array
     *  @dev      remove loan from loans array
     *  @dev      update borrower in `address => borrower` mapping
     *  @dev    === Reverts on ===
     *  @dev    auction active `AuctionActive()`
     *  @dev    loan not fully collateralized `BorrowerUnderCollateralized()`
     *  @dev    === Emit events ===
     *  @dev    - `LoanStamped`
     */
    function stampLoan(
        AuctionsState storage auctions_,
        DepositsState storage deposits_,
        LoansState    storage loans_,
        PoolState calldata poolState_
    ) external returns (
        uint256 newLup_
    ) {
        // revert if loan is in auction
        if (_inAuction(auctions_, msg.sender)) revert AuctionActive();

        Borrower memory borrower = loans_.borrowers[msg.sender];

        newLup_ = Deposits.getLup(deposits_, poolState_.debt);

        // revert if loan is not fully collateralized at current LUP
        if (
            !_isCollateralized(
                Maths.wmul(borrower.t0Debt, poolState_.inflator), // current borrower debt
                borrower.collateral,
                newLup_,
                poolState_.poolType
            )
        ) revert BorrowerUnderCollateralized();

        // update loan state to stamp Neutral Price
        Loans.update(
            loans_,
            auctions_,
            deposits_,
            borrower,
            msg.sender,
            poolState_.debt,
            poolState_.rate,
            newLup_,
            false,          // loan not in auction
            true            // stamp Neutral Price of the loan
        );

        emit LoanStamped(msg.sender);
    }

    /**********************/
    /*** View Functions ***/
    /**********************/

    /**
     *  @notice Returns `true` if borrower is in auction.
     *  @dev    Used to accuratley increment and decrement `t0DebtInAuction` accumulator.
     *  @param  auctions_ Struct for pool auctions state.
     *  @param  borrower_ Borrower address to check auction status for.
     *  @return `True` if borrower is in auction.
     */
    function _inAuction(
        AuctionsState storage auctions_,
        address borrower_
    ) internal view returns (bool) {
        return auctions_.liquidations[borrower_].kickTime != 0;
    }

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { Math }     from '@openzeppelin/contracts/utils/math/Math.sol';
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { PoolType } from '../../interfaces/pool/IPool.sol';

import {
    AuctionsState,
    Borrower,
    Bucket,
    DepositsState,
    Kicker,
    Lender,
    Liquidation,
    LoansState,
    PoolState,
    ReserveAuctionState
}                             from '../../interfaces/pool/commons/IPoolState.sol';
import {
    KickResult,
    KickReserveAuctionParams
}                             from '../../interfaces/pool/commons/IPoolInternals.sol';

import {
    MAX_NEUTRAL_PRICE,
    _auctionPrice,
    _bondParams,
    _bpf,
    _claimableReserves,
    _isCollateralized,
    _priceAt,
    _reserveAuctionPrice
}                                   from '../helpers/PoolHelper.sol';
import {
    _revertIfPriceDroppedBelowLimit
}                                   from '../helpers/RevertsHelper.sol';

import { Buckets }  from '../internal/Buckets.sol';
import { Deposits } from '../internal/Deposits.sol';
import { Loans }    from '../internal/Loans.sol';
import { Maths }    from '../internal/Maths.sol';

/**
    @title  Auctions kicker actions library
    @notice External library containing kicker actions involving auctions within pool:
            - kick undercollateralized loans; start reserve auctions
 */
library KickerActions {

    /*************************/
    /*** Local Var Structs ***/
    /*************************/

    /// @dev Struct used for `kick` function local vars.
    struct KickLocalVars {
        uint256 borrowerDebt;       // [WAD] the accrued debt of kicked borrower
        uint256 borrowerCollateral; // [WAD] amount of kicked borrower collateral
        uint256 neutralPrice;       // [WAD] neutral price recorded in kick action
        uint256 noOfLoans;          // number of loans and auctions in pool (used to calculate MOMP)
        uint256 momp;               // [WAD] MOMP of kicked auction
        uint256 bondFactor;         // [WAD] bond factor of kicked auction
        uint256 bondSize;           // [WAD] bond size of kicked auction
        uint256 t0KickPenalty;      // [WAD] t0 debt added as kick penalty
        uint256 kickPenalty;        // [WAD] current debt added as kick penalty
    }

    /// @dev Struct used for `kickWithDeposit` function local vars.
    struct KickWithDepositLocalVars {
        uint256 amountToDebitFromDeposit; // [WAD] the amount of quote tokens used to kick and debited from lender deposit
        uint256 bucketCollateral;         // [WAD] amount of collateral in bucket
        uint256 bucketDeposit;            // [WAD] amount of quote tokens in bucket
        uint256 bucketLP;                 // [WAD] LP of the bucket
        uint256 bucketPrice;              // [WAD] bucket price
        uint256 bucketScale;              // [WAD] bucket scales
        uint256 bucketUnscaledDeposit;    // [WAD] unscaled amount of quote tokens in bucket
        uint256 lenderLP;                 // [WAD] LP of lender in bucket
        uint256 redeemedLP;               // [WAD] LP used by kick action
    }

    /**************/
    /*** Events ***/
    /**************/

    // See `IPoolEvents` for descriptions
    event Kick(address indexed borrower, uint256 debt, uint256 collateral, uint256 bond);
    event RemoveQuoteToken(address indexed lender, uint256 indexed price, uint256 amount, uint256 lpRedeemed, uint256 lup);
    event KickReserveAuction(uint256 claimableReservesRemaining, uint256 auctionPrice, uint256 currentBurnEpoch);
    event BucketBankruptcy(uint256 indexed index, uint256 lpForfeited);

    /**************/
    /*** Errors ***/
    /**************/

    // See `IPoolErrors` for descriptions
    error AuctionActive();
    error BorrowerOk();
    error InsufficientLiquidity();
    error InsufficientLP();
    error InvalidAmount();
    error NoReserves();
    error PriceBelowLUP();
    error ReserveAuctionTooSoon();

    /***************************/
    /***  External Functions ***/
    /***************************/

    /**
     *  @notice See `IPoolKickerActions` for descriptions.
     *  @return The `KickResult` struct result of the kick action.
     */
    function kick(
        AuctionsState storage auctions_,
        DepositsState storage deposits_,
        LoansState    storage loans_,
        PoolState calldata poolState_,
        address borrowerAddress_,
        uint256 limitIndex_
    ) external returns (
        KickResult memory
    ) {
        return _kick(
            auctions_,
            deposits_,
            loans_,
            poolState_,
            borrowerAddress_,
            limitIndex_,
            0
        );
    }

    /**
     *  @notice See `IPoolKickerActions` for descriptions.
     *  @dev    === Write state ===
     *  @dev   - `Deposits.unscaledRemove` (remove amount in `Fenwick` tree, from index): update `values` array state
     *  @dev   - decrement `lender.lps` accumulator
     *  @dev   - decrement `bucket.lps` accumulator
     *  @dev    === Reverts on ===
     *  @dev    insufficient deposit to kick auction `InsufficientLiquidity()`
     *  @dev    no `LP` redeemed to kick auction `InsufficientLP()`
     *  @dev    === Emit events ===
     *  @dev    - `RemoveQuoteToken`
     *  @return kickResult_ The `KickResult` struct result of the kick action.
     */
    function kickWithDeposit(
        AuctionsState storage auctions_,
        DepositsState storage deposits_,
        mapping(uint256 => Bucket) storage buckets_,
        LoansState storage loans_,
        PoolState calldata poolState_,
        uint256 index_,
        uint256 limitIndex_
    ) external returns (
        KickResult memory kickResult_
    ) {
        Bucket storage bucket = buckets_[index_];
        Lender storage lender = bucket.lenders[msg.sender];

        KickWithDepositLocalVars memory vars;

        if (bucket.bankruptcyTime < lender.depositTime) vars.lenderLP = lender.lps;

        vars.bucketLP              = bucket.lps;
        vars.bucketCollateral      = bucket.collateral;
        vars.bucketPrice           = _priceAt(index_);
        vars.bucketUnscaledDeposit = Deposits.unscaledValueAt(deposits_, index_);
        vars.bucketScale           = Deposits.scale(deposits_, index_);
        vars.bucketDeposit         = Maths.wmul(vars.bucketUnscaledDeposit, vars.bucketScale);

        // calculate amount to remove based on lender LP in bucket
        vars.amountToDebitFromDeposit = Buckets.lpToQuoteTokens(
            vars.bucketCollateral,
            vars.bucketLP,
            vars.bucketDeposit,
            vars.lenderLP,
            vars.bucketPrice,
            Math.Rounding.Down
        );

        // cap the amount to remove at bucket deposit
        if (vars.amountToDebitFromDeposit > vars.bucketDeposit) vars.amountToDebitFromDeposit = vars.bucketDeposit;

        // revert if no amount that can be removed
        if (vars.amountToDebitFromDeposit == 0) revert InsufficientLiquidity();

        // kick top borrower
        kickResult_ = _kick(
            auctions_,
            deposits_,
            loans_,
            poolState_,
            Loans.getMax(loans_).borrower,
            limitIndex_,
            vars.amountToDebitFromDeposit
        );

        // amount to remove from deposit covers entire bond amount
        if (vars.amountToDebitFromDeposit > kickResult_.amountToCoverBond) {
            // cap amount to remove from deposit at amount to cover bond
            vars.amountToDebitFromDeposit = kickResult_.amountToCoverBond;

            // recalculate the LUP with the amount to cover bond
            kickResult_.lup = Deposits.getLup(deposits_, poolState_.debt + vars.amountToDebitFromDeposit);
            // entire bond is covered from deposit, no additional amount to be send by lender
            kickResult_.amountToCoverBond = 0;
        } else {
            // lender should send additional amount to cover bond
            kickResult_.amountToCoverBond -= vars.amountToDebitFromDeposit;
        }

        // revert if the bucket price used to kick and remove is below new LUP
        if (vars.bucketPrice < kickResult_.lup) revert PriceBelowLUP();

        // remove amount from deposits
        if (vars.amountToDebitFromDeposit == vars.bucketDeposit && vars.bucketCollateral == 0) {
            // In this case we are redeeming the entire bucket exactly, and need to ensure bucket LP are set to 0
            vars.redeemedLP = vars.bucketLP;

            Deposits.unscaledRemove(deposits_, index_, vars.bucketUnscaledDeposit);
            vars.bucketUnscaledDeposit = 0;

        } else {
            vars.redeemedLP = Buckets.quoteTokensToLP(
                vars.bucketCollateral,
                vars.bucketLP,
                vars.bucketDeposit,
                vars.amountToDebitFromDeposit,
                vars.bucketPrice,
                Math.Rounding.Up
            );

            uint256 unscaledAmountToRemove = Maths.floorWdiv(vars.amountToDebitFromDeposit, vars.bucketScale);

            // revert if calculated unscaled amount is 0
            if (unscaledAmountToRemove == 0) revert InsufficientLiquidity();

            Deposits.unscaledRemove(deposits_, index_, unscaledAmountToRemove);
            vars.bucketUnscaledDeposit -= unscaledAmountToRemove;
        }

        vars.redeemedLP = Maths.min(vars.lenderLP, vars.redeemedLP);

        // revert if LP redeemed amount to kick auction is 0
        if (vars.redeemedLP == 0) revert InsufficientLP();

        uint256 bucketRemainingLP = vars.bucketLP - vars.redeemedLP;

        if (vars.bucketCollateral == 0 && vars.bucketUnscaledDeposit == 0 && bucketRemainingLP != 0) {
            bucket.lps            = 0;
            bucket.bankruptcyTime = block.timestamp;

            emit BucketBankruptcy(
                index_,
                bucketRemainingLP
            );
        } else {
            // update lender and bucket LP balances
            lender.lps -= vars.redeemedLP;
            bucket.lps -= vars.redeemedLP;
        }

        emit RemoveQuoteToken(
            msg.sender,
            index_,
            vars.amountToDebitFromDeposit,
            vars.redeemedLP,
            kickResult_.lup
        );
    }

    /*************************/
    /***  Reserve Auction  ***/
    /*************************/

    /**
     *  @notice See `IPoolKickerActions` for descriptions.
     *  @dev    === Write state ===
     *  @dev    update `reserveAuction.unclaimed` accumulator
     *  @dev    update `reserveAuction.kicked` timestamp state
     *  @dev    === Reverts on ===
     *  @dev    no reserves to claim `NoReserves()`
     *  @dev    === Emit events ===
     *  @dev    - `KickReserveAuction`
     *  @return kickerAward_ The `LP`s awarded to reserve auction kicker.
     */
    function kickReserveAuction(
        AuctionsState storage auctions_,
        ReserveAuctionState storage reserveAuction_,
        KickReserveAuctionParams calldata params_
    ) external returns (uint256 kickerAward_) {
        // retrieve timestamp of latest burn event and last burn timestamp
        uint256 latestBurnEpoch   = reserveAuction_.latestBurnEventEpoch;
        uint256 lastBurnTimestamp = reserveAuction_.burnEvents[latestBurnEpoch].timestamp;

        // check that at least two weeks have passed since the last reserve auction completed, and that the auction was not kicked within the past 72 hours
        if (block.timestamp < lastBurnTimestamp + 2 weeks || block.timestamp - reserveAuction_.kicked <= 72 hours) {
            revert ReserveAuctionTooSoon();
        }

        uint256 curUnclaimedAuctionReserve = reserveAuction_.unclaimed;

        uint256 claimable = _claimableReserves(
            Maths.wmul(params_.t0PoolDebt, params_.inflator),
            params_.poolSize,
            auctions_.totalBondEscrowed,
            curUnclaimedAuctionReserve,
            params_.poolBalance
        );

        kickerAward_ = Maths.wmul(0.01 * 1e18, claimable);

        curUnclaimedAuctionReserve += claimable - kickerAward_;

        if (curUnclaimedAuctionReserve == 0) revert NoReserves();

        reserveAuction_.unclaimed = curUnclaimedAuctionReserve;
        reserveAuction_.kicked    = block.timestamp;

        // increment latest burn event epoch and update burn event timestamp
        latestBurnEpoch += 1;

        reserveAuction_.latestBurnEventEpoch = latestBurnEpoch;
        reserveAuction_.burnEvents[latestBurnEpoch].timestamp = block.timestamp;

        emit KickReserveAuction(
            curUnclaimedAuctionReserve,
            _reserveAuctionPrice(block.timestamp),
            latestBurnEpoch
        );
    }

    /***************************/
    /***  Internal Functions ***/
    /***************************/

    /**
     *  @notice Called to start borrower liquidation and to update the auctions queue.
     *  @dev    === Write state ===
     *  @dev    - `_recordAuction`:
     *  @dev      `borrower -> liquidation` mapping update
     *  @dev      increment `auctions count` accumulator
     *  @dev      increment `auctions.totalBondEscrowed` accumulator
     *  @dev      updates auction queue state
     *  @dev    - `_updateEscrowedBonds`:
     *  @dev      update `locked` and `claimable` kicker accumulators
     *  @dev    - `Loans.remove`:
     *  @dev      delete borrower from `indices => borrower` address mapping
     *  @dev      remove loan from loans array
     *  @dev    === Emit events ===
     *  @dev    - `Kick`
     *  @param  auctions_        Struct for pool auctions state.
     *  @param  deposits_        Struct for pool deposits state.
     *  @param  loans_           Struct for pool loans state.
     *  @param  poolState_       Current state of the pool.
     *  @param  borrowerAddress_ Address of the borrower to kick.
     *  @param  limitIndex_      Index of the lower bound of `NP` tolerated when kicking the auction.
     *  @param  additionalDebt_  Additional debt to be used when calculating proposed `LUP`.
     *  @return kickResult_      The `KickResult` struct result of the kick action.
     */
    function _kick(
        AuctionsState storage auctions_,
        DepositsState storage deposits_,
        LoansState    storage loans_,
        PoolState calldata poolState_,
        address borrowerAddress_,
        uint256 limitIndex_,
        uint256 additionalDebt_
    ) internal returns (
        KickResult memory kickResult_
    ) {
        Liquidation storage liquidation = auctions_.liquidations[borrowerAddress_];
        // revert if liquidation is active
        if (liquidation.kickTime != 0) revert AuctionActive();

        Borrower storage borrower = loans_.borrowers[borrowerAddress_];

        kickResult_.debtPreAction       = borrower.t0Debt;
        kickResult_.collateralPreAction = borrower.collateral;
        kickResult_.t0KickedDebt        = kickResult_.debtPreAction ;
        // add amount to remove to pool debt in order to calculate proposed LUP
        kickResult_.lup          = Deposits.getLup(deposits_, poolState_.debt + additionalDebt_);

        KickLocalVars memory vars;
        vars.borrowerDebt       = Maths.wmul(kickResult_.t0KickedDebt, poolState_.inflator);
        vars.borrowerCollateral = kickResult_.collateralPreAction;

        // revert if kick on a collateralized borrower
        if (_isCollateralized(vars.borrowerDebt, vars.borrowerCollateral, kickResult_.lup, poolState_.poolType)) {
            revert BorrowerOk();
        }

        // calculate auction params
        // neutral price is capped at 50 * max pool price
        vars.neutralPrice = Maths.min(
            Maths.wmul(borrower.t0Np, poolState_.inflator),
            MAX_NEUTRAL_PRICE
        );
        // check if NP is not less than price at the limit index provided by the kicker - done to prevent frontrunning kick auction call with a large amount of loan
        // which will make it harder for kicker to earn a reward and more likely that the kicker is penalized
        _revertIfPriceDroppedBelowLimit(vars.neutralPrice, limitIndex_);

        vars.noOfLoans = Loans.noOfLoans(loans_) + auctions_.noOfAuctions;

        vars.momp = _priceAt(
            Deposits.findIndexOfSum(
                deposits_,
                Maths.wdiv(poolState_.debt, vars.noOfLoans * 1e18)
            )
        );

        (vars.bondFactor, vars.bondSize) = _bondParams(
            vars.borrowerDebt,
            vars.borrowerCollateral,
            vars.momp
        );

        // record liquidation info
        _recordAuction(
            auctions_,
            liquidation,
            borrowerAddress_,
            vars.bondSize,
            vars.bondFactor,
            vars.momp,
            vars.neutralPrice
        );

        // update escrowed bonds balances and get the difference needed to cover bond (after using any kick claimable funds if any)
        kickResult_.amountToCoverBond = _updateEscrowedBonds(auctions_, vars.bondSize);

        // remove kicked loan from heap
        Loans.remove(loans_, borrowerAddress_, loans_.indices[borrowerAddress_]);

        // when loan is kicked, penalty of three months of interest is added
        vars.t0KickPenalty = Maths.wdiv(Maths.wmul(kickResult_.t0KickedDebt, poolState_.rate), 4 * 1e18);
        vars.kickPenalty   = Maths.wmul(vars.t0KickPenalty, poolState_.inflator);

        kickResult_.t0PoolDebt   = poolState_.t0Debt + vars.t0KickPenalty;
        kickResult_.t0KickedDebt += vars.t0KickPenalty;

        // update borrower debt with kicked debt penalty
        borrower.t0Debt = kickResult_.t0KickedDebt;

        emit Kick(
            borrowerAddress_,
            vars.borrowerDebt + vars.kickPenalty,
            vars.borrowerCollateral,
            vars.bondSize
        );
    }

    /**
     *  @notice Updates escrowed bonds balances, reuse kicker claimable funds and calculates difference needed to cover new bond.
     *  @dev    === Write state ===
     *  @dev    update `locked` and `claimable` kicker accumulators
     *  @dev    update `totalBondEscrowed` accumulator
     *  @param  auctions_       Struct for pool auctions state.
     *  @param  bondSize_       Bond size to cover newly kicked auction.
     *  @return bondDifference_ The amount that kicker should send to pool to cover auction bond.
     */
    function _updateEscrowedBonds(
        AuctionsState storage auctions_,
        uint256 bondSize_
    ) internal returns (uint256 bondDifference_){
        Kicker storage kicker = auctions_.kickers[msg.sender];

        kicker.locked += bondSize_;

        uint256 kickerClaimable = kicker.claimable;

        if (kickerClaimable >= bondSize_) {
            // no need to update total bond escrowed as bond is covered by kicker claimable (which is already tracked by accumulator)
            kicker.claimable -= bondSize_;
        } else {
            bondDifference_  = bondSize_ - kickerClaimable;
            kicker.claimable = 0;

            // increment total bond escrowed by amount needed to cover bond difference
            auctions_.totalBondEscrowed += bondDifference_;
        }
    }

    /**
     *  @notice Saves in storage a new liquidation that was kicked.
     *  @dev    === Write state ===
     *  @dev    `borrower -> liquidation` mapping update
     *  @dev    increment auctions count accumulator
     *  @dev    updates auction queue state
     *  @param  auctions_        Struct for pool auctions state.
     *  @param  liquidation_     Struct for current auction state.
     *  @param  borrowerAddress_ Address of the borrower that is kicked.
     *  @param  bondSize_        Bond size to cover newly kicked auction.
     *  @param  bondFactor_      Bond factor of the newly kicked auction.
     *  @param  momp_            Current pool `MOMP`.
     *  @param  neutralPrice_    Current pool `Neutral Price`.
     */
    function _recordAuction(
        AuctionsState storage auctions_,
        Liquidation storage liquidation_,
        address borrowerAddress_,
        uint256 bondSize_,
        uint256 bondFactor_,
        uint256 momp_,
        uint256 neutralPrice_
    ) internal {
        // record liquidation info
        liquidation_.kicker       = msg.sender;
        liquidation_.kickTime     = uint96(block.timestamp);
        liquidation_.kickMomp     = uint96(momp_); // cannot exceed max price enforced by _priceAt() function
        liquidation_.bondSize     = SafeCast.toUint160(bondSize_);
        liquidation_.bondFactor   = SafeCast.toUint96(bondFactor_);
        liquidation_.neutralPrice = SafeCast.toUint96(neutralPrice_);

        // increment number of active auctions
        ++auctions_.noOfAuctions;

        // update auctions queue
        if (auctions_.head != address(0)) {
            // other auctions in queue, liquidation doesn't exist or overwriting.
            auctions_.liquidations[auctions_.tail].next = borrowerAddress_;
            liquidation_.prev = auctions_.tail;
        } else {
            // first auction in queue
            auctions_.head = borrowerAddress_;
        }
        // update liquidation with the new ordering
        auctions_.tail = borrowerAddress_;
    }

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { Bucket, Lender } from '../../interfaces/pool/commons/IPoolState.sol';

import { MAX_FENWICK_INDEX } from '../helpers/PoolHelper.sol';

import { Maths } from '../internal/Maths.sol';

/**
    @title  LPActions library
    @notice External library containing logic for `LP` owners to:
            - `increase`/`decrease`/`revoke` `LP` allowance; `approve`/`revoke` `LP` transferors; `transfer` `LP`
 */
library LPActions {

    /**************/
    /*** Events ***/
    /**************/

    // See `IPoolEvents` for descriptions
    event ApproveLPTransferors(address indexed lender, address[] transferors);
    event RevokeLPTransferors(address indexed lender, address[] transferors);
    event IncreaseLPAllowance(address indexed owner, address indexed spender, uint256[] indexes, uint256[] amounts);
    event DecreaseLPAllowance(address indexed owner, address indexed spender, uint256[] indexes, uint256[] amounts);
    event RevokeLPAllowance(address indexed owner, address indexed spender, uint256[] indexes);
    event TransferLP(address owner, address newOwner, uint256[] indexes, uint256 lp);

    /**************/
    /*** Errors ***/
    /**************/

    // See `IPoolErrors` for descriptions
    error BucketBankruptcyBlock();
    error InvalidAllowancesInput();
    error InvalidIndex();
    error NoAllowance();
    error TransferorNotApproved();
    error TransferToSameOwner();

    /***************************/
    /***  External Functions ***/
    /***************************/

    /**
     *  @notice See `IPoolLPActions` for descriptions
     *  @dev    === Write state ===
     *  @dev    increment `LP` allowances
     *  @dev    === Reverts on ===
     *  @dev    invalid indexes and amounts input `InvalidAllowancesInput()`
     *  @dev    === Emit events ===
     *  @dev    - `IncreaseLPAllowance`
     */
    function increaseLPAllowance(
        mapping(uint256 => uint256) storage allowances_,
        address spender_,
        uint256[] calldata indexes_,
        uint256[] calldata amounts_
    ) external {
        uint256 indexesLength = indexes_.length;

        if (indexesLength != amounts_.length) revert InvalidAllowancesInput();

        uint256 index;
        for (uint256 i = 0; i < indexesLength; ) {
            index = indexes_[i];

            allowances_[index] += amounts_[i];

            unchecked { ++i; }
        }

        emit IncreaseLPAllowance(
            msg.sender,
            spender_,
            indexes_,
            amounts_
        );
    }

    /**
     *  @notice See `IPoolLPActions` for descriptions
     *  @dev    === Write state ===
     *  @dev    decrement `LP` allowances
     *  @dev    === Reverts on ===
     *  @dev    invalid indexes and amounts input `InvalidAllowancesInput()`
     *  @dev    === Emit events ===
     *  @dev    - `DecreaseLPAllowance`
     */
    function decreaseLPAllowance(
        mapping(uint256 => uint256) storage allowances_,
        address spender_,
        uint256[] calldata indexes_,
        uint256[] calldata amounts_
    ) external {
        uint256 indexesLength = indexes_.length;

        if (indexesLength != amounts_.length) revert InvalidAllowancesInput();

        uint256 index;

        for (uint256 i = 0; i < indexesLength; ) {
            index = indexes_[i];

            allowances_[index] -= amounts_[i];

            unchecked { ++i; }
        }

        emit DecreaseLPAllowance(
            msg.sender,
            spender_,
            indexes_,
            amounts_
        );
    }

    /**
     *  @notice See `IPoolLPActions` for descriptions
     *  @dev    === Write state ===
     *  @dev    decrement `LP` allowances
     *  @dev    === Emit events ===
     *  @dev    - `RevokeLPAllowance`
     */
    function revokeLPAllowance(
        mapping(uint256 => uint256) storage allowances_,
        address spender_,
        uint256[] calldata indexes_
    ) external {
        uint256 indexesLength = indexes_.length;
        uint256 index;

        for (uint256 i = 0; i < indexesLength; ) {
            index = indexes_[i];

            allowances_[index] = 0;

            unchecked { ++i; }
        }

        emit RevokeLPAllowance(
            msg.sender,
            spender_,
            indexes_
        );
    }

    /**
     *  @notice See `IPoolLPActions` for descriptions
     *  @dev    === Write state ===
     *  @dev    `approvedTransferors` mapping
     *  @dev    === Emit events ===
     *  @dev    - `ApproveLPTransferors`
     */
    function approveLPTransferors(
        mapping(address => bool) storage allowances_,
        address[] calldata transferors_
    ) external  {
        uint256 transferorsLength = transferors_.length;
        for (uint256 i = 0; i < transferorsLength; ) {
            allowances_[transferors_[i]] = true;

            unchecked { ++i; }
        }

        emit ApproveLPTransferors(
            msg.sender,
            transferors_
        );
    }

    /**
     *  @notice See `IPoolLPActions` for descriptions
     *  @dev    === Write state ===
     *  @dev    `approvedTransferors` mapping
     *  @dev    === Emit events ===
     *  @dev    - `RevokeLPTransferors`
     */
    function revokeLPTransferors(
        mapping(address => bool) storage allowances_,
        address[] calldata transferors_
    ) external  {
        uint256 transferorsLength = transferors_.length;
        for (uint256 i = 0; i < transferorsLength; ) {
            delete allowances_[transferors_[i]];

            unchecked { ++i; }
        }

        emit RevokeLPTransferors(
            msg.sender,
            transferors_
        );
    }

    /**
     *  @notice See `IPoolLPActions` for descriptions
     *  @dev    === Write state ===
     *  @dev    delete allowance mapping
     *  @dev    increment new `lender.lps` accumulator and `lender.depositTime` state
     *  @dev    delete old lender from `bucket -> lender` mapping
     *  @dev    === Reverts on ===
     *  @dev    invalid index `InvalidIndex()`
     *  @dev    no allowance `NoAllowance()`
     *  @dev    === Emit events ===
     *  @dev    - `TransferLP`
     */
    function transferLP(
        mapping(uint256 => Bucket) storage buckets_,
        mapping(address => mapping(address => mapping(uint256 => uint256))) storage allowances_,
        mapping(address => mapping(address => bool)) storage approvedTransferors_,
        address ownerAddress_,
        address newOwnerAddress_,
        uint256[] calldata indexes_
    ) external {
        // revert if msg.sender is not the new owner and is not approved as a transferor by the new owner
        if (newOwnerAddress_ != msg.sender && !approvedTransferors_[newOwnerAddress_][msg.sender]) revert TransferorNotApproved();

        // revert if new owner address is the same as old owner address
        if (ownerAddress_ == newOwnerAddress_) revert TransferToSameOwner();

        uint256 indexesLength = indexes_.length;
        uint256 index;
        uint256 lpTransferred;

        for (uint256 i = 0; i < indexesLength; ) {
            index = indexes_[i];

            // revert if invalid index
            if (index > MAX_FENWICK_INDEX) revert InvalidIndex();

            Bucket storage bucket = buckets_[index];
            Lender storage owner  = bucket.lenders[ownerAddress_];

            uint256 bankruptcyTime   = bucket.bankruptcyTime;
            uint256 ownerDepositTime = owner.depositTime;
            uint256 ownerLpBalance   = bankruptcyTime < ownerDepositTime ? owner.lps : 0;

            uint256 allowedAmount = allowances_[ownerAddress_][newOwnerAddress_][index];
            if (allowedAmount == 0) revert NoAllowance();

            // transfer allowed amount or entire LP balance
            allowedAmount = Maths.min(allowedAmount, ownerLpBalance);

            // move owner LP (if any) to the new owner
            if (allowedAmount != 0) {
                Lender storage newOwner = bucket.lenders[newOwnerAddress_];

                uint256 newOwnerDepositTime = newOwner.depositTime;

                if (newOwnerDepositTime > bankruptcyTime) {
                    // deposit happened in a healthy bucket, add amount of LP to new owner
                    newOwner.lps += allowedAmount;
                } else {
                    // bucket bankruptcy happened after deposit, reset balance and add amount of LP to new owner
                    newOwner.lps = allowedAmount;
                }

                // remove amount of LP from old owner
                owner.lps     -= allowedAmount;
                // add amount of LP to total LP transferred
                lpTransferred += allowedAmount;

                // set the deposit time as the max of transferred deposit and current deposit time
                newOwner.depositTime = Maths.max(ownerDepositTime, newOwnerDepositTime);
            }

            // reset allowances of transferred LP
            delete allowances_[ownerAddress_][newOwnerAddress_][index];

            unchecked { ++i; }
        }

        emit TransferLP(
            ownerAddress_,
            newOwnerAddress_,
            indexes_,
            lpTransferred
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { Math } from '@openzeppelin/contracts/utils/math/Math.sol';

import {
    AddQuoteParams,
    MoveQuoteParams,
    RemoveQuoteParams
}                     from '../../interfaces/pool/commons/IPoolInternals.sol';
import {
    Bucket,
    DepositsState,
    Lender,
    PoolState
}                     from '../../interfaces/pool/commons/IPoolState.sol';

import { _depositFeeRate, _priceAt, MAX_FENWICK_INDEX } from '../helpers/PoolHelper.sol';

import { Deposits } from '../internal/Deposits.sol';
import { Buckets }  from '../internal/Buckets.sol';
import { Maths }    from '../internal/Maths.sol';

/**
    @title  LenderActions library
    @notice External library containing logic for lender actors:
            - `Lenders`: add, remove and move quote tokens;
            - `Traders`: add, remove and move quote tokens; add and remove collateral
 */
library LenderActions {

    /*************************/
    /*** Local Var Structs ***/
    /*************************/

    /// @dev Struct used for `moveQuoteToken` function local vars.
    struct MoveQuoteLocalVars {
        uint256 fromBucketPrice;            // [WAD] Price of the bucket to move amount from.
        uint256 fromBucketCollateral;       // [WAD] Total amount of collateral in from bucket.
        uint256 fromBucketLP;               // [WAD] Total amount of LP in from bucket.
        uint256 fromBucketLenderLP;         // [WAD] Amount of LP owned by lender in from bucket.
        uint256 fromBucketDepositTime;      // Time of lender deposit in the bucket to move amount from.
        uint256 fromBucketRemainingLP;      // Amount of LP remaining in from bucket after move.
        uint256 fromBucketRemainingDeposit; // Amount of scaled deposit remaining in from bucket after move.
        uint256 toBucketPrice;              // [WAD] Price of the bucket to move amount to.
        uint256 toBucketBankruptcyTime;     // Time the bucket to move amount to was marked as insolvent.
        uint256 toBucketDepositTime;        // Time of lender deposit in the bucket to move amount to.
        uint256 toBucketUnscaledDeposit;    // Amount of unscaled deposit in to bucket.
        uint256 toBucketDeposit;            // Amount of scaled deposit in to bucket.
        uint256 toBucketScale;              // Scale deposit of to bucket.
        uint256 ptp;                        // [WAD] Pool Threshold Price.
        uint256 htp;                        // [WAD] Highest Threshold Price.
    }

    /// @dev Struct used for `removeQuoteToken` function local vars.
    struct RemoveDepositParams {
        uint256 depositConstraint; // [WAD] Constraint on deposit in quote token.
        uint256 lpConstraint;      // [WAD] Constraint in LPB terms.
        uint256 bucketLP;          // [WAD] Total LPB in the bucket.
        uint256 bucketCollateral;  // [WAD] Claimable collateral in the bucket.
        uint256 price;             // [WAD] Price of bucket.
        uint256 index;             // Bucket index.
        uint256 dustLimit;         // Minimum amount of deposit which may reside in a bucket.
    }

    /**************/
    /*** Events ***/
    /**************/

    // See `IPoolEvents` for descriptions
    event AddQuoteToken(address indexed lender, uint256 indexed index, uint256 amount, uint256 lpAwarded, uint256 lup);
    event BucketBankruptcy(uint256 indexed index, uint256 lpForfeited);
    event MoveQuoteToken(address indexed lender, uint256 indexed from, uint256 indexed to, uint256 amount, uint256 lpRedeemedFrom, uint256 lpAwardedTo, uint256 lup);
    event RemoveQuoteToken(address indexed lender, uint256 indexed index, uint256 amount, uint256 lpRedeemed, uint256 lup);

    /**************/
    /*** Errors ***/
    /**************/

    // See `IPoolErrors` for descriptions
    error BucketBankruptcyBlock();
    error CannotMergeToHigherPrice();
    error DustAmountNotExceeded();
    error InvalidIndex();
    error InvalidAmount();
    error LUPBelowHTP();
    error NoClaim();
    error InsufficientLP();
    error InsufficientLiquidity();
    error InsufficientCollateral();
    error MoveToSameIndex();

    /***************************/
    /***  External Functions ***/
    /***************************/

    /**
     *  @notice See `IERC20PoolLenderActions` and `IERC721PoolLenderActions` for descriptions
     *  @dev    === Write state ===
     *  @dev    - `Buckets.addCollateral`:
     *  @dev      increment `bucket.collateral` and `bucket.lps` accumulator
     *  @dev      `addLenderLP`: increment `lender.lps` accumulator and `lender.depositTime `state
     *  @dev    === Reverts on ===
     *  @dev    invalid bucket index `InvalidIndex()`
     *  @dev    no LP awarded in bucket `InsufficientLP()`
     */
    function addCollateral(
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        uint256 collateralAmountToAdd_,
        uint256 index_
    ) external returns (uint256 bucketLP_) {
        // revert if no amount to be added
        if (collateralAmountToAdd_ == 0) revert InvalidAmount();
        // revert if adding at invalid index
        if (index_ == 0 || index_ > MAX_FENWICK_INDEX) revert InvalidIndex();

        uint256 bucketDeposit = Deposits.valueAt(deposits_, index_);
        uint256 bucketPrice   = _priceAt(index_);

        bucketLP_ = Buckets.addCollateral(
            buckets_[index_],
            msg.sender,
            bucketDeposit,
            collateralAmountToAdd_,
            bucketPrice
        );

        // revert if (due to rounding) the awarded LP is 0
        if (bucketLP_ == 0) revert InsufficientLP();
    }

    /**
     *  @notice See `IPoolLenderActions` for descriptions
     *  @dev    === Write state ===
     *  @dev    - `Deposits.unscaledAdd` (add new amount in `Fenwick` tree): update `values` array state 
     *  @dev    - increment `bucket.lps` accumulator
     *  @dev    - increment `lender.lps` accumulator and `lender.depositTime` state
     *  @dev    === Reverts on ===
     *  @dev    invalid bucket index `InvalidIndex()`
     *  @dev    same block when bucket becomes insolvent `BucketBankruptcyBlock()`
     *  @dev    no LP awarded in bucket `InsufficientLP()`
     *  @dev    calculated unscaled amount to add is 0 `InvalidAmount()`
     *  @dev    === Emit events ===
     *  @dev    - `AddQuoteToken`
     */
    function addQuoteToken(
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        PoolState calldata poolState_,
        AddQuoteParams calldata params_
    ) external returns (uint256 bucketLP_, uint256 lup_) {
        // revert if no amount to be added
        if (params_.amount == 0) revert InvalidAmount();
        // revert if adding to an invalid index
        if (params_.index == 0 || params_.index > MAX_FENWICK_INDEX) revert InvalidIndex();

        Bucket storage bucket = buckets_[params_.index];

        uint256 bankruptcyTime = bucket.bankruptcyTime;

        // cannot deposit in the same block when bucket becomes insolvent
        if (bankruptcyTime == block.timestamp) revert BucketBankruptcyBlock();

        uint256 unscaledBucketDeposit = Deposits.unscaledValueAt(deposits_, params_.index);
        uint256 bucketScale           = Deposits.scale(deposits_, params_.index);
        uint256 bucketDeposit         = Maths.wmul(bucketScale, unscaledBucketDeposit);
        uint256 bucketPrice           = _priceAt(params_.index);
        uint256 addedAmount           = params_.amount;

        // charge unutilized deposit fee where appropriate
        uint256 lupIndex = Deposits.findIndexOfSum(deposits_, poolState_.debt);
        bool depositBelowLup = lupIndex != 0 && params_.index > lupIndex;
        if (depositBelowLup) {
            addedAmount = Maths.wmul(addedAmount, Maths.WAD - _depositFeeRate(poolState_.rate));
        }

        bucketLP_ = Buckets.quoteTokensToLP(
            bucket.collateral,
            bucket.lps,
            bucketDeposit,
            addedAmount,
            bucketPrice,
            Math.Rounding.Down
        );

        // revert if (due to rounding) the awarded LP is 0
        if (bucketLP_ == 0) revert InsufficientLP();

        uint256 unscaledAmount = Maths.wdiv(addedAmount, bucketScale);
        // revert if unscaled amount is 0
        if (unscaledAmount == 0) revert InvalidAmount();

        Deposits.unscaledAdd(deposits_, params_.index, unscaledAmount);

        // update lender LP
        Buckets.addLenderLP(bucket, bankruptcyTime, msg.sender, bucketLP_);

        // update bucket LP
        bucket.lps += bucketLP_;

        // only need to recalculate LUP if the deposit was above it
        if (!depositBelowLup) {
            lupIndex = Deposits.findIndexOfSum(deposits_, poolState_.debt);
        }
        lup_ = _priceAt(lupIndex);

        emit AddQuoteToken(
            msg.sender,
            params_.index,
            addedAmount,
            bucketLP_,
            lup_
        );
    }

    /**
     *  @notice See `IPoolLenderActions` for descriptions
     *  @dev    === Write state ===
     *  @dev    - `_removeMaxDeposit`:
     *  @dev      `Deposits.unscaledRemove` (remove amount in `Fenwick` tree, from index): update `values` array state
     *  @dev    - `Deposits.unscaledAdd` (add amount in `Fenwick` tree, to index): update `values` array state
     *  @dev    - decrement `lender.lps` accumulator for from bucket
     *  @dev    - increment `lender.lps` accumulator and `lender.depositTime` state for to bucket
     *  @dev    - decrement `bucket.lps` accumulator for from bucket
     *  @dev    - increment `bucket.lps` accumulator for to bucket
     *  @dev    === Reverts on ===
     *  @dev    same index `MoveToSameIndex()`
     *  @dev    dust amount `DustAmountNotExceeded()`
     *  @dev    invalid index `InvalidIndex()`
     *  @dev    no LP awarded in to bucket `InsufficientLP()`
     *  @dev    === Emit events ===
     *  @dev    - `BucketBankruptcy`
     *  @dev    - `MoveQuoteToken`
     */
    function moveQuoteToken(
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        PoolState calldata poolState_,
        MoveQuoteParams calldata params_
    ) external returns (uint256 fromBucketRedeemedLP_, uint256 toBucketLP_, uint256 movedAmount_, uint256 lup_) {
        if (params_.maxAmountToMove == 0)
            revert InvalidAmount();
        if (params_.fromIndex == params_.toIndex)
            revert MoveToSameIndex();
        if (params_.maxAmountToMove != 0 && params_.maxAmountToMove < poolState_.quoteTokenScale)
            revert DustAmountNotExceeded();
        if (params_.toIndex == 0 || params_.toIndex > MAX_FENWICK_INDEX) 
            revert InvalidIndex();

        Bucket storage toBucket = buckets_[params_.toIndex];

        MoveQuoteLocalVars memory vars;
        vars.toBucketBankruptcyTime = toBucket.bankruptcyTime;

        // cannot move in the same block when target bucket becomes insolvent
        if (vars.toBucketBankruptcyTime == block.timestamp) revert BucketBankruptcyBlock();

        Bucket storage fromBucket       = buckets_[params_.fromIndex];
        Lender storage fromBucketLender = fromBucket.lenders[msg.sender];

        vars.fromBucketPrice       = _priceAt(params_.fromIndex);
        vars.fromBucketCollateral  = fromBucket.collateral;
        vars.fromBucketLP          = fromBucket.lps;
        vars.fromBucketDepositTime = fromBucketLender.depositTime;

        vars.toBucketPrice         = _priceAt(params_.toIndex);

        if (fromBucket.bankruptcyTime < vars.fromBucketDepositTime) vars.fromBucketLenderLP = fromBucketLender.lps;

        (movedAmount_, fromBucketRedeemedLP_, vars.fromBucketRemainingDeposit) = _removeMaxDeposit(
            deposits_,
            RemoveDepositParams({
                depositConstraint: params_.maxAmountToMove,
                lpConstraint:      vars.fromBucketLenderLP,
                bucketLP:          vars.fromBucketLP,
                bucketCollateral:  vars.fromBucketCollateral,
                price:             vars.fromBucketPrice,
                index:             params_.fromIndex,
                dustLimit:         poolState_.quoteTokenScale
            })
        );

        lup_ = Deposits.getLup(deposits_, poolState_.debt);
        // apply unutilized deposit fee if quote token is moved from above the LUP to below the LUP
        if (vars.fromBucketPrice >= lup_ && vars.toBucketPrice < lup_) {
            movedAmount_ = Maths.wmul(movedAmount_, Maths.WAD - _depositFeeRate(poolState_.rate));
        }

        vars.toBucketUnscaledDeposit = Deposits.unscaledValueAt(deposits_, params_.toIndex);
        vars.toBucketScale           = Deposits.scale(deposits_, params_.toIndex);
        vars.toBucketDeposit         = Maths.wmul(vars.toBucketUnscaledDeposit, vars.toBucketScale);

        toBucketLP_ = Buckets.quoteTokensToLP(
            toBucket.collateral,
            toBucket.lps,
            vars.toBucketDeposit,
            movedAmount_,
            vars.toBucketPrice,
            Math.Rounding.Down
        );

        // revert if (due to rounding) the awarded LP in to bucket is 0
        if (toBucketLP_ == 0) revert InsufficientLP();

        Deposits.unscaledAdd(deposits_, params_.toIndex, Maths.wdiv(movedAmount_, vars.toBucketScale));

        vars.htp = Maths.wmul(params_.thresholdPrice, poolState_.inflator);

        // check loan book's htp against new lup, revert if move drives LUP below HTP
        if (params_.fromIndex < params_.toIndex && vars.htp > lup_) revert LUPBelowHTP();

        // update lender and bucket LP balance in from bucket
        vars.fromBucketRemainingLP = vars.fromBucketLP - fromBucketRedeemedLP_;

        // check if from bucket healthy after move quote tokens - set bankruptcy if collateral and deposit are 0 but there's still LP
        if (vars.fromBucketCollateral == 0 && vars.fromBucketRemainingDeposit == 0 && vars.fromBucketRemainingLP != 0) {
            fromBucket.lps            = 0;
            fromBucket.bankruptcyTime = block.timestamp;

            emit BucketBankruptcy(
                params_.fromIndex,
                vars.fromBucketRemainingLP
            );
        } else {
            // update lender and bucket LP balance
            fromBucketLender.lps -= fromBucketRedeemedLP_;

            fromBucket.lps = vars.fromBucketRemainingLP;
        }

        // update lender and bucket LP balance in target bucket
        Lender storage toBucketLender = toBucket.lenders[msg.sender];

        vars.toBucketDepositTime = toBucketLender.depositTime;
        if (vars.toBucketBankruptcyTime >= vars.toBucketDepositTime) {
            // bucket is bankrupt and deposit was done before bankruptcy time, reset lender lp amount
            toBucketLender.lps = toBucketLP_;

            // set deposit time of the lender's to bucket as bucket's last bankruptcy timestamp + 1 so deposit won't get invalidated
            vars.toBucketDepositTime = vars.toBucketBankruptcyTime + 1;
        } else {
            toBucketLender.lps += toBucketLP_;
        }

        // set deposit time to the greater of the lender's from bucket and the target bucket
        toBucketLender.depositTime = Maths.max(vars.fromBucketDepositTime, vars.toBucketDepositTime);

        // update bucket LP balance
        toBucket.lps += toBucketLP_;

        emit MoveQuoteToken(
            msg.sender,
            params_.fromIndex,
            params_.toIndex,
            movedAmount_,
            fromBucketRedeemedLP_,
            toBucketLP_,
            lup_
        );
    }

    /**
     *  @notice See `IPoolLenderActions` for descriptions
     *  @dev    === Write state ===
     *  @dev    - `_removeMaxDeposit`:
     *  @dev      `Deposits.unscaledRemove` (remove amount in `Fenwick` tree, from index): update `values` array state
     *  @dev    - decrement `lender.lps` accumulator
     *  @dev    - decrement `bucket.lps` accumulator
     *  @dev    === Reverts on ===
     *  @dev    no `LP` `NoClaim()`;
     *  @dev    `LUP` lower than `HTP` `LUPBelowHTP()`
     *  @dev    === Emit events ===
     *  @dev    - `RemoveQuoteToken`
     *  @dev    - `BucketBankruptcy`
     */
    function removeQuoteToken(
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        PoolState calldata poolState_,
        RemoveQuoteParams calldata params_
    ) external returns (uint256 removedAmount_, uint256 redeemedLP_, uint256 lup_) {
        // revert if no amount to be removed
        if (params_.maxAmount == 0) revert InvalidAmount();

        Bucket storage bucket = buckets_[params_.index];
        Lender storage lender = bucket.lenders[msg.sender];

        uint256 depositTime = lender.depositTime;

        RemoveDepositParams memory removeParams;

        if (bucket.bankruptcyTime < depositTime) removeParams.lpConstraint = lender.lps;

        // revert if no LP to claim
        if (removeParams.lpConstraint == 0) revert NoClaim();

        removeParams.depositConstraint = params_.maxAmount;
        removeParams.price             = _priceAt(params_.index);
        removeParams.bucketLP          = bucket.lps;
        removeParams.bucketCollateral  = bucket.collateral;
        removeParams.index             = params_.index;
        removeParams.dustLimit         = poolState_.quoteTokenScale;

        uint256 unscaledRemaining;

        (removedAmount_, redeemedLP_, unscaledRemaining) = _removeMaxDeposit(
            deposits_,
            removeParams
        );

        lup_ = Deposits.getLup(deposits_, poolState_.debt);

        uint256 htp = Maths.wmul(params_.thresholdPrice, poolState_.inflator);

        if (
            // check loan book's htp doesn't exceed new lup
            htp > lup_
            ||
            // ensure that pool debt < deposits after removal
            // this can happen if lup and htp are less than min bucket price and htp > lup (since LUP is capped at min bucket price)
            (poolState_.debt != 0 && poolState_.debt > Deposits.treeSum(deposits_))
        ) revert LUPBelowHTP();

        uint256 lpRemaining = removeParams.bucketLP - redeemedLP_;

        // check if bucket healthy after remove quote tokens - set bankruptcy if collateral and deposit are 0 but there's still LP
        if (removeParams.bucketCollateral == 0 && unscaledRemaining == 0 && lpRemaining != 0) {
            bucket.lps            = 0;
            bucket.bankruptcyTime = block.timestamp;

            emit BucketBankruptcy(
                params_.index,
                lpRemaining
            );
        } else {
            // update lender and bucket LP balances
            lender.lps -= redeemedLP_;

            bucket.lps = lpRemaining;
        }

        emit RemoveQuoteToken(
            msg.sender,
            params_.index,
            removedAmount_,
            redeemedLP_,
            lup_
        );
    }

    /**
     *  @notice See `IPoolLenderActions` for descriptions
     *  @dev    === Write state ===
     *  @dev    decrement `lender.lps` accumulator
     *  @dev    decrement `bucket.collateral` and `bucket.lps` accumulator
     *  @dev    === Reverts on ===
     *  @dev    not enough collateral `InsufficientCollateral()`
     *  @dev    no `LP` redeemed `InsufficientLP()`
     *  @dev    === Emit events ===
     *  @dev    - `BucketBankruptcy`
     */
    function removeCollateral(
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        uint256 amount_,
        uint256 index_
    ) external returns (uint256 lpAmount_) {
        // revert if no amount to be removed
        if (amount_ == 0) revert InvalidAmount();

        Bucket storage bucket = buckets_[index_];

        uint256 bucketCollateral = bucket.collateral;

        if (amount_ > bucketCollateral) revert InsufficientCollateral();

        uint256 bucketPrice   = _priceAt(index_);
        uint256 bucketLP      = bucket.lps;
        uint256 bucketDeposit = Deposits.valueAt(deposits_, index_);

        lpAmount_ = Buckets.collateralToLP(
            bucketCollateral,
            bucketLP,
            bucketDeposit,
            amount_,
            bucketPrice,
            Math.Rounding.Up
        );

        // revert if (due to rounding) required LP is 0
        if (lpAmount_ == 0) revert InsufficientLP();

        Lender storage lender = bucket.lenders[msg.sender];

        uint256 lenderLpBalance;
        if (bucket.bankruptcyTime < lender.depositTime) lenderLpBalance = lender.lps;
        if (lenderLpBalance == 0 || lpAmount_ > lenderLpBalance) revert InsufficientLP();

        // update bucket LP and collateral balance
        bucketLP -= lpAmount_;

        // If clearing out the bucket collateral, ensure it's zeroed out
        if (bucketLP == 0 && bucketDeposit == 0) {
            amount_ = bucketCollateral;
        }

        bucketCollateral  -= amount_;
        bucket.collateral = bucketCollateral;

        // check if bucket healthy after collateral remove - set bankruptcy if collateral and deposit are 0 but there's still LP
        if (bucketCollateral == 0 && bucketDeposit == 0 && bucketLP != 0) {
            bucket.lps            = 0;
            bucket.bankruptcyTime = block.timestamp;

            emit BucketBankruptcy(
                index_,
                bucketLP
            );
        } else {
            // update lender and bucket LP balances
            lender.lps -= lpAmount_;
            bucket.lps = bucketLP;
        }
    }

    /**
     *  @notice Removes max collateral amount from a given bucket index.
     *  @dev    === Write state ===
     *  @dev    - `_removeMaxCollateral`:
     *  @dev      decrement `lender.lps` accumulator
     *  @dev      decrement `bucket.collateral` and `bucket.lps` accumulator
     *  @dev    === Reverts on ===
     *  @dev    not enough collateral `InsufficientCollateral()`
     *  @dev    no claim `NoClaim()`
     *  @dev    leaves less than dust limit in bucket `DustAmountNotExceeded()`
     *  @return Amount of collateral that was removed.
     *  @return Amount of LP redeemed for removed collateral amount.
     */
    function removeMaxCollateral(
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        uint256 dustLimit_,
        uint256 maxAmount_,
        uint256 index_
    ) external returns (uint256, uint256) {
        // revert if no amount to remove
        if (maxAmount_ == 0) revert InvalidAmount();

        return _removeMaxCollateral(
            buckets_,
            deposits_,
            dustLimit_,
            maxAmount_,
            index_
        );
    }

    /**
     *  @notice See `IERC721PoolLenderActions` for descriptions
     *  @dev    === Write state ===
     *  @dev    - `Buckets.addCollateral`:
     *  @dev      increment `bucket.collateral` and `bucket.lps` accumulator
     *  @dev      increment `lender.lps` accumulator and `lender.depositTime` state
     *  @dev    === Reverts on ===
     *  @dev    invalid merge index `CannotMergeToHigherPrice()`
     *  @dev    no `LP` awarded in `toIndex_` bucket `InsufficientLP()`
     *  @dev    no collateral removed from bucket `InvalidAmount()`
     */
    function mergeOrRemoveCollateral(
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        uint256[] calldata removalIndexes_,
        uint256 collateralAmount_,
        uint256 toIndex_
    ) external returns (uint256 collateralToMerge_, uint256 bucketLP_) {
        uint256 i;
        uint256 fromIndex;
        uint256 collateralRemoved;
        uint256 noOfBuckets = removalIndexes_.length;
        uint256 collateralRemaining = collateralAmount_;

        // Loop over buckets, exit if collateralAmount is reached or max noOfBuckets is reached
        while (collateralToMerge_ < collateralAmount_ && i < noOfBuckets) {
            fromIndex = removalIndexes_[i];

            if (fromIndex > toIndex_) revert CannotMergeToHigherPrice();

            (collateralRemoved, ) = _removeMaxCollateral(
                buckets_,
                deposits_,
                1,                   // dust limit is same as collateral scale
                collateralRemaining,
                fromIndex
            );

            // revert if calculated amount of collateral to remove is 0
            if (collateralRemoved == 0) revert InvalidAmount();

            collateralToMerge_ += collateralRemoved;

            collateralRemaining = collateralRemaining - collateralRemoved;

            unchecked { ++i; }
        }

        if (collateralToMerge_ != collateralAmount_) {
            // Merge totalled collateral to specified bucket, toIndex_
            uint256 toBucketDeposit = Deposits.valueAt(deposits_, toIndex_);
            uint256 toBucketPrice   = _priceAt(toIndex_);

            bucketLP_ = Buckets.addCollateral(
                buckets_[toIndex_],
                msg.sender,
                toBucketDeposit,
                collateralToMerge_,
                toBucketPrice
            );

            // revert if (due to rounding) the awarded LP is 0
            if (bucketLP_ == 0) revert InsufficientLP();
        }
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    /**
     *  @notice Removes max collateral amount from a given bucket index.
     *  @dev    === Write state ===
     *  @dev    decrement `lender.lps` accumulator
     *  @dev    decrement `bucket.collateral` and `bucket.lps` accumulator
     *  @dev    === Reverts on ===
     *  @dev    not enough collateral `InsufficientCollateral()`
     *  @dev    no claim `NoClaim()`
     *  @dev    no `LP` redeemed `InsufficientLP()`
     *  @dev    leaves less than dust limit in bucket `DustAmountNotExceeded()`
     *  @dev    === Emit events ===
     *  @dev    - `BucketBankruptcy`
     *  @return collateralAmount_ Amount of collateral that was removed.
     *  @return lpAmount_         Amount of `LP` redeemed for removed collateral amount.
     */
    function _removeMaxCollateral(
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        uint256 dustLimit_,
        uint256 maxAmount_,
        uint256 index_
    ) internal returns (uint256 collateralAmount_, uint256 lpAmount_) {
        Bucket storage bucket = buckets_[index_];

        uint256 bucketCollateral = bucket.collateral;
        // revert if there's no collateral in bucket
        if (bucketCollateral == 0) revert InsufficientCollateral();

        Lender storage lender = bucket.lenders[msg.sender];

        uint256 lenderLpBalance;

        if (bucket.bankruptcyTime < lender.depositTime) lenderLpBalance = lender.lps;
        // revert if no LP to redeem
        if (lenderLpBalance == 0) revert NoClaim();

        uint256 bucketPrice   = _priceAt(index_);
        uint256 bucketLP     = bucket.lps;
        uint256 bucketDeposit = Deposits.valueAt(deposits_, index_);

        // limit amount by what is available in the bucket
        collateralAmount_ = Maths.min(maxAmount_, bucketCollateral);

        // determine how much LP would be required to remove the requested amount
        uint256 requiredLP = Buckets.collateralToLP(
            bucketCollateral,
            bucketLP,
            bucketDeposit,
            collateralAmount_,
            bucketPrice,
            Math.Rounding.Up
        );

        // revert if (due to rounding) the required LP is 0
        if (requiredLP == 0) revert InsufficientLP();

        // limit withdrawal by the lender's LPB
        if (requiredLP <= lenderLpBalance) {
            // withdraw collateralAmount_ as is
            lpAmount_ = requiredLP;
        } else {
            lpAmount_         = lenderLpBalance;
            collateralAmount_ = Math.mulDiv(lenderLpBalance, collateralAmount_, requiredLP);

            if (collateralAmount_ == 0) revert InsufficientLP();
        }

        // update bucket LP and collateral balance
        bucketLP -= Maths.min(bucketLP, lpAmount_);

        // If clearing out the bucket collateral, ensure it's zeroed out
        if (bucketLP == 0 && bucketDeposit == 0) collateralAmount_ = bucketCollateral;

        collateralAmount_ = Maths.min(bucketCollateral, collateralAmount_);
        bucketCollateral  -= collateralAmount_;
        if (bucketCollateral != 0 && bucketCollateral < dustLimit_) revert DustAmountNotExceeded();
        bucket.collateral = bucketCollateral;

        // check if bucket healthy after collateral remove - set bankruptcy if collateral and deposit are 0 but there's still LP
        if (bucketCollateral == 0 && bucketDeposit == 0 && bucketLP != 0) {
            bucket.lps            = 0;
            bucket.bankruptcyTime = block.timestamp;

            emit BucketBankruptcy(
                index_,
                bucketLP
            );
        } else {
            // update lender and bucket LP balances
            lender.lps -= lpAmount_;
            bucket.lps = bucketLP;
        }
    }

    /**
     *  @notice Removes the amount of quote tokens calculated for the given amount of LP.
     *  @dev    === Write state ===
     *  @dev    - `Deposits.unscaledRemove` (remove amount in `Fenwick` tree, from index):
     *  @dev      update `values` array state
     *  @dev    === Reverts on ===
     *  @dev    no `LP` redeemed `InsufficientLP()`
     *  @dev    no unscaled amount removed` `InvalidAmount()`
     *  @return removedAmount_     Amount of scaled deposit removed.
     *  @return redeemedLP_        Amount of bucket `LP` corresponding for calculated scaled deposit amount.
     *  @return unscaledRemaining_ Amount of unscaled deposit remaining.
     */
    function _removeMaxDeposit(
        DepositsState storage deposits_,
        RemoveDepositParams memory params_
    ) internal returns (uint256 removedAmount_, uint256 redeemedLP_, uint256 unscaledRemaining_) {

        uint256 unscaledDepositAvailable = Deposits.unscaledValueAt(deposits_, params_.index);

        // revert if there's no liquidity available to remove
        if (unscaledDepositAvailable == 0) revert InsufficientLiquidity();

        uint256 depositScale           = Deposits.scale(deposits_, params_.index);
        uint256 scaledDepositAvailable = Maths.wmul(unscaledDepositAvailable, depositScale);

        // Below is pseudocode explaining the logic behind finding the constrained amount of deposit and LPB
        // scaledRemovedAmount is constrained by the scaled maxAmount(in QT), the scaledDeposit constraint, and
        // the lender LPB exchange rate in scaled deposit-to-LPB for the bucket:
        // scaledRemovedAmount = min ( maxAmount_, scaledDeposit, lenderLPBalance*exchangeRate)
        // redeemedLP_ = min ( maxAmount_/scaledExchangeRate, scaledDeposit/exchangeRate, lenderLPBalance)

        uint256 scaledLpConstraint = Buckets.lpToQuoteTokens(
            params_.bucketCollateral,
            params_.bucketLP,
            scaledDepositAvailable,
            params_.lpConstraint,
            params_.price,
            Math.Rounding.Down
        );
        uint256 unscaledRemovedAmount;
        if (
            params_.depositConstraint < scaledDepositAvailable &&
            params_.depositConstraint < scaledLpConstraint
        ) {
            // depositConstraint is binding constraint
            removedAmount_ = params_.depositConstraint;
            redeemedLP_    = Buckets.quoteTokensToLP(
                params_.bucketCollateral,
                params_.bucketLP,
                scaledDepositAvailable,
                removedAmount_,
                params_.price,
                Math.Rounding.Up
            );
            redeemedLP_ = Maths.min(redeemedLP_, params_.lpConstraint);
            unscaledRemovedAmount = Maths.wdiv(removedAmount_, depositScale);
        } else if (scaledDepositAvailable < scaledLpConstraint) {
            // scaledDeposit is binding constraint
            removedAmount_ = scaledDepositAvailable;
            redeemedLP_    = Buckets.quoteTokensToLP(
                params_.bucketCollateral,
                params_.bucketLP,
                scaledDepositAvailable,
                removedAmount_,
                params_.price,
                Math.Rounding.Up
            );
            redeemedLP_ = Maths.min(redeemedLP_, params_.lpConstraint);
            unscaledRemovedAmount = unscaledDepositAvailable;
        } else {
            // redeeming all LP
            redeemedLP_    = params_.lpConstraint;
            removedAmount_ = Buckets.lpToQuoteTokens(
                params_.bucketCollateral,
                params_.bucketLP,
                scaledDepositAvailable,
                redeemedLP_,
                params_.price,
                Math.Rounding.Down
            );
            unscaledRemovedAmount = Maths.wdiv(removedAmount_, depositScale);
        }

        // If clearing out the bucket deposit, ensure it's zeroed out
        if (redeemedLP_ == params_.bucketLP) {
            removedAmount_ = scaledDepositAvailable;
            unscaledRemovedAmount = unscaledDepositAvailable;
        }

        unscaledRemaining_ = unscaledDepositAvailable - unscaledRemovedAmount;

        // revert if (due to rounding) required LP is 0
        if (redeemedLP_ == 0) revert InsufficientLP();
        // revert if calculated amount of quote to remove is 0
        if (unscaledRemovedAmount == 0) revert InvalidAmount();

        // update FenwickTree
        Deposits.unscaledRemove(deposits_, params_.index, unscaledRemovedAmount);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { PRBMathSD59x18 } from "@prb-math/contracts/PRBMathSD59x18.sol";
import { PRBMathUD60x18 } from "@prb-math/contracts/PRBMathUD60x18.sol";

import { InterestState, EmaState, PoolState, DepositsState } from '../../interfaces/pool/commons/IPoolState.sol';

import { _dwatp, _indexOf, MAX_FENWICK_INDEX, MIN_PRICE, MAX_PRICE } from '../helpers/PoolHelper.sol';

import { Deposits } from '../internal/Deposits.sol';
import { Buckets }  from '../internal/Buckets.sol';
import { Loans }    from '../internal/Loans.sol';
import { Maths }    from '../internal/Maths.sol';

/**
    @title  PoolCommons library
    @notice External library containing logic for common pool functionality:
            - interest rate accrual and interest rate params update
            - pool utilization
 */
library PoolCommons {

    /*****************/
    /*** Constants ***/
    /*****************/

    uint256 internal constant CUBIC_ROOT_1000000 = 100 * 1e18;
    uint256 internal constant ONE_THIRD          = 0.333333333333333334 * 1e18;

    uint256 internal constant INCREASE_COEFFICIENT = 1.1 * 1e18;
    uint256 internal constant DECREASE_COEFFICIENT = 0.9 * 1e18;
    int256  internal constant PERCENT_102          = 1.02 * 1e18;
    int256  internal constant NEG_H_MAU_HOURS      = -0.057762265046662105 * 1e18; // -ln(2)/12
    int256  internal constant NEG_H_TU_HOURS       = -0.008251752149523158 * 1e18; // -ln(2)/84

    /**************/
    /*** Events ***/
    /**************/

    // See `IPoolEvents` for descriptions
    event ResetInterestRate(uint256 oldRate, uint256 newRate);
    event UpdateInterestRate(uint256 oldRate, uint256 newRate);

    /*************************/
    /*** Local Var Structs ***/
    /*************************/

    /// @dev Struct used for `updateInterestState` function local vars.
    struct UpdateInterestLocalVars {
        uint256 debtEma;
        uint256 depositEma;
        uint256 debtColEma;
        uint256 lupt0DebtEma;
        uint256 t0Debt2ToCollateral;
        uint256 newMeaningfulDeposit;
        uint256 newDebt;
        uint256 newDebtCol;
        uint256 newLupt0Debt;
        uint256 lastEmaUpdate;
        int256 elapsed;
        int256 weightMau;
        int256 weightTu;
        uint256 newInterestRate;
        uint256 nonAuctionedT0Debt;
    }

    /**************************/
    /*** External Functions ***/
    /**************************/

    /**
     *  @notice Calculates EMAs, caches values required for calculating interest rate, and saves new values in storage.
     *  @notice Calculates new pool interest rate (Never called more than once every 12 hours) and saves new values in storage.
     *  @dev    === Write state ===
     *  @dev    `EMA`s state
     *  @dev    interest rate accumulator and `interestRateUpdate` state
     *  @dev    === Emit events ===
     *  @dev    - `UpdateInterestRate` / `ResetInterestRate`
     */
    function updateInterestState(
        InterestState storage interestParams_,
        EmaState      storage emaParams_,
        DepositsState storage deposits_,
        PoolState memory poolState_,
        uint256 lup_
    ) external {
        UpdateInterestLocalVars memory vars;
        // load existing EMA values
        vars.debtEma       = emaParams_.debtEma;
        vars.depositEma    = emaParams_.depositEma;
        vars.debtColEma    = emaParams_.debtColEma;
        vars.lupt0DebtEma  = emaParams_.lupt0DebtEma;
        vars.lastEmaUpdate = emaParams_.emaUpdate;

        vars.t0Debt2ToCollateral = interestParams_.t0Debt2ToCollateral;

        // calculate new interest params
        vars.nonAuctionedT0Debt = poolState_.t0Debt - poolState_.t0DebtInAuction;
        vars.newDebt = Maths.wmul(vars.nonAuctionedT0Debt, poolState_.inflator);
        // new meaningful deposit cannot be less than pool's debt
        vars.newMeaningfulDeposit = Maths.max(
            _meaningfulDeposit(
                deposits_,
                poolState_.t0DebtInAuction,
                vars.nonAuctionedT0Debt,
                poolState_.inflator,
                vars.t0Debt2ToCollateral
            ),
            vars.newDebt
        );
        vars.newDebtCol   = Maths.wmul(poolState_.inflator, vars.t0Debt2ToCollateral);
        vars.newLupt0Debt = Maths.wmul(lup_, vars.nonAuctionedT0Debt);

        // update EMAs only once per block
        if (vars.lastEmaUpdate != block.timestamp) {

            // first time EMAs are updated, initialize EMAs
            if (vars.lastEmaUpdate == 0) {
                vars.debtEma      = vars.newDebt;
                vars.depositEma   = vars.newMeaningfulDeposit;
                vars.debtColEma   = vars.newDebtCol;
                vars.lupt0DebtEma = vars.newLupt0Debt;
            } else {
                vars.elapsed   = int256(Maths.wdiv(block.timestamp - vars.lastEmaUpdate, 1 hours));
                vars.weightMau = PRBMathSD59x18.exp(PRBMathSD59x18.mul(NEG_H_MAU_HOURS, vars.elapsed));
                vars.weightTu  = PRBMathSD59x18.exp(PRBMathSD59x18.mul(NEG_H_TU_HOURS,  vars.elapsed));

                // calculate the t0 debt EMA, used for MAU
                vars.debtEma = uint256(
                    PRBMathSD59x18.mul(vars.weightMau, int256(vars.debtEma)) +
                    PRBMathSD59x18.mul(1e18 - vars.weightMau, int256(interestParams_.debt))
                );

                // update the meaningful deposit EMA, used for MAU
                vars.depositEma = uint256(
                    PRBMathSD59x18.mul(vars.weightMau, int256(vars.depositEma)) +
                    PRBMathSD59x18.mul(1e18 - vars.weightMau, int256(interestParams_.meaningfulDeposit))
                );

                // calculate the debt squared to collateral EMA, used for TU
                vars.debtColEma = uint256(
                    PRBMathSD59x18.mul(vars.weightTu, int256(vars.debtColEma)) +
                    PRBMathSD59x18.mul(1e18 - vars.weightTu, int256(interestParams_.debtCol))
                );

                // calculate the EMA of LUP * t0 debt
                vars.lupt0DebtEma = uint256(
                    PRBMathSD59x18.mul(vars.weightTu, int256(vars.lupt0DebtEma)) +
                    PRBMathSD59x18.mul(1e18 - vars.weightTu, int256(interestParams_.lupt0Debt))
                );
            }

            // save EMAs in storage
            emaParams_.debtEma      = vars.debtEma;
            emaParams_.depositEma   = vars.depositEma;
            emaParams_.debtColEma   = vars.debtColEma;
            emaParams_.lupt0DebtEma = vars.lupt0DebtEma;

            // save last EMA update time
            emaParams_.emaUpdate = block.timestamp;
        }

        // reset interest rate if pool rate > 10% and debtEma < 5% of depositEma
        if (
            poolState_.rate > 0.1 * 1e18
            &&
            vars.debtEma < Maths.wmul(vars.depositEma, 0.05 * 1e18)
        ) {
            interestParams_.interestRate       = uint208(0.1 * 1e18);
            interestParams_.interestRateUpdate = uint48(block.timestamp);

            emit ResetInterestRate(
                poolState_.rate,
                0.1 * 1e18
            );
        }
        // otherwise calculate and update interest rate if it has been more than 12 hours since the last update
        else if (block.timestamp - interestParams_.interestRateUpdate > 12 hours) {
            vars.newInterestRate = _calculateInterestRate(
                poolState_,
                vars.debtEma,
                vars.depositEma,
                vars.debtColEma,
                vars.lupt0DebtEma
            );

            if (poolState_.rate != vars.newInterestRate) {
                interestParams_.interestRate       = uint208(vars.newInterestRate);
                interestParams_.interestRateUpdate = uint48(block.timestamp);

                emit UpdateInterestRate(
                    poolState_.rate,
                    vars.newInterestRate
                );
            }
        }

        // save new interest rate params to storage
        interestParams_.debt              = vars.newDebt;
        interestParams_.meaningfulDeposit = vars.newMeaningfulDeposit;
        interestParams_.debtCol           = vars.newDebtCol;
        interestParams_.lupt0Debt         = vars.newLupt0Debt;
    }

    /**
     *  @notice Calculates new pool interest and scale the fenwick tree to update amount of debt owed to lenders (saved in storage).
     *  @dev    === Write state ===
     *  @dev    - `Deposits.mult` (scale `Fenwick` tree with new interest accrued):
     *  @dev      update `scaling` array state
     *  @param  emaParams_      Struct for pool `EMA`s state.
     *  @param  deposits_       Struct for pool deposits state.
     *  @param  poolState_      Current state of the pool.
     *  @param  thresholdPrice_ Current Pool Threshold Price.
     *  @param  elapsed_        Time elapsed since last inflator update.
     *  @return newInflator_    The new value of pool inflator.
     *  @return newInterest_    The new interest accrued.
     */
    function accrueInterest(
        EmaState      storage emaParams_,
        DepositsState storage deposits_,
        PoolState calldata poolState_,
        uint256 thresholdPrice_,
        uint256 elapsed_
    ) external returns (uint256 newInflator_, uint256 newInterest_) {
        // Scale the borrower inflator to update amount of interest owed by borrowers
        uint256 pendingFactor = PRBMathUD60x18.exp((poolState_.rate * elapsed_) / 365 days);

        // calculate the highest threshold price
        newInflator_ = Maths.wmul(poolState_.inflator, pendingFactor);
        uint256 htp = Maths.wmul(thresholdPrice_, newInflator_);

        uint256 accrualIndex;
        if (htp > MAX_PRICE)      accrualIndex = 1;                 // if HTP is over the highest price bucket then no buckets earn interest
        else if (htp < MIN_PRICE) accrualIndex = MAX_FENWICK_INDEX; // if HTP is under the lowest price bucket then all buckets earn interest
        else                      accrualIndex = _indexOf(htp);     // else HTP bucket earn interest

        uint256 lupIndex = Deposits.findIndexOfSum(deposits_, poolState_.debt);
        // accrual price is less of lup and htp, and prices decrease as index increases
        if (lupIndex > accrualIndex) accrualIndex = lupIndex;

        uint256 interestEarningDeposit = Deposits.prefixSum(deposits_, accrualIndex);

        if (interestEarningDeposit != 0) {
            newInterest_ = Maths.wmul(
                _lenderInterestMargin(_utilization(emaParams_.debtEma, emaParams_.depositEma)),
                Maths.wmul(pendingFactor - Maths.WAD, poolState_.debt)
            );

            // lender factor computation, capped at 10x the interest factor for borrowers
            uint256 lenderFactor = Maths.min(
                Maths.floorWdiv(newInterest_, interestEarningDeposit),
                Maths.wmul(pendingFactor - Maths.WAD, Maths.wad(10))
            ) + Maths.WAD;

            // Scale the fenwick tree to update amount of debt owed to lenders
            Deposits.mult(deposits_, accrualIndex, lenderFactor);
        }
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    /**
     *  @notice Calculates new pool interest rate.
     */
    function _calculateInterestRate(
        PoolState memory poolState_,
        uint256 debtEma_,
        uint256 depositEma_,
        uint256 debtColEma_,
        uint256 lupt0DebtEma_
    ) internal pure returns (uint256 newInterestRate_)  {
        // meaningful actual utilization
        int256 mau;
        // meaningful actual utilization * 1.02
        int256 mau102;

        if (poolState_.debt != 0) {
            // calculate meaningful actual utilization for interest rate update
            mau    = int256(_utilization(debtEma_, depositEma_));
            mau102 = mau * PERCENT_102 / 1e18;
        }

        // calculate target utilization
        int256 tu = (lupt0DebtEma_ != 0) ? 
            int256(Maths.wdiv(debtColEma_, lupt0DebtEma_)) : int(Maths.WAD);

        newInterestRate_ = poolState_.rate;

        // raise rates if 4*(tu-1.02*mau) < (tu+1.02*mau-1)^2-1
        if (4 * (tu - mau102) < (((tu + mau102 - 1e18) / 1e9) ** 2) - 1e18) {
            newInterestRate_ = Maths.wmul(poolState_.rate, INCREASE_COEFFICIENT);
        // decrease rates if 4*(tu-mau) > 1-(tu+mau-1)^2
        } else if (4 * (tu - mau) > 1e18 - ((tu + mau - 1e18) ** 2) / 1e18) {
            newInterestRate_ = Maths.wmul(poolState_.rate, DECREASE_COEFFICIENT);
        }

        // bound rates between 10 bps and 50000%
        newInterestRate_ = Maths.min(500 * 1e18, Maths.max(0.001 * 1e18, newInterestRate_));
    }

    /**
     *  @notice Calculates pool meaningful actual utilization.
     *  @param  debtEma_     `EMA` of pool debt.
     *  @param  depositEma_  `EMA` of meaningful pool deposit.
     *  @return utilization_ Pool meaningful actual utilization value.
     */
    function _utilization(
        uint256 debtEma_,
        uint256 depositEma_
    ) internal pure returns (uint256 utilization_) {
        if (depositEma_ != 0) utilization_ = Maths.wdiv(debtEma_, depositEma_);
    }

    /**
     *  @notice Calculates lender interest margin.
     *  @param  mau_ Meaningful actual utilization.
     *  @return The lender interest margin value.
     */
    function _lenderInterestMargin(
        uint256 mau_
    ) internal pure returns (uint256) {
        // Net Interest Margin = ((1 - MAU1)^(1/3) * 0.15)
        // Where MAU1 is MAU capped at 100% (min(MAU,1))
        // Lender Interest Margin = 1 - Net Interest Margin

        // PRBMath library forbids raising a number < 1e18 to a power.  Using the product and quotient rules of 
        // exponents, rewrite the equation with a coefficient s which provides sufficient precision:
        // Net Interest Margin = ((1 - MAU1) * s)^(1/3) / s^(1/3) * 0.15

        uint256 base = 1_000_000 * 1e18 - Maths.min(mau_, 1e18) * 1_000_000;
        // If unutilized deposit is infinitessimal, lenders get 100% of interest.
        if (base < 1e18) {
            return 1e18;
        } else {
            // cubic root of the percentage of meaningful unutilized deposit
            uint256 crpud = PRBMathUD60x18.pow(base, ONE_THIRD);
            // finish calculating Net Interest Margin, and then convert to Lender Interest Margin
            return 1e18 - Maths.wdiv(Maths.wmul(crpud, 0.15 * 1e18), CUBIC_ROOT_1000000);
        }
    }

    /**
     *  @notice Calculates pool's meaningful deposit.
     *  @param  deposits_            Struct for pool deposits state.
     *  @param  t0DebtInAuction_     Value of pool's t0 debt currently in auction.
     *  @param  nonAuctionedT0Debt_  Value of pool's t0 debt that is not in auction.
     *  @param  inflator_            Pool's current inflator.
     *  @param  t0Debt2ToCollateral_ `t0Debt2ToCollateral` ratio.
     *  @return meaningfulDeposit_   Pool's meaningful deposit.
     */
    function _meaningfulDeposit(
        DepositsState storage deposits_,
        uint256 t0DebtInAuction_,
        uint256 nonAuctionedT0Debt_,
        uint256 inflator_,
        uint256 t0Debt2ToCollateral_
    ) internal view returns (uint256 meaningfulDeposit_) {
        uint256 dwatp = _dwatp(nonAuctionedT0Debt_, inflator_, t0Debt2ToCollateral_);
        if (dwatp == 0) {
            meaningfulDeposit_ = Deposits.treeSum(deposits_);
        } else {
            if      (dwatp >= MAX_PRICE) meaningfulDeposit_ = 0;
            else if (dwatp >= MIN_PRICE) meaningfulDeposit_ = Deposits.prefixSum(deposits_, _indexOf(dwatp));
            else                         meaningfulDeposit_ = Deposits.treeSum(deposits_);
        }
        meaningfulDeposit_ -= Maths.min(
            meaningfulDeposit_,
            Maths.wmul(t0DebtInAuction_, inflator_)
        );
    }

    /**********************/
    /*** View Functions ***/
    /**********************/

    /**
     *  @notice Calculates pool interest factor for a given interest rate and time elapsed since last inflator update.
     *  @param  interestRate_   Current pool interest rate.
     *  @param  elapsed_        Time elapsed since last inflator update.
     *  @return The value of pool interest factor.
     */
    function pendingInterestFactor(
        uint256 interestRate_,
        uint256 elapsed_
    ) external pure returns (uint256) {
        return PRBMathUD60x18.exp((interestRate_ * elapsed_) / 365 days);
    }

    /**
     *  @notice Calculates pool pending inflator given the current inflator, time of last update and current interest rate.
     *  @param  inflator_      Current pool inflator.
     *  @param  inflatorUpdate Timestamp when inflator was updated.
     *  @param  interestRate_  The interest rate of the pool.
     *  @return The pending value of pool inflator.
     */
    function pendingInflator(
        uint256 inflator_,
        uint256 inflatorUpdate,
        uint256 interestRate_
    ) external view returns (uint256) {
        return Maths.wmul(
            inflator_,
            PRBMathUD60x18.exp((interestRate_ * (block.timestamp - inflatorUpdate)) / 365 days)
        );
    }

    /**
     *  @notice Calculates lender interest margin for a given meaningful actual utilization.
     *  @dev Wrapper of the internal function.
     */
    function lenderInterestMargin(
        uint256 mau_
    ) external pure returns (uint256) {
        return _lenderInterestMargin(mau_);
    }

    /**
     *  @notice Calculates pool meaningful actual utilization.
     *  @dev Wrapper of the internal function.
     */
    function utilization(
        EmaState storage emaParams_
    ) external view returns (uint256 utilization_) {
        return _utilization(emaParams_.debtEma, emaParams_.depositEma);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { PoolType } from '../../interfaces/pool/IPool.sol';

import {
    AuctionsState,
    Borrower,
    Bucket,
    DepositsState,
    Kicker,
    Liquidation,
    LoansState,
    PoolState,
    ReserveAuctionState
}                       from '../../interfaces/pool/commons/IPoolState.sol';
import {
    SettleParams,
    SettleResult
}                       from '../../interfaces/pool/commons/IPoolInternals.sol';

import {
    _auctionPrice,
    _indexOf,
    _priceAt,
    MAX_FENWICK_INDEX,
    MIN_PRICE,
    DEPOSIT_BUFFER   
}  from '../helpers/PoolHelper.sol';

import { Buckets }  from '../internal/Buckets.sol';
import { Deposits } from '../internal/Deposits.sol';
import { Loans }    from '../internal/Loans.sol';
import { Maths }    from '../internal/Maths.sol';

/**
    @title  Auction settler library
    @notice External library containing actions involving auctions within pool:
            - `settle` auctions
 */
library SettlerActions {

    /*************************/
    /*** Local Var Structs ***/
    /*************************/

    /// @dev Struct used for `_settlePoolDebtWithDeposit` function local vars.
    struct SettleLocalVars {
        uint256 collateralUsed;     // [WAD] collateral used to settle debt
        uint256 debt;               // [WAD] debt to settle
        uint256 hpbCollateral;      // [WAD] amount of collateral in HPB bucket
        uint256 hpbUnscaledDeposit; // [WAD] unscaled amount of of quote tokens in HPB bucket before settle
        uint256 hpbLP;              // [WAD] amount of LP in HPB bucket
        uint256 index;              // index of settling bucket
        uint256 maxSettleableDebt;  // [WAD] max amount that can be settled with existing collateral
        uint256 price;              // [WAD] price of settling bucket
        uint256 scaledDeposit;      // [WAD] scaled amount of quote tokens in bucket
        uint256 scale;              // [WAD] scale of settling bucket
        uint256 unscaledDeposit;    // [WAD] unscaled amount of quote tokens in bucket
    }

    /**************/
    /*** Events ***/
    /**************/

    // See `IPoolEvents` for descriptions
    event AuctionSettle(address indexed borrower, uint256 collateral);
    event AuctionNFTSettle(address indexed borrower, uint256 collateral, uint256 lp, uint256 index);
    event BucketBankruptcy(uint256 indexed index, uint256 lpForfeited);
    event Settle(address indexed borrower, uint256 settledDebt);

    /**************/
    /*** Errors ***/
    /**************/

    // See `IPoolErrors` for descriptions
    error AuctionNotClearable();
    error NoAuction();

    /***************************/
    /***  External Functions ***/
    /***************************/

    /**
     *  @notice See `IPoolSettlerActions` for descriptions.
     *  @notice Settles the debt of the given loan / borrower by performing following steps:
     *          1. settle debt with `HPB`s deposit, up to specified buckets depth.
     *          2. settle debt with pool reserves (if there's still debt and no collateral left after step 1).
     *          3. forgive bad debt from next `HPB`, up to remaining buckets depth (and if there's still debt after step 2).
     *  @dev    === Write state ===
     *  @dev    update borrower state
     *  @dev    === Reverts on ===
     *  @dev    loan is not in auction `NoAuction()`
     *  @dev    `72` hours didn't pass and auction still has collateral `AuctionNotClearable()`
     *  @dev    === Emit events ===
     *  @dev    - `Settle`
     *  @return result_ The `SettleResult` struct result of settle action.
     */
    function settlePoolDebt(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        LoansState storage loans_,
        ReserveAuctionState storage reserveAuction_,
        PoolState calldata poolState_,
        SettleParams memory params_
    ) external returns (SettleResult memory result_) {
        uint256 kickTime = auctions_.liquidations[params_.borrower].kickTime;
        if (kickTime == 0) revert NoAuction();

        Borrower memory borrower = loans_.borrowers[params_.borrower];
        if ((block.timestamp - kickTime < 72 hours) && (borrower.collateral != 0)) revert AuctionNotClearable();

        result_.debtPreAction       = borrower.t0Debt;
        result_.collateralPreAction = borrower.collateral;
        result_.t0DebtSettled       = borrower.t0Debt;
        result_.collateralSettled   = borrower.collateral;

        // 1. settle debt with HPB deposit
        (
            borrower.t0Debt,
            borrower.collateral,
            params_.bucketDepth
        ) = _settlePoolDebtWithDeposit(
            buckets_,
            deposits_,
            params_,
            borrower,
            poolState_.inflator
        );

        if (borrower.t0Debt != 0 && borrower.collateral == 0) {
            // 2. settle debt with pool reserves
            uint256 assets = Maths.floorWmul(poolState_.t0Debt - result_.t0DebtSettled + borrower.t0Debt, poolState_.inflator) + params_.poolBalance;

            uint256 liabilities =
                // require 1.0 + 1e-9 deposit buffer (extra margin) for deposits
                Maths.wmul(DEPOSIT_BUFFER, Deposits.treeSum(deposits_)) +
                auctions_.totalBondEscrowed +
                reserveAuction_.unclaimed;

            // settle debt from reserves (assets - liabilities) if reserves positive, round reserves down however
            if (assets > liabilities) {
                borrower.t0Debt -= Maths.min(borrower.t0Debt, Maths.floorWdiv(assets - liabilities, poolState_.inflator));
            }

            // 3. forgive bad debt from next HPB
            if (borrower.t0Debt != 0) {
                borrower.t0Debt = _forgiveBadDebt(
                    buckets_,
                    deposits_,
                    params_,
                    borrower,
                    poolState_.inflator
                );
            }
        }

        // complete result struct with debt settled
        result_.t0DebtSettled -= borrower.t0Debt;

        emit Settle(
            params_.borrower,
            result_.t0DebtSettled
        );

        // if entire debt was settled then settle auction
        if (borrower.t0Debt == 0) {
            (borrower.collateral, ) = _settleAuction(
                auctions_,
                buckets_,
                deposits_,
                params_.borrower,
                borrower.collateral,
                poolState_.poolType
            );
        }

        // complete result struct with debt and collateral post action and collateral settled
        result_.debtPostAction      = borrower.t0Debt;
        result_.collateralRemaining = borrower.collateral;
        result_.collateralSettled   -= result_.collateralRemaining;

        // update borrower state
        loans_.borrowers[params_.borrower] = borrower;
    }

    /***************************/
    /***  Internal Functions ***/
    /***************************/

    /**
     *  @notice Performs auction settle based on pool type, emits settle event and removes auction from auctions queue.
     *  @dev    === Emit events ===
     *  @dev    - `AuctionNFTSettle` or `AuctionSettle`
     *  @param  auctions_              Struct for pool auctions state.
     *  @param  buckets_               Struct for pool buckets state.
     *  @param  deposits_              Struct for pool deposits state.
     *  @param  borrowerAddress_       Address of the borrower that exits auction.
     *  @param  borrowerCollateral_    Borrower collateral amount before auction exit (in `NFT` could be fragmented as result of partial takes).
     *  @param  poolType_              Type of the pool (can be `ERC20` or `ERC721`).
     *  @return remainingCollateral_   Collateral remaining after auction is settled (same amount for `ERC20` pool, rounded collateral for `ERC721` pool).
     *  @return compensatedCollateral_ Amount of collateral compensated (`ERC721` settle only), to be deducted from pool pledged collateral accumulator. Always `0` for `ERC20` pools.
     */
    function _settleAuction(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        address borrowerAddress_,
        uint256 borrowerCollateral_,
        uint256 poolType_
    ) internal returns (uint256 remainingCollateral_, uint256 compensatedCollateral_) {

        if (poolType_ == uint8(PoolType.ERC721)) {
            uint256 lp;
            uint256 bucketIndex;

            // floor collateral of borrower
            remainingCollateral_ = (borrowerCollateral_ / Maths.WAD) * Maths.WAD;

            // if there's fraction of NFTs remaining then reward difference to borrower as LP in auction price bucket
            if (remainingCollateral_ != borrowerCollateral_) {

                // calculate the amount of collateral that should be compensated with LP
                compensatedCollateral_ = borrowerCollateral_ - remainingCollateral_;

                uint256 auctionPrice = _auctionPrice(
                    auctions_.liquidations[borrowerAddress_].kickMomp,
                    auctions_.liquidations[borrowerAddress_].neutralPrice,
                    auctions_.liquidations[borrowerAddress_].kickTime
                );

                // determine the bucket index to compensate fractional collateral
                bucketIndex = auctionPrice > MIN_PRICE ? _indexOf(auctionPrice) : MAX_FENWICK_INDEX;

                // deposit collateral in bucket and reward LP to compensate fractional collateral
                lp = Buckets.addCollateral(
                    buckets_[bucketIndex],
                    borrowerAddress_,
                    Deposits.valueAt(deposits_, bucketIndex),
                    compensatedCollateral_,
                    _priceAt(bucketIndex)
                );
            }

            emit AuctionNFTSettle(
                borrowerAddress_,
                remainingCollateral_,
                lp,
                bucketIndex
            );

        } else {
            remainingCollateral_ = borrowerCollateral_;

            emit AuctionSettle(
                borrowerAddress_,
                remainingCollateral_
            );
        }

        _removeAuction(auctions_, borrowerAddress_);
    }

    /**
     *  @notice Removes auction and repairs the queue order.
     *  @notice Updates kicker's claimable balance with bond size awarded and subtracts bond size awarded from `liquidationBondEscrowed`.
     *  @dev    === Write state ===
     *  @dev    decrement kicker locked accumulator, increment kicker claimable accumumlator
     *  @dev    decrement auctions count accumulator
     *  @dev    update auction queue state
     *  @param  auctions_ Struct for pool auctions state.
     *  @param  borrower_ Auctioned borrower address.
     */
    function _removeAuction(
        AuctionsState storage auctions_,
        address borrower_
    ) internal {
        Liquidation memory liquidation = auctions_.liquidations[borrower_];
        // update kicker balances
        Kicker storage kicker = auctions_.kickers[liquidation.kicker];

        kicker.locked    -= liquidation.bondSize;
        kicker.claimable += liquidation.bondSize;

        // decrement number of active auctions
        -- auctions_.noOfAuctions;

        // update auctions queue
        if (auctions_.head == borrower_ && auctions_.tail == borrower_) {
            // liquidation is the head and tail
            auctions_.head = address(0);
            auctions_.tail = address(0);
        }
        else if(auctions_.head == borrower_) {
            // liquidation is the head
            auctions_.liquidations[liquidation.next].prev = address(0);
            auctions_.head = liquidation.next;
        }
        else if(auctions_.tail == borrower_) {
            // liquidation is the tail
            auctions_.liquidations[liquidation.prev].next = address(0);
            auctions_.tail = liquidation.prev;
        }
        else {
            // liquidation is in the middle
            auctions_.liquidations[liquidation.prev].next = liquidation.next;
            auctions_.liquidations[liquidation.next].prev = liquidation.prev;
        }
        // delete liquidation
        delete auctions_.liquidations[borrower_];
    }

    /**
     *  @notice Called to settle debt using `HPB` deposits, up to the number of specified buckets depth.
     *  @dev    === Write state ===
     *  @dev    - `Deposits.unscaledRemove()` (remove amount in `Fenwick` tree, from index):
     *  @dev      update `values` array state
     *  @dev    - `Buckets.addCollateral`:
     *  @dev      increment `bucket.collateral` and `bucket.lps` accumulator
     *  @dev      increment `lender.lps` accumulator and `lender.depositTime` state
     *  @dev    === Emit events ===
     *  @dev    - `BucketBankruptcy`
     *  @param  buckets_             Struct for pool buckets state.
     *  @param  deposits_            Struct for pool deposits state.
     *  @param  params_              Struct containing params for settle action.
     *  @param  borrower_            Struct containing borrower details.
     *  @param  inflator_            Current pool inflator.
     *  @return remainingt0Debt_     Remaining borrower `t0` debt after settle with `HPB`.
     *  @return remainingCollateral_ Remaining borrower collateral after settle with `HPB`.
     *  @return bucketDepth_         Number of buckets to use for forgiving debt in case there's more remaining.
     */
    function _settlePoolDebtWithDeposit(
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        SettleParams memory params_,
        Borrower memory borrower_,
        uint256 inflator_
    ) internal returns (uint256 remainingt0Debt_, uint256 remainingCollateral_, uint256 bucketDepth_) {
        remainingt0Debt_     = borrower_.t0Debt;
        remainingCollateral_ = borrower_.collateral;
        bucketDepth_         = params_.bucketDepth;

        while (bucketDepth_ != 0 && remainingt0Debt_ != 0 && remainingCollateral_ != 0) {
            SettleLocalVars memory vars;

            (vars.index, , vars.scale) = Deposits.findIndexAndSumOfSum(deposits_, 1);
            vars.hpbUnscaledDeposit    = Deposits.unscaledValueAt(deposits_, vars.index);
            vars.unscaledDeposit       = vars.hpbUnscaledDeposit;
            vars.price                 = _priceAt(vars.index);

            if (vars.unscaledDeposit != 0) {
                vars.debt              = Maths.wmul(remainingt0Debt_, inflator_);           // current debt to be settled
                vars.maxSettleableDebt = Maths.floorWmul(remainingCollateral_, vars.price); // max debt that can be settled with existing collateral
                vars.scaledDeposit     = Maths.wmul(vars.scale, vars.unscaledDeposit);

                // 1) bucket deposit covers remaining loan debt to settle, loan's collateral can cover remaining loan debt to settle
                if (vars.scaledDeposit >= vars.debt && vars.maxSettleableDebt >= vars.debt) {
                    // remove only what's needed to settle the debt
                    vars.unscaledDeposit = Maths.wdiv(vars.debt, vars.scale);
                    vars.collateralUsed  = Maths.ceilWdiv(vars.debt, vars.price);

                    // settle the entire debt
                    remainingt0Debt_ = 0;
                }
                // 2) bucket deposit can not cover all of loan's remaining debt, bucket deposit is the constraint
                else if (vars.maxSettleableDebt >= vars.scaledDeposit) {
                    vars.collateralUsed = Maths.ceilWdiv(vars.scaledDeposit, vars.price);

                    // subtract from debt the corresponding t0 amount of deposit
                    remainingt0Debt_ -= Maths.floorWdiv(vars.scaledDeposit, inflator_);
                }
                // 3) loan's collateral can not cover remaining loan debt to settle, loan collateral is the constraint
                else {
                    vars.unscaledDeposit = Maths.wdiv(vars.maxSettleableDebt, vars.scale);
                    vars.collateralUsed  = remainingCollateral_;

                    remainingt0Debt_ -= Maths.floorWdiv(vars.maxSettleableDebt, inflator_);
                }

                // remove settled collateral from loan
                remainingCollateral_ -= vars.collateralUsed;

                // use HPB bucket to swap loan collateral for loan debt
                Bucket storage hpb = buckets_[vars.index];
                vars.hpbLP         = hpb.lps;
                vars.hpbCollateral = hpb.collateral + vars.collateralUsed;

                // set amount to remove as min of calculated amount and available deposit (to prevent rounding issues)
                vars.unscaledDeposit    = Maths.min(vars.hpbUnscaledDeposit, vars.unscaledDeposit);
                vars.hpbUnscaledDeposit -= vars.unscaledDeposit;

                // remove amount to settle debt from bucket (could be entire deposit or only the settled debt)
                Deposits.unscaledRemove(deposits_, vars.index, vars.unscaledDeposit);

                // check if bucket healthy - set bankruptcy if collateral is 0 and entire deposit was used to settle and there's still LP
                if (vars.hpbCollateral == 0 && vars.hpbUnscaledDeposit == 0 && vars.hpbLP != 0) {
                    hpb.lps            = 0;
                    hpb.bankruptcyTime = block.timestamp;

                    emit BucketBankruptcy(
                        vars.index,
                        vars.hpbLP
                    );
                } else {
                    // add settled collateral into bucket
                    hpb.collateral = vars.hpbCollateral;
                }

            } else {
                // Deposits in the tree is zero, insert entire collateral into lowest bucket 7388
                Buckets.addCollateral(
                    buckets_[vars.index],
                    params_.borrower,
                    0,  // zero deposit in bucket
                    remainingCollateral_,
                    vars.price
                );
                // entire collateral added into bucket, no borrower pledged collateral remaining
                remainingCollateral_ = 0;
            }

            --bucketDepth_;
        }
    }

    /**
     *  @notice Called to forgive bad debt starting from next `HPB`, up to the number of remaining buckets depth.
     *  @dev    === Write state ===
     *  @dev    - `Deposits.unscaledRemove()` (remove amount in `Fenwick` tree, from index):
     *  @dev      update `values` array state
     *  @dev      reset `bucket.lps` accumulator and update `bucket.bankruptcyTime`
     *  @dev    === Emit events ===
     *  @dev    - `BucketBankruptcy`
     *  @param  buckets_         Struct for pool buckets state.
     *  @param  deposits_        Struct for pool deposits state.
     *  @param  params_          Struct containing params for settle action.
     *  @param  borrower_        Struct containing borrower details.
     *  @param  inflator_        Current pool inflator.
     *  @return remainingt0Debt_ Remaining borrower `t0` debt after forgiving bad debt in case not enough buckets used.
     */
    function _forgiveBadDebt(
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        SettleParams memory params_,
        Borrower memory borrower_,
        uint256 inflator_
    ) internal returns (uint256 remainingt0Debt_) {
        remainingt0Debt_ = borrower_.t0Debt;

        // loop through remaining buckets if there's still debt to forgive
        while (params_.bucketDepth != 0 && remainingt0Debt_ != 0) {

            (uint256 index, , uint256 scale) = Deposits.findIndexAndSumOfSum(deposits_, 1);
            uint256 unscaledDeposit          = Deposits.unscaledValueAt(deposits_, index);
            uint256 depositToRemove          = Maths.wmul(scale, unscaledDeposit);
            uint256 debt                     = Maths.wmul(remainingt0Debt_, inflator_);
            uint256 depositRemaining;

            // 1) bucket deposit covers entire loan debt to settle, no constraints needed
            if (depositToRemove >= debt) {
                // no remaining debt to forgive
                remainingt0Debt_ = 0;

                uint256 depositUsed = Maths.wdiv(debt, scale);
                depositRemaining = unscaledDeposit - depositUsed;

                // Remove deposit used to forgive bad debt from bucket
                Deposits.unscaledRemove(deposits_, index, depositUsed);

            // 2) loan debt to settle exceeds bucket deposit, bucket deposit is the constraint
            } else {
                // subtract from remaining debt the corresponding t0 amount of deposit
                remainingt0Debt_ -= Maths.floorWdiv(depositToRemove, inflator_);

                // Remove all deposit from bucket
                Deposits.unscaledRemove(deposits_, index, unscaledDeposit);
            }

            Bucket storage hpbBucket = buckets_[index];
            uint256 bucketLP = hpbBucket.lps;
            // If the remaining deposit and resulting bucket collateral is so small that the exchange rate
            // rounds to 0, then bankrupt the bucket.  Note that lhs are WADs, so the
            // quantity is naturally 1e18 times larger than the actual product
            if (depositRemaining * Maths.WAD + hpbBucket.collateral * _priceAt(index) <= bucketLP) {
                // existing LP for the bucket shall become unclaimable
                hpbBucket.lps            = 0;
                hpbBucket.bankruptcyTime = block.timestamp;

                emit BucketBankruptcy(
                    index,
                    bucketLP
                );
            }

            --params_.bucketDepth;
        }
    }

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { PRBMathSD59x18 } from "@prb-math/contracts/PRBMathSD59x18.sol";
import { Math }           from '@openzeppelin/contracts/utils/math/Math.sol';

import { PoolType } from '../../interfaces/pool/IPool.sol';

import {
    AuctionsState,
    Borrower,
    Bucket,
    BurnEvent,
    DepositsState,
    Liquidation,
    LoansState,
    PoolState,
    ReserveAuctionState
}                        from '../../interfaces/pool/commons/IPoolState.sol';
import {
    TakeResult
}                        from '../../interfaces/pool/commons/IPoolInternals.sol';

import {
    _auctionPrice,
    _bpf,
    _isCollateralized,
    _priceAt,
    _reserveAuctionPrice,
    _roundToScale
}                           from '../helpers/PoolHelper.sol';
import { _revertOnMinDebt } from '../helpers/RevertsHelper.sol';

import { SettlerActions } from './SettlerActions.sol';

import { Buckets }  from '../internal/Buckets.sol';
import { Deposits } from '../internal/Deposits.sol';
import { Loans }    from '../internal/Loans.sol';
import { Maths }    from '../internal/Maths.sol';

/**
    @title  Auction Taker Actions library
    @notice External library containing actions involving taking auctions within pool:
            - `take` and `bucketTake` auctioned collateral; take reserves
 */
library TakerActions {

    /*******************************/
    /*** Function Params Structs ***/
    /*******************************/

    /// @dev Struct used to hold `bucketTake` function params.
    struct BucketTakeParams {
        address borrower;        // borrower address to take from
        bool    depositTake;     // deposit or arb take, used by bucket take
        uint256 index;           // bucket index, used by bucket take
        uint256 inflator;        // [WAD] current pool inflator
        uint256 collateralScale; // precision of collateral token based on decimals
    }

    /// @dev Struct used to hold `take` function params.
    struct TakeParams {
        address borrower;        // borrower address to take from
        uint256 takeCollateral;  // [WAD] desired amount to take
        uint256 inflator;        // [WAD] current pool inflator
        uint256 poolType;        // pool type (ERC20 or NFT)
        uint256 collateralScale; // precision of collateral token based on decimals
    }

    /*************************/
    /*** Local Var Structs ***/
    /*************************/

    /// @dev Struct used for `take` function local vars.
    struct TakeLocalVars {
        uint256 auctionPrice;             // [WAD] The price of auction.
        uint256 bondChange;               // [WAD] The change made on the bond size (beeing reward or penalty).
        uint256 borrowerDebt;             // [WAD] The accrued debt of auctioned borrower.
        int256  bpf;                      // The bond penalty factor.
        uint256 bucketPrice;              // [WAD] The bucket price.
        uint256 bucketScale;              // [WAD] The bucket scale.
        uint256 collateralAmount;         // [WAD] The amount of collateral taken.
        uint256 excessQuoteToken;         // [WAD] Difference of quote token that borrower receives after take (for fractional NFT only)
        uint256 factor;                   // The take factor, calculated based on bond penalty factor.
        bool    isRewarded;               // True if kicker is rewarded (auction price lower than neutral price), false if penalized (auction price greater than neutral price).
        address kicker;                   // Address of auction kicker.
        uint256 quoteTokenAmount;         // [WAD] Scaled quantity in Fenwick tree and before 1-bpf factor, paid for collateral
        uint256 t0RepayAmount;            // [WAD] The amount of debt (quote tokens) that is recovered / repayed by take t0 terms.
        uint256 t0BorrowerDebt;           // [WAD] Borrower's t0 debt.
        uint256 t0DebtPenalty;            // [WAD] Borrower's t0 penalty - 7% from current debt if intial take, 0 otherwise.
        uint256 unscaledDeposit;          // [WAD] Unscaled bucket quantity
        uint256 unscaledQuoteTokenAmount; // [WAD] The unscaled token amount that taker should pay for collateral taken.
    }

    /**************/
    /*** Events ***/
    /**************/

    // See `IPoolEvents` for descriptions
    event BucketTake(address indexed borrower, uint256 index, uint256 amount, uint256 collateral, uint256 bondChange, bool isReward);
    event BucketTakeLPAwarded(address indexed taker, address indexed kicker, uint256 lpAwardedTaker, uint256 lpAwardedKicker);
    event Take(address indexed borrower, uint256 amount, uint256 collateral, uint256 bondChange, bool isReward);
    event ReserveAuction(uint256 claimableReservesRemaining, uint256 auctionPrice, uint256 currentBurnEpoch);

    /**************/
    /*** Errors ***/
    /**************/

    // See `IPoolErrors` for descriptions
    error AuctionPriceGtBucketPrice();
    error CollateralRoundingNeededButNotPossible();
    error InsufficientLiquidity();
    error InsufficientCollateral();
    error InvalidAmount();
    error NoAuction();
    error NoReserves();
    error NoReservesAuction();
    error ReserveAuctionTooSoon();
    error TakeNotPastCooldown();

    /***************************/
    /***  External Functions ***/
    /***************************/

    /**
     *  @notice See `IPoolTakerActions` for descriptions.
     *  @notice Performs bucket take collateral on an auction, rewards taker and kicker (if case) and updates loan info (settles auction if case).
     *  @dev    === Reverts on ===
     *  @dev    not enough collateral to take `InsufficientCollateral()`
     *  @return result_ `TakeResult` struct containing details of bucket take result.
    */
    function bucketTake(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        LoansState storage loans_,
        PoolState memory poolState_,
        address borrowerAddress_,
        bool    depositTake_,
        uint256 index_,
        uint256 collateralScale_
    ) external returns (TakeResult memory result_) {
        Borrower memory borrower = loans_.borrowers[borrowerAddress_];
        // revert if borrower's collateral is 0
        if (borrower.collateral == 0) revert InsufficientCollateral();

        result_.debtPreAction       = borrower.t0Debt;
        result_.collateralPreAction = borrower.collateral;

        // bucket take auction
        TakeLocalVars memory vars = _takeBucket(
            auctions_,
            buckets_,
            deposits_,
            borrower,
            BucketTakeParams({
                borrower:        borrowerAddress_,
                inflator:        poolState_.inflator,
                depositTake:     depositTake_,
                index:           index_,
                collateralScale: collateralScale_
            })
        );

        // update borrower after take
        borrower.collateral -= vars.collateralAmount;
        borrower.t0Debt     = vars.t0BorrowerDebt - vars.t0RepayAmount;
        // update pool params after take
        poolState_.t0Debt += vars.t0DebtPenalty;
        poolState_.t0Debt -= vars.t0RepayAmount;
        poolState_.debt   = Maths.wmul(poolState_.t0Debt, poolState_.inflator);

        // update loan after take
        (
            result_.newLup,
            result_.settledAuction,
            result_.remainingCollateral,
            result_.compensatedCollateral
        ) = _takeLoan(auctions_, buckets_, deposits_, loans_, poolState_, borrower, borrowerAddress_);

        // complete take result struct
        result_.debtPostAction       = borrower.t0Debt;
        result_.collateralPostAction = borrower.collateral;
        result_.t0PoolDebt           = poolState_.t0Debt;
        result_.poolDebt             = poolState_.debt;
        result_.collateralAmount     = vars.collateralAmount;
        result_.t0DebtPenalty        = vars.t0DebtPenalty;
        // if settled then debt in auction changed is the entire borrower debt, otherwise only repaid amount
        result_.t0DebtInAuctionChange = result_.settledAuction ? vars.t0BorrowerDebt : vars.t0RepayAmount;
    }

    /**
     *  @notice See `IPoolTakerActions` for descriptions.
     *  @notice Performs take collateral on an auction, rewards taker and kicker (if case) and updates loan info (settles auction if case).
     *  @dev    === Reverts on ===
     *  @dev    insufficient collateral to take `InsufficientCollateral()`
     *  @return result_ `TakeResult` struct containing details of take result.
    */
    function take(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        LoansState storage loans_,
        PoolState memory poolState_,
        address borrowerAddress_,
        uint256 collateral_,
        uint256 collateralScale_
    ) external returns (TakeResult memory result_) {
        // revert if no amount to take
        if (collateral_ == 0) revert InvalidAmount();

        Borrower memory borrower = loans_.borrowers[borrowerAddress_];

        if (
            // revert in case of NFT take when there isn't a full token to be taken
            (poolState_.poolType == uint8(PoolType.ERC721) && borrower.collateral < 1e18) ||
            // revert in case of ERC20 take when no collateral to be taken
            (poolState_.poolType == uint8(PoolType.ERC20)  && borrower.collateral == 0)
        ) {
            revert InsufficientCollateral();
        }

        result_.debtPreAction       = borrower.t0Debt;
        result_.collateralPreAction = borrower.collateral;

        // take auction
        TakeLocalVars memory vars = _take(
            auctions_,
            borrower,
            TakeParams({
                borrower:        borrowerAddress_,
                takeCollateral:  collateral_,
                inflator:        poolState_.inflator,
                poolType:        poolState_.poolType,
                collateralScale: collateralScale_
            })
        );

        // update borrower after take
        borrower.collateral -= vars.collateralAmount;
        borrower.t0Debt     = vars.t0BorrowerDebt - vars.t0RepayAmount;
        // update pool params after take
        poolState_.t0Debt += vars.t0DebtPenalty;
        poolState_.t0Debt -= vars.t0RepayAmount;
        poolState_.debt   = Maths.wmul(poolState_.t0Debt, poolState_.inflator);

        // update loan after take
        (
            result_.newLup,
            result_.settledAuction,
            result_.remainingCollateral,
            result_.compensatedCollateral
        ) = _takeLoan(auctions_, buckets_, deposits_, loans_, poolState_, borrower, borrowerAddress_);

        // complete take result struct
        result_.debtPostAction       = borrower.t0Debt;
        result_.collateralPostAction = borrower.collateral;
        result_.t0PoolDebt           = poolState_.t0Debt;
        result_.poolDebt             = poolState_.debt;
        result_.collateralAmount     = vars.collateralAmount;
        result_.t0DebtPenalty        = vars.t0DebtPenalty;
        result_.quoteTokenAmount     = vars.quoteTokenAmount;
        result_.excessQuoteToken     = vars.excessQuoteToken;
        // if settled then debt in auction changed is the entire borrower debt, otherwise only repaid amount
        result_.t0DebtInAuctionChange = result_.settledAuction ? vars.t0BorrowerDebt : vars.t0RepayAmount;
    }

    /*************************/
    /***  Reserve Auction  ***/
    /*************************/

    /**
     *  @notice See `IPoolTakerActions` for descriptions.
     *  @dev    === Write state ===
     *  @dev    decrement `reserveAuction.unclaimed` accumulator
     *  @dev    === Reverts on ===
     *  @dev    not kicked or `72` hours didn't pass `NoReservesAuction()`
     *  @dev    === Emit events ===
     *  @dev    - `ReserveAuction`
     */
    function takeReserves(
        ReserveAuctionState storage reserveAuction_,
        uint256 maxAmount_
    ) external returns (uint256 amount_, uint256 ajnaRequired_) {
        // revert if no amount to be taken
        if (maxAmount_ == 0) revert InvalidAmount();

        uint256 kicked = reserveAuction_.kicked;

        if (kicked != 0 && block.timestamp - kicked <= 72 hours) {
            uint256 unclaimed = reserveAuction_.unclaimed;
            uint256 price     = _reserveAuctionPrice(kicked);

            amount_       = Maths.min(unclaimed, maxAmount_);
            ajnaRequired_ = Maths.ceilWmul(amount_, price);

            unclaimed -= amount_;

            reserveAuction_.unclaimed = unclaimed;

            uint256 totalBurned = reserveAuction_.totalAjnaBurned + ajnaRequired_;
            
            // accumulate additional ajna burned
            reserveAuction_.totalAjnaBurned = totalBurned;

            uint256 burnEventEpoch = reserveAuction_.latestBurnEventEpoch;

            // record burn event information to enable querying by staking rewards
            BurnEvent storage burnEvent = reserveAuction_.burnEvents[burnEventEpoch];
            burnEvent.totalInterest = reserveAuction_.totalInterestEarned;
            burnEvent.totalBurned   = totalBurned;

            emit ReserveAuction(
                unclaimed,
                price,
                burnEventEpoch
            );
        } else {
            revert NoReservesAuction();
        }
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    /**
     *  @notice Performs take collateral on an auction and updates bond size and kicker balance accordingly.
     *  @dev    === Emit events ===
     *  @dev    - `Take`
     *  @param  auctions_ Struct for pool auctions state.
     *  @param  borrower_ Struct containing auctioned borrower details.
     *  @param  params_   Struct containing take action params details.
     *  @return vars_     Struct containing auction take vars.
    */
    function _take(
        AuctionsState storage auctions_,
        Borrower memory borrower_,
        TakeParams memory params_
    ) internal returns (TakeLocalVars memory vars_) {
        Liquidation storage liquidation = auctions_.liquidations[params_.borrower];

        vars_ = _prepareTake(
            liquidation,
            borrower_.t0Debt,
            borrower_.collateral,
            params_.inflator
        );

        // These are placeholder max values passed to calculateTakeFlows because there is no explicit bound on the
        // quote token amount in take calls (as opposed to bucketTake)
        vars_.unscaledDeposit = type(uint256).max;
        vars_.bucketScale     = Maths.WAD;

        uint256 takeableCollateral = borrower_.collateral;
        // for NFT take make sure the take flow and bond change calculation happens for the rounded collateral that can be taken
        if (params_.poolType == uint8(PoolType.ERC721)) {
            takeableCollateral = (takeableCollateral / 1e18) * 1e18;
        }

        // In the case of take, the taker binds the collateral qty but not the quote token qty
        // ugly to get take work like a bucket take -- this is the max amount of quote token from the take that could go to
        // reduce the debt of the borrower -- analagous to the amount of deposit in the bucket for a bucket take
        vars_ = _calculateTakeFlowsAndBondChange(
            Maths.min(takeableCollateral, params_.takeCollateral),
            params_.inflator,
            params_.collateralScale,
            vars_
        );

        _rewardTake(auctions_, liquidation, vars_);

        emit Take(
            params_.borrower,
            vars_.quoteTokenAmount,
            vars_.collateralAmount,
            vars_.bondChange,
            vars_.isRewarded
        );

        if (params_.poolType == uint8(PoolType.ERC721)) {
            // slither-disable-next-line divide-before-multiply
            uint256 collateralTaken = (vars_.collateralAmount / 1e18) * 1e18; // solidity rounds down, so if 2.5 it will be 2.5 / 1 = 2

            // collateral taken not a round number
            if (collateralTaken != vars_.collateralAmount) {
                if (Maths.min(borrower_.collateral, params_.takeCollateral) >= collateralTaken + 1e18) {
                    // round up collateral to take
                    collateralTaken += 1e18;

                    // taker should send additional quote tokens to cover difference between collateral needed to be taken and rounded collateral, at auction price
                    // borrower will get quote tokens for the difference between rounded collateral and collateral taken to cover debt
                    vars_.excessQuoteToken = Maths.wmul(collateralTaken - vars_.collateralAmount, vars_.auctionPrice);
                    vars_.collateralAmount = collateralTaken;
                } else {
                    // shouldn't get here, but just in case revert
                    revert CollateralRoundingNeededButNotPossible();
                }
            }
        }
    }

    /**
     *  @notice Performs bucket take collateral on an auction and rewards taker and kicker (if case).
     *  @dev    === Emit events ===
     *  @dev    - `BucketTake`
     *  @param  auctions_ Struct for pool auctions state.
     *  @param  buckets_  Struct for pool buckets state.
     *  @param  deposits_ Struct for pool deposits state.
     *  @param  borrower_ Struct containing auctioned borrower details.
     *  @param  params_   Struct containing take action details.
     *  @return vars_     Struct containing auction take vars.
    */
    function _takeBucket(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        Borrower memory borrower_,
        BucketTakeParams memory params_
    ) internal returns (TakeLocalVars memory vars_) {
        Liquidation storage liquidation = auctions_.liquidations[params_.borrower];

        vars_= _prepareTake(
            liquidation,
            borrower_.t0Debt,
            borrower_.collateral,
            params_.inflator
        );

        vars_.unscaledDeposit = Deposits.unscaledValueAt(deposits_, params_.index);

        // revert if no quote tokens in arbed bucket
        if (vars_.unscaledDeposit == 0) revert InsufficientLiquidity();

        vars_.bucketPrice  = _priceAt(params_.index);

        // cannot arb with a price lower than the auction price
        if (vars_.auctionPrice > vars_.bucketPrice) revert AuctionPriceGtBucketPrice();
        
        // if deposit take then price to use when calculating take is bucket price
        if (params_.depositTake) vars_.auctionPrice = vars_.bucketPrice;

        vars_.bucketScale = Deposits.scale(deposits_, params_.index);

        vars_ = _calculateTakeFlowsAndBondChange(
            borrower_.collateral,
            params_.inflator,
            params_.collateralScale,
            vars_
        );

        // revert if bucket deposit cannot cover at least one unit of collateral
        if (vars_.collateralAmount == 0) revert InsufficientLiquidity();

        _rewardBucketTake(
            auctions_,
            deposits_,
            buckets_,
            liquidation,
            params_.index,
            params_.depositTake,
            vars_
        );

        emit BucketTake(
            params_.borrower,
            params_.index,
            vars_.quoteTokenAmount,
            vars_.collateralAmount,
            vars_.bondChange,
            vars_.isRewarded
        );
    }

    /**
     *  @notice Performs update of an auctioned loan that was taken (using bucket or regular take).
     *  @notice If borrower becomes recollateralized then auction is settled. Update loan's state.
     *  @dev    === Reverts on ===
     *  @dev    borrower debt less than pool min debt `AmountLTMinDebt()`
     *  @param  auctions_              Struct for pool auctions state.
     *  @param  buckets_               Struct for pool buckets state.
     *  @param  deposits_              Struct for pool deposits state.
     *  @param  loans_                 Struct for pool loans state.
     *  @param  poolState_             Struct containing pool details.
     *  @param  borrower_              The borrower details owning loan that is taken.
     *  @param  borrowerAddress_       The address of the borrower.
     *  @return newLup_                The new `LUP` of pool (after debt is repaid).
     *  @return settledAuction_        True if auction is settled by the take action. (`NFT` take: rebalance borrower collateral in pool if true)
     *  @return remainingCollateral_   Borrower collateral remaining after take action. (`NFT` take: collateral to be rebalanced in case of `NFT` settlement)
     *  @return compensatedCollateral_ Amount of collateral compensated, to be deducted from pool pledged collateral accumulator.
    */
    function _takeLoan(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        LoansState storage loans_,
        PoolState memory poolState_,
        Borrower memory borrower_,
        address borrowerAddress_
    ) internal returns (
        uint256 newLup_,
        bool settledAuction_,
        uint256 remainingCollateral_,
        uint256 compensatedCollateral_
    ) {

        uint256 borrowerDebt = Maths.wmul(borrower_.t0Debt, poolState_.inflator);

        // check that taking from loan doesn't leave borrower debt under min debt amount
        _revertOnMinDebt(
            loans_,
            poolState_.debt,
            borrowerDebt,
            poolState_.quoteTokenScale
        );

        // calculate new lup with repaid debt from take
        newLup_ = Deposits.getLup(deposits_, poolState_.debt);

        remainingCollateral_ = borrower_.collateral;

        if (_isCollateralized(borrowerDebt, borrower_.collateral, newLup_, poolState_.poolType)) {
            settledAuction_ = true;

            // settle auction and update borrower's collateral with value after settlement
            (remainingCollateral_, compensatedCollateral_) = SettlerActions._settleAuction(
                auctions_,
                buckets_,
                deposits_,
                borrowerAddress_,
                borrower_.collateral,
                poolState_.poolType
            );

            borrower_.collateral = remainingCollateral_;
        }

        // update loan state, stamp borrower t0Np only when exiting from auction
        Loans.update(
            loans_,
            auctions_,
            deposits_,
            borrower_,
            borrowerAddress_,
            poolState_.debt,
            poolState_.rate,
            newLup_,
            !settledAuction_,
            settledAuction_ // stamp borrower t0Np if exiting from auction
        );
    }

    /**
     *  @notice Rewards actors of a regular take action.
     *  @dev    === Write state ===
     *  @dev    update liquidation `bond size` accumulator
     *  @dev    update kicker's `locked balance` accumulator
     *  @dev    update `auctions.totalBondEscrowed` accumulator
     *  @param  auctions_     Struct for pool auctions state.
     *  @param  liquidation_  Struct containing details of auction.
     *  @param  vars          Struct containing take action result details.
     */
    function _rewardTake(
        AuctionsState storage auctions_,
        Liquidation storage liquidation_,
        TakeLocalVars memory vars
    ) internal {
        if (vars.isRewarded) {
            // take is below neutralPrice, Kicker is rewarded
            liquidation_.bondSize                 += uint160(vars.bondChange);
            auctions_.kickers[vars.kicker].locked += vars.bondChange;
            auctions_.totalBondEscrowed           += vars.bondChange;
        } else {
            // take is above neutralPrice, Kicker is penalized
            vars.bondChange = Maths.min(liquidation_.bondSize, vars.bondChange);

            liquidation_.bondSize                 -= uint160(vars.bondChange);
            auctions_.kickers[vars.kicker].locked -= vars.bondChange;
            auctions_.totalBondEscrowed           -= vars.bondChange;
        }
    }

    /**
     *  @notice Rewards actors of a bucket take action.
     *  @dev    === Write state ===
     *  @dev    - `Buckets.addLenderLP`:
     *  @dev      increment taker `lender.lps` accumulator and `lender.depositTime` state
     *  @dev      increment kicker `lender.lps` accumulator and l`ender.depositTime` state
     *  @dev    - update liquidation bond size accumulator
     *  @dev    - update kicker's locked balance accumulator
     *  @dev    - update `auctions.totalBondEscrowed` accumulator
     *  @dev    - `Deposits.unscaledRemove()` (remove amount in `Fenwick` tree, from index):
     *  @dev      update `values` array state
     *  @dev    - increment `bucket.collateral` and `bucket.lps` accumulator
     *  @dev    === Emit events ===
     *  @dev    - `BucketTakeLPAwarded`
     *  @param  auctions_     Struct for pool auctions state.
     *  @param  deposits_     Struct for pool deposits state.
     *  @param  buckets_      Struct for pool buckets state.
     *  @param  liquidation_  Struct containing details of auction to be taken from.
     *  @param  bucketIndex_  Index of a bucket, likely the `HPB`, in which collateral will be deposited.
     *  @param  depositTake_  If `true` then the take will happen at an auction price equal with bucket price. Auction price is used otherwise.
     *  @param  vars          Struct containing bucket take action result details.
     */
    function _rewardBucketTake(
        AuctionsState storage auctions_,
        DepositsState storage deposits_,
        mapping(uint256 => Bucket) storage buckets_,
        Liquidation storage liquidation_,
        uint256 bucketIndex_,
        bool depositTake_,
        TakeLocalVars memory vars
    ) internal {
        Bucket storage bucket = buckets_[bucketIndex_];

        uint256 bankruptcyTime = bucket.bankruptcyTime;
        uint256 scaledDeposit  = Maths.wmul(vars.unscaledDeposit, vars.bucketScale);
        uint256 totalLPReward;
        uint256 takerLPReward;
        uint256 kickerLPReward;

        // if arb take - taker is awarded collateral * (bucket price - auction price) worth (in quote token terms) units of LPB in the bucket
        if (!depositTake_) {
            takerLPReward = Buckets.quoteTokensToLP(
                bucket.collateral,
                bucket.lps,
                scaledDeposit,
                Maths.wmul(vars.collateralAmount, vars.bucketPrice - vars.auctionPrice),
                vars.bucketPrice,
                Math.Rounding.Down
            );
            totalLPReward = takerLPReward;

            Buckets.addLenderLP(bucket, bankruptcyTime, msg.sender, takerLPReward);
        }

        // the bondholder/kicker is awarded bond change worth of LPB in the bucket
        if (vars.isRewarded) {
            kickerLPReward = Buckets.quoteTokensToLP(
                bucket.collateral,
                bucket.lps,
                scaledDeposit,
                vars.bondChange,
                vars.bucketPrice,
                Math.Rounding.Down
            );
            totalLPReward  += kickerLPReward;

            Buckets.addLenderLP(bucket, bankruptcyTime, vars.kicker, kickerLPReward);
        } else {
            // take is above neutralPrice, Kicker is penalized
            vars.bondChange = Maths.min(liquidation_.bondSize, vars.bondChange);

            liquidation_.bondSize -= uint160(vars.bondChange);

            auctions_.kickers[vars.kicker].locked -= vars.bondChange;
            auctions_.totalBondEscrowed           -= vars.bondChange;
        }

        // remove quote tokens from bucket’s deposit
        Deposits.unscaledRemove(deposits_, bucketIndex_, vars.unscaledQuoteTokenAmount);

        // total rewarded LP are added to the bucket LP balance
        if (totalLPReward != 0) bucket.lps += totalLPReward;
        // collateral is added to the bucket’s claimable collateral
        bucket.collateral += vars.collateralAmount;

        emit BucketTakeLPAwarded(
            msg.sender,
            vars.kicker,
            takerLPReward,
            kickerLPReward
        );
    }

    /**
     *  @notice Utility function to validate take and calculate take's parameters.
     *  @dev    write state:
     *              - update liquidation.alreadyTaken state
     *  @dev    reverts on:
     *              - loan is not in auction NoAuction()
     *              - in 1 hour cool down period TakeNotPastCooldown()
     *  @param  liquidation_ Liquidation struct holding auction details.
     *  @param  t0Debt_      Borrower t0 debt.
     *  @param  collateral_  Borrower collateral.
     *  @param  inflator_    The pool's inflator, used to calculate borrower debt.
     *  @return vars         The prepared vars for take action.
     */
    function _prepareTake(
        Liquidation storage liquidation_,
        uint256 t0Debt_,
        uint256 collateral_,
        uint256 inflator_
    ) internal returns (TakeLocalVars memory vars) {

        uint256 kickTime = liquidation_.kickTime;
        if (kickTime == 0) revert NoAuction();
        if (block.timestamp - kickTime <= 1 hours) revert TakeNotPastCooldown();

        vars.t0BorrowerDebt = t0Debt_;

        // if first take borrower debt is increased by 7% penalty
        if (!liquidation_.alreadyTaken) {
            vars.t0DebtPenalty  = Maths.wmul(t0Debt_, 0.07 * 1e18);
            vars.t0BorrowerDebt += vars.t0DebtPenalty;

            liquidation_.alreadyTaken = true;
        }

        vars.borrowerDebt = Maths.wmul(vars.t0BorrowerDebt, inflator_);

        uint256 neutralPrice = liquidation_.neutralPrice;

        vars.auctionPrice = _auctionPrice(liquidation_.kickMomp, neutralPrice, kickTime);
        vars.bpf          = _bpf(
            vars.borrowerDebt,
            collateral_,
            neutralPrice,
            liquidation_.bondFactor,
            vars.auctionPrice
        );
        vars.factor       = uint256(1e18 - Maths.maxInt(0, vars.bpf));
        vars.kicker       = liquidation_.kicker;
        vars.isRewarded   = (vars.bpf  >= 0);
    }

    /**
     *  @notice Computes the flows of collateral, quote token between the borrower, lender and kicker.
     *  @param  totalCollateral_        Total collateral in loan.
     *  @param  inflator_               Current pool inflator.
     *  @param  vars                    TakeParams for the take/buckettake
     */
    function _calculateTakeFlowsAndBondChange(
        uint256              totalCollateral_,
        uint256              inflator_,
        uint256              collateralScale_,
        TakeLocalVars memory vars
    ) internal pure returns (
        TakeLocalVars memory
    ) {
        // price is the current auction price, which is the price paid by the LENDER for collateral
        // from the borrower point of view, the price is actually (1-bpf) * price, as the rewards to the
        // bond holder are effectively paid for by the borrower.
        uint256 borrowerPayoffFactor = (vars.isRewarded) ? Maths.WAD - uint256(vars.bpf)                       : Maths.WAD;
        uint256 borrowerPrice        = (vars.isRewarded) ? Maths.wmul(borrowerPayoffFactor, vars.auctionPrice) : vars.auctionPrice;

        // If there is no unscaled quote token bound, then we pass in max, but that cannot be scaled without an overflow.  So we check in the line below.
        vars.quoteTokenAmount = (vars.unscaledDeposit != type(uint256).max) ? Maths.wmul(vars.unscaledDeposit, vars.bucketScale) : type(uint256).max;

        uint256 borrowerCollateralValue = Maths.wmul(totalCollateral_, borrowerPrice);
        
        if (vars.quoteTokenAmount <= vars.borrowerDebt && vars.quoteTokenAmount <= borrowerCollateralValue) {
            // quote token used to purchase is constraining factor
            vars.collateralAmount         = _roundToScale(Maths.wdiv(vars.quoteTokenAmount, borrowerPrice), collateralScale_);
            vars.t0RepayAmount            = Maths.wdiv(vars.quoteTokenAmount, inflator_);
            vars.unscaledQuoteTokenAmount = vars.unscaledDeposit;

            vars.quoteTokenAmount         = Maths.wmul(vars.collateralAmount, vars.auctionPrice);

        } else if (vars.borrowerDebt <= borrowerCollateralValue) {
            // borrower debt is constraining factor
            vars.collateralAmount         = _roundToScale(Maths.wdiv(vars.borrowerDebt, borrowerPrice), collateralScale_);
            vars.t0RepayAmount            = vars.t0BorrowerDebt;
            vars.unscaledQuoteTokenAmount = Maths.wdiv(vars.borrowerDebt, vars.bucketScale);

            vars.quoteTokenAmount         = (vars.isRewarded) ? Maths.wdiv(vars.borrowerDebt, borrowerPayoffFactor) : vars.borrowerDebt;

        } else {
            // collateral available is constraint
            vars.collateralAmount         = totalCollateral_;
            vars.t0RepayAmount            = Maths.wdiv(borrowerCollateralValue, inflator_);
            vars.unscaledQuoteTokenAmount = Maths.wdiv(borrowerCollateralValue, vars.bucketScale);

            vars.quoteTokenAmount         = Maths.wmul(vars.collateralAmount, vars.auctionPrice);
        }

        if (vars.isRewarded) {
            // take is below neutralPrice, Kicker is rewarded
            vars.bondChange = Maths.wmul(vars.quoteTokenAmount, uint256(vars.bpf));
        } else {
            // take is above neutralPrice, Kicker is penalized
            vars.bondChange = Maths.wmul(vars.quoteTokenAmount, uint256(-vars.bpf));
        }

        return vars;
    }

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { PRBMathSD59x18 } from "@prb-math/contracts/PRBMathSD59x18.sol";
import { Math }           from '@openzeppelin/contracts/utils/math/Math.sol';

import { PoolType } from '../../interfaces/pool/IPool.sol';

import { Buckets } from '../internal/Buckets.sol';
import { Maths }   from '../internal/Maths.sol';

    error BucketIndexOutOfBounds();
    error BucketPriceOutOfBounds();

    /*************************/
    /*** Price Conversions ***/
    /*************************/

    /// @dev constant price indices defining the min and max of the potential price range
    int256  constant MAX_BUCKET_INDEX  =  4_156;
    int256  constant MIN_BUCKET_INDEX  = -3_232;
    uint256 constant MAX_FENWICK_INDEX =  7_388;

    uint256 constant MIN_PRICE = 99_836_282_890;
    uint256 constant MAX_PRICE = 1_004_968_987.606512354182109771 * 1e18;

    uint256 constant MAX_NEUTRAL_PRICE = 50_248_449_380.325617709105488550 * 1e18; // 50 * MAX_PRICE

    /// @dev deposit buffer (extra margin) used for calculating reserves
    uint256 constant DEPOSIT_BUFFER = 1.000000001 * 1e18;

    /// @dev step amounts in basis points. This is a constant across pools at `0.005`, achieved by dividing `WAD` by `10,000`
    int256 constant FLOAT_STEP_INT = 1.005 * 1e18;

    /**
     *  @notice Calculates the price (`WAD` precision) for a given `Fenwick` index.
     *  @dev    Reverts with `BucketIndexOutOfBounds` if index exceeds maximum constant.
     *  @dev    Uses fixed-point math to get around lack of floating point numbers in `EVM`.
     *  @dev    Fenwick index is converted to bucket index.
     *  @dev    Fenwick index to bucket index conversion:
     *  @dev      `1.00`      : bucket index `0`,     fenwick index `4156`: `7388-4156-3232=0`.
     *  @dev      `MAX_PRICE` : bucket index `4156`,  fenwick index `0`:    `7388-0-3232=4156`.
     *  @dev      `MIN_PRICE` : bucket index - `3232`, fenwick index `7388`: `7388-7388-3232=-3232`.
     *  @dev    `V1`: `price = MIN_PRICE + (FLOAT_STEP * index)`
     *  @dev    `V2`: `price = MAX_PRICE * (FLOAT_STEP ** (abs(int256(index - MAX_PRICE_INDEX))));`
     *  @dev    `V3 (final)`: `x^y = 2^(y*log_2(x))`
     */
    function _priceAt(
        uint256 index_
    ) pure returns (uint256) {
        // Lowest Fenwick index is highest price, so invert the index and offset by highest bucket index.
        int256 bucketIndex = MAX_BUCKET_INDEX - int256(index_);
        if (bucketIndex < MIN_BUCKET_INDEX || bucketIndex > MAX_BUCKET_INDEX) revert BucketIndexOutOfBounds();

        return uint256(
            PRBMathSD59x18.exp2(
                PRBMathSD59x18.mul(
                    PRBMathSD59x18.fromInt(bucketIndex),
                    PRBMathSD59x18.log2(FLOAT_STEP_INT)
                )
            )
        );
    }

    /**
     *  @notice Calculates the  Fenwick  index for a given price.
     *  @dev    Reverts with `BucketPriceOutOfBounds` if price exceeds maximum constant.
     *  @dev    Price expected to be inputted as a `WAD` (`18` decimal).
     *  @dev    `V1`: `bucket index = (price - MIN_PRICE) / FLOAT_STEP`
     *  @dev    `V2`: `bucket index = (log(FLOAT_STEP) * price) /  MAX_PRICE`
     *  @dev    `V3 (final)`: `bucket index =  log_2(price) / log_2(FLOAT_STEP)`
     *  @dev    `Fenwick index = 7388 - bucket index + 3232`
     */
    function _indexOf(
        uint256 price_
    ) pure returns (uint256) {
        if (price_ < MIN_PRICE || price_ > MAX_PRICE) revert BucketPriceOutOfBounds();

        int256 index = PRBMathSD59x18.div(
            PRBMathSD59x18.log2(int256(price_)),
            PRBMathSD59x18.log2(FLOAT_STEP_INT)
        );

        int256 ceilIndex = PRBMathSD59x18.ceil(index);
        if (index < 0 && ceilIndex - index > 0.5 * 1e18) {
            return uint256(4157 - PRBMathSD59x18.toInt(ceilIndex));
        }
        return uint256(4156 - PRBMathSD59x18.toInt(ceilIndex));
    }

    /**********************/
    /*** Pool Utilities ***/
    /**********************/

    /**
     *  @notice Calculates the minimum debt amount that can be borrowed or can remain in a loan in pool.
     *  @param  debt_          The debt amount to calculate minimum debt amount for.
     *  @param  loansCount_    The number of loans in pool.
     *  @return minDebtAmount_ Minimum debt amount value of the pool.
     */
    function _minDebtAmount(
        uint256 debt_,
        uint256 loansCount_
    ) pure returns (uint256 minDebtAmount_) {
        if (loansCount_ != 0) {
            minDebtAmount_ = Maths.wdiv(Maths.wdiv(debt_, Maths.wad(loansCount_)), 10**19);
        }
    }

    /**
     *  @notice Calculates origination fee for a given interest rate.
     *  @notice Calculated as greater of the current annualized interest rate divided by `52` (one week of interest) or `5` bps.
     *  @param  interestRate_ The current interest rate.
     *  @return Fee rate based upon the given interest rate.
     */
    function _borrowFeeRate(
        uint256 interestRate_
    ) pure returns (uint256) {
        // greater of the current annualized interest rate divided by 52 (one week of interest) or 5 bps
        return Maths.max(Maths.wdiv(interestRate_, 52 * 1e18), 0.0005 * 1e18);
    }

    /**
     * @notice Calculates the unutilized deposit fee, charged to lenders who deposit below the `LUP`.
     * @param  interestRate_ The current interest rate.
     * @return Fee rate based upon the given interest rate, capped at 10%.
     */
    function _depositFeeRate(
        uint256 interestRate_
    ) pure returns (uint256) {
        // current annualized rate divided by 365 (24 hours of interest), capped at 10%
        return Maths.min(Maths.wdiv(interestRate_, 365 * 1e18), 0.1 * 1e18);
    }

    /**
     *  @notice Calculates debt-weighted average threshold price.
     *  @param  t0Debt_              Pool debt owed by borrowers in `t0` terms.
     *  @param  inflator_            Pool's borrower inflator.
     *  @param  t0Debt2ToCollateral_ `t0-debt-squared-to-collateral` accumulator. 
     */
    function _dwatp(
        uint256 t0Debt_,
        uint256 inflator_,
        uint256 t0Debt2ToCollateral_
    ) pure returns (uint256) {
        return t0Debt_ == 0 ? 0 : Maths.wdiv(Maths.wmul(inflator_, t0Debt2ToCollateral_), t0Debt_);
    }

    /**
     *  @notice Collateralization calculation.
     *  @param debt_       Debt to calculate collateralization for.
     *  @param collateral_ Collateral to calculate collateralization for.
     *  @param price_      Price to calculate collateralization for.
     *  @param type_       Type of the pool.
     *  @return `True` if collateralization calculated is equal or greater than `1`.
     */
    function _isCollateralized(
        uint256 debt_,
        uint256 collateral_,
        uint256 price_,
        uint8 type_
    ) pure returns (bool) {
        if (type_ == uint8(PoolType.ERC20)) return Maths.wmul(collateral_, price_) >= debt_;
        else {
            //slither-disable-next-line divide-before-multiply
            collateral_ = (collateral_ / Maths.WAD) * Maths.WAD; // use collateral floor
            return Maths.wmul(collateral_, price_) >= debt_;
        }
    }

    /**
     *  @notice Price precision adjustment used in calculating collateral dust for a bucket.
     *          To ensure the accuracy of the exchange rate calculation, buckets with smaller prices require
     *          larger minimum amounts of collateral.  This formula imposes a lower bound independent of token scale.
     *  @param  bucketIndex_              Index of the bucket, or `0` for encumbered collateral with no bucket affinity.
     *  @return pricePrecisionAdjustment_ Unscaled integer of the minimum number of decimal places the dust limit requires.
     */
    function _getCollateralDustPricePrecisionAdjustment(
        uint256 bucketIndex_
    ) pure returns (uint256 pricePrecisionAdjustment_) {
        // conditional is a gas optimization
        if (bucketIndex_ > 3900) {
            int256 bucketOffset = int256(bucketIndex_ - 3900);
            int256 result = PRBMathSD59x18.sqrt(PRBMathSD59x18.div(bucketOffset * 1e18, int256(36 * 1e18)));
            pricePrecisionAdjustment_ = uint256(result / 1e18);
        }
    }

    /**
     *  @notice Returns the amount of collateral calculated for the given amount of `LP`.
     *  @dev    The value returned is capped at collateral amount available in bucket.
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  bucketLP_         Amount of `LP` in bucket.
     *  @param  deposit_          Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / `LP`.
     *  @param  lenderLPBalance_  The amount of `LP` to calculate collateral for.
     *  @param  bucketPrice_      Bucket's price.
     *  @return collateralAmount_ Amount of collateral calculated for the given `LP `amount.
     */
    function _lpToCollateral(
        uint256 bucketCollateral_,
        uint256 bucketLP_,
        uint256 deposit_,
        uint256 lenderLPBalance_,
        uint256 bucketPrice_
    ) pure returns (uint256 collateralAmount_) {
        collateralAmount_ = Buckets.lpToCollateral(
            bucketCollateral_,
            bucketLP_,
            deposit_,
            lenderLPBalance_,
            bucketPrice_,
            Math.Rounding.Down
        );

        if (collateralAmount_ > bucketCollateral_) {
            // user is owed more collateral than is available in the bucket
            collateralAmount_ = bucketCollateral_;
        }
    }

    /**
     *  @notice Returns the amount of quote tokens calculated for the given amount of `LP`.
     *  @dev    The value returned is capped at available bucket deposit.
     *  @param  bucketLP_         Amount of `LP` in bucket.
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  deposit_          Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / `LP`.
     *  @param  lenderLPBalance_  The amount of `LP` to calculate quote token amount for.
     *  @param  maxQuoteToken_    The max quote token amount to calculate `LP` for.
     *  @param  bucketPrice_      Bucket's price.
     *  @return quoteTokenAmount_ Amount of quote tokens calculated for the given `LP` amount, capped at available bucket deposit.
     */
    function _lpToQuoteToken(
        uint256 bucketLP_,
        uint256 bucketCollateral_,
        uint256 deposit_,
        uint256 lenderLPBalance_,
        uint256 maxQuoteToken_,
        uint256 bucketPrice_
    ) pure returns (uint256 quoteTokenAmount_) {
        quoteTokenAmount_ = Buckets.lpToQuoteTokens(
            bucketCollateral_,
            bucketLP_,
            deposit_,
            lenderLPBalance_,
            bucketPrice_,
            Math.Rounding.Down
        );

        if (quoteTokenAmount_ > deposit_)       quoteTokenAmount_ = deposit_;
        if (quoteTokenAmount_ > maxQuoteToken_) quoteTokenAmount_ = maxQuoteToken_;
    }

    /**
     *  @notice Rounds a token amount down to the minimum amount permissible by the token scale.
     *  @param  amount_       Value to be rounded.
     *  @param  tokenScale_   Scale of the token, presented as a power of `10`.
     *  @return scaledAmount_ Rounded value.
     */
    function _roundToScale(
        uint256 amount_,
        uint256 tokenScale_
    ) pure returns (uint256 scaledAmount_) {
        scaledAmount_ = (amount_ / tokenScale_) * tokenScale_;
    }

    /**
     *  @notice Rounds a token amount up to the next amount permissible by the token scale.
     *  @param  amount_       Value to be rounded.
     *  @param  tokenScale_   Scale of the token, presented as a power of `10`.
     *  @return scaledAmount_ Rounded value.
     */
    function _roundUpToScale(
        uint256 amount_,
        uint256 tokenScale_
    ) pure returns (uint256 scaledAmount_) {
        if (amount_ % tokenScale_ == 0)
            scaledAmount_ = amount_;
        else
            scaledAmount_ = _roundToScale(amount_, tokenScale_) + tokenScale_;
    }

    /*********************************/
    /*** Reserve Auction Utilities ***/
    /*********************************/

    uint256 constant MINUTE_HALF_LIFE    = 0.988514020352896135_356867505 * 1e27;  // 0.5^(1/60)

    /**
     *  @notice Calculates claimable reserves within the pool.
     *  @dev    Claimable reserve auctions and escrowed auction bonds are guaranteed by the pool.
     *  @param  debt_                    Pool's debt.
     *  @param  poolSize_                Pool's deposit size.
     *  @param  totalBondEscrowed_       Total bond escrowed.
     *  @param  reserveAuctionUnclaimed_ Pool's unclaimed reserve auction.
     *  @param  quoteTokenBalance_       Pool's quote token balance.
     *  @return claimable_               Calculated pool reserves.
     */  
    function _claimableReserves(
        uint256 debt_,
        uint256 poolSize_,
        uint256 totalBondEscrowed_,
        uint256 reserveAuctionUnclaimed_,
        uint256 quoteTokenBalance_
    ) pure returns (uint256 claimable_) {
        uint256 guaranteedFunds = totalBondEscrowed_ + reserveAuctionUnclaimed_;

        // calculate claimable reserves if there's quote token excess
        if (quoteTokenBalance_ > guaranteedFunds) {
            claimable_ = Maths.wmul(0.995 * 1e18, debt_) + quoteTokenBalance_;

            claimable_ -= Maths.min(
                claimable_,
                // require 1.0 + 1e-9 deposit buffer (extra margin) for deposits
                Maths.wmul(DEPOSIT_BUFFER, poolSize_) + guaranteedFunds
            );

            // incremental claimable reserve should not exceed excess quote in pool
            claimable_ = Maths.min(
                claimable_,
                quoteTokenBalance_ - guaranteedFunds
            );
        }
    }

    /**
     *  @notice Calculates reserves auction price.
     *  @param  reserveAuctionKicked_ Time when reserve auction was started (kicked).
     *  @return price_                Calculated auction price.
     */     
    function _reserveAuctionPrice(
        uint256 reserveAuctionKicked_
    ) view returns (uint256 price_) {
        if (reserveAuctionKicked_ != 0) {
            uint256 secondsElapsed   = block.timestamp - reserveAuctionKicked_;
            uint256 hoursComponent   = 1e27 >> secondsElapsed / 3600;
            uint256 minutesComponent = Maths.rpow(MINUTE_HALF_LIFE, secondsElapsed % 3600 / 60);

            price_ = Maths.rayToWad(1_000_000_000 * Maths.rmul(hoursComponent, minutesComponent));
        }
    }

    /*************************/
    /*** Auction Utilities ***/
    /*************************/

    /**
     *  @notice Calculates auction price.
     *  @param  kickMomp_     `MOMP` recorded at the time of kick.
     *  @param  neutralPrice_ `Neutral Price` of the auction.
     *  @param  kickTime_      Time when auction was kicked.
     *  @return price_         Calculated auction price.
     */
    function _auctionPrice(
        uint256 kickMomp_,
        uint256 neutralPrice_,
        uint256 kickTime_
    ) view returns (uint256 price_) {
        uint256 elapsedHours = Maths.wdiv((block.timestamp - kickTime_) * 1e18, 1 hours * 1e18);

        elapsedHours -= Maths.min(elapsedHours, 1e18);  // price locked during cure period

        int256 timeAdjustment  = PRBMathSD59x18.mul(-1 * 1e18, int256(elapsedHours)); 
        uint256 referencePrice = Maths.max(kickMomp_, neutralPrice_); 

        price_ = 32 * Maths.wmul(referencePrice, uint256(PRBMathSD59x18.exp2(timeAdjustment)));
    }

    /**
     *  @notice Calculates bond penalty factor.
     *  @dev    Called in kick and take.
     *  @param debt_         Borrower debt.
     *  @param collateral_   Borrower collateral.
     *  @param neutralPrice_ `NP` of auction.
     *  @param bondFactor_   Factor used to determine bondSize.
     *  @param auctionPrice_ Auction price at the time of call.
     *  @return bpf_         Factor used in determining bond `reward` (positive) or `penalty` (negative).
     */
    function _bpf(
        uint256 debt_,
        uint256 collateral_,
        uint256 neutralPrice_,
        uint256 bondFactor_,
        uint256 auctionPrice_
    ) pure returns (int256) {
        int256 thresholdPrice = int256(Maths.wdiv(debt_, collateral_));

        int256 sign;
        if (thresholdPrice < int256(neutralPrice_)) {
            // BPF = BondFactor * min(1, max(-1, (neutralPrice - price) / (neutralPrice - thresholdPrice)))
            sign = Maths.minInt(
                1e18,
                Maths.maxInt(
                    -1 * 1e18,
                    PRBMathSD59x18.div(
                        int256(neutralPrice_) - int256(auctionPrice_),
                        int256(neutralPrice_) - thresholdPrice
                    )
                )
            );
        } else {
            int256 val = int256(neutralPrice_) - int256(auctionPrice_);
            if (val < 0 )      sign = -1e18;
            else if (val != 0) sign = 1e18;
        }

        return PRBMathSD59x18.mul(int256(bondFactor_), sign);
    }

    /**
     *  @notice Calculates bond parameters of an auction.
     *  @param  borrowerDebt_ Borrower's debt before entering in liquidation.
     *  @param  collateral_   Borrower's collateral before entering in liquidation.
     *  @param  momp_         Current pool `momp`.
     */
    function _bondParams(
        uint256 borrowerDebt_,
        uint256 collateral_,
        uint256 momp_
    ) pure returns (uint256 bondFactor_, uint256 bondSize_) {
        uint256 thresholdPrice = borrowerDebt_  * Maths.WAD / collateral_;

        // bondFactor = min(30%, max(1%, (MOMP - thresholdPrice) / MOMP))
        if (thresholdPrice >= momp_) {
            bondFactor_ = 0.01 * 1e18;
        } else {
            bondFactor_ = Maths.min(
                0.3 * 1e18,
                Maths.max(
                    0.01 * 1e18,
                    1e18 - Maths.wdiv(thresholdPrice, momp_)
                )
            );
        }

        bondSize_ = Maths.wmul(bondFactor_,  borrowerDebt_);
    }

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import {
    AuctionsState,
    Borrower,
    DepositsState,
    LoansState,
    PoolBalancesState
} from '../../interfaces/pool/commons/IPoolState.sol';

import { _minDebtAmount, _priceAt } from './PoolHelper.sol';

import { Loans }    from '../internal/Loans.sol';
import { Deposits } from '../internal/Deposits.sol';
import { Maths }    from '../internal/Maths.sol';

    // See `IPoolErrors` for descriptions
    error AuctionNotCleared();
    error AmountLTMinDebt();
    error DustAmountNotExceeded();
    error LimitIndexExceeded();
    error RemoveDepositLockedByAuctionDebt();
    error TransactionExpired();

    /**
     *  @notice Called by `LP` removal functions assess whether or not `LP` is locked.
     *  @dev    Reverts with `RemoveDepositLockedByAuctionDebt` if debt locked.
     *  @param  t0DebtInAuction_ Pool's t0 debt currently in auction.
     *  @param  index_           The deposit index from which `LP` is attempting to be removed.
     *  @param  inflator_        The pool inflator used to properly assess t0 debt in auctions.
     */
    function _revertIfAuctionDebtLocked(
        DepositsState storage deposits_,
        uint256 t0DebtInAuction_,
        uint256 index_,
        uint256 inflator_
    ) view {
        if (t0DebtInAuction_ != 0 ) {
            // deposit in buckets within liquidation debt from the top-of-book down are frozen.
            if (index_ <= Deposits.findIndexOfSum(deposits_, Maths.wmul(t0DebtInAuction_, inflator_))) revert RemoveDepositLockedByAuctionDebt();
        } 
    }

    /**
     *  @notice Check if head auction is clearable (auction is kicked and `72` hours passed since kick time or auction still has debt but no remaining collateral).
     *  @dev    Reverts with `AuctionNotCleared` if auction is clearable.
     */
    function _revertIfAuctionClearable(
        AuctionsState storage auctions_,
        LoansState    storage loans_
    ) view {
        address head     = auctions_.head;
        uint256 kickTime = auctions_.liquidations[head].kickTime;
        if (kickTime != 0) {
            if (block.timestamp - kickTime > 72 hours) revert AuctionNotCleared();

            Borrower storage borrower = loans_.borrowers[head];
            if (borrower.t0Debt != 0 && borrower.collateral == 0) revert AuctionNotCleared();
        }
    }

    /**
     *  @notice  Check if provided price is at or above index limit provided by borrower.
     *  @notice  Prevents stale transactions and certain `MEV` manipulations.
     *  @dev     Reverts with `LimitIndexExceeded` if index limit provided exceeded.
     *  @param newPrice_   New price to be compared with given limit price (can be `LUP`, `NP`).
     *  @param limitIndex_ Limit price index provided by user creating the transaction.
     */
    function _revertIfPriceDroppedBelowLimit(
        uint256 newPrice_,
        uint256 limitIndex_
    ) pure {
        if (newPrice_ < _priceAt(limitIndex_)) revert LimitIndexExceeded();
    }

    /**
     *  @notice Check if expiration provided by user has met or exceeded current block height timestamp.
     *  @notice Prevents stale transactions interacting with the pool at potentially unfavorable prices.
     *  @dev    Reverts with `TransactionExpired` if expired.
     *  @param  expiry_ Expiration provided by user when creating the transaction.
     */
    function _revertAfterExpiry(
        uint256 expiry_
    ) view {
        if (block.timestamp > expiry_) revert TransactionExpired();
    }

    /**
     *  @notice Called when borrower debt changes, ensuring minimum debt rules are honored.
     *  @dev    Reverts with `DustAmountNotExceeded` if under dust amount or with `AmountLTMinDebt` if amount under min debt value.
     *  @param  loans_        Loans heap, used to determine loan count.
     *  @param  poolDebt_     Total pool debt, used to calculate average debt.
     *  @param  borrowerDebt_ New debt for the borrower, assuming the current transaction succeeds.
     *  @param  quoteDust_    Smallest amount of quote token when can be transferred, determined by token scale.
     */
    function _revertOnMinDebt(
        LoansState storage loans_,
        uint256 poolDebt_,
        uint256 borrowerDebt_,
        uint256 quoteDust_
    ) view {
        if (borrowerDebt_ != 0) {
            if (borrowerDebt_ < quoteDust_) revert DustAmountNotExceeded();
            uint256 loansCount = Loans.noOfLoans(loans_);
            if (loansCount >= 10)
                if (borrowerDebt_ < _minDebtAmount(poolDebt_, loansCount)) revert AmountLTMinDebt();
        }
    }

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { Math } from '@openzeppelin/contracts/utils/math/Math.sol';

import { Bucket, Lender } from '../../interfaces/pool/commons/IPoolState.sol';

import { Maths } from './Maths.sol';

/**
    @title  Buckets library
    @notice Internal library containing common logic for buckets management.
 */
library Buckets {

    /**************/
    /*** Events ***/
    /**************/

    // See `IPoolError` for descriptions
    error BucketBankruptcyBlock();

    /***********************************/
    /*** Bucket Management Functions ***/
    /***********************************/

    /**
     *  @notice Add collateral to a bucket and updates `LP` for bucket and lender with the amount coresponding to collateral amount added.
     *  @dev    Increment `bucket.collateral` and `bucket.lps` accumulator
     *  @dev    - `addLenderLP`:
     *  @dev    increment `lender.lps` accumulator and `lender.depositTime` state
     *  @param  lender_                Address of the lender.
     *  @param  deposit_               Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / `LP`.
     *  @param  collateralAmountToAdd_ Additional collateral amount to add to bucket.
     *  @param  bucketPrice_           Bucket price.
     *  @return addedLP_               Amount of bucket `LP` for the collateral amount added.
     */
    function addCollateral(
        Bucket storage bucket_,
        address lender_,
        uint256 deposit_,
        uint256 collateralAmountToAdd_,
        uint256 bucketPrice_
    ) internal returns (uint256 addedLP_) {
        // cannot deposit in the same block when bucket becomes insolvent
        uint256 bankruptcyTime = bucket_.bankruptcyTime;
        if (bankruptcyTime == block.timestamp) revert BucketBankruptcyBlock();

        // calculate amount of LP to be added for the amount of collateral added to bucket
        addedLP_ = collateralToLP(
            bucket_.collateral,
            bucket_.lps,
            deposit_,
            collateralAmountToAdd_,
            bucketPrice_,
            Math.Rounding.Down
        );
        // update bucket LP balance and collateral

        // update bucket collateral
        bucket_.collateral += collateralAmountToAdd_;
        // update bucket and lender LP balance and deposit timestamp
        bucket_.lps += addedLP_;

        addLenderLP(bucket_, bankruptcyTime, lender_, addedLP_);
    }

    /**
     *  @notice Add amount of `LP` for a given lender in a given bucket.
     *  @dev    Increments lender lps accumulator and updates the deposit time.
     *  @param  bucket_         Bucket to record lender `LP`.
     *  @param  bankruptcyTime_ Time when bucket become insolvent.
     *  @param  lender_         Lender address to add `LP` for in the given bucket.
     *  @param  lpAmount_       Amount of `LP` to be recorded for the given lender.
     */
    function addLenderLP(
        Bucket storage bucket_,
        uint256 bankruptcyTime_,
        address lender_,
        uint256 lpAmount_
    ) internal {
        if (lpAmount_ != 0) {
            Lender storage lender = bucket_.lenders[lender_];

            if (bankruptcyTime_ >= lender.depositTime) lender.lps = lpAmount_;
            else lender.lps += lpAmount_;

            lender.depositTime = block.timestamp;
        }
    }

    /**********************/
    /*** View Functions ***/
    /**********************/

    /****************************/
    /*** Assets to LP helpers ***/
    /****************************/

    /**
     *  @notice Returns the amount of bucket `LP` calculated for the given amount of collateral.
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  bucketLP_         Amount of `LP` in bucket.
     *  @param  deposit_          Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / `LP`.
     *  @param  collateral_       The amount of collateral to calculate bucket LP for.
     *  @param  bucketPrice_      Bucket's price.
     *  @param  rounding_         The direction of rounding when calculating LP (down when adding, up when removing collateral from pool).
     *  @return Amount of `LP` calculated for the amount of collateral.
     */
    function collateralToLP(
        uint256 bucketCollateral_,
        uint256 bucketLP_,
        uint256 deposit_,
        uint256 collateral_,
        uint256 bucketPrice_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        // case when there's no deposit nor collateral in bucket
        if (deposit_ == 0 && bucketCollateral_ == 0) return Maths.wmul(collateral_, bucketPrice_);

        // case when there's deposit or collateral in bucket but no LP to cover
        if (bucketLP_ == 0) return Maths.wmul(collateral_, bucketPrice_);

        // case when there's deposit or collateral and bucket has LP balance
        return Math.mulDiv(
            bucketLP_,
            collateral_ * bucketPrice_,
            deposit_ * Maths.WAD + bucketCollateral_ * bucketPrice_,
            rounding_
        );
    }

    /**
     *  @notice Returns the amount of `LP` calculated for the given amount of quote tokens.
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  bucketLP_         Amount of `LP` in bucket.
     *  @param  deposit_          Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / `LP`.
     *  @param  quoteTokens_      The amount of quote tokens to calculate `LP` amount for.
     *  @param  bucketPrice_      Bucket's price.
     *  @param  rounding_         The direction of rounding when calculating LP (down when adding, up when removing quote tokens from pool).
     *  @return The amount of `LP` coresponding to the given quote tokens in current bucket.
     */
    function quoteTokensToLP(
        uint256 bucketCollateral_,
        uint256 bucketLP_,
        uint256 deposit_,
        uint256 quoteTokens_,
        uint256 bucketPrice_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        // case when there's no deposit nor collateral in bucket
        if (deposit_ == 0 && bucketCollateral_ == 0) return quoteTokens_;

        // case when there's deposit or collateral in bucket but no LP to cover
        if (bucketLP_ == 0) return quoteTokens_;

        // case when there's deposit or collateral and bucket has LP balance
        return Math.mulDiv(
            bucketLP_,
            quoteTokens_ * Maths.WAD,
            deposit_ * Maths.WAD + bucketCollateral_ * bucketPrice_,
            rounding_
        );
    }

    /****************************/
    /*** LP to Assets helpers ***/
    /****************************/

    /**
     *  @notice Returns the amount of collateral calculated for the given amount of lp
     *  @dev    The value returned is not capped at collateral amount available in bucket.
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  bucketLP_         Amount of `LP` in bucket.
     *  @param  deposit_          Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / `LP`.
     *  @param  lp_               The amount of LP to calculate collateral amount for.
     *  @param  bucketPrice_      Bucket's price.
     *  @return The amount of collateral coresponding to the given `LP` in current bucket.
     */
    function lpToCollateral(
        uint256 bucketCollateral_,
        uint256 bucketLP_,
        uint256 deposit_,
        uint256 lp_,
        uint256 bucketPrice_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        // case when there's no deposit nor collateral in bucket
        if (deposit_ == 0 && bucketCollateral_ == 0) return Maths.wdiv(lp_, bucketPrice_);

        // case when there's deposit or collateral in bucket but no LP to cover
        if (bucketLP_ == 0) return Maths.wdiv(lp_, bucketPrice_);

        // case when there's deposit or collateral and bucket has LP balance
        return Math.mulDiv(
            deposit_ * Maths.WAD + bucketCollateral_ * bucketPrice_,
            lp_,
            bucketLP_ * bucketPrice_,
            rounding_
        );
    }

    /**
     *  @notice Returns the amount of quote token (in value) calculated for the given amount of `LP`.
     *  @dev    The value returned is not capped at available bucket deposit.
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  bucketLP_         Amount of `LP` in bucket.
     *  @param  deposit_          Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / `LP`.
     *  @param  lp_               The amount of LP to calculate quote tokens amount for.
     *  @param  bucketPrice_      Bucket's price.
     *  @return The amount coresponding to the given quote tokens in current bucket.
     */
    function lpToQuoteTokens(
        uint256 bucketCollateral_,
        uint256 bucketLP_,
        uint256 deposit_,
        uint256 lp_,
        uint256 bucketPrice_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        // case when there's no deposit nor collateral in bucket
        if (deposit_ == 0 && bucketCollateral_ == 0) return lp_;

        // case when there's deposit or collateral in bucket but no LP to cover
        if (bucketLP_ == 0) return lp_;

        // case when there's deposit or collateral and bucket has LP balance
        return Math.mulDiv(
            deposit_ * Maths.WAD + bucketCollateral_ * bucketPrice_,
            lp_,
            bucketLP_ * Maths.WAD,
            rounding_
        );
    }

    /****************************/
    /*** Exchange Rate helper ***/
    /****************************/

    /**
     *  @notice Returns the exchange rate for a given bucket (conversion of 1 lp to quote token).
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  bucketLP_         Amount of `LP` in bucket.
     *  @param  bucketDeposit_    The amount of quote tokens deposited in the given bucket.
     *  @param  bucketPrice_      Bucket's price.
     */
    function getExchangeRate(
        uint256 bucketCollateral_,
        uint256 bucketLP_,
        uint256 bucketDeposit_,
        uint256 bucketPrice_
    ) internal pure returns (uint256) {
        return lpToQuoteTokens(
            bucketCollateral_,
            bucketLP_,
            bucketDeposit_,
            Maths.WAD,
            bucketPrice_,
            Math.Rounding.Up
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { Math } from '@openzeppelin/contracts/utils/math/Math.sol';

import { DepositsState } from '../../interfaces/pool/commons/IPoolState.sol';

import { _priceAt, MAX_FENWICK_INDEX } from '../helpers/PoolHelper.sol';

import { Maths } from './Maths.sol';

/**
    @title  Deposits library
    @notice Internal library containing common logic for deposits management.
    @dev    Implemented as `Fenwick Tree` data structure.
 */
library Deposits {

    /// @dev Max index supported in the `Fenwick` tree
    uint256 internal constant SIZE = 8192;

    /**
     *  @notice Increase a value in the FenwickTree at an index.
     *  @dev    Starts at leaf/target and moved up towards root
     *  @param  deposits_          Deposits state struct.
     *  @param  index_             The deposit index.
     *  @param  unscaledAddAmount_ The unscaled amount to increase deposit by.
     */
    function unscaledAdd(
        DepositsState storage deposits_,
        uint256 index_,
        uint256 unscaledAddAmount_
    ) internal {
        // price buckets are indexed starting at 0, Fenwick bit logic is more elegant starting at 1
        ++index_;

        // unscaledAddAmount_ is the raw amount to add directly to the value at index_, unaffected by the scale array
        // For example, to denote an amount of deposit added to the array, we would need to call unscaledAdd with
        // (deposit amount) / scale(index).  There are two reasons for this:
        // 1- scale(index) is often already known in the context of where unscaledAdd(..) is called, and we want to avoid
        //    redundant iterations through the Fenwick tree.
        // 2- We often need to precisely change the value in the tree, avoiding the rounding that dividing by scale(index).
        //    This is more relevant to unscaledRemove(...), where we need to ensure the value is precisely set to 0, but we
        //    also prefer it here for consistency.

        uint256 value;
        uint256 scaling;
        uint256 newValue;

        while (index_ <= SIZE) {
            value    = deposits_.values[index_];
            scaling  = deposits_.scaling[index_];

            // Compute the new value to be put in location index_
            newValue = value + unscaledAddAmount_;

            // Update unscaledAddAmount to propogate up the Fenwick tree
            // Note: we can't just multiply addAmount_ by scaling[i_] due to rounding
            // We need to track the precice change in values[i_] in order to ensure
            // obliterated indices remain zero after subsequent adding to related indices
            // if scaling==0, the actual scale value is 1, otherwise it is scaling
            if (scaling != 0) unscaledAddAmount_ = Maths.wmul(newValue, scaling) - Maths.wmul(value, scaling);

            deposits_.values[index_] = newValue;

            // traverse upwards through tree via "update" route
            index_ += lsb(index_);
        }
    }

    /**
     *  @notice Finds index and sum of first bucket that EXCEEDS the given sum
     *  @dev    Used in `LUP` and `MOMP` calculation
     *  @param  deposits_      Struct for deposits state.
     *  @param  targetSum_     The sum to find index for.
     *  @return sumIndex_      Smallest index where prefixsum greater than the sum.
     *  @return sumIndexSum_   Sum at index PRECEDING `sumIndex_`.
     *  @return sumIndexScale_ Scale of bucket PRECEDING `sumIndex_`.
     */
    function findIndexAndSumOfSum(
        DepositsState storage deposits_,
        uint256 targetSum_
    ) internal view returns (uint256 sumIndex_, uint256 sumIndexSum_, uint256 sumIndexScale_) {
        // i iterates over bits from MSB to LSB.  We check at each stage if the target sum is to the left or right of sumIndex_+i
        uint256 i  = 4096; // 1 << (_numBits - 1) = 1 << (13 - 1) = 4096
        uint256 runningScale = Maths.WAD;

        // We construct the target sumIndex_ bit by bit, from MSB to LSB.  lowerIndexSum_ always maintains the sum
        // up to the current value of sumIndex_
        uint256 lowerIndexSum;
        uint256 curIndex;
        uint256 value;
        uint256 scaling;
        uint256 scaledValue;

        while (i > 0) {
            // Consider if the target index is less than or greater than sumIndex_ + i
            curIndex = sumIndex_ + i;
            value    = deposits_.values[curIndex];
            scaling  = deposits_.scaling[curIndex];

            // Compute sum up to sumIndex_ + i
            scaledValue =
                lowerIndexSum +
                (
                    scaling != 0 ? Math.mulDiv(
                        runningScale * scaling,
                        value,
                        1e36
                    ) : Maths.wmul(runningScale, value)
                );

            if (scaledValue  < targetSum_) {
                // Target value is too small, need to consider increasing sumIndex_ still
                if (curIndex <= MAX_FENWICK_INDEX) {
                    // sumIndex_+i is in range of Fenwick prices.  Target index has this bit set to 1.  
                    sumIndex_ = curIndex;
                    lowerIndexSum = scaledValue;
                }
            } else {
                // Target index has this bit set to 0
                // scaling == 0 means scale factor == 1, otherwise scale factor == scaling
                if (scaling != 0) runningScale = Maths.floorWmul(runningScale, scaling);

                // Current scaledValue is <= targetSum_, it's a candidate value for sumIndexSum_
                sumIndexSum_   = scaledValue;
                sumIndexScale_ = runningScale;
            }
            // Shift i to next less significant bit
            i = i >> 1;
        }
    }

    /**
     *  @notice Finds index of passed sum. Helper function for `findIndexAndSumOfSum`.
     *  @dev    Used in `LUP` and `MOMP` calculation
     *  @param  deposits_ Deposits state struct.
     *  @param  sum_      The sum to find index for.
     *  @return sumIndex_ Smallest index where prefixsum greater than the sum.
     */
    function findIndexOfSum(
        DepositsState storage deposits_,
        uint256 sum_
    ) internal view returns (uint256 sumIndex_) {
        (sumIndex_,,) = findIndexAndSumOfSum(deposits_, sum_);
    }

    /**
     *  @notice Get least significant bit (`LSB`) of integer `i_`.
     *  @dev    Used primarily to decrement the binary index in loops, iterating over range parents.
     *  @param  i_  The integer with which to return the `LSB`.
     */
    function lsb(
        uint256 i_
    ) internal pure returns (uint256 lsb_) {
        if (i_ != 0) {
            // "i & (-i)"
            lsb_ = i_ & ((i_ ^ 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) + 1);
        }
    }

    /**
     *  @notice Scale values in the tree from the index provided, upwards.
     *  @dev    Starts at passed in node and increments through range parent nodes, and ends at `8192`.
     *  @param  deposits_ Deposits state struct.
     *  @param  index_    The index to start scaling from.
     *  @param  factor_   The factor to scale the values by.
     */
    function mult(
        DepositsState storage deposits_,
        uint256 index_,
        uint256 factor_
    ) internal {
        // price buckets are indexed starting at 0, Fenwick bit logic is more elegant starting at 1
        ++index_;

        uint256 sum;
        uint256 value;
        uint256 scaling;
        uint256 bit = lsb(index_);

        // Starting with the LSB of index, we iteratively move up towards the MSB of SIZE
        // Case 1:     the bit of index_ is set to 1.  In this case, the entire subtree below index_
        //             is scaled.  So, we include factor_ into scaling[index_], and remember in sum how much
        //             we increased the subtree by, so that we can use it in case we encounter 0 bits (below).
        // Case 2:     The bit of index_ is set to 0.  In this case, consider the subtree below the node
        //             index_+bit. The subtree below that is not entirely scaled, but it does contain the
        //             subtree what was scaled earlier.  Therefore: we need to increment it's stored value
        //             (in sum) which was set in a prior interation in case 1.
        while (bit <= SIZE) {
            if ((bit & index_) != 0) {
                // Case 1 as described above
                value   = deposits_.values[index_];
                scaling = deposits_.scaling[index_];

                // Calc sum, will only be stored in range parents of starting node, index_
                if (scaling != 0) {
                    // Note: we can't just multiply by factor_ - 1 in the following line, as rounding will
                    // cause obliterated indices to have nonzero values.  Need to track the actual
                    // precise delta in the value array
                    uint256 scaledFactor = Maths.wmul(factor_, scaling);

                    sum += Maths.wmul(scaledFactor, value) - Maths.wmul(scaling, value);

                    // Apply scaling to all range parents less then starting node, index_
                    deposits_.scaling[index_] = scaledFactor;
                } else {
                    // this node's scale factor is 1
                    sum += Maths.wmul(factor_, value) - value;
                    deposits_.scaling[index_] = factor_;
                }
                // Unset the bit in index to continue traversing up the Fenwick tree
                index_ -= bit;
            } else {
                // Case 2 above.  superRangeIndex is the index of the node to consider that
                //                contains the sub range that was already scaled in prior iteration
                uint256 superRangeIndex = index_ + bit;

                value   = (deposits_.values[superRangeIndex] += sum);
                scaling = deposits_.scaling[superRangeIndex];

                // Need to be careful due to rounding to propagate actual changes upwards in tree.
                // sum is always equal to the actual value we changed deposits_.values[] by
                if (scaling != 0) sum = Maths.wmul(value, scaling) - Maths.wmul(value - sum, scaling);
            }
            // consider next most significant bit
            bit = bit << 1;
        }
    }

    /**
     *  @notice Get prefix sum of all indexes from provided index downwards.
     *  @dev    Starts at tree root and decrements through range parent nodes summing from index `sumIndex_`'s range to index `0`.
     *  @param  deposits_  Deposits state struct.
     *  @param  sumIndex_  The index to receive the prefix sum.
     *  @param  sum_       The prefix sum from current index downwards.
     */
    function prefixSum(
        DepositsState storage deposits_,
        uint256 sumIndex_
    ) internal view returns (uint256 sum_) {
        // price buckets are indexed starting at 0, Fenwick bit logic is more elegant starting at 1
        ++sumIndex_;

        uint256 runningScale = Maths.WAD; // Tracks scale(index_) as we move down Fenwick tree
        uint256 j            = SIZE;      // bit that iterates from MSB to LSB
        uint256 index        = 0;         // build up sumIndex bit by bit

        // Used to terminate loop.  We don't need to consider final 0 bits of sumIndex_
        uint256 indexLSB = lsb(sumIndex_);
        uint256 curIndex;

        while (j >= indexLSB) {
            curIndex = index + j;

            // Skip considering indices outside bounds of Fenwick tree
            if (curIndex > SIZE) continue;

            // We are considering whether to include node index + j in the sum or not.  Either way, we need to scaling[index + j],
            // either to increment sum_ or to accumulate in runningScale
            uint256 scaled = deposits_.scaling[curIndex];

            if (sumIndex_ & j != 0) {
                // node index + j of tree is included in sum
                uint256 value = deposits_.values[curIndex];

                // Accumulate in sum_, recall that scaled==0 means that the scale factor is actually 1
                sum_  += scaled != 0 ? Math.mulDiv(
                    runningScale * scaled,
                    value,
                    1e36
                ) : Maths.wmul(runningScale, value);

                // Build up index bit by bit
                index = curIndex;

                // terminate if we've already matched sumIndex_
                if (index == sumIndex_) break;
            } else {
                // node is not included in sum, but its scale needs to be included for subsequent sums
                if (scaled != 0) runningScale = Maths.floorWmul(runningScale, scaled);
            }
            // shift j to consider next less signficant bit
            j = j >> 1;
        }
    }

    /**
     *  @notice Decrease a node in the `FenwickTree` at an index.
     *  @dev    Starts at leaf/target and moved up towards root.
     *  @param  deposits_             Deposits state struct.
     *  @param  index_                The deposit index.
     *  @param  unscaledRemoveAmount_ Unscaled amount to decrease deposit by.
     */
    function unscaledRemove(
        DepositsState storage deposits_,
        uint256 index_,
        uint256 unscaledRemoveAmount_
    ) internal {
        // price buckets are indexed starting at 0, Fenwick bit logic is more elegant starting at 1
        ++index_;

        // We operate with unscaledRemoveAmount_ here instead of a scaled quantity to avoid duplicate computation of scale factor
        // (thus redundant iterations through the Fenwick tree), and ALSO so that we can set the value of a given deposit exactly
        // to 0.
        
        while (index_ <= SIZE) {
            // Decrement deposits_ at index_ for removeAmount, storing new value in value
            uint256 value   = (deposits_.values[index_] -= unscaledRemoveAmount_);
            uint256 scaling = deposits_.scaling[index_];

            // If scale factor != 1, we need to adjust unscaledRemoveAmount by scale factor to adjust values further up in tree
            // On the line below, it would be tempting to replace this with:
            // unscaledRemoveAmount_ = Maths.wmul(unscaledRemoveAmount, scaling).  This will introduce nonzero values up
            // the tree due to rounding.  It's important to compute the actual change in deposits_.values[index_]
            // and propogate that upwards.
            if (scaling != 0) unscaledRemoveAmount_ = Maths.wmul(value + unscaledRemoveAmount_, scaling) - Maths.wmul(value,  scaling);

            // Traverse upward through the "update" path of the Fenwick tree
            index_ += lsb(index_);
        }
    }

    /**
     *  @notice Scale tree starting from given index.
     *  @dev    Starts at leaf/target and moved up towards root.
     *  @param  deposits_ Deposits state struct.
     *  @param  index_    The deposit index.
     *  @return scaled_   Scaled value.
     */
    function scale(
        DepositsState storage deposits_,
        uint256 index_
    ) internal view returns (uint256 scaled_) {
        // price buckets are indexed starting at 0, Fenwick bit logic is more elegant starting at 1
        ++index_;

        // start with scaled_1 = 1
        scaled_ = Maths.WAD;
        while (index_ <= SIZE) {
            // Traverse up through Fenwick tree via "update" path, accumulating scale factors as we go
            uint256 scaling = deposits_.scaling[index_];
            // scaling==0 means actual scale factor is 1
            if (scaling != 0) scaled_ = Maths.wmul(scaled_, scaling);
            index_ += lsb(index_);
        }
    }

    /**
     *  @notice Returns sum of all deposits.
     *  @param  deposits_ Deposits state struct.
     *  @return Sum of all deposits in tree.
     */
    function treeSum(
        DepositsState storage deposits_
    ) internal view returns (uint256) {
        // In a scaled Fenwick tree, sum is at the root node and never scaled
        return deposits_.values[SIZE];
    }

    /**
     *  @notice Returns deposit value for a given deposit index.
     *  @param  deposits_     Deposits state struct.
     *  @param  index_        The deposit index.
     *  @return depositValue_ Value of the deposit.
     */
    function valueAt(
        DepositsState storage deposits_,
        uint256 index_
    ) internal view returns (uint256 depositValue_) {
        // Get unscaled value at index and multiply by scale
        depositValue_ = Maths.wmul(unscaledValueAt(deposits_, index_), scale(deposits_,index_));
    }

    /**
     *  @notice Returns unscaled (deposit without interest) deposit value for a given deposit index.
     *  @param  deposits_             Deposits state struct.
     *  @param  index_                The deposit index.
     *  @return unscaledDepositValue_ Value of unscaled deposit.
     */
    function unscaledValueAt(
        DepositsState storage deposits_,
        uint256 index_
    ) internal view returns (uint256 unscaledDepositValue_) {
        // In a scaled Fenwick tree, sum is at the root node, but needs to be scaled
        ++index_;

        uint256 j = 1;

        // Returns the unscaled value at the node.  We consider the unscaled value for two reasons:
        // 1- If we want to zero out deposit in bucket, we need to subtract the exact unscaled value
        // 2- We may already have computed the scale factor, so we can avoid duplicate traversal

        unscaledDepositValue_ = deposits_.values[index_];
        uint256 curIndex;
        uint256 value;
        uint256 scaling;

        while (j & index_ == 0) {
            curIndex = index_ - j;

            value   = deposits_.values[curIndex];
            scaling = deposits_.scaling[curIndex];

            unscaledDepositValue_ -= scaling != 0 ? Maths.wmul(scaling, value) : value;
            j = j << 1;
        }
    }

    /**
     *  @notice Returns `LUP` for a given debt value (capped at min bucket price).
     *  @param  deposits_ Deposits state struct.
     *  @param  debt_     The debt amount to calculate `LUP` for.
     *  @return `LUP` for given debt.
     */
    function getLup(
        DepositsState storage deposits_,
        uint256 debt_
    ) internal view returns (uint256) {
        return _priceAt(findIndexOfSum(deposits_, debt_));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import {
    AuctionsState,
    Borrower,
    DepositsState,
    Loan,
    LoansState
} from '../../interfaces/pool/commons/IPoolState.sol';

import { _priceAt } from '../helpers/PoolHelper.sol';

import { Deposits } from './Deposits.sol';
import { Maths }    from './Maths.sol';

/**
    @title  Loans library
    @notice Internal library containing common logic for loans management.
    @dev    The `Loans` heap is a `Max Heap` data structure (complete binary tree), the root node is the loan with the highest threshold price (`TP`)
            at a given time. The heap is represented as an array, where the first element is a dummy element (`Loan(address(0), 0)`) and the first
            value of the heap starts at index `1`, `ROOT_INDEX`. The threshold price of a loan's parent is always greater than or equal to the
            threshold price of the loan.
    @dev    This code was modified from the following source: https://github.com/zmitton/eth-heap/blob/master/contracts/Heap.sol
 */
library Loans {

    uint256 constant ROOT_INDEX = 1;

    /**************/
    /*** Errors ***/
    /**************/

    // See `IPoolErrors` for descriptions
    error ZeroThresholdPrice();

    /***********************/
    /***  Initialization ***/
    /***********************/

    /**
     *  @notice Initializes Loans Max Heap.
     *  @dev    Organizes loans so `Highest Threshold Price` can be retrieved easily.
     *  @param  loans_ Holds Loan heap data.
     */
    function init(LoansState storage loans_) internal {
        loans_.loans.push(Loan(address(0), 0));
    }

    /***********************************/
    /***  Loans Management Functions ***/
    /***********************************/

    /**
     *  @notice Updates a loan: updates heap (`upsert` if `TP` not `0`, `remove` otherwise) and borrower balance.
     *  @dev    === Write state ===
     *  @dev    - `_upsert`:
     *  @dev      insert or update loan in `loans` array
     *  @dev    - `remove`:
     *  @dev      remove loan from `loans` array
     *  @dev    - update borrower in `address => borrower` mapping
     *  @param loans_           Holds loans heap data.
     *  @param auctions_        Struct for pool auctions state.
     *  @param deposits_        Struct for pool deposits state.
     *  @param borrower_        Borrower struct with borrower details.
     *  @param borrowerAddress_ Borrower's address to update.
     *  @param poolDebt_        Pool's current debt.
     *  @param poolRate_        Pool's current rate.
     *  @param lup_             Current LUP.
     *  @param inAuction_       Whether the loan is in auction or not.
     *  @param t0NpUpdate_      Whether the neutral price of borrower should be updated or not.
     */
    function update(
        LoansState storage loans_,
        AuctionsState storage auctions_,
        DepositsState storage deposits_,
        Borrower memory borrower_,
        address borrowerAddress_,
        uint256 poolDebt_,
        uint256 poolRate_,
        uint256 lup_,
        bool inAuction_,
        bool t0NpUpdate_
    ) internal {

        bool activeBorrower = borrower_.t0Debt != 0 && borrower_.collateral != 0;

        uint256 t0ThresholdPrice = activeBorrower ? Maths.wdiv(borrower_.t0Debt, borrower_.collateral) : 0;

        // loan not in auction, update threshold price and position in heap
        if (!inAuction_ ) {
            // get the loan id inside the heap
            uint256 loanId = loans_.indices[borrowerAddress_];
            if (activeBorrower) {
                // revert if threshold price is zero
                if (t0ThresholdPrice == 0) revert ZeroThresholdPrice();

                // update heap, insert if a new loan, update loan if already in heap
                _upsert(loans_, borrowerAddress_, loanId, uint96(t0ThresholdPrice));

            // if loan is in heap and borrwer is no longer active (no debt, no collateral) then remove loan from heap
            } else if (loanId != 0) {
                remove(loans_, borrowerAddress_, loanId);
            }
        }

        // update t0 neutral price of borrower
        if (t0NpUpdate_) {
            if (t0ThresholdPrice != 0) {
                uint256 loansInPool = loans_.loans.length - 1 + auctions_.noOfAuctions;
                uint256 curMomp     = _priceAt(Deposits.findIndexOfSum(deposits_, Maths.wdiv(poolDebt_, loansInPool * 1e18)));

                borrower_.t0Np = (1e18 + poolRate_) * curMomp * t0ThresholdPrice / lup_ / 1e18;
            } else {
                borrower_.t0Np = 0;
            }
        }

        // save borrower state
        loans_.borrowers[borrowerAddress_] = borrower_;
    }

    /**************************************/
    /***  Loans Heap Internal Functions ***/
    /**************************************/

    /**
     *  @notice Moves a `Loan` up the heap.
     *  @param loans_ Holds loans heap data.
     *  @param loan_  `Loan` to be moved.
     *  @param index_ Index of `Loan` to be moved to.
     */
    function _bubbleUp(LoansState storage loans_, Loan memory loan_, uint index_) private {
        uint256 count = loans_.loans.length;
        if (index_ == ROOT_INDEX || loan_.thresholdPrice <= loans_.loans[index_ / 2].thresholdPrice){
          _insert(loans_, loan_, index_, count);
        } else {
          _insert(loans_, loans_.loans[index_ / 2], index_, count);
          _bubbleUp(loans_, loan_, index_ / 2);
        }
    }

    /**
     *  @notice Moves a `Loan` down the heap.
     *  @param loans_ Holds loans heap data.
     *  @param loan_  `Loan` to be moved.
     *  @param index_ Index of `Loan` to be moved to.
     */
    function _bubbleDown(LoansState storage loans_, Loan memory loan_, uint index_) private {
        // Left child index.
        uint cIndex = index_ * 2;

        uint256 count = loans_.loans.length;
        if (count <= cIndex) {
            _insert(loans_, loan_, index_, count);
        } else {
            Loan memory largestChild = loans_.loans[cIndex];

            if (count > cIndex + 1 && loans_.loans[cIndex + 1].thresholdPrice > largestChild.thresholdPrice) {
                largestChild = loans_.loans[++cIndex];
            }

            if (largestChild.thresholdPrice <= loan_.thresholdPrice) {
              _insert(loans_, loan_, index_, count);
            } else {
              _insert(loans_, largestChild, index_, count);
              _bubbleDown(loans_, loan_, cIndex);
            }
        }
    }

    /**
     *  @notice Inserts a `Loan` in the heap.
     *  @param loans_ Holds loans heap data.
     *  @param loan_  `Loan` to be inserted.
     *  @param index_ Index of `Loan` to be inserted at.
     */
    function _insert(LoansState storage loans_, Loan memory loan_, uint index_, uint256 count_) private {
        if (index_ == count_) loans_.loans.push(loan_);
        else loans_.loans[index_] = loan_;

        loans_.indices[loan_.borrower] = index_;
    }

    /**
     *  @notice Removes `Loan` from heap given borrower address.
     *  @param loans_    Holds loans heap data.
     *  @param borrower_ Borrower address whose `Loan` is being updated or inserted.
     *  @param index_    Index of `Loan` to be removed.
     */
    function remove(LoansState storage loans_, address borrower_, uint256 index_) internal {
        delete loans_.indices[borrower_];
        uint256 tailIndex = loans_.loans.length - 1;
        if (index_ == tailIndex) loans_.loans.pop(); // we're removing the tail, pop without sorting
        else {
            Loan memory tail = loans_.loans[tailIndex];
            loans_.loans.pop();            // remove tail loan
            _bubbleUp(loans_, tail, index_);
            _bubbleDown(loans_, loans_.loans[index_], index_);
        }
    }

    /**
     *  @notice Performs an insert or an update dependent on borrowers existance.
     *  @param loans_          Holds loans heap data.
     *  @param borrower_       Borrower address that is being updated or inserted.
     *  @param index_          Index of `Loan` to be upserted.
     *  @param thresholdPrice_ `Threshold Price` that is updated or inserted.
     */
    function _upsert(
        LoansState storage loans_,
        address borrower_,
        uint256 index_,
        uint96 thresholdPrice_
    ) internal {
        // Loan exists, update in place.
        if (index_ != 0) {
            Loan memory currentLoan = loans_.loans[index_];
            if (currentLoan.thresholdPrice > thresholdPrice_) {
                currentLoan.thresholdPrice = thresholdPrice_;
                _bubbleDown(loans_, currentLoan, index_);
            } else {
                currentLoan.thresholdPrice = thresholdPrice_;
                _bubbleUp(loans_, currentLoan, index_);
            }

        // New loan, insert it
        } else {
            _bubbleUp(loans_, Loan(borrower_, thresholdPrice_), loans_.loans.length);
        }
    }


    /**********************/
    /*** View Functions ***/
    /**********************/

    /**
     *  @notice Retreives `Loan` by index, `index_`.
     *  @param loans_ Holds loans heap data.
     *  @param index_ Index to retrieve `Loan`.
     *  @return `Loan` struct retrieved by index.
     */
    function getByIndex(LoansState storage loans_, uint256 index_) internal view returns(Loan memory) {
        return loans_.loans.length > index_ ? loans_.loans[index_] : Loan(address(0), 0);
    }

    /**
     *  @notice Retreives `Loan` with the highest threshold price value.
     *  @param loans_ Holds loans heap data.
     *  @return `Max Loan` in the heap.
     */
    function getMax(LoansState storage loans_) internal view returns(Loan memory) {
        return getByIndex(loans_, ROOT_INDEX);
    }

    /**
     *  @notice Returns number of loans in pool.
     *  @param loans_ Holds loans heap data.
     *  @return Number of loans in pool.
     */
    function noOfLoans(LoansState storage loans_) internal view returns (uint256) {
        return loans_.loans.length - 1;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.18;

/**
    @title  Maths library
    @notice Internal library containing common maths.
 */
library Maths {

    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * y + WAD / 2) / WAD;
    }

    function floorWmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * y) / WAD;
    }

    function ceilWmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * y + WAD - 1) / WAD;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * WAD + y / 2) / y;
    }

    function floorWdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * WAD) / y;
    }

    function ceilWdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * WAD + y - 1) / y;
    }

    function ceilDiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x + y - 1) / y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x >= y ? x : y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x <= y ? x : y;
    }

    function wad(uint256 x) internal pure returns (uint256) {
        return x * WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * y + RAY / 2) / RAY;
    }

    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }

    function rayToWad(uint256 x) internal pure returns (uint256) {
        return (x + 10**9 / 2) / 10**9;
    }

    /*************************/
    /*** Integer Functions ***/
    /*************************/

    function maxInt(int256 x, int256 y) internal pure returns (int256) {
        return x >= y ? x : y;
    }

    function minInt(int256 x, int256 y) internal pure returns (int256) {
        return x <= y ? x : y;
    }

}