pragma solidity^0.8.9;

interface ICalculator {
    function getResults() external view returns (uint);
}

contract Calculator is ICalculator {
    constructor() public{}

    function getResults() external view returns(uint){
        uint a = 1;
        uint b = 2;
        uint result = a + b;
        return result;
    }
}