//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "IERC20.sol";
import "VRFConsumerBase.sol";
import "LinkTokenInterface.sol";

contract Lottery30 is VRFConsumerBase{

    address[] public allowedNetworks = [0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06, 0x404460C6A5EdE2D891e8297795264fDe62ADBB75];

    //BNB Chain Testnet
    //Info - Chainlink Oracle
    uint public fee = 100000000000000000;
    uint public minimumAccountBalanceLink = 2 ether; 
    bytes32 public keyhash = 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186;
    address public link = 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06;
    address public vrfCoordinator = 0xa555fC018435bef5A13C6c6870a9d4C11DEC329C;

    struct Request{
        bytes32 requestId;
        uint dateRequested;    
    }

    //Info - Payment Method
    address public constant usdtAddress = 0x337610d27c682E347C9cD60BD4b3b107C9d34dDd;
    IERC20 public immutable usdt;

    //Ownership
    address payable public immutable owner;

    //Expenditure
    address public constant expenditureAddress = 0x60c3B0d5701FCd79E60B974CF0469364aBc71C23;
    uint8 public expenditure;

    //GAME
    uint[10] listOfGameNumbers = [1,2,3,4,5,6,7,8,9,10];//to change
    uint[] auxListOfGameNumbers;
    lottoGame[] public lottoGames;
    uint public constant minimumGameValue = 1;
    uint public constant maximumGameValue = 10;
    uint public betPrice = 1*10**18 wei;
    uint public totalTicketsSold = 0;

    //Prize Percentage for hit numbers 
    uint public prizePercentageNumbers_6 = 60;
    uint public prizePercentageNumbers_5 = 20;
    uint public prizePercentageNumbers_4 = 20;

    //Game States
    enum stateLottery{
        Created,
        Open,
        Closed, 
        Finalized
    }

    //Game Properties
    struct lottoGame{
        stateLottery state;
        uint date;
        uint[] listWinners;
        bool firstTicket;
        uint firstTicketNumber;
        uint lastTicketNumber;
        bool doneWinnersProcessing;
        bool doneWinnersPaymentProcessing;
        bool startNumbersDraw;
        uint dateStartNumbersDraw; 
        bool endedNumbersDraw;
        uint[6] sortedNumbers;
        bytes32[6] requestsId;
        uint counterOfSortedNumbers;
    }

    Request[] listOfRequests;

    //Info about bet placed
    mapping( uint => address) public ticketToBuyer;//unique ticket to buyer address
    mapping( uint => uint[6]) public ticketToChosenNumbers;//unique ticket to choosen numbers
    mapping( uint => uint) public ticketToGameId;//unique ticket to mega lotto game id
    mapping( uint => uint) public ticketToHitNumbers;//unique ticket to hit numbers in respective game
    mapping( uint => bool) public ticketIsWinner;//unique ticket is winner in its respective game
    mapping( uint => bool) public ticketIsProcessedAlternativeMethod;//unique ticket was processed [alternative method]
    mapping( uint => bool) public ticketWasRewarded;//unique ticket was rewarded

    //Events
    event AddNewGame(uint gameId);
    event OpenGameToBet(uint gameId);
    event CloseGameToBet(uint gameId);
    event ChangedTicketPrice(uint newPrice);
    event ChangedExpenditure(uint newExpenditure);
    event ChangedPrizePorcentage(uint hitNumbers, uint value);
    event ReceivedBetOnMega(uint[6] numbers, address purchaser, uint gameNumber);
    event StartGenerateRandomNumbers();
    event FinishedGenerateRandomNumbers();
    event PaymentDone(address payer, uint amount, uint date);
    event RequestedRequest(Request request);
    event DrawnNumber(uint number, uint position);
    event NewWinner(uint ticket, address winner, uint numberOfHits);
    event Prizes(uint prize_6_numbers, uint prize_5_numbers, uint prize_4_numbers);
    event PrizesToEachWinner(uint prize_6_numbers, uint prize_5_numbers, uint prize_4_numbers);
    event WinnersNumbers(uint winners_6_numbers, uint winners_5_numbers, uint winners_4_numbers);
    event FinalizedWinnersProcessing(uint gameId, uint date);
    event FinalizedPaymentProcessing(uint gameId, uint date);
    event FinalizeGame(uint gameId, uint date);
    event TransferedFundsPrize(address newContract);
    event EndsContract();

    //Classe's Constructor
    constructor() payable VRFConsumerBase(vrfCoordinator,link){
        //define owner
        owner = payable(msg.sender);
        //set crypto to pay
        usdt = IERC20(usdtAddress); 
        //set expenditure percentage
        expenditure = 5;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only allowed to the contract owner!");
        _;
    }

    modifier onlyAllowedAddress(address linkContractAddress){
        require(linkContractAddress==allowedNetworks[0],"Only allowed Link contract address");
        _;
    }

    //Returns funds in Link from the contract
    function getBalanceContract(address _addr) public view onlyAllowedAddress(_addr) returns (uint) {
        return LinkTokenInterface(_addr).balanceOf(address(this));
    }

    //Transfer funds to the owner in case the contract version changes
    function transferFundsLink(address _addr) public payable onlyOwner onlyAllowedAddress(_addr) returns (bool){
        return LinkTokenInterface(_addr).transfer(owner,getBalanceContract(_addr));
    }

    //Returns funds in USDT from the contract
    function balanceUsdt() public view returns(uint) {
        return usdt.balanceOf(address(this));
    }

    function addNewGame() public onlyOwner{
        //Don't permit create another game before last game is over
        if(lottoGames.length != 0){
            require(lottoGames[lottoGames.length-1].state == stateLottery.Finalized, "The last game is not over!");
        }
        //New game parameterization
        uint[] memory emptyWinnersArray;
        uint[6] memory emptySortedNumbers = [type(uint).max, type(uint).max, type(uint).max, type(uint).max, type(uint).max, type(uint).max];
        bytes32 zero = 0x0000000000000000000000000000000000000000000000000000000000000000;
        bytes32[6] memory emptylistRequestId = [zero, zero, zero, zero, zero, zero];
        lottoGames.push(lottoGame(stateLottery.Created, block.timestamp, emptyWinnersArray,
            false, type(uint).max, type(uint).max, false, false, false, 0, false, emptySortedNumbers, emptylistRequestId, 0));

        emit AddNewGame(lottoGames.length-1);
    }

    //Free the public to bet
    function openGameToBet() public onlyOwner{
        //Just permit open game to public if the state is Created
        require(lottoGames.length > 0, "No one game registered");
        require(lottoGames[lottoGames.length-1].state == stateLottery.Created, "The last game has already been opened!");
        lottoGames[lottoGames.length-1].state = stateLottery.Open;

        emit OpenGameToBet(lottoGames.length-1);
    }

    //Lock the public to bet
    function closeGameToBet() public onlyOwner{
        //Just permit to close the game if state is Open
        require(lottoGames.length > 0, "No one game registered");
        require(lottoGames[lottoGames.length-1].state == stateLottery.Open,"The last game state is not 'Open'!");
        lottoGames[lottoGames.length-1].state = stateLottery.Closed;

        emit CloseGameToBet(lottoGames.length-1);
    }

    //Bet on Mega Game
    function betOnMegaGame(uint firstNumber, uint secondNumber, uint thirdNumber,
        uint fourthNumber, uint fifthNumber, uint sixthNumber) public returns(uint[6] memory){

        //All numbers must be on the range
        require((firstNumber >= minimumGameValue && firstNumber <= maximumGameValue)&&
            (secondNumber >= minimumGameValue && secondNumber <= maximumGameValue)&&
            (thirdNumber >= minimumGameValue && thirdNumber <= maximumGameValue)&&
            (fourthNumber >= minimumGameValue && fourthNumber <= maximumGameValue)&&
            (fifthNumber >= minimumGameValue && fifthNumber <= maximumGameValue)&&
            (sixthNumber >= minimumGameValue && sixthNumber <= maximumGameValue),"At least one of the numbers is out of range!");
        
        //All numbers must be different
        uint[6] memory chosenNumbers = [firstNumber, secondNumber, thirdNumber, fourthNumber, fifthNumber, sixthNumber];
        //Sort array 
        chosenNumbers = bubbleSort(chosenNumbers);
        require((chosenNumbers[0]!=chosenNumbers[1])&&
            (chosenNumbers[1]!=chosenNumbers[2])&&
            (chosenNumbers[2]!=chosenNumbers[3])&&
            (chosenNumbers[3]!=chosenNumbers[4])&&
            (chosenNumbers[4]!=chosenNumbers[5]),"There are equal numbers, this is not allowed!");

        //There must be a game available for betting
        require(lottoGames[lottoGames.length-1].state == stateLottery.Open,"There aren't available games!");

        //Allowance amount must be greater than betPrice
        require(usdt.allowance(msg.sender, address(this)) >= betPrice, "The allowance must be greater than the ticket value." );

        //Calls the ERC20's contract to make payment
        usdt.transferFrom(msg.sender, address(this), betPrice);
        //Transfer of expenditure
        usdt.transfer(expenditureAddress, betPrice*expenditure/100);

        //Emits events regarding the payment and game performed
        emit PaymentDone(msg.sender, betPrice, block.timestamp);
        emit ReceivedBetOnMega(chosenNumbers, msg.sender, lottoGames.length - 1);

        //Updates the tickets belonging to the current game
        if(lottoGames[lottoGames.length-1].firstTicket == true){
            lottoGames[lottoGames.length-1].lastTicketNumber = totalTicketsSold;
        }
        else if(lottoGames[lottoGames.length-1].firstTicket == false){
            lottoGames[lottoGames.length-1].firstTicket = true;
            lottoGames[lottoGames.length-1].firstTicketNumber = totalTicketsSold;
            lottoGames[lottoGames.length-1].lastTicketNumber = totalTicketsSold;
        }
        
        //Feed database
        ticketToBuyer[totalTicketsSold] = msg.sender;
        ticketToChosenNumbers[totalTicketsSold] = chosenNumbers;
        ticketToGameId[totalTicketsSold] = lottoGames.length - 1;

        //Update ticket
        totalTicketsSold++;

        return chosenNumbers;
    }

    //Organizes choosen numbers
    function bubbleSort(uint[6] memory chosenNumbers) public pure returns(uint[6] memory ){
        
        uint length =  chosenNumbers.length;

        for(uint i=0; i<length-1; i++){
            for(uint j=0; j<length-1; j++){
                if(chosenNumbers[j] > chosenNumbers[j+1]){
                    uint current_value = chosenNumbers[j];
                    chosenNumbers[j] = chosenNumbers[j+1];
                    chosenNumbers[j+1] = current_value;
                }
            }
        }
        return chosenNumbers;
    }

    //Method responsible for drawing numbers
    function generateRandomNumbers() public onlyOwner{
        //Just permit to generate random numbers of game is state is Closed
        require(lottoGames.length > 0, "No one game registered");
        require(lottoGames[lottoGames.length-1].state == stateLottery.Closed &&
            lottoGames[lottoGames.length-1].startNumbersDraw == false, "The last game state must be 'Closed' and and numbers generation process not started");
        
        uint balanceLink;
        balanceLink = getBalanceContract(link);
        require(balanceLink >= minimumAccountBalanceLink, "The contract does not have the minimum of link token to start the operation");

        //Set the beginning of the process and saves timestamp
        lottoGames[lottoGames.length-1].startNumbersDraw =  true;
        lottoGames[lottoGames.length-1].dateStartNumbersDraw = block.timestamp;    

        //Reset auxiliar array to pick the numbers
        delete auxListOfGameNumbers;
        for(uint i=0; i<listOfGameNumbers.length; i++){
            auxListOfGameNumbers.push(listOfGameNumbers[i]);
        }

        emit StartGenerateRandomNumbers();
        //Reset list of requests and fill with new requests
        delete listOfRequests;
        for(uint i=0; i<6; i++){//tem que retornar aqui
            Request memory request = Request(requestRandomness(keyhash, fee), block.timestamp);
            listOfRequests.push(request);
            emit RequestedRequest(request);
        }
    }

    //Executes when returning random number by oracle
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {   
        //it only allows receiving a random number by oracle if 
        //the random number generation process is open and limited to 6 numbers
        require(lottoGames.length > 0, "No one game registered");
        require(lottoGames[lottoGames.length-1].state == stateLottery.Closed &&
            lottoGames[lottoGames.length-1].startNumbersDraw == true &&
            lottoGames[lottoGames.length-1].endedNumbersDraw == false &&
            lottoGames[lottoGames.length-1].counterOfSortedNumbers < 6,
            "The last game state must be 'Closed', numbers generation process started");

        //Checks if the request id is in the list
        lottoGame storage auxLastLottoGame;
        auxLastLottoGame = lottoGames[lottoGames.length-1];
        for(uint i=0; i< listOfRequests.length; i++){
            if(listOfRequests[i].requestId == _requestId){ 
                uint sortedNumber = _randomness%auxListOfGameNumbers.length;
                auxLastLottoGame.sortedNumbers[auxLastLottoGame.counterOfSortedNumbers] = auxListOfGameNumbers[sortedNumber];
                auxLastLottoGame.requestsId[auxLastLottoGame.counterOfSortedNumbers] = _requestId;
                emit DrawnNumber(auxListOfGameNumbers[sortedNumber], auxLastLottoGame.counterOfSortedNumbers+1);

                //Remove sorted number from possibilities
                removeItemFromPossibilitiesNumbersArray(sortedNumber);
                
                //Updates the number of numbers drawn
                auxLastLottoGame.counterOfSortedNumbers++;
            }
        }

        //Ends random number generation process
        if(auxLastLottoGame.counterOfSortedNumbers==6){
            auxLastLottoGame.endedNumbersDraw = true;
            emit FinishedGenerateRandomNumbers();
        }
    }

    //Removes number from possibilities array
    function removeItemFromPossibilitiesNumbersArray(uint _index) internal{
        require(_index < auxListOfGameNumbers.length, "index out of bound");
        for (uint i = _index; i < auxListOfGameNumbers.length -1; i++) {
            auxListOfGameNumbers[i] = auxListOfGameNumbers[i+1];
        }
        auxListOfGameNumbers.pop();
    }

    //Does another request in delayed case (5min)
    function doNewRequestOracle() public onlyOwner(){
        require(lottoGames.length > 0, "No one game registered");
        require(lottoGames[lottoGames.length-1].state == stateLottery.Closed &&
            lottoGames[lottoGames.length-1].startNumbersDraw == true &&
            lottoGames[lottoGames.length-1].endedNumbersDraw == false &&
            block.timestamp > lottoGames[lottoGames.length-1].dateStartNumbersDraw + 300,
            "The last game state must be 'Closed', numbers generation process started, delayed by more than 5 minutes and not finished");

        uint balanceLink;
        balanceLink = getBalanceContract(link);
        require(balanceLink >= minimumAccountBalanceLink, "The contract does not have the minimum of link token to start the operation");

        //Request another time, reason: no response
        Request memory request = Request(requestRandomness(keyhash, fee), block.timestamp);
        listOfRequests.push(request);
        emit RequestedRequest(request);
    }

    //Gets last draw numbers from last game
    function getLastGameDrawnNumbers() public view returns(uint[6] memory){
        require(lottoGames.length > 0, "No one game registered");
        return(lottoGames[lottoGames.length-1].sortedNumbers);
    }

    //Gets draw numbers from game by index
    function getGameDrawnNumbers(uint _index) public view returns(uint[6] memory){
        require(lottoGames.length > 0, "No one game registered");
        require(_index < lottoGames.length, "index out of bound");
        return(lottoGames[_index].sortedNumbers);
    }

    //Gets list of requested requests from last game
    function getLastGameListOfResquests() public view returns(bytes32[6] memory){
        require(lottoGames.length > 0, "No one game registered");
        return(lottoGames[lottoGames.length-1].requestsId);
    }

    //Gets list of requested requests from game by index
    function getGameListOfResquests(uint _index) public view returns(bytes32[6] memory){
        require(lottoGames.length > 0, "No one game registered");
        require(_index < lottoGames.length, "index out of bound");
        return(lottoGames[_index].requestsId);
    }

    //Calculates game winners
    function processWinners() public onlyOwner{
        //Just permit to process the winners of game if the state is Closed
        require(lottoGames.length > 0, "No one game registered");
        require(lottoGames[lottoGames.length-1].state == stateLottery.Closed && 
            lottoGames[lottoGames.length-1].startNumbersDraw == true &&
            lottoGames[lottoGames.length-1].endedNumbersDraw == true &&
            lottoGames[lottoGames.length-1].counterOfSortedNumbers == 6 &&
            lottoGames[lottoGames.length-1].doneWinnersProcessing == false, "The last game state must be 'Closed' and uncalculated winners!");

        //Do the Processing 
        lottoGame storage auxLastLottoGame;
        auxLastLottoGame = lottoGames[lottoGames.length-1];

        if(auxLastLottoGame.firstTicket==false){
            //Do nothing
        }else{
            for(uint i=auxLastLottoGame.firstTicketNumber; i<=auxLastLottoGame.lastTicketNumber; i++){
                //Checks each bet
                uint[6] memory drawnNumbers = auxLastLottoGame.sortedNumbers;
                uint hitNumbers = 0;
                
                for(uint j=0; j<6; j++){
                    for(uint k=0; k<6; k++){
                        if(ticketToChosenNumbers[i][j]==drawnNumbers[k])
                        hitNumbers++;
                    }
                }

                ticketToHitNumbers[i] = hitNumbers;
                //Condition to be considered a winner
                if(hitNumbers>=4){
                    auxLastLottoGame.listWinners.push(i);
                    ticketIsWinner[i]=true;
                    emit NewWinner(i, ticketToBuyer[i], hitNumbers);
                }
            }
        }

        //Set status of processing
        auxLastLottoGame.doneWinnersProcessing = true;    
        emit FinalizedWinnersProcessing(lottoGames.length-1, block.timestamp);
    }

    //Calculates if specific ticket from last game is a winner
    function processTickets(uint ticket0, uint ticket1) public onlyOwner{
        
        lottoGame storage auxLastLottoGame;
        auxLastLottoGame = lottoGames[lottoGames.length-1];
        
        //Just permit to process the winners of game if the state is Closed
        require(lottoGames.length > 0, "No one game registered");
        require(auxLastLottoGame.state == stateLottery.Closed && 
            auxLastLottoGame.startNumbersDraw == true &&
            auxLastLottoGame.endedNumbersDraw == true &&
            auxLastLottoGame.counterOfSortedNumbers == 6 &&
            auxLastLottoGame.doneWinnersProcessing == false, "The last game state must be 'Closed' and uncalculated winners!");
        require(lottoGames[lottoGames.length-1].firstTicket == true &&
            ticket0>=auxLastLottoGame.firstTicketNumber &&
            ticket0<=auxLastLottoGame.lastTicketNumber &&
            ticket1>=auxLastLottoGame.firstTicketNumber &&
            ticket1<=auxLastLottoGame.lastTicketNumber, "The ticket must be emmited in the last game");
        require(ticket0<=ticket1, "Interval [ticket0,ticket1], ticket0<=ticket11");

        //require(ticketIsWinner[ticket]==false, "The ticket cannot be considered a winning ticket");

        //Do the Processing 
        uint[6] memory drawnNumbers = auxLastLottoGame.sortedNumbers;
        uint hitNumbers;
        
        for(uint i=ticket0; i<=ticket1; i++){
            if(ticketIsProcessedAlternativeMethod[i]==true || ticketIsWinner[i]==true){

            }else{
                //Checks each bet
                hitNumbers = 0;

                for(uint j=0; j<6; j++){
                    for(uint k=0; k<6; k++){
                        if(ticketToChosenNumbers[i][j]==drawnNumbers[k])
                        hitNumbers++;
                    }
                }

                ticketToHitNumbers[i] = hitNumbers;
                //Condition to be considered a winner
                if(hitNumbers>=4){
                    auxLastLottoGame.listWinners.push(i);
                    ticketIsWinner[i]=true;
                    emit NewWinner(i, ticketToBuyer[i], hitNumbers);
                }
                ticketIsProcessedAlternativeMethod[i]=true;
            }
        }
    }

    //Finalizes the winners process by alternative method
    function finalizeWinnersProcessing() public onlyOwner returns(bool){
        lottoGame storage auxLastLottoGame;
        auxLastLottoGame = lottoGames[lottoGames.length-1];
        
        //Just permit to process the winners of game if the state is Closed
        require(lottoGames.length > 0, "No one game registered");
        require(auxLastLottoGame.state == stateLottery.Closed && 
            auxLastLottoGame.startNumbersDraw == true &&
            auxLastLottoGame.endedNumbersDraw == true &&
            auxLastLottoGame.counterOfSortedNumbers == 6 &&
            auxLastLottoGame.doneWinnersProcessing == false, "The last game state must be 'Closed' and uncalculated winners!");

        bool doneWinnersProcessing = false;
        if(auxLastLottoGame.firstTicket == false){
            auxLastLottoGame.doneWinnersProcessing = true;
            doneWinnersProcessing = true;
        }else{
            uint firstTicketNumber = auxLastLottoGame.firstTicketNumber;
            uint lastTicketNumber = auxLastLottoGame.lastTicketNumber;

            //Traverses the entire array
            for(uint i=firstTicketNumber; i<=lastTicketNumber; i++){
                if(ticketIsProcessedAlternativeMethod[i]==false){
                    return doneWinnersProcessing;
                }
            }
            doneWinnersProcessing = true;
            auxLastLottoGame.doneWinnersProcessing = true;
            emit FinalizedWinnersProcessing(lottoGames.length-1, block.timestamp);
        }
        return doneWinnersProcessing;
    }

    //Gets list of winners from last game
    function getsLastGameListOfWinners() public view returns(uint[] memory){
        require(lottoGames.length > 0, "No one game registered");
        return(lottoGames[lottoGames.length-1].listWinners);
    }

    //Gets list of winners from game by index
    function getGameListOfWinners(uint _index) public view returns(uint[] memory){
        require(lottoGames.length > 0, "No one game registered");
        require(_index < lottoGames.length, "index out of bound");
        return(lottoGames[_index].listWinners);
    }

    //Processes payment to winners
    function payWinners() public onlyOwner{
        //Just permit to process the winners of game if the state is Closed and calculated winners 
        require(lottoGames.length > 0, 
            "No one game registered");
        require(lottoGames[lottoGames.length-1].state == stateLottery.Closed && 
            lottoGames[lottoGames.length-1].doneWinnersProcessing == true &&
            lottoGames[lottoGames.length-1].doneWinnersPaymentProcessing == false,
            "The last game state must be 'Closed' and calculated winners!");
        require(prizePercentageNumbers_4 + prizePercentageNumbers_5 + prizePercentageNumbers_6 == 100,
            "The sum of the percentages must be igual to 100%");

        //Calculates the prizes
        uint full_Prize = balanceUsdt();
        //First pays to 6 numbers
        uint prize_6 = full_Prize*prizePercentageNumbers_6/100; 
        //Then pays to 5 numbers
        uint prize_5 = full_Prize*prizePercentageNumbers_5/100;
        //Then pays to 4 numbers
        uint prize_4 = full_Prize*prizePercentageNumbers_4/100;
        
        //Announces prize values
        emit Prizes(prize_6, prize_5, prize_4);

        lottoGame storage auxLastLottoGame;
        auxLastLottoGame = lottoGames[lottoGames.length-1];

        uint counterNumberWinnersWith4numbers = 0;
        uint counterNumberWinnersWith5numbers = 0;
        uint counterNumberWinnersWith6numbers = 0;
        //Counter how many winners in each box
        for(uint i=0; i<auxLastLottoGame.listWinners.length; i++){
            uint hitNumbers = ticketToHitNumbers[auxLastLottoGame.listWinners[i]];
            if(hitNumbers==6){
                counterNumberWinnersWith6numbers++;
            }else if(hitNumbers==5){
                counterNumberWinnersWith5numbers++;
            }else if(hitNumbers==4){
                counterNumberWinnersWith4numbers++;
            }
        }

        //Emits how many winners
        emit WinnersNumbers(counterNumberWinnersWith6numbers, counterNumberWinnersWith5numbers, counterNumberWinnersWith4numbers);

        uint prizeToWinnerWith6Numbers = 0;
        uint prizeToWinnerWith5Numbers = 0;
        uint prizeToWinnerWith4Numbers = 0;

        if(counterNumberWinnersWith6numbers == 0){
            prizeToWinnerWith6Numbers = 0;
        }else{
            prizeToWinnerWith6Numbers = prize_6/counterNumberWinnersWith6numbers;
        }

        if(counterNumberWinnersWith5numbers == 0){
            prizeToWinnerWith5Numbers = 0;
        }else{
            prizeToWinnerWith5Numbers = prize_5/counterNumberWinnersWith5numbers;
        }

        if(counterNumberWinnersWith4numbers == 0){
            prizeToWinnerWith4Numbers = 0;
        }else{
            prizeToWinnerWith4Numbers = prize_4/counterNumberWinnersWith4numbers;
        }

        emit PrizesToEachWinner(prizeToWinnerWith6Numbers, prizeToWinnerWith5Numbers, prizeToWinnerWith4Numbers);

        //Do the Payment
        for(uint i=0; i<auxLastLottoGame.listWinners.length; i++){
            uint hitNumbers = ticketToHitNumbers[auxLastLottoGame.listWinners[i]];
            address winner = ticketToBuyer[auxLastLottoGame.listWinners[i]];

            //Makes payment if it has not yet been made according to the hit numbers.
            if(ticketWasRewarded[auxLastLottoGame.listWinners[i]] == false){

                if(hitNumbers==6){
                    usdt.transfer(winner, prizeToWinnerWith6Numbers);
                    ticketWasRewarded[auxLastLottoGame.listWinners[i]] = true;
                    emit PaymentDone(winner, prizeToWinnerWith6Numbers, block.timestamp);
                }else if(hitNumbers==5){
                    usdt.transfer(winner, prizeToWinnerWith5Numbers);
                    emit PaymentDone(winner, prizeToWinnerWith5Numbers, block.timestamp);
                    ticketWasRewarded[auxLastLottoGame.listWinners[i]] = true;
                }else if(hitNumbers==4){
                    usdt.transfer(winner, prizeToWinnerWith4Numbers);
                    emit PaymentDone(winner, prizeToWinnerWith4Numbers, block.timestamp);
                    ticketWasRewarded[auxLastLottoGame.listWinners[i]] = true;
                }
            }
        }

        //Set status of processing
        lottoGames[lottoGames.length-1].doneWinnersPaymentProcessing = true;
        emit FinalizedPaymentProcessing(lottoGames.length -1, block.timestamp);
    }

    //Changes the prize porcentagem
    function changePrizePorcentagem(uint index, uint percentageValue) public onlyOwner{
        require(index == 4 || index == 5 || index == 6," Index must be in interval [4,6]");
        require(percentageValue >= 0 && percentageValue <= 100, "Percentage value must be in interval [0,100]");

        if(index == 4){
            prizePercentageNumbers_4 = percentageValue;
        }else if(index == 5){
            prizePercentageNumbers_5 = percentageValue;
        }else if(index == 6){
            prizePercentageNumbers_6 = percentageValue;
        }

        emit ChangedPrizePorcentage(index, percentageValue);
    } 

    //Ends current game
    function finalizeGame() public onlyOwner{
        //Just permit to finalize the game if the state is Closed and processed/paid winners
        require(lottoGames.length > 0, "No one game registered");
        require(lottoGames[lottoGames.length-1].state == stateLottery.Closed &&
            lottoGames[lottoGames.length-1].doneWinnersProcessing == true &&
            lottoGames[lottoGames.length-1].doneWinnersPaymentProcessing == true, "The last game state must be 'Closed', raised the winners and paid them!");
        lottoGames[lottoGames.length-1].state = stateLottery.Finalized;

        emit FinalizeGame(lottoGames.length -1, block.timestamp);
    }
    
    //Changes bet price
    function changeBetPrice(uint newBetPrice) public onlyOwner{
        require(newBetPrice>= 1*10**18, "The minimum price for bet is 1 USDT");
        betPrice = newBetPrice;
        emit ChangedTicketPrice(newBetPrice);
    }

    //Changes expenditure percentage
    function changeExpenditurePercentage(uint8 newExpenditurePercentage) public onlyOwner{
        require(newExpenditurePercentage>= 5 && newExpenditurePercentage<=50, "The expenditure percentage must be in interval [5,50]");
        expenditure = newExpenditurePercentage;
        emit ChangedExpenditure(newExpenditurePercentage);
    }

    //Tranfers Funds Prize - Needs announcement before and say the new Contract that will receive the Prize
	function transfersFundsPrize(address newContract) public onlyOwner{
        usdt.transfer(newContract, balanceUsdt());
        emit TransferedFundsPrize(newContract);
    }

    //Ends contract
    function finalize() public onlyOwner {
        usdt.transfer(owner, balanceUsdt());
        emit EndsContract();
        selfdestruct(owner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "LinkTokenInterface.sol";

import "VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}