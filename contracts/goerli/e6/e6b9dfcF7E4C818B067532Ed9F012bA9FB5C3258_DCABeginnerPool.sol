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

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IERC20.sol";
import "./DCAPoolCore.sol";

contract DCABeginnerPool is DCAPoolCore {

    constructor(address _dcaOrderSystem, address _cdcaToken) {
        dcaOrderSystem = _dcaOrderSystem;
        cdcaToken = _cdcaToken;
    }

    function swapToken(
        address _planner,
        address _stableToken,
        address _dcaToken,
        uint256 _stableTokenAmount
    ) external onlyOrderSystem {
        address[] memory path = new address[](2);
        path[0] = _stableToken;
        path[1] = _dcaToken;

        uint256 deadline = block.timestamp + 30;

        IUniswapV2Router02(SpookySwapRouter).swapExactTokensForTokens(
            (_stableTokenAmount * (100 - feePercent)) / 100,
            0,
            path,
            _planner,
            deadline
        );
        feeAmountPerToken[_stableToken] += _stableTokenAmount * feePercent;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IERC20.sol";

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IDCAOrderSystem {
    function readWeeklyGoodDCAPilots()
        external
        view
        returns (address[] memory, uint256);

    function resetWeeklyScore() external;
}

contract DCAPoolCore is Ownable {
    address public SpookySwapRouter =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address public dcaOrderSystem;
    address public cdcaToken;

    uint8 public constant feePercent = 2;
    uint256 public lockedAmountForSharing; //locked tokens of bad pilots to be shared with good pilots
    mapping(address => uint256) public feeAmountPerToken; //2% fee amount of stable coins for system

    modifier onlyOrderSystem() {
        require(
            msg.sender == dcaOrderSystem,
            "Only Order System can call this function!"
        );
        _;
    }

    ///@notice transfer reward to pilot & planner per each task
    function rewardPilotAndPlanner(
        address _pilot,
        address _planner,
        uint256 _tokenAmount
    ) external onlyOrderSystem {
        IERC20(cdcaToken).transfer(_pilot, _tokenAmount);
        IERC20(cdcaToken).transfer(_planner, _tokenAmount);
    }

    ///@notice refund token to planner when he/she cancels his order
    function refundTokenForCanceledOrder(
        address _planner,
        address _tokenAddress,
        uint256 _tokenAmount
    ) external onlyOrderSystem {
        IERC20(_tokenAddress).transfer(_planner, _tokenAmount);
    }

    ///@notice lock bad pilot's credit cdca when he misses a task
    function lockPilotCredit(uint256 _tokenAmount) external onlyOrderSystem {
        lockedAmountForSharing += _tokenAmount;
    }

    ///@notice share locked cdca to pilots
    function shareLockedCDCAToPilots() external onlyOwner {
        (address[] memory pilots, uint256 number) = IDCAOrderSystem(
            dcaOrderSystem
        ).readWeeklyGoodDCAPilots();
        require(number > 0, "No pilots to share the reward!");

        uint256 shareAmount = lockedAmountForSharing / number;

        for (uint256 i; i < number; i++) {
            IERC20(cdcaToken).transfer(pilots[i], shareAmount);
        }

        assert(lockedAmountForSharing == 0);

        IDCAOrderSystem(dcaOrderSystem).resetWeeklyScore();
    }

    ///@notice withdraw system fee
    function withdrawFeeToken(address _receiver, address _token)
        external
        onlyOwner
    {
        require(feeAmountPerToken[_token] > 0, "Nothing to withdraw!");
        IERC20(_token).transfer(_receiver, feeAmountPerToken[_token]);
    }

    ///@notice withdraw whole balance of token against emergency
    function withdrawERC20Tokens(address _receiver, address _token)
        external
        onlyOwner
    {
        IERC20(_token).transfer(
            _receiver,
            IERC20(_token).balanceOf(address(this))
        );
    }

    ///@notice cdca balance for reward system
    function getCurrentRewardCDCABalance() external view returns (uint256) {
        return
            IERC20(cdcaToken).balanceOf(address(this)) - lockedAmountForSharing;
    }

    function setDCAOrderSystem(address _dcaOrderSystem) external onlyOwner {
        dcaOrderSystem = _dcaOrderSystem;
    }

    function setCDCAToken(address _cdcaToken) external onlyOwner {
        cdcaToken = _cdcaToken;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns(uint8);
}