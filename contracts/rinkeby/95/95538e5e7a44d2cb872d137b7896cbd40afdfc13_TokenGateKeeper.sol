// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import {IGateKeeper} from "./IGateKeeper.sol";

/**
 * @notice Compatible with both ER20s and ERC721s.
 */
interface Token {
    function balanceOf(address owner) external view returns (uint256);
}

/**
 * @notice a contract that implements an token gatekeeper
 */
contract TokenGateKeeper is IGateKeeper {
    // last gate id
    uint96 private _lastId;

    struct TokenGate {
        Token token;
        uint256 minimumBalance;
    }

    event TokenGateCreated(Token token, uint256 minimumBalance);

    /// @notice Get the information for a gate identifyied by it's `id`.
    mapping(uint96 => TokenGate) public gateInfo;

    /// @inheritdoc IGateKeeper
    function isAllowed(
        address participant,
        bytes12 id,
        bytes memory /* userData */
    ) external view returns (bool) {
        TokenGate memory _gate = gateInfo[uint96(id)];
        return _gate.token.balanceOf(participant) >= _gate.minimumBalance;
    }

    /// @notice Creates a gate that requires a minimum balance of a token.
    /// @param  token The token address (eg. ERC20 or ERC721).
    /// @param  minimumBalance The minimum balance allowed for participation.
    /// @return id The ID of the new gate.
    function createGate(Token token, uint256 minimumBalance)
        external
        returns (bytes12 id)
    {
        uint96 id_ = ++_lastId;
        id = bytes12(id_);
        gateInfo[id_].token = token;
        gateInfo[id_].minimumBalance = minimumBalance;
        emit TokenGateCreated(token, minimumBalance);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

// Interface for a gatekeeper contract used for private crowdfund instances.
interface IGateKeeper {
    /// @notice Check if a participant is eligible to participate in a crowdfund.
    /// @param participant The address of the participant.
    /// @param id The ID of the gate to eligibility against.
    /// @param userData The data used to check eligibility.
    /// @return `true` if the participant is allowed to participate, `false` otherwise.
    function isAllowed(
        address participant,
        bytes12 id,
        bytes memory userData
    ) external view returns (bool);
}