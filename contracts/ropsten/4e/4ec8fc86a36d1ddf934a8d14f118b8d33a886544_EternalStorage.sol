/**
 *Submitted for verification at Etherscan.io on 2022-07-12
*/

pragma solidity 0.4.24;

// SLETI BDB 2022

/**
 * @title EternalStorage
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 */
contract EternalStorage {

  mapping(bytes32 => uint256) internal uintStorage;
  mapping(bytes32 => string) internal stringStorage;
  mapping(bytes32 => address) internal addressStorage;
  mapping(bytes32 => bytes) internal bytesStorage;
  mapping(bytes32 => bool) internal boolStorage;
  mapping(bytes32 => int256) internal intStorage;

}

contract LogicContract is EternalStorage {
    // Has storage collision with 
    // Contract: UpgradeabilityOwnerStorage - address private _upgradeabilityOwner;
    address public collision_upgradeabilityOwner;

    // Read function: Get data from stringStorage with index keccak256(abi.encodePacked("testVariable"))
    function getTestVariable() public view returns (string) {
        return stringStorage[keccak256(abi.encodePacked("testVariable"))];
    }

    // Set function: Set data for stringStorage with index keccak256(abi.encodePacked("testVariable"))
    function setTestVariable(string _testVariable) public {
        stringStorage[keccak256(abi.encodePacked("testVariable"))] = _testVariable;
    }

    // Read function: Get message sender address
    function readSenderAddress() public view returns (address) {
        return msg.sender;
    }

    // Read function: Get this contract address
    // Returns proxy contract address when called from a proxy contract
    function readContractAddress() public view returns (address) {
        return address(this);
    }
}