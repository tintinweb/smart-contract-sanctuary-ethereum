/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.12;



// Part: IMintableERC1155

interface IMintableERC1155 {
  function mint(address to, uint256 id, uint256 amount) external;
  function balanceOf(address account, uint256 id) external view returns (uint256);
}

// Part: OpenZeppelin/[email protected]/Context

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

// Part: OpenZeppelin/[email protected]/Ownable

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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// Part: OpenZeppelin/[email protected]/Pausable

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
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
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
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
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
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

// File: Achievements.sol

contract Achievements is Ownable, Pausable {

  struct AchievementSettings_s {
    bool isRepeatable;
    bool isPaused;
    mapping (address => bool) isMinter;
  }

  mapping (address => mapping (uint256 => AchievementSettings_s)) public achievementSettingsForId;

  // Permission Modifiers
  modifier onlyIdMinter(address _token, uint256 _id) {
    require(achievementSettingsForId[_token][_id].isMinter[msg.sender] == true, "Revert: caller is not a valid minter");
    _;
  }

  modifier onlyUnpaused(address _token, uint256 _id) {
    require(paused() == false, "Revert: All minting is paused");
    require(achievementSettingsForId[_token][_id].isPaused == false, "Revert: This achievement ID is paused");
    _;
  }

  modifier checkRepeatable(address _token, address _account, uint256 _id) {
    if (!achievementSettingsForId[_token][_id].isRepeatable)
      require(IMintableERC1155(_token).balanceOf(_account, _id) == 0, "Can't mint this achievement for this account anymore.");
    _;
  }

  // One Tx setup for achievement ID
  function setAchievementSettingsForId(address _token, uint256 _id, bool _isRepeatable, bool _isPaused, address _newMinter) public onlyOwner {
    if (_isRepeatable)
      enableRepeatForId(_token, _id);
    if (_isPaused)
      pauseMintingForId(_token, _id);
    addMinterForId(_token, _newMinter, _id);
  }



  // Repeatable Achievement functions
  function enableRepeatForId(address _token, uint256 _id) public onlyOwner {
    achievementSettingsForId[_token][_id].isRepeatable = true;
  }

  function disableRepeatForId(address _token, uint256 _id) public onlyOwner {
    delete(achievementSettingsForId[_token][_id].isRepeatable);
  }


  // Pause functions
  function pauseAllMinting() public onlyOwner {
    _pause();
  }

  function unpauseAllMinting() public onlyOwner {
    _unpause();
  }

  function pauseMintingForMany(address _token, uint256[] memory _ids) public onlyOwner {
    for(uint256 i = 0; i < _ids.length; i++) {
      achievementSettingsForId[_token][_ids[i]].isPaused = true;
    }
  }

  function pauseMintingForId(address _token, uint256 _id) public onlyOwner {
    achievementSettingsForId[_token][_id].isPaused = true;
  }

  function unpauseMintingForId(address _token, uint256 _id) public onlyOwner {
    delete(achievementSettingsForId[_token][_id].isPaused);
  }


  // Achievement Minting Functions
  function mintAchievement(address _token, address _account, uint256 _id) public onlyIdMinter(_token, _id) onlyUnpaused(_token, _id) checkRepeatable(_token, _account, _id) {
    IMintableERC1155(_token).mint(_account, _id, 1);
  }

  function mintAchievementBatch(address _token, address[] memory _accounts, uint256 _id) public onlyIdMinter(_token, _id) onlyUnpaused(_token, _id) {
    if (achievementSettingsForId[_token][_id].isRepeatable) {
      for (uint256 i = 0; i < _accounts.length; i++) {
        IMintableERC1155(_token).mint(_accounts[i], _id, 1);
      }
    } else {
      for (uint256 i = 0; i < _accounts.length; i++) {
        require(IMintableERC1155(_token).balanceOf(_accounts[i], _id) == 0, "Can't have duplicate accounts for unrepeatable achievement.");
        IMintableERC1155(_token).mint(_accounts[i], _id, 1);
      }
    }
  }


  // Minter Address Functions
  function isMinterForId(address _token, address _minter, uint256 _id) public view returns (bool) {
    return achievementSettingsForId[_token][_id].isMinter[_minter];
  }

  function isMinterForIdsBatch(address _token, address _minter, uint256[] memory _ids) public view returns (bool[] memory) {
    bool[] memory resultArray = new bool[](_ids.length);
    for (uint256 i = 0; i < _ids.length; i++) {
      resultArray[i] = achievementSettingsForId[_token][_ids[i]].isMinter[_minter];
    }

    return resultArray;
  }

  function addMinterForId(address _token, address _newMinter, uint256 _id) public onlyOwner {
    require(_newMinter != address(0), "New minter can't be the null address");
    _addMinter(_token, _newMinter, _id);
  }

  function removeMinterForId(address _token, address _newMinter, uint256 _id) public onlyOwner {
    _removeMinter(_token, _newMinter, _id);
  }

  function _addMinter(address _token, address _newMinter, uint256 _id) private {
    achievementSettingsForId[_token][_id].isMinter[_newMinter] = true;
  }

  function _removeMinter(address _token, address _newMinter, uint256 _id) private {
    delete(achievementSettingsForId[_token][_id].isMinter[_newMinter]);
  }
}