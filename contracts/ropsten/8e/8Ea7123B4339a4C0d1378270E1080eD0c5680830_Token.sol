pragma solidity ^0.8.0;

// Safemath not needed anymore from sol 0.8 onwards
// import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Token {
    // Safemath not needed anymore from sol 0.8 onwards
    // using SafeMath for uint;

    //Variables
    string public name = "JoJo Coin";
    string public symbol = "JJC";
    uint256 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address =>mapping(address => uint256)) public allowance; //Tracks how many tokens the exchange is allowed to spend. First address is yours, second is the exchange


    //Events
    event Transfer(address indexed from, address indexed to, uint256 value);        //indexed means only the events in which we're the receiver/sender?
    event Approval(address indexed owner, address indexed spender, uint256 value);


    constructor() {
        totalSupply = 1000000 * (10 ** decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal{
        require(_to != address(0));
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    // Approve tokens - Allow someone else to spend our tokens
    function approve(address _spender, uint256 _value) public returns (bool success){
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    // Transfer from
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
}