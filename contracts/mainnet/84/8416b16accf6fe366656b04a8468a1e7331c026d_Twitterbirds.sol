// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Twitterbirds is ERC721A, Ownable {
    using Strings for uint256;

    constructor() ERC721A("Twitterbirds", "Twitterbirds") {}

    uint256 public constant MAX_SUPPLY = 2000;

    uint256 public price = 0.004 ether;

    uint256 public maxPerTransaction = 10;

    uint256 public maxFreeAmountPerAddress = 10;

    uint256 private mintCount = 0;

    uint256 public freeMintAmount = 333;

    string private baseTokenURI;

    bool public saleOpen = true;

    mapping(address => bool) private _mintedFreeAddress;

    mapping(address => uint256) private _mintedFreeAmount;

    event Minted(uint256 totalMinted);

    function totalSupply() public view override returns (uint256) {
        return mintCount;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setFreeAmount(uint256 amount) external onlyOwner {
        freeMintAmount = amount;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function flipSale() external onlyOwner {
        saleOpen = !saleOpen;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }

    function mintOneForFree() external {
        require(
            _mintedFreeAddress[msg.sender] == false,
            "Maxinum 1 free mint for per address."
        );
        _mintedFreeAddress[msg.sender] = true;
        _safeMint(msg.sender, 1);
        emit Minted(1);
    }

    function mint(uint256 _count) external payable {
        uint256 supply = totalSupply();

        require(saleOpen, "Sale is not open yet");
        require(supply + _count <= MAX_SUPLY, "Exceeds maximum supply");
        require(_count > 0, "Minimum 1 NFT has to be minted per transaction");
        require(
            _count <= maxPerTransaction,
            "Maximum 10 NFTs can be minted per transaction"
        );

        if (
            (mintCount + _count) > freeMintAmount ||
            _mintedFreeAmount[msg.sender] + _count > maxFreeAmountPerAddress
        ) {
            require(
                msg.value >= price * _count,
                "Ether sent with this transaction is not correct"
            );
        } else {
            _mintedFreeAmount[msg.sender] += _count;
        }

        mintCount += _count;
        _safeMint(msg.sender, _count);
        emit Minted(_count);
    }

    function reserveMint(uint256 _count) external onlyOwner {
        uint256 supply = totalSupply();

        require(saleOpen, "Sale is not open yet");
        require(supply + _count <= MAX_SUPLY, "Exceeds maximum supply");
        _safeMint(msg.sender, _count);
        emit Minted(_count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
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
            string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json"));
    }
}