//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './ISuperStaking.sol';

contract SuperStaking is ISuperToken {

  /* using SafeERC20 for IERC20; */

  /* SuperToken rewardTokens;
  IUniswapV2ERC20 lPTokens; */

  IERC20 rewardTokens;
  IERC20 lPTokens;

  uint public override reward_period_minutes;
  uint public override lock_period_minutes;
  uint256 public override reward_procents;

  /* UniswapV2Factory router; */

  struct Stake {
    uint256 stakeId;
    uint256 amount;
    uint claim_time;
    uint start_time;
  }

  struct Stake_account {
    Stake[] stakes;
    uint256 total_amount;
  }

  mapping(address => Stake_account) private stakeAccounts;

  /* event StakeDone (
      address indexed _from,
      uint256 _value
  );

  event Claim(
      address indexed _to,
      uint256 _value
  );

  event Unstake(
    address indexed _to,
    uint256 _value
  ); */

  constructor(address _uniswap_contract_address,
              address _erc20_reward_contract_address,
              uint _reward_period_minutes,
              uint _lock_period_minutes,
              uint256 _reward_procents
              ) {
    require(address(_uniswap_contract_address) != address(0),
    "Contract address can not be zero");
    require(address(_erc20_reward_contract_address) != address(0),
    "Contract address can not be zero");
    require(_reward_period_minutes != 0, "Reward period can not be zero");
    rewardTokens = IERC20(_erc20_reward_contract_address);
    lPTokens = IERC20(_uniswap_contract_address);
    reward_period_minutes = _reward_period_minutes;
    lock_period_minutes = _lock_period_minutes;
    reward_procents = _reward_procents;
  }

  function stake(uint256 _amount) public virtual override {
    require(lPTokens.balanceOf(msg.sender) >= _amount, "Not enaught tokens");
    address(lPTokens).delegatecall(abi.encodeWithSignature("transfer(address, uint256)", address(this), _amount));
    Stake_account storage sk = stakeAccounts[msg.sender];
    sk.total_amount += _amount;
    Stake memory st = Stake(
      {
        stakeId: sk.stakes.length,
        amount: _amount,
        start_time: block.timestamp,
        claim_time: block.timestamp
      }
    );
    sk.stakes.push(st);
    emit StakeDone(msg.sender, _amount);
  }

  function claim() public virtual override {
    uint _now_ = block.timestamp;
    uint256 total_reward;
    Stake_account storage sk = stakeAccounts[msg.sender];
    for (uint i = 0; i < sk.stakes.length; i++){
      uint reward_times = (_now_ - sk.stakes[i].claim_time) / (reward_period_minutes * 1 minutes);
      uint256 reward = sk.stakes[i].amount * reward_procents * reward_times / 100;
      total_reward += reward;
      sk.stakes[i].claim_time = _now_- (_now_ - sk.stakes[i].claim_time) % (reward_period_minutes * 1 minutes);
    }
    require(rewardTokens.balanceOf(address(this)) >= total_reward, "Sorry, but it is not enougth tokens on the contract");
    rewardTokens.transfer(msg.sender, total_reward);
    emit Claim(msg.sender, total_reward);
  }

  function claimOneStake(uint256 _stakeId) public virtual override {
    uint _now_ = block.timestamp;
    Stake_account storage sk = stakeAccounts[msg.sender];
    uint reward_times = (_now_ - sk.stakes[_stakeId].claim_time) / (reward_period_minutes * 1 minutes);
    uint256 reward = sk.stakes[_stakeId].amount * reward_procents * reward_times / 100;
    sk.stakes[_stakeId].claim_time = _now_- (_now_ - sk.stakes[_stakeId].claim_time) % (reward_period_minutes * 1 minutes);
    require(rewardTokens.balanceOf(address(this)) >= reward, "Sorry, but it is not enougth tokens on the contract");
    rewardTokens.transfer(msg.sender, reward);
    emit Claim(msg.sender, reward);
  }

  function unstake(uint256 _stakeId, uint256 _amount) public virtual override {
    uint _now_ = block.timestamp;
    Stake_account storage sk = stakeAccounts[msg.sender];
    require(_stakeId < sk.stakes.length, "Invalid ID of stake");
    require(_now_ >=  sk.stakes[_stakeId].start_time + lock_period_minutes * 1 minutes, "Its not time to unstake");
    require(sk.stakes[_stakeId].amount >= _amount, "Amount of tokens exceeds staked amount");
    claimOneStake(_stakeId);
    sk.stakes[_stakeId].amount -= _amount;
    address(lPTokens).call(abi.encodeWithSignature("transfer(address, uint256)", msg.sender, _amount));
    sk.total_amount -= _amount;
    emit Unstake(msg.sender, _amount);
  }

  function getStakerState() public view returns(uint256, Stake[] memory) {
    Stake_account storage sk = stakeAccounts[msg.sender];
    return(sk.total_amount, sk.stakes);
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

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.5.0;

interface ISuperToken {
  event StakeDone(address indexed _from, uint _value);
  event Claim(address indexed _to, uint _value);
  event Unstake(address indexed _to, uint _value);

  function reward_period_minutes() external view returns (uint);
  function lock_period_minutes() external view returns (uint);
  function reward_procents() external view returns (uint256);
  /* function getStakerState() external view returns (uint256, Stake[] memory); */

  /**
   * @dev Moves `_amount` lp tokens from the caller's account to this contract.
   *
   * Emits a {StakeDone} event.
   */
  function stake(uint256 _amount) external;

  /**
   * @dev Calculate rewards of each user's stake and transfer resulted amount
   * of tokens to user. In each stake's timestamp for reward estimation is updated.
   *
   * Emits a {Claim} event.
   */
  function claim() external;
  function claimOneStake(uint256 _stakeId) external;
  function unstake(uint256 _stakeId, uint256 _amount) external;
}