// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Ownable } from "./utils/Ownable.sol";
import { GenericErrorsAndEvents } from "./utils/GenericErrorsAndEvents.sol";
import { LeagueLedgerStructs } from "./structs/LeagueLedgerStructs.sol";
import { IERC721TManager } from "./interfaces/IERC721TManager.sol";

contract CatanLeagueLedger is Ownable, LeagueLedgerStructs, GenericErrorsAndEvents {

    address public leagueERC721Trophy;
    address public leagueFactory;
    string public leagueNickName;
    uint256 public matchCount;
    mapping(address => bool) public leagueMembers;
    mapping(address => uint256) public leagueMemberWins;
    mapping(bytes => ProposedMatchResult) public stagedMatchResults;
    bool initialized;

    event MatchResult(uint256[] victoryPoints, address[] leagueParticipants);

    constructor() {
        leagueMembers[msg.sender] = true;
    }

    modifier onlyLeagueMember {
        if (!leagueMembers[msg.sender]) {
            revert("Only league members can call this function.");
        }
        _;
    }

    function initializeLedger(
        address leagueFactory_,
        string calldata leagueNickName_
    ) external {
        if (initialized) {
            revert AlreadyInitialized();
        }
        leagueFactory = leagueFactory_;
        leagueNickName = leagueNickName_;
        initialized = true;
    }

    function addLeagueMember(address newMember) external onlyLeagueMember {
        leagueMembers[newMember] = true;
    }

    function deleteLeagueMember(address member) external onlyOwner {
        delete leagueMembers[member];
    }

    function changeLeagueERC721Trophy(address newLeagueERC721Trophy) external onlyOwner {
        leagueERC721Trophy = newLeagueERC721Trophy;
        matchCount = 0;
    }

    function proposeMatchResult(uint256[] memory victoryPoints, address[] memory leagueParticipants) external onlyLeagueMember {
        if (victoryPoints.length != leagueParticipants.length) {
            revert("number of reported victory points must be equal to reported participants");
        }
        bytes memory data = encodeTransactionData(victoryPoints, leagueParticipants);
        stagedMatchResults[data] = ProposedMatchResult(msg.sender, 0);
    }

    function confirmMatchResult(uint256[] memory victoryPoints, address[] memory leagueParticipants) external onlyLeagueMember {
        if (victoryPoints.length != leagueParticipants.length) {
            revert("number of reported victory points must be equal to reported participants");
        }
        bytes memory data = encodeTransactionData(victoryPoints, leagueParticipants);
        if (stagedMatchResults[data].originalProposer == msg.sender){
            revert("you proposed this match therefore you cannot confirm it");
        }
        commitMatchResult(victoryPoints, leagueParticipants);
        delete stagedMatchResults[data];
    }

    function commitMatchResult(uint256[] memory victoryPoints, address[] memory leagueParticipants) internal {
        address winner = leagueParticipants[0];
        uint256 winningPoints = victoryPoints[0];
        for (uint i=1; i<victoryPoints.length; ++i) {
            if (victoryPoints[i] > winningPoints) {
                winner = leagueParticipants[i];
                winningPoints = victoryPoints[i];
            }
        }
        leagueMemberWins[winner]++;
        matchCount++;
        IERC721TManager(leagueERC721Trophy).mint(winner, matchCount);
        emit MatchResult(victoryPoints, leagueParticipants);
    }

    function encodeTransactionData(
        uint256[] memory victoryPoints,
        address[] memory leagueParticipants
    ) internal view returns (bytes memory) {
        bytes32 safeTxHash =
            keccak256(
                abi.encode(
                    victoryPoints,
                    leagueParticipants,
                    matchCount
                )
            );
        return abi.encodePacked(safeTxHash);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC721TManager {
    function mint(address winner, uint256 tokenId) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function initalizeERC721T(
        string calldata name_,
        string calldata symbol_,
        address leagueLedger_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract LeagueLedgerStructs {
    struct ProposedMatchResult {
        address originalProposer;
        uint256 approverCount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract GenericErrorsAndEvents {
    error AlreadyInitialized();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert("Only the owner can call this function.");
        }
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}