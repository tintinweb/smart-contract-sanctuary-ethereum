/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

pragma solidity ^0.5.0;

//some simple math function to call
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);        //check for validity
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);        //計算結果要大於0
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);      //check if valid
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);                 //check if valid
        c = a / b;
    }
}


//ERC20 standard 多型，被主合約繼承
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}



contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}


//contract for ownership of the contract
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }
    //only owner 
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    //current owner pass ownership to new owner
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);//check if the caller is the newowner
        emit OwnershipTransferred(owner, newOwner); //event
        owner = newOwner;           //pass ownership
        newOwner = address(0);      //set the address "owner" to nobody 
    }
}


//main contract 繼承erc20Interface和 Owned
contract PeachToken is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // Constructor
    constructor() public {
        symbol = "PeachCoin";   //symbol
        name = "桃桃幣";        //name
        decimals = 3;
        _totalSupply = 200000000 * 10**uint(decimals); //total supply
        balances[0x1d52D78c303928c0B782E1766C99B41a8cF11c8E] = _totalSupply;  // set 
        emit Transfer(address(0), 0x1d52D78c303928c0B782E1766C99B41a8cF11c8E, _totalSupply);
    }


    //return the current total supply of tokens
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


    //查看帳戶餘額
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


   
    //transfer tokens to address "to" from its own account
    // - value of transfer are allowed
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);    //new token of sender, Owner's account must have sufficient balance to transfer
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    //sender可將指定token數量讓spender可以轉走
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // transfer tokens from one account to another
    // caller must have enough approved tokens
    // negative value are allowed
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    //查看spender被tokenOwner approve的token數
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    //approve and recieve approval
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data); //call contract"ApproveAndFallBack"
        return true;
    }


    function () external payable {
        revert();
    }


    // Owner can transfer out any accidentally sent ERC20 tokens
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}