// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract Stacking{
    struct Stacks{ //Struct
       uint balance;
       uint stakingTime;

    }
    mapping (address => Stacks) stackings; //Mapping
    uint minimumStack=5 ether;
    address public owner;
    constructor(){
     owner = msg.sender;
    }

    modifier onlyOwner(){ // Modifer that check owener
      require(msg.sender == owner,"You are not Owner");
        _;
    }
    event ChangeOwner(address _oldOwner,address new_owner);
    event StackNow(address _staker, uint256 _amount, address _contractAddress);
    event Withdraw(address _user, uint256 amount, address sendFrom);
    event WithdrawOwner(address _owner,address _to, uint256 amount);
    


 function changeOwner(address _owner)public onlyOwner{
    require(_owner != address(0),"Its not valid address");
    require(_owner != owner ,"You are already owner");
    owner = _owner;
    emit ChangeOwner(msg.sender,_owner);
 }
 
        fallback()external{ } // fallback function


function stackNow()public payable {
    require(msg.value >= minimumStack,"Minimum Staking is 5 ether");
    require(stackings[msg.sender].balance == 0,"Already staked");
    stackings[msg.sender].balance = msg.value;
    stackings[msg.sender].stakingTime = block.timestamp;

    emit StackNow(msg.sender, msg.value, address(this));
}
function withdrawlTime(address _user) public view returns(uint256){
   uint256 stakingT =  stackings[_user].stakingTime;
   uint256 withdrawlT = stakingT +(30 * 24 * 60 * 60); //30days stacking
   return withdrawlT;
}

function calculateReward(address _user)public view returns(uint256){
    uint256 reward = (stackings[_user].balance *2)/100; //  2% amount *2/100 // 100*2/100
    return reward;
}
function withdraw()public{
    require(stackings[msg.sender].balance > 0 ,"Not_stack Yet");
    require(withdrawlTime(msg.sender) <= block.timestamp, "Can't Withdraw Now"); // stack time+30days <cureent time of withdraw
    require(address(this).balance > stackings[msg.sender].balance + calculateReward(msg.sender), "contract balance is not enough");

    uint _amount=stackings[msg.sender].balance + calculateReward(msg.sender);
    (bool success,)=payable(msg.sender).call{value:_amount}("");
    require(success,"Invalid Transaction");
    stackings[msg.sender].balance = 0;
    stackings[msg.sender].stakingTime = 0;

    emit Withdraw(msg.sender, stackings[msg.sender].balance + calculateReward(msg.sender), address(this));
}

function stakingBalance(address _user) external view returns(uint256 balance){ // 
    return stackings[_user].balance;
}

function withdrawOwner(uint amount, address payable _to) external onlyOwner{
    require(address(this).balance >= amount,"Contract balance is not enough");
    (bool success,)=_to.call{value:amount}("");
    require(success,"Transaction is not proceeded");
    emit WithdrawOwner(msg.sender, _to, amount);
}

}