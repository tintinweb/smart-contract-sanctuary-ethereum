// SPDX-License-Identifier: MIT
//  _______     _____  _ __     _______ ____    __  __    _    ____       _    ____  _____ ____  
// | ____\ \   / / _ \| |\ \   / / ____|  _ \  |  \/  |  / \  |  _ \     / \  |  _ \| ____/ ___| 
// |  _|  \ \ / / | | | | \ \ / /|  _| | | | | | |\/| | / _ \ | | | |   / _ \ | |_) |  _| \___ \ 
// | |___  \ V /| |_| | |__\ V / | |___| |_| | | |  | |/ ___ \| |_| |  / ___ \|  __/| |___ ___) |
// |_____|  \_/  \___/|_____\_/  |_____|____/  |_|  |_/_/   \_\____/  /_/   \_\_|   |_____|____/ 

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract EvolvedMadApes is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant MAX_PUBLIC_MINT = 5;
    uint256 public constant MAX_WHITELIST_MINT = 5;
    uint256 public constant MAX_OG_MINT = 6;
    uint256 public PUBLIC_SALE_PRICE = .14 ether;
    uint256 public WHITELIST_SALE_PRICE = .12 ether;

    string private baseTokenUri;
    string public placeholderTokenUri;

    address internal immutable founders = 0x6C1Ae0Fa69EbE027F3E93b5634F7c3E86448F860;
    address internal immutable donation = 0xac647d49fC1c928f2Ce866815AaBFD14913C32a7;

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
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_PUBLIC_MINT, "Evolved Mad Apes - Already Minted Maximum Times!");
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

    function SpecialMint(uint _quantity) external onlyOwner{
        teamMinted = true;
        _safeMint(msg.sender, _quantity);
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
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri,trueId.toString(),".json")) : "";
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
    function SetPublicPrice(uint256 price ) external onlyOwner
    {
        PUBLIC_SALE_PRICE = price;
    }
    function SetWhitelistPrice(uint256 price ) external onlyOwner
    {
        WHITELIST_SALE_PRICE = price;
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

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(founders).transfer((balance * 950) / 1000);
        payable(donation).transfer((balance * 50) / 1000);
    }
}