// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Stacking{
   
    // mapping (address => uint256) public stackingBalance;
    struct Stacks{
       uint256 _bal;
       uint256 _stakingTime;
    }
    mapping (address => Stacks) stackings;
    
    address public owner;
    constructor(){
     owner = msg.sender;
    }

    modifier onlyOwner(){ // Modifer that check owener
      require(msg.sender == owner,"NOT_OWNER");
        _;
    }
    event ChangeOwner(address _oldOwner,address new_owner);
    event Stackings(address _staker, uint256 _amount, address _contractAddress);
    event Withdraw(address _user, uint256 amount, address sendFrom);
    event WithdrawOwner(address _owner,address _to, uint256 amount);
    


 function changeOwner(address _owner)public onlyOwner{
    require(_owner != address(0),"WRONG_ADDRESS");
    require(_owner != owner ,"ALREADY_OWNER");
    owner = _owner;
    emit ChangeOwner(msg.sender,_owner);
 }
 
        fallback()external{ }
// fallback function

function stacking()public payable {
    require(msg.value >= 0.05 ether,"Minmum Staking is 0.05 ether");
    require(stackings[msg.sender]._bal == 0,"Already staked");
    // stackingBalance[msg.sender] = msg.value;
    stackings[msg.sender]._bal = msg.value;
    stackings[msg.sender]._stakingTime = block.timestamp;
    // require msg.value>= 0.5 ether;
    emit Stackings(msg.sender, msg.value, address(this));
}
function withdrawlTime(address _user) public view returns(uint256){
   uint256 stakingT =  stackings[_user]._stakingTime;
   uint256 withdrawlT = stakingT +(30 * 24 * 60 * 60);
   return withdrawlT;
}

function calculateReward(address _user)public view returns(uint256){
    uint256 reward = (stackings[_user]._bal *2)/100; //  2% amount *2/100 // 100*2/100
    return reward;
}
function withdraw()public{
    require(stackings[msg.sender]._bal > 0 ,"Not_stack Yet");
    require(withdrawlTime(msg.sender) <= block.timestamp, "Can't Withdraw Now"); // 30 sept <  20 sept
    require(address(this).balance > stackings[msg.sender]._bal + calculateReward(msg.sender), "NOT_ENOUGTH_BALANCE_IN_CONTRACT");
    stackings[msg.sender]._bal = 0;
    stackings[msg.sender]._stakingTime = 0;
    // inside contract address send eth or native , .transfer , send , call
    payable(msg.sender).transfer(stackings[msg.sender]._bal + calculateReward(msg.sender));
    emit Withdraw(msg.sender, stackings[msg.sender]._bal + calculateReward(msg.sender), address(this));
}

function stakingBalance(address _user) external view returns(uint256 balance){ // 
    return stackings[_user]._bal;
}

function withdrawOwner(uint amount, address payable _to) external onlyOwner{
    require(address(this).balance >= amount,"Not Enough Balamnce in Contract");
    _to.transfer(amount);
    emit WithdrawOwner(msg.sender, _to, amount);
}

}