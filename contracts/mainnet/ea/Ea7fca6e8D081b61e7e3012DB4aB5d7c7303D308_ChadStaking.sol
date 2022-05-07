/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

// SPDX-License-Identifier: MIT
// so much staking in teh LBC: RASTARYK 
//CHAD STAKING v1.7
 
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol
 
 
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
 
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol
 
 
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
 
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 
 
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
 
pragma solidity ^0.8.0;
 
 
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
 
// File: contracts/FunkieFly/FFLYStaking.sol
 
 
// Author : RASTARYK
 
pragma solidity ^0.8.0;
 
 
 
interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
}
 
interface IERC20 { 
    function decimals() external view returns (uint8);
 
    function balanceOf(address account) external view returns (uint256);
 
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
 
    event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract ChadStaking is Ownable, ReentrancyGuard {
    address public tokenAddress = 0xcAAEEA96a42ddA1c2045F198FEdF298Ed5aDB039; // Token address
    address public NFTaddress = 0xcCD3CBcc6d1135A69D0327440596D6D20cb49984; // NFT address
 
    IERC20 token = IERC20(tokenAddress);
    IERC721 nft = IERC721(NFTaddress);
 
    uint256 public launchTime;
    uint256 public totalDistributed;
    uint256 public tokensPerNFT; //Rewards percentage per NFT holding.
    uint256 public rewardDuration; //Duration in days for which rewards duration is application. If 1 then its daily (24 hrs) distribution
 
    mapping (address => uint256) public totalClaimed;
    mapping (address => uint256) public lastClaimed;
 
    event Claim(address recipient, uint256 value);
 
    constructor() {
        launchTime = block.timestamp;
        setRewardsPerNFT(1 * 10 ** 18);
        setRewardDuration(1 days);
    }
 
    function setRewardsPerNFT(uint256 _tokensPerNFT) public onlyOwner { //Pass rewards token in weis dor example 0.01 = 10000000000000000
        tokensPerNFT = _tokensPerNFT;
    }
 
    function setRewardDuration(uint256 _rewardDuration) public onlyOwner { //Pass duration in number of seconds for exaxmple 1 day = 86400 seconds
        rewardDuration = _rewardDuration;
    }
 
    function getUnclaimedRewards() public view returns (uint256){
        uint256 nftBalance = nft.balanceOf(msg.sender);
        uint256 timeLapsed;
 
        if((block.timestamp - lastClaimed[msg.sender]) <= 1 days){
            return 0;
        }
 
        if(nftBalance > 0) {
            if(lastClaimed[msg.sender] == 0) {
                timeLapsed = block.timestamp - launchTime;
            } else {
                timeLapsed = block.timestamp - lastClaimed[msg.sender];
            }
            uint256 unclaimedDuration = timeLapsed / rewardDuration;
            uint256 unclaimedRewards = (tokensPerNFT * unclaimedDuration) * nftBalance;
            return (unclaimedRewards);
        }
 
        return 0;
    }
 
    function getUnclaimedRewardsByAddress(address _walletAddress) public view returns (uint256){
        uint256 nftBalance = nft.balanceOf(_walletAddress);
        uint256 timeLapsed;
        if(nftBalance > 0) {
            if(lastClaimed[_walletAddress] == 0) {
                timeLapsed = block.timestamp - launchTime;
            } else {
                timeLapsed = block.timestamp - lastClaimed[_walletAddress];
            }
            uint256 unclaimedDuration = timeLapsed / rewardDuration;
            uint256 unclaimedRewards = (tokensPerNFT * unclaimedDuration) * nftBalance;
            return (unclaimedRewards);
        }
 
        return 0;
    }
 
    function getNFTbalance() public view returns (uint256){
        return nft.balanceOf(msg.sender);
    }
 
    function getNFTbalanceByAddress(address _walletAddress) public view returns (uint256){
        return nft.balanceOf(_walletAddress);
    }
 
    function getTokenBalance() public view returns(uint256) {
        return token.balanceOf(msg.sender);
    }
 
    function claimRewards() public nonReentrant {
        require(nft.balanceOf(msg.sender) > 0,"You do not hold any FFLY NFT");
        require(((block.timestamp - lastClaimed[msg.sender]) > 1 days), "You already have claimed today");
 
        uint256 payableRewards = getUnclaimedRewards();
        require(token.balanceOf(address(this)) >= payableRewards, "Insufficient contract reward token balance");
 
        totalClaimed[msg.sender] += payableRewards;
        lastClaimed[msg.sender] = block.timestamp;
 
        totalDistributed += payableRewards;
 
        bool success = token.transfer(msg.sender,payableRewards);
        require(success, "Token Transfer failed.");
 
        emit Claim(msg.sender, payableRewards);
    }
 
    function getTotalRewardsSupply() public view returns(uint256){ //Returns number of tokens in the contract to be used for rewards payouts
        return (token.balanceOf(address(this)));
    }
 
    function emergencyWithdrawRewardSupplyTokens(address _withdrawAddress) external onlyOwner {
        require(token.balanceOf(address(this)) > 0,"Insufficient token balance");
        bool success = token.transfer(_withdrawAddress,token.balanceOf(address(this)));
        require(success, "Token Transfer failed.");
    }
}