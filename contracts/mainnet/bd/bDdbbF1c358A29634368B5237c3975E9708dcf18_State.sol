// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//------------------------------------------------------------------------------
// geneticchain.io - NextGen Generative NFT Platform
//------------------------------------------------------------------------------
//    _______                   __   __        ______ __          __
//   |     __|-----.-----.-----|  |_|__|----. |      |  |--.---.-|__|-----.
//   |    |  |  -__|     |  -__|   _|  |  __| |   ---|     |  _  |  |     |
//   |_______|_____|__|__|_____|____|__|____| |______|__|__|___._|__|__|__|
//
//------------------------------------------------------------------------------
// Genetic Chain: library/State
//------------------------------------------------------------------------------
// Author: papaver (@tronicdreams)
//------------------------------------------------------------------------------

/**
 * @dev Handle contract state efficiently as possbile.
 */
library State {

    //-------------------------------------------------------------------------
    // struct
    //-------------------------------------------------------------------------

    struct Data {
        uint8     _live;
        uint8     _locked;
        uint16[4] _supply;
        uint16[4] _privatemax;
        uint16[4] _max;
        uint48    _unused;
    }

    //-------------------------------------------------------------------------
    // interface
    //-------------------------------------------------------------------------

    function initialize(Data storage data, uint16[4] memory pmax, uint16[4] memory max)
        internal
    {
        data._privatemax[0] = pmax[0];
        data._privatemax[1] = pmax[1];
        data._privatemax[2] = pmax[2];
        data._privatemax[3] = pmax[3];
        data._max[0]        = max[0];
        data._max[1]        = max[1];
        data._max[2]        = max[2];
        data._max[3]        = max[3];
    }

    //-------------------------------------------------------------------------

    function publicLive(Data storage data)
        public view returns (bool)
    {
        return data._live == 1;
    }

    //-------------------------------------------------------------------------

    function locked(Data storage data)
        public view returns (bool)
    {
        return data._locked == 1;
    }

    //-------------------------------------------------------------------------

    function enablePublicLive(Data storage data)
        public
    {
        data._live = 1;
    }

    //-------------------------------------------------------------------------

    function toggleLocked(Data storage data)
        public
    {
        data._locked = data._locked == 1 ? 0 : 1;
    }

    //-------------------------------------------------------------------------

    function getMax(Data storage data, uint256 index)
        internal
        view
        returns (uint256)
    {
        return data._live == 0 ? data._privatemax[index] : data._max[index];
    }

    //-------------------------------------------------------------------------

    function getSupply(Data storage data, uint256 index)
        internal
        view
        returns (uint256)
    {
        return data._supply[index];
    }

    //-------------------------------------------------------------------------

    function addSupply(Data storage data, uint256 index, uint256 count)
        internal
     {
        require(data._supply[index] + count <= getMax(data, index), "exceed supply");
        unchecked {
            data._supply[index] += uint16(count);
        }
    }

    //-------------------------------------------------------------------------

    function totalSupply(Data storage data)
        internal
        view
        returns (uint256 supply)
    {
        for (uint256 i = 0; i < data._supply.length; ++i) {
            supply += uint16(data._supply[i]);
        }
    }

}