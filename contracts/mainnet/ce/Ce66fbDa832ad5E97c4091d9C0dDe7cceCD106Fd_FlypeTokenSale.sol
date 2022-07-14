// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
pragma solidity 0.8.10;
import "./IFlypeNFT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FlypeTokenSale is Ownable, ReentrancyGuard{
    /// @notice Contains parameters, necessary for the pool
    /// @dev to see this parameters use getPoolInfo, checkUsedAddress and checkUsedNFT functions
    struct PoolInfo
    {
        uint256 takenSeats;
        uint256 maxSeats;
        uint256 maxTicketsPerUser;
        uint256 ticketPrice;
        uint256 ticketReward;
        uint256 lockup;
        mapping(address => uint256) takenTickets;
    }
    
    /// @notice pool ID for Econom class
    uint256 constant public ECONOM_PID = 0;
    /// @notice pool ID for Buisness class
    uint256 constant public BUISNESS_PID = 1;
    /// @notice pool ID for First class
    uint256 constant public FIRST_CLASS_PID = 2;
    
    /// @notice address of Flype NFT
    IFlypeNFT public immutable Flype_NFT;

    /// @notice address of USDC
    IERC20 public immutable USDC;
    /// @notice True if minting is paused 
    bool public onPause;

    mapping(uint256 => PoolInfo) poolInfo;
    mapping(address => bool) public banlistAddress;

    /// @notice Restricts from calling function with non-existing pool id 
    modifier poolExist(uint pid){
        require(pid <= 2, "Wrong pool ID");
        _;
    }

    /// @notice Restricts from calling function when sale is on pause
    modifier OnPause(){
        require(!onPause, "Pool is on pause");
        _;
    }

    /// @notice event emmited on each token sale
    /// @dev all events whould be collected after token sale and then distributed
    /// @param user address of buyer
    /// @param pid pool id
    /// @param takenSeat № of last taken seat
    /// @param blockNumber on which block transaction was mined
    /// @param timestamp timestamp on the block when it was mined
    event Sale(
        address indexed user, 
        uint256 pid, 
        uint256 takenSeat, 
        uint256 reward,
        uint256 lockup,
        uint256 blockNumber, 
        uint256 timestamp
    );

    /// @notice event emmited on each pool initialization
    /// @param pid pool id
    /// @param takenSeat № of last taken seat
    /// @param maxSeats maximum number of participants
    /// @param ticketPrice amount of usdc which must be approved to participate
    /// @param ticketReward reward, which must be sent
    /// @param blockNumber on which block transaction was mined
    /// @param timestamp timestamp on the block when it was mined
    event InitializePool(
        uint256 pid, 
        uint256 takenSeat,
        uint256 maxSeats,
        uint256 maxTicketsPerUser,
        uint256 ticketPrice,
        uint256 ticketReward,
        uint256 lockup,
        uint256 blockNumber, 
        uint256 timestamp
    );

    /// @notice Performs initial setup.
    /// @param _FlypeNFT address of Flype NFT
    constructor(IFlypeNFT _FlypeNFT, IERC20 _USDC) ReentrancyGuard(){
        Flype_NFT = _FlypeNFT;
        USDC = _USDC;
    }

    /// @notice Function that allows contract owner to initialize and update update pool settings
    /// @param pid pool id
    /// @param _maxSeats maximum number of participants
    /// @param _ticketPrice amount of usdc which must be approved to participate
    /// @param _ticketReward reward, which must be sent
    /// @param _lockup time before token can be collected
    function initializePool(
        uint256 pid, 
        uint256 _maxSeats, 
        uint256 _maxTicketPerUser,
        uint256 _ticketPrice, 
        uint256 _ticketReward,
        uint256 _lockup) 
        external 
        onlyOwner
        poolExist(pid)
    {
        PoolInfo storage pool = poolInfo[pid];
        pool.maxSeats = _maxSeats;
        pool.ticketPrice = _ticketPrice;
        pool.ticketReward = _ticketReward;
        pool.lockup = _lockup;
        pool.maxTicketsPerUser = _maxTicketPerUser;
        emit InitializePool(
            pid, 
            pool.takenSeats,
            pool.maxSeats,
            pool.maxTicketsPerUser,
            pool.ticketPrice,
            pool.ticketReward,
            pool.lockup,
            block.number, 
            block.timestamp
        );
    }

    /// @notice Function that allows contract owner to ban address from sale
    /// @param user address which whould be banned or unbanned
    /// @param isBanned state of ban
    function banAddress(address user, bool isBanned) external onlyOwner{
        banlistAddress[user] = isBanned;
    }

    /// @notice Function that allows contract owner to pause sale
    /// @param _onPause state of pause
    function setOnPause(bool _onPause) external onlyOwner{
        onPause = _onPause;
    }

    /// @notice Function that allows contract owner to receive all available usdc from sale
    /// @param receiver address which whould receive usdc
    function takeAllTokens(address receiver) external onlyOwner{
        _takeTokens(receiver, USDC.balanceOf(address(this)));
    }

    /// @notice Function that allows contract owner to receive usdc from sale
    /// @param receiver address which whould receive usdc
    /// @param amount amount of usdc to transfer to receiver
    function takeTokens(address receiver, uint256 amount) external onlyOwner{
        _takeTokens(receiver, amount);
    }

    /// @notice emit Sale event for chosen pool
    /// @param pid Pool id 
    function buyTokens (
        uint256 pid,
        uint256 amountOfTickets
    )
    external
    OnPause
    nonReentrant
    poolExist(pid)
    {
        require(!banlistAddress[_msgSender()], "This address is banned");
        require(amountOfTickets > 0, "Amount of tickets cannot be zero");
        require(Flype_NFT.allowList(_msgSender()), "NFT isn't on the balance");
        PoolInfo storage pool = poolInfo[pid];  
        require(pool.takenSeats < pool.maxSeats, "No seats left");  
        require(pool.takenTickets[_msgSender()] < pool.maxTicketsPerUser, "User cannot buy more than maxTicketsPerUser");
        uint256 toTransfer;
        for(
            uint256 i = 0; i < amountOfTickets 
                && pool.takenSeats < pool.maxSeats
                && pool.takenTickets[_msgSender()] < pool.maxTicketsPerUser; 
            i++
        ){
            toTransfer += pool.ticketPrice;
            pool.takenSeats++;
            pool.takenTickets[_msgSender()]++;
            emit Sale(
                _msgSender(), 
                pid, 
                pool.takenSeats, 
                pool.ticketReward,
                pool.lockup,
                block.number, 
                block.timestamp
            );        
        }
        if(toTransfer > 0) USDC.transferFrom(_msgSender(), address(this), toTransfer);
    }

    /// @notice get pool setting and parameters
    /// @param pid pool id
    /// @return takenSeats № of last taken seat
    /// @return maxSeats maximum number of participants
    /// @return maxTicketsPerUser maximum number of participations per user
    /// @return ticketPrice amount of usdc which must approve to participate in pool
    function getPoolInfo(uint256 pid) 
    external 
    poolExist(pid) 
    view 
    returns(
        uint256 takenSeats,
        uint256 maxSeats,
        uint256 maxTicketsPerUser,
        uint256 ticketPrice,
        uint256 ticketReward,
        uint256 lockup
        )
    {
        return 
        (
            poolInfo[pid].takenSeats,
            poolInfo[pid].maxSeats,
            poolInfo[pid].maxTicketsPerUser,
            poolInfo[pid].ticketPrice,
            poolInfo[pid].ticketReward,
            poolInfo[pid].lockup
        );
    }

    function getUserTicketsAmount(uint256 pid, address user) external view returns(uint256){
        return(poolInfo[pid].takenTickets[user]);
    }

    /// @notice Function that transfer usdc from sale to given address
    /// @param receiver address which whould receive usdc
    /// @param amount amount to transfer
    function _takeTokens(address receiver, uint256 amount) internal{
        USDC.transfer(receiver, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IFlypeNFT{
    function allowList(address user) external view returns(bool); 
}