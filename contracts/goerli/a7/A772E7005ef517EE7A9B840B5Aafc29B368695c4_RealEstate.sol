// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract RealEstate {
    address public admin;
    address public preparation;
    address public dueDiligence;
    address public realEstateNFT;
    address public completion;

    address public owner;
    address public broker;
    address public externalAdvisor;
    address public prospectiveBuyer;

    bool private sold = false;

    struct RequestToSeeRealEstateData {
        string data1;
        string data2;
        string data3;
    }
    address[] public requestToSeeRealEstateList;
    mapping(address => bool) public requestToSeeRealEstate;
    mapping(address => RequestToSeeRealEstateData)
        private requestToSeeRealEstateData;

    constructor(address _admin) {
        owner = msg.sender;
        admin = _admin;
    }

    function setPreparationContract(address _contract) public {
        require(msg.sender == owner, "not broker");
        preparation = _contract;
    }

    function setDueDiligenceContract(address _contract) public {
        require(msg.sender == broker, "not broker");
        dueDiligence = _contract;
    }

    function setRealEstateNFTContract(address _contract) public {
        require(msg.sender == externalAdvisor, "not external advisor");
        realEstateNFT = _contract;
    }

    function setCompletionContract(address _contract) public {
        require(msg.sender == broker, "not broker");
        completion = _contract;
    }

    function setBroker(address _broker) public {
        require(msg.sender == preparation, "not preparation");
        broker = _broker;
    }

    function setExternalAdvisor(address _contract) public {
        require(msg.sender == broker, "not broker");
        externalAdvisor = _contract;
    }

    function isAuthorizedUser(
        address _user
    ) public view returns (bool authorizedUser) {
        authorizedUser =
            _user == owner ||
            _user == broker ||
            _user == admin ||
            _user == externalAdvisor ||
            _user == address(this);
    }

    function permissionToSeeTheRealEstate(
        address _user
    ) public view returns (bool authorizedUser) {
        authorizedUser = requestToSeeRealEstate[_user] == true;
    }

    function makeRequestToSeeTheCredentialRealEstate(
        string memory data1,
        string memory data2,
        string memory data3
    ) public {
        require(!sold, "has already sold");
        requestToSeeRealEstate[msg.sender] = false;
        requestToSeeRealEstateList.push(msg.sender);
        requestToSeeRealEstateData[msg.sender] = RequestToSeeRealEstateData(
            data1,
            data2,
            data3
        );
    }

    function givePermissionToSeeTheRealEstate(
        address _prospectiveBuyer
    ) public {
        require(msg.sender == broker, "not broker");
        requestToSeeRealEstate[_prospectiveBuyer] = true;
    }

    function getRequestToSeeRealEstateList()
        public
        view
        returns (address[] memory)
    {
        return requestToSeeRealEstateList;
    }

    function setProspectiveBuyer(address _prospectiveBuyer) public {
        require(msg.sender == completion);
        prospectiveBuyer = _prospectiveBuyer;
    }
}