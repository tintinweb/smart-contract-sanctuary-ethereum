// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract APIKeyManager is Ownable, ReentrancyGuard {

  /****************************************
   * Structs
   ****************************************/
  struct KeyDef {
    uint256 startTime;  // ms
    uint256 expiryTime; // ms
    address owner;
    uint64 tierId;
  }

  struct Tier {
    uint256 price; // price per millisecond
    bool active;
  }
  
  /****************************************
   * ERC20 Token
   ****************************************
   * This is the address for the token that 
   * will be accepted for key payment.
   ****************************************/
  IERC20 public erc20;

  /****************************************
   * Key Tiers
   ****************************************
   * Tier Definition mapping
   ****************************************/
  mapping(uint64 => Tier) tier;

  /****************************************
   * Tier index tracker
   ****************************************/
  uint64 currentTierId = 0;

  /****************************************
   * Key Hash Map
   ****************************************
   * Maps the API key hashes to their key
   * definitions.
   ****************************************/
  mapping(bytes32 => KeyDef) keyDef;

  /****************************************
   * Owner key count map
   ****************************************
   * Maps an owner address to number of
   * keys owned.
   ****************************************/
  mapping(address => uint256) keyCount;

  /****************************************
   * Key Id Map
   ****************************************
   * Maps the Key ID to the key hash.
   ****************************************/
  mapping(uint256 => bytes32) keyHash;

  /****************************************
   * Current Key Id
   ****************************************/
  uint256 currentKeyId = 0;

  /****************************************
   * Last Admin Withdrawal Timestamp
   ****************************************
   * Used to prevent double withdrawals of
   * user funds.
   ****************************************/
  uint256 public lastWithdrawal;

  /****************************************
   * Constructor
   ****************************************/
  constructor(
    IERC20 _erc20
  ) Ownable() ReentrancyGuard() {
    erc20 = _erc20;
  }

  /****************************************
   * Modifiers
   ****************************************/
  modifier _keyExists(bytes32 _keyHash) {
    require(keyExists(_keyHash), "APIKeyManager: key does not exist");
    _;
  }

  modifier _tierExists(uint64 _tierId) {
    require(_tierId < currentTierId, "APIKeyManager: tier does not exist");
    _;
  }

  /****************************************
   * Internal Functions
   ****************************************/
  function usedBalance(bytes32 _keyHash) internal view virtual _keyExists(_keyHash) returns(uint256) {
    uint256 _startTime = keyDef[_keyHash].startTime;
    uint256 _endTime = keyDef[_keyHash].expiryTime;

    // Ensure that we don't consider time previous to last withdrawal to prevent double claims:
    if(lastWithdrawal > _startTime) {
      _startTime = lastWithdrawal;
    }

    // Return zero if key end time is less or equal to start time:
    if(_endTime <= _startTime) {
      return 0;
    }

    // Calculate used balance from start:
    uint256 _usedTime = _endTime - _startTime;
    uint256 _usedBalance = _usedTime * tierPrice(keyDef[_keyHash].tierId);
    return _usedBalance;
  }

  function acceptPayment(uint256 _amount) internal {
    uint256 _allowance = IERC20(erc20).allowance(_msgSender(), address(this));
    require(_allowance >= _amount, "APIKeyManager: low token allowance");
    IERC20(erc20).transferFrom(_msgSender(), address(this), _amount);
  }

  /****************************************
   * Public Functions
   ****************************************/
  function isTierActive(uint64 _tierId) public view virtual _tierExists(_tierId) returns(bool) {
    return tier[_tierId].active;
  }

  function tierPrice(uint64 _tierId) public view virtual _tierExists(_tierId) returns(uint256) {
    return tier[_tierId].price;
  }
  
  function numTiers() public view virtual returns(uint64) {
    return currentTierId;
  }

  function numKeys() public view virtual returns(uint256) {
    return currentKeyId;
  }

  function keyExists(bytes32 _keyHash) public view virtual returns(bool) {
    return keyDef[_keyHash].owner != address(0);
  }

  function isKeyActive(bytes32 _keyHash) public view virtual _keyExists(_keyHash) returns(bool) {
    return keyDef[_keyHash].expiryTime > block.timestamp;
  }

  function remainingBalance(bytes32 _keyHash) public view virtual _keyExists(_keyHash) returns(uint256) {
    if(!isKeyActive(_keyHash)) {
      return 0;
    } else {
      uint256 _remainingTime = keyDef[_keyHash].expiryTime - block.timestamp;
      return _remainingTime * tierPrice(keyDef[_keyHash].tierId);
    }
  }

  function expiryOf(bytes32 _keyHash) public view virtual _keyExists(_keyHash) returns(uint256) {
    return keyDef[_keyHash].expiryTime;
  }

  function ownerOf(bytes32 _keyHash) public view virtual _keyExists(_keyHash) returns(address) {
    address owner = keyDef[_keyHash].owner;
    require(owner != address(0), "APIKeyManager: invalid key hash");
    return owner;
  }

  function numKeysOf(address owner) public view virtual returns(uint256) {
    uint256 _count = 0;
    uint256 _numKeys = numKeys();
    for(uint256 _id = 0; _id < _numKeys; _id++) {
      if(ownerOf(keyHash[_id]) == owner) {
        _count++;
      }
    }
    return _count;
  }

  function availableWithdrawal() public view virtual returns(uint256) {
    uint256 _numKeys = numKeys();
    uint256 _availableBalance = 0;
    for(uint256 _id = 0; _id < _numKeys; _id++) {
      _availableBalance += usedBalance(keyHash[_id]);
    }
    return _availableBalance;
  }

  /****************************************
   * External Functions
   ****************************************/

  function tierIdOf(bytes32 _keyHash) external view virtual _keyExists(_keyHash) returns(uint64) {
    return keyDef[_keyHash].tierId;
  }
  
  function keysOf(address owner) external view virtual returns(bytes32[] memory) {
    uint256 _numKeys = numKeys();
    uint256 _ownerKeyCount = numKeysOf(owner);
    bytes32[] memory _keyHashes = new bytes32[](_ownerKeyCount);
    uint256 _index = 0;
    for(uint256 _id = 0; _id < _numKeys; _id++) {
      if(ownerOf(keyHash[_id]) == owner) {
        _keyHashes[_index] = keyHash[_id];
        _index++;
      }
    }
    return _keyHashes;
  }

  function activateKey(bytes32 _keyHash, uint256 _msDuration, uint64 _tierId) external nonReentrant() {
    require(!keyExists(_keyHash), "APIKeyManager: key exists");
    require(isTierActive(_tierId), "APIKeyManager: inactive tier");

    // Get target tier price:
    uint256 _tierPrice = tierPrice(_tierId);

    // Accept erc20 payment for _tierPrice * _msDuration:
    uint256 _amount = _tierPrice * _msDuration;
    if(_amount > 0) {
      acceptPayment(_amount);
    }

    // Initialize Key:
    keyDef[_keyHash].expiryTime = block.timestamp + _msDuration;
    keyDef[_keyHash].startTime = block.timestamp;
    keyDef[_keyHash].tierId = _tierId;
    keyDef[_keyHash].owner = _msgSender();
    keyCount[_msgSender()]++;
  }

  function extendKey(bytes32 _keyHash, uint256 _msDuration) external _keyExists(_keyHash) nonReentrant() {
    require(ownerOf(_keyHash) == _msgSender(), "APIKeyManager: not owner");
    uint64 _tierId = keyDef[_keyHash].tierId;
    require(isTierActive(_tierId), "APIKeyManager: inactive tier");

    // Get target tier price:
    uint256 _tierPrice = tierPrice(_tierId);

    // Accept erc20 payment for _tierPrice * _msDuration:
    uint256 _amount = _tierPrice * _msDuration;
    if(_amount > 0) {
      acceptPayment(_amount);
    }

    // Extend the expiry time:
    if(isKeyActive(_keyHash)) {
      keyDef[_keyHash].expiryTime += _msDuration;
    } else {
      keyDef[_keyHash].expiryTime = block.timestamp + _msDuration;
    }
  }

  function deactivateKey(bytes32 _keyHash) external _keyExists(_keyHash) nonReentrant() {
    require(ownerOf(_keyHash) == _msgSender(), "APIKeyManager: not owner");
    uint256 _remainingBalance = remainingBalance(_keyHash);
    require(_remainingBalance > 0, "APIKeyManager: no balance");

    // Expire key:
    keyDef[_keyHash].expiryTime = block.timestamp;

    // Send erc20 payment to owner:
    IERC20(erc20).transfer(_msgSender(), _remainingBalance);
  }

  function addTier(uint256 _price) external onlyOwner {
    tier[currentTierId].price = _price;
    tier[currentTierId].active = true;
    currentTierId++;
  }

  function archiveTier(uint64 _tierId) external onlyOwner _tierExists(_tierId) {
    tier[_tierId].active = false;
  }

  function withdraw() external nonReentrant() onlyOwner {
    uint256 _balance = availableWithdrawal();
    lastWithdrawal = block.timestamp;
    IERC20(erc20).transfer(owner(), _balance);
  }

  function transfer(bytes32 _keyHash, address _to) external _keyExists(_keyHash) nonReentrant() {
    require(ownerOf(_keyHash) == _msgSender(), "APIKeyManager: not owner");
    keyCount[ownerOf(_keyHash)]--;
    keyCount[_to]++;
    keyDef[_keyHash].owner = _to;
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