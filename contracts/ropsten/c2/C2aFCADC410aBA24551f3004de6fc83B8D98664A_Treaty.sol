/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Treaty{

    // ... ...
    // Treaty is an agreement contract that helps the participants.
    // Get your service and pay for it.
    // ... ...
    
    address public owner;
    address public Dapp;

    mapping(address => uint) public AcceptorsWallet;
    mapping(address => uint) public ServiceAgreement;
    mapping(address => bool) public AgreementStatus;

    mapping(address => bool) public CommitStatus;
    mapping(address => uint) public CommitValue;
    mapping(address => address) public pairs;

    constructor(address application){
        owner = msg.sender;
        Dapp = application;
    }

    /* Only Dapp */
    function setAgreementStatus(address receptionist, address acceptor, bool status) external{
        require(Dapp == msg.sender);
        AgreementStatus[receptionist] = status;
        if(status == false){
            require(pairs[receptionist] == acceptor, 'acceptor was not hire receptionist');
            AcceptorsWallet[acceptor] += CommitValue[receptionist];
            CommitValue[receptionist] = 0;
            CommitStatus[receptionist] = false;
            pairs[receptionist] = address(0);
        }
    }

    function showPair(address receptionist) external view returns(address){
        require(Dapp == msg.sender);
        return pairs[receptionist];
    }

    /* Only Acceptor */
    function deposit() external payable{
        require(msg.value > 0,'no value');
        AcceptorsWallet[msg.sender] += msg.value;
    }

    function withdraw() external {
        require(AcceptorsWallet[msg.sender] > 0, 'impossible transfer');
        bool flag = payable(msg.sender).send(AcceptorsWallet[msg.sender]);
        require(flag, "transaction failed");
        AcceptorsWallet[msg.sender] = 0;
    }

    function showAgreement(address receptionist) external view returns(uint){
        return ServiceAgreement[receptionist];
    }

    function commit(address receptionist) external{
        require(CommitStatus[receptionist] == false, 'Receptionist is bussy');
        uint servicevalue = ServiceAgreement[receptionist];
        AcceptorsWallet[msg.sender] -= servicevalue;
        CommitValue[receptionist] += servicevalue;
        CommitStatus[receptionist] = true;
        pairs[receptionist] = msg.sender;
    }


    /* Only Receptionist */
    function setServiceAgreement(uint agreementvalue) external{
        require(agreementvalue > 0, 'not a valid value');
        require(CommitStatus[msg.sender] == false, 'Acceptor already commit, withdraw it');
        ServiceAgreement[msg.sender] = agreementvalue;
    }

    function withdrawCommit() external{
        require(CommitStatus[msg.sender] == true, 'impossible withdraw');
        require(AgreementStatus[msg.sender] == true, 'you did not provide the service');
        require(CommitValue[msg.sender] > 0,'impossible transfer');

        uint value = CommitValue[msg.sender];  
        CommitValue[msg.sender] = 0;
        CommitStatus[msg.sender] = false;
        pairs[msg.sender] = address(0);

        bool flag = payable(msg.sender).send(value);
        require(flag, "transaction failed");
    }
}