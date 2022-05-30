/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File contracts/misc/isolation/PoolFundManagerInterface.sol


pragma solidity ^0.8.0;

interface PoolFundManagerInterface {

    function mint(address minter, uint amount) external payable;
    function redeem(address redeemer, uint amount) external ;
    function borrow(address borrower, uint amount) external;
    function repayBorrow(address borrower, uint amount) external payable;
    function liquidateBorrow(address borrower, uint amount) external payable;
}

interface PoolFundManagerConfigInterface{
    function minReserveRatio() external returns(uint);
    function maxReserveRatio() external returns(uint);
    function getMarketToken(address underlying) external view returns(address);
    function setMarketToken(address underlying, address market) external;
}


// File contracts/lib/interfaces/MarketTokenInterface.sol


pragma solidity ^0.8.0;

interface MarketTokenInterface {
    function isMarketToken() external view returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function underlying() external view returns (address);
    function reserveFactorMantissa() external view returns (uint256);
    function accrualBlockTimestamp() external view returns (uint256);
    function borrowIndex() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
    function totalReserves() external view returns (uint256);
    function accountTokens(address account) external view returns (uint256);
    function accountBorrows(address account) external view returns (uint256,uint256);
    function protocolSeizeShareMantissa() external view returns (uint256);
    function comptroller() external view returns (address);
    function interestRateModel() external view returns (address);

    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerSecond() external view returns (uint);
    function supplyRatePerSecond() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);

    function _setComptroller(address newComptroller) external returns (uint);
    function _setReserveFactor(uint newReserveFactorMantissa) external  returns (uint);
    function _reduceReserves(uint reduceAmount) external  returns (uint);
    function _setInterestRateModel(address newInterestRateModel) external  returns (uint);



    
}

interface MarketTokenEtherInterface is MarketTokenInterface{

    function mint() external payable;
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow() external payable;
    function repayBorrowBehalf(address borrower) external payable;
    function liquidateBorrow(address borrower, address marketTokenCollateral) external payable;

    function _addReserves() external payable returns (uint);

}

interface MarketTokenERC20Interface is MarketTokenInterface{

    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, address marketTokenCollateral) external returns (uint);
    function sweepToken(address token) external ;

    function _addReserves(uint addAmount) external returns (uint);

}


// File contracts/lib/interfaces/ComptrollerInterface.sol


pragma solidity ^0.8.0;

interface ComptrollerInterface {

    function isComptroller() external view returns(bool);
    function oracle() external view returns(address);
    function distributioner() external view returns(address);
    function closeFactorMantissa() external view returns(uint);
    function liquidationIncentiveMantissa() external view returns(uint);
    function maxAssets() external view returns(uint);
    function accountAssets(address account,uint index) external view returns(address);
    function markets(address market) external view returns(bool,uint);

    function pauseGuardian() external view returns(address);
    function paused() external view returns(bool);
    function marketMintPaused(address market) external view returns(bool);
    function marketRedeemPaused(address market) external view returns(bool);
    function marketBorrowPaused(address market) external view returns(bool);
    function marketRepayBorrowPaused(address market) external view returns(bool);
    function marketTransferPaused(address market) external view returns(bool);
    function marketSeizePaused(address market) external view returns(bool);
    function borrowCaps(address market) external view returns(uint);
    function supplyCaps(address market) external view returns(uint);
    function liquidateWhiteAddresses(uint index) external view returns(address);

    function enterMarkets(address[] calldata marketTokens) external returns (uint[] memory);
    function exitMarket(address marketToken) external returns (uint);

    function mintAllowed(address marketToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(address marketToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address marketToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address marketToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address marketToken, address borrower, uint borrowAmount) external returns (uint);
    function borrowVerify(address marketToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address marketToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);
    function repayBorrowVerify(
        address marketToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) external;

    function liquidateBorrowAllowed(
        address marketTokenBorrowed,
        address marketTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint);
    function liquidateBorrowVerify(
        address marketTokenBorrowed,
        address marketTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external;

    function seizeAllowed(
        address marketTokenCollateral,
        address marketTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);
    function seizeVerify(
        address marketTokenCollateral,
        address marketTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address marketToken, address src, address dst, uint transferTokens) external returns (uint);
    function transferVerify(address marketToken, address src, address dst, uint transferTokens) external;

    function liquidateCalculateSeizeTokens(
        address marketTokenBorrowed,
        address marketTokenCollateral,
        uint repayAmount) external view returns (uint, uint);

    function getHypotheticalAccountLiquidity(
        address account,
        address marketTokenModify,
        uint redeemTokens,
        uint borrowAmount) external view returns (uint, uint, uint);

    function getAssetsIn(address account) external view returns (address[] memory);
    function checkMembership(address account, address marketToken) external view returns (bool) ;
    function getAccountLiquidity(address account) external view returns (uint, uint, uint) ;
    function getAllMarkets() external view returns (address[] memory);
    function isDeprecated(address marketToken) external view returns (bool);
    function isMarketListed(address marketToken) external view returns (bool);

    
}

interface ComptrollerFlashloanInterface is ComptrollerInterface{
    function flashloanAllowed(
        address marketToken,
        address receiver,
        uint256 amount,
        bytes calldata params
    ) external view returns (uint);

    function flashloanVerify(
        address marketToken,
        address receiver,
        uint256 amount,
        bytes calldata params
    ) external;

    function marketFlashloanPaused(address market) external view returns(bool);
    function flashloanWhiteAddresses(uint index) external view returns(address);

}


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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


// File contracts/lib/interfaces/IERC20.sol


pragma solidity ^0.8.0;

interface IERC20 is IERC20Upgradeable{
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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


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


// File @openzeppelin/contracts-upgradeable/access/[email protected]


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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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


// File contracts/misc/isolation/PoolFundManagerForWePiggy.sol


pragma solidity ^0.8.0;






contract PoolFundManagerForWePiggy is PoolFundManagerInterface,OwnableUpgradeable  {

    using SafeERC20Upgradeable for IERC20;

    enum ActionType { DepositAction, RedeemAction, BorrowAction, RepayAction }

    ComptrollerInterface public comptroller;       
    PoolFundManagerConfigInterface public config;     //configuration contract address

    mapping(address => uint256) public totalBorrows;     // amount of borrow tokens
    mapping(address => uint256) public totalReserve;   // amount of tokens in reservation
    mapping(address => uint256) public totalWePiggy;  // amount of tokens in wepiggy
   
    address public constant WPC_ADDR = 0x6F620EC89B8479e97A6985792d0c64F237566746;

    event WithdrawWPC(address beneficiary, uint256 amount);

    modifier onlyMarketListed(address _token) {
        require(address(comptroller) ==  MarketTokenInterface(_token).comptroller(),"Error comptroller");
        require(comptroller.isMarketListed(_token),"Unsupported market");
        _;
    }


    function initialize(address _comptroller, address _config) public initializer {
        comptroller = ComptrollerInterface(_comptroller);
        config = PoolFundManagerConfigInterface(_config);

        OwnableUpgradeable.__Ownable_init();
    }

    /**
     * Total amount of the token
     * @param token token address, the underlying of poolMarket
     */
    function getTotalDepositStore(address token) public view returns(uint) {
        // totalLoans[token] = U   totalReserve[token] = R
        return totalWePiggy[token] + totalBorrows[token] + totalReserve[token]; // return totalAmount = C + U + R
    }

    /**
     * Update total amount of token in WePiggy
     * @param token token address, the underlying of poolMarket
     */
    function updateTotalWePiggy(address token) internal{
        address marketAddr = config.getMarketToken(token);
        if(marketAddr != address(0)){
            totalWePiggy[token] = MarketTokenInterface(marketAddr).balanceOfUnderlying(address(this));
        }
    }

    /**
     * Update the total reservation. 
     * @param token token address, the underlying of poolMarket
     * @param amount the amount
     * @param action indicate if user's operation is deposit or withdraw, and borrow or repay.
     * @return wepiggyAmount the actuall amount deposit/withdraw from the saving pool
     */
    function updateTotalReserve(address token, uint amount, ActionType action) internal returns(uint256 wepiggyAmount){
        
        uint totalAmount = getTotalDepositStore(token);
        address marketAddr = config.getMarketToken(token);

        if(action == ActionType.DepositAction || action == ActionType.RepayAction){
            // update totalAmount when deposit or update totalBorrows when repay
            if(action == ActionType.DepositAction){
                totalAmount = totalAmount + amount;
            }else{
                totalBorrows[token] = totalBorrows[token] + amount;
            }

            // Expected total amount of token in reservation after deposit or repay
            uint totalReserveBeforeAdjust = totalReserve[token] + amount;

            // Trigger toWePiggt if the new reservation ratio is bigger than 20%
            if(marketAddr != address(0) && totalReserveBeforeAdjust > totalAmount * config.maxReserveRatio() / 100){
                uint midReserveRatio = (config.maxReserveRatio() + config.minReserveRatio()) / 2;
                uint toWePiggyAmount = totalReserveBeforeAdjust - (totalAmount * midReserveRatio / 100);

                wepiggyAmount = toWePiggyAmount;
                totalWePiggy[token] = totalWePiggy[token] + toWePiggyAmount;
                totalReserve[token] = totalReserve[token] + amount - toWePiggyAmount;
            }else{
                totalReserve[token] = totalReserve[token] + amount;
            }

        }else if(action == ActionType.RedeemAction || action == ActionType.BorrowAction){

            require(totalReserve[token] + totalWePiggy[token] >= amount,"Lack of liquidity.");

            // update totalAmount when redeem or update totalBorrows when borrow
            if(action == ActionType.RedeemAction){
                totalAmount = totalAmount - amount;
            }else{
                totalBorrows[token] = totalBorrows[token] + amount;
            }

            // Expected total amount of token in reservation after redeem or borrow.
            uint totalReserveBeforeAdjust = totalReserve[token] > amount ? totalReserve[token] - amount : 0;

            // Trigger fromWePiggy if the new reservation ratio is less than 10%
            if(marketAddr != address(0) && totalReserveBeforeAdjust < totalAmount * config.minReserveRatio() / 100){
                uint midReserveRatio = (config.maxReserveRatio() + config.minReserveRatio()) / 2;
                uint totalAvailable = totalReserve[token] + totalWePiggy[token] - amount;

                if(totalAvailable < totalAmount * midReserveRatio / 100){
                    // Withdraw all the tokens from WePiggy
                    wepiggyAmount = totalWePiggy[token];
                    totalWePiggy[token] = 0;
                    totalReserve[token] = totalAvailable;
                }else{
                    // Withdraw partial tokens from WePiggy
                    uint totalInWePiggy = totalAvailable - (totalAmount * midReserveRatio / 100);
                    wepiggyAmount = totalWePiggy[token] - totalInWePiggy;
                    totalWePiggy[token] = totalInWePiggy;
                    totalReserve[token] = totalAvailable - totalInWePiggy;
                }

            }else{
                totalReserve[token] = totalReserve[token] - amount;
            }

        }else{
            revert("Error action");
        }

        return wepiggyAmount;

    }



    function update(address token, uint amount, ActionType action) internal returns(uint) {

        updateTotalWePiggy(token);

        uint wepiggyAmount = updateTotalReserve(token, amount, action);
        return wepiggyAmount;
    }
    

    function mint(address minter, uint amount) external payable onlyMarketListed(msg.sender){
       
        require(amount != 0,"Amount is zero");
        address token = MarketTokenInterface(msg.sender).underlying();

        minter;
        //todo 更新利润分配

        uint wepiggyAmount = update(token, amount, ActionType.DepositAction);
        if(wepiggyAmount > 0){
            toWePiggy(token, wepiggyAmount);
        }
        

    }

    function redeem(address redeemer, uint amount) external onlyMarketListed(msg.sender){
        
        require(amount != 0,"Amount is zero");
        address token = MarketTokenInterface(msg.sender).underlying();

        redeemer;
        //todo 更新利润分配
        uint wepiggyAmount = update(token, amount, ActionType.DepositAction);
        if(wepiggyAmount > 0){
            fromWePiggy(token, wepiggyAmount);
        }

        if(token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE){
            payable(msg.sender).transfer(amount);
        }else{
            _approveMax(token, msg.sender, amount);
        }

        
    }

    function borrow(address borrower, uint amount) external onlyMarketListed(msg.sender){
       
        require(amount != 0,"Amount is zero");
        address token = MarketTokenInterface(msg.sender).underlying();

        borrower;
        //todo 更新利润分配

        uint wepiggyAmount = update(token, amount, ActionType.DepositAction);
        if(wepiggyAmount > 0){
            fromWePiggy(token, wepiggyAmount);
        }

        if(token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE){
            payable(msg.sender).transfer(amount);
        }else{
            _approveMax(token, msg.sender, amount);
        }

    }

    function repayBorrow(address borrower, uint amount) external payable onlyMarketListed(msg.sender){
      
        require(amount != 0,"Amount is zero");
        address token = MarketTokenInterface(msg.sender).underlying();

        borrower;
        //todo 更新利润分配

        uint wepiggyAmount = update(token, amount, ActionType.DepositAction);
        if(wepiggyAmount > 0){
            toWePiggy(token, wepiggyAmount);
        }

    }

    function liquidateBorrow(address borrower, uint amount) external payable onlyMarketListed(msg.sender){
        
        require(amount != 0,"Amount is zero");
        address token = MarketTokenInterface(msg.sender).underlying();

        borrower;
        //todo 更新利润分配

        uint wepiggyAmount = update(token, amount, ActionType.DepositAction);
        if(wepiggyAmount > 0){
            toWePiggy(token, wepiggyAmount);
        }

    }

    /**
     * withdraw token from wepiggy
     */
    function fromWePiggy(address _token, uint _amount) internal {
        address marketAddr = config.getMarketToken(_token);
        if(marketAddr != address(0)){
            bytes memory payload = abi.encodeWithSignature("redeemUnderlying(uint256)", _amount);
            (bool success, bytes memory returndata) = marketAddr.call(payload);
            require(success && abi.decode(returndata,(uint)) == 0,"redeemUnderlying failed");
        }

    }

    /**
     * deposit token to wepiggy
     */
    function toWePiggy(address _token, uint _amount) internal {
        address marketAddr = config.getMarketToken(_token);
        if(marketAddr != address(0)){
            if(_token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE){
                bytes memory payload = abi.encodeWithSignature("mint()");
                (bool success, ) = marketAddr.call{value:_amount}(payload);
                require(success,"mint failed");
            }else{
                _approveMax(_token, marketAddr, _amount);

                bytes memory payload = abi.encodeWithSignature("mint(uint256)", _amount);
                (bool success,bytes memory returndata) = marketAddr.call(payload);
                require(success && abi.decode(returndata,(uint)) == 0,"mint failed 111");
            }
        }
    }


    function _approveMax(address token, address to, uint amount) internal {

        IERC20 erc20 = IERC20(token);
        uint allowance = erc20.allowance(address(this), to);
        if (allowance < amount) {
            erc20.safeApprove(to, type(uint).max);
        }
    }

    

    function callWePiggy(address _poolMarket, uint _amount, uint callType) external onlyOwner{
        if(callType == 1){
            fromWePiggy(_poolMarket, _amount);
        }else if(callType == 2){
            toWePiggy(_poolMarket, _amount);
        }
    }

    /**
     * Withdraw WPC token to beneficiary
     * @param _beneficiary the address of the WPC to
     */
    function withdrawWPC(address _beneficiary) external onlyOwner {
        uint256 wpcBalance = IERC20(WPC_ADDR).balanceOf(address(this));
        IERC20(WPC_ADDR).transfer(_beneficiary, wpcBalance);

        emit WithdrawWPC(_beneficiary, wpcBalance);
    }

    receive() external payable {}

}