/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/LotteriaPenna.sol

/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


contract Lottery {
    // Lottery agent and beneficiary
    using SafeMath for uint256;
    address public organizer;
    /// @dev (STARTED) -> closeGame -> (CLOSED) -> endGame -> (STARTED)
    /// @dev Game can be closed only if the time is over,
    /// @dev at this point players can't buy a new tickets
    /// @dev So this time is used to generate a random number,
    /// @dev thereby choose a winner ticket.
    /// @dev Once it is done state changes to CLOSED
    enum GameState {
        STARTED,
        CLOSED
    }

    GameState public state = GameState.STARTED;

    // Contains all game parameters and rules
    struct Game {
        // Ticket price in wei
        uint256 ticketPrice;
        uint256 gameTarget;
        // The percentage of sales returned to the players in the form of prize
        uint256 prizePayout;
        // The money from sales that will be used to pay prize
        uint256 prizePool;
    }

    // Partnership with a lottery
    address public treasury;
    //Lottery team address
    address public part1=0xe3e2FAdeA523127b48F0F6119cFDf2E3C0F7E9E4;
    address public part2=0x213BA065aEe918211BbF2A48F0f770d5Df9ff365;
 
    // The percentage of sales provided to a lottery partner
    uint256 public commission;
    uint256 public score;

    //uint256 public maxTickets=100;

    uint256 public prize1share=60;
    uint256 public prize2share=30;
    uint256 public prize3share=10;

      uint256[] public expandedValues;
    // Parameters for the current and next games.
    // Organizer can only change the rules for the next game
    // current game rules are immutable
    Game public next;
    Game public current;

    // Allowed withdrawals of previous lottery winners
    mapping(address => uint256) public unclaimedPrizes;
    uint256 public unclaimedPrizesTotal = 0;

    // Participant info
    struct Participant {
        // Unique id assigned on first buy
        uint256 id;
        // Number of tickets
        uint256 tickets;
    }

    // Participants of the current game
    address[] participantAddresses;
    mapping(address => Participant) public participants;

    // Sold tickets
    address[] tickets;
    address[] public winners = new address[](3);

    // Number of sold tickets in current game
    uint256 public soldTickets = 0;
    uint256 public luckyTicket1;
    uint256 public luckyTicket2;
    uint256 public luckyTicket3;
    // The date when the current game will end and the new will be started
    //uint256 public gameEndDate;
    // total games
    uint256 public gameNumber = 1;


    modifier isOrganizer() {
        require(msg.sender == organizer, "Caller is not organizer");
        _;
    }

    /// Game ends and winner is defined
    event Win(address[] indexed _winners, uint256 _prize);

    /// Buy tickets
    event Buy(address indexed _participant, uint256 _amount);

    /// Claim rewards
    event Claim(address indexed _to, uint256 _amount);

    /// New partnership is established
    event PartnershipTreasury(address indexed _treasury, uint256 _commission);
    

    /// The game has not closed yet.
    error GameNotYetClosed();

    /// @dev Set contract deployer as organizer
    constructor() {
        organizer = msg.sender;
      //  current = Game(5000000000000000, 2000000000000000000, 80, 0);//500 tickets
        current = Game(5000000000000000, 200000000000000000, 80, 0);//50 tickets
        next = current;
    }

    receive() external payable {}

    /// @notice organizer can set the new ticket price for the next game
    /// @param _ticketPrice new ticket price in wei
    function setTicketPrice(uint256 _ticketPrice) public isOrganizer {
        next.ticketPrice = _ticketPrice;
    }

     function setTarget(uint256 _gameTarget) public isOrganizer {
        next.gameTarget = _gameTarget;
    }

    function getParticipantTickets(address _partAddr) public view returns(uint256){
        Participant storage player = participants[_partAddr];
        return player.tickets;
    }

   
 /*function setMaxTicket(uint256 _maxTickets) public isOrganizer {
        maxTickets = _maxTickets;
    }*/

     function setPrizeShare(uint256 _pshare1,uint256 _pshare2,uint256 _pshare3) public isOrganizer {
         require(_pshare1 + _pshare2 + _pshare3<=100, "major the 100%");
        prize1share = _pshare1;
        prize2share = _pshare2;
        prize3share = _pshare3;
    }

    /// @notice organizer can change the time period for the next game
    /// @param _gameTime new time period for next game
 /*   function setGameTime(uint256 _gameTime) public isOrganizer {
        require(_gameTime <= 30 days);
        next.gameTime = _gameTime;
    }*/

    /// @notice organizer can change the prize payout for the next game
    /// @param _prizePayout new prize payout (% received by players) for next game
    function setPrizePayout(uint256 _prizePayout) public isOrganizer {
        require(_prizePayout <= 100);
        next.prizePayout = _prizePayout;
    }

   

//SSET ADDRESS 3 STAKEHOLDER
    function setPart1(address _part1)
        public
        isOrganizer
    {        part1 = _part1;    }

     function setPart2(address _part2)
        public
        isOrganizer
    {        part2 = _part2;    }

    
         

            function setTreasury(address _treasury, uint256 _commission)
        public
        isOrganizer
    {
        require(_commission <= 100);
        treasury = _treasury;
        commission = _commission;
        emit PartnershipTreasury(_treasury, commission);
    }

//DARIO: a che SERVE?

 //   function increasePrizePool() public payable {
  
 // 
 //       require(msg.value > 0);
  
 //       current.prizePool += msg.value;

 //     }

    /// @notice organizer can take the profit
    /// _address address where to transfer profit
    //DARIO: dividere profit per 3
  /*  function withdrawProfit(address _address) public isOrganizer {
        require(profit() > 0);
        payable(_address).transfer(profit());
    }*/

function withdrawProfit() public isOrganizer {
        require(profit() > 0);
        uint256 part = profit().div(2);
        payable(part1).transfer(part);
        payable(part2).transfer(part);
      

    }


    /// @return current organizer profit
    function profit() public view returns (uint256) {
        if (address(this).balance - withholdings() < 0) {
            return 0;
        }
        return address(this).balance - withholdings();
    }

       function getBalance() public view returns (uint256) {
        return address(this).balance;
    }


    /// @notice Returns the amounts required to be subtracted from a balance
    /// @notice to cover payments
    ///
    /// @return withholdings
    function withholdings() internal view returns (uint256) {
        return current.prizePool + next.prizePool + unclaimedPrizesTotal;
    }

    /// @notice anyone can buy a tickets
    /// @param _amount number of tickets to buy
    function buy(uint256 _amount) public payable {
       // require(block.timestamp < gameEndDate, "Game is closed");

         require(score < current.gameTarget, ">target");
         uint256 payout;
         uint256 totalPrice = _amount * current.ticketPrice;

        require(

            msg.value >= totalPrice,
            "Insufficient amount"
        );
         payout = totalPrice.mul(current.prizePayout).div(100);
        
       /* require(
            getParticipantTickets(msg.sender)+_amount <= maxTickets,
            "Too many Tickets"
        );*/
         // refund excessive values
        if (msg.value > totalPrice) {
            uint256 refund = msg.value - totalPrice;
            payable(msg.sender).transfer(refund);
        }
        Participant storage participant = participants[msg.sender];
        // register new participant if he/she does not exist
        if (participant.id == 0) {
            participantAddresses.push(msg.sender);
            participant.id = participantAddresses.length;
            participant.tickets = 0;
        }

        participant.tickets += _amount;

        for (uint256 i = 0; i < _amount; i++) {
            tickets.push(msg.sender);
            soldTickets++;
        }

        //uint256 payout = totalPrice.mul(current.prizePayout).div(100);
        if (treasury != address(0)) {
            // partner gets % (commission) of the profit
            uint256 incentives = ((totalPrice - payout) * commission) / 100;
            unclaimedPrizes[treasury] += incentives;
            unclaimedPrizesTotal += incentives;
        }

      /*uint256 nextPayout = (payout * 10) / 100;
        current.prizePool += payout - nextPayout;
        next.prizePool += nextPayout;*/

        current.prizePool += payout;

        score=current.prizePool;

        emit Buy(msg.sender, _amount);
    }

    /// @dev this method should be overriden with true RNG implementation
    function closeGame() public virtual {
       // require(block.timestamp >= gameEndDate);

       require(score >= current.gameTarget, "Game is closed");

        state = GameState.CLOSED;
      
        endGame();
    }

    /// @notice anyone can end the game, but only if the game is closed
    function endGame() public {
       
        if (state != GameState.CLOSED) revert GameNotYetClosed();

        if (participantAddresses.length > 0) {
            winners = draw();
            unclaimedPrizes[winners[0]] += current.prizePool.mul(prize1share).div(100);
            unclaimedPrizes[winners[1]] += current.prizePool.mul(prize2share).div(100);
            unclaimedPrizes[winners[2]] += current.prizePool.mul(prize3share).div(100);
            unclaimedPrizesTotal += current.prizePool;

            emit Win(winners, current.prizePool);
        } else {
            next.prizePool += current.prizePool;
        }

       
    }
    function startGame() public {

        require(state == GameState.CLOSED, "Game is Opened");
        score=0;
     current = next;
        next.prizePool = 0;

       // gameEndDate = block.timestamp + current.gameTime;

       //inserire qui il confronto col nuovo balance
        state = GameState.STARTED;

        for (uint256 i = 0; i < participantAddresses.length; i++) {
            delete participants[participantAddresses[i]];
        }
        delete participantAddresses;
        // all tickets are burned after game is ended
        delete tickets;
        delete soldTickets;
        gameNumber += 1;
    }
    /// @notice Players can claim prize if they have a winner tickets
    function claim() public returns (bool) {
        uint256 prize = unclaimedPrizes[msg.sender];
        if (prize > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receivin.g call
            // before `send` returns.
            unclaimedPrizes[msg.sender] = 0;
            unclaimedPrizesTotal -= prize;
            payable(msg.sender).transfer(prize);

          /*  if (!payable(msg.sender).send(prize)) {
                // No need to call throw here, just reset the amount owing
                unclaimedPrizes[msg.sender] = prize;
                unclaimedPrizesTotal += prize;
                return false;
            }*/

            emit Claim(msg.sender, prize);
        }
        return true;
    }

    /// @notice Select winner aggiornare la randomizzazione
    function draw() internal returns (address[] memory) {
        address[] memory datawin = new address[](3);

        expand(random());
       
       luckyTicket1 = expandedValues[0].mod(soldTickets);
       datawin[0]=tickets[luckyTicket1];
       //moficare per rendere non riselezionare i vincitori
       luckyTicket2 = expandedValues[1].mod(soldTickets);
       while(luckyTicket2==luckyTicket1){luckyTicket2 = expandedValues[1].mod(soldTickets);}

       datawin[1]=tickets[luckyTicket2];

       luckyTicket3 = expandedValues[2].mod(soldTickets);
       while(luckyTicket3==luckyTicket1 || luckyTicket3==luckyTicket2){luckyTicket3 = expandedValues[2].mod(soldTickets);}
       datawin[2]=tickets[luckyTicket3];

        return datawin;
    }

    /// @notice Generate random number
    function random() internal view virtual returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        participantAddresses
                    )
                )
            );
    }
    function expand(uint256 _randomResult) public {
    expandedValues = new uint256[](3);
    for (uint256 i = 0; i < 3; i++) {
        expandedValues[i] = uint256(keccak256(abi.encode(_randomResult, i)));
    }
    }

 /*   function addNewInfluPin(uint256 _influPin) public isOrganizer {
        Influencer memory influ;
        influ.pin=_influPin;
      
    }*/

    
}