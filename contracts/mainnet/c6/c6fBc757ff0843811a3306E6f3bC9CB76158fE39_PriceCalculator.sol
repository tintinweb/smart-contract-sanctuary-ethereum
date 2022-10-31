// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

import "./IPriceCalculator.sol";
import "../../base/governance/ControllableV2.sol";
import "../../third_party/uniswap/IUniswapV2Factory.sol";
import "../../third_party/uniswap/IUniswapV2Pair.sol";
import "../../third_party/uniswap/IUniPoolV3.sol";
import "../../third_party/uniswap/IUniFactoryV3.sol";
import "../../third_party/firebird/IFireBirdPair.sol";
import "../../third_party/firebird/IFireBirdFactory.sol";
import "../../base/interface/ISmartVault.sol";
import "../../third_party/iron/IIronSwap.sol";
import "../../third_party/iron/IIronLpToken.sol";
import "../../third_party/curve/ICurveLpToken.sol";
import "../../third_party/curve/ICurveMinter.sol";
import "../../third_party/IERC20Extended.sol";
import "../../third_party/aave/IAaveToken.sol";
import "../../third_party/aave/IWrappedAaveToken.sol";
import "../../third_party/balancer/IBPT.sol";
import "../../third_party/balancer/IBVault.sol";
import "../../third_party/dystopia/IDystopiaFactory.sol";
import "../../third_party/dystopia/IDystopiaPair.sol";
import "../../openzeppelin/Math.sol";

pragma solidity 0.8.4;

/// @title Calculate current price for token using data from swap platforms
/// @author belbix, bogdoslav
contract PriceCalculator is Initializable, ControllableV2, IPriceCalculator {

  // ************ CONSTANTS **********************

  string public constant VERSION = "1.6.1";
  string public constant IS3USD = "IRON Stableswap 3USD";
  string public constant IRON_IS3USD = "IronSwap IRON-IS3USD LP";
  address public constant FIREBIRD_FACTORY = 0x5De74546d3B86C8Df7FEEc30253865e1149818C8;
  address public constant DYSTOPIA_FACTORY = 0x1d21Db6cde1b18c7E47B0F7F42f4b3F68b9beeC9;
  address public constant CONE_FACTORY = 0x0EFc2D2D054383462F2cD72eA2526Ef7687E1016;
  address public constant UNIV3_FACTORY_ETHEREUM = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
  bytes32 internal constant _DEFAULT_TOKEN_SLOT = 0x3787EA0F228E63B6CF40FE5DE521CE164615FC0FBC5CF167A7EC3CDBC2D38D8F;
  uint256 constant public PRECISION_DECIMALS = 18;
  uint256 constant public DEPTH = 20;
  address public constant CRV_USD_BTC_ETH_MATIC = 0xdAD97F7713Ae9437fa9249920eC8507e5FbB23d3;
  address public constant CRV_USD_BTC_ETH_FANTOM = 0x58e57cA18B7A47112b877E31929798Cd3D703b0f;
  address public constant BEETHOVEN_VAULT_FANTOM = 0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce;
  address public constant BALANCER_VAULT_ETHEREUM = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

  // ************ VARIABLES **********************
  // !!! DON'T CHANGE NAMES OR ORDERING !!!

  // Addresses for factories and registries for different DEX platforms.
  // Functions will be added to allow to alter these when needed.
  address[] public swapFactories;
  // Symbols for detecting platforms
  string[] public swapLpNames;

  //Key tokens are used to find liquidity for any given token on Swap platforms.
  address[] public keyTokens;

  mapping(address => address) public replacementTokens;

  mapping(address => bool) public allowedFactories;

  // ********** EVENTS ****************************

  event DefaultTokenChanged(address oldToken, address newToken);
  event KeyTokenAdded(address newKeyToken);
  event KeyTokenRemoved(address keyToken);
  event SwapPlatformAdded(address factoryAddress, string name);
  event SwapPlatformRemoved(address factoryAddress, string name);
  event ReplacementTokenUpdated(address token, address replacementToken);
  event MultipartTokenUpdated(address token, bool status);

  constructor() {
    assert(_DEFAULT_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.calculator.defaultToken")) - 1));
  }

  function initialize(address _controller) external initializer {
    ControllableV2.initializeControllable(_controller);
  }

  /// @dev Allow operation only for Controller or Governance
  modifier onlyControllerOrGovernance() {
    require(_isController(msg.sender) || _isGovernance(msg.sender), "Not controller or gov");
    _;
  }

  function getPriceWithDefaultOutput(address token) external view override returns (uint256) {
    return getPrice(token, defaultToken());
  }

  //Main function of the contract. Gives the price of a given token in the defined output token.
  //The contract allows for input tokens to be LP tokens from Uniswap forks.
  //In case of LP token, the underlying tokens will be found and valued to get the price.
  // Output token should exist int the keyTokenList
  function getPrice(address token, address outputToken) public view override returns (uint256) {

    if (token == outputToken) {
      return (10 ** PRECISION_DECIMALS);
    }

    uint256 rate = 1;
    uint256 rateDenominator = 1;
    // check if it is a vault need to return the underlying price
    if (IController(_controller()).vaults(token)) {
      rate = ISmartVault(token).getPricePerFullShare();
      token = ISmartVault(token).underlying();
      rateDenominator = 10 ** IERC20Extended(token).decimals();
      // some vaults can have another vault as underlying
      if (IController(_controller()).vaults(token)) {
        rate = rate * ISmartVault(token).getPricePerFullShare();
        token = ISmartVault(token).underlying();
        rateDenominator = rateDenominator * (10 ** IERC20Extended(token).decimals());
      }
    }

    // if the token exists in the mapping, we'll swap it for the replacement
    // example amBTC/renBTC pool -> wbtc
    if (replacementTokens[token] != address(0)) {
      token = replacementTokens[token];
    }

    uint256 price;
    if (isSwapPlatform(token)) {
      address[2] memory tokens;
      uint256[2] memory amounts;
      (tokens, amounts) = getLpUnderlying(token);
      for (uint256 i = 0; i < 2; i++) {
        address[] memory usedLps = new address[](DEPTH);
        uint256 priceToken = computePrice(tokens[i], outputToken, usedLps, 0);
        if (priceToken == 0) {
          return 0;
        }
        uint256 tokenValue = priceToken * amounts[i] / 10 ** PRECISION_DECIMALS;
        price += tokenValue;
      }
    } else if (isIronPair(token)) {
      price = IIronSwap(IIronLpToken(token).swap()).getVirtualPrice();
    } else if (token == CRV_USD_BTC_ETH_FANTOM || token == CRV_USD_BTC_ETH_MATIC) {
      ICurveMinter minter = ICurveMinter(ICurveLpToken(token).minter());
      uint tvl = 0;
      for (uint256 i = 0; i < 3; i++) {
        address coin = minter.coins(i);
        uint balance = normalizePrecision(minter.balances(i), IERC20Extended(coin).decimals());
        uint256 priceToken = getPrice(coin, outputToken);
        if (priceToken == 0) {
          return 0;
        }

        uint256 tokenValue = priceToken * balance / 10 ** PRECISION_DECIMALS;
        tvl += tokenValue;
      }
      price = tvl * (10 ** PRECISION_DECIMALS)
      / normalizePrecision(IERC20Extended(token).totalSupply(), IERC20Extended(token).decimals());

    } else if (isAave(token)) {
      address aToken = unwrapAaveIfNecessary(token);
      address[] memory usedLps = new address[](DEPTH);
      price = computePrice(IAaveToken(aToken).UNDERLYING_ASSET_ADDRESS(), outputToken, usedLps, 0);
      // add wrapped ratio if necessary
      if (token != aToken) {
        uint ratio = IWrappedAaveToken(token).staticToDynamicAmount(10 ** PRECISION_DECIMALS);
        price = price * ratio / (10 ** PRECISION_DECIMALS);
      } else {
        uint ratio = IAaveToken(aToken).totalSupply() * (10 ** PRECISION_DECIMALS) / IAaveToken(aToken).scaledTotalSupply();
        price = price * ratio / (10 ** PRECISION_DECIMALS);
      }
    } else if (isBPT(token)) {
      price = calculateBPTPrice(token, outputToken);
    } else {
      address[] memory usedLps = new address[](DEPTH);
      price = computePrice(token, outputToken, usedLps, 0);
    }

    return price * rate / rateDenominator;
  }

  function isSwapPlatform(address token) public view returns (bool) {
    address factory;
    //slither-disable-next-line unused-return,variable-scope,uninitialized-local
    try IUniswapV2Pair(token).factory{gas : 3000}() returns (address _factory) {
      factory = _factory;
    } catch {}

    return allowedFactories[factory];
  }

  function isIronPair(address token) public view returns (bool) {
    return isEqualString(IERC20Extended(token).name(), IS3USD) || isEqualString(IERC20Extended(token).name(), IRON_IS3USD);
  }

  function isAave(address token) public view returns (bool) {
    try IAaveToken(token).UNDERLYING_ASSET_ADDRESS{gas : 60000}() returns (address) {
      return true;
    } catch {}
    return false;
  }

  function unwrapAaveIfNecessary(address token) public view returns (address) {
    try IWrappedAaveToken(token).ATOKEN{gas : 60000}() returns (address aToken) {
      return aToken;
    } catch {}
    return token;
  }

  function isBPT(address token) public view returns (bool) {
    IBPT bpt = IBPT(token);
    try bpt.getVault{gas : 3000}() returns (address vault){
      return (vault == BEETHOVEN_VAULT_FANTOM
      || vault == BALANCER_VAULT_ETHEREUM);
    } catch {}
    return false;
  }

  /* solhint-disable no-unused-vars */
  function checkFactory(IUniswapV2Pair pair, address compareFactory) public view returns (bool) {
    //slither-disable-next-line unused-return,variable-scope,uninitialized-local
    try pair.factory{gas : 3000}() returns (address factory) {
      bool check = (factory == compareFactory) ? true : false;
      return check;
    } catch {}
    return false;
  }

  //Get underlying tokens and amounts for LP
  function getLpUnderlying(address lpAddress) public view returns (address[2] memory, uint256[2] memory) {
    IUniswapV2Pair lp = IUniswapV2Pair(lpAddress);
    address[2] memory tokens;
    uint256[2] memory amounts;
    tokens[0] = lp.token0();
    tokens[1] = lp.token1();
    uint256 token0Decimals = IERC20Extended(tokens[0]).decimals();
    uint256 token1Decimals = IERC20Extended(tokens[1]).decimals();
    uint256 supplyDecimals = lp.decimals();
    (uint256 reserve0, uint256 reserve1,) = lp.getReserves();
    uint256 totalSupply = lp.totalSupply();
    if (reserve0 == 0 || reserve1 == 0 || totalSupply == 0) {
      amounts[0] = 0;
      amounts[1] = 0;
      return (tokens, amounts);
    }
    amounts[0] = reserve0 * 10 ** (supplyDecimals - token0Decimals + PRECISION_DECIMALS) / totalSupply;
    amounts[1] = reserve1 * 10 ** (supplyDecimals - token1Decimals + PRECISION_DECIMALS) / totalSupply;
    return (tokens, amounts);
  }

  //General function to compute the price of a token vs the defined output token.
  function computePrice(address token, address outputToken, address[] memory usedLps, uint256 deep)
  public view returns (uint256) {
    if (token == outputToken) {
      return 10 ** PRECISION_DECIMALS;
    } else if (token == address(0)) {
      return 0;
    }

    require(deep < DEPTH, "PC: too deep");

    (address keyToken,, address lpAddress) = getLargestPool(token, usedLps);
    require(lpAddress != address(0), toAsciiString(token));
    usedLps[deep] = lpAddress;
    deep++;

    uint256 lpPrice = getPriceFromLp(lpAddress, token);
    uint256 keyTokenPrice = computePrice(keyToken, outputToken, usedLps, deep);
    return lpPrice * keyTokenPrice / 10 ** PRECISION_DECIMALS;
  }

  // Gives the LP with largest liquidity for a given token
  // and a given tokenset (either keyTokens or pricingTokens)
  function getLargestPool(address token, address[] memory usedLps)
  public override view returns (address, uint256, address) {
    uint256 largestLpSize = 0;
    address largestKeyToken = address(0);
    uint256 largestPlatformIdx = 0;
    address lpAddress = address(0);
    address[] memory _keyTokens = keyTokens;
    for (uint256 i = 0; i < _keyTokens.length; i++) {
      if (token == _keyTokens[i]) {
        continue;
      }
      for (uint256 j = 0; j < swapFactories.length; j++) {
        (uint256 poolSize, address lp) = getLpForFactory(swapFactories[j], token, _keyTokens[i]);

        if (arrayContains(usedLps, lp)) {
          continue;
        }

        if (poolSize > largestLpSize) {
          largestLpSize = poolSize;
          largestKeyToken = _keyTokens[i];
          largestPlatformIdx = j;
          lpAddress = lp;
        }
      }
    }

    // try to find in UNIv3
    if (lpAddress == address(0) && block.chainid == 1) {
      for (uint256 i = 0; i < _keyTokens.length; i++) {
        if (token == _keyTokens[i]) {
          continue;
        }

        (uint256 poolSize, address lp) = findLpInUniV3(token, _keyTokens[i]);

        if (arrayContains(usedLps, lp)) {
          continue;
        }

        if (poolSize > largestLpSize) {
          largestLpSize = poolSize;
          largestKeyToken = _keyTokens[i];
          largestPlatformIdx = type(uint).max;
          lpAddress = lp;
        }

      }
    }

    return (largestKeyToken, largestPlatformIdx, lpAddress);
  }

  function getLpForFactory(address _factory, address token, address tokenOpposite)
  public view returns (uint256, address){
    address pairAddress;
    // shortcut for firebird ice-weth
    if (_factory == FIREBIRD_FACTORY) {
      pairAddress = IFireBirdFactory(_factory).getPair(token, tokenOpposite, 50, 20);
    } else if (_factory == DYSTOPIA_FACTORY || _factory == CONE_FACTORY) {
      address sPair = IDystopiaFactory(_factory).getPair(token, tokenOpposite, true);
      address vPair = IDystopiaFactory(_factory).getPair(token, tokenOpposite, false);
      uint sReserve = getLpSize(sPair, token);
      uint vReserve = getLpSize(vPair, token);
      if (sReserve > vReserve) {
        return (sReserve, sPair);
      } else {
        return (vReserve, vPair);
      }
    } else {
      pairAddress = IUniswapV2Factory(_factory).getPair(token, tokenOpposite);
    }
    if (pairAddress != address(0)) {
      return (getLpSize(pairAddress, token), pairAddress);
    }
    return (0, address(0));
  }

  function findLpInUniV3(address token, address tokenOpposite)
  public view returns (uint256, address){

    address pairAddress;
    uint reserve;
    uint[] memory fees = new uint[](4);
    fees[0] = 100;
    fees[1] = 500;
    fees[2] = 3000;
    fees[3] = 10000;
    for (uint i; i < fees.length; ++i) {
      address pairAddressTmp = IUniFactoryV3(UNIV3_FACTORY_ETHEREUM).getPool(token, tokenOpposite, uint24(fees[i]));
      if (pairAddressTmp != address(0)) {
        uint reserveTmp = getUniV3Reserve(pairAddressTmp, token);
        if (reserveTmp > reserve) {
          pairAddress = pairAddressTmp;
          reserve = reserveTmp;
        }
      }
    }
    return (reserve, pairAddress);
  }

  function getUniV3Reserve(address pairAddress, address token) public view returns (uint) {
    return IERC20(token).balanceOf(pairAddress);
  }

  function getLpSize(address pairAddress, address token) public view returns (uint256) {
    if (pairAddress == address(0)) {
      return 0;
    }
    IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
    address token0 = pair.token0();
    (uint112 poolSize0, uint112 poolSize1,) = pair.getReserves();
    uint256 poolSize = (token == token0) ? poolSize0 : poolSize1;
    return poolSize;
  }

  //Generic function giving the price of a given token vs another given token on Swap platform.
  function getPriceFromLp(address lpAddress, address token) public override view returns (uint256) {
    address _factory = IUniswapV2Pair(lpAddress).factory();
    if (_factory == DYSTOPIA_FACTORY || _factory == CONE_FACTORY) {
      (address token0, address token1) = IDystopiaPair(lpAddress).tokens();
      uint256 tokenInDecimals = token == token0 ? IERC20Extended(token0).decimals() : IERC20Extended(token1).decimals();
      uint256 tokenOutDecimals = token == token1 ? IERC20Extended(token0).decimals() : IERC20Extended(token1).decimals();
      uint out = IDystopiaPair(lpAddress).getAmountOut(10 ** tokenInDecimals, token);
      return out * (10 ** PRECISION_DECIMALS) / (10 ** tokenOutDecimals);
    } else if (_factory == UNIV3_FACTORY_ETHEREUM) {
      address token0 = IUniPoolV3(lpAddress).token0();
      address token1 = IUniPoolV3(lpAddress).token1();

      uint256 tokenInDecimals = token == token0 ? IERC20Extended(token0).decimals() : IERC20Extended(token1).decimals();
      uint256 tokenOutDecimals = token == token1 ? IERC20Extended(token0).decimals() : IERC20Extended(token1).decimals();
      (uint160 sqrtPriceX96,,,,,,) = IUniPoolV3(lpAddress).slot0();

      uint divider = Math.max(10 ** tokenOutDecimals / 10 ** tokenInDecimals, 1);
      if (token == token0) {
        return uint(sqrtPriceX96) ** 2 / 2 ** 96 * 1e18 / 2 ** 96 / divider * 1e18 / (10 ** tokenOutDecimals);
      } else {
        return 2 ** 192 * 1e18 / uint(sqrtPriceX96) ** 2 / divider * 1e18 / (10 ** tokenOutDecimals);
      }
    } else {
      IUniswapV2Pair pair = IUniswapV2Pair(lpAddress);
      address token0 = pair.token0();
      address token1 = pair.token1();
      (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
      uint256 token0Decimals = IERC20Extended(token0).decimals();
      uint256 token1Decimals = IERC20Extended(token1).decimals();

      // both reserves should have the same decimals
      reserve0 = reserve0 * (10 ** PRECISION_DECIMALS) / (10 ** token0Decimals);
      reserve1 = reserve1 * (10 ** PRECISION_DECIMALS) / (10 ** token1Decimals);

      if (token == token0) {
        return reserve1 * (10 ** PRECISION_DECIMALS) / reserve0;
      } else if (token == token1) {
        return reserve0 * (10 ** PRECISION_DECIMALS) / reserve1;
      } else {
        revert("PC: token not in lp");
      }
    }
  }

  //Checks if a given token is in the keyTokens list.
  function isKeyToken(address token) public view returns (bool) {
    for (uint256 i = 0; i < keyTokens.length; i++) {
      if (token == keyTokens[i]) {
        return true;
      }
    }
    return false;
  }

  function isSwapFactoryToken(address adr) public view returns (bool) {
    for (uint256 i = 0; i < swapFactories.length; i++) {
      if (adr == swapFactories[i]) {
        return true;
      }
    }
    return false;
  }

  function isSwapName(string memory name) public view returns (bool) {
    for (uint256 i = 0; i < swapLpNames.length; i++) {
      if (isEqualString(name, swapLpNames[i])) {
        return true;
      }
    }
    return false;
  }

  function keyTokensSize() external view returns (uint256) {
    return keyTokens.length;
  }

  function swapFactoriesSize() external view returns (uint256) {
    return swapFactories.length;
  }

  // ************* INTERNAL *****************

  function toAsciiString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint(uint160(x)) / (2 ** (8 * (19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2 * i] = char(hi);
      s[2 * i + 1] = char(lo);
    }
    return string(s);
  }

  function char(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
  }

  function isEqualString(string memory arg1, string memory arg2) internal pure returns (bool) {
    bool check = (keccak256(abi.encodePacked(arg1)) == keccak256(abi.encodePacked(arg2))) ? true : false;
    return check;
  }

  function arrayContains(address[] memory usedLps, address lp) internal pure returns (bool) {
    for (uint256 d = 0; d < usedLps.length; d++) {
      if (usedLps[d] == lp) {
        return true;
      }
    }
    return false;
  }

  function removeFromKeyTokens(uint256 index) internal {
    require(index < keyTokens.length, "PC: wrong index");

    for (uint256 i = index; i < keyTokens.length - 1; i++) {
      keyTokens[i] = keyTokens[i + 1];
    }
    keyTokens.pop();
  }

  function removeFromSwapFactories(uint index) internal {
    require(index < swapFactories.length, "PC: wrong index");

    for (uint i = index; i < swapFactories.length - 1; i++) {
      swapFactories[i] = swapFactories[i + 1];
    }
    swapFactories.pop();
  }

  function removeFromSwapNames(uint index) internal {
    require(index < swapLpNames.length, "PC: wrong index");

    for (uint i = index; i < swapLpNames.length - 1; i++) {
      swapLpNames[i] = swapLpNames[i + 1];
    }
    swapLpNames.pop();
  }

  function defaultToken() public view returns (address value) {
    bytes32 slot = _DEFAULT_TOKEN_SLOT;
    assembly {
      value := sload(slot)
    }
  }

  function normalizePrecision(uint256 amount, uint256 decimals) internal pure returns (uint256){
    return amount * (10 ** PRECISION_DECIMALS) / (10 ** decimals);
  }

  function calculateBPTPrice(address token, address outputToken) internal view returns (uint256){
    IBPT bpt = IBPT(token);
    address balancerVault = bpt.getVault();
    bytes32 poolId = bpt.getPoolId();
    uint256 totalBPTSupply = bpt.totalSupply();
    (IERC20[] memory poolTokens, uint256[] memory balances,) = IBVault(balancerVault).getPoolTokens(poolId);

    uint256 totalPrice = 0;
    uint[] memory prices = new uint[](poolTokens.length);
    for (uint i = 0; i < poolTokens.length; i++) {
      uint256 tokenDecimals = IERC20Extended(address(poolTokens[i])).decimals();
      uint256 tokenPrice;
      if (token != address(poolTokens[i])) {
        if (prices[i] == 0) {
          tokenPrice = getPrice(address(poolTokens[i]), outputToken);
          prices[i] = tokenPrice;
        } else {
          tokenPrice = prices[i];
        }
      } else {
        // if token the same as BPT assume it has the same price as another one token in the pool
        uint ii = i == 0 ? 1 : 0;
        if (prices[ii] == 0) {
          tokenPrice = getPrice(address(poolTokens[ii]), outputToken);
          prices[ii] = tokenPrice;
        } else {
          tokenPrice = prices[ii];
        }
      }
      // unknown token price
      if (tokenPrice == 0) {
        return 0;
      }
      totalPrice = totalPrice + tokenPrice * balances[i] * 10 ** PRECISION_DECIMALS / 10 ** tokenDecimals;

    }
    return totalPrice / totalBPTSupply;
  }

  // ************* GOVERNANCE ACTIONS ***************

  function setDefaultToken(address _newDefaultToken) external onlyControllerOrGovernance {
    require(_newDefaultToken != address(0), "PC: zero address");
    emit DefaultTokenChanged(defaultToken(), _newDefaultToken);
    bytes32 slot = _DEFAULT_TOKEN_SLOT;
    assembly {
      sstore(slot, _newDefaultToken)
    }
  }

  function addKeyTokens(address[] memory newTokens) external onlyControllerOrGovernance {
    for (uint256 i = 0; i < newTokens.length; i++) {
      addKeyToken(newTokens[i]);
    }
  }

  function addKeyToken(address newToken) public onlyControllerOrGovernance {
    require(!isKeyToken(newToken), "PC: already have");
    keyTokens.push(newToken);
    emit KeyTokenAdded(newToken);
  }

  function removeKeyToken(address keyToken) external onlyControllerOrGovernance {
    require(isKeyToken(keyToken), "PC: not key");
    uint256 i;
    for (i = 0; i < keyTokens.length; i++) {
      if (keyToken == keyTokens[i]) {
        break;
      }
    }
    removeFromKeyTokens(i);
    emit KeyTokenRemoved(keyToken);
  }

  function addSwapPlatform(address _factoryAddress, string memory _name) external onlyControllerOrGovernance {
    for (uint256 i = 0; i < swapFactories.length; i++) {
      require(swapFactories[i] != _factoryAddress, "PC: factory already exist");
      require(!isEqualString(swapLpNames[i], _name), "PC: name already exist");
    }
    swapFactories.push(_factoryAddress);
    swapLpNames.push(_name);
    allowedFactories[_factoryAddress] = true;
    emit SwapPlatformAdded(_factoryAddress, _name);
  }

  function changeFactoriesStatus(address[] memory factories, bool status) external onlyControllerOrGovernance {
    for (uint256 i; i < factories.length; i++) {
      allowedFactories[factories[i]] = status;
    }
  }

  function removeSwapPlatform(address _factoryAddress, string memory _name) external onlyControllerOrGovernance {
    require(isSwapFactoryToken(_factoryAddress), "PC: swap not exist");
    require(isSwapName(_name), "PC: name not exist");
    uint256 i;
    for (i = 0; i < swapFactories.length; i++) {
      if (_factoryAddress == swapFactories[i]) {
        break;
      }
    }
    removeFromSwapFactories(i);

    for (i = 0; i < swapLpNames.length; i++) {
      if (isEqualString(_name, swapLpNames[i])) {
        break;
      }
    }
    removeFromSwapNames(i);
    emit SwapPlatformRemoved(_factoryAddress, _name);
  }

  function setReplacementTokens(address _inputToken, address _replacementToken)
  external onlyControllerOrGovernance {
    replacementTokens[_inputToken] = _replacementToken;
    emit ReplacementTokenUpdated(_inputToken, _replacementToken);
  }
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IPriceCalculator {

  function getPrice(address token, address outputToken) external view returns (uint256);

  function getPriceWithDefaultOutput(address token) external view returns (uint256);

  function getLargestPool(address token, address[] memory usedLps) external view returns (address, uint256, address);

  function getPriceFromLp(address lpAddress, address token) external view returns (uint256);

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "../../openzeppelin/Initializable.sol";
import "../interface/IControllable.sol";
import "../interface/IControllableExtended.sol";
import "../interface/IController.sol";

/// @title Implement basic functionality for any contract that require strict control
///        V2 is optimised version for less gas consumption
/// @dev Can be used with upgradeable pattern.
///      Require call initializeControllable() in any case.
/// @author belbix
abstract contract ControllableV2 is Initializable, IControllable, IControllableExtended {

  bytes32 internal constant _CONTROLLER_SLOT = bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1);
  bytes32 internal constant _CREATED_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created")) - 1);
  bytes32 internal constant _CREATED_BLOCK_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created_block")) - 1);

  event ContractInitialized(address controller, uint ts, uint block);

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param __controller Controller address
  function initializeControllable(address __controller) public initializer {
    _setController(__controller);
    _setCreated(block.timestamp);
    _setCreatedBlock(block.number);
    emit ContractInitialized(__controller, block.timestamp, block.number);
  }

  /// @dev Return true if given address is controller
  function isController(address _value) external override view returns (bool) {
    return _isController(_value);
  }

  function _isController(address _value) internal view returns (bool) {
    return _value == _controller();
  }

  /// @notice Return true if given address is setup as governance in Controller
  function isGovernance(address _value) external override view returns (bool) {
    return _isGovernance(_value);
  }

  function _isGovernance(address _value) internal view returns (bool) {
    return IController(_controller()).governance() == _value;
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  function controller() external view override returns (address) {
    return _controller();
  }

  function _controller() internal view returns (address result) {
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Set a controller address to contract slot
  function _setController(address _newController) private {
    require(_newController != address(0));
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      sstore(slot, _newController)
    }
  }

  /// @notice Return creation timestamp
  /// @return ts Creation timestamp
  function created() external view override returns (uint256 ts) {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      ts := sload(slot)
    }
  }

  /// @dev Filled only once when contract initialized
  /// @param _value block.timestamp
  function _setCreated(uint256 _value) private {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      sstore(slot, _value)
    }
  }

  /// @notice Return creation block number
  /// @return ts Creation block number
  function createdBlock() external view returns (uint256 ts) {
    bytes32 slot = _CREATED_BLOCK_SLOT;
    assembly {
      ts := sload(slot)
    }
  }

  /// @dev Filled only once when contract initialized
  /// @param _value block.number
  function _setCreatedBlock(uint256 _value) private {
    bytes32 slot = _CREATED_BLOCK_SLOT;
    assembly {
      sstore(slot, _value)
    }
  }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function allPairs(uint) external view returns (address pair);

  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint);

  function balanceOf(address owner) external view returns (uint);

  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);

  function transfer(address to, uint value) external returns (bool);

  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint amount0In,
    uint amount1In,
    uint amount0Out,
    uint amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

  function price0CumulativeLast() external view returns (uint);

  function price1CumulativeLast() external view returns (uint);

  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);

  function burn(address to) external returns (uint amount0, uint amount1);

  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;


interface IUniPoolV3 {
  event Burn(
    address indexed owner,
    int24 indexed tickLower,
    int24 indexed tickUpper,
    uint128 amount,
    uint256 amount0,
    uint256 amount1
  );
  event Collect(
    address indexed owner,
    address recipient,
    int24 indexed tickLower,
    int24 indexed tickUpper,
    uint128 amount0,
    uint128 amount1
  );
  event CollectProtocol(
    address indexed sender,
    address indexed recipient,
    uint128 amount0,
    uint128 amount1
  );
  event Flash(
    address indexed sender,
    address indexed recipient,
    uint256 amount0,
    uint256 amount1,
    uint256 paid0,
    uint256 paid1
  );
  event IncreaseObservationCardinalityNext(
    uint16 observationCardinalityNextOld,
    uint16 observationCardinalityNextNew
  );
  event Initialize(uint160 sqrtPriceX96, int24 tick);
  event Mint(
    address sender,
    address indexed owner,
    int24 indexed tickLower,
    int24 indexed tickUpper,
    uint128 amount,
    uint256 amount0,
    uint256 amount1
  );
  event SetFeeProtocol(
    uint8 feeProtocol0Old,
    uint8 feeProtocol1Old,
    uint8 feeProtocol0New,
    uint8 feeProtocol1New
  );
  event Swap(
    address indexed sender,
    address indexed recipient,
    int256 amount0,
    int256 amount1,
    uint160 sqrtPriceX96,
    uint128 liquidity,
    int24 tick
  );

  function burn(
    int24 tickLower,
    int24 tickUpper,
    uint128 amount
  ) external returns (uint256 amount0, uint256 amount1);

  function collect(
    address recipient,
    int24 tickLower,
    int24 tickUpper,
    uint128 amount0Requested,
    uint128 amount1Requested
  ) external returns (uint128 amount0, uint128 amount1);

  function collectProtocol(
    address recipient,
    uint128 amount0Requested,
    uint128 amount1Requested
  ) external returns (uint128 amount0, uint128 amount1);

  function factory() external view returns (address);

  function fee() external view returns (uint24);

  function feeGrowthGlobal0X128() external view returns (uint256);

  function feeGrowthGlobal1X128() external view returns (uint256);

  function flash(
    address recipient,
    uint256 amount0,
    uint256 amount1,
    bytes memory data
  ) external;

  function increaseObservationCardinalityNext(
    uint16 observationCardinalityNext
  ) external;

  function initialize(uint160 sqrtPriceX96) external;

  function liquidity() external view returns (uint128);

  function maxLiquidityPerTick() external view returns (uint128);

  function mint(
    address recipient,
    int24 tickLower,
    int24 tickUpper,
    uint128 amount,
    bytes memory data
  ) external returns (uint256 amount0, uint256 amount1);

  function observations(uint256)
  external
  view
  returns (
    uint32 blockTimestamp,
    int56 tickCumulative,
    uint160 secondsPerLiquidityCumulativeX128,
    bool initialized
  );

  function observe(uint32[] memory secondsAgos)
  external
  view
  returns (
    int56[] memory tickCumulatives,
    uint160[] memory secondsPerLiquidityCumulativeX128s
  );

  function positions(bytes32)
  external
  view
  returns (
    uint128 _liquidity,
    uint256 feeGrowthInside0LastX128,
    uint256 feeGrowthInside1LastX128,
    uint128 tokensOwed0,
    uint128 tokensOwed1
  );

  function protocolFees()
  external
  view
  returns (uint128 _token0, uint128 _token1);

  function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

  function slot0()
  external
  view
  returns (
    uint160 sqrtPriceX96,
    int24 tick,
    uint16 observationIndex,
    uint16 observationCardinality,
    uint16 observationCardinalityNext,
    uint8 feeProtocol,
    bool unlocked
  );

  function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
  external
  view
  returns (
    int56 tickCumulativeInside,
    uint160 secondsPerLiquidityInsideX128,
    uint32 secondsInside
  );

  function swap(
    address recipient,
    bool zeroForOne,
    int256 amountSpecified,
    uint160 sqrtPriceLimitX96,
    bytes memory data
  ) external returns (int256 amount0, int256 amount1);

  function tickBitmap(int16) external view returns (uint256);

  function tickSpacing() external view returns (int24);

  function ticks(int24)
  external
  view
  returns (
    uint128 liquidityGross,
    int128 liquidityNet,
    uint256 feeGrowthOutside0X128,
    uint256 feeGrowthOutside1X128,
    int56 tickCumulativeOutside,
    uint160 secondsPerLiquidityOutsideX128,
    uint32 secondsOutside,
    bool initialized
  );

  function token0() external view returns (address);

  function token1() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IUniFactoryV3 {
  event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);
  event OwnerChanged(address indexed oldOwner, address indexed newOwner);
  event PoolCreated(
    address indexed token0,
    address indexed token1,
    uint24 indexed fee,
    int24 tickSpacing,
    address pool
  );

  function createPool(
    address tokenA,
    address tokenB,
    uint24 fee
  ) external returns (address pool);

  function enableFeeAmount(uint24 fee, int24 tickSpacing) external;

  function feeAmountTickSpacing(uint24) external view returns (int24);

  function getPool(
    address,
    address,
    uint24
  ) external view returns (address);

  function owner() external view returns (address);

  function parameters()
  external
  view
  returns (
    address factory,
    address token0,
    address token1,
    uint24 fee,
    int24 tickSpacing
  );

  function setOwner(address _owner) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

interface IFireBirdPair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;


  event PaidProtocolFee(uint112 collectedFee0, uint112 collectedFee1);
  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint amount0In,
    uint amount1In,
    uint amount0Out,
    uint amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function getCollectedFees() external view returns (uint112 _collectedFee0, uint112 _collectedFee1);
  function getTokenWeights() external view returns (uint32 tokenWeight0, uint32 tokenWeight1);
  function getSwapFee() external view returns (uint32);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;

  function initialize(address, address, uint32, uint32) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

interface IFireBirdFactory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint32 tokenWeight0, uint32 swapFee, uint);

  function feeTo() external view returns (address);

  function formula() external view returns (address);

  function protocolFee() external view returns (uint);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB, uint32 tokenWeightA, uint32 swapFee) external view returns (address pair);

  function allPairs(uint) external view returns (address pair);

  function isPair(address) external view returns (bool);

  function allPairsLength() external view returns (uint);

  function createPair(address tokenA, address tokenB, uint32 tokenWeightA, uint32 swapFee) external returns (address pair);

  function getWeightsAndSwapFee(address pair) external view returns (uint32 tokenWeight0, uint32 tokenWeight1, uint32 swapFee);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;

  function setProtocolFee(uint) external;
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface ISmartVault {

  function DEPOSIT_FEE_DENOMINATOR() external view returns (uint256);

  function LOCK_PENALTY_DENOMINATOR() external view returns (uint256);

  function TO_INVEST_DENOMINATOR() external view returns (uint256);

  function VERSION() external view returns (string memory);

  function active() external view returns (bool);

  function addRewardToken(address rt) external;

  function alwaysInvest() external view returns (bool);

  function availableToInvestOut() external view returns (uint256);

  function changeActivityStatus(bool _active) external;

  function changeAlwaysInvest(bool _active) external;

  function changeDoHardWorkOnInvest(bool _active) external;

  function changePpfsDecreaseAllowed(bool _value) external;

  function changeProtectionMode(bool _active) external;

  function deposit(uint256 amount) external;

  function depositAndInvest(uint256 amount) external;

  function depositFeeNumerator() external view returns (uint256);

  function depositFor(uint256 amount, address holder) external;

  function disableLock() external;

  function doHardWork() external;

  function doHardWorkOnInvest() external view returns (bool);

  function duration() external view returns (uint256);

  function earned(address rt, address account)
  external
  view
  returns (uint256);

  function earnedWithBoost(address rt, address account)
  external
  view
  returns (uint256);

  function exit() external;

  function getAllRewards() external;

  function getAllRewardsAndRedirect(address owner) external;

  function getPricePerFullShare() external view returns (uint256);

  function getReward(address rt) external;

  function getRewardTokenIndex(address rt) external view returns (uint256);

  function initializeSmartVault(
    string memory _name,
    string memory _symbol,
    address _controller,
    address __underlying,
    uint256 _duration,
    bool _lockAllowed,
    address _rewardToken,
    uint256 _depositFee
  ) external;

  function lastTimeRewardApplicable(address rt)
  external
  view
  returns (uint256);

  function lastUpdateTimeForToken(address) external view returns (uint256);

  function lockAllowed() external view returns (bool);

  function lockPenalty() external view returns (uint256);

  function notifyRewardWithoutPeriodChange(
    address _rewardToken,
    uint256 _amount
  ) external;

  function notifyTargetRewardAmount(address _rewardToken, uint256 amount)
  external;

  function overrideName(string memory value) external;

  function overrideSymbol(string memory value) external;

  function periodFinishForToken(address) external view returns (uint256);

  function ppfsDecreaseAllowed() external view returns (bool);

  function protectionMode() external view returns (bool);

  function rebalance() external;

  function removeRewardToken(address rt) external;

  function rewardPerToken(address rt) external view returns (uint256);

  function rewardPerTokenStoredForToken(address)
  external
  view
  returns (uint256);

  function rewardRateForToken(address) external view returns (uint256);

  function rewardTokens() external view returns (address[] memory);

  function rewardTokensLength() external view returns (uint256);

  function rewardsForToken(address, address) external view returns (uint256);

  function setLockPenalty(uint256 _value) external;

  function setRewardsRedirect(address owner, address receiver) external;

  function setLockPeriod(uint256 _value) external;

  function setStrategy(address newStrategy) external;

  function setToInvest(uint256 _value) external;

  function stop() external;

  function strategy() external view returns (address);

  function toInvest() external view returns (uint256);

  function underlying() external view returns (address);

  function underlyingBalanceInVault() external view returns (uint256);

  function underlyingBalanceWithInvestment() external view returns (uint256);

  function underlyingBalanceWithInvestmentForHolder(address holder)
  external
  view
  returns (uint256);

  function underlyingUnit() external view returns (uint256);

  function userBoostTs(address) external view returns (uint256);

  function userLastDepositTs(address) external view returns (uint256);

  function userLastWithdrawTs(address) external view returns (uint256);

  function userLockTs(address) external view returns (uint256);

  function userRewardPerTokenPaidForToken(address, address)
  external
  view
  returns (uint256);

  function withdraw(uint256 numberOfShares) external;

  function withdrawAllToVault() external;

  function getAllRewardsFor(address rewardsReceiver) external;

  function lockPeriod() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "../../openzeppelin/IERC20.sol";

interface IIronSwap {
  /// EVENTS
  event AddLiquidity(
    address indexed provider,
    uint256[] tokenAmounts,
    uint256[] fees,
    uint256 invariant,
    uint256 tokenSupply
  );

  event TokenExchange(
    address indexed buyer,
    uint256 soldId,
    uint256 tokensSold,
    uint256 boughtId,
    uint256 tokensBought
  );

  event RemoveLiquidity(address indexed provider, uint256[] tokenAmounts, uint256[] fees, uint256 tokenSupply);

  event RemoveLiquidityOne(address indexed provider, uint256 tokenIndex, uint256 tokenAmount, uint256 coinAmount);

  event RemoveLiquidityImbalance(
    address indexed provider,
    uint256[] tokenAmounts,
    uint256[] fees,
    uint256 invariant,
    uint256 tokenSupply
  );

  event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);

  event StopRampA(uint256 A, uint256 timestamp);

  event NewFee(uint256 fee, uint256 adminFee, uint256 withdrawFee);

  event CollectProtocolFee(address token, uint256 amount);

  event FeeControllerChanged(address newController);

  event FeeDistributorChanged(address newController);

  // pool data view functions
  function getLpToken() external view returns (IERC20 lpToken);

  function getA() external view returns (uint256);

  function getAPrecise() external view returns (uint256);

  function getToken(uint8 index) external view returns (IERC20);

  function getTokens() external view returns (IERC20[] memory);

  function getTokenIndex(address tokenAddress) external view returns (uint8);

  function getTokenBalance(uint8 index) external view returns (uint256);

  function getTokenBalances() external view returns (uint256[] memory);

  function getNumberOfTokens() external view returns (uint256);

  function getVirtualPrice() external view returns (uint256);

  function calculateTokenAmount(uint256[] calldata amounts, bool deposit) external view returns (uint256);

  function calculateSwap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx
  ) external view returns (uint256);

  function calculateRemoveLiquidity(address account, uint256 amount) external view returns (uint256[] memory);

  function calculateRemoveLiquidityOneToken(
    address account,
    uint256 tokenAmount,
    uint8 tokenIndex
  ) external view returns (uint256 availableTokenAmount);

  function getAdminBalances() external view returns (uint256[] memory adminBalances);

  function getAdminBalance(uint8 index) external view returns (uint256);

  function calculateCurrentWithdrawFee(address account) external view returns (uint256);

  // state modifying functions
  function swap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256 minDy,
    uint256 deadline
  ) external returns (uint256);

  function addLiquidity(
    uint256[] calldata amounts,
    uint256 minToMint,
    uint256 deadline
  ) external returns (uint256);

  function removeLiquidity(
    uint256 amount,
    uint256[] calldata minAmounts,
    uint256 deadline
  ) external returns (uint256[] memory);

  function removeLiquidityOneToken(
    uint256 tokenAmount,
    uint8 tokenIndex,
    uint256 minAmount,
    uint256 deadline
  ) external returns (uint256);

  function removeLiquidityImbalance(
    uint256[] calldata amounts,
    uint256 maxBurnAmount,
    uint256 deadline
  ) external returns (uint256);

  function updateUserWithdrawFee(address recipient, uint256 transferAmount) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

interface IIronLpToken {

  function swap() external view returns (address);

}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.4;

interface ICurveLpToken {

  function minter() external view returns (address);

}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.4;

interface ICurveMinter {
  function coins(uint256 i) external view returns (address);

  function balances(uint256 i) external view returns (uint256);

  function lp_token() external view returns (address);

  function get_virtual_price() external view returns (uint);

  function add_liquidity(uint256[] calldata amounts, uint256 min_mint_amount, bool use_underlying) external;

  function add_liquidity(uint256[] calldata amounts, uint256 min_mint_amount) external;

  function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn_amount, bool use_underlying) external;

  function remove_liquidity(uint256 _amount, uint256[3] calldata amounts, bool use_underlying) external;

  function exchange(int128 from, int128 to, uint256 _from_amount, uint256 _min_to_amount) external;

  function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external;

  function calc_token_amount(uint256[3] calldata amounts, bool deposit) external view returns (uint);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IERC20Extended {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);


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

pragma solidity 0.8.4;

interface IAaveToken {
  function scaledTotalSupply() external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function UNDERLYING_ASSET_ADDRESS() external view returns (address);

}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.4;

interface IWrappedAaveToken {

  function ATOKEN() external view returns (address);

  function staticToDynamicAmount(uint value) external view returns (uint);

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

/// @dev lite version of BPT token
interface IBPT {
    function getNormalizedWeights() external view returns (uint256[] memory);
    function getVault() external view returns (address);
    function getPoolId() external view returns (bytes32);
    function totalSupply() external view returns (uint256);
    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: ISC
pragma solidity 0.8.4;

import "../../openzeppelin/IERC20.sol";


interface IAsset {
}

interface IBVault {
  // Internal Balance
  //
  // Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
  // transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
  // when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
  // gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
  //
  // Internal Balance management features batching, which means a single contract call can be used to perform multiple
  // operations of different kinds, with different senders and recipients, at once.

  /**
   * @dev Returns `user`'s Internal Balance for a set of tokens.
     */
  function getInternalBalance(address user, IERC20[] calldata tokens) external view returns (uint256[] memory);

  /**
   * @dev Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
     * and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
     * it lets integrators reuse a user's Vault allowance.
     *
     * For each operation, if the caller is not `sender`, it must be an authorized relayer for them.
     */
  function manageUserBalance(UserBalanceOp[] calldata ops) external payable;

  /**
   * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     without manual WETH wrapping or unwrapping.
     */
  struct UserBalanceOp {
    UserBalanceOpKind kind;
    IAsset asset;
    uint256 amount;
    address sender;
    address payable recipient;
  }

  // There are four possible operations in `manageUserBalance`:
  //
  // - DEPOSIT_INTERNAL
  // Increases the Internal Balance of the `recipient` account by transferring tokens from the corresponding
  // `sender`. The sender must have allowed the Vault to use their tokens via `IERC20.approve()`.
  //
  // ETH can be used by passing the ETH sentinel value as the asset and forwarding ETH in the call: it will be wrapped
  // and deposited as WETH. Any ETH amount remaining will be sent back to the caller (not the sender, which is
  // relevant for relayers).
  //
  // Emits an `InternalBalanceChanged` event.
  //
  //
  // - WITHDRAW_INTERNAL
  // Decreases the Internal Balance of the `sender` account by transferring tokens to the `recipient`.
  //
  // ETH can be used by passing the ETH sentinel value as the asset. This will deduct WETH instead, unwrap it and send
  // it to the recipient as ETH.
  //
  // Emits an `InternalBalanceChanged` event.
  //
  //
  // - TRANSFER_INTERNAL
  // Transfers tokens from the Internal Balance of the `sender` account to the Internal Balance of `recipient`.
  //
  // Reverts if the ETH sentinel value is passed.
  //
  // Emits an `InternalBalanceChanged` event.
  //
  //
  // - TRANSFER_EXTERNAL
  // Transfers tokens from `sender` to `recipient`, using the Vault's ERC20 allowance. This is typically used by
  // relayers, as it lets them reuse a user's Vault allowance.
  //
  // Reverts if the ETH sentinel value is passed.
  //
  // Emits an `ExternalBalanceTransfer` event.

  enum UserBalanceOpKind {DEPOSIT_INTERNAL, WITHDRAW_INTERNAL, TRANSFER_INTERNAL, TRANSFER_EXTERNAL}

  /**
   * @dev Emitted when a user's Internal Balance changes, either from calls to `manageUserBalance`, or through
     * interacting with Pools using Internal Balance.
     *
     * Because Internal Balance works exclusively with ERC20 tokens, ETH deposits and withdrawals will use the WETH
     * address.
     */
  event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);

  /**
   * @dev Emitted when a user's Vault ERC20 allowance is used by the Vault to transfer tokens to an external account.
     */
  event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

  // Pools
  //
  // There are three specialization settings for Pools, which allow for cheaper swaps at the cost of reduced
  // functionality:
  //
  //  - General: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
  // balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
  // which increase with the number of registered tokens.
  //
  //  - Minimal Swap Info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
  // balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
  // constant product one popularized by Balancer V1. Swap costs are smaller compared to general Pools, and are
  // independent of the number of registered tokens.
  //
  //  - Two Token: only allows two tokens to be registered. This achieves the lowest possible swap gas cost. Like
  // minimal swap info Pools, these are called via IMinimalSwapInfoPool.

  enum PoolSpecialization {GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN}

  /**
   * @dev Registers the caller account as a Pool with a given specialization setting. Returns the Pool's ID, which
     * is used in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be
     * changed.
     *
     * The caller is expected to be a smart contract that implements either `IGeneralPool` or `IMinimalSwapInfoPool`,
     * depending on the chosen specialization setting. This contract is known as the Pool's contract.
     *
     * Note that the same contract may register itself as multiple Pools with unique Pool IDs, or in other words,
     * multiple Pools may share the same contract.
     *
     * Emits a `PoolRegistered` event.
     */
  function registerPool(PoolSpecialization specialization) external returns (bytes32);

  /**
   * @dev Emitted when a Pool is registered by calling `registerPool`.
     */
  event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

  /**
   * @dev Returns a Pool's contract address and specialization setting.
     */
  function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

  /**
   * @dev Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
     * exit by receiving registered tokens, and can only swap registered tokens.
     *
     * Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
     * of two, that is, both tokens must be registered in the same `registerTokens` call, and they must be sorted in
     * ascending order.
     *
     * The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
     * Manager for the corresponding token. Asset Managers can manage a Pool's tokens via `managePoolBalance`,
     * depositing and withdrawing them directly, and can even set their balance to arbitrary amounts. They are therefore
     * expected to be highly secured smart contracts with sound design principles, and the decision to register an
     * Asset Manager should not be made lightly.
     *
     * Pools can choose not to assign an Asset Manager to a given token by passing in the zero address. Once an Asset
     * Manager is set, it cannot be changed except by deregistering the associated token and registering again with a
     * different Asset Manager.
     *
     * Emits a `TokensRegistered` event.
     */
  function registerTokens(
    bytes32 poolId,
    IERC20[] calldata tokens,
    address[] calldata assetManagers
  ) external;

  /**
   * @dev Emitted when a Pool registers tokens by calling `registerTokens`.
     */
  event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

  /**
   * @dev Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
     * balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
     * must be deregistered in the same `deregisterTokens` call.
     *
     * A deregistered token can be re-registered later on, possibly with a different Asset Manager.
     *
     * Emits a `TokensDeregistered` event.
     */
  function deregisterTokens(bytes32 poolId, IERC20[] calldata tokens) external;

  /**
   * @dev Emitted when a Pool deregisters tokens by calling `deregisterTokens`.
     */
  event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

  /**
   * @dev Returns detailed information for a Pool's registered token.
     *
     * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
     * withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
     * equals the sum of `cash` and `managed`.
     *
     * Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
     * `managed` or `total` balance to be greater than 2^112 - 1.
     *
     * `lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
     * join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
     * example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
     * change for this purpose, and will update `lastChangeBlock`.
     *
     * `assetManager` is the Pool's token Asset Manager.
     */
  function getPoolTokenInfo(bytes32 poolId, IERC20 token)
  external
  view
  returns (
    uint256 cash,
    uint256 managed,
    uint256 lastChangeBlock,
    address assetManager
  );

  /**
   * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
     * the tokens' `balances` changed.
     *
     * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
     * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to `registerTokens`.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
     * instead.
     */
  function getPoolTokens(bytes32 poolId)
  external
  view
  returns (
    IERC20[] memory tokens,
    uint256[] memory balances,
    uint256 lastChangeBlock
  );

  /**
   * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
  function joinPool(
    bytes32 poolId,
    address sender,
    address recipient,
    JoinPoolRequest calldata request
  ) external payable;

  enum JoinKind {INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT}
  enum ExitKind {EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT}

  struct JoinPoolRequest {
    IAsset[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
  }

  /**
   * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
  function exitPool(
    bytes32 poolId,
    address sender,
    address payable recipient,
    ExitPoolRequest calldata request
  ) external;

  struct ExitPoolRequest {
    IAsset[] assets;
    uint256[] minAmountsOut;
    bytes userData;
    bool toInternalBalance;
  }

  /**
   * @dev Emitted when a user joins or exits a Pool by calling `joinPool` or `exitPool`, respectively.
     */
  event PoolBalanceChanged(
    bytes32 indexed poolId,
    address indexed liquidityProvider,
    IERC20[] tokens,
    int256[] deltas,
    uint256[] protocolFeeAmounts
  );

  enum PoolBalanceChangeKind {JOIN, EXIT}

  // Swaps
  //
  // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
  // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
  // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
  //
  // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
  // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
  // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
  // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
  // individual swaps.
  //
  // There are two swap kinds:
  //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
  // `onSwap` hook) the amount of tokens out (to send to the recipient).
  //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
  // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
  //
  // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
  // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
  // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
  // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
  // the final intended token.
  //
  // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
  // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
  // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
  // much less gas than they would otherwise.
  //
  // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
  // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
  // updating the Pool's internal accounting).
  //
  // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
  // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
  // minimum amount of tokens to receive (by passing a negative value) is specified.
  //
  // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
  // this point in time (e.g. if the transaction failed to be included in a block promptly).
  //
  // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
  // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
  // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
  // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
  //
  // Finally, Internal Balance can be used when either sending or receiving tokens.

  enum SwapKind {GIVEN_IN, GIVEN_OUT}

  /**
   * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
  function swap(
    SingleSwap calldata singleSwap,
    FundManagement calldata funds,
    uint256 limit,
    uint256 deadline
  ) external payable returns (uint256);

  /**
   * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
  struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    IAsset assetIn;
    IAsset assetOut;
    uint256 amount;
    bytes userData;
  }

  /**
   * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
  function batchSwap(
    SwapKind kind,
    BatchSwapStep[] calldata swaps,
    IAsset[] calldata assets,
    FundManagement calldata funds,
    int256[] calldata limits,
    uint256 deadline
  ) external payable returns (int256[] memory);

  /**
   * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
  struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
    uint256 amount;
    bytes userData;
  }

  /**
   * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
     */
  event Swap(
    bytes32 indexed poolId,
    IERC20 indexed tokenIn,
    IERC20 indexed tokenOut,
    uint256 amountIn,
    uint256 amountOut
  );

  /**
   * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
  struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
  }

  /**
   * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
     * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
     *
     * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
     * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
     * receives are the same that an equivalent `batchSwap` call would receive.
     *
     * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
     * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
     * approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */
  function queryBatchSwap(
    SwapKind kind,
    BatchSwapStep[] calldata swaps,
    IAsset[] calldata assets,
    FundManagement calldata funds
  ) external returns (int256[] memory assetDeltas);

  // BasePool.sol

  /**
* @dev Returns the amount of BPT that would be burned from `sender` if the `onExitPool` hook were called by the
     * Vault with the same arguments, along with the number of tokens `recipient` would receive.
     *
     * This function is not meant to be called directly, but rather from a helper contract that fetches current Vault
     * data, such as the protocol swap fee percentage and Pool balances.
     *
     * Like `IVault.queryBatchSwap`, this function is not view due to internal implementation details: the caller must
     * explicitly use eth_call instead of eth_sendTransaction.
     */
  function queryExit(
    bytes32 poolId,
    address sender,
    address recipient,
    uint256[] memory balances,
    uint256 lastChangeBlock,
    uint256 protocolSwapFeePercentage,
    bytes memory userData
  ) external returns (uint256 bptIn, uint256[] memory amountsOut);


}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IDystopiaFactory {

  function isPair(address pair) external view returns (bool);

  function getInitializable() external view returns (address, address, bool);

  function isPaused() external view returns (bool);

  function pairCodeHash() external pure returns (bytes32);

  function getPair(address tokenA, address token, bool stable) external view returns (address);

  function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IDystopiaPair {

  // Structure to capture time period obervations every 30 minutes, used for local oracles
  struct Observation {
    uint timestamp;
    uint reserve0Cumulative;
    uint reserve1Cumulative;
  }

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

  function burn(address to) external returns (uint amount0, uint amount1);

  function mint(address to) external returns (uint liquidity);

  function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);

  function getAmountOut(uint, address) external view returns (uint);

  function claimFees() external returns (uint, uint);

  function tokens() external view returns (address, address);

  function token0() external view returns (address);

  function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
  /**
   * @dev Returns the largest of two numbers.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  /**
   * @dev Returns the smallest of two numbers.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
   * @dev Returns the average of two numbers. The result is rounded towards
   * zero.
   */
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow.
    return (a & b) + (a ^ b) / 2;
  }

  /**
   * @dev Returns the ceiling of the division of two numbers.
   *
   * This differs from standard division with `/` in that it rounds up instead
   * of rounding down.
   */
  function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b - 1) / b can overflow on addition, so we distribute.
    return a / b + (a % b == 0 ? 0 : 1);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private _initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private _initializing;

  /**
   * @dev Modifier to protect an initializer function from being invoked twice.
   */
  modifier initializer() {
    require(_initializing || !_initialized, "Initializable: contract is already initialized");

    bool isTopLevelCall = !_initializing;
    if (isTopLevelCall) {
      _initializing = true;
      _initialized = true;
    }

    _;

    if (isTopLevelCall) {
      _initializing = false;
    }
  }
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

/// @dev This interface contains additional functions for Controllable class
///      Don't extend the exist Controllable for the reason of huge coherence
interface IControllableExtended {

  function created() external view returns (uint256 ts);

  function controller() external view returns (address adr);

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IController {


  function VERSION() external view returns (string memory);

  function addHardWorker(address _worker) external;

  function addStrategiesToSplitter(
    address _splitter,
    address[] memory _strategies
  ) external;

  function addStrategy(address _strategy) external;

  function addVaultsAndStrategies(
    address[] memory _vaults,
    address[] memory _strategies
  ) external;

  function announcer() external view returns (address);

  function bookkeeper() external view returns (address);

  function changeWhiteListStatus(address[] memory _targets, bool status)
  external;

  function controllerTokenMove(
    address _recipient,
    address _token,
    uint256 _amount
  ) external;

  function dao() external view returns (address);

  function distributor() external view returns (address);

  function doHardWork(address _vault) external;

  function feeRewardForwarder() external view returns (address);

  function fund() external view returns (address);

  function fundDenominator() external view returns (uint256);

  function fundKeeperTokenMove(
    address _fund,
    address _token,
    uint256 _amount
  ) external;

  function fundNumerator() external view returns (uint256);

  function fundToken() external view returns (address);

  function governance() external view returns (address);

  function hardWorkers(address) external view returns (bool);

  function initialize() external;

  function isAllowedUser(address _adr) external view returns (bool);

  function isDao(address _adr) external view returns (bool);

  function isHardWorker(address _adr) external view returns (bool);

  function isPoorRewardConsumer(address _adr) external view returns (bool);

  function isRewardDistributor(address _adr) external view returns (bool);

  function isValidStrategy(address _strategy) external view returns (bool);

  function isValidVault(address _vault) external view returns (bool);

  function mintAndDistribute(uint256 totalAmount, bool mintAllAvailable)
  external;

  function mintHelper() external view returns (address);

  function psDenominator() external view returns (uint256);

  function psNumerator() external view returns (uint256);

  function psVault() external view returns (address);

  function pureRewardConsumers(address) external view returns (bool);

  function rebalance(address _strategy) external;

  function removeHardWorker(address _worker) external;

  function rewardDistribution(address) external view returns (bool);

  function rewardToken() external view returns (address);

  function setAnnouncer(address _newValue) external;

  function setBookkeeper(address newValue) external;

  function setDao(address newValue) external;

  function setDistributor(address _distributor) external;

  function setFeeRewardForwarder(address _feeRewardForwarder) external;

  function setFund(address _newValue) external;

  function setFundNumeratorDenominator(uint256 numerator, uint256 denominator)
  external;

  function setFundToken(address _newValue) external;

  function setGovernance(address newValue) external;

  function setMintHelper(address _newValue) external;

  function setPSNumeratorDenominator(uint256 numerator, uint256 denominator)
  external;

  function setPsVault(address _newValue) external;

  function setPureRewardConsumers(address[] memory _targets, bool _flag)
  external;

  function setRewardDistribution(
    address[] memory _newRewardDistribution,
    bool _flag
  ) external;

  function setRewardToken(address _newValue) external;

  function setVaultController(address _newValue) external;

  function setVaultStrategyBatch(
    address[] memory _vaults,
    address[] memory _strategies
  ) external;

  function strategies(address) external view returns (bool);

  function strategyTokenMove(
    address _strategy,
    address _token,
    uint256 _amount
  ) external;

  function upgradeTetuProxyBatch(
    address[] memory _contracts,
    address[] memory _implementations
  ) external;

  function vaultController() external view returns (address);

  function vaults(address) external view returns (bool);

  function whiteList(address) external view returns (bool);
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