//SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.9.0;


contract Lottery {

    address payable public rake_acc;
    address public owner; //person who deployed lottery
    address payable[] public players;

    uint256 public entryFee = .001 ether;

    address public theWinner;

    constructor(){
        //owner also stores the pot
        owner = msg.sender; //person who deployed contract's address
    }

    function setRakeAccount(address rake_address) public onlyOwner {
        require(msg.sender == owner, "You aren't the owner");

        rake_acc = payable(rake_address);
    }

    receive() external payable {
        require(msg.value == entryFee, "Must be .001 ether");
        uint rake = msg.value * 2 / 100;
        rake_acc.transfer(rake);

        players.push(payable(msg.sender));
    }

    function getBalance() external view returns(uint){
        return address(this).balance;
    }

    function getRakeAccount() public view returns(address)
    {
        return rake_acc;
    }

    //memory stored only temp storage for duration of function
    function getPlayers() public view returns (address payable[] memory)
    {
        return players;
    }


    function random() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function pickWinner() public returns (address){
        require(msg.sender == owner, "You aren't the owner");
        require(players.length >= 3, "Not enough participants");


        uint r = random();

        uint index = r % players.length;

        theWinner = address(players[index]);
    }

    function transferWinner(address winner) public onlyOwner{
        require(msg.sender == owner,"You aren't the owner");

        //this == current smart contract
        payable(winner).transfer(address(this).balance);

        //reset state of the contract
        players = new address payable[](0);

        players = new address payable[](0); //resets the lottery

    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

}