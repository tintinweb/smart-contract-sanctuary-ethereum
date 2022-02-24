/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// File: contracts/BBA/mainframe.sol


pragma solidity 0.8.12;


contract ArkadeWhitelist {

    mapping(address => bool) public whitelist;
    mapping(address => uint8) public caseArrayPointer;
    address[] public casesWhiteList;
    uint8 public casesContractCount;
    address public owner;

    constructor(){
        owner = msg.sender;
        whitelist[msg.sender] = true;
        casesContractCount = 0;
    }
    modifier isWhitelisted() {
        require(whitelist[msg.sender] == true, "Not white listed");
        _;
    }

    function addCaseContract(address newContract) isWhitelisted external {
        require(whitelist[newContract] == false, "already added");
        casesWhiteList.push(newContract);
        whitelist[newContract] = true;
        caseArrayPointer[newContract] = casesContractCount;
        casesContractCount++;
    }

    function removeCaseContract(address newContract) isWhitelisted external {
        require(whitelist[newContract], "Isn't white listed");
        delete casesWhiteList[caseArrayPointer[newContract]];
        whitelist[newContract] = false;
        caseArrayPointer[newContract] = 0;
    }





}