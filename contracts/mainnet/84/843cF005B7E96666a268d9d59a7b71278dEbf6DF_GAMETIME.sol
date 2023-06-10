// SPDX-License-Identifier: MIT
// DumplingZai v69696969 
// "I smash keyboards and vomit smart contracts"


pragma solidity ^0.8.7;

import "./2.IERC20.sol";
import "./3.Ownable.sol";
import "./4.Pausable.sol";
import "./5.IERC721.sol";
import "./6.VRFV2WrapperConsumerBase.sol";
import "./7.ConfirmedOwner.sol";
import "./8.IERC721Receiver.sol";
import "./9.AccessControl.sol";

contract GAMETIME is 
    AccessControl,
    VRFV2WrapperConsumerBase,
    ConfirmedOwner,
    Pausable,
    IERC721Receiver
    {
    
    // ==== Variables declaration ====
        // ==== Game related ====
        IERC721[] public rewardNFTs; // NFT rewards array
        uint256[] public rewardNFTIds; // NFT token ID array
        uint256 public rewardETHPerWinner; // ETH rewards
        uint256 public gameRound = 1; //for clearing participant mapping
        uint256 public gameStarted = 0;
        uint256 public numberOfWinners;  
        uint256 public costPerEntry; //amount of eth per entry
        uint256 public maxAllowedEntries; // maximum number of entry
        uint256 public numberOfCurrentEntries; // current entry number
        uint256 private entriesTracker; // internal tracker
        uint256 public prizeMode; // 0 for NFT prize, 1 for ETH prize
        address[] public winnerList; //storing of winners per round
        mapping(address => Participant) public participants; // mapping of each unique participants
        mapping(uint256 => mapping(uint256 => address)) public participantByEntryIndexPerRound; //for new participantByEntryIndex each round
        mapping(address => mapping(uint256 => PrizeInfo[])) Winners; // mapping of each winner to their prizes
        mapping(uint256 => address[]) public winnersPerRound;

        struct PrizeInfo { // record of each selected winner and their prize 
            address nft; 
            uint256 prizeAmountOrId; 
            bool claimed; 
            uint256 round;
        }

        struct Participant { // record of each unique participants information
            uint256 lastParticipatedRound;
            uint256 numberOfEntries;
        }

        // ==== Chainlink VRF related ====
        uint256 public randomResult; //stores result of the chainlink randomizer 
        uint32 private callbackGasLimit = 300000; // gas limit to call on VRF
        uint16 private requestConfirmations = 3;
        uint32 private numWords = 1;
        address private linkAddress = 0x514910771AF9Ca656af840dff83E8264EcF986CA; //$LINK tokens address 
        address private wrapperAddress = 0x5A861794B927983406fCE1D062e00b9368d97Df6; //ChainLink wrapper address
  
        // ==== Automation related ====
        bytes32 public constant AUTOMATOR_ROLE = keccak256("AUTOMATOR_ROLE"); //Automator initalisation

    constructor()
        ConfirmedOwner(msg.sender)
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
    {}

    //==== Game & Rewards Settings ====    
    function setRewardsNFT(IERC721[] memory _rewardNFTs, uint256[] memory _rewardNFTIds) external onlyOwnerOrAutomator {
        require(_rewardNFTs.length == _rewardNFTIds.length, "NFTs and IDs arrays should have the same length");
        require(_rewardNFTs.length >= numberOfWinners, "The number of rewards is lesser than the number of winners");
        rewardNFTs = _rewardNFTs;
        rewardNFTIds = _rewardNFTIds;
    }

    function setRewardsETHPerWinner(uint256 _rewardETHPerWinner) external onlyOwnerOrAutomator {
        rewardETHPerWinner = _rewardETHPerWinner;
    }

    function gameSetup(uint256 _entryCost, uint256 _maxEntries, uint256 _numberOfWinners, uint256 _prizeMode) external onlyOwnerOrAutomator {
        costPerEntry = _entryCost;
        maxAllowedEntries = _maxEntries;
        numberOfWinners = _numberOfWinners;
        prizeMode = _prizeMode;
        gameStarted = 1;
    }
    
    function resetGame() external onlyOwnerOrAutomator {
        // Increment the game round
        gameRound++;

        // Reset the current entries, max entries, reward NFTs, and reward NFT IDs
        numberOfCurrentEntries = 0;
        maxAllowedEntries = 0;
        numberOfWinners = 0;
        delete rewardNFTs;
        delete rewardNFTIds;
        delete winnerList;
        gameStarted = 0;
        entriesTracker = 0;
        rewardETHPerWinner = 0;
        costPerEntry = 0;
    }

    function clearRewards() external onlyOwnerOrAutomator {
        delete rewardNFTs;
        delete rewardNFTIds;
        rewardETHPerWinner = 0;
    }

    function setGameRound(uint256 round) public onlyOwnerOrAutomator {
        gameRound = round;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // ==== Game Operations ====
    function enterGame() external payable whenNotPaused {
        require(msg.value >= costPerEntry, "ETH sent should equal or more than the cost per entry");
        require(msg.value % costPerEntry == 0, "ETH sent should be as a multiple of cost per entry");
        uint256 numOfEntries = msg.value / costPerEntry;
        require(numberOfCurrentEntries + numOfEntries <= maxAllowedEntries, "Exceeds maximum entries allowed");
         // If it's a new round, reset their entries
        if(participants[msg.sender].lastParticipatedRound < gameRound) {
            participants[msg.sender].numberOfEntries = 0; // reset their entries
        }

        for (uint256 i = 0; i < numOfEntries; i++) {
            participantByEntryIndexPerRound[gameRound][numberOfCurrentEntries] = msg.sender;
            numberOfCurrentEntries++; //increment the new current entries number
            entriesTracker++; //internal entries tracker
            participants[msg.sender].numberOfEntries++; //increment number of times user entered the game
        }   
        participants[msg.sender].lastParticipatedRound = gameRound; // update their participation round
    }

    function pickWinners() public onlyOwnerOrAutomator whenNotPaused {
        require(entriesTracker == maxAllowedEntries, "Maximum entries not reached");
        require(numberOfWinners <= entriesTracker, "More winner than entries");
        
        for(uint256 i = 0; i < numberOfWinners; i++) {
            uint256 index = uint256(keccak256(abi.encodePacked(randomResult, i))) % entriesTracker; //generate random index 
            address payable winner = payable(participantByEntryIndexPerRound[gameRound][index]); //identify winner
            winnerList.push(winner);
            PrizeInfo memory prize;
            if (prizeMode == 0){
                uint256 nftIndex = randomResult % rewardNFTs.length; //generate random index 
                IERC721 rewardNFT = rewardNFTs[nftIndex]; //NFT selected
                uint256 rewardNFTId = rewardNFTIds[nftIndex];
                require(rewardNFT.ownerOf(rewardNFTId) == address(this), "Contract doesn't own the NFT");
                prize = PrizeInfo(address(rewardNFTs[nftIndex]), rewardNFTIds[nftIndex], false, gameRound);
                Winners[winner][gameRound].push(prize); 

                //removing winner from pool for next selection 
                rewardNFTs[nftIndex] = rewardNFTs[rewardNFTs.length - 1]; // swap distributed NFT address to last position
                rewardNFTs.pop(); //remove that NFT address 
                rewardNFTIds[nftIndex] = rewardNFTIds[rewardNFTIds.length - 1]; //swap distrbuted NFT token ID to last position
                rewardNFTIds.pop(); //remove that NFT token ID
            }
            else if (prizeMode == 1){ //ETH prize to be given out
                require(address(this).balance >= rewardETHPerWinner, "Contract doesn't have enough ETH");
                prize = PrizeInfo(address(0), rewardETHPerWinner, false, gameRound); // NFT address is 0x0 for ETH prize
                Winners[winner][gameRound].push(prize);
            }

            //Shift array to fill gap and remove last position to avoid duplicate winners
            for (uint256 j = index; j < numberOfCurrentEntries - 1; j++) {
                participantByEntryIndexPerRound[gameRound][j] = participantByEntryIndexPerRound[gameRound][j + 1];
            }
            delete participantByEntryIndexPerRound[gameRound][numberOfCurrentEntries - 1];
            entriesTracker--;
        }
        gameStarted = 2;
    }

    
    function claimPrizes(address winner) external {
        require(Winners[winner][gameRound].length > 0, "No prizes in this round");

        for(uint256 i = 0; i < Winners[winner][gameRound].length; i++) {
            // Only allow claiming of prizes that haven't been claimed yet
            if (!Winners[winner][gameRound][i].claimed) {
                if (Winners[winner][gameRound][i].nft == address(0)) {
                    // ETH prize
                    require(address(this).balance >= Winners[winner][gameRound][i].prizeAmountOrId, "Contract doesn't have enough ETH");
                    payable(winner).transfer(Winners[winner][gameRound][i].prizeAmountOrId); // transfer ETH to winner
                } else {
                    // NFT prize
                    IERC721 rewardNFT = IERC721(Winners[winner][gameRound][i].nft);
                    uint256 rewardNFTId = Winners[winner][gameRound][i].prizeAmountOrId;
                    require(rewardNFT.ownerOf(rewardNFTId) == address(this), "Contract doesn't own the NFT");
                    rewardNFT.transferFrom(address(this), winner, rewardNFTId); // transfer NFT to winner
                }
                Winners[winner][gameRound][i].claimed = true;
            }
        }
    }
    
    
    // ==== Game information query ====
    function getContractETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getTokenBalance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function getParticipantEntries(address participantAddress) external view returns (uint256) {
        if (participants[participantAddress].lastParticipatedRound < gameRound) {
            return 0;
        } else {
            return participants[participantAddress].numberOfEntries;
        }
    }

    function winnerCheck (address winner) external view returns (bool) {
        PrizeInfo[] storage prizeInfo = Winners[winner][gameRound];
        if (prizeInfo.length > 0) {
            for(uint256 i = 0; i < prizeInfo.length; i++) {
                if (!prizeInfo[i].claimed) {
                    return true;
                }
            }
        }
        return false;
    }

    function getWinnerListLength() public view returns (uint) {
        return winnerList.length;
    }

    // ==== Random generator =====
    function requestRandomNumber() external onlyOwnerOrAutomator returns (uint256 requestId) {
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
    function withdrawETH(address payable _to) external onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw");
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawERC20(address token, address to) external onlyOwner {
        IERC20 erc20Token = IERC20(token);
        uint256 balance = erc20Token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        erc20Token.transfer(to, balance);
    }

    function withdrawNFTs(address nft, uint256 id, address to) external onlyOwner {
        IERC721 erc721Token = IERC721(nft);
        require(erc721Token.ownerOf(id) == address(this), "The contract doesn't own this NFT");
        erc721Token.transferFrom(address(this), to, id);
    }

    // ===== Others =====
    function onERC721Received(address, address, uint256, bytes memory) external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    

    function addAutomator(address _automator) external onlyOwner {
        grantRole(AUTOMATOR_ROLE, _automator);
    }

    function removeAutomator(address automator) external onlyOwner {
    revokeRole(AUTOMATOR_ROLE, automator);
    }

    modifier onlyOwnerOrAutomator() {
        require(owner() == _msgSender() || hasRole(AUTOMATOR_ROLE, _msgSender()), "Caller is not the owner or an automator");
        _;
    }

    receive() external payable {}//to receive ETH

}