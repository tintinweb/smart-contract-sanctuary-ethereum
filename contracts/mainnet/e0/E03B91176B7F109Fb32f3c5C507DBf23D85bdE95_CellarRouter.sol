// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import { ERC20 } from "@rari-capital/solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import { ICellar } from "./interfaces/ICellar.sol";
import { ISushiSwapRouter } from "./interfaces/ISushiSwapRouter.sol";

import "./Errors.sol";
import { ICellarRouter } from "./interfaces/ICellarRouter.sol";

contract CellarRouter is ICellarRouter {
    using SafeTransferLib for ERC20;

    // ======================================== INITIALIZATION ========================================

    /**
     * @notice SushiSwap Router V2 contract. Used for swapping into the current asset of a given cellar.
     */
    ISushiSwapRouter public immutable sushiswapRouter; // 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F

    /**
     * @param _sushiswapRouter Sushiswap V2 router address
     */
    constructor(ISushiSwapRouter _sushiswapRouter) {
        sushiswapRouter = _sushiswapRouter;
    }

    // ======================================= ROUTER OPERATIONS =======================================

    /**
     * @notice Deposit assets into a cellar using permit.
     * @param cellar address of the cellar to deposit into
     * @param assets amount of assets to deposit
     * @param receiver address receiving the shares
     * @param owner address that owns the assets being deposited
     * @param deadline timestamp after which permit is invalid
     * @param v used to produce valid secp256k1 signature from the caller along with r and s
     * @param r used to produce valid secp256k1 signature from the caller along with v and s
     * @param s used to produce valid secp256k1 signature from the caller along with r and v
     * @return shares amount of shares minted
     */
    function depositIntoCellarWithPermit(
        ICellar cellar,
        uint256 assets,
        address receiver,
        address owner,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 shares) {
        // Retrieve the cellar's current asset.
        ERC20 asset = cellar.asset();

        // Approve the assets from the user to the router via permit.
        asset.permit(owner, address(this), assets, deadline, v, r, s);

        // Transfer assets from the user to the router.
        asset.safeTransferFrom(owner, address(this), assets);

        // Approve the cellar to spend assets.
        asset.safeApprove(address(cellar), assets);

        // Deposit assets into the cellar.
        shares = cellar.deposit(assets, receiver);
    }

    /**
     * @notice Deposit into a cellar by first performing a swap to the cellar's current asset if necessary.
     * @param cellar address of the cellar to deposit into
     * @param path array of [token1, token2, token3] that specifies the swap path on Sushiswap
     * @param assets amount of assets to deposit
     * @param minAssetsOut minimum amount of assets received from swap
     * @param receiver address receiving the shares
     * @param owner address that owns the assets being deposited
     * @return shares amount of shares minted
     */
    function depositAndSwapIntoCellar(
        ICellar cellar,
        address[] calldata path,
        uint256 assets,
        uint256 minAssetsOut,
        address receiver,
        address owner
    ) public returns (uint256 shares) {
        // Retrieve the asset being swapped.
        ERC20 assetIn = ERC20(path[0]);

        // Retrieve the cellar's current asset.
        ERC20 asset = cellar.asset();

        // Check to make sure a swap is necessary
        if (assetIn != asset) {
            // Retrieve the asset received after the swap.
            ERC20 assetOut = ERC20(path[path.length - 1]);

            // Ensure that the asset that will be deposited into the cellar is valid.
            if (assetOut != asset) revert USR_InvalidSwap(address(assetOut), address(asset));

            // Transfer assets from the user to the router.
            assetIn.safeTransferFrom(owner, address(this), assets);

            // Approve assets to be swapped.
            assetIn.safeApprove(address(sushiswapRouter), assets);

            // Perform swap to cellar's current asset.
            uint256[] memory swapOutput = sushiswapRouter.swapExactTokensForTokens(
                assets,
                minAssetsOut,
                path,
                address(this),
                block.timestamp + 60
            );

            // Retrieve the final assets received from swap.
            assets = swapOutput[swapOutput.length - 1];
        }

        // Approve the cellar to spend assets.
        asset.safeApprove(address(cellar), assets);

        // Deposit assets into the cellar.
        shares = cellar.deposit(assets, receiver);
    }

    /**
     * @notice Deposit into a cellar by first performing a swap to the cellar's current asset if necessary.
     * @param cellar address of the cellar to deposit into
     * @param path array of [token1, token2, token3] that specifies the swap path on Sushiswap
     * @param assets amount of assets to deposit
     * @param minAssetsOut minimum amount of assets received from swap
     * @param receiver address receiving the shares
     * @param owner address that owns the assets being deposited
     * @param deadline timestamp after which permit is invalid
     * @param v used to produce valid secp256k1 signature from the caller along with r and s
     * @param r used to produce valid secp256k1 signature from the caller along with v and s
     * @param s used to produce valid secp256k1 signature from the caller along with r and v
     * @return shares amount of shares minted
     */
    function depositAndSwapIntoCellarWithPermit(
        ICellar cellar,
        address[] calldata path,
        uint256 assets,
        uint256 minAssetsOut,
        address receiver,
        address owner,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 shares) {
        // Retrieve the asset being swapped.
        ERC20 assetIn = ERC20(path[0]);

        // Approve the assets from the user to the router via permit.
        assetIn.permit(owner, address(this), assets, deadline, v, r, s);

        // Deposit assets into the cellar using a swap if necessary.
        shares = depositAndSwapIntoCellar(cellar, path, assets, minAssetsOut, receiver, owner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

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

    /*///////////////////////////////////////////////////////////////
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

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import { ERC20 } from "@rari-capital/solmate/src/tokens/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICellar is IERC20 {
    // ======================================= ERC4626 OPERATIONS =======================================

    function asset() external view returns (ERC20);

    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    function totalAssets() external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256);

    function convertToAssets(uint256 shares) external view returns (uint256);

    function previewDeposit(uint256 assets) external view returns (uint256);

    function previewMint(uint256 shares) external view returns (uint256);

    function previewWithdraw(uint256 assets) external view returns (uint256);

    function previewRedeem(uint256 shares) external view returns (uint256);

    function maxDeposit(address) external view returns (uint256);

    function maxMint(address) external view returns (uint256);

    function maxWithdraw(address owner) external view returns (uint256);

    function maxRedeem(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

/**
 * @notice Partial interface for a SushiSwap Router contract
 **/
interface ISushiSwapRouter {
    /**
     * @notice Swaps an exact amount of input tokens for as many output tokens as possible, along the route determined by the `path`
     * @dev The first element of `path` is the input token, the last is the output token,
     *      and any intermediate elements represent intermediate pairs to trade through (if, for example, a direct pair does not exist).
     *      `msg.sender` should have already given the router an allowance of at least `amountIn` on the input token
     * @param amountIn The amount of input tokens to send
     * @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert
     * @param path An array of token addresses. `path.length` must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
     * @param to Recipient of the output tokens
     * @param deadline Unix timestamp after which the transaction will revert
     * @return amounts The input token amount and all subsequent output token amounts
     **/
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

// ========================================== USER ERRORS ===========================================

/**
 * @dev These errors represent invalid user input to functions. Where appropriate, the invalid value
 *      is specified along with constraints. These errors can be resolved by callers updating their
 *      arguments.
 */

/**
 * @notice Attempted an action with zero assets.
 */
error USR_ZeroAssets();

/**
 * @notice Attempted an action with zero shares.
 */
error USR_ZeroShares();

/**
 * @notice Attempted deposit more liquidity over the liquidity limit.
 * @param maxLiquidity the max liquidity
 */
error USR_LiquidityRestricted(uint256 maxLiquidity);

/**
 * @notice Attempted deposit more than the per wallet limit.
 * @param maxDeposit the max deposit
 */
error USR_DepositRestricted(uint256 maxDeposit);

/**
 * @notice Attempted to transfer more active shares than the user has.
 * @param activeShares amount of shares user has
 * @param attemptedActiveShares amount of shares user tried to transfer
 */
error USR_NotEnoughActiveShares(uint256 activeShares, uint256 attemptedActiveShares);

/**
 * @notice Attempted swap into an asset that is not the current asset of the cellar.
 * @param assetOut address of the asset attempted to swap to
 * @param currentAsset address of the current asset of cellar
 */
error USR_InvalidSwap(address assetOut, address currentAsset);

/**
 * @notice Attempted to sweep an asset that is managed by the cellar.
 * @param token address of the token that can't be sweeped
 */
error USR_ProtectedAsset(address token);

/**
 * @notice Attempted rebalance into the same asset.
 * @param asset address of the asset
 */
error USR_SameAsset(address asset);

/**
 * @notice Attempted to update the position to one that is not supported by the platform.
 * @param unsupportedPosition address of the unsupported position
 */
error USR_UnsupportedPosition(address unsupportedPosition);

/**
 * @notice Attempted rebalance into an untrusted position.
 * @param asset address of the asset
 */
error USR_UntrustedPosition(address asset);

/**
 * @notice Attempted to update a position to an asset that uses an incompatible amount of decimals.
 * @param newDecimals decimals of precision that the new position uses
 * @param maxDecimals maximum decimals of precision for a position to be compatible with the cellar
 */
error USR_TooManyDecimals(uint8 newDecimals, uint8 maxDecimals);

// ========================================== STATE ERRORS ===========================================

/**
 * @dev These errors represent actions that are being prevented due to current contract state.
 *      These errors do not relate to user input, and may or may not be resolved by other actions
 *      or the progression of time.
 */

/**
 * @notice Attempted action was prevented due to contract being shutdown.
 */
error STATE_ContractShutdown();

/**
 * @notice Attempted to shutdown the contract when it was already shutdown.
 */
error STATE_AlreadyShutdown();

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import { ERC20 } from "@rari-capital/solmate/src/tokens/ERC20.sol";
import { ICellar } from "../interfaces/ICellar.sol";

interface ICellarRouter {
    // ======================================= ROUTER OPERATIONS =======================================

    function depositIntoCellarWithPermit(
        ICellar cellar,
        uint256 assets,
        address receiver,
        address owner,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 shares);

    function depositAndSwapIntoCellar(
        ICellar cellar,
        address[] calldata path,
        uint256 assets,
        uint256 minAssetsOut,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    function depositAndSwapIntoCellarWithPermit(
        ICellar cellar,
        address[] calldata path,
        uint256 assets,
        uint256 minAssetsOut,
        address receiver,
        address owner,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 shares);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}