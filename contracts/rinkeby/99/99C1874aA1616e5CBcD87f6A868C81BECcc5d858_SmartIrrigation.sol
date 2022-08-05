/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

/// @title SmartIrrigation
/// @author Walter Cojal Medina
/// @notice Receives the sensors data, process and decides whether to start or stop the irrigaiton
/// @dev SmartContract connect to ESP32 

contract SmartIrrigation {

    // Dirección del profesor
    struct SoilParam {
        uint32 soilMoisture;
        uint16 temperature;
        uint16 humidty;
        bool irrigate;
        uint256 createdAt;
    }

    address public owner;
    uint256 public currentBlock = 0;
    mapping (bytes32 => SoilParam) public Params;

    event nuevo_registro(
        bytes32 id,
        uint32 soilMoisture,
        uint16 temperature,
        uint16 humidty,
        bool irrigate
    );

    constructor () {
        owner = msg.sender;
    }

    function setSoilParams(
        uint32 _soilMoisture, 
        uint16 _temperature, 
        uint16 _humidity
    ) public {
        bytes32 hash_index = keccak256(abi.encodePacked(currentBlock));
        Params[hash_index] = SoilParam(
            _soilMoisture, 
            _temperature, 
            _humidity, 
            false, 
            block.timestamp
        );
        currentBlock++;
        emit nuevo_registro(hash_index, _soilMoisture, _temperature, _humidity, false);
    }

    function getSoilMoisture() public view HasRegister() returns (uint32) {
        bytes32 hash_index = keccak256(abi.encodePacked(currentBlock-1));
        return Params[hash_index].soilMoisture;
    }

    function getTemperature() public view HasRegister() returns (uint16) {
        bytes32 hash_index = keccak256(abi.encodePacked(currentBlock-1));
        return Params[hash_index].temperature;
    }

    function getHumidity() public view HasRegister() returns (uint16) {
        bytes32 hash_index = keccak256(abi.encodePacked(currentBlock-1));
        return Params[hash_index].humidty;
    }

    function getSoilParamAt(uint256 index) public view returns (uint32, uint16, uint16) {
        bytes32 hash_index = keccak256(abi.encodePacked(index));
        SoilParam memory param = Params[hash_index];
        return (param.soilMoisture, param.temperature, param.humidty);
    }

    function updateIrrigation(bool _irrigate) public OnlyOwner(msg.sender) {
        bytes32 hash_index = keccak256(abi.encodePacked(currentBlock-1));
        SoilParam memory _param = Params[hash_index];
        _param.irrigate = _irrigate;
        Params[hash_index] = _param;
    }

    function isIrrigating() public view HasRegister() returns (bool) {
        bytes32 hash_index = keccak256(abi.encodePacked(currentBlock-1));
        return Params[hash_index].irrigate;
    }

    modifier HasRegister() {
        require(currentBlock > 0, "The list is empty");
        _;
    }

    modifier OnlyOwner(address _address) {
        require(_address == owner, "You don't have permission to start irrigating");
        _;
    }

}