// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

import "../interfaces/connext/IConnext.sol";
import "./PingMe.sol";

contract PingMeInitiator {
    address constant PINGME_ADDR = 0xd41D09D455E9BD2cFa7FD42c235b933EF7604dD9;

    IConnext public connext;
    address public promiseRouter;
    address public testToken;

    constructor(
        IConnext connext_,
        address promiseRouter_,
        address testToken_
    ) {
        connext = connext_;
        promiseRouter = promiseRouter_;
        testToken = testToken_;
    }

    function initiatePing(
        string memory msg_,
        uint32 destDomain
    ) public {
        bytes memory callData = abi.encodeWithSelector(
            IPingMe.justPing.selector,
            msg_
        );

        uint32 originDomain = uint32(connext.domain());

        IConnext.CallParams memory callParams = IConnext.CallParams({
            to: PINGME_ADDR,
            callData: callData,
            originDomain: originDomain,
            destinationDomain: destDomain,
            agent: PINGME_ADDR, // address allowed to transaction on destination side in addition to relayers
            recovery: PINGME_ADDR, // fallback address to send funds to if execution fails on destination side
            forceSlow: false, // option to force Nomad slow path (~30 mins) instead of paying 0.05% fee
            receiveLocal: false, // option to receive the local Nomad-flavored asset instead of the adopted asset
            callback: address(0), // this contract implements the callback
            callbackFee: 0, // fee paid to relayers; relayers don't take any fees on testnet
            relayerFee: 0, // fee paid to relayers; relayers don't take any fees on testnet
            slippageTol: 9995 // tolerate .05% slippage
        });

        IConnext.XCallArgs memory xcallArgs = IConnext.XCallArgs({
            params: callParams,
            transactingAssetId: testToken,
            amount: 0
        });

        connext.xcall(xcallArgs);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

import "./IExecutor.sol";

/**
 * @title IConnextHandler interface stripped down version.
 * @author fujidao Labs
 */
interface IConnext {
  // ============= Structs =============

  /**
  * @notice These are the call parameters that will remain constant between the
  * two chains. They are supplied on `xcall` and should be asserted on `execute`
  * @property to - The account that receives funds, in the event of a crosschain call,
  * will receive funds if the call fails.
  * @param to - The address you are sending funds (and potentially data) to
  * @param callData - The data to execute on the receiving chain. If no crosschain call is needed, then leave empty.
  * @param originDomain - The originating domain (i.e. where `xcall` is called). Must match nomad domain schema
  * @param destinationDomain - The final domain (i.e. where `execute` / `reconcile` are called). Must match nomad domain schema
  * @param agent - An address who can execute txs on behalf of `to`, in addition to allowing relayers
  * @param recovery - The address to send funds to if your `Executor.execute call` fails
  * @param callback - The address on the origin domain of the callback contract
  * @param callbackFee - The relayer fee to execute the callback
  * @param forceSlow - If true, will take slow liquidity path even if it is not a permissioned call
  * @param receiveLocal - If true, will use the local nomad asset on the destination instead of adopted.
  * @param relayerFee - The amount of relayer fee the tx called xcall with
  * @param slippageTol - Max bps of original due to slippage (i.e. would be 9995 to tolerate .05% slippage)
  */
  struct CallParams {
    address to;
    bytes callData;
    uint32 originDomain;
    uint32 destinationDomain;
    address agent;
    address recovery;
    bool forceSlow;
    bool receiveLocal;
    address callback;
    uint256 callbackFee;
    uint256 relayerFee;
    uint256 slippageTol;
  }

  /**
  * @notice The arguments you supply to the `xcall` function called by user on origin domain
  * @param params - The CallParams. These are consistent across sending and receiving chains
  * @param transactingAssetId - The asset the caller sent with the transfer. Can be the adopted, canonical,
  * or the representational asset
  * @param amount - The amount of transferring asset the tx called xcall with
  */
  struct XCallArgs {
    CallParams params;
    address transactingAssetId; // Could be adopted, local, or wrapped
    uint256 amount;
  }

  function domain() external view returns (uint256);

  function xcall(XCallArgs calldata _args) external payable returns (bytes32);

  function executor() external view returns (IExecutor);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

import "../interfaces/connext/IConnext.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IPingMe {

  event IWasPinged(address indexed caller, uint256 totalPings, string message);

  function justPing(string memory msg_) external;

  function pingAndPingBack(string memory msg_, address pingReceiver_, uint32 destDomain) external;
}

contract PingMe is IPingMe {
    IConnext public connext;
    address public promiseRouter;
    address public testToken;

    // Testnet only: ping to check Connext bridge working.
    uint256 public totalPings;

    constructor(IConnext connext_, address promiseRouter_, address testToken_) {
        connext = connext_;
        promiseRouter = promiseRouter_;
        testToken = testToken_;
    }

    // Testnet only: ping to check Connext bridge working.
    function justPing(string memory msg_) public override {
        totalPings++;
        emit IWasPinged(msg.sender, totalPings, msg_);
    }

    function pingAndPingBack(string memory msg_, address pingReceiver_, uint32 destDomain) public override {
        justPing(msg_);

        string memory newMsg = "I am pinging back";

        bytes memory callData = abi.encodeWithSelector(
            IPingMe.justPing.selector,
            newMsg
        );

        uint32 originDomain = uint32(connext.domain());

        IConnext.CallParams memory callParams = IConnext.CallParams({
            to: pingReceiver_,
            callData: callData,
            originDomain: originDomain,
            destinationDomain: destDomain,
            agent: pingReceiver_, // address allowed to transaction on destination side in addition to relayers
            recovery: pingReceiver_, // fallback address to send funds to if execution fails on destination side
            forceSlow: true, // option to force Nomad slow path (~30 mins) instead of paying 0.05% fee
            receiveLocal: false, // option to receive the local Nomad-flavored asset instead of the adopted asset
            callback: address(0), // this contract implements the callback
            callbackFee: 0, // fee paid to relayers; relayers don't take any fees on testnet
            relayerFee: 0, // fee paid to relayers; relayers don't take any fees on testnet
            slippageTol: 9995 // tolerate .05% slippage
        });

        IConnext.XCallArgs memory xcallArgs = IConnext.XCallArgs({
            params: callParams,
            transactingAssetId: testToken,
            amount: 0
        });

        connext.xcall(xcallArgs);
    }

    function pushTokensOut(address token_) public {
      IERC20 token = IERC20(token_);
      uint bal = token.balanceOf(address(this));
      token.transfer(msg.sender, bal);
    }

    function setConnextHandler(address addr_) external {
        connext = IConnext(addr_);
    }

    function setPromiseRouter(address addr_) external {
        promiseRouter = addr_;
    }

    function setTestToken(address addr_) external {
        testToken = addr_;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IExecutor {
  /**
   * @param _transferId Unique identifier of transaction id that necessitated
   * calldata execution
   * @param _amount The amount to approve or send with the call
   * @param _to The address to execute the calldata on
   * @param _assetId The assetId of the funds to approve to the contract or
   * send along with the call
   * @param _properties The origin properties
   * @param _callData The data to execute
   */
  struct ExecutorArgs {
    bytes32 transferId;
    uint256 amount;
    address to;
    address recovery;
    address assetId;
    bytes properties;
    bytes callData;
  }

  event Executed(
    bytes32 indexed transferId,
    address indexed to,
    address indexed recovery,
    address assetId,
    uint256 amount,
    bytes _properties,
    bytes callData,
    bytes returnData,
    bool success
  );

  function getConnext() external returns (address);

  function originSender() external returns (address);

  function origin() external returns (uint32);

  function amount() external returns (uint256);

  function execute(ExecutorArgs calldata _args) external payable returns (bool success, bytes memory returnData);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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