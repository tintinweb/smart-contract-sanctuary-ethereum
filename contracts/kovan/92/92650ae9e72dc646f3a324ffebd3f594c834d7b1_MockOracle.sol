pragma solidity >=0.8.0;

contract MockOracle {
    mapping(address => uint256) public getPrice;

    function setPrice(address token, uint256 price) external {
        getPrice[token] = price;
    }
}