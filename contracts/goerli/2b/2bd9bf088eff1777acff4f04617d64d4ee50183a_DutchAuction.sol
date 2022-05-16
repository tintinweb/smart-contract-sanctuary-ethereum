/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


error InsufficientBalance(uint256 msgvalue);

//remove amount?
contract DutchAuction {
        event Payment(
        address _from,
        uint amount,
        uint price,
        string character,
        string obstacle,
        string surface
    );
    uint private constant PAUSE = 15;
    address payable public immutable seller;
    uint public immutable startingPrice;
    uint public immutable minimumPrice;
    uint public startAt;
    uint public pausedFor;
    string[] characters = ["rk2","grf"];
    string[] obstacles = ["wc1","elwa"];
    string[] surfaces = ["547","702"];

    constructor(
        uint _startingPrice,
        uint _minimumPrice
    ) {
        seller = payable(msg.sender);
        startingPrice = _startingPrice;
        minimumPrice = _minimumPrice;
        startAt = block.timestamp;
        pausedFor = startAt;
    }

    function startAuction() internal{
        startAt = block.timestamp;
        pausedFor = startAt + PAUSE;
    }

    function getPrice() public view returns (uint) {
        uint timeElapsed;
        if(pausedFor==startAt){
            timeElapsed = block.timestamp - startAt;
        }else{
            timeElapsed = block.timestamp - startAt - PAUSE;
        }
        require(timeElapsed>0, "auction is paused, please wait");
        return (startingPrice - minimumPrice)/(timeElapsed+1) + minimumPrice;
    }
    function isPaused() public view returns (bool) {
        uint timeElapsed;
        if(pausedFor==startAt){
            timeElapsed = block.timestamp - startAt;
        }else{
            timeElapsed = block.timestamp - startAt - PAUSE;
        }
        if(timeElapsed>0){
            return false;
        }else{
            return true;
        }
    }
    function compareStrings(string memory a, string memory b) public view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function containedIn(string memory target, string[] memory checklist) public view returns (bool) {
        for (uint i = 0; i < checklist.length; i++) {
            if (compareStrings(checklist[i], target)) {
                return true;
            }
        }
        return false;
    }

    function buy(string memory character, string memory obstacle, string memory surface) external payable {
        require(block.timestamp>=pausedFor, "auction not yet started");
        require(containedIn(character, characters), "invalid character choice");
        require(containedIn(obstacle, obstacles), "invalid obstacle choice");
        require(containedIn(surface, surfaces), "invalid surface choice");
        uint price = getPrice();
        if (msg.value < price)
            revert InsufficientBalance({
                msgvalue: msg.value
            });
        uint refund = msg.value - price;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        emit Payment(msg.sender, msg.value, price, character, obstacle, surface);
        startAuction();
        //selfdestruct(seller);
    }
}