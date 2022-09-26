/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract USDT {
    address public admin;
    string private symbol;
    string private name;
    uint8 private decimals;
    uint public totalSupply;
    uint public maxSupply;

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    constructor(string memory _symbol, string memory _name, uint8  _decimals){
        admin  = msg.sender;
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        maxSupply = 100_000_000*10**_decimals;
    }

    modifier checkOwner() {
        // require(msg.sender!=admin,"Only owner can access.");
        if(msg.sender==admin) revert("Only owner can access");
        _;
    }

    modifier checkMinVal(uint _amount) {
        require(_amount>0,"Invalid amount.");
        _;
    }

    function mint(address _to, uint _amount) public checkOwner checkMinVal(_amount) returns (bool){
        require(_to != address(0),"address cannot be zero");
        require(maxSupply>=totalSupply+_amount,"max supply reached");

        balanceOf[_to] = _amount;
        totalSupply += _amount; 
        return true;
    }

    function burn(address _to, uint _amount) public checkMinVal(_amount) returns (bool){
        require(_to != address(0),"address cannot be zero");

        balanceOf[_to] -= _amount;
        totalSupply -= _amount;

        return true;
    }

    function approve(address _to, uint _amount) public checkMinVal(_amount) returns (bool){
        require(_to != address(0),"address cannot be zero");

        allowance[msg.sender][_to] = _amount;
        return true;
    }

    function transferFrom(address  _from, address  _to, uint _amount) public returns (bool){
        require(_from!=address(0),"invalid address");
        allowance[_from][_to] -= _amount;
        _transfer(_from,_to,_amount);
        return true;
    }

    function _transfer(address  _from, address  _to, uint _amount) private returns(bool) {
         require(_to != address(0), "to address cannot be zero");
        require(
            balanceOf[_from] >= _amount,
            "from address doesn't have enough balance"
        );
        require(balanceOf[_to] + _amount >= balanceOf[_to], "Addition error");

        balanceOf[_from] -= _amount;
        balanceOf[_to] += _amount;
        return true;  
    }

    function transfer(address  _from, address  _to, uint _amount) public  returns(bool){
        _transfer(_from, _to, _amount);
        return true;
    }

}