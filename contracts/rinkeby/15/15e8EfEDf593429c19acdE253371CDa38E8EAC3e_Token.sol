/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

pragma solidity >=0.7.0 <0.9.0;

interface ERC20 {

function totalSupply() external view returns (uint256 _totalSupply);
function balanceOf(address _owner) external view returns (uint256 balance);
function transfer(address _to, uint256 _value) external returns (bool success);
function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
function approve(address _spender, uint256 _value) external returns (bool success);
function allowance(address _owner, address _spender) external view returns (uint256 remaining);
event Transfer(address indexed _from, address indexed _to, uint _value);
event Approval(address indexed _owner, address indexed _spender, uint _value);

}

contract Token is ERC20 {
    string public constant symbol = "SHR";
    string public constant name = "Sahar";
    uint8 public constant decimals = 18;

    uint private constant __totalSupply = 10000000000;

    mapping (address => uint) private __balanceOf;
    mapping (address => mapping (address => uint)) private __allowances;

    constructor() public {
        __balanceOf[msg.sender] = __totalSupply;
    }

    function totalSupply() public pure override returns (uint256 _totalSupply){
        _totalSupply = __totalSupply;
    }

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        return __balanceOf[_owner];
    }

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        if (_value > 0 && _value <= balanceOf(msg.sender)) {
            __balanceOf[msg.sender] -= _value;
            __balanceOf[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success){
        if (__allowances[_from][msg.sender] > 0 &&
        _value > 0 &&
        __allowances[_from][msg.sender] >= _value
        && !isContract(_to)) {
            __balanceOf[_from] -= _value;
            __balanceOf[_to] += _value;
            emit Transfer(_from, _to, _value);
            return true;
        }
        return false;

    }

    function isContract(address _addr) public view returns (bool) {
        uint codeSize;
        assembly {
            codeSize := extcodesize(_addr)
        }
        return codeSize > 0;    
    }

    function approve(address _spender, uint256 _value) public override returns (bool success){
        __allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256 remaining) {
        return __allowances[_owner][_spender];
    }


}