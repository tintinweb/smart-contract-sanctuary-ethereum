/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IToken {
    function allowance(address, address) external view returns(uint256);
    function getEthBalance(address) external view returns (uint256);
    function balanceOf(address) external view returns(uint256);
}

interface IBeefyStrategy {
    function paused() external view returns (bool);
}

interface IBeefyVault {
    function balance() external view returns (uint256);
    function getPricePerFullShare() external view returns (uint256);
    function strategy() external view returns (IBeefyStrategy);
}

interface IBeefyBoost {
    function totalSupply() external view returns (uint256);
    function periodFinish() external view returns (uint256);
    function rewardRate() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function earned(address) external view returns (uint256);
    function isPreStake() external view returns (bool);
}

struct BoostInfo {
    uint256 totalSupply;
    uint256 rewardRate;
    uint256 periodFinish;
    bool isPreStake;
}

struct VaultInfo {
    uint256 balance;
    uint256 pricePerFullShare;
    address strategy;
    bool paused;
}

struct GovVaultInfo {
    uint256 totalSupply;
}

struct GovVaultBalanceInfo {
    uint256 balance;
    uint256 rewards;
}

struct BoostBalanceInfo {
    uint256 balance;
    uint256 rewards;
}

struct AllowanceInfo {
    uint[] allowances;
}

contract BeefyV2AppMulticall {

    function getVaultInfo(address[] calldata vaults) external view returns (VaultInfo[] memory) {
        VaultInfo[] memory results = new VaultInfo[](vaults.length);

        for (uint i = 0; i < vaults.length; i++) {
            IBeefyVault vault = IBeefyVault(vaults[i]);
            IBeefyStrategy strat = vault.strategy();
            bool paused;
            try strat.paused() returns (bool _paused) {
                paused = _paused;
            } catch { 
                paused = false; 
            }
            results[i] = VaultInfo(
                vault.balance(),
                vault.getPricePerFullShare(),
                address(strat),
                paused
            );
        }

        return results;
    }

    function getBoostInfo(address[] calldata boosts) external view returns (BoostInfo[] memory) {
        BoostInfo[] memory results = new BoostInfo[](boosts.length);

        for (uint i = 0; i < boosts.length; i++) {
            IBeefyBoost boost = IBeefyBoost(boosts[i]);
            uint256 periodFinish = boost.periodFinish();
            bool isPreStake;
            try boost.isPreStake() returns (bool _isPreStake) {
                isPreStake = _isPreStake;
            } catch { 
                isPreStake = periodFinish == 0; 
            }
            results[i] = BoostInfo(
                boost.totalSupply(),
                boost.rewardRate(),
                periodFinish,
                isPreStake
            );
        }

        return results;
    }

    function getGovVaultInfo(address[] calldata govVaults) external view returns (GovVaultInfo[] memory) {
        GovVaultInfo[] memory results = new GovVaultInfo[](govVaults.length);

        for (uint i = 0; i < govVaults.length; i++) {
            IBeefyBoost govVault = IBeefyBoost(govVaults[i]);
            results[i] = GovVaultInfo(
                govVault.totalSupply()
            );
        }

        return results;
    }

    function getTokenBalances(address[] calldata tokens, address owner) external view returns (uint256[] memory) {
        uint256[] memory results = new uint256[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            IToken token = IToken(tokens[i]);
            results[i] = token.balanceOf(owner);
        }
        return results;
    }

    function getBoostOrGovBalance(address[] calldata boosts, address owner) external view returns (BoostBalanceInfo[] memory) {
        BoostBalanceInfo[] memory results = new BoostBalanceInfo[](boosts.length);
        for (uint i = 0; i < boosts.length; i++) {
            IBeefyBoost boost = IBeefyBoost(boosts[i]);
            results[i] = BoostBalanceInfo(
                boost.balanceOf(owner),
                boost.earned(owner)
            );
        }

        return results;
    }

    function getGovVaultBalance(address[] calldata govVaults, address owner) external view returns (GovVaultBalanceInfo[] memory) {
        GovVaultBalanceInfo[] memory results = new GovVaultBalanceInfo[](govVaults.length);
        for (uint i = 0; i < govVaults.length; i++) {
            IBeefyBoost govVault = IBeefyBoost(govVaults[i]);
            results[i] = GovVaultBalanceInfo(
                govVault.balanceOf(owner),
                govVault.earned(owner)
            );
        }

        return results;
    }

    function getAllowances(address[] calldata tokens, address[][] calldata spenders, address owner) external view returns (AllowanceInfo[] memory) {
        AllowanceInfo[] memory results = new AllowanceInfo[](tokens.length);

        for (uint i = 0; i < tokens.length; i++) {
            IToken token = IToken(tokens[i]);
            address[] calldata tokenSpenders = spenders[i];
            results[i] = AllowanceInfo(
                new uint256[](tokenSpenders.length)
            );
            for (uint j = 0; j < tokenSpenders.length; j++) {
                results[i].allowances[j] = token.allowance(owner, tokenSpenders[j]);
            }
        }

        return results;
    }

    function getAllowancesFlat(address[] calldata tokens, address[][] calldata spenders, address owner) external view returns (uint256[] memory) {
        uint totalLength;
        for(uint i = 0; i < spenders.length; i++) {
            totalLength += spenders[i].length;
        }
        
        uint256[] memory results = new uint256[](totalLength);

        uint maxAcum;
        for (uint i = 0; i < tokens.length; i++) {
            IToken token = IToken(tokens[i]);
            address[] calldata tokenSpenders = spenders[i];
            for (uint j = 0; j < tokenSpenders.length; j++) {
                results[maxAcum++] = token.allowance(owner, tokenSpenders[j]);
            }
        }

        return results;
    }
}