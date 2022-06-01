pragma solidity 0.4.24;

import './SafeMath.sol';
import './Pausable.sol';
import './StakeContract.sol';

/* @title Staking Pool Contract
 * Open Zeppelin Pausable is Ownable.  contains address owner */
contract StakePool is Pausable {
  using SafeMath for uint;

  /** @dev address of staking contract
    * this variable is set at construction, and can be changed only by owner.*/
  address private stakeContract;
  /** @dev staking contract object to interact with staking mechanism.
    * this is a mock contract.  */
  StakeContract private sc;

  /** @dev track total staked amount */
  uint private totalStaked;
  /** @dev track total deposited to pool */
  uint private totalDeposited;

  /** @dev track balances of ether deposited to pool */
  mapping(address => uint) private depositedBalances;
  /** @dev track balances of ether staked */
  mapping(address => uint) private stakedBalances;
  /** @dev track user request to enter next staking period */
  mapping(address => uint) private requestStake;
  /** @dev track user request to exit current staking period */
  mapping(address => uint) private requestUnStake;

  /** @dev track users
    * users must be tracked in this array because mapping is not iterable */
  address[] private users;
  /** @dev track index by address added to users */
  mapping(address => uint) private userIndex;

  /** @dev notify when funds received from staking contract
    * @param sender       msg.sender for the transaction
    * @param amount       msg.value for the transaction
   */
  event NotifyFallback(address sender, uint amount);

  /** @dev notify that StakeContract address has been changed 
    * @param oldSC old address of the staking contract
    * @param newSC new address of the staking contract
   */
  event NotifyNewSC(address oldSC, address newSC);

  /** @dev trigger notification of deposits
    * @param sender  msg.sender for the transaction
    * @param amount  msg.value for the transaction
    * @param balance the users balance including this deposit
   */
  event NotifyDeposit(address sender, uint amount, uint balance);

  /** @dev trigger notification of staked amount
    * @param sender       msg.sender for the transaction
    * @param amount       msg.value for the transaction
    */
  event NotifyStaked(address sender, uint amount);

  /** @dev trigger notification of change in users staked balances
    * @param user            address of user
    * @param previousBalance users previous staked balance
    * @param newStakeBalence users new staked balance
    */
  event NotifyUpdate(address user, uint previousBalance, uint newStakeBalence);

  /** @dev trigger notification of withdrawal
    * @param sender   address of msg.sender
    * @param startBal users starting balance
    * @param finalBal users final balance after withdrawal
    * @param request  users requested withdraw amount
    */
  event NotifyWithdrawal(
    address sender,
    uint startBal,
    uint finalBal,
    uint request);

  /** @dev trigger notification of earnings to be split
    * @param earnings uint staking earnings for pool
    */
   event NotifyEarnings(uint earnings);


  /** @dev contract constructor
    * @param _stakeContract the address of the staking contract/mechanism
    */
  constructor(address _stakeContract) public {
    require(_stakeContract != address(0));
    stakeContract = _stakeContract;
    sc = StakeContract(stakeContract);
    // set owner to users[0] because unknown user will return 0 from userIndex
    // this also allows owners to withdraw their own earnings using same
    // functions as regular users
    users.push(owner);
  }

  /** @dev payable fallback
    * it is assumed that only funds received will be from stakeContract */
  function () external payable {
    emit NotifyFallback(msg.sender, msg.value);
  }

  /************************ USER MANAGEMENT **********************************/

  /** @dev test if user is in current user list
    * @param _user address of user to test if in list
    * @return true if user is on record, otherwise false
    */
  function isExistingUser(address _user) internal view returns (bool) {
    if ( userIndex[_user] == 0) {
      return false;
    }
    return true;
  }

  /** @dev remove a user from users array
    * @param _user address of user to remove from the list
    */
  function removeUser(address _user) internal {
    if (_user == owner ) return;
    uint index = userIndex[_user];
    // user is not last user
    if (index < users.length.sub(1)) {
      address lastUser = users[users.length.sub(1)];
      users[index] = lastUser;
      userIndex[lastUser] = index;
    }
    // this line removes last user
    users.length = users.length.sub(1);
  }

  /** @dev add a user to users array
    * @param _user address of user to add to the list
    */
  function addUser(address _user) internal {
    if (_user == owner ) return;
    if (isExistingUser(_user)) return;
    users.push(_user);
    // new user is currently last in users array
    userIndex[_user] = users.length.sub(1);
  }

  /************************ USER MANAGEMENT **********************************/

  /** @dev set staking contract address
    * @param _stakeContract new address to change staking contract / mechanism
    */
  function setStakeContract(address _stakeContract) external onlyOwner {
    require(_stakeContract != address(0));
    address oldSC = stakeContract;
    stakeContract = _stakeContract;
    sc = StakeContract(stakeContract);
    emit NotifyNewSC(oldSC, stakeContract);
  }

  /** @dev stake funds to stakeContract
    */
  function stake() external onlyOwner {
    // * update mappings
    // * send total balance to stakeContract
    uint toStake;
    for (uint i = 0; i < users.length; i++) {
      uint amount = requestStake[users[i]];
      toStake = toStake.add(amount);
      stakedBalances[users[i]] = stakedBalances[users[i]].add(amount);
      requestStake[users[i]] = 0;
    }

    // track total staked
    totalStaked = totalStaked.add(toStake);

    address(sc).transfer(toStake);

    emit NotifyStaked(msg.sender, toStake);
  }

  /** @dev unstake funds from stakeContract
    */
  function unstake() external onlyOwner {
    uint unStake;
    for (uint i = 0; i < users.length; i++) {
      uint amount = requestUnStake[users[i]];
      unStake = unStake.add(amount);
      stakedBalances[users[i]] = stakedBalances[users[i]].sub(amount);
      depositedBalances[users[i]] = depositedBalances[users[i]].add(amount);
      requestUnStake[users[i]] = 0;
    }

    // track total staked
    totalStaked = totalStaked.sub(unStake);

    sc.withdraw(unStake);

    emit NotifyStaked(msg.sender, -unStake);
  }

  /** @dev calculated new stakedBalances
    * @return true if calc is successful, otherwise false
    */
  function calcNewBalances() external onlyOwner {
    uint earnings = address(sc).balance.sub(totalStaked);
    emit NotifyEarnings(earnings);
    uint ownerProfit = earnings.div(100);
    earnings = earnings.sub(ownerProfit);

    if (totalStaked > 0 && earnings > 0) {
      for (uint i = 0; i < users.length; i++) {
        uint currentBalance = stakedBalances[users[i]];
        stakedBalances[users[i]] =
          currentBalance.add(
            earnings.mul(currentBalance).div(totalStaked)
          );
        emit NotifyUpdate(users[i], currentBalance, stakedBalances[users[i]]);
      }
      uint ownerBalancePrior = stakedBalances[owner];
      stakedBalances[owner] = stakedBalances[owner].add(ownerProfit);
      emit NotifyUpdate(owner, ownerBalancePrior, stakedBalances[owner]);
      totalStaked = address(sc).balance;
    }
  }

  /** @dev deposit funds to the contract
    */
  function deposit() external payable whenNotPaused {
    depositedBalances[msg.sender] = depositedBalances[msg.sender].add(msg.value);
    emit NotifyDeposit(msg.sender, msg.value, depositedBalances[msg.sender]);
  }

  /** @dev withdrawal funds out of pool
    * @param wdValue amount to withdraw
    */
  function withdraw(uint wdValue) external whenNotPaused {
    require(wdValue > 0);
    require(depositedBalances[msg.sender] >= wdValue);
    uint startBalance = depositedBalances[msg.sender];
    depositedBalances[msg.sender] = depositedBalances[msg.sender].sub(wdValue);
    checkIfUserIsLeaving(msg.sender);

    msg.sender.transfer(wdValue);

    emit NotifyWithdrawal(
      msg.sender,
      startBalance,
      depositedBalances[msg.sender],
      wdValue
    );
  }

  /** @dev if user has no deposit and no staked funds they are leaving the 
    * pool.  Remove them from user list.
    * @param _user address of user to check
    */
  function checkIfUserIsLeaving(address _user) internal {
    if (depositedBalances[_user] == 0 && stakedBalances[_user] == 0) {
      removeUser(_user);
    }
  }

  /** @dev user can request to enter next staking period */
  function requestNextStakingPeriod() external whenNotPaused {
    require(depositedBalances[msg.sender] > 0);

    addUser(msg.sender);
    uint amount = depositedBalances[msg.sender];
    depositedBalances[msg.sender] = 0;
    requestStake[msg.sender] = requestStake[msg.sender].add(amount);
    emit NotifyStaked(msg.sender, requestStake[msg.sender]);
  }

  /** @dev user can request to exit at end of current staking period
    * @param amount requested amount to withdraw from staking contract
   */
  function requestExitAtEndOfCurrentStakingPeriod(uint amount) external whenNotPaused {
    require(stakedBalances[msg.sender] >= amount);
    requestUnStake[msg.sender] = requestUnStake[msg.sender].add(amount);
    emit NotifyStaked(msg.sender, requestUnStake[msg.sender]);
  }

  /** @dev retreive current state of users funds
    * @return array of values describing the current state of user
   */
  function getState() external view returns (uint[]) {
    uint[] memory state = new uint[](4);
    state[0] = depositedBalances[msg.sender];
    state[1] = requestStake[msg.sender];
    state[2] = requestUnStake[msg.sender];
    state[3] = stakedBalances[msg.sender];
    return state;
  }
}