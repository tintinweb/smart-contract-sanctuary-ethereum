// contracts/MetaMAFIA.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MetaMAFIA_flat.sol";

contract MetaMAFIA is ERC20Capped, Ownable, Pausable {
    uint8 private _decimals;
    mapping(address => bool) private _pausedUsers;

    event PausedUser(address sender, address account);
    event UnpausedUser(address sender, address account);

    constructor()
    ERC20("Meta MAFIA", "MAF")
    ERC20Capped(500000000 * 10 ** 8) {
        _decimals = 8;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, msg.sender);
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, msg.sender, currentAllowance - amount);
        }
        _burn(account, amount);
    }

    function mint(address account, uint256 amount) public virtual onlyOwner {
        _mint(account, amount);
    }

    function pause() public virtual onlyOwner {
        _pause();
    }

    function unpause() public virtual onlyOwner {
        _unpause();
    }

    function pauseUser(address account) public virtual onlyOwner {
        _pausedUsers[account] = true;
        emit PausedUser(msg.sender, account);
    }

    function unpauseUser(address account) public virtual onlyOwner {
        _pausedUsers[account] = false;
        emit UnpausedUser(msg.sender, account);
    }

    function pausedUser(address account) public view virtual returns (bool) {
        return _pausedUsers[account];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
        require(!pausedUser(msg.sender), "ERC20PausableUser: user token transfer while paused");
    }
}