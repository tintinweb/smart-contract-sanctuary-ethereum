/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

/** 
 *  SourceUnit: /Users/macos/dev/cLend/contracts/CLending.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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




/** 
 *  SourceUnit: /Users/macos/dev/cLend/contracts/CLending.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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




/** 
 *  SourceUnit: /Users/macos/dev/cLend/contracts/CLending.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

////import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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




/** 
 *  SourceUnit: /Users/macos/dev/cLend/contracts/CLending.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
////import "../proxy/utils/Initializable.sol";

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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}




/** 
 *  SourceUnit: /Users/macos/dev/cLend/contracts/CLending.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED

pragma solidity =0.8.6;

// solcurity: E1, index what could be useful for offchain reading. Do not index dynamic types like strings or bytes.
// solcurity: E5
contract cLendingEventEmitter {
    event LoanTermsChanged(
        uint256 previousYearlyInterst,
        uint256 newYearlyInterst,
        uint256 previousLoanDefaultThresholdPercent,
        uint256 newLoanDefaultThresholdPercent,
        uint256 timestamp,
        address changedBy
    );

    event NewTokenAdded(
        address token,
        uint256 collaterability,
        address liquidationBeneficiary,
        uint256 timestamp,
        address addedBy
    );

    event TokenLiquidationBeneficiaryChanged(
        address token,
        address oldBeneficiary,
        address newBeneficiary,
        uint256 timestamp,
        address changedBy
    );

    event TokenCollaterabilityChanged(
        address token,
        uint256 oldCollaterability,
        uint256 newCollaterability,
        uint256 timestamp,
        address changedBy
    );

    event CollateralAdded(address token, uint256 amount, uint256 timestamp, address addedBy);

    event LoanTaken(uint256 amount, uint256 timestamp, address takenBy);

    event Repayment(address token, uint256 amountTokens, uint256 timestamp, address addedBy);

    event InterestPaid(address paidInToken, uint256 interestAmountInDAI, uint256 timestamp, address paidBy);

    event Liquidation(
        address userWhoWasLiquidated,
        uint256 totalCollateralValueLiquidated,
        uint256 timestamp,
        address caller
    );

    event CollateralReclaimed(address token, uint256 amount, uint256 timestamp, address byWho);
}




/** 
 *  SourceUnit: /Users/macos/dev/cLend/contracts/CLending.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED

pragma solidity =0.8.6;

struct DebtorSummary {
    uint256 timeLastBorrow; // simple timestamp
    uint256 amountDAIBorrowed; // denominated in DAI units (1e18)
    uint256 pendingInterests; // interests accumulated from previous loans
    // Meaning 1 DAI = 1e18 here since DAI is 1e18
    Collateral[] collateral;
}

struct Collateral {
    address collateralAddress;
    uint256 amountCollateral;
}




/** 
 *  SourceUnit: /Users/macos/dev/cLend/contracts/CLending.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity =0.8.6;

////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Library housing all the different function helpers that take space in the main contract
 * @author CVault Finance
 */
library CLendingLibrary {
    function safeTransferFrom(
        IERC20 token,
        address person,
        uint256 sendAmount
    ) internal returns (uint256 transferedAmount) {
        uint256 balanceBefore = token.balanceOf(address(this));
        token.transferFrom(person, address(this), sendAmount);
        uint256 balanceAfter = token.balanceOf(address(this));

        transferedAmount = balanceAfter - balanceBefore;
        require(transferedAmount == sendAmount, "UNSUPPORTED_TOKEN");
    }
}




/** 
 *  SourceUnit: /Users/macos/dev/cLend/contracts/CLending.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

////import "../utils/ContextUpgradeable.sol";
////import "../proxy/utils/Initializable.sol";

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
        __Context_init_unchained();
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
    uint256[49] private __gap;
}


/** 
 *  SourceUnit: /Users/macos/dev/cLend/contracts/CLending.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED

pragma solidity =0.8.6;

////import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
////import "./CLendingLibrary.sol";
////import "./types/CLendingTypes.sol";
////import "./CLendingEventEmitter.sol";

/**
 * @title Lending contract for CORE and CoreDAO
 * @author CVault Finance
 */
contract CLending is OwnableUpgradeable, cLendingEventEmitter {
    using CLendingLibrary for IERC20;

    IERC20 public constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 public constant CORE_TOKEN = IERC20(0x62359Ed7505Efc61FF1D56fEF82158CcaffA23D7);
    address private constant DEADBEEF = 0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF;

    mapping(address => DebtorSummary) public debtorSummary;
    mapping(address => uint256) public collaterabilityOfToken;
    mapping(address => address) public liquidationBeneficiaryOfToken;
    mapping(address => bool) public isAngel;


    address public coreDAOTreasury;
    uint256 public yearlyPercentInterest;
    uint256 public loanDefaultThresholdPercent;
    IERC20 public coreDAO; // initialized hence not immutable but should be

    bool private entered;
    bool private holyIntervention;

    /// @dev upfront storage allocation for further upgrades
    uint256[52] private _____gap;

    modifier nonEntered {
        require(!entered, "NO_REENTRY");
        entered = true;
        _;
        entered = false;
    }

    modifier notHaram {
        require(!holyIntervention,"GOD_SAYS_NO");
        _;
    }

    function editAngels(address _angel, bool _isAngel) external onlyOwner {
        isAngel[_angel] = _isAngel;
    }

    function intervenienteHomine() external {
        require(isAngel[msg.sender] || msg.sender == owner(),"HERETICAL");
        holyIntervention = true;
    }

    function godIsDead() external onlyOwner {
        holyIntervention = false;
    }

    function initialize(
        address _coreDAOTreasury,
        IERC20 _daoToken,
        uint256 _yearlyPercentInterest,
        uint256 _loanDefaultThresholdPercent,
        uint256 _coreTokenCollaterability
    ) external initializer {
        require(msg.sender == 0x5A16552f59ea34E44ec81E58b3817833E9fD5436, "BUM");
        __Ownable_init();

        coreDAOTreasury = _coreDAOTreasury;

        changeLoanTerms(_yearlyPercentInterest, _loanDefaultThresholdPercent);

        require(loanDefaultThresholdPercent > 100, "WOULD_LIQUIDATE");

        addNewToken(address(_daoToken), DEADBEEF, 1, 18);
        addNewToken(address(CORE_TOKEN), DEADBEEF, _coreTokenCollaterability, 18);
        addNewToken(address(DAI), _coreDAOTreasury, 1, 18); // DAI should never be liquidated but this is just in case

        coreDAO = _daoToken;
    }

    receive() external payable {
        revert("ETH_NOT_ACCEPTED");
    }

    // It should be noted that this will change everything backwards in time meaning some people might be liquidated right away
    function changeLoanTerms(uint256 _yearlyPercentInterest, uint256 _loanDefaultThresholdPercent) public onlyOwner {
        require(_loanDefaultThresholdPercent > 100, "WOULD_LIQUIDATE");

        emit LoanTermsChanged(
            yearlyPercentInterest,
            _yearlyPercentInterest,
            loanDefaultThresholdPercent,
            _loanDefaultThresholdPercent,
            block.timestamp,
            msg.sender
        );

        yearlyPercentInterest = _yearlyPercentInterest;
        loanDefaultThresholdPercent = _loanDefaultThresholdPercent;
    }

    function editTokenCollaterability(address token, uint256 newCollaterability) external onlyOwner {
        emit TokenCollaterabilityChanged(
            token,
            collaterabilityOfToken[token],
            newCollaterability,
            block.timestamp,
            msg.sender
        );
        require(liquidationBeneficiaryOfToken[token] != address(0), "NOT_ADDED");
        collaterabilityOfToken[token] = newCollaterability;
    }

    // warning this does not support different amount than 18 decimals
    function addNewToken(
        address token,
        address liquidationBeneficiary,
        uint256 collaterabilityInDAI,
        uint256 decimals
    ) public onlyOwner {
        /// 1e18 CORE = 5,500 e18 DAI
        /// 1units CORE = 5,500units DAI
        // $1DAI = 1e18 units

        /// wBTC = 1e8
        /// collaterability of wbtc  40,000e10
        /// totalCollaterability = how much UNITS of DAI one UNIT of this token is worth
        // Collapse = worth less than 1 dai per unit ( 1e18 token is worth less than $1 or token has higher decimals than than 1e18)
        require(decimals == 18, "UNSUPPORTED_DECIMALS");
        require(
            collaterabilityOfToken[token] == 0 && liquidationBeneficiaryOfToken[token] == address(0),
            "ALREADY_ADDED"
        );
        if (liquidationBeneficiary == address(0)) {
            liquidationBeneficiary = DEADBEEF;
        } // covers not send to 0 tokens
        require(collaterabilityInDAI > 0, "INVALID_COLLATERABILITY");
        emit NewTokenAdded(token, collaterabilityInDAI, liquidationBeneficiary, block.timestamp, msg.sender);
        liquidationBeneficiaryOfToken[token] = liquidationBeneficiary;
        collaterabilityOfToken[token] = collaterabilityInDAI;
    }

    function editTokenLiquidationBeneficiary(address token, address newBeneficiary) external onlyOwner {
        // Since beneficiary defaults to deadbeef it cannot be 0 if its been added before
        require(liquidationBeneficiaryOfToken[token] != address(0), "NOT_ADDED");
        require(token != address(CORE_TOKEN) && token != address(coreDAO), "CANNOT_MODIFY"); // Those should stay burned or floor doesnt hold
        if (newBeneficiary == address(0)) {
            newBeneficiary = DEADBEEF;
        } // covers not send to 0 tokens
        emit TokenLiquidationBeneficiaryChanged(
            token,
            liquidationBeneficiaryOfToken[token],
            newBeneficiary,
            block.timestamp,
            msg.sender
        );
        liquidationBeneficiaryOfToken[token] = newBeneficiary;
    }

    // Repays the loan supplying collateral and not adding it
    // solcurity: C48
    function repayLoan(IERC20 token, uint256 amount) external notHaram nonEntered {

        (uint256 totalDebt, ) = _liquidateDeliquent(msg.sender);
        DebtorSummary storage userSummaryStorage = debtorSummary[msg.sender];
        uint256 tokenCollateralAbility = collaterabilityOfToken[address(token)];
        uint256 offeredCollateralValue = amount * tokenCollateralAbility;
        uint256 _accruedInterest = accruedInterest(msg.sender);

        require(offeredCollateralValue > 0, "NOT_ENOUGH_COLLATERAL_OFFERED"); // covers both cases its a not supported token and 0 case
        require(totalDebt > 0, "NOT_DEBT");
        require(offeredCollateralValue >= _accruedInterest, "INSUFFICIENT_AMOUNT"); // Has to be done because we have to update debt time
        require(amount > 0, "REPAYMENT_NOT_SUCESSFUL");

        // Note that acured interest is never bigger than 10% of supplied collateral because of liquidateDelinquent call above
        if (offeredCollateralValue > totalDebt) {

            amount = quantityOfTokenForValueInDAI(totalDebt, tokenCollateralAbility);

            require(amount > 0, "REPAYMENT_NOT_SUCESSFUL");
            userSummaryStorage.amountDAIBorrowed = 0;

            // Updating debt time is not nessesary since accrued interest on 0 will always be 0
        } else {
            userSummaryStorage.amountDAIBorrowed -= (offeredCollateralValue - _accruedInterest);



            // Send the repayment amt
        }
        
        // Nessesary to do it after the change of amount
        token.safeTransferFrom(msg.sender, amount); // amount is changed if user supplies more than is neesesry to wipe their debt and interest

        emit Repayment(address(token), amount, block.timestamp, msg.sender);

        // Interst handling
        // Interest is always repaid here because of the offeredCollateralValue >= _accruedInterest check
        uint256 amountTokensForInterestRepayment = quantityOfTokenForValueInDAI(
            _accruedInterest,
            tokenCollateralAbility
        );

        if (amountTokensForInterestRepayment > 0) {

            _safeTransfer(address(token), coreDAOTreasury, amountTokensForInterestRepayment);

        }
        _wipeInterestOwed(userSummaryStorage);
        emit InterestPaid(address(token), _accruedInterest, block.timestamp, msg.sender);
    }

    function quantityOfTokenForValueInDAI(uint256 quantityOfDAI, uint256 tokenCollateralAbility)
        public
        pure
        returns (uint256)
    {
        require(tokenCollateralAbility > 0, "TOKEN_UNSUPPORTED");
        return quantityOfDAI / tokenCollateralAbility;
    }

    // solcurity: C48
    function _supplyCollateral(
        DebtorSummary storage userSummaryStorage,
        address user,
        IERC20 token,
        uint256 amount
    ) private nonEntered {
        // Clear previous borrows & collateral for this user if they are delinquent
        _liquidateDeliquent(user);

        uint256 tokenCollateralAbility = collaterabilityOfToken[address(token)]; // essentially a whitelist

        require(token != DAI, "DAI_IS_ONLY_FOR_REPAYMENT");
        require(tokenCollateralAbility != 0, "NOT_ACCEPTED");
        require(amount > 0, "!AMOUNT");
        require(user != address(0), "NO_ADDRESS");

        // Transfer the token from owner, ////important this is first because of interest repayment which can send
        token.safeTransferFrom(user, amount);

        // We add collateral into the user struct
        _upsertCollateralInUserSummary(userSummaryStorage, token, amount);
        emit CollateralAdded(address(token), amount, block.timestamp, msg.sender);
    }

    function addCollateral(IERC20 token, uint256 amount) external {
        DebtorSummary storage userSummaryStorage = debtorSummary[msg.sender];
        _supplyCollateral(userSummaryStorage, msg.sender, token, amount);
    }

    function addCollateralAndBorrow(
        IERC20 tokenCollateral,
        uint256 amountCollateral,
        uint256 amountBorrow
    ) external notHaram {

        DebtorSummary storage userSummaryStorage = debtorSummary[msg.sender];
        _supplyCollateral(userSummaryStorage, msg.sender, tokenCollateral, amountCollateral);
        _borrow(userSummaryStorage, msg.sender, amountBorrow);
    }

    function borrow(uint256 amount) external notHaram {

        DebtorSummary storage userSummaryStorage = debtorSummary[msg.sender];
        _borrow(userSummaryStorage, msg.sender, amount);
    }

    // Repays all users accumulated interest with margin
    // Then checks if borrow can be preformed, adds it to total borrowed as well as transfers the dai to user
    // solcurity: C48
    function _borrow(
        DebtorSummary storage userSummaryStorage,
        address user,
        uint256 amountBorrow
    ) private nonEntered {
        // We take users accrued interest and the amount borrowed
        // We repay the accured interest from the loan amount, by adding it on top of the loan amount
        uint256 totalCollateral = userCollateralValue(user); // Value of collateral in DAI
        uint256 userAccruedInterest = accruedInterest(user); // Interest in DAI
        uint256 totalAmountBorrowed = userSummaryStorage.amountDAIBorrowed;
        uint256 totalDebt = userAccruedInterest + totalAmountBorrowed;

        require(totalDebt < totalCollateral, "OVER_DEBTED");
        require(amountBorrow > 0, "NO_BORROW"); // This is intentional after adding accured interest
        require(user != address(0), "NO_ADDRESS");

        uint256 userRemainingCollateral = totalCollateral - totalDebt; // User's collateral before making this loan

        // If the amount borrow is higher than remaining collateral, cap it
        if (amountBorrow > userRemainingCollateral) {
            amountBorrow = userRemainingCollateral;
        }
        userSummaryStorage.amountDAIBorrowed += amountBorrow;
        _wipeInterestOwed(userSummaryStorage); // because we added it to their borrowed amount

        // carry forward the previous interest
        userSummaryStorage.pendingInterests = userAccruedInterest;

        DAI.transfer(user, amountBorrow); // DAI transfer function doesnt need safe transfer

        emit LoanTaken(amountBorrow, block.timestamp, user);
    }

    function _upsertCollateralInUserSummary(
        DebtorSummary storage userSummaryStorage,
        IERC20 token,
        uint256 amount
    ) private returns (uint256 collateralIndex) {
        // Insert or update operation
        require(amount != 0, "INVALID_AMOUNT");
        bool collateralAdded;

        // Loops over all provided collateral, checks if its there and if it is edit it
        uint256 length = userSummaryStorage.collateral.length;

        for (uint256 i = 0; i < length; i++) {
            Collateral storage collateral = userSummaryStorage.collateral[i];

            if (collateral.collateralAddress == address(token)) {
                
                collateral.amountCollateral += amount;
                collateralIndex = i;
                collateralAdded = true;
            }
        }

        // If it has not been already supplied we push it on
        if (!collateralAdded) {

            collateralIndex = userSummaryStorage.collateral.length;
            
            userSummaryStorage.collateral.push(
                Collateral({collateralAddress: address(token), amountCollateral: amount})
            );
        }
    }

    function _isLiquidable(uint256 totalDebt, uint256 totalCollateral) private view returns (bool) {
        return totalDebt > (totalCollateral * loanDefaultThresholdPercent) / 100;
    }

    // Liquidates people in default
    // solcurity: C48
    function liquidateDelinquent(address user) external notHaram nonEntered returns (uint256 totalDebt, uint256 totalCollateral)  {
        return _liquidateDeliquent(user);
    }

    function _liquidateDeliquent(address user) private returns (uint256 totalDebt, uint256 totalCollateral) {
        totalDebt = userTotalDebt(user); // This is with interest
        totalCollateral = userCollateralValue(user);

        if (_isLiquidable(totalDebt, totalCollateral)) {

            // user is in default, wipe their debt and collateral
            _liquidate(user); // only callsite
            emit Liquidation(user, totalCollateral, block.timestamp, msg.sender);
            return (0, 0);
        }
    }

    // Only called in liquidatedliquent
    // function of great consequence
    // Loops over all user supplied collateral of user, and sends it
    // to burn/beneficiary + pays 0.5% to caller if caller is not the user being liquidated.
    function _liquidate(address user) private  {
        // solcurity: C2 - debtorSummary[user]
        uint256 length = debtorSummary[user].collateral.length;

        for (uint256 i = 0; i < length; i++) {
            uint256 amount = debtorSummary[user].collateral[i].amountCollateral;
            address currentCollateralAddress = debtorSummary[user].collateral[i].collateralAddress;
            
            if (
                msg.sender == user || // User liquidates himself no incentive.
                currentCollateralAddress == address(coreDAO) || // no incentive for coreDAO to maintain floor, burned anyway
                currentCollateralAddress == address(CORE_TOKEN)
            ) {

                // no incentive for core to maintain floor, and its burned anyway
                _safeTransfer(
                    currentCollateralAddress, //token
                    liquidationBeneficiaryOfToken[currentCollateralAddress], // to
                    amount //amount
                );
            } else {

                // Someone else liquidates user 0.5% incentive (1/200)
                _safeTransfer(
                    currentCollateralAddress, //token
                    liquidationBeneficiaryOfToken[currentCollateralAddress], // to
                    (amount * 199) / 200 //amount 99.5%
                );

                _safeTransfer(
                    currentCollateralAddress, //token
                    msg.sender, // to
                    amount / 200 //amount 0.5%
                );
            }
        }

        // remove all collateral and debt
        delete debtorSummary[user];
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(bytes4(keccak256(bytes("transfer(address,uint256)"))), to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function reclaimAllCollateral() external notHaram nonEntered {
        (uint256 totalDebt,) = _liquidateDeliquent(msg.sender);

        // Can only reclaim if there is collateral and 0 debt.
        // If user was liquidated by above call, then this will revert
        require(totalDebt == 0, "STILL_IN_DEBT");

        // solcurity: C2 - debtorSummary[msg.sender]
        uint256 length = debtorSummary[msg.sender].collateral.length;
        require(length > 0, "NOTHING_TO_CLAIM");
        for (uint256 i = 0; i < length; i++) {
            address collateralAddress = debtorSummary[msg.sender].collateral[i].collateralAddress;
            uint256 amount = debtorSummary[msg.sender].collateral[i].amountCollateral;

            require(amount > 0, "SAFETY_CHECK_FAIL");

            _safeTransfer(
                collateralAddress, //token
                msg.sender, // to
                amount //amount
            );
                        
            emit CollateralReclaimed(collateralAddress, amount, block.timestamp, msg.sender);
        }

        // User doesnt have collateral anymore and paid off debt, bye
        delete debtorSummary[msg.sender];
    }

    function userCollaterals(address user) public view returns (Collateral[] memory) {
        return debtorSummary[user].collateral;
    }

    function userTotalDebt(address user) public view returns (uint256) {
        return accruedInterest(user) + debtorSummary[user].amountDAIBorrowed;
    }

    function accruedInterest(address user) public view returns (uint256) {
        DebtorSummary memory userSummaryMemory = debtorSummary[user];
        uint256 timeSinceLastLoan = block.timestamp - userSummaryMemory.timeLastBorrow;

        // Formula :
        // Accrued interest =
        // (DAI borrowed * percent interest per year * time since last loan ) / 365 days * 100
        // + interest already pending ( from previous updates )
        return
            ((userSummaryMemory.amountDAIBorrowed * yearlyPercentInterest * timeSinceLastLoan) / 365_00 days) + // 365days * 100 in seconds
            userSummaryMemory.pendingInterests;
    }

    function _wipeInterestOwed(DebtorSummary storage userSummaryStorage) private {
        userSummaryStorage.timeLastBorrow = block.timestamp;

        // solcurity: C38
        userSummaryStorage.pendingInterests = 0; // clear user pending interests
    }

    function userCollateralValue(address user) public view returns (uint256 collateral) {
        Collateral[] memory userCollateralTokens = debtorSummary[user].collateral;
        for (uint256 i = 0; i < userCollateralTokens.length; i++) {
            Collateral memory currentToken = userCollateralTokens[i];

            uint256 tokenDebit = collaterabilityOfToken[currentToken.collateralAddress] * currentToken.amountCollateral;
            collateral += tokenDebit;
        }
    }
}