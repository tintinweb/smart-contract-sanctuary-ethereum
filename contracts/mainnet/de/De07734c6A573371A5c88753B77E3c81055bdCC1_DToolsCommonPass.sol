// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./Ownable.sol";

contract DToolsCommonPass is ERC721A, ERC721ABurnable, Ownable {
    uint256 public maxSupply = 1024;

    string public metadataURI = "https://api.dtools.org/commonpass/";

    constructor() ERC721A("DToolsCommonPass", "DTCP") {}

    // metadata uri

    function _baseURI() internal view override returns (string memory) {
        return metadataURI;
    }

    function setBaseURI(string calldata _uri) public onlyOwner {
        metadataURI = _uri;
    }

    // max supply

    function setMaxSupply(uint256 _supply) external onlyOwner {
        maxSupply = _supply;
    }

    // pass management

    function mint() external {
        require(totalSupply() < maxSupply, "sold out");
        _mint(msg.sender, 1);
    }

    function mintByOwner(uint256 quantity) external onlyOwner {
        _mint(msg.sender, quantity);
    }

    function airdropByOwner(
        address[] calldata _addresses,
        uint8[] calldata _counts
    ) external onlyOwner {
        for (uint32 i = 0; i < _addresses.length; ++i) {
            _mint(_addresses[i], _counts[i]);
        }
    }
}