// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Supply.sol";

contract ParisNftDayTest is Ownable, ERC1155Supply {

    string public name = "Test 1155 Flying dutchdude";

    constructor()
    ERC1155("ipfs://QmYRzyNUbLGwDEu11WLksHMsducDQsDy56Qhhq778HRufN/{id}.json")
        {
        }

    function drop(address targetAddress, uint256 amount) external onlyOwner {
        _mint(targetAddress, 0, amount, "");
    }


}