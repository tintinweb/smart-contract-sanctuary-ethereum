// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibERC20Storage.sol";

contract ERC20WithdrawFacet {
    ERC20Storage internal token;

    function withdraw() external {
        require(msg.sender == token._owner);
        _transfer(address(this), msg.sender, token._balances[address(this)]);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = token._balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            token._balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            token._balances[to] += amount;
        }

        // emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct ERC20Storage {
    string _name;
    string _symbol;
    uint8 _decimal;
    uint256 _totalSupply;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    address _owner;
}