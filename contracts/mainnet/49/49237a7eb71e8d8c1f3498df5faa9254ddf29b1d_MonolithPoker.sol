/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INftHolder {
    function poke(	
        address pool,	
        address[] memory tokens,	
        address bountyReceiver) external;
}

contract MonolithPoker { 
    INftHolder public immutable nftHolder = INftHolder(0x35f4979fD163F2bfd5ba294172cc3c9AD569f548);

    struct PokeData {
        address pool;
        address[] tokens;
    }

    function multiPoke(PokeData[] calldata _pokeData) external {
        for (uint i; i < _pokeData.length;) {
            nftHolder.poke(_pokeData[i].pool, _pokeData[i].tokens, msg.sender);
            unchecked { ++i; }
        }
    }
}