// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface IERC20{
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract MyToken is IERC20{
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address public _publicBank;

    mapping (address => uint256) private balances; //账户余额
    mapping (address=> mapping(address=>uint256)) private allowances; // a(b)=>100 a允许b花费100元，b可以多个人

    constructor(string memory _na ,string memory _sym , uint8 _deci,uint256 _initialSupply)  {
        _name = _na;
        _symbol = _sym;
        _decimals = _deci;
        _totalSupply = _initialSupply;
        _publicBank = msg.sender;
        balances[msg.sender] = _initialSupply;
    }


    modifier onlyAdmin(){
        require(msg.sender == _publicBank, "admin required");
        _;
    }


    function name() external override view returns (string memory){
        return _name;
    }
    function symbol() external override view returns (string memory){
        return _symbol;
    }
    function decimals() external override view returns (uint8){
        return _decimals;
    }
    function totalSupply() external override view returns (uint256){
        return _totalSupply;
    }
    function balanceOf(address _owner) external override view returns (uint256 balance){
        return balances[_owner];
    }

    //向别人转钱
    function transfer(address _to, uint256 _value) external override returns (bool success){
        require(balances[msg.sender] >= _value,"Not enough amount!");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender,_to,_value);
        return true;
    }

    //当前用户通过_from给_to打钱，前提是approve过
    function transferFrom(address _from, address _to, uint256 _value) external override returns (bool success){
        uint _allowance = allowances[_from][msg.sender];
        uint leftAllowance = _allowance - _value;
        require (leftAllowance >= 0 , "Not enought allowance!");
        allowances[_from][msg.sender] = leftAllowance;
        require (balances[_from] > _value,"Not enougth Amount" );
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from,_to,_value);
        return true;
    }

    //允许授权行为，持有者（当前用户）允许被授权人转走一定数量的Token资产,_spender花钱的人
    function approve(address _spender, uint256 _value) external override returns (bool success){
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) external override view returns (uint256 remaining){
        return allowances[_owner][_spender];
    }

    //中心打钱
    function sendUserMoneny(address _to, uint256 _value) public onlyAdmin returns (bool success){
        require(balances[_publicBank] >= _value,"Not enough amount!");
        balances[_publicBank] -= _value;
        balances[_to] += _value;
        emit Transfer(_publicBank,_to,_value);
        return true;
    }

    //还钱
    function getMoneyBack(address user,uint256 _value) public onlyAdmin returns (bool success){
        if(_value >balances[user]){
            balances[_publicBank] += balances[user];
            balances[user] = 0;
        }else{
            balances[user] -= _value;
            balances[_publicBank] += _value;
        }
        emit Transfer(user,_publicBank,_value);
        return true;
    }

    //铸币
    function _mint( uint256 amount) public payable onlyAdmin virtual returns (uint256) {
        require(amount == msg.value,"wei is not enough");
        _totalSupply += amount;
        balances[_publicBank] += amount;
        return _totalSupply;
    }

    function destroy(uint256 amount) public onlyAdmin virtual returns (uint256) {
        require(balances[_publicBank] >= amount,"bank is not enough");
        _totalSupply -= amount;
        balances[_publicBank] -= amount;
        return _totalSupply;
    }

}