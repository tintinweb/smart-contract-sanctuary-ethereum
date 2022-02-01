// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

interface ERC721Contract {
    function balanceOf(address owner) external view returns (uint256);
}

contract NFTL is Ownable, ERC721A, ReentrancyGuard {
    string public NFTL_PROVENANCE = "";

    // Public sale params
    bool public SALE_IS_ACTIVE = false;

    bool public PRESALE_IS_ACTIVE = false;
    
    uint256 public collectionStartingIndexBlock;

    uint private startingIndex;
    
    uint public constant MAX_NFTL_PURCHASE = 20; // to save gas, some place used value instead of var, so be careful during changing this value
    uint256 public MAX_NFTL = 10000; // to save gas, some place used value instead of var, so be careful during changing this value

    uint256 public saleEndTimeStamp;

    uint256 public NFTL_PRICE = 69000000000000000; // 0.069 ETH

    uint public reserveNFTL = 35;

    // ############################# modifier #############################
    modifier whenPublicSaleActive() {
        require(SALE_IS_ACTIVE, "Public sale is not active");
        _;
    }

    // ############################# constructor #############################
    constructor() ERC721A("RageAgainstLeMeme", "NFTL", 20, 10000) { }
    
    // ############################# function section #############################
    
    // ***************************** onlyOwner : Start *****************************

    function setSaleEndTimeStamp(uint256 _saleEndTimeStamp) public onlyOwner {
        saleEndTimeStamp = _saleEndTimeStamp;
    }
    
    function withdraw() public onlyOwner {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "Transfer failed.");
    }

    function setNFTLPrice(uint256 price) public onlyOwner {
        NFTL_PRICE = price;
    }

    function setMaxNFTL(uint256 maxNFTL) public onlyOwner {
        MAX_NFTL = maxNFTL;
    }

    function mintReserveNFTL(address _to, uint256 _reserveAmount) public onlyOwner {        
        require(_reserveAmount > 0 && _reserveAmount <= reserveNFTL, "Not enough reserve left");
        _safeMint(_to, _reserveAmount);
        reserveNFTL = reserveNFTL - _reserveAmount;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        NFTL_PROVENANCE = provenanceHash;
    }
    
    function pauseSale() external onlyOwner {
        SALE_IS_ACTIVE = false;
    }

    function pausePreSale() external onlyOwner {
        PRESALE_IS_ACTIVE = false;
    }

    /**
     * Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        collectionStartingIndexBlock = block.number;
    }
    
    function startSale() external onlyOwner {
        require(!SALE_IS_ACTIVE, "Public sale has already begun");
        SALE_IS_ACTIVE = true;
    }

    function startPreSale() external onlyOwner {
        require(!PRESALE_IS_ACTIVE, "Presale has already begun");
        PRESALE_IS_ACTIVE = true;
    }

    // ***************************** onlyOwner : End *****************************

    // ***************************** public view : Start *************************
    
    function tokensOfOwner(address _owner) public view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function publicBalanceOfCats(address _owner) public view returns(uint256) {
        address rektCatAddress = 0x13fc42944Dc32Bba381A38F2Ee64f8231eF597E2;
        ERC721Contract rektCats = ERC721Contract(rektCatAddress);
        return rektCats.balanceOf(_owner);
    }

    function presaleMintNFTL(uint numberOfTokens) public payable {

        uint256 currentTotalSupply = totalSupply();
        require(PRESALE_IS_ACTIVE, "Pre-sale must be active to mint NFTL");
        require(saleEndTimeStamp > block.timestamp, "Minting close");
        require(numberOfTokens < 21, "Can only mint 20 tokens at a time");
        require(currentTotalSupply + numberOfTokens < 10001, "Purchase would exceed max supply of NFTLs"); // ref MAX_NFTL
        uint256 costToMint = NFTL_PRICE * numberOfTokens;
        require(costToMint <= msg.value, "Ether value sent is not correct");

        if (currentTotalSupply == 0) {
            collectionStartingIndexBlock = block.number;
        }

        _safeMint(msg.sender, numberOfTokens);
    }

    function mintNFTL(uint numberOfTokens) public payable {
        uint256 currentTotalSupply = totalSupply();
        require(SALE_IS_ACTIVE, "Sale must be active to mint NFTL");
        require(saleEndTimeStamp > block.timestamp, "Minting close");
        require(numberOfTokens < 21, "Can only mint 20 tokens at a time");
        require(currentTotalSupply + numberOfTokens < 10001, "Purchase would exceed max supply of NFTLs"); // ref MAX_NFTL
        uint256 costToMint = NFTL_PRICE * numberOfTokens;
        require(costToMint <= msg.value, "Ether value sent is not correct");

        if (currentTotalSupply == 0) {
            collectionStartingIndexBlock = block.number;
        }

        _safeMint(msg.sender, numberOfTokens);
    }

    function getTime() public view virtual returns(uint256) {
        return block.timestamp;
    }

    // Set the starting index for the collection
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(collectionStartingIndexBlock != 0, "Starting index block must be set");
        
        uint newStartingIndex = 0;
        newStartingIndex = uint(blockhash(collectionStartingIndexBlock)) % MAX_NFTL;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number - collectionStartingIndexBlock > 255) {
            newStartingIndex = uint(blockhash(block.number - 1)) % MAX_NFTL;
        }
        // Prevent default sequence
        if (newStartingIndex == 0) {
            newStartingIndex = newStartingIndex + 1;
        }
        startingIndex = newStartingIndex;
    }

    // // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
      _baseTokenURI = baseURI;
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
      _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
      return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
      external
      view
      returns (TokenOwnership memory)
    {
      return ownershipOf(tokenId);
    }
}