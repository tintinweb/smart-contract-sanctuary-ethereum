pragma solidity ^0.6.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ERC20Basic is IERC20 {

    string public constant name = "Taca Token";
    string public constant symbol = "TACA";
    uint8 public constant decimals = 18;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_ = 10000000000000000000000000;
    uint256 maxSupply_ = 100000000000000000000000000;

    address public contractOwner;

    using SafeMath for uint256;

    modifier onlyOwner {
        
        require(msg.sender == contractOwner);
        _;
    }

    constructor(address tokenOwner) public {

        contractOwner = tokenOwner;
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns (uint256) {
        
        return totalSupply_;
    }

    function maxSupply() public view returns (uint256) {
        
        return maxSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        
        require(numTokens <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        
        allowed[msg.sender][delegate] = numTokens;
        
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        
        require(account != address(0));
        require(totalSupply_ + amount <= maxSupply_);

        totalSupply_ = totalSupply_.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwner {
        
        require(account != address(0));
        require(amount <= balances[account]);

        totalSupply_ = totalSupply_.sub(amount);
        balances[account] = balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
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

contract DEX {

    event Bought(uint256 amount);
    event Sold(uint256 amount);

    address public contractAddress;

    IERC20 public token;

    uint256 tokenPrice;

    constructor(uint256 _tokenPrice) public {
        
        contractAddress = address(this);
        tokenPrice = _tokenPrice;
        token = new ERC20Basic(msg.sender);
    }

    function buy() payable public {
        
        uint256 amountTobuy = msg.value * tokenPrice;
        uint256 dexBalance = token.balanceOf(address(this));
        
        require(amountTobuy > 0, 'Insuficient ETH Sent Quantity');
        require(amountTobuy <= dexBalance, 'Insuficient DEX Balance');
        
        token.transfer(msg.sender, amountTobuy);
        
        emit Bought(amountTobuy);
    }

    function sell(uint256 amount) public {
        
        require(amount > 0, 'Insuficient Sent Token Quantity');
        
        uint256 allowance = token.allowance(msg.sender, address(this));
        
        require(allowance >= amount, 'Insuficient Account Allowance');
        
        token.transferFrom(msg.sender, address(this), amount);
        msg.sender.transfer(amount/tokenPrice);
        
        emit Sold(amount);
    }

}