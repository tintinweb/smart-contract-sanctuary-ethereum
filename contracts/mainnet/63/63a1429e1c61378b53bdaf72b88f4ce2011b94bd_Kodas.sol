// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Kodas is ERC721A, Ownable {
    string public baseURI;
    string public constant baseExtension = ".json";
    uint256 public constant MAX_PER_TX_FREE = 20;
    uint256 public constant MAX_PER_TX = 20;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public FREE_MAX_SUPPLY = 1000;
    uint256 public price = 0.001 ether;
    bool public paused = false;

    constructor() ERC721A("10K Kodas", "Kodas") {
        _safeMint(_msgSender(), 10);
    }

    function mint(uint256 _amount) external payable {
        address _caller = _msgSender();
        require(!paused, "Paused");
        require(MAX_SUPPLY >= totalSupply() + _amount, "Exceeds max supply");
        require(_amount > 0, "No 0 mints");
        require(MAX_PER_TX >= _amount, "Excess max per paid tx");

        if (FREE_MAX_SUPPLY >= totalSupply()) {
            require(MAX_PER_TX_FREE >= _amount, "Excess max per free tx");
        } else {
            require(MAX_PER_TX >= _amount, "Excess max per paid tx");
            require(msg.value >= _amount * price, "Invalid funds provided");
        }

        _safeMint(_caller, _amount);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = _msgSender().call{value: balance}("");
        require(success, "Failed to send");
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setMaxFreeSupply(uint256 freeSupply) external onlyOwner {
        FREE_MAX_SUPPLY = freeSupply;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist.");
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(_tokenId),
                        baseExtension
                    )
                )
                : "";
    }
}