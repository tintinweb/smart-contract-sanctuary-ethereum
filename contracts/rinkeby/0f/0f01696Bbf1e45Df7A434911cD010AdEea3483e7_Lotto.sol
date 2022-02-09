// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LottoBase.sol";
import "./interfaces/ISuperdraw.sol";

contract Lotto is LottoBase {
    using SafeERC20 for IERC20;

// STATE VARIABLES

    /// @dev SuperDraw % of prize pool
    uint256 public superDrawPercent;

    /// @dev Price of the ticket
    uint256 public ticketPrice;

    /// @dev This is the Superdraw contract
    ISuperdraw public superdrawContract;

// CONSTRUCTOR

    constructor(
        uint256 _ticketPrice,
        address _paymentAddress,
        address _superdrawContract,
        uint256 _drawTarget,
        uint256 _winnerPercent,
        uint256 _nextDrawPercent,
        uint256 _burnPercent,
        uint256 _closerFeePercent,
        uint256 _superDrawPercent
        
        )
    {
        paymentContract = IERC20(_paymentAddress);                    // Set contract for payments
        superdrawContract = ISuperdraw(_superdrawContract);           // Set Contract for the Superdraw
        ticketPrice = _ticketPrice;                                   // Set initial ticket price
        drawTarget = _drawTarget;                                     // Set the draw length
        winnerPercent = _winnerPercent;                               // Set initial winners %
        nextDrawPercent = _nextDrawPercent;                           // Set initial next draw %
        burnPercent = _burnPercent;                                   // Set initial burn %
        closerFeePercent = _closerFeePercent;                         // Set initial closers fee %
        superDrawPercent = _superDrawPercent;                         // Set initial superdraw %
        Draw memory firstDraw;                                         // Instantiate instance of Draw
        draws.push(firstDraw);                                         // Create the first draw
        draws[0].target = block.number + _drawTarget;                 // Start the first draw by setting the deadline
    }

// EVENTS

    event PriceChanged(address updatedBy, uint256 newPrice);

// MODIFIERS

    /// @dev Only after the current draw has reached it's target is this action allowed
    modifier afterTarget() override {
        require(block.number > draws[getCurrentDraw()].target, "The draw deadline was not reached yet");
        _;
    }

    /// @dev Only before the current draw has reached it's deadline is this action allowed
    modifier withinTarget() override {
        require(block.number <= draws[getCurrentDraw()].target, "This draw has reached its deadline");        _;
    }

    /// @dev Only when the draw is complete is this action allowed
    /// @param drawIndex Which draw are you checking?
    modifier drawComplete(uint256 drawIndex) override {
        require(drawIndex < draws.length,                   "Draw out of range");
        require(block.number > draws[drawIndex].target,     "This draw is still open");
        require(draws[drawIndex].drawStatus == State.Closed, "This draw still needs to be closed");
        _;
    }

// PUBLIC FUNCTIONS

    /// @dev EXTERNAL: Anyone can buy a ticket
    /// @param numTickets Number of lotto tickets
    function buyTicket(uint256 numTickets)
        external
        nonReentrant
        whenNotPaused
        withinTarget
    {
        uint256 superDraw = 0;
        Draw storage draw = draws[getCurrentDraw()];                                                // Shortcut accessor for the Draw
        require( numTickets < 101,                                                                 "You can buy a maximum of 100 tickets" );
        uint256 priceToPay = ticketPrice * numTickets;                                             // Calculate Tokens to Pay
        require( paymentContract.balanceOf(_msgSender()) >= priceToPay,                             "Balance too low to pay for tickets" );
        draw.numberOfTickets = draw.numberOfTickets + numTickets;                                  // Add the number of tickets sold
        for (uint i = 0; i < numTickets; i++) {                                                    // Loop through the players
            draw.players.push(_msgSender());                                                        // Add players address for each ticket
        }
        emit TicketsAdded(_msgSender(), priceToPay, numTickets);                                                 // Write an event to the chain
        if ( superDrawPercent > 0 ) {
            superDraw = priceToPay * superDrawPercent / 100;                                        // calculate amount to go to super draw
        }
        draw.prizePool = draw.prizePool + priceToPay - superDraw;                                   // Add to the pize pool (excludes Superdraw)
        if ( superDraw > 0 ) {
            superdrawContract.addTickets(numTickets, _msgSender(), superDraw);                     // Add to superdraw
            paymentContract.safeTransferFrom(_msgSender(), address(superdrawContract), superDraw);  // Take the tokens for tickets
        }
        paymentContract.safeTransferFrom(_msgSender(), address(this), priceToPay - superDraw);      // Take the tokens for tickets
    }

// ADMIN FUNCTIONS

    /// @dev ADMIN: Owner can set the price
    /// @param price The new price
    function setPrice(uint256 price)
        external
        onlyOwner
    {
        if ( price != 0 && 
             price != ticketPrice
        ) {
            ticketPrice = price;
            emit PriceChanged(_msgSender(), price);
        }
    }

    /// @dev ADMIN: Owner can change the Superdraw address
    /// @param superdrawContractAddress The address of the new Farmland Superdraw contract
    function setSuperDrawContract(address superdrawContractAddress)
        external
        onlyOwner
    {
        superdrawContract = ISuperdraw(superdrawContractAddress);                       // Reset the Superdraw contract
        emit ContractAddressChanged(_msgSender(), "Superdraw Contract", superdrawContractAddress);    // Write an event to the chain
    }

    /// @dev ADMIN: Owner can change % that goes to the Superdraw
    /// @param superDraw The percentage of the prize pool allocated to super draw
    function setSuperdraw(uint256 superDraw)
        external
        onlyOwner
    {
        superDrawPercent = superDraw;                        // Reset the % that goes to the Superdraw
        emit PayoutStructureChanged(_msgSender(), 0, 0, 0, 0, superDraw);  // Write an event to the chain
    }

// GETTERS

    /// @dev INTERNAL: Get next target
    function getNextTarget()
        override
        view
        internal
        returns (uint256 nextTarget)
    {
        nextTarget = block.number + drawTarget;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISuperdraw {
    function addTickets(uint256 numTickets, address entrant, uint256 amountAddedToPrizePool) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandomNumbers {
    function getRandomNumber(uint256 drawIndex) external;
    function fulfillRandomness(bytes32 requestId, uint256 randomness) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC777.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/IRandomNumbers.sol";

enum State {Open, Closed, Pending}
struct Draw { address winnersAddress; bool prizeClaimed; address[] players; uint256 prizePool; State drawStatus; uint256 target; uint256 winnerPrize; uint256 numberOfTickets;}

abstract contract LottoBase is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

// STATE VARIABLES

    /**
     * @dev PUBLIC: Stores all the draws
     */
    Draw[] public draws;
    
    /// @dev Winners % of prize pool
    uint256 public winnerPercent;

    /// @dev Next Draw % of prize pool
    uint256 public nextDrawPercent;

    /// @dev Burn % of prize pool
    uint256 public burnPercent;

    /// @dev Closers % of prize pool
    uint256 public closerFeePercent;

    /// @dev Target for each draw
    uint256 public drawTarget;

    /// @dev This is the contract used to pay for tickets
    IERC20 public paymentContract;

    /// @dev Initialise the nonce used to generate pseudo random numbers
    uint256 private randomNonce;

    /// @dev This is the external VRF contract to generate random numbers
    IRandomNumbers public randomContract;

// EVENTS

    event ContractAddressChanged(address updatedBy, string addressType, address newAddress);
    event TicketsAdded(address updatedBy, uint256 pricePaid, uint256 totalTickets);
    event DrawClosed(address updatedBy, uint256 burnedAmount, uint256 closerFee, uint256 nextDrawAmount);
    event PrizeClaimed(address updatedBy, uint256 amountClaimed);
    event PayoutStructureChanged(address updatedBy, uint256 winnerPercent, uint256 burnPercent, uint256 closerFeePercent, uint256 nextDrawPercent, uint256 superDrawPercent);
    event DrawTargetChanged(address updatedBy, uint256 newTarget);

// MODIFIERS

    /// @dev Only after the current draw has reached it's target is this action allowed
    modifier afterTarget() virtual {
        require(draws[getCurrentDraw()].prizePool > draws[getCurrentDraw()].target, "The draw target was not reached yet");
        _;
    }

    /// @dev Only before the current draw has reached it's target is this action allowed
    modifier withinTarget() virtual {
        require(draws[getCurrentDraw()].prizePool <= draws[getCurrentDraw()].target, "This draw has reached its target");
        _;
    }

    /// @dev Only when the draw is complete is this action allowed
    /// @param drawIndex Which draw are you checking?
    modifier drawComplete(uint256 drawIndex) virtual {
        require(drawIndex < draws.length,                              "Draw out of range");
        require(draws[drawIndex].prizePool > draws[drawIndex].target, "This draw is still open");
        require(draws[drawIndex].drawStatus == State.Closed,           "This draw still needs to be closed");
        _;
    }

    /// @dev Only allows winners to perform this action
    /// @param drawIndex Which draw are you checking?
    modifier isWinner(uint256 drawIndex) virtual {
        require(drawIndex < draws.length,                        "Draw out of range");
        require(draws[drawIndex].prizePool > 0,                  "No prize for this draw");
        require(!draws[drawIndex].prizeClaimed,                  "Prize already claimed");
        require(_msgSender() == draws[drawIndex].winnersAddress, "Sorry, you did not win this time!");
        _;
    }

    /// @dev Only allows existing draws
    /// @param drawIndex Which draw are you checking?
    modifier isADraw(uint256 drawIndex) virtual {
        require(drawIndex <= draws.length, "Draw out of range");
        _;
    }

    /// @dev Only allow VRF random contract to perform this action
    modifier isVRFContract() virtual {
        require(_msgSender() <= address(randomContract), "Only permitted by VRF Contract");
        _;
    }

// PUBLIC FUNCTIONS

    /// @dev EXTERNAL: Winner can claim a prize
    /// @param drawIndex Which draw are you claiming for?
    function claimWinningPrize(uint256 drawIndex)
        virtual
        external
        nonReentrant
        drawComplete(drawIndex)
        isWinner(drawIndex)
    {
        Draw storage draw = draws[drawIndex];                          // Shortcut accessor for the Draw
        uint256 amount = draw.winnerPrize;                              // Calculate the prize for this Draw
        require (paymentContract.balanceOf(address(this)) >= amount,    "Contract balance isnt enough to cover the winner");
        draw.prizeClaimed = true;                                       // Set prize as claimed
        emit PrizeClaimed(_msgSender(), amount);                                      // Write an event to the chain
        paymentContract.safeTransfer(_msgSender(), amount);             // Pay winner
    }

    /// @dev EXTERNAL: Closes the current draw, starts the next draw, chooses the winner, 
    /// @dev passes part of the prize pool to the next draw & the super draw, completes the burn & pays the closer
    function closeDraw()
        virtual
        external
        nonReentrant
        afterTarget
    {
        Draw storage draw = draws[getCurrentDraw()];                                  // Shortcut accessor for the Draw
        require(draw.drawStatus == State.Open,                                        "The lottery has ended. Please check if you won the price!");
        
        (uint256 winnerPrize, uint256 closersFee, uint256 burnAmount,
        uint256 nextDrawAmount) = splitPrizePool(draw.prizePool);                     // Split the pool and allocate to the various pots

        uint256 randomNumber = 0;                                                     // Instantiate the random number used to choose the winner
        uint256 numberOfPlayers = draw.players.length;                                // Store the number of players in a local variable saves gas
        bool isVRFActive = isVRF();                                                   // Store if the VRF contract has been activated
        if (numberOfPlayers > 0 ) {
            if (!isVRFActive) {
                randomNumber = getRandomNumber();                                     // Retrieve random number from internal function
                draw.winnersAddress = draw.players[randomNumber % numberOfPlayers];   // Assign winner using internal randomness
                draw.drawStatus = State.Closed;                                       // Flag draw as ended
            } else {
                randomContract.getRandomNumber(getCurrentDraw());                     // Request random number
                draw.drawStatus = State.Pending;
            }
            draw.winnerPrize = winnerPrize;                                           // Update the winners prize
        } else {
            nextDrawAmount = draw.prizePool;                                          // Roll over the prize pool into the next draw
            draw.winnerPrize = 0;                                                     // No winners prize
            closersFee = 0;                                                           // No closers fee forfor a roll over draw
            burnAmount = 0;                                                           // No burn for a roll over draw
            draw.drawStatus = State.Closed;                                           // Flag draw as ended
        }
        emit DrawClosed(_msgSender(), burnAmount, closersFee, nextDrawAmount);                      // Write an event to the chain
        Draw memory nextDraw;                                                         // Instantiate instance of draw
        draws.push(nextDraw);                                                         // Create the next draw
        draws[getCurrentDraw()].target = getNextTarget();                             // Start next draw by setting the target
        draws[getCurrentDraw()].prizePool = nextDrawAmount;                           // Seeds the next draw
        if (closersFee > 0) {
           paymentContract.safeTransfer(_msgSender(), closersFee);                   // Send to the close fee to the caller
        }
        if (burnAmount > 0) {
            IERC777(address(paymentContract)).burn(burnAmount,"");                    // The Burn
        }
    }

    /// @dev EXTERNAL: Call back function for the VRF co-ordinator to choose winner & close the draw
    /// @param drawIndex Which draw are you closing?
    /// @param randomNumber This is the random number to choose a winner
    function chooseWinnerVRF(uint256 drawIndex, uint256 randomNumber)
        virtual
        external
        isADraw(drawIndex)
        isVRFContract
    {
        Draw storage draw = draws[drawIndex];                                        // Shortcut accessor for the Draw
        require(draw.drawStatus == State.Pending,                                     "This draw is needs to be pending");
        uint256 numberOfPlayers = draw.players.length;                                // Store the number of players in a local variable saves gas
        draw.winnersAddress = draw.players[randomNumber % numberOfPlayers];          // Assign winner using external randomness
        draw.drawStatus = State.Closed;                                               // Flag draw as ended
    }

// INTERNAL FUNCTIONS

    /// @dev INTERNAL: Generates a random number to choose a winner
    function getRandomNumber()
        virtual
        internal
        returns (uint256 randomNumber)
    {
        randomNonce++;
        return uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), randomNonce)));
    }

// ADMIN FUNCTIONS

    /// @dev ADMIN: Owner can set the draw target
    /// @param newDrawtarget The new draw target
    function setDrawTarget(uint256 newDrawtarget)
        virtual
        external
        onlyOwner
    {
        if ( newDrawtarget != 0 && 
             newDrawtarget != drawTarget
        ) {
            drawTarget = newDrawtarget;
            emit DrawTargetChanged(_msgSender(), newDrawtarget);
        }
    }

    /// @dev ADMIN: Owner can start or pause the contract
    /// @param value False starts & True pauses the contract
    function isPaused(bool value)
        virtual
        external
        onlyOwner 
    {
        if ( !value ) {
            _unpause();
        } else {
            _pause();
        }
    }

    /// @dev ADMIN: Owner can change the draw payout structure
    /// @param winner The percentage of the prize pool allocated to the winner
    /// @param burn The percentage of the prize pool allocated to the burn
    /// @param closerFee The percentage of the prize pool allocated to the closer
    /// @param nextDraw The percentage of the prize pool allocated to the next draw
    function setPayoutStructure(uint256 winner, uint256 burn, uint256 closerFee, uint256 nextDraw)
        virtual
        external
        onlyOwner
    {
        require ( winner + burn + closerFee + nextDraw == 100, "Total should equal 100");
        winnerPercent = winner;
        burnPercent = burn;
        closerFeePercent = closerFee;
        nextDrawPercent = nextDraw;
        emit PayoutStructureChanged(_msgSender(), winner, burn, closerFee, nextDraw, 0);
    }

    /// @dev ADMIN: Owner can change the payment contract
    /// @param paymentContractAddress The address of the new payment token
    function setPaymentContract(address paymentContractAddress)
        virtual
        external
        onlyOwner
    {
        paymentContract = IERC20(paymentContractAddress);
        emit ContractAddressChanged(_msgSender(), "Payment Contract", paymentContractAddress);
    }

    /// @dev ADMIN: Owner can change the contract that generates the random number
    /// @param randomContractAddress The address of the new randomness contract
    function setRandomnessAddress(address randomContractAddress)
        virtual
        external
        onlyOwner
    {
        randomContract = IRandomNumbers(randomContractAddress);
        emit ContractAddressChanged(_msgSender(), "Random Contract", randomContractAddress);
    }

// GETTERS

    /// @dev INTERNAL: Calculates the split of the prizepool
    function splitPrizePool(uint256 prizePool)
        virtual
        internal
        view
        returns (
            uint256 winnersPrize,
            uint256 closersFee,
            uint256 burnAmount,
            uint256 nextDrawAmount
        )
    {
        if ( winnerPercent > 0 ) {
            winnersPrize = prizePool * winnerPercent / 100;             // Calculate winners prize
        }
        if ( closerFeePercent > 0 ) {
            closersFee = prizePool * closerFeePercent / 100;            // Calculate closer fee
        }
        if ( burnPercent > 0 ) {
            burnAmount = prizePool * burnPercent / 100;                 // Calculate burn amount
        }
        if ( nextDrawPercent > 0 ) {
            nextDrawAmount = prizePool * nextDrawPercent / 100;         // Calculate amount to go to next draw
        }
    }

    /// @dev INTERNAL: Get next target
    function getNextTarget()
        virtual
        internal
        view
        returns (uint256 nextTarget)
    {
        nextTarget = drawTarget;
    }

    /// @dev EXTERNAL: Return list of players for a draw
    /// @param drawIndex Which draw?
    function getPlayersByDraw(uint256 drawIndex)
        virtual
        external
        view
        returns (
            address[] memory players                       // Define the array of addresses / players to be returned.
        )
    {
        if ( drawIndex > draws.length ) {return players;} // Return empty array if draw out of range
        return draws[drawIndex].players;                   // Return the array of players in a draw
    }

    /// @dev PUBLIC: Returns true if using the VRF randomness contract
    function isVRF()
        virtual
        public
        view
        returns (
            bool
        )
    {
        if (address(randomContract) == address(0)) {
            return false;
            } else {
                return true;
        }
    }

    /// @dev EXTERNAL: Return number of tickets per players for a draw
    /// @param drawIndex Which draw?
    /// @param account Which address?
    function getNumberOfTicketPerAddressByDraw(uint256 drawIndex, address account)
        virtual
        external
        view
        returns (
            uint256 tickets                                                            // Define the return variable
        )
    {
        if ( drawIndex > draws.length ) {return 0;}                                    // Return 0 if draw out of range
        uint256 totalTickets = draws[drawIndex].players.length;                         // Store the total number tickets in a local variable
        for(uint256 ticketIndex = 0; ticketIndex < totalTickets; ticketIndex++){         // Loop through the draws
            if ( account == draws[drawIndex].players[ticketIndex] )
                {
                    tickets++;                                                         // Add drawIndex to _winners array
                }
        }
    }

    /// @dev PUBLIC: Return winners address by draw
    /// @param drawIndex Which draw?
    function getWinnerByDraw(uint256 drawIndex)
        virtual
        public
        view
        returns (
            address winner
        )
    {
        if ( drawIndex > draws.length ) {
            return address(0);                                 // Return empty array if draw out of range
        }                                                      
        if ( draws[drawIndex].drawStatus != State.Closed )    // Or not closed
        {
            return address(0);                                 // Return zero address 
        }
        return draws[drawIndex].winnersAddress;               // Return the winners address
    }
    
    /// @dev EXTERNAL: Return unclaimed wins by address
    /// @param account Which address?
    function getUnclaimedWinnerByAddress(address account)
        virtual
        external
        view
        returns (uint256[] memory winners)
    {
        uint256 total = getCurrentDraw();                                  // Store the total draws in a local variable
        uint256 unclaimedTotal = 0;                                        
        for(uint256 drawIndex = 0; drawIndex < total; drawIndex++){        // Loop through the draws
            if ( !draws[drawIndex].prizeClaimed &&                         // Check if win is unclaimed
                 draws[drawIndex].numberOfTickets > 0 &&                   // with entrants
                 account == getWinnerByDraw(drawIndex) )
                {
                    unclaimedTotal++;                                      // increment unclaimedTotal
                }
        }
        uint256 winnersIndex = 0;
        uint256[] memory _winners = new uint256[](unclaimedTotal);
        if ( total == 0 ) {
            return new uint256[](0);                                       // Return an empty array
        } else {
            for(uint256 drawIndex = 0; drawIndex < total; drawIndex++){    // Loop through the draws
                if ( !draws[drawIndex].prizeClaimed &&                     // Check if win is unclaimed
                     draws[drawIndex].numberOfTickets > 0 &&               // with entrants
                     account == getWinnerByDraw(drawIndex) )
                     {
                        _winners[winnersIndex] = drawIndex;                // Add drawIndex to _winners array
                        winnersIndex++;
                    }
            }
        }
        return _winners;
    }

    /// @dev PUBLIC: Return current active draw
    function getCurrentDraw()
        virtual
        public
        view
        returns (
            uint256 currentDraw        // Define the return value
        )
    {
        return draws.length - 1;       // Return the length of the draws array
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC777/IERC777.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (interfaces/IERC777.sol)

pragma solidity ^0.8.0;

import "../token/ERC777/IERC777.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}