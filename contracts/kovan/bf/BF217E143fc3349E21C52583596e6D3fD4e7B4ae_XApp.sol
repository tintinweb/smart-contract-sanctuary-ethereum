// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.14;

interface IXApp {
	error NoOwner();
	error UnknownNonce();
	error RetryFailed();
	error XAppNotRegistered(uint32);

	event XAppRegistered(uint32 indexed chainDomain, address xAppContract);
	event XCallSent(
		uint32 indexed destinationDomain,
		address indexed destinationContract,
		bytes payloadWithSignature
	);
	event XCallExecuted(
		uint32 indexed originDomain,
		uint256 nonce,
		address destination,
		bytes payloadWithSignature
	);
	event FailedCallSaved(
		uint32 indexed originDomain,
		uint256 nonce,
		address destination,
		bytes payloadWithSignature
	);

	struct FailedCall {
		address to;
		bytes payloadWithSignature;
	}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.14;

import { IXApp } from "./IXApp.sol";

import { IExecutor } from "./vendor/connext/IExecutor.sol";
import { IConnextHandler } from "./vendor/connext/IConnextHandler.sol";
import { CallParams, XCallArgs, ExecuteArgs } from "./vendor/connext/LibConnextStorage.sol";
import { Ownable } from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/*
	XApp is mainly trying a catch-fail system. This will allow the user to try again the call if it fails for some reason.
	For POC purposes, we are doing permissionless call only and it's not optimized.
 */
contract XApp is IXApp, Ownable {
	IConnextHandler public immutable connext;
	uint32 public immutable domain;

	//Chain Domain -> XApp
	mapping(uint32 => address) public xCallApps;
	mapping(uint32 => uint256) public nonces;
	mapping(uint32 => mapping(uint256 => FailedCall)) public failedXCalls;

	uint256[] public failedNonce; //this is for test purposes.

	constructor(address _connext, uint32 _domain) {
		connext = IConnextHandler(_connext);
		domain = _domain;
	}

	function sendXCall(
		address _to,
		address _token,
		uint256 _tokenAmount,
		uint32 _destinationDomain,
		bool _permissionless,
		bytes calldata _payloadWithSignature
	) external {
		address xAppDestination = xCallApps[_destinationDomain];

		if (xAppDestination == address(0)) {
			revert XAppNotRegistered(_destinationDomain);
		}

		bytes memory callData = abi.encodeWithSelector(
			XApp.xCallReceived.selector,
			_to,
			_destinationDomain,
			_payloadWithSignature
		);

		CallParams memory callParams = CallParams({
			to: xAppDestination,
			callData: callData,
			originDomain: domain,
			destinationDomain: _destinationDomain,
			recovery: xAppDestination,
			callback: address(this),
			callbackFee: 0,
			forceSlow: !_permissionless,
			receiveLocal: false
		});

		XCallArgs memory xcallArgs = XCallArgs({
			params: callParams,
			transactingAssetId: _token,
			amount: _tokenAmount,
			relayerFee: 0
		});

		connext.xcall(xcallArgs);
		emit XCallSent(_destinationDomain, _to, _payloadWithSignature);
	}

	function xCallReceived(
		address _to,
		uint32 _domain,
		bytes calldata _payloadWithSignature
	) external {
		uint256 nonce = nonces[_domain];
		nonces[_domain]++;

		(bool success, ) = _to.call(_payloadWithSignature);

		if (success) {
			emit XCallExecuted(_domain, nonce, _to, _payloadWithSignature);
			return;
		}

		failedXCalls[_domain][nonce] = FailedCall(_to, _payloadWithSignature);

		failedNonce.push(nonce);
		emit FailedCallSaved(_domain, nonce, _to, _payloadWithSignature);
	}

	function retryFailedCall(uint32 _chainDomain, uint256 _nonce) external {
		FailedCall memory failedCallData = failedXCalls[_chainDomain][_nonce];

		if (failedCallData.to == address(0)) revert UnknownNonce();

		(bool success, ) = failedCallData.to.call(
			failedCallData.payloadWithSignature
		);

		if (!success) revert RetryFailed();

		delete failedXCalls[_chainDomain][_nonce];
	}

	function deleteFailedCall(uint32 _chainDomain, uint256 _nonce)
		external
		onlyOwner
	{
		delete failedXCalls[_chainDomain][_nonce];
	}

	function registerNewXApp(uint32 _chainDomain, address _xAppAddress)
		external
		onlyOwner
	{
		xCallApps[_chainDomain] = _xAppAddress;

		emit XAppRegistered(_chainDomain, _xAppAddress);
	}

	function getXAppAddressOf(uint32 _chainDomain)
		external
		view
		returns (address)
	{
		return xCallApps[_chainDomain];
	}

	function getFailedCallDataOf(uint32 _chainDomain, uint256 _nonce)
		external
		view
		returns (FailedCall memory)
	{
		return failedXCalls[_chainDomain][_nonce];
	}

	function getLastFailedNonce() external view returns (uint256) {
		return failedNonce[failedNonce.length - 1];
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import {IExecutor} from "./IExecutor.sol";
import { CallParams, XCallArgs, ExecuteArgs } from "./LibConnextStorage.sol";

interface IConnextHandler {
  // BridgeFacet
  function relayerFees(bytes32 _transferId) external view returns (uint256);

  function routedTransfers(bytes32 _transferId) external view returns (address[] memory);

  function domain() external view returns (uint256);

  function executor() external view returns (IExecutor);

  function nonce() external view returns (uint256);

  function xcall(XCallArgs calldata _args) external payable returns (bytes32);

  function handle(
    uint32 _origin,
    uint32 _nonce,
    bytes32 _sender,
    bytes memory _message
  ) external;

  function execute(ExecuteArgs calldata _args) external returns (bytes32 transferId);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

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
 * @param recovery - The address to send funds to if your `Executor.execute call` fails
 * @param callback - The address on the origin domain of the callback contract
 * @param callbackFee - The relayer fee to execute the callback
 * @param forceSlow - If true, will take slow liquidity path even if it is not a permissioned call
 * @param receiveLocal - If true, will use the local nomad asset on the destination instead of adopted.
 */
struct CallParams {
  address to;
  bytes callData;
  uint32 originDomain;
  uint32 destinationDomain;
  address recovery;
  address callback;
  uint256 callbackFee;
  bool forceSlow;
  bool receiveLocal;
}

/**
 * @notice The arguments you supply to the `xcall` function called by user on origin domain
 * @param params - The CallParams. These are consistent across sending and receiving chains
 * @param transactingAssetId - The asset the caller sent with the transfer. Can be the adopted, canonical,
 * or the representational asset
 * @param amount - The amount of transferring asset the tx called xcall with
 * @param relayerFee - The amount of relayer fee the tx called xcall with
 */
struct XCallArgs {
  CallParams params;
  address transactingAssetId; // Could be adopted, local, or wrapped
  uint256 amount;
  uint256 relayerFee;
}

/**
 * @notice
 * @param params - The CallParams. These are consistent across sending and receiving chains
 * @param local - The local asset for the transfer, will be swapped to the adopted asset if
 * appropriate
 * @param routers - The routers who you are sending the funds on behalf of
 * @param amount - The amount of liquidity the router provided or the bridge forwarded, depending on
 * if fast liquidity was used
 * @param relayerFee - The relayer fee amount
 * @param nonce - The nonce used to generate transfer id
 * @param originSender - The msg.sender of the xcall on origin domain
 */
struct ExecuteArgs {
  CallParams params;
  address local; // local representation of canonical token
  address[] routers;
  bytes[] routerSignatures;
  uint256 relayerFee;
  uint256 amount;
  uint256 nonce;
  address originSender;
}

/**
 * @notice Contains RouterFacet related state
 * @param approvedRouters - Mapping of whitelisted router addresses
 * @param routerRecipients - Mapping of router withdraw recipient addresses.
 * If set, all liquidity is withdrawn only to this address. Must be set by routerOwner
 * (if configured) or the router itself
 * @param routerOwners - Mapping of router owners
 * If set, can update the routerRecipient
 * @param proposedRouterOwners - Mapping of proposed router owners
 * Must wait timeout to set the
 * @param proposedRouterTimestamp - Mapping of proposed router owners timestamps
 * When accepting a proposed owner, must wait for delay to elapse
 */
struct RouterPermissionsManagerInfo {
  mapping(address => bool) approvedRouters;
  mapping(address => bool) approvedForPortalRouters;
  mapping(address => address) routerRecipients;
  mapping(address => address) routerOwners;
  mapping(address => address) proposedRouterOwners;
  mapping(address => uint256) proposedRouterTimestamp;
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

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.14;

import { Ownable } from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/*
This is were we test the retry mechanism.


What I won't test:
- Callback 
    Callbacks are a bad design for E2E, mainly in web3.

- Permission's calls 
    Permissioned vs permisionless calls. There's no point of testing both in a PoC, the end result is the same.            

- recovery
    No need to test it.
*/

contract Target is Ownable {
	error NotAllowed();

	mapping(address => bool) public isAllowed;

	uint256 public uselessValue;

	function changeUselessValue(uint256 _value) external {
		uselessValue = _value;
	}

	function updateUselessValue(address _from, uint256 _uselessValue)
		external
	{
		if (!isAllowed[_from]) revert NotAllowed();
		uselessValue = _uselessValue;
	}

	function allowUserToXCall(address _user, bool _status) external {
		isAllowed[_user] = _status;
	}
}