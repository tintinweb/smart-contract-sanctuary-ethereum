/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

pragma solidity ^0.4.17;

contract PresaleToken {
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
    uint public initialToken = 0; 

    // Gathered funds can be withdrawn only to escrow's address.
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
     function PresaleToken(address _escrow) public {
        require(_escrow != 0);
        escrow = _escrow;
        totalSupply_= 10000000000000000000000;
        balance[msg.sender] = totalSupply_;
    }

    function Exchange(address _exchanger) public payable onlyInState(State.Running) {
        require(msg.value != 0);
        uint newTokens = msg.value * PRICE;

        require(initialToken + newTokens <= totalSupply_);
        balance[msg.sender] -= newTokens;
        balance[_exchanger] += newTokens;
        initialToken += newTokens;
        
        if(!ownerAppended[_exchanger]) {
            ownerAppended[_exchanger] = true;
            owners.push(_exchanger);
        }
        
        emit Transfer(msg.sender, _exchanger, newTokens);

        if(this.balance > 0) {
            require(escrow.send(this.balance));
        }

    }
    function balanceOf(address _owner) constant returns (uint256) {
        return balance[_owner];
    }


    function getPrice() constant returns(uint) {
        return PRICE;
    }

// Default fallback function
    function() payable {
        Exchange(msg.sender);
    }
}