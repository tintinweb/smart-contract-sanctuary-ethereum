// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

contract FeeTierStrate is Ownable {
  struct FeeRecObj {
    uint256 index;
    string title;
    address account;
    uint256 feePercent;
    bool exist;
  }

  struct ManagerObj {
    uint256 index;
    bool exist;
  }

  uint256 public MAX_FEE = 1000;
  uint256 public MAX_INDEX = 1;
  uint256 private depositFee = 0;
  uint256 private totalFee = 100;
  uint256 private withdrawlFee = 0;
  uint256 private baseFee = 1000;

  mapping (uint256 => FeeRecObj) private _feeTier;
  uint256[] private _tierIndex;

  mapping (address => ManagerObj) private _manageAccess;
  address[] private _feeManager;

  modifier onlyManager() {
    require(msg.sender == owner() || _manageAccess[msg.sender].exist, "!manager");
    _;
  }

  function getAllManager() public view returns(address[] memory) {
    return _feeManager;
  }

  function setManager(address usraddress, bool access) public onlyOwner {
    if (access == true) {
      if ( ! _manageAccess[usraddress].exist) {
        uint256 newId = _feeManager.length;
        _manageAccess[usraddress] = ManagerObj(newId, true);
        _feeManager.push(usraddress);
      }
    }
    else {
      if (_manageAccess[usraddress].exist) {
        address lastObj = _feeManager[_feeManager.length - 1];
        _feeManager[_manageAccess[usraddress].index] = _feeManager[_manageAccess[lastObj].index];
        _feeManager.pop();
        delete _manageAccess[usraddress];
      }
    }
  }

  function getMaxFee() public view returns(uint256) {
    return MAX_FEE;
  }

  function setMaxFee(uint256 newFee) public onlyManager {
    MAX_FEE = newFee;
  }

  function setDepositFee(uint256 newFee) public onlyManager {
    depositFee = newFee;
  }

  function setTotalFee(uint256 newFee) public onlyManager {
    totalFee = newFee;
  }

  function setWithdrawFee(uint256 newFee) public onlyManager {
    withdrawlFee = newFee;
  }

  function setBaseFee(uint256 newFee) public onlyManager {
    baseFee = newFee;
  }

  function getDepositFee() public view returns(uint256, uint256) {
    return (depositFee, baseFee);
  }

  function getTotalFee() public view returns(uint256, uint256) {
    return (totalFee, baseFee);
  }

  function getWithdrawFee() public view returns(uint256, uint256) {
    return (withdrawlFee, baseFee);
  }

  function getAllTier() public view returns(uint256[] memory) {
    return _tierIndex;
  }

  function insertTier(string memory title, address account, uint256 fee) public onlyManager {
    require(fee < MAX_FEE, "Fee tier value is overflowed");
    _tierIndex.push(MAX_INDEX);
    _feeTier[MAX_INDEX] = FeeRecObj(_tierIndex.length - 1, title, account, fee, true);
    MAX_INDEX = MAX_INDEX + 1;
  }

  function getTier(uint256 index) public view returns(address, string memory, uint256) {
    require(_feeTier[index].exist, "Only existing tier can be loaded");
    FeeRecObj memory tierItem = _feeTier[index];
    return (tierItem.account, tierItem.title, tierItem.feePercent);
  }

  function updateTier(uint256 index, string memory title, address account, uint256 fee) public onlyManager {
    require(_feeTier[index].exist, "Only existing tier can be loaded");
    require(fee < MAX_FEE, "Fee tier value is overflowed");
    _feeTier[index].title = title;
    _feeTier[index].account = account;
    _feeTier[index].feePercent = fee;
  }

  function removeTier(uint256 index) public onlyManager {
    require(_feeTier[index].exist, "Only existing tier can be removed");
    uint256 arr_index = _feeTier[index].index;
    uint256 last_index = _tierIndex[_tierIndex.length-1];
    
    FeeRecObj memory changedObj = _feeTier[last_index];
    _feeTier[last_index] = FeeRecObj(arr_index, changedObj.title, changedObj.account, changedObj.feePercent, true);
    _tierIndex[arr_index] = last_index;
    _tierIndex.pop();
    delete _feeTier[index];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}