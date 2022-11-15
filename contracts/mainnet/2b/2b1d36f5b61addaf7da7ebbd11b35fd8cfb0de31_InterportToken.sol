/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


contract InterportToken {

    error OnlyOwnerError();
    error ZeroAddressError();
    error MintAccessError();
    error BurnAccessError();

    string public name = "Interport Token";
    string public symbol = "ITP";
    uint8 public immutable decimals = 18;

    address public immutable underlying = address(0); // Anyswap ERC20 standard

    address public owner;
    address public multichainRouter;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event SetMultichainRouter(address indexed multichainRouter);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) {
            revert OnlyOwnerError();
        }

        _;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user balances can't exceed the max uint256 value
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
    )
        external
        returns (bool)
    {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals

        if (allowed != type(uint256).max) {
            allowance[from][msg.sender] = allowed - amount;
        }

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user balances can't exceed the max uint256 value
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    function mint(address _to, uint256 _amount) external returns (bool) {
        // Minters: contract owner + Multichain router
        bool condition =
            msg.sender == owner ||
            msg.sender == multichainRouter;

        if (!condition) {
            revert MintAccessError();
        }

        _mint(_to, _amount);

        return true;
    }

    function burn(uint256 _amount) external returns (bool) {
        // Simplified burn function for token holders
        _burn(msg.sender, _amount);

        return true;
    }

    function burn(address _from, uint256 _amount) external returns (bool) {
        // Burners: token holders + Multichain router
        bool condition =
            _from == msg.sender ||
            msg.sender == multichainRouter;

        if (!condition) {
            revert BurnAccessError();
        }

        _burn(_from, _amount);

        return true;
    }

    function setMultichainRouter(address _multichainRouter) external onlyOwner {
        // Zero address is allowed
        multichainRouter = _multichainRouter;

        emit SetMultichainRouter(_multichainRouter);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) {
            revert ZeroAddressError();
        }

        address previousOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(previousOwner, newOwner);
    }

    function _mint(address to, uint256 amount) private {
        totalSupply += amount;

        // Cannot overflow because the sum of all user balances can't exceed the max uint256 value
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) private {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance will never be larger than the total supply
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}