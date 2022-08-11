/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface GuildController {
    function get_guild_weight(address addr) external view returns (uint256);
    function guild_relative_weight(address addr) external view returns (uint256);
    function guild_effective_weight(address addr) external view returns (uint256);
    function guilds(uint index) external view returns (address);
}


interface Guild {
    function last_change_rate() external view returns (uint256);
    function commission_rate(uint timestamp) external view returns (uint256);
}

contract VrhQuery {

    function getGuildWeights(address guildController, address[] memory _guilds) external view returns (uint[] memory) {
        uint[] memory weights = new uint[](_guilds.length);

        for(uint i = 0; i < _guilds.length; i++) {
            weights[i] = GuildController(guildController).get_guild_weight(_guilds[i]);
        }

        return weights;
    }

    function guildRelativeWeights(address guildController, address[] memory _guilds) external view returns (uint[] memory) {
        uint[] memory weights = new uint[](_guilds.length);

        for(uint i = 0; i < _guilds.length; i++) {
            weights[i] = GuildController(guildController).guild_relative_weight(_guilds[i]);
        }

        return weights;
    }

    function guildEffectiveWeights(address guildController, address[] memory _guilds) external view returns (uint[] memory) {
        uint[] memory weights = new uint[](_guilds.length);

        for(uint i = 0; i < _guilds.length; i++) {
            weights[i] = GuildController(guildController).guild_effective_weight(_guilds[i]);
        }

        return weights;
    }

    function commissionRates(address[] memory _guilds) external view returns (uint[] memory) {
        uint[] memory rates = new uint[](_guilds.length);

        for(uint i = 0; i < _guilds.length; i++) {
            uint lastChangeRate = Guild(_guilds[i]).last_change_rate();
            rates[i] = Guild(_guilds[i]).commission_rate(lastChangeRate);
        }

        return rates;
    }

}