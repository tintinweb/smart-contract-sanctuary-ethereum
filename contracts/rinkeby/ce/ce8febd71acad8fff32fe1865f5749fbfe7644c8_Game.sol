/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint balance);

    function ownerOf(uint tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint tokenId) external;

    function safeTransferFrom(address from, address to, uint tokenId, string calldata data) external;

    function transferFrom(address from, address to, uint tokenId) external;

    function approve(address to, uint tokenId) external;

    function getApproved(uint tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract Game {

    address private constant goldNFT = 0x177AEE0430fec334628540bF67dEf93722FE2003;
    address private constant silverNFT = 0xDd13B1327E331dbF270D2E90BcC723a2AdC24ed2;
    address private constant bronzeNFT = 0x906f0f22fD629982ac9d677661832d67Ed718420;
    address private constant ticketNFT = 0x5e3F4F5321de374f971357D03Ebd6b80a3516549;
    
    uint goldcurr = 1;
    uint silvercurr = 1;
    uint bronzecurr = 1;

    event lotteryNumber(uint one, uint two, uint three, uint four, uint five, uint six);

    address owner;
    address[] player;
    mapping (address => bool) isPlayer;
    mapping (address => uint[6]) person;
    mapping (address => uint) public win;

    constructor (address _owner) {
        owner = _owner;
    }

    modifier onlyowner() {
        require(msg.sender == owner, "Permission Error");
        _;
    }  

    modifier onlyplayer() {
        require(isPlayer[msg.sender] == true, "You are not player !");
        _;
    }  

    function join(uint ticketID) public returns (bool) {
        require(IERC721(ticketNFT).isApprovedForAll(msg.sender, address(this)) == true, "You haven't approved !");
        IERC721(ticketNFT).transferFrom(msg.sender, owner, ticketID);
        player.push(msg.sender);
        isPlayer[msg.sender] = true;
        return true;
    }

    function playerList() public view returns (address[] memory){
        return player;
    }

    function bet(uint one, uint two, uint three, uint four, uint five, uint six) public onlyplayer {
        uint[6] memory temp;
    
        temp[0] = one; 
        temp[1] = two; 
        temp[2] = three; 
        temp[3] = four; 
        temp[4] = five; 
        temp[5] = six;

        person[msg.sender] = temp;
    }

    function getnumber() public view returns (uint[6] memory){
        return person[msg.sender];
    }

    function random(uint nonce) private view returns(uint) {
        return (uint(keccak256(abi.encodePacked(nonce, block.timestamp, block.difficulty)))) % 20+1;
    }


    function lottery() public onlyowner {
        uint nonce;
        uint one = random(nonce++); 
        uint two = random(nonce++);
        uint three = random(nonce++);
        uint four = random(nonce++);
        uint five = random(nonce++);
        uint six = random(nonce++);

        emit lotteryNumber(one, two, three, four, five, six);

        for (uint i = 0; i < player.length; i++) {

            uint count = 0;
            address user = player[i];

            for (uint j = 0; j < 6; j++) {
                if (person[user][j] == one || person[user][j] == two || person[user][j] == three || person[user][j] == four || person[user][j] == five || person[user][j] == six)
                    count++;
            }
            win[user] = count; 

        }

        for (uint i = 0; i < player.length; i++) {

            address user = player[i];

            if (win[user] == 0)
                continue;
            else if (win[user] == 1) {
                IERC721(bronzeNFT).transferFrom(owner, user, bronzecurr++);
            } else if (win[user] == 2) {
                IERC721(silverNFT).transferFrom(owner, user, silvercurr++);
            } else {
                IERC721(goldNFT).transferFrom(owner, user, goldcurr++);
            }

        }

    }

}