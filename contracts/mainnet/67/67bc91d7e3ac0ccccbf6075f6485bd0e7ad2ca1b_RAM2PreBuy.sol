/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT AND GPL-3.0
// Sources flattened with hardhat v2.8.4 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

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


// File contracts/RAM2PreBuy.sol


pragma solidity ^0.8.9;

contract RAM2PreBuy is Ownable {

    address public _RAM2;

    bool public _preBuyStopped;

    uint8 public _totalPreBuyBatch;

    uint8 public _totalPreBuyNFTs;

    uint256 public _preBuyPrice = 0.11 ether;

    mapping(address => uint8[]) private _usersBatch;

    address private _fundReceiver;

    struct PreBuy {
        mapping(address => uint8) _users;
        mapping(address => bool) _userMintStatus;
        uint8 _usersCount;
        uint8 _batchSize;
    }

    PreBuy[] private _preBuyUsers;

    /**
     * @dev setting default owner as fund receiver
     */
    constructor() {
        _fundReceiver = owner();
    }

    fallback() external {}

    receive() external payable {}

    function checkPreBuyStopped() private view {
        require(!_preBuyStopped, "RAM2PreBuy: pre buy stopped");
    }

    /**
     * @dev This method is used to set RAM2 contract address.
     * @param _ramContract RAM2 contract address
     */
    function configurePreBuy(address _ramContract) external onlyOwner {
        _RAM2 = _ramContract;
    }

    /**
     * @dev This method is used to stop pre buy functionality.
     */
    function stopPreBuy() external onlyOwner {
        _preBuyStopped = true;
    }

    /**
     * @dev This method is used to set new fund receiver.
     * @param _newFundReceiver new fund receiver
     */
    function setNewFundReceiver(address _newFundReceiver) external onlyOwner {
        _fundReceiver = _newFundReceiver;
    }

    /**
     * @dev This method is used to set pre buy price.
     * @param _price new price in wei
     */
    function setPreBuyPrice(uint256 _price) external onlyOwner {
        _preBuyPrice = _price;
    }

    /**
     * @dev This method is used change user mint status.
     * This method is only accessible by RAM2 contract.
     * @param _batchNum pre buy batch number
     * @param _user user's address
     */
    function setUserMintStatus(uint8 _batchNum, address _user) external {
        require(msg.sender == _RAM2, "RAM2PreBuy: caller is not RAM2");
        _preBuyUsers[_batchNum-1]._userMintStatus[_user] = true;
    }

    /**
     * @dev This method is used register for pre buy sale.
     * @param _num number of nfts
     */
    function registerForPreBuy(uint8 _num) payable external {
        checkPreBuyStopped();
        require(_preBuyUsers[_totalPreBuyBatch-1]._users[msg.sender] + _num <= 3, "RAM2PreBuy: max 3 nfts allowed");
        require((_preBuyPrice * _num) == msg.value, "RAM2PreBuy: invalid price");
        if(_preBuyUsers[_totalPreBuyBatch-1]._users[msg.sender] == 0) {
            require(_preBuyUsers[_totalPreBuyBatch-1]._usersCount < _preBuyUsers[_totalPreBuyBatch-1]._batchSize, "RAM2PreBuy: max users limit reached");
            _preBuyUsers[_totalPreBuyBatch-1]._usersCount++;

            _usersBatch[msg.sender].push(_totalPreBuyBatch);
        }

        _preBuyUsers[_totalPreBuyBatch-1]._users[msg.sender] += _num;
        _totalPreBuyNFTs += _num;

        payable(_fundReceiver).transfer(msg.value);
    }

    /**
     * @dev This method is used create a new pre buy batch sale.
     * @param _batchSize batch size
     */
    function createNewPreBuyBatch(uint8 _batchSize) external onlyOwner {
        checkPreBuyStopped();    
        if(_totalPreBuyBatch > 0) {
            require(_preBuyUsers[_totalPreBuyBatch-1]._usersCount == _preBuyUsers[_totalPreBuyBatch-1]._batchSize, "RAM2PreBuy: previous batch is not ended");
        }

        PreBuy storage _new = _preBuyUsers.push();
        _new._batchSize = _batchSize;
        _totalPreBuyBatch++;
    }

    /**
     * @dev This method is used to get pre buy batch number on which user registered.
     * @param _user user's address
     */
    function getPreBuyBatchNumByUser(address _user) external view returns(uint8[] memory _registeredBatches) {
        return _usersBatch[_user];
    }

    /**
     * @dev This method is used to get last pre buy batch register details.
     */
    function getPreBuyBatch() external view returns(uint8 _allowed, uint8 _registered) {
        return (_preBuyUsers[_totalPreBuyBatch-1]._batchSize, _preBuyUsers[_totalPreBuyBatch-1]._usersCount);
    }

    /**
     * @dev This method is used to get total nfts buy user in batch.
     * @param _batchNum batch number
     * @param _user user's address
     */
    function getPreBuyBatchUsersNFTs(uint8 _batchNum, address _user) external view returns(uint8) {
        return _preBuyUsers[_batchNum-1]._users[_user];
    }

    /**
     * @dev This method is used to get user's mint status by pre buy batch number.
     * @param _batchNum batch number
     * @param _user user's address
     */
    function getPreBuyBatchUsersMintStatus(uint8 _batchNum, address _user) external view returns(bool) {
        return _preBuyUsers[_batchNum-1]._userMintStatus[_user];
    }
}