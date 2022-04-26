/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract Prediction {
    struct Price {
        string trainingPrice;
        string predictedPrice;
        string trainingDate;
        string predictionDate;
    }
    mapping(string => Price) public prices;
    
    function addPrice(string memory stockName, string memory trainingPrice, string memory predictedPrice, string memory trainingDate, string memory predictionDate) public {
        prices[stockName] = Price(trainingPrice, predictedPrice, trainingDate, predictionDate);
    }

    function getPrice(string memory stockName) public view returns (Price memory) {
        return prices[stockName];
    }

}