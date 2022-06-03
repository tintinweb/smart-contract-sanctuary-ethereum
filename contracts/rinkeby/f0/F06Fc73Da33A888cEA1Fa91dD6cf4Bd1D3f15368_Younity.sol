/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

//SPDX-License-Identifier: MIT
pragma solidity  0.8.10;
contract ERC20 {

    constructor (string memory _name, string memory _symbol, uint8 _decimal) {
        name_ = _name;
        symbol_ = _symbol;
        decimal_ = _decimal;
        //tSupply = _tSupply;
        //balances[msg.sender] = tSupply;//deployer has all the tokens initially
        owner = msg.sender;//deployer
    }
    address owner;
    string name_ ;
    string symbol_;
    uint8 decimal_;
    uint256 tSupply;
    mapping (address => uint256) balances;
    mapping (address => mapping(address => uint256)) allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function name() public view returns (string memory){
        return name_;
    }
    function symbol() public view returns (string memory){
        return symbol_;
    }
    function decimals() public view returns (uint8) {
        return decimal_;
    }
    function totalSupply() public view returns (uint256){
        return tSupply;
    }
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balances[msg.sender]>=_value, "Error ::: Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender,_to,_value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(balances[_from]>=_value, "Error ::: Insufficient balance");
        require(allowed[_from][msg.sender]>= _value, "Not enough allowance");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from,_to,_value);
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }

    // Mint & Burn
    function mint (address _user, uint256 _qty) public returns(bool){
        require(msg.sender == owner, "Only owner");
        tSupply += _qty;
        // 1. Minted tokens to msg.sender
        // balances[msg.sender] += _qty;
        // // 2. Mint tokens to deployer only
        // balances[owner] += _qty;
        // 3. Minted to _user addr
        balances[_user] += _qty;
        emit Transfer(address(0), _user, _qty);
        return true;
    }

    function burn (uint256 _qty ) public returns(bool){
        require(balances[owner] >= _qty, "Not enough tokens to burn");
        require(msg.sender == owner, "Only owner");
        tSupply -= _qty;
        balances[owner] -= _qty;
        emit Transfer(owner, address(0), _qty);
        return true;

    }

}

contract Younity is ERC20("Younity","YNT",0) {

    constructor (uint256 _tSupply) {
        mint(owner,_tSupply);
    }

}