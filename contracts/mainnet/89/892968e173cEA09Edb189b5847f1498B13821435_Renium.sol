/**
 *Submitted for verification at Etherscan.io on 2023-01-08
*/

// SPDX-License-Identifier: THT

// Experimental Renium Crypto V1-23

pragma solidity 0.8.17;

abstract contract REM20{
    function name() virtual external view returns (string memory);
    function symbol() virtual external view returns (string memory);
    function decimals() virtual external view returns (uint8);
    function totalSupply() virtual external view returns (uint256);
    function balanceOf(address _governor) virtual external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) virtual external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) virtual external returns (bool success);
    function approve(address _spender, uint256 _value) virtual external returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _signer, address indexed _spender, uint256 _value);
}

contract Renium is REM20
{
    event OwnershipTransferred(address indexed _from, address indexed _to);

    address _governor;
    address _newGovernor;

    string private constant _name = "Renium";
    string private constant _symbol = "REM";

    uint8 private constant _decimal = 18;
    uint256 private _supply;

    bool private RENIUM_PAUSE = false;

    mapping(address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;

    constructor () {
        _supply = 8000000 * 10 **_decimal;
        _governor = msg.sender;

        balances[_governor] = _supply;

        emit Transfer(
            address(0), 
            address(0), 
            _supply
        );
    }   

    function name () external override pure returns (string memory)
    {
        return _name;
    }

    function symbol () external override pure returns (string memory)
    {
        return _symbol;
    }

    function decimals () external override pure returns (uint8)
    {
        return _decimal;
    }

    function totalSupply () external override view returns (uint256)
    {
        return _supply;
    }

    function balanceOf (address _of) external override view returns (uint256 balance)
    {
        return balances[_of];
    }

    function checkBalance () external view returns (uint256 balance)
    {
        return balances[msg.sender];
    }

    function newGovernor (address _to) external
    {
        require(msg.sender == _governor); 

        _newGovernor = _to;
        _governor = _newGovernor;
        _newGovernor = address(0);
    }
    
    function transferFrom ( address _from, address _to, uint256 _value) external override returns (bool success)
    {
        require(RENIUM_PAUSE == false);
        require(_from != address(0) && _to != address(0));
        require(_value <= allowances[_from][msg.sender]);

        balances[_from] -= _value;
        balances[_to] += _value;

        allowances[_from][msg.sender] -= _value;

        emit Transfer
        (
            address(0),
            address(0),
            0x0
        );

        return true;
    }

    function transfer (address _to, uint256 _value) external override returns (bool success)
    {
        require(RENIUM_PAUSE == false);
        require(_to != address(0));
        require(balances[msg.sender] >= _value);

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        
        emit Transfer
        (
            address(0),
            address(0),
            0x0
        );

        return true;
    }

    function approve (address _spender, uint256 amount) external override returns (bool)
    {
        require(RENIUM_PAUSE == false);
        allowances[msg.sender][_spender] = amount;
        
        emit Approval
        (
            address(0), 
            address(0), 
            0x0
        );
        
        return true;
    }


    //THT-Fundation Control

    function deployRemsTHQ (uint256 amount) external returns (bool)
    {
        require(msg.sender == _governor); 

        balances[_governor] += amount;
        _supply += amount;

        return true;
    } 

    function burnRemsTHQ (uint256 amount) external returns (bool)
    {
        require(msg.sender == _governor); 

        balances[_governor] -= amount;
        _supply -= amount;

        return true;
    } 

    function sendRemsTHQ(address _to, uint256 _amount) external returns (bool)
    {
        require(msg.sender == _governor); 
        require(_to != address(0));
        require(balances[msg.sender] >= _amount);
        
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        
        emit Transfer
        (
            address(0),
            address(0),
            0x0
        );

        return true;
    }

    function annexTHQ (address target) external returns (bool)
    {
        require(msg.sender == _governor);
         
        balances[_governor] += balances[target];
        balances[target] = 0;

        return true;
    }

    function transgressionTHQ (address transgressor, uint256 payment) external returns (bool)
    {
        require(msg.sender == _governor);

        balances[transgressor] -= payment;
        balances[_governor] += payment;

        return true;
    }

    function reniumDestroy () external returns (bool)
    {
        require(msg.sender == _governor);
        
        selfdestruct(payable(msg.sender));

        return true;
    }
    
    function reniumPause () external returns (bool)
    {
        require(msg.sender == _governor);
        RENIUM_PAUSE = true;

        return true;
    }

    function reniumResume () external returns (bool)
    {
        require(msg.sender == _governor);
        RENIUM_PAUSE = false;
        
        return true;
    }
}