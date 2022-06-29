// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IDIVAPorterModule.sol";
import "./interfaces/IBond.sol";
import "./interfaces/IBondFactory.sol";
import "./interfaces/IDIVA.sol";

contract DIVAPorterModule is IDIVAPorterModule, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;

    // Mapping to check if pool is settled already
    mapping(uint256 => bool) public poolIsSettled;

    bool private immutable _challengeable;
    address private _bondFactoryAddress;

    constructor(address bondFactoryAddress_) {
        _challengeable = false;
        _bondFactoryAddress = bondFactoryAddress_;
    }

    function setFinalReferenceValue(address _divaDiamond, uint256 _poolId)
        external
        override
        nonReentrant
    {
        require(
            !poolIsSettled[_poolId],
            "DIVAPorterModule: pool is already settled"
        );

        // Connect to DIVA contract and extract pool parameters based on `_poolId`
        IDIVA _diva = IDIVA(_divaDiamond);
        IDIVA.Pool memory _params = _diva.getPoolParameters(_poolId);

        // Connect to Porter Bond contract based on the address stored in the 
        // referenceAsset field
        string memory _porterBond = _params.referenceAsset;
        IBond _bond = IBond(_stringToAddress(_porterBond));

        uint256 _amountUnpaid = _bond.amountUnpaid();
        
        // Get scaling factor as DIVA Protocol expects the final reference value
        // to be expressed as an integer with 18 decimals, but payment token
        // may have less decimals
        uint256 _SCALING = uint256(
            10**(18 - IERC20Metadata(_bond.paymentToken()).decimals())
        );

        // Update poolIsSettled storage variable external contract interactions 
        poolIsSettled[_poolId] = true;

        // Forward final value to DIVA contract. Allocates the settlement fee as part of 
        // that process to this contract.
        _diva.setFinalReferenceValue(
            _poolId,
            _amountUnpaid * _SCALING, // formatted value (18 decimals)
            _challengeable
        );

        // Get the current fee claim allocated to this contract address (msg.sender)
        uint256 feeClaim = _diva.getClaims(
            _params.collateralToken,
            address(this)
        );

        // Transfer fee claim to the first reporter who is calling the function
        _diva.transferFeeClaim(msg.sender, _params.collateralToken, feeClaim);
    }

    function createContingentPool(
        address _divaDiamond,
        PorterPoolParams calldata _porterPoolParams
    ) external override nonReentrant returns (uint256) {
        IBondFactory _bondFactory = IBondFactory(_bondFactoryAddress);
        address _porterBond = _porterPoolParams.referenceAsset;
        require(
            _bondFactory.isBond(_porterBond), // check if Bond address is valid from Bond factory contract
            "DIVAPorterModule: invalid Bond address"
        );

        IBond _bond = IBond(_porterBond);
        uint256 gracePeriodEnd = _bond.gracePeriodEnd();
        uint256 bondTotalSupply = IERC20Metadata(_porterBond).totalSupply();

        // Set allowance for collateral token
        IERC20Metadata collateralToken = IERC20Metadata(
            _porterPoolParams.collateralToken
        );
        collateralToken.approve(
            _divaDiamond,
            _porterPoolParams.collateralAmount
        );

        // Transfer approved collateral tokens from user to DIVAPorterModule contract
        collateralToken.safeTransferFrom(
            msg.sender,
            address(this),
            _porterPoolParams.collateralAmount
        );

        IDIVA.PoolParams memory _poolParams;
        _poolParams.referenceAsset = _addressToString(_porterBond);
        _poolParams.expiryTime = uint96(gracePeriodEnd);
        _poolParams.floor = 0;
        _poolParams.inflection = _porterPoolParams.inflection;
        _poolParams.cap = bondTotalSupply;
        _poolParams.gradient = _porterPoolParams.gradient;
        _poolParams.collateralAmount = _porterPoolParams.collateralAmount;
        _poolParams.collateralToken = _porterPoolParams.collateralToken;
        _poolParams.dataProvider = address(this);
        _poolParams.capacity = _porterPoolParams.capacity;

        IDIVA _diva = IDIVA(_divaDiamond);
        uint256 _poolId = _diva.createContingentPool(_poolParams);

        return _poolId;
    }

    function setBondFactoryAddress(address _newBondFactoryAddress)
        external
        override
        onlyOwner
    {
        _bondFactoryAddress = _newBondFactoryAddress;
    }

    function challengeable() external view override returns (bool) {
        return _challengeable;
    }

    function getBondFactoryAddress() external view override returns (address) {
        return _bondFactoryAddress;
    }

    /**
     * @notice Function to convert address to string.
     */
    function _addressToString(address _addr)
        internal
        pure
        returns (string memory)
    {
        bytes32 _bytes = bytes32(uint256(uint160(_addr)));
        bytes memory _hex = "0123456789abcdef";

        bytes memory _string = new bytes(42);
        _string[0] = "0";
        _string[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            _string[2 + i * 2] = _hex[uint256(uint8(_bytes[i + 12] >> 4))];
            _string[3 + i * 2] = _hex[uint256(uint8(_bytes[i + 12] & 0x0f))];
        }
        return string(_string);
    }

    /**
     * @notice Function to convert string to address.
     */
    function _stringToAddress(string memory _a)
        internal
        pure
        returns (address)
    {
        bytes memory tmp = bytes(_a);
        require(tmp.length == 42, "DIVAPorterModule: invalid address");
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint256 i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) b1 -= 87;
            else if ((b1 >= 48) && (b1 <= 57)) b1 -= 48;
            if ((b2 >= 97) && (b2 <= 102)) b2 -= 87;
            else if ((b2 >= 48) && (b2 <= 57)) b2 -= 48;
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
pragma solidity 0.8.9;

interface IDIVAPorterModule {
    // Argument for `createContingentPool` function inside DIVAPorterModule contract.
    // Note that expiryTime is automatically set to the end of the grace period.
    // Further note that referenceAsset is an address rather than a string.
    struct PorterPoolParams {
        address referenceAsset;
        uint256 inflection;
        uint256 gradient;
        uint256 collateralAmount;
        address collateralToken;
        uint256 capacity;
    }

    /**
     * @dev Function to set the final reference value for a given `poolId`.
     * @param _divaDiamond Address of the diva smart contract. Used as argument
     * rather than a hard-coded constant to avoid redeploying the oracle contracts
     * when a new version of DIVA Protocol is released.
     * @param _poolId The unique identifier of the pool.
     */
    function setFinalReferenceValue(address _divaDiamond, uint256 _poolId)
        external;

    /**
     * @notice Function to create contingent pool. Note that as opposed to DIVA Protocol,
     * expiryTime is automatically set to the end of the grace period. Further note that
     * referenceAsset is an address rather than a string.
     * @dev Position token supply equals `collateralAmount` (minimum 1e6).
     * Position tokens have the same amount of decimals as the collateral token.
     * Only ERC20 tokens with 6 <= decimals <= 18 are accepted as collateral.
     * Tokens with flexible supply like Ampleforth should not be used. When
     * interest/yield bearing tokens are considered, only use tokens with a
     * constant balance mechanism such as Compound's cToken or the wrapped
     * version of Lido's staked ETH (wstETH).
     * ETH is not supported as collateral in v1. It has to be wrapped into WETH
       before deposit.
     * @param _divaDiamond Address of the diva smart contract. Used as argument
     * rather than a hard-coded constant to avoid redeploying the oracle contracts
     * when a new version of DIVA Protocol is released.
     * @param _porterPoolParams Struct containing the pool specification:
     * - referenceAsset: The address of bond contract.
     * - inflection: Value of underlying at which the long token will payout
         out `gradient` and the short token `1-gradient`.
     * - gradient: Long token payout at inflection. The short token payout at
         inflection is `1-gradient`.
     * - collateralAmount: Collateral amount to be deposited into the pool to
         back the position tokens.
     * - collateralToken: ERC20 collateral token address.
     * - capacity: The maximum collateral amount that the pool can accept.
     * @return poolId
     */
    function createContingentPool(
        address _divaDiamond,
        PorterPoolParams calldata _porterPoolParams
    ) external returns (uint256);

    /**
     * @dev Function to update `_bondFactoryAddress`. Only callable by contract owner.
     * @param _newBondFactoryAddress New Bond Factory Address
     */
    function setBondFactoryAddress(address _newBondFactoryAddress) external;

    /**
     * @dev Returns whether the oracle's data feed is challengeable or not.
     * Will return false in that implementation.
     */
    function challengeable() external view returns (bool);

    /**
     * @dev Returns Bond Factory address
     */
    function getBondFactoryAddress() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

interface IBond {
    /**
        @notice The amount of paymentTokens required to fully pay the contract.
        @return paymentTokens The number of paymentTokens unpaid.
    */
    function amountUnpaid() external view returns (uint256 paymentTokens);

    /**
        @notice One week after the maturity date. Bond collateral can be 
            redeemed after this date.
        @return gracePeriodEndTimestamp The grace period end date as 
            a timestamp. This is always one week after the maturity date
    */
    function gracePeriodEnd()
        external
        view
        returns (uint256 gracePeriodEndTimestamp);

    /**
        @notice This is the token the borrower deposits into the contract and
            what the Bond holders will receive when redeemed.
        @return The address of the token.
    */
    function paymentToken() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

interface IBondFactory {
    /**
        @notice Returns whether or not the given address key is a bond created
            by this Bond factory.
        @dev This mapping is used to check if a bond was issued by this contract
            on-chain. For example, if we want to make a new contract that
            accepts any issued Bonds and exchanges them for new Bonds, the
            exchange contract would need a way to know that the Bonds are owned
            by this contract.
    */
    function isBond(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Shortened version of the interface including required functions only
 */
interface IDIVA {
    // Settlement status
    enum Status {
        Open,
        Submitted,
        Challenged,
        Confirmed
    }

    // Collection of pool related parameters
    struct Pool {
        uint256 floor;
        uint256 inflection;
        uint256 cap;
        uint256 gradient;
        uint256 collateralBalance;
        uint256 finalReferenceValue;
        uint256 capacity;
        uint256 statusTimestamp;
        address shortToken;
        uint96 payoutShort;
        address longToken;
        uint96 payoutLong;
        address collateralToken;
        uint96 expiryTime;
        address dataProvider;
        uint96 protocolFee;
        uint96 settlementFee;
        Status statusFinalReferenceValue;
        string referenceAsset;
    }

    // Argument for `createContingentPool` function
    struct PoolParams {
        string referenceAsset;
        uint96 expiryTime;
        uint256 floor;
        uint256 inflection;
        uint256 cap;
        uint256 gradient;
        uint256 collateralAmount;
        address collateralToken;
        address dataProvider;
        uint256 capacity;
    }

    /**
     * @dev Throws if called by any account other than the `dataProvider`
     * specified in the contract parameters. Current implementation allows
     * for positive final values only. For negative metrices, choose the
     * negated or shifted version as your reference asset (e.g., -LIBOR).
     * @param _poolId The pool Id for which the settlement value is submitted
     * @param _finalReferenceValue Proposed settlement value by the data
     * feed provider
     * @param _allowChallenge Toggle to enable/disable the challenge
     * functionality. If 0, then the submitted reference value will
     * immediately go into confirmed status, a challenge will not be possible.
     * This parameter was introduced to allow automated oracles (e.g.,
     * Tellor, Uniswap v3, Chainlink) to settle without dispute.
     */
    function setFinalReferenceValue(
        uint256 _poolId,
        uint256 _finalReferenceValue,
        bool _allowChallenge
    ) external;

    /**
     * @notice Function to transfer fee claims to another account. To be
     * called by oracle contract after a user has triggered the reference
     * value feed and settlement fees were assigned
     * @dev `msg.sender` has to have a fee claim allocation in order to initiate
     * the transfer
     * @param _recipient Recipient address of the fee claim
     * @param _collateralToken Collateral token address
     * @param _amount Amount expressed in collateral token to transfer to
     * recipient
     */
    function transferFeeClaim(
        address _recipient,
        address _collateralToken,
        uint256 _amount
    ) external;

    /**
     * @notice Function to issue long and the short position tokens to
     * `msg.sender` upon collateral deposit. Provided collateral is kept inside
     * the contract until position tokens are redeemed by calling
     * `redeemPositionToken` or `removeLiquidity`.
     * @dev Position token supply equals `collateralAmount` (minimum 1e6).
     * Position tokens have the same amount of decimals as the collateral token.
     * Only ERC20 tokens with 6 <= decimals <= 18 are accepted as collateral.
     * Tokens with flexible supply like Ampleforth should not be used. When
     * interest/yield bearing tokens are considered, only use tokens with a
     * constant balance mechanism such as Compound's cToken or the wrapped
     * version of Lido's staked ETH (wstETH).
     * ETH is not supported as collateral in v1. It has to be wrapped into WETH
       before deposit.
     * @param _poolParams Struct containing the pool specification:
     * - referenceAsset: The name of the reference asset (e.g., Tesla-USD or
         ETHGasPrice-GWEI).
     * - expiryTime: Expiration time of the position tokens expressed as a unix
         timestamp in seconds.
     * - floor: Value of underlying at or below which the short token will pay
         out the max amount and the long token zero.
     * - inflection: Value of underlying at which the long token will payout
         out `gradient` and the short token `1-gradient`.
     * - cap: Value of underlying at or above which the long token will pay
         out the max amount and short token zero.
     * - gradient: Long token payout at inflection. The short token payout at
         inflection is `1-gradient`.
     * - collateralAmount: Collateral amount to be deposited into the pool to
         back the position tokens.
     * - collateralToken: ERC20 collateral token address.
     * - dataProvider: Address that is supposed to report the final value of
         the reference asset.
     * - capacity: The maximum collateral amount that the pool can accept.
     * @return poolId
     */
    function createContingentPool(PoolParams calldata _poolParams)
        external
        returns (uint256);

    /**
     * @notice Returns the pool parameters for a given pool Id
     * @param _poolId Id of the pool
     * @return Pool struct
     */
    function getPoolParameters(uint256 _poolId)
        external
        view
        returns (Pool memory);

    /**
     * @dev Returns the claims by collateral tokens for a given account
     * @param _recipient Account address
     * @param _collateralToken Collateral token address
     * @return Array of Claim structs
     */
    function getClaims(address _collateralToken, address _recipient)
        external
        view
        returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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