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

    // List of documents
    mapping(string => Doc) public documents;


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
        documents[id].title = title;
        documents[id].description = description;
    }
}