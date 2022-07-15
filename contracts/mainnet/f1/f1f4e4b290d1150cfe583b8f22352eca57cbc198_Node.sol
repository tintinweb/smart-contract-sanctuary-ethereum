/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**

      /$$$$$$   /$$$$$$  /$$      /$$
     /$$__  $$ /$$__  $$| $$$    /$$$
    |__/  \ $$| $$  \__/| $$$$  /$$$$
       /$$$$$/| $$ /$$$$| $$ $$/$$ $$
      |___  $$| $$|_  $$| $$  $$$| $$
     /$$  \ $$| $$  \ $$| $$\  $ | $$
    |  $$$$$$/|  $$$$$$/| $$ \/  | $$
    \______/  \______/ |__/     |__/


    ** Website
       https://3gm.dev/

    ** Twitter
       https://twitter.com/3gmdev

**/


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)




// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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


contract Node is Ownable {

    event Payment(
        uint256 discordID,
        uint256 payment,
        uint256 txTimestamp,
        uint256 expireTimestamp
    );

    uint256 public price;
    bool public paused = true;

    mapping(uint256 => uint256) public userPayments;
    uint256[] public nodeUsers;

    function makePayment(uint256 discordID, uint256 months) external payable {
        require(!paused, "Paused");
        require(discordID > 0 && months > 0, "No zero params");
        uint256 payment = msg.value;
        require(msg.sender != address(0), "No zero address");
        require(payment == (price * months), "No enough payment");
        uint256 expireTimestamp = userPayments[discordID];
        if(block.timestamp >= expireTimestamp){
            expireTimestamp = block.timestamp + (30 days * months);
        }else{
            expireTimestamp += (30 days * months);
        }
        _makePayment(discordID, payment, expireTimestamp);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = _msgSender().call{value: balance}("");
        require(success, "Failed to send");
    }

    function togglePause() external onlyOwner {
        paused = !paused;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function makePaymentByAdmin(uint256 discordID, uint256 payment, uint256 expireTimestamps) external onlyOwner {
        _makePayment(discordID, payment, expireTimestamps);
    }

    function makePaymentsByAdmin(uint256[] calldata discordIDs, uint256[] calldata payments, uint256[] calldata expireTimestamps) external onlyOwner {
        require(discordIDs.length == expireTimestamps.length, "Not same lenght");
        for (uint256 i; i < discordIDs.length; i++) {
            _makePayment(discordIDs[i], payments[i], expireTimestamps[i]);
        }
    }

    function checkAlreadyUser(uint256 discordID) internal view returns (bool) {
        if(userPayments[discordID] == 0) return false;
        return true;
    }

    function _makePayment(uint256 discordID, uint256 payment, uint256 expireTimestamp) internal {
        if(!checkAlreadyUser(discordID)){
            nodeUsers.push(discordID);
        }
        userPayments[discordID] = expireTimestamp;
        emit Payment(discordID, payment, block.timestamp, expireTimestamp);
    }

    function getUsersList() public view returns (uint256[] memory) {
        return nodeUsers;
    }
}