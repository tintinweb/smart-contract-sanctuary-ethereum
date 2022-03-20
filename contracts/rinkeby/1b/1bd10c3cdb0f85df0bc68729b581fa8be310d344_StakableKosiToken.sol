/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity^0.8.0;

library SafeMath {
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

interface ERC20Token {

    function totalSupply() external view returns (uint256); // This is a method to get the total supply of a token
    function balanceOf(address account) external view returns (uint256); // This is a method to get an accounts balance of a particular token
    function allowance(address owner, address spender) external view returns (uint256); // This is a method that specifies how many tokens the spender address can transfer from the allowance address
    function buyToken() external payable returns (bool); // This is a method that specifies is used to buy tokens and incrementing the total supply

    function transfer(address recipient, uint256 amount) external returns (bool); // This is a method to transfer a token to another account
    function approve(address spender, uint256 amount) external returns (bool); // this is a method that specifies allowing another address transfer tokens for another address
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value); // This is an event that is emmited after a transfer occurs
    event Approval(address indexed owner, address indexed spender, uint256 value); // This is an event that is emmited when a new approval has been created
    event TokenMint(address indexed minter, uint256 value); // This is an event that is emmitted when new tokens are minted

}

interface Stakable {
    function isStakeholder(address _address) external view returns(bool, uint256); // This is a method to check if an address is a stakeholder
    function addStakeholder(address _stakeholder) external; // This is a method to add an address to list of stakeholders
    function removeStakeholder(address _stakeholder) external; // This is a method to remove an address from the list of stakeholders

    function stakeOf(address _stakeholder) external view returns(uint256);
    function totalStakes() external view returns(uint256); 
    function createStake(uint256 _stake) external;
    function removeStake(uint256 _stake) external;

    function rewardOf(address _stakeholder) external view returns(uint256);
    function totalRewards() external view returns(uint256);

    function calculateReward(address _stakeholder) external view returns(uint256);
    function withdrawReward() external; 



}

contract StakableKosiToken is ERC20Token, Stakable {
    using SafeMath for uint256;

    string public constant name = "Kosi Cash";
    string public constant symbol = "KSC";
    uint8 public constant decimals = 18;

    mapping(address => uint256) balances;
    address[] internal stakeholders;

    mapping(address => uint256) internal stakes;
    
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => uint256) stakeLock ;

    uint256 totalSupply_;
    address _owner; 
    uint256 public buyPrice = 1000;

    modifier onlyOwner(){
        require(msg.sender == _owner, "action can only be carried out by owner");
        _; 
    }

    constructor() {
        totalSupply_ = 1000 * (10 ** decimals);
        balances[msg.sender] = totalSupply_;
    }

    function modifyTokenBuyPrice(uint256 _newPrice) public onlyOwner {
        buyPrice = _newPrice;
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens); // remove numTokens from the message senders address
        balances[receiver] = balances[receiver].add(numTokens); // add numTokens to the message senders address
        emit Transfer(msg.sender, receiver, numTokens);  // emit the transfer event from the contranct
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens; //  set the amount of token that can be sent from an account
        emit Approval(msg.sender, delegate, numTokens); // emit an approval event
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function buyToken() public override payable returns (bool) {
        uint256 amount = msg.value * buyPrice; // 1 ETH is 1000 KSC therefore 1 wei is 100 mini KSC
        balances[msg.sender] = balances[msg.sender].add(amount);
        totalSupply_.add(amount);
        emit TokenMint(msg.sender, amount);
        return true;
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    function isStakeholder(address _address) public override view returns(bool, uint256){
        for (uint256 s = 0; s < stakeholders.length; s += 1){
           if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    function addStakeholder(address _stakeholder) override public {
       (bool _isStakeholder, ) = isStakeholder(_stakeholder);
            if(!_isStakeholder) stakeholders.push(_stakeholder);
    }

    function removeStakeholder(address _stakeholder) override public {
       (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
       if(_isStakeholder){
           stakeholders[s] = stakeholders[stakeholders.length - 1];
           stakeholders.pop();
       }
   }

   function stakeOf(address _stakeholder) override public view returns(uint256) {
       return stakes[_stakeholder];
   }

   function totalStakes() public override view returns(uint256){
       uint256 _totalStakes = 0;
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           _totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
       }
      return _totalStakes;
   }

   function createStake(uint256 _stake) public override {
       require (balances[msg.sender] > _stake, "you can not stake more tokens than you own");
       balances[msg.sender]  = balances[msg.sender].sub(_stake);
       if(stakes[msg.sender] == 0) addStakeholder(msg.sender);
       stakes[msg.sender] = stakes[msg.sender].add(_stake);
       stakeLock[msg.sender]  =  block.timestamp + (7 * 1 days);

   }

   function removeStake(uint256 _stake) public override {
       require (stakes[msg.sender] > _stake, "you can not remove more stake than you deposited");
       stakes[msg.sender] = stakes[msg.sender].sub(_stake);
       if(stakes[msg.sender] == 0) removeStakeholder(msg.sender);
       balances[msg.sender]  = balances[msg.sender].add(_stake);
   }

    function calculateReward(address _stakeholder) public override view returns(uint256){
       return stakes[_stakeholder] / 100;
   }


   function rewardOf(address _stakeholder) public override view returns(uint256){
       return calculateReward(_stakeholder);
   }

   function totalRewards() public override view returns(uint256){
       uint256 _totalRewards = 0;
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           _totalRewards = _totalRewards.add(calculateReward(stakeholders[s]));
       }
       return _totalRewards;
   }

   function withdrawReward() public override {
       require (block.timestamp >= stakeLock[msg.sender], "stake period still ongoing");
       uint256 reward = calculateReward(msg.sender);
       balances[msg.sender] = balances[msg.sender].add(reward);
   }
}