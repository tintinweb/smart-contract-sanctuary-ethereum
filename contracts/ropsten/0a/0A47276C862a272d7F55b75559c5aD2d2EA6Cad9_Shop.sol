// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Shop {
    uint public playerCount = 0;
    // uint public pot = 0;
    address public dealer;
    Player[] public playerInGame;
    UPLINES[] public Uplines;
    mapping(address => UPLINES) public upline;
    mapping(address => Player) public players;
    uint public uplinesCount = 0;
    uint public uplinesEarns = 0;
    uint256[] public levelIncome = [12, 5, 3];
    enum Level {
        Novice,
        Inermadiate,
        Advanced
    }

    struct UPLINES {
        // address UserAddress;
        address refAccount;
    }
    struct Player {
        address UserAddress;
        address referralAddress;
        // Level playerLevel;
        string firstName;
        string lastName;
        uint createdTime;
    }

    constructor() {
        dealer = payable(msg.sender);
    }

    // add player
    function addPlayer(
        address referralAddress,
        string memory firstName,
        string memory lastName
    ) private {
        Player memory newPlayer = Player(
            msg.sender,
            referralAddress,
            firstName,
            lastName,
            block.timestamp
        );
        players[msg.sender] = newPlayer;
        playerInGame.push(newPlayer);
    }

    // get UnLevel
    function getUplines(address _me) private {
        UPLINES memory data = upline[_me];
        address ref = data.refAccount;

        UPLINES memory newUpline = UPLINES(ref);
        upline[msg.sender] = newUpline;
        Uplines.push(newUpline);

        if (uplinesCount <= 3) {
            getUplines(ref);
        }
        uplinesCount += 1;

        // require(uplinesCount <= 3 ," Uplines Hkalasssss!");

        //        if(uplinesCount >=3){
        // require(playerInGame.length > 0 ," Olala ");
        //           for(uint i=0; i< Uplines.length; i++){
        //             address currentPlayerAddress = Uplines[i];
        //             if(currentPlayerAddress != msg.sender)
        //             {
        //                 payable(currentPlayerAddress).transfer(msg.value * levelIncome[i] /100);
        //             }
        //         }

        // getUplines(ref);
        //        }
    }

    // Join Game
    function joinGame(
        address referralAddress,
        string memory firstName,
        string memory lastName
    ) public payable {
        // require(msg.value ==25 ether, "the Joining fee is 25 ether");
        // if(payable(dealer).send(msg.value)){
        addPlayer(referralAddress, firstName, lastName);

        playerCount += 1;
        // pot +=25;
        // }
        payable(dealer).transfer((msg.value * 80) / 100);

        getUplines(msg.sender);

        // require(playerInGame.length >0 ," Olala ");
        //   for(uint i=0; i< playerInGame.length; i++){
        //     address currentPlayerAddress = playerInGame[i].UserAddress;
        //     if(currentPlayerAddress != msg.sender)
        //     {

        //         payable(currentPlayerAddress).transfer(msg.value * levelIncome[i] /100);
        //     }
        // }
    }

    // get the unLevel addresses
    // function getUnLevel(address  _address) private  {
    //   Player memory  data = players[_address];
    //        address ref = data.referralAddress;
    // }

    // pay the winners
    // function payOutWinners() payable public{
    // require(msg.sender == dealer, "only the dealer can pay out the winners.!");
    // require(msg.value == pot * (1 ether));
    // uint payPerWinner1 = msg.value * 12/100;
    // uint payPerWinner2 = msg.value * 5/100;
    // uint payPerWinner3 = msg.value * 3/100;
    // uint payPerWinner=0;
    // for(uint i=0; i< playerInGame.length; i++){
    //     address currentPlayerAddress = playerInGame[i].playerAddress;
    //     if(currentPlayerAddress != msg.sender)
    //     {

    //         payable(currentPlayerAddress).transfer(msg.value * levelIncome[i] /100);
    //     }
    // }
    // }
}