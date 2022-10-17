// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./SeedGroup.sol";
import "./SimpleRollingGroup.sol";
import "./CustomRollingGroup.sol";
import "./CustomGroup.sol";

contract DistributeFactory is Ownable {

    address public groupContractDeployer;

    modifier onlyDeployer {
        if (msg.sender != owner() && msg.sender != groupContractDeployer) {
            revert NotADeployer();
        }

        _;
    }

    /* ========== Add Groups ============= */
    function addSeedGroup(
        bytes32 merkleRoot_,
        uint256[] calldata pDates_,
        uint256[] calldata percentages_,
        bool isOpen_
    )
        external
        onlyDeployer
        returns (address)
    {
        SeedGroup groupContract = new SeedGroup(merkleRoot_, pDates_, percentages_, isOpen_);
        return address(groupContract);
    }

    function addSimpleRollingGroup(
        bytes32 merkleRoot_,
        uint256 period_,
        uint256 percentage_,
        bool isOpen_
    )
        external
        onlyDeployer
        returns (address)
    {
        SimpleRollingGroup groupContract = new SimpleRollingGroup(merkleRoot_, period_, percentage_, isOpen_);
        return address(groupContract);
    }

    function addCustomRollingGroup(
        bytes32 merkleRoot_,
        bool isOpen_
    )
        external
        onlyDeployer
        returns (address)
    {
        CustomRollingGroup groupContract = new CustomRollingGroup(merkleRoot_, isOpen_);
        return address(groupContract);
    }

    function addCustomGroup(
        bytes32 merkleRoot_,
        bool isOpen_
    )
        external
        onlyDeployer
        returns (address)
    {
        CustomGroup groupContract = new CustomGroup(merkleRoot_, isOpen_);
        return address(groupContract);
    }

    /* ========== UPDATE ========== */
    function updateGroupContractDeployer(address groupContractDeployer_) external onlyOwner {
        groupContractDeployer = groupContractDeployer_;

        emit GroupContractDeployerUpdated(groupContractDeployer_);
    }

    /* ========== EVENTS ========== */
    event GroupContractDeployerUpdated(address groupContractDeployer);

    /* ========== ERRORS ========== */
    error NotADeployer();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./BaseGroup.sol";

contract CustomGroup is BaseGroup {
    constructor(bytes32 merkleRoot_, bool isOpen_) BaseGroup(merkleRoot_, isOpen_) {}

    function claimableAmount(
        address receiverAddress,
        uint256 amount,
        uint256[] calldata dates,
        uint256[] calldata percentages
    )
        external
        view
        returns (uint256 lastPaidDate, uint256 claimable)
    {
        uint256 currentTime = block.timestamp;

        uint256 claimablePercentage = 0;

        for(uint256 i = 0; i < dates.length; i++) {
            uint256 date = dates[i];

            if (currentTime >= date) {
                if (date > userLastPaidDate[receiverAddress]) {
                    claimablePercentage += percentages[i];
                    lastPaidDate = date;
                }
            }
        }

        if (lastPaidDate == dates[dates.length - 1]) {
            claimable = amount - userClaimedAmount[receiverAddress];
        } else {
            claimable = amount * claimablePercentage / PERCENT_DENOMINATOR;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./RollingGroup.sol";

contract SimpleRollingGroup is RollingGroup {
   
    uint256 public immutable period;
    uint256 public immutable percentage;

    constructor(bytes32 merkleRoot_, uint256 period_, uint256 percentage_, bool isOpen_) RollingGroup(merkleRoot_, isOpen_) {
        if (period_ <= 0 || percentage_ > PERCENT_DENOMINATOR) {
            revert SimpleRollingGroupInvalidInitValues();
        }
      
        period = period_;
        percentage = percentage_;
    }

    function claimableAmount(
        address receiverAddress,
        uint256 amount,
        uint256 startDate
    )
        external
        view
        returns (uint256 lastPaidDate, uint256 claimable)
    {
        (lastPaidDate, claimable) = _claimableAmount(receiverAddress, amount, startDate, period, percentage);
    }

    /* ========== ERRORS ========== */
    error SimpleRollingGroupInvalidInitValues();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./BaseGroup.sol";

contract SeedGroup is BaseGroup {
    struct DistStage {
        uint48 distDate;
        uint16 percentage;
    }

    DistStage[] private _stages;

    constructor(bytes32 merkleRoot_, uint256[] memory pDates, uint256[] memory percentages, bool isOpen_) BaseGroup(merkleRoot_, isOpen_) {
        if (pDates.length == 0 || percentages.length == 0 || pDates.length != percentages.length) {
            revert InvalidSeedGroupInitValues();
        }

        uint256 totalPercentage = 0;

        for (uint256 i = 0; i < pDates.length; i++) {
            DistStage memory stage = DistStage(
                uint48(pDates[i]),
                uint16(percentages[i])
            );
            unchecked {
                totalPercentage += percentages[i];    
            }
            
            _stages.push(stage);
        }

        if (totalPercentage != PERCENT_DENOMINATOR) {
            revert SeedGroupPercentageSumIsNot100();
        }
    }

    function claimableAmount(address receiverAddress, uint256 amount) external view returns (uint256 lastPaidDate, uint256 claimable) {
        DistStage[] memory stageList = _stages;

        uint256 currentTime = block.timestamp;

        uint256 claimablePercentage = 0;

        for(uint256 i = 0; i < stageList.length; i++) {
            uint256 distDate = stageList[i].distDate;

            if (currentTime >= distDate) {
                if (distDate > userLastPaidDate[receiverAddress]) {
                    claimablePercentage += stageList[i].percentage;
                    lastPaidDate = distDate;
                }
            }
        }

        if (lastPaidDate == stageList[stageList.length - 1].distDate) {
            claimable = amount - userClaimedAmount[receiverAddress];
        } else {
            claimable = amount * claimablePercentage / PERCENT_DENOMINATOR;
        }
    }

    function stages() external view returns(DistStage[] memory) {
        return _stages;
    }

    /* ========== ERRORS ========== */
    error InvalidSeedGroupInitValues();
    error SeedGroupPercentageSumIsNot100();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./RollingGroup.sol";

contract CustomRollingGroup is RollingGroup {
   
    constructor(bytes32 merkleRoot_, bool isOpen_) RollingGroup(merkleRoot_, isOpen_) {}

    function claimableAmount(
        address receiverAddress,
        uint256 amount,
        uint256 startDate,
        uint256 period,
        uint256 percentage
    )
        external
        view
        returns (uint256 lastPaidDate, uint256 claimable)
    {
        if (percentage > PERCENT_DENOMINATOR) {
            revert PercentageAbove100();
        }
        (lastPaidDate, claimable) = _claimableAmount(receiverAddress, amount, startDate, period, percentage);
    }

    /* ========== ERRORS ========== */
    error PercentageAbove100();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFactory {
    function groupContractDeployer() external view returns (address);
}

contract BaseGroup is Ownable {

    bytes32 public merkleRoot;

    mapping(address => uint256) public userClaimedAmount;   // Total claimed amount
    mapping(address => uint256) public userLastPaidDate;    // The last paid date - pDates or startDate & period

    bool public immutable isOpen;
    IFactory public immutable factory;

    uint256 public constant PERCENT_DENOMINATOR = 10000;

    modifier onlyValidator {
        if (msg.sender != owner() && msg.sender != factory.groupContractDeployer()) {
            revert OnlyFactoryOrDistributorCanDoThisAction();
        }

        _;
    }

    constructor(bytes32 merkleRoot_, bool isOpen_) {
        merkleRoot = merkleRoot_;
        isOpen = isOpen_;
        factory = IFactory(msg.sender);
    }

    function updateUserDistribute(address receiverAddress, uint256 lastPaidDate, uint256 claimable)
        external
        onlyValidator()
    {
        userLastPaidDate[receiverAddress] = lastPaidDate;
        userClaimedAmount[receiverAddress] += claimable;
    }

    function updateMerkleRoot(bytes32 merkleRoot_) external onlyValidator {
        if (!isOpen) {
            revert GroupIsNotOpened();
        }

        merkleRoot = merkleRoot_;
    }

    /* ========== ERRORS ========== */
    error GroupIsNotOpened();
    error OnlyFactoryOrDistributorCanDoThisAction();
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./BaseGroup.sol";

contract RollingGroup is BaseGroup {
   
    constructor(bytes32 merkleRoot_, bool isOpen_) BaseGroup(merkleRoot_, isOpen_) {}

    function _claimableAmount(
        address receiverAddress,
        uint256 amount,
        uint256 startDate,
        uint256 period,
        uint256 percentage
    )
        internal
        view
        returns (uint256 lastPaidDate, uint256 claimable)
    {

        uint256 currentTime = block.timestamp;

        // if currentTime is before startDate
        if (currentTime < startDate) {
            return (lastPaidDate, claimable);
        }

        uint256 restAmount = amount - userClaimedAmount[receiverAddress];

        // If the user already get paid all amount, no need to pay
        if (restAmount == 0) {
            return (lastPaidDate, claimable);
        }

        // How many time the user should paid
        uint256 passedTimeFromStart = currentTime - startDate;
        uint256 paidCntFromStart =  (passedTimeFromStart / period) + 1;

        // If the user should get paid more than 100%
        // In case of percentage is 30% and he should get paid 4 times
        // Send rest of amount
        if ((paidCntFromStart * percentage) >= PERCENT_DENOMINATOR) {
            claimable = restAmount;
            lastPaidDate = startDate + (paidCntFromStart - 1) * period;

            return (lastPaidDate, claimable);
        }

        lastPaidDate = userLastPaidDate[receiverAddress];
        if (lastPaidDate == 0) {
            lastPaidDate = startDate;
        }

        // How many time the user should paid more
        // Calculated from the lastPaidDate.
        uint256 passedTimeFromLast = lastPaidDate - startDate;
        uint256 paidCntFromLast = (passedTimeFromLast / period) + 1;

        uint256 shouldPaidCnt = paidCntFromStart - paidCntFromLast + 1;

        claimable = (amount * percentage * shouldPaidCnt) / PERCENT_DENOMINATOR;
        lastPaidDate = lastPaidDate + (shouldPaidCnt - 1) * period;
    }
}