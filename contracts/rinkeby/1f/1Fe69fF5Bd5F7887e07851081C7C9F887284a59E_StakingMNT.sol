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
// function approve(address _spender, uint256 _value) public virtual returns (bool success);
function allowance(address _owner, address _spender) external view returns (uint256 remaining);

// event Transfer(address indexed _from, address indexed _to, uint256 _value);
// event Approval(address indexed _owner, address indexed _spender, uint256 _value);


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
    uint  public StackTime;
    uint   currentTime;
    uint public rewardTime;
    uint public finalTimes;
    uint   balance;
    uint public perc;
    uint public stacked_value;
    uint public totalRewards;
    uint public transferRewards;

 ERC20_STD mntToken = ERC20_STD(0x651Baaa9B1f0C9484E8f47daA217630Be4b11e92);

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
    stacked_value=tokenToBeStack;
    StackTime=block.timestamp;
    return true;

}

function checkAllowance(address user) public view returns (uint limit){
    return mntToken.allowance(msg.sender, user);
}


function ViewclaimRewards() public  returns(uint){
    currentTime=block.timestamp;
    rewardTime =(currentTime - StackTime);
    finalTimes=rewardTime/60;
    balance = stacked_value;
    require(finalTimes<11, "you have availed your reward limits" );
    perc= (balance*2/100);
    totalRewards=perc*finalTimes-transferRewards;
    return totalRewards;

}

function withdrawRewards(uint _ClaimedValue) public  returns(uint){
  transferRewards=_ClaimedValue;
 require(_ClaimedValue<=totalRewards, "you do not have enought rewards");
  mntToken.transfer(msg.sender,transferRewards);
  return transferRewards;


}
function stackValue() public view returns(uint){
    return balance;
}

function totalReward() public view returns(uint){
    return totalRewards;
}

function transferredToken() public view returns(uint){
 return transferRewards;
}




}