// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './interface/ICommitment.sol';

contract Commitment is ICommitment {

    mapping(address => Commitment[]) userCommitments;
    
    /************************************************
     *  Getters
     ***********************************************/

    // commitment is so long
    // commitments => coms

    /// get user's commitment length
    function getComsLength(address _address) public view returns (uint256 length) {
        length = userCommitments[_address].length;
    }

    /// get user's all commitments
    function getAllComs(address _address) public view returns (Commitment[] memory commitments) {
        uint256 length = getComsLength(_address);
        for (uint256 i = 0; i < length; i++) {
            commitments[i] = userCommitments[_address][i];
        }
    }

    /// get target commitment
    function getTargetCom(address _address, uint256 _id) private view returns (Commitment memory commitment) {
        uint256 length = getComsLength(_address);
        Commitment[] memory commtiments = getAllComs(_address);
        uint256 targetIndex;
        for (uint256 i = 0; i < length; i++) {
            if (commtiments[i].id == _id) targetIndex = i;
        }
        commitment = userCommitments[_address][targetIndex];
    }

    /************************************************
     *  Add
     ***********************************************/

    /// add commitment
    function addCom(
        address _address,
        uint256 _id,
        bytes32 _data,
        uint256 _groupId,
        string calldata _userId,
        uint256 _createdAt
    ) external {
        userCommitments[_address].push(Commitment(_id, _userId, _groupId, _data, '', address(0), _createdAt));
    }

    /************************************************
     *  Update
     ***********************************************/

    /// update commitment
    function updateCom(
        string calldata _metadta,
        address _mintAddress,
        address _address,
        uint256 _id
    ) external view {
        Commitment memory commitment = getTargetCom(_address, _id);
        commitment.metadata = _metadta;
        commitment.mintAddress = _mintAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICommitment {
    /// type of commitment
    struct Commitment {
        uint256 id;
        string userId; /// userId: `User#${address}`必要なさそうだったら消す
        uint256 groupId;
        bytes32 data;
        string metadata;
        address mintAddress;
        uint256 createdAt; /// 必要なさそうだったら消す
    }
}