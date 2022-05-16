// SPDX-License-Identifier: Unlicense
// MagpieCore 0.1.2
pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import './interfaces/IMagpieCore.sol';
import './interfaces/IMagpiePool.sol';
import './interfaces/IWormhole.sol';
import './interfaces/IWormholeCore.sol';
import './interfaces/balancer-v2/IVault.sol';
import './interfaces/uniswap-v2/IUniswapV2Router02.sol';
import './lib/LibAsset.sol';
import './lib/LibBytes.sol';
import './lib/LibSwap.sol';
import './lib/LibUint256Array.sol';
import './lib/LibAddressArray.sol';
import './security/Pausable.sol';

contract MagpieCore is ReentrancyGuard, Ownable, Pausable, IMagpieCore {
  using LibAsset for address;
  using LibBytes for bytes;
  using LibSwap for SwapArgs;
  using LibUint256Array for uint256[];
  using LibAddressArray for address[];

  mapping(uint64 => bool) private sequences;
  mapping(uint16 => Amm) private _amms;

  Config public config;

  constructor(Config memory _config) Pausable(_config.pauserAddress) {
    config = _config;
  }

  modifier ensure(uint256 deadline) {
    require(deadline >= block.timestamp, 'MagpieCore: expired transaction');
    _;
  }

  receive() external payable {
    require(config.weth == msg.sender, 'MagpieCore: invalid sender');
  }

  function updateConfig(Config calldata _config) external override onlyOwner {
    require(_config.weth != address(0), 'MagpieCore: invalid weth');
    require(_config.magpiePoolAddress != address(0), 'MagpieCore: invalid magpiePoolAddress');
    require(_config.coreBridgeAddress != address(0), 'MagpieCore: invalid coreBridgeAddress');
    require(_config.consistencyLevel > 1, 'MagpieCore: invalid consistencyLevel');

    config = _config;

    emit ConfigUpdated(config, msg.sender);
  }

  function updateAmms(Amm[] calldata amms) external override onlyOwner {
    require(amms.length > 0, 'MagpieCore: invalid amms');
    for (uint256 i = 0; i < amms.length; i++) {
      Amm memory amm = Amm({
        id: amms[i].id,
        index: amms[i].index,
        protocolIndex: amms[i].protocolIndex
      });

      require(amm.id != address(0), 'MagpieCore: invalid amm address');
      require(amm.index > 0, 'MagpieCore: invalid amm index');
      require(amm.protocolIndex > 0, 'MagpieCore: invalid amm protocolIndex');

      _amms[amm.index] = amm;
    }

    emit AmmsUpdated(amms, msg.sender);
  }

  function _wrapAssets(SwapArgs memory swapArgs) private returns (SwapArgs memory newSwapArgs) {
    address fromAssetId = swapArgs.getFromAssetId();
    address toAssetId = swapArgs.getToAssetId();
    uint256 amountIn = swapArgs.getAmountIn();

    if (fromAssetId.isNative()) {
      IWETH(config.weth).deposit{value: amountIn}();
    }

    for (uint256 i = 0; i < swapArgs.assets.length; i++) {
      if (
        (fromAssetId.isNative() && fromAssetId == swapArgs.assets[i]) ||
        (toAssetId.isNative() && toAssetId == swapArgs.assets[i])
      ) {
        swapArgs.assets[i] = config.weth;
      }
    }

    newSwapArgs = swapArgs;
  }

  function _wrapSwap(SwapArgs memory swapArgs, bool transferFromSender)
    private
    returns (uint256[] memory amountOuts)
  {
    require(swapArgs.routes.length > 0, 'MagpieCore: invalid route size');
    address fromAssetId = swapArgs.getFromAssetId();
    address toAssetId = swapArgs.getToAssetId();
    address payable to = swapArgs.to;
    uint256 amountIn = swapArgs.getAmountIn();

    require(fromAssetId != toAssetId, 'MagpieCore: invalid fromAssetId - toAssetId');

    swapArgs = _wrapAssets(swapArgs);

    if (!fromAssetId.isNative() && transferFromSender) {
      fromAssetId.transferFrom(msg.sender, address(this), amountIn);
    }

    amountOuts = _swap(swapArgs);

    uint256 amountOut = amountOuts.sum();

    if (toAssetId.isNative()) {
      IWETH(config.weth).withdraw(amountOut);
    }

    if (to != address(this)) {
      toAssetId.transfer(to, amountOut);
    }
  }

  function _swap(SwapArgs memory swapArgs) private returns (uint256[] memory amountOuts) {
    amountOuts = new uint256[](swapArgs.routes.length);
    address fromAssetId = swapArgs.getFromAssetId();
    address toAssetId = swapArgs.getToAssetId();
    uint256 startingBalance = toAssetId.getBalance();

    for (uint256 i = 0; i < swapArgs.routes.length; i++) {
      Route memory route = swapArgs.routes[i];
      Hop memory firstHop = route.hops[0];
      Hop memory lastHop = route.hops[route.hops.length - 1];
      require(fromAssetId == swapArgs.assets[firstHop.path[0]], 'MagpieCore: invalid from asset');
      require(
        toAssetId == swapArgs.assets[lastHop.path[lastHop.path.length - 1]],
        'MagpieCore: invalid to asset'
      );
      amountOuts[i] = _swapRoute(route, swapArgs.assets, swapArgs.deadline);
    }

    uint256 amountOut = amountOuts.sum();

    require(toAssetId.getBalance() == startingBalance + amountOut, 'MagpieCore: invalid amountOut');

    for (uint256 j = 0; j < swapArgs.assets.length; j++) {
      require(swapArgs.assets[j] != address(0), 'MagpieCore: invalid asset - address0');
    }

    require(amountOut >= swapArgs.amountOutMin, 'MagpieCore: insufficient output amount');
  }

  function _swapRoute(
    Route memory route,
    address[] memory assets,
    uint256 deadline
  ) private returns (uint256) {
    require(route.hops.length > 0, 'MagpieCore: invalid hop size');
    uint256 lastAmountOut = 0;

    for (uint256 i = 0; i < route.hops.length; i++) {
      uint256 amountIn = i == 0 ? route.amountIn : lastAmountOut;
      Hop memory hop = route.hops[i];
      lastAmountOut = _swapHop(amountIn, hop, assets, deadline);
    }

    return lastAmountOut;
  }

  function _swapHop(
    uint256 amountIn,
    Hop memory hop,
    address[] memory assets,
    uint256 deadline
  ) private returns (uint256) {
    Amm memory amm = _amms[hop.ammIndex];

    require(amm.id != address(0), 'MagpieCore: invalid amm');
    require(hop.path.length > 1, 'MagpieCore: invalid path size');
    address fromAssetId = assets[hop.path[0]];

    if (fromAssetId.getAllowance(address(this), amm.id) < amountIn) {
      fromAssetId.approve(amm.id, type(uint256).max);
    }

    if (amm.protocolIndex == 1) {
      return _swapUniswapV2(amountIn, hop, assets, deadline);
    } else if (amm.protocolIndex == 2 || amm.protocolIndex == 3) {
      return _swapBalancerV2(amountIn, hop, assets, deadline);
    }

    return 0;
  }

  function _swapUniswapV2(
    uint256 amountIn,
    Hop memory hop,
    address[] memory assets,
    uint256 deadline
  ) private returns (uint256) {
    Amm memory amm = _amms[hop.ammIndex];
    address[] memory path = new address[](hop.path.length);
    for (uint256 i = 0; i < hop.path.length; i++) {
      path[i] = assets[hop.path[i]];
    }
    uint256[] memory amounts = IUniswapV2Router02(amm.id).swapExactTokensForTokens(
      amountIn,
      0,
      path,
      address(this),
      deadline
    );

    return amounts[amounts.length - 1];
  }

  function _swapBalancerV2(
    uint256 amountIn,
    Hop memory hop,
    address[] memory assets,
    uint256 deadline
  ) private returns (uint256) {
    Amm memory amm = _amms[hop.ammIndex];
    IVault.BatchSwapStep[] memory swaps = new IVault.BatchSwapStep[](hop.path.length - 1);
    uint256 poolIdIndex = 0;
    IAsset[] memory balancerAssets = new IAsset[](hop.path.length);
    int256[] memory limits = new int256[](hop.path.length);
    for (uint256 i = 0; i < hop.path.length - 1; i++) {
      swaps[i] = IVault.BatchSwapStep({
        poolId: hop.poolData.toBytes32(poolIdIndex),
        assetInIndex: i,
        assetOutIndex: i + 1,
        amount: i == 0 ? amountIn : 0,
        userData: '0x'
      });
      poolIdIndex += 32;
      balancerAssets[i] = IAsset(assets[hop.path[i]]);
      limits[i] = i == 0 ? int256(amountIn) : int256(0);

      if (i == hop.path.length - 2) {
        balancerAssets[i + 1] = IAsset(assets[hop.path[i + 1]]);
        limits[i + 1] = int256(0);
      }
    }
    require(hop.poolData.length == poolIdIndex, 'MagpieCore: poolData is invalid');
    IVault.FundManagement memory funds = IVault.FundManagement({
      sender: address(this),
      fromInternalBalance: false,
      recipient: payable(address(this)),
      toInternalBalance: false
    });

    int256[] memory deltas = IVault(amm.id).batchSwap(
      IVault.SwapKind.GIVEN_IN,
      swaps,
      balancerAssets,
      funds,
      limits,
      deadline
    );
    int256 lastDelta = deltas[hop.path.length - 1];

    return lastDelta > 0 ? 0 : uint256(-lastDelta);
  }

  function _intermediarySwap(SwapArgs memory swapArgs, bool transferFromSender)
    private
    returns (uint256[] memory amountOuts)
  {
    uint256 amountIn = swapArgs.getAmountIn();
    amountOuts = new uint256[](1);
    amountOuts[0] = amountIn;
    uint256 amountOut = amountIn;
    require(amountOut >= swapArgs.amountOutMin, 'MagpieCore: invalid intermediary amountIn');

    if (transferFromSender) {
      address fromAssetId = swapArgs.getFromAssetId();
      fromAssetId.transferFrom(msg.sender, address(this), amountIn);
    } else {
      address toAssetId = swapArgs.getToAssetId();
      toAssetId.transfer(swapArgs.to, amountOut);
    }
  }

  function swap(SwapArgs calldata swapArgs)
    external
    payable
    ensure(swapArgs.deadline)
    whenNotPaused
    returns (uint256[] memory amountOuts)
  {
    amountOuts = _wrapSwap(swapArgs, true);

    emit Swapped(swapArgs, amountOuts, msg.sender);
  }

  function swapIn(SwapInArgs calldata args, bool useTokenBridge)
    external
    payable
    override
    ensure(args.swapArgs.deadline)
    whenNotPaused
    returns (
      uint256[] memory amountOuts,
      uint64 coreSequence,
      uint64 tokenSequence
    )
  {
    require(args.swapArgs.to == address(this), 'MagpieCore: invalid swapArgs to');

    require(
      config.intermediaries.includes(args.swapArgs.getToAssetId()) == true,
      'MagpieCore: invalid intermediary'
    );

    uint256 amountOut;

    if (config.intermediaries.includes(args.swapArgs.getFromAssetId())) {
      amountOuts = _intermediarySwap(args.swapArgs, true);
      amountOut = amountOuts.sum();
    } else {
      amountOuts = _wrapSwap(args.swapArgs, true);
      amountOut = amountOuts.sum();
    }

    args.swapArgs.getToAssetId().increaseAllowance(config.magpiePoolAddress, amountOut);
    IMagpiePool.BridgeInTokenArgs memory bridgeInArgs = IMagpiePool.BridgeInTokenArgs({
      toChainId: args.payload.recipientChainId,
      tokenAddress: args.swapArgs.getToAssetId(),
      receiver: args.payload.to,
      amount: amountOut,
      useTokenBridge: useTokenBridge
    });
    {
      tokenSequence = IMagpiePool(config.magpiePoolAddress).bridgeInToken(bridgeInArgs);

      bytes memory payloadOut = bytes.concat(
        abi.encodePacked(
          args.payload.fromAssetId,
          args.payload.toAssetId,
          args.payload.to,
          args.payload.intermediaryReceiver,
          args.payload.recipientChainId,
          args.payload.amountOutMin
        ),
        abi.encodePacked(
          args.payload.swapOutGasFee,
          args.payload.destGasTokenAmount,
          block.chainid,
          amountOut,
          useTokenBridge
        )
      );

      coreSequence = IWormholeCore(config.coreBridgeAddress).publishMessage(
        uint32(block.timestamp % 2**32),
        payloadOut,
        config.consistencyLevel
      );

      emit SwappedIn(args, amountOuts, coreSequence, tokenSequence, msg.sender);

      return (amountOuts, coreSequence, tokenSequence);
    }
  }

  function swapOut(SwapOutArgs calldata args)
    external
    override
    ensure(args.swapArgs.deadline)
    whenNotPaused
    returns (uint256[] memory amountOuts)
  {
    (IWormholeCore.VM memory vm, bool valid, string memory reason) = IWormholeCore(
      config.coreBridgeAddress
    ).parseAndVerifyVM(args.encodedVmCore);

    require(valid == true, 'MagpieCore: invalid vaa');
    require(sequences[vm.sequence] != true, 'MagpieCore: already used sequence');

    sequences[vm.sequence] = true;

    ValidationOutPayload memory payload = vm.payload.parse();

    SwapArgs memory swapArgs = args.swapArgs;

    address fromAssetId = swapArgs.getFromAssetId();
    address toAssetId = swapArgs.getToAssetId();

    if (payload.to == msg.sender) {
      swapArgs.routes[0].amountIn += payload.swapOutGasFee;
      payload.swapOutGasFee = 0;
    } else {
      require(swapArgs.amountOutMin >= payload.amountOutMin, 'MagpieCore: invalid amountOutMin');
    }

    require(
      config.intermediaries.includes(fromAssetId) == true,
      'MagpieCore: invalid intermediary'
    );
    require(payload.fromAssetId == fromAssetId, 'MagpieCore: invalid fromAssetId');
    require(payload.toAssetId == toAssetId, 'MagpieCore: invalid toAssetId');
    require(payload.to == swapArgs.to && payload.to != address(this), 'MagpieCore: invalid to');
    require(
      payload.intermediaryReceiver == address(this),
      'MagpieCore: invalid intermediaryReceiver'
    );
    require(
      uint256(payload.recipientChainId) == block.chainid,
      'MagpieCore: invalid recipientChainId'
    );
    require(swapArgs.amountOutMin >= payload.amountOutMin, 'MagpieCore: invalid amountOutMin');
    require(swapArgs.getAmountIn() == payload.amountIn, 'MagpieCore: invalid amountIn');

    uint256 totalAmountIn = payload.amountIn + payload.destGasTokenAmount;
    IMagpiePool.BridgeOutTokenArgs memory bridgeOutArgs = IMagpiePool.BridgeOutTokenArgs({
      tokenAddress: payload.fromAssetId,
      amount: totalAmountIn,
      receiver: payable(payload.to),
      gasFee: payload.swapOutGasFee,
      encodedVM: args.encodedVmBridge
    });
    uint256 amountToTransfer = IMagpiePool(config.magpiePoolAddress).bridgeOutToken(
      bridgeOutArgs
    );
    uint256 transferFee = totalAmountIn - amountToTransfer;

    require(swapArgs.routes[0].amountIn >= transferFee, 'MagpieCore: invalid amountIn in route 0');
    swapArgs.routes[0].amountIn -= transferFee;

    if (config.intermediaries.includes(toAssetId)) {
      amountOuts = _intermediarySwap(swapArgs, false);
    } else {
      amountOuts = _wrapSwap(swapArgs, false);
    }

    if (payload.destGasTokenAmount > 0) {
      require(
        args.gasTokenSwapArgs.getAmountIn() == payload.destGasTokenAmount,
        'MagpieCore: invalid amountIn'
      );
      require(
        args.gasTokenSwapArgs.getFromAssetId() == payload.fromAssetId,
        'MagpieCore: invalid fromAssetId'
      );
      require(args.gasTokenSwapArgs.getToAssetId().isNative(), 'MagpieCore: invalid toAssetId');
      require(args.gasTokenSwapArgs.to == payable(payload.to), 'MagpieCore: invalid to');
      _swap(args.gasTokenSwapArgs);
    }

    emit SwappedOut(args, amountOuts, msg.sender);
  }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface IMagpieCore {

  struct Config {
    address weth;
    address pauserAddress;
    address magpiePoolAddress;
    address coreBridgeAddress;
    address[] intermediaries;
    uint8 consistencyLevel;
  }
 
  struct Amm {
    address id;
    uint16 index;
    uint8 protocolIndex;
  }

  struct Hop {
    uint16 ammIndex;
    uint8[] path;
    bytes poolData;
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

  struct ValidationInPayload{
    bytes32 fromAssetId;
    bytes32 toAssetId;
    bytes32 to; /* user address */
    uint256 amountOutMin;
    bytes32 intermediaryReceiver; /* Magpie core address in bytes of the recipient chain */
    uint256 recipientChainId;
    uint256 swapOutGasFee; 
    uint256 destGasTokenAmount;
  }

  struct ValidationOutPayload {
    address fromAssetId;
    address toAssetId;
    address to; /* user address */
    address intermediaryReceiver; /* Magpie core address of the recipient chain */
    uint256 recipientChainId;
    uint256 amountOutMin;
    uint256 swapOutGasFee;
    uint256 destGasTokenAmount;
    uint256 senderChainId;
    uint256 amountIn;
    bool useTokenBridge;
  }

  struct SwapInArgs {
    SwapArgs swapArgs;
    ValidationInPayload payload;
  }

  struct SwapOutArgs {
    SwapArgs swapArgs;
    SwapArgs gasTokenSwapArgs;
    uint256 tokenGasFee;
    bytes encodedVmCore;
    bytes encodedVmBridge;
  }

  function updateAmms(
    Amm[] calldata amms
  ) external;

  function updateConfig(
    Config calldata config
  ) external;

  function swap(
    SwapArgs calldata args
  ) external payable returns(uint256[] memory amountOuts);

  function swapIn(
    SwapInArgs calldata swapArgs,
    bool tokenBridge
  ) external payable returns(uint256[] memory amountOuts, uint64, uint64);

  function swapOut(
    SwapOutArgs calldata args
  ) external returns(uint256[] memory amountOuts);

  event ConfigUpdated(
    Config config, 
    address caller
  );

  event AmmsUpdated(
    Amm[] amms,
    address caller
  );

  event Swapped(
    SwapArgs args, 
    uint256[] amountOuts,
    address caller
  );

  event SwappedIn(
    SwapInArgs args,
    uint256[] amountOuts,
    uint64 coreSequence, 
    uint64 tokenSequence,
    address caller
  );

  event SwappedOut(
    SwapOutArgs args, 
    uint256[] amountOuts,
    address caller
  );

}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface IMagpiePool {
  function getLiquidity(address tokenAddress) external returns(uint256);

  struct BridgeOutTokenArgs {
    address tokenAddress;
    uint256 amount;
    address payable receiver;
    uint256 gasFee;
    bytes encodedVM;
  }

  struct BridgeInTokenArgs {
    uint256 toChainId;
    address tokenAddress;
    bytes32 receiver;
    uint256 amount;
    bool useTokenBridge;
  }

  function bridgeInToken(BridgeInTokenArgs calldata bridgeInArgs) external returns(uint64);

  function bridgeOutToken(BridgeOutTokenArgs calldata bridgeOutArgs) external returns(uint256);

  function transfer(
    address _tokenAddress,
    address receiver,
    uint256 _tokenAmount
  ) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface IWormhole {

  function transferTokens(address token, uint256 amount, uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) external payable returns (uint64 sequence);

  function wrapAndTransferETH(uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) external payable returns (uint64 sequence);

  function completeTransfer(bytes memory encodedVm) external;

  function chainId() external view returns (uint16) ;

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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IAsset.sol";

interface IVault {

  enum SwapKind { GIVEN_IN, GIVEN_OUT }

  function swap(
    SingleSwap memory singleSwap,
    FundManagement memory funds,
    uint256 limit,
    uint256 deadline
  ) external payable returns (uint256);

  struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    IAsset assetIn;
    IAsset assetOut;
    uint256 amount;
    bytes userData;
  }

  function batchSwap(
    SwapKind kind,
    BatchSwapStep[] memory swaps,
    IAsset[] memory assets,
    FundManagement memory funds,
    int256[] memory limits,
    uint256 deadline
  ) external payable returns (int256[] memory);

  struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
    uint256 amount;
    bytes userData;
  }

  struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
  }

  function queryBatchSwap(
    SwapKind kind,
    BatchSwapStep[] memory swaps,
    IAsset[] memory assets,
    FundManagement memory funds
  ) external returns (int256[] memory assetDeltas);

}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountETH);
  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;
  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable;
  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;
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

  function approve(
    address self,
    address spender,
    uint256 amount
  ) internal {
    require(!self.isNative(), "LibAsset: Allowance can't be increased for native asset");
    SafeERC20.safeApprove(IERC20(self), spender, amount);
  }

  function getAllowance(address self, address owner, address spender) internal view returns (uint256) {
    return IERC20(self).allowance(owner, spender);
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

  function toBool(bytes memory self, uint256 start) internal pure returns (bool) {
    require(self.length >= start + 1, 'LibBytes: toBool outOfBounds');
    bool tempBool;

    assembly {
      tempBool := mload(add(add(self, 0x1), start))
    }

    return tempBool;
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

    payload.intermediaryReceiver = self.toAddress(i);
    i += 32;

    payload.recipientChainId = self.toUint256(i);
    i += 32;

    payload.amountOutMin = self.toUint256(i);
    i += 32;

    payload.swapOutGasFee = self.toUint256(i);
    i +=32;

    payload.destGasTokenAmount = self.toUint256(i);
    i += 32;

    payload.senderChainId = self.toUint256(i);
    i += 32;

    payload.amountIn = self.toUint256(i);
    i += 32;

    payload.useTokenBridge = self.toBool(i);
    i += 1;

    require(self.length == i, 'LibBytes: payload is invalid');
  }

}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/IMagpieCore.sol";
import "../interfaces/IWETH.sol";
import "./LibAsset.sol";

library LibSwap {
  using LibAsset for address;
  using LibSwap for IMagpieCore.SwapArgs;

  function getFromAssetId(IMagpieCore.SwapArgs memory self) internal pure returns (address) {
    return self.assets[self.routes[0].hops[0].path[0]];
  }
  
  function getToAssetId(IMagpieCore.SwapArgs memory self) internal pure returns (address) {
    IMagpieCore.Hop memory hop = self.routes[0].hops[self.routes[0].hops.length - 1];
    return self.assets[hop.path[hop.path.length - 1]];
  }

  function getAmountIn(IMagpieCore.SwapArgs memory self) internal pure returns (uint256) {
    uint256 amountIn = 0;

    for (uint256 i = 0; i < self.routes.length; i++) {
      amountIn += self.routes[i].amountIn;
    }

    return amountIn;
  }

}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

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

import {Pausable as OpenZeppelinPausable} from '@openzeppelin/contracts/security/Pausable.sol';

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is OpenZeppelinPausable {
  address private _pauser;

  event PauserChanged(address indexed previousPauser, address indexed newPauser);

  /**
   * @dev The pausable constructor sets the original `pauser` of the contract to the sender
   * account & Initializes the contract in unpaused state..
   */
  constructor (address pauser) {
    require(pauser != address(0), 'Pauser Address cannot be 0');
    _pauser = pauser;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isPauser(address pauser) public view returns (bool) {
    return pauser == _pauser;
  }

  /**
   * @dev Throws if called by any account other than the pauser.
   */
  modifier onlyPauser() {
    require(isPauser(msg.sender), 'Only pauser is allowed to perform this operation');
    _;
  }

  /**
   * @dev Allows the current pauser to transfer control of the contract to a newPauser.
   * @param newPauser The address to transfer pauserShip to.
   */
  function changePauser(address newPauser) public onlyPauser {
    _changePauser(newPauser);
  }

  /**
   * @dev Transfers control of the contract to a newPauser.
   * @param newPauser The address to transfer ownership to.
   */
  function _changePauser(address newPauser) internal {
    require(newPauser != address(0));
    emit PauserChanged(_pauser, newPauser);
    _pauser = newPauser;
  }

  function renouncePauser() external virtual onlyPauser {
    emit PauserChanged(_pauser, address(0));
    _pauser = address(0);
  }

  function pause() public onlyPauser {
    _pause();
  }

  function unpause() public onlyPauser {
    _unpause();
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);
  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountETH);
  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETHWithPermit(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountToken, uint amountETH);
  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
  function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
  function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

  function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}