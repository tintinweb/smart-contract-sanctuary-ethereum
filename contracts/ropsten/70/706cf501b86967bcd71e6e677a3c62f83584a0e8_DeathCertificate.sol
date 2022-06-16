// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./EtherWill.sol";

contract DeathCertificate {
    struct Person {
        string NIN; // EGN in Bulgaria
        // more fields such as name, lastname, email can be added in the future
    }

    struct Document {
        Person announcer;
        Person dead;
        Person doctor;
    }

    address private admin;

    EtherWill private etherWillAddr;
    
    mapping(address => bool) private certifiedInstitustions;

    mapping(string => bool) private deadPeople;

    event Death(Document document);

    event Log(string func, address sender, uint value); //For logging money

    constructor(address payable _addr) {
        admin = msg.sender;
        etherWillAddr = EtherWill(_addr);
        etherWillAddr.setDeathSertificateAddr(address(this));
    }

    receive() external payable {
        emit Log("receive", msg.sender, msg.value);
    }

    modifier isAdmin() {
        require(msg.sender == admin, "Caller is not admin");
        _;
    }

    modifier isCertifiedInstitution() {
        require(certifiedInstitustions[msg.sender], "Caller is not certified institution");
        _;
    }

    function addCertifiedInstitution(address institution) public isAdmin {
        certifiedInstitustions[institution] = true;
    }

    // Acceopts death certificate and announce EtherWill SC
    function announceDeath( Document memory doc ) public isCertifiedInstitution {
        require(!deadPeople[doc.announcer.NIN] && !deadPeople[doc.dead.NIN], "Invalid document");
        deadPeople[doc.dead.NIN] = true;

        emit Death(doc);
        // call Wills smart contract to execute the wills of the dead person
        etherWillAddr.executeWills(doc.dead.NIN);
    }

    // UI version - since we did not find a way to send structs from web3
    function announceDeathUI(
        string memory announcerNIN,
        string memory deadNIN,
        string memory doctorNIN
    ) public isCertifiedInstitution {
        Person memory announcer = Person({NIN: announcerNIN});
        Person memory dead = Person({NIN: deadNIN });
        Person memory doctor = Person({NIN: doctorNIN});
    
        Document memory document = Document({ announcer: announcer, dead: dead, doctor: doctor });
        require(!deadPeople[document.announcer.NIN] && !deadPeople[document.dead.NIN], "Invalid document");
        deadPeople[document.dead.NIN] = true;

        emit Death(document);
        // call Wills smart contract to execute the wills of the dead person
        etherWillAddr.executeWills(document.dead.NIN);
    }
}