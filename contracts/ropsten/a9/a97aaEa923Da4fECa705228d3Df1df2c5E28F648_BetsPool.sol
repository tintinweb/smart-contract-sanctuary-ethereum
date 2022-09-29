//SPDX-License-Identifier: MIT
pragma solidity >0.8.16;

import "./interfaces/IBetsPool.sol";

contract BetsPool is IBetsPool {
    uint256 public _betId;
    mapping(uint256 => mapping(string => PlayInBet[])) public activeBets;
    mapping(address => bool) admins;

    modifier onlyAdmins() {
        require(admins[msg.sender], "Sender not admin");
        _;
    }

    constructor() {
        admins[msg.sender] = true;
    }

    function allActiveBets(uint256 _sportId, string memory _event)
        external
        view
        override
        returns (PlayInBet[] memory)
    {
        return activeBets[_sportId][_event];
    }

    function addBet(
        uint8 _sportId,
        address _better,
        string memory _event,
        string memory _betSlug,
        uint256 _betAmount
    ) external override onlyAdmins {
        activeBets[_sportId][_event].push(
            PlayInBet({
                betId: _betId,
                betSlug: _betSlug,
                betAmount: _betAmount,
                better: _better,
                betStatus: status.unresolved
            })
        );
        emit BetCreated(_betId, _sportId, _betSlug);
        _betId++;
    }

    function updateBet(
        uint8 _sportId,
        uint256 betIndex,
        status _status,
        string memory _event
    ) external override onlyAdmins {
        activeBets[_sportId][_event][betIndex].betStatus = _status;
    }

    function addAdmin(address admin) external onlyAdmins {
        admins[admin] = true;
    }

    function removeAdmin(address admin) external onlyAdmins {
        admins[admin] = false;
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