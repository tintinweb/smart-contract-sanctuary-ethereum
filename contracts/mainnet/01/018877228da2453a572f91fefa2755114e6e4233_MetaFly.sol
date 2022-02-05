//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";

contract MetaFly is Ownable, Pausable {

    string  public name = "MetaFly";
    string  public symbol = "MTF";
    string  public standard = "MetaFly TOKEN CREATE BY META TEC";
    uint256 public totalSupply = 1000000000000; 
    uint8   public decimals = 3;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Mint(address indexed minter, address indexed account, uint256 amount);
    event Burn(address indexed burner, address indexed account, uint256 amount);

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowed;
    

    constructor() {
        // balanceOf[msg.sender] = totalSupply;
        _balances[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value)
        public
        whenNotPaused
        returns (bool)
    {
        require(_to != address(0), "MetaFly: to address is not valid");
        require(
            _value <= _balances[msg.sender],
            "MetaFly: insufficient balance"
        );
        
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function balanceOf(address _owner)
        public
        view
        returns (uint256 balance)
    {
        return _balances[_owner];
    }

    function approve(address _spender, uint256 _value)
        public
        whenNotPaused
        returns (bool)
    {
        _allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public whenNotPaused returns (bool) {
        require(_from != address(0), "MetaFly: from address is not valid");
        require(_to != address(0), "MetaFly: to address is not valid");
        require(_value <= _balances[_from], "MetaFly: insufficient balance");
        require(
            _value <= _allowed[_from][msg.sender],
            "MetaFly: from not allowed"
        );

        _balances[_from] -= _value;
        _balances[_to] += _value;
        _allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        whenNotPaused
        returns (uint256)
    {
        return _allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint256 _addedValue)
        public
        whenNotPaused
        returns (bool)
    {
        _allowed[msg.sender][_spender] += _addedValue;

        emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);

        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue)
        public
        whenNotPaused
        returns (bool)
    {
        uint256 oldValue = _allowed[msg.sender][_spender];

        if (_subtractedValue > oldValue) {
            _allowed[msg.sender][_spender] = 0;
        } else {
            _allowed[msg.sender][_spender] = oldValue - _subtractedValue;
        }

        emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);

        return true;
    }

    function mintTo(address _to, uint256 _amount)
        public
        whenNotPaused
        onlyOwner
    {
        require(_to != address(0), "MetaFly: to address is not valid");
        require(_amount > 0, "MetaFly: amount is not valid");

        totalSupply += _amount;
        _balances[_to] += _amount;

        emit Mint(msg.sender, _to, _amount);
    }

    function burnFrom(address _from, uint256 _amount)
        public
        whenNotPaused
        onlyOwner
    {
        require(_from != address(0), "MetaFly: from address is not valid");
        require(_balances[_from] >= _amount, "MetaFly: insufficient balance");

        _balances[_from] -= _amount;
        totalSupply -= _amount;

        emit Burn(msg.sender, _from, _amount);
    }

    


}