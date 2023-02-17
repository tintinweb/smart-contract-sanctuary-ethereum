/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
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

enum States {
  Soon,
  Open,
  End,
  Claim
}

contract IDO is Ownable {
  struct IDOUser {
    bool achievedGoal;
    bool claimed;
    uint256 downlinesBuyAmount;
    uint256 rebate;
    uint256 downlinesAchieveGoalCount;
    uint256 balance;
    address[5] uplines;
    address[] downlines;
  }

  States public currentIdoState;

  IERC20 public ETH;
  IERC20 public launchedToken;

  mapping(address => IDOUser) private IDOUsers;

  uint256 private constant MAX_UINT = type(uint256).max;
  uint256 public constant MIN_BUY_AMOUNT = 0.001*(10**18);
  uint256 public claimRatio;
  uint256 public totalSoldAmount = 0;
  uint256 public denominator = 1000;

  address public defaultUpline;

  event Buy(address buyer, uint256 amount);
  event Claim(address claimer, uint256 amount);

  modifier inState(States _state) {
    require(currentIdoState == _state, 'IDO: wrong state');
    _;
  }


    constructor() {
        ETH = IERC20(0xD55DB0299D15ABf4105B848CC704B991021f5499);
        currentIdoState = States.Soon;
        defaultUpline = owner();
    }

  function buy(
    uint256 amount,
    address uplineToBeSet
  ) external inState(States.Open) {
    require(amount >= MIN_BUY_AMOUNT, 'IDO: amount should be greater than 10');

    address _uplineToBeSet = uplineToBeSet;

    if (uplineToBeSet == msg.sender) _uplineToBeSet = address(0);

    if (IDOUsers[msg.sender].downlinesAchieveGoalCount >= 10) {
      require(
        IDOUsers[msg.sender].balance + amount <= 300 ether,
        'IDO: you can not buy more than 300'
      );
    } else {
      require(
        IDOUsers[msg.sender].balance + amount <= 100 ether,
        'IDO: you can not buy more than 100'
      );
    }


    bool paySuccess = ETH.transferFrom(msg.sender, address(this), amount);
    require(paySuccess, 'IDO: pay failed');

    totalSoldAmount += amount;
    IDOUsers[msg.sender].balance += amount;

    // if not linked and want to link
    if (
      IDOUsers[msg.sender].uplines[0] == address(0) &&
      _uplineToBeSet != address(0)
    ) {
      IDOUsers[_uplineToBeSet].downlines.push(msg.sender);
      IDOUsers[msg.sender].uplines[0] = _uplineToBeSet;

      for (uint i = 0; i < 4; i++) {
        if (IDOUsers[_uplineToBeSet].uplines[i] == address(0)) break;

        IDOUsers[msg.sender].uplines[i + 1] = IDOUsers[_uplineToBeSet].uplines[
          i
        ];
      }
    }

    // if not linked and do not want to link
    if (
      IDOUsers[msg.sender].uplines[0] == address(0) &&
      _uplineToBeSet == address(0)
    ) {
      IDOUsers[defaultUpline].downlines.push(msg.sender);
      IDOUsers[msg.sender].uplines[0] = defaultUpline;

      for (uint i = 0; i < 4; i++) {
        if (IDOUsers[defaultUpline].uplines[i] == address(0)) break;

        IDOUsers[msg.sender].uplines[i + 1] = IDOUsers[defaultUpline].uplines[
          i
        ];
      }
    }

    // if linked, send ref reward
    if (IDOUsers[msg.sender].uplines[0] != address(0)) {
      uint256[5] memory refRewardRatio = [uint256(30), 20, 10, 10, 10];

      for (uint i = 0; i < 5; i++) {
        if (IDOUsers[msg.sender].uplines[i] == address(0)) break;

        address upline = IDOUsers[msg.sender].uplines[i];

        uint256 refReward = ((amount * refRewardRatio[i]) / denominator); // (amount * 30) / 1000
        bool payRefReward = ETH.transfer(upline, refReward);
        require(payRefReward, 'IDO: pay reward failed');

        IDOUsers[upline].rebate += refReward;
      }
    }

    if (
      !(IDOUsers[msg.sender].achievedGoal) &&
      IDOUsers[msg.sender].balance >= 100 ether
    ) {
      for (uint i = 0; i < 5; i++) {
        if (IDOUsers[msg.sender].uplines[i] == address(0)) break;

        address upline = IDOUsers[msg.sender].uplines[i];
        IDOUsers[upline].downlinesAchieveGoalCount += 1;
        IDOUsers[upline].downlinesBuyAmount += amount;
      }

      IDOUsers[msg.sender].achievedGoal = true;
    }

    emit Buy(msg.sender, amount);
  }

  function claim() external inState(States.Claim) {
    require(
      IDOUsers[msg.sender].balance > 0,
      'IDO: you do not have any balance'
    );
    require(!IDOUsers[msg.sender].claimed, 'IDO: you have already claimed');

    uint256 claimAmount = (IDOUsers[msg.sender].balance * claimRatio) /
      (10 ** 18);
    IDOUsers[msg.sender].balance = 0;
    IDOUsers[msg.sender].claimed = true;

    bool claimSuccess = launchedToken.transfer(msg.sender, claimAmount);
    require(claimSuccess, 'IDO: token transfer failed');

    emit Claim(msg.sender, claimAmount);
  }

  function withdrawTokens(
    address tokenAddress,
    uint256 amount
  ) external onlyOwner {
    bool success = IERC20(tokenAddress).transfer(owner(), amount);
    require(success, 'IDO: transfer failed');
  }

  function setLaunchedToken(address _launchedTokenAddress) external onlyOwner {
    launchedToken = IERC20(_launchedTokenAddress);
  }

  function setDenominator(uint _denominator) external onlyOwner {
    require(_denominator > 0, 'IDO: denominator can not be less than 1');
    denominator = _denominator;
  }

  function setDefaultUpline(address _defaultUpline) external onlyOwner {
    require(_defaultUpline != address(0), 'IDO: defaultUpline can not be 0');
    defaultUpline = _defaultUpline;
  }

  function setState(States _state) public onlyOwner {
    require(currentIdoState != _state, 'IDO: can not set to the same state');
    if (_state == States.End) {
      require(totalSoldAmount > 0, 'IDO: nothing sold');
      claimRatio = ((29850000) * (10 ** 18)) / totalSoldAmount;
    }

    currentIdoState = _state;
  }

  function getIDOUserInfo(address addr) public view returns (IDOUser memory) {
    IDOUser memory user = IDOUsers[addr];
    return user;
  }
}