// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "ERC20.sol";

/*
  Fake MockERC20 proxy.
  Admins can manipulate balances.
  Users can mint for themselves.
*/
contract SelfSufficientERC20 is ERC20 {
    // Simple permissions management.
    mapping(address => bool) admins;
    address owner;
    uint256 max_mint = MAX_MINT;

    uint256 constant MAX_MINT = 1000; // Maximal amount per selfMint transaction.

    function initlialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external onlyOwner {
        require(decimals_ == 0, "ALREADY_INITIALIZED");
        require(_decimals != 0, "ILLEGAL_INIT_VALUE");
        name_ = _name;
        symbol_ = _symbol;
        decimals_ = _decimals;
    }

    constructor() public {
        admins[msg.sender] = true;
        owner = msg.sender;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "ONLY_ADMIN");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    function registerAdmin(address newAdmin) external onlyOwner {
        admins[newAdmin] = true;
    }

    function removeAdmin(address oldAdmin) external onlyOwner {
        require(oldAdmin != owner, "OWNER_MUST_REMAIN_ADMIN");
        admins[oldAdmin] = false;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        admins[newOwner] = true;
        owner = newOwner;
    }

    function adminApproval(
        address fundsOwner,
        address spender,
        uint256 value
    ) external onlyAdmin {
        _approve(fundsOwner, spender, value);
    }

    function setBalance(address account, uint256 amount) external onlyAdmin {
        _totalSupply += amount - _balances[account];
        _balances[account] = amount;
    }

    function resetMaxMint(uint256 newMax) external onlyOwner {
        max_mint = newMax;
    }

    function selfMint(uint256 amount) external {
        require(amount <= max_mint, "ILLEGAL_AMOUNT");
        _mint(msg.sender, amount);
    }
}