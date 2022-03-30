// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./IERCExtend.sol";
import "./AuthorityControlled.sol";

contract Chimp is ERC20, IERCExtend, AuthorityControlled {
    using SafeMath for uint256;

   constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        IAuthority authority_
    ) AuthorityControlled(authority_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function mint(address account_, uint256 amount_)
        public
        virtual
        override
        onlyManager
    {
        require(account_ != address(0), "Chimp: mint to the zero address");
        _totalSupply = _totalSupply.add(amount_);
        _balances[account_] = _balances[account_].add(amount_);
        emit Transfer(address(0), account_, amount_);
    }

    function burn(uint256 amount_) public virtual override {
        _balances[msg.sender] = _balances[msg.sender].sub(
            amount_,
            "Chimp: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount_);
        emit Transfer(msg.sender, address(0), amount_);
    }

    function burnFrom(address account_, uint256 amount_)
        public
        virtual
        override
    {
        require(account_ != address(0), "Chimp: burn from the zero address");
        uint256 decreasedAllowance_ = allowance(account_, msg.sender).sub(
            amount_,
            "Chimp: burn amount exceeds allowance"
        );

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }

    function _burn(address account_, uint256 amount_) internal virtual {
        _balances[account_] = _balances[account_].sub(
            amount_,
            "Chimp: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount_);
        emit Transfer(account_, address(0), amount_);
    }
}