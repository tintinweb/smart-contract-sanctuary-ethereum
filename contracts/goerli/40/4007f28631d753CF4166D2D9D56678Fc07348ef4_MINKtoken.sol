//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./Ownable.sol";

contract MINKtoken is ERC20, Ownable {
    constructor(uint256 totalSupply) ERC20("MINKTest", "MINKTest") {
        _mint(owner(), totalSupply);
    }

    function decimals() public pure override returns (uint8) {
        return 3;
    }

    function runPurchase(
        address to,
        string memory details,
        uint256 amount
    ) public virtual {
        purchase(to, details, amount);
    }

    function purchase(
        address to,
        string memory details,
        uint256 amount
    ) internal virtual returns (bool) {
        transfer(to, amount);

        emit purchaseDetails(details, _msgSender(), to, true);

        return true;
    }
}