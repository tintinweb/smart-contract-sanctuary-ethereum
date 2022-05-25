pragma solidity 0.6.12;

interface MockLendingPool {
    function reeterantCall() external;
}

contract ReeterantCall {
    function attack(address contractAddress) external {
        MockLendingPool(contractAddress).reeterantCall();
    }
}