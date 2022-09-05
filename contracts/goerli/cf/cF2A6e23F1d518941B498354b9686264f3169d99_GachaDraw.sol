// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAnimeMetaverseTicket.sol";

error InsufficientReward();
error InvalidActivity();
error InvalidTicketAmount();
error InvalidActivityType();
error InactiveActivity();
error ActivityTimestampError();
error InvalidTicketTokenId();
error InvalidAddress();
error InvalidInput();

contract GachaDraw is Ownable {
    modifier validActivity(uint _activityId) {
        if(_activityId > totalActivities || _activityId < 1) {
            revert InvalidActivity();
        }
        _;
    }

    modifier validTicket(uint256 _ticketId) {
        if(!(_ticketId == FREE_ACTIVITY_TYPE || _ticketId == PREMIUM_ACTIVITY_TYPE)) {
            revert InvalidTicketTokenId();
        }
        _;
    }

    modifier validAddress(address _address) {
        if (_address == address(0) || _address == address(this)) {
            revert InvalidAddress();
        }
        _;
    }

    uint256 public constant FREE_ACTIVITY_TYPE = 1;
    uint256 public constant PREMIUM_ACTIVITY_TYPE = 2;
    uint256 public constant SPECIAL_ACTIVITY_TYPE = 3;

    IAnimeMetaverseTicket TicketContract;

    struct Activity {
        string eventName;
        string activityName;
        uint256 activityId;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 activityType;
        bool isActive;
        uint256[] rewardTokenIds;
        uint256[] totalRewardSupply;
        uint256[] maximumRewardSupply;
    }

    struct AvailableRewardItem {
        uint256 tokenId;
        uint256 index;
    }

    struct AvailableRewardResult {
        AvailableRewardItem[] availableRewards;
        uint256 availableRewardCount;
    }

    mapping(uint256 => Activity) public activities;

    uint256 public totalActivities = 0;
    uint256 public totalRewardWon = 0;

    // constructor() {}

    function setTicketContract(address _ticketContractAddress) 
    external onlyOwner validAddress(_ticketContractAddress) {
        TicketContract = IAnimeMetaverseTicket(_ticketContractAddress);
    }

    function createActivity(
        // string memory _eventName,
        // string memory _activityName,
        // uint256 _startTimestamp,
        // uint256 _endTimestamp,
        // uint256 _activityType
        // uint256[] memory _rewardTokenIds,
        uint256[] memory _rewardTokenSupply
    ) external onlyOwner {

        // if(!(
        //     _activityType == FREE_ACTIVITY_TYPE ||
        //     _activityType == PREMIUM_ACTIVITY_TYPE ||
        //     _activityType == SPECIAL_ACTIVITY_TYPE
        // )) {
        //     revert InvalidActivityType();
        // }

        

        // if(_rewardTokenIds.length != _rewardTokenSupply.length) {
        //     revert InvalidInput();
        // }

        totalActivities ++;

        // activitis[totalActivities] = Activity(
        //     _eventName,
        //     _activityName,
        //     totalActivities,
        //     _startTimestamp,
        //     _endTimestamp,
        //     _activityType,
        //     true,
        //     _rewardTokenIds,
        //     new uint256[](_rewardTokenIds.length),
        //     _rewardTokenSupply
        // );

    }

    function createActivity2(
        // string memory _eventName,
        // string memory _activityName,
        // uint256 _startTimestamp,
        // uint256 _endTimestamp,
        // uint256 _activityType
        uint256[] memory _rewardTokenIds,
        uint256[] memory _rewardTokenSupply
    ) external onlyOwner {

        // if(!(
        //     _activityType == FREE_ACTIVITY_TYPE ||
        //     _activityType == PREMIUM_ACTIVITY_TYPE ||
        //     _activityType == SPECIAL_ACTIVITY_TYPE
        // )) {
        //     revert InvalidActivityType();
        // }

        

        // if(_rewardTokenIds.length != _rewardTokenSupply.length) {
        //     revert InvalidInput();
        // }

        totalActivities ++;

        // activitis[totalActivities] = Activity(
        //     _eventName,
        //     _activityName,
        //     totalActivities,
        //     _startTimestamp,
        //     _endTimestamp,
        //     _activityType,
        //     true,
        //     _rewardTokenIds,
        //     new uint256[](_rewardTokenIds.length),
        //     _rewardTokenSupply
        // );

    }


    // function setActivityStatus(uint256 _activityId, bool _flag) external onlyOwner validActivity(_activityId) {
    //     activitis[_activityId].isActive = _flag;
    // }

    // function setActivityTimestamp(
    //     uint256 _activityId, 
    //     uint256 _startTimestamp, 
    //     uint256 _endTimestamp
    // ) external onlyOwner validActivity(_activityId) {
    //     activitis[_activityId].startTimestamp = _startTimestamp;
    //     activitis[_activityId].endTimestamp = _endTimestamp;
    // }

    // function getAvailableRewardToken(uint256 _activityId) internal view returns(AvailableRewardResult memory) {
    //     AvailableRewardItem[] memory selectedReward = new AvailableRewardItem[](activitis[_activityId].rewardTokenIds.length);
    //     uint256 totalAvailableReward = 0;

    //     for(uint256 i = 0; i < activitis[_activityId].rewardTokenIds.length; i++) {
    //         if(activitis[_activityId].totalRewardSupply[i] < activitis[_activityId].maximumRewardSupply[i]) {
    //             selectedReward[totalAvailableReward] = AvailableRewardItem(activitis[_activityId].rewardTokenIds[i], i);
    //             totalAvailableReward ++;
    //         }
    //     }

    //     if(totalAvailableReward <= 0) {
    //         revert InsufficientReward();
    //     }

    //     return AvailableRewardResult(selectedReward, totalAvailableReward);
    // }

    // function getRandomNumber(uint256 moduler) internal view returns(uint256) {
    //     uint256 seed = uint256(keccak256(abi.encodePacked(
    //         block.timestamp + block.difficulty +
    //         ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
    //         block.gaslimit + 
    //           ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
    //         block.number + totalRewardWon + totalActivities
    //     )));

    //     return (seed % moduler);
    // }

    

    // function drawTicket(
    //     uint256 _activityId, 
    //     uint256 _ticketTokenId, 
    //     uint256 _amount
    // ) external validActivity(_activityId) validTicket(_ticketTokenId) {
        
    //     if(!activitis[_activityId].isActive) {
    //         revert InactiveActivity();
    //     }

    //     // NOTE: add array length validtion

    //     if(
    //         block.timestamp < activitis[_activityId].startTimestamp || 
    //         block.timestamp > activitis[_activityId].endTimestamp
    //     ) {
    //         revert ActivityTimestampError();
    //     }

    //     if(
    //         activitis[_activityId].activityType != SPECIAL_ACTIVITY_TYPE
    //         && activitis[_activityId].activityType != _ticketTokenId
    //     ) {
    //         revert InvalidTicketTokenId();
    //     }
        
    //     if(!(_amount == 1 || _amount == 10)) {
    //         revert InvalidTicketAmount();
    //     }
        
    //     for(uint256 i = 0; i < _amount; i++) {
    //         AvailableRewardResult memory availableRewardResult = getAvailableRewardToken(_activityId);
    //         uint256 selectedIndex = getRandomNumber(availableRewardResult.availableRewardCount);
    //         AvailableRewardItem memory selectedReward = availableRewardResult.availableRewards[selectedIndex];
    //         activitis[_activityId].totalRewardSupply[selectedReward.index] ++;
    //         totalRewardWon ++;

    //         TicketContract.burn(_ticketTokenId, msg.sender, 1);
    //         // Rewardcontract.mintReward()
    //     }
    // }

    // function getTotalRewarSupply(uint256 _activityId) external view returns(uint256[] memory) {
    //     return activitis[_activityId].totalRewardSupply;
    // }

    // function getMaximumRewarSupply(uint256 _activityId) external view returns(uint256[] memory) {
    //     return activitis[_activityId].maximumRewardSupply;
    // }

    // function getRewardTokenIds(uint256 _activityId) external view returns(uint256[] memory) {
    //     return activitis[_activityId].rewardTokenIds;
    // }
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