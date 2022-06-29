// SPDX-License-Identifier: MIT
/*

Contract for the LobsterLand server subscription system

@mintertale
*/

import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.0;

contract LobsterLand {
	event Subscribes(address indexed _address, uint256 indexed _discordId, uint256 _expired, uint256 _payed);

    address   public owner; //creator contract
	address   public lobster;
    uint256   public price = 9 * 10**16; // 0.09

    mapping (uint256 => uint256) data;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender || lobster == msg.sender, "Ownership Assertion: Caller of the function is not the owner.");
    _;
    }

    function buyAlpha(uint256 _discordId) public payable  {
        require(msg.value > 0, "You need set amount");
		require(_discordId > 10**16, "You need set discord ID");
        uint monthCounter = 1;
        uint256 expired;
        if(msg.value > price){
            monthCounter = uint(msg.value/price);
        }

        if (data[_discordId] > 0){
            expired = data[_discordId];
        } else {
            expired = block.timestamp;
        }
    
        data[_discordId] = 86400 * 30 * monthCounter + expired;
		
		emit Subscribes(msg.sender,  _discordId, 86400 * 30 * monthCounter + expired, msg.value);

    }


    function getExpiredStatus(uint256 _discordId) external view returns (bool status){
        status = true;
        if (block.timestamp < data[_discordId]){
            status = false;
        }
    }

    function getExpiredTime(uint256 _discordId) external view returns (uint256 time){
        time = data[_discordId];
    }

    function withdraw(address _toaddress) external onlyOwner {
        address payable _to = payable(_toaddress);
        _to.transfer(address(this).balance);
    }

	function setLobster(address _address) external onlyOwner {
		lobster = _address;
	}

	function setExpireSub(uint256 _discordId) public onlyOwner {
		data[_discordId] = block.timestamp;
	}

    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }


    function setSubscribe(uint256 _discordId, uint16 _countDays) public onlyOwner {
        uint256 expired = data[_discordId];
        if (expired == 0){
            expired = block.timestamp;
        }
        data[_discordId] = expired + 86400 * _countDays;
		emit Subscribes(address(0x00), _discordId , expired + 86400 * _countDays, 0);
    }


	receive() external payable {
		
    }

    function balance() external view returns (uint256 amount){
        amount = address(this).balance;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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