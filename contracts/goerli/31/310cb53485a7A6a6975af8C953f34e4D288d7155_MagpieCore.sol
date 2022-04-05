// SPDX-License-Identifier: Unlicense
// MagpieCore 0.1.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IMagpieCore.sol";
import "./interfaces/IMagpieRouter.sol";
import "./interfaces/IWormhole.sol";
import "./interfaces/IWormholeCore.sol";
import "./lib/LibAsset.sol";
import "./lib/LibBytes.sol";
import "./lib/LibSwap.sol";
import "./lib/LibUint256Array.sol";
import "./lib/LibAddressArray.sol";
import "./interfaces/IMagpiePool.sol";

contract MagpieCore is ReentrancyGuard, Ownable, IMagpieCore {
  using LibAsset for address;
  using LibBytes for bytes;
  using LibSwap for IMagpieRouter.SwapArgs;
  using LibUint256Array for uint256[];
  using LibAddressArray for address[];

  mapping(uint64 => bool) private sequences;

  Config public config;

  constructor(Config memory _config) {
    config = _config;
  }

  function updateConfig(Config calldata _config) external onlyOwner {
    require(_config.weth != address(0), 'MagpieCore: invalid weth');
    require(_config.routerAddress != address(0), 'MagpieCore: invalid routerAddress');
    require(_config.coreBridgeAddress != address(0), 'MagpieCore: invalid coreBridgeAddress');
    require(_config.consistencyLevel > 1, 'MagpieCore: invalid consistencyLevel');
    require(_config.liquidityPoolAddress != address(0), 'MagpieCore: invalid liquidityPoolAddress');

    config = _config;
    
    emit ConfigUpdated(config, msg.sender);
  }

  function _swap(IMagpieRouter.SwapArgs memory swapArgs, bool transferFromSender) internal returns(uint256[] memory amountOuts) {
    address fromAssetId = swapArgs.getFromAssetId();
    address toAssetId = swapArgs.getToAssetId();
    address payable to = swapArgs.to;
    uint256 amountIn = swapArgs.getAmountIn();
    
    if (fromAssetId.isNative()) {
      IWETH(config.weth).deposit{value: amountIn}();
    }

    if (transferFromSender) {
      fromAssetId.transferFrom(msg.sender, address(this), amountIn);
    }

    fromAssetId.increaseAllowance(config.routerAddress, amountIn);
    swapArgs = swapArgs.prepare(config.weth);
    swapArgs.to = payable(address(this));
    amountOuts = IMagpieRouter(config.routerAddress).swap(swapArgs);

    uint256 amountOut = amountOuts.sum();
    require(swapArgs.getToAssetId().getBalance() >= amountOut, 'MagpieCore: invalid amountOut');

    swapArgs.to = to;

    if (toAssetId.isNative()) {
      IWETH(config.weth).withdraw(amountOut);
    }

    if (to != address(this)) {
      toAssetId.transfer(to, amountOut);
    }
  }

  function swap(IMagpieRouter.SwapArgs calldata swapArgs) external payable returns(uint256[] memory amountOuts) {
    amountOuts = _swap(swapArgs, true);

    emit Swapped(swapArgs, amountOuts, msg.sender);
  }

  function swapIn(SwapInArgs calldata args) external payable override returns(uint256[] memory amountOuts, uint64) {
    require(args.swapArgs.to == address(this), 'MagpieCore: invalid swapArgs to');
    address toAssetId = args.swapArgs.getToAssetId();
    require(config.intermediaries.includes(toAssetId) == true, 'MagpieCore: invalid intermediary');
    uint32 nonceValue = uint32(block.timestamp % 2**32);
    amountOuts = _swap(args.swapArgs, true);
    uint256 amountOut = amountOuts.sum();
    address recipient = address(uint160(uint256(args.payload.recipientId)));
    toAssetId.increaseAllowance(config.liquidityPoolAddress, amountOut);
    IMagpiePool(config.liquidityPoolAddress).depositErc20(args.payload.recipientChainId, 
                                                              toAssetId, 
                                                              recipient, 
                                                              amountOuts[amountOuts.length-1]);

    bytes memory payload = abi.encodePacked(
      args.payload.fromAssetId,
      args.payload.toAssetId,
      args.payload.to,
      args.payload.recipientId,
      args.payload.recipientChainId,
      args.payload.amountOutMin
    );

    uint64 coreSequence = IWormholeCore(config.coreBridgeAddress).publishMessage(
      nonceValue,
      payload,
      config.consistencyLevel
    );

    emit SwappedIn(args, amountOuts, coreSequence, msg.sender);

    return (amountOuts, coreSequence);
  }

  function swapOut(SwapOutArgs calldata args, uint256 tokenGasPrice) external returns(uint256[] memory amountOuts) {

    (IWormholeCore.VM memory vm, bool valid, string memory reason) = IWormholeCore(config.coreBridgeAddress).parseAndVerifyVM(args.encodedVmCore);

    require(valid == true, 'MagpieCore: invalid vaa');
    require(sequences[vm.sequence] != true, 'MagpieCore: already used sequence');

    sequences[vm.sequence] = true;

    IMagpieCore.ValidationOutPayload memory payload = vm.payload.parse();

    address fromAssetId = args.swapArgs.getFromAssetId();
    address toAssetId = args.swapArgs.getToAssetId();
    uint256 amountIn = args.swapArgs.getAmountIn();

    require(config.intermediaries.includes(fromAssetId) == true, 'MagpieCore: invalid intermediary');
    require(payload.fromAssetId == fromAssetId, 'MagpieCore: invalid fromAssetId');
    require(payload.toAssetId == toAssetId, 'MagpieCore: invalid toAssetId');
    require(payload.to == args.swapArgs.to, 'MagpieCore: invalid to');
    require(payload.recipientId == address(this), 'MagpieCore: invalid recipientId');
    require(uint256(payload.recipientChainId) == block.chainid, 'MagpieCore: invalid recipientChainId');
    require(args.swapArgs.amountOutMin >= payload.amountOutMin, 'MagpieCore: invalid amountOutMin');

    fromAssetId.increaseAllowance(config.routerAddress, amountIn);
    IMagpiePool(config.liquidityPoolAddress).sendFundsToUser(payload.toAssetId, payload.amountOutMin, payload.to, tokenGasPrice, payload.recipientChainId);

    amountOuts = _swap(args.swapArgs, false);

    emit SwappedOut(args, amountOuts, msg.sender);
    
  }

}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "./IMagpieRouter.sol";

interface IMagpieCore {

  struct Config {
    address weth;
    address routerAddress;
    address liquidityPoolAddress;
    address coreBridgeAddress;
    address[] intermediaries;
    uint8 consistencyLevel;
  }
  
  struct ValidationInPayload {
    bytes32 fromAssetId;
    bytes32 toAssetId;
    bytes32 to;
    bytes32 recipientId;
    uint256 recipientChainId;
    // TODO: Remove
    uint16 recipientBridgeChainId;
    uint256 amountOutMin;
  }

  struct ValidationOutPayload {
    address fromAssetId;
    address toAssetId;
    address to;
    address recipientId;
    uint256 recipientChainId;
    uint256 amountOutMin;
  }

  struct SwapInArgs{
    IMagpieRouter.SwapArgs swapArgs;
    ValidationInPayload payload;
  }

  struct SwapOutArgs{
    IMagpieRouter.SwapArgs swapArgs;
    bytes encodedVmCore;
    bytes encodedVmBridge;
  }

  function swap(
    IMagpieRouter.SwapArgs calldata args
  ) external payable returns(uint256[] memory amountOuts);

  function swapIn(
    SwapInArgs calldata args
  ) external payable returns(uint256[] memory amountOuts, uint64);

  function swapOut(
    SwapOutArgs calldata args,
    uint256 tokenGasPrice
  ) external returns(uint256[] memory amountOuts);

  event ConfigUpdated(
    Config config, 
    address caller
  );

  event Swapped(
    IMagpieRouter.SwapArgs args, 
    uint256[] amountOuts,
    address caller
  );

  event SwappedIn(
    SwapInArgs args, 
    uint256[] amountOuts,
    uint64 coreSequence, 
    address caller
  );

  event SwappedOut(
    SwapOutArgs args, 
    uint256[] amountOuts,
    address caller
  );

}

// SPDX-License-Identifier: Unlicense
// MagpieCore 0.1.0
pragma solidity >=0.8.0 <0.9.0;

interface IMagpieRouter {

  struct Amm {
    address id;
    uint16 index;
    uint8 protocolIndex;
  }

  struct Hop {
    uint16 ammIndex;
    uint8[] path;
  }

  struct Route {
    uint256 amountIn;
    Hop[] hops;
  }

  struct SwapArgs {
    Route[] routes;
    address[] assets;
    address payable to;
    uint256 amountOutMin;
    uint256 deadline;
  }

  function swap(
    SwapArgs calldata args
  ) external returns (uint256[] memory amountOuts);

  function addAmm(
    Amm calldata amm
  ) external;

  function removeAmm(
    uint16 ammIndex
  ) external;

  event Swapped(
    SwapArgs args,
    uint256[] amountOuts,
    address caller
  );

  event AmmAdded(
    Amm amm,
    address caller
  );

  event AmmRemoved(
    Amm amm,
    address caller
  );

}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface IWormhole {

  function transferTokens(address token, uint256 amount, uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) external payable returns (uint64 sequence);

  function wrapAndTransferETH(uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) external payable returns (uint64 sequence);

  function completeTransfer(bytes memory encodedVm) external;

}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface IWormholeCore {
  
  function publishMessage(uint32 nonce, bytes memory payload, uint8 consistencyLevel) external payable returns (uint64 sequence);

  function parseAndVerifyVM(bytes calldata encodedVM) external view returns (IWormholeCore.VM memory vm, bool valid, string memory reason);

  struct Signature {
		bytes32 r;
		bytes32 s;
		uint8 v;
		uint8 guardianIndex;
	}

  struct VM {
		uint8 version;
		uint32 timestamp;
		uint32 nonce;
		uint16 emitterChainId;
		bytes32 emitterAddress;
		uint64 sequence;
		uint8 consistencyLevel;
		bytes payload;

		uint32 guardianSetIndex;
		Signature[] signatures;

		bytes32 hash;
	}
    
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibAsset {
  using LibAsset for address;

  address constant NATIVE_ASSETID = address(0);

  function isNative(address self) internal pure returns (bool) {
    return self == NATIVE_ASSETID;
  }

  function getBalance(address self) internal view returns (uint) {
    return
      self.isNative()
        ? address(this).balance
        : IERC20(self).balanceOf(address(this));
  }

  function transferFrom(
    address self,
    address from,
    address to,
    uint256 amount
  ) internal {
    SafeERC20.safeTransferFrom(IERC20(self), from, to, amount);
  }

  function increaseAllowance(
    address self,
    address spender,
    uint256 amount
  ) internal {
    require(!self.isNative(), "LibAsset: Allowance can't be increased for native asset");
    SafeERC20.safeIncreaseAllowance(IERC20(self), spender, amount);
  }

  function decreaseAllowance(
    address self,
    address spender,
    uint256 amount
  ) internal {
    require(!self.isNative(), "LibAsset: Allowance can't be decreased for native asset");
    SafeERC20.safeDecreaseAllowance(IERC20(self), spender, amount);
  }

  function transfer(
      address self,
      address payable recipient,
      uint256 amount
  ) internal {
    self.isNative()
      ? Address.sendValue(recipient, amount)
      : SafeERC20.safeTransfer(IERC20(self), recipient, amount);
  }

}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;
import "../interfaces/IMagpieCore.sol";

library LibBytes {
  using LibBytes for bytes;

  function toAddress(bytes memory self, uint256 start) internal pure returns (address) {
    return address(uint160(uint256(self.toBytes32(start))));
  }

  function toUint16(bytes memory self, uint256 start) internal pure returns (uint16) {
      require(self.length >= start + 2, 'LibBytes: toUint16 outOfBounds');
    uint16 tempUint;

    assembly {
      tempUint := mload(add(add(self, 0x2), start))
    }

    return tempUint;
  }

  function toUint256(bytes memory self, uint256 start) internal pure returns (uint256) {
      require(self.length >= start + 32, 'LibBytes: toUint256 outOfBounds');
    uint256 tempUint;

    assembly {
      tempUint := mload(add(add(self, 0x20), start))
    }

    return tempUint;
  }

  function toBytes32(bytes memory self, uint256 start) internal pure returns (bytes32) {
    require(self.length >= start + 32, 'LibBytes: toBytes32 outOfBounds');
    bytes32 tempBytes32;

    assembly {
      tempBytes32 := mload(add(add(self, 0x20), start))
    }

    return tempBytes32;
  }

  function parse(bytes memory self) internal pure returns (IMagpieCore.ValidationOutPayload memory payload) {
    uint256 i = 0;

    payload.fromAssetId = self.toAddress(i);
    i += 32;

    payload.toAssetId = self.toAddress(i);
    i += 32;

    payload.to = self.toAddress(i);
    i += 32;

    payload.recipientId = self.toAddress(i);
    i += 32;

    payload.recipientChainId = self.toUint256(i);
    i += 32;

    payload.amountOutMin = self.toUint256(i);
    i += 32;

    require(self.length == i, 'LibBytes: payload is invalid');
  }

}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/IMagpieCore.sol";
import "../interfaces/IMagpieRouter.sol";
import "../interfaces/IWETH.sol";

library LibSwap {
  using LibSwap for IMagpieRouter.SwapArgs;

  function validate(IMagpieRouter.SwapArgs memory self) internal pure {
    require(self.routes.length > 0, 'LibSwap: invalid route size');
    address fromAssetId = self.getFromAssetId();
    address toAssetId = self.getToAssetId();
    require(fromAssetId != toAssetId, 'LibSwap: invalid fromAssetId - toAssetId');
    for (uint256 i = 0; i < self.routes.length; i++) {
      IMagpieRouter.Route memory route = self.routes[i];
      require(route.hops.length > 0, 'MagpieRouter: invalid hop size');
      IMagpieRouter.Hop memory firstHop = route.hops[0];
      IMagpieRouter.Hop memory lastHop = route.hops[route.hops.length - 1];
      require(fromAssetId == self.assets[firstHop.path[0]], 'LibSwap: invalid from asset');
      require(toAssetId == self.assets[lastHop.path[lastHop.path.length - 1]], 'LibSwap: invalid to asset');
    }

    for (uint256 j = 0; j < self.assets.length; j++) {
      require(self.assets[j] != address(0), 'LibSwap: invalid asset - address0');
    }
  }

  function getFromAssetId(IMagpieRouter.SwapArgs memory self) internal pure returns (address) {
    return self.assets[self.routes[0].hops[0].path[0]];
  }
  
  function getToAssetId(IMagpieRouter.SwapArgs memory self) internal pure returns (address) {
    IMagpieRouter.Hop memory hop = self.routes[0].hops[0];
    return self.assets[hop.path[hop.path.length - 1]];
  }

  function getAmountIn(IMagpieRouter.SwapArgs memory self) internal pure returns (uint256) {
    uint256 amountIn = 0;

    for (uint256 i = 0; i < self.routes.length; i++) {
      amountIn += self.routes[i].amountIn;
    }

    return amountIn;
  }

  function prepare(IMagpieRouter.SwapArgs memory self, address weth) internal pure returns (IMagpieRouter.SwapArgs memory swapArgs) {
    address fromAssetId = self.getFromAssetId();
    address toAssetId = self.getToAssetId();

    for (uint256 i = 0; i < self.assets.length; i++) {
      if (
        (fromAssetId == address(0) && fromAssetId == self.assets[i]) ||
        (toAssetId == address(0) && toAssetId == self.assets[i])
      ) {
        self.assets[i] = weth;
      }
    }

    swapArgs = self;
  }

}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;
import "../interfaces/IMagpieCore.sol";

library LibUint256Array {

  function sum(uint256[] memory self) internal pure returns (uint256) {
    uint256 amountOut = 0;

    for (uint256 i = 0; i < self.length; i++) {
      amountOut += self[i];
    }

    return amountOut;
  }

}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;
import "../interfaces/IMagpieCore.sol";

library LibAddressArray {

  function includes(address[] memory self, address value) internal pure returns (bool) {
    for (uint256 i = 0; i < self.length; i++) {
      if (self[i] == value) {
        return true;
      }
    }

    return false;
  }

}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface IMagpiePool{
    function depositErc20(uint256 toChainId,address tokenAddress,address receiver,uint256 amount) external; 

    function sendFundsToUser(address tokenAddress,uint256 amount,address receiver,uint256 tokenGasPrice,uint256 fromChainId) external; 

    function transfer(address _tokenAddress, address receiver, uint256 _tokenAmount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}