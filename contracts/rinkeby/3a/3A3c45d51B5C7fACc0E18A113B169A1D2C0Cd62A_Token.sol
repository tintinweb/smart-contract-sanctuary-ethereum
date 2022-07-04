// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "IERC20.sol";


contract Token is IERC20 {

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        balances[msg.sender] = totalSupply();
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() public pure returns (uint256) {
        return 1e9;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) external virtual override returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom (address _from, address _to, uint256 _value) external virtual override returns (bool) {
        require(allowed[_from][msg.sender] >= _value, "Insufficient allowance");
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(balances[_from] >= _value, "Insufficient balance");
        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowed[_owner][_spender];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * Interface of the ERC20 standard as defined in the EIP-20 https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external pure returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool success);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}