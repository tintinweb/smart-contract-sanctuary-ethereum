pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract newContract {
    uint A = 0;
    function setInfo(uint newA) public {
        A = newA;
    }

    function getInfo() public view returns (uint){
        return A;
    }

}