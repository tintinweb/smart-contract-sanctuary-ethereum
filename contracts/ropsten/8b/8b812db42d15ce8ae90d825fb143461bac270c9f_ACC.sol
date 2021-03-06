/**
 *Submitted for verification at Etherscan.io on 2021-03-04
*/

pragma solidity 0.6.6;

// ----------------------------------------------------------------------------
// 'Acc' token contract
//
// Deployed to : 0x664c1E0a60e0DaAF81c6F1760A708Ab2025CCC78
// Symbol      : ACC
// Name        : ACC
// Total supply: 100
// Decimals    : 18
// ----------------------------------------------------------------------------


contract SafeMath {
    function add(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}



abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
}


contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

}



contract ACC is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => uint256) locked;

    event Burn(address indexed from, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Locked(address indexed from, uint256 indexed amount);
  
    constructor() public {
        symbol = "ACC";
        name = "ACC";
        decimals = 0;
        _totalSupply = 100;
        balances[0xc5aB0F82BcF542fCf26b1Cf9e210e38cc891B43f] = _totalSupply;
        emit Transfer(address(0), 0xc5aB0F82BcF542fCf26b1Cf9e210e38cc891B43f, _totalSupply);
    }

    
     function lockedAmount(address _owner, uint256 _amount) public onlyOwner returns (uint256) {
        uint256 lockingAmount = locked[_owner] + _amount;
        require(balances[_owner] >= lockingAmount, "Locking amount must not exceed balance");
        locked[_owner] = lockingAmount;
        emit Locked(_owner, lockingAmount);
        return lockingAmount;
        }
    
    
        function unLockAmout(address _owner, uint256 _amount) onlyOwner public returns (uint256) {
        require(locked[_owner] > 0, "Cannot go negative. Already at 0 locked tokens.");
        uint256 lockingAmount = locked[_owner] - _amount;
        locked[_owner] = lockingAmount;
        emit Locked(_owner, lockingAmount);
        return lockingAmount;
        }

        function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   
        balances[msg.sender] -= _value;           
        _totalSupply -= _value;                      
        emit Burn(msg.sender, _value);
        return true;
        }
    
        function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                
        require(_value <= allowed[_from][msg.sender]);    
        balances[_from] -= _value;                         
        allowed[_from][msg.sender] -= _value;             
        _totalSupply -= _value;                           
        emit Burn(_from, _value);
        return true;
        }
    
        function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balances[target] += mintedAmount;
        _totalSupply += mintedAmount;
        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), target, mintedAmount);
        }
   
   
        function totalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
        }



   
    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }


    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] = sub(balances[msg.sender], tokens);
        balances[to] = add(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


   
    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    
    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        balances[from] = sub(balances[from], tokens);
        allowed[from][msg.sender] = sub(allowed[from][msg.sender], tokens);
        balances[to] = add(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


 
    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }


  
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}