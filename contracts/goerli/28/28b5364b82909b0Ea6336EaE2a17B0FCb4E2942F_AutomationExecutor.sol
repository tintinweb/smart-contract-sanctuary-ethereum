//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { BotLike } from "./interfaces/BotLike.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { IExchange } from "./interfaces/IExchange.sol";

contract AutomationExecutor {
    BotLike public immutable bot;

    address public exchange;
    address public owner;

    mapping(address => bool) public callers;

    constructor(BotLike _bot, address _exchange) {
        bot = _bot;
        exchange = _exchange;
        owner = msg.sender;
        callers[owner] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "executor/only-owner");
        _;
    }

    modifier auth(address caller) {
        require(callers[caller], "executor/not-authorized");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function setExchange(address newExchange) external onlyOwner {
        exchange = newExchange;
    }

    function addCaller(address caller) external onlyOwner {
        callers[caller] = true;
    }

    function removeCaller(address caller) external onlyOwner {
        require(caller != msg.sender, "executor/cannot-remove-owner");
        callers[caller] = false;
    }

    function execute(
        bytes calldata executionData,
        uint256 cdpId,
        bytes calldata triggerData,
        address commandAddress,
        uint256 triggerId,
        uint256 txCostsDaiCoverage
    ) external auth(msg.sender) {
        bot.execute(
            executionData,
            cdpId,
            triggerData,
            commandAddress,
            triggerId,
            txCostsDaiCoverage
        );
    }

    function swapTokenForDai(
        address asset,
        uint256 amount,
        uint256 receiveAtLeast,
        address callee,
        bytes calldata withData
    ) external auth(msg.sender) {
        // amount has to be strictly less than the balance save at least 1 wei at the storage slot to save gas
        require(
            amount > 0 && amount < IERC20(asset).balanceOf(address(this)),
            "executor/invalid-amount"
        );

        uint256 allowance = IERC20(asset).allowance(address(this), exchange);
        if (amount > allowance) {
            require(IERC20(asset).approve(exchange, type(uint256).max), "executor/approval-failed");
        }
        IExchange(exchange).swapTokenForDai(asset, amount, receiveAtLeast, callee, withData);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface BotLike {
    function addRecord(
        uint256 cdpId,
        uint256 triggerType,
        uint256 replacedTriggerId,
        bytes memory triggerData
    ) external;

    function removeRecord(
        // This function should be executed allways in a context of AutomationBot address not DsProxy,
        //msg.sender should be dsProxy
        uint256 cdpId,
        uint256 triggerId
    ) external;

    function execute(
        bytes calldata executionData,
        uint256 cdpId,
        bytes calldata triggerData,
        address commandAddress,
        uint256 triggerId,
        uint256 txCostsDaiCoverage
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

interface IExchange {
    function swapTokenForDai(
        address asset,
        uint256 amount,
        uint256 receiveAtLeast,
        address callee,
        bytes calldata withData
    ) external;

    function swapDaiForToken(
        address asset,
        uint256 amount,
        uint256 receiveAtLeast,
        address callee,
        bytes calldata withData
    ) external;
}