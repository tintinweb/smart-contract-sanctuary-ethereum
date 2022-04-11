/**
 *Submitted for verification at Etherscan.io on 2022-04-10
*/

// File: contracts/Stakeable.sol


pragma solidity ^0.8.9;


contract Stakeable {


    
    constructor() {
        
        stakeholders.push();
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

   
    uint256 internal rewardPerHour = 1000;

    
    function _addStakeholder(address staker) internal returns (uint256){
        
        stakeholders.push();
        
        uint256 userIndex = stakeholders.length - 1;
        
        stakeholders[userIndex].user = staker;
        
        stakes[staker] = userIndex;
        return userIndex; 
    }

   
    function _stake(uint256 _amount) internal{
         
        require(_amount > 0, "Cannot stake nada");
        

        
        uint256 index = stakes[msg.sender];
        
        uint256 timestamp = block.timestamp;
        
        if(index == 0){
           
            index = _addStakeholder(msg.sender);
        }

        
        stakeholders[index].address_stakes.push(Stake(msg.sender, _amount, timestamp,0));
        
        emit Staked(msg.sender, _amount, index,timestamp); 
    }

    
      function calculateStakeReward(Stake memory _current_stake) internal view returns(uint256){
         
          return (((block.timestamp - _current_stake.since) / 1 hours) * _current_stake.amount) / rewardPerHour;
      }

    
     function _withdrawStake(uint256 amount, uint256 index) internal returns(uint256){
         
        uint256 user_index = stakes[msg.sender];
        Stake memory current_stake = stakeholders[user_index].address_stakes[index];
        require(current_stake.amount >= amount, "Staking: Cannot withdraw more than you have staked silly billy");

         
         uint256 reward = calculateStakeReward(current_stake);
         
         current_stake.amount = current_stake.amount - amount;
         
         if(current_stake.amount == 0){
             delete stakeholders[user_index].address_stakes[index];
         }else {
             
             stakeholders[user_index].address_stakes[index].amount = current_stake.amount;
            
            stakeholders[user_index].address_stakes[index].since = block.timestamp;    
         }

         return amount+reward;

     }

     
    function hasStake(address _staker) public view returns(StakingSummary memory){
       
        uint256 totalStakeAmount; 
       
        StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[_staker]].address_stakes);
        
        for (uint256 s = 0; s < summary.stakes.length; s += 1){
           uint256 availableReward = calculateStakeReward(summary.stakes[s]);
           summary.stakes[s].claimable = availableReward;
           totalStakeAmount = totalStakeAmount+summary.stakes[s].amount;
       }
       
       summary.total_amount = totalStakeAmount;
        return summary;
    }




}
// File: contracts/Ownable.sol


pragma solidity ^0.8.9;


contract Ownable {
    
    address private _owner;

   
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: only owner can call this function");
       
        _;
    }

    constructor() {
        _owner = msg.sender;
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
// File: contracts/PulseOG.sol


pragma solidity ^0.8.9;

// blockchains are speech and speech is a protected human right.



contract PulseOG is Ownable, Stakeable{
  

 
  uint private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

 
  mapping (address => uint256) private _balances;
 
   mapping (address => mapping (address => uint256)) private _allowances;

  
  event Transfer(address indexed from, address indexed to, uint256 value);
  
  event Approval(address indexed owner, address indexed spender, uint256 value);

 
  constructor(string memory token_name, string memory short_symbol, uint8 token_decimals, uint256 token_totalSupply){
      _name = token_name;
      _symbol = short_symbol;
      _decimals = token_decimals;
      _totalSupply = token_totalSupply;

      _balances[msg.sender] = _totalSupply;

     
      emit Transfer(address(0), msg.sender, _totalSupply);
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
 
  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }


  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "PulseOG: cannot mint to zero address");

   
    _totalSupply = _totalSupply + (amount);
    
    _balances[account] = _balances[account] + amount;
    
    emit Transfer(address(0), account, amount);
  }
 
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "PulseOG: cannot burn from zero address");
    require(_balances[account] >= amount, "PulseOG: Cannot burn more than the account owns");

    
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


  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "PulseOG: transfer from zero address");
    require(recipient != address(0), "PulseOG: transfer to zero address");
    require(_balances[sender] >= amount, "PulseOG: cant transfer more than your account holds");

    _balances[sender] = _balances[sender] - amount;
    _balances[recipient] = _balances[recipient] + amount;

    emit Transfer(sender, recipient, amount);
  }
 
  function getOwner() external view returns (address) {
    return owner();
  }
  
   function allowance(address owner, address spender) external view returns(uint256){
     return _allowances[owner][spender];
   }
  
   function approve(address spender, uint256 amount) external returns (bool) {
     _approve(msg.sender, spender, amount);
     return true;
   }


    function _approve(address owner, address spender, uint256 amount) internal {
      require(owner != address(0), "PulseOG: approve cannot be done from zero address");
      require(spender != address(0), "PulseOG: approve cannot be to zero address");
      
      _allowances[owner][spender] = amount;

      emit Approval(owner,spender,amount);
    }
    
    function transferFrom(address spender, address recipient, uint256 amount) external returns(bool){
      
      require(_allowances[spender][msg.sender] >= amount, "PulseOG: You cannot spend that much on this account");
      
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
      
      require(_amount < _balances[msg.sender], "PulseOG: Cannot stake more than you own");

        _stake(_amount);
               
        _burn(msg.sender, _amount);
    }

   
    function withdrawStake(uint256 amount, uint256 stake_index)  public {

      uint256 amount_to_mint = _withdrawStake(amount, stake_index);
      
      _mint(msg.sender, amount_to_mint);
    }

}