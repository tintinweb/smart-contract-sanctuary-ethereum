/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

pragma solidity >=0.4.22 <0.8.0;
contract SimpleStorage{
    uint256  number;

    function setData(uint256 num)  public{
        number = num;
    }

    function getData() public view returns(uint256){
      return number;
    }
}