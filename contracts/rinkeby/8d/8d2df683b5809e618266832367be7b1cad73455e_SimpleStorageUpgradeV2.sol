pragma solidity ^0.8.0;
//import "hardhat/console.sol";

contract SimpleStorageUpgradeV2 {
    uint storeData;
    uint storedKey;

    event Change(string message, uint newVal);

    function set(uint x) public {
//        console.log("ddd");
        require(x < 10000, "Should be less than 10000");
        storeData = x;
        emit Change("set", x);
    }

    function get() public view returns (uint) {
        return storeData;
    }

    function setKey(uint key) public {
        storedKey = key;
    }

    function getKey() public view returns (uint) {
        return storedKey;
    }
}