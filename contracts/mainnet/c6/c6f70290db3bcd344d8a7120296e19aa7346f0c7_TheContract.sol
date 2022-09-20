// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./AdminPause.sol";
import "./RoyaltiesConfig.sol";

contract TheContract is ERC721A, AdminPause, RoyaltiesConfig {
    uint256 public maxSupply = 10000;
    uint256 public walletCap = 3;
    uint256 public price = 0.01 ether;
    bool public saleActive;
    bool public burnStatus;
    string private tokenName;
    string private tokenSymbol;
    string private baseURI;

    constructor(string memory _tokenName, string memory _tokenSymbol) 
        ERC721A(_tokenName, _tokenSymbol) 
        {
            tokenName = _tokenName;
            tokenSymbol = _tokenSymbol;
        }

    // SETUP & ADMIN FUNCTIONS //

    function toggleSaleStatus() public onlyAdmins {
        saleActive = !saleActive;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyAdmins {
        maxSupply = _maxSupply;
    }

    function setPrice(uint256 _price) public onlyAdmins {
        price = _price;
    }

    function setWalletCap(uint256 _walletCap) public onlyAdmins {
        walletCap = _walletCap;
    }

    function toggleBurnStatus() public onlyAdmins {
        burnStatus = !burnStatus;
    }

    function setTokenName(string memory _tokenName) public onlyAdmins {
        tokenName = _tokenName;
    }

    function setTokenSymbol(string memory _tokenSymbol) public onlyAdmins {
        tokenName = _tokenSymbol;
    }

    function setBaseURI(string memory URI) public onlyAdmins {
        baseURI = URI;
    }

    function reserve(address _address, uint256 amount) public onlyAdmins {
        require(
            amount + _numberMinted(_address) <= walletCap,
            string(
                abi.encodePacked(
                    "Maximum tokens per wallet is ",
                    _toString(walletCap)
                )
            )
        );

        safeMint(_address, amount);
    }

    function withdraw(address _address) public onlyAdmins {
        payable(_address).transfer(address(this).balance);
    }

    // PUBLIC FUNCTIONS //

    function mint(uint256 amount) public payable whenNotPaused {
        require(saleActive, "Sale is not available now");

        require(msg.value == price * amount, "Incorrect amount of Ether sent");

        require(
            amount + _numberMinted(msg.sender) <= walletCap,
            string(
                abi.encodePacked(
                    "Maximum tokens per wallet is ",
                    _toString(walletCap)
                )
            )
        );

        safeMint(msg.sender, amount);
    }

    function burn(uint256 tokenId) public whenNotPaused {
        require(burnStatus, "Token burning is not available now");
        _burn(tokenId, true);
    }

    // METADATA & MISC FUNCTIONS //

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, RoyaltiesConfig)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            RoyaltiesConfig.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function name() public view override returns (string memory) {
        return tokenName;
    }

    function symbol() public view override returns (string memory) {
        return tokenSymbol;
    }

    function safeMint(address to, uint256 amount) internal {
        require(totalSupply() + amount <= maxSupply, "Too few tokens remaining");
        _safeMint(to, amount);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal whenNotPaused override {}
}