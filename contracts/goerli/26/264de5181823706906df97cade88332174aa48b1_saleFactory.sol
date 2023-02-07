// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract saleFactory {
    address[] public deployedSales;

    function createNFTsale(string memory NFTname, string memory NFTsymbol, uint256 price, uint256 MaxTokens, uint256 TokensReserved, string memory baseNFTURI, uint256 MaxPerWallet, uint256 MaxPerTX) public {
        address newSale = address(new NFT(msg.sender, NFTname, NFTsymbol, price, MaxTokens, TokensReserved, baseNFTURI, MaxPerWallet, MaxPerTX));

        deployedSales.push(newSale);

    }

    function getDeployedSales() public view returns ( address[] memory) {
        return deployedSales;
    }

}

contract NFT is ERC721URIStorage, Ownable {

    using Strings for uint256;

    address public Creator;
    uint256 public MAX_TOKENS;
    uint256 private TOKENS_RESERVED;
    uint256 public price;
    uint256 public MAX_MINT_PER_TX;
    uint256 public MAX_MINT_PER_WALLET;
    string public NFTName;
    string public NFTSymbol;


    bool public isSaleActive;
    uint256 public totalSupply;
    mapping (address => uint256) private mintedPerWallet;

    string public baseURI;
    string public baseExtension = ".json";

    modifier onlyCreator() {
        require(msg.sender == Creator);
        _;
    }

    constructor(address creator, string memory NFTname, string memory NFTsymbol, uint256 Price, uint256 MaxTokens, uint256 TokensReserved, string memory baseNFTURI, uint256 MaxPerWallet, uint256 MaxPerTX ) ERC721(NFTname, NFTsymbol) {
        baseURI = baseNFTURI;
        Creator = creator;
        NFTName = NFTname;
        NFTSymbol = NFTsymbol;
        price = Price;
        TOKENS_RESERVED = TokensReserved;
        totalSupply = TOKENS_RESERVED;
        MAX_TOKENS = MaxTokens;
        MAX_MINT_PER_TX = MaxPerTX;
        MAX_MINT_PER_WALLET = MaxPerWallet;

        for (uint256 i =1; i<TOKENS_RESERVED; i++) {
            _safeMint (msg.sender, i);
        }

    }

    function mint(uint256 _numTokens) external payable {
        require(isSaleActive, "Paused");
        require(_numTokens <= MAX_MINT_PER_TX, "Bad amnt");
        require(mintedPerWallet[msg.sender] + _numTokens <= MAX_MINT_PER_WALLET);
        uint256 curTotalSupply = totalSupply;
        require(curTotalSupply + _numTokens <= MAX_TOKENS);
        require(_numTokens * price <= msg.value, "No balance");

        for (uint256 i = 1; i<=_numTokens; ++i) {
            uint256 newTokenID = curTotalSupply + i;
            _safeMint(msg.sender, newTokenID);
            _setTokenURI(newTokenID, tokenURI(newTokenID));
        }
        mintedPerWallet[msg.sender] += _numTokens;
        totalSupply += _numTokens;
    }

    function getTokenURI(uint256 tokenID) public view returns(string memory) {
        return tokenURI(tokenID);
    }

    function flipSaleState() external onlyCreator {
        isSaleActive = !isSaleActive;
    }

    function setBaseURI(string memory _baseURI) external onlyCreator {
        baseURI = _baseURI;
    }

    function withdrawAll() external payable onlyCreator {
        uint256 balance = address(this).balance;
        (bool transfer,) = payable(msg.sender).call{value: balance}("");

        require(transfer);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "URI none"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0

        ? string (abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";

    }

    function _baseURI() internal view  virtual override returns (string memory) {
        return baseURI;
    }

    function getSaleInfo() public view returns (address, uint256, uint256, uint256, uint256, string memory, string memory, string memory, bool, uint256 ) {
        return (
        Creator,
        MAX_TOKENS,
        price,
        MAX_MINT_PER_TX,
        MAX_MINT_PER_WALLET,
        NFTName,
        NFTSymbol,
        baseURI,
        isSaleActive,
        totalSupply
        );
    }
}