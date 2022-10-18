/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
} 

contract Ownable {
    
    address public owner;
    
    function Ownable() public {
        owner = msg.sender;
    }
 
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
 
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
    
}
 
contract Ramamike_TokenCoin is Ownable {
    
    string public constant name = "Ramamike Token";
    
    string public constant symbol = "RAMA1";
    
    uint32 public constant decimals = 18;
    
    uint public totalSupply = 0;
    
    mapping (address => uint) balances;
    
    mapping (address => mapping(address => uint)) allowed;
    
    function mint(address _to, uint _value) public onlyOwner {
        assert(totalSupply + _value >= totalSupply && balances[_to] + _value >= balances[_to]);
        balances[_to] += _value;
        totalSupply += _value;
        Transfer(0x0, _to, _value);
    }
    
    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        balances[msg.sender] -= _value; 
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        if( allowed[_from][msg.sender] >= _value &&
            balances[_from] >= _value 
            && balances[_to] + _value >= balances[_to]) {
            allowed[_from][msg.sender] -= _value;
            balances[_from] -= _value; 
            balances[_to] += _value;
            Transfer(_from, _to, _value);
            return true;
        } 
        return false;
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }
    
    event Transfer(address indexed _from, address indexed _to, uint _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    
}

contract Ramamike_ICO {

    using SafeMath for uint;

    Ramamike_TokenCoin public token = new Ramamike_TokenCoin();
    
    uint start = 1644300000; // 08.02.2022 06:00:00
    
    uint period = 28;
    
    uint rate=1000000000000000000000; // 1 ether = 1000 toke

    address public owner=msg.sender;
     
    function() external payable {
        require(now > start && now < start + period*1 days);
        uint tokens=rate.mul(msg.value).div(1 ether);
        token.mint(msg.sender, tokens);
    }

    function showBalance() public constant returns (uint) {
        return this.balance;
    }

    function takeEther() public {
        require(msg.sender==owner && now > start );
        uint totalBalans=this.balance;
        owner.transfer(totalBalans);
    }
}