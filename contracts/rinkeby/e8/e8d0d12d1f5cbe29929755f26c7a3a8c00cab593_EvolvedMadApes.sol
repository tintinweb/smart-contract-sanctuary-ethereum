// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract EvolvedMadApes is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 9898;
    uint256 public constant MAX_PUBLIC_MINT = 3;
    uint256 public constant MAX_WHITELIST_MINT = 3;
    uint256 public constant MAX_OG_MINT = 4;
    uint256 public constant PUBLIC_SALE_PRICE = .022 ether;
    uint256 public constant WHITELIST_SALE_PRICE = .016 ether;
    uint256 public constant TEAM_MINT_QUANT = 20;

    string private baseTokenUri;
    string public placeholderTokenUri;

    //deploy smart contract, toggle WL, toggle WL when done, toggle publicSale 
    bool public isRevealed = false;
    bool public publicSale = false;
    bool public whiteListSale = false;
    bool public pause = false;
    bool public teamMinted = false;

    mapping(address => uint256) public allowlist;

    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalWhitelistMint;

    constructor() ERC721A("Evolved Mad Apes", "EMA"){

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Evolved Mad Apes - Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require(publicSale, "Evolved Mad Apes - Not Yet Active.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Evolved Mad Apes - Beyond Max Supply");
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_PUBLIC_MINT, "Evolved Mad Apes - Already Minted 3 Times!");
        require(msg.value >= (PUBLIC_SALE_PRICE * _quantity), "Evolved Mad Apes - Below ");
        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function whitelistMint(uint256 _quantity) external payable callerIsUser{
        require(whiteListSale, "Evolved Mad Apes - Whitelist Mint Is Not Active");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Evolved Mad Apes - Cannot mint beyond max supply");
        require((totalWhitelistMint[msg.sender] + _quantity)  <= MAX_WHITELIST_MINT, "Evolved Mad Apes - Already Minted Maximum Times!");
        require(msg.value >= (WHITELIST_SALE_PRICE * _quantity), "Evolved Mad Apes - Payment is below the price");
        require(allowlist[msg.sender] > 0, "Evolved Mad Apes - You are not whitelisted");
        totalWhitelistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function teamMint() external onlyOwner{
        require(!teamMinted, "Evolved Mad Apes - Team already minted");
        teamMinted = true;
        _safeMint(msg.sender, TEAM_MINT_QUANT);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId + 1;

        if(!isRevealed){
            return placeholderTokenUri;
        }
        //string memory baseURI = _baseURI();
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }

    /// @dev walletOf() function shouldn't be called on-chain due to gas consumption
    function walletOf() external view returns(uint256[] memory){
        address _owner = msg.sender;
        uint256 numberOfOwnedNFT = balanceOf(_owner);
        uint256[] memory ownerIds = new uint256[](numberOfOwnedNFT);

        for(uint256 index = 0; index < numberOfOwnedNFT; index++){
            ownerIds[index] = tokenOfOwnerByIndex(_owner, index);
        }

        return ownerIds;
    }

    function SetWhitelist(address[] memory addresses, uint256 numSlots) external onlyOwner
    {
        require(
            numSlots > 0,
            "MintAmount < 1 "
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = numSlots;
        }
    }
    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }
    function setPlaceHolderUri(string memory _placeholderTokenUri) external onlyOwner{
        placeholderTokenUri = _placeholderTokenUri;
    }

    function togglePause() external onlyOwner{
        pause = !pause;
    }

    function toggleWhiteListSale() external onlyOwner{
        whiteListSale = !whiteListSale;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function toggleReveal() external onlyOwner{
        isRevealed = !isRevealed;
    }

    function withdraw() external onlyOwner{
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}