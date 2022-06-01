//SPDX-License-Identifier: Unlicense

import "./IRKUToken.sol";

pragma solidity ^0.8.5;

contract RkuToken is IRkuToken {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) _allowance;

    string public _name;
    string public _symbol;
    uint8 public _decimals;
    uint256 public _totalSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        mint(msg.sender, initialSupply);
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function demicals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

        function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return balances[account];
    }

    function allowance(address account, address delegate)
        external
        view
        override
        returns (uint256)
    {
        return _allowance[account][delegate];
    }

    function trancfer(address buyer, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _trancfer(msg.sender, buyer, amount);
        return true;
    }

    function trancferFrom(
        address seller,
        address buyer,
        uint256 amount
    ) external virtual override returns (bool) {
        _trancfer(seller, buyer, amount);
        _spendAllowance(seller, msg.sender, amount);
        return true;
    }

    function approve(address delegate, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        require(
            delegate != address(0),
            "Delegate must have a non-zero address!"
        );

        _allowance[msg.sender][delegate] = amount;

        emit Approval(msg.sender, delegate, amount);
        return true;
    }

    function burn(address account, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        require(
            account != address(0),
            "Burner account must have a non-zero address!"
        );
        require(
            balances[account] >= amount,
            "Burn amount must not exceed balance!"
        );

        unchecked {
            balances[account] -= amount;
        }

        _totalSupply -= amount;

        emit Trancfer(account, address(0), amount);
        return true;
    }

    function mint(address account, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        require(
            account != address(0),
            "Receiving account must have a non-zero address!"
        );

        _totalSupply += amount;
        balances[account] += amount;

        emit Trancfer(address(0), account, amount);
        return true;
    }

    function _trancfer(
        address seller,
        address buyer,
        uint256 amount
    ) internal {
        require(seller != address(0), "Seller must have a non-zero address!");
        require(buyer != address(0), "Byuer must have a non-zero address!");
        require(
            balances[seller] >= amount,
            "Seller does not have the specified amount!"
        );

        unchecked {
            balances[msg.sender] -= amount;
        }

        balances[buyer] += amount;

        emit Trancfer(seller, buyer, amount);
    }

    function _spendAllowance(
        address seller,
        address delegate,
        uint256 amount
    ) internal {
        require(
            _allowance[seller][delegate] >= amount,
            "Delegate does not have enough allowance!"
        );

        unchecked {
            _allowance[seller][delegate] -= amount;
        }
    }

}