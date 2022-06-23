/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

pragma solidity ^0.4.17;


// SPDX-License-Identifier: MIT



    contract VOMOICO {
/// Fields:
    string public constant name = "VOMO";
    string public constant symbol = "VT";
    uint public constant decimals = 18;  
    // uint public constant PRICE = 100; 
    uint public constant PRICE = 147; // per 1 Ether
    uint256 public constant PRESALE_TOKEN_SOFT_CAP = 4200000000000000000000000;  //4.2 million    4,200,000
    uint256 public constant SOFTCAP_RATE = 625;
    uint256 public constant PRESALE_TOKEN_HARD_CAP = 9450000000000000000000000;    //9.45 million    9,450,000
    uint256 public constant  HARDCAP_RATE= 277;
    uint256 public start_timestamp;
    // uint256 public extTime = 7776000;
    uint256 public constant  Vesting_timestamp=(start_timestamp + 7776000);     //90 days
    uint256 public constant softdays = start_timestamp + 2592000;              //30 days
    uint256 public constant harddays = softdays + 2592000;                    //30 days after soft days
    //address funder1 = 0x69e56D0aF44380BC3B0D666c4207BBF910f0ADC9;
    uint newTokens;
    uint256 balSoftcap;

    enum State{
    Init,
    Running
    }
    // uint256 public PRESALE_END_COUNTDOWN;
    uint numTokens;
    uint256 totalSupply_;
    
    State public currentState = State.Running;
    uint public initialToken = 0; // amount of tokens already sold

// Gathered funds can be withdrawn only to escrow's address.
    address public escrow = 0;                                   //how can you set an address to 0?
    mapping (address => uint256) private balance;
    mapping (address => bool) ownerAppended;
    address[] public owners;

/// Modifiers:
    modifier onlyInState(State state)
    { 
        require(state == currentState);
    _; 
    }

/// Events:

    event Transfer(address indexed from, address indexed to, uint256 _value);

/// Functions:
/// @dev Constructor

    function VOMOICO(address escrow, uint256 start_timestamp) public {
    start_timestamp = start_timestamp;
    require(escrow != 0);
    escrow = escrow;
    totalSupply_ = 1400000000000000000000000000;      //1.4 billion    1,400,000,000
    }

//buy

    function buyTokens(address _buyer) public payable onlyInState(State.Running) {      //always running?
     //Softcap
    if (softdays >= block.timestamp){    //If 30 days since the start time have NOT passed.
    require(msg.value != 0);
    newTokens = msg.value * SOFTCAP_RATE;    //1 * 625 =  625 wei

    require(initialToken + newTokens <= PRESALE_TOKEN_SOFT_CAP);   

    balance[_buyer] += newTokens;    //
    initialToken += newTokens;       //track the total number of tokens bought.

    if(!ownerAppended[_buyer]) {
    ownerAppended[_buyer] = true;
    owners.push(_buyer);
    }

    Transfer(msg.sender, _buyer,  newTokens);
    balance[msg.sender] -= PRESALE_TOKEN_SOFT_CAP;   // ???  When did they get these tokens? why decrease full amount?  Underflow??

    balSoftcap = balance[msg.sender];  //this does nothing now

    if(this.balance > 0) {
    require(escrow.send(this.balance));
    }
    }

//hardCap
 if (harddays>= block.timestamp){       //If 30 days since the softdays time have passed.
    require(msg.value != 0);
    newTokens = msg.value * HARDCAP_RATE;
    require(initialToken + newTokens <= PRESALE_TOKEN_HARD_CAP);
    balance[_buyer] += newTokens;    //tokens aren't decreased from anywhere
    initialToken += newTokens;
    if(!ownerAppended[_buyer]) {
    ownerAppended[_buyer] = true;
    owners.push(_buyer);
    }
    Transfer(msg.sender, _buyer,  newTokens);
    
    if(this.balance > 0) {
    require(escrow.send(this.balance));
    }
    }
//Listing_Price
    if (harddays<= block.timestamp){    //If hard days have also expired
    require(msg.value != 0);
    newTokens = msg.value * SOFTCAP_RATE;
//    console.log("newToken");
    require(initialToken + newTokens <= totalSupply_);     //now enforce the total supply
    balance[_buyer] += newTokens;
    initialToken += newTokens;

    if(!ownerAppended[_buyer]) {
    ownerAppended[_buyer] = true;
    owners.push(_buyer);
    }

    Transfer(msg.sender, _buyer,  newTokens);

    if(this.balance > 0) {
    require(escrow.send(this.balance));
    }
    }

    }

/// @dev Returns number of tokens owned by given address.
/// @param _owner Address of token owner.
    function balanceOf(address _owner) constant returns (uint256) {
    return balance[_owner];
    }

    function getPrice() constant returns(uint) {
    return PRICE;
    }
    address public owner;
    
    // Tranfer Owbnership
    function Ownable() {     //no visibility 0.4.x ?
    owner = msg.sender;
    }

    modifier onlyOwner() {
    require(msg.sender == owner);
    _ ;
    }
    function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
    owner = newOwner;
    }

    }

// Default fallback function
    function() payable {
    buyTokens(msg.sender);
    }
    
 function redeem(address _buyer, uint numTokens) external onlyOwner { 

//    console.log(start_timestamp,"st");
//    console.log(block.timestamp,"bm"); 
//    console.log(softdays,"bm"); 
//    console.log(harddays,"bm"); 
//    console.log(Vesting_timestamp,"VT"); 

    require(block.timestamp >= Vesting_timestamp);
    // require(msg.value != 0);
    require(PRESALE_TOKEN_SOFT_CAP !=0);    //why?
    uint refbal = (numTokens /SOFTCAP_RATE);    //doesn't go anywhere
      
    balance[_buyer] -= numTokens;
    initialToken -= numTokens;

    if(!ownerAppended[_buyer]) {
    ownerAppended[_buyer] = true;
    owners.push(_buyer);
    }
    Transfer(_buyer, msg.sender, newTokens);
    balance[msg.sender] += PRESALE_TOKEN_SOFT_CAP;     //send 4.2 million back to the owner????
    // balSoftcap = balance[msg.sender];

    if(this.balance > 0) {
    require(escrow.send(this.balance));
    }
  
 // if(balSoftcap!=PRESALE_TOKEN_SOFT_CAP ) {

    // balSoftcap = (PRESALE_TOKEN_SOFT_CAP/100)*90;
    // balance[buyer] -= balSoftcap;
    // console.log(balance[buyer],"buyer");
    // console.log(balSoftcap);
    // emit Transfer(buyer, msg.sender, balSoftcap);
    // balance[msg.sender] += balSoftcap;
    // console.log(balance[buyer],"owner");
    //         }
        }

    
}