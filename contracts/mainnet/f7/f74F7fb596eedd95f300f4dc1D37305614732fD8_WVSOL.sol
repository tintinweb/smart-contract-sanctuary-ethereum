/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Stakeable {

    constructor() { }

    function initStakeable() internal {
        stakeholders.push();
        rewardPerHour = 36500;
    }

    struct Stake{
        address user;
        uint256 amount;
        uint256 since;
        uint256 claimable;
    }
  
    struct Stakeholder{
        address user;
        Stake[] address_stakes;
        
    }

     struct StakingSummary{
         uint256 total_amount;
         Stake[] stakes;
     }

    Stakeholder[] internal stakeholders;

    mapping(address => uint256) internal stakes;

    event Staked(address indexed user, uint256 amount, uint256 index, uint256 timestamp);

    uint256 internal rewardPerHour;

    function _addStakeholder(address staker) internal returns (uint256){
        stakeholders.push();
        uint256 userIndex = stakeholders.length - 1;
        stakeholders[userIndex].user = staker;
        stakes[staker] = userIndex;
        return userIndex; 
    }

    function _stake(uint256 _amount) internal {
        require(_amount > 0, "Cannot stake nothing");
        
        uint256 index = stakes[msg.sender];
        uint256 timestamp = block.timestamp;
        if(index == 0){
            index = _addStakeholder(msg.sender);
        }

        stakeholders[index].address_stakes.push(Stake(msg.sender, _amount, timestamp,0));
        emit Staked(msg.sender, _amount, index,timestamp);
    }

    function calculateStakeReward(Stake memory _current_stake) internal view returns(uint256){
      uint256 stakeTime = block.timestamp - _current_stake.since;
      if (stakeTime < 1 days) {
        return 0;
      }
      return (((stakeTime) / 1 hours) * _current_stake.amount) / rewardPerHour;
    }

    function _withdrawStake(uint256 amount, uint256 index) internal returns(uint256, uint256, uint256){
      uint256 user_index = stakes[msg.sender];
      Stake memory current_stake = stakeholders[user_index].address_stakes[index];
      require(current_stake.amount >= amount, "Staking: Cannot withdraw more than you have staked");

      uint256 reward = calculateStakeReward(current_stake);
      current_stake.amount = current_stake.amount - amount;
      if(current_stake.amount == 0){
          delete stakeholders[user_index].address_stakes[index];
      } else {
        stakeholders[user_index].address_stakes[index].amount = current_stake.amount;
        stakeholders[user_index].address_stakes[index].since = block.timestamp;    
      }
      uint256 devReward = ( reward * 5 ) / 100; 
      reward -= devReward;
      return (amount, reward, devReward);
    }

    function _withdrawStakeWithZeroReward(uint256 amount, uint256 index) internal returns(uint256){
      uint256 user_index = stakes[msg.sender];
      Stake memory current_stake = stakeholders[user_index].address_stakes[index];
      require(current_stake.amount >= amount, "Staking: Cannot withdraw more than you have staked");
      current_stake.amount = current_stake.amount - amount;
      if(current_stake.amount == 0) {
        delete stakeholders[user_index].address_stakes[index];
      } else {
        stakeholders[user_index].address_stakes[index].amount = current_stake.amount;
        stakeholders[user_index].address_stakes[index].since = block.timestamp;    
      }
      return (amount);
    }
   
    function hasStake(address _staker) public view returns(StakingSummary memory){
      uint256 totalStakeAmount; 
      StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[_staker]].address_stakes);
      for (uint256 s = 0; s < summary.stakes.length; s += 1) {
        uint256 availableReward = calculateStakeReward(summary.stakes[s]);
        summary.stakes[s].claimable = availableReward;
        totalStakeAmount = totalStakeAmount+summary.stakes[s].amount;
      }
      summary.total_amount = totalStakeAmount;
      return summary;
    }
}


contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: only owner can call this function");
        _;
    }

    constructor() {    }

    function initOwner() internal {
      _owner = 0xF36834a746fFcC8D13E508154075Fc83B2FEa83d;
      emit OwnershipTransferred(address(0), _owner);
    }
   
    function owner() public view returns(address) {
        return _owner;

    }
   
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

  
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
  
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract WVSOL is Ownable, Stakeable{
 
    uint private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;
    uint private _rewardsupply;

    address devAddress;
    address adminAddress;


    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event AdminAddress(address _from, address to);
    event DevAddress(address _from, address to);

    constructor() { 
    }

    bool initialized;

    modifier isInitialized {
      require(!initialized, "You can not initialize function again ");
      _;
    }

    function initialize() public isInitialized {
      _name = "Wrapped VSolidus Coin";
      _symbol = "WVSOL";
      _decimals = 8;
      
      uint256 premine = 450_000_000 * (10 ** _decimals);

      initOwner();
      initStakeable();

      _mint(owner(), premine);
      _rewardsupply = premine;
      devAddress = 0x2B98d6c2FC894714f14cE17f76599fb04E9193Bd; 
      adminAddress = 0x9c67cfEcd0633d3dDeB666aE6b9ffe084015eB23; 

      initialized = true;
    }

    function changeDevAddress(address _addr) onlyOwner public {
      emit DevAddress(devAddress, _addr);
      devAddress = _addr;
    }

    function changeAdminAddress(address _addr) onlyOwner public {
      emit AdminAddress(adminAddress, _addr);
      adminAddress = _addr;
    }
  
    function decimals() external view returns (uint8) {
      return _decimals;
    }
  
    function symbol() external view returns (string memory){
      return _symbol;
    }
 
    function name() external view returns (string memory){
      return _name;
    }
    
    function totalSupply() external view returns (uint256){
      return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
      return _balances[account];
    }
function getTotalStakeholders() public view returns(uint256) {
  return stakeholders.length;
}

function getTotalStakedAmount() public view returns(uint256) {
  return balanceOf(address(this));
}

    function _mint(address account, uint256 amount) internal {
      require(account != address(0), "DevToken: cannot mint to zero address");

      _totalSupply = _totalSupply + (amount);
      _balances[account] = _balances[account] + amount;
      emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
      require(account != address(0), "DevToken: cannot burn from zero address");
      require(_balances[account] >= amount, "DevToken: Cannot burn more than the account owns");

      _balances[account] = _balances[account] - amount;
      _totalSupply = _totalSupply - amount;
      emit Transfer(account, address(0), amount);
    }
 
    function burn(address account, uint256 amount) public onlyOwner returns(bool) {
      _burn(account, amount);
      return true;
    }

    function mint(address account, uint256 amount) public onlyOwner returns(bool){
      _mint(account, amount);
      return true;
    }

 
    function transfer(address recipient, uint256 amount) external returns(bool) {
      _transfer(msg.sender, recipient, amount);
      return true;
    }
 
    function _transfer(address sender, address recipient, uint256 amount) internal {
      require(sender != address(0), "DevToken: transfer from zero address");
      require(recipient != address(0), "DevToken: transfer to zero address");
      require(_balances[sender] >= amount, "DevToken: cant transfer more than your account holds");

      _balances[sender] = _balances[sender] - amount;
      _balances[recipient] = _balances[recipient] + amount;

      emit Transfer(sender, recipient, amount);
    }


    function allowance(address owner, address spender) external view returns(uint256){
      return _allowances[owner][spender];
    }
  
    function approve(address spender, uint256 amount) external returns (bool) {
      _approve(msg.sender, spender, amount);
      return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
      require(owner != address(0), "DevToken: approve cannot be done from zero address");
      require(spender != address(0), "DevToken: approve cannot be to zero address");
      _allowances[owner][spender] = amount;

      emit Approval(owner,spender,amount);
    }

    function transferFrom(address spender, address recipient, uint256 amount) external returns(bool){
      // Make sure spender is allowed the amount 
      require(_allowances[spender][msg.sender] >= amount, "DevToken: You cannot spend that much on this account");
      _transfer(spender, recipient, amount);
      _approve(spender, msg.sender, _allowances[spender][msg.sender] - amount);
      return true;
    }
  
    function increaseAllowance(address spender, uint256 amount) public returns (bool) {
      _approve(msg.sender, spender, _allowances[msg.sender][spender]+amount);
      return true;
    }
 
    function decreaseAllowance(address spender, uint256 amount) public returns (bool) {
      _approve(msg.sender, spender, _allowances[msg.sender][spender]-amount);
      return true;
    }


    function stake(uint256 _amount) public {
      require(_amount < _balances[msg.sender], "DevToken: Cannot stake more than you own");
      _stake(_amount);
      _transfer(msg.sender, address(this), _amount);
    }

    function getRemainingReward() view public returns(uint256) {
      return _rewardsupply;
    }

    function reduceRewardSupply(uint amount) private {
      uint256 temp = _rewardsupply;
      _rewardsupply -= amount;
      emit RewardAmountReduced(temp, _rewardsupply);
    }

    event RewardAmountReduced(uint256 _from, uint256 _to);

    event LastAmountMinted(uint256 stakedAmount, uint256 remaningAmount, uint256 rewardAmount, uint totalAmount);

    event CanNotGetReward(uint256 userRewardAmount, uint256 contractRewardAmountHold);

    event NotFinished24Hours(address _from, address _to, uint256 amount);

    function mintReward(uint256 amountStaked, uint256 userReward, uint256 devReward) private {
      _mint(devAddress, devReward/2);
      _mint(adminAddress, devReward/2);
      _mint(msg.sender, userReward);
      _transfer(address(this), msg.sender, amountStaked);
    }

    function withdrawStake(uint256 amount, uint256 stake_index)  public {
      uint256 amountStaked;
      uint256 devReward;
      uint256 userReward;

      if (getRemainingReward() > 0 ) {

        (amountStaked, userReward, devReward) = _withdrawStake(amount, stake_index);

        if( (userReward + devReward) > 0 ) { 
          if ( (userReward + devReward) < getRemainingReward() ) {
            reduceRewardSupply(devReward + userReward);
            mintReward(amountStaked, userReward, devReward);
          }
          else
          {
            userReward = getRemainingReward();
            devReward = ( userReward * 5 ) / 100;
            userReward -= devReward;
            mintReward(amountStaked, userReward, devReward);
            _rewardsupply = 0;          
          }
        }

        else {
          _transfer(address(this), msg.sender, amountStaked);
          emit NotFinished24Hours(address(this), msg.sender, amountStaked);
        }

      }
      else {
        amountStaked = _withdrawStakeWithZeroReward(amount, stake_index);
        _transfer(address(this), msg.sender, amountStaked);
        emit CanNotGetReward(userReward + devReward, getRemainingReward());
      }
    }

    function withdrawBNB() onlyOwner public payable {
      payable(owner()).transfer(address(this).balance);
    }

    fallback() external payable {}

    receive() external payable {
      payable(owner()).transfer(address(this).balance);
    }
}