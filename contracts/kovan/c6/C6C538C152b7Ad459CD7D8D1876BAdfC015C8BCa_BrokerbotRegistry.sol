/**
* SPDX-License-Identifier: MIT
*
* Copyright (c) 2016-2019 zOS Global Limited
*
*/
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */

interface IERC20 {

    // Optional functions
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

/**
* SPDX-License-Identifier: LicenseRef-Aktionariat
*
* Proprietary License
*
* This code cannot be used without an explicit permission from the copyright holder.
* If you wish to use the Aktionariat Brokerbot, you can either use the open version
* named Brokerbot.sol that can be used under an MIT License with Automated License Fee Payments,
* or you can get in touch with use to negotiate a license to use LicensedBrokerbot.sol .
*
* Copyright (c) 2021 Aktionariat AG (aktionariat.com), All rights reserved.
*/
pragma solidity ^0.8.0;

import "./IBrokerbot.sol";
import "../ERC20/IERC20.sol";
import "../utils/Ownable.sol";

/// @title Brokerbot Registry
/// @notice Holds a registry from all deployed active brokerbots
contract BrokerbotRegistry is Ownable {
  /// @notice Returns the brokerbot address for a given pair base and share token, or address 0 if it does not exist
  /// @dev mapping is [base][token] = brokerbotAddress
  /// @return brokerbot The brokerbot address
  mapping(IERC20 => mapping(IERC20 => IBrokerbot)) public getBrokerbot;

  /// @notice Emitted when brokerbot is registered.
  /// @param brokerbot The address of the brokerbot
  /// @param base The address of the base currency
  /// @param token The address of the share token
  event RegisterBrokerbot(IBrokerbot brokerbot, IERC20 indexed base, IERC20 indexed token);

  /// @notice Emmitted when calling syncBrokerbot function
  /// @param brokerbot The brokerbot address that is synced
  event SyncBrokerbot(IBrokerbot indexed brokerbot);

  constructor(address _owner) Ownable(_owner) {}

  /// @notice Per network only one active brokerbot should exist per base/share pair
  /// @param _brokerbot The brokerbot contract that should be registered.
  /// @param _base The contract of the base currency of the brokerbot.
  /// @param _token The contract of the share token of the brokerbot.
  function registerBrokerbot(IBrokerbot _brokerbot, IERC20 _base, IERC20 _token ) external onlyOwner() {
    getBrokerbot[_base][_token] = _brokerbot;
    emit RegisterBrokerbot(_brokerbot, _base, _token);
  }

  /// @notice This event is usful for indexers/subgraphs to update token balances which are not tracked with other events
  /// @param _brokerbot The brokerbot that should be synced
  function syncBrokerbot(IBrokerbot _brokerbot) external {
    emit SyncBrokerbot(_brokerbot);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20/IERC20.sol";

interface IBrokerbot {

  function base() external view returns (IERC20);
  
  function settings() external view returns (uint256);

  // @return The amount of shares bought on buying or how much in the base currency is transfered on selling
  function processIncoming(IERC20 token_, address from, uint256 amount, bytes calldata ref) external payable returns (uint256);

}

// SPDX-License-Identifier: MIT
//
// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
//
// Modifications:
// - Replaced Context._msgSender() with msg.sender
// - Made leaner
// - Extracted interface

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
contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address initialOwner) {
        owner = initialOwner;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "not owner");
        _;
    }
}