/**
 *Submitted for verification at Etherscan.io on 2022-11-22
*/

pragma solidity 0.8.8;

contract NumberStorage{
    mapping(address => uint256) public addressFavNumber;

    function getNumberForAddress(address _addr) public view returns (uint256){
        // if value was never set, return default value
        return addressFavNumber[_addr];
    }
    function setFavNumber(uint256 number) public {
        //update or set value for sender address
        addressFavNumber[msg.sender]=number;
    }
    function getNumberForMyAddress() public view returns (uint256){
        return addressFavNumber[msg.sender];
    }
}