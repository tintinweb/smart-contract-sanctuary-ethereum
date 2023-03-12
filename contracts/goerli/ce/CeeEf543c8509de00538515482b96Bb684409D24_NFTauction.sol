/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}


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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */

library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
        return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param owner address The address which owns the funds.
    * @param spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(
        address owner,
        address spender
    )
        public
        view
        returns (uint256)
    {
        return _allowed[owner][spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= _balances[msg.sender]);
        require(to != address(0));

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param spender The address which will spend the funds.
    * @param value The amount of tokens to be spent.
    */
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    */
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        public
        returns (bool)
    {
        require(value <= _balances[from]);
        require(value <= _allowed[from][msg.sender]);
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed_[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param spender The address which will spend the funds.
    * @param addedValue The amount of tokens to increase the allowance by.
    */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
        public
        returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed_[_spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param spender The address which will spend the funds.
    * @param subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
        public
        returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev Internal function that mints an amount of the token and assigns it to
    * an account. This encapsulates the modification of balances such that the
    * proper events are emitted.
    * @param account The account that will receive the created tokens.
    * @param amount The amount that will be created.
    */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0));
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
    * @dev Internal function that burns an amount of the token of a given
    * account.
    * @param account The account whose tokens will be burnt.
    * @param amount The amount that will be burnt.
    */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0));
        require(amount <= _balances[account]);

        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
    * @dev Internal function that burns an amount of the token of a given
    * account, deducting from the sender's allowance for said account. Uses the
    * internal burn function.
    * @param account The account whose tokens will be burnt.
    * @param amount The amount that will be burnt.
    */
    function _burnFrom(address account, uint256 amount) internal {
        require(amount <= _allowed[account][msg.sender]);

        // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
        // this function needs to emit an event with the updated approval.
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
        amount);
        _burn(account, amount);
    }
}

library SafeERC20 {
    using SafeMath for uint256;
        
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    )
        internal
    {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    )
        internal
    {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    )
        internal
    {
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }
    
    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    )
        internal
    {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }
    
    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    )
        internal
    {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}

interface IERC721 {
    function safeTransferFrom(address from, address to, uint tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract NFTauction is Ownable, ReentrancyGuard {
    
    using SafeERC20 for IERC20;

    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    enum CouponType {
        Mint,
        PostMint
    }

    struct AuctionItem {
        address creator;
        address lastBidder;
        uint256 bidPrice;
        uint256 startTime;
        uint256 expireTime;
        uint256 royaltyPercentage;
        uint256 auctionType; // 0: mint case 1: post-mint case
        bool notCancelled;
    }

    mapping(address => mapping(uint256 => AuctionItem)) public auctionItems;
    mapping(address => mapping(address => bool)) public curators;
    mapping(address => bool) public supportedContracts;

    uint256 private minDuration = 600;
    uint256 private maxDuration = 2592000;
    address private couponSigner = 0x802A58454Be713142f5188b8264e3CC9478F4935;
    // address public ss;
    // address private paymentToken = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; // weth on goerli
    // address private paymentToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // weth on mainnet

    event AddedContract(address nftContract);
    event AddedCurator(address nftContract, address curator);
    event RemovedContract(address nftContract);
    event AuctionStarted(
        address nftContract,
        address creator,
        uint256 tokenId,        
        uint256 startPrice,
        uint256 startTime,
        uint256 expireTime,
        uint256 auctionType
    );

    event BidCreated(
        address nftContract,
        address lastBidder,
        uint256 tokenId,
        uint256 lastBidPrice
    );

    event AuctionCancelled(
        address nftContract,
        uint256 tokenId
    );

    event AuctionExtended(
        address nftContract,
        uint256 tokenId,
        uint256 newExpireTime
    );

    event AuctionEnded(
        address nftContract,
        address auctionWinner,
        uint256 tokenId,
        uint256 auctionPrice
    );

    error AlreadyAdded(address nftContract);
    error AlreadyRemoved(address nftContract);
    error InvalidDuration(uint256 duration);
    error InvalidBidPrice(uint256 bidPrice);
    error TransferFailed();
 
    modifier OnlyCuratorORItemOwner(address nftContract, uint256 tokenId) {
        IERC721 tokenContract = IERC721(nftContract);
        require(tokenContract.ownerOf(tokenId) == msg.sender || curators[nftContract][msg.sender] == true);
        _;
    }

    modifier HasTransferApproval(address nftContract, uint256 tokenId) {
        IERC721 tokenContract = IERC721(nftContract);
        require(tokenContract.getApproved(tokenId) == address(this) || tokenContract.isApprovedForAll(msg.sender, address(this)));
        _;
    }

    modifier OnlySupportedContract(address nftContract) {
        require(supportedContracts[nftContract] == true);
        _;
    }

    modifier onlyAfterStart(address nftContract, uint256 tokenId) {
        require(block.timestamp > auctionItems[nftContract][tokenId].startTime);
        _;
    }

    modifier onlyBeforeEnd(address nftContract, uint256 tokenId) {
        require(block.timestamp < auctionItems[nftContract][tokenId].expireTime);
        _;
    }

    modifier onlyNotCancelled(address nftContract, uint256 tokenId) {
        require(auctionItems[nftContract][tokenId].notCancelled == true);
        _;
    }

    // modifier validBidCheck(address nftContract, uint256 tokenId, uint256 bidPrice) {
    //     require(auctionItems[nftContract][tokenId].lastBidPrice < bidPrice);
    //     _;
    // }

    function _isVerifiedCoupon(bytes32 digest, Coupon memory coupon) internal view returns (bool) {
        address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
        require(signer != address(0), "zero-address");
        return signer == couponSigner;
    }

    function addCurators(address nftContract, address curator) external onlyOwner {
        address _nftContract = nftContract;
        address _curator = curator;
        if (curators[_nftContract][_curator] == true) {
            revert AlreadyAdded(_curator);
        }
        curators[_nftContract][_curator] == true;
        emit AddedCurator(_nftContract, _curator);
    }

    function addSupportedContract(address nftContract) external onlyOwner {
        address _nftContract = nftContract;
        if (supportedContracts[_nftContract] == true) {
            revert AlreadyAdded(_nftContract);
        }
        supportedContracts[_nftContract] = true;
        emit AddedContract(_nftContract);
    }

    function removeSupportedContract(address nftContract) external onlyOwner {
        address _nftContract = nftContract;
        if (supportedContracts[_nftContract] == false) {
            revert AlreadyRemoved(_nftContract);
        }
        supportedContracts[_nftContract] = false;
        emit RemovedContract(_nftContract);
    }

    function createAuction(
        address nftContract, 
        uint256 tokenId, 
        uint256 bidPrice, 
        uint256 duration, 
        uint256 royaltyPercentage,
        uint256 auctionType
    ) 
        external
        OnlyCuratorORItemOwner(nftContract, tokenId)
        OnlySupportedContract(nftContract)
    {
        if (duration < minDuration || duration > maxDuration) {
            revert InvalidDuration(duration);
        }

        if (bidPrice == 0) {
            revert InvalidBidPrice(bidPrice);
        }

        uint256 startTime = block.timestamp;
        uint256 expireTime = startTime + duration;
        auctionItems[nftContract][tokenId] = AuctionItem(
            msg.sender,
            address(0),
            bidPrice,
            startTime,
            expireTime,
            royaltyPercentage,
            auctionType,
            true
        );

        emit AuctionStarted(
            nftContract,
            msg.sender,
            tokenId,        
            bidPrice,
            startTime,
            expireTime,
            auctionType
        );
    }

    function cancelAuction(address nftContract, uint256 tokenId) 
        external 
        OnlyCuratorORItemOwner(nftContract, tokenId) 
        onlyNotCancelled(nftContract, tokenId)
        returns (bool success)
    {
        auctionItems[nftContract][tokenId].notCancelled = false;
        emit AuctionCancelled(nftContract, tokenId);
        return true;
    }

    function getDigest(
        uint256 auctionType,
        uint256 tokenId,
        uint256 bidPrice,
        address nftContract
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(auctionType, tokenId, bidPrice, nftContract));
    }

    function placeBid(
        uint256 auctionType,
        uint256 tokenId,
        uint256 bidPrice,
        address nftContract, 
        Coupon memory coupon
    ) 
        public returns (bool)
    {
        // require(auctionItems[nftContract][tokenId].notCancelled == true, "cancelled");

        bytes32 digest = getDigest(auctionType, tokenId, bidPrice, nftContract);

        // ss = ecrecover(digest, coupon.v, coupon.r, coupon.s);
        require(_isVerifiedCoupon(digest, coupon), "Invalid Coupon");
        // uint256 expireTime = auctionItems[nftContract][tokenId].expireTime;

        // if (block.timestamp + 300 > expireTime) {
        //     auctionItems[nftContract][tokenId].expireTime = expireTime + 600;
        // }

        // // auctionItems[nftContract][tokenId].lastBidPrice = bidPrice;
        // auctionItems[nftContract][tokenId].lastBidder = msg.sender;
        // // IERC20(paymentToken).safeApprove(address(this), bidPrice);

        // emit BidCreated(nftContract, msg.sender, tokenId, bidPrice);

        return true;
    }

    // function claimNFT(address nftContract, uint256 tokenId)
    //     public nonReentrant
    //     OnlyCuratorORItemOwner(nftContract, tokenId)
    //     onlyNotCancelled(nftContract, tokenId)
    // {
    //     require(
    //         auctionItems[nftContract][tokenId].expireTime <= block.timestamp,
    //         "active-auction"
    //     );

    //     address _auctionWinner = auctionItems[nftContract][tokenId].lastBidder;
    //     uint256 auctionPrice = auctionItems[nftContract][tokenId].lastBidPrice;
    //     uint256 servicePercentage = auctionItems[nftContract][tokenId].royaltyPercentage;
    //     uint256 _serviceFee = (auctionPrice * servicePercentage) / 10000;
    //     uint256 finalPrice = auctionPrice - _serviceFee;

    //     // IERC20(paymentToken)
    //     //     .safeTransferFrom(
    //     //         _auctionWinner,
    //     //         address(this),
    //     //         auctionPrice
    //     //     );
    //     // IERC20(paymentToken).safeTransfer(
    //     //     msg.sender,
    //     //     finalPrice
    //     // );

    //     IERC721(nftContract).safeTransferFrom(
    //         msg.sender,
    //         _auctionWinner,
    //         tokenId
    //     );

    //     emit AuctionEnded(
    //         nftContract,
    //         _auctionWinner,
    //         tokenId,
    //         auctionPrice
    //     );
    // }

    function extendAuction(address nftContract, uint256 tokenId, uint256 extensionDuration) 
        public nonReentrant
        OnlyCuratorORItemOwner(nftContract, tokenId)
    {
        uint256 expireTime = auctionItems[nftContract][tokenId].expireTime;
        uint256 startTime = auctionItems[nftContract][tokenId].startTime;
        uint256 newExpireTime = expireTime + extensionDuration;
        uint256 newDuration = newExpireTime - startTime;

        if (newDuration > maxDuration) {
            revert InvalidDuration(newDuration);
        }

        auctionItems[nftContract][tokenId].expireTime = newExpireTime;

        emit AuctionExtended(nftContract, tokenId, newExpireTime);
    }

    function withdraw() public onlyOwner {
        // uint256 wethBalance = IERC20(paymentToken).balanceOf(address(this));
        // if (wethBalance > 0) {
        //     IERC20(paymentToken).safeTransfer(
        //         msg.sender,
        //         wethBalance
        //     );
        // }
    }

    function _transfer(address to, uint256 amount) internal {
        bool callStatus;
        assembly {
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }
        if (!callStatus) revert TransferFailed();
    }
}