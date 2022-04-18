// SPDX-License-Identifier: BUSL-1.1
// EPSProxy Contracts v1.11.0 (epsproxy/contracts/ProxyRegister.sol)

pragma solidity ^0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@epsproxy/contracts/EPS.sol";
import "@omnus/contracts/token/ERC20Spendable/ERC20SpendableReceiver.sol"; 

/**
 * @dev The EPS Register contract.
 */
contract ProxyRegister is EPS, Ownable, ERC20SpendableReceiver {
  using SafeERC20 for IERC20;

  struct Record {
    address nominator;
    address delivery; 
  }

  uint256 private registerFee;
  uint256 private registerFeeOat;
  address private treasury;

  mapping (address => address) nominatorToProxy;
  mapping (address => Record) proxyToRecord;

  /**
  * @dev Constructor initialises the register fee and treasury address:
  */
  constructor(
    uint256 _registerFee,
    uint256 _registerFeeOat,
    address _treasury,
    address _ERC20Spendable
  ) 
    ERC20SpendableReceiver(_ERC20Spendable) 
  {
    setRegisterFee(_registerFee);
    setRegisterFeeOat(_registerFeeOat);
    setTreasuryAddress(_treasury);
  }

  /** 
  * @dev Nominators can nominate ONCE only
  */ 
  modifier isNotCurrentNominator(address _nominator) {
    require(!nominationExists(_nominator), "Address has an existing nomination");
    _;
  }

  /**
  * @dev Check if this nominator is already on the registry
  */
  modifier isExistingNominator(address _nominator) {
    require(nominationExists(_nominator), "Nominator entry does not exist");
    _;
  }

  /** 
  * @dev Proxys can act as proxy ONCE only
  */ 
  modifier isNotCurrentProxy(address _proxy) {
    require(!proxyRecordExists(_proxy), "Address is already acting as a proxy");
    _;
  }

  /**
  * @dev Check if this proxy is already on the registry
  */
  modifier isExistingProxy(address _proxy) {
    require(proxyRecordExists(_proxy), "Proxy entry does not exist");
    _;
  }

  /**
  * @dev Return if an entry exists for this nominator address
  */
  function nominationExists(address _nominator) public view returns (bool) {
    return nominatorToProxy[_nominator] != address(0);
  }

  /**
  * @dev Return if an entry exists for this nominator address - For Caller
  */
  function nominationExistsForCaller() public view returns (bool) {
    return nominationExists(msg.sender);
  }

  /**
  * @dev Return if an entry exists for this proxy address
  */
  function proxyRecordExists(address _proxy) public view returns (bool) {
    return proxyToRecord[_proxy].nominator != address(0);
  }

  /**
  * @dev Return if an entry exists for this proxy address - For Caller
  */
  function proxyRecordExistsForCaller() external view returns (bool) {
    return proxyRecordExists(msg.sender);
  }

  /**
  * @dev Return if an entry exists for this nominator address
  */
  function nominatorRecordExists(address _nominator) public view returns (bool) {
    return proxyToRecord[nominatorToProxy[_nominator]].nominator != address(0);
  }

  /**
  * @dev Return if an entry exists for this nominator address - For Caller
  */
  function nominatorRecordExistsForCaller() external view returns (bool) {
    return nominatorRecordExists(msg.sender);
  }

  /**
  * @dev Return if the address is an active proxy address OR a nominator with an active proxy
  */
  function addressIsActive(address _receivedAddress) public view returns (bool) {
    bool isActive = false;
    // Check if the address is an active proxy address or active nominator:
    if (proxyRecordExists(_receivedAddress) || nominatorRecordExists(_receivedAddress)){
      isActive = true;
    }
    return isActive;
  }

  /**
  * @dev Return if the address is an active proxy address OR a nominator with an active proxy - For Caller
  */
  function addressIsActiveForCaller() external view returns (bool) {
    return addressIsActive(msg.sender);
  }

  /**
  * @dev Get entry details by proxy
  */
  function getProxyRecord(address _proxy) public view returns (address nominator, address proxy, address delivery) {
    Record memory currentItem = proxyToRecord[_proxy];
    return (currentItem.nominator, nominatorToProxy[currentItem.nominator], currentItem.delivery);
  }
  
  /**
  * @dev Get entry details by proxy - For Caller
  */
  function getProxyRecordForCaller() external view returns (address nominator, address proxy, address delivery) {
    return (getProxyRecord(msg.sender));
  }

  /**
  * @dev Get entry details by nominator
  */
  function getNominatorRecord(address _nominator) public view returns (address nominator, address proxy, address delivery) {
    address proxyAddress = nominatorToProxy[_nominator];
    if (proxyToRecord[proxyAddress].nominator == address(0)) {
      // This function returns registry entries. If there is no entry on the registry (despite there being a nomination), do
      // not return the proxy address:
      proxyAddress = address(0);
    }
    return (proxyToRecord[proxyAddress].nominator, proxyAddress, proxyToRecord[proxyAddress].delivery);
  }

  /**
  * @dev Get entry details by nominator - For Caller
  */
  function getNominatorRecordForCaller() external view returns (address nominator, address proxy, address delivery) {
    return (getNominatorRecord(msg.sender));
  }

  /**
  * @dev Get nomination details only for nominator
  */
  function getNomination(address _nominator) public view returns (address proxy) {
    return (nominatorToProxy[_nominator]);
  }

  /**
  * @dev Get nomination details only for nominator - For Caller
  */
  function getNominationForCaller() public view returns (address proxy) {
    return (getNomination(msg.sender));
  }

  /**
  * @dev Returns the proxied address details (nominator and delivery address) for a passed proxy address  
  */
  function getAddresses(address _receivedAddress) public view returns (address nominator, address delivery, bool isProxied) {
    require(!nominationExists(_receivedAddress), "Nominator address cannot interact directly, only through the proxy address");
    Record memory currentItem = proxyToRecord[_receivedAddress];
    if (proxyToRecord[_receivedAddress].nominator == address(0)) {
      return(_receivedAddress, _receivedAddress, false);
    }
    else {
      return (currentItem.nominator, currentItem.delivery, true);
    }
  }

  /**
  * @dev Returns the proxied address details (owner and delivery address) for the msg.sender being interacted with
  */
  function getAddressesForCaller() external view returns (address nominator, address delivery, bool isProxied) {
    return (getAddresses(msg.sender));
  }

  /**
  * @dev Returns the current role of a given address (nominator, proxy, none)
  */
  function getRole(address _roleAddress) public view returns (string memory currentRole) {
    if (proxyRecordExists(_roleAddress)) {
      return "Proxy";
    }
    if (nominationExists(_roleAddress)) {
      if (proxyRecordExists(nominatorToProxy[_roleAddress])) {
        return "Nominator - Proxy Active";
      }
      else {
        return "Nominator - Proxy Pending";
      }
    }
    return "None";
  }

  /**
  * @dev Returns the current role of a given address (nominator, proxy, none) - For Caller
  */
  function getRoleForCaller() external view returns (string memory currentRole) {
    return getRole(msg.sender);
  }

  /**
  * @dev The nominator initiaties a proxy entry
  */
  function makeNomination(address _proxy, uint256 _provider) external payable {
    require(msg.value == registerFee, "Register fee must be paid");

    performNomination(msg.sender, _proxy, _provider);
  }

  /**
  * @dev The nominator initiaties a proxy entry, paying with ERC20
  */
  function receiveSpendableERC20(address _caller, uint256 _tokenPaid, uint256[] memory _arguments) override external onlyERC20Spendable(msg.sender) returns(bool, uint256[] memory) { 
    require(_tokenPaid == registerFeeOat, "Register fee must be paid");

    performNomination(_caller, address(uint160(_arguments[0])), _arguments[1]);

    return(true, new uint256[](0)); 
  }

  /**
  * @dev Process the nomination
  */
  function performNomination(address _nominator, address _proxy, uint256 _provider) internal isNotCurrentNominator(_nominator) isNotCurrentProxy(_proxy) isNotCurrentProxy(_nominator) {
    require (_proxy != address(0), "Proxy address must be provided");
    require (_proxy != _nominator, "Proxy address cannot be the same as Nominator address");

    nominatorToProxy[_nominator] = _proxy;
    emit NominationMade(_nominator, _proxy, block.timestamp, _provider); 
  }
  
  /**
  * @dev Proxy accepts nomination
  */
  function acceptNomination(address _nominator, address _delivery, uint256 _provider) external isNotCurrentProxy(msg.sender) isNotCurrentProxy(_nominator) {
    // The nominator must be passed in:
    require (_nominator != address(0), "Nominator address must be provided");
    // The sender must match the proxy nomination:
    require (nominatorToProxy[_nominator] == msg.sender, "Caller is not the nominated proxy for this nominator");
    // We have a valid nomination, create the ProxyRegisterItem:
    proxyToRecord[msg.sender] = Record(_nominator, _delivery);
    emit NominationAccepted(_nominator, msg.sender, _delivery, block.timestamp, _provider);
  }

  /**
  * @dev Change delivery address on an existing proxy item. Can only be called by the proxy address.
  */
  function updateDeliveryAddress(address _delivery, uint256 _provider) external isExistingProxy(msg.sender) {
    Record memory priorItem = proxyToRecord[msg.sender];
    proxyToRecord[msg.sender].delivery = _delivery;
    emit DeliveryUpdated(priorItem.nominator, msg.sender, _delivery, priorItem.delivery, block.timestamp, _provider);
  }

  /**
  * @dev delete a proxy entry. BOTH the nominator and proxy can delete a proxy arrangement and all
  * aspects of that proxy arrangement will be removed.
  */
  function deleteRecordByNominator(uint256 _provider) external isExistingNominator(msg.sender) {
    deleteProxyRegisterItems(msg.sender, nominatorToProxy[msg.sender], "nominator", _provider);
  }

  /**
  * @dev delete a proxy entry. BOTH the nominator and proxy can delete a proxy arrangement and all
  * aspects of that proxy arrangement will be removed.
  */
  function deleteRecordByProxy(uint256 _provider) external isExistingProxy(msg.sender) {
    deleteProxyRegisterItems(proxyToRecord[msg.sender].nominator, msg.sender, "proxy", _provider);
  }

  /**
  * @dev delete the nomination and record (if present)
  */
  function deleteProxyRegisterItems(address _nominator, address _proxy, string memory _initiator, uint256 _provider) internal {
    // First remove the nomination. We know this must exists, as it has to come before the proxy can be accepted:
    delete nominatorToProxy[_nominator];
    emit NominationDeleted(_initiator, _nominator, _proxy, block.timestamp, _provider);
    // Now remove the proxy register item. If the nominator is deleting a nomination that has not been accepted by a proxy
    // then this will not exists. Check that the proxy is for this nominator.
    if (proxyToRecord[_proxy].nominator == _nominator) {
      address deletedDelivery = proxyToRecord[_proxy].delivery; 
      delete proxyToRecord[_proxy];
      emit RecordDeleted(_initiator, _nominator, _proxy, deletedDelivery, block.timestamp, _provider);
    }
  }

  /**
  * @dev set the fee for initiating a registration (accepting a proxy, updating the delivery address and deletions will always be free)
  */
  function setRegisterFee(uint256 _registerFee) public onlyOwner returns (bool)
  {
    require(_registerFee != registerFee, "No change to register fee");
    registerFee = _registerFee;
    emit RegisterFeeSet(registerFee);
    return true;
  }

  /**
  * @dev set the OAT fee for initiating a registration (accepting a proxy, updating the delivery address and deletions will always be free)
  */
  function setRegisterFeeOat(uint256 _registerFeeOat) public onlyOwner returns (bool)
  {
    require(_registerFeeOat != registerFeeOat, "No change to register fee");
    registerFeeOat = _registerFeeOat;
    emit RegisterFeeOatSet(_registerFeeOat);
    return true;
  }

  /**
  * @dev return the register fee:
  */
  function getRegisterFee() external view returns (uint256 _registerFee) {
    return(registerFee);
  }

    /**
  * @dev return the OAT register fee:
  */
  function getRegisterFeeOat() external view returns (uint256 _registerFeeOat) {
    return(registerFeeOat);
  }

  /**
  * @dev set the treasury address:
  */
  function setTreasuryAddress(address _treasuryAddress) public onlyOwner returns (bool)
  {
    require(_treasuryAddress != treasury, "No change to treasury address");
    treasury = _treasuryAddress;
    emit TreasuryAddressSet(treasury);
    return true;
  }

  /**
  * @dev get the treasury address:
  */
  function getTreasuryAddress() external view returns (address _treasuryAddress) {
    return(treasury);
  }

  /**
  * @dev withdraw eth to the treasury:
  */
  function withdraw(uint256 _amount) external onlyOwner returns (bool) {
    (bool success, ) = treasury.call{value: _amount}("");
    require(success, "Withdrawal failed.");
    emit Withdrawal(_amount, block.timestamp);
    return true;
  }

  /**
  * @dev Allow any token payments to be withdrawn:
  */
  function withdrawERC20(IERC20 _token, uint256 _amountToWithdraw) external onlyOwner {
    _token.safeTransfer(treasury, _amountToWithdraw); 
    emit TokenWithdrawal(_amountToWithdraw, address(_token), block.timestamp);
  }

  /**
  * @dev revert fallback
  */
  fallback() external payable {
    revert();
  }

  /**
  * @dev revert receive
  */
  receive() external payable {
    revert();
  }
}

// SPDX-License-Identifier: MIT
// Omnus Contracts (contracts/token/ERC20Spendable/SpendableERC20Receiver.sol)
// https://omnuslab.com/spendable

// ERC20SpendableReceiver (Lightweight library for allowing contract interaction on token transfer).

pragma solidity ^0.8.13;

/**
*
* @dev ERC20SpendableReceiver - library contract for an ERC20 extension to allow ERC20s to 
* operate as 'spendable' items, i.e. a token that can trigger an action on another contract
* at the same time as being transfered. Similar to ERC677 and the hooks in ERC777, but with more
* of an empasis on interoperability (returned values) than ERC677 and specifically scoped interaction
* rather than the general hooks of ERC777. 
*
* This library contract allows a smart contract to operate as a receiver of ERC20Spendable tokens.
*
*/

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";   
import "@omnus/contracts/token/ERC20Spendable/IERC20SpendableReceiver.sol"; 

/**
*
* @dev ERC20SpendableReceiver.
*
*/
abstract contract ERC20SpendableReceiver is Context, Ownable, IERC20SpendableReceiver {
  
  address public immutable ERC20Spendable; 

  event ERC20Received(address _caller, uint256 _tokenPaid, uint256[] _arguments);

  /** 
  *
  * @dev must be passed the token contract for the payable ERC20:
  *
  */ 
  constructor(address _ERC20Spendable) {
    ERC20Spendable = _ERC20Spendable;
  }

  /** 
  *
  * @dev Only allow authorised token:
  *
  */ 
  modifier onlyERC20Spendable(address _caller) {
    require (_caller == ERC20Spendable, "Call from unauthorised caller");
    _;
  }

  /** 
  *
  * @dev function to be called on receive. Must be overriden, including the addition of a fee check, if required:
  *
  */ 
  function receiveSpendableERC20(address _caller, uint256 _tokenPaid, uint256[] memory _arguments) external virtual onlyERC20Spendable(msg.sender) returns(bool, uint256[] memory) { 
    // Must be overriden 
  }

}

// SPDX-License-Identifier: MIT
// EPSProxy Contracts v1.11.0 (epsproxy/contracts/EPS.sol)

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev Implementation of the EPS register interface.
 */
interface EPS {
  // Emitted when an address nominates a proxy address:
  event NominationMade(address indexed nominator, address indexed proxy, uint256 timestamp, uint256 provider);
  // Emitted when an address accepts a proxy nomination:
  event NominationAccepted(address indexed nominator, address indexed proxy, address indexed delivery, uint256 timestamp, uint256 provider);
  // Emitted when the proxy address updates the delivery address on a record:
  event DeliveryUpdated(address indexed nominator, address indexed proxy, address indexed delivery, address oldDelivery, uint256 timestamp, uint256 provider);
  // Emitted when a nomination record is deleted. initiator 0 = nominator, 1 = proxy:
  event NominationDeleted(string initiator, address indexed nominator, address indexed proxy, uint256 timestamp, uint256 provider);
  // Emitted when a register record is deleted. initiator 0 = nominator, 1 = proxy:
  event RecordDeleted(string initiator, address indexed nominator, address indexed proxy, address indexed delivery, uint256 timestamp, uint256 provider);
  // Emitted when the register fee is set:
  event RegisterFeeSet(uint256 indexed registerFee);
  event RegisterFeeOatSet(uint256 indexed registerFeeOat);
  // Emitted when the treasury address is set:
  event TreasuryAddressSet(address indexed treasuryAddress);
  // Emitted on withdrawal to the treasury address:
  event Withdrawal(uint256 indexed amount, uint256 timestamp);
  event TokenWithdrawal(uint256 indexed amount, address indexed tokenAddress, uint256 timestamp);

  function nominationExists(address _nominator) external view returns (bool);
  function nominationExistsForCaller() external view returns (bool);
  function proxyRecordExists(address _proxy) external view returns (bool);
  function proxyRecordExistsForCaller() external view returns (bool);
  function nominatorRecordExists(address _nominator) external view returns (bool);
  function nominatorRecordExistsForCaller() external view returns (bool);
  function getProxyRecord(address _proxy) external view returns (address nominator, address proxy, address delivery);
  function getProxyRecordForCaller() external view returns (address nominator, address proxy, address delivery);
  function getNominatorRecord(address _nominator) external view returns (address nominator, address proxy, address delivery);
  function getNominatorRecordForCaller() external view returns (address nominator, address proxy, address delivery);
  function addressIsActive(address _receivedAddress) external view returns (bool);
  function addressIsActiveForCaller() external view returns (bool);
  function getNomination(address _nominator) external view returns (address proxy);
  function getNominationForCaller() external view returns (address proxy);
  function getAddresses(address _receivedAddress) external view returns (address nominator, address delivery, bool isProxied);
  function getAddressesForCaller() external view returns (address nominator, address delivery, bool isProxied);
  function getRole(address _roleAddress) external view returns (string memory currentRole);
  function getRoleForCaller() external view returns (string memory currentRole);
  function makeNomination(address _proxy, uint256 _provider) external payable;
  function acceptNomination(address _nominator, address _delivery, uint256 _provider) external;
  function updateDeliveryAddress(address _delivery, uint256 _provider) external;
  function deleteRecordByNominator(uint256 _provider) external;
  function deleteRecordByProxy(uint256 _provider) external;
  function setRegisterFee(uint256 _registerFee) external returns (bool);
  function getRegisterFee() external view returns (uint256 _registerFee);
  function setRegisterFeeOat(uint256 _registerFeeOat) external returns (bool);
  function getRegisterFeeOat() external view returns (uint256 _registerFeeOat);

  function setTreasuryAddress(address _treasuryAddress) external returns (bool);
  function getTreasuryAddress() external view returns (address _treasuryAddress);
  function withdraw(uint256 _amount) external returns (bool);
  function withdrawERC20(IERC20 _token, uint256 _amountToWithdraw) external;
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
// Omnus Contracts (contracts/token/ERC20Spendable/ISpendableERC20.sol)
// https://omnuslab.com/spendable

// IERC20SpendableReceiver - Interface definition for contracts to implement spendable ERC20 functionality

pragma solidity ^0.8.13;

/**
*
* @dev IERC20SpendableReceiver - library contract for an ERC20 extension to allow ERC20s to 
* operate as 'spendable' items, i.e. a token that can trigger an action on another contract
* at the same time as being transfered. Similar to ERC677 and the hooks in ERC777, but with more
* of an empasis on interoperability (returned values) than ERC677 and specifically scoped interaction
* rather than the general hooks of ERC777. 
*
* This library contract allows a smart contract to operate as a receiver of ERC20Spendable tokens.
*
* Interface Definition IERC20SpendableReceiver
*
*/

interface IERC20SpendableReceiver{

  /** 
  *
  * @dev function to be called on receive. 
  *
  */ 
  function receiveSpendableERC20(address _caller, uint256 _tokenPaid, uint256[] memory arguments) external returns(bool, uint256[] memory);

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