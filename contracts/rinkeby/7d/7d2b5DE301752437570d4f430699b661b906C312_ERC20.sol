//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./IERC20.sol";

contract ERC20 is IERC20 {
    uint256 private totalAmount;

    mapping(address => uint256) private amounts;

    mapping(address => mapping(address => uint256)) private permission;

    address private contractOwner;
    string private name;
    string private symbol;

    modifier onlyOwner() {
        require(msg.sender == owner());
        _;
    }

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
        contractOwner = msg.sender;
    }

    function owner() public view returns (address) {
        return contractOwner;
    }

    function totalSupply() external view override returns (uint256) {
        return totalAmount;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return amounts[account];
    }

    function transfer(address to, uint256 amount) external override {
        require(amounts[msg.sender] >= amount, "Insufficient funds");
        require(to != address(0x0), "Invalid address to");

        amounts[msg.sender] -= amount;
        amounts[to] += amount;
    }

    function allowance(address tokenOwner, address receiver)
        external
        view
        override
        returns (uint256)
    {
        return permission[tokenOwner][receiver];
    }

    function approve(address receiver, uint256 amount) external override {
        permission[msg.sender][receiver] = amount;
    }

    function burn(uint256 amount) external onlyOwner {
        require(amounts[msg.sender] >= amount, "Insufficient funds");
        amounts[msg.sender] -= amount;
    }

    function mint(uint256 amount) external onlyOwner {
        amounts[msg.sender] += amount;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override {
        require(permission[from][msg.sender] >= amount, "Not have permission");
        require(amounts[from] >= amount, "Insufficient funds");
        require(from != address(0x0), "Invalid address from");
        require(to != address(0x0), "Invalid address to");

        amounts[from] -= amount;
        amounts[to] += amount;
        permission[from][to] = 0;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external;

    function allowance(address tokenOwner, address receiver)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external;

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;
}