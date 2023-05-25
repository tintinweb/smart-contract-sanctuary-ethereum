//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract YourContract {

    // State Variables
    address public immutable owner;
    uint public imageTotal = 0;
    string[] public images;
    uint public numberOfPlays = 0;
    mapping(address => uint) public cooldown;
    mapping (uint => PlayerCard) cardlist;
    uint public reward = 0.01 ether;

    event CardResult(address player, string[] imageURLs, bool isMatch);

    // Constructor: Called once on contract deployment
    // Check packages/hardhat/deploy/00_deploy_your_contract.ts
    constructor(address _owner) {
        owner = _owner;

        addImage("https://images.unsplash.com/photo-1532680678473-a16f2cda8e43?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTAxfHxzaGFwZXxlbnwwfDB8MHx8fDA%3D&auto=format&fit=crop&w=800&q=60");
        addImage("https://images.unsplash.com/photo-1551907234-4f794b152738?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxzZWFyY2h8MjZ8fHNoYXBlfGVufDB8fDB8fA%3D%3D&auto=format&fit=crop&w=800&q=60");
        addImage("https://images.unsplash.com/photo-1602750600155-1970ac3ad999?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MjAwfHxzaGFwZXxlbnwwfDB8MHx8fDA%3D&auto=format&fit=crop&w=800&q=60");
        addImage("https://images.unsplash.com/photo-1524168948265-8f79ad8d4e33?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OXx8c2hhcGV8ZW58MHwwfDB8fHww&auto=format&fit=crop&w=800&q=60");
        addImage("https://images.unsplash.com/photo-1503883391826-af91d7ce0533?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTV8fHNoYXBlfGVufDB8MHwwfHx8MA%3D%3D&auto=format&fit=crop&w=800&q=60");
        addImage("https://images.unsplash.com/photo-1509266044497-ed3d3ab3471e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MzN8fHNoYXBlfGVufDB8MHwwfHx8MA%3D%3D&auto=format&fit=crop&w=800&q=60");
        addImage("https://images.unsplash.com/photo-1473456229365-7a538630163b?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mzh8fHNoYXBlfGVufDB8MHwwfHx8MA%3D%3D&auto=format&fit=crop&w=800&q=60");
        addImage("https://images.unsplash.com/photo-1506463108611-88834e9f6169?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NTJ8fHNoYXBlfGVufDB8MHwwfHx8MA%3D%3D&auto=format&fit=crop&w=800&q=60");
        addImage("https://images.unsplash.com/photo-1516476675914-0160447c7282?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NzV8fHNoYXBlfGVufDB8MHwwfHx8MA%3D%3D&auto=format&fit=crop&w=800&q=60");
    }

    // Modifier: used to define a set of rules that must be met before or after a function is executed
    // Check the withdraw() function
    modifier isOwner() {
        // msg.sender: predefined variable that represents address of the account that called the current function
        require(msg.sender == owner, "Not the Owner");
        _;
    }

    struct PlayerCard {
        uint id;
        mapping(string => uint) sameImageCount;
    }

    function addImage(string memory _imageURL) public payable {
        images.push(_imageURL);
        imageTotal++;
    }

    function playGame() external payable{
        require(msg.value >= 0.001 ether, "Failed to send enough value");
        require(address(this).balance >= reward, "Not enough reward");

        string[] memory imageURLs = fillScratchCard();
        numberOfPlays += 1;

        bool isWinner = checkForMatching(imageURLs);

         if (isWinner ) {
            (bool sent, ) = msg.sender.call{value: reward}("");
            require(sent, "Failed to send Ether");
        }

        emit CardResult(msg.sender, imageURLs, isWinner);
    }

    function fillScratchCard() internal view returns (string[] memory) {
        string[] memory imageURLs = new string[](9);

        for(uint i = 0; i < 9; i++){
            uint _randomNumber = uint(keccak256(abi.encode(block.timestamp, block.difficulty, msg.sender, i))) % imageTotal;
            imageURLs[i] = images[_randomNumber];
        }

        return imageURLs;
    }

    function checkForMatching(string[] memory imageURLs) internal returns (bool) {
        PlayerCard storage currentCard = cardlist[numberOfPlays];
        currentCard.id = numberOfPlays;

        for(uint i = 0; i < 9; i++){
            currentCard.sameImageCount[imageURLs[i]] += 1;
            if(currentCard.sameImageCount[imageURLs[i]] == 3) return true;
        }

        return false;
    }

    function getPrizePool() external view returns (uint) {
        return address(this).balance;
    }

    function getAdvertisement() external view returns (string[] memory) {
        return images;
    }

    /**
     * Function that allows the owner to withdraw all the Ether in the contract
     * The function can only be called by the owner of the contract as defined by the isOwner modifier
     */
    function withdraw() isOwner public {
        (bool success,) = owner.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    /**
     * Function that allows the contract to receive ETH
     */
    receive() external payable {}
}