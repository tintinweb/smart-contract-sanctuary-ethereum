/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface GuildController {
    function get_guild_weight(address addr) external view returns (uint256);
    function guild_relative_weight(address addr) external view returns (uint256);
    function guild_effective_weight(address addr) external view returns (uint256);
    function guilds(uint index) external view returns (address);
    function global_member_list(address addr) external view returns (address);
}


interface Guild {
    function last_change_rate() external view returns (uint256);
    function commission_rate(uint timestamp) external view returns (uint256);
    function working_supply() external view returns (uint256);
    function claimable_tokens(address addr) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}


interface RewardVestingEscrow {
    function balanceOf(address addr) external view returns (uint256);
    function get_claimable_tokens(address addr) external view returns (uint256);
}

interface VotingEscrow {
    function supply() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function locked(address addr) external view returns (uint256);
}

interface Vrh {
    function rate() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function mintable_in_timeframe(uint fromTime, uint toTime) external view returns (uint256);
}

interface VestingEscrow {
    function lockedSupply() external view returns (uint256);
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


    function home(address vrhAddress, uint fromTime, uint toTime, address votingEscrowAddress, address vestingEscrowAddress1, address vestingEscrowAddress2, address vestingEscrowAddress3) external view returns (uint[] memory) {
        uint[] memory results = new uint[](8);

        results[0] = Vrh(vrhAddress).rate();
        results[1] = Vrh(vrhAddress).totalSupply();
        results[2] = Vrh(vrhAddress).mintable_in_timeframe(fromTime, toTime);

        results[3] = VotingEscrow(votingEscrowAddress).supply();
        results[4] = VotingEscrow(votingEscrowAddress).totalSupply();

        results[5] = VestingEscrow(vestingEscrowAddress1).lockedSupply();
        results[6] = VestingEscrow(vestingEscrowAddress2).lockedSupply();
        results[7] = VestingEscrow(vestingEscrowAddress3).lockedSupply();

        return results;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    event Response(bytes data);

    function dashboard(address addr, address votingEscrowAddress, address guildControllerAddress, address rewardVestingEscrowAddress) external returns (uint[] memory) {
        uint[] memory results = new uint[](3);

        results[0] = VotingEscrow(votingEscrowAddress).locked(addr);

        address guildAddress = GuildController(guildControllerAddress).global_member_list(addr);
        if(guildAddress == address(0)){
            results[1] = RewardVestingEscrow(rewardVestingEscrowAddress).get_claimable_tokens(addr);
        }else{
            (bool success, bytes memory data) = guildAddress.staticcall(abi.encodeWithSelector(bytes4(keccak256(bytes("claimable_tokens(address)"))), addr));

            (uint claimable) = abi.decode(data, (uint));
            results[1] = claimable;
        }

        results[2] = RewardVestingEscrow(rewardVestingEscrowAddress).balanceOf(addr) - RewardVestingEscrow(rewardVestingEscrowAddress).get_claimable_tokens(addr);

        return results;
    }

}