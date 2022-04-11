/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

pragma solidity ^0.4.24;
 
//@title Safe Math contract
contract SafeMath {
    
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
 
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
 
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
 
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
}

// @title Ownable
contract Ownable {
    
    address public owner;

    constructor() public{
        owner=msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
  }

}

 
 
//@title ERC Token Standard #20 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
 
    event Transfer(address indexed from, address indexed to, uint tokens);
}
 
 // @title Actual token contract
 
contract NikiToken is ERC20Interface, SafeMath, Ownable {
    
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public totalNumberOfTokens;
    bool public active;
    uint public _raisedAmount;
    uint public tokensPerWei=3;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event BoughtTokens(address to, uint256 value);
 
    constructor() public {
        symbol = "NK";
        name = "Niki Token";
        totalNumberOfTokens = 100;
        active=true;
    }



    // returns raised amount from token sale
    function raisedAmount()  public view onlyOwner returns(uint256) {
        return _raisedAmount;
    }
    
    // sets true if selling of tokens is active
    // sets false if selling of token is not active
    // only owner can determine if selling is active
    function setAcitve(bool trueOrFalse) public onlyOwner {
        active=trueOrFalse;
    }

    // returns if selling of tokens is acitve
    function isActive() public view returns(bool) {
        return active;
    }

    // only lets function exicutes if sale is actice
    modifier whenSaleIsActive() {
    // Check if sale is active
    assert(isActive());
    _;
  }

    // returns how many tokens are left for sale
    function totalSupply() public constant returns (uint) {
        return totalNumberOfTokens;
    }
  
    // ERC20 function, returnig how many tokens token owner has
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
 
    //ERC 20 function, transfers amount of tokens that token owner wants to send using safeMath
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
 
 
    // Only lets token selling if there are tokens left to buy for meesage value
    modifier ifTokensAreAvailable(uint256 messageValue) {
        uint256 weiAmount = messageValue; // Calculate tokens to sell
        uint256 tokens = safeMul(weiAmount,3);
        require(totalNumberOfTokens>= tokens);
        _;
    }

    // Function for buying tokens
    function buyTokens() public payable ifTokensAreAvailable(msg.value) whenSaleIsActive{
        uint256 weiAmount = msg.value; // Calculate tokens to sell
        uint256 tokens = safeMul(weiAmount,tokensPerWei);

        balances[msg.sender]=safeAdd(balances[msg.sender],tokens) ; // Updating balances
        totalNumberOfTokens=safeSub(totalNumberOfTokens,tokens); // Updates how many tokens left
        _raisedAmount=safeAdd(_raisedAmount,msg.value); // Updates raised amount
       
        emit BoughtTokens(msg.sender, tokens); //emit that a token is bought
  }
     // Fallback function
     // Prevent accounts from directly sending ETH to the contract
     function () public payable {
         revert();
     }

}