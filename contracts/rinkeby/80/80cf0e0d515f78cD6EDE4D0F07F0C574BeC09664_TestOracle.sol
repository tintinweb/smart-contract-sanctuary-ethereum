// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

contract TestOracle{
    mapping(address => int) internal _priceOf;

    function setPriceOf(address _token, int _price) external{
        _priceOf[_token] = _price;
    }

    function priceOf(address _token) external view returns(int price, uint8 decimals){
        price = _priceOf[_token];
        decimals = 18;
    }
    
}