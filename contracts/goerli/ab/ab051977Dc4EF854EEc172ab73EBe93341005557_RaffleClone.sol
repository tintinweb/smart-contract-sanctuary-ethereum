// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "Ownable.sol";
import "ReentrancyGuard.sol";
import "IERC721Receiver.sol";
import "Clones.sol";
import "Raffle.sol";

contract RaffleClone is Ownable {

    address immutable raffleImplementation;

    constructor() {
        raffleImplementation = address(new Raffle());
        transferOwnership(msg.sender);
    }

    function createRaffle (
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
        ) external {

            address raffle = Clones.clone(raffleImplementation);
            Raffle(raffle).initialize(_raffleName, _ticketPrice, _totalTickets, _rngesusContract, _raffleCreator, _feeAddresses, _feePercentages, _durationDays, _maxTicketsPerWallet, _developer);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "Ownable.sol";
import "ReentrancyGuard.sol";
import "IERC721Receiver.sol";
import "Initializable.sol";

interface IERC721 {
  function ownerOf(uint256 _tokenId) external view returns (address);
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IRNGesus {
    function prayToRngesus(uint256 _gweiForFulfillPrayer) external payable returns (uint256);
    function randomNumbers(uint256 _requestId) external view returns (uint256);
}

contract Raffle is Ownable, ReentrancyGuard, IERC721Receiver, Initializable {
    
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

    // save all player addresses in raffleBox
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

    function initialize(
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
        ) public initializer {

        // transfer ownership of this contract to the contract creator
        transferOwnership(_raffleCreator);

        // max 1000 ticket per raffle, min 10 tickets
        require(_totalTickets <= 5000, "Maximum tickets is 5000.");
        require(_totalTickets >= 10, "Minimum tickets is 10.");
        require(_durationDays >= 3, "Minimum duration is 3 days.");
        require(_durationDays <= 10, "Maximum duration is 10 days.");
        require(_maxTicketsPerWallet > 0, "Max tickets per wallet, should be at least 1.");
        require(_feeAddresses.length == _feePercentages.length, "Array length of _feeAddresses and _feePercentages should be the same.");
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
            ticketsLeft, nftContract, nftTokenId, winner, raffleState
        );

        return (a, b);

    }

    // the raffle creator transfers the NFT prize to the contract
    // the NFT must be approved for this contract by the owner before calling this funcion
    function transferNftToRaffle(address _nftContract, uint256 _nftTokenId) public nonReentrant onlyOwner {
        
        // require raffle state is WAITING_FOR_NFT
        require(raffleState == RAFFLE_STATE.WAITING_FOR_NFT, "Can't transfer a NFT a this time.");

        // transfer NFT to raffle contract
        IERC721(_nftContract).safeTransferFrom(owner(), address(this), _nftTokenId);

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
    
    // return NFT to contract owner when the raffleState is CLAIM_REFUND
    function returnNftToOwner() public onlyOwner nonReentrant {

        require(raffleState == RAFFLE_STATE.CLAIM_REFUND, "You can only return the NFT to you when the raffle is canceled.");

        // check if this contract is the owner of the NFT        
        require(address(this) == IERC721(nftContract).ownerOf(nftTokenId), "This contract is not the owner of the NFT.");

        // transfer NFT back to contract owner
        IERC721(nftContract).safeTransferFrom(address(this), owner(), nftTokenId);

    }

    // in case the contract gets locked, the developer can set the state to CLAIM_REFUND
    function failSafe() public {

        require(msg.sender == developer, "Don't touch this button!");
        raffleState = RAFFLE_STATE.CLAIM_REFUND;

    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}