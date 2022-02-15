pragma solidity 0.8.4;


interface IFactory {
    function createContract(bytes memory bytecode, uint salt) external returns (bool);
}

contract Challenge {
    bool public isSolved;
    IFactory factory;

    constructor(address _factory) {
        factory = IFactory(_factory);
    }

    function createContract(bytes memory bytecode, uint salt) public {
        isSolved = factory.createContract(bytecode, salt);
    }
}