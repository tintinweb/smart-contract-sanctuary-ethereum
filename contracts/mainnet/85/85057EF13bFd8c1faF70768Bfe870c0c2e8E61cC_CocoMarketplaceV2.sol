// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICoco.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
            
// @author 0xBori <https://twitter.com/0xBori>   
contract CocoMarketplaceV2 is Ownable {

    uint256 public whitelistCounter;
    uint256 public raffleCounter;
    uint256 public whitelistTimer;
    uint256 public raffleTimer;
    address public cocoAddress;
    mapping(uint => Whitelist) whitelists;
    mapping(uint => Raffle) raffles;
    mapping(uint => mapping(address => bool)) _hasPurchasedWL;
    mapping(uint => mapping(address => bool)) _hasPurchasedRaffle;

    struct Whitelist {
        uint256 price;
        uint256 amount;
        uint256 timestamp;
    }

    struct Raffle {
        uint256 price;
        uint256 endTime;
        bool capped;
    }

    event PurchaseWL (uint256 indexed _id, address indexed _address, string _name);
    event EnterRaffle (uint256 indexed _id, address indexed _address, uint256 _amount, string _name);

    constructor() { 
        cocoAddress = 0x133B7c4A6B3FDb1392411d8AADd5b8B006ad69a4;
        whitelistCounter = 33;
        whitelistTimer = 60 * 60 * 24;
        raffleTimer = whitelistTimer;
    }

    function enterRaffle(uint256 _id, uint256 _amount, string memory _name) public {
        require(
            block.timestamp < raffles[_id].endTime,
            "Raffle ended."
        );

        if (raffles[_id].capped) {
            require(
                !_hasPurchasedRaffle[_id][msg.sender],
                "Already entered"
            );
            _hasPurchasedRaffle[_id][msg.sender] = true;
        }

        ICoco(cocoAddress).burnFrom(msg.sender, raffles[_id].price * _amount);
        emit EnterRaffle(_id, msg.sender, _amount, _name);
    }

    function purchase(uint256 _id, string memory _name) public {
        require(
            block.timestamp > whitelists[_id].timestamp,
            "Not live yet."
        );
        require(
            whitelists[_id].amount != 0,
            "No spots left"
        );
       require(
           !_hasPurchasedWL[_id][msg.sender],
           "Address has already purchased");

        unchecked {
            whitelists[_id].amount--;
        }

        _hasPurchasedWL[_id][msg.sender] = true;
        ICoco(cocoAddress).burnFrom(msg.sender, whitelists[_id].price);

        emit PurchaseWL(_id, msg.sender, _name);
    }

    function addWhitelist(uint256 _amount, uint256 _price) external onlyOwner {
        whitelists[whitelistCounter++] = Whitelist(
            _price * 10 ** 18,
            _amount,
            block.timestamp + whitelistTimer
        );
    }

    function addRaffle(uint256 _price, bool _capped) external onlyOwner {
        raffles[raffleCounter++] = Raffle(
            _price * 10 ** 18,
            block.timestamp + raffleTimer,
            _capped
        );
    }

    function editWhitelist(uint256 _id, uint256 _amount, uint256 _price, uint256 _timestamp) external onlyOwner {
        whitelists[_id].amount = _amount;
        whitelists[_id].price = _price * 10 ** 18;
        whitelists[_id].timestamp = _timestamp;
    }

    function editWLAmount(uint256 _id, uint256 _amount) external onlyOwner {
        whitelists[_id].amount = _amount;
    }

    function editWLPrice(uint256 _id, uint256 _price) external onlyOwner {
        whitelists[_id].price = _price * 10 ** 18;
    }

    function editWLTimestamp(uint256 _id, uint256 _timestamp) external onlyOwner {
        whitelists[_id].timestamp = _timestamp;
    }

    function editRaffle(uint256 _id, uint256 _price, bool _capped, uint256 _timestamp) external onlyOwner {
        raffles[_id].price = _price * 10 ** 18;
        raffles[_id].capped = _capped;
        raffles[_id].endTime = _timestamp;
    }

    function editRaffleAmount(uint256 _id, bool _capped) external onlyOwner {
        raffles[_id].capped = _capped;
    }

    function editRafflePrice(uint256 _id, uint256 _price) external onlyOwner {
        raffles[_id].price = _price * 10 ** 18;
    }

    function editRaffleEnd(uint256 _id, uint256 _timestamp) external onlyOwner {
        raffles[_id].endTime = _timestamp;
    }

    function skipRaffleIndex() external onlyOwner {
        // Extremely unlikely this overflows
        unchecked {
            ++raffleCounter;
        }
    }

    function setCocoAddress(address _cocoAddress) public onlyOwner {
        cocoAddress = _cocoAddress;
    }

    function setWhitelistTimer(uint256 _time) external onlyOwner {
        whitelistTimer = _time;
    }

    function setRaffleTimer(uint256 _time) external onlyOwner {
        raffleTimer = _time;
    }

    function getWhitelist(uint256 _id) public view returns (Whitelist memory) {
        return whitelists[_id];
    }

    function getRaffle(uint256 _id) public view returns (Raffle memory) {
        return raffles[_id];
    }

    function hasPurchasedWL(uint256 _id, address _address) public view returns (bool) {
        return _hasPurchasedWL[_id][_address];
    }

    function hasPurchasedRaffle(uint256 _id, address _address) public view returns (bool) {
        return _hasPurchasedRaffle[_id][_address];
    }

    function isCappedRaffle(uint256 _id) public view returns (bool) {
        return raffles[_id].capped;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface ICoco is IERC20 {
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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