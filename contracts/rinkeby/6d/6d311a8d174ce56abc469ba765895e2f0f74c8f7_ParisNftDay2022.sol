// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";

contract ParisNftDay2022 is ERC1155, Ownable {

    string public name = "Paris NFT Day 2022";

    constructor()
    ERC1155("ipfs://QmYRzyNUbLGwDEu11WLksHMsducDQsDy56Qhhq778HRufN/{id}.json")
        {
        }

    function drop(address targetAddress, uint256 amount) external onlyOwner {
        _mint(targetAddress, 0, amount, "");
    }


}