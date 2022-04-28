/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

pragma solidity ^0.4.17;

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Aureus is ERC20Interface{
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint public decimals;
    uint public bonusEnds;
    uint public icoEnds;
    uint public icoStarts;
    uint public allContributers;
    uint allTokens;
    address admin;
    mapping (address => uint) public balances;
    mapping(address => mapping(address => uint)) allowed;

    function Aureus () public {
        name = "Aureus Coin";
        decimals = 18;
        symbol = "AUS";
        bonusEnds = now + 2 weeks;
        icoEnds = now + 4 weeks;
        icoStarts = now;
        allTokens = 1000000000000000000 * 100000;   // equals 10,000 coin initial supply
        admin = (msg.sender);
        balances[msg.sender] = allTokens;
    }

    // needed for erc20 interface
    function totalSupply() public constant returns (uint) {
        return allTokens;
    }
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    function transfer(address to, uint tokens) public returns (bool success) {
        require(tokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }
    function burnCoin(address tokenOwner, uint tokens) public returns (bool success) {
        require(msg.sender == admin);
        require(tokens > 0);
        require(tokens <= balances[tokenOwner]);
        balances[tokenOwner] = balances[tokenOwner].sub(tokens);
        allTokens = allTokens.sub(tokens);
        Transfer(tokenOwner, address(0), tokens);
        return true;
    }
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(tokens <= balances[from]);
        require(tokens <= allowed[from][msg.sender]);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    // --->

    function myBalance() public constant returns (uint){
        return (balances[msg.sender]);
    }

    function myAddress() public constant returns (address){
        address myAdr = msg.sender;
        return myAdr;
    }

    function buyAureus(uint tokens) public payable {
        balances[msg.sender] = balances[msg.sender].add(tokens);
        allTokens = allTokens.add(tokens);
        Transfer(address(0), msg.sender, tokens);
        allContributers++;
    }
    // 100 DC token == 1 Ether
    function buyTokens() public payable {
        uint tokens;
        //if(now <= bonusEnds) {
        //    tokens =  msg.value.mul(125);  // 25% bonus
        //}else {
            tokens =  msg.value.mul(100); // no bonus
        //}
        balances[msg.sender] = balances[msg.sender].add(tokens);
        allTokens = allTokens.add(tokens);
        Transfer(address(0), msg.sender, tokens);
        allContributers++;
    }

}