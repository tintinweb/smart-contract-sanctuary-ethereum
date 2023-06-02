pragma solidity >=0.7.0 <0.9.0;

contract RockPaperScissors {
    struct Game{
        address _address;
        RockPaperScissors bet;
        address _oponnent;
        uint ammount;//in WEI
    }
    mapping(address /*Player1*/=> Game)newGames;
    mapping(address /*opponent*/=> address/*player1*/)waitingForOpponent;//Notify Oponnent who was challagned

        enum RockPaperScissors
        {
            Empty,//index: 0
            Rock, //call it with 1
            Paper,//call it with 2
            Scissors //....3
        } 

     address contractCreator;
     constructor(){
         contractCreator=msg.sender;
     }   
     bool private fireEvent;//To Test how much logging costs

    event GameEndedEvent(address indexed player1,RockPaperScissors player1Bet, address indexed player2,RockPaperScissors player2Bet,uint ammount,uint8 state);//state 1: player1 won 0 Draw 2 player2 won, 4 is deleted game
    event GameStartetEvent(address indexed player1,address indexed opponent,uint ammount);

    function humanVsComputer(RockPaperScissors mybet)public   {//no money against contract
        require(!(mybet==RockPaperScissors.Empty),"Empty bet not allowed");
        uint256 computerBet=generateRandomNumber();
        RockPaperScissors opponent=RockPaperScissors.Empty;
        if(computerBet==0){
            opponent=RockPaperScissors.Rock;
        }else if(computerBet==1){
            opponent=RockPaperScissors.Paper;
        }else{
            opponent=RockPaperScissors.Scissors;
        }
        //string memory gamestatus="Loose";
        uint8 state=2;//Player2 won or player1 loose
        if(mybet==RockPaperScissors.Rock && opponent==RockPaperScissors.Scissors 
            || mybet==RockPaperScissors.Paper && opponent==RockPaperScissors.Rock
            || mybet==RockPaperScissors.Scissors && opponent==RockPaperScissors.Paper){
          //  gamestatus="Winner";
             state=1;
         }else if(mybet==opponent){
            //gamestatus="Draw";
            state=0;
        }
            emit GameEndedEvent(msg.sender,mybet,address(0),opponent,0,state);//state !=4 means no delte event
    }

    
     function registerForNewGameWithOpponent(RockPaperScissors rockOrPaperOrSciccor, address opponent)public payable {
        require((newGames[msg.sender].bet==RockPaperScissors.Empty),"Allready waiting. Need an opponent Or unregister");
        require(!(rockOrPaperOrSciccor==RockPaperScissors.Empty),"Empty bet not allowed");
        require(opponent!=msg.sender,"You need to choose an other oponnent than you");
        require(opponent!=address(0),"Empty Address not allowed");
        newGames[msg.sender]=Game(msg.sender,rockOrPaperOrSciccor,opponent,newGames[msg.sender].ammount+msg.value);
        waitingForOpponent[opponent]=msg.sender;//toNotifyOponent


        emit GameStartetEvent(msg.sender,opponent,newGames[msg.sender].ammount);//Just for the UI to know who is waiting
    }
     function unregisterAndRefundEther() public {
        require(!(newGames[msg.sender].bet==RockPaperScissors.Empty),"No Game started");
            Game memory game=newGames[msg.sender];
            if( game.ammount>0){payable(msg.sender).transfer(newGames[msg.sender].ammount);}//transfer money back to player from contract
            if(game._oponnent!=address(0) ){//the old game had an opponnent
            waitingForOpponent[game._oponnent]=address(0);//delete
            }
        emit GameEndedEvent(msg.sender,game.bet,game._oponnent,RockPaperScissors.Empty,game.ammount,4);//State 4 is deleted Oponnent did not bet
        newGames[msg.sender]=Game(msg.sender,RockPaperScissors.Empty,address(0),0);//reset
    }
     
    function acceptChallange(address opponentAdr,RockPaperScissors rockOrPaperOrSciccor)public payable  {
        require(!(rockOrPaperOrSciccor==RockPaperScissors.Empty),"Empty bet not allowed. Choose Rock or Paper ir Scussirs");
        require(!(newGames[opponentAdr].bet==RockPaperScissors.Empty),"The Oponent did not start a new game");
        require(newGames[opponentAdr].ammount<=msg.value,"You need to pay the same as the other");
        require(newGames[opponentAdr]._oponnent==msg.sender || newGames[opponentAdr]._oponnent==address(0) ,"You are not allowed to play against him. He is wating for other oponnent");
        waitingForOpponent[msg.sender]=address(0);//delete from opponnets
        
        Game memory game=newGames[opponentAdr];

        uint8 state=2;
        if(rockOrPaperOrSciccor==RockPaperScissors.Rock && game.bet==RockPaperScissors.Scissors 
            || rockOrPaperOrSciccor==RockPaperScissors.Paper && game.bet==RockPaperScissors.Rock
            || rockOrPaperOrSciccor==RockPaperScissors.Scissors && game.bet==RockPaperScissors.Paper)
        {
                payable(msg.sender).transfer(newGames[msg.sender].ammount);  //  gamestatus="Winner";
                state=1;//player1 won
         }else if(rockOrPaperOrSciccor==game.bet){
            payable(msg.sender).transfer(msg.value);
            payable(game._oponnent).transfer(newGames[msg.sender].ammount);
            state=0;//   gamestatus="Draw";
        }else{
            payable(game._address).transfer(game.ammount*2); //  gamestatus="Loose";
        }
         emit GameEndedEvent(msg.sender,rockOrPaperOrSciccor,game._address,game.bet,game.ammount,state);

          newGames[opponentAdr].bet=RockPaperScissors.Empty;
          newGames[opponentAdr]._oponnent=address(0);

        
    }
     function getGameWhichWasStartedBy(address player1) public view returns ( Game memory){
        Game memory tmp=newGames[player1];
        tmp.bet=RockPaperScissors.Empty;//Make invisble
        return tmp;//with this information you can querry for Game
    }

    function getOpponnentFor(address player) public view returns (address){
        return newGames[player]._oponnent;
    }
    function getOpponentWhoWasChallangedBy(address player2) public view returns (address){
        return waitingForOpponent[player2];//with this information you can querry for Game
    }

     function generateRandomNumber()//Unasafe: HumanVsPC
        private
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender
                    )
                )
            ) % 3;
    }


}