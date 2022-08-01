/**
 *Submitted for verification at Etherscan.io on 2022-07-31
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface Shard {
    function balanceOf(address wallet) external view returns(uint256);
    function burnShards(address wallet, uint256 amount) external;
}

interface ShardOld {
    function balanceOf(address wallet) external view returns(uint256);
    function burnShards(address wallet, uint256 amount) external;
}

interface MP {
    function balanceOf(address wallet) external view returns(uint256);
}

interface Frame {
    function getTokensStaked(address wallet) external view returns (uint256[] memory);
}

/*
⠀*⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⢀⣀⣀⣠⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⣷⣦⣄⣀⣀⡀⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⢸⣿⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⣿⡇⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⢸⣿⠀⢸⣿⣿⣿⣿⡿⠟⠁⠀⠀⣀⣾⣿⣿⠀⣿⡇⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⢸⣿⠀⢸⣿⣿⡿⠋⠀⠀⠀⣠⣾⣿⡿⠋⠁⠀⣿⡇⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⢸⣿⠀⢸⠟⠉⠀⠀⢀⣴⣾⣿⠿⠋⠀⠀⠀⠀⣿⡇⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⢸⣿⠀⠀⠀⠀⣠⣴⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀⣿⡇⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⢸⣿⠀⠀⣠⣾⣿⡿⠋⠁⠀⠀⠀⠀⠀⣠⣶⠀⣿⡇⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⢸⣿⠀⢸⣿⠿⠋⠀⠀⠀⠀⠀⢀⣠⣾⡿⠟⠀⣿⡇⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⢸⣿⠀⠘⠁⠀⠀⠀⠀⠀⢀⣴⣿⡿⠋⣠⣴⠀⣿⡇⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⢸⣿⠀⠀⠀⠀⠀⠀⣠⣾⣿⠟⢁⣠⣾⣿⣿⠀⣿⡇⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⢸⣿⠀⠀⠀⢀⣠⣾⡿⠋⢁⣴⣿⣿⣿⣿⣿⠀⣿⡇⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⢸⣿⣀⣀⣀⣈⣉⣉⣀⣀⣉⣉⣉⣉⣉⣉⣉⣀⣿⡇⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⠘⠛⠛⠛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⠛⠛⠃⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠛⠛⠛⠛⠋⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 *          MIRRORPASS.XYZ
 */
contract Reservation is Ownable {
    Shard private shards;
    ShardOld private shardOld;
    MP private mp;
    Frame private frame;

    uint256 public reserveTime = 0;
    uint256 public closeTime = 0;

    uint256 public totalReserved = 0;
    uint256 public reservePrice = 280 ether;

    mapping(address => uint256) public reservedBots;
    mapping(address => bool) public adminAddresses;

    event Reserved(address wallet, uint256 amount, uint256 timestamp);

    modifier onlyAdmins() {
        require(adminAddresses[msg.sender], "You're not authorized to call this");
        _;
    }

    modifier isNotContract() {
        require(tx.origin == msg.sender, "No contracts allowed");
        _;
    }

    modifier isReservationAvailable() {
        require(reserveTime > 0 && closeTime > 0,  "Reserving is currently disabled");
        require(block.timestamp >= reserveTime, "Reserving is currently disabled");
        require(closeTime > block.timestamp, "Reserving has now ended");
        _;
    }

    modifier isHolder() {
        require(mp.balanceOf(msg.sender) > 0 || frame.getTokensStaked(msg.sender).length > 0, "You're not a mirror pass holder");
        _;
    }

    // this burns the tokens in order to reserve a bot for the mint
    function reserve(uint256 amount, uint256 oldBal, uint256 newBal) public isNotContract isReservationAvailable isHolder {
        require((shards.balanceOf(msg.sender) + shardOld.balanceOf(msg.sender)) >= amount * reservePrice, "Not enough shards to reserve this amount");
        require(oldBal + newBal >= amount * reservePrice, "Not enough shards provided in the transaction");

        if (oldBal > 0) {
            shardOld.burnShards(msg.sender, oldBal);
        }

        if (newBal > 0) {
            shards.burnShards(msg.sender, newBal);
        }

        totalReserved += amount;
        reservedBots[msg.sender] += amount;
        emit Reserved(msg.sender, amount, block.timestamp);
    }

    function changeReservedFromWallet(address wallet, uint256 amount) public onlyAdmins {
        reservedBots[wallet] = amount;
    }

    function setShardsContract(address shardsContract) public onlyOwner {
        shards = Shard(shardsContract);
    }

    function setOldShardsContract(address oldContract) public onlyOwner {
        shardOld = ShardOld(oldContract);
    }

    function setTokenContract(address tokenContract) public onlyOwner {
        mp = MP(tokenContract);
    }

    function setFrameContract(address frameContract) public onlyOwner {
        frame = Frame(frameContract);
    }

    function setReservePrice(uint256 amount) public onlyOwner {
        reservePrice = amount;
    }

    function setReserving(uint256 timestamp) public onlyOwner {
        reserveTime = timestamp;
        closeTime = timestamp + 1 days;
    }

    // incase it's required
    function forceCloseTime(uint256 time) public onlyOwner {
        closeTime = time;
    }
    
    function setAdminAddresses(address contractAddress, bool state) public onlyOwner {
        adminAddresses[contractAddress] = state;
    }
}