/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    
}

contract EduIt is IERC20 {
    address public owner;
    uint256 _totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;

    constructor(uint256 _initiallSupply) {
        _totalSupply = _initiallSupply;
        balances[msg.sender] = _initiallSupply;
        owner = msg.sender;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
       _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256)
    {
        return allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;
        return true;
    }

    function _transfer(address from,
        address to,
        uint256 amount) private returns (bool) {
        require(balances[from] >= amount, "not enought balance");
        balances[to] += amount;
        balances[from] = balances[from] - amount;
        emit Transfer(from, to, amount);
        return true;
    }


        function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool){
        _transfer(from, to, amount);
        return true;
    }
}