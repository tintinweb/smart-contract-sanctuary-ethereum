/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract SendIpfsHash {
    CompanyHash[] private arrCompanyHash;
    string[] private commentHistory;

    // Events
    event AddNewCompany(string _companyHash, string _companyName);
    event AddNewComment(string _companyHash, string _commentHash);
    event AddNewSubComment(string _ipfsHashChild, string _ipfsHashParent);
    event AddLatestCommentInfo(string _cidComment);

    struct CompanyHash {
        string companyHash;
        string name;
    }

    mapping(string => string[]) private arrComment;
    mapping(string => string[]) private arrRepComment;

    mapping(string => address) private arrCreaterCmtAddress;

    function addNewCompany(
        string memory _companyHash,
        string memory _companyName
    ) public payable {
        for (uint256 i = 0; i < arrCompanyHash.length; i++) {
            if (
                keccak256(abi.encodePacked((arrCompanyHash[i].name))) ==
                keccak256(abi.encodePacked((_companyName)))
            ) return;
        }
        arrCompanyHash.push(CompanyHash(_companyHash, _companyName));
        emit AddNewCompany(_companyHash, _companyName);
    }

    function addNewComment(
        string memory _companyHash,
        string memory _commentHash
    ) public payable {
        for (uint256 i = 0; i < arrCompanyHash.length; i++) {
            if (
                keccak256(abi.encodePacked((arrCompanyHash[i].companyHash))) ==
                keccak256(abi.encodePacked((_companyHash)))
            ) {
                arrComment[_companyHash].push(_commentHash);
                arrCreaterCmtAddress[_commentHash] = msg.sender;
                return;
            }
        }
        emit AddNewComment(_companyHash, _commentHash);
    }

    function addNewSubComment(
        string memory _ipfsHashChild,
        string memory _ipfsHashParent
    ) public payable {
        if (checkExistComment(_ipfsHashParent)) {
            arrRepComment[_ipfsHashParent].push(_ipfsHashChild);
            arrCreaterCmtAddress[_ipfsHashChild] = msg.sender;
        }
        emit AddNewSubComment(_ipfsHashChild, _ipfsHashParent);
    }

    function checkExistComment(string memory _hash) private returns (bool) {
        return arrCreaterCmtAddress[_hash] != address(0x0);
    }

    function addLatestCommentInfo(string memory _cidComment) public payable {
        commentHistory.push(_cidComment);
        emit AddLatestCommentInfo(_cidComment);
    }

    function getArrRepComment(string memory _ipfsHash)
        public
        view
        returns (string[] memory)
    {
        return arrRepComment[_ipfsHash];
    }

    function getArrCompany() public view returns (CompanyHash[] memory) {
        return arrCompanyHash;
    }

    function getCompanyHash(string memory _companyName)
        public
        view
        returns (string memory _name)
    {
        for (uint256 i = 0; i < arrCompanyHash.length; i++) {
            if (
                keccak256(abi.encodePacked((arrCompanyHash[i].name))) ==
                keccak256(abi.encodePacked((_companyName)))
            ) {
                return arrCompanyHash[i].companyHash;
            }
        }
    }

    function getArrComment(string memory _companyHash)
        public
        view
        returns (string[] memory)
    {
        return arrComment[_companyHash];
    }

    function getCommentHistory() public view returns (string[] memory) {
        return commentHistory;
    }
}