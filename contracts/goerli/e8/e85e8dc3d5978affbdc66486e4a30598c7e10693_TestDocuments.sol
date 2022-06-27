/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

pragma solidity 0.8.15;
// SPDX-License-Identifier: UNLICENSED
contract TestDocuments
{

    struct Doc {
        string title; 
        string description; 
    }

    struct Change {
        string docId; 
        string oldTitle;
        string oldDescription;
        string newTitle;
        string newDescription;
    }

    uint changesMade = 0;

    // List of documents
    mapping(string => Doc) public documents;
    mapping(uint256 => Change) public changes;

    function AddDocument(string memory id, string memory title, string memory description) public
    {
        Doc storage newDoc = documents[id];
        newDoc.title = title;
        newDoc.description = description;
    }

    function RequestDocument(string memory id) public view returns (Doc memory document_){
        return documents[id];
    }

    function EditDocument(string memory id, string memory title, string memory description) public{
        string memory oldTitle = documents[id].title;
        string memory oldDesc = documents[id].description;

        documents[id].title = title;
        documents[id].description = description;

        Change storage newChange = changes[changesMade];
        newChange.docId = id;
        newChange.oldTitle = oldTitle;
        newChange.oldDescription = oldDesc;
        newChange.newTitle = title;
        newChange.newDescription = description;
        changesMade++;
    }

}