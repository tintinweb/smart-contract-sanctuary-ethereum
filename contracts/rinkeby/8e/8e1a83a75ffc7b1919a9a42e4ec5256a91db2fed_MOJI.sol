// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract MOJI is Ownable, ERC721A, ReentrancyGuard {
    mapping (uint256 => string) public provenance;

    // Public sale params
    bool public SALE_IS_ACTIVE = false;
    
    mapping (uint256 => uint256) public seriesStartingIndexBlock;

    mapping (uint256 => uint256) public seriesStartingIndex;
    
    // sell price
    uint256 public price = 69000000000000000; // 0.069 ETH
    
    uint public constant MAX_MOJI_PURCHASE = 20; // to save gas, some place used value instead of var, so be careful during changing this value

    uint256 public initialSeriesSize = 1000;
    uint256 public currentSeries = 1;

    uint256 public maxSupplyWithCurrentSeries = 1000;
    uint256 public currentSeriesSize = 1000;

    uint256 public saleDuration;
    uint256 public saleStartTime;
    uint256 public saleStartingPrice;
    // sell min price
    uint256 public saleMinPrice = 1000000000000000; 
    
    // ############################# constructor #############################
    constructor() ERC721A("MOJI", "MOJI", 20, 900000) { }
    
    // ############################# function section #############################

    // ***************************** internal : Start *****************************
    function getElapsedSaleTime() internal view returns (uint256) {
        return saleStartTime > 0 ? block.timestamp - saleStartTime : 0;
    }
    // ***************************** internal : End *****************************
    
    // ***************************** onlyOwner : Start *****************************
    
    function withdraw() public onlyOwner {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "Transfer failed.");
    }

    function setProvenanceHash(string memory provenanceHash, uint256 series) public onlyOwner {
        require(series <= currentSeries, "Only can set provenance for started series");
        provenance[series] = provenanceHash;
    }
    
    function pauseSale() external onlyOwner {
        SALE_IS_ACTIVE = false;
    }

    function lockTraits(uint256 lockSeriesNum) external onlyOwner {
        require(lockSeriesNum <= currentSeries, "Can not lock future series");

        uint256 lockIndex = initialSeriesSize * ((2 ** lockSeriesNum) - 1); 
        require(traitsLockedIndex() < lockIndex,"Can not unlock already locked items");

        _lockTraits(lockIndex);
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    /**
     * Set the starting index block for the series, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(seriesStartingIndex[currentSeries] == 0, "Starting index is already set");
        
        seriesStartingIndexBlock[currentSeries] = block.number;
    }
    
    // function startSale() external onlyOwner {
    //     require(!SALE_IS_ACTIVE, "Public sale has already begun");
    //     SALE_IS_ACTIVE = true;
    // }

    function startSale(uint256 duration, uint256 startPrice) external onlyOwner {
        require(!SALE_IS_ACTIVE, "Public sale has already begun");
        saleDuration = duration;
        saleStartingPrice = startPrice;
        saleStartTime = block.timestamp;
        SALE_IS_ACTIVE = true;
    }

    function startNextSeries() external onlyOwner {
        require(seriesStartingIndex[currentSeries] != 0, "Starting index block must be set");
        // require(totalSupply() == maxSupplyWithCurrentSeries, "current series not fully minted");
        currentSeries += 1;
        maxSupplyWithCurrentSeries = initialSeriesSize * ((2 ** currentSeries) - 1);
        currentSeriesSize = initialSeriesSize * (2 ** (currentSeries - 1));

    }

    // ***************************** onlyOwner : End *****************************

    // ***************************** public view : Start ****************************

    function getDropCount(uint256 maxPrice) public view returns (uint256) {
        if(maxPrice> 1000000000000000000) return (32 + ((maxPrice - 1000000000000000000)/250000000000000000)); 
        else if (maxPrice> 50000000000000000) return (13+ ((maxPrice - 50000000000000000)/ 50000000000000000)); 
        else if (maxPrice> 10000000000000000) return (9+ ((maxPrice - 10000000000000000)/ 10000000000000000)); 
        else if (maxPrice> 1000000000000000) return ((maxPrice - 1000000000000000)/ 1000000000000000); 
        else return 0;
    }

    function getDropedPrice(uint256 dropedPoint) public view returns (uint256)  {
        if(dropedPoint > 32) return ((dropedPoint-32) * 250000000000000000 + 1000000000000000000);
        else if(dropedPoint > 13) return ((dropedPoint-13)*50000000000000000 + 50000000000000000);
        else if(dropedPoint > 9) return ((dropedPoint-9)*10000000000000000 + 10000000000000000);
        else if(dropedPoint > 0) return ((dropedPoint)*1000000000000000 +1000000000000000);
        else return 1000000000000000;
    }

    function mintPrice() public view returns (uint256) {
        uint256 elapsed = getElapsedSaleTime();
        if (elapsed >= saleDuration) {
            return saleMinPrice;
        } else {
            uint256 currentPrice = 40 * elapsed / saleDuration;
            return
                currentPrice > saleMinPrice ? currentPrice : saleMinPrice;
        }
    }

    // function getDropedPrice(uint256 dropedPoint) {
    //     if(dropedPoint > 32) return parseFloat((dropedPoint-32)*0.25 + 1).toFixed(3);
    //     else if(dropedPoint > 13) return parseFloat((dropedPoint-13)*0.05 + 0.05).toFixed(3);
    //     else if(dropedPoint > 9) return parseFloat((dropedPoint-9)*0.01 + 0.01).toFixed(3);
    //     else if(dropedPoint > 0) return parseFloat((dropedPoint)*0.001 + 0.001).toFixed(3);
    //     else return 0.001;
    // }

    function getRemainingSaleTime() public view returns (uint256) {
        require(saleStartTime > 0, "Public sale hasn't started yet");
        if (getElapsedSaleTime() >= saleDuration) {
            return 0;
        }

        return (saleStartTime + saleDuration) - block.timestamp;
    }

    function mintWithD(uint numberOfTokens) public payable {
        uint256 currentTotalSupply = totalSupply();
        require(SALE_IS_ACTIVE, "Sale must be active to mint MOJI");
        require(numberOfTokens < 21, "Can only mint 20 tokens at a time");
        require(currentTotalSupply + numberOfTokens <= maxSupplyWithCurrentSeries, "Purchase would exceed max supply of MOJIs"); // ref MAX_MOJI
        uint256 costToMint = getDropedPrice(13) * numberOfTokens;
        require(costToMint <= msg.value, "Ether value sent is not correct");    
        
        if (seriesStartingIndexBlock[currentSeries] == 0) {
            seriesStartingIndexBlock[currentSeries] = block.number;
        }
        
        _safeMint(msg.sender, numberOfTokens);
    }

    function setCurrentSeries(uint256 _CurrentSeries) public {
        currentSeries = _CurrentSeries;
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
        require(ownerOf(tokenId) == msg.sender, "Your wallet does not own this token!");
        require(bytes(traitsCode).length == 64, "Traits code is invalid");
        _setTokenTraitsCode(tokenId, traitsCode);
    }

    function tokenTraitsCode(uint256 tokenId) public view returns(string memory) {
        return _tokenTraits(tokenId);
    }

    function setTokenRevealed(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Your wallet does not own this token!");
        _setTokenRevealed(tokenId);
    }
    
    function isTokenRevealed(uint256 tokenId) public view returns(bool) {
        return _isTokenRevealed(tokenId);
    }

    function mint(uint numberOfTokens) public payable {
        uint256 currentTotalSupply = totalSupply();
        require(SALE_IS_ACTIVE, "Sale must be active to mint MOJI");
        require(numberOfTokens < 21, "Can only mint 20 tokens at a time");
        require(currentTotalSupply + numberOfTokens <= maxSupplyWithCurrentSeries, "Purchase would exceed max supply of MOJIs"); // ref MAX_MOJI
        uint256 costToMint = price * numberOfTokens;
        require(costToMint <= msg.value, "Ether value sent is not correct");    
        
        if (seriesStartingIndexBlock[currentSeries] == 0) {
            seriesStartingIndexBlock[currentSeries] = block.number;
        }
        
        _safeMint(msg.sender, numberOfTokens);
    }
    
    // Set the starting index for the series
    function setStartingIndex() public {
        require(seriesStartingIndex[currentSeries] == 0, "Starting index is already set");
        require(seriesStartingIndexBlock[currentSeries] != 0, "Starting index block must be set");

        uint newStartingIndex = 0;
        newStartingIndex = uint(blockhash(seriesStartingIndexBlock[currentSeries])) % currentSeriesSize;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number - seriesStartingIndexBlock[currentSeries] > 255) {
            newStartingIndex = uint(blockhash(block.number - 1)) % currentSeriesSize;
        }
        // Prevent default sequence
        if (newStartingIndex == 0) {
            newStartingIndex = newStartingIndex + 1;
        }
        newStartingIndex = maxSupplyWithCurrentSeries - currentSeriesSize + newStartingIndex;
        seriesStartingIndex[currentSeries] = newStartingIndex;
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