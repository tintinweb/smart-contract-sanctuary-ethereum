pragma solidity 0.8.16;

import "./Deployed.sol";

contract Deployer {

    event DeployedContract(address indexed contractAddress);

    function deployContract() external {
        Deployed deployedContract = new Deployed();
        emit DeployedContract(address(deployedContract));
    }
}

pragma solidity 0.8.16;

contract Deployed {
    uint256 currentNumber;

    event NewNumber(uint256 indexed number);

    function setNumber(uint256 newNumber) external {
        currentNumber = newNumber;
        emit NewNumber(newNumber);
    }
}