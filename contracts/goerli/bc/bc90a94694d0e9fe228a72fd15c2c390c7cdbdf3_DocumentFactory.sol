/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// File: contracts/document-verify.sol

//SPDX-License-Identifier: None

pragma solidity ^0.8.13;

contract Document {
    address public owner;
    string public uri;
    string public docType;
    address public DocAddr;
    string  public docParams;

    function setType(string memory _docTypes ) public {
        if(keccak256(abi.encodePacked(_docTypes)) == keccak256(abi.encodePacked("resolutions"))){
            docType = _docTypes;
        }
        else if(keccak256(abi.encodePacked(_docTypes)) == keccak256(abi.encodePacked("contracts"))){
            docType = _docTypes;
        }
        else if(keccak256(abi.encodePacked(_docTypes)) == keccak256(abi.encodePacked("certificates"))){
            docType = _docTypes;
        }
        else if(keccak256(abi.encodePacked(_docTypes)) == keccak256(abi.encodePacked("affidavits"))){
            docType = _docTypes;
        }
        else {
            require(false ,"type is not correct");
            // docType = "";
        }
    }

    constructor(address _owner, string memory _uri, string memory _docTypes,string memory _docParams) payable {
        // setType(_docTypes);
        owner = _owner;
        uri = _uri;
        // docTypes = 
        docType = _docTypes;
        DocAddr = address(this);
        docParams = _docParams;
        
    }
}

contract DocumentFactory {

    Document[] public documents;

    // struct DocInfo {
    //     string types;
    // }

    // mapping (address => DocInfo) public docInfo;
    


    function create(address _owner, string memory _docType,string memory _uri, string  memory _docParams) public {
        if(keccak256(abi.encodePacked(_docType)) == keccak256(abi.encodePacked("resolutions"))){
            Document document = new Document(_owner, _docType,_uri, _docParams);
        // document.setType(_docType);
        documents.push(document);
        }
        else if(keccak256(abi.encodePacked(_docType)) == keccak256(abi.encodePacked("contracts"))){
            Document document = new Document(_owner, _docType,_uri, _docParams);
        // document.setType(_docType);
        documents.push(document);
        }
        else if(keccak256(abi.encodePacked(_docType)) == keccak256(abi.encodePacked("certificates"))){
            Document document = new Document(_owner, _docType,_uri, _docParams);
        // document.setType(_docType);
        documents.push(document);
        }
        else if(keccak256(abi.encodePacked(_docType)) == keccak256(abi.encodePacked("affidavits"))){
            Document document = new Document(_owner, _docType,_uri, _docParams);
        // document.setType(_docType);
        documents.push(document);
        }
        else {
            require(false ,"type is not correct");
        }
        
    }

    function createAndSendEther(address _owner, string memory _docType, string memory _uri, string  memory _docParams) public payable {
        Document document = (new Document){value: msg.value}(_owner, _docType, _uri, _docParams);
        documents.push(document);
    }

    function create2(
        address _owner,
        string memory _docType,
        string memory _uri,
        string  memory _docParams
    ) public {
        Document document = new Document(_owner, _docType,_uri, _docParams);
        documents.push(document);
    }

    function create2AndSendEther(
        address _owner,
        string memory _docType,
        string memory _uri,
        string memory _docParams
    ) public payable {
        Document document = new Document(_owner, _docType,_uri, _docParams);
        documents.push(document);
    }

    function getDocument(uint _index)
        public
        view
        returns (
            address owner,
            string memory docType,
            string memory uri,
            address DocAddr,
            uint balance,
            string memory docParams
        )
    {
        Document document = documents[_index];

        return (document.owner(), document.docType(),document.uri(), document.DocAddr(), address(document).balance, document.docParams());
    }
}