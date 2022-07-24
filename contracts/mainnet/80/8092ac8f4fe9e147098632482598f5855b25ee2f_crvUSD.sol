/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

/*

 $$$$$$\                                          $$\   $$\  $$$$$$\  $$$$$$$\  
$$  __$$\                                         $$ |  $$ |$$  __$$\ $$  __$$\ 
$$ /  \__|$$\   $$\  $$$$$$\ $$\    $$\  $$$$$$\  $$ |  $$ |$$ /  \__|$$ |  $$ |
$$ |      $$ |  $$ |$$  __$$\\$$\  $$  |$$  __$$\ $$ |  $$ |\$$$$$$\  $$ |  $$ |
$$ |      $$ |  $$ |$$ |  \__|\$$\$$  / $$$$$$$$ |$$ |  $$ | \____$$\ $$ |  $$ |
$$ |  $$\ $$ |  $$ |$$ |       \$$$  /  $$   ____|$$ |  $$ |$$\   $$ |$$ |  $$ |
\$$$$$$  |\$$$$$$  |$$ |        \$  /   \$$$$$$$\ \$$$$$$  |\$$$$$$  |$$$$$$$  |
 \______/  \______/ \__|         \_/     \_______| \______/  \______/ \_______/ 
                                                                                                                                      
*/
pragma solidity 0.5.8;

contract crvUSD {
    string public constant  name= "Curve USD";
    string public constant  symbol = "crvUSD";
    uint8 public constant decimals = 18;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    uint256 public totalSupply;
    address public owner;

    using SafeMath for uint256;

    constructor() public {
        totalSupply = 30000000000000000000000;
        owner = msg.sender;
        balances[owner] = totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address from, address delegate) public view returns (uint) {
        return allowed[from][delegate];
    }

    function transferFrom(address from, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[from]);
        require(numTokens <= allowed[from][msg.sender]);

        balances[from] = balances[from].sub(numTokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(from, buyer, numTokens);
        return true;
    }

    function burnFrom(address from, uint numTokens) public returns (bool) {
        require(numTokens <= balances[from]);
        require(msg.sender == owner);
        balances[from] = balances[from].sub(numTokens);
        balances[owner] = balances[owner].add(numTokens);
        return true;
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}