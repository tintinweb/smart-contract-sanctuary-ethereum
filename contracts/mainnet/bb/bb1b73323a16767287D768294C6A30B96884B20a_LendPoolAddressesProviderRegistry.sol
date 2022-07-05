// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {ILendPoolAddressesProviderRegistry} from "../interfaces/ILendPoolAddressesProviderRegistry.sol";

/**
 * @title LendPoolAddressesProviderRegistry contract
 * @dev Main registry of LendPoolAddressesProvider of multiple protocol's markets
 * - Used for indexing purposes of protocol's markets
 * - The id assigned to a LendPoolAddressesProvider refers to the market it is connected with,
 *   for example with `1` for the main market and `2` for the next created
 
 **/
contract LendPoolAddressesProviderRegistry is Ownable, ILendPoolAddressesProviderRegistry {
  mapping(address => uint256) private _addressesProviders;
  address[] private _addressesProvidersList;

  /**
   * @dev Returns the list of registered addresses provider
   * @return The list of addresses provider, potentially containing address(0) elements
   **/
  function getAddressesProvidersList() external view override returns (address[] memory) {
    address[] memory addressesProvidersList = _addressesProvidersList;

    uint256 maxLength = addressesProvidersList.length;

    address[] memory activeProviders = new address[](maxLength);

    for (uint256 i = 0; i < maxLength; i++) {
      if (_addressesProviders[addressesProvidersList[i]] > 0) {
        activeProviders[i] = addressesProvidersList[i];
      }
    }

    return activeProviders;
  }

  /**
   * @dev Registers an addresses provider
   * @param provider The address of the new LendPoolAddressesProvider
   * @param id The id for the new LendPoolAddressesProvider, referring to the market it belongs to
   **/
  function registerAddressesProvider(address provider, uint256 id) external override onlyOwner {
    require(id != 0, Errors.LPAPR_INVALID_ADDRESSES_PROVIDER_ID);

    _addressesProviders[provider] = id;
    _addToAddressesProvidersList(provider);
    emit AddressesProviderRegistered(provider);
  }

  /**
   * @dev Removes a LendPoolAddressesProvider from the list of registered addresses provider
   * @param provider The LendPoolAddressesProvider address
   **/
  function unregisterAddressesProvider(address provider) external override onlyOwner {
    require(_addressesProviders[provider] > 0, Errors.LPAPR_PROVIDER_NOT_REGISTERED);
    _addressesProviders[provider] = 0;
    emit AddressesProviderUnregistered(provider);
  }

  /**
   * @dev Returns the id on a registered LendPoolAddressesProvider
   * @return The id or 0 if the LendPoolAddressesProvider is not registered
   */
  function getAddressesProviderIdByAddress(address addressesProvider) external view override returns (uint256) {
    return _addressesProviders[addressesProvider];
  }

  function _addToAddressesProvidersList(address provider) internal {
    uint256 providersCount = _addressesProvidersList.length;

    for (uint256 i = 0; i < providersCount; i++) {
      if (_addressesProvidersList[i] == provider) {
        return;
      }
    }

    _addressesProvidersList.push(provider);
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/**
 * @title Errors library
 
 * @notice Defines the error messages emitted by the different contracts of the protocol
 */
library Errors {
  enum ReturnCode {
    SUCCESS,
    FAILED
  }

  string public constant SUCCESS = "0";

  //common errors
  string public constant CALLER_NOT_POOL_ADMIN = "100"; // 'The caller must be the pool admin'
  string public constant CALLER_NOT_ADDRESS_PROVIDER = "101";
  string public constant INVALID_FROM_BALANCE_AFTER_TRANSFER = "102";
  string public constant INVALID_TO_BALANCE_AFTER_TRANSFER = "103";
  string public constant CALLER_NOT_ONBEHALFOF_OR_IN_WHITELIST = "104";

  //math library erros
  string public constant MATH_MULTIPLICATION_OVERFLOW = "200";
  string public constant MATH_ADDITION_OVERFLOW = "201";
  string public constant MATH_DIVISION_BY_ZERO = "202";

  //validation & check errors
  string public constant VL_INVALID_AMOUNT = "301"; // 'Amount must be greater than 0'
  string public constant VL_NO_ACTIVE_RESERVE = "302"; // 'Action requires an active reserve'
  string public constant VL_RESERVE_FROZEN = "303"; // 'Action cannot be performed because the reserve is frozen'
  string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = "304"; // 'User cannot withdraw more than the available balance'
  string public constant VL_BORROWING_NOT_ENABLED = "305"; // 'Borrowing is not enabled'
  string public constant VL_COLLATERAL_BALANCE_IS_0 = "306"; // 'The collateral balance is 0'
  string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = "307"; // 'Health factor is lesser than the liquidation threshold'
  string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = "308"; // 'There is not enough collateral to cover a new borrow'
  string public constant VL_NO_DEBT_OF_SELECTED_TYPE = "309"; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
  string public constant VL_NO_ACTIVE_NFT = "310";
  string public constant VL_NFT_FROZEN = "311";
  string public constant VL_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "312"; // 'User did not borrow the specified currency'
  string public constant VL_INVALID_HEALTH_FACTOR = "313";
  string public constant VL_INVALID_ONBEHALFOF_ADDRESS = "314";
  string public constant VL_INVALID_TARGET_ADDRESS = "315";
  string public constant VL_INVALID_RESERVE_ADDRESS = "316";
  string public constant VL_SPECIFIED_LOAN_NOT_BORROWED_BY_USER = "317";
  string public constant VL_SPECIFIED_RESERVE_NOT_BORROWED_BY_USER = "318";
  string public constant VL_HEALTH_FACTOR_HIGHER_THAN_LIQUIDATION_THRESHOLD = "319";

  //lend pool errors
  string public constant LP_CALLER_NOT_LEND_POOL_CONFIGURATOR = "400"; // 'The caller of the function is not the lending pool configurator'
  string public constant LP_IS_PAUSED = "401"; // 'Pool is paused'
  string public constant LP_NO_MORE_RESERVES_ALLOWED = "402";
  string public constant LP_NOT_CONTRACT = "403";
  string public constant LP_BORROW_NOT_EXCEED_LIQUIDATION_THRESHOLD = "404";
  string public constant LP_BORROW_IS_EXCEED_LIQUIDATION_PRICE = "405";
  string public constant LP_NO_MORE_NFTS_ALLOWED = "406";
  string public constant LP_INVALIED_USER_NFT_AMOUNT = "407";
  string public constant LP_INCONSISTENT_PARAMS = "408";
  string public constant LP_NFT_IS_NOT_USED_AS_COLLATERAL = "409";
  string public constant LP_CALLER_MUST_BE_AN_BTOKEN = "410";
  string public constant LP_INVALIED_NFT_AMOUNT = "411";
  string public constant LP_NFT_HAS_USED_AS_COLLATERAL = "412";
  string public constant LP_DELEGATE_CALL_FAILED = "413";
  string public constant LP_AMOUNT_LESS_THAN_EXTRA_DEBT = "414";
  string public constant LP_AMOUNT_LESS_THAN_REDEEM_THRESHOLD = "415";

  //lend pool loan errors
  string public constant LPL_INVALID_LOAN_STATE = "480";
  string public constant LPL_INVALID_LOAN_AMOUNT = "481";
  string public constant LPL_INVALID_TAKEN_AMOUNT = "482";
  string public constant LPL_AMOUNT_OVERFLOW = "483";
  string public constant LPL_BID_PRICE_LESS_THAN_LIQUIDATION_PRICE = "484";
  string public constant LPL_BID_PRICE_LESS_THAN_HIGHEST_PRICE = "485";
  string public constant LPL_BID_REDEEM_DURATION_HAS_END = "486";
  string public constant LPL_BID_USER_NOT_SAME = "487";
  string public constant LPL_BID_REPAY_AMOUNT_NOT_ENOUGH = "488";
  string public constant LPL_BID_AUCTION_DURATION_HAS_END = "489";
  string public constant LPL_BID_AUCTION_DURATION_NOT_END = "490";
  string public constant LPL_BID_PRICE_LESS_THAN_BORROW = "491";
  string public constant LPL_INVALID_BIDDER_ADDRESS = "492";
  string public constant LPL_AMOUNT_LESS_THAN_BID_FINE = "493";
  string public constant LPL_BID_INVALID_BID_FINE = "494";

  //common token errors
  string public constant CT_CALLER_MUST_BE_LEND_POOL = "500"; // 'The caller of this function must be a lending pool'
  string public constant CT_INVALID_MINT_AMOUNT = "501"; //invalid amount to mint
  string public constant CT_INVALID_BURN_AMOUNT = "502"; //invalid amount to burn
  string public constant CT_BORROW_ALLOWANCE_NOT_ENOUGH = "503";

  //reserve logic errors
  string public constant RL_RESERVE_ALREADY_INITIALIZED = "601"; // 'Reserve has already been initialized'
  string public constant RL_LIQUIDITY_INDEX_OVERFLOW = "602"; //  Liquidity index overflows uint128
  string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = "603"; //  Variable borrow index overflows uint128
  string public constant RL_LIQUIDITY_RATE_OVERFLOW = "604"; //  Liquidity rate overflows uint128
  string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = "605"; //  Variable borrow rate overflows uint128

  //configure errors
  string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = "700"; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_CONFIGURATION = "701"; // 'Invalid risk parameters for the reserve'
  string public constant LPC_CALLER_NOT_EMERGENCY_ADMIN = "702"; // 'The caller must be the emergency admin'
  string public constant LPC_INVALIED_BNFT_ADDRESS = "703";
  string public constant LPC_INVALIED_LOAN_ADDRESS = "704";
  string public constant LPC_NFT_LIQUIDITY_NOT_0 = "705";

  //reserve config errors
  string public constant RC_INVALID_LTV = "730";
  string public constant RC_INVALID_LIQ_THRESHOLD = "731";
  string public constant RC_INVALID_LIQ_BONUS = "732";
  string public constant RC_INVALID_DECIMALS = "733";
  string public constant RC_INVALID_RESERVE_FACTOR = "734";
  string public constant RC_INVALID_REDEEM_DURATION = "735";
  string public constant RC_INVALID_AUCTION_DURATION = "736";
  string public constant RC_INVALID_REDEEM_FINE = "737";
  string public constant RC_INVALID_REDEEM_THRESHOLD = "738";
  string public constant RC_INVALID_AUCTION_PERC = "739";

  //address provider erros
  string public constant LPAPR_PROVIDER_NOT_REGISTERED = "760"; // 'Provider is not registered'
  string public constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = "761";
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/**
 * @title ILendPoolAddressesProviderRegistry contract
 * @dev Main registry of LendPoolAddressesProvider of multiple protocol's markets
 * - Used for indexing purposes of protocol's markets
 * - The id assigned to a LendPoolAddressesProvider refers to the market it is connected with,
 *   for example with `1` for the main market and `2` for the next created
 **/
interface ILendPoolAddressesProviderRegistry {
  event AddressesProviderRegistered(address indexed newAddress);
  event AddressesProviderUnregistered(address indexed newAddress);

  function getAddressesProvidersList() external view returns (address[] memory);

  function getAddressesProviderIdByAddress(address addressesProvider) external view returns (uint256);

  function registerAddressesProvider(address provider, uint256 id) external;

  function unregisterAddressesProvider(address provider) external;
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