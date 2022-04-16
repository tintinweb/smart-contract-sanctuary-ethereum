// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Moonguns is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 2000;
    uint256 public maxPerTx = 2;
    uint256 public maxPerAddress = 2;
    uint256 public teamReserve = 10;
    uint256 public mintPrice = 0.01 ether;

    string private _baseTokenURI;

    bool public saleOpen = false;
    mapping(address => bool) public allowlists;

    constructor() ERC721A("Moonguns", "Moonguns") {
        _safeMint(msg.sender, teamReserve);
    }

    function mint(uint256 _num) external payable userOnly {
        require(saleOpen, "Sale is not open yet");
        require(totalSupply() + _num <= maxSupply, "Exceeds maximum supply");
        require(_num > 0, "Minimum 1 NFT has to be minted per transaction");
        require(
            _num <= maxPerTx,
            "Maximum 5 NFTs can be minted per transaction"
        );
        require(
            numberMinted(msg.sender) + _num <= maxPerAddress,
            "Max mint amount per wallet exceeded."
        );

        bool inAllowlist = allowlists[msg.sender] == true;

        if (inAllowlist) {
            allowlists[msg.sender] = false;
        } else {
            require(
                msg.value >= mintPrice * _num,
                "Ether sent with this transaction is not correct"
            );
        }

        _safeMint(msg.sender, _num);

        refundIfOver((inAllowlist ? 0 ether : mintPrice) * _num);
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

    function refundIfOver(uint256 _value) private {
        require(msg.value >= _value, "SP: Insufficient ether amount");
        if (msg.value > _value) {
            payable(msg.sender).transfer(msg.value - _value);
        }
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
            string(
                abi.encodePacked(_baseTokenURI, tokenId.toString(), ".json")
            );
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }
}