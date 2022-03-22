// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Stakable.sol";

contract DevToken is Ownable, Stakable {

  uint private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  mapping(address => uint256) private _balances;

  // _allowances is used to manage and control allowance
  mapping(address => mapping(address => uint256)) _allowances;

  // Transfer event notofies the blockchain that assets transfer has taken place
  event Transfer(address indexed fron, address indexed to, uint256 value);

  // Approval is emitted when a new spender is approved to spend tokens on the owners account
  event Approval(address indexed owner, address indexed spender, uint256 value);

  // The constructor will then be triggered when we create the smart contract
  constructor(string memory token_name, string memory short_symbol, uint8 token_decimals, uint256 token_totalSupply) {
    _name = token_name;
    _symbol = short_symbol;
    _decimals = token_decimals;
    _totalSupply = token_totalSupply;

    // Add all the tokens created to the creator of the token
    _balances[msg.sender] = _totalSupply;

    // Emit the transfer event to notify the blockchain that a transfer occured
    emit Transfer(address(0), msg.sender, _totalSupply);

  }

  function decimals() external view returns(uint8) {
    return _decimals;
  }

  function symbol() external view returns(string memory) {
    return _symbol;
  }

  function  name() external view returns(string memory) {
    return _name;
  }

  function totalSupply() external view returns(uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view returns(uint256) {
    return _balances[account];
  }

  // _mint will create tokens on the address inputted and then increase the total supply
 function _mint(address account, uint256 amount) internal {
    require(account != address(0), "DevToken: cannot mint to zero address");

    // Increase total supply
    _totalSupply = _totalSupply + (amount);
    // Add amount to the account balance using the balance mapping
    _balances[account] = _balances[account] + amount;
    // Emit our event to log the action
    emit Transfer(address(0), account, amount);
  }

  //  _burn will destroy tokens from an address inputted and then decrease total supply
   function _burn(address account, uint256 amount) internal {
    require(account != address(0), "DevToken: cannot burn from zero address");
    require(_balances[account] >= amount, "DevToken: Cannot burn more than the account owns");

    // Remove the amount from the account balance
    _balances[account] = _balances[account] - amount;
    // Decrease totalSupply
    _totalSupply = _totalSupply - amount;
    // Emit event, use zero address as reciever
    emit Transfer(account, address(0), amount);
  }

  // burn is used to destroy tokens on an address
  function burn(address account, uint256 amount) public onlyOwner returns(bool) {
    _burn(account, amount);
    return true;
  }

  // mint is used to create tokens and assign them to msg.sender
  function mint(address account, uint256 amount) public onlyOwner returns(bool){
    _mint(account, amount);
    return true;
  }

  function buyToken(address account, uint256 amount) public payable{
        uint256 Rate = 1000;
        uint256 amount = msg.value ** _decimals / Rate;

        mint(account, amount);
    }

  // Transfer is used to transfer funds from the sender to the recipient callable from outside the contract
  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  // _transfer is used for internal transfers
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "DevToken: transfer from zero address");
    require(recipient != address(0), "DevToken: transfer to zero address");
    require(_balances[sender] >= amount, "DevToken: cant transfer more than your account holds");

    _balances[sender] = _balances[sender] - amount;
    _balances[recipient] = _balances[recipient] + amount;

    emit Transfer(sender, recipient, amount);
  }

   // getOwner just calls Ownables owner function. 
  function getOwner() external view returns (address) {
    return owner();
  }
 
 // allowance is used view how much allowance an spender has
  function allowance(address owner, address spender) external view returns(uint256){
     return _allowances[owner][spender];
   }
  // approve will use the senders address and allow the spender to use X amount of tokens on his behalf
  function approve(address spender, uint256 amount) external returns (bool) {
     _approve(msg.sender, spender, amount);
     return true;
   }

   // _approve is used to add a new Spender to a Owners account
  function _approve(address owner, address spender, uint256 amount) internal {
      require(owner != address(0), "DevToken: approve cannot be done from zero address");
      require(spender != address(0), "DevToken: approve cannot be to zero address");
      // Set the allowance of the spender address at the Owner mapping over accounts to the amount
      _allowances[owner][spender] = amount;

      emit Approval(owner,spender,amount);
    }
    
    // transferFrom is used to transfer Tokens from a Accounts allowance
  function transferFrom(address spender, address recipient, uint256 amount) external returns(bool){
      // Make sure spender is allowed the amount 
      require(_allowances[spender][msg.sender] >= amount, "DevToken: You cannot spend that much on this account");
      // Transfer first
      _transfer(spender, recipient, amount);
      // Reduce current allowance so a user cannot respend
      _approve(spender, msg.sender, _allowances[spender][msg.sender] - amount);
      return true;
    }
    
  // increaseAllowance Adds allowance to a account from the function caller address
  function increaseAllowance(address spender, uint256 amount) public returns (bool) {
      _approve(msg.sender, spender, _allowances[msg.sender][spender]+amount);
      return true;
    }

  // decreaseAllowance Decrease the allowance on the account inputted from the caller address
  function decreaseAllowance(address spender, uint256 amount) public returns (bool) {
      _approve(msg.sender, spender, _allowances[msg.sender][spender]-amount);
      return true;
    }

  // Add functionality like burn to the _stake afunction
  function stake(uint256 _amount) public {
      // Make sure staker actually is good for it
      require(_amount < _balances[msg.sender], "DevToken: Cannot stake more than you own");

        _stake(_amount);
                // Burn the amount of tokens on the sender
        _burn(msg.sender, _amount);
    }

    // withdrawStake is used to withdraw stakes from the account holder
    function withdrawStake(uint256 amount, uint256 stake_index)  public {

      uint256 amount_to_mint = _withdrawStake(amount, stake_index);
      // Return staked tokens to user
      _mint(msg.sender, amount_to_mint);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Stakable {

    constructor() {
      stakeholders.push();  
    }

     
     // A stake struct is used to represent the way we store stakes, 
    struct Stake{
        address user;
        uint256 amount;
        // This claimable field is new and used to tell how big of a reward is currently available
        uint256 claimable;
    }
    // Stakeholder is a staker that has active stakes
    struct Stakeholder{
        address user;
        Stake[] address_stakes;
        
    }
     
    // StakingSummary is a struct that is used to contain all stakes performed by a certain account
    struct StakingSummary{
         uint256 total_amount;
         Stake[] stakes;
     }

    Stakeholder[] internal stakeholders;
   
    mapping(address => uint256) internal stakes;
    
     //Staked event is triggered whenever a user stakes tokens, address is indexed to make it filterable
    event Staked(address indexed user, uint256 amount, uint256 index);

    uint256 internal rewardPerStake = 100;

    // _addStakeholder takes care of adding a stakeholder to the stakeholders array
    function _addStakeholder(address staker) internal returns (uint256){
        // Push a empty item to the Array to make space for our new stakeholder
        stakeholders.push();
        // Calculate the index of the last item in the array by Len-1
        uint256 userIndex = stakeholders.length - 1;
        // Assign the address to the new index
        stakeholders[userIndex].user = staker;
        // Add index to the stakeHolders
        stakes[staker] = userIndex;
        return userIndex; 
    }

    // _Stake is used to make a stake for an sender. It will remove the amount staked from the stakers account and place those tokens inside a stake container
    function _stake(uint256 _amount) internal{
        // Simple check so that user does not stake 0 
        require(_amount > 0, "Cannot stake nothing");
        

        // Mappings in solidity creates all values, but empty, so we can just check the address
        uint256 index = stakes[msg.sender];
        // block.timestamp = timestamp of the current block in seconds since the epoch
      //  uint256 timestamp = block.timestamp;
        // See if the staker already has a staked index or if its the first time
        if(index == 0){
            // This stakeholder stakes for the first time
            // We need to add him to the stakeHolders and also map it into the Index of the stakes
            // The index returned will be the index of the stakeholder in the stakeholders array
            index = _addStakeholder(msg.sender);
        }

        // Use the index to push a new Stake
        // push a newly created Stake with the current block timestamp.
        stakeholders[index].address_stakes.push(Stake(msg.sender, _amount, 0));
        // Emit an event that the stake has occured
        emit Staked(msg.sender, _amount, index);
    }


    function calculateStakeReward(Stake memory _current_stake) internal view returns(uint256){
          // We will reward the user 1% per stake
          return (( _current_stake.amount) / rewardPerStake);
      }

    
    // withdrawStake takes in an amount and a index of the stake and will remove tokens from that stake
    // index of the stake is the users stake counter, starting at 0 for the first stake
    function _withdrawStake(uint256 amount, uint256 index) internal returns(uint256){
         // Grab user_index which is the index to use to grab the Stake[]
        uint256 user_index = stakes[msg.sender];
        Stake memory current_stake = stakeholders[user_index].address_stakes[index];
        require(current_stake.amount >= amount, "Staking: Cannot withdraw more than you have staked");

         // Calculate available Reward first before we start modifying data
         uint256 reward = calculateStakeReward(current_stake);
         // Remove by subtracting the money unstaked 
         current_stake.amount = current_stake.amount - amount;
         // If stake is empty, 0, then remove it from the array of stakes
         if(current_stake.amount == 0){
             delete stakeholders[user_index].address_stakes[index];
         }else {
             // If not empty then replace the value of it
             stakeholders[user_index].address_stakes[index].amount = current_stake.amount;
             // Reset timer of stake
            // stakeholders[user_index].address_stakes[index].since = block.timestamp;    
         }

         return amount+reward;
     }

    // hasStake is used to check if a account has stakes and the total amount along with all the seperate stakes
    function hasStake(address _staker) public view returns(StakingSummary memory){
        // totalStakeAmount is used to count total staked amount of the address
        uint256 totalStakeAmount; 
        // Keep a summary in memory since we need to calculate this
        StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[_staker]].address_stakes);
        // Itterate all stakes and grab amount of stakes
        for (uint256 s = 0; s < summary.stakes.length; s += 1){
           uint256 availableReward = calculateStakeReward(summary.stakes[s]);
           summary.stakes[s].claimable = availableReward;
           totalStakeAmount = totalStakeAmount+summary.stakes[s].amount;
       }
       // Assign calculate amount to summary
       summary.total_amount = totalStakeAmount;
        return summary;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract Ownable {
    // _owner is the owner of the Token
    address private _owner;

    // Event OwnershipTransferred is used to log that a ownership change of the token has occured
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // We create our own function modifier called onlyOwner, it will Require the current owner to be the same as msg.sender
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: only owner can call this function");
        _;
    }

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    
    // owner() returns the currently assigned owner of the Token
    function owner() public view returns(address) {
        return _owner;

    }

    /**
    * @notice renounceOwnership will set the owner to zero address
    * This will make the contract owner less, It will make ALL functions with
    * onlyOwner no longer callable.
    * There is no way of restoring the owner
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    // transferOwnership will assign the {newOwner} as owner
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    
    // _transferOwnership will assign the {newOwner} as owner
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}