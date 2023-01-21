// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ReentrancyGuard.sol";
import "./Math.sol";

interface IRNGesus {
    function prayToRngesus(uint256 _gweiForFulfillPrayer) external payable returns (uint256);
    function randomNumbers(uint256 _requestId) external view returns (uint256);
}

contract EthRaffle is ReentrancyGuard {

    // check if contract is already initialized
    bool private initialized;

    // contract variables
    string public raffleName;
    address public raffleCreator;
    uint256 public prizePoolAllocationPercentage;
    uint256 public prizePool;
    uint256 public totalTicketsBought;
    address public winner;
    
    // contract address and request id for RNGesus
    address public rngesusContract;
    uint256 public rngesusRequestId;

    // different price tiers when buying multiple tickets
    struct PriceTier {
        uint256 price;
        uint256 amountOfTickets;
    }
    mapping(uint256 => PriceTier) public priceTiers;

    // keep track of how many tickets bought by which address
    struct TicketsBought {
        uint256 currentTicketsBought; // current total amount of tickets bought in the raffle
        address player; // the player's wallet address
    }

    TicketsBought[] public raffleBox;

    // raffle states
    // TICKET_SALE_OPEN     - once the NFT has been trasfered to this contract, players can now join the raffle (buy tickets)
    // WAITING_FOR_PAYOUT   - once the random number has been created, execute the payout function and the winner will get the ETH prize, 
    //                          the remainder will go to the raffleCreator
    // RAFFLE_FINISHED      - the raffle is finished, thank you for playing
    
    enum RAFFLE_STATE {
        TICKET_SALE_OPEN,
        WAITING_FOR_PAYOUT,
        RAFFLE_FINISHED
    }

    // raffleState variable
    RAFFLE_STATE public raffleState;

    // events
    event TicketSale(
        address buyer,
        uint256 amountOfTickets,
        uint256 pricePaid
    );

    event Winner(
        address winner,
        uint256 prize
    );

    function initialize(
        string memory _raffleName,
        address _raffleCreator,
        uint256 _prizePoolAllocationPercentage,
        address _rngesusContract,
        PriceTier[] calldata _priceTiers

    ) external nonReentrant {

        // check if contract is already initialized
        require(!initialized, "Contract is already initialized.");
        initialized = true;

        // set the raffle variables
        raffleName = _raffleName;
        raffleCreator = _raffleCreator;
        rngesusContract = _rngesusContract;
        prizePoolAllocationPercentage = _prizePoolAllocationPercentage;

        require(_priceTiers.length > 0, "No price tiers found.");

        // set the ticket price tiers
        for (uint256 i = 0; i < _priceTiers.length; i++) {

            require(_priceTiers[i].amountOfTickets > 0, "Amount of tickets should be more than 0.");

            // create PriceTier and map to priceTiers 
            priceTiers[i] =  PriceTier({
                price: _priceTiers[i].price,
                amountOfTickets: _priceTiers[i].amountOfTickets
            });            

        }

    }

    function addEthToPrizePool() external payable {

        require(msg.sender == raffleCreator, "Only the Raffle Creator can add ETH to the prize pool.");
        prizePool += msg.value;

    }

    function buyTicket(uint256 _priceTier) external payable nonReentrant {

        require(raffleState == RAFFLE_STATE.TICKET_SALE_OPEN, "Can't buy tickets anymore.");

        uint256 amountOfTickets = priceTiers[_priceTier].amountOfTickets;
        uint256 ticketsPrice = priceTiers[_priceTier].price;

        require(msg.value == ticketsPrice, "Please pay the correct amount.");

        // create new TicketsBought struct
        TicketsBought memory ticketsBought = TicketsBought({
            player: msg.sender,
            currentTicketsBought: totalTicketsBought + amountOfTickets
        });

        // push TicketsBought struct to raffleBox
        raffleBox.push(ticketsBought);

        // add amountOfTickets to totalTicketsBought
        totalTicketsBought += amountOfTickets;

        // add eth to the prize pool
        prizePool += msg.value / 100 * prizePoolAllocationPercentage;

        emit TicketSale(msg.sender, amountOfTickets, ticketsPrice);

    }

    function drawWinner(uint256 _gweiForFulfillPrayer) public payable nonReentrant {

        // only the raffle creator can execute this function
        require(msg.sender == raffleCreator, "Only the Raffle Creator can draw the winner.");

        // check if raffle state is TICKET_SALE_OPEN
        require(raffleState == RAFFLE_STATE.TICKET_SALE_OPEN, "Can't draw a winner at this time.");

        // pray to RNGesus to request a random number
        rngesusRequestId = IRNGesus(rngesusContract).prayToRngesus{value: msg.value}(_gweiForFulfillPrayer);

        // set raffle state to WAITING_FOR_PAYOUT
        raffleState = RAFFLE_STATE.WAITING_FOR_PAYOUT;

    }

    function payOut() public nonReentrant {

        // only the raffle creator can execute this function
        require(msg.sender == raffleCreator, "Only the Raffle Creator can pay out.");

        // check if the raffle_state is WAITING_FOR_PAYOUT
        require(raffleState == RAFFLE_STATE.WAITING_FOR_PAYOUT, "You can't pay out at this time.");

        // get random number from RNGesus
        uint256 randomNumber = IRNGesus(rngesusContract).randomNumbers(rngesusRequestId);

        // make sure that RNGesus created a random number, it will return 0 if it has not been created yet
        require(randomNumber != 0, "RNGesus has not created a random number yet, please wait a few minutes.");

        // get the winning ticket (modulo can have 0 as a value, that's why we add 1)
        uint256 winningTicket = (randomNumber % totalTicketsBought) + 1;

        // find the index of raffle box for the winner
        uint winnerIndex = findWinnerIndex(winningTicket);

        // get the winner addres from the raffle box
        winner = raffleBox[winnerIndex].player;

        // pay the winner the prize pool
        payable(winner).transfer(prizePool);

        emit Winner(winner, prizePool);

        // transfer remaining balance to the raffle creator
        payable(raffleCreator).transfer(address(this).balance);

        // the raffle is finished, thanks for playing
        raffleState = RAFFLE_STATE.RAFFLE_FINISHED;

    }

    // find the index of the raffle box to determine the winner based on the ticket number
    function findWinnerIndex(uint256 winningTicket) internal view returns (uint256) {

        // set low to 0 and high to the raffle box length
        uint256 low = 0;
        uint256 high = raffleBox.length;

        while (low < high) {

            // get the average of low and high (Math will round down)
            uint256 mid = Math.average(low, high);

            // check if current tickets bought for index mid is greater than winning ticket number
            if (raffleBox[mid].currentTicketsBought > winningTicket) {

                // if so, set high to mid and run again
                high = mid;

            } else {
                // if current tickets bought is lower than winning ticket, set low to mid + 1
                low = mid + 1;
            }
        }

        // once we break out of the while loop, currentTicketsBought is either exact for the raffle box index low -1
        // if not, the winning raffle box index is equal to low
        if (low > 0 && raffleBox[low - 1].currentTicketsBought == winningTicket) {
            return low - 1;
        } else {
            return low;
        }
    }

    // get contract variables
    function getContractVariables() public view returns (bytes memory) {

        bytes memory contractVariables = abi.encode(
            raffleName, prizePoolAllocationPercentage, prizePool, totalTicketsBought, winner
        );

        return contractVariables;

    }

}