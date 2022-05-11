/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File contracts/DappsStaking.sol

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

/// Interface to the precompiled contract on Shibuya/Shiden/Astar
/// Predeployed at the address 0x0000000000000000000000000000000000005001
interface DappsStaking {
    // Storage getters

    /// @notice Read current era.
    /// @return era, The current era
    function read_current_era() external view returns (uint256);

    /// @notice Read unbonding period constant.
    /// @return period, The unbonding period in eras
    function read_unbonding_period() external view returns (uint256);

    /// @notice Read Total network reward for the given era
    /// @return reward, Total network reward for the given era
    function read_era_reward(uint32 era) external view returns (uint128);

    /// @notice Read Total staked amount for the given era
    /// @return staked, Total staked amount for the given era
    function read_era_staked(uint32 era) external view returns (uint128);

    /// @notice Read Staked amount for the staker
    /// @param staker in form of 20 or 32 hex bytes
    /// @return amount, Staked amount by the staker
    function read_staked_amount(bytes calldata staker) external view returns (uint128);

    /// @notice Read the staked amount from the era when the amount was last staked/unstaked
    /// @return total, The most recent total staked amount on contract
    function read_contract_stake(address contract_id) external view returns (uint128);

    // Extrinsic calls

    /// @notice Register provided contract.
    function register(address) external;

    /// @notice Stake provided amount on the contract.
    function bond_and_stake(address, uint128) external;

    /// @notice Start unbonding process and unstake balance from the contract.
    function unbond_and_unstake(address, uint128) external;

    /// @notice Withdraw all funds that have completed the unbonding process.
    function withdraw_unbonded() external;

    /// @notice Claim one era of unclaimed staker rewards for the specifeid contract.
    ///         Staker account is derived from the caller address.
    function claim_staker(address) external;

    /// @notice Claim one era of unclaimed dapp rewards for the specified contract and era.
    function claim_dapp(address, uint128) external;
}


// File contracts/EtherWallet.sol

pragma solidity ^0.8.10;

// prettier-ignore
abstract contract EtherWallet {
    receive() external payable {}
    fallback() external payable {}

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}


// File contracts/test/DappsStakingMock.sol

pragma solidity ^0.8.0;


// prettier-ignore
contract DappsStakingMock is DappsStaking, EtherWallet {
    // read
    function read_current_era() external view returns (uint256) {
        return era;
    }
    function read_unbonding_period() external pure returns (uint256) {
        return 2;
    }
    function read_era_reward(uint32) external pure returns (uint128) {
        return 0;
    }
    function read_era_staked(uint32) external pure returns (uint128) {
        return 0;
    }
    function read_staked_amount(bytes calldata) external pure returns (uint128) {
        return 0;
    }
    function read_contract_stake(address) external pure returns (uint128) {
        return 0;
    }

    // write
    function register(address) external {}
    function bond_and_stake(address, uint128) external {}
    function unbond_and_unstake(address, uint128) external {}
    function withdraw_unbonded() external {}
    function claim_staker(address caller) external {
        (bool success, ) = payable(caller).call{value: 1 ether}("");
        require(success);
    }
    function claim_dapp(address, uint128) external {}

    // for test
    uint256 private era = 1;
    function next() external {
        era++;
    }
}