//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISettings.sol";


/// @title Contract storing system wide parameters
/// @author George Spasov
/// @notice This contract holds the settings governing the different processes within the fractional vaults and can only be set by the DAO
/// @dev Ownership must be transferred to the DAO
contract Settings is Ownable, ISettings {// Owned by the governance

    /// Fractionalisation settings

    /// @notice the maximum number of fractions that the vault can be fractionalised into
    uint256 public maxFractions = 100_000_000_000 * 10 ** 18;

    /// @notice the minimum number of fractions that the vault can be fractionalised into
    uint256 public constant minFractions = 100 * 10 ** 18;

    /// @dev Percentages are represented as basis points, with each point being 0.01%
    /// ex. 100% = 10000, 1% = 100 0.01% = 1
    uint256 public constant MAX_PERCENT = 10000;

    /// YIELD settings

    /// @notice the fee % that the manager can take from any yield
    uint256 public managementFee = 100; // 1%

    /// @notice the fee % that the harvester can take from any yield
    uint256 public harvesterFee = 50; // 0.5%

    /// AUCTIONS settings

    /// @notice the percent of fractions that have voted before an auction can start
    uint256 public votingQuorum = 1000; // 10%

    /// @notice the length of auctions
    uint256 public auctionLength = 3 days;

    /// @notice if a bid comes within this much of the end of the auction, the auction end will be increased with this much
    uint256 public lastBidBuffer = 15 minutes;

    /// @notice the minimum bid increase for a bid to be valid
    uint256 public minBidIncrease = 500; // 5%

    event MaxFractionsChanged(uint256 oldMax, uint256 newMax);

    event ManagementMaxFeeChanged(uint256 oldMax, uint256 newMax);
    event HarvesterFeeChanged(uint256 oldFee, uint256 newFee);

    event VotingQuorumChanged(uint256 oldQuorum, uint256 newQuorum);
    event AuctionLengthChanged(uint256 oldLength, uint256 newLength);
    event AuctionLastBidBuffer(uint256 oldBuffer, uint256 newBuffer);
    event MinBidIncreaseChanged(uint256 oldIncrease, uint256 newIncrease);

    /// @notice Sets the maximum number the user can decide to divide the asset into
    /// @param max The maximum number of fractions
    function setMaxFractionsLimits(uint256 max) external onlyOwner {
        require(max > minFractions, "setMaxFractionsLimits :: Incorrect bounds");

        emit MaxFractionsChanged(maxFractions, max);
        maxFractions = max;

    }

    /// @notice Sets the percentage that a manager gets out of successful harvests
    /// @dev the fee is denoted according to the basis points outlined above
    /// @param fee The fee percentage the manager gets
    function setManagementFee(uint256 fee) external onlyOwner {
        require(fee <= MAX_PERCENT, "setManagementFee :: Incorrect management fee");

        emit ManagementMaxFeeChanged(managementFee, fee);
        managementFee = fee;
    }

    /// @notice Sets the percentage that the harvester is getting out of successful harvest
    /// @dev the fee is denoted according to the basis points outlined above
    /// @param fee The fee percentage going to the harvester
    function setHarvesterFee(uint256 fee) external onlyOwner {
        require(fee <= MAX_PERCENT, "setHarvesterFee :: Incorrect harvester fee");

        emit HarvesterFeeChanged(harvesterFee, fee);
        harvesterFee = fee;
    }

    /// @notice Sets the minimum quorum of fraction holders that have set an exit price in order for auction to be started
    /// @dev the denoted quorum is in % according to the basis points
    /// @param quorum The quorum percentage
    function setVotingQuorum(uint256 quorum) external onlyOwner {
        require(quorum <= MAX_PERCENT, "setVotingQuorum :: Incorrect voting quorum");

        emit VotingQuorumChanged(votingQuorum, quorum);
        votingQuorum = quorum;
    }

    /// @notice Sets the length of the auction once started
    /// @param length The length of the auction phase
    function setAuctionLength(uint256 length) external onlyOwner {
        require(length > 0, "setAuctionLength :: Incorrect auction length");

        emit AuctionLengthChanged(auctionLength, length);
        auctionLength = length;
    }

    /// @notice Sets the length of the buffer for the auctions
    /// @dev If a bid is submitted within this much of the end of the auction, the auction will be extended by this much.
    /// @param buffer The length of the auction end buffer
    function setLastBidBuffer(uint256 buffer) external onlyOwner {
        require(buffer > 0, "setLastBidBuffer :: Incorrect last bid buffer");

        emit AuctionLastBidBuffer(lastBidBuffer, buffer);
        lastBidBuffer = buffer;
    }

    /// @notice Sets the minimum increase each bid needs to up the previous one
    /// @dev the denoted quorum is in % according to the basis points
    /// @param increase The bid percent
    function setMinBidIncrease(uint256 increase) external onlyOwner {
        require(increase <= MAX_PERCENT, "setMinBidIncrease :: Incorrect minimum bid increase set");

        emit MinBidIncreaseChanged(minBidIncrease, increase);
        minBidIncrease = increase;
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;


interface ISettings {
    function maxFractions() external view returns (uint256);

    function minFractions() external view returns (uint256);

    function MAX_PERCENT() external view returns (uint256);

    function managementFee() external view returns (uint256);

    function harvesterFee() external view returns (uint256);

    function votingQuorum() external view returns (uint256);

    function auctionLength() external view returns (uint256);

    function lastBidBuffer() external view returns (uint256);

    function minBidIncrease() external view returns (uint256);
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