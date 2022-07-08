// SPDX-License-Identifier: MIT
// Adapted from BgD Aave Payload @ https://github.com/bgd-labs/aave-ecosystem-reserve-v2/blob/master/src/PayloadAaveBGD.sol

pragma solidity 0.8.11;

import {IInitializableAdminUpgradeabilityProxy} from "src/interfaces/IInitializableAdminUpgradeabilityProxy.sol";
import {IAaveEcosystemReserveController} from "src/interfaces/IAaveEcosystemReserveController.sol";
import {IStreamable} from "src/interfaces/IStreamable.sol";
import {IAdminControlledEcosystemReserve} from "src/interfaces/IAdminControlledEcosystemReserve.sol";
import {IERC20} from "src/interfaces/IERC20.sol";

contract PayloadAaveSigP {
    IInitializableAdminUpgradeabilityProxy public constant COLLECTOR_V2_PROXY =
        IInitializableAdminUpgradeabilityProxy(
            0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c
        );

    IAaveEcosystemReserveController public constant CONTROLLER_OF_COLLECTOR =
        IAaveEcosystemReserveController(
            0x3d569673dAa0575c936c7c67c4E6AedA69CC630C
        );

    address public constant GOV_SHORT_EXECUTOR =
        0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;

    IERC20 public constant AUSDC =
        IERC20(0xBcca60bB61934080951369a648Fb03DF4F96263C);
    IERC20 public constant AUSDT =
        IERC20(0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811);

    // As per the offchain governance proposal
    // 50% upfront payment, 50% streamed with:
    // Start stream time = block.timestamp + 6 months
    // End streat time = block.timestamp + 12 months
    // (splits payment equally between aUSDC and aUSDT):


    uint256 public constant FEE = 1296000 * 1e6; // $1,296,000. Minimum engagement fee as per proposal
    uint256 public constant UPFRONT_AMOUNT = FEE / 2;// $648.000 ; // 50% of the fee

    uint256 public constant AUSDC_UPFRONT_AMOUNT = UPFRONT_AMOUNT / 2; // 324,000 aUSDC
    uint256 public constant AUSDT_UPFRONT_AMOUNT = UPFRONT_AMOUNT /2 ; // 324,000 aUSDT

    uint256 public constant AUSDC_STREAM_AMOUNT = 324010368000; // ~324,000 aUSDC. A bit more for the streaming requirements
    uint256 public constant AUSDT_STREAM_AMOUNT = 324010368000; // ~324,000 aUSDT. A bit more for the streaming requirements

    uint256 public constant STREAMS_DURATION = 180 days; // 6 months of 30 days
    uint256 public constant STREAMS_DELAY = 180 days; // 6 months of 30 days

    address public constant SIGP =
        address(0xC9a872868afA68BA937f65A1c5b4B252dAB15D85);

    function execute() external {

        // Transfer of the upfront payment, 50% of the total engagement fee, split in aUSDC and aUSDT.
        CONTROLLER_OF_COLLECTOR.transfer(
            address(COLLECTOR_V2_PROXY),
            AUSDC,
            SIGP,
            AUSDC_UPFRONT_AMOUNT
        );

        CONTROLLER_OF_COLLECTOR.transfer(
            address(COLLECTOR_V2_PROXY),
            AUSDT,
            SIGP,
            AUSDT_UPFRONT_AMOUNT
        );

        // Creation of the streams

        // aUSDC stream
        // 6 months stream, starting 6 months from now
        CONTROLLER_OF_COLLECTOR.createStream(
            address(COLLECTOR_V2_PROXY),
            SIGP,
            AUSDC_STREAM_AMOUNT,
            AUSDC,
            block.timestamp + STREAMS_DELAY,
            block.timestamp + STREAMS_DELAY + STREAMS_DURATION
        );

        // aUSDT stream
        // 6 months stream, starting 6 months from now
        CONTROLLER_OF_COLLECTOR.createStream(
            address(COLLECTOR_V2_PROXY),
            SIGP,
            AUSDT_STREAM_AMOUNT,
            AUSDT,
            block.timestamp + STREAMS_DELAY,
            block.timestamp + STREAMS_DELAY + STREAMS_DURATION
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IInitializableAdminUpgradeabilityProxy {
    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external
        payable;

    function admin() external returns (address);

    function implementation() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {IERC20} from "./IERC20.sol";

interface IAaveEcosystemReserveController {
    /**
     * @notice Proxy function for ERC20's approve(), pointing to a specific collector contract
     * @param collector The collector contract with funds (Aave ecosystem reserve)
     * @param token The asset address
     * @param recipient Allowance's recipient
     * @param amount Allowance to approve
     **/
    function approve(
        address collector,
        IERC20 token,
        address recipient,
        uint256 amount
    ) external;

    /**
     * @notice Proxy function for ERC20's transfer(), pointing to a specific collector contract
     * @param collector The collector contract with funds (Aave ecosystem reserve)
     * @param token The asset address
     * @param recipient Transfer's recipient
     * @param amount Amount to transfer
     **/
    function transfer(
        address collector,
        IERC20 token,
        address recipient,
        uint256 amount
    ) external;

    /**
     * @notice Proxy function to create a stream of token on a specific collector contract
     * @param collector The collector contract with funds (Aave ecosystem reserve)
     * @param recipient The recipient of the stream of token
     * @param deposit Total amount to be streamed
     * @param tokenAddress The ERC20 token to use as streaming asset
     * @param startTime The unix timestamp for when the stream starts
     * @param stopTime The unix timestamp for when the stream stops
     * @return uint256 The stream id created
     **/
    function createStream(
        address collector,
        address recipient,
        uint256 deposit,
        IERC20 tokenAddress,
        uint256 startTime,
        uint256 stopTime
    ) external returns (uint256);

    /**
     * @notice Proxy function to withdraw from a stream of token on a specific collector contract
     * @param collector The collector contract with funds (Aave ecosystem reserve)
     * @param streamId The id of the stream to withdraw tokens from
     * @param funds Amount to withdraw
     * @return bool If the withdrawal finished properly
     **/
    function withdrawFromStream(
        address collector,
        uint256 streamId,
        uint256 funds
    ) external returns (bool);

    /**
     * @notice Proxy function to cancel a stream of token on a specific collector contract
     * @param collector The collector contract with funds (Aave ecosystem reserve)
     * @param streamId The id of the stream to cancel
     * @return bool If the cancellation happened correctly
     **/
    function cancelStream(address collector, uint256 streamId)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IStreamable {
    struct Stream {
        uint256 deposit;
        uint256 ratePerSecond;
        uint256 remainingBalance;
        uint256 startTime;
        uint256 stopTime;
        address recipient;
        address sender;
        address tokenAddress;
        bool isEntity;
    }

    event CreateStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    );

    event WithdrawFromStream(
        uint256 indexed streamId,
        address indexed recipient,
        uint256 amount
    );

    event CancelStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 senderBalance,
        uint256 recipientBalance
    );

    function balanceOf(uint256 streamId, address who)
        external
        view
        returns (uint256 balance);

    function getStream(uint256 streamId)
        external
        view
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address token,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond
        );

    function createStream(
        address recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    ) external returns (uint256 streamId);

    function withdrawFromStream(uint256 streamId, uint256 funds)
        external
        returns (bool);

    function cancelStream(uint256 streamId) external returns (bool);

    function initialize(address fundsAdmin) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import {IERC20} from "./IERC20.sol";

interface IAdminControlledEcosystemReserve {
    /** @notice Emitted when the funds admin changes
     * @param fundsAdmin The new funds admin
     **/
    event NewFundsAdmin(address indexed fundsAdmin);

    /** @notice Returns the mock ETH reference address
     * @return address The address
     **/
    function ETH_MOCK_ADDRESS() external pure returns (address);

    /**
     * @notice Return the funds admin, only entity to be able to interact with this contract (controller of reserve)
     * @return address The address of the funds admin
     **/
    function getFundsAdmin() external view returns (address);

    /**
     * @dev Function for the funds admin to give ERC20 allowance to other parties
     * @param token The address of the token to give allowance from
     * @param recipient Allowance's recipient
     * @param amount Allowance to approve
     **/
    function approve(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external;

    /**
     * @notice Function for the funds admin to transfer ERC20 tokens to other parties
     * @param token The address of the token to transfer
     * @param recipient Transfer's recipient
     * @param amount Amount to transfer
     **/
    function transfer(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;


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