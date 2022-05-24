// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract TestToken {
    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    string public name;

    string public symbol;

    uint8 public decimals;

    uint256 public totalSupply;

    event Transfer(
        address indexed seller,
        address indexed buyer,
        uint256 amount
    );

    event Approval(
        address indexed owner,
        address indexed delegate,
        uint256 amount
    );

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        mint(msg.sender, initialSupply);
    }

    function transfer(address buyer, uint256 amount) external returns (bool) {
        require(buyer != address(0), "Buyer must have a non-zero address!");
        require(
            balanceOf[msg.sender] >= amount,
            "Transfer amount must not exceed balance!"
        );

        unchecked {
            balanceOf[msg.sender] -= amount;
        }

        balanceOf[buyer] += amount;

        emit Transfer(msg.sender, buyer, amount);
        return true;
    }

    function transferFrom(
        address seller,
        address buyer,
        uint256 amount
    ) external returns (bool) {
        require(seller != address(0), "Seller must have a non-zero address!");
        require(buyer != address(0), "Buyer must have a non-zero address!");

        require(
            balanceOf[seller] >= amount,
            "Seller does not have the specified amount!"
        );

        require(
            allowance[seller][msg.sender] >= amount,
            "Delegate does not have enough allowance!"
        );
        unchecked {
            balanceOf[seller] -= amount;
        }

        unchecked {
            allowance[seller][msg.sender] -= amount;
        }

        balanceOf[buyer] += amount;

        emit Transfer(seller, buyer, amount);
        return true;
    }

    function approve(address delegate, uint256 amount) external returns (bool) {
        require(
            delegate != address(0),
            "Delegate must have a non-zero address!"
        );

        allowance[msg.sender][delegate] = amount;

        emit Approval(msg.sender, delegate, amount);
        return true;
    }

    function burn(address account, uint256 amount) external returns (bool) {
        require(
            account != address(0),
            "Burner account must have a non-zero address!"
        );

        require(
            balanceOf[account] >= amount,
            "Burn amount must not exceed balance!"
        );

        unchecked {
            balanceOf[account] -= amount;
        }

        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
        return true;
    }

    function mint(address account, uint256 amount) public returns (bool) {
        require(
            account != address(0),
            "Receiving account must have a non-zero address!"
        );

        totalSupply += amount;
        balanceOf[account] += amount;

        emit Transfer(address(0), account, amount);
        return true;
    }
}