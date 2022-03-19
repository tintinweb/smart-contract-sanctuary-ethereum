// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AirdropSubscription is Ownable, KeeperCompatibleInterface {

  error OnlyKeeperRegistry();

  struct Subscription {
    address subscriber;
    uint256 start;
    uint256 end;
    uint8 tier;
  }

  struct Airdrop {
    address creator;
    address token;
    uint256 totalTiers;
    uint256 qty;
    uint256 start;
    uint256 end;
  }

  uint256 constant MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

  mapping(address => mapping(uint256 => bool)) public claimed;
  Airdrop[] public airdrops;

  mapping(address => bool) public isSubscribed;
  mapping(address => uint256) public subscriptionIndex;
  Subscription[] public subscriptions;

  mapping(address => bool) public isWhitelisted;
  mapping(address => uint256) public whitelistIndex;
  address[] public _whitelist;

  address public uniswapV2RouterAddress;
  IUniswapV2Router02 public uniswapV2Router;

  uint256 public subscriptionDuration;
  uint256 public totalTiers = 0;
  uint256 public basePrice = 10 * 10**18; // $10
  IERC20 public busd;
  address[] public wethBusdPath;

  address payable public lead;
  address payable public dev1;
  address payable public dev2;

  constructor(
    address[] memory team_,
    address busd_,
    uint256 subscriptionDuration_,
    address uniswapV2RouterAddress_
  ) {
    super.transferOwnership(team_[0]);
    lead = payable(team_[0]);
    dev1 = payable(team_[1]);
    dev2 = payable(team_[2]);
    busd = IERC20(busd_);
    subscriptionDuration = subscriptionDuration_;
    uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAddress_);

    // Store weth to busd path for reuse
    wethBusdPath = new address[](2);
    wethBusdPath[0] = uniswapV2Router.WETH();
    wethBusdPath[1] = address(busd);
  }

  receive() external payable {}
  fallback() external payable {}

  /**
   * @notice Get list of addresses with expired subscriptions and return keeper-compatible payload
   * @return upkeepNeeded signals if upkeep is needed
   * @return performData is an abi encoded list of addresses to unsubscribe
   */
  function checkUpkeep(bytes calldata checkData) public view override returns (bool, bytes memory) {
    uint256[] memory pollRange = abi.decode(checkData, (uint256[]));
    uint256 numSubs = getNumSubscriptions();
    require(pollRange[0] < numSubs, "Invalid checkData start");
    require(pollRange[0] < pollRange[1], "Invalid checkData range");
    uint256 pollUntil = (pollRange[1] > numSubs) ? numSubs : pollRange[1];
    address[] memory unsubscribed = new address[](pollUntil - pollRange[0]);
    uint256 index = 0;
    for (uint256 i = pollRange[0]; i < pollUntil; i++) {
      if (block.timestamp > subscriptions[i].end) {
        unsubscribed[index++] = subscriptions[i].subscriber;
      }
    }
    bool upkeepNeeded = (index > 0);
    bytes memory performData = abi.encode(unsubscribed);
    return (upkeepNeeded, performData);
  }

  /**
   * @notice Called by keeper to clenaup expired subscriptions
   * @param performData The abi encoded list of addresses to unsubscribe
   */
  function performUpkeep(bytes calldata performData) external override {
    address[] memory addresses = abi.decode(performData, (address[]));
    for (uint256 i = 0; i < addresses.length; i++) {
      uint256 deleteIndex = subscriptionIndex[addresses[i]];
      require(block.timestamp > subscriptions[deleteIndex].end, "Not expired");
      totalTiers -= subscriptions[deleteIndex].tier;
      if (deleteIndex != subscriptions.length - 1) {
        // deleting in middle - overwrite w/ last element
        subscriptions[deleteIndex] = subscriptions[subscriptions.length - 1];
        subscriptionIndex[subscriptions[deleteIndex].subscriber] = deleteIndex;
      }
      // cleanup storage space
      subscriptions.pop();
      delete subscriptionIndex[addresses[i]];
      isSubscribed[addresses[i]] = false;
    }
  }

  // AIRDROP CLAIMING FUNCTIONS
  function getClaimableTokens(address _subscriber, uint256 _airdropIndex) public view returns (uint256) {
    Airdrop memory airdrop = airdrops[_airdropIndex];
    Subscription memory subscription = subscriptions[subscriptionIndex[_subscriber]];
    if (!isWhitelisted[airdrop.token]) return 0; // Airdrop not whitelisted
    if (claimed[_subscriber][_airdropIndex]) return 0; // Already claimed
    if (block.timestamp > subscription.end) return 0; // Subscription expired
    if (subscription.start > airdrop.start) return 0; // Subscribed after airdrop began
    return (subscription.tier * airdrop.qty) / airdrop.totalTiers;
  }

  function getAllClaimableTokens(address _subscriber) public view returns (uint256[] memory) {
    uint256[] memory allClaimableTokens = new uint256[](airdrops.length);
    for (uint256 i = 0; i < airdrops.length; i++) {
      allClaimableTokens[i] = getClaimableTokens(_subscriber, i);
    }
    return allClaimableTokens;
  }

  function claimAirdrop(address _subscriber, uint256 _airdropIndex) external {
    uint256 claimableTokens = getClaimableTokens(_subscriber, _airdropIndex);
    require(claimableTokens > 0, "Nothing to claim");
    claimed[_subscriber][_airdropIndex] = true;
    IERC20(airdrops[_airdropIndex].token).transfer(_subscriber, claimableTokens);
  }

  // SUBSCRIPTION PAYMENTS
  function subscribeBNB(uint8 _tier) public payable {
    require(1 <= _tier && _tier <= 3, "Invalid tier");
    require(!isSubscribed[msg.sender], "Already subscribed");
    require(msg.value >= getPaymentBNB(_tier), "Not enough BNB sent");

    // Pay in BNB
    uniswapV2Router.swapExactETHForTokens{value:msg.value}(
        getPaymentBUSD(_tier),
        wethBusdPath,
        address(this),
        block.timestamp+10
    );
    _subscribe(msg.sender, _tier);
  }

  function subscribeBUSD(uint8 _tier, uint256 _payment) public {
    require(1 <= _tier && _tier <= 3, "Invalid tier");
    require(!isSubscribed[msg.sender], "Already subscribed");
    require(_payment >= getPaymentBUSD(_tier), "Invalid payment sent");

    // Pay in BUSD
    busd.transferFrom(msg.sender, address(this), _payment);
    _subscribe(msg.sender, _tier);
  }

  function getPaymentBNB(uint8 _tier) public view returns (uint256) {
    require(1 <= _tier && _tier <= 3, "Invalid tier");
    uint256 amountOut = getPaymentBUSD(_tier);
    uint256 amountInMin = uniswapV2Router.getAmountsIn(amountOut, wethBusdPath)[0];
    uint256 amountInMinWithSlippage = (amountInMin*10080)/10000; // 80 bips
    return amountInMinWithSlippage;
  }

  function getPaymentBUSD(uint8 _tier) public view returns (uint256) {
    require(1 <= _tier && _tier <= 3, "Invalid tier");
    if (_tier == 1) return basePrice * 100 / 100; // 1x tierOnePrice w/ 0% discount
    if (_tier == 2) return basePrice * 180 / 100; // 2x tierOnePrice w/ 10% discount
    if (_tier == 3) return basePrice * 240 / 100; // 3x tierOnePrice w/ 20% discount
    return MAX_INT;
  }

  function _subscribe(address _subscriber, uint8 _tier) internal {
    isSubscribed[_subscriber] = true;
    uint256 index = subscriptions.length;
    subscriptionIndex[_subscriber] = index;
    subscriptions.push(Subscription(
      _subscriber,
      block.timestamp,
      block.timestamp + subscriptionDuration,
      _tier
    ));
    totalTiers += _tier;
  }

  // AIRDROP CREATIONs
  function createAirdrop(address _token, uint256 _qty, uint256 _start, uint256 _end) external {
    require(isWhitelisted[_token], "Not whitelisted");
    require(_qty > 0, "Invalid qty");
    require(block.timestamp <= _start, "Cant start in the past");
    require(_start < _end, "Invalid start and end");
    IERC20(_token).transferFrom(msg.sender, address(this), _qty);
    airdrops.push(
      Airdrop(msg.sender, _token, totalTiers, _qty, _start, _end)
    );
  }

  function cleanupAirdrop(uint256 _airdropIndex) external {
    Airdrop memory airdrop = airdrops[_airdropIndex];
    require(block.timestamp < airdrop.start || airdrop.end < block.timestamp, "Cant do this mid-airdrop");
    require(msg.sender == airdrop.creator, "Not original airdropper");
    IERC20(airdrop.token).transfer(msg.sender, IERC20(airdrop.token).balanceOf(address(this)));
  }

  // MANAGEMENT
  function whitelist(address _token) external onlyOwner {
    isWhitelisted[_token] = true;
    whitelistIndex[_token] = _whitelist.length;
    _whitelist.push(_token);
  }

  function unsetWhitelist(address _token) external onlyOwner {
    isWhitelisted[_token] = false;
    uint deleteIndex = whitelistIndex[_token];
    if (deleteIndex != _whitelist.length - 1) {
      // deleting in middle - overwrite w/ last element
      _whitelist[deleteIndex] = _whitelist[_whitelist.length - 1];
      whitelistIndex[_whitelist[deleteIndex]] = deleteIndex;
    }
    // cleanup storage space
    _whitelist.pop();
    delete whitelistIndex[_token];
  }

  function setBasePrice(uint256 _basePrice) external onlyOwner {
    basePrice = _basePrice;
  }

  function payoutBNB() external {
    uint256 bnbAmount = address(this).balance;
    require(lead.send((bnbAmount*70)/100));
    require(dev1.send((bnbAmount*15)/100));
    require(dev2.send((bnbAmount*15)/100));
  }

  function payoutBUSD() external {
    uint256 busdAmount = busd.balanceOf(address(this));
    busd.transfer(lead, (busdAmount*70)/100);
    busd.transfer(dev1, (busdAmount*15)/100);
    busd.transfer(dev2, (busdAmount*15)/100);
  }

  function transferOwnership(address _lead) public override {
    require(msg.sender == lead);
    super.transferOwnership(_lead);
    lead = payable(_lead);
  }

  function updateDev1Address(address _dev1) external {
    require(msg.sender == dev1);
    dev1 = payable(_dev1);
  }

  function updateDev2Address(address _dev2) external {
    require(msg.sender == dev2);
    dev2 = payable(_dev2);
  }

  // UI HELPERS / READ ONLY VIEWS
  function getNumSubscriptions() public view returns (uint256) {
    return subscriptions.length;
  }

  function getNumAirdrops() public view returns (uint256) {
    return airdrops.length;
  }

  function getNumWhitelisted() public view returns (uint256) {
    return _whitelist.length;
  }

  function getWhitelist() public view returns (address[] memory _addresses) {
    _addresses = new address[](_whitelist.length);
    for (uint i; i < _whitelist.length; i++) {
      _addresses[i] = _whitelist[i];
    }
  }

  function getTokenInfo(address[] calldata _tokens) public view returns (
    address[] memory addresses, // convenience
    string[] memory names,
    string[] memory symbols,
    uint[] memory decimals
  ) {
    addresses = new address[](_tokens.length);
    names = new string[](_tokens.length);
    symbols = new string[](_tokens.length);
    decimals = new uint[](_tokens.length);
    for (uint i; i < _tokens.length; i++) {
        IERC20 token = IERC20(_tokens[i]);
        (addresses[i]) = _tokens[i];
        (names[i]) = token.name();
        (symbols[i]) = token.symbol();
        (decimals[i]) = token.decimals();
    }
  }
}

// TODO
// function getAirdrops() public view returns (
//   address[] memory creators,
//   address[] memory tokens,
//   uint[] memory totalTiers,
//   uint[] memory quantities,
//   uint[] memory starts,
//   uint[] memory ends
// ) {
//   creators = new address[](airdrops.length);
//   tokens = new address[](airdrops.length);
//   totalTiers = new uint[](airdrops.length);
//   quantities = new uint[](airdrops.length);
//   starts = new uint[](airdrops.length);
//   ends = new uint[](airdrops.length);
//   for (uint i; i < airdrops.length; i++) {
//     creators[i] = airdrops[i].creator;
//     tokens[i] = airdrops[i].token;
//     totalTiers[i] = airdrops[i].totalTiers;
//     quantities[i] = airdrops[i].qty;
//     starts[i] = airdrops[i].start;
//     ends[i] = airdrops[i].end;
//   }
// }

contract MockAirdropSubscription is AirdropSubscription {

  constructor(
    address[] memory team_,
    address busd_,
    uint256 subscriptionDuration_,
    address uniswapV2RouterAddress_,
    uint256 mockSubs_
  ) AirdropSubscription(
    team_,
    busd_,
    subscriptionDuration_,
    uniswapV2RouterAddress_
  ) {
    // Generate mock subscriptions
    for (uint16 i = 0; i < mockSubs_; i++) {
      address addy = address(uint160(uint(keccak256(abi.encodePacked(i)))));
      uint8 tier = uint8(i % 3) + 1;
      subscriptionIndex[addy] = i;
      subscriptions.push(Subscription(addy, block.timestamp - 10, block.timestamp - 5, tier));
      totalTiers += tier;
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

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