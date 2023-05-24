// SPDX-License-Identifier: MIT
/**
  ▄████  ██▀███   ██▓  █████▒▄▄▄█████▓▓█████  ██▀███  
 ██▒ ▀█▒▓██ ▒ ██▒▓██▒▓██   ▒ ▓  ██▒ ▓▒▓█   ▀ ▓██ ▒ ██▒
▒██░▄▄▄░▓██ ░▄█ ▒▒██▒▒████ ░ ▒ ▓██░ ▒░▒███   ▓██ ░▄█ ▒
░▓█  ██▓▒██▀▀█▄  ░██░░▓█▒  ░ ░ ▓██▓ ░ ▒▓█  ▄ ▒██▀▀█▄  
░▒▓███▀▒░██▓ ▒██▒░██░░▒█░      ▒██▒ ░ ░▒████▒░██▓ ▒██▒
 ░▒   ▒ ░ ▒▓ ░▒▓░░▓   ▒ ░      ▒ ░░   ░░ ▒░ ░░ ▒▓ ░▒▓░
  ░   ░   ░▒ ░ ▒░ ▒ ░ ░          ░     ░ ░  ░  ░▒ ░ ▒░
░ ░   ░   ░░   ░  ▒ ░ ░ ░      ░         ░     ░░   ░ 
      ░    ░      ░                      ░  ░   ░   
      Thief in the night
         A degens paradise
            0 tax - thats what grifters do
               no tokens held by dev
                  fuck rugs                                                                              
                                                                                   */

pragma solidity ^0.8.0;


contract GRIFTER {
    string public name = "GRIFTER";
    string public symbol = "GRIFTER";
    uint256 public totalSupply = 5_000_000* 10**18; 
    uint8 public decimals = 18;


    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(_to != address(0));
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        require(_to != address(0));
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function renounce() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }


    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }
}