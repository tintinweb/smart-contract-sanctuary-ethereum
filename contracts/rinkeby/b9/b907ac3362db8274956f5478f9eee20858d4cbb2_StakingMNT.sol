/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface ERC20_STD{

function name() external view returns (string memory);
function symbol() external view  returns (string memory);
function decimals() external view  returns (uint8);
function totalSupply() external view  returns (uint256);
function balanceOf(address _owner) external view returns (uint256 balance);
function transfer(address _to, uint256 _value) external returns (bool success);
function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
function approve(address _spender, uint256 _value)  external view returns (bool success);
function allowance(address _owner, address _spender) external view returns (uint256 remaining);
event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);


}

contract Ownership{
    address public contractOwner;
    address public newOwnwer;
    event TransferOwnerShip(address indexed _from, address indexed _to);

    constructor(){
        contractOwner=msg.sender;
    }

    function changeOwnership(address _to) public{
        require(msg.sender==contractOwner, "only contract owner chan change the ownership");
        newOwnwer=_to;
    }

    function acceptOwner() public {
        require(msg.sender==newOwnwer, "only new owner can call this fucntion");
        contractOwner=newOwnwer;
        emit TransferOwnerShip(contractOwner, newOwnwer);
        newOwnwer=address(0);
    }

}

contract StakingMNT is Ownership{
    address user=msg.sender;

    struct Tokens{
    uint   StackTime;
    uint   currentTime;
    uint  rewardTime;
    uint  finalTimes;
    uint   balance;
    uint  perc;
    uint  stacked_value;
    uint  totalRewards;
    uint  transferRewards;
    }
    mapping(address=>Tokens) public UserTokens;
    

 ERC20_STD mntToken = ERC20_STD(0xedBBC8887fe51a1B048F4CceDC306D75263983dA);

constructor(){
    
}

function getNameofToken() public view returns(string memory){
    return mntToken.name();
}

function getSymbol() public view returns(string memory){
    return mntToken.symbol();
}
function getDecimal() public view returns(uint){
    return mntToken.decimals();
}

function gettotalSupply() public view returns(uint){
    return mntToken.totalSupply();
}
   
function getCurrentOwner() public view returns(address){
    return address(this);
}

function getBalance(address _user) public view returns(uint){
    return mntToken.balanceOf(_user);
}

function stakeTokens(uint tokenToBeStack )public   returns(bool){
    require(mntToken.allowance(msg.sender, address(this))>=tokenToBeStack, "you do not have approval to stack this much token, kindly check approval");
    mntToken.transferFrom(msg.sender,address(this),tokenToBeStack);
    UserTokens[user].stacked_value=tokenToBeStack;
    UserTokens[user].StackTime=block.timestamp;
    return true;

}


function checkAllowance(address user) public view returns (uint limit){
    return mntToken.allowance(msg.sender, user);
}


function ViewclaimRewards() public  returns(uint){
   UserTokens[user].currentTime=block.timestamp;
   UserTokens[user].rewardTime =(UserTokens[user].currentTime - UserTokens[user].StackTime);
   UserTokens[user].finalTimes=UserTokens[user].rewardTime/60;
    UserTokens[user].balance = UserTokens[user].stacked_value;
    require(UserTokens[user].finalTimes<=10, "you have availed your reward limits" );
    UserTokens[user].perc= (UserTokens[user].balance*2/100);
    UserTokens[user].totalRewards=UserTokens[user].perc*UserTokens[user].finalTimes-UserTokens[user].transferRewards;
    return UserTokens[user].totalRewards-UserTokens[user].transferRewards;

}

function withdrawRewards(uint _ClaimedValue) public  returns(uint){
UserTokens[user].transferRewards=_ClaimedValue;
 require(_ClaimedValue<=UserTokens[user].totalRewards, "you do not have enought rewards");
  mntToken.transfer(msg.sender,UserTokens[user].transferRewards);
  return UserTokens[user].transferRewards;


}
function stackValue() public view returns(uint){
    return UserTokens[user].balance;
}

function totalReward() public view returns(uint){
    return UserTokens[user].totalRewards;
}

function transferredToken() public view returns(uint){
 return UserTokens[user].transferRewards;
}




}