// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./DefaultOperatorFilterer.sol";

contract TheCatz is DefaultOperatorFilterer, ERC721A, Ownable {
    using Strings for uint256;
    uint256 public maxSupply = 5555;
    uint256 public maxFreeAmount = 5555;
    uint256 public maxFreePerWallet = 1;
    uint256 public price = 0.002 ether;
    uint256 public maxPerTx = 100;
    uint256 public maxPerWallet = 100;
    uint256 public teamReserved = 555;
    bool public mintEnabled = false;
    string public baseURI;

    constructor() ERC721A("The Catz", "Catz") {
        _safeMint(msg.sender, 2);
    }

    function mint(uint256 quantity) external payable {
        require(mintEnabled, "Minting is not live yet.");
        require(totalSupply() + quantity < maxSupply + 1, "No more");
        uint256 cost = price;
        uint256 _maxPerWallet = maxPerWallet;

        if(totalSupply() < maxFreeAmount && _numberMinted(msg.sender) < maxFreePerWallet && quantity <= maxFreePerWallet) {
            cost = 0;
            _maxPerWallet = maxFreePerWallet;
        }
        
        require(
            _numberMinted(msg.sender) + quantity <= _maxPerWallet,
            "Max per wallet"
        );

        uint256 needPayCount = quantity;
        if (_numberMinted(msg.sender) == 0) {
            needPayCount = quantity - 1;
        }
        require(
            msg.value >= needPayCount * cost,
            "Please send the exact amount."
        );
        _safeMint(msg.sender, quantity);
    }

    function teamMint() public onlyOwner {
        _safeMint(msg.sender, teamReserved);
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function flipSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setMaxFreeAmount(uint256 _amount) external onlyOwner {
        maxFreeAmount = _amount;
    }

    function setMaxFreePerWallet(uint256 _amount) external onlyOwner {
        maxFreePerWallet = _amount;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }

    //=========================================================================
    // OPENSEA-PROVIDED OVERRIDES for OPERATOR FILTER REGISTRY
    //=========================================================================

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}