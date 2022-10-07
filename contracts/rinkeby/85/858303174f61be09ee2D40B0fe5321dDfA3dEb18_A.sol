// Contract A
pragma solidity ^0.8.13;

contract A {

    address public sender;
    uint256 public balance;

    function delegateCallToB(address _contractLogic, uint256 _balance) external {
        (bool success, ) =  _contractLogic.delegatecall(abi.encodePacked(bytes4(keccak256("setBalance(uint256)")), _balance));
        require(success, "Delegatecall failed");
    }
}