pragma solidity >=0.5.8;

contract Demo {
    event Echo(string message);

    function echo(string calldata message) external {
        emit Echo(message);
    }
}