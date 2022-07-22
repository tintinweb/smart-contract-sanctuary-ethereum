/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

pragma solidity 0.8.15;
    contract VomoPresale {
/// Fields:
    string public constant name = "VOMO";
    string public constant symbol = "Vomo";
    uint public constant decimals = 18;
    uint public constant PRICE = 100; // per 1 Ether
    uint actualPrice =PRICE-((PRICE/100)*2);
    
    enum State{
    Init,
    Running
    }
    uint256 public PRESALE_END_COUNTDOWN;
    uint numTokens;
    uint256 totalSupply_;
    address funder1 = 0x69e56D0aF44380BC3B0D666c4207BBF910f0ADC9;
    address funder2 = 0x11a99181d9d954863B41C3Ec51035D856b69E9e8;
    address _referral;
    State public currentState = State.Running;
    uint public initialToken = 0; // amount of tokens already sold

// Gathered funds can be withdrawn only to escrow's address.
    address public escrow ;
    mapping (address => uint256) private balance;
    mapping (address => bool) ownerAppended;
    address[] public owners;

/// Modifiers:
    modifier onlyInState(State state){ require(state == currentState); _; }

/// Events:

    event Transfer(address indexed from, address indexed to, uint256 _value);

/// Functions:
    constructor(address _escrow, uint256 _PRESALE_END_COUNTDOWN) public {
    PRESALE_END_COUNTDOWN = _PRESALE_END_COUNTDOWN;
    require(_escrow != address(0));
    escrow = _escrow;
    totalSupply_ = 1400000000000000000000000000;

    uint fundToken1 = (totalSupply_/100)*15;
    balance[funder1] += fundToken1;
   emit Transfer(msg.sender, funder1,  fundToken1);
    
    uint fundToken2 = (totalSupply_/100)*5;
    balance[funder2] += fundToken2;
   emit Transfer(msg.sender, funder2,  fundToken2);
    uint totalFunder = (fundToken1 +  fundToken2);
    uint supplyBal = totalSupply_ - totalFunder;

    balance[msg.sender] = supplyBal;


    }


    function buyTokens(address _buyer, address _referral) public payable onlyInState(State.Running) {
    require(_referral !=  _buyer);
    require(block.timestamp <= PRESALE_END_COUNTDOWN, "Presale Date Exceed.");
    require(msg.value != 0);
    uint newTokens = msg.value * actualPrice;
    uint reftokensVal = msg.value * PRICE;
    if (msg.value>=13152000000000000) {
        uint refToken = (reftokensVal/100)*4;
        balance[_referral] += refToken;
   emit Transfer(msg.sender, _referral,  refToken);
    }
    require(initialToken + newTokens <= totalSupply_);

    balance[_buyer] += newTokens;
    initialToken += newTokens;
    if(!ownerAppended[_buyer]) {
    ownerAppended[_buyer] = true;
    owners.push(_buyer);
    }
   emit Transfer(msg.sender, _buyer,  newTokens);
   
    if(address(this).balance > 0) {
    payable (escrow).send(address(this).balance);
    }

    }

/// @dev Returns number of tokens owned by given address.
/// @param _owner Address of token owner.
   function balanceOf(address _owner) public view virtual returns (uint256) {
        return balance[_owner];
    }

    function getPrice() public view virtual returns(uint) {
    return PRICE;
    }
    address public owner;

//Transfer Function
    // uint numTokens = 1000000000000000000;
    mapping(address => bool) public hasClaimed;
    
// // Transfer Ownership
    function Ownable() public {
    owner = msg.sender;
    }

    modifier onlyOwner() {
    require(msg.sender == owner);
    _ ;
    }
    function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
    owner = newOwner;
    }
    }

// Default fallback function
    function fallback () public payable {
    buyTokens(msg.sender, _referral);
    }
    
}