// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./IChallenge.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract HistoryChallenges{
    using SafeMath for uint256;

    /**
     * @dev Returns information about a specific challenge contract.
     * @param _contractChallengeAddress The address of the challenge contract.
     * @return sponsor The address of the sponsor who initiated the challenge.
     * @return challenger The address of the challenger who accepted the challenge.
     * @return challengeStart The start time of the challenge.
     * @return challengeEnd The end time of the challenge.
     * @return challengeDays The duration of the challenge in days.
     * @return targetChallenge The goal or target of the challenge.
     * @return minimumAchievementDays The minimum number of days required to achieve the challenge.
     * @return awardReceiversPercent An array of percentages representing the distribution of awards to receivers.
     */
    function challengesInfo1(address payable _contractChallengeAddress) public view returns(
        address sponsor,
        address challenger,
        uint256 challengeStart,
        uint256 challengeEnd,
        uint256 challengeDays,
        uint256 targetChallenge,
        uint256 minimumAchievementDays,
        uint256[] memory awardReceiversPercent
    ){
        sponsor = IChallenge(_contractChallengeAddress).sponsor();
        challenger = IChallenge(_contractChallengeAddress).challenger();
        challengeStart = IChallenge(_contractChallengeAddress).startTime();
        challengeEnd = IChallenge(_contractChallengeAddress).endTime();
        challengeDays = IChallenge(_contractChallengeAddress).duration();
        targetChallenge = IChallenge(_contractChallengeAddress).goal();
        minimumAchievementDays = IChallenge(_contractChallengeAddress).dayRequired();
        awardReceiversPercent = IChallenge(_contractChallengeAddress).getAwardReceiversPercent();
    }
    
    /**
     * @dev Returns additional information about a specific challenge contract.
     * @param _contractChallengeAddress The address of the challenge contract.
     * @return depopsitMatic The amount of deposited Matic.
     * @return amountDepositToken An array of amounts deposited for each ERC20 token.
     * @return indexNft The index of the associated NFT (minus 1).
     * @return contractChallengeAddress The address of the challenge contract.
     * @return contractNftAddress The address of the associated NFT contract.
     * @return chainId The chain ID of the blockchain network.
     * @return challengeResult The result of the challenge (1 for success).
     */
    function challengesInfo2(address payable _contractChallengeAddress) public view returns(
        uint256 depopsitMatic, uint256[] memory amountDepositToken,
        uint256 indexNft, address contractChallengeAddress, 
        address contractNftAddress, uint256 chainId, uint256 challengeResult
    ){  
        bool isChallengeSuccess = IChallenge(_contractChallengeAddress).isSuccess();
        if(isChallengeSuccess) {
            assembly {
                chainId := chainid()
            }
            
            address[] memory erc20ListAddress = IChallenge(_contractChallengeAddress).allContractERC20();
            uint256[] memory depositToken = new uint256[](erc20ListAddress.length); 

            for(uint256 i = 0; i < erc20ListAddress.length; i++) {
                depositToken[i] = 0;
            }

            if(IChallenge(_contractChallengeAddress).allowGiveUp(1)) {
                return(
                    IChallenge(_contractChallengeAddress).totalReward(),
                    depositToken,
                    IChallenge(_contractChallengeAddress).indexNft().sub(1),
                    _contractChallengeAddress,
                    IChallenge(_contractChallengeAddress).erc721Address(1),
                    chainId,
                    1
                );
            } else {
                address createByToken = IChallenge(_contractChallengeAddress).createByToken();
                for(uint256 i = 0; i < erc20ListAddress.length; i++) {
                    if(createByToken == erc20ListAddress[0]) {
                        depositToken[i] = IChallenge(_contractChallengeAddress).totalReward();
                    } else {
                        depositToken[i] = 0;
                    }
                }
                return(
                    0,
                    depositToken,
                    IChallenge(_contractChallengeAddress).indexNft().sub(1),
                    _contractChallengeAddress,
                    IChallenge(_contractChallengeAddress).erc721Address(1),
                    chainId,
                    1
                );
            }
        } 
    }
    
    /**
     * @dev Returns the history of tokens and coins sent to a specific challenge contract.
     * @param _contractChallengeAddress The address of the challenge contract.
     * @return totalReward The total reward amount.
     * @return contractBalance The balance of the contract in the base token.
     * @return tokenBalanceBefore An array of token balances before the challenge.
     * @return tokenBalanceAfter An array of token balances after the challenge.
     * @return listTokenSymbol An array of token symbols.
     */
    function getHistoryTokenAndCoinSendToContract(address payable _contractChallengeAddress) public view returns(
        uint256, 
        uint256, 
        uint256[] memory, 
        uint256[] memory,
        string[] memory
    ) {
        bool isCoinChallenges = IChallenge(_contractChallengeAddress).allowGiveUp(1);
        uint256 totalReward = IChallenge(_contractChallengeAddress).totalReward();
        address[] memory erc20ListAddress = IChallenge(_contractChallengeAddress).allContractERC20();
        uint256[] memory tokenBalanceBefor = new uint256[](erc20ListAddress.length); 
        string[] memory listTokenSymbol = new string[](erc20ListAddress.length); 
        uint256[] memory tokenBalanceAfter = new uint256[](erc20ListAddress.length); 
        uint256 contractBalance = IChallenge(_contractChallengeAddress).getContractBalance();
        if(isCoinChallenges) {
            for(uint256 i = 0; i < erc20ListAddress.length; i++) {
                tokenBalanceAfter[i] = IERC20(erc20ListAddress[i]).balanceOf(_contractChallengeAddress);
                listTokenSymbol[i] = IERC20(erc20ListAddress[i]).symbol();
            }
            
            uint256 balanceContract;

            if(contractBalance > totalReward) {
                balanceContract = contractBalance.sub(totalReward);
            }
            
            if(IChallenge(_contractChallengeAddress).isFinished()) {
                uint256 balanceMatic = IChallenge(_contractChallengeAddress).totalBalanceBaseToken();
                uint256[] memory balanceToken = IChallenge(_contractChallengeAddress).getBalanceToken();
                return(
                    totalReward, 
                    balanceMatic >= totalReward ? balanceMatic.sub(totalReward) : 0, 
                    tokenBalanceBefor, 
                    balanceToken, 
                    listTokenSymbol
                );
            } else {
                return(totalReward, balanceContract, tokenBalanceBefor, tokenBalanceAfter, listTokenSymbol);
            }
        } else {
            address payable challengeAddress = _contractChallengeAddress;
            uint256 indexCreateToken;
            for(uint256 i = 0; i < erc20ListAddress.length; i++) {
                listTokenSymbol[i] = IERC20(erc20ListAddress[i]).symbol();
                uint256 balance = IERC20(erc20ListAddress[i]).balanceOf(challengeAddress);
                address createByToken = IChallenge(challengeAddress).createByToken();
                if(createByToken == erc20ListAddress[i]) {
                    tokenBalanceBefor[i] = totalReward;
                    indexCreateToken = i;
                    if(balance >= totalReward) {
                        tokenBalanceAfter[i] = balance.sub(totalReward);
                    }
                } else {
                    tokenBalanceAfter[i] = balance;
                }
            }

            if(IChallenge(challengeAddress).isFinished()) {
                uint256 balanceMatic = IChallenge(_contractChallengeAddress).totalBalanceBaseToken();
                uint256[] memory balanceToken = IChallenge(challengeAddress).getBalanceToken();
                balanceToken[indexCreateToken] = balanceToken[indexCreateToken].sub(totalReward);
                return(0, balanceMatic, tokenBalanceBefor, balanceToken, listTokenSymbol);
            } else {
                return(0, contractBalance, tokenBalanceBefor, tokenBalanceAfter, listTokenSymbol);
            }
        }
    }
    
    /**
     * @dev Compares two strings to check if they are equal.
     * @param a The first string to compare.
     * @param b The second string to compare.
     * @return True if the strings are equal, false otherwise.
     */
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}