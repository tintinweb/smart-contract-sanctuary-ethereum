// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155Supply.sol";

contract ParisNftDayTest is Ownable, ERC1155Supply {

    string public name = "Paris NFT Day 2022";

    string public symbol = "PND2022";

    constructor()
    ERC1155("ipfs://QmYRzyNUbLGwDEu11WLksHMsducDQsDy56Qhhq778HRufN/{id}.json")
        {
        }

    function drop(address targetAddress, uint256 amount) external onlyOwner {
        _mint(targetAddress, 0, amount, "");
    }



}