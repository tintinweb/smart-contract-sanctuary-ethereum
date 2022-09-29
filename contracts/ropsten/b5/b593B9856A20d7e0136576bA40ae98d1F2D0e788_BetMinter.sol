//SPDX-License-Identifier: MIT
pragma solidity >0.8.16;
import "./interfaces/IBetsPool.sol";

contract BetMinter {
    IBetsPool _betsPool;

    constructor(IBetsPool betsPool) {
        _betsPool = betsPool;
    }

    function Bet(
        uint8 _sportId,
        string memory _event,
        string memory _betSlug
    ) external payable {
        require(msg.value > 0, "Bet amount too low");
        _betsPool.addBet(_sportId, msg.sender, _event, _betSlug, msg.value);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >0.8.16;

interface IBetsPool {
    enum status {
        unresolved,
        lost,
        won,
        claimed
    }

    struct PlayInBet {
        uint256 betId;
        string betSlug;
        uint256 betAmount;
        address better;
        status betStatus;
    }

    event BetCreated(
        uint256 indexed _betId,
        uint8 indexed sportId,
        string indexed bestslug
    );

    function allActiveBets(uint256, string memory)
        external
        view
        returns (PlayInBet[] memory);

    function addBet(
        uint8 _sportId,
        address _better,
        string memory _event,
        string memory _betSlug,
        uint256 _betAmount
    ) external;

    function updateBet(
        uint8 _sportId,
        uint256 betIndex,
        status _status,
        string memory _betSlug
    ) external;
}