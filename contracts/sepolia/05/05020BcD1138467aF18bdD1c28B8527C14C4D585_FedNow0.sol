// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./Ownable.sol";

contract FedNow0 is ERC1155, Ownable {
    constructor() ERC1155("https://dbdan.ddns.net/{id}.json") {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        _mint(to, id, amount, data);
    }
}