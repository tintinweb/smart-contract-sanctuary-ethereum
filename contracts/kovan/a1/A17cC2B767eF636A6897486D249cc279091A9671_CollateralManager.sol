/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "../interfaces/newInterfaces/managers/ICollateralManager.sol";
import "../manager/Manager.sol";


/**
 * @title CollateralManager
 * @author Carson Case
 * @notice A contract to manage the collateral of the Roci protocol
 */

contract CollateralManager is ICollateralManager, Manager {

    constructor(IAddressBook _addressBook) AddressHandler(_addressBook, "NewDeploy") {}

    /**
    * @dev function to return the ERC20 contract AND amount for a collateral deposit
    * @param _paymentContract address
    * @param _user borrower
    * @return ERC20 contract address of collateral
    * @return Collateral amount deposited
     */
    function getCollateralLookup(address _paymentContract, address _user)
        external
        view
        override
        returns (address, uint256)
    {
        return (
            collateralLookup[_paymentContract][_user].ERC20Contract,
            collateralLookup[_paymentContract][_user].amount
        );
    }

}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./IManager.sol";


/**
 * @title ICollateralManager
 * @author Carson Case
 * @notice A contract to manage the collateral of the Roci protocol
 * @dev the overrides of deposit/withdrawal will probably need to use data to store the loan ID
 */
interface ICollateralManager is IManager {


    /**
    * @dev function to return the ERC20 contract AND amount for a collateral deposit
    * @param _paymentContract address
    * @param _user of borrower
    * @return ERC20 contract address of collateral
    * @return Collateral amount deposited
     */
    function getCollateralLookup(address _paymentContract,  address _user)
        external
        view
        returns (address, uint256);

}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../interfaces/newInterfaces/managers/IManager.sol";
import "../utilities/AddressHandler.sol";
import "../libraries/Structs.sol";
import {Errors} from "../libraries/Errors.sol";

/**
 * @title Manager
 * @author George Burlakov
 * @notice A contract to manage the collateral of the Roci protocol
 */
abstract contract Manager is IManager, AddressHandler, Pausable {
    using SafeERC20 for IERC20Metadata;

    // mapping is payment contract (investor) => loan ID => collateral
    mapping(address => mapping(address => Structs.collateral)) internal collateralLookup;
    // mapping of accepted ERC20 collateral
    mapping(address => bool) public acceptedCollateral;
    // Events
    event AcceptedCollateralAdded(uint256 timestamp, address[] indexed ERC20Tokens);
    event AcceptedCollateralRemoved(uint256 timestamp, address[] indexed ERC20CTokens);

    /**
     * @dev function to add more accepted collateral
     * @param _toAdd is the collateral to add
     */
    function addAcceptedDeposits(address[] memory _toAdd) 
    external override
    onlyRole(Role.admin) {
        for (uint256 i = 0; i < _toAdd.length; i++) {
            acceptedCollateral[_toAdd[i]] = true;
        }
        emit AcceptedCollateralAdded(block.timestamp, _toAdd);
    }

    /**
     * @dev function to remove accepted collateral
     * @param _toRemove is the collateral to remove
     */
    function removeAcceptedDeposits(address[] memory _toRemove)
        external override
        onlyRole(Role.admin)
    {
        for (uint256 i = 0; i < _toRemove.length; i++) {
            acceptedCollateral[_toRemove[i]] = false;
        }

        emit AcceptedCollateralRemoved(block.timestamp, _toRemove);
    }


    function deposit(
        address _from,
        address _erc20,
        uint256 _amount
    ) external override whenNotPaused {
        require(
            acceptedCollateral[_erc20],
            Errors.MANAGER_COLLATERAL_NOT_ACCEPTED
        );
        IERC20Metadata(_erc20).safeTransferFrom(_from, address(this), _amount);

        if (collateralLookup[msg.sender][_from].amount == 0) {
            collateralLookup[msg.sender][_from] = Structs.collateral(
                block.timestamp,
                _erc20,
                _amount
            );
        } else {
            require(
                _erc20 == collateralLookup[msg.sender][_from].ERC20Contract,
                Errors.MANAGER_COLLATERAL_INCREASE
            );
            collateralLookup[msg.sender][_from].amount += _amount;
        }
    }

    /**
    * @dev function to withdra collateral
    * @notice it looks up the collateral based off the payment contract being MSG.sender. Meaning
    *   the payment contract must be the one to call this function
    * @param _user i.e., the borrower
    * @param _amount to withdraw
    * @param _receiver who receives the withdrawn collateral (also the borrower)
     */
    function withdrawal(address _user, uint256 _amount, address _receiver) external override whenNotPaused{
        // Require that the amount of collateral requested to be withdrawn is greater than 0
        require(_amount > 0, Errors.MANAGER_ZERO_WITHDRAW);
        // msg.sender is the collateral payment contract
        // Fetch collateral object for this borrower and collateral payment contract
        // The returned data looks like:
        /*
            struct collateral {
                uint256 creationTimestamp;
                address ERC20Contract;
                uint256 amount;
            }
        */
        Structs.collateral storage c = collateralLookup[msg.sender][_user];
        // Require that the amount being withdrawn is not greater than what is held by this collateral payment contract for this borrower
        require(c.amount >= _amount, Errors.MANAGER_EXCEEDING_WITHDRAW);
        // Reduce the amount by the amount being withdrawn
        c.amount -= _amount;
        // Transfer the amount to the borrower
        IERC20Metadata(c.ERC20Contract).safeTransfer(_receiver, _amount);
    }

    function pause() public onlyRole(Role.admin) {
        _pause();
    }

    function unpause() public onlyRole(Role.admin) {
        _unpause();
    }
      
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAddressBook} from "../../IAddressBook.sol";

/**
* @title IManager
* @author Carson Case ([email protected])
* @dev base contract for other managers. Contracts that hold funds for others, keep track of the owners,
*   and also have accepted deposited fund types that can be updated.
 */
interface IManager{
    // function deposit(uint _amount, bytes memory _data) external;
    function deposit(address _from, address _erc20,  uint256 _amount) external;
    // function withdrawal(uint _amount, address _receiver, bytes memory _data) external;
    function withdrawal(address user, uint256 _amount, address _receiver) external;
    function addAcceptedDeposits(address[] memory) external;
    function removeAcceptedDeposits(address[] memory) external;
}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IAddressBook{
    function addressList(string memory _category) external view returns(address[] memory);
    function dailyLimit() external  view returns (uint128);
    function globalLimit() external view returns (uint128);
    function setDailyLimit(uint128 newLimit) external;
    function setGlobalLimit(uint128 newLimit) external;
    function getMaturityDate() external view returns (uint256);
    function setLoanDuration(uint256 _newLoanDuration) external;

    function userDailyLimit() external  view returns (uint128);
    function userGlobalLimit() external view returns (uint128);
    function setUserDailyLimit(uint128 newLimit) external;
    function setUserGlobalLimit(uint128 newLimit) external;


    function globalNFCSLimit(uint _nfcsId) external view  returns (uint128);
    function setGlobalNFCSLimit(uint _nfcsId, uint128 newLimit) external;



    function latePenalty() external  view returns (uint);
    function scoreValidityPeriod() external view returns (uint);
    function setLatePenalty(uint newPenalty) external;
    function setScoreValidityPeriod(uint newValidityPeriod) external;

    function minScore() external  view returns (uint16);
    function maxScore() external view returns (uint16);
    function setMinScore(uint16 newScore) external;
    function setMaxScore(uint16 newScore) external;

    function notGenerated() external  view returns (uint16);
    function generationError() external view returns (uint16);
    function setNotGenerated(uint16 newValue) external;
    function setGenerationError(uint16 newValue) external;

    function penaltyAPYMultiplier() external  view returns (uint8);
    function gracePeriod() external view returns (uint128);
    function setPenaltyAPYMultiplier(uint8 newMultiplier) external;
    function setGracePeriod(uint128 newPeriod) external;
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import {IAddressBook} from "../interfaces/IAddressBook.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AddressHandler{
    string internal _category;
    enum Role{
        token,
        bonds,
        paymentContract,
        revManager,
        NFCS,
        collateralManager,
        priceFeed,
        oracle,
        admin
    }

    IAddressBook public addressBook;

    constructor(IAddressBook _addressBook, string memory _startingCategory){
        addressBook = _addressBook;
        _category = _startingCategory;
    }

    modifier onlyRole(Role _role){
        require(msg.sender == lookup(_role),
                string(
                    abi.encodePacked(
                        "AddressHandler: account ",
                        Strings.toHexString(uint160(msg.sender), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(_role), 32)
                    )
                )
            );
        _;
    }

    function changeCateogory(string memory _newCategory) external onlyRole(Role.admin){
        _category = _newCategory;
    }

    function lookup(Role _role) internal view returns(address contractAddress){
        contractAddress = addressBook.addressList(_category)[uint(_role)];
        require(contractAddress != address(0), 
            string(
                abi.encodePacked("AddressHandler: lookup failed for role: ", 
                Strings.toHexString(uint256(_role), 32)
                )
            )
        );
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Structs {
    struct Score {
        uint256 tokenId;
        uint256 timestamp;
        uint16 creditScore;
    }

    /**
        * @param _amount to borrow
        * @param _duration of loan in seconds
        * @param _NFCSID is the user's NFCS NFT ID from Roci's Credit scoring system
        * @param _collateralAmount is the amount of collateral to send in
        * @param _collateral is the ERC20 address of the collateral
        * @param _hash is the hash of this address and the loan ID. See Bonds.sol for more info on this @newLoan()
        * @param _signature is the signature of the data hashed for hash
    */
    struct BorrowArgs{
        uint256 _amount;
        uint256 _NFCSID;
        uint256 _collateralAmount;
        address _collateral;
        bytes32 _hash;
        bytes _signature;
    }

    /// @notice collateral info is stored in a struct/mapping pair
    struct collateral {
        uint256 creationTimestamp;
        address ERC20Contract;
        uint256 amount;
    }

    // Share struct that decides the share of each address
    struct Share{
        address payee;
        uint share;
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

/**
 * @title Errors library
 * @author Konstantin Samarin
 * @notice Defines the error messages emitted by the different contracts of the RociFi protocol
 * @dev Error messages prefix glossary:
 *  - NFCS = NFCS
 *  - BONDS = Bonds
 *  - INVESTOR = Investor
 *  - POOL_INVESTOR = PoolInvestor
 *  - SCORE_DB = ScoreConfigs, ScoreDB
 *  - PAYMENT = ERC20CollateralPayment, ERC20PaymentStandard, RociPayment
 *  - PRICE_FEED = PriceFeed
 *  - REVENUE = PaymentSplitter, RevenueManager
 *  - LOAN = Loan 
 *  - VERSION = Version
 */
library Errors {
  string public constant NFCS_TOKEN_MINTED = '0'; //  Token already minted
  string public constant NFCS_TOKEN_NOT_MINTED = '1'; //  No token minted for address
  string public constant NFCS_ADDRESS_BUNDLED = '2';  // Address already bundled
  string public constant NFCS_WALLET_VERIFICATION_FAILED = '3'; //  Wallet verification failed
  string public constant NFCS_NONEXISTENT_TOKEN = '4';  // Nonexistent NFCS token
  string public constant NFCS_TOKEN_HAS_BUNDLE = '5'; //  Token already has an associated bundle
  string public constant NFCS_TOKEN_HAS_NOT_BUNDLE = '6'; //  Token does not have an associated bundle

  string public constant BONDS_HASH_AND_ENCODING = '100'; //  Hash of data signed must be the paymentContractAddress and id encoded in that order
  string public constant BONDS_BORROWER_SIGNATURE = '101';  // Data provided must be signed by the borrower
  string public constant BONDS_NOT_STACKING = '102'; //  Not staking any NFTs
  string public constant BONDS_NOT_STACKING_INDEX = '103'; //  Not staking any tokens at this index
  string public constant BONDS_DELETE_HEAD = '104';  // Cannot delete the head

  string public constant INVESTOR_ISSUE_BONDS = '200'; //  Issue minting bonds
  string public constant INVESTOR_INSUFFICIENT_AMOUNT = '201'; //  Cannot borrow an amount of 0
  string public constant INVESTOR_BORROW_WITH_ANOTHER_SCORE = '202'; //  Cannot borrow if there is active loans with different score

  string public constant POOL_INVESTOR_INTEREST_RATE = '300';  // Interest rate has to be greater than zero
  string public constant POOL_INVESTOR_ZERO_POOL_VALUE = '301';  // Pool value is zero
  string public constant POOL_INVESTOR_ZERO_TOTAL_SUPPLY = '302';  // Total supply is zero
  string public constant POOL_INVESTOR_BONDS_LOST = '303';  // Bonds were lost in unstaking
  string public constant POOL_INVESTOR_NOT_ENOUGH_FUNDS = '304';  // Not enough funds to fulfill the loan

  string public constant MANAGER_COLLATERAL_NOT_ACCEPTED = '400';  // Collateral is not accepted
  string public constant MANAGER_COLLATERAL_INCREASE = '401';  // When increasing collateral, the same ERC20 address should be used
  string public constant MANAGER_ZERO_WITHDRAW = '402';  // Cannot withdrawal zero
  string public constant MANAGER_EXCEEDING_WITHDRAW = '403';  // Requested withdrawal amount is too large

  string public constant SCORE_DB_EQUAL_LENGTH = '501';  // Arrays must be of equal length
  string public constant SCORE_DB_VERIFICATION = '502';  // Unverified score
  string public constant SCORE_DB_SCORE_NOT_GENERATED= '503';  // Score not yet generated.
  string public constant SCORE_DB_SCORE_GENERATING = '504';  // Error generating score.
  string public constant SCORE_DB_UNKNOW_FETCHING_SCORE = '505';  //  Unknown error fetching score.


  string public constant PAYMENT_NFCS_OUTDATED = '600';  // Outdated NFCS score outdated
  string public constant PAYMENT_ZERO_LTV = '601';  // LTV cannot be zero
  string public constant PAYMENT_NOT_ENOUGH_COLLATERAL = '602';  // Not enough collateral to issue a loan
  string public constant PAYMENT_NO_BONDS = '603';  // There is no bonds to liquidate a loan
  string public constant PAYMENT_FULFILLED = '604';  // Contract is paid off
  string public constant PAYMENT_NFCS_OWNERSHIP = '605';  // NFCS ID must belong to the borrower
  string public constant PAYMENT_NON_ISSUED_LOAN = '606';  // Loan has not been issued
  string public constant PAYMENT_WITHDRAWAL_COLLECTION = '607';  // There are not enough payments available for collection
  string public constant PAYMENT_LOAN_NOT_DELINQUENT = '608';  // Loan not delinquent
  string public constant PAYMENT_AMOUNT_TOO_LARGE = '609';  // Payment amount is too large
  string public constant PAYMENT_CLAIM_COLLATERAL = '610';  // Cannot claim collateral if this collateral is necessary for any non Closed/Liquidated loan's delinquency status

  string public constant PRICE_FEED_TOKEN_NOT_SUPPORTED = '700';  // Token is not supported
  
  string public constant REVENUE_ADDRESS_TO_SHARE = '800';  // Non-equal length of addresses and shares
  string public constant REVENUE_UNIQUE_INDEXES = '801';  // Indexes in an array must not be duplicate
  string public constant REVENUE_FAILED_ETHER_TX = '802';  // Failed to send Ether
  string public constant REVENUE_UNVERIFIED_INVESTOR = '803';  // Only verified investors may request funds or make a payment
  string public constant REVENUE_NOT_ENOUGH_FUNDS = '804';  // Not enough funds to complete this request

  string public constant LOAN_MIN_PAYMENT = '900';  // Minimal payment should be made
  string public constant LOAN_DAILY_LIMIT = '901';  // Exceeds daily borrow limit
  string public constant LOAN_DAILY_LIMIT_USER = '902';  // Exceeds user daily borrow limit
  string public constant LOAN_TOTAL_LIMIT_USER = '903';  // Exceeds user total borrow limit
  string public constant LOAN_TOTAL_LIMIT = '904';  // Exceeds total borrow limit
  string public constant LOAN_CONFIGURATION = '905';  // Loan that is already issued, or not configured cannot be issued
  string public constant LOAN_TOTAL_LIMIT_NFCS = '906';  // Exceeds total nfcs borrow limit
  string public constant LOAN_DAILY_LIMIT_NFCS = '907';  // Exceeds daily nfcs borrow limit

  string public constant VERSION = '1000';  // Incorrect version of contract

   
  string public constant ADDRESS_BOOK_SET_MIN_SCORE = '1100';  // New min score must be less then maxScore
  string public constant ADDRESS_BOOK_SET_MAX_SCORE = '1101';  // New max score must be more then minScore
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}