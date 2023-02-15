// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./N2WToken.sol";

interface IN2WToken {
    function approve(address _spender, uint256 _amount) external returns (bool);

    function allowance(address _owner, address _spender) external returns (uint256);

    function transfer(address _to, uint256 _amount) external;

    function transferFrom(address _from, address _to, uint256 _amount) external;

    function balanceOf(address _account) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IN2WToken.sol";

contract N2WStaking {
    IN2WToken n2wToken;

    address public owner;

    uint256 public duration;
    uint256 public finishAt;
    uint256 public updatedAt;
    uint256 public rewardRate;
    uint256 public rewardPerTokenStored;

    // User address => rewardPerTokenStored
    mapping(address => uint256) userRewardPerTokenPaid;
    // User address => rewards to be claimed
    mapping(address => uint256) public rewards;

    //Total staked
    uint256 public totalSupply;

    // User address => staked amount
    mapping(address => uint256) public balanceOf;

    constructor(address _n2wTokenAddress) {
        owner = msg.sender;
        n2wToken = IN2WToken(_n2wTokenAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }

        _;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(finishAt, block.timestamp);
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;
    }

    function earned(address _account) public view returns (uint) {
        return
            ((balanceOf[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }

    function _min(uint256 x, uint256 y) private pure returns (uint) {
        return x <= y ? x : y;
    }

    function n2wStake(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "Staking amount must be more than 0");

        n2wToken.transferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
    }

    function withdraw(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        n2wToken.transfer(msg.sender, _amount);
    }

    function getReward() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            n2wToken.transfer(msg.sender, reward);
        }
    }

    function setRewardsDuration(uint256 _duration) external onlyOwner {
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
    }

    function notifyRewardAmount(
        uint256 _amount
    ) external onlyOwner updateReward(address(0)) {
        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint remainingRewards = (finishAt - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");
        require(
            rewardRate * duration <= n2wToken.balanceOf(address(this)),
            "reward amount > balance"
        );

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract N2WToken {
  using SafeMath for uint256;

  string public _name = "nice2win";
  string public _symbol = "n2w";
  uint256 public _totalSupply;
  uint8 public _decimals = 18;
  uint256 public mintingReductionInterval = 7776000; // 3 months would be approximately 3 * 30 * 24 * 60 * 60 = 7776000 seconds.
  uint256 public currentMintingRate = 100;
  uint256 public lastReductionTimestamp;

  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) public allowed;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Burn(address indexed burner, uint256 value);

  constructor ( uint256 initialSupply ) {
    _totalSupply = initialSupply * 10 ** uint256(_decimals);
    balances[msg.sender] = _totalSupply;
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function approve(address spender, uint256 amount) public returns (bool success) {
    require(amount > 0, "amount must be more than 0");
    allowed[msg.sender][spender] = amount;
    return true;
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return allowed[owner][spender];
  }

  function balanceOf(address account) public view returns (uint256) {
    return balances[account];
  }

  function transfer(address recipient, uint256 amount) public {
    require(recipient != address(0), "can't transfer to 0x0");
    require(amount > 0, "amount must be more than 0");
    require(balances[msg.sender] >= amount, "Not enough balance.");
    require(balances[recipient] + amount >= balances[recipient], "Overflow.");

    balances[msg.sender] = balances[msg.sender].sub(amount);
    balances[recipient] = balances[recipient].add(amount);

    emit Transfer(msg.sender, recipient, amount);
  }

  function transferFrom(address sender, address recipient, uint256 amount) public {
    require(recipient != address(0), "can't transfer to 0x0");
    require(amount > 0, "amount must be more than 0");
    require(balances[sender] >= amount, "Not enough balance.");
    require(balances[recipient] + amount >= balances[recipient], "Overflow.");
    require(allowed[sender][msg.sender] >= amount, "Not enough allowance.");

    balances[sender] = balances[sender].sub(amount);
    balances[recipient] = balances[msg.sender].add(amount);
    allowed[sender][msg.sender] = allowed[sender][msg.sender].sub(amount);

    emit Transfer(sender, recipient, amount);
  }

  function mint(address account, uint256 amount) public returns (bool success) {
    require(account != address(0));

    _totalSupply = _totalSupply.add(amount);
    balances[msg.sender] = balances[msg.sender].add(amount);

    emit Transfer(address(0), msg.sender, amount);

    return true;
  }

  // call burn function through the house edge reduction function LINE: 59
  function burn(uint256 amount) public returns (bool success) {
    require(balances[msg.sender] >= amount, "Not enough balance.");
    require(amount > 0, "amount must be more than 0");

    balances[msg.sender] = balances[msg.sender].sub(amount);
    _totalSupply = _totalSupply.sub(amount);

    emit Burn(msg.sender, amount);

    return true;
  }
}