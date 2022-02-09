/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.8;

contract Snw {
    //mapping represents how much each user has in token
    mapping(address => uint) public balanceOf;
    mapping(address =>  mapping(address => uint)) public allowance;
    // function name() public view returns (string)
    // function symbol() public view returns (string)
    // function decimals() public view returns (uint8)
    // function totalSupply() public view returns (uint256)
    string public name = "Snow Inu";
    string public symbol = "SNWinu";
    uint256 public totalSupply = 7000000000*10**18; // 1 billion tokens
    uint256 public decimals = 18;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }


    // function balanceOf(address _owner) public view returns (uint256 balance)
    // function transfer(address _to, uint256 _value) public returns (bool success)
    function transfer(
        address _to, 
        uint256 _amount
        ) 
        public 
        returns 
        (bool success)
        {
        beforeTokenTransfer(_to, _amount);
        require(balanceOf[msg.sender] >= _amount);
        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        bool _bool = true;
        afterTokenTransfer(msg.sender, _to, _amount, _bool);
        return _bool;
      

    }
    // function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _amount
        ) 
        public 
        returns 
        (bool success)
        {

        require(_amount <= balanceOf[_from]);
        require(_amount <= allowance[_from][msg.sender]);
        allowance[_from][_to] -= _amount;
        balanceOf[_from] -= _amount;
        balanceOf[_to] += _amount;
        emit Transfer(_from, _to, _amount);
        bool _bool = true;
        afterTokenTransfer(_from, _to, _amount, _bool);
        return true;
    }
    // function approve(address _spender, uint256 _value) public returns (bool success)
    function approve(
        address _spender, 
        uint256 _amount
        ) 
        internal
        virtual 
        returns 
        (bool success)
        {
        require(msg.sender != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;

    }
    // function allowance(address _owner, address _spender) public view returns (uint256 remaining)
    function mint(uint _amount) internal{
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
        emit Transfer(address(0), msg.sender, _amount);
    }

    function burn(uint _amount) internal{
      
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        emit Transfer(msg.sender ,address(0), _amount);
    }

    function beforeTokenTransfer(address _to, uint _amount ) internal  {

    }
    //transfers %10 of total send amount to charity
    // on every transfer call made

    function afterTokenTransfer(
        address _sender, 
        address _receiver, 
        uint _amount, 
        bool _bool
        ) internal 
        {
        if(_bool == true){
            address charity = 0x617F2E2fD72FD9D5503197092aC168c91465E7f2; //address of charity
            _receiver ;
            require(balanceOf[_sender] >= _amount);
            balanceOf[msg.sender] -= _amount;
            balanceOf[charity] += _amount;
            emit Transfer(msg.sender, charity, _amount);
            // return true;
        }
        
    }
}