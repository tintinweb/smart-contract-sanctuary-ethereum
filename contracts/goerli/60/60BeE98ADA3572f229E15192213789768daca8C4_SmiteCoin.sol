// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Context.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./ERC20.sol";
import "./Ownable.sol";

contract SmiteCoin is Ownable, ERC20 {
    mapping(address => bool) public blacklists;

    constructor() ERC20("Smite Coin", "SC")
    {
        _mint(msg.sender, 10000 * 10 ** 29);
    }

    function blacklist(address walletAddress, bool isBlacklisting) external onlyOwner {
        blacklists[walletAddress] = isBlacklisting;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal virtual {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");
    }
}