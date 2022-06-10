// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Formule1.sol";

contract DutchAuctionSeller is Ownable {

    uint256 public startDate;

    uint256 public endDate;

    uint256 public startPrice;

    uint256 public endPrice;


    uint256 public lastBlockTimeStamp;





    // SM ADDRESS
    Formule1 private collection = Formule1(0x6b29DA21D0Ed01CF546F65566C8AD75337deCB86 );

    bool public paused = true;
    // DUTCHAUCTION CONTRACT ADRESS
    constructor()
        {

        }


    function create(address targetAddress, uint256 tokenId, uint256 amount) external payable {
        collection.drop(targetAddress,tokenId,amount);
    }


    function setDetails(uint256 _startDate, uint256 _endDate, uint256 _startPrice, uint256 _endPrice) external  onlyOwner{
        startDate=_startDate;
        endDate=_endDate;
        startPrice=_startPrice;
        endPrice=_endPrice;
    }

    function setPause(bool _paused) external onlyOwner {
        paused = _paused;
    }

    function setTimeBlock() external onlyOwner  returns(uint256){
        lastBlockTimeStamp =  block.timestamp;
        return lastBlockTimeStamp;
    }

    function timeBlock256() external view returns(uint256){
        uint256 nowSeconds = block.timestamp;
        return nowSeconds;
    }


    function timeBlock() external view returns(uint){
        uint nowSeconds = block.timestamp;
        return nowSeconds;
    }


    function getCurrentPrice() external view returns(uint256) {
        uint256 nowSeconds = block.timestamp;
        require(nowSeconds>=startDate, "auction didn't start yet");
        require(!paused, "smart contract is on pause");
        if(nowSeconds >= endDate) {
            return endPrice;
        }
       return ((nowSeconds - endDate) * (startPrice - endPrice)) / (startDate - endDate) + endPrice;
        
    }

    

}