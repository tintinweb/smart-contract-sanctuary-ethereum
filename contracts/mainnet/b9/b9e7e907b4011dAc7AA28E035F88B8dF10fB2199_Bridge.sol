// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';

contract Bridge is Ownable {
  IERC20 _token = IERC20(0x30dcBa0405004cF124045793E1933C798Af9E66a);
  bool public isActive;
  uint256 public bridgeCost = 2 ether / 100;
  uint16 public sourceConfirmations = 30;

  struct Bridge {
    bytes32 id;
    bool isSource;
    uint256 sourceBlock;
    bool isComplete;
    address wallet;
    uint256 amount;
  }

  address[] _relays;
  mapping(address => uint256) _relaysIdx;

  mapping(bytes32 => Bridge) public sources;
  bytes32[] _incompleteSources;
  mapping(bytes32 => uint256) _incSourceIdx;

  mapping(bytes32 => Bridge) public receivers;
  bytes32[] _incompleteReceivers;
  mapping(bytes32 => uint256) _incReceiverIdx;
  mapping(bytes32 => address) public receiverIniter;
  mapping(bytes32 => address) public receiverSender;

  event Create(bytes32 indexed id, address wallet, uint256 amount);
  event InitDeliver(bytes32 indexed id, address wallet, uint256 amount);
  event Deliver(bytes32 indexed id, address wallet, uint256 amount);

  modifier onlyRelay() {
    bool _isValid;
    for (uint256 _i = 0; _i < _relays.length; _i++) {
      if (_relays[_i] == msg.sender) {
        _isValid = true;
        break;
      }
    }
    require(_isValid, 'Must be relay');
    _;
  }

  function getBridgeToken() external view returns (address) {
    return address(_token);
  }

  function getIncompleteSources() external view returns (bytes32[] memory) {
    return _incompleteSources;
  }

  function getIncompleteReceivers() external view returns (bytes32[] memory) {
    return _incompleteReceivers;
  }

  function setBridgeToken(address __token) external onlyOwner {
    _token = IERC20(__token);
  }

  function setIsActive(bool _isActive) external onlyOwner {
    isActive = _isActive;
  }

  function setBridgeCost(uint256 _wei) external onlyOwner {
    bridgeCost = _wei;
  }

  function setRelay(address _relay, bool _isRelay) external onlyOwner {
    uint256 _idx = _relaysIdx[_relay];
    if (_isRelay) {
      require(
        _relays.length == 0 || (_idx == 0 && _relays[_idx] != _relay),
        'Must enable'
      );
      _relaysIdx[_relay] = _relays.length;
      _relays.push(_relay);
    } else {
      require(_relays[_idx] == _relay, 'Must disable');
      delete _relaysIdx[_relay];
      _relaysIdx[_relays[_relays.length - 1]] = _idx;
      _relays[_idx] = _relays[_relays.length - 1];
      _relays.pop();
    }
  }

  function create(uint256 _amount) external payable {
    require(isActive, 'Bridge disabled');
    require(msg.value >= bridgeCost, 'Must pay bridge fee');

    _amount = _amount == 0 ? _token.balanceOf(msg.sender) : _amount;
    require(_amount > 0, 'Must bridge some tokens');

    bytes32 _id = sha256(abi.encodePacked(msg.sender, block.number, _amount));
    require(sources[_id].id == bytes32(0), 'Can only bridge once per block');

    _token.transferFrom(msg.sender, address(this), _amount);

    sources[_id] = Bridge({
      id: _id,
      isSource: true,
      sourceBlock: block.number,
      isComplete: false,
      wallet: msg.sender,
      amount: _amount
    });
    _incSourceIdx[_id] = _incompleteSources.length;
    _incompleteSources.push(_id);
    emit Create(_id, msg.sender, _amount);
  }

  function setSourceComplete(bytes32 _id) external onlyRelay {
    require(sources[_id].id != bytes32(0), 'Source does not exist');
    require(!sources[_id].isComplete, 'Source is already complete');
    sources[_id].isComplete = true;

    uint256 _sourceIdx = _incSourceIdx[_id];
    delete _incSourceIdx[_id];
    _incSourceIdx[
      _incompleteSources[_incompleteSources.length - 1]
    ] = _sourceIdx;
    _incompleteSources[_sourceIdx] = _incompleteSources[
      _incompleteSources.length - 1
    ];
    _incompleteSources.pop();
  }

  function initDeliver(
    bytes32 _id,
    address _user,
    uint256 _sourceBlock,
    uint256 _amount
  ) external onlyRelay {
    require(isActive, 'Bridge disabled');

    bytes32 _idCheck = sha256(abi.encodePacked(_user, _sourceBlock, _amount));
    require(_id == _idCheck, 'Not recognized');
    require(receiverIniter[_id] == address(0), 'Already initialized');

    receiverIniter[_id] = msg.sender;
    receivers[_id] = Bridge({
      id: _id,
      isSource: false,
      sourceBlock: _sourceBlock,
      isComplete: false,
      wallet: _user,
      amount: _amount
    });
    _incReceiverIdx[_id] = _incompleteReceivers.length;
    _incompleteReceivers.push(_id);
    emit InitDeliver(_id, receivers[_id].wallet, receivers[_id].amount);
  }

  function deliver(bytes32 _id) external onlyRelay {
    require(isActive, 'Bridge disabled');
    Bridge storage receiver = receivers[_id];
    require(receiver.id == _id && _id != bytes32(0), 'Invalid bridge txn');
    require(
      msg.sender != receiverIniter[_id],
      'Initer and sender must be different'
    );
    require(!receiver.isComplete, 'Already completed');

    receiverSender[_id] = msg.sender;
    receiver.isComplete = true;

    _token.transfer(receiver.wallet, receiver.amount);

    uint256 _recIdx = _incReceiverIdx[_id];
    delete _incReceiverIdx[_id];
    _incReceiverIdx[
      _incompleteReceivers[_incompleteReceivers.length - 1]
    ] = _recIdx;
    _incompleteReceivers[_recIdx] = _incompleteReceivers[
      _incompleteReceivers.length - 1
    ];
    _incompleteReceivers.pop();
    emit Deliver(_id, receiver.wallet, receiver.amount);
  }

  function setSourceConfirmations(uint16 _conf) external onlyOwner {
    sourceConfirmations = _conf;
  }

  function withdrawERC20(address _token, uint256 _amount) external onlyOwner {
    IERC20 _contract = IERC20(_token);
    _amount = _amount == 0 ? _contract.balanceOf(address(this)) : _amount;
    require(_amount > 0);
    _contract.transfer(owner(), _amount);
  }

  function withdrawETH() external onlyOwner {
    payable(owner()).call{ value: address(this).balance }('');
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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