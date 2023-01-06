/// SPDX-License-Identifier: UNLICENSED
// @title Stakeable Endowment Token
// @author Origin Address
// @notice This contract is proprietary and may not be copied or used without permission.

pragma solidity ^0.8.13;

import "./StakableEndowmentToken.sol";

contract TEXAN is StakableEndowmentToken {

    constructor() {
        setNameAndSymbol("TEXAN Token", "TEXAN");

        // NOTE: This has been modified so the original Owner Address does NOT hold
        // the supply. The Endowment Supply holds 97T stars for available rewards  
        // and is no longer held by the OA account.  We think this is good for security purposes.
        //
        //  These 3T tokens are for initial circulation.  (most will be staked)
        uint intitialTotalSupply = 3 * 1e30; // 3 Trillion Tokens ( 1e12 * decimals(1e18)) 

        _mint(msg.sender, intitialTotalSupply);
    }

    receive()
    payable
    external
    {
        uint256 fbfail = 1;
        require(fbfail == 0, string(abi.encodePacked(name(), ": You can not send ETH to this contract!")));
    }

    fallback() external {}
}