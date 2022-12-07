//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./UserToken.sol";

contract DoctorToken{
    address[] public patients;
    mapping (address => bool) isPatient;

    mapping (address => bool) requestPatient;
    address[] public requests;

    struct document{
        string ipfsLink;
        uint time;
        address doctor;
        address[] hasAccess;
        uint id;
    }
    address owner;

    constructor(address sender){
        owner = sender;
    }

    function createDocs(address patientContract, string memory record) public{
        UserToken patientData = UserToken(patientContract);

        if(isPatient[patientContract] != true){
            revert();
        }
        patientData.createRecord(address(this), record);
    }

    function addPatient(address patient) public{
        if(requestPatient[patient] != true){
            revert();
        }

        patients.push(patient);
        isPatient[patient] = true;
        requestPatient[patient] = false;

        uint index;
        for(uint i = 0; i < requests.length; i++){
            if(requests[i] == patient){
                index = i;
            }
        }

        delete requests[index];
        requests[index] = requests[requests.length - 1];
        requests.pop();
    }

    function requestDoctor(address patientHandler) external{
        if(requestPatient[patientHandler] == true){
            revert();
        }
        requestPatient[patientHandler] = true;
        requests.push(patientHandler);
    }

    function getDocumentss(address patientHandler) public view returns(UserToken.document[] memory){
        UserToken patient = UserToken(patientHandler);
        return patient.getRecords(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error UserRegistry_AccountExists();
error UserRegistry_NoAccount();

import "./DoctorToken.sol";
import "./UserToken.sol";

contract UserRegistry {
    mapping(address => bool) public accountCreated;
    mapping(address => string) private accountData;
    mapping(string => bool) private ppsExists;
    mapping(address => address) private managingContract;

    event createEvent(address indexed from, string message, bool indexed success);

    function createAccount(string memory msgArg, string memory pps, bool isDoctor) public {
        if(accountCreated[msg.sender] == true || ppsExists[pps] == true){
            revert UserRegistry_AccountExists();
        }

        emit createEvent(msg.sender, "created Account", true);
        accountCreated[msg.sender] = true;
        accountData[msg.sender] = msgArg;
        ppsExists[pps] = true;

        if(isDoctor != true){
            address contractAddress = address(new UserToken(msg.sender));
            managingContract[msg.sender] = contractAddress;
        } else{
            address contractAddress = address(new DoctorToken(msg.sender));
            managingContract[msg.sender] = contractAddress;
        }
    }

    function signIn() public view returns (string memory) {
        if (accountCreated[msg.sender] != true) {
            revert UserRegistry_NoAccount();
        }
        return accountData[msg.sender];
    }

    function changeDetails(string memory msgArgs) public {
        if (accountCreated[msg.sender] != true) {
            revert UserRegistry_NoAccount();
        }
        accountData[msg.sender] = msgArgs;
    }

    function getManagingAddress() public view returns(address){
        return managingContract[msg.sender];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./DoctorToken.sol";

contract UserToken {
    address public owner;

    mapping(address => bool) private doctors;
    mapping(uint => string) private keys;
    mapping(address => string) private doctorsToNickname;

    document[] public records;
    address[] private doctorList;

    struct document {
        string ipfsLink;
        uint time;
        address doctor;
        address[] hasAccess;
        uint id;
    }

    constructor(address sender) {
        owner = sender;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function createRecord(
        address doctorHandler,
        string memory ipfsLink
    ) public {
        if (doctors[doctorHandler] != true) {
            revert();
        }
        document memory record = document(
            ipfsLink,
            block.timestamp,
            doctorHandler,
            new address[](0),
            records.length
        );
        records.push(record);
        records[records.length - 1].hasAccess.push(doctorHandler);
        records[records.length - 1].hasAccess.push(owner);
    }

    function addDoctor(address doctor, string memory nickName) public {
        if (msg.sender != owner) {
            revert();
        }

        if (doctors[doctor] == true) {
            revert();
        } else {
            DoctorToken doctorHandler = DoctorToken(doctor);
            doctorHandler.requestDoctor(address(this));
            doctors[doctor] = true;
            doctorList.push(doctor);
            doctorsToNickname[doctor] = nickName;
        }
    }

    function hasAccess(uint index) public view returns (address[] memory) {
        return records[index].hasAccess;
    }

    function getRecords(
        address doctorHandler
    ) public view returns (document[] memory) {
        document[] memory data = new document[](0);

        for (uint i = 0; i < records.length; i++) {
            address[] memory doctorsInArray = records[i].hasAccess;

            for (uint v = 0; v < doctorsInArray.length; v++) {
                if (doctorsInArray[v] == doctorHandler) {
                    uint length = data.length;
                    uint newLength = length + 1;

                    document[] memory oldData = data;
                    data = new document[](newLength);

                    for (uint z = 0; z < oldData.length; z++) {
                        data[z] = oldData[z];
                    }
                    data[length] = records[i];
                }
            }
        }

        return data;
    }

    function addToRecord(address toAdd, uint256 id) public {
        if (msg.sender != owner) {
            revert();
        }

        records[id].hasAccess.push(toAdd);
    }

    function getDoctors() public view returns(address[] memory){
        return doctorList;
    }

    function getNickName(address doctorAddress) public view returns(string memory){
        if(msg.sender != owner){
            revert();
        } else{
            return doctorsToNickname[doctorAddress];
        }
    }
}