/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

//ERC Token Standard 20 Interface
interface ERC20Interface {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256 balance);

    function allowance(address owner, address sender)
        external
        view
        returns (uint256 remaining);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool success);

    function approve(address spender, uint256 amount)
        external
        returns (bool success);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

//Actual token contract
contract LinkinParkToken is ERC20Interface {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        symbol = "LPT";
        name = "LinkinPark Coin";
        decimals = 18;
        _totalSupply = 1_000_001_000_000_000_000_000_000;
        balances[0x4A87bF3839D4a916fe1a2183dB87E77758B355B3] = _totalSupply;
        emit Transfer(
            address(0),
            0x4A87bF3839D4a916fe1a2183dB87E77758B355B3,
            _totalSupply
        );
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256 balance) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        returns (bool success)
    {
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[recipient] = balances[recipient] + amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        public
        returns (bool success)
    {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool success) {
        balances[sender] = balances[sender] - amount;
        allowed[sender][msg.sender] = allowed[sender][msg.sender] - amount;
        balances[recipient] = balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowed[owner][spender];
    }
}