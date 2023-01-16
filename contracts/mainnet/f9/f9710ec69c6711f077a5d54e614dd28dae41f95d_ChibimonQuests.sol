// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IERC20} from './IERC20.sol';
import {IERC721} from './IERC721.sol';
import {Ownable} from './Ownable.sol';
import {ECDSA} from './ECDSA.sol';

error IncorrectSignature();
error QuestNotActive();
error NoQuestAmountAvailable();
error TokenAlreadyCompletedQuest(uint256 tokenId);
error AddressCantBeBurner();
error QuestIdCantBeZero();
error QuestAlreadyExists();

contract ChibimonQuests is Ownable {

    using ECDSA for bytes32;

    struct Quest {
        uint256 id;
        uint256 amount;
        uint256 activeFrom;
        uint256 activeUntil;
        uint256 apeCoinRewards;
        address[] nftRewardContracts;
        uint256[] nftRewardTokenIds;
    }

    address private signer;
    address public treasury;

    mapping(uint256 => mapping(uint256 => bool)) public tokenHistory;
    mapping(uint256 => Quest) public quests;
    uint256[] public questIds;

    IERC20 public immutable apeCoin;

    constructor(address apeCoinAddress, address signerAddress) {
        treasury = msg.sender;
        signer = signerAddress;

        apeCoin = IERC20(apeCoinAddress);
    }
    
    // external

    function claim(bytes calldata signature, uint256 questId, uint256[] calldata tokenIds) external {
        if( !_verifySig(msg.sender, questId, tokenIds, signature) ) revert IncorrectSignature();
        if( (quests[questId].activeFrom > block.timestamp || quests[questId].activeUntil < block.timestamp) ) revert QuestNotActive();
        if( quests[questId].amount <= 0 ) revert NoQuestAmountAvailable();

        for(uint256 i; i < tokenIds.length; i++) {
            if( tokenHistory[tokenIds[i]][questId] ) revert TokenAlreadyCompletedQuest(tokenIds[i]);
            tokenHistory[tokenIds[i]][questId] = true;
        }

        _claim(msg.sender, questId);
    }

    // external owner

    function claimForHolder(address holder, uint256 questId) external onlyOwner {
        if( quests[questId].amount <= 0 ) revert NoQuestAmountAvailable();
        
        _claim(holder, questId);
    }

    function setTokenQuestHistory(uint256 tokenId, uint256 questId, bool status) external onlyOwner {
        tokenHistory[tokenId][questId] = status;
    }

    function createQuest(uint256 id, uint256 amount, uint256 activeFrom, uint256 activeUntil, uint256 apeCoinRewards, address[] calldata nftRewardContracts, uint256[] calldata nftRewardTokenIds) external onlyOwner {
        _createQuest(id, amount, activeFrom, activeUntil, apeCoinRewards, nftRewardContracts, nftRewardTokenIds);
    }

    function createQuest(uint256 id, uint256 amount, uint256 activeFrom, uint256 activeUntil, uint256 apeCoinRewards) external onlyOwner {
        address[] memory emptyContracts;
        uint256[] memory emptyTokens;

        _createQuest(id, amount, activeFrom, activeUntil, apeCoinRewards, emptyContracts, emptyTokens);
    }

    function editQuestAmount(uint256 id, uint256 amount) external onlyOwner {
        quests[id].amount = amount;
    }

    function editQuestActiveTimespan(uint256 id, uint256 activeFrom, uint256 activeUntil) external onlyOwner {
        quests[id].activeFrom = activeFrom;
        quests[id].activeUntil = activeUntil;
    }

    function editQuestApeCoinRewards(uint256 id, uint256 apeCoinRewards) external onlyOwner {
        quests[id].apeCoinRewards = apeCoinRewards;
    }

    function editQuestNftRewards(uint256 id, address[] calldata nftRewardContracts, uint256[] calldata nftRewardTokenIds) external onlyOwner {
        quests[id].nftRewardContracts = nftRewardContracts;
        quests[id].nftRewardTokenIds = nftRewardTokenIds;
    }

    function deleteQuest(uint256 id) external onlyOwner {
        delete quests[id];

        for(uint256 i; i < questIds.length; i++) {
            if(questIds[i] == id ) {
                delete questIds[i]; 
                break;
            } 
        }
    }

    function setSigner(address signerAddress) external onlyOwner {
        if( signerAddress == address(0) ) revert AddressCantBeBurner();
        signer = signerAddress;
    }
    
    // public views

    function getQuests() public view returns(Quest[] memory) {
        return _getQuests(false);
    }

    function getActiveQuests() public view returns(Quest[] memory) {
        return _getQuests(true);
    }

    function getTokenQuestHistory(uint256 tokenId) public view returns(uint256[] memory) {
        uint256[] memory tokenQuests = new uint256[](_getTokenQuestHistoryCount(tokenId));
        uint256 tokenQuestIndex;

        for(uint256 i; i < questIds.length; i++) {
            if(tokenHistory[tokenId][questIds[i]]) {
                tokenQuests[tokenQuestIndex++] = questIds[i];
            }
        }

        return tokenQuests;
    }

    // internal

    function _createQuest(uint256 id, uint256 amount, uint256 activeFrom, uint256 activeUntil, uint256 apeCoinRewards, address[] memory nftRewardContracts, uint256[] memory nftRewardTokenIds) internal {
        
        if( id <= 0) revert QuestIdCantBeZero();
        if( quests[id].id > 0 ) revert QuestAlreadyExists();

        Quest memory newQuest = Quest(
            id,
            amount,
            activeFrom,
            activeUntil,
            apeCoinRewards,
            nftRewardContracts,
            nftRewardTokenIds
        );

        quests[id] = newQuest;
        questIds.push(id);

    }

    function _claim(address sender, uint256 questId) internal {

        --quests[questId].amount;

        if(quests[questId].apeCoinRewards > 0) {
            apeCoin.transferFrom(treasury, sender, quests[questId].apeCoinRewards * 1e18);
        }

        if(quests[questId].nftRewardContracts.length > 0) {
            for( uint256 i; i < quests[questId].nftRewardContracts.length; i++) {
                IERC721 nftContract = IERC721(quests[questId].nftRewardContracts[i]);
                nftContract.transferFrom(treasury, sender, quests[questId].nftRewardTokenIds[i]);
            }
        }

    }

    // internal views
    
    function _getTokenQuestHistoryCount(uint256 tokenId) internal view returns(uint256) {
            uint256 tokenQuestCount;

            for(uint256 i; i < questIds.length; i++) {
                if(tokenHistory[tokenId][questIds[i]]) {
                    tokenQuestCount++;
                }
            }

            return tokenQuestCount;
    }

    function _getQuestCount(bool onlyActive) internal view returns(uint256) {
        uint256 questCount;

        for(uint256 i; i < questIds.length; i++) {
            if( questIds[i] > 0 && 
            ( !onlyActive || (quests[questIds[i]].activeFrom <= block.timestamp && quests[questIds[i]].activeUntil >= block.timestamp))) {
                questCount++;
            }
        }

        return questCount;
    }

    function _getQuests(bool onlyActive) internal view returns(Quest[] memory) {
        Quest[] memory allQuests = new Quest[](_getQuestCount(onlyActive));
        uint256 questIndex;
        
        for(uint256 i; i < questIds.length; i++) {
            if( questIds[i] > 0 && 
            ( !onlyActive || (quests[questIds[i]].activeFrom <= block.timestamp && quests[questIds[i]].activeUntil >= block.timestamp))) {
                allQuests[questIndex++] = quests[questIds[i]];
            }
        }

        return allQuests;
    }

    function _verifySig(address sender, uint256 questId, uint256[] calldata tokenIds, bytes memory signature) internal view returns(bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(sender, questId, tokenIds));
        return signer == messageHash.toEthSignedMessageHash().recover(signature);
    }

}