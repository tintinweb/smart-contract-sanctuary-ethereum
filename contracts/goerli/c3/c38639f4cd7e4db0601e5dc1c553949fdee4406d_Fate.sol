// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/* Fate Finance Coming Soon to Arbitrum
* Twitter : https://twitter.com/Fate_Finance
* Telegram : https://t.me/FateFinance
* GitBook : https://fate-finance.gitbook.io/fate-finance/
*/

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";

contract Fate is ERC20, ERC20Burnable, ERC20Permit, ERC20Votes {
    constructor() ERC20("Fate", "FATE") ERC20Permit("Fate") {
        _mint(msg.sender, 600000 * 10 ** decimals());
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}