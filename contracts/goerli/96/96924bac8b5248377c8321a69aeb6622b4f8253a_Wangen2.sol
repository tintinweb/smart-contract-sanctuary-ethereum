// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC1155Supply.sol";
import "./AggregatorV3Interface.sol";

contract Wangen2 is Ownable, ERC1155Supply {
    using Strings for uint256;
    using Address for address payable;

    uint256 public constant BRONZE_TOKEN_ID = 1;
    uint256 public constant SILVER_TOKEN_ID = 2;
    uint256 public constant GOLD_TOKEN_ID = 3;
    uint256 public constant PLATINUM_TOKEN_ID = 4;
    uint256 public constant BLACK_TOKEN_ID = 5;

    AggregatorV3Interface private usdByEthFeed;
    AggregatorV3Interface private usdByEuroFeed;

    string public name = "Christopher Wangen collection";

    string public symbol = "CW";

    //SUPPLIES

    uint256 public goldMaxSupply = 50;

    uint256 public platMaxSupply = 10;

    uint256 public blackMaxSupply = 5;

    uint256 public goldCryptoMaxSupply = goldMaxSupply / 2;

    uint256 public platinumCryptoMaxSupply = platMaxSupply / 2;

    uint256 public blackCryptoMaxSupply = blackMaxSupply / 2;

    //PRICES

    uint256 public bronzeEurPrice = 200;

    uint256 public silverEurPrice = 1000;

    uint256 public goldEurPrice = 2600;

    uint256 public platEurPrice = 10000;

    uint256 public blackEurPrice = 20000;

    uint256 public eurFunds;

    uint256 public maxEurFunds = 400000;

    address public dropperAddress;

    address public stakingContractAddress;

    uint public openingTransferDate;
      
    address public fundsReceiver = 0x7EFFC0db5d98e2fD82bc9aD495452A032092225f;

    bool public buyBack = false;

    address public burnerAddress;
          
    uint buyBackThreshold = 1825779802;

    bool public isPaused = false;


    constructor(address usdByEthFeedAddress, address usdByEuroFeedAddress)
    ERC1155("https://storage.googleapis.com/devmetata666666/Wag-wan/metadata/")
        {
            usdByEthFeed = AggregatorV3Interface(usdByEthFeedAddress);
            usdByEuroFeed = AggregatorV3Interface(usdByEuroFeedAddress);
        }
 

    function mint(uint256 bronzeCount, uint256 silverCount, uint256 goldCount, uint256 platiniumCount, uint256 blackCount) external payable {
        require(isPaused == false,"Contract is paused");
        _checkMaxSupply(bronzeCount, silverCount, goldCount, platiniumCount, blackCount);
        _checkCryptoSupply(goldCount, platiniumCount, blackCount);
        uint256 totalEurPrice = (bronzeCount * bronzeEurPrice) + (silverCount * silverEurPrice);
        totalEurPrice = totalEurPrice + (goldCount * goldEurPrice) + (platiniumCount * platEurPrice) + (blackCount * blackEurPrice);
        _checkPayment(totalEurPrice);
        _checkMaxPrice(totalEurPrice);
        eurFunds = eurFunds + totalEurPrice;
        uint256 freeTokens = platiniumCount * 6 + blackCount * 14;
        _uncheckedMint(msg.sender, bronzeCount + freeTokens, silverCount, goldCount, platiniumCount, blackCount);
    }

    function drop(address to, uint256 bronzeCount, uint256 silverCount, uint256 goldCount, uint256 platiniumCount, uint256 blackCount) external {
        require(isPaused == false,"Contract is paused");
        require(msg.sender == owner() || msg.sender == dropperAddress, "not allowed");
        _checkMaxSupply(bronzeCount, silverCount, goldCount, platiniumCount, blackCount);
        uint256 freeBronzeCount = platiniumCount * 6 + blackCount * 14;
        uint paidBronzeCount = freeBronzeCount >= bronzeCount ? 0 : bronzeCount - freeBronzeCount;
        uint256 totalEurPrice = (paidBronzeCount * bronzeEurPrice) + (silverCount * silverEurPrice);
        totalEurPrice = totalEurPrice + (goldCount * goldEurPrice) + (platiniumCount * platEurPrice) + (blackCount * blackEurPrice);
        _checkMaxPrice(totalEurPrice);
        eurFunds = eurFunds + totalEurPrice;
        _uncheckedMint(to, bronzeCount, silverCount, goldCount, platiniumCount, blackCount);
    }

    function _uncheckedMint(address to, uint256 bronzeCount, uint256 silverCount, uint256 goldCount, uint256 platinumCount, uint256 blackCount) private {
        unchecked{
            if(bronzeCount>0){
                _mint(to, 1, bronzeCount, "");
                _safeTransferFrom(to,stakingContractAddress,1,bronzeCount,"");
            }
            if(silverCount>0){
                _mint(to, 2, silverCount, "");
                _safeTransferFrom(to,stakingContractAddress,2,silverCount,"");
            }
            if(goldCount>0){
                _mint(to, 3, goldCount, "");
                _safeTransferFrom(to,stakingContractAddress,3,goldCount,"");
            }
            if(platinumCount>0){
                _mint(to, 4, platinumCount, "");
                _safeTransferFrom(to,stakingContractAddress,4,platinumCount,"");
            }
            if(blackCount>0){
                _mint(to, 5, blackCount, "");
                _safeTransferFrom(to,stakingContractAddress,5,blackCount,"");
            }
        }
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(tokenId), tokenId.toString(), ".json"));
    }


    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

   

    function setDropperAddress(address _dropperAddress) external onlyOwner {
        dropperAddress = _dropperAddress;
    }

    function setMaxEurFunds(uint256 _maxEurFunds) external onlyOwner {
        maxEurFunds = _maxEurFunds;
    }

    function setStakingContract(address _stackingContratAddress) external onlyOwner {
        stakingContractAddress = _stackingContratAddress;
    }

    function setOpeningTransferDate(uint _openingTransferDate) external onlyOwner {
        openingTransferDate = _openingTransferDate;
    }
    
    function setFundsReceiver(address  _fundsReceiver) external onlyOwner {
        fundsReceiver = _fundsReceiver;
    }

    function activeBuyBack() external onlyOwner {
        require(buyBack == false, "buyback is already active");
        require(buyBackThreshold < block.timestamp);
        buyBack = true;
    }

    // DEV TIME
    function setBuyBackThreshold(uint _buyBackThreshold) external onlyOwner {
        buyBackThreshold = _buyBackThreshold;
    }

    function setBurnerAddress(address _burnerAddress) external onlyOwner {
        burnerAddress = _burnerAddress;
    }

    function setPause(bool _pause) external onlyOwner {
        isPaused = _pause;
    }

    //SUPPLY CHECKER
    function _checkMaxSupply(uint256 bronzeCount, uint256 silverCount, uint256 goldCount, uint256 platiniumCount, uint256 blackCount) private view {
        require(bronzeCount>=0&&silverCount>=0&&goldCount>=0&&platiniumCount>=0&&blackCount>=0, "quantity must be positive");
        require(totalSupply(3) + goldCount<= goldMaxSupply, "gold supply reached");
        require(totalSupply(4) + platiniumCount<= platMaxSupply, "platinium supply reached");
        require(totalSupply(5) + blackCount<= blackMaxSupply, "black supply reached");
    }

    function _checkCryptoSupply(uint256 goldCount, uint256 platiniumCount, uint256 blackCount) private view {
        require(totalSupply(3) + goldCount <= goldCryptoMaxSupply, "gold crypto supply reached");
        require(totalSupply(4) + platiniumCount <= platinumCryptoMaxSupply, "platinium crypto supply reached");
        require(totalSupply(5) + blackCount <= blackCryptoMaxSupply, "black crypto supply reached");
    }

    function _checkMaxPrice(uint256 priceInEuro) private view {
        require(eurFunds + priceInEuro<= maxEurFunds, "eur max funds reached");
    }

    
    //PAYMENT CHECKER
    
    function _checkPayment(uint256 priceInEuro) private view {
        uint256 priceInWei = getWeiPrice(priceInEuro);
        uint256 minPrice = (priceInWei * 995) / 1000;
        uint256 maxPrice = (priceInWei * 1005) / 1000;
        require(msg.value >= minPrice, "Not enough ETH");
        require(msg.value <= maxPrice, "Too much ETH");
    }
    
    //PRICE CALCULATION FUNCTIONS

    function getUsdByEth() private view returns (uint256) {
        (, int256 price, , , ) = usdByEthFeed.latestRoundData();
        return uint256(price);
    }

    function getUsdByEuro() private view returns (uint256) {
        (, int256 price, , , ) = usdByEuroFeed.latestRoundData();
        return uint256(price);
    }

    function getWeiPrice(uint256 priceInEuro) public view returns (uint256) {
        uint256 priceInDollar = (priceInEuro * getUsdByEuro() * 10**18) / 10**usdByEuroFeed.decimals();
        uint256 weiPrice = (priceInDollar * 10**usdByEthFeed.decimals()) / getUsdByEth();
        return weiPrice;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Supply) {       
        if(openingTransferDate > block.timestamp){
            require(from == address(0)
                || from == address(stakingContractAddress)
                || to == address(stakingContractAddress),
                "Not allowed");
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function retrieveFunds() external {
        require(
            msg.sender == owner() ||
            msg.sender == fundsReceiver,
            "Not allowed"
        );
        
       payable(fundsReceiver).sendValue(address(this).balance);
    }

    function setMaxSupply(uint256 tokenid,uint256  supply) external onlyOwner {
        require(tokenid > 2 && tokenid < 6 && supply >= 0 , "Bad parameter provided");
        if(tokenid == 3){
            goldMaxSupply = supply;
        }else if(tokenid == 4){
            platMaxSupply = supply;
        }else  if(tokenid == 5){
            blackMaxSupply = supply;
        }
    }

    function setCryptoMaxSupply(uint256 tokenid,uint256  supply) external onlyOwner {
        require(tokenid > 2 && tokenid < 6 && supply >= 0 , "Bad parameter provided");
        if(tokenid == 3){
            goldCryptoMaxSupply = supply;
        }else if(tokenid == 4){
            platinumCryptoMaxSupply = supply;
        }else  if(tokenid == 5){
            blackCryptoMaxSupply = supply;
        }
    }
   

    function setTokenPrice(uint256 tokenid, uint256 price) external onlyOwner{
        require(tokenid > 0 && tokenid < 6 && price > 0 , "Bad parameter provided");
        if(tokenid == 1){
            bronzeEurPrice = price;
        }else if(tokenid == 2){
            silverEurPrice = price;
        }else if(tokenid == 3){
            goldEurPrice = price;
        }else if(tokenid == 4){
            platEurPrice = price;
        }else  if(tokenid == 5){
            blackEurPrice = price; 
        }
    }

    function airBurn(uint256[] memory ids, uint256[] memory amounts, address from) external {
        require(msg.sender == burnerAddress && burnerAddress != address(0), "This operation is not allowed" );
        require(buyBack == true, "Burn is not allowed out of buyBack period");
        require(ids.length == amounts.length, 'Bad idss and amounts parameters');
        _burnBatch(from,ids,amounts);
    }

    function burn(uint256[] memory ids, uint256[] memory amounts) external {
        require(ids.length == amounts.length, 'Bad idss and amounts parameters');
        require(buyBack == true, "Burn is not allowed out of buyBack period");
        _burnBatch(msg.sender,ids,amounts);
    }
    
}