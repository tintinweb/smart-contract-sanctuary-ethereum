// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract MOJI is Ownable, ERC721A, ReentrancyGuard {
    string public MOJI_PROVENANCE = "";

    // Public sale params
    bool public SALE_IS_ACTIVE = false;
    
    uint256 public collectionStartingIndexBlock;

    uint private startingIndex;
    
    // sell price
    uint256 public MOJI_PRICE = 69000000000000000; // 0.069 ETH
    
    uint public constant MAX_MOJI_PURCHASE = 20; // to save gas, some place used value instead of var, so be careful during changing this value
    uint256 public MAX_MOJI = 10000; // to save gas, some place used value instead of var, so be careful during changing this value

    uint256 public InitialStartingSize = 1000;
    uint256 public CurrentSeries = 1;
    


    // ############################# constructor #############################
    constructor() ERC721A("MOJI", "MOJI", 20, 900000) { }
    
    // ############################# function section #############################
    
    // ***************************** onlyOwner : Start *****************************
    
    function withdraw() public onlyOwner {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "Transfer failed.");
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        MOJI_PROVENANCE = provenanceHash;
    }
    
    function pauseSale() external onlyOwner {
        SALE_IS_ACTIVE = false;
    }

    function lockTraits() external onlyOwner {
        _lockTraits();
    }

    function setMOJIPrice(uint256 price) public onlyOwner {
        MOJI_PRICE = price;
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

    // ***************************** onlyOwner : End *****************************

    // ***************************** public view : Start ****************************
    
    function currentSeriesSize() public view returns(uint256) {
        // return InitialStartingSize * (2 ** (CurrentSeries - 1));
        return InitialStartingSize * ((2 ** CurrentSeries) - 1);
    }

    function maxTotalSupplyWithCurrentSeries() public view returns(uint256) {
        return InitialStartingSize * ((2 ** CurrentSeries) - 1);
    }

    function setCurrentSeries(uint256 _CurrentSeries) public {
        CurrentSeries = _CurrentSeries;
    }

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

    function setTokenTraitsCode(uint256 tokenId, string memory traitsCode) public {
        require(ownerOf(tokenId) == msg.sender, "your wallet doesn't own this token!");
        require(bytes(traitsCode).length == 64, "Traits code is invalid");
        _setTokenTraitsCode(tokenId, traitsCode);
    }

    function tokenTraitsCode(uint256 tokenId) public view returns(string memory) {
        return _tokenTraits(tokenId);
    }

    function mintMOJI(uint numberOfTokens) public payable {
        uint256 currentTotalSupply = totalSupply();
        require(SALE_IS_ACTIVE, "Sale must be active to mint MOJI");
        require(numberOfTokens < 21, "Can only mint 20 tokens at a time");
        require(currentTotalSupply + numberOfTokens < 10001, "Purchase would exceed max supply of MOJIs"); // ref MAX_MOJI
        uint256 costToMint = MOJI_PRICE * numberOfTokens;
        require(costToMint <= msg.value, "Ether value sent is not correct");    
        
        if (currentTotalSupply == 0) {
            collectionStartingIndexBlock = block.number;
        }
        
        _safeMint(msg.sender, numberOfTokens);
    }
    
    // Set the starting index for the collection
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(collectionStartingIndexBlock != 0, "Starting index block must be set");
        
        uint newStartingIndex = 0;
        newStartingIndex = uint(blockhash(collectionStartingIndexBlock)) % MAX_MOJI;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number - collectionStartingIndexBlock > 255) {
            newStartingIndex = uint(blockhash(block.number - 1)) % MAX_MOJI;
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