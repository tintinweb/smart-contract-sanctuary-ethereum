// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract PM22 is Ownable, ERC721A, ReentrancyGuard {
    mapping (uint256 => string) public Provenance;

    bool public SaleIsActive = false;

    mapping (uint256 => uint256) public seriesStartingIndexBlock;

    mapping (uint256 => uint256) public SeriesStartingIndex;

    mapping (uint256 => uint256) private mintedReserveCountOfSeries;

    uint public constant MaxMOJIPurchase = 100; // to save gas, some place used value instead of var, so be careful during changing this value

    uint256 public initialSeriesSize = 1000;
    uint256 public currentSeries = 1;

    uint256 public maxSupplyWithCurrentSeries = 1000;
    uint256 public currentSeriesSize = 1000;

    uint256 public saleDuration;
    uint256 public saleStartTime;
    uint256 public saleStartingPrice;
    // sell min price
    uint256 public saleMinPrice = 1000000000000000;
    uint256 private numOfDropPoints = 0;
    
    // ############################# constructor #############################
    constructor() ERC721A("PM22", "PM22", 100, 1000) { }

    // ############################# function section #############################

    // ***************************** internal : Start *****************************
    function getElapsedSaleTime() internal view returns (uint256) {
        return saleStartTime > 0 ? block.timestamp - saleStartTime : 0;
    }

    function getNumOfDropPoints(uint256 maxPrice) internal pure returns (uint256) {
        if(maxPrice> 1000000000000000000) return (32 + ((maxPrice - 1000000000000000000)/250000000000000000)); 
        else if (maxPrice> 50000000000000000) return (13+ ((maxPrice - 50000000000000000)/ 50000000000000000)); 
        else if (maxPrice> 10000000000000000) return (9+ ((maxPrice - 10000000000000000)/ 10000000000000000)); 
        else if (maxPrice> 1000000000000000) return ((maxPrice - 1000000000000000)/ 1000000000000000); 
        else return 0;
    }

    function getDroppedPrice(uint256 droppedPoint) internal pure returns (uint256)  {
        if(droppedPoint > 32) return ((droppedPoint-32) * 250000000000000000 + 1000000000000000000);
        else if(droppedPoint > 13) return ((droppedPoint-13)*50000000000000000 + 50000000000000000);
        else if(droppedPoint > 9) return ((droppedPoint-9)*10000000000000000 + 10000000000000000);
        else if(droppedPoint > 0) return ((droppedPoint)*1000000000000000 +1000000000000000);
        else return 1000000000000000;
    }
    // ***************************** internal : End *****************************

    // ***************************** onlyOwner : Start *****************************

    function withdraw() public onlyOwner {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "Transfer failed.");
    }

    function setProvenanceHash(string memory provenanceHash, uint256 series) public onlyOwner {
        require(series <= currentSeries, "Only can set provenance for started series");
        Provenance[series] = provenanceHash;
    }

    function pauseSale() external onlyOwner {
        SaleIsActive = false;
    }

    function lockTraits(uint256 lockSeriesNum) external onlyOwner {
        require(lockSeriesNum <= currentSeries, "Can not lock future series");

        uint256 lockIndex = initialSeriesSize * ((2 ** lockSeriesNum) - 1); 
        require(traitsLockedIndex() < lockIndex,"Can not unlock already locked items");

        _lockTraits(lockIndex);
    }

    function setSaleMinPrice(uint256 _price) public onlyOwner {
        saleMinPrice = _price;
    }

    /**
     * Set the starting index block for the series, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(SeriesStartingIndex[currentSeries] == 0, "Starting index is already set");

        seriesStartingIndexBlock[currentSeries] = block.number;
    }

    function startSale(uint256 duration, uint256 startPrice) external onlyOwner {
        require(!SaleIsActive, "Public sale has already begun");
        saleDuration = duration;
        saleStartingPrice = startPrice;
        saleStartTime = block.timestamp;
        numOfDropPoints = getNumOfDropPoints(startPrice);
        SaleIsActive = true;
    }

    function startNextSeries() external onlyOwner {
        require(SeriesStartingIndex[currentSeries] != 0, "Starting index must be set");
        require(totalSupply() == maxSupplyWithCurrentSeries, "current series not fully minted");
        currentSeries += 1;
        maxSupplyWithCurrentSeries = initialSeriesSize * ((2 ** currentSeries) - 1);
        currentSeriesSize = initialSeriesSize * (2 ** (currentSeries - 1));
        _setCollectionSize(maxSupplyWithCurrentSeries);
    }

    // ***************************** onlyOwner : End *****************************

    // ***************************** public view : Start ****************************

    function MintPrice() public view returns (uint256) {
        uint256 elapsed = getElapsedSaleTime();
        if (elapsed >= saleDuration) {
            return saleMinPrice;
        } else {
            uint256 currentPrice = getDroppedPrice(((numOfDropPoints * getRemainingSaleTime()) / saleDuration) + 1);
            return currentPrice > saleMinPrice ? currentPrice : saleMinPrice;
        }
    }

    function remainingReserveInSeries(uint256 seriesNumber) public view returns (uint256) {
        return 35 - mintedReserveCountOfSeries[seriesNumber];
    }

    function getRemainingSaleTime() public view returns (uint256) {
        require(saleStartTime > 0, "Public sale hasn't started yet");
        if (getElapsedSaleTime() >= saleDuration) {
            return 0;
        }

        return (saleStartTime + saleDuration) - block.timestamp;
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

    function SetTokenTraitsCode(uint256 tokenId, string memory traitsCode) public {
        require(ownerOf(tokenId) == msg.sender, "Your wallet does not own this token!");
        require(bytes(traitsCode).length > 10, "Traits code is invalid");
        _setTokenTraitsCode(tokenId, traitsCode);
    }

    function TokenTraitsCode(uint256 tokenId) public view returns(string memory) {
        return _tokenTraits(tokenId);
    }

    function SetTokenRevealed(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Your wallet does not own this token!");
        _setTokenRevealed(tokenId);
    }

    function IsTokenRevealed(uint256 tokenId) public view returns(bool) {
        return _isTokenRevealed(tokenId);
    }

    function mintReserve(address _to, uint256 _reserveAmount) public onlyOwner {
        require(_reserveAmount > 0 && mintedReserveCountOfSeries[currentSeries] + _reserveAmount <= 35, "Not enough reserve left");
        _safeMint(_to, _reserveAmount);
        mintedReserveCountOfSeries[currentSeries] += _reserveAmount;
    }

    function Mint(uint numberOfTokens) public payable {
        uint256 currentTotalSupply = totalSupply();
        require(SaleIsActive, "Sale must be active to mint MOJI");
        require(numberOfTokens < 101, "Can only mint 100 tokens at a time");
        require(currentTotalSupply + numberOfTokens <= maxSupplyWithCurrentSeries, "Purchase would exceed max supply of MOJIs"); // ref MAX_MOJI
        uint256 costToMint = MintPrice() * numberOfTokens;
        require(costToMint <= msg.value, "Ether value sent is not correct");    

        if (seriesStartingIndexBlock[currentSeries] == 0) {
            seriesStartingIndexBlock[currentSeries] = block.number;
        }

        _safeMint(msg.sender, numberOfTokens);

        if (msg.value > costToMint) {
            (bool success, ) = msg.sender.call{value: msg.value - costToMint}("");
            require(success, "Extra amount refund transfer failed.");
        }
    }

    // Set the starting index for the series
    function setStartingIndex() public {
        require(SeriesStartingIndex[currentSeries] == 0, "Starting index is already set");
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
        SeriesStartingIndex[currentSeries] = newStartingIndex;
    }

    // metadata URI
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