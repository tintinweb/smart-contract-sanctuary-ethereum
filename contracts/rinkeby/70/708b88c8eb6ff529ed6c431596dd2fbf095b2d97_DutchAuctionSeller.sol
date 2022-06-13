// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Formule1.sol";
import "./Strings.sol";

contract DutchAuctionSeller is Ownable {

    uint256 public startDate;

    uint256 public endDate;

    uint256 public startPrice;

    uint256 public endPrice;
    
    Formule1 private collection;

    function initCollection(address collectionContractAdress) external  {
        collection =  Formule1(collectionContractAdress );
    }

    bool public paused = true;
    constructor()
        {

        }

    function create(address targetAddress) external payable {
        require(msg.value >= getCurrentPrice(), "Value is less than current price");
        require(paused == true,"Auction is paused");
        collection.mint(targetAddress);
    }

    function setDetails(uint256 _startDate, uint256 _endDate, uint256 _startPrice, uint256 _endPrice) external onlyOwner{
        startDate =_startDate;
        endDate = _endDate;
        startPrice=  _startPrice;
        endPrice=_endPrice;
    }

    function setPause(bool _paused) external onlyOwner {
        paused = _paused;
    }

    function getCurrentPrice() public view returns(uint256) {
        uint256 nowSeconds = block.timestamp;       
        require(nowSeconds>=startDate, "Auction didn't start yet");
        require(!paused, "Auction is on pause !");
        if(nowSeconds >= endDate) {
            return endPrice;
        }
        uint256 gap = startPrice - endPrice;
        uint256 duree = endDate - startDate;
        uint256 distanceFin = endDate - nowSeconds;
        uint256 r = distanceFin * gap / duree;
        r = r + endPrice;
        return  r;
    }


    function timeBlock256() external view returns(uint256){
        uint256 nowSeconds = block.timestamp;
        return nowSeconds;
    }

}