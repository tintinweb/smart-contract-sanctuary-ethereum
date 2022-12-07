// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "Ownable.sol";
import "Raffle.sol";

contract RaffleFactory is Ownable {

    Raffle[] public raffleArray;
    address public rngesus;
    uint256 public becomeRaffleCreatorFee = 1 ether;

    struct RaffleCreator {
        bool isRaffleCreator;
    }

    mapping(address => RaffleCreator) public raffleCreators;

    constructor(
        address _rngesus
    ) {
        rngesus = _rngesus;
        raffleCreators[msg.sender].isRaffleCreator = true;
    }

    function createNewRaffle(
        string memory _raffleName, 
        uint256 _ticketPrice,
        uint256 _totalTickets,
        uint256 _durationDays,
        uint256 _maxTicketsPerWallet,
        address[] memory _feeAddresses,
        uint256[] memory _feePercentages
    ) public {

        require(raffleCreators[msg.sender].isRaffleCreator == true, "You can't create Raffles, use becomeRaffleCreator() to become a Raffle Creator.");

        address _developer = owner();
        address _raffleCreator = msg.sender;

        Raffle raffle = new Raffle(
            _raffleName,
            _ticketPrice, 
            _totalTickets,
            rngesus,
            _raffleCreator,
            _feeAddresses,
            _feePercentages,
            _durationDays,
            _maxTicketsPerWallet,
            _developer
        );

        raffleArray.push(raffle);

    }

    function setRngesus(address _rngesus) public onlyOwner {
        
        rngesus = _rngesus;

    }


    function becomeRaffleCreator() public payable {

        require(msg.value == becomeRaffleCreatorFee, "Please transfer the correct amount as stated in becomeRaffleCreatorFee.");
        raffleCreators[msg.sender].isRaffleCreator = true;

    }

    function removeRaffleCreator(address raffleCreator) public onlyOwner {

        raffleCreators[raffleCreator].isRaffleCreator = false;
    }

    function addRaffleCreator(address raffleCreator) public onlyOwner {

        raffleCreators[raffleCreator].isRaffleCreator = true;

    }

    function setBecomeRaffleCreatorFee(uint256 _becomeRaffleCreatorFee) public onlyOwner {

        becomeRaffleCreatorFee = _becomeRaffleCreatorFee;

    }

    function withdrawalFunds() external onlyOwner {      

        payable(owner()).transfer(address(this).balance);
        
    }

    function getRaffleArray() external view returns (Raffle[] memory) {
        
        return raffleArray;
    
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

pragma solidity 0.8.17;

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

    // raffleCreator will provide the NFT prize to the contract
    address public raffleCreator;
    
    // set address of developer
    address public developer;
    
    // set deployment date once NFT is received by the contract
    uint256 public deployDate;

    // set raffle duration in days (is set after NFT has been recieved by contract)
    uint256 public durationDays;

    // set raffle name, total tickets, ticket price, tickets left, max tickets per wallet
    string public raffleName;
    uint256 public totalTickets;
    uint256 public ticketPrice;
    uint256 public ticketsLeft;
    uint256 public maxTicketsPerWallet;
    
    // set fee addresses and fee percentages
    address[] public feeAddresses;
    uint256[] public feePercentages;

    // set the contract address and token id of the NFT prize
    address public nftContract;
    uint256 public nftTokenId;

    // save all ticket buy address in raffleBox
    address[] public raffleBox;

    // contract address and request id for RNGesus
    address public rngesusContract;
    uint256 public rngesusRequestId;
    
    // set the winner once drawn
    address public winner;

    // keep a struct with player info
    // how many tickets a player bought
    // and if the player has been refunded
    struct Player {
        uint256 ticketsBought;
        bool isRefunded;
    }

    // mapping from address to Player struct
    mapping(address => Player) public players;

    // raffle state
    // WAITING_FOR_NFT      - the contract has just been deployed, the raffle creator can now send the NFT
    // TICKET_SALE_OPEN     - once the NFT has been received by this contract, players can now join the raffle
    // DRAW_WINNER          - when all tickets are sold, the raffle creator can start the draw winner process and request a random number from RNGesus
    // WAITING_FOR_PAYOUT   - once the random number has been received, the winner will get the NFT, 
    //                          the ETH will be send to the fee addresses
    // RAFFLE_FINISHED      - the raffle is finished, thank you for playing
    // CLAIM_REFUND         - if the raffle has not been concluded after X days, players OR the raffle creator can request to put this contract in CLAIM_REFUND state
    //                          in this state players can claim back the ETH they transfered for the tickets, the raffle creator can claim back the nft. NO RUG PULLS!  
    enum RAFFLE_STATE {
        WAITING_FOR_NFT,
        TICKET_SALE_OPEN,
        DRAW_WINNER,
        WAITING_FOR_PAYOUT,
        RAFFLE_FINISHED,
        CLAIM_REFUND
    }

    // raffleState variable
    RAFFLE_STATE public raffleState;

    // event for when the winner is drawn
    event Winner(address winner);

    constructor(
        string memory _raffleName,
        uint256 _ticketPrice, 
        uint256 _totalTickets, 
        address _rngesusContract, 
        address _raffleCreator,
        address[] memory _feeAddresses,
        uint256[] memory _feePercentages,
        uint256 _durationDays,
        uint256 _maxTicketsPerWallet,
        address _developer
        ) {

        // transfer ownership of this contract to the raffleCreator
        transferOwnership(_raffleCreator);

        // max 1000 ticket per raffle, min 10 tickets
        require(_totalTickets <= 5000, "Maximum tickets is 5000.");
        require(_totalTickets >= 10, "Minimum tickets is 10.");
        require(_durationDays >= 3, "Minimum duration is 3 days.");
        require(_durationDays <= 10, "Maximum duration is 10 days.");
        require(_maxTicketsPerWallet > 0, "Max tickets per wallet, should be at least 1.");
        require(_feeAddresses.length == _feePercentages.length, "Length of _feeAddresses and _feePercetages should be the same.");
        require(checkFeePercentages(_feePercentages), "Fee Percentages does not equal 100.");

        // set contract variables
        raffleName = _raffleName;
        totalTickets = _totalTickets;
        ticketsLeft = _totalTickets;  // no sales yet, same as totalTickets
        ticketPrice = _ticketPrice;
        rngesusContract = _rngesusContract;
        durationDays = _durationDays;
        maxTicketsPerWallet = _maxTicketsPerWallet;
        feeAddresses = _feeAddresses;
        feePercentages = _feePercentages;
        developer = _developer;

        // set raffle_state to WAITING_FOR_NFT
        raffleState = RAFFLE_STATE.WAITING_FOR_NFT;

    }

    function checkFeePercentages(uint256[] memory _feePercentages) internal pure returns(bool) {

        // create empty uint256 totalFeePercentage
        uint256 totalFeePercentage;

        // loop through _feePercentages array
        for (uint256 feePercentagesIndex = 0; feePercentagesIndex < _feePercentages.length; feePercentagesIndex++) {

            // add _feePercentage to totalFeePercentage
            totalFeePercentage += _feePercentages[feePercentagesIndex];

        }

        // check if totalFeePercentage is 100 or not
        if (totalFeePercentage == 100) {
            return true;
        }
        else {
            return false;
        }

    }

    // get contract variables
    // a function so ugly, only a mother can love
    function getContractVariables() public view returns (bytes memory, bytes memory) {

        bytes memory a = abi.encode(
            durationDays, deployDate, raffleName, totalTickets, ticketPrice, maxTicketsPerWallet
        );

        bytes memory b = abi.encode(
            ticketsLeft, nftContract, nftTokenId, winner, raffleState, raffleCreator
        );

        return (a, b);

    }

    // the raffle creator transfers the NFT prize to the contract
    // the NFT must be approved for this contract by the owner before calling this funcion
    function transferNftToRaffle(address _nftContract, uint256 _nftTokenId) public nonReentrant onlyOwner {
        
        // require raffle state is WAITING_FOR_NFT
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

    function buyTicket(uint256 _amountOfTickets, address _referral) public payable nonReentrant {
        
        // check if raffle state is TICKET_SALE_OPEN
        require(raffleState == RAFFLE_STATE.TICKET_SALE_OPEN, "You can't buy tickets at this time.");
        
        require(msg.sender != _referral, "You can't refer yourself, this is not a clown fiesta!");

        // check if correct amount of ETH is send
        require(msg.value == _amountOfTickets * ticketPrice, "Incorrect value for the amount of tickets.");

        // check if enough tickets are left
        require(ticketsLeft >= _amountOfTickets, "Not enough tickets left, buy less.");

        // check if this wallet already purchased the maximum amount of tickets
        require(players[msg.sender].ticketsBought != maxTicketsPerWallet, "You already purchased the maximum amount of tickets for this wallet.");

        // check if this wallet haven't reach maxTicketsPerWallet when purchasing tickets
        require(players[msg.sender].ticketsBought + _amountOfTickets <= maxTicketsPerWallet, "Purchase less tickets, otherwise you will exceed maximum amount of tickets for this wallet.");
        
        // loop through amountOfTickets
        for (uint256 amountOfTicketsIndex = 0; amountOfTicketsIndex < _amountOfTickets; amountOfTicketsIndex++) {
            
            // add player address to raffleBox array for each ticket
            raffleBox.push(msg.sender);

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

        // pray to RNGesus to request a random number
        rngesusRequestId = IRNGesus(rngesusContract).prayToRngesus{value: msg.value}(_gweiForFulfillPrayer);

        // set raffle state to WAITING_FOR_PAYOUT
        raffleState = RAFFLE_STATE.WAITING_FOR_PAYOUT;

        return rngesusRequestId;

    }

    // once a random number has been created by RNGesus, transfer the NFT to the winner and pay the fee addresses
    function payOut() public nonReentrant {

        // check if the raffle_state is WAITING_FOR_PAYOUT
        require(raffleState == RAFFLE_STATE.WAITING_FOR_PAYOUT, "You can't pay out at this time.");

        // get random number from RNGesus
        uint256 randomNumber = IRNGesus(rngesusContract).randomNumbers(rngesusRequestId);

        // make sure that RNGesus created a random number, it will return 0 if it has not been created yet
        require(randomNumber != 0, "RNGesus has not created a random number yet, please wait a few minutes.");

        // get the winning ticket (index of raffleBox)
        uint256 winning_ticket = randomNumber % totalTickets;

        // get winner_address from winning ticket from raffleBox 
        address winner_address = raffleBox[winning_ticket];

        // emit message to tx logs
        emit Winner(winner_address);

        // transfer NFT to winner
        IERC721(nftContract).safeTransferFrom(address(this), winner_address, nftTokenId);

        // pay all fee addresses their share
        uint256 onePercent = address(this).balance / 100;

        // loop through all fee addresses and pay all parties
        for (uint256 feeAddressIndex = 0; feeAddressIndex < feeAddresses.length; feeAddressIndex++) {

            // extra security measure
            // the final fee address will receive the remaining balance of the contract
            // this to avoid any lock ups (when we want to transfer more than is availabe)
            // and to make sure that no ETH is left in the contract
            if (feeAddressIndex == feeAddresses.length - 1) {
                payable(feeAddresses[feeAddressIndex]).transfer(address(this).balance);
            }
            else {
                uint256 transferAmount = onePercent * feePercentages[feeAddressIndex];
                payable(feeAddresses[feeAddressIndex]).transfer(transferAmount);
            }

        }

        // set raffle state to RAFFLE_FINISHED
        raffleState = RAFFLE_STATE.RAFFLE_FINISHED;

    }

    // all players can request a refund after the raffle duration days has elapsed
    // initialze CLAIM_REFUND state, so players can claim their ticket price
    // raffle creator can claim NFT back
    function requestRefund() public nonReentrant {

        // check if duration days has passed
        require(block.timestamp >= (deployDate + (durationDays * 86400)), "Refunds can not be requested yet.");

        // check if requester bought at least 1 ticket
        require(players[msg.sender].ticketsBought > 0, "You didn't buy any tickets, why request a refund?");

        // check if raffle state is TICKET_SALE_OPEN, refunds can only be requested when not all tickets are sold
        require(raffleState == RAFFLE_STATE.TICKET_SALE_OPEN, "You can't request a refund at this time.");

        // set raffle state to CLAIM_REFUND
        raffleState = RAFFLE_STATE.CLAIM_REFUND;

    }

    // claim refund 
    function claimRefund() public nonReentrant {

        // check if raffle state is CLAIM_REFUND
        require(raffleState == RAFFLE_STATE.CLAIM_REFUND, "You can't claim a refund at this time.");

        // check if player already requested a refund
        require(players[msg.sender].isRefunded == false, "You are already refunded.");

        // check if the player bought tickets
        require(players[msg.sender].ticketsBought > 0, "You didn't buy any tickets, why claim a refund?");

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
    function cancelRaffle() public onlyOwner nonReentrant {

        // check if raffle state is OPEN
        require(raffleState == RAFFLE_STATE.TICKET_SALE_OPEN, "You can't cancel the raffle at this time.");

        // check if duration days has passed
        require(block.timestamp >= (deployDate + (durationDays * 86400)), "Refunds can not be requested yet.");

        // set raffle state to CLAIM_REFUND
        raffleState = RAFFLE_STATE.CLAIM_REFUND;

    }
    
    // return NFT to raffleCreator when the raffleState is CLAIM_REFUND
    function returnNftToRaffleCreator() public onlyOwner nonReentrant {

        require(raffleState == RAFFLE_STATE.CLAIM_REFUND, "You can only return the NFT to you when the raffle is canceled.");

        // check if this contract is the owner of the NFT        
        require(address(this) == IERC721(nftContract).ownerOf(nftTokenId), "This contract is not the owner of the NFT.");

        // transfer NFT back to raffleCreator
        IERC721(nftContract).safeTransferFrom(address(this), raffleCreator, nftTokenId);

    }

    // in case the contract gets locked, the developer can set the state to CLAIM_REFUND
    function failSafe() public {

        require(msg.sender == developer, "Don't touch this button!");
        raffleState = RAFFLE_STATE.CLAIM_REFUND;

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