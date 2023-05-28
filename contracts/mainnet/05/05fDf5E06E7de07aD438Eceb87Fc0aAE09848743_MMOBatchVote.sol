// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC721Receiver} from "./IERC721Receiver.sol";
import {IMoneyMakingOpportunity} from "./IMoneyMakingOpportunity.sol";

contract MMOBatchVote is IERC721Receiver {
    IMoneyMakingOpportunity public immutable MMO;

    constructor(address _mmo) {
        MMO = IMoneyMakingOpportunity(_mmo);
    }

    error NotMMOToken();

    function onERC721Received(address, address from, uint256 tokenId, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        if (msg.sender != address(MMO)) {
            revert NotMMOToken();
        }

        uint256[] memory votes = abi.decode(data, (uint256[]));
        for (uint256 i = 0; i < votes.length;) {
            MMO.castVote(tokenId, votes[i], true);

            unchecked {
                ++i;
            }
        }

        MMO.transferFrom(address(this), from, tokenId);

        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMoneyMakingOpportunity {
    function unlock(address _uriContract) external;
    function claim() external;
    function castVote(uint256 tokenId, uint256 week, bool vote) external;
    function proposeSettlementAddress(uint256 week, address settlementAddress) external;
    function settlePayment() external;
    function calculateVotes(uint256 week) external view returns (uint256, uint256);
    function tokenIdToWeek(uint256 tokenId) external view returns (uint256);
    function weekToTokenId(uint256 week) external view returns (uint256);
    function currentWeek() external view returns (uint256);
    function isEliminated(uint256 tokenId) external view returns (bool);
    function setTokenURIContract(address _uriContract) external;
    function updateTokenURI(uint256 tokenId) external;
    function batchUpdateTokenURI(uint256 from, uint256 to) external;
    function lockURI() external;
    function transferFrom(address from, address to, uint256 tokenId) external;
}