/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract deviceRegistration{
	
	mapping(bytes32 => bool) deviceRegistrationStatus;
	event DeviceRegistrationSucessful(bytes32 indexed _deviceId);
	event DeviceUnRegistrationSucessful(bytes32 indexed _deviceId);
	
	function setDeviceRegistration(bytes32 _deviceId) public{							//this function will register the device
		require(!deviceRegistrationStatus[_deviceId],"device already registered");
		deviceRegistrationStatus[_deviceId] = true;
		emit DeviceRegistrationSucessful(_deviceId);
	}

	function RemoveDeviceRegistration(bytes32 _deviceId) public{						//this function will remove the registration of the device
		require(deviceRegistrationStatus[_deviceId],"device not registered");
		delete deviceRegistrationStatus[_deviceId];
		emit DeviceUnRegistrationSucessful(_deviceId);
	}
	
	function deviceRegistrationStatusCheck(bytes32 _deviceId) public view returns(bool){		// this function is used to find whether a device is registered or not
		return deviceRegistrationStatus[_deviceId];
	}

	function encryptDeviceId(address _deviceId) public pure returns(bytes32){					//this function is used to encrypt the deviceId
		return keccak256(abi.encodePacked(_deviceId));
	}
}