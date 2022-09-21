/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

pragma solidity 0.4.24;

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
    
    address public collision_upgradeabilityOwner;

     // Read function: Get data from stringStorage with index keccak256(abi.encodePacked("testVariable"))
    function getTestVariable() public view returns (string) {
        return stringStorage[keccak256(abi.encodePacked("testVariable"))];
    }

    //keccak256(abi.encodePacked("testVariable", "sampleVar"))
    //string(abi.encodePacked("testVariable", "sampleVar"))

    // Set function: Set data for stringStorage with index keccak256(abi.encodePacked("testVariable"))
    function setTestVariable(string _testVariable) public {
        stringStorage[keccak256(abi.encodePacked("testVariable"))] = _testVariable;
    }

    function getSampleVariable() public view returns (string) {
        return stringStorage[keccak256(abi.encodePacked("sampleVariable"))];
    }
    
      function sampleVariable(string _sampleVariable, string _sampleVar2) public {
        stringStorage[keccak256(abi.encodePacked("sampleVariable"))] = string(abi.encodePacked( _sampleVariable, " " , _sampleVar2));
        
    }
}


// Author: Joseph Esparago sample, 2022