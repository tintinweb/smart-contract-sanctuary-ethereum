pragma solidity  0.4.24;
import './SafeMath.sol';

/**

    GOMT Token implementation

*/

contract GOMT is SafeMath {

    string public constant standard = 'Token 0.1';

    uint8 public constant decimals = 8;

 

    string public constant name = 'GoMeat';

    string public constant symbol = 'GOMT';

   

    uint256 public constant totalSupply = 10 ** 6 * 5 * 10 ** uint256(decimals);

 

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

 

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

 

    function GOMT()

    public{

        balanceOf[msg.sender] = totalSupply;

    }

 

    modifier validAddress(address _address) {

        require(_address != 0x0);

        _;

    }

 

    function transfer(address _to, uint256 _value)

    external

    validAddress(_to)

    returns(bool success)

    {

        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);

        balanceOf[_to] = safeAdd(balanceOf[_to], _value);

        Transfer(msg.sender, _to, _value);

        return true;

    }

 

    function transferFrom(address _from, address _to, uint256 _value)

    external

    validAddress(_from)

    validAddress(_to)

    returns(bool success)

    {

        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);

        balanceOf[_from] = safeSub(balanceOf[_from], _value);

        balanceOf[_to] = safeAdd(balanceOf[_to], _value);

        Transfer(_from, _to, _value);

        return true;

    }

 

    function approve(address _spender, uint256 _value)

    external

    validAddress(_spender)

    returns(bool success)

    {

        require(_value == 0 || allowance[msg.sender][_spender] == 0);

        allowance[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;

    }

 

    function () public payable {

        revert();

    }

}