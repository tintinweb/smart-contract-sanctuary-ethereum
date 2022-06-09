/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

pragma solidity ^0.8.0;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
 
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
 
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
 
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
 
contract Ownable {
  address public owner;
 
 
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
 
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    owner = msg.sender;
  }
 
 
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
 
 
  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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

contract Crowfund is Ownable {
    struct Activity {
        uint256 target;
        uint256 fund;
        uint32  startAt;
        uint32  endAt;
        address last;
        bool    finish;
        bool    close;
    }

    using SafeMath for uint256;
    IERC20 public immutable tokenReward;
    IERC20 public immutable tokenAccept;
    uint  public  period;
    uint256 public price;
    mapping(uint => Activity) public activities;
    mapping(uint => mapping(address => uint256)) public raiseAmount;

    event StartCrowfundEvent(uint period, address indexed owner, uint256 target, uint32 startAt, uint32 endAt);
    event CancelCrowfundEvent(uint period);
    event EndCrowfundEvent(uint period);
    event IncreaseAmountEvent(uint indexed period, address indexed owner, uint256 amount);

    constructor(address _tokenAccept, address _tokenReward, uint256 _price) {
        tokenReward = IERC20(_tokenReward);
        tokenAccept = IERC20(_tokenAccept);
        price = _price;
    }

    function GetBalance(address _token) external view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function WithDraw(address _token) external onlyOwner {
        IERC20(_token).transfer(msg.sender, this.GetBalance(_token));
    }
    
    function StartCrowfund(uint256 _target, uint32 _startAt, uint32 _endAt) external onlyOwner {
        require(_startAt >= block.timestamp, "start < now");
        require(_endAt > _startAt, " end < start");

        period += 1;
        activities[period] = Activity({
            target : _target,
            fund : 0,
            startAt : _startAt,
            endAt : _endAt,
            last: address(0x0),
            finish : false, 
            close : false
        });

        emit StartCrowfundEvent(period, msg.sender, _target, _startAt, _endAt);
    } 

    function CancelCrowfund(uint _period) external onlyOwner {
        Activity  memory activity = activities[_period];
        require(block.timestamp < activity.startAt, "started");
        delete activities[_period];

        emit CancelCrowfundEvent(_period);
    }

    function IncreaseAmount(address from, uint256 _amount) external onlyOwner {
        Activity  storage activity = activities[period];
        require(block.timestamp >= activity.startAt , "not started");
        require(block.timestamp <= activity.endAt, "ended");
        require(activity.target > 0, "invalid");
        require(!activity.finish, "finished");
        require(!activity.close, "closed");
        activity.fund += _amount;
        activity.last = from;
        uint256 overFund = 0;
        if(activity.fund >= activity.target) {
            activity.finish = true;
            overFund = activity.fund.sub(activity.target);
        }
        raiseAmount[period][from] += _amount;
        tokenReward.transfer(from, (_amount.sub(overFund)).mul(price));

        emit IncreaseAmountEvent(period, from, _amount);
    }

    function EndCrowfund() external onlyOwner {
        Activity  storage activity = activities[period];
        require(!activity.close, "closed");

        if(activity.target < activity.fund) {
            uint256 overFund = activity.fund.sub(activity.target);
            if(tokenAccept.transfer(activity.last, overFund)) {
                raiseAmount[period][activity.last] -= overFund;
                activity.fund = activity.target;
            }

        }
        activity.close = true;
        tokenAccept.transfer(msg.sender, activity.fund);

        emit EndCrowfundEvent(period);
    }
}