/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.4.26;

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;
        require(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}


////////////////////////////////////////////////////////////////////////////////

/*
 * ERC20Basic
 * Simpler version of ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
    uint public totalSupply;
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public returns(bool);
    event Transfer(address indexed from, address indexed to, uint value);
}

////////////////////////////////////////////////////////////////////////////////

/*
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint);
    function transferFrom(address from, address to, uint value) public returns(bool);
    function approve(address spender, uint value) public returns(bool);
    event Approval(address indexed owner, address indexed spender, uint value);
}

////////////////////////////////////////////////////////////////////////////////

/*
 * Basic token
 * Basic version of StandardToken, with no allowances
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) balances;

    /*
     * Fix for the ERC20 short address attack
     */
    modifier onlyPayloadSize(uint size) {
        if (msg.data.length < size + 4) {
         revert();
        }
        _;
    }

    function transfer(address _to, uint _value)  public onlyPayloadSize(2 * 32) returns(bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
      return balances[_owner];
    }
}


////////////////////////////////////////////////////////////////////////////////

/**
 * Standard ERC20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint)) allowed;

    function transferFrom(address _from, address _to, uint _value) public returns(bool){

        var _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already revert if this condition is not met
        if (_value > _allowance) revert();

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint _value) public returns(bool){
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}

////////////////////////////////////////////////////////////////////////////////

/*
 * SimpleToken
 *
 * Very simple ERC20 Token example, where all tokens are pre-assigned
 * to the creator. Note they can later distribute these tokens
 * as they wish using `transfer` and other `StandardToken` functions.
 */
contract SimpleToken is StandardToken {

    string public name = "Test";
    string public symbol = "TST";
    uint public decimals = 18;
    uint public INITIAL_SUPPLY = 10**(50+18);

    function TestToken(string _name, string _symbol, uint _decimals) public {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    event Burn(address indexed _burner, uint _value);

    function burn(uint _value) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value);
        Transfer(msg.sender, address(0x0), _value);
        return true;
    }

    // save some gas by making only one contract call
    function burnFrom(address _from, uint256 _value) public returns (bool) {
        transferFrom( _from, msg.sender, _value );
        return burn(_value);
    }
}

contract dex {
    address public token0=0x110a13FC3efE6A245B50102D2d79B3E76125Ae83;
    address public token1=0xaD6D458402F60fD3Bd25163575031ACDce07538D;
    uint public lastPrice=10;

    /*constructor (address tokenAddress1,address tokenAddress2){
    token0=tokenAddress1;
    token1=tokenAddress2;

    }*/


    function getBalance (address adres,address token) public view returns (uint256){
        uint256 balances = SimpleToken(token).balanceOf(adres)*10**(18-SimpleToken(token).decimals());
        return balances;
    }

    function divide(uint arda,uint baa) public view returns(uint256){
        return (arda*10**0)/baa;
    }

    function sync() public {
        uint256 token0Balance = getBalance(address(this),token0);
        uint256 token1Balance = getBalance(address(this),token1);
        lastPrice=(token0Balance*10**(18-SimpleToken(token0).decimals()))/(token1Balance*10**(18-SimpleToken(token1).decimals()));

    }

    function swap(uint256 amount) public{
        uint256 token0Balance = getBalance(address(this),token0);
        uint256 token1Balance = getBalance(address(this),token1);
        uint256 _recieveAmount1 = token0Balance/amount;
        uint256 _sendAmount1 = token1Balance/_recieveAmount1;

        SimpleToken(token0).transferFrom(msg.sender,address(this),amount);
        SimpleToken(token1).transfer(msg.sender,_sendAmount1);

    }

}