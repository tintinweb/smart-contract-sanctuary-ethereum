//pragma solidity ^0.8.9;
pragma solidity >=0.4.22 <0.9.0;

contract admin_contract {
    struct ContractInfo {
        uint id;
        string name;
        string contactAddress;
        bool isDeleted;
    }
    uint public totalContractNum;
    mapping(uint => ContractInfo) public contractInfos;
    mapping(address => bool) public contracts;
    address public admin;

    // ----- check etc -----
    modifier checkAdmin() {
        require (msg.sender == admin, "Error: only admin is allowed.");
        _;
    }

    function getIsAdmin(address addr) public view returns(bool) {
        return addr == admin;
    }

    function addContract (string memory name, string memory addressString) public {
        totalContractNum++;
        contractInfos[totalContractNum] = ContractInfo(totalContractNum, name, addressString, false);
    }

    function deleteContract (uint id) public {
        contractInfos[id].isDeleted = true;
    }

    function reopenContract (uint id) public {
        contractInfos[id].isDeleted = false;
    }

    function getAllContracts () public view returns (ContractInfo[] memory){
        ContractInfo[] memory allContracts = new ContractInfo[](totalContractNum);
        for (uint i = 0; i < totalContractNum; i++) {
            ContractInfo storage member = contractInfos[i];
            allContracts[i] = member;
        }
        return allContracts;
    }

}