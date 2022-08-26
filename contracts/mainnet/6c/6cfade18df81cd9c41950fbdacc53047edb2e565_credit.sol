/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Imperial Credits
 * @dev create a Ownable and Mintable ERC 20 token
*/

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}


contract Ownable { 
  // Variable that maintains 
  // owner address
  address private _owner;
  
  // Sets the original owner of 
  // contract when it is deployed
  constructor()
  {
    _owner = msg.sender;
  }
  
  // Publicly exposes who is the
  // owner of this contract
  function owner() public view returns(address) 
  {
    return _owner;
  }
  
  // onlyOwner modifier that validates only 
  // if caller of function is contract owner, 
  // otherwise not
  modifier onlyOwner() 
  {
    require(isOwner(),
    "Function accessible only by the owner !!");
    _;
  }
  
  // function for owners to verify their ownership. 
  // Returns true for owners otherwise false
  function isOwner() public view returns(bool) 
  {
    return msg.sender == _owner;
  }
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract credit is IERC20, Ownable{
    using SafeMath for uint;
    mapping(address => uint256) balances;
 
    // Mapping owner address to
    // those who are allowed to
    // use a certain number of their moey
    mapping(address => mapping (
            address => uint256)) allowed;

    uint _totalSupply;

    string public _name;
    string public _symbol;
    uint8 public _decimals;

    constructor() Ownable() {
        //set info
        _name = "Imperial Credits";
        _symbol = "$CREDIT";
        _decimals = 5;
        _totalSupply = 2000000000 * 10**5;
        // give all of the credits to contract creator
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function _mint(address to, uint value) public onlyOwner {
        _totalSupply = _totalSupply.add(value);
        balances[to] = balances[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) public onlyOwner {
        balances[from] = balances[from].sub(value);
        _totalSupply = _totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function name() public override view returns (string memory) {
        return _name;
    }
    function symbol() public override view returns (string memory){
        return _symbol;
    }
    function decimals() public override view returns (uint8){
        return _decimals;
    }
    
    // totalSupply function
    function totalSupply() public override view returns (uint){
        return _totalSupply;
    }

    // balanceOf function
    function balanceOf(address _owner) public override view returns (uint balance) {
        return balances[_owner];
    }
    
    // function approve
    function approve(address _spender, uint _amount) public override returns (bool success) {
        // If the address is allowed
        // to spend from this contract
        // if he have the token he send
        allowed[msg.sender][_spender] = _amount;
        
        // Fire the event "Approval"
        // to execute any logic that
        // was listening to it
        emit Approval(msg.sender,
                        _spender, _amount);
        return true;
    }
    
    // transfer function
    function transfer(address _to, uint _amount) public override returns (bool success) {
        // transfers the value if
        // balance of sender is
        // greater than the amount
        if (balances[msg.sender] >= _amount) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            
            // Fire a transfer event for
            // any logic that is listening
            emit Transfer(msg.sender,
                        _to, _amount);
                return true;
        }
        else {
            //no token
            return false;
        }
    }
    
    
    /* The transferFrom method is used for
    a withdraw workflow, allowing
    contracts to send tokens on
    your behalf, for example to
    "deposit" to a contract address
    and/or to charge fees in sub-currencies;*/
    function transferFrom(address _from, address _to, uint _amount) public override returns (bool success)
    {
    if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            balances[_to] += _amount;
            
            // Fire a Transfer event for
            // any logic that is listening
            emit Transfer(_from, _to, _amount);
        return true;
    
    }
    else
    {
        return false;
    }
    }
    
    // Check if address is allowed
    // to spend on the owner's behalf
    function allowance(address _owner, address _spender) public override view returns (uint remaining)
    {
    return allowed[_owner][_spender];
    }

}