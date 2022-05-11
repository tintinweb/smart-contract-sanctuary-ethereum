pragma solidity 0.4.24;

contract StMaticPrice {
    uint256 public price;
    function fullfil(uint256 input) external {
        price = input;
    }
}