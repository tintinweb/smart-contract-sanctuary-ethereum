// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./Ownable.sol";

contract DToolsPremiumPass is ERC721A, ERC721ABurnable, Ownable {
    uint256 public mintPrice = 40000000000000000;

    uint256 public renewPrice = 40000000000000000;

    uint256 public maxSupply = 512;

    string public metadataURI = "https://api.dtools.org/premiumpass/";

    address public contractReceiver;

    event RenewEvent(address indexed payer, uint256 indexed tokenId);

    constructor() ERC721A("DToolsPremiumPass", "DTPP") {
        contractReceiver = msg.sender;
    }

    // metadata uri

    function _baseURI() internal view override returns (string memory) {
        return metadataURI;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        metadataURI = _uri;
    }

    // mint/renew price

    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    function setRenewPrice(uint256 _price) external onlyOwner {
        renewPrice = _price;
    }

    // receiver

    function setContractReceiver(address _receiver) external onlyOwner {
        contractReceiver = _receiver;
    }

    // max supply

    function setMaxSupply(uint256 _supply) external onlyOwner {
        maxSupply = _supply;
    }

    // pass management

    function mint() external payable {
        require(totalSupply() < maxSupply, "sold out");
        require(msg.value >= mintPrice, "insufficient value");

        _mint(msg.sender, 1);
    }

    function renew(uint256 tokenId) external payable {
        require(msg.value >= renewPrice, "insufficient value");
        emit RenewEvent(msg.sender, tokenId);
    }

    function renewByOwner(uint256[] calldata tokenIds) external onlyOwner {
        uint256 len = tokenIds.length;
        for (uint32 i = 0; i < len; ++i) {
            emit RenewEvent(msg.sender, tokenIds[i]);
        }
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

    function extract() external onlyOwner {
        payable(contractReceiver).transfer(address(this).balance);
    }
}