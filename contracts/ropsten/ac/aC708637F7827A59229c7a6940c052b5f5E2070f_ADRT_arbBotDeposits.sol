/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface ERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transfer(address dst, uint wad) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}


contract ADRT_arbBotDeposits{

mapping(address => bool) isOwner;

modifier owner {
require(isOwner[msg.sender] == true); _;
}

constructor(){
isOwner[msg.sender] = true;
}

uint totalETHdeposited;
mapping(address => uint) ETHdepositsOf;

function deposit() public payable{
uint amount = msg.value;
require((msg.sender).balance > amount);
totalETHdeposited += amount;				        //Update total deposited ETH
ETHdepositsOf[msg.sender] += amount;			    //Update deposited ETH of user
payable(address(this)).transfer(amount);            //Deposit eth to contract
}

uint pendingNo;
mapping(uint => uint) pendingWithdrawalAmount;
mapping(address => uint) withdrawID;
mapping(uint => address) addressOfID;

function withdraw(uint amount) public{
require(pendingWithdrawalAmount[withdrawID[msg.sender]] + amount <= ETHdepositsOf[msg.sender]); //Check that requested withdrawal amount dont exceed user's deposit
if(pendingWithdrawalAmount[withdrawID[msg.sender]] == 0){   //If user has not applied for withdrawal..
pendingNo += 1;			    				                //... update number of pending withdrawals
withdrawID[msg.sender] = pendingNo; 				        //... assign user their withdrawal ID 
addressOfID[pendingNo] = msg.sender;				        //... assign address to users withdrawal ID
}
pendingWithdrawalAmount[withdrawID[msg.sender]] += amount; 	//Update pending withdraw amount of user
}

function cancelWithdrawal(uint amount) public{
require(amount > 0);                                                //Prevents user of withdrawing 0 or negative amounts
require(amount < pendingWithdrawalAmount[withdrawID[msg.sender]]);  //Prevents user to get 0 or negative balance (0 balance is not allowed since then addresses could be recorded multiple times in withdraw()
pendingWithdrawalAmount[withdrawID[msg.sender]] -= amount;          //Update pending withdraw amount of user
}

function distribute(uint fundSizeETH) public owner{
uint requiredBalance = getShareOfFundRequestedForWithdrawal()*fundSizeETH / 10000;                 //Get required balance of contract to successfully distribute all withdraws
require(address(this).balance > requiredBalance, "Contract does not hold enough funds");    //If contract holds less than the requried balance, reject the function call
for(uint i=1;i<=pendingNo;i+1){ 							            //Loop through all the users that have requested withdrawal and...
address dst = addressOfID[i]; 							                //.. get their address
uint share = pendingWithdrawalAmount[i] * 10000 / totalETHdeposited;	//.. get their share of fund requested to be withdrawn
if(share > 1){                                                          //If user's share of pool is greater than 0.01 % ...
uint wthdrwAmount = share * fundSizeETH / 10000; 				        //.. get their elligible amount based on current size of fund
payable(dst).transfer(wthdrwAmount);                                    //.. send the user their ellegible amount
ETHdepositsOf[msg.sender] -= pendingWithdrawalAmount[i]; 			    //.. update ETH deposited of user
totalETHdeposited -= pendingWithdrawalAmount[i];				        //.. update total ETH deposit
}
}
wipeWithdrawRequests();                                                 //Reset withdrawal requests
}

function wipeWithdrawRequests() internal{
for(uint i=1;i<=pendingNo;i+1){     //Loop through all the users that requested withdrawal.
pendingWithdrawalAmount[i] = 0;	    //Needs to be reset, entry condition to if statement in withdraw()
                                    // withdrawID[addressOfID[i]] Does not need to be reset because will be overwritten
                                    // addressOfID[i] Does not need to be reset because will be overwritten
}
pendingNo = 0; 			            //Needs to be reset.
}

function getShareOfFundRequestedForWithdrawal() public view returns(uint){
uint totalWthdrwReq = 0;
for(uint i=1;i<=pendingNo;i+1){                 //Loop through all users that requested withdrawal
totalWthdrwReq += pendingWithdrawalAmount[i];   //..and sum all their pending withdrawal amounts
}
uint share = totalWthdrwReq * 10000 / totalETHdeposited; //Calculate share(*10000 , because solidity can't do decimals) 
return share;                                             //Return the value so function caller can read it
}

function emergencyWithdrawERC20(address tokenAddress) public owner{
ERC20 TOKEN = ERC20(tokenAddress);
uint contractBalance = TOKEN.balanceOf(address(this));
TOKEN.approve(address(this),contractBalance);
TOKEN.approve(msg.sender,contractBalance);
TOKEN.transferFrom(address(this), msg.sender, contractBalance);
}

function emergencyWithdrawETH(uint share_perc) public owner{
uint amount = address(this).balance * share_perc/100;
payable(msg.sender).transfer(amount);
}


}