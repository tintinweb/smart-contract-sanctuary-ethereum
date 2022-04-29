// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract BasicTokenMock {
    ///=============================================================================================
    /// Events
    ///=============================================================================================

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    ///=============================================================================================
    /// MetaData
    ///=============================================================================================

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    ///=============================================================================================
    /// ERC20
    ///=============================================================================================

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    ///=============================================================================================
    /// Constructor
    ///=============================================================================================

    constructor(address _initialAccount, uint256 _initialBalance) {
        name = "Basick Token Mock";
        symbol = "BTM";
        decimals = 18;
        _mint(_initialAccount, _initialBalance);
    }

    ///=============================================================================================
    /// ERC20 Logic
    ///=============================================================================================

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    ///=============================================================================================
    /// External Mint Logic
    ///=============================================================================================

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }

    ///=============================================================================================
    /// Internal Mint Logic
    ///=============================================================================================

    function _mint(address to, uint256 amount) internal {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    // burn feature hasnt been tested
    function _burn(address from, uint256 amount) internal {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}