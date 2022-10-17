/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

// SPDX-License-Identifier: MIT
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
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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

interface IToken{
    function balanceOf(address owner) external view returns (uint256 balance);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
    function transfer(address to,uint256 amount) external returns (bool);
}

interface INFT{
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract StakingRewards is Ownable, ReentrancyGuard{
    IToken private _token;
    INFT private _nft;
    address public treasury;

    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) private _userRewardPerTokenPaid;
    mapping(address => uint256) private _rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    uint256 public period;
    uint256 public rate;
    uint256 public start;

    mapping(address => bool) public _admin;


    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = _blockTime();
        if (account != address(0)) {
            _rewards[account] = earned(account);
            _userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier onlyAdmin() {
        require(_admin[msg.sender] || msg.sender==owner(), "Caller is not the an admin");
        _;
    }

    constructor(address tokenAddress, address nftAddress, address treasury_, uint256 period_, uint256 rate_) {
        _token = IToken(tokenAddress);
        _nft = INFT(nftAddress);
        treasury = treasury_;
        period = period_;
        rate = rate_;
        start = block.timestamp;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function rewardRate() public view returns (uint256) {
        if (_blockTime() < period + start) return rate;
        return 0;
    }

    function apr() public view returns (uint256) {
        if (_totalSupply == 0) return 0;
        if(_blockTime()>start + period) return 0;
        return (rewardRate() * 1e5 * 365 * 24 * 60 * 60) / _totalSupply;
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) return a;
        return b;
    }

    function _getPeriod() private view returns (uint256){
        uint256 periodEnd = start + period;
        if (periodEnd > _blockTime()) {
            uint256 lastUpdate = _max(lastUpdateTime, start);
            return _blockTime() - lastUpdate;
        } else {
            return 0; 
        }
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) return rewardPerTokenStored;
        return rewardPerTokenStored + (_getPeriod() * rate * 1e18) / _totalSupply;
    }

    function earned(address account) public view returns (uint256){
        //if (_totalSupply == 0) return 0;
        return ((_balances[account] * (rewardPerToken() - _userRewardPerTokenPaid[account])) / 1e18) 
            + _rewards[account];
    }

    function _blockTime() private view returns (uint256){
        return block.timestamp;
        /***** for testing only *******/
        //return _blocktimestamp;
    }

    function canStake() public view returns (bool){
        return _nft.balanceOf(msg.sender)>0;
    }

    function deposit(uint256 amount) external nonReentrant updateReward(msg.sender){
        require(_token.balanceOf(msg.sender)>0 && _nft.balanceOf(msg.sender)>0,"Invalid Wallet");
        _balances[msg.sender] += amount;
        _totalSupply += amount;
        _token.transferFrom(msg.sender, address(this), amount);
    }


    function exit() public nonReentrant {
        uint256 amount = _balances[msg.sender];
        uint256 reward = earned(msg.sender);
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = _blockTime();
        _userRewardPerTokenPaid[msg.sender] = rewardPerTokenStored;
        _totalSupply -= amount;
        _balances[msg.sender] = 0;
        _rewards[msg.sender] = 0;
        _token.transferFrom(treasury, msg.sender, reward);
        _token.transfer(msg.sender, amount);
    }

    ///////Admin Functions///////
    function setPeriod(uint256 period_) public onlyAdmin{
        period = period_;
    }

    function setRate(uint256 rate_) public onlyAdmin{
        rate = rate_;
    }   

    function setAdmin(address admin, bool hasAccess) public onlyAdmin{
        _admin[admin] = hasAccess;
    }
    

}