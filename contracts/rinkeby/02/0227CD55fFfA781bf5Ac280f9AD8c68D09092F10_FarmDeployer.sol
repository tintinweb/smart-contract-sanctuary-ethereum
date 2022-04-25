//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IFarmDeployer.sol";


contract FarmDeployer is Ownable, IFarmDeployer {

    event DeployedERC20Farm(
        address farmAddress,
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _rewardPerBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        uint256 _earlyWithdrawalFee,
        address _feeReceiver,
        bool _keepReflectionOnDeposit,
        address owner
    );

    event DeployedERC20FarmFixEnd(
        address farmAddress,
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        uint256 _earlyWithdrawalFee,
        address _feeReceiver,
        address owner
    );

    event DeployedERC721Farm(
        address farmAddress,
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _rewardPerBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        address owner
    );

    event DeployedERC721FarmFixEnd(
        address farmAddress,
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        address owner
    );

    event NewDeploymentCost(uint256);
    event NewIncomeFee(uint256);
    event NewMaxLockTime(uint256);
    event NewFeeReceiver(address payable);
    event SetFarmDeployers(
        IFarmDeployer20 farmDeployer20,
        IFarmDeployer20FixEnd farmDeployer20FixEnd,
        IFarmDeployer721 farmDeployer721,
        IFarmDeployer721 farmDeployer721FixEnd
    );

    uint256 public deploymentCost;
    uint256 public maxLockTime;
    uint256 public incomeFee;
    address payable public feeReceiver;

    IFarmDeployer20 public farmDeployer20;
    IFarmDeployer20FixEnd public farmDeployer20FixEnd;
    IFarmDeployer721 public farmDeployer721;
    IFarmDeployer721 public farmDeployer721FixEnd;


    /*
     * @notice Initialize the contract
     * @param _deploymentCost: Cost of pool creation (in BNB)
     * @param _maxLockTime: Maximum number of blocks, that pools are allowed
     * to demand for locking deposits
     * @param _incomeFee: Amount of income fee (for reward tokens, in basis points)
     * @param _feeReceiver: Address of receiver for deployment cost fee and reward tokens fee
     */
    constructor(
        uint256 _deploymentCost,
        uint256 _maxLockTime,
        uint256 _incomeFee,
        address payable _feeReceiver
    ) {
        deploymentCost = _deploymentCost;
        maxLockTime = _maxLockTime;
        feeReceiver = _feeReceiver;
        incomeFee = _incomeFee;
    }


    /*
     * @notice Deploys ERC20Farm contract. Requires amount of BNB to be paid
     * @param _stakeToken: Stake token contract address
     * @param _rewardToken: Reward token contract address
     * @param _startBlock: Start block
     * @param _rewardPerBlock: Reward per block (in rewardToken)
     * @param _userStakeLimit: Maximum amount of tokens a user is allowed to stake (if any, else 0)
     * @param _minimumLockTime: Minimum number of blocks user should wait after deposit to withdraw without fee
     * @param _earlyWithdrawalFee: Fee for early withdrawal - in basis points
     * @param _feeReceiver: Receiver of early withdrawal fees
     * @param _keepReflectionOnDeposit: Should the farm keep track of reflection tokens on deposit?
     * @return farmAddress: Address of deployed pool contract
     */
    function deployERC20Farm(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _rewardPerBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        uint256 _earlyWithdrawalFee,
        address _feeReceiver,
        bool _keepReflectionOnDeposit
    ) external payable returns(address farmAddress){
        require(msg.value >= deploymentCost, "Not enough ETH");
        require(_minimumLockTime <= maxLockTime, "Over max lock time");
        feeReceiver.transfer(msg.value);

        farmAddress = farmDeployer20.deploy(
                _stakeToken,
                _rewardToken,
                _startBlock,
                _rewardPerBlock,
                _userStakeLimit,
                _minimumLockTime,
                _earlyWithdrawalFee,
                _feeReceiver,
                _keepReflectionOnDeposit,
                msg.sender
            );

        emit DeployedERC20Farm(
            farmAddress,
            _stakeToken,
            _rewardToken,
            _startBlock,
            _rewardPerBlock,
            _userStakeLimit,
            _minimumLockTime,
            _earlyWithdrawalFee,
            _feeReceiver,
            _keepReflectionOnDeposit,
            msg.sender
        );
    }


    /*
     * @notice Deploys ERC20FarmFixEnd contract. Requires amount of BNB to be paid
     * @param _stakeToken: Stake token contract address
     * @param _rewardToken: Reward token contract address
     * @param _startBlock: Start block
     * @param _endBlock: End block of reward distribution
     * @param _userStakeLimit: Maximum amount of tokens a user is allowed to stake (if any, else 0)
     * @param _minimumLockTime: Minimum number of blocks user should wait after deposit to withdraw without fee
     * @param _earlyWithdrawalFee: Fee for early withdrawal - in basis points
     * @param _feeReceiver: Receiver of early withdrawal fees
     * @param _keepReflectionOnDeposit: Should the farm keep track of reflection tokens on deposit?
     * @return farmAddress: Address of deployed pool contract
     */
    function deployERC20FarmFixEnd(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        uint256 _earlyWithdrawalFee,
        address _feeReceiver
    ) external payable returns(address farmAddress){
        require(msg.value >= deploymentCost, "Not enough ETH");
        require(_minimumLockTime <= maxLockTime, "Over max lock time");
        feeReceiver.transfer(msg.value);

        farmAddress = farmDeployer20FixEnd.deploy(
                _stakeToken,
                _rewardToken,
                _startBlock,
                _endBlock,
                _userStakeLimit,
                _minimumLockTime,
                _earlyWithdrawalFee,
                _feeReceiver,
                msg.sender
            );

        emit DeployedERC20FarmFixEnd(
            farmAddress,
            _stakeToken,
            _rewardToken,
            _startBlock,
            _endBlock,
            _userStakeLimit,
            _minimumLockTime,
            _earlyWithdrawalFee,
            _feeReceiver,
            msg.sender
        );
    }


    /*
     * @notice Deploys ERC721Farm contract. Requires amount of BNB to be paid
     * @param _stakeToken: Stake token address
     * @param _rewardToken: Reward token address
     * @param _startBlock: Start block
     * @param _rewardPerBlock: Reward per block (in rewardToken)
     * @param _userStakeLimit: Maximum amount of tokens a user is allowed to stake (if any, else 0)
     * @param _minimumLockTime: Minimum number of blocks user should wait after deposit to withdraw without fee
     * @return farmAddress: Address of deployed pool contract
     */
    function deployERC721Farm(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _rewardPerBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime
    ) external payable returns(address farmAddress){
        require(msg.value >= deploymentCost, "Not enough ETH");
        require(_minimumLockTime <= maxLockTime, "Over max lock time");
        feeReceiver.transfer(msg.value);

        farmAddress = farmDeployer721.deploy(
                _stakeToken,
                _rewardToken,
                _startBlock,
                _rewardPerBlock,
                _userStakeLimit,
                _minimumLockTime,
                msg.sender
            );

        emit DeployedERC721Farm(
            farmAddress,
            _stakeToken,
            _rewardToken,
            _startBlock,
            _rewardPerBlock,
            _userStakeLimit,
            _minimumLockTime,
            msg.sender
        );
    }


    /*
     * @notice Deploys ERC721FarmFixEnd contract. Requires amount of BNB to be paid
     * @param _stakeToken: Stake token address
     * @param _rewardToken: Reward token address
     * @param _startBlock: Start block
     * @param _endBlock: End block of reward distribution
     * @param _userStakeLimit: Maximum amount of tokens a user is allowed to stake (if any, else 0)
     * @param _minimumLockTime: Minimum number of blocks user should wait after deposit to withdraw without fee
     * @return farmAddress: Address of deployed pool contract
     */
    function deployERC721FarmFixEnd(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime
    ) external payable returns(address farmAddress){
        require(msg.value >= deploymentCost, "Not enough ETH");
        require(_minimumLockTime <= maxLockTime, "Over max lock time");
        feeReceiver.transfer(msg.value);

        farmAddress = farmDeployer721FixEnd.deploy(
                _stakeToken,
                _rewardToken,
                _startBlock,
                    _endBlock,
                _userStakeLimit,
                _minimumLockTime,
                msg.sender
            );

        emit DeployedERC721FarmFixEnd(
            farmAddress,
            _stakeToken,
            _rewardToken,
            _startBlock,
            _endBlock,
            _userStakeLimit,
            _minimumLockTime,
            msg.sender
        );
    }


    /*
     * @notice Sets farm deployers contracts
     * @param _farmDeployer20: ERC20 farm deployer address with fixed reward per block
     * @param _farmDeployer20FixEnd: ERC20 farm deployer address with fixed end block
     * @param _farmDeployer721: ERC721 farm deployer address with fixed reward per block
     * @param _farmDeployer721FixEnd: ERC721 farm deployer address with fixed end block
     */
    function setDeployers(
        IFarmDeployer20 _farmDeployer20,
        IFarmDeployer20FixEnd _farmDeployer20FixEnd,
        IFarmDeployer721 _farmDeployer721,
        IFarmDeployer721 _farmDeployer721FixEnd
    ) external onlyOwner {
        farmDeployer20 = _farmDeployer20;
        farmDeployer20FixEnd = _farmDeployer20FixEnd;
        farmDeployer721 = _farmDeployer721;
        farmDeployer721FixEnd = _farmDeployer721FixEnd;

        emit SetFarmDeployers(
            _farmDeployer20,
            _farmDeployer20FixEnd,
            _farmDeployer721,
            _farmDeployer721FixEnd
        );
    }


    /*
     * @notice Sets the cost for deploying pools
     * @param _deploymentCost: Amount of BNB to pay
     */
    function setDeploymentCost(uint256 _deploymentCost) external onlyOwner {
        require(deploymentCost != _deploymentCost, "Already set");
        deploymentCost = _deploymentCost;

        emit NewDeploymentCost(_deploymentCost);
    }


    /*
     * @notice Sets fee receiver address
     * @param _feeReceiver: Address of fee receiver
     */
    function setFeeReceiver(address payable _feeReceiver) external onlyOwner {
        require(feeReceiver != _feeReceiver, "Already set");
        require(address(0) != _feeReceiver);
        feeReceiver = _feeReceiver;

        emit NewFeeReceiver(_feeReceiver);
    }


    /*
     * @notice Sets income fee share for the pools
     * @param _incomeFee: Income fee (in basis points)
     * (can't be higher than 5000 (50%)
     */
    function setIncomeFee(uint256 _incomeFee) external onlyOwner {
        require(_incomeFee <= 5000, "Over 50%");
        incomeFee = _incomeFee;

        emit NewIncomeFee(_incomeFee);
    }


    /*
     * @notice Sets Maximum number of blocks, that pools are allowed
     * to demand for locking deposits
     * @param _maxLockTime: Maximum number of blocks, that pools are allowed
     * to demand for locking deposits
     */
    function setMaxLockTime(uint256 _maxLockTime) external onlyOwner {
        require(maxLockTime != _maxLockTime, "Already set");
        maxLockTime = _maxLockTime;

        emit NewMaxLockTime(_maxLockTime);
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

interface IFarmDeployer {
    function maxLockTime() external returns(uint256);
    function incomeFee() external returns(uint256);
    function feeReceiver() external returns(address payable);
}

interface IFarmDeployer20 {
    function farmDeployer() external returns(address);
    function deploy(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _rewardPerBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        uint256 _earlyWithdrawalFee,
        address _feeReceiver,
        bool _keepReflectionOnDeposit,
        address owner
    ) external returns(address);
}

interface IFarmDeployer20FixEnd {
    function farmDeployer() external returns(address);
    function deploy(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        uint256 _earlyWithdrawalFee,
        address _feeReceiver,
        address owner
    ) external returns(address);
}

interface IFarmDeployer721 {
    function farmDeployer() external returns(address);
    function deploy(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _rewardPerBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        address owner
    ) external returns(address);
}

interface IFarmDeployer721FixEnd {
    function farmDeployer() external returns(address);
    function deploy(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        address owner
    ) external returns(address);
}

interface IERC20Farm {
    function initialize(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _rewardPerBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        uint256 _earlyWithdrawalFee,
        address _feeReceiver,
        bool _keepReflectionOnDeposit,
        address owner
    ) external;
}

interface IERC20FarmFixEnd {
    function initialize(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        uint256 _earlyWithdrawalFee,
        address _feeReceiver,
        address owner
    ) external;
}

interface IERC721Farm {
    function initialize(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _rewardPerBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        address owner
    ) external;
}

interface IERC721FarmFixEnd {
    function initialize(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        address owner
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