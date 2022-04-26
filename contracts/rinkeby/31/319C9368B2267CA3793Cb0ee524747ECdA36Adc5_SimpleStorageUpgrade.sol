pragma solidity ^0.8.0;
//import "hardhat/console.sol";

contract SimpleStorageUpgrade {
    uint storeData;

    event Change(string message, uint newVal);

    function set(uint x) public {
//        console.log("ddd");
        require(x < 5000, "Should be less than 5000");
        storeData = x;
        emit Change("set", x);
    }

    function get() public view returns (uint) {
        return storeData;
    }
}