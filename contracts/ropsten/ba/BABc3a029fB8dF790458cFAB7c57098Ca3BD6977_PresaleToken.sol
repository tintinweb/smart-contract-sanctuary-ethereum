/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

pragma solidity ^0.4.17;

contract PresaleToken {
    /// Fields:
    string public constant name = "INU_Infinity";
    string public constant symbol = "INU";
    uint public constant decimals = 18;
    uint public constant PRICE = 100;  // per 1 Ether

    //  price
    // Cap is 4000 ETH
    // 1 eth = 100;  presale 
    // uint public constant TOKEN_SUPPLY = 50000000 ;

    enum State{
        Init,
        Running
    }

    uint256 totalSupply_;

    // constructor() {
    //   totalSupply_ = 50000000;
    //   balance[msg.sender] = totalSupply_;
    // }

    State public currentState = State.Running;
    uint public initialToken = 0; // amount of tokens already sold

    // Gathered funds can be withdrawn only to escrow's address.
    address public escrow = 0;
    mapping (address => uint256) private balance;
    mapping (address => bool) ownerAppended;
    address[] public owners;

    /// Modifiers:
    modifier onlyInState(State state){ require(state == currentState); _; }

    /// Events:

    event Transfer(address indexed _from, address indexed _to, uint256 _value);


    /// Functions:
    /// @dev Constructor
     function PresaleToken(address _escrow) public {
        require(_escrow != 0);
        escrow = _escrow;
        totalSupply_ = 50000000000000000000000000;
        balance[msg.sender] = totalSupply_;
    }

    function buyTokens(address _buyer) public payable onlyInState(State.Running) {
        require(msg.value != 0);
        uint newTokens = msg.value * PRICE;

        require(initialToken + newTokens <= totalSupply_);

        balance[_buyer] += newTokens;
        initialToken += newTokens;
        
        if(!ownerAppended[_buyer]) {
            ownerAppended[_buyer] = true;
            owners.push(_buyer);
        }
        
        Transfer(msg.sender, _buyer, newTokens);

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
//Tranfer Function
   
    function transfer(address receiver, uint numTokens) public returns (bool) {
    require(numTokens <= balance[msg.sender]);
    balance[msg.sender] -= numTokens;
    balance[receiver] += numTokens;
    emit Transfer(msg.sender, receiver, numTokens);
    return true;
    }
// Tranfer Owbnership
    function Ownable() {
    owner = msg.sender;
    }

    modifier onlyOwner() {
    require(msg.sender == owner);
_   ;
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
}