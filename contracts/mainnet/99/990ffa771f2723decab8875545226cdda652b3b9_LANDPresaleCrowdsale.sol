// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract LANDPresaleCrowdsale is Ownable, Pausable {
    address public receiverAddress = 0x5Be192c0Be2521E7617594c2E8854f21C5a11967; // receiver address

    uint32 public cap; // Max cap of the sale
    uint32 public totalBought; // Total tokens bought from this sale

    uint64 public _startTime; // Time when crowdsale starts
    uint64 public _endTime; // Time when crowdsale ends

    bool public _whitelistDesactivated; // bool to control the use of whitelist

    mapping(uint32 => bool) public _idSale; // tokenIDs that are for sale.
    mapping(uint32 => bool) public _idSold; // tokenIDs that have been sold.
    mapping(uint32 => uint8) public _idType; // from token_id to idType
    mapping(uint8 => uint) public _typePrice; // Which is the price of the type of token_id
    mapping(address => bool) public _whitelist; // whitelisted addresses

    event LANDBought(uint32 _tokenID, address _buyer); // Event to capture which token Id has been bought per buyer.

    constructor(uint32 _cap) {
        cap = _cap;
        _startTime = 0;
        _endTime = 1671759098; // December 23th 2022 9:31:38
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
    * @dev buy LAND function
    */
    function buyLAND(uint32 _tokenID) external payable whenNotPaused {
        require(totalBought < cap, "LANDPresaleCrowdsale: Total cap already minted");
        require(_idSale[_tokenID] && !_idSold[_tokenID], "LANDPresaleCrowdsale: _tokenID not available for sale or already bought");
        require(_whitelistDesactivated || _whitelist[_msgSender()], "LANDPresaleCrowdsale: Sender is not whitelisted or whitelist active");
        require(_startTime < uint64(block.timestamp) && _endTime > uint64(block.timestamp), "LANDPresaleCrowdsale: Not correct Event time");

        uint salePrice = _typePrice[_idType[_tokenID]];
        require(msg.value >= salePrice, "LANDPresaleCrowdsale: Sent value is less than sale price for this _tokenID");

        // another token bought
        totalBought += 1;

        // mark tokenId that has been sold
        _idSale[_tokenID] = false;
        _idSold[_tokenID] = true;

        // Refund back the remaining to the receiver
        uint value = msg.value - salePrice;
        if (value > 0) {
            payable(_msgSender()).transfer(value);
        }

        // emit event to catch in the frontend to update grid and keep track of buyers.
        emit LANDBought(_tokenID, _msgSender());
    }

    /**
    * @dev Transfer all held by the contract to the owner.
    */
    function reclaimETH() external onlyOwner {
        payable(receiverAddress).transfer(address(this).balance);
    }

    /**
    * @dev Transfer all ERC20 of tokenContract held by contract to the owner.
    */
    function reclaimERC20(address _tokenContract) external onlyOwner {
        require(_tokenContract != address(0), "Invalid address");
        IERC20 token = IERC20(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(receiverAddress, balance);
    }

    /**
    * @dev Set status for whitelist, wether to use whitelist or not for the sale
    */
    function setWhitelistDesactivatedStatus(bool _status) external onlyOwner {
        _whitelistDesactivated = _status;
    }

    /**
    * @dev Set status for tokens IDs, set up which IDs are for sale
    */
    function setIDSale(uint32[] calldata _tokenID, bool _status) external onlyOwner {
        for (uint i = 0; i < _tokenID.length; i++) {
            _idSale[_tokenID[i]] = _status;
        }
    }

    /**
    * @dev Set which ID type is each token_id, don't need to do it with the type 0.
    */
    function setIDType(uint32[] calldata _tokenID, uint8 _type) external onlyOwner {
        for (uint i = 0; i < _tokenID.length; i++) {
            _idType[_tokenID[i]] = _type;
            _idSale[_tokenID[i]] = true;
        }
    }

    /**
    * @dev Set price for each type of tokenID, price has to be in weis.
    */
    function setTypePrice(uint8 _type, uint _price) external onlyOwner {
        {
            _typePrice[_type] = _price;
        }
    }

    /**
    * @dev Set start Time for the Sale
    */
    function setStartTime(uint64 _newTime) external onlyOwner {
        _startTime = _newTime;
    }

    /**
    * @dev Set end Time for the Sale
    */
    function setEndTime(uint64 _newTime) external onlyOwner {
        _endTime = _newTime;
    }

    /**
    * @dev Set whitelist address status true or false in bulk
    */
    function setWhitelist(address[] calldata _addresses, bool _status) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            _whitelist[_addresses[i]] = _status;
        }
    }

    /**
    * @dev Check address whitelist status
    */
    function isWhitelist() external view returns (bool) {
        return _whitelist[_msgSender()];
    }

    /**
    * @dev Get _tokenID price
    */
    function getTokenPrice(uint32 _tokenID) external view returns (uint) {
        return _typePrice[_idType[_tokenID]];
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

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