//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface TokenERC20 {
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function totalSupply() external view returns(uint256);
    function balanceOf(address user) external view returns(uint256 balance);
    function allowance(address owner, address spender) external view returns(uint256 remaining);

    function transfer(address _to, uint256 _amount) external returns(bool success);
    function transferFrom(address _from, address _to, uint256 _amount) external returns(bool success);
    function approve(address _spender, uint256 _amount) external returns(bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
}

contract ERC20 is TokenERC20{

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address private owner;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    constructor() {
        _name = "Russian ruble";
        _symbol = "RUB";
        _decimals = 18;

        owner = msg.sender;

        mint(owner, 10**_decimals);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function");
        _; // body of function
    }

// view functions

function name() external view override returns(string memory){
    return _name;
    }

    function symbol() external view override returns(string memory){
        return _symbol;
    }

    function decimals() external view override returns(uint8){
        return _decimals;
    }

     function balanceOf(address _owner) public view override returns (uint256) {
        return balances[_owner];
    }


    function totalSupply() external view override returns(uint256){
        return _totalSupply;
    }

    function allowance(address _owner, address _spender) external view override returns(uint256 remaining){
        return allowed[_owner][_spender];
    }

// functions

    function transfer(address _to, uint256 _amount) public override returns(bool success) {
        require(balances[msg.sender] >= _amount, "Amount more than your balance");

        balances[msg.sender] -= _amount;
        balances[_to] += _amount;

        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public override returns(bool success){
        require(balances[_from] >= _amount, "Check allowance");
        require(allowed[_from][msg.sender] >= _amount, "Your balance less, than amount");

        balances[msg.sender] += _amount;
        balances[_from] -= _amount;
        allowed[_from][msg.sender] -= _amount;

        emit Transfer(_from, _to, _amount);
        emit Approval(_from, msg.sender, allowed[_from][msg.sender]);
        return true;
    }

    function approve(address _spender, uint256 _amount) public override returns(bool success){
        require(balances[msg.sender] >= _amount, "Your balance less, than amount");

        allowed[msg.sender][_spender] = _amount;

        emit Approval(msg.sender, _spender, _amount);
        return true;
    } 

    function increaseAllowance(address _from, uint256 _amount) public returns(bool success){
        allowed[msg.sender][_from] += _amount;

        emit Approval(msg.sender, _from, allowed[msg.sender][_from]);
        return true;
    }

    function decreaseAllowance(address _from, uint256 _amount) public returns(bool success){
         require(allowed[msg.sender][_from] >= _amount, "Allowed much less than could be decrease");

        allowed[msg.sender][_from] -= _amount;

        emit Approval(msg.sender, _from, allowed[msg.sender][_from]);
        return true;
    }

   function mint(address _to, uint256 _amount) public onlyOwner returns (bool success){
       balances[_to] += _amount;
        _totalSupply += _amount;

        emit Transfer(address(0), owner, _amount);
        return true;
   }

   function burn(uint256 _amount) public onlyOwner returns (bool success){
       require(balanceOf(owner) >= _amount, "You haven't such amount of tokens");

        balances[owner] -= _amount;
        _totalSupply -= _amount;

        emit Transfer(owner, address(0), _amount);
        return true;
   }
    
    
}