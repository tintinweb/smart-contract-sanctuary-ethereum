/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


    // requires further comments
contract OraclePOC {

    uint constant coreDataTypes = 6; //bool[], uint[], int[], address[], bytes32[], string[]

    // indicates how many of each core data type is linked to this address
    mapping(string => uint[coreDataTypes]) private valuesCountMapping;
    
    mapping(string => bool) private usedMapping;
    mapping(string => bool[]) private boolsMapping;
    mapping(string => int[]) private integerMapping;
    mapping(string => uint[]) private integerUnsignedMapping;
    mapping(string => address[]) private accountIdMapping;
    mapping(string => bytes32[]) private bytes32Mapping;
    mapping(string => string[]) private stringMapping;

    //the owner address of this contract, i.e. who can add data
    address private _owner;
   
    
    /**
     * @dev Emitted when contract owner is changed from `oldContractOwnerId` to `newContractOwnerId`.
     */
    event OwnerChanged(address indexed oldContractOwnerId, address indexed newContractOwnerId);

    /**
     * @dev Emitted when new data is added to this contract's storage.
     *
     * - `key` is the key given for this data's lookup. It can be used with the read functions to discover the related data
     */
    event newData(string key);

    constructor(address owner_) {
         _owner = owner_;
    }

    /**
     * @dev Functions using this modifier restrict the caller to only be the contract owner address (or the account operator of the owner)
     */
   modifier onlyOwner {
        require(msg.sender == owner(), "Caller is not the owner");
      _;
   }

    function setDataValues(string calldata _key, bool[] memory _boolValues, int[] memory _integerValues, uint[] memory _integerUnsignedValues, address[] memory _accountIdValues, bytes32[] memory _bytes32Values, string[] memory _stringValues) external onlyOwner {
        require(usedMapping[_key] == false, "Key has already been used");
        valuesCountMapping[_key] = [_boolValues.length, _integerValues.length, _integerUnsignedValues.length, _accountIdValues.length, _bytes32Values.length, _stringValues.length];
        usedMapping[_key] = true;
        boolsMapping[_key] = _boolValues;
        integerMapping[_key] = _integerValues;
        integerUnsignedMapping[_key] = _integerUnsignedValues;
        accountIdMapping[_key] = _accountIdValues;
        bytes32Mapping[_key] = _bytes32Values;
        stringMapping[_key] = _stringValues;
        emit newData(_key);
    }

    /**
     * @dev Changes the contract owner to 'newContractOwnerId', i.e. who can mint new tokens
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Requirements:
     *
     * - caller must have the owner role.
     */
    function changeOwner(address newContractOwnerId) external onlyOwner() returns (bool) {
        require(newContractOwnerId != address(0x0), "Zero address used");
        address oldOwner = _owner;
        _owner = newContractOwnerId;
        emit OwnerChanged(oldOwner, newContractOwnerId);
        return true;
    }

    /**
     * @dev Returns the address with the owner role of this token contract, 
     * i.e. what address can add new data.
     * if a multi-sig owner is required, this address should 
     * point to a smart contract implementing this multi-sig.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    function isKeyUsed(string calldata _key) external view returns(bool)  {
        return usedMapping[_key]; 
    }

    function getDataValueCount(string calldata _key) external view returns(uint[coreDataTypes] memory)  {
        return valuesCountMapping[_key]; 
    }

    function getDataBooleanValueCount(string calldata _key) external view returns(uint)  {
        return boolsMapping[_key].length; 
    }

    function getDataBooleanValue(string calldata _key, uint _arrayNumber) external view returns(bool)  {
        return boolsMapping[_key][_arrayNumber]; 
    }

    function getDataIntegerValueCount(string calldata _key) external view returns(uint)  {
        return integerMapping[_key].length; 
    }

    function getDataIntegerValue(string calldata _key, uint _arrayNumber) external view returns(int)  {
        return integerMapping[_key][_arrayNumber]; 
    }

    function getDataIntegerUnsignedValueCount(string calldata _key) external view returns(uint)  {
        return integerMapping[_key].length; 
    }

    function getDataIntegerUnsignedValue(string calldata _key, uint _arrayNumber) external view returns(uint)  {
        return integerUnsignedMapping[_key][_arrayNumber]; 
    }

    function getDataAccountIdValueCount(string calldata _key) external view returns(uint)  {
        return accountIdMapping[_key].length; 
    }

    function getDataAccountIdValue(string calldata _key, uint _arrayNumber) external view returns(address)  {
        return accountIdMapping[_key][_arrayNumber]; 
    }

    function getDataBytes32ValueCount(string calldata _key) external view returns(uint)  {
        return bytes32Mapping[_key].length; 
    }

    function getDataBytes32Value(string calldata _key, uint _arrayNumber) external view returns(bytes32)  {
        return bytes32Mapping[_key][_arrayNumber]; 
    }

    function getDataStringValueCount(string calldata _key) external view returns(uint)  {
        return stringMapping[_key].length; 
    }

    function getDataStringValue(string calldata _key, uint _arrayNumber) external view returns(string memory)  {
        return stringMapping[_key][_arrayNumber]; 
    }


}