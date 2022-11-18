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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

// Comment for Remix
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.0/contracts/access/Ownable.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.0/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct Project {
    uint128 id;
    uint48 approvedAt;
    uint48 endAt;
    address walletAddress; // 20 bytes
    uint256 backedAmount;
    uint256 targetAmount;
}

contract CleverLaunch is Ownable {
    // MainStorage part
    mapping(uint128 => Project) private projectMap;

    mapping(uint128 => mapping(address => uint256)) private userBackedAmount;

    address tokenAddress;

    address cleverLaunchAddress;
    // End of MainStorage part

    // Event part
    event TokenAddressChanged(
        address indexed previousTokenAddress,
        address indexed newTokenAddress
    );

    event ProjectApproved(uint128 indexed projectId);

    event ProjectDeposit(
        uint128 indexed projectId,
        address from,
        uint256 amount
    );

    event BackerClaimFund(
        uint128 indexed projectId,
        address indexed walletAddress,
        uint256 amount
    );

    event CreatorClaimFund(
        uint128 indexed projectId,
        address indexed walletAddress,
        uint256 amount
    );
    // TODO: add more event
    // End of Event part

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    // Modifier part
    /**
     * @dev Throws if project id does not exist.
     */
    modifier onlyProjectExist(uint128 _projectId) {
        require(
            projectMap[_projectId].approvedAt != 0,
            "Project does not exist"
        );
        _;
    }

    modifier onlyProjectNotEnded(uint128 _projectId) {
        require(
            projectMap[_projectId].endAt > block.timestamp,
            "Project ended"
        );
        _;
    }

    modifier onlyProjectNotExist(uint128 _projectId) {
        require(
            projectMap[_projectId].approvedAt == 0,
            "Project already exist"
        );
        _;
    }

    modifier onlyProjectFailedFunding(uint128 _projectId) {
        if (
            projectMap[_projectId].endAt > block.timestamp * 1000 &&
            projectMap[_projectId].targetAmount >
            projectMap[_projectId].backedAmount
        ) {
            revert("Project is not failed funding yet");
        }
        _;
    }

    modifier onlyProjectSuccessFunding(uint128 _projectId) {
        if (
            projectMap[_projectId].endAt > block.timestamp * 1000 &&
            projectMap[_projectId].targetAmount <=
            projectMap[_projectId].backedAmount
        ) {
            revert("Project is not success funding yet");
        }
        _;
    }

    // End of Modifier part

    // Action part
    function deposit(uint128 _projectId, uint256 _amount)
        external
        onlyProjectExist(_projectId)
        onlyProjectNotEnded(_projectId)
    {
        require(_amount > 0, "Amount can't be 0");

        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), _amount);

        // update state
        userBackedAmount[_projectId][msg.sender] += _amount;
        projectMap[_projectId].backedAmount += _amount;

        emit ProjectDeposit(_projectId, msg.sender, _amount);
    }

    function createProject(
        uint128 _projectId,
        uint48 _approvedAt,
        uint48 _endAt,
        address _walletAddress,
        uint256 _targetAmount
    ) external onlyOwner onlyProjectNotExist(_projectId) {
        require(
            _approvedAt < _endAt,
            "Approved time must be higher than end time"
        );
        require(_endAt > block.timestamp, "Invalid end time");
        require(
            _targetAmount > 0,
            "Target amount cannot be equal or less than 0"
        );
        // prevent accidentally burn fund
        require(_walletAddress != address(0x0), "Invalid wallet address");

        projectMap[_projectId] = Project(
            _projectId,
            _approvedAt,
            _endAt,
            _walletAddress,
            0,
            _targetAmount
        );
    }

    // Set the ERC20 token address
    function setTokenAddress(address _tokenAddress) external {
        require(tokenAddress != _tokenAddress);
        address prevTokenAddress = tokenAddress;
        tokenAddress = _tokenAddress;
        emit TokenAddressChanged(prevTokenAddress, tokenAddress);
    }

    function getTokenAddress() external view returns (address) {
        return tokenAddress;
    }

    // For backer to reclaim their fund
    // Only work after project has failed funding round
    function claimFundBacker(uint128 _projectId)
        external
        onlyProjectExist(_projectId)
        onlyProjectFailedFunding(_projectId)
    {
        require(
            userBackedAmount[_projectId][msg.sender] > 0,
            "User backed amount is empty"
        );
        IERC20 token = IERC20(tokenAddress);
        uint256 transferAmount = userBackedAmount[_projectId][msg.sender];
        userBackedAmount[_projectId][msg.sender] = 0;

        token.transfer(msg.sender, transferAmount);

        emit BackerClaimFund(_projectId, msg.sender, transferAmount);
    }

    function claimFundCreator(uint128 _projectId)
        external
        onlyProjectExist(_projectId)
        onlyProjectSuccessFunding(_projectId)
    {
        require(
            projectMap[_projectId].backedAmount > 0,
            "Project fund is empty"
        );
        IERC20 token = IERC20(tokenAddress);

        // CleverLaunch takes 5%
        uint256 transferAmount = projectMap[_projectId].backedAmount -
            (projectMap[_projectId].backedAmount * 5) /
            100;
        projectMap[_projectId].backedAmount = 0;

        token.transfer(projectMap[_projectId].walletAddress, transferAmount);

        emit CreatorClaimFund(
            _projectId,
            projectMap[_projectId].walletAddress,
            transferAmount
        );
    }

    function getBackerAmount(uint128 _projectId, address _backerAddress)
        external
        view
        returns (uint256)
    {
        return userBackedAmount[_projectId][_backerAddress];
    }

    function getProjectEndTime(uint128 _projectId)
        external
        view
        returns (uint48)
    {
        return projectMap[_projectId].endAt;
    }

    function getProjectBackedAmount(uint128 _projectId)
        external
        view
        returns (uint256 backedAmount)
    {
        backedAmount = projectMap[_projectId].backedAmount;
    }

    function getProjectWalletAddress(uint128 _projectId)
        external
        view
        returns (address)
    {
        return projectMap[_projectId].walletAddress;
    }
}