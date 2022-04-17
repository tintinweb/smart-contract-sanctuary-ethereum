// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Moonguns is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 2000;
    uint256 public maxPerTx = 10;
    uint256 public maxPerAddress = 20;
    uint256 public mintPrice = 0.005 ether;

    string private _baseTokenURI;

    uint256 private mintCount = 0;
    uint256 public freeMintAmount = 600;

    bool public saleOpen = true;
    mapping(address => bool) public allowlists;

    bool public revealed = false;
    string public unRevealedURI =
        "https://ipfs.io/ipfs/QmfD2whNT7q7TYY2WkYKFA1ZFVmXAnEN2zAy4BawjKgBKg";

    constructor() ERC721A("Moonguns", "Moonguns") {
        allowlists[msg.sender] = true;
    }

    function mint(uint256 _num) external payable userOnly {
        require(saleOpen, "Sale is not open yet");
        require(totalSupply() + _num <= maxSupply, "Exceeds maximum supply");
        require(_num > 0, "Minimum 1 NFT has to be minted per transaction");

        if (allowlists[msg.sender] != true) {
            require(
                _num <= maxPerTx,
                "Maximum 5 NFTs can be minted per transaction"
            );
            require(
                numberMinted(msg.sender) + _num <= maxPerAddress,
                "Max mint amount per wallet exceeded."
            );
            if ((mintCount + _num) > freeMintAmount) {
                require(
                    msg.value >= mintPrice * _num,
                    "Ether sent with this transaction is not correct"
                );
            }
        }

        mintCount += _num;

        _safeMint(msg.sender, _num);
    }

    modifier userOnly() {
        require(tx.origin == msg.sender, "SP: We like real users");
        _;
    }

    function setAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlists[addresses[i]] = true;
        }
    }

    function flipSale() external onlyOwner {
        saleOpen = !saleOpen;
    }

    function flipRevealed(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            revealed
                ? string(
                    abi.encodePacked(_baseTokenURI, tokenId.toString(), ".json")
                )
                : unRevealedURI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }
}