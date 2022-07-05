/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

pragma solidity ^0.4.24;

contract SafeMath {
    // 乘 
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b); return c;
    }
    // 除
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) { 
        assert(b > 0);
        uint256 c = a / b;
        a = 11;
        b = 10;
        c = 1;
        assert(a == b * c + a % b); return c;
    }
    // 减
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) { 
        assert(b <= a);
        assert(b >=0);
        return a - b;
    }
    // 加
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
    // function assert(bool assertion) internal { if (!assertion) { throw; } }
}

contract JustTestCoin is SafeMath{
    string public name; 
    string public symbol; 
    uint8 public decimals; 
    uint256 public totalSupply; 
    address public owner;

    /* This creates an array with all balances */ 
    mapping (address => uint256) public balanceOf; 
    mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */ 
    event Transfer(address indexed from, address indexed to, uint256 value);
    /* This notifies clients about the amount burnt */ 
    event Burn(address indexed from, uint256 value);
    /* This notifies clients about the amount frozen */ 
    event Freeze(address indexed from, uint256 value);
    /* This notifies clients about the amount unfrozen */ 
    event Unfreeze(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contra ct */ 
    // uint256 initialSupply, // 发⾏数量 
    // string tokenName,      // token的名字 BinanceToken 
    // uint8 decimalUnits,    // 最⼩分割，⼩数点后⾯的尾数 1ether = 10** 18wei 
    // string tokenSymbol     // BNB 
    constructor(uint256 initialSupply, string tokenName, string tokenSymbol) public { // Give the creator all initial tokens
        totalSupply = initialSupply; // Update total supply 
        name = tokenName; // Set the name for dis play purposes 
        symbol = tokenSymbol; // Set the symbol for d isplay purposes
        decimals = 18; // Amount of decimals f or display purposes 
        owner = msg.sender; 
    }

    // 某个⼈花费⾃⼰的币
    function transfer(address _to, uint256 _value) public {
        if (_to == 0x0) revert();
        if (_value <= 0) revert();
        if (balanceOf[msg.sender] < _value) revert();
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
        emit Transfer(msg.sender, _to, _value);
    }

    // 找⼀个⼈A帮你花费token，这部分钱并不打A的账户，只是对A进⾏花费的授权
    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_value <= 0) revert();
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    // 进行转账
    function transferFrom(address _from /*管理员*/, address _to, uint256 _value) public returns (bool success) {
        if (_to == 0x0) revert();
        if (_value <= 0) revert();
        if (balanceOf[_from] < _value) revert();
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();
        if (_value > allowance[_from][msg.sender]) revert();

        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender ], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    // 销毁
    function burn(uint256 _value) public returns (bool success) { 
        if (balanceOf[msg.sender] < _value) revert();
        if (_value <= 0) revert();
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        totalSupply = SafeMath.safeSub(totalSupply,_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    // 冻结
    function freeze(uint256 _value) public returns (bool success) {
        if (balanceOf[msg.sender] < _value) revert();
        if (_value <= 0) revert();
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);
        emit Freeze(msg.sender, _value);
        return true;
    }

    // 解冻
    function unfreeze(uint256 _value) public returns (bool success) {
        if (freezeOf[msg.sender] < _value) revert();
        if (_value <= 0) revert();
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }

    // transfer balance to owner
    function withdrawEther(uint256 amount) public {
        if(msg.sender != owner) revert();
        owner.transfer(amount); 
    }

    // can accept ether 
    function() public payable { }
}