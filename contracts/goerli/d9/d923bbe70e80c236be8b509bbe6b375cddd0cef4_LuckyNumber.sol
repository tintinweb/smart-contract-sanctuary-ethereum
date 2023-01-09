/**
 *Submitted for verification at Etherscan.io on 2023-01-09
*/

pragma solidity ^0.8.1;

contract LuckyNumber{

    
    mapping(address=>uint256) public addressToLuckyNumber;
    uint256 public maxLuckNumber = 1337;
    event LuckNumberSet(address indexed _address, uint256 _luckNumber);
    
    function getMyLuckyNumber() view external returns(uint256){
     require(addressToLuckyNumber[msg.sender] != 0 , "First set your Lucky Number");
     return addressToLuckyNumber[msg.sender];
    }

    function setMyLuckyNumber(uint256 _luckyNumber) external {
        require(_luckyNumber >0 , "Lucky no can not be zero");
        require(_luckyNumber <= maxLuckNumber , "Lucky number can not be greater than 1337");
        addressToLuckyNumber[msg.sender] = _luckyNumber;
        emit LuckNumberSet(msg.sender,_luckyNumber);
    }
}