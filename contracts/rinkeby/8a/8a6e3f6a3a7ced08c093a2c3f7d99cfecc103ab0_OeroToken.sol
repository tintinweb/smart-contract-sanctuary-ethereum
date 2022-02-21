/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

pragma solidity ^0.8.11;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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


//https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/IERC20.sol
interface IERC20 {

    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


interface IBurnable {

    function burn(uint _amount) external returns (bool);

    event Burn(address indexed burner, uint indexed value);
}

interface IMintable {
    
    function mint(address _to, uint256 _amount) external returns (bool);

    event Mint(address indexed to, uint256 amount);
}


interface IBlacklistedAddress {

    function isBlacklistedAddr(address addr) external returns(bool);

    function markAsBlackAddr(address blackAddr) external returns (bool);

    function clearAddr(address whiteAddr) external returns (bool);
   
    event BlackAddr(address blackAddr);

    event WhiteAddr(address whiteAddr);
}


contract Ownable {

  address public owner;

  constructor(address _newOwner) {
      owner = _newOwner;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }
}


contract OeroToken is IERC20, IBurnable, IMintable, IBlacklistedAddress, Ownable {

using SafeMath for uint256;

    string  public constant name = "OERO";

    string  public constant symbol = "OEUR";

    string  public constant standard = "OERO v1.0"; //?????????????

    uint8 public constant decimals = 2;

    //uint256 public totalSupply;
    uint256 private _totalSupply;

    uint256 public constant MAX_SUPPLY = 1000000000;

    mapping(address => bool) public frozen;

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    address public contract_addr;

    constructor(address newOwner) Ownable(newOwner) {
        balances[newOwner] = 100000000;
        _totalSupply = 100000000;
        contract_addr = address(this);
    }


    //IBurnable-BEGIN
    function burn(uint256 _amount) public onlyOwner returns (bool success){
        require(balances[msg.sender] >= _amount);

        balances[msg.sender] = balances[msg.sender].sub(_amount);
        _totalSupply = _totalSupply.sub(_amount);
        emit Burn(address(msg.sender), _amount);
        emit Transfer(address(msg.sender), address(0x0), _amount);

        return true;
    }
    //IBurnable-END



    //IMintable-BEGIN
    function mint(address _to, uint256 _amount) public onlyOwner returns(bool) {
        require(_totalSupply + _amount <= MAX_SUPPLY);

        _totalSupply = _totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0x0), _to, _amount);
        return true;
    }


    //IMintable-END



    //IBlacklistedAddress-BEGIN
    function isBlacklistedAddr(address addr) public view returns(bool) {
        return frozen[addr];
    }

    function markAsBlackAddr(address blackAddr) public onlyOwner returns(bool) {
        require(address(owner) != address(blackAddr)); //protection of owner address
        frozen[blackAddr] = true;
        emit BlackAddr(blackAddr);
        return true;
    }

     function clearAddr(address whiteAddr) public onlyOwner returns(bool) {
        frozen[whiteAddr] = false;
        emit WhiteAddr(whiteAddr);
        return true;
    }    
    //IBlacklistedAddress-END



    //IERC20-BEGIN

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        require(!isBlacklistedAddr(address(msg.sender)));
        require(!isBlacklistedAddr(_to)); //??????????????

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        require(!isBlacklistedAddr(_from));
        require(!isBlacklistedAddr(msg.sender));

        //var _allowance = allowed[_from][msg.sender];

        uint256 _allowance_amount = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        //allowed[_from][msg.sender] = _allowance.sub(_value);
        allowed[_from][msg.sender] = _allowance_amount.sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        require(!isBlacklistedAddr(msg.sender));
        require(!isBlacklistedAddr(_spender));//unnecessary!!!!!!!!!!!!!!

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    //IERC20-END


    function increaseApproval (address _spender, uint _addedValue) public
        returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public
        returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /* Interface declaration */
    function isToken() public pure returns (bool) {
        return true;
    }

}