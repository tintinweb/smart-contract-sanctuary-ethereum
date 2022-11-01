import "./Ownable.sol";
pragma solidity 0.5.12;


contract CoinToss is Ownable {

    struct Bet {
    // Creates a Bet that contains id, playerBet and playerChoice

        uint id;
        address playerAddress;
        uint playerBet;
        uint playerChoice;
    }

    event BetPlaced(uint playerBet, uint playerChoice);

    uint internal balance;
    uint public betAmount;

    mapping(address => Bet) private bets;
    //
    address[] private players;
    //

    modifier onlyBetOwner() {
        require(msg.sender == bets[msg.sender].playerAddress);
        _;
    }

    /*  PUBLIC FUNCTIONS  */
    function placeBet(uint playerBet, uint playerChoice) public payable {
        /* function makes a call to metaMask and signs for the transaction of the playerBet */
        require(playerChoice == 0 || playerChoice == 1, "Choice must be 0 or 1.");
        require(msg.value >= 0.00001 ether);
        betAmount += msg.value;

        Bet memory newBet;
        newBet.playerAddress = msg.sender;
        newBet.playerBet = playerBet;
        newBet.playerChoice = playerChoice;

        insertBet(newBet);
        players.push(msg.sender);

        assert(
            keccak256(
                abi.encodePacked(
                    bets[msg.sender].playerBet,
                    bets[msg.sender].playerChoice
                )
            )
            ==
            keccak256(
                abi.encodePacked(
                    newBet.playerBet,
                    newBet.playerChoice
                )
            )
        );

        emit BetPlaced(newBet.playerBet, newBet.playerChoice);
    }

    function checkResult() public payable returns(bool) {
        // check if result and playerChoice are the same number.

        uint playerChoice = bets[msg.sender].playerChoice;
        uint result = random();

        if (result == playerChoice) {
            payOutBetAmount();
            return true;
        } else {
            payOutToBalance();
            return false;
        }
    }

    function payOutBetAmount() public payable onlyBetOwner returns(uint) {
       // Transfer the betAmount to the owner of the Bet.

        uint toPayOut = betAmount;
        betAmount = 0;
        msg.sender.transfer(toPayOut);
        return toPayOut;
    }

    function payOutToBalance() public payable onlyOwner returns(uint, uint) {
        // When player loses the betAmount is added to the balance of the smartcontract.

        uint toBalance = betAmount;
        betAmount = 0;
        balance += toBalance;
        return (toBalance, balance);
    }

    /* PRIVATE FUNCTIONS */
    function random() private view returns(uint) {
        // This function returns a random 0 or 1.
        return now%2;
    }

    function insertBet(Bet memory newBet) private {
        address player = msg.sender;
        bets[player] = newBet;
    }



}