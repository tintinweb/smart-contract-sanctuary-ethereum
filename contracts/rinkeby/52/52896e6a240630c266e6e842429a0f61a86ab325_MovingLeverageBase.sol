/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity 0.6.12;

contract MovingLeverageBase {
    address public owner;

    struct MovingLeverage {
        uint256 origin;
    }

    mapping(uint256 => mapping(int128 => MovingLeverage))
        public movingLeverages; // pid =>(coin id => MovingLeverage)

    event SetOwner(address owner);
    event SetOriginMovingLeverage(
        uint256 pid,
        int128 curveCoinId,
        uint256 current,
        uint256 blockNumber
    );

    modifier onlyOwner() {
        require(owner == msg.sender, "MovingLeverageBase: caller is not the owner");
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;

        emit SetOwner(_owner);
    }

    constructor(address _owner) public {
        owner = _owner;
    }

    function setOriginMovingLeverage(
        uint256 _pid,
        int128 _curveCoinId,
        uint256 _origin
    ) public onlyOwner {
        MovingLeverage storage movingLeverage = movingLeverages[_pid][
            _curveCoinId
        ];

        movingLeverage.origin = _origin;

        emit SetOriginMovingLeverage(
            _pid,
            _curveCoinId,
            _origin,
            block.timestamp
        );
    }

    function setOriginMovingLeverageBatch(
        uint256 _total,
        uint256[] calldata _pids,
        int128[] calldata _curveCoinIds,
        uint256[] calldata _origins
    ) external {
        require(_total == _pids.length, "!_pids.length");
        require(_total == _curveCoinIds.length, "!_curveCoinIds.length");
        require(_total == _origins.length, "!_origins.length");

        for (uint256 i = 0; i < _total; i++) {
            setOriginMovingLeverage(_pids[i], _curveCoinIds[i], _origins[i]);
        }
    }

    function get(uint256 _pid, int128 _coinId)
        external
        view
        returns (uint256)
    {
        return movingLeverages[_pid][_coinId].origin;
    }
}