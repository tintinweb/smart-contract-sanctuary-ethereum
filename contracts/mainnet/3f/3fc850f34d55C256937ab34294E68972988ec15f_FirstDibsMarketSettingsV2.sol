//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import '@openzeppelin/contracts/access/Ownable.sol';
import './IFirstDibsMarketSettingsV2.sol';

contract FirstDibsMarketSettingsV2 is Ownable, IFirstDibsMarketSettingsV2 {
    // default buyer's premium (price paid by buyer above winning bid)
    uint32 public override globalBuyerPremium;

    // default commission for auction admin (1stDibs)
    uint32 public override globalMarketCommission;

    // 10% min bid increment
    uint32 public override globalMinimumBidIncrement;

    // default global auction time buffer (if bid is made in last 15 min,
    // extend auction another 15 min)
    uint32 public override globalTimeBuffer;

    // default global auction duration (24 hours)
    uint32 public override globalAuctionDuration;

    // address of the auction admin (1stDibs)
    address public override commissionAddress;

    constructor(address _commissionAddress) {
        require(
            _commissionAddress != address(0),
            'Cannot have null address for _commissionAddress'
        );
        globalTimeBuffer = 15 * 60;
        globalAuctionDuration = 24 * 60 * 60;
        commissionAddress = _commissionAddress; // receiver address for auction admin (globalMarketplaceCommission gets sent here)
        globalBuyerPremium = 300;
        globalMarketCommission = 500;
        globalMinimumBidIncrement = 1000;
    }

    modifier nonZero(uint256 _value) {
        require(_value > 0, 'Value must be greater than zero');
        _;
    }

    /**
     * @dev Modifier used to ensure passed value is <= 10000. Handy to validate RBS values.
     * @param _value uint256 to validate
     */
    modifier lte10000(uint256 _value) {
        require(_value <= 10000, 'Value must be <= 10000');
        _;
    }

    /**
     * @dev setter for global auction admin
     * @param _commissionAddress address of the global auction admin (1stDibs wallet)
     */
    function setCommissionAddress(address _commissionAddress) external onlyOwner {
        require(
            _commissionAddress != address(0),
            'Cannot have null address for _commissionAddress'
        );
        commissionAddress = _commissionAddress;
    }

    /**
     * @dev setter for global time buffer
     * @param _timeBuffer new time buffer in seconds
     */
    function setGlobalTimeBuffer(uint32 _timeBuffer) external onlyOwner nonZero(_timeBuffer) {
        globalTimeBuffer = _timeBuffer;
    }

    /**
     * @dev setter for global auction duration
     * @param _auctionDuration new auction duration in seconds
     */
    function setGlobalAuctionDuration(uint32 _auctionDuration)
        external
        onlyOwner
        nonZero(_auctionDuration)
    {
        globalAuctionDuration = _auctionDuration;
    }

    /**
     * @dev setter for global buyer premium
     * @param _buyerPremium new buyer premium percent
     */
    function setGlobalBuyerPremium(uint32 _buyerPremium) external onlyOwner {
        globalBuyerPremium = _buyerPremium;
    }

    /**
     * @dev setter for global market commission rate
     * @param _marketCommission new market commission rate
     */
    function setGlobalMarketCommission(uint32 _marketCommission)
        external
        onlyOwner
        lte10000(_marketCommission)
    {
        require(_marketCommission >= 300, 'Market commission cannot be lower than 3%');
        globalMarketCommission = _marketCommission;
    }

    /**
     * @dev setter for global minimum bid increment
     * @param _bidIncrement new minimum bid increment
     */
    function setGlobalMinimumBidIncrement(uint32 _bidIncrement)
        external
        onlyOwner
        nonZero(_bidIncrement)
    {
        globalMinimumBidIncrement = _bidIncrement;
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

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

interface IFirstDibsMarketSettingsV2 {
    function globalBuyerPremium() external view returns (uint32);

    function globalMarketCommission() external view returns (uint32);

    function globalMinimumBidIncrement() external view returns (uint32);

    function globalTimeBuffer() external view returns (uint32);

    function globalAuctionDuration() external view returns (uint32);

    function commissionAddress() external view returns (address);
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