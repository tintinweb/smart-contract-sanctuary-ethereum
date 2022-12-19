//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract FetcchGovernance is Ownable {
    uint256 constant FLOAT_HANDLER_TEN_4 = 10000;
    uint256 private BASE_FEE = 100;

    address private constant NATIVE =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public fetcchpool;
    mapping(address => bool) public lpData;
    mapping(address => mapping(address => uint256)) public lpBalance;
    mapping(address => mapping(address => uint256)) public lpRewards;
    mapping(address => mapping(address => uint256)) public lpDisbursedRewards;
    mapping(address => uint256) totalLiquidity;
    mapping(address => uint256) totalExcessLiquidity;
    mapping(address => uint256) rewardsPool;

    address[] lpList;
    // mapping(address => uint) public totalRewardsEarned;

    modifier onlyPool(address _pool) {
        require(
            _pool == fetcchpool,
            "Fetcch: only can be called by FetcchPool"
        );
        _;
    }

    event AddedLP(address lp, address token, uint256 amount);

    constructor(address _fetcchpool) {
        fetcchpool = _fetcchpool;
    }

    function changePool(address _pool) external onlyOwner {
        fetcchpool = _pool;
    }

    function addLP(
        address _lp,
        address _token,
        uint256 _amount // onlyPool(msg.sender)
    ) public {
        require(_amount > 0, "Fetcch: amount should be greater than zero");
        require(_lp != address(0), "Fetcch: LP Address cannot be zero");
        require(_token != address(0), "Fetcch: Cannot be address(0)");
        // require(lpData[_lp], "Fetcch: LP already exists");

        lpData[_lp] = true;
        lpBalance[_lp][_token] = _amount;
        lpList.push(_lp);
        emit AddedLP(_lp, _token, _amount);
    }

    function updateLP(
        address _lp,
        address _token,
        uint256 _disbursedAmount,
        uint256 _disbursedReward
    ) public onlyPool(msg.sender) {
        lpBalance[_lp][_token] -= _disbursedAmount;
        lpDisbursedRewards[_lp][_token] += _disbursedReward;
    }

    function addRewards(address _token, uint256 _amount) public {
        uint256 _fees = (_amount * BASE_FEE) / FLOAT_HANDLER_TEN_4;

        require(_token != address(0), "Fetcch: Cannot be address(0)");
        require(_amount > 0, "Fetcch: amount should be greater than zero");
        require(_fees > 0, "Fetcch: fees should be greater than zero");

        unchecked {
            rewardsPool[_token] += _fees;
        }
    }

    function disburseReward(address _token) public {
        uint256 liquidity = totalLiquidity[_token];
        uint256 totalRewards = rewardsPool[_token];

        uint256 leng = lpList.length;
        for (uint256 i = 0; i < leng; ) {
            address lp = lpList[i];
            uint256 lpTokenBalance = lpBalance[lp][_token];

            uint256 position = (lpTokenBalance * 10) / liquidity;
            uint256 userReward = (position * totalRewards) / 100;

            lpRewards[lp][_token] = userReward;

            unchecked {
                i++;
            }
        }
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