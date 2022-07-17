/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract patientRegistration{
	
	mapping(bytes32 => bool) patientRegistrationStatus;
	event PatientRegistrationSucessful(bytes32 indexed _patientId);
	event PatientUnRegistrationSucessful(bytes32 indexed _patientId);

	function setPatientRegistration(bytes32 _patientId) public{							//this function will register the patient
		require(!patientRegistrationStatus[_patientId],"patient already registered");
		patientRegistrationStatus[_patientId] = true;
		emit PatientRegistrationSucessful(_patientId);
	}
	
    function RemovePatientRegistration(bytes32 _patientId) public{						//this function will remove the registration of the patient
		require(patientRegistrationStatus[_patientId],"patient not registered");
		delete patientRegistrationStatus[_patientId];
		emit PatientUnRegistrationSucessful(_patientId);
	}

	function patientRegistrationStatusCheck(bytes32 _patientId) public view returns(bool){			// this function is used to find whether a patient is registered or not
		return patientRegistrationStatus[_patientId];
	}

	function encryptPatientId(address _patientId) public pure returns(bytes32){						//this function is used to encrypt the patientId
		return keccak256(abi.encodePacked(_patientId));
	}
	
}