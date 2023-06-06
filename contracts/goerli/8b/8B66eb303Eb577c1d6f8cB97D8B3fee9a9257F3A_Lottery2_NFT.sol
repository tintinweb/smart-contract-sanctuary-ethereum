// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./2.IERC20.sol";
import "./3.Ownable.sol";
import "./4.Pausable.sol";
import "./5.IERC721.sol";
import "./6.VRFV2WrapperConsumerBase.sol";
import "./7.ConfirmedOwner.sol";

contract Lottery2_NFT is
    VRFV2WrapperConsumerBase,
    ConfirmedOwner,
    Pausable
{
    // ==== Variables declaration ====
        // ==== Game related ====
        IERC721[] public rewardNFTs; // NFT rewards array
        uint256[] public rewardNFTIds; // NFT token ID array
        uint256 public gameRound = 1;
        uint256 public costPerEntry; //amount of eth per entry
        uint256 public maxAllowedEntries; // maximum number of entry
        uint256 public numberOfCurrentEntries; // current entry number
        mapping(uint256 => address) public participantByEntryIndex; // mapping of participant address for each entry
        mapping(address => Participant) public participants; // mapping of each unique participants

        struct Participant { // record of each unique participants information
            uint256 lastParticipatedRound;
            uint256 numberOfEntries;
        }

        // ==== Chainlink VRF related ====
        uint256 public randomResult; //stores result of the chainlink randomizer 
        uint32 private callbackGasLimit = 300000; // gas limit to call on VRF
        uint16 private requestConfirmations = 3;
        uint32 private numWords = 1;
        address private linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB; //$LINK tokens address 
        address private wrapperAddress = 0x708701a1DfF4f478de54383E49a627eD4852C816; //ChainLink wrapper address

    constructor()
        ConfirmedOwner(msg.sender)
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
    {}

    //==== Game & Rewards Settings ====    
    function setRewards(IERC721[] memory _rewardNFTs, uint256[] memory _rewardNFTIds) external onlyOwner {
        require(_rewardNFTs.length == _rewardNFTIds.length, "NFTs and IDs arrays should have the same length");
        rewardNFTs = _rewardNFTs;
        rewardNFTIds = _rewardNFTIds;
    }

    function gameSetup(uint256 _entryCost, uint256 _maxEntries) external onlyOwner {
        costPerEntry = _entryCost;
        maxAllowedEntries = _maxEntries;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // ==== Game Operations ====
    function enterGame() public payable whenNotPaused {
        require(msg.value == costPerEntry, "ETH sent should equal the cost per entry");
        require(numberOfCurrentEntries < maxAllowedEntries, "Maximum entries reached");

        // If it's a new round, reset their entries
        if(participants[msg.sender].lastParticipatedRound < gameRound) {
            participants[msg.sender].numberOfEntries = 0; // reset their entries
        }
        
        participantByEntryIndex[numberOfCurrentEntries] = msg.sender; //save user address to entry index
        numberOfCurrentEntries++; //increment the new current entries number
        participants[msg.sender].numberOfEntries++; //increment number of times user entered the game
        participants[msg.sender].lastParticipatedRound = gameRound; // update their participation round
    }

    function pickWinners(uint256 numberOfWinners) public onlyOwner whenNotPaused {
        require(numberOfCurrentEntries >= maxAllowedEntries, "Maximum entries not reached");
        require(numberOfWinners <= rewardNFTs.length, "More winners than NFTs");
        require(numberOfWinners <= numberOfCurrentEntries, "More winners than participants");

        for(uint256 i = 0; i < numberOfWinners; i++) {
            uint256 index = randomResult % numberOfCurrentEntries; //generate random index
            address winner = participantByEntryIndex[index]; //identify winner

            uint256 nftIndex = randomResult % rewardNFTs.length; //generate randon index 
            IERC721 rewardNFT = rewardNFTs[nftIndex]; //NFT selected
            uint256 rewardNFTId = rewardNFTIds[nftIndex];

            require(rewardNFT.ownerOf(rewardNFTId) == address(this), "Contract doesn't own the NFT");
            rewardNFT.transferFrom(address(this), winner, rewardNFTId); //transfer NFT to winner

            rewardNFTs[nftIndex] = rewardNFTs[rewardNFTs.length - 1]; // swap distributed NFT address to last position
            rewardNFTs.pop(); //remove that NFT address 
            rewardNFTIds[nftIndex] = rewardNFTIds[rewardNFTIds.length - 1]; //swap distrbuted NFT token ID to last position
            rewardNFTIds.pop(); //remove that NFT token ID

            //Shift array to fill gap and remove last position to avoid duplicate winners
            for (uint256 j = index; j < numberOfCurrentEntries - 1; j++) {
                participantByEntryIndex[j] = participantByEntryIndex[j + 1];
            }
            delete participantByEntryIndex[numberOfCurrentEntries - 1];
            numberOfCurrentEntries--;
        }
    }
    
    // ==== Game information query ====
    function getParticipantEntries(address participant) public view returns (uint256) {
        return participants[participant].numberOfEntries;
    }

    function getCurrentEntries() public view returns (uint256) {
        return numberOfCurrentEntries;
    }

    function getContractETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTokenBalance(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    // ==== Game reset ====
    function resetGame() public onlyOwner {
        // Make sure we've picked winners already
        require(numberOfCurrentEntries == 0, "Game has not finished yet");

        // Increment the game round
        gameRound++;

        // Reset the current entries, max entries, reward NFTs, and reward NFT IDs
        numberOfCurrentEntries = 0;
        maxAllowedEntries = 0;
        delete rewardNFTs;
        delete rewardNFTIds;
    }

    function clearRewards() public onlyOwner {
        delete rewardNFTs;
        delete rewardNFTIds;
    }

    // ==== Random generator =====
    function requestRandomNumber() public onlyOwner returns (uint256 requestId) {
        require(LINK.balanceOf(address(this)) >= 0.25 ether, "Not enough LINK to pay fee");
        return requestRandomness(callbackGasLimit, requestConfirmations, numWords);
    }

    function fulfillRandomWords(uint256 , uint256[] memory randomWords)
        internal
        override
    {
        randomResult = randomWords[0];
    }

    // ==== Withdraw assets ====
    function withdrawETH(address payable _to) public onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw");
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawERC20(address token, address to) public onlyOwner {
        IERC20 erc20Token = IERC20(token);
        uint256 balance = erc20Token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        erc20Token.transfer(to, balance);
    }

    function withdrawNFTs(address nft, uint256 id, address to) public onlyOwner {
        IERC721 erc721Token = IERC721(nft);
        require(erc721Token.ownerOf(id) == address(this), "The contract doesn't own this NFT");
        erc721Token.transferFrom(address(this), to, id);
    }
    
}