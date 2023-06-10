// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Notarization registry made for Moneyviz srl
 * @notice Use this contract to notarify information
 * @author Alessandro Morandi <[email protected]>
 */
contract MoneyvizNotarify {

    struct NotarizationDoc {
        address sender;
        uint256 timestamp;
        string  reasonid;
        string  linkOrIpfs;
        string  hash;
        string  tag;
        string  docType;
    }

    NotarizationDoc[] internal docHistory;
    mapping(address => uint256[]) internal senderDocs;

    event CreatedNewNotarizationDocEvent(
        address indexed sender,
        uint256 timestamp,
        string  indexed reasonid,
        string  linkOrIpfs,
        string  hash,
        string  indexed tag,
        string  docType
    );

    function createNotarizationDoc(
        string memory _reasonid,
        string memory _linkOrIpfs,
        string memory _hash,
        string memory _tag
    ) public {

        uint256 index = docHistory.length;
        string memory _docType = '';
        docHistory.push(NotarizationDoc(
            msg.sender,
            block.timestamp,
            _reasonid,
            _linkOrIpfs,
            _hash,
            _tag,
            _docType
        ));
        senderDocs[msg.sender].push(index);
        emit CreatedNewNotarizationDocEvent(
            msg.sender,
            block.timestamp,
            _reasonid,
            _linkOrIpfs,
            _hash,
            _tag,
            _docType
        );
    }

    function getlenghtOfDocArray() public view returns (uint256) {
        return docHistory.length;
    }

    function simpleNotarify(
        string memory _reasonid,
        string memory _linkOrIpfs,
        string memory _hash,
        string memory _tag
    ) public {
        string memory _docType = "ONLYEVENT";
        emit CreatedNewNotarizationDocEvent(
            msg.sender,
            block.timestamp,
            _reasonid,
            _linkOrIpfs,
            _hash,
            _tag,
            _docType
        );
    }

    function getDocsIds() public view returns (uint256[] memory) {
        return senderDocs[msg.sender];
    }

    function getDocsIdsByAddress(address _sender) public view returns (uint256[] memory) {
        return senderDocs[_sender];
    }

    function getDocByAddress(uint256 _index) public view returns (NotarizationDoc memory) {
        require(_index < docHistory.length, "Index is not valid. must be < max doc history array lenght");
        NotarizationDoc memory doc = docHistory[_index];
        return doc;
    }
}