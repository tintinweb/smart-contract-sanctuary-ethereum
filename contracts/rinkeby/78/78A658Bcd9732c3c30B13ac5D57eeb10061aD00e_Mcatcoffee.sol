// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract Mcatcoffee is ERC1155, Ownable{
    string public name;
    string public symbol;
    uint256 public maxSupply = 15;
    uint256 public maxMintAmount = 5;
    bool public paused = false;

    constructor() ERC1155("ipfs://QmaGyHCUgjbqBFHZwXmKUakdZ2e1RhZAqZfiGZEibQQeDW/{id}.json") {
        name = "Mister Cat Coffee4";
        symbol = "MCC4";
        mint(maxMintAmount);
    }


    function mint(uint256 _amount) public{

        for (uint256 i = 1; i < _amount; i++) {
            _mint(msg.sender, i, 1, "");
        }
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked("ipfs://QmaGyHCUgjbqBFHZwXmKUakdZ2e1RhZAqZfiGZEibQQeDW/", Strings.toString(_tokenId), ".json"));
    }
}