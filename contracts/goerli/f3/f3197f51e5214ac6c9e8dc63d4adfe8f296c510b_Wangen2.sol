// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC1155Supply.sol";
import "./AggregatorV3Interface.sol";

contract Wangen2 is Ownable, ERC1155Supply {
    using Strings for uint256;
    using Address for address payable;

    AggregatorV3Interface private usdByEthFeed;

    AggregatorV3Interface private usdByEuroFeed;

    string public name = "TESTESTESTACW1";

    string public symbol = "CWTEST";

    //SUPPLIES

    uint256 public GOLD_MAX_SUPPLY = 100;

    uint256 public PLAT_MAX_SUPPLY = 50;

    uint256 public BLACK_MAX_SUPPLY = 20;

    uint256 public bronzeSupply;

    uint256 public silverSupply;

    uint256 public goldSupply;

    uint256 public platSupply;

    uint256 public blackSupply;

    //PRICES

    uint256 public BRONZE_EUR_PRICE = 1;

    uint256 public SILVER_EUR_PRICE = 2;

    uint256 public GOLD_EUR_PRICE = 3;

    uint256 public PLAT_EUR_PRICE = 4;

    uint256 public BLACK_EUR_PRICE = 5;

    uint256 public eurFunds;

    uint256 public MAX_EUR_FUNDS = 2000;

    address public dropperAddress;

    address public stakingContractAddress;

    uint public openingTransferDate;

    uint256 public goldCryptoMaxSupply = GOLD_MAX_SUPPLY / 2;

    uint256 public platinumCryptoMaxSupply = PLAT_MAX_SUPPLY / 2;

    uint256 public blackCryptoMaxSupply = BLACK_MAX_SUPPLY / 2;

    address public fundsReceiver = 0x7EFFC0db5d98e2fD82bc9aD495452A032092225f;

   
    

    //metadatas 
    string public baseURI = "https://server.wagmi-studio.com/cw/test/metadata/";


    constructor(address usdByEthFeedAddress, address usdByEuroFeedAddress)
    ERC1155("ipfs://QmSz6SriDmqUTN53h93ivuLAKCibPXbYEnVNq9yfdj22h3/")
        {
            usdByEthFeed = AggregatorV3Interface(usdByEthFeedAddress);
            usdByEuroFeed = AggregatorV3Interface(usdByEuroFeedAddress);
        }
 

    function mint(uint256 bronzeCount, uint256 silverCount, uint256 goldCount, uint256 platiniumCount, uint256 blackCount) external payable {
        _checkMaxSupply(bronzeCount, silverCount, goldCount, platiniumCount, blackCount);
        _checkCryptoSupply(goldCount, platiniumCount, blackCount);
        uint256 totalEurPrice = (bronzeCount * BRONZE_EUR_PRICE) + (silverCount * SILVER_EUR_PRICE);
        totalEurPrice = totalEurPrice + (goldCount * GOLD_EUR_PRICE) + (platiniumCount * PLAT_EUR_PRICE) + (blackCount * BLACK_EUR_PRICE);
        _checkPayment(totalEurPrice);
        _checkMaxPrice(totalEurPrice);
        eurFunds = eurFunds + totalEurPrice;
        uint256 freeTokens = platiniumCount * 6 + blackCount * 14;
        _uncheckedMint(msg.sender, bronzeCount + freeTokens, silverCount, goldCount, platiniumCount, blackCount);
    }

    function drop(address to, uint256 bronzeCount, uint256 silverCount, uint256 goldCount, uint256 platiniumCount, uint256 blackCount) external {
        require(msg.sender == owner() || msg.sender == dropperAddress, "not allowed");
        _checkMaxSupply(bronzeCount, silverCount, goldCount, platiniumCount, blackCount);
        uint256 freeBronzeCount = platiniumCount * 6 + blackCount * 14;
        uint paidBronzeCount = freeBronzeCount >= bronzeCount ? 0 : bronzeCount - freeBronzeCount;
        uint256 totalEurPrice = (paidBronzeCount * BRONZE_EUR_PRICE) + (silverCount * SILVER_EUR_PRICE);
        totalEurPrice = totalEurPrice + (goldCount * GOLD_EUR_PRICE) + (platiniumCount * PLAT_EUR_PRICE) + (blackCount * BLACK_EUR_PRICE);
        _checkMaxPrice(totalEurPrice);
        eurFunds = eurFunds + totalEurPrice;
        _uncheckedMint(to, bronzeCount, silverCount, goldCount, platiniumCount, blackCount);
    }

    function _uncheckedMint(address to, uint256 bronzeCount, uint256 silverCount, uint256 goldCount, uint256 platiniumCount, uint256 blackCount) private {
        unchecked{
            if(bronzeCount>0){
                _mint(to, 1, bronzeCount, "");
                bronzeSupply = bronzeSupply + bronzeCount;
            }
            if(silverCount>0){
                _mint(to, 2, silverCount, "");
                silverSupply = silverSupply + silverCount;
            }
            if(goldCount>0){
                _mint(to, 3, goldCount, "");
                goldSupply = goldSupply + goldCount;
            }
            if(platiniumCount>0){
                _mint(to, 4, platiniumCount, "");
                platSupply = platSupply + platiniumCount;
            }
            if(blackCount>0){
                _mint(to, 5, blackCount, "");
                blackSupply = blackSupply + blackCount;
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

    function setStakingContract(address _stackingContratAddress) external onlyOwner {
        stakingContractAddress = _stackingContratAddress;
    }

    function setOpeningTransferDate(uint _openingTransferDate) external onlyOwner {
        openingTransferDate = _openingTransferDate;
    }

    function setGoldCryptoMaxSupply(uint256 _goldCryptoMaxSupply) external onlyOwner {
        goldCryptoMaxSupply = _goldCryptoMaxSupply;
    }

    function setPlatinumCryptoMaxSupply(uint256 _platinumCryptoMaxSupply) external onlyOwner {
        platinumCryptoMaxSupply = _platinumCryptoMaxSupply;
    }

    function setBlackCryptoMaxSupply(uint256 _blackCryptoMaxSupply) external onlyOwner {
        blackCryptoMaxSupply = _blackCryptoMaxSupply;
    }

    function setFundsReceiver(address  _fundsReceiver) external onlyOwner {
        fundsReceiver = _fundsReceiver;
    }

    
   

    //SUPPLY CHECKER

    function _checkMaxSupply(uint256 bronzeCount, uint256 silverCount, uint256 goldCount, uint256 platiniumCount, uint256 blackCount) private view {
        require(bronzeCount>=0&&silverCount>=0&&goldCount>=0&&platiniumCount>=0&&blackCount>=0, "quantity must be positive");
        require(goldSupply + goldCount<= GOLD_MAX_SUPPLY, "gold supply reached");
        require(platSupply + platiniumCount<= PLAT_MAX_SUPPLY, "platinium supply reached");
        require(blackSupply + blackCount<= BLACK_MAX_SUPPLY, "black supply reached");
    }

    function _checkCryptoSupply(uint256 goldCount, uint256 platiniumCount, uint256 blackCount) private view {
        require(goldSupply + goldCount <= goldCryptoMaxSupply, "gold crypto supply reached");
        require(platSupply + platiniumCount <= platinumCryptoMaxSupply, "platinium crypto supply reached");
        require(blackSupply + blackCount <= blackCryptoMaxSupply, "black crypto supply reached");
    }

    function _checkMaxPrice(uint256 priceInEuro) private view {
        require(eurFunds + priceInEuro<= MAX_EUR_FUNDS, "eur max funds reached");
    }

    function totalSupply() external view returns (uint256)  {
        return bronzeSupply + silverSupply + goldSupply + platSupply + blackSupply;
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

    
}