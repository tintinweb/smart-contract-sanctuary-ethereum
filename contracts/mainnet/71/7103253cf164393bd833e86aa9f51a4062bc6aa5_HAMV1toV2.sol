/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

/**
Migrate your $HAM from V1 to V2
*/

pragma solidity 0.8.15;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier:MIT

// ERC20 token standard interface
interface IERC20 {
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `_account`.
     */
    function balanceOf(address _account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's _account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Emitted when `value` tokens are moved from one _account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// Dex Factory contract interface
interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// Dex Router02 contract interface
interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the _account sending and
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
 * there is an _account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner _account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any _account other than the owner.
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new _account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    /**
     * @dev set the owner for the first time.
     * Can only be called by the contract or deployer.
     */
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
     * by making the `nonReentrant` function external, and make it call a
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

// Main Contract
contract HAMV1toV2 is Ownable, ReentrancyGuard {
    //using SafeMath for uint256;

    struct UserInfo {
        uint256 depositeddAmountV1;
        bool claimed;
    }

    mapping(address => UserInfo) public userInfo;

    event Log(string, uint256);
    event AuditLog(string, address);

    uint256 public totalDepositedAmountV1;
    uint256 public totalClaimedAmountV2;
    uint256 public rate = 1;
    bool public openForDeposit = false;

    uint256 public treasureAmountV2;
    
    IERC20 public tokenV1 = IERC20(0x2238796FB82aa4E989a1E96bFD0c4412550C4904); //HAM V1 Contract
    IERC20 public tokenV2 = IERC20(0xEAd485158Ee12f43B03cC0612dcb006DAb4731cC); //HAM V2 Contract
    address public tokenV2Pair = 0x7C82350B8B5861b9B593F3b3844C3aE2cb7734E5;
    address public constant HAMMultiSig =
        0x904Ce75fbcf15dc6D14ACe599181D7D66BdFc4E7;

    function depositV1(uint256 amount) external nonReentrant{
        require(openForDeposit, "Not in deposit period");

        tokenV1.transferFrom(msg.sender, address(this), amount);
        totalDepositedAmountV1 = totalDepositedAmountV1 + amount;
        userInfo[msg.sender].depositeddAmountV1 = userInfo[msg.sender].depositeddAmountV1 + amount;
        userInfo[msg.sender].claimed = false;
        emit AuditLog("The deposit has been successfull for the holder:",msg.sender);
        emit Log("They have deposited a total of:",amount);
    }

    function claimV2() external nonReentrant{
        require(tokenV2.balanceOf(tokenV2Pair) > 0, "Token hasn't launched yet");
        require(userInfo[msg.sender].depositeddAmountV1 > 0, "You haven't deposit V1 yet");
        require(userInfo[msg.sender].claimed == false, "You already claimed");
        
        uint256 claimAmount = userInfo[msg.sender].depositeddAmountV1 * 10;
        userInfo[msg.sender].claimed = true;
        userInfo[msg.sender].depositeddAmountV1 = 0;
        treasureAmountV2 -= claimAmount;
        totalClaimedAmountV2 += claimAmount;
        tokenV2.transfer(msg.sender, claimAmount);
        emit AuditLog("The claim has been successfull for the holder:",msg.sender);
        emit Log("They have claimed a total of:",claimAmount);
    }

    function claimableV2Amount(address account) public view returns (uint256) {
        if(userInfo[account].claimed){
            return 0;
        }
        return userInfo[account].depositeddAmountV1 * 10;
    }

    function addV2Token(uint256 amount) external nonReentrant {
        require(amount > 0, "You need to deposit more than 0 tokens.");
        tokenV2.transferFrom(msg.sender, address(this), amount);
        treasureAmountV2 = treasureAmountV2 + amount;
        emit AuditLog("The admin has successfully added tokens to the contract:",msg.sender);
        emit Log("The total added to the treasure is:",amount);
    }

    function depositOpen() external onlyOwner{
        require(openForDeposit != true, "Deposit is already open.");
        openForDeposit = true;
        emit AuditLog("The migration has been opened for deposits.",msg.sender);
    }

    function depositClose() external onlyOwner{
        require(openForDeposit != false, "Deposit is already closed.");
        openForDeposit = false;
        emit AuditLog("The migration has been closed for deposits.",msg.sender);
    }

    function withdrawV1() external onlyOwner{
        tokenV1.transfer(msg.sender, tokenV1.balanceOf(address(this)));
        emit AuditLog("The owner has successfully withdraw V1 Tokens.",msg.sender);
        emit Log("The total withdraw from contract is:",tokenV1.balanceOf(address(this)));
    }

    function withdrawV2() external onlyOwner{
        tokenV2.transfer(msg.sender, tokenV2.balanceOf(address(this)));
        emit AuditLog("The owner has successfully withdraw V2 Tokens.",msg.sender);
        emit Log("The total withdraw from contract is:",tokenV2.balanceOf(address(this)));
    }
    function updateSetup(address _tokenV2, address _v2Pair, address _migrationV1) external onlyOwner{
    require( _tokenV2 != address(0),"Token V2 Address need to start with : ZERO");
    require( _v2Pair != address(0),"Token V2 Pair Address need to start with : ZERO");
    require( _migrationV1 != address(0),"Token V2 Pair Address need to start with : ZERO");
        tokenV2 = IERC20(_tokenV2);
        tokenV2Pair = _v2Pair;
        tokenV1 = IERC20(_migrationV1);
        emit AuditLog("The Setup has been updated.",msg.sender);
    }
    function updateClaim (address _holder, bool _status) external onlyOwner {
        require(userInfo[msg.sender].claimed == true, "User can claim!, no need for update");
        userInfo[_holder].claimed = _status;
        emit AuditLog("The user claim has been updated.",msg.sender);
    }
}