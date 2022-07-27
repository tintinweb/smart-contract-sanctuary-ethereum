/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.9.3 https://hardhat.org

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


// File contracts/lib/interfaces/PriceOracle.sol


pragma solidity ^0.8.0;

interface PriceOracle {
    /**
      * @notice Get the underlying price of a marketToken asset
      * @param marketToken The marketToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e(36-decimals)).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(MarketTokenInterface marketToken) external view returns (uint);
}


interface PriceSource {
    /**
     * @notice Get the price of an token asset.
     * @param token The token asset to get the price of.
     * @return The token asset price in USD as a mantissa (scaled by 1e8).
    */
    function getPrice(address token) external view returns (uint);
}


// File contracts/lib/interfaces/DistributionerInterface.sol


pragma solidity ^0.8.0;

interface DistributionerInterface {

    function _initializeMarket(address marketToken) external;

    function distributeMintReward(address marketToken, address minter) external;
    function distributeRedeemReward(address marketToken, address redeemer) external;
    function distributeBorrowReward(address marketToken, address borrower) external;
    function distributeRepayBorrowReward(address marketToken, address borrower) external;
    function distributeSeizeReward(address marketTokenCollateral, address borrower, address liquidator) external;
    function distributeTransferReward(address marketToken, address src, address dst) external;

    function rewardSupplySpeeds(address marketToken) external view returns(uint);
    function rewardBorrowSpeeds(address marketToken) external view returns(uint);
    function rewardAccrued(address account) external view returns(uint);
    function rewardToken() external view returns(address);

    function claimRewardToken(address holder) external;
    function claimRewardToken(address holder, address[] memory marketTokens) external;
    function claimRewardToken(address[] memory holders, address[] memory marketTokens, bool borrowers, bool suppliers) external;


}

interface DistributionerManagerInterface {
    function getDistributioners() external view returns(address[] memory);
}


// File contracts/lib/ExponentialNoError.sol


pragma solidity ^0.8.0;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mul_ScalarTruncate(Exp memory a, uint scalar) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mul_ScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return add_(truncate(product), addend);
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint n, string memory errorMessage) pure internal returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function safe32(uint n, string memory errorMessage) pure internal returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        return add_(a, b, "addition overflow");
    }

    function add_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b) pure internal returns (uint) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Double memory b) pure internal returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint a, uint b) pure internal returns (uint) {
        return div_(a, b, "divide by zero");
    }

    function div_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }
}


// File contracts/lib/ErrorReporter.sol


pragma solidity ^0.8.0;

contract ComptrollerErrorReporter {

  uint public constant NO_ERROR = 0; // support legacy return codes

  error Unauthorized();
  error ComptrollerMismatch();
  error InsufficientShortfall();
  error InsufficientLiquidity(); 
  error InvalidCloseFactor();
  error InvalidCollateralFactor();
  error MarketNotEntered();
  error MarketNotListed();
  error MarketAlreadyListed();
  error NonzeroBorrowBalance();
  error PriceError();
  error Rejection();
  error SnapshotError();
  error TooManyAssets();
  error TooMuchRepay();

  error ExitMarketBalanceOwed();
  error ExitMarketRejection();
  error SetCloseFactorOwnerCheck();
  error SetCloseFactorValidation();
  error SetCollateralFactorOwnerCheck();
  error SetCollateralFactorNoExists();
  error SetCollateralFactorValidation();
  error SetCollateralFactorWithoutPrice();
  error SetLiquidationIncentiveOwnerCheck();
  error SetLiquidationIncentiveValidation();
  error SetMaxAssetsOwnerCheck();
  error SetPriceOracleOwnerCheck();
  error SupportMarketExists();
  error SupportMarketOwnerCheck();
  error SetPauseGuarianOwnerCheck();

}

contract TokenErrorReporter {

  uint public constant NO_ERROR = 0; // support legacy return codes

  error TransferComptrollerRejection(uint256 errorCode);
  error TransferNotAllowed();
  error TransferNotEnough();
  error TransferTooMuch();

  error ExchangeRateReadFailed(uint errorCode);

  error MintComptrollerRejection(uint256 errorCode);
  error MintFreshnessCheck();
  
  error RedeemExchangeTokenCalculationFailed(uint256 errorCode);
  error RedeemExchangeAmountCalculationFailed(uint256 errorCode);
  error RedeemComptrollerRejection(uint256 errorCode);
  error RedeemFreshnessCheck();
  error RedeemTransferOutNotPossible();

  error BorrowComptrollerRejection(uint256 errorCode);
  error BorrowFreshnessCheck();
  error BorrowCashNotAvailable();

  error RepayBorrowComptrollerRejection(uint256 errorCode);
  error RepayBorrowFreshnessCheck();

  error LiquidateComptrollerRejection(uint256 errorCode);
  error LiquidateFreshnessCheck();
  error LiquidateCollateralFreshnessCheck();
  error LiquidateAccrueBorrowInterestFailed(uint256 errorCode);
  error LiquidateAccrueCollateralInterestFailed(uint256 errorCode);
  error LiquidateLiquidatorIsBorrower();
  error LiquidateCloseAmountIsZero();
  error LiquidateCloseAmountIsUintMax();
  error LiquidateRepayBorrowFreshFailed(uint256 errorCode);

  error LiquidateSeizeComptrollerRejection(uint256 errorCode);
  error LiquidateSeizeLiquidatorIsBorrower();

  error AcceptAdminPendingAdminCheck();

  error SetComptrollerOwnerCheck();
  error SetPendingAdminOwnerCheck();

  error SetReserveFactorAdminCheck();
  error SetReserveFactorFreshCheck();
  error SetReserveFactorBoundsCheck();

  error AddReservesFactorFreshCheck(uint256 actualAddAmount);

  error ReduceReservesAdminCheck();
  error ReduceReservesFreshCheck();
  error ReduceReservesCashNotAvailable();
  error ReduceReservesCashValidation();

  error SetInterestRateModelOwnerCheck();
  error SetInterestRateModelFreshCheck();


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


// File contracts/comptroller/AbstractComptroller.sol


pragma solidity ^0.8.0;






abstract contract AbstractComptroller is ComptrollerErrorReporter, ExponentialNoError, OwnableUpgradeable{

    bool public constant isComptroller = true;

    /**
     * @notice Oracle which gives the price of any given asset
     */
    PriceOracle public oracle;

    /**
     * @notice distribution the reward token
     */
    DistributionerInterface public distributioner;

    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    uint public closeFactorMantissa;

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
    uint public liquidationIncentiveMantissa;

    /**
     * @notice Per-account mapping of "assets you are in"
     */
    mapping(address => MarketTokenInterface[]) public accountAssets;

    /**
     * @notice A list of all markets
     */
    MarketTokenInterface[] public allMarkets;

    struct Market {
        /**
         * @notice Whether or not this market is listed
         */
        bool isListed;

        /**
         * @notice Multiplier representing the most one can borrow against their collateral in this market.
         *  For instance, 0.9 to allow borrowing 90% of collateral value.
         *  Must be between 0 and 1, and stored as a mantissa.
         */
        uint collateralFactorMantissa;

        /**
         * @notice Per-market mapping of "accounts in this asset"
         */
        mapping(address => bool) accountMembership;

    }

    /**
     * @notice Official mapping of pTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    mapping(address => Market) public markets;

    /**
     * @notice The Pause Guardian can pause certain actions as a safety mechanism.
     *  Actions which allow users to remove their own assets cannot be paused.
     */
    address public pauseGuardian;
    bool public paused;
    mapping(address => bool) public marketMintPaused;
    mapping(address => bool) public marketRedeemPaused;
    mapping(address => bool) public marketBorrowPaused;
    mapping(address => bool) public marketRepayBorrowPaused;
    mapping(address => bool) public marketTransferPaused;
    mapping(address => bool) public marketSeizePaused;

    /**
     * @notice Borrow caps enforced by borrowAllowed for each marketToken address. Defaults to zero which corresponds to unlimited borrowing.
     */
    mapping(address => uint) public borrowCaps;

    /**
     * @notice Supply caps enforced by mintAllowed for each marketToken address. Defaults to zero which corresponds to unlimited minting.
     */
    mapping(address => uint) public supplyCaps;

    /**
     * @notice Only addresses in the allowlist can call liquidations
     */
    address[] public liquidateAllowAddresses;

    // No collateralFactorMantissa may exceed this value
    uint internal constant collateralFactorMaxMantissa = 0.9e18; // 0.9

    /// @notice Emitted when an admin supports a market
    event MarketListed(MarketTokenInterface marketToken);

    /// @notice Emitted when an account enters a market
    event MarketEntered(MarketTokenInterface marketToken, address account);

    /// @notice Emitted when an account exits a market
    event MarketExited(MarketTokenInterface marketToken, address account);

    /// @notice Emitted when close factor is changed by admin
    event NewCloseFactor(uint oldCloseFactorMantissa, uint newCloseFactorMantissa);

    /// @notice Emitted when a collateral factor is changed by admin
    event NewCollateralFactor(MarketTokenInterface marketToken, uint oldCollateralFactorMantissa, uint newCollateralFactorMantissa);

    /// @notice Emitted when liquidation incentive is changed by admin
    event NewLiquidationIncentive(uint oldLiquidationIncentiveMantissa, uint newLiquidationIncentiveMantissa);

    /// @notice Emitted when price oracle is changed
    event NewPriceOracle(PriceOracle oldPriceOracle, PriceOracle newPriceOracle);

    /// @notice Emitted when pause guardian is changed
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

    /// @notice Emitted when distributioner is changed
    event NewDistributioner(address oldDistributioner, address newDistributioner);

    /// @notice Emitted when an action is paused on a market
    event ActionPaused(MarketTokenInterface marketToken, string action, bool pauseState);

    /// @notice Emitted when paused changed
    event Paused(bool pauseState);

    /// @notice Emitted when borrow cap for a marketToken is changed
    event NewBorrowCap(MarketTokenInterface indexed marketToken, uint newBorrowCap);

    /// @notice Emitted when mint cap for a marketToken is changed
    event NewSupplyCap(MarketTokenInterface indexed marketToken, uint newSupplyCap);

    /// @notice Emitted when minted
    event MintVerify(address marketToken, address minter, uint actualMintAmount, uint mintTokens);

    /// @notice Emitted when redeemed
    event RedeemVerify(address marketToken, address redeemer, uint redeemAmount, uint redeemTokens);

    /// @notice Emitted when borrowed
    event BorrowVerify(address marketToken, address borrower, uint borrowAmount);

    /// @notice Emitted when repayborrowed
    event RepayBorrowVerify(address marketToken, address payer, address borrower, uint actualRepayAmount, uint borrowerIndex);

    /// @notice Emitted when liquidateborrowed
    event LiquidateBorrowVerify(address marketTokenBorrowed,address marketTokenCollateral,address liquidator,address borrower,uint actualRepayAmount,uint seizeTokens);

    /// @notice Emitted when seized
    event SeizeVerify(address marketTokenCollateral,address marketTokenBorrowed,address liquidator,address borrower,uint seizeTokens); 

    /// @notice Emitted when transfered
    event TransferVerify(address marketToken, address src, address dst, uint transferTokens);

    function hasOwnerRights() public virtual view returns(bool) {
        return msg.sender == owner();
    }


}


// File contracts/comptroller/Comptroller.sol


pragma solidity ^0.8.0;

contract Comptroller is AbstractComptroller {

    function initialize(PriceOracle _oracle, uint _closeFactorMantissa,uint _liquidationIncentiveMantissa) public initializer virtual {
        OwnableUpgradeable.__Ownable_init();
       
        oracle = _oracle;
        closeFactorMantissa = _closeFactorMantissa;
        liquidationIncentiveMantissa = _liquidationIncentiveMantissa;
    }

    /*** Assets You Are In ***/

    /**
     * @notice Returns the assets an account has entered
     * @param account The address of the account to pull assets for
     * @return A dynamic list with the assets the account has entered
     */
    function getAssetsIn(address account) external view returns (MarketTokenInterface[] memory) {
        MarketTokenInterface[] memory assetsIn = accountAssets[account];
        return assetsIn;
    }

    /**
     * @notice Returns whether the given account is entered in the given asset
     * @param account The address of the account to check
     * @param marketToken The marketToken to check
     * @return True if the account is in the asset, otherwise false.
     */
    function checkMembership(address account, MarketTokenInterface marketToken) external view returns (bool) {
        return markets[address(marketToken)].accountMembership[account];
    }

    /**
     * @notice Add assets to be included in account liquidity calculation
     * @param marketTokens The list of addresses of the marketToken markets to be enabled
     * @return Success indicator for whether each corresponding market was entered
     */
    function enterMarkets(address[] memory marketTokens) public returns (uint[] memory) {
        uint len = marketTokens.length;

        uint[] memory results = new uint[](len);
        for (uint i = 0; i < len; i++) {
            MarketTokenInterface marketToken = MarketTokenInterface(marketTokens[i]);
            addToMarketInternal(marketToken, msg.sender);

            results[i] = NO_ERROR;
        }

        return results;
    }

    /**
     * @notice Add the market to the borrower's "assets in" for liquidity calculations
     * @param marketToken The market to enter
     * @param borrower The address of the account to modify
     */
    function addToMarketInternal(MarketTokenInterface marketToken, address borrower) internal {
        Market storage marketToJoin = markets[address(marketToken)];

        if (!marketToJoin.isListed) {
            // market is not listed, cannot join
            revert MarketNotListed();
        }

        if (marketToJoin.accountMembership[borrower] == true) {
            // already joined
            return;
        }

        // survived the gauntlet, add to list
        // NOTE: we store these somewhat redundantly as a significant optimization
        //  this avoids having to iterate through the list for the most common use cases
        //  that is, only when we need to perform liquidity checks
        //  and not whenever we want to check if an account is in a particular market
        marketToJoin.accountMembership[borrower] = true;
        accountAssets[borrower].push(marketToken);

        emit MarketEntered(marketToken, borrower);

    }

    /**
     * @notice Removes asset from sender's account liquidity calculation
     * @dev Sender must not have an outstanding borrow balance in the asset,
     *  or be providing necessary collateral for an outstanding borrow.
     * @param marketTokenAddress The address of the asset to be removed
     * @return Whether or not the account successfully exited the market
     */
    function exitMarket(address marketTokenAddress) external returns (uint) {
        MarketTokenInterface marketToken = MarketTokenInterface(marketTokenAddress);
        /* Get sender tokensHeld and amountOwed underlying from the marketToken */
        (uint oErr, uint tokensHeld, uint amountOwed, ) = marketToken.getAccountSnapshot(msg.sender);
        require(oErr == 0, "exitMarket: getAccountSnapshot failed"); // semi-opaque error code

        /* Fail if the sender has a borrow balance */
        if (amountOwed != 0) {
            revert NonzeroBorrowBalance();
        }

        /* Fail if the sender is not permitted to redeem all of their tokens */
        redeemAllowedInternal(marketTokenAddress, msg.sender, tokensHeld);

        Market storage marketToExit = markets[address(marketToken)];

        /* Return true if the sender is not already ‘in’ the market */
        if (!marketToExit.accountMembership[msg.sender]) {
            return NO_ERROR;
        }

        /* Set marketToken account membership to false */
        delete marketToExit.accountMembership[msg.sender];

        /* Delete marketToken from the account’s list of assets */
        // load into memory for faster iteration
        MarketTokenInterface[] memory userAssetList = accountAssets[msg.sender];
        uint len = userAssetList.length;
        uint assetIndex = len;
        for (uint i = 0; i < len; i++) {
            if (userAssetList[i] == marketToken) {
                assetIndex = i;
                break;
            }
        }

        // We *must* have found the asset in the list or our redundant data structure is broken
        assert(assetIndex < len);

        // copy last item in list to location of item to be removed, reduce length by 1
        MarketTokenInterface[] storage storedList = accountAssets[msg.sender];
        storedList[assetIndex] = storedList[storedList.length - 1];
        storedList.pop();

        emit MarketExited(marketToken, msg.sender);

        return NO_ERROR;
    }

    /*** Policy Hooks ***/

    /**
     * @notice Checks if the account should be allowed to mint tokens in the given market
     * @param marketToken The market to verify the mint against
     * @param minter The account which would get the minted tokens
     * @param mintAmount The amount of underlying being supplied to the market in exchange for tokens
     * @return 0 if the mint is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function mintAllowed(address marketToken, address minter, uint mintAmount) external returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!marketMintPaused[marketToken] && paused==false, "mint is paused");

        if (!markets[marketToken].isListed) {
            revert MarketNotListed();
        }

        // addToMarket when user mint
        if (!markets[marketToken].accountMembership[minter]) {
            require(msg.sender == marketToken, "sender must be marketToken");
            addToMarketInternal(MarketTokenInterface(msg.sender), minter);
            assert(markets[marketToken].accountMembership[minter]);
        }

        // make sure the supplyCap
        uint supplyCap = supplyCaps[marketToken];
        if (supplyCap != 0) {
            uint totalSupply = MarketTokenInterface(marketToken).totalSupply();
            uint exchangeRate = MarketTokenInterface(marketToken).exchangeRateStored();
            uint balance = mul_ScalarTruncate(Exp({mantissa : exchangeRate}), totalSupply);
            uint nextTotalMints = add_(balance, mintAmount);
            require(nextTotalMints < supplyCap, "market mint cap reached");
        }

        if(address(distributioner) != address(0)){
            distributioner.distributeMintReward(marketToken,minter);
        }

        return NO_ERROR;
    }

    /**
     * @notice Validates mint and reverts on rejection. May emit logs.
     * @param marketToken Asset being minted
     * @param minter The address minting the tokens
     * @param actualMintAmount The amount of the underlying asset being minted
     * @param mintTokens The number of tokens being minted
     */
    function mintVerify(address marketToken, address minter, uint actualMintAmount, uint mintTokens) public virtual{
        emit MintVerify(marketToken, minter, actualMintAmount, mintTokens);
    }

    /**
     * @notice Checks if the account should be allowed to redeem tokens in the given market
     * @param marketToken The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of marketTokens to exchange for the underlying asset in the market
     * @return 0 if the redeem is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function redeemAllowed(address marketToken, address redeemer, uint redeemTokens) external returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!marketRedeemPaused[marketToken] && paused==false, "redeem is paused");

        redeemAllowedInternal(marketToken, redeemer, redeemTokens);

        if(address(distributioner) != address(0)){
            distributioner.distributeRedeemReward(marketToken,redeemer);
        }

        return NO_ERROR;
    }

    function redeemAllowedInternal(address marketToken, address redeemer, uint redeemTokens) internal view{
        if (!markets[marketToken].isListed) {
            revert MarketNotListed();
        }

        /* If the redeemer is not 'in' the market, then we can bypass the liquidity check */
        if (!markets[marketToken].accountMembership[redeemer]) {
            return;
        }

        /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
        (, uint shortfall) = getHypotheticalAccountLiquidityInternal(redeemer, MarketTokenInterface(marketToken), redeemTokens, 0);
    
        if (shortfall > 0) {
            revert InsufficientLiquidity();
        }
    }

    /**
     * @notice Validates redeem and reverts on rejection. May emit logs.
     * @param marketToken Asset being redeemed
     * @param redeemer The address redeeming the tokens
     * @param redeemAmount The amount of the underlying asset being redeemed
     * @param redeemTokens The number of tokens being redeemed
     */
    function redeemVerify(address marketToken, address redeemer, uint redeemAmount, uint redeemTokens) public virtual{
        emit RedeemVerify(marketToken, redeemer, redeemAmount, redeemTokens);
    }

    /**
     * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
     * @param marketToken The market to verify the borrow against
     * @param borrower The account which would borrow the asset
     * @param borrowAmount The amount of underlying the account would borrow
     * @return 0 if the borrow is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function borrowAllowed(address marketToken, address borrower, uint borrowAmount) external returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!marketBorrowPaused[marketToken] && paused==false, "borrow is paused");

        if (!markets[marketToken].isListed) {
            revert MarketNotListed();
        }

        if (!markets[marketToken].accountMembership[borrower]) {
            // only marketTokens may call borrowAllowed if borrower not in market
            require(msg.sender == marketToken, "sender must be marketToken");

            // attempt to add borrower to the market
            addToMarketInternal(MarketTokenInterface(msg.sender), borrower);

            // it should be impossible to break the important invariant
            assert(markets[marketToken].accountMembership[borrower]);
        }

        if (oracle.getUnderlyingPrice(MarketTokenInterface(marketToken)) == 0) {
            revert PriceError();
        }

        uint borrowCap = borrowCaps[marketToken];
        // Borrow cap of 0 corresponds to unlimited borrowing
        if (borrowCap != 0) {
            uint totalBorrows = MarketTokenInterface(marketToken).totalBorrows();
            uint nextTotalBorrows = add_(totalBorrows, borrowAmount);
            require(nextTotalBorrows < borrowCap, "market borrow cap reached");
        }

        ( , uint shortfall) = getHypotheticalAccountLiquidityInternal(borrower, MarketTokenInterface(marketToken), 0, borrowAmount);
        if (shortfall > 0) {
            revert InsufficientLiquidity();
        }

        if(address(distributioner) != address(0)){
            distributioner.distributeBorrowReward(marketToken, borrower);
        }

        return NO_ERROR;
    }

    /**
     * @notice Validates borrow and reverts on rejection. May emit logs.
     * @param marketToken Asset whose underlying is being borrowed
     * @param borrower The address borrowing the underlying
     * @param borrowAmount The amount of the underlying asset requested to borrow
     */
    function borrowVerify(address marketToken, address borrower, uint borrowAmount) public virtual{
        emit BorrowVerify(marketToken, borrower, borrowAmount);
    }

    /**
     * @notice Checks if the account should be allowed to repay a borrow in the given market
     * @param marketToken The market to verify the repay against
     * @param payer The account which would repay the asset
     * @param borrower The account which would borrowed the asset
     * @param repayAmount The amount of the underlying asset the account would repay
     * @return 0 if the repay is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function repayBorrowAllowed(
        address marketToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint) {

        // Pausing is a very serious situation - we revert to sound the alarms
        require(!marketRepayBorrowPaused[marketToken] && paused==false, "repayborrow is paused");

        // Shh - currently unused
        payer;
        borrower;
        repayAmount;

        if (!markets[marketToken].isListed) {
            revert MarketNotListed();
        }

        if(address(distributioner) != address(0)){
            distributioner.distributeRepayBorrowReward(marketToken, borrower);
        }

        return NO_ERROR;
    }

    /**
     * @notice Validates repayBorrow and reverts on rejection. May emit logs.
     * @param marketToken Asset being repaid
     * @param payer The address repaying the borrow
     * @param borrower The address of the borrower
     * @param actualRepayAmount The amount of underlying being repaid
     */
    function repayBorrowVerify(
        address marketToken,
        address payer,
        address borrower,
        uint actualRepayAmount,
        uint borrowerIndex) public virtual {
        emit RepayBorrowVerify(marketToken,payer,borrower,actualRepayAmount,borrowerIndex);
    }

    /**
     * @notice Checks if the liquidation should be allowed to occur
     * @param marketTokenBorrowed Asset which was borrowed by the borrower
     * @param marketTokenCollateral Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param repayAmount The amount of underlying being repaid
     */
    function liquidateBorrowAllowed (
        address marketTokenBorrowed,
        address marketTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external view returns (uint) {
        
        // check the liquidateAllowAddresses
        if(liquidateAllowAddresses.length > 0) {
            bool _liquidateBorrowAllowed = false;
            for(uint i = 0; i < liquidateAllowAddresses.length; i++){
                if(liquidator == liquidateAllowAddresses[i]){
                    _liquidateBorrowAllowed = true;
                    break;
                }
            }
            require(_liquidateBorrowAllowed,"The liquidator is not permitted to execute.");
        }
        

        if (!markets[marketTokenBorrowed].isListed || !markets[marketTokenCollateral].isListed) {
            revert MarketNotListed();
        }

        // Make sure the borrower's marketTokenCollateral has entered
        bool marketEntered = markets[address(marketTokenCollateral)].accountMembership[borrower];
        if(marketEntered == false){
            revert MarketNotEntered();
        }

        uint borrowBalance = MarketTokenInterface(marketTokenBorrowed).borrowBalanceStored(borrower);

        /* allow accounts to be liquidated if the market is deprecated */
        if (isDeprecated(MarketTokenInterface(marketTokenBorrowed))) {
            require(borrowBalance >= repayAmount, "Can not repay more than the total borrow");
        } else {
            /* The borrower must have shortfall in order to be liquidatable */
            (, uint shortfall) = getAccountLiquidityInternal(borrower);
            if (shortfall == 0) {
                revert InsufficientShortfall();
            }

            /* The liquidator may not repay more than what is allowed by the closeFactor */
            uint maxClose = mul_ScalarTruncate(Exp({mantissa: closeFactorMantissa}), borrowBalance);
            if (repayAmount > maxClose) {
                revert TooMuchRepay();
            }
        }

        return NO_ERROR;
    }

    /**
     * @notice Validates liquidateBorrow and reverts on rejection. May emit logs.
     * @param marketTokenBorrowed Asset which was borrowed by the borrower
     * @param marketTokenCollateral Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param actualRepayAmount The amount of underlying being repaid
     */
    function liquidateBorrowVerify(
        address marketTokenBorrowed,
        address marketTokenCollateral,
        address liquidator,
        address borrower,
        uint actualRepayAmount,
        uint seizeTokens) public virtual{
         
        emit LiquidateBorrowVerify(marketTokenBorrowed,marketTokenCollateral,liquidator,borrower,actualRepayAmount,seizeTokens);
    }

    /**
     * @notice Checks if the seizing of assets should be allowed to occur
     * @param marketTokenCollateral Asset which was used as collateral and will be seized
     * @param marketTokenBorrowed Asset which was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeAllowed(
        address marketTokenCollateral,
        address marketTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!marketSeizePaused[marketTokenCollateral] && !marketSeizePaused[marketTokenBorrowed] && paused==false, "seize is paused");

        // Shh - currently unused
        seizeTokens;

        if (!markets[marketTokenCollateral].isListed || !markets[marketTokenBorrowed].isListed) {
            revert MarketNotListed();
        }

        if (MarketTokenInterface(marketTokenCollateral).comptroller() != MarketTokenInterface(marketTokenBorrowed).comptroller()) {
            revert ComptrollerMismatch();
        }

        if(address(distributioner) != address(0)){
            distributioner.distributeSeizeReward(marketTokenCollateral,borrower,liquidator);
        }

        return NO_ERROR;
    }

    /**
     * @notice Validates seize and reverts on rejection. May emit logs.
     * @param marketTokenCollateral Asset which was used as collateral and will be seized
     * @param marketTokenBorrowed Asset which was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeVerify(
        address marketTokenCollateral,
        address marketTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) public virtual{
        
        emit SeizeVerify(marketTokenCollateral,marketTokenBorrowed,liquidator,borrower,seizeTokens);
    }

    /**
     * @notice Checks if the account should be allowed to transfer tokens in the given market
     * @param marketToken The market to verify the transfer against
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of marketTokens to transfer
     * @return 0 if the transfer is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function transferAllowed(address marketToken, address src, address dst, uint transferTokens) external returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!marketTransferPaused[marketToken] && paused==false, "transfer is paused");

        // Currently the only consideration is whether or not
        //  the src is allowed to redeem this many tokens
        redeemAllowedInternal(marketToken, src, transferTokens);

        // the dst will enter market
        if (!markets[marketToken].accountMembership[dst]) {
            require(msg.sender == marketToken, "sender must be marketToken");
            addToMarketInternal(MarketTokenInterface(msg.sender), dst);
            assert(markets[marketToken].accountMembership[dst]);
        }

        if(address(distributioner) != address(0)){
            distributioner.distributeTransferReward(marketToken,src,dst);
        }

        return NO_ERROR;
    }

    /**
     * @notice Validates transfer and reverts on rejection. May emit logs.
     * @param marketToken Asset being transferred
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of marketTokens to transfer
     */
    function transferVerify(address marketToken, address src, address dst, uint transferTokens) public virtual {
        
        emit TransferVerify(marketToken, src, dst, transferTokens);
    }

    /*** Liquidity/Liquidation Calculations ***/

    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *  Note that `cTokenBalance` is the number of marketTokens the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountLiquidityLocalVars {
        uint sumCollateral;
        uint sumBorrowPlusEffects;
        uint cTokenBalance;
        uint borrowBalance;
        uint exchangeRateMantissa;
        uint oraclePriceMantissa;
        Exp collateralFactor;
        Exp exchangeRate;
        Exp oraclePrice;
        Exp tokensToDenom;
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code (semi-opaque),
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidity(address account) public view returns (uint, uint, uint) {
        (uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, MarketTokenInterface(address(0)), 0, 0);

        return (NO_ERROR, liquidity, shortfall);
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code,
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidityInternal(address account) internal view returns (uint, uint) {
        return getHypotheticalAccountLiquidityInternal(account, MarketTokenInterface(address(0)), 0, 0);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param marketTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return (possible error code (semi-opaque),
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidity(
        address account,
        address marketTokenModify,
        uint redeemTokens,
        uint borrowAmount) public view returns (uint, uint, uint) {
        (uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, MarketTokenInterface(marketTokenModify), redeemTokens, borrowAmount);
        return (NO_ERROR, liquidity, shortfall);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param marketTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @dev Note that we calculate the exchangeRateStored for each collateral marketToken using stored data,
     *  without calculating accumulated interest.
     * @return (possible error code,
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidityInternal(
        address account,
        MarketTokenInterface marketTokenModify,
        uint redeemTokens,
        uint borrowAmount) internal view returns (uint, uint) {

        AccountLiquidityLocalVars memory vars; // Holds all our calculation results
        uint oErr;

        // For each asset the account is in
        MarketTokenInterface[] memory assets = accountAssets[account];
        for (uint i = 0; i < assets.length; i++) {
            MarketTokenInterface asset = assets[i];

            // Read the balances and exchange rate from the marketToken
            (oErr, vars.cTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = asset.getAccountSnapshot(account);
            if (oErr != 0) { // semi-opaque error code, we assume NO_ERROR == 0 is invariant between upgrades
                revert SnapshotError();
            }
            vars.collateralFactor = Exp({mantissa: markets[address(asset)].collateralFactorMantissa});
            vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa});

            // Get the normalized price of the asset
            vars.oraclePriceMantissa = oracle.getUnderlyingPrice(asset);
            if (vars.oraclePriceMantissa == 0) {
                revert PriceError();
            }
            vars.oraclePrice = Exp({mantissa: vars.oraclePriceMantissa});

            // Pre-compute a conversion factor from tokens -> ether (normalized price value)
            vars.tokensToDenom = mul_(mul_(vars.collateralFactor, vars.exchangeRate), vars.oraclePrice);

            // sumCollateral += tokensToDenom * cTokenBalance
            vars.sumCollateral = mul_ScalarTruncateAddUInt(vars.tokensToDenom, vars.cTokenBalance, vars.sumCollateral);

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.oraclePrice, vars.borrowBalance, vars.sumBorrowPlusEffects);

            // Calculate effects of interacting with marketTokenModify
            if (asset == marketTokenModify) {
                // redeem effect
                // sumBorrowPlusEffects += tokensToDenom * redeemTokens
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.tokensToDenom, redeemTokens, vars.sumBorrowPlusEffects);

                // borrow effect
                // sumBorrowPlusEffects += oraclePrice * borrowAmount
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.oraclePrice, borrowAmount, vars.sumBorrowPlusEffects);
            }
        }

        // These are safe, as the underflow condition is checked first
        if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
            return (vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
        } else {
            return (0, vars.sumBorrowPlusEffects - vars.sumCollateral);
        }
    }

    /**
     * @notice Calculate number of tokens of collateral asset to seize given an underlying amount
     * @dev Used in liquidation (called in marketToken.liquidateBorrowFresh)
     * @param marketTokenBorrowed The address of the borrowed marketToken
     * @param marketTokenCollateral The address of the collateral marketToken
     * @param actualRepayAmount The amount of marketTokenBorrowed underlying to convert into marketTokenCollateral tokens
     * @return (errorCode, number of marketTokenCollateral tokens to be seized in a liquidation)
     */
    function liquidateCalculateSeizeTokens(address marketTokenBorrowed, address marketTokenCollateral, uint actualRepayAmount) external view returns (uint, uint) {
        /* Read oracle prices for borrowed and collateral markets */
        uint priceBorrowedMantissa = oracle.getUnderlyingPrice(MarketTokenInterface(marketTokenBorrowed));
        uint priceCollateralMantissa = oracle.getUnderlyingPrice(MarketTokenInterface(marketTokenCollateral));
        if (priceBorrowedMantissa == 0 || priceCollateralMantissa == 0) {
            revert PriceError();
        }

        /*
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         *  seizeTokens = seizeAmount / exchangeRate
         *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
         */
        uint exchangeRateMantissa = MarketTokenInterface(marketTokenCollateral).exchangeRateStored(); // Note: reverts on error
        uint seizeTokens;
        Exp memory numerator;
        Exp memory denominator;
        Exp memory ratio;

        numerator = mul_(Exp({mantissa: liquidationIncentiveMantissa}), Exp({mantissa: priceBorrowedMantissa}));
        denominator = mul_(Exp({mantissa: priceCollateralMantissa}), Exp({mantissa: exchangeRateMantissa}));
        ratio = div_(numerator, denominator);

        seizeTokens = mul_ScalarTruncate(ratio, actualRepayAmount);

        return (NO_ERROR, seizeTokens);
    }

    /*** Admin Functions ***/

    /**
      * @notice Sets a new price oracle for the comptroller
      * @dev Admin function to set a new price oracle
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setPriceOracle(PriceOracle newOracle) public returns (uint) {
        require(hasOwnerRights(), "only owner can set price oracle");

        // Track the old oracle for the comptroller
        PriceOracle oldOracle = oracle;

        // Set comptroller's oracle to newOracle
        oracle = newOracle;

        // Emit NewPriceOracle(oldOracle, newOracle)
        emit NewPriceOracle(oldOracle, newOracle);

        return NO_ERROR;
    }

    /**
      * @notice Sets the closeFactor used when liquidating borrows
      * @dev Admin function to set closeFactor
      * @param newCloseFactorMantissa New close factor, scaled by 1e18
      * @return uint 0=success, otherwise a failure
      */
    function _setCloseFactor(uint newCloseFactorMantissa) external returns (uint) {
    	require(hasOwnerRights(), "only owner can set close factor");

        uint oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = newCloseFactorMantissa;
        emit NewCloseFactor(oldCloseFactorMantissa, closeFactorMantissa);

        return NO_ERROR;
    }

    /**
      * @notice Sets the collateralFactor for a market
      * @dev Admin function to set per-market collateralFactor
      * @param marketToken The market to set the factor on
      * @param newCollateralFactorMantissa The new collateral factor, scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setCollateralFactor(MarketTokenInterface marketToken, uint newCollateralFactorMantissa) public returns (uint) {
        require(hasOwnerRights(), "only owner can set collateral factor");
        
        // Verify market is listed
        Market storage market = markets[address(marketToken)];
        if (!market.isListed) {
            revert SetCollateralFactorNoExists(); 
        }

        Exp memory newCollateralFactorExp = Exp({mantissa: newCollateralFactorMantissa});

        // Check collateral factor <= 0.9
        Exp memory highLimit = Exp({mantissa: collateralFactorMaxMantissa});
        if (lessThanExp(highLimit, newCollateralFactorExp)) {
            revert SetCollateralFactorValidation();
        }

        // If collateral factor != 0, fail if price == 0
        if (newCollateralFactorMantissa != 0 && oracle.getUnderlyingPrice(marketToken) == 0) {
            revert SetCollateralFactorWithoutPrice();
        }

        // Set market's collateral factor to new collateral factor, remember old value
        uint oldCollateralFactorMantissa = market.collateralFactorMantissa;
        market.collateralFactorMantissa = newCollateralFactorMantissa;

        // Emit event with asset, old collateral factor, and new collateral factor
        emit NewCollateralFactor(marketToken, oldCollateralFactorMantissa, newCollateralFactorMantissa);

        return NO_ERROR;
    }

    /**
      * @notice Sets liquidationIncentive
      * @dev Admin function to set liquidationIncentive
      * @param newLiquidationIncentiveMantissa New liquidationIncentive scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setLiquidationIncentive(uint newLiquidationIncentiveMantissa) external returns (uint) {
        require(hasOwnerRights(), "only owner can set liquidation incentive matissa");

        // Save current value for use in log
        uint oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;

        // Set liquidation incentive to new incentive
        liquidationIncentiveMantissa = newLiquidationIncentiveMantissa;

        // Emit event with old incentive, new incentive
        emit NewLiquidationIncentive(oldLiquidationIncentiveMantissa, newLiquidationIncentiveMantissa);

        return NO_ERROR;
    }

    /**
      * @notice Add the market to the markets mapping and set it as listed
      * @dev Admin function to set isListed and add support for the market
      * @param marketToken The address of the market (token) to list
      * @return uint 0=success, otherwise a failure. (See enum Error for details)
      */
    function _supportMarket(MarketTokenInterface marketToken) public returns (uint) {
        require(hasOwnerRights(), "only owner can support market");

        if (markets[address(marketToken)].isListed) {
            revert SupportMarketExists();
        }

        marketToken.isMarketToken(); // Sanity check to make sure its really a MarketTokenInterface

        Market storage market = markets[address(marketToken)];
        market.isListed = true;
        market.collateralFactorMantissa = 0;

        _addMarketInternal(address(marketToken));
        if(address(distributioner) != address(0)){
            distributioner._initializeMarket(address(marketToken));
        }
        
        emit MarketListed(marketToken);

        return NO_ERROR;
    }

    function _addMarketInternal(address marketToken) internal {
        for (uint i = 0; i < allMarkets.length; i ++) {
            require(allMarkets[i] != MarketTokenInterface(marketToken), "market already added");
        }
        allMarkets.push(MarketTokenInterface(marketToken));
    }


    /**
      * @notice Set the given borrow caps for the given marketToken markets. Borrowing that brings total borrows to or above borrow cap will revert.
      * @dev Owner function to set the borrow caps. A borrow cap of 0 corresponds to unlimited borrowing.
      * @param marketTokens The addresses of the markets (tokens) to change the borrow caps for
      * @param newBorrowCaps The new borrow cap values in underlying to be set. A value of 0 corresponds to unlimited borrowing.
      */
    function _setMarketBorrowCaps(MarketTokenInterface[] calldata marketTokens, uint[] calldata newBorrowCaps) external {
    	require(hasOwnerRights(), "only owner can set borrow caps"); 

        uint numMarkets = marketTokens.length;
        uint numBorrowCaps = newBorrowCaps.length;

        require(numMarkets != 0 && numMarkets == numBorrowCaps, "invalid input");

        for(uint i = 0; i < numMarkets; i++) {
            borrowCaps[address(marketTokens[i])] = newBorrowCaps[i];
            emit NewBorrowCap(marketTokens[i], newBorrowCaps[i]);
        }
    }

    /**
      * @notice Set the given supply caps for the given marketToken markets. Minting that brings total borrows to or above supply cap will revert.
      * @dev Owner function to set the supply caps. A supply cap of 0 corresponds to unlimited minting.
      * @param marketTokens The addresses of the markets (tokens) to change the supply caps for
      * @param newSupplyCaps The new supply cap values in underlying to be set. A value of 0 corresponds to unlimited minting.
      */
    function _setMarketSupplyCaps(MarketTokenInterface[] calldata marketTokens, uint[] calldata newSupplyCaps) external {
        require(hasOwnerRights(), "only owner can set borrow caps"); 

        uint numMarkets = marketTokens.length;
        uint numSupplyCaps = newSupplyCaps.length;

        require(numMarkets != 0 && numMarkets == numSupplyCaps, "invalid input");
        for(uint i = 0; i < numMarkets; i++) {
            supplyCaps[address(marketTokens[i])] = newSupplyCaps[i];
            emit NewSupplyCap(marketTokens[i], newSupplyCaps[i]);
        }
    }

    /**
     * @notice Admin function to change the Pause Guardian
     * @param newPauseGuardian The address of the new Pause Guardian
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setPauseGuardian(address newPauseGuardian) public returns (uint) {
        require(hasOwnerRights(), "only owner can set pause guardian"); 

        // Save current value for inclusion in log
        address oldPauseGuardian = pauseGuardian;

        // Store pauseGuardian with value newPauseGuardian
        pauseGuardian = newPauseGuardian;

        emit NewPauseGuardian(oldPauseGuardian, pauseGuardian);

        return NO_ERROR;
    }

    function _setDistributioner(address newDistributioner) public returns (uint) {
        require(hasOwnerRights(),"only owner can set distributioner");

        // Save current value for inclusion in log
        address oldDistributioner = address(distributioner);

        distributioner = DistributionerInterface(newDistributioner);

        emit NewDistributioner(oldDistributioner, address(distributioner));

        return NO_ERROR;
    }


    function _setMarketMintPaused(MarketTokenInterface marketToken, bool state) public returns (bool) {
       require(msg.sender == pauseGuardian || hasOwnerRights(), "only pause guardian and owner can pause");

        marketMintPaused[address(marketToken)] = state;
        emit ActionPaused(marketToken, "Mint", state);
        return state;
    }

    function _setMarketRedeemPaused(MarketTokenInterface marketToken, bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || hasOwnerRights(), "only pause guardian and owner can pause");

        marketRedeemPaused[address(marketToken)] = state;
        emit ActionPaused(marketToken, "Redeem", state);
        return state;
    }

    function _setMarketBorrowPaused(MarketTokenInterface marketToken, bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || hasOwnerRights(), "only pause guardian and owner can pause");

        marketBorrowPaused[address(marketToken)] = state;
        emit ActionPaused(marketToken, "Borrow", state);
        return state;
    }

    function _setMarketRepayBorrowPaused(MarketTokenInterface marketToken, bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || hasOwnerRights(), "only pause guardian and owner can pause");

        marketRepayBorrowPaused[address(marketToken)] = state;
        emit ActionPaused(marketToken, "RepayBorrow", state);
        return state;
    }
    
    function _setMarketTransferPaused(MarketTokenInterface marketToken, bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || hasOwnerRights(), "only pause guardian and owner can pause");

        marketTransferPaused[address(marketToken)] = state;
        emit ActionPaused(marketToken, "Transfer", state);
        return state;
    }

    function _setMarketSeizePaused(MarketTokenInterface marketToken, bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || hasOwnerRights(), "only pause guardian and owner can pause");

        marketSeizePaused[address(marketToken)]  = state;
        emit ActionPaused(marketToken, "Seize", state);
        return state;
    }

    function _setPaused(bool state) public {
        require(hasOwnerRights(), "only owner can pause");
        paused = state;
        emit Paused(state);
    }

    /**
     * @notice Return all of the markets
     * @dev The automatic getter may be used to access an individual market.
     * @return The list of market addresses
     */
    function getAllMarkets() public view returns (MarketTokenInterface[] memory) {
        return allMarkets;
    }

    function isMarketListed(address marketToken) public view returns (bool){
        return markets[marketToken].isListed;
    }

    function isDeprecated(MarketTokenInterface marketToken) public view returns (bool) {
        return
            markets[address(marketToken)].collateralFactorMantissa == 0 && 
            marketBorrowPaused[address(marketToken)] == true && 
            marketToken.reserveFactorMantissa() == 1e18
        ;
    }

    function _setLiquidateAllowAddresses(address[] memory _liquidateAllowAddresses) public  {
        require(hasOwnerRights(),"only owner can set liquidateAllowAddresses");
        liquidateAllowAddresses = _liquidateAllowAddresses;
    }

}