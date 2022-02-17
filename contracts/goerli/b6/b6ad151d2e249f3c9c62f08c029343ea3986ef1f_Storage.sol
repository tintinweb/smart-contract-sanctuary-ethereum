/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

pragma solidity >=0.4.22 <0.9.0;

contract Storage{

    uint256 private number;

    function store(uint256 num) public {
        number = num;
    }

    function retreive() public view returns (uint256){
        return number;
    }

}