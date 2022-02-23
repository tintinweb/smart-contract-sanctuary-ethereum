/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Works1 {

    address private owner;

    struct Work {
        bool isPublic;
        address authorAdress;
        string authorEmail;
        bytes32 password;
        string metaUri;
        string title;
    }

    Work[] private works;

    mapping (string => uint256[]) titlesToWorkIndexes;

    struct Author {
        string email;
        mapping(string => string) worksLinks;
    }

    Author[] private authors;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    function addAuthor(string memory email) public onlyOwner {
        Author storage newAuthor = authors.push();
        newAuthor.email = email;
    }

    function _addWork(
        bool isPublic,
        address authorAdress,
        string memory authorEmail,
        bytes32 password,
        string memory metaUri,
        string memory title
    ) private {
        Work storage newWork = works.push();
        newWork.isPublic= isPublic;
        newWork.authorAdress = authorAdress;
        newWork.authorEmail = authorEmail;
        newWork.password = password;
        newWork.metaUri = metaUri;
        newWork.title = title;
        uint256[] storage indexes = titlesToWorkIndexes[title];
        indexes.push(works.length-1);
    }

    function addWorkByEmail(
        bool isPublic,
        string memory authorEmail,
        string memory password,
        string memory metaUri,
        string memory title
    ) public onlyOwner {
        require(bytes(authorEmail).length != 0, "Email is required");
        if(!isPublic) {
            require(bytes(password).length != 0, "Non public works with email must have a non empty password");
        }
        bytes32 hasdedPassword = keccak256(bytes(password));
        require(bytes(metaUri).length != 0, "Meta uri is required");
        _addWork(isPublic, address(0), authorEmail, hasdedPassword, metaUri, title);
    }

    function getWorkUri(
        string memory title,
        string memory authorEmail
    ) public view returns(string memory) {
        bytes32 bEmail = keccak256(bytes(authorEmail));
        string memory foundedUri = "";
        uint256[] storage worksWithThisTitleIndexes = titlesToWorkIndexes[title];
        for(uint256 i=0; i<worksWithThisTitleIndexes.length; i++) {
            Work storage currWork = works[worksWithThisTitleIndexes[i]];
            if(keccak256(bytes(currWork.authorEmail)) == bEmail) {
                require(currWork.isPublic, "Request work is not public");
                foundedUri = currWork.metaUri;
                break;
            }
        }
        return foundedUri;
    }

    function getWorkUris(string memory title) public view returns(string[] memory) {
        uint256[] storage worksIndexes = titlesToWorkIndexes[title];
        uint256 size = worksIndexes.length;
        uint256 publicUrisSize = 0;
        
        for(uint256 i=0; i < size; i++) {
            Work storage currWork = works[worksIndexes[i]];
            if(currWork.isPublic) {
                publicUrisSize++;
            }
        }

        string[] memory publicUris = new string[](publicUrisSize);
        uint256 index = 0;

        for(uint256 i=0; i < size; i++) {
            Work storage currWork = works[worksIndexes[i]];
            if(currWork.isPublic) {
                publicUris[index++] = currWork.metaUri;
            }
        }
        return publicUris;
    }

}