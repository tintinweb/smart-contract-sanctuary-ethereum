pragma solidity ^0.8.7;

/**
* @title ContractName
* @dev ContractDescription
* @custom:dev-run-script file_path
*/
contract contractFuction {
    uint value;
    function getValue() external view returns(uint) {
        return value;
    }

    // pure is used to do logic within function 
    // function addNumber() external pure returns(uint) {
    //     return 1 + 1;
    // }

    function setValue(uint _value) external {
        value = _value;
    }

    // this private funtion no one call from out side from contract is used to do logic within function 
    function addNumber() external pure returns(uint) {
        return 1 + 1;
    }
}