/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

pragma solidity ^0.4.26;

contract Token {
    /// Fields:
    string public constant name = "Test Coin";
    string public constant symbol = "TTC";
    uint public constant decimals = 18;
    uint public constant PRICE = 10;  // per 1 Ether

 enum State{
        Init,
        Running
    }

    uint256 totalSupply_;


    State public currentState = State.Running;
    uint public initialToken = 0; // amount of tokens already sold

    address public escrow = 0;
    mapping (address => uint256) private balance;
    mapping (address => bool) ownerAppended;
    address[] public owners;

    /// Modifiers:
    modifier onlyInState(State state){ require(state == currentState); _; }

    /// Events:

    event Transfer(address indexed from, address indexed to, uint256 _value);


    /// Functions:
    /// @dev Constructor
     function Token(address _escrow) public {
        require(_escrow != 0);
        escrow = _escrow;
        totalSupply_ = 10000000000000000000000; //10000ETH convert into wei;
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
// Transfer Owbnership
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