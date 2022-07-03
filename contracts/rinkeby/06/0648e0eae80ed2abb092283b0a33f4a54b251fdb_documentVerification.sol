/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

pragma solidity ^0.8.0;

contract documentVerification {
    
    struct Document{
        address[32] allowedVoters;
        bool[32] votes;
    }
    Document[] documents;
    uint numberOfDocuments = 1;
    mapping(uint256 => uint256) index;

    function addAllowedVoter(uint256 _document_hash, uint256 voterAddress) public {

    }

    function upload(uint256 _document_hash, bool _doIAgree, address[32] memory _allowedVoters) public {
        if(index[_document_hash] == 0){
            return;
        }
        if(_allowedVoters[0] != msg.sender){
            return;
        }

        index[_document_hash] = numberOfDocuments;
        Document memory newDoc;
        newDoc.allowedVoters = _allowedVoters;

        //restriction could be lifted by using a loop
        newDoc.votes[0] = _doIAgree;
        documents.push(newDoc);
        numberOfDocuments++;

        emit Upload(msg.sender, _document_hash, index[_document_hash]);
        emit Voting(msg.sender, _document_hash, _doIAgree);
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
}