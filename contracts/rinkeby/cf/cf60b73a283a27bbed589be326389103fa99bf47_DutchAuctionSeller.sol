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

    bool public paused = false;
    constructor()
        {

        }

    function create(address targetAddress) external payable {
        require(msg.value *10^18 >= getCurrentPrice(), "Value is less than current price");
        require(paused == false,"Auction is paused");
        //uint256 nowSeconds = block.timestamp; 
        //require(startDate >= nowSeconds,"Auction is not started.");
        collection.mint(targetAddress);
    }

    function setDetails(uint256 _startDate, uint256 _endDate, uint256 _startPrice, uint256 _endPrice) external onlyOwner{
        //uint256 nowSeconds = block.timestamp; 
        //require(_startDate >= nowSeconds,"startdate can't be past");
        require(_endDate >= _startDate,"endate must be superior to startdate");
        require(_startPrice > _endPrice,"startprice must be superior to endprice");
        require(_endPrice > 0,"endprice must be superior or egal to 0");
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
        //require(nowSeconds>=startDate, "Auction didn't start yet");
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