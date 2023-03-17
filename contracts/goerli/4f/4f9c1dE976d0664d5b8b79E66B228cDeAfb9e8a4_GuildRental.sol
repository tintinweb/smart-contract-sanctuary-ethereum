// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//  ==========  INTERNAL IMPORTS    ==========

import {IGuildRental} from "../interfaces/IGuildRental.sol";

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

contract GuildRental is IGuildRental {
    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error OnlyGuildContract();

    /*///////////////////////////////////////////////////////////////
                               STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct GuildRentalSorage {
        uint256 rBase;
        uint256 uOpt;
        uint256 rSlope1;
        uint256 rSlope2;
    }

    /*///////////////////////////////////////////////////////////////
                               STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint256 public constant MAX_RATE = 100_000;

    address public immutable guildContract;

    GuildRentalSorage private s;

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyGuildContract() {
        if (msg.sender != guildContract) revert OnlyGuildContract();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address guild, uint256 rBase, uint256 uOpt, uint256 rSlope1, uint256 rSlope2) {
        guildContract = guild;
        s.rBase = rBase;
        s.uOpt = uOpt;
        s.rSlope1 = rSlope1;
        s.rSlope2 = rSlope2;
    }

    /*///////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    function getRBase() external view returns (uint256) {
        return s.rBase;
    }

    function getUOpt() external view returns (uint256) {
        return s.uOpt;
    }

    function getRSlope1() external view returns (uint256) {
        return s.rSlope1;
    }

    function getRSlope2() external view returns (uint256) {
        return s.rSlope2;
    }

    /// @notice Returns the actual utilization rate of the asset pool
    /// @param _totalDeposit Total number of assets deposited in the pool
    /// @param _totalRental Total number of rentals
    function getActualUtilizationRate(uint256 _totalDeposit, uint256 _totalRental) external pure returns (uint256) {
        return (_totalRental * MAX_RATE) / _totalDeposit;
    }

    /// @notice Returns the rental premium based on the actual utilaization rate
    /// @param _uActual _uActual utilization rate based on BASIS_POINT
    /// @return rPremium Rental premium based on BASIS_POINT
    function getRentalPremium(uint256 _uActual) external view returns (uint256 rPremium) {
        if (_uActual < s.uOpt) {
            rPremium = s.rBase + (_uActual * s.rSlope1) / s.uOpt;
        } else {
            rPremium = s.rBase + s.rSlope1 + ((_uActual - s.uOpt) * s.rSlope2) / (MAX_RATE - s.uOpt);
        }
    }

    /*///////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/

    function setRBase(uint256 rBase) external onlyGuildContract {
        s.rBase = rBase;
    }

    function setUOpt(uint256 uOpt) external onlyGuildContract {
        s.uOpt = uOpt;
    }

    function setRSlope1(uint256 rSlope1) external onlyGuildContract {
        s.rSlope1 = rSlope1;
    }

    function setRSlope2(uint256 rSlope2) external onlyGuildContract {
        s.rSlope2 = rSlope2;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IGuildRental {
    function getActualUtilizationRate(uint256 _totalDeposit, uint256 _totalRental) external pure returns (uint256);

    function getRentalPremium(uint256 _uActual) external view returns (uint256 rPremium);

    function setRBase(uint256 rBase) external;

    function setUOpt(uint256 uOpt) external;

    function setRSlope1(uint256 rSlope1) external;

    function setRSlope2(uint256 rSlope2) external;
}