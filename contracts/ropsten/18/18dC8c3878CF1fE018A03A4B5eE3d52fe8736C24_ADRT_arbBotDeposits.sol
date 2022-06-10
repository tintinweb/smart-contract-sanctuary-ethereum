/**
 *Submitted for verification at Etherscan.io on 2022-06-10
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
ERC20 USDC = ERC20(0xc778417E063141139Fce010982780140Aa0cD5Ab);

constructor(){

}

uint totalUSDCdeposited;
mapping(address => uint) USDCdepositsOf;

function deposit(uint amount) public{
USDC.approve(address(this),amount); 			    //Approve this contract to transfer user's USDC
USDC.transferFrom(msg.sender,address(this),amount); //Transfer USDC from user to this contract
totalUSDCdeposited += amount;				        //Update total deposited USDC
USDCdepositsOf[msg.sender] += amount;			    //Update deposited USDC of user
}

uint pendingNo;
mapping(uint => uint) pendingWithdrawalAmount;
mapping(address => uint) withdrawID;
mapping(uint => address) addressOfID;

function withdraw(uint amount) public{
require(pendingWithdrawalAmount[withdrawID[msg.sender]] + amount <= USDCdepositsOf[msg.sender]); //Check that requested withdrawal amount dont exceed user's deposit
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

function distribute(uint fundSizeUSDC) public{
uint requiredBalance = getShareOfFundRequestedForWithdrawal()*fundSizeUSDC / 10000;                 //Get required balance of contract to successfully distribute all withdraws
require(USDC.balanceOf(address(this)) > requiredBalance, "Contract does not hold enough funds");    //If contract holds less than the requried balance, reject the function call
for(uint i=1;i<=pendingNo;i+1){ 							            //Loop through all the users that have requested withdrawal and...
address dst = addressOfID[i]; 							                //.. get their address
uint share = pendingWithdrawalAmount[i] * 10000 / totalUSDCdeposited;	//.. get their share of fund requested to be withdrawn
if(share > 1){                                                          //If user's share of pool is greater than 0.01 % ...
uint whtdrwAmount = share * fundSizeUSDC / 10000; 				        //.. get their elligible amount based on current size of fund
USDC.transfer(dst,whtdrwAmount); 						                //.. transfer respective USDC amount
USDCdepositsOf[msg.sender] -= pendingWithdrawalAmount[i]; 			    //.. update USDC deposited of user
totalUSDCdeposited -= pendingWithdrawalAmount[i];				        //.. update total USDC deposit
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
uint share = totalWthdrwReq * 10000 / totalUSDCdeposited; //Calculate share(*10000 , because solidity can't do decimals) 
return share;                                             //Return the value so function caller can read it
}



}