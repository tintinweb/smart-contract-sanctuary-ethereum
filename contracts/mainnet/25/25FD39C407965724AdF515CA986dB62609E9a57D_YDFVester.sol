/******************************************************************************************************
Yieldification Vesting Contract

Website: https://yieldification.com
Twitter: https://twitter.com/yieldification
Telegram: https://t.me/yieldification
******************************************************************************************************/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IYDF.sol';

contract YDFVester is Ownable {
  IYDF private _ydf;

  uint256 public fullyVestedPeriod = 90 days;
  uint256 public withdrawsPerPeriod = 10;

  struct TokenVest {
    uint256 start;
    uint256 end;
    uint256 totalWithdraws;
    uint256 withdrawsCompleted;
    uint256 amount;
  }
  mapping(address => TokenVest[]) public vests;
  address[] public stakeContracts;

  event CreateVest(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 index, uint256 amountWithdrawn);

  modifier onlyStake() {
    bool isStake;
    for (uint256 i = 0; i < stakeContracts.length; i++) {
      if (msg.sender == stakeContracts[i]) {
        isStake = true;
        break;
      }
    }
    require(isStake, 'not a staking contract');
    _;
  }

  constructor(address _token) {
    _ydf = IYDF(_token);
  }

  // we expect the staking contract (re: the owner) to transfer tokens to
  // this contract, so no need to transferFrom anywhere
  function createVest(address _user, uint256 _amount) external onlyStake {
    vests[_user].push(
      TokenVest({
        start: block.timestamp,
        end: block.timestamp + fullyVestedPeriod,
        totalWithdraws: withdrawsPerPeriod,
        withdrawsCompleted: 0,
        amount: _amount
      })
    );
    emit CreateVest(_user, _amount);
  }

  function withdraw(uint256 _index) external {
    address _user = msg.sender;
    TokenVest storage _vest = vests[_user][_index];
    require(_vest.amount > 0, 'vest does not exist');
    require(
      _vest.withdrawsCompleted < _vest.totalWithdraws,
      'already withdrew all tokens'
    );

    uint256 _tokensPerWithdrawPeriod = _vest.amount / _vest.totalWithdraws;
    uint256 _withdrawsAllowed = getWithdrawsAllowed(_user, _index);

    // make sure the calculated allowed amount doesn't exceed total amount for vest
    _withdrawsAllowed = _withdrawsAllowed > _vest.totalWithdraws
      ? _vest.totalWithdraws
      : _withdrawsAllowed;

    require(
      _vest.withdrawsCompleted < _withdrawsAllowed,
      'currently vesting, please wait for next withdrawable time period'
    );

    uint256 _withdrawsToComplete = _withdrawsAllowed - _vest.withdrawsCompleted;

    _vest.withdrawsCompleted = _withdrawsAllowed;
    _ydf.transfer(_user, _tokensPerWithdrawPeriod * _withdrawsToComplete);
    _ydf.addToBuyTracker(
      _user,
      _tokensPerWithdrawPeriod * _withdrawsToComplete
    );

    // clean up/remove vest entry if it's completed
    if (_vest.withdrawsCompleted == _vest.totalWithdraws) {
      vests[_user][_index] = vests[_user][vests[_user].length - 1];
      vests[_user].pop();
    }

    emit Withdraw(
      _user,
      _index,
      _tokensPerWithdrawPeriod * _withdrawsToComplete
    );
  }

  function getWithdrawsAllowed(address _user, uint256 _index)
    public
    view
    returns (uint256)
  {
    TokenVest memory _vest = vests[_user][_index];
    uint256 _secondsPerWithdrawPeriod = (_vest.end - _vest.start) /
      _vest.totalWithdraws;
    return (block.timestamp - _vest.start) / _secondsPerWithdrawPeriod;
  }

  function getUserVests(address _user)
    external
    view
    returns (TokenVest[] memory)
  {
    return vests[_user];
  }

  function getYDF() external view returns (address) {
    return address(_ydf);
  }

  function addStakingContract(address _contract) external onlyOwner {
    stakeContracts.push(_contract);
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
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/interfaces/IERC20.sol';

/**
 * @dev YDF token interface
 */

interface IYDF is IERC20 {
  function addToBuyTracker(address _user, uint256 _amount) external;

  function burn(uint256 _amount) external;

  function stakeMintToVester(uint256 _amount) external;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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