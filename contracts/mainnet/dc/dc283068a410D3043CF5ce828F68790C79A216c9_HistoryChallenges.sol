// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ChallengeDetail.sol";
import "./SafeMath.sol";
import "./ERC20.sol";

contract HistoryChallenges{
    using SafeMath for uint256;

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
        sponsor = ChallengeDetail(_contractChallengeAddress).sponsor();
        challenger = ChallengeDetail(_contractChallengeAddress).challenger();
        challengeStart = ChallengeDetail(_contractChallengeAddress).startTime();
        challengeEnd = ChallengeDetail(_contractChallengeAddress).endTime();
        challengeDays = ChallengeDetail(_contractChallengeAddress).duration();
        targetChallenge = ChallengeDetail(_contractChallengeAddress).goal();
        minimumAchievementDays = ChallengeDetail(_contractChallengeAddress).dayRequired();
        awardReceiversPercent = ChallengeDetail(_contractChallengeAddress).getAwardReceiversPercent();
    }

    function challengesInfo2(address payable _contractChallengeAddress) public view returns(
        uint256 depopsitMatic, uint256[] memory amountDepositToken,
        uint256 indexNft, address contractChallengeAddress, 
        address contractNftAddress, uint256 chainId, uint256 challengeResult
    ){  
        bool isChallengeSuccess = ChallengeDetail(_contractChallengeAddress).isSuccess();
        if(isChallengeSuccess) {
            assembly {
                chainId := chainid()
            }
            
            address[] memory erc20ListAddress = ChallengeDetail(_contractChallengeAddress).allContractERC20();
            uint256[] memory depositToken = new uint256[](erc20ListAddress.length); 

            for(uint256 i = 0; i < erc20ListAddress.length; i++) {
                depositToken[i] = 0;
            }

            if(ChallengeDetail(_contractChallengeAddress).allowGiveUp(1)) {
                return(
                    ChallengeDetail(_contractChallengeAddress).totalReward(),
                    depositToken,
                    ChallengeDetail(_contractChallengeAddress).indexNft().sub(1),
                    _contractChallengeAddress,
                    ChallengeDetail(_contractChallengeAddress).erc721Address(1),
                    chainId,
                    1
                );
            } else {
                address createByToken = ChallengeDetail(_contractChallengeAddress).createByToken();
                for(uint256 i = 0; i < erc20ListAddress.length; i++) {
                    if(createByToken == erc20ListAddress[0]) {
                        depositToken[i] = ChallengeDetail(_contractChallengeAddress).totalReward();
                    } else {
                        depositToken[i] = 0;
                    }
                }
                return(
                    0,
                    depositToken,
                    ChallengeDetail(_contractChallengeAddress).indexNft().sub(1),
                    _contractChallengeAddress,
                    ChallengeDetail(_contractChallengeAddress).erc721Address(1),
                    chainId,
                    1
                );
            }
        } 
    }

    function getHistoryTokenAndCoinSendToContract(address payable _contractChallengeAddress) public view returns(
        uint256, 
        uint256, 
        uint256[] memory, 
        uint256[] memory,
        string[] memory
    ) {
        bool isCoinChallenges = ChallengeDetail(_contractChallengeAddress).allowGiveUp(1);
        uint256 totalReward = ChallengeDetail(_contractChallengeAddress).totalReward();
        address[] memory erc20ListAddress = ChallengeDetail(_contractChallengeAddress).allContractERC20();
        uint256[] memory tokenBalanceBefor = new uint256[](erc20ListAddress.length); 
        string[] memory listTokenSymbol = new string[](erc20ListAddress.length); 
        uint256[] memory tokenBalanceAfter = new uint256[](erc20ListAddress.length); 
        uint256 contractBalance = ChallengeDetail(_contractChallengeAddress).getContractBalance();
        if(isCoinChallenges) {
            for(uint256 i = 0; i < erc20ListAddress.length; i++) {
                tokenBalanceAfter[i] = ERC20(erc20ListAddress[i]).balanceOf(_contractChallengeAddress);
                listTokenSymbol[i] = ERC20(erc20ListAddress[i]).symbol();
            }
            
            uint256 balanceContract;

            if(contractBalance > totalReward) {
                balanceContract = contractBalance.sub(totalReward);
            }
            
            if(ChallengeDetail(_contractChallengeAddress).isFinished()) {
                uint256 balanceMatic = ChallengeDetail(_contractChallengeAddress).totalBalanceBaseToken();
                uint256[] memory balanceToken = ChallengeDetail(_contractChallengeAddress).getBalanceToken();
                return(totalReward, balanceMatic.sub(totalReward), tokenBalanceBefor, balanceToken, listTokenSymbol);
            } else {
                return(totalReward, balanceContract, tokenBalanceBefor, tokenBalanceAfter, listTokenSymbol);
            }
        } else {
            address payable challengeAddress = _contractChallengeAddress;
            uint256 indexCreateToken;
            for(uint256 i = 0; i < erc20ListAddress.length; i++) {
                listTokenSymbol[i] = ERC20(erc20ListAddress[i]).symbol();
                uint256 balance = ERC20(erc20ListAddress[i]).balanceOf(challengeAddress);
                address createByToken = ChallengeDetail(challengeAddress).createByToken();
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

            if(ChallengeDetail(challengeAddress).isFinished()) {
                uint256 balanceMatic = ChallengeDetail(_contractChallengeAddress).totalBalanceBaseToken();
                uint256[] memory balanceToken = ChallengeDetail(challengeAddress).getBalanceToken();
                balanceToken[indexCreateToken] = balanceToken[indexCreateToken].sub(totalReward);
                return(0, balanceMatic, tokenBalanceBefor, balanceToken, listTokenSymbol);
            } else {
                return(0, contractBalance, tokenBalanceBefor, tokenBalanceAfter, listTokenSymbol);
            }
        }
    }


    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}