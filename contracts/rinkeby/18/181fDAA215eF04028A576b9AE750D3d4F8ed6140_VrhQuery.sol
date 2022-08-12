/**
 *Submitted for verification at Etherscan.io on 2022-08-12
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
    function working_supply() external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract VrhQuery {

    function balances(address _address, address[] memory _tokens) external view returns (uint[] memory) {
        uint[] memory results = new uint[](_tokens.length);

        for(uint i = 0; i < _tokens.length; i++) {
            results[i] = IERC20(_tokens[i]).balanceOf(_address);
        }

        return results;
    }


    function getGuildWeights(address guildController, address[] memory _guilds) external view returns (uint[] memory) {
        uint[] memory results = new uint[](_guilds.length);

        for(uint i = 0; i < _guilds.length; i++) {
            results[i] = GuildController(guildController).get_guild_weight(_guilds[i]);
        }

        return results;
    }

    function guildRelativeWeights(address guildController, address[] memory _guilds) external view returns (uint[] memory) {
        uint[] memory results = new uint[](_guilds.length);

        for(uint i = 0; i < _guilds.length; i++) {
            results[i] = GuildController(guildController).guild_relative_weight(_guilds[i]);
        }

        return results;
    }

    function guildEffectiveWeights(address guildController, address[] memory _guilds) external view returns (uint[] memory) {
        uint[] memory results = new uint[](_guilds.length);

        for(uint i = 0; i < _guilds.length; i++) {
            results[i] = GuildController(guildController).guild_effective_weight(_guilds[i]);
        }

        return results;
    }

    function commissionRates(address[] memory _guilds) external view returns (uint[] memory) {
        uint[] memory results = new uint[](_guilds.length);

        for(uint i = 0; i < _guilds.length; i++) {
            uint lastChangeRate = Guild(_guilds[i]).last_change_rate();
            results[i] = Guild(_guilds[i]).commission_rate(lastChangeRate);
        }

        return results;
    }

    function workingSupply(address[] memory _guilds) external view returns (uint[] memory) {
        uint[] memory results = new uint[](_guilds.length);

        for(uint i = 0; i < _guilds.length; i++) {
            results[i] = Guild(_guilds[i]).working_supply();
        }

        return results;
    }

}