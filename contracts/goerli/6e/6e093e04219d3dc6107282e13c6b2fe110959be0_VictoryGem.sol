// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./ERC20.sol";

contract VictoryGem is
    ERC20 {

    address private _owner;

    constructor(
        address[] memory holders,
        uint256[] memory amounts
    ) ERC20("BPC", "BPC") {
        require(holders.length == amounts.length, "wrong arguments");

        for (uint256 i = 0; i < holders.length; i++) {
            _mint(holders[i], amounts[i]);
        }
        _owner = _msgSender();
    }

    function getOwner() external view returns (address) {
        return _owner;
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
}