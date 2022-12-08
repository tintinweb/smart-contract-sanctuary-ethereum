pragma solidity ^0.8.9;

import "../interfaces/IEpochs.sol";
import "../interfaces/IAllocationsStorage.sol";

/* SPDX-License-Identifier: UNLICENSED */

contract Allocations {
    event Voted(uint256 indexed epoch, address indexed user, uint8 proposalId, uint8 alpha);

    IEpochs public immutable epochs;
    IAllocationsStorage public immutable allocationsStorage;

    constructor(address _epochsAddress, address _allocationsStorageAddress) {
        epochs = IEpochs(_epochsAddress);
        allocationsStorage = IAllocationsStorage(_allocationsStorageAddress);
    }

    function vote(uint8 _proposalId, uint8 _alpha) external {
        require(_proposalId != 0, "HN/proposal-id-cannot-be-0");
        require(epochs.isStarted(), "HN/not-started-yet");
        require(epochs.isDecisionWindowOpen(), "HN/decision-window-closed");
        require(_alpha >= 0 && _alpha <= 100, "HN/alpha-out-of-range");
        uint256 epoch = epochs.getCurrentEpoch();

        IAllocationsStorage.Vote memory _vote = allocationsStorage.getUserVote(epoch, msg.sender);
        if (_vote.proposalId != 0) {
            allocationsStorage.removeVote(epoch, _vote.proposalId, msg.sender);
        }
        allocationsStorage.addVote(epoch, _proposalId, msg.sender, _alpha);

        emit Voted(epoch, msg.sender, _proposalId, _alpha);
    }
}

pragma solidity ^0.8.9;

/* SPDX-License-Identifier: UNLICENSED */

interface IAllocationsStorage {
    struct Vote {
        uint256 alpha;
        uint256 proposalId;
    }

    function getUserVote(uint256 _epoch, address _user) external view returns (Vote memory);

    function addVote(
        uint256 _epoch,
        uint256 _proposalId,
        address _user,
        uint256 _alpha
    ) external;

    function removeVote(
        uint256 _epoch,
        uint256 _proposalId,
        address _user
    ) external;

    function getUsersAlphas(uint256 _epoch, uint256 _proposalId)
        external
        view
        returns (address[] memory, uint256[] memory);

    function getVotesCount(uint256 _epoch, uint256 _proposalId) external view returns (uint256);

    function getUser(
        uint256 _epoch,
        uint256 _proposalId,
        uint256 _index
    ) external view returns (address);
}

pragma solidity ^0.8.9;

/* SPDX-License-Identifier: UNLICENSED */

interface IEpochs {
    function getCurrentEpoch() external view returns (uint256);

    function isStarted() external view returns (bool);

    function isDecisionWindowOpen() external view returns (bool);
}