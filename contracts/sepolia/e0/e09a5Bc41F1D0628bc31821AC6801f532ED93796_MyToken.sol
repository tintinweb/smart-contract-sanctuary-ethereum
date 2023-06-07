// SPDX-License-Identifier: MIT
//
//Twitter:
//Telegram:
//
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";

contract MyToken is ERC20, Ownable {
    mapping(address => bool) private _isBlacklisted;

    event BlacklistUpdated(address indexed account, bool isBlacklisted);

    constructor() ERC20("My Token", "MTK") {
        _mint(msg.sender, 100000000000000 * 10 ** decimals());
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _isBlacklisted[account];
    }

    function updateBlacklist(address account, bool isBlacklisted_) public onlyOwner {
        _isBlacklisted[account] = isBlacklisted_;
        emit BlacklistUpdated(account, isBlacklisted_);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(!_isBlacklisted[msg.sender], "Sender is blacklisted");
        require(!_isBlacklisted[recipient], "Recipient is blacklisted");
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(!_isBlacklisted[sender], "Sender is blacklisted");
        require(!_isBlacklisted[recipient], "Recipient is blacklisted");
        return super.transferFrom(sender, recipient, amount);
    }
}