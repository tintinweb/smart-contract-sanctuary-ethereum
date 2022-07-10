/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

pragma solidity ^0.8.0;

contract documentVerification {
    
    struct Document{
        address[8] admins;
        address[32] allowedVoters;
        bool[32] votes;
    }
    Document[] documents;
    uint numberOfDocuments = 1;
    mapping(uint256 => uint256) index;


    function upload(uint256 _document_hash, address[32] memory _allowedVoters) public {
        if(index[_document_hash] != 0){
            return;
        }

        index[_document_hash] = numberOfDocuments;
        Document memory newDoc;
        newDoc.allowedVoters = _allowedVoters;

        //add own address as admin
        newDoc.admins[0] = msg.sender;

        //restriction could be lifted by using a loop
        documents.push(newDoc);
        numberOfDocuments++;

        emit Upload(msg.sender, _document_hash, index[_document_hash]);
    }
    
    //every admin can add and remove admins
    //this means you have to TRUST other admins
    function changeAdmins(uint256 _document_hash, address[8] memory _adminAddresses) public {
        if(index[_document_hash] == 0){
            return;
        }
        for(uint i = 0; i<8; i++){
            if(documents[index[_document_hash]].admins[i] == msg.sender){
                documents[index[_document_hash]].admins = _adminAddresses;
                emit ChangeAdmins(msg.sender, _document_hash, _adminAddresses);
                return;
            }
        }
    }

    function changeAllowedVoters(uint256 _document_hash, address[32] memory _voterAddresses) public {
        if(index[_document_hash] == 0){
            return;
        }
        for(uint i = 0; i<8; i++){
            if(documents[index[_document_hash]].admins[i] == msg.sender){
                delete documents[index[_document_hash]].votes;
                documents[index[_document_hash]].allowedVoters = _voterAddresses;
                emit ChangeVoters(msg.sender, _document_hash, _voterAddresses);
                return;
            }
        }
    }

    function vote(uint256 _document_hash, bool _doIAgree) public {
        if(index[_document_hash] == 0){
            return;
        }
        for(uint i = 0; i<32; i++){
            if(documents[index[_document_hash]].allowedVoters[i] == msg.sender){
                documents[index[_document_hash]].votes[i] = _doIAgree;
            }
        }
        emit Voting(msg.sender, _document_hash, _doIAgree);
    }

    event Voting(address indexed _from, uint256 _document_hash, bool _doIAgree);
    event Upload(address indexed _from, uint256 _document_hash, uint256 index);
    event ChangeAdmins(address indexed _from, uint256 _document_hash, address[8] _adminAddresses);
    event ChangeVoters(address indexed _from, uint256 _document_hash, address[32] _voterAddresses);
}