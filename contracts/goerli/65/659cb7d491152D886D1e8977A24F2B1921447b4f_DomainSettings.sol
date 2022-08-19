//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IDomainSettings} from "./IDomainSettings.sol";

contract DomainSettings is Ownable, IDomainSettings {

    /// @notice 最小投票时长
    uint256 public override minVoteDuration;

    /// @notice 最大投票时长
    uint256 public override maxVoteDuration;

    /// @notice 投票百分百
    uint256 public override votePercentage;

    /// @notice 最小拍卖时长
    uint256 public override minAuctionDuration;

    /// @notice 最大拍卖时长
    uint256 public override maxAuctionDuration;

    /// @notice 竞拍加价百分百
    uint256 public override bidIncreasePercentage;

    /// @notice 最小预售时长
    uint256 public override minPresaleDuration;

    /// @notice 最大预售时长
    uint256 public override maxPresaleDuration;

    event UpdateMinVoteDuration(uint256 minVoteDuration, uint256 newMinVoteDuration);

    event UpdateMaxVoteDuration(uint256 maxVoteDuration, uint256 newMaxVoteDuration);

    event UpdateMinAuctionDuration(uint256 minAuctionDuration, uint256 newMinAuctionDuration);

    event UpdateMaxAuctionDuration(uint256 maxAuctionDuration, uint256 newMaxAuctionDuration);

    event UpdateVotePercentage(uint256 votePercentage, uint256 newVotePercentage);

    event UpdateBidIncreasePercentage(uint256 bidIncreasePercentage, uint256 newBidIncreasePercentage);

    event UpdateMinPresaleDuration(uint256 minPresaleDuration, uint256 newMinPresaleDuration);

    event UpdateMaxPresaleDuration(uint256 maxPresaleDuration, uint256 newMaxPresaleDuration);

    constructor() {

        minVoteDuration = 1 days;
        maxVoteDuration = 28 days;

        // 5100/10000%
        votePercentage = 5100;

        minAuctionDuration = 7 days;
        maxAuctionDuration = 168 days;

        //  100/10000%
        bidIncreasePercentage = 100;

        minPresaleDuration = 1 days;
        maxPresaleDuration = 28 days;
    }

    // 最小投票时长
    function setMinVoteDuration(uint256 newMinVoteDuration) external onlyOwner {
        require(newMinVoteDuration < maxVoteDuration, "DomainSettings: min vote duration too high");
        emit UpdateMinVoteDuration(minVoteDuration, newMinVoteDuration);
        minVoteDuration = newMinVoteDuration;
    }

    // 最大投票时长
    function setMaxVoteDuration(uint256 newMaxVoteDuration) external onlyOwner {
        require(newMaxVoteDuration > minVoteDuration, "DomainSettings: max vote duration too low");
        emit UpdateMaxVoteDuration(maxVoteDuration, newMaxVoteDuration);
        maxVoteDuration = newMaxVoteDuration;
    }

    // 最小拍卖时长
    function setMinAuctionDuration(uint256 newMinAuctionDuration) external onlyOwner {
        require(newMinAuctionDuration < maxAuctionDuration, "DomainSettings: min auction duration too high");
        emit UpdateMinAuctionDuration(minAuctionDuration, newMinAuctionDuration);
        minAuctionDuration = newMinAuctionDuration;
    }

    // 最大拍卖时长
    function setMaxAuctionDuration(uint256 newMaxAuctionDuration) external onlyOwner {
        require(newMaxAuctionDuration > minAuctionDuration, "DomainSettings: max auction duration too low");
        emit UpdateMaxAuctionDuration(maxAuctionDuration, newMaxAuctionDuration);
        maxAuctionDuration = newMaxAuctionDuration;
    }

    // 投票比率
    function setVotePercentage(uint256 newVotePercentage) external onlyOwner {
        //10000 is 100%
        require(newVotePercentage <= 10000, "DomainSettings: vote percentage too high");
        require(newVotePercentage >= 5001, "DomainSettings: vote percentage too low");
        emit UpdateVotePercentage(votePercentage, newVotePercentage);
        votePercentage = newVotePercentage;
    }

    // 拍卖加价比率
    function setBidIncreasePercentage(uint256 newBidIncreasePercentage) external onlyOwner {
        //10000 is 100%
        require(newBidIncreasePercentage <= 10000, "DomainSettings: bid increase percentage too high");
        require(newBidIncreasePercentage >= 100, "DomainSettings: bid increase percentage too low");
        emit UpdateBidIncreasePercentage(bidIncreasePercentage, newBidIncreasePercentage);
        bidIncreasePercentage = newBidIncreasePercentage;
    }

    // 最小预售时长
    function setMinPresaleDuration(uint256 newMinPresaleDuration) external onlyOwner {
        require(newMinPresaleDuration < maxPresaleDuration, "DomainSettings: min pre-sale duration too high");
        emit UpdateMinPresaleDuration(minPresaleDuration, newMinPresaleDuration);
        minPresaleDuration = newMinPresaleDuration;
    }

    // 最大预售时长
    function setMaxPresaleDuration(uint256 newMaxPresaleDuration) external onlyOwner {
        require(newMaxPresaleDuration > minPresaleDuration, "DomainSettings: max pre-sale duration too low");
        emit UpdateMaxPresaleDuration(maxPresaleDuration, newMaxPresaleDuration);
        maxPresaleDuration = newMaxPresaleDuration;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDomainSettings {

    //最小投票时长
    function minVoteDuration() external returns (uint256);

    //最大投票时长
    function maxVoteDuration() external returns (uint256);

    //投票百分百
    function votePercentage() external returns (uint256);

    //最小拍卖时长
    function minAuctionDuration() external returns (uint256);

    //最大拍卖时长
    function maxAuctionDuration() external returns (uint256);

    //竞拍加价百分百
    function bidIncreasePercentage() external returns (uint256);

    //最小预售时长
    function minPresaleDuration() external returns (uint256);

    //最大预售时长
    function maxPresaleDuration() external returns (uint256);

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