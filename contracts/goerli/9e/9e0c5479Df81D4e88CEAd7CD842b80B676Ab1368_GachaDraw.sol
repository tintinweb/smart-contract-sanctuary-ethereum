// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAnimeMetaverseTicket.sol";
import "./IAnimeMetaverseReward.sol";

/// @notice Should have sufficient reward for gacha activity
/// @dev Use this custom error on revert function whenever there is insufficiant reward
error InsufficientReward();

/// @notice Should provide a valid activity Id for any gacha activity
/// @dev Use this custom error on revert function whenever invalid activity Id
error InvalidActivity();

/// @notice Should provide a valid activity type either FREE_ACTIVITY_TYPE or PREMIUM_ACTIVITY_TYPE
/// @dev Use this custom error on revert function whenever the activity type is not valid
error InvalidActivityType();

/// @notice Should draw ticket for a active gacha activity
/// @dev Use this custom error on revert function the activity is not active
error InactiveActivity();

/// @notice Should draw ticket for a active gacha activity
/// @dev Use this custom error on revert function draw is out of event timestamp
error ActivityTimestampError();

/// @notice Should input valid address other than 0x0
/// @dev Use this custom error on revert function whenever validating address
error InvalidAddress();

/// @notice Should provide valid timestamp 
/// @dev Use this custom error on revert function whenever there is invalid timestamp
error InvalidTimestamp();

/// @notice Should provide valid amount of ticket 
/// @dev Use this custom error on revert function whenever there is invalid amount of ticket
error InsufficientTicket();

/// @notice Should provide valid array length as input
/// @dev Use this custom error on revert function whenever the array length does not match
error InvalidInputLength();

/// @notice Should provide valid input
/// @dev Use this custom error with message on revert function whenever the input is not valid
error InvalidInput(string message);

contract GachaDraw is Ownable {

    /// @notice Emit when a new activity is created
    /// @dev Emeits in createActivity method
    /// @param _activityId New activity Id
    /// @param _startTimestamp Activity starting timestamp
    /// @param _endTimestamp Activity end timestamp
    /// @param _rewardTokenSupply Maximumreward supply for this activity
    event ActivityCreated(
        uint256 _activityId,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256[] _rewardTokenSupply
    );

    /// @notice Emit a gacha draw is completed
    /// @dev Emeits in drawTicket function
    /// @param _activityId Gacha activity Id
    /// @param _walletAddress Activity event Id
    /// @param _ticketType Used ticket type
    /// @param _ticketAmount Amount of ticket used for draw
    event DrawCompleted(
        uint256 _activityId,
        address _walletAddress,
        uint256 _ticketType,
        uint256 _ticketAmount,
        uint256[] _tokenIds,
        uint256[] _tokenAmounts,
        uint256 _drawIndex
    );

    modifier validActivity(uint256 _activityId) {
        if (_activityId > totalActivities || _activityId < 1) {
            revert InvalidActivity();
        }
        _;
    }

    modifier validActivityType(uint256 _activitType) {
        if (
            !(_activitType == FREE_ACTIVITY_TYPE ||
                _activitType == PREMIUM_ACTIVITY_TYPE)
        ) {
            revert InvalidActivityType();
        }
        _;
    }

    modifier validAddress(address _address) {
        if (_address == address(0) || _address == address(this)) {
            revert InvalidAddress();
        }
        _;
    }

    modifier validTimestamp(uint256 _startTimestamp, uint256 _endTimestamp) {
        if (_endTimestamp <= _startTimestamp) {
            revert InvalidTimestamp();
        }
        _;
    }

    uint256 public constant FREE_ACTIVITY_TYPE = 1;
    uint256 public constant PREMIUM_ACTIVITY_TYPE = 2;

    /// @dev Ticket smart contract instance
    IAnimeMetaverseTicket public TicketContract;
    /// @dev Reward smart contract instance
    IAnimeMetaverseReward public RewardContract;

    /// @dev Activity structure for keeping track all activity information
    struct Activity {
        uint256 activityId;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 activityType;
        bool isActive;
        uint256[] rewardTokenIds;
        uint256[] totalRewardSupply;
        uint256[] maximumRewardSupply;
        uint256 remainingSupply;
    }

    /// @dev Mapping to store activity information
    mapping(uint256 => Activity) public activities;

    uint256 public totalActivities = 0;
    uint256 public totalRewardWon = 0;
    uint256 public totalCompleteDraw = 0;
    uint256 public maxRewardTokenId = 18;

    /// @dev Create gacha draw contract instance
    /// @param _ticketContractAddress Ticket contract address
    /// @param _rewardContractAddress Reward contract address
    constructor(address _ticketContractAddress, address _rewardContractAddress)
    {
        TicketContract = IAnimeMetaverseTicket(_ticketContractAddress);
        RewardContract = IAnimeMetaverseReward(_rewardContractAddress);
    }

    /// @notice Owner only method for updating ticket token contract
    /// @dev Update ticket contract address
    /// @param _ticketContractAddress New ticket contract address
    function setTicketContract(address _ticketContractAddress)
        external
        onlyOwner
        validAddress(_ticketContractAddress)
    {
        TicketContract = IAnimeMetaverseTicket(_ticketContractAddress);
    }

    /// @notice Owner only method for updating max Id range for reward token
    /// @dev Update max reward tokenId range
    /// @param _maxRewardTokenId New range for reward tokenId
    function setMaxRewardTokenId(uint256 _maxRewardTokenId) external onlyOwner {
        maxRewardTokenId = _maxRewardTokenId;
    }

    /// @notice Owner only method for updating reward token contract
    /// @dev Update reward contract address
    /// @param _rewardContractAddress New reward contract address
    function setRewardContract(address _rewardContractAddress)
        external
        onlyOwner
        validAddress(_rewardContractAddress)
    {
        RewardContract = IAnimeMetaverseReward(_rewardContractAddress);
    }

    /// @notice Owner only method for creating an activity for gacha draw
    /// @dev Create a new activity
    /// @param _startTimestamp Activity starting time
    /// @param _endTimestamp Activity ending time
    /// @param _activityType Activity type: free or premium
    /// @param _rewardTokenIds tokenIds for giving reward
    /// @param _maxRewardSupply Max supply for each tokenId
    function createActivity(
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _activityType,
        uint256[] calldata _rewardTokenIds,
        uint256[] calldata _maxRewardSupply
    )
        external
        onlyOwner
        validActivityType(_activityType)
        validTimestamp(_startTimestamp, _endTimestamp)
    {

        if(_rewardTokenIds.length != _maxRewardSupply.length) {
            revert InvalidInputLength(); 
        }

        uint256 remainingSupply;
        for(uint256 index = 0; index < _rewardTokenIds.length; index++) {
            remainingSupply = remainingSupply + _maxRewardSupply[index];
            if(_rewardTokenIds[index] > maxRewardTokenId || _rewardTokenIds[index] < 1) {
                revert InvalidInput("Invalid reward tokenId.");
            }
        }

        /// @dev validate supply input
        if (remainingSupply < 1) {
            revert InsufficientReward();
        }

        totalActivities++;

        /// @dev Store activity information in map
        activities[totalActivities] = Activity({
            activityId: totalActivities,
            startTimestamp: _startTimestamp,
            endTimestamp: _endTimestamp,
            activityType: _activityType,
            isActive: true,
            totalRewardSupply: new uint256[](_maxRewardSupply.length),
            maximumRewardSupply: _maxRewardSupply,
            remainingSupply: remainingSupply,
            rewardTokenIds: _rewardTokenIds
        });

        /// @dev emit event after creating activity
        emit ActivityCreated(
            totalActivities,
            _startTimestamp,
            _endTimestamp,
            _maxRewardSupply
        );
    }

    /// @notice Owner only method for updating activity status
    /// @dev Sets activity as active or inactive
    /// @param _activityId Activity Id for which the status will be updated
    /// @param _flag Activity status flag
    function setActivityStatus(uint256 _activityId, bool _flag)
        external
        onlyOwner
        validActivity(_activityId)
    {
        activities[_activityId].isActive = _flag;
    }

    /// @notice Owner only method for updating activity timestamp
    /// @dev Update new timestamp
    /// @param _activityId Activity Id for which the timestamp will be updated
    /// @param _startTimestamp New start timestamp
    /// @param _endTimestamp New end timestamp
    function setActivityTimestamp(
        uint256 _activityId,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    )
        external
        onlyOwner
        validActivity(_activityId)
        validTimestamp(_startTimestamp, _endTimestamp)
    {
        activities[_activityId].startTimestamp = _startTimestamp;
        activities[_activityId].endTimestamp = _endTimestamp;
    }
    
    /// @notice Owner only method for updating max supply for an activity
    /// @dev Update activity reward supply
    /// @param _activityId Selected activity
    /// @param _rewardTokenIds tokenIds for giving reward
    /// @param _maxRewardSupply Max supply for each tokenId
    function updateMaximumRewardSupply(
        uint256 _activityId,
        uint256[] calldata _rewardTokenIds,
        uint256[] calldata _maxRewardSupply
    ) external onlyOwner validActivity(_activityId) {
        Activity memory activity = activities[_activityId];

        if(_rewardTokenIds.length != _maxRewardSupply.length) {
            revert InvalidInputLength(); 
        }

        if(_rewardTokenIds.length != activity.rewardTokenIds.length) {
            revert InvalidInputLength();
        }

        for(uint256 index = 0; index < _rewardTokenIds.length; index++) {
            if(_rewardTokenIds[index] != activity.rewardTokenIds[index]) {
                revert InvalidInput("TokenId Not Found.");
            }

            if(_maxRewardSupply[index] < activity.totalRewardSupply[index]) {
                revert InvalidInput("Maximum Supply Can Not Be Lower Than Total Supply.");
            }

            activity.maximumRewardSupply[index] = _maxRewardSupply[index];
        }

        activities[_activityId] = activity;
    }

    
    /// @notice External function for gacha draw. It burns tickets and provide rewards
    /// @dev Randomly choice reward tickets, burn the gacha tickets and then mint the reward for user
    /// @param _activityId Id of the activity for which users want to draw tickets
    /// @param _ticketAmount Id of the activity for getting total reward token supply
    function drawTicket(uint256 _activityId, uint256 _ticketAmount)
        external
        validActivity(_activityId)
    {
        Activity storage activity = activities[_activityId];

        /// @notice Reverts if the activity is not active
        /// @dev Validates if the activity is active or not
        if (!activity.isActive) {
            revert InactiveActivity();
        }

        /// @notice Reverts if current timestamp is out of range of the activity start and end timestamp
        /// @dev Validates if the current timestamp is within activity start and end timestamp
        if (
            block.timestamp < activity.startTimestamp ||
            block.timestamp > activity.endTimestamp
        ) {
            revert ActivityTimestampError();
        }

        if (_ticketAmount < 1) {
            revert InsufficientTicket();
        }

        /// @notice Reverts if the rewards supply is not enough
        /// @dev Validates if there are enough tickets or not
        if (activity.remainingSupply < _ticketAmount) {
            revert InsufficientReward();
        }

        totalCompleteDraw++;
        uint256[] memory selectedTokenAmount = new uint256[](maxRewardTokenId + 1);
        uint256[] memory tokenIds = new uint256[](maxRewardTokenId + 1);

        /// @dev For each tickets burns the tickets and mint a random reward
        for (uint256 i = 0; i < _ticketAmount; i++) {
            uint256 randomIndex = getRandomNumber(activity.remainingSupply);

            uint256 selectedTokenId = 0;
            uint256 indexCount = 0;

            /// @dev Find out the choosen reward time and increase it's supply
            for (uint256 j = 0; j < activities[_activityId].rewardTokenIds.length; j++) {
                uint256 remaining = activities[_activityId].maximumRewardSupply[j] 
                - activities[_activityId].totalRewardSupply[j];
                indexCount += remaining;

                if (remaining > 0 && indexCount >= randomIndex) {
                    selectedTokenId = activities[_activityId].rewardTokenIds[j];
                    activities[_activityId].totalRewardSupply[j]++;
                    break;
                }
            }

            selectedTokenAmount[selectedTokenId]++;
            activity.remainingSupply--;
            totalRewardWon++;
        }

        /// @dev Burns the tickets
        TicketContract.burn(activity.activityType, msg.sender, _ticketAmount);

        for (uint256 i = 0; i < activities[_activityId].rewardTokenIds.length; i++) {
            uint256 tokenId = activities[_activityId].rewardTokenIds[i];
            tokenIds[tokenId] = tokenId;
            if(selectedTokenAmount[tokenId] > 0) {
                ///@dev Mints one randomly choosen reward ticket
                RewardContract.mint(
                    _activityId,
                    msg.sender,
                    tokenId,
                    selectedTokenAmount[tokenId],
                    ""
                );
            }
        }

        emit DrawCompleted(
            _activityId,
            msg.sender,
            activity.activityType,
            _ticketAmount,
            tokenIds,
            selectedTokenAmount,
            totalCompleteDraw
        );
    }

    /// @notice Internal function for generating random number
    /// @dev Generate a randmom number where, 0 <= randomnumber < _moduler
    /// @param _moduler The range for generating random number
    function getRandomNumber(uint256 _moduler) internal view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number +
                        totalRewardWon
                )
            )
        );

        return (seed - ((seed / _moduler) * _moduler));
    }

    /// @notice getTotalRewardSupply is a external view method which has no gas fee
    /// @dev Provides the saved total reward token supply for any activity
    /// @param _activityId Id of the activity for getting total reward token supply
    function getTotalRewardSupply(uint256 _activityId)
        external
        view
        returns (uint256[] memory)
    {
        return activities[_activityId].totalRewardSupply;
    }

    /// @notice getMaximumRewardSupply is a external view method which has no gas fee
    /// @dev Provides the saved maximum reward token supply for any activity
    /// @param _activityId Id of the activity for getting maximum reward token supply
    function getMaximumRewardSupply(uint256 _activityId)
        external
        view
        returns (uint256[] memory)
    {
        return activities[_activityId].maximumRewardSupply;
    }

    /// @notice getRewardTokenIds is a external view method which has no gas fee
    /// @dev Provides the saved reward token Ids for any activity
    /// @param _activityId Id of the activity for getting reward tokenIds
    function getRewardTokenIds(uint256 _activityId)
        external
        view
        returns (uint256[] memory)
    {
        return activities[_activityId].rewardTokenIds;
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

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.15;

interface IAnimeMetaverseTicket {
    function burn(
        uint256 tokenId,
        address _account,
        uint256 _numberofTickets
    ) external;
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.15;

interface IAnimeMetaverseReward {
    function mint(
        uint256 _activityId,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;
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