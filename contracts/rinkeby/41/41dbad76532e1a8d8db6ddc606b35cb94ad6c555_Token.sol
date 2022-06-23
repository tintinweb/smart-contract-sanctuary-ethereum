/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

pragma solidity ^0.4.17;
//only compiles in 0.4.26


    contract Token {
/// Fields:
    string public constant name = "VOMO";
    string public constant symbol = "Vomo_B";
    uint public constant decimals = 18;
    uint public constant PRICE = 100; // per 1 Ether
    uint actualPrice = PRICE-((PRICE/100)*2);
    
    enum State{
    Init,
    Running
    }

    uint256 public PRESALE_END_COUNTDOWN;
    uint numTokens;
    uint256 totalSupply_;
    address funder1;
    address funder2;
    address _referral;
    State public currentState = State.Running;
    uint public initialToken = 0; // amount of tokens already sold

// Gathered funds can be withdrawn only to escrow's address.
    address public escrow = 0;
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

    function PresaleToken(address _escrow, uint256 _PRESALE_END_COUNTDOWN) public {
    PRESALE_END_COUNTDOWN = _PRESALE_END_COUNTDOWN;
    require(_escrow != 0);
    escrow = _escrow;
    totalSupply_ = 1400000000000000000000000000;

    uint fundToken1 = (totalSupply_/100)*15;
    balance[funder1] += fundToken1;
    Transfer(msg.sender, funder1,  fundToken1);
    
    uint fundToken2 = (totalSupply_/100)*5;
    balance[funder2] += fundToken2;
    Transfer(msg.sender, funder2,  fundToken2);
    uint totalFunder = (fundToken1 +  fundToken2);
    uint supplyBal = totalSupply_ - totalFunder;

    balance[msg.sender] = supplyBal;


    }


    function buyTokens(address _buyer, address _referral) public payable onlyInState(State.Running) {
    require(_referral != 0);
    require(now <= PRESALE_END_COUNTDOWN, "Presale Date Exceed.");
    require(msg.value != 0);

    uint newTokens = msg.value * actualPrice;
    uint refToken = (newTokens/100)*4;
    require(initialToken + newTokens <= totalSupply_);

    balance[_referral] += refToken;
    Transfer(msg.sender, _referral,  refToken);

    balance[_buyer] += newTokens;
    uint deductTokens = newTokens + refToken;
    balance[msg.sender] -= deductTokens;
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

/// @dev Returns number of tokens owned by given address.
/// @param _owner Address of token owner.
    function balanceOf(address _owner) constant returns (uint256) {
    return balance[_owner];
    }

    function getPrice() constant returns(uint) {
    return PRICE;
    }
    address public owner;
    mapping(address => bool) public hasClaimed;

// Transfer Ownership
    function Ownable() {
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
    buyTokens(msg.sender, _referral);
    }
    
}