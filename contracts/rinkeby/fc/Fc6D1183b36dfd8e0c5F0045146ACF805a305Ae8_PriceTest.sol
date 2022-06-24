/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

pragma solidity >=0.7.0 <0.9.0;

contract PriceTest{

    uint public price;

    function updatePrice(uint x) public {

        price = x;
    }
}