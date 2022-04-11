import "./ERC721.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title Dragons of Zobrotera contract
 * @dev Extends ERC721 Non-Fungible Token Standard implementation
 */
contract DOZ is AccessControl, ERC721{
    using SafeMath for uint256;

    // White listed role
    bytes32 private constant whiteListedRole = keccak256("whitelisted");

    // Max mint per transaction
    uint public constant maxNftPurchase = 40; 

    // Mapping from address to number of mint during presale
    mapping(address => uint256) private presaleAllowedMint;
    // Mapping from address to number of mint during presale
    mapping(address => uint256) private presaled;

    // Tokens total count
    uint256 private count = 0;
    // Test tokens total count
    uint256 private testCount = 1 * (10 ** 10);
    // NFT price
    uint256 private nftPrice = 0.55 * (10 ** 18);
    // Reserved number of giveaway
    uint256 private numberOfGiveaways = 100;
    // Maximum number of nft that can be minted
    uint256 private maxSupply = 10000;
    // Maximum max supply during presale
    uint256 private maxSupplyAtPresaleEnd = 400;
    // Status of the official sale
    bool private saleIsActive = false;
    // Status of the presale
    bool private presaleIsActive = false;

    // Event emitted when a token as been minted safly
    event SafeMinted(address who, uint256 timestamp, uint256[] tokenIds, bool isTestMint);
    // Event emitted when a token as been minted safly througt a giveaway
    event GiveawaySafeMinted(address[] winners);
    // Event emitted for the surprise
    event CholroneSafeMinted(address who);

    /**
        Initialize and setup the admin role for the owner
    */
    constructor() ERC721("Dragons of Zobrotera", "DOZ") {
        _setRoleAdmin(whiteListedRole, DEFAULT_ADMIN_ROLE);
        _setupRole(getRoleAdmin(whiteListedRole), msg.sender);
    }

    function internalMint(address to, uint256 numberOfToken) private {
        uint256[] memory output = new uint256[](numberOfToken);

        for(uint32 i = 0; i < numberOfToken; i++){
            uint mintIndex = totalSupply();
            _safeMint(to, mintIndex);
            output[i] = mintIndex;
            count += 1;
        }

        emit SafeMinted(to, block.timestamp, output, false);
    }

    /**
        Update the number of reserved giveaway
        @param _numberOfGiveaway the new number of reserved giveaway
    */
    function reserveGiveaways(uint256 _numberOfGiveaway) public onlyOwner {
        numberOfGiveaways = _numberOfGiveaway;
    }

    /**
        Withdraw ether from the contract to the owner's wallet
    */
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    /**
        Add new white listed addresses
        Used to identify the presale authorized wallets
        @param addresses the new addresses to add to the white list  
    */
    function whitelistAddressesForPresale(address[] memory addresses, uint256 allowedMint) public onlyOwner{
        for(uint32 i = 0; i < addresses.length; i++){
            grantRole(whiteListedRole, addresses[i]);
            presaleAllowedMint[addresses[i]] = allowedMint;
        }
    }

    /** 
        Airdrop giveaway into the winners wallets
        @param winners the winners addresses list
    */
    function airdropGiveaways(address[] memory winners) public onlyOwner {
        require(totalSupply().add(winners.length) <= maxSupply, "Airdrop would exceed max supply of Nfts");

        for(uint32 i = 0; i < winners.length; i++){
            internalMint(winners[i], 1);
        }
    }

    /**
        Toggle the official sale state
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
        Toggle the official sale state
    */
    function flipPresaleState() public onlyOwner {
        presaleIsActive = !presaleIsActive;
    }

    /**
        Update the total max supply
        @param newMaxSupply the new max supply
     */
    function updateMaxSupply(uint256 newMaxSupply) public onlyOwner {
        require(newMaxSupply >= count);
        maxSupply = newMaxSupply;
    }

    /**
        Update the total max supply
        @param newMaxSupply the new max supply
     */
    function updatePresaleMaxSupply(uint256 newMaxSupply) public onlyOwner {
        require(newMaxSupply >= count);
        maxSupplyAtPresaleEnd = newMaxSupply;
    }
    
    /**
        Mint a nft during the presale
    */
    function mintNftOnPresale(uint64 numberOfToken) public payable onlyRole(whiteListedRole) {
        require(presaleIsActive, "Preale must be active to mint Nft");
        require(!saleIsActive, "Presale as been closed");
        require(totalSupply().add(numberOfToken) <= maxSupplyAtPresaleEnd, "Purchase would exceed max supply during presale");
        require(nftPrice.mul(numberOfToken) <= msg.value, "Ether value sent is not correct");
        require(presaled[msg.sender].add(numberOfToken) <= presaleAllowedMint[msg.sender], "You can't mint anymore");
        
        internalMint(msg.sender, numberOfToken);
        presaled[msg.sender] = numberOfToken;
    }

    /**
        Mint a nft during the official sale
        @param numberOfToken the number of token to mint
    */
    function mintNft(uint64 numberOfToken) public payable {
        require(saleIsActive, "Sale must be active to mint Nft");
        require(totalSupply().add(numberOfToken) <= maxSupply.sub(numberOfGiveaways), "Purchase would exceed max supply of Nfts");
        require(nftPrice.mul(numberOfToken) <= msg.value, "Ether value sent is not correct");
        require(numberOfToken <= maxNftPurchase, "You can't mint more than 20 token in the same transaction");
        
        internalMint(msg.sender, numberOfToken);
    }

    /**
        Get the current total supply
        @return uint256
    */
    function numberOfGiveawayReserved() public view returns (uint256) {
        return numberOfGiveaways;
    }

    /**
        Get the current total supply
        @return uint256
    */
    function totalSupply() public view returns (uint256) {
        return count;
    }

    /**
        Get the current official sale state
        @return boolean
    */
    function isSaleActive() public view returns (bool) {
        return saleIsActive;
    }

    /**
        Get the current presale state
        @return boolean
    */
    function isPresaleActive() public view returns (bool) {
        return presaleIsActive;
    }

    /**
        Get the current presale state
        @return boolean
    */
    function presaleMaxSupply() public view returns (uint256) {
        return maxSupplyAtPresaleEnd;
    }

    /**
        Get the current presale state
        @return boolean
    */
    function mintPrice() public view returns (uint256) {
        return nftPrice;
    }

    /**
        Emergency: price can be changed in case of large fluctuations in ETH price.
        This feature is here to prevent nft from having prices that are too different from each other.
        WITH A MAXIMUM OF 0.1 ETH
        @param newPrice the new nft price
    */
    function emergencyChangePrice(uint256 newPrice) public onlyOwner {
        require(newPrice >= 0, "Price can't be lower than 0");
        nftPrice = newPrice;
    }
}