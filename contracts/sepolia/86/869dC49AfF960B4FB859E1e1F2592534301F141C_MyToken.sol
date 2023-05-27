// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "ERC20.sol";
import "Ownable.sol";

interface IWhitelist {
    function addToWhitelist(address candidate) external;

    function removeFromWhitelist(address candidate) external;
}

abstract contract BaseToken is IWhitelist, ERC20 {
    mapping(address => bool) internal _whitelist;

    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals) ERC20(name, symbol) {
        _decimals = decimals;
    }

    function mintTo(address account, uint256 amount) external virtual {}

    function addToWhitelist(address candidate) external virtual override {}

    function removeFromWhitelist(address candidate) external virtual override {}

    function isMember(address account) public view returns (bool) {
        return _whitelist[account];
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {}
}

contract MyToken is BaseToken, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) BaseToken(name, symbol, decimals) {}

    function isContract(address addr) private view returns (bool) { 
        return addr.code.length > 0; 
    }

    function isWhitelisted(address candidate) private view returns(bool) {
        return (!isContract(candidate) || isMember(candidate));
    }

    function addToWhitelist(address candidate) external onlyOwner override {
        _whitelist[candidate] = true;
    }

    function removeFromWhitelist(address candidate) external onlyOwner override {
        delete _whitelist[candidate];
    }

    function mintTo(address account, uint256 amount) external onlyOwner override {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from != address(0)) { // if minting
            require(isWhitelisted(to), "Contract is not in the whitelist");
        }
    }
}