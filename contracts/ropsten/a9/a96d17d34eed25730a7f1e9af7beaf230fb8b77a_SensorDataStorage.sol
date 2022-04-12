/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title SensorDataStorage
 */
 
contract SensorDataStorage {

    mapping(uint256 => bool) sensoresActivos;
    mapping(uint256 => uint256) contadorLogs;
    uint256 totalSensores;

    event NewSensorData(uint256 indexed sensorID, uint256 valor, uint256 logID);

    function setSensorValue(uint256 sensorID, uint256 valor) public {       
        require(sensoresActivos[sensorID] == true , "El sensor no esta activo.");

        //Registro de información de sensores a través de eventos en Blockchain
        emit NewSensorData(sensorID, contadorLogs[sensorID], valor);
        
        contadorLogs[sensorID]++;
    }

    function addSensor() public {
        totalSensores++;
        sensoresActivos[totalSensores] = true;
    }

    function removeSensor(uint256 sensorID) public {
        sensoresActivos[sensorID] = false;
    }

}