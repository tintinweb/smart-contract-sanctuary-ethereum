/**
 *Submitted for verification at Etherscan.io on 2023-01-11
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.7;

interface d2OLike {
    function burn(address,uint256) external;
    function mint(address,uint256) external;
}

interface LMCVLike {
    function moveD2O(address src, address dst, uint256 rad) external;
    function d2O(address user) external returns (uint256);
}

contract d2OJoin {

    //
    // --- Interfaces and data ---
    //

    LMCVLike    public immutable    lmcv;
    d2OLike     public immutable    d2O;
    uint256     constant            RAY = 10 ** 27;
    address                         lmcvProxy;

    //
    // --- Events ---
    //

    event Join(address indexed usr, uint256 wad);
    event Exit(address indexed usr, uint256 wad);

    //
    // --- Modifiers ---
    //

    modifier auth {
        require(msg.sender == lmcvProxy, "d2OJoin/not-authorized");
        _;
    }

    //
    // --- Init ---
    //

    constructor(address _lmcv, address _d2O, address _lmcvProxy) {
        require(_lmcv != address(0x0)
            && _d2O != address(0x0)
            && _lmcvProxy != address(0x0),
            "d2OJoin/Can't be zero address"
        );
        lmcv = LMCVLike(_lmcv);
        d2O = d2OLike(_d2O);
        lmcvProxy = _lmcvProxy;
    }

    //
    // --- User's functions ---
    //

    function join(address usr, uint256 wad) external {
        lmcv.moveD2O(address(this), usr, RAY * wad);
        d2O.burn(msg.sender, wad);
        emit Join(usr, wad);
    }

    function exit(address usr, uint256 wad) external {
        lmcv.moveD2O(msg.sender, address(this), RAY * wad);
        d2O.mint(usr, wad);
        emit Exit(usr, wad);
    }

    function proxyExit(address usr, uint256 wad) external auth {
        lmcv.moveD2O(usr, address(this), RAY * wad);
        d2O.mint(usr, wad);
        emit Exit(usr, wad);
    }
}