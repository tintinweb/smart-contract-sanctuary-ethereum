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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.15;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title AllowanceTransfer
/// @notice Handles ERC20 token permissions through signature based allowance setting and ERC20 token transfers by checking allowed amounts
/// @dev Requires user's token approval on the Permit2 contract
interface IAllowanceTransfer {
    /// @notice Thrown when an allowance on a token has expired.
    /// @param deadline The timestamp at which the allowed amount is no longer valid
    error AllowanceExpired(uint256 deadline);

    /// @notice Thrown when an allowance on a token has been depleted.
    /// @param amount The maximum amount allowed
    error InsufficientAllowance(uint256 amount);

    /// @notice Thrown when too many nonces are invalidated.
    error ExcessiveInvalidation();

    /// @notice Emits an event when the owner successfully invalidates an ordered nonce.
    event NonceInvalidation(
        address indexed owner, address indexed token, address indexed spender, uint48 newNonce, uint48 oldNonce
    );

    /// @notice Emits an event when the owner successfully sets permissions on a token for the spender.
    event Approval(
        address indexed owner, address indexed token, address indexed spender, uint160 amount, uint48 expiration
    );

    /// @notice Emits an event when the owner successfully sets permissions using a permit signature on a token for the spender.
    event Permit(
        address indexed owner,
        address indexed token,
        address indexed spender,
        uint160 amount,
        uint48 expiration,
        uint48 nonce
    );

    /// @notice Emits an event when the owner sets the allowance back to 0 with the lockdown function.
    event Lockdown(address indexed owner, address token, address spender);

    /// @notice The permit data for a token
    struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice The permit message signed for a single token allownce
    struct PermitSingle {
        // the permit data for a single token alownce
        PermitDetails details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The permit message signed for multiple token allowances
    struct PermitBatch {
        // the permit data for multiple token allowances
        PermitDetails[] details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The saved permissions
    /// @dev This info is saved per owner, per token, per spender and all signed over in the permit message
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    struct PackedAllowance {
        // amount allowed
        uint160 amount;
        // permission expiry
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice A token spender pair.
    struct TokenSpenderPair {
        // the token the spender is approved
        address token;
        // the spender address
        address spender;
    }

    /// @notice Details for a token transfer.
    struct AllowanceTransferDetails {
        // the owner of the token
        address from;
        // the recipient of the token
        address to;
        // the amount of the token
        uint160 amount;
        // the token to be transferred
        address token;
    }

    /// @notice A mapping from owner address to token address to spender address to PackedAllowance struct, which contains details and conditions of the approval.
    /// @notice The mapping is indexed in the above order see: allowance[ownerAddress][tokenAddress][spenderAddress]
    /// @dev The packed slot holds the allowed amount, expiration at which the allowed amount is no longer valid, and current nonce thats updated on any signature based approvals.
    function allowance(address, address, address) external view returns (uint160, uint48, uint48);

    /// @notice Approves the spender to use up to amount of the specified token up until the expiration
    /// @param token The token to approve
    /// @param spender The spender address to approve
    /// @param amount The approved amount of the token
    /// @param expiration The timestamp at which the approval is no longer valid
    /// @dev The packed allowance also holds a nonce, which will stay unchanged in approve
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    function approve(address token, address spender, uint160 amount, uint48 expiration) external;

    /// @notice Permit a spender to a given amount of the owners token via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitSingle Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitSingle memory permitSingle, bytes calldata signature) external;

    /// @notice Permit a spender to the signed amounts of the owners tokens via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitBatch Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitBatch memory permitBatch, bytes calldata signature) external;

    /// @notice Transfer approved tokens from one address to another
    /// @param from The address to transfer from
    /// @param to The address of the recipient
    /// @param amount The amount of the token to transfer
    /// @param token The token address to transfer
    /// @dev Requires the from address to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(address from, address to, uint160 amount, address token) external;

    /// @notice Transfer approved tokens in a batch
    /// @param transferDetails Array of owners, recipients, amounts, and tokens for the transfers
    /// @dev Requires the from addresses to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(AllowanceTransferDetails[] calldata transferDetails) external;

    /// @notice Enables performing a "lockdown" of the sender's Permit2 identity
    /// by batch revoking approvals
    /// @param approvals Array of approvals to revoke.
    function lockdown(TokenSpenderPair[] calldata approvals) external;

    /// @notice Invalidate nonces for a given (token, spender) pair
    /// @param token The token to invalidate nonces for
    /// @param spender The spender to invalidate nonces for
    /// @param newNonce The new nonce to set. Invalidates all nonces less than it.
    /// @dev Can't invalidate more than 2**16 nonces per transaction.
    function invalidateNonces(address token, address spender, uint48 newNonce) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// Just an interface for Dai's permits
pragma solidity ^0.8.17;
abstract contract IPermitDai {
    function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external virtual;
    // Defining details for checking
    function PERMIT_TYPEHASH() public virtual returns (bytes32);
    function nonces(address) public virtual returns (uint256);
}

/// SPDX-License-Identifier: NONE
pragma solidity ^0.8.15;

import "./ToadStructs.sol";
import "./IMulticall.sol";
import "./IPermit2/IAllowanceTransfer.sol";
/**
 * IToadRouter03 
 * Extends the V1 router with auto-unwrap functions and permit2 support - also implements Multicall
 * Also has a proper price calculator
 */
abstract contract IToadRouter03 is IMulticall {

    /**
     * Run a permit on a token to the Permit2 contract for max uint256
     * @param owner the token owner
     * @param tok the token to permit
     * @param deadline A deadline to expire by
     * @param v v of the sig
     * @param r r of the sig
     * @param s s of the sig
     */
    function performPermit(address owner, address tok, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual;

    /**
     * Run a permit on a token to the Permit2 contract via the Dai-style permit
     * @param owner the token owner
     * @param tok the token to permit
     * @param deadline A deadline to expire by
     * @param nonce the nonce
     * @param v v of the sig
     * @param r r of the sig
     * @param s s of the sig
     */
    function performPermitDai(address owner, address tok, uint256 nonce, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual;

    /**
     * Run a Permit2 permit on a token to be spent by us
     * @param owner The tokens owner
     * @param permitSingle The struct 
     * @param signature The signature
     */
    function performPermit2Single(address owner, IAllowanceTransfer.PermitSingle memory permitSingle, bytes calldata signature) public virtual;

    /**
     * Run a batch of Permit2 permits on a token to be spent by us
     * @param owner The tokens owner
     * @param permitBatch The struct
     * @param signature The signature
     */
    function performPermit2Batch(address owner, IAllowanceTransfer.PermitBatch memory permitBatch, bytes calldata signature) public virtual;

    function swapExactTokensForTokensSupportingFeeOnTransferTokensWithWETHGas(uint amountIn, uint amountOutMin, ToadStructs.AggPath[] calldata path1, ToadStructs.AggPath[] calldata path2, address to, uint deadline, ToadStructs.FeeStruct calldata fees, ToadStructs.DexData[] calldata dexes) public virtual returns(uint256 outputAmount);

    function swapExactTokensForWETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, ToadStructs.AggPath[] calldata path, address to, uint deadline, ToadStructs.FeeStruct calldata fees, ToadStructs.DexData[] calldata dexes, bool unwrap) public virtual returns(uint256 outputAmount);

    function swapExactWETHforTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, ToadStructs.AggPath[] calldata path, address to, uint deadline, ToadStructs.FeeStruct calldata fees, ToadStructs.DexData[] calldata dexes) public virtual returns(uint256 outputAmount);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, ToadStructs.AggPath[] calldata path, address to, uint deadline, ToadStructs.FeeStruct calldata fees, uint256 ethFee, ToadStructs.AggPath[] calldata gasPath, ToadStructs.DexData[] calldata dexes) public virtual returns(uint256 outputAmount);

    function getPriceOut(uint256 amountIn, ToadStructs.AggPath[] calldata path, ToadStructs.DexData[] calldata dexes) public view virtual returns (uint256[] memory amounts);

    function getAmountsOut(uint amountIn, ToadStructs.AggPath[] calldata path, ToadStructs.DexData[] calldata dexes) external view virtual returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, ToadStructs.AggPath[] calldata path, ToadStructs.DexData[] calldata dexes) external view virtual returns (uint[] memory amounts);

    
    // IToadRouter01
    string public versionRecipient = "3.0.0";
    address public immutable factory;
    address public immutable WETH;

    constructor(address fac, address weth) {
        factory = fac;
        WETH = weth;
    }

    function unwrapWETH(address to, uint256 amount, ToadStructs.FeeStruct calldata fees) external virtual;

    function quote(uint amountA, uint reserveA, uint reserveB) external pure virtual returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure virtual returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure virtual returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view virtual returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view virtual returns (uint[] memory amounts);

}


//swapExactTokensForTokensSupportingFeeOnTransferTokensWithWETHGas(uint256,uint256,(address,uint96)[],(address,uint96)[],address,uint256,(uint256,address,uint96),(bytes32,address)[])

pragma solidity ^0.8.15;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.15;

import './IMulticall.sol';


/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
    /// @inheritdoc IMulticall
    function multicall(bytes[] calldata data) public payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;
import "./IToadRouter03.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ToadswapLibrary.sol";
import "./TransferHelper.sol";
import "./IWETH.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC20Permit.sol";
import "./Multicall.sol";
import "./IPermitDai.sol";

/**
 * ToadRouter03
 * A re-implementation of the Uniswap v2 router with bot-driven meta-transactions.
 * Bot private keys are all stored on a hardware wallet.
 * ToadRouter03 implements ERC2612 (ERC20Permit) and auto-unwrap functions
 */
contract ToadRouter03 is IToadRouter03, Ownable, Multicall {
    mapping(address => bool) allowedBots;
    address immutable PERMIT2;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "ToadRouter: EXPIRED");
        _;
    }

    modifier onlyBot() {
        require(allowedBots[_msgSender()], "ToadRouter: UNTRUSTED");
        _;
    }

    constructor(
        address fac,
        address weth,
        address permit
    ) IToadRouter03(fac, weth) {
        // Do any other stuff necessary
        // Add sender to allowedBots
        allowedBots[_msgSender()] = true;
        PERMIT2 = permit;
    }

    function addTrustedBot(address newBot) external onlyOwner {
        allowedBots[newBot] = true;
    }

    function removeTrustedBot(address bot) external onlyOwner {
        allowedBots[bot] = false;
    }

    receive() external payable {
        if (_msgSender() != WETH) {
            revert("ToadRouter: No ETH not from WETH.");
        }
    }

    function performPermit2Single(
        address owner,
        IAllowanceTransfer.PermitSingle memory permitSingle,
        bytes calldata signature
    ) public virtual override onlyBot {
        IAllowanceTransfer permitCA = IAllowanceTransfer(PERMIT2);
        permitCA.permit(owner, permitSingle, signature);
    }

    function performPermit2Batch(
        address owner,
        IAllowanceTransfer.PermitBatch memory permitBatch,
        bytes calldata signature
    ) public virtual override onlyBot {
        IAllowanceTransfer permitCA = IAllowanceTransfer(PERMIT2);
        permitCA.permit(owner, permitBatch, signature);
    }

    function performPermit(
        address owner,
        address tok,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override ensure(deadline) onlyBot {
        IERC20Permit ptok = IERC20Permit(tok);
        ptok.permit(owner, PERMIT2, type(uint256).max, deadline, v, r, s);
    }

    function performPermitDai(address owner, address tok, uint256 nonce, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual override onlyBot {
        IPermitDai dpermit = IPermitDai(tok);
        dpermit.permit(owner, PERMIT2, nonce, deadline, true, v, r, s);
    }

    function stfFirstHop(
        uint256 amountIn,
        ToadStructs.DexData memory dex1,
        address path0,
        address path1,
        address to
    ) internal {
        TransferHelper.safeTransferFrom(
            PERMIT2,
            path0,
            to,
            ToadswapLibrary.pairFor(dex1.factory, path0, path1, dex1.initcode),
            amountIn
        );
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokensWithWETHGas(
        uint amountIn,
        uint amountOutMin,
        ToadStructs.AggPath[] calldata path1,
        ToadStructs.AggPath[] calldata path2,
        address to,
        uint deadline,
        ToadStructs.FeeStruct calldata fees,
        ToadStructs.DexData[] calldata dexes
    )
        public
        virtual
        override
        ensure(deadline)
        onlyBot
        returns (uint256 outputAmount)
    {
        // This does two half-swaps, so we can extract the gas return

        // Swap the first half
        TransferHelper.safeTransferFrom(
            PERMIT2,
            path1[0].token,
            to,
            ToadswapLibrary.pairFor(
                dexes[path1[1].dexId].factory,
                path1[0].token,
                path1[1].token,
                dexes[path1[1].dexId].initcode
            ),
            amountIn
        );
        uint256 wethBalanceBefore = IERC20(WETH).balanceOf(address(this));
        // Swap to us
        _swapSupportingFeeOnTransferTokens(path1, address(this), dexes);
        // Extract the WETH to pay the relayer
        IWETH(WETH).withdraw(fees.gasReturn + fees.fee);
        TransferHelper.safeTransferETH(tx.origin, fees.gasReturn);
        if (fees.fee > 0) {
            TransferHelper.safeTransferETH(fees.feeReceiver, fees.fee);
        }
        // Send the remaining WETH to the next hop
        TransferHelper.safeTransfer(
            path2[0].token,
            ToadswapLibrary.pairFor(
                dexes[path2[1].dexId].factory,
                path2[0].token,
                path2[1].token,
                dexes[path1[1].dexId].initcode
            ),
            IERC20(WETH).balanceOf(address(this)) - wethBalanceBefore
        );
        // Grab the pre-balance
        uint256 balanceBefore = IERC20(path2[path2.length - 1].token).balanceOf(
            to
        );
        // Run the final half of swap to the end user
        _swapSupportingFeeOnTransferTokens(path2, to, dexes);
        // Do the output amount check
        outputAmount =
            IERC20(path2[path2.length - 1].token).balanceOf(to) -
            (balanceBefore);
        require(
            outputAmount >= amountOutMin,
            "ToadRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        ToadStructs.AggPath[] calldata path,
        address to,
        uint deadline,
        ToadStructs.FeeStruct calldata fees,
        uint256 ethFee,
        ToadStructs.AggPath[] calldata gasPath,
        ToadStructs.DexData[] calldata dexes
    )
        public
        virtual
        override
        ensure(deadline)
        onlyBot
        returns (uint256 outputAmount)
    {
        if (fees.gasReturn + fees.fee > 0) {
            // Swap the gasReturn tokens from their wallet to us as WETH, unwrap and send to tx origin
            uint balanceBef = IERC20(WETH).balanceOf(address(this));
            stfFirstHop(
                fees.gasReturn + fees.fee,
                dexes[gasPath[1].dexId],
                gasPath[0].token,
                gasPath[1].token,
                to
            );
            _swapSupportingFeeOnTransferTokens(gasPath, address(this), dexes);
            uint256 botAmount = IERC20(WETH).balanceOf(address(this)) -
                balanceBef;
            IWETH(WETH).withdraw(botAmount);
            TransferHelper.safeTransferETH(tx.origin, botAmount - ethFee);
            if (ethFee > 0) {
                TransferHelper.safeTransferETH(fees.feeReceiver, ethFee);
            }
        }

        // Swap remaining tokens to the path provided
        stfFirstHop(
            amountIn - fees.gasReturn - fees.fee,
            dexes[path[1].dexId],
            path[0].token,
            path[1].token,
            to
        );

        uint balanceBefore = IERC20(path[path.length - 1].token).balanceOf(to);

        _swapSupportingFeeOnTransferTokens(path, to, dexes);
        outputAmount =
            IERC20(path[path.length - 1].token).balanceOf(to) -
            (balanceBefore);
        require(
            outputAmount >= amountOutMin,
            "ToadRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactWETHforTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        ToadStructs.AggPath[] calldata path,
        address to,
        uint deadline,
        ToadStructs.FeeStruct calldata fees,
        ToadStructs.DexData[] calldata dexes
    )
        public
        virtual
        override
        ensure(deadline)
        onlyBot
        returns (uint256 outputAmount)
    {
        require(path[0].token == WETH, "ToadRouter: INVALID_PATH");
        // Send us gas first
        if (fees.gasReturn + fees.fee > 0) {
            TransferHelper.safeTransferFrom(
                PERMIT2,
                WETH,
                to,
                address(this),
                fees.gasReturn + fees.fee
            );
            // Pay the relayer
            IWETH(WETH).withdraw(fees.gasReturn + fees.fee);
            TransferHelper.safeTransferETH(tx.origin, fees.gasReturn);
            if (fees.fee > 0) {
                TransferHelper.safeTransferETH(fees.feeReceiver, fees.fee);
            }
        }
        // Send to first pool
        stfFirstHop(
            amountIn - fees.gasReturn - fees.fee,
            dexes[path[1].dexId],
            path[0].token,
            path[1].token,
            to
        );

        uint256 balanceBefore = IERC20(path[path.length - 1].token).balanceOf(
            to
        );
        _swapSupportingFeeOnTransferTokens(path, to, dexes);
        outputAmount =
            IERC20(path[path.length - 1].token).balanceOf(to) -
            (balanceBefore);
        require(
            outputAmount >= amountOutMin,
            "ToadRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactTokensForWETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        ToadStructs.AggPath[] calldata path,
        address to,
        uint deadline,
        ToadStructs.FeeStruct calldata fees,
        ToadStructs.DexData[] calldata dexes,
        bool unwrap
    )
        public
        virtual
        override
        ensure(deadline)
        onlyBot
        returns (uint256 outputAmount)
    {
        require(
            path[path.length - 1].token == WETH,
            "ToadRouter: INVALID_PATH"
        );

        stfFirstHop(
            amountIn,
            dexes[path[1].dexId],
            path[0].token,
            path[1].token,
            to
        );

        _swapSupportingFeeOnTransferTokens(path, address(this), dexes);
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        // Adjust output amount to be exclusive of the payout of gas
        outputAmount = amountOut - fees.gasReturn - fees.fee;
        require(
            outputAmount >= amountOutMin,
            "ToadRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        // Give the WETH to the holder
        if (unwrap) {
            IWETH(WETH).withdraw(outputAmount + fees.gasReturn + fees.fee);
            TransferHelper.safeTransferETH(to, outputAmount);
        } else {
            TransferHelper.safeTransfer(WETH, to, outputAmount);
        }
        // Pay the relayer
        if (fees.gasReturn + fees.fee > 0) {
            if (!unwrap) {
                IWETH(WETH).withdraw(fees.gasReturn + fees.fee);
            }
            TransferHelper.safeTransferETH(tx.origin, fees.gasReturn);
            if (fees.fee > 0) {
                TransferHelper.safeTransferETH(fees.feeReceiver, fees.fee);
            }
        }
    }

    // Gasloan WETH unwrapper
    function unwrapWETH(
        address to,
        uint256 amount,
        ToadStructs.FeeStruct calldata fees
    ) external virtual override onlyBot {
        IERC20(WETH).transferFrom(to, address(this), amount);
        IWETH(WETH).withdraw(amount);
        TransferHelper.safeTransferETH(tx.origin, fees.gasReturn);
        if (fees.fee > 0) {
            TransferHelper.safeTransferETH(fees.feeReceiver, fees.fee);
        }
        TransferHelper.safeTransferETH(to, amount - fees.gasReturn - fees.fee);
    }

    function getPriceOut(
        uint256 amountIn,
        ToadStructs.AggPath[] calldata path,
        ToadStructs.DexData[] calldata dexes
    ) public view virtual override returns (uint256[] memory amounts) {
        return ToadswapLibrary.getPriceOut(amountIn, path, dexes);
    }

    function _swapSupportingFeeOnTransferTokens(
        ToadStructs.AggPath[] memory path,
        address _to,
        ToadStructs.DexData[] memory dexes
    ) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (
                path[i].token,
                path[i + 1].token
            );
            (address token0, ) = ToadswapLibrary.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(
                ToadswapLibrary.pairFor(
                    dexes[path[i + 1].dexId].factory,
                    input,
                    output,
                    dexes[path[i + 1].dexId].initcode
                )
            );
            uint amountInput;
            uint amountOutput;
            {
                // scope to avoid stack too deep errors
                (uint reserve0, uint reserve1, ) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == token0
                    ? (reserve0, reserve1)
                    : (reserve1, reserve0);
                amountInput =
                    IERC20(input).balanceOf(address(pair)) -
                    reserveInput;
                amountOutput = ToadswapLibrary.getAmountOut(
                    amountInput,
                    reserveInput,
                    reserveOutput
                );
            }
            (uint amount0Out, uint amount1Out) = input == token0
                ? (uint(0), amountOutput)
                : (amountOutput, uint(0));
            address to = i < path.length - 2
                ? ToadswapLibrary.pairFor(
                    dexes[path[i + 2].dexId].factory,
                    output,
                    path[i + 2].token,
                    dexes[path[i + 2].dexId].initcode
                )
                : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) public pure virtual override returns (uint amountB) {
        return ToadswapLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) public pure virtual override returns (uint amountOut) {
        return ToadswapLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) public pure virtual override returns (uint amountIn) {
        return ToadswapLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(
        uint amountIn,
        address[] memory path
    ) public view virtual override returns (uint[] memory amounts) {
        // Adjusted to use new code - this is a uniswap-only call
        ToadStructs.AggPath[] memory aggPath = new ToadStructs.AggPath[](
            path.length
        );
        ToadStructs.DexData[] memory dexes = new ToadStructs.DexData[](1);
        dexes[0] = ToadStructs.DexData(
            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f",
            factory
        );
        for (uint256 i = 0; i < path.length; i++) {
            aggPath[i] = ToadStructs.AggPath(path[i], 0);
        }
        return ToadswapLibrary.getAmountsOut(amountIn, aggPath, dexes);
    }

    function getAmountsIn(
        uint amountOut,
        address[] memory path
    ) public view virtual override returns (uint[] memory amounts) {
        // Adjusted to use new code - this is a uniswap-only call
        ToadStructs.AggPath[] memory aggPath = new ToadStructs.AggPath[](
            path.length
        );
        ToadStructs.DexData[] memory dexes = new ToadStructs.DexData[](1);
        dexes[0] = ToadStructs.DexData(
            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f",
            factory
        );
        for (uint256 i = 0; i < path.length; i++) {
            aggPath[i] = ToadStructs.AggPath(path[i], 0);
        }
        return ToadswapLibrary.getAmountsIn(amountOut, aggPath, dexes);
    }

    function getAmountsOut(
        uint amountIn,
        ToadStructs.AggPath[] calldata path,
        ToadStructs.DexData[] calldata dexes
    ) external view virtual override returns (uint[] memory amounts) {
        return ToadswapLibrary.getAmountsOut(amountIn, path, dexes);
    }

    function getAmountsIn(
        uint amountOut,
        ToadStructs.AggPath[] calldata path,
        ToadStructs.DexData[] calldata dexes
    ) external view virtual override returns (uint[] memory amounts) {
        return ToadswapLibrary.getAmountsIn(amountOut, path, dexes);
    }
}

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.15;

contract ToadStructs {
    /**
     * token: The token
     * dexId: the position of the dex struct in the list provided - should be the same between input and output token 
     */
    struct AggPath {
        address token;
        uint96 dexId;
    }
    /**
     * DexData - a list of UniV2 dexes referred to in AggPath - shared between gasPath and path
     * initcode: the initcode to feed the create2 seed
     * factory: the factory address to feed the create2 seed
     */
    struct DexData {
        bytes32 initcode;
        address factory;
    }
    /**
     * FeeStruct - a batch of fees to be paid in gas and optionally to another account
     */
    struct FeeStruct {
        uint256 gasReturn;
        address feeReceiver;
        uint96 fee;
    }
}

/**
 * Modified version of the UniswapV2Library to use inbuilt SafeMath
 * Also now supports 
 */
//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import './ToadStructs.sol';
library ToadswapLibrary {


    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'ToadswapLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ToadswapLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a UniswapV2 pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        pair = pairFor(factory, tokenA, tokenB, hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f');
    }


    function pairFor(address factory, address tokenA, address tokenB, bytes32 initCodeHash) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            initCodeHash // init code hash
        )))));
    }


    function getPriceOut(uint256 amountIn, ToadStructs.AggPath[] calldata path, ToadStructs.DexData[] calldata dexes) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, 'ToadswapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {

            (uint reserveIn, uint reserveOut) = getReserves(dexes[path[i+1].dexId].factory, path[i].token, path[i + 1].token, dexes[path[i+1].dexId].initcode);
            amounts[i + 1] = quote(amounts[i], reserveIn, reserveOut);
        }
    }


    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB, bytes32 initCodeHash) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB, initCodeHash)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'ToadswapLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'ToadswapLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA * (reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'ToadswapLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'ToadswapLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'ToadswapLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'ToadswapLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(uint amountIn, ToadStructs.AggPath[] memory path, ToadStructs.DexData[] memory dexes) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'ToadswapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(dexes[path[i+1].dexId].factory, path[i].token, path[i + 1].token, dexes[path[i+1].dexId].initcode);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(uint amountOut, ToadStructs.AggPath[] memory path, ToadStructs.DexData[] memory dexes) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'ToadswapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(dexes[path[i].dexId].factory, path[i - 1].token, path[i].token, dexes[path[i].dexId].initcode);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

//SPDX-License-Identifier: GPL-3.0
// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
// Modified by TBC to use Permit2's transferFrom
import "./IPermit2/IAllowanceTransfer.sol";
pragma solidity ^0.8.15;
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address permit2, address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint160,address)')));
        IAllowanceTransfer permitter = IAllowanceTransfer(permit2);
        permitter.transferFrom(from, to, uint160(value), token);
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}