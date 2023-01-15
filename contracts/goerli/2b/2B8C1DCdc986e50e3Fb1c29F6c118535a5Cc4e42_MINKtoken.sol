//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./Ownable.sol";

contract MINKtoken is ERC20, Ownable {
    constructor(uint256 totalSupply) ERC20("MINKTOKEN", "MINK") {
        _mint(owner(), totalSupply);
    }

    function decimals() public pure override returns (uint8) {
        return 3;
    }

    mapping(address => uint256) TotalPurchasePerUser;

    function purchase(
        address to,
        string memory Purchasedetails,
        uint256 amount
    ) public virtual {
        _Purchase(to, Purchasedetails, amount);
    }

    function _Purchase(
        address to,
        string memory Purchasedetails,
        uint256 amount
    ) internal virtual returns (bool) {
        transfer(to, amount);

        TotalPurchasePerUser[_msgSender()] += amount;

        emit purchaseDetails(Purchasedetails, _msgSender(), to, true);
        return true;
    }

    function getTotalPurchasePerUser(address user)
        public
        view
        returns (uint256)
    {
        return TotalPurchasePerUser[user];
    }
}