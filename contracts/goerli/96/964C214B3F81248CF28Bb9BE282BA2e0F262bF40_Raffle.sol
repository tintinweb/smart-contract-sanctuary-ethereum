// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "Ownable.sol";
import "ReentrancyGuard.sol";
import "IERC721Receiver.sol";

interface IERC721 {
  function ownerOf(uint256 _tokenId) external view returns (address);
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IRNGesus {
    function prayToRngesus(uint256 _gweiForFulfillPrayer) external payable returns (uint256);
    function randomNumbers(uint256 _requestId) external view returns (uint256);
}

contract Raffle is Ownable, ReentrancyGuard, IERC721Receiver {

    // raffleCreator will get remaining balance of this contract
    // after the raffle is finished
    address payable public raffleCreator;
    
    // set address of promotor and developer
    address payable public promotor;
    address payable public developer;

    // set deployment date once NFT is received by the contract
    uint256 public deployDate;

    // set raffle name, total tickets, ticket price and tickets left
    string public raffleName;
    uint256 public totalTickets;
    uint256 public ticketPrice;
    uint256 public ticketsLeft;
    
    // set the contract address and token id of the NFT prize
    address public nftContract;
    uint256 public nftTokenId;

    // array with all addresses that joined the raffle
    address[] public raffleBox;

    // contract address and request id for RNGesus
    address public rngesusContract;
    uint256 public rngesusRequestId;

    // keep track of how many tickets (players can have multiple tickets!!)
    // requested a refund
    uint256 public refundRequests;
    
    // set the winner once we know it
    address public winner;

    // keep a struct with player info
    // how many tickets a player bought
    // if the player requested a refund
    // and if the player has been refunded
    struct Player {
        uint256 ticketsBought;
        bool refundRequested;
        bool isRefunded;
    }

    // mapping from address to Player struct
    mapping(address => Player) public players;

    // raffle state
    // WAITING_FOR_NFT - the contract has just been deployed, the raffle creator can now send the NFT
    // TICKET_SALE_OPEN - once the NFT has been received by this, players can now join the raffle
    // DRAW_WINNER - when all tickets are sold, the raffle creator can start the draw winner process and request for a random number
    // WAITING_FOR_PAYOUT - once the random number has been received, the winner will get the NFT, the ETH will be send to the raffle creator, promotor and developer
    // RAFFLE_FINISHED - the raffle is finished, thank you for playing
    // REFUND_TICKET - if the raffle has not been concluded after 7 days, players OR the raffle creator can request to put this contract in REFUND_TICKET state
    //                 in this state you can claim back the ETH you have sent for your tickets, the raffle creator can claim back the nft, so no rug pulls  
    enum RAFFLE_STATE {
        WAITING_FOR_NFT,
        TICKET_SALE_OPEN,
        DRAW_WINNER,
        WAITING_FOR_PAYOUT,
        RAFFLE_FINISHED,
        REFUND_TICKET
    }

    // raffleState variable
    RAFFLE_STATE public raffleState;

    // event for when the winner is drawn
    event Winner(address winner);

    // to start a raffle, you need the raffle name, the ticket price, total amount of tickets, the RNGesus contract address
    // the raffle creator address, the promotor address and the developer address
    constructor(
        string memory _raffleName,
        uint256 _ticketPrice, 
        uint256 _totalTickets, 
        address _rngesusContract, 
        address _raffleCreator,
        address _promotor, 
        address _developer
        
        ) {

        // transfer ownership of this contract to the raffleCreator
        transferOwnership(_raffleCreator);

        // max 1000 ticket per raffle, min 10 tickets
        require(_totalTickets <= 1000, "Maximum tickets is 1000");
        require(_totalTickets >= 10, "Minimum tickets is 10");

        // set raffleCreator, promotor and developer addresses
        raffleCreator = payable(_raffleCreator);
        promotor = payable(_promotor);
        developer = payable(_developer);

        // set contract variables
        raffleName = _raffleName;
        totalTickets = _totalTickets;
        ticketsLeft = _totalTickets;  // no sales yet, same as totalTickets
        ticketPrice = _ticketPrice;
        rngesusContract = _rngesusContract;

        // set raffle_state to WAITING_FOR_NFT
        raffleState = RAFFLE_STATE.WAITING_FOR_NFT;

    }

    // get contract variables
    function getContractVariables() public view returns (bytes memory) {

        return abi.encode(
            raffleCreator, raffleName, totalTickets, 
            ticketPrice, ticketsLeft, nftContract, nftTokenId, winner
        );

    }

    // the raffle creator transfers the nft price to the contract
    // NFT must be approved by owner before calling this funcion
    function transferNftToRaffle(address _nftContract, uint256 _nftTokenId) public nonReentrant onlyOwner {
        
        // require correct raffle state
        require(raffleState == RAFFLE_STATE.WAITING_FOR_NFT, "Can't transfer a NFT a this time.");

        // transfer NFT to raffle contract
        IERC721(_nftContract).safeTransferFrom(msg.sender, address(this), _nftTokenId);

        // set nftContract and nftTokenId
        nftContract = _nftContract;
        nftTokenId = _nftTokenId;

        // set deployDate
        deployDate = block.timestamp;

        // set raffle_state to TICKET_SALE_OPEN
        raffleState = RAFFLE_STATE.TICKET_SALE_OPEN;

    }

    // we need this function because we use safeTransferFrom to transfer the NFT to this contract
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function buyTicket(uint256 _amountOfTickets) public payable nonReentrant {
        
        // check if raffle state is TICKET_SALE_OPEN
        require(raffleState == RAFFLE_STATE.TICKET_SALE_OPEN, "You can't buy tickets at this time.");
        
        // check if correct amount of ETH is send
        require(msg.value == _amountOfTickets * ticketPrice, "Incorrect value for the amount of tickets.");

        // check if enough tickets are left
        require(ticketsLeft >= _amountOfTickets, "Not enough tickets left, try to buy less.");

        // check if the player already request a refund
        require(players[msg.sender].refundRequested == false, "You requested a refund, you can't buy more tickets.");
        
        // loop through amountOfTickets
        for (uint256 amountOfTicketsIndex = 0; amountOfTicketsIndex < _amountOfTickets; amountOfTicketsIndex++) {
            
            // add player address to raffleBox array for each ticket
            raffleBox.push(payable(msg.sender));

        }

        // increase ticketsBought in Player struct with _amountOfTickets
        players[msg.sender].ticketsBought += _amountOfTickets;

        // decrease ticketsLeft with _amountOfTickets
        ticketsLeft -= _amountOfTickets;

        // set raffle_state to DRAW_WINNER when no tickets are left
        if(ticketsLeft == 0) {
            raffleState = RAFFLE_STATE.DRAW_WINNER;
        }

    }

    
    function drawWinner(uint256 _gweiForFulfillPrayer) public payable nonReentrant returns (uint256) {

        // check if the raffle_state is DRAW_WINNER
        require(raffleState == RAFFLE_STATE.DRAW_WINNER, "You can't draw the winner at this time.");

        // check if all tickets are sold
        require(raffleBox.length == totalTickets);

        rngesusRequestId = IRNGesus(rngesusContract).prayToRngesus{value: msg.value}(_gweiForFulfillPrayer);

        raffleState = RAFFLE_STATE.WAITING_FOR_PAYOUT;

        return rngesusRequestId;

    }

    
    // once a winner has been drawn, send the NFT to the winner, pay the promotor and developer
    // the remaining balance goes to the raffleCreator
    function payOut() public nonReentrant {

        // check if the raffle_state is WAITING_FOR_PAYOUT
        require(raffleState == RAFFLE_STATE.WAITING_FOR_PAYOUT, "You can't pay out at this time.");

        // get random number from RNGesus
        uint256 _randomNumber = IRNGesus(rngesusContract).randomNumbers(rngesusRequestId);

        // make sure that RNGesus created a random number, it will return 0 if it has not been created yet
        require(_randomNumber != 0, "RNGesus has not created a random number yet, please wait a few minutes.");

        // get the winning ticket (index of raffleBox)
        uint256 _winning_ticket = _randomNumber % totalTickets;

        // get winner_address from winning ticket from raffleBox 
        address _winner_address = raffleBox[_winning_ticket];

        winner = _winner_address;

        // emit message to tx logs
        emit Winner(_winner_address);

        // transfer NFT to winner
        IERC721(nftContract).safeTransferFrom(address(this), _winner_address, nftTokenId);

        // 10% costs are added to the contract value, which means we have
        // 11 pieces of 10%. Divide contract value by 11 to get the 10% costs
        uint256 _costs = ticketPrice * totalTickets / 11; 

        // split royalties for developer and fee for promoter
        uint256 _developerRoyalties = _costs / 2;
        uint256 _promotorFee = _costs - _developerRoyalties;
        
        // transfer royalties to developer and fees to promotor
        developer.transfer(_developerRoyalties);
        promotor.transfer(_promotorFee);

        // transfer ticket sales to contract creator
        raffleCreator.transfer(address(this).balance);

        // set raffle state to RAFFLE_FINISHED
        raffleState = RAFFLE_STATE.RAFFLE_FINISHED;

    }

    // when more than 5 tickets (one player can hold multiple tickets) request a refund,
    // initialze REFUND_TICKET state, so players can refund their ticket price
    function requestRefund() public {

        // check if 7 days has passed
        require(block.timestamp >= (deployDate + 7 days), "Refunds can be requested 7 days after the start of the raffle.");

        // check if raffle state is TICKET_SALE_OPEN, refunds can only be requested when not all tickets are sold
        require(raffleState == RAFFLE_STATE.TICKET_SALE_OPEN, "You can't request a refund at this time.");

        // require that the player hasn't requested a refund yet
        require(players[msg.sender].refundRequested == false, "You already requested a refund");

        // set refendRequested in Player struct to true
        players[msg.sender].refundRequested = true;

        // get the amount of tickets the player bought
        uint256 _ticketsBought = players[msg.sender].ticketsBought;

        // add amount of tickets the player bought to refundRequests
        refundRequests += _ticketsBought;

        // when at least 5 tickets requested a refund, set raffleState to REFUND_TICKET
        // one player can hold multiple tickets, it's possible that only 1 player
        // can set the raffleState to REFUND_TICKET
        if (refundRequests >= 5) {

            // set raffle state to REFUND_TICKET
            raffleState = RAFFLE_STATE.REFUND_TICKET;

        }

    }


    // refund ticket 
    function refundTickets() public nonReentrant {

        // check if raffle state is REFUND_TICKET
        require(raffleState == RAFFLE_STATE.REFUND_TICKET, "You can't refund your tickets at this time.");

        // check if player already requested a refund
        require(players[msg.sender].isRefunded == false, "You are already refunded.");

        // set isRefunded to true for this address
        players[msg.sender].isRefunded = true;

        // check how many tickets this player bought
        uint256 _ticketsBought = players[msg.sender].ticketsBought;

        // the refund amount is the amount of tickets bought x ticket price
        uint256 _refundAmount = _ticketsBought * ticketPrice;

        // transfer the refund amount to this address
        payable(msg.sender).transfer(_refundAmount);
    }

    // cancel raffle by creator
    function cancelRaffle() public onlyOwner {

        // check if raffle state is OPEN
        require(raffleState == RAFFLE_STATE.TICKET_SALE_OPEN, "You can't cancel the raffle at this time.");

        // check if 7 days has passed
        require(block.timestamp >= (deployDate + 7 days), "You can only cancel a raffle 7 days after the NFT has been recieved by this contract.");

        // set raffle state to REFUND_TICKET
        raffleState = RAFFLE_STATE.REFUND_TICKET;

    }

    // return NFT to raffleCreator when the raffleState is REFUND_TICKET
    function returnNftToRaffleCreator() public onlyOwner nonReentrant {

        require(raffleState == RAFFLE_STATE.REFUND_TICKET, "You can only return the NFT to you when the raffle is canceled.");

        // check if this contract is the owner of the NFT        
        require(address(this) == IERC721(nftContract).ownerOf(nftTokenId), "This contract is not the owner of the NFT, you probably already have the NFT back.");

        // transfer NFT back to raffleCreator
        IERC721(nftContract).safeTransferFrom(address(this), raffleCreator, nftTokenId);

    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}