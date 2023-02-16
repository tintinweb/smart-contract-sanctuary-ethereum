// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.17;

import "./utils/Context.sol";

import "./interfaces/IControl.sol";

contract ControlResolver is Context {

    /* ========== STATE VARIABLES ========== */

    // TODO replace
    uint256 private constant FOUR_HOUR_TIME = 14400;
    uint256 private constant FIVE_MINUTES_TIME = 300;
    // uint256 private constant FOUR_HOUR_TIME = 14400;
    // uint256 private constant FIVE_MINUTES_TIME = 300;

    IControl public control;

    address private _initializer;
    bool private _isInitialized;

    /* ========== CONSTRUCTOR ========== */

    constructor() {
        _initializer = _msgSender();
    }

    /* ========== INITIALIZE ========== */

    function initialize(address control_) external {
        require(_msgSender() == _initializer, "ControlResolver: caller is not the initializer");
        // TODO uncomment
        // require(!_isInitialized, "ControlResolver: already initialized");

        require(control_ != address(0), "ControlResolver: invalid control address");
        control = IControl(control_);

        _isInitialized = true;
    }

    /* ========== FUNCTIONS ========== */

    function checker() external view returns (bool canExec, bytes memory execPayload) {
        uint256 mintProgressCount = control.mintProgressCount();
        uint256 redeemProgressCount = control.redeemProgressCount();
        uint256 lastExecutedMint = control.lastExecutedMint();
        uint256 lastExecutedRedeem = control.lastExecutedRedeem();

        uint256 price = control.getCurrentPrice();

        bool canMint = price > control.PRICE_UPPER_BOUND() && block.timestamp > lastExecutedMint + FOUR_HOUR_TIME;
        bool canMintForProgression = mintProgressCount > 0.1 * 1e18 && block.timestamp > lastExecutedMint + FIVE_MINUTES_TIME;
        bool canRedeem = price < control.PRICE_LOWER_BOUND() && block.timestamp > lastExecutedRedeem + FOUR_HOUR_TIME;
        bool canRedeemForProgression = redeemProgressCount > 0.1 * 1e18 && block.timestamp > lastExecutedRedeem + FIVE_MINUTES_TIME;

        if (canMint || canMintForProgression) {
            execPayload = abi.encodeCall(IControl.execute, (0));
            return (true, execPayload);
        }
        else if (canRedeem || canRedeemForProgression) {
            execPayload = abi.encodeCall(IControl.execute, (1));
            return (true, execPayload);
        }

        // canExec = false;
        execPayload = abi.encodePacked(
            "Price: ",
            price,
            ", Mint's Last Execution Time: ",
            lastExecutedMint,
            ", Mint's Progress Count: ",
            mintProgressCount,
            ", Redeem's Last Execution Time: ",
            lastExecutedRedeem,
            ", Redeem's Progress Count: ",
            redeemProgressCount
        );
    }
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.17;

interface IControl {

    function PRICE_UPPER_BOUND() external view returns (uint256);

    function PRICE_LOWER_BOUND() external view returns (uint256);

    function mintProgressCount() external view returns (uint256);

    function redeemProgressCount() external view returns (uint256);

    function lastExecutedMint() external view returns (uint256);

    function lastExecutedRedeem() external view returns (uint256);

    function delegateApprove(address token, address guy, bool isApproved) external;

    function getDailyInitialMints() external view returns (uint256 startTime, uint256 endTime, uint256 amountUSD);

    function getInitialMints() external view returns (uint256 startTime, uint256 endTime, uint256 amountUSD);

    function initialMint() external payable;

    function getCurrentPrice() external view returns (uint256);

    function execute(uint8 argument) external;
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