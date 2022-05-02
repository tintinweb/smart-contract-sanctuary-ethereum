/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

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
interface IInitializableAdminUpgradeabilityProxy {
    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external
        payable;

    function admin() external returns (address);

    function implementation() external returns (address);
}
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


contract PayloadAaveBGD {
    IInitializableAdminUpgradeabilityProxy public constant COLLECTOR_V2_PROXY =
        IInitializableAdminUpgradeabilityProxy(
            0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c
        );

    IInitializableAdminUpgradeabilityProxy
        public constant AAVE_TOKEN_COLLECTOR_PROXY =
        IInitializableAdminUpgradeabilityProxy(
            0x25F2226B597E8F9514B3F68F00f494cF4f286491
        );

    address public constant GOV_SHORT_EXECUTOR =
        0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;

    IAaveEcosystemReserveController public constant CONTROLLER_OF_COLLECTOR =
        IAaveEcosystemReserveController(
            0x3d569673dAa0575c936c7c67c4E6AedA69CC630C
        );

    IStreamable public constant ECOSYSTEM_RESERVE_V2_IMPL =
        IStreamable(0x1aa435ed226014407Fa6b889e9d06c02B1a12AF3);

    IERC20 public constant AUSDC =
        IERC20(0xBcca60bB61934080951369a648Fb03DF4F96263C);
    IERC20 public constant ADAI =
        IERC20(0x028171bCA77440897B824Ca71D1c56caC55b68A3);
    IERC20 public constant AUSDT =
        IERC20(0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811);
    IERC20 public constant AAVE =
        IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);

    uint256 public constant AUSDC_UPFRONT_AMOUNT = 1200000 * 1e6; // 1'200'000 aUSDC
    uint256 public constant ADAI_UPFRONT_AMOUNT = 1000000 ether; // 1'000'000 aDAI
    uint256 public constant AUSDT_UPFRONT_AMOUNT = 1000000 * 1e6; // 1'000'000 aUSDT
    uint256 public constant AAVE_UPFRONT_AMOUNT = 8400 ether; // 8'400 AAVE

    uint256 public constant AUSDC_STREAM_AMOUNT = 4800008160000; // ~4'800'000 aUSDC. A bit more for the streaming requirements
    uint256 public constant AAVE_STREAM_AMOUNT = 12600000000000074880000; // ~12'600 AAVE. A bit more for the streaming requirements
    uint256 public constant STREAMS_DURATION = 450 days; // 15 months of 30 days

    address public constant BGD_RECIPIENT =
        0xb812d0944f8F581DfAA3a93Dda0d22EcEf51A9CF;

    function execute() external {
        // Upgrade of both treasuries' implementation
        // We use a common implementation for both ecosystem's reserves
        COLLECTOR_V2_PROXY.upgradeToAndCall(
            address(ECOSYSTEM_RESERVE_V2_IMPL),
            abi.encodeWithSelector(
                IStreamable.initialize.selector,
                address(CONTROLLER_OF_COLLECTOR)
            )
        );
        AAVE_TOKEN_COLLECTOR_PROXY.upgradeToAndCall(
            address(ECOSYSTEM_RESERVE_V2_IMPL),
            abi.encodeWithSelector(
                IStreamable.initialize.selector,
                address(CONTROLLER_OF_COLLECTOR)
            )
        );
        // We initialise the implementation, for security
        ECOSYSTEM_RESERVE_V2_IMPL.initialize(address(CONTROLLER_OF_COLLECTOR));

        // Transfer of the upfront payment, 40% of the total
        CONTROLLER_OF_COLLECTOR.transfer(
            address(COLLECTOR_V2_PROXY),
            AUSDC,
            BGD_RECIPIENT,
            AUSDC_UPFRONT_AMOUNT
        );
        CONTROLLER_OF_COLLECTOR.transfer(
            address(COLLECTOR_V2_PROXY),
            ADAI,
            BGD_RECIPIENT,
            ADAI_UPFRONT_AMOUNT
        );
        CONTROLLER_OF_COLLECTOR.transfer(
            address(COLLECTOR_V2_PROXY),
            AUSDT,
            BGD_RECIPIENT,
            AUSDT_UPFRONT_AMOUNT
        );
        CONTROLLER_OF_COLLECTOR.transfer(
            address(AAVE_TOKEN_COLLECTOR_PROXY),
            AAVE,
            BGD_RECIPIENT,
            AAVE_UPFRONT_AMOUNT
        );

        // Creation of the streams
        CONTROLLER_OF_COLLECTOR.createStream(
            address(COLLECTOR_V2_PROXY),
            BGD_RECIPIENT,
            AUSDC_STREAM_AMOUNT,
            AUSDC,
            block.timestamp,
            block.timestamp + STREAMS_DURATION
        );
        CONTROLLER_OF_COLLECTOR.createStream(
            address(AAVE_TOKEN_COLLECTOR_PROXY),
            BGD_RECIPIENT,
            AAVE_STREAM_AMOUNT,
            AAVE,
            block.timestamp,
            block.timestamp + STREAMS_DURATION
        );
    }
}