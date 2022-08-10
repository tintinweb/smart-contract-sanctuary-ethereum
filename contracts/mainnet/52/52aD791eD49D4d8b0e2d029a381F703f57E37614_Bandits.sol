// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Burnable.sol";
import "./SafeMath.sol";
import "./IERC721.sol";

/**
 * @title Bandits Contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract Bandits is ERC721Burnable {
    using SafeMath for uint256;
    uint16 private mintedCount;

    bool public privateSale;
    bool public publicSale;

    string public baseTokenURI;
    uint16 public MAX_SUPPLY;
    uint16 public RESEVE_AMOUNT;

    uint16 public maxByMint;
    uint256 public mintPrice;

    address private admin;

    mapping(address => bool) public mintedWL;

    string public constant CONTRACT_NAME = "Bandits Contract";
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant MINT_TYPEHASH =
        keccak256("Mint(address user,uint256 num)");

    constructor(address _admin) ERC721("Bandits In The Metaverse", "BITM") {
        MAX_SUPPLY = 3333;
        RESEVE_AMOUNT = 133;
        mintPrice = 0.025 ether;
        maxByMint = 3;
        admin = _admin;
        uint16 tokenId = totalSupply();
        _safeMint(msg.sender, tokenId);
        mintedCount = mintedCount + 1;
    }

    function setPrivateSaleStatus(bool status) external onlyOwner {
        privateSale = status;
    }

    function setPublicSaleStatus(bool status) external onlyOwner {
        publicSale = status;
    }

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    function setCount(uint16 _max_supply, uint16 _maxByMint)
        external
        onlyOwner
    {
        MAX_SUPPLY = _max_supply;
        maxByMint = _maxByMint;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function totalSupply() public view virtual returns (uint16) {
        return mintedCount;
    }

    function getTokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner);
        uint256 supply = totalSupply();

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;
            uint256 tokenId;

            for (tokenId = 0; tokenId < supply; tokenId++) {
                if (_owners[tokenId] == owner) {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                    if (resultIndex >= tokenCount) {
                        break;
                    }
                }
            }
            return result;
        }
    }

    function mintByUser(uint8 _numberOfTokens) external payable {
        require(publicSale, "Public Sale is not active");
        require(tx.origin == msg.sender, "Only EOA");
        require(
            totalSupply() + _numberOfTokens <= MAX_SUPPLY - RESEVE_AMOUNT,
            "Max Limit To Presale"
        );
        require(_numberOfTokens <= maxByMint, "Exceeds Amount");
        require(mintPrice * _numberOfTokens <= msg.value, "Low Price To Mint");

        for (uint8 i = 0; i < _numberOfTokens; i += 1) {
            uint16 tokenId = uint16(totalSupply() + i);
            _safeMint(msg.sender, tokenId);
        }
        mintedCount = mintedCount + _numberOfTokens;
    }

    function mintByUserPrivate(
        uint8 _numberOfTokens,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        require(privateSale, "Private Sale is not active");
        require(!mintedWL[msg.sender], "You minted aleady");
        require(tx.origin == msg.sender, "Only EOA");
        require(
            totalSupply() + _numberOfTokens <= MAX_SUPPLY - RESEVE_AMOUNT,
            "Max Limit To Presale"
        );
        require(_numberOfTokens <= maxByMint, "Exceeds Amount");
        require(mintPrice * _numberOfTokens <= msg.value, "Low Price To Mint");

        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(CONTRACT_NAME)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(MINT_TYPEHASH, msg.sender, _numberOfTokens)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == admin, "Invalid signatory");

        for (uint8 i = 0; i < _numberOfTokens; i += 1) {
            _safeMint(msg.sender, mintedCount + i);
        }

        mintedCount = mintedCount + _numberOfTokens;
        mintedWL[msg.sender] = true;
    }

    function reserveNft(address account, uint8 _numberOfTokens)
        external
        onlyOwner
    {
        require(
            totalSupply() + _numberOfTokens <= MAX_SUPPLY,
            "Max Limit To Presale"
        );

        for (uint8 i = 0; i < _numberOfTokens; i += 1) {
            uint16 tokenId = uint16(totalSupply() + i);
            _safeMint(account, tokenId);
        }
        mintedCount = mintedCount + _numberOfTokens;
    }

    function withdrawAll() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        payable(msg.sender).transfer(totalBalance);
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}