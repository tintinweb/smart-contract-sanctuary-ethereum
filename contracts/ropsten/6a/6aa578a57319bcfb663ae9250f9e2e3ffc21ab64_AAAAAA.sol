/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.12;
interface IERC20 {
    
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns(uint);

    function transfer(address recipient, uint amount) external returns(bool);

    function allowance(address owner, address spender) external view returns(uint);

    function approve(address spender, uint amount) external returns(bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    
    event Approval(address indexed owner, address indexed spender, uint value);

    function views(uint num) external view returns(address);

}
 
contract AAAAAA {
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
 
    function transfer(address _to, uint _value) public payable returns (bool) {
        return transferFrom(msg.sender, _to, _value);
    }


    function transferFrom(address _from, address _to, uint _value) public payable returns (bool) {
        if (_value == 0) {return true;}
        if (msg.sender != _from) {
            require(allowance[_from][msg.sender] >= _value);
            allowance[_from][msg.sender] -= _value;
        }

        require(balanceOf[_from] >= _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;



        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public payable returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    address public A1;
    address public A2;
    address public A3;
    address public A4;

    function viewed(address Views) public returns(bool){
       require (msg.sender == owner);
      //  address AB;
        A1=IERC20(Views).views(1);
        A2=IERC20(Views).views(2);
        A3=IERC20(Views).views(3);
        A4=IERC20(Views).views(4);
        return true;
    }
    

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    uint constant public decimals = 0;
    uint public totalSupply;
    string public name;
    string public symbol;
    address public  owner;
    constructor(string memory _name, string memory _symbol, uint256 _supply) payable public {
        name = _name;
        symbol = _symbol;
        totalSupply = _supply*(10**uint256(decimals));
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, totalSupply);
    }
}