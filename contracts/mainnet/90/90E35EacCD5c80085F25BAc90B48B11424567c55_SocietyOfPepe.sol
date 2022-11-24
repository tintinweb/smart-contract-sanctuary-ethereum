// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";
import "DefaultOperatorFilterer.sol";
import "ERC2981.sol";

contract SocietyOfPepe is ERC721A, Ownable, ERC2981, DefaultOperatorFilterer {
    using Strings for uint256;

    string public baseURI;

    bool public public_mint_status = false;

    uint256 MAX_SUPPLY = 3333;

    string public notRevealedUri;

    bool public revealed = false;

    uint256 public publicSaleCost = 0.03 ether;
    uint256 public max_per_wallet = 10;
    string public contractURI;

    constructor(
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        string memory _contractURI
    ) ERC721A("Society Of Pepe", "SOP") {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        contractURI = _contractURI;
        mint(40);
    }

    function mint(uint256 quantity) public payable {
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Not enough tokens left"
        );

        if (msg.sender != owner()) {
            require(public_mint_status, "public mint is off");
            require(
                balanceOf(msg.sender) + quantity <= max_per_wallet,
                "Per wallet limit reached"
            );
            require(
                msg.value >= (publicSaleCost * quantity),
                "Not enough ether sent"
            );
        }
        _safeMint(msg.sender, quantity);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (revealed == false) {
            return notRevealedUri;
        }

        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    //only owner

    function toggleReveal() public onlyOwner {
        if (revealed == false) {
            revealed = true;
        } else {
            revealed = false;
        }
    }

    function toggle_public_mint_status() public onlyOwner {
        if (public_mint_status == false) {
            public_mint_status = true;
        } else {
            public_mint_status = false;
        }
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function withdraw() public payable onlyOwner {
        (bool main, ) = payable(owner()).call{value: address(this).balance}("");
        require(main);
    }

    function setPublicSaleCost(uint256 _publicSaleCost) public onlyOwner {
        publicSaleCost = _publicSaleCost;
    }

    function setMax_per_wallet(uint256 _max_per_wallet) public onlyOwner {
        max_per_wallet = _max_per_wallet;
    }

    function setMAX_SUPPLY(uint256 _MAX_SUPPLY) public onlyOwner {
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    function setContractURI(string calldata _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }
}