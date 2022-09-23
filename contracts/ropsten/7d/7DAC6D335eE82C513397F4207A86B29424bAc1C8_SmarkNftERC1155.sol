// contracts/SmarkNftERC1155.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";

contract SmarkNftERC1155 is ERC1155 {
    address public owner;

    constructor() ERC1155("https://opensea.io/zh-CN/assets/ethereum/0x495f947276749ce646f68ac8c248420045cb7b5e/{id}") {
        owner = msg.sender;
    }

    function mint(
        uint256 id,
        uint256 amount
    ) public {
        require(msg.sender == owner, "Smark NFT: address is not owner");

        _mint(owner, id, amount, "");
    }
}