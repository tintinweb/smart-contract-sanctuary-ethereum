// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract PondToken {

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    string public constant name = "Pond";
    string public constant symbol = "POND";
    uint8 public constant decimals = 18;

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_;

    constructor(uint256 total) {
      totalSupply_ = total;
      balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public view returns (uint256) {
      return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] -= numTokens;
        balances[receiver] += numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] -= numTokens;
        allowed[owner][msg.sender] -= numTokens;
        balances[buyer] += numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}

contract PondFarming is Ownable {
  string public name = "Pond Farm";
  uint public apy;
  PondToken public pondToken;
  // address public rewardAddress;
  address[] public stakers;
  mapping(address => uint) public stakingBalance;
  mapping(address => uint) public stakingTime;
  mapping(address => bool) public hasStaked;

  constructor(PondToken _pondToken) {
    pondToken = _pondToken;
    // rewardAddress = msg.sender;
    apy = 10000;
  }

  //1. get staked amount and reward amount
  function getRewardTokens() public view returns(uint, uint){
    uint balance = stakingBalance[msg.sender];
    if (balance == 0){
      return (0, 0);
    }
    uint lastTime = stakingTime[msg.sender];
    uint reward = balance * (block.timestamp - lastTime) * apy/100 / 365 days;
    return (balance, reward);
  }

  //2. Stake Tokens (Deposit)
  function stakeTokens(uint _amount) public {
    require(_amount > 0, "amount cannot be 0");
    pondToken.transferFrom(msg.sender, address(this), _amount);
    uint balance;
    uint reward;
    (balance, reward) = getRewardTokens();
    pondToken.transfer(msg.sender, reward);

    //Update Staking Balance and Time
    stakingBalance[msg.sender] = balance + _amount;
    stakingTime[msg.sender] = block.timestamp;

    //Add user to stakers array if they haven't staked already.
    if(!hasStaked[msg.sender]) {
      stakers.push(msg.sender);
    }

    //Update a users' staking flag
    hasStaked[msg.sender] = true;
  }

  //3. Issuing Tokens
  function issueTokens() public onlyOwner {
    for(uint i=0; i<stakers.length; i++) {
      address recipient = stakers[i];
      uint balance = stakingBalance[recipient];
      if(balance > 0) {
        // staked token transfer 
        // pondToken.transfer(recipient, balance);
        uint lastTime = stakingTime[recipient];
        uint reward = balance * (block.timestamp - lastTime) * apy/100 / 365 days;
        // reward token transfer
        pondToken.transfer(recipient, balance + reward);
        stakingBalance[recipient] = 0;
        hasStaked[recipient] = false;
      }
    }
  }

  //4. Un-Stake Tokens (Withdraw)
  //Users unstake their tokens and get reward tokens too.
  function unstakeTokens() public {
    uint balance; uint reward;
    (balance, reward) = getRewardTokens();
    require(balance > 0, "Staking Balance cannot be 0.");
    pondToken.transfer(msg.sender, balance + reward);
    // pondToken.transferFrom(rewardAddress, msg.sender, reward);
    stakingBalance[msg.sender] = 0;
    hasStaked[msg.sender] = false;
  }

  //5. owner set reward address
  // function setRewardAddress(address _addr) public {
  //   require(msg.sender == owner, "not owner");
  //   require(_addr != address(0), "invalid address");
  //   rewardAddress = _addr;
  // }

  //6. owner set apy
  function setAPY(uint _apy) public onlyOwner {
    apy = _apy;
  }

  //7. Update staking amount
  function updateStakingAmount(address stakingAddress, uint updateAmount, bool updateFlag) public onlyOwner {
    uint userBalance = stakingBalance[stakingAddress];
    uint newBalance = 0;

    require(userBalance > 0, "No staking balance");

    if (updateFlag) {
      // Plus Staking Balance
      newBalance = userBalance + updateAmount;
    } else {
      // Minus Staking Balance
      newBalance = userBalance >= updateAmount ? userBalance - updateAmount : 0;        
    }
    stakingBalance[stakingAddress] = newBalance;
  }
}