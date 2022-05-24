// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract RT is
    ERC20, Ownable {

    address private _owner;

    constructor(
        address[] memory holders,
        uint256[] memory amounts
    ) ERC20("RT", "RT") {
        require(holders.length == amounts.length, "wrong arguments");

        for (uint256 i = 0; i < holders.length; i++) {
            _mint(holders[i], amounts[i]);
        }
        _owner = _msgSender();
    }

    function batchTransfer(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external returns (bool) {
        require(recipients.length == amounts.length, "Invalid input parameters");

        for(uint256 i = 0; i < recipients.length; i++) {
            _transfer(_msgSender(), recipients[i], amounts[i]);
        }
        return true;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}