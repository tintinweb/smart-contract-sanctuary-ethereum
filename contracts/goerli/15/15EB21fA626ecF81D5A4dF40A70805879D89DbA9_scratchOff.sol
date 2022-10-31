/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract scratchOff {

    uint private lotteryFunds;
    uint private playerFunds;
    uint private playerTickets;
    address payable private owner;
    address[] private playerAddresses;
    mapping(address => Player) private players;

    struct Player {
        uint funds;
        uint tickets;
    }
 

    constructor(){
        lotteryFunds = address(this).balance;
        owner = payable(msg.sender);
        playerFunds = 0;
        playerTickets = 0;
        lotteryFunds = 0;
    }

    receive() external payable{}

    function fundAccount() public payable {
        //check if player has an account
        if(contains(msg.sender)) {
            //allow players to fund their accounts
            players[msg.sender].funds += msg.value;
            playerFunds += msg.value;
        } else { //create a new account
            require(msg.value >= .0005 gwei, ".0005 gwei required to open account");
            //charge .0005 eth to open an account
            Player memory _player = Player(msg.value - .0005 gwei,0);
            lotteryFunds += .0005 gwei;
            players[msg.sender] = _player;
            //add player's address to list of addresses to keep account
            playerAddresses.push(msg.sender);
            //add any funds over .0005 eth to total player funds
            playerFunds += players[msg.sender].funds;
        }
    }

    function buyTicket() public {
        //remove 2 eth from address account and add a ticket
        require(players[msg.sender].funds >= 2 gwei, "add gwei to your account");
        //don't allow a player to buy a ticket if the casino can't afford a payout
        require(lotteryFunds >= 1 gwei + playerTickets * 1 gwei, "casino closed for lack of funding");
        players[msg.sender].funds -= 2 gwei;
        players[msg.sender].tickets++;
        playerTickets++;
    }

    function play(int _num) public {
        require(players[msg.sender].tickets > 0, "No tickets!");  //check if player has a ticket
        lotteryFunds += 2 gwei;
        playerFunds -= 2 gwei;
        playerTickets--;
        players[msg.sender].tickets--;
        if(oracleNumber(_num) % 2 == 0) {
            players[msg.sender].funds += 3 gwei;
            playerFunds += 3 gwei;
            lotteryFunds -= 3 gwei;
        }
    }

    function takePayout() public {
        //check if player is owed more money than exists in the casino (shouldn't ever get executed)
        if(players[msg.sender].funds > address(this).balance){
            (bool success,) = msg.sender.call{value: address(this).balance}("");
            require(success, "Not paid");
            playerFunds -= address(this).balance;
            players[msg.sender].funds -= address(this).balance;
        //pay the player their balance
        } else {
            (bool success,) = msg.sender.call{value: players[msg.sender].funds}("");
            require(success, "Not paid");
            playerFunds -= players[msg.sender].funds;
            players[msg.sender].funds = 0;
        }
    }

    function fundCasino() public payable {
        //allow casino owner to fund the casino
        require(msg.sender == owner, "not owner");
        lotteryFunds += msg.value;
    }

    function takeProfits(uint amount) public {
        //allow casino owner to take money from the casino
        require(msg.sender == owner, "not the owner, buster");
        if(amount >= address(this).balance - playerFunds) { //Don't allow owner to take funds in player accounts
            (bool success,) = owner.call{value: address(this).balance - playerFunds}("");
            require(success, "Not paid");
            lotteryFunds = 0;
        } else {
            (bool success,) = msg.sender.call{value: amount}("");
            require(success, "Not paid");
            lotteryFunds -= amount;
        }
    }

    function closeCasino() public {
        //give owner all casino profits
        require(msg.sender == owner, "not the owner, buster");
        (bool success,) = owner.call{value: address(this).balance - playerFunds}("");
        require(success, "Not paid");
        lotteryFunds = 0;
        //return funds to all players and reimburse players for tickets already purchased
        for (uint i = 0; i < playerAddresses.length; i++) {
            (bool _success,) = playerAddresses[i].call{value: players[playerAddresses[i]].funds + players[playerAddresses[i]].tickets * 2 gwei}("");
             require(_success, "Not paid");
             playerFunds -= players[playerAddresses[i]].funds;
             players[playerAddresses[i]].funds = 0;
        }
    }
    //check if player already has an account
    function contains(address _address) private view returns(bool){
        for(uint i = 0; i < playerAddresses.length; i++){
            if(playerAddresses[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function getFunds() public view returns(uint) {
        return players[msg.sender].funds;
    }

    function getTickets() public view returns(uint){
        return players[msg.sender].tickets;
    }

    function getPlayers(address _address) public view returns(Player memory){
        require(msg.sender == owner, "only the owner can view players");
        return players[_address];
    }

    function getPlayerAddresses() public view returns(address[] memory){
        require(msg.sender == owner, "only the owner can view player addresses");
        return playerAddresses;
    }

    function getLotteryFunds() public view returns(uint){
        require(msg.sender == owner, "only owner can view that");
        return lotteryFunds/10**14;
    }

    function getPlayerfunds() public view returns(uint){
        require(msg.sender == owner, "only owner can view that");
        return playerFunds;
    }

    function oracleNumber(int _num) private pure returns(int){ //add oracle function here
        return _num;
    }
}