/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface iDeviceRegistration{
	function deviceRegistrationStatusCheck(bytes32 _deviceId) external view returns(bool);
}

interface iPatientRegistration{
	function patientRegistrationStatusCheck(bytes32 _patientId) external view returns(bool);
}

contract patientDeviceDataEncryption{

	struct patientData{
		bytes32 deviceId;					//encrypted device ID from which data is coming
		bytes32 keccak256KeyHash;			// key required to decrypt the uri
		string uri;							//encrypted uri
	}
	
	address public deviceRegistrationContractAddress;           //device Registration Contract address
	address public patientRegistrationContractAddress;          //patient Registration Contract address
	mapping(bytes32=>bool)public deviceEngagedStatus;           
	mapping(bytes32=>mapping(bytes32=>bool)) patientDeviceStatus;
	mapping(bytes32 => mapping(string => patientData[])) public uploadToIPFS1;
	mapping(bytes32 => mapping(string => patientData[])) public uploadToIPFS2;
		
	event PatientDeviceRegistrationSucessful(bytes32 indexed _patientId, bytes32 indexed _deviceId);
	event PatientDeviceRemovalSucessful(bytes32 indexed _patientId, bytes32 indexed _deviceId);
	
	constructor(address _deviceRegistrationContractAddress, address _patientRegistrationContractAddress){
		deviceRegistrationContractAddress = _deviceRegistrationContractAddress;
		patientRegistrationContractAddress = _patientRegistrationContractAddress;
	}
	
	function setPatientDeviceRegistration(bytes32 _patientId,bytes32 _deviceId) public {                    //to assign a registered device to a registered patient
		require(iPatientRegistration(patientRegistrationContractAddress).patientRegistrationStatusCheck(_patientId),"patient doesn't exist");
		require(iDeviceRegistration(deviceRegistrationContractAddress).deviceRegistrationStatusCheck(_deviceId),"device doesn't exist");
		require(!patientDeviceStatus[_patientId][_deviceId],"device patient already registered");	
		require(!deviceEngagedStatus[_deviceId],"Device is already assign to other Patient");
		patientDeviceStatus[_patientId][_deviceId] = true; 
		deviceEngagedStatus[_deviceId] = true;		
		emit PatientDeviceRegistrationSucessful(_patientId,_deviceId);
	}
	
	function RemovePatientDeviceRegistration(bytes32 _patientId,bytes32 _deviceId) public {             //to remove a device from the patient
		require(patientDeviceStatus[_patientId][_deviceId],"device is not given to you");
		delete patientDeviceStatus[_patientId][_deviceId];
		delete deviceEngagedStatus[_deviceId];
		emit PatientDeviceRemovalSucessful(_patientId,_deviceId);
	}
	
	function patientDeviceRegistrationStatusCheck(bytes32 _patientId, bytes32 _deviceId) public view returns(bool){         //to check patient device status
		return patientDeviceStatus[_patientId][_deviceId];
	}
	
	function uploadPatientDataToIPFS1(bytes32 _patientId,string memory _reportType,bytes32 _deviceId,bytes32[] memory _keccak256KeyHash,string[] memory _uri)public{        
        //to upload the encrypted first IPFS uri that have the patient data along with the encryption key
		uint256 noOfKeys;
		uint256 noOfUri;
		noOfKeys = _keccak256KeyHash.length;
		noOfUri = _uri.length;
		require(noOfKeys == noOfUri,"Keys and Uri are not of same length");
		require(patientDeviceStatus[_patientId][_deviceId],"device is not given to you");
		for(uint256 i; i<noOfKeys; i++){
		    uploadToIPFS1[_patientId][_reportType].push(patientData(_deviceId,_keccak256KeyHash[i],_uri[i]));		    
        }
    }

    function uploadPatientDataToIPFS2(bytes32 _patientId,string memory _reportType,bytes32 _deviceId,bytes32[] memory _keccak256KeyHash,string[] memory _uri)public{
		//to upload the encrypted second IPFS uri that have the patient data along with the encryption key
        uint256 noOfKeys;
		uint256 noOfUri;
		noOfKeys = _keccak256KeyHash.length;
		noOfUri = _uri.length;
		require(noOfKeys == noOfUri,"Keys and Uri are not of same length");
		require(patientDeviceStatus[_patientId][_deviceId],"device is not given to you");
		for(uint256 i; i<noOfKeys; i++){
		    uploadToIPFS2[_patientId][_reportType].push(patientData(_deviceId,_keccak256KeyHash[i],_uri[i]));		    
        }
    }
		
}