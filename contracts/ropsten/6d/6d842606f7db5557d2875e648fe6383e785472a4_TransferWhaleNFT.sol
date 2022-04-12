/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: contracts/WhaleTrade.sol


pragma solidity ^0.8.7;


contract TransferWhaleNFT is Ownable {
    address private _ownerAddr;

    constructor () payable {
        _ownerAddr = msg.sender;
    }

    enum TradeStatus {  
        STATUS_POST, STATUS_TRADING, STATUS_COMPLETE, STATUS_ERROR 
    }

    struct NFTProduct {
        address contractAddr;
        uint256 tokenId;
    }

    struct TradeRoom {
        NFTProduct nftProduct;
        uint256 price;
        address sellerAddr;
        TradeStatus tradeStatus;
        address payable buyerAddr;
    }

    mapping(uint => TradeRoom) rooms;
    uint roomLen = 0;

    event RoomCreated (address indexed sellerAddress, uint256 price, uint256 roomNumber);

    event Response(bool success, bytes data);

    // price 단위는 wei = ether * 10^18
    function createRoom (address _contractAddr, uint256 _tokenId, uint256 _price) public returns (uint roomNum) {
        rooms[roomLen] = TradeRoom({
            nftProduct: NFTProduct({
                contractAddr: _contractAddr,
                tokenId: _tokenId
            }),
            price: _price,
            sellerAddr: msg.sender,
            tradeStatus: TradeStatus.STATUS_POST,
            buyerAddr: payable(msg.sender) // will change
        });
        roomNum = roomLen;
        roomLen = roomLen + 1;

        // owner address로 approve 
        (bool success, bytes memory data) = _contractAddr.call(
            abi.encodeWithSignature("approve(address, uint256)", _ownerAddr, _tokenId)
        );

        emit Response(success, data);

    }




}