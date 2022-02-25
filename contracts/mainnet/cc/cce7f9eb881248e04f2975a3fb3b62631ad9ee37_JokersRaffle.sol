// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'libraries.sol';

// February 25th, 2022
// https://slamjokers.com
// Made for "Jokers by SLAM" by @Kadabra_SLAM (Telegram)

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface JokerNFTContract {
    function claimRaffleRewardMint() external returns (bool);
}

contract JokersRaffle is Ownable {
    address[] entries;
    address[] winners;

    address public jokersNFTContractAddress;
    bool isContinueNew = true;
    bool paused = false;
    bool public isLive = true;
    uint public enterPriceFinney = 10; // 0.01 Ether = 10 Finney
    uint public maxParticipants = 8;

    constructor() {
        // <3
    }

    event EnteredRaffle(address);
    event RaffleWinner(address);
    
    receive() external payable {
        enter(); // If sent directly to the contract
    }

    function pickWinner() private view returns (uint) {
        uint random = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, entries)));
        uint index = random % entries.length;
        return index;
    }

    function claimFreeJokerMint() public {
        bool _isWinner = isWinner(msg.sender);
        require(_isWinner, "Not a winner");

        JokerNFTContract JokerNFTContractObj = JokerNFTContract(jokersNFTContractAddress);
        JokerNFTContractObj.claimRaffleRewardMint();
    }

    function enter() public payable {
        require(isLive && !paused, "The raffle has been paused");
        require(msg.value == enterPriceFinney * (10**15), "Pay the exact Ether amount to enter the raffle");

        bool allowedToEnter = true;
        for (uint i=0; i < entries.length; i++) {
            if (msg.sender == entries[i]) {
                allowedToEnter = false;
                continue;
            }
        }
        require(allowedToEnter, "Already entered this raffle");

        bool _isWinner = isWinner(msg.sender);
        require(!_isWinner, "Already won a raffle");

        entries.push(msg.sender);
        emit EnteredRaffle(msg.sender);

        if (entries.length >= maxParticipants) {
            uint winnerIndex = pickWinner();
            address winner = entries[winnerIndex];
        
            winners.push(winner);
            delete entries;
            emit RaffleWinner(winner);

            isLive = isContinueNew;
        }
    }

    function viewWinners() public view returns(address [] memory){
        return winners;
    }

    function isWinner(address _address) public view returns(bool){
        bool _isWinner = false;
        for (uint i=0; i < winners.length; i++) {
            if (_address == winners[i]) {
                _isWinner = true;
                continue;
            }
        }
        return _isWinner;
    }

    function viewCurrentEntries() public view returns(address [] memory){
        return entries;
    }

    function getTotalEntries() public view returns (uint) {
        return entries.length;
    }

    // OnlyOwner
    function setConfig(address _nftContractAddress, uint256 _finneyPrice, uint _maxParticipants) external onlyOwner{
        jokersNFTContractAddress = _nftContractAddress;
        enterPriceFinney = _finneyPrice;
        maxParticipants = _maxParticipants;
    }

    function pause(bool _pause) public onlyOwner{
        paused = _pause;
    }
    
    function setIsLiveNext(bool _isLiveNext) public onlyOwner{
        isContinueNew = _isLiveNext;
    }

    function resetRaffle() public onlyOwner{
        delete entries;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // To get any tokens out of the contract if needed
    function withdrawToken(address _tokenContract, uint256 _amount, address _to) external onlyOwner{
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(_to, _amount);
    }
    function withdrawToken_All(address _tokenContract, address _to) external onlyOwner{
        IERC20 tokenContract = IERC20(_tokenContract);
        uint256 _amount = tokenContract.balanceOf(address(this));
        tokenContract.transfer(_to, _amount);
    }
}