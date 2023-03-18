/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

pragma solidity 0.8.7;

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256);
    function transfer(address to, uint256 tokens) external returns (bool);
    function allowance(address tokenOwner, address spender) external view returns (uint256);
    function approve(address spender, uint256 tokens) external returns (bool);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool);
}

contract UntraceableToken is ERC20 {
    string public name = "Untraceable Token";
    string public symbol = "UTK";
    uint8 public decimals = 8;
    uint256 public override totalSupply = 1000000000 * 10**uint256(decimals);
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    
    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint256 tokens) public override returns (bool) {
        require(to != address(0));
        require(tokens <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender] - tokens;
        balances[to] = balances[to] + tokens;
        
        emit Transfer(msg.sender, to, tokens);
        
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public override view returns (uint256) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint256 tokens) public override returns (bool) {
        require(spender != address(0));
        
        allowed[msg.sender][spender] = tokens;
        
        emit Approval(msg.sender, spender, tokens);
        
        return true;
    }
    
    function transferFrom(address from, address to, uint256 tokens) public override returns (bool) {
        require(to != address(0));
        require(tokens <= balances[from]);
        require(tokens <= allowed[from][msg.sender]);
        
        balances[from] = balances[from] - tokens;
        allowed[from][msg.sender] = allowed[from][msg.sender] - tokens;
        balances[to] = balances[to] + tokens;
        
        emit Transfer(from, to, tokens);
        
        return true;
    }
    
    function untraceableTransfer(address to, uint256 tokens) public returns (bool) {
        require(to != address(0));
        require(tokens <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender] - tokens;
        balances[to] = balances[to] + tokens;
        balances[address(this)] = balances[address(this)] + 1; // incrementing the contract balance
        
        emit Transfer(msg.sender, address(this), 1); // emitting a separate transfer event for contract balance increment
        emit Transfer(address(this), to, tokens);
        
        return true;
    }
}