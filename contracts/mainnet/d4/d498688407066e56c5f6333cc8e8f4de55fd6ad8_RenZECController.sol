// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma abicoder v2;

import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { UniswapV2Library } from "../libraries/UniswapV2Library.sol";
import { ZeroLib } from "../libraries/ZeroLib.sol";
import { IERC2612Permit } from "../interfaces/IERC2612Permit.sol";
import { IRenCrv } from "../interfaces/CurvePools/IRenCrv.sol";
import { SplitSignatureLib } from "../libraries/SplitSignatureLib.sol";
import { IBadgerSettPeak } from "../interfaces/IBadgerSettPeak.sol";
import { IWETH } from "../interfaces/IWETH.sol";
import { ICurveFi } from "../interfaces/ICurveFi.sol";
import { IGateway } from "../interfaces/IGateway.sol";
import { ICurveTricrypto } from "../interfaces/CurvePools/ICurveTricrypto.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IyVault } from "../interfaces/IyVault.sol";
import { ISett } from "../interfaces/ISett.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ECDSA } from "@openzeppelin/contracts/cryptography/ECDSA.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/drafts/EIP712Upgradeable.sol";

contract BadgerBridgeZeroController is EIP712Upgradeable {
  using SafeERC20 for IERC20;
  using SafeMath for *;
  uint256 public fee;
  address public governance;
  address public strategist;

  address constant btcGateway = 0xe4b679400F0f267212D5D812B95f58C83243EE71;
  address constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address constant routerv3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
  address constant factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
  address constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address constant wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
  address constant renbtc = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;
  address constant renCrv = 0x93054188d876f558f4a66B2EF1d97d16eDf0895B;
  address constant threepool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
  address constant tricrypto = 0x80466c64868E1ab14a1Ddf27A676C3fcBE638Fe5;
  address constant renCrvLp = 0x49849C98ae39Fff122806C06791Fa73784FB3675;
  address constant bCrvRen = 0x6dEf55d2e18486B9dDfaA075bc4e4EE0B28c1545;
  address constant settPeak = 0x41671BA1abcbA387b9b2B752c205e22e916BE6e3;
  address constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
  uint24 constant wethWbtcFee = 500;
  uint24 constant usdcWethFee = 500;
  uint256 public governanceFee;
  bytes32 constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
  bytes32 constant LOCK_SLOT = keccak256("upgrade-lock-v3");
  uint256 constant GAS_COST = uint256(42e4);
  uint256 constant ETH_RESERVE = uint256(5 ether);
  uint256 internal renbtcForOneETHPrice;
  uint256 internal burnFee;
  uint256 public keeperReward;
  uint256 public constant REPAY_GAS_DIFF = 41510;
  uint256 public constant BURN_GAS_DIFF = 41118;
  mapping(address => uint256) public nonces;
  bytes32 internal PERMIT_DOMAIN_SEPARATOR_WBTC;
  mapping(address => uint256) public noncesUsdt;
  bytes32 constant PERMIT_DOMAIN_SEPARATOR_USDT_SLOT = keccak256("usdt-permit");

  function getUsdtDomainSeparator() public view returns (bytes32) {
    bytes32 separator_slot = PERMIT_DOMAIN_SEPARATOR_USDT_SLOT;
    bytes32 separator;
    assembly {
      separator := sload(separator_slot)
    }
    return separator;
  }

  function setStrategist(address _strategist) public {
    require(msg.sender == governance, "!governance");
    strategist = _strategist;
  }

  function setGovernance(address _governance) public {
    require(msg.sender == governance, "!governance");
    governance = _governance;
  }

  function approveUpgrade(bool lock) public {
    bool isLocked;
    bytes32 lock_slot = LOCK_SLOT;
    bytes32 permit_slot = PERMIT_DOMAIN_SEPARATOR_USDT_SLOT;

    assembly {
      isLocked := sload(lock_slot)
    }
    require(!isLocked, "cannot run upgrade function");

    IERC20(usdt).safeApprove(tricrypto, ~uint256(0) >> 2);
    bytes32 permit_usdt_separator = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("USDT"),
        keccak256("1"),
        getChainId(),
        usdt
      )
    );

    assembly {
      sstore(lock_slot, lock)
      sstore(permit_slot, permit_usdt_separator)
    }
  }

  function computeCalldataGasDiff() internal pure returns (uint256 diff) {
    if (true) return 0; // TODO: implement exact gas metering
    // EVM charges less for zero bytes, we must compute the offset for refund
    // TODO make this efficient
    uint256 sz;
    assembly {
      sz := calldatasize()
    }
    diff = sz.mul(uint256(68));
    bytes memory slice;
    for (uint256 i = 0; i < sz; i += 0x20) {
      uint256 word;
      assembly {
        word := calldataload(i)
      }
      for (uint256 i = 0; i < 256 && ((uint256(~0) << i) & word) != 0; i += 8) {
        if ((word >> i) & 0xff != 0) diff -= 64;
      }
    }
  }

  function getChainId() internal pure returns (uint256 result) {
    assembly {
      result := chainid()
    }
  }

  function setParameters(
    uint256 _governanceFee,
    uint256 _fee,
    uint256 _burnFee,
    uint256 _keeperReward
  ) public {
    require(governance == msg.sender, "!governance");
    governanceFee = _governanceFee;
    fee = _fee;
    burnFee = _burnFee;
    keeperReward = _keeperReward;
  }

  function initialize(address _governance, address _strategist) public initializer {
    fee = uint256(25e14);
    burnFee = uint256(4e15);
    governanceFee = uint256(5e17);
    governance = _governance;
    strategist = _strategist;
    keeperReward = uint256(1 ether).div(1000);
    IERC20(renbtc).safeApprove(btcGateway, ~uint256(0) >> 2);
    IERC20(renbtc).safeApprove(renCrv, ~uint256(0) >> 2);
    IERC20(wbtc).safeApprove(renCrv, ~uint256(0) >> 2);
    IERC20(wbtc).safeApprove(tricrypto, ~uint256(0) >> 2);
    IERC20(usdt).safeApprove(tricrypto, ~uint256(0) >> 2);
    IERC20(wbtc).safeApprove(routerv3, ~uint256(0) >> 2);
    IERC20(usdc).safeApprove(routerv3, ~uint256(0) >> 2);
    PERMIT_DOMAIN_SEPARATOR_WBTC = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("WBTC"),
        keccak256("1"),
        getChainId(),
        wbtc
      )
    );
    bytes32 permit_separator_usdt = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("USDT"),
        keccak256("1"),
        getChainId(),
        usdt
      )
    );
    bytes32 permit_slot = PERMIT_DOMAIN_SEPARATOR_USDT_SLOT;
    assembly {
      sstore(permit_slot, permit_separator_usdt)
    }
  }

  function applyRatio(uint256 v, uint256 n) internal pure returns (uint256 result) {
    result = v.mul(n).div(uint256(1 ether));
  }

  function toWBTC(uint256 amount) internal returns (uint256 amountOut) {
    uint256 amountStart = IERC20(wbtc).balanceOf(address(this));
    (bool success, ) = renCrv.call(abi.encodeWithSelector(IRenCrv.exchange.selector, 0, 1, amount));
    amountOut = IERC20(wbtc).balanceOf(address(this)).sub(amountStart);
  }

  function toUSDC(
    uint256 minOut,
    uint256 amountIn,
    address out
  ) internal returns (uint256 amountOut) {
    uint256 wbtcAmountIn = toWBTC(amountIn);
    bytes memory path = abi.encodePacked(wbtc, wethWbtcFee, weth, usdcWethFee, usdc);
    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      recipient: out,
      deadline: block.timestamp + 1,
      amountIn: wbtcAmountIn,
      amountOutMinimum: minOut,
      path: path
    });
    amountOut = ISwapRouter(routerv3).exactInput(params);
  }

  function quote() internal {
    (uint256 amountWeth, uint256 amountRenBTC) = UniswapV2Library.getReserves(factory, weth, renbtc);
    renbtcForOneETHPrice = UniswapV2Library.quote(uint256(1 ether), amountWeth, amountRenBTC);
  }

  function renBTCtoETH(
    uint256 minOut,
    uint256 amountIn,
    address out
  ) internal returns (uint256 amountOut) {
    uint256 wbtcAmountOut = toWBTC(amountIn);
    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
      tokenIn: wbtc,
      tokenOut: weth,
      fee: wethWbtcFee,
      recipient: address(this),
      deadline: block.timestamp + 1,
      amountIn: wbtcAmountOut,
      amountOutMinimum: minOut,
      sqrtPriceLimitX96: 0
    });
    amountOut = ISwapRouter(routerv3).exactInputSingle(params);
    IWETH(weth).withdraw(amountOut);
    address payable recipient = address(uint160(out));
    recipient.transfer(amountOut);
  }

  function burnApproved(
    address from,
    address asset,
    uint256 amount,
    uint256 minOut,
    bytes memory destination
  ) public payable returns (uint256 amountToBurn) {
    require(asset == wbtc || asset == usdc || asset == renbtc || asset == address(0x0), "!approved-module");
    if (asset != address(0x0)) IERC20(asset).transferFrom(msg.sender, address(this), amount);
    amountToBurn = asset == wbtc ? toRenBTC(amount.sub(applyRatio(amount, burnFee))) : asset == usdc
      ? fromUSDC(minOut, amount.sub(applyRatio(amount, burnFee)))
      : asset == renbtc
      ? amount
      : fromETHToRenBTC(minOut, msg.value.sub(applyRatio(msg.value, burnFee)));
    IGateway(btcGateway).burn(destination, amountToBurn);
  }

  function toRenBTC(uint256 amountIn) internal returns (uint256 amountOut) {
    uint256 balanceStart = IERC20(renbtc).balanceOf(address(this));
    (bool success, ) = renCrv.call(abi.encodeWithSelector(IRenCrv.exchange.selector, 1, 0, amountIn));
    amountOut = IERC20(renbtc).balanceOf(address(this)).sub(balanceStart);
  }

  function fromUSDC(uint256 minOut, uint256 amountIn) internal returns (uint256 amountOut) {
    bytes memory path = abi.encodePacked(usdc, usdcWethFee, weth, wethWbtcFee, wbtc);
    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      recipient: address(this),
      deadline: block.timestamp + 1,
      amountIn: amountIn,
      amountOutMinimum: minOut,
      path: path
    });
    amountOut = ISwapRouter(routerv3).exactInput(params);
    amountOut = toRenBTC(amountOut);
  }

  function fromETHToRenBTC(uint256 minOut, uint256 amountIn) internal returns (uint256 amountOut) {
    uint256 amountStart = IERC20(renbtc).balanceOf(address(this));
    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
      tokenIn: weth,
      tokenOut: wbtc,
      fee: wethWbtcFee,
      recipient: address(this),
      deadline: block.timestamp + 1,
      amountIn: amountIn,
      amountOutMinimum: minOut,
      sqrtPriceLimitX96: 0
    });
    amountOut = ISwapRouter(routerv3).exactInputSingle{ value: amountIn }(params);
    (bool success, ) = renCrv.call(abi.encodeWithSelector(IRenCrv.exchange.selector, 1, 0, amountOut, 1));
    require(success, "!curve");
    amountOut = IERC20(renbtc).balanceOf(address(this)).sub(amountStart);
  }

  function toETH() internal returns (uint256 amountOut) {
    uint256 wbtcStart = IERC20(wbtc).balanceOf(address(this));

    uint256 amountStart = address(this).balance;
    (bool success, ) = tricrypto.call(
      abi.encodeWithSelector(ICurveTricrypto.exchange.selector, 1, 2, wbtcStart, 0, true)
    );
    amountOut = address(this).balance.sub(amountStart);
  }

  function fromUSDT(uint256 amountIn) internal returns (uint256 amountOut) {
    uint256 wbtcIn = IERC20(wbtc).balanceOf(address(this));
    (bool success, ) = tricrypto.call(
      abi.encodeWithSelector(ICurveTricrypto.exchange.selector, 0, 1, amountIn, 0, false)
    );
    require(success, "!curve");
    wbtcIn = IERC20(wbtc).balanceOf(address(this)).sub(wbtcIn);
    amountOut = toRenBTC(wbtcIn);
  }

  function toUSDT(uint256 amountIn) internal returns (uint256 amountOut) {
    uint256 wbtcOut = toWBTC(amountIn);
    amountOut = IERC20(usdt).balanceOf(address(this));
    (bool success, ) = tricrypto.call(
      abi.encodeWithSelector(ICurveTricrypto.exchange.selector, 1, 0, wbtcOut, 0, false)
    );
    require(success, "!curve");
    amountOut = IERC20(usdt).balanceOf(address(this)).sub(amountOut);
  }

  receive() external payable {
    // no-op
  }

  function earn() public {
    quote();
    toWBTC(IERC20(renbtc).balanceOf(address(this)));
    toETH();
    uint256 balance = address(this).balance;
    if (balance > ETH_RESERVE) {
      uint256 output = balance - ETH_RESERVE;
      uint256 toGovernance = applyRatio(output, governanceFee);
      bool success;
      address payable governancePayable = address(uint160(governance));
      (success, ) = governancePayable.call{ value: toGovernance, gas: gasleft() }("");
      require(success, "error sending to governance");
      address payable strategistPayable = address(uint160(strategist));
      (success, ) = strategistPayable.call{ value: output.sub(toGovernance), gas: gasleft() }("");
      require(success, "error sending to strategist");
    }
  }

  function computeRenBTCGasFee(uint256 gasCost, uint256 gasPrice) internal view returns (uint256 result) {
    result = gasCost.mul(tx.gasprice).mul(renbtcForOneETHPrice).div(uint256(1 ether));
  }

  function deductMintFee(uint256 amountIn, uint256 multiplier) internal view returns (uint256 amount) {
    amount = amountIn.sub(applyFee(amountIn, fee, multiplier));
  }

  function deductBurnFee(uint256 amountIn, uint256 multiplier) internal view returns (uint256 amount) {
    amount = amountIn.sub(applyFee(amountIn, burnFee, multiplier));
  }

  function applyFee(
    uint256 amountIn,
    uint256 _fee,
    uint256 multiplier
  ) internal view returns (uint256 amount) {
    amount = computeRenBTCGasFee(GAS_COST.add(keeperReward.div(tx.gasprice)), tx.gasprice).add(
      applyRatio(amountIn, _fee)
    );
  }

  struct LoanParams {
    address to;
    address asset;
    uint256 nonce;
    uint256 amount;
    address module;
    address underwriter;
    bytes data;
    uint256 minOut;
    uint256 _mintAmount;
    uint256 gasDiff;
  }

  function toTypedDataHash(LoanParams memory params) internal view returns (bytes32 result) {
    bytes32 digest = _hashTypedDataV4(
      keccak256(
        abi.encode(
          keccak256(
            "TransferRequest(address asset,uint256 amount,address underwriter,address module,uint256 nonce,bytes data)"
          ),
          params.asset,
          params.amount,
          params.underwriter,
          params.module,
          params.nonce,
          keccak256(params.data)
        )
      )
    );
    return digest;
  }

  function repay(
    address underwriter,
    address to,
    address asset,
    uint256 amount,
    uint256 actualAmount,
    uint256 nonce,
    address module,
    bytes32 nHash,
    bytes memory data,
    bytes memory signature
  ) public returns (uint256 amountOut) {
    require(msg.data.length <= 516, "too much calldata");
    uint256 _gasBefore = gasleft();
    LoanParams memory params;
    {
      require(
        module == wbtc || module == usdc || module == renbtc || module == usdt || module == address(0x0),
        "!approved-module"
      );
      params = LoanParams({
        to: to,
        asset: asset,
        amount: amount,
        nonce: nonce,
        module: module,
        underwriter: underwriter,
        data: data,
        minOut: 1,
        _mintAmount: 0,
        gasDiff: computeCalldataGasDiff()
      });
      if (data.length > 0) (params.minOut) = abi.decode(data, (uint256));
    }
    bytes32 digest = toTypedDataHash(params);

    params._mintAmount = IGateway(btcGateway).mint(
      keccak256(abi.encode(params.to, params.nonce, params.module, params.data)),
      actualAmount,
      nHash,
      signature
    );

    {
      amountOut = module == wbtc ? toWBTC(deductMintFee(params._mintAmount, 1)) : module == address(0x0)
        ? renBTCtoETH(params.minOut, deductMintFee(params._mintAmount, 1), to)
        : module == usdt
        ? toUSDT(deductMintFee(params._mintAmount, 1))
        : module == usdc
        ? toUSDC(params.minOut, deductMintFee(params._mintAmount, 1), to)
        : deductMintFee(params._mintAmount, 1);
    }
    {
      if (module != usdc && module != address(0x0)) IERC20(module).safeTransfer(to, amountOut);
    }
    {
      tx.origin.transfer(
        Math.min(
          _gasBefore.sub(gasleft()).add(REPAY_GAS_DIFF).add(params.gasDiff).mul(tx.gasprice).add(keeperReward),
          address(this).balance
        )
      );
    }
  }

  function computeBurnNonce(BurnLocals memory params) internal view returns (uint256 result) {
    result = uint256(
      keccak256(
        abi.encodePacked(params.asset, params.amount, params.deadline, params.nonce, params.data, params.destination)
      )
    );
    while (result < block.timestamp) {
      // negligible probability of this
      result = uint256(keccak256(abi.encodePacked(result)));
    }
  }

  function computeERC20PermitDigest(bytes32 domainSeparator, BurnLocals memory params)
    internal
    view
    returns (bytes32 result)
  {
    result = keccak256(
      abi.encodePacked(
        "\x19\x01",
        domainSeparator,
        keccak256(abi.encode(PERMIT_TYPEHASH, params.to, address(this), params.nonce, computeBurnNonce(params), true))
      )
    );
  }

  struct BurnLocals {
    address to;
    address asset;
    uint256 amount;
    uint256 deadline;
    uint256 nonce;
    bytes data;
    uint256 minOut;
    uint256 burnNonce;
    uint256 gasBefore;
    uint256 gasDiff;
    uint8 v;
    bytes32 r;
    bytes32 s;
    bytes destination;
    bytes signature;
  }

  function burn(
    address to,
    address asset,
    uint256 amount,
    uint256 deadline,
    bytes memory data,
    bytes memory destination,
    bytes memory signature
  ) public returns (uint256 amountToBurn) {
    require(msg.data.length <= 580, "too much calldata");
    BurnLocals memory params = BurnLocals({
      to: to,
      asset: asset,
      amount: amount,
      deadline: deadline,
      data: data,
      nonce: 0,
      burnNonce: 0,
      v: uint8(0),
      r: bytes32(0),
      s: bytes32(0),
      destination: destination,
      signature: signature,
      gasBefore: gasleft(),
      minOut: 1,
      gasDiff: 0
    });
    {
      params.gasDiff = computeCalldataGasDiff();
      if (params.data.length > 0) (params.minOut) = abi.decode(params.data, (uint256));
    }
    require(block.timestamp < params.deadline, "!deadline");
    if (params.asset == wbtc) {
      params.nonce = nonces[to];
      nonces[params.to]++;
      require(
        params.to == ECDSA.recover(computeERC20PermitDigest(PERMIT_DOMAIN_SEPARATOR_WBTC, params), params.signature),
        "!signature"
      ); //  wbtc does not implement ERC20Permit
      {
        IERC20(params.asset).transferFrom(params.to, address(this), params.amount);
        amountToBurn = toRenBTC(deductBurnFee(params.amount, 1));
      }
    } else if (params.asset == usdt) {
      params.nonce = noncesUsdt[to];
      noncesUsdt[params.to]++;
      require(
        params.to == ECDSA.recover(computeERC20PermitDigest(getUsdtDomainSeparator(), params), params.signature),
        "!signature"
      ); //  usdt does not implement ERC20Permit
      {
        (bool success, ) = params.asset.call(
          abi.encodeWithSelector(IERC20.transferFrom.selector, params.to, address(this), params.amount)
        );
        require(success, "!usdt");
      }
      amountToBurn = deductBurnFee(fromUSDT(params.amount), 1);
    } else if (params.asset == renbtc) {
      {
        params.nonce = IERC2612Permit(params.asset).nonces(params.to);
        params.burnNonce = computeBurnNonce(params);
      }
      {
        (params.v, params.r, params.s) = SplitSignatureLib.splitSignature(params.signature);
        IERC2612Permit(params.asset).permit(
          params.to,
          address(this),
          params.nonce,
          params.burnNonce,
          true,
          params.v,
          params.r,
          params.s
        );
      }
      {
        IERC20(params.asset).transferFrom(params.to, address(this), params.amount);
      }
      amountToBurn = deductBurnFee(params.amount, 1);
    } else if (params.asset == usdc) {
      {
        params.nonce = IERC2612Permit(params.asset).nonces(params.to);
        params.burnNonce = computeBurnNonce(params);
      }
      {
        (params.v, params.r, params.s) = SplitSignatureLib.splitSignature(params.signature);
        IERC2612Permit(params.asset).permit(
          params.to,
          address(this),
          params.amount,
          params.burnNonce,
          params.v,
          params.r,
          params.s
        );
      }
      {
        IERC20(params.asset).transferFrom(params.to, address(this), params.amount);
      }
      amountToBurn = deductBurnFee(fromUSDC(params.minOut, params.amount), 1);
    } else revert("!supported-asset");
    {
      IGateway(btcGateway).burn(params.destination, amountToBurn);
    }
    {
      tx.origin.transfer(
        Math.min(
          params.gasBefore.sub(gasleft()).add(BURN_GAS_DIFF).add(params.gasDiff).mul(tx.gasprice).add(keeperReward),
          address(this).balance
        )
      );
    }
  }

  function burnETH(uint256 minOut, bytes memory destination) public payable returns (uint256 amountToBurn) {
    amountToBurn = fromETHToRenBTC(minOut, msg.value.sub(applyRatio(msg.value, burnFee)));
    IGateway(btcGateway).burn(destination, amountToBurn);
  }

  function fallbackMint(
    address underwriter,
    address to,
    address asset,
    uint256 amount,
    uint256 actualAmount,
    uint256 nonce,
    address module,
    bytes32 nHash,
    bytes memory data,
    bytes memory signature
  ) public {
    LoanParams memory params = LoanParams({
      to: to,
      asset: asset,
      amount: amount,
      nonce: nonce,
      module: module,
      underwriter: underwriter,
      data: data,
      minOut: 1,
      _mintAmount: 0,
      gasDiff: 0
    });
    bytes32 digest = toTypedDataHash(params);
    uint256 _actualAmount = IGateway(btcGateway).mint(
      keccak256(abi.encode(params.to, params.nonce, params.module, params.data)),
      actualAmount,
      nHash,
      signature
    );
    IERC20(asset).safeTransfer(to, _actualAmount);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

pragma solidity >=0.5.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

library UniswapV2Library {
  using SafeMath for uint256;

  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex"ff",
              factory,
              keccak256(abi.encodePacked(token0, token1)),
              hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
            )
          )
        )
      )
    );
  }

  // fetches and sorts the reserves for a pair
  function getReserves(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (uint256 reserveA, uint256 reserveB) {
    (address token0, ) = sortTokens(tokenA, tokenB);
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
    (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) internal pure returns (uint256 amountB) {
    require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
    require(reserveA > 0 && reserveB > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
    amountB = amountA.mul(reserveB) / reserveA;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

/**
@title helper functions for the Zero contract suite
@author raymondpulver
*/
library ZeroLib {
  enum LoanStatusCode {
    UNINITIALIZED,
    UNPAID,
    PAID
  }
  struct LoanParams {
    address to;
    address asset;
    uint256 amount;
    uint256 nonce;
    address module;
    bytes data;
  }
  struct MetaParams {
    address from;
    uint256 nonce;
    bytes data;
    address module;
    address asset;
  }
  struct LoanStatus {
    address underwriter;
    LoanStatusCode status;
  }
  struct BalanceSheet {
    uint128 loaned;
    uint128 required;
    uint256 repaid;
  }
}

interface IERC2612Permit {
  /**
   * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
   * given `owner`'s signed approval.
   *
   * IMPORTANT: The same issues {IERC20-approve} has related to transaction
   * ordering also apply here.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   * - `deadline` must be a timestamp in the future.
   * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
   * over the EIP712-formatted function arguments.
   * - the signature must use ``owner``'s current nonce (see {nonces}).
   *
   * For more information on the signature format, see the
   * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
   * section].
   */
  function permit(
    address holder,
    address spender,
    uint256 nonce,
    uint256 expiry,
    bool allowed,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function permit(
    address holder,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @dev Returns the current ERC2612 nonce for `owner`. This value must be
   * included whenever a signature is generated for {permit}.
   *
   * Every successful call to {permit} increases ``owner``'s nonce by one. This
   * prevents a signature from being used multiple times.
   */
  function nonces(address owner) external view returns (uint256);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
}

interface IRenCrv {
  function exchange(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

library SplitSignatureLib {
  function splitSignature(bytes memory signature)
    internal
    pure
    returns (
      uint8 v,
      bytes32 r,
      bytes32 s
    )
  {
    if (signature.length == 65) {
      assembly {
        r := mload(add(signature, 0x20))
        s := mload(add(signature, 0x40))
        v := byte(0, mload(add(signature, 0x60)))
      }
    } else if (signature.length == 64) {
      assembly {
        r := mload(add(signature, 0x20))
        let vs := mload(add(signature, 0x40))
        s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
        v := add(shr(255, vs), 27)
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IBadgerSettPeak {
  function mint(
    uint256,
    uint256,
    bytes32[] calldata
  ) external returns (uint256);

  function redeem(uint256, uint256) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.8.0;

interface IWETH {
  function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface ICurveFi {
  function add_liquidity(uint256[2] calldata amounts, uint256 idx) external;

  function remove_liquidity_one_coin(
    uint256,
    int128,
    uint256
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IMintGateway {
  function mint(
    bytes32 _pHash,
    uint256 _amount,
    bytes32 _nHash,
    bytes calldata _sig
  ) external returns (uint256);

  function mintFee() external view returns (uint256);
}

interface IBurnGateway {
  function burn(bytes memory _to, uint256 _amountScaled) external returns (uint256);

  function burnFee() external view returns (uint256);
}

interface IGateway is IMintGateway, IBurnGateway {

}

/*
interface IGateway is IMintGateway, IBurnGateway {
    function mint(
        bytes32 _pHash,
        uint256 _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) external returns (uint256);

    function mintFee() external view returns (uint256);

    function burn(bytes calldata _to, uint256 _amountScaled)
        external
        returns (uint256);

    function burnFee() external view returns (uint256);
}
*/

pragma solidity >=0.6.0 <0.8.0;

interface ICurveTricrypto {
  function exchange(
    uint256 i,
    uint256 j,
    uint256 dx,
    uint256 min_dy,
    bool use_eth
  ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import { IERC20 } from "oz410/token/ERC20/IERC20.sol";

abstract contract IyVault is IERC20 {
  function pricePerShare() external view virtual returns (uint256);

  function getPricePerFullShare() external view virtual returns (uint256);

  function totalAssets() external view virtual returns (uint256);

  function deposit(uint256 _amount) external virtual returns (uint256);

  function withdraw(uint256 maxShares) external virtual returns (uint256);

  function want() external virtual returns (address);

  function decimals() external view virtual returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface ISett {
  function deposit(uint256) external;

  function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                _getChainId(),
                address(this)
            )
        );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _getChainId() private view returns (uint256 chainId) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.9.0;
import { BadgerBridgeZeroController } from "../controllers/BadgerBridgeZeroController.sol";
import { IERC2612Permit } from "../interfaces/IERC2612Permit.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/SplitSignatureLib.sol";

contract DummyBurnCaller {
  constructor(address controller, address renzec) {
    IERC20(renzec).approve(controller, ~uint256(0) >> 2);
  }

  function callBurn(
    address controller,
    address from,
    address asset,
    uint256 amount,
    uint256 deadline,
    bytes memory signature,
    bytes memory destination
  ) public {
    (uint8 v, bytes32 r, bytes32 s) = SplitSignatureLib.splitSignature(signature);
    uint256 nonce = IERC2612Permit(asset).nonces(from);
    IERC2612Permit(asset).permit(from, address(this), nonce, deadline, true, v, r, s);
    address payable _controller = address(uint160(controller));
    BadgerBridgeZeroController(_controller).burnApproved(from, asset, amount, 1, destination);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/drafts/EIP712Upgradeable.sol";
import { IERC20 } from "oz410/token/ERC20/ERC20.sol";
import { SafeERC20 } from "oz410/token/ERC20/SafeERC20.sol";
import { IZeroMeta } from "../interfaces/IZeroMeta.sol";
import { IZeroModule } from "../interfaces/IZeroModule.sol";
import { ZeroUnderwriterLock } from "../underwriter/ZeroUnderwriterLock.sol";
import { ZeroLib } from "../libraries/ZeroLib.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ControllerUpgradeable } from "./ControllerUpgradeable.sol";
import { EIP712 } from "oz410/drafts/EIP712.sol";
import { ECDSA } from "oz410/cryptography/ECDSA.sol";
import { FactoryLib } from "../libraries/factory/FactoryLib.sol";
import { SplitSignatureLib } from "../libraries/SplitSignatureLib.sol";
import { ZeroUnderwriterLockBytecodeLib } from "../libraries/bytecode/ZeroUnderwriterLockBytecodeLib.sol";
import { IGateway } from "../interfaces/IGateway.sol";
import { IGatewayRegistry } from "../interfaces/IGatewayRegistry.sol";
import { IStrategy } from "../interfaces/IStrategy.sol";
import { SafeMath } from "oz410/math/SafeMath.sol";
import { LockForImplLib } from "../libraries/LockForImplLib.sol";
import { IERC2612Permit } from "../interfaces/IERC2612Permit.sol";
import "../interfaces/IConverter.sol";
import { ZeroControllerTemplate } from "./ZeroControllerTemplate.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "hardhat/console.sol";

/**
@title upgradeable contract which determines the authority of a given address to sign off on loans
@author raymondpulver
*/
contract ZeroController is ZeroControllerTemplate {
  using SafeMath for uint256;
  using SafeERC20 for *;

  function getChainId() internal view returns (uint8 response) {
    assembly {
      response := chainid()
    }
  }

  function setFee(uint256 _fee) public {
    require(msg.sender == governance, "!governance");
    fee = _fee;
  }

  function approveModule(address module, bool isApproved) public virtual {
    require(msg.sender == governance, "!governance");
    approvedModules[module] = isApproved;
  }

  function setBaseFeeByAsset(address _asset, uint256 _fee) public {
    require(msg.sender == governance, "!governance");
    baseFeeByAsset[_asset] = _fee;
  }

  function deductFee(uint256 _amount, address _asset) internal view returns (uint256 result) {
    result = _amount.mul(uint256(1 ether).sub(fee)).div(uint256(1 ether)).sub(baseFeeByAsset[_asset]);
  }

  function addFee(uint256 _amount, address _asset) internal view returns (uint256 result) {
    result = _amount.mul(uint256(1 ether).add(fee)).div(uint256(1 ether)).add(baseFeeByAsset[_asset]);
  }

  function initialize(address _rewards, address _gatewayRegistry) public {
    __Ownable_init_unchained();
    __Controller_init_unchained(_rewards);
    __EIP712_init_unchained("ZeroController", "1");
    gatewayRegistry = _gatewayRegistry;
    underwriterLockImpl = FactoryLib.deployImplementation(
      ZeroUnderwriterLockBytecodeLib.get(),
      "zero.underwriter.lock-implementation"
    );

    maxGasPrice = 100e9;
    maxGasRepay = 250000;
    maxGasLoan = 500000;
  }

  modifier onlyUnderwriter() {
    require(ownerOf[uint256(uint160(address(lockFor(msg.sender))))] != address(0x0), "must be called by underwriter");
    _;
  }

  function setGasParameters(
    uint256 _maxGasPrice,
    uint256 _maxGasRepay,
    uint256 _maxGasLoan,
    uint256 _maxGasBurn
  ) public {
    require(msg.sender == governance, "!governance");
    maxGasPrice = _maxGasPrice;
    maxGasRepay = _maxGasRepay;
    maxGasLoan = _maxGasLoan;
    maxGasBurn = _maxGasBurn;
  }

  function balanceOf(address _owner) public view override returns (uint256 result) {
    result = _balanceOf(_owner);
  }

  function lockFor(address underwriter) public view returns (ZeroUnderwriterLock result) {
    result = LockForImplLib.lockFor(address(this), underwriterLockImpl, underwriter);
  }

  function mint(address underwriter, address vault) public virtual {
    address lock = FactoryLib.deploy(underwriterLockImpl, bytes32(uint256(uint160(underwriter))));
    ZeroUnderwriterLock(lock).initialize(vault);
    ownerOf[uint256(uint160(lock))] = msg.sender;
  }

  function _typedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
  }

  function fallbackMint(
    address underwriter,
    address to,
    address asset,
    uint256 amount,
    uint256 actualAmount,
    uint256 nonce,
    address module,
    bytes32 nHash,
    bytes memory data,
    bytes memory signature
  ) public {
    ZeroLib.LoanParams memory params = ZeroLib.LoanParams({
      to: to,
      asset: asset,
      amount: amount,
      nonce: nonce,
      module: module,
      data: data
    });
    bytes32 digest = toTypedDataHash(params, underwriter);
    require(loanStatus[digest].status == ZeroLib.LoanStatusCode.UNINITIALIZED, "loan already exists");
    uint256 _actualAmount = IGateway(IGatewayRegistry(gatewayRegistry).getGatewayByToken(asset)).mint(
      keccak256(abi.encode(params.to, params.nonce, params.module, params.data)),
      actualAmount,
      nHash,
      signature
    );
    delete (loanStatus[digest]);
    IERC20(asset).safeTransfer(to, _actualAmount);
  }

  function repay(
    address underwriter,
    address to,
    address asset,
    uint256 amount,
    uint256 actualAmount,
    uint256 nonce,
    address module,
    bytes32 nHash,
    bytes memory data,
    bytes memory signature
  ) public {
    uint256 _gasBefore = gasleft();
    ZeroLib.LoanParams memory params = ZeroLib.LoanParams({
      to: to,
      asset: asset,
      amount: amount,
      nonce: nonce,
      module: module,
      data: data
    });
    bytes32 digest = toTypedDataHash(params, underwriter);
    require(loanStatus[digest].status == ZeroLib.LoanStatusCode.UNPAID, "loan is not in the UNPAID state");

    ZeroUnderwriterLock lock = ZeroUnderwriterLock(lockFor(msg.sender));
    lock.trackIn(actualAmount);
    uint256 _mintAmount = IGateway(IGatewayRegistry(gatewayRegistry).getGatewayByToken(asset)).mint(
      keccak256(abi.encode(params.to, params.nonce, params.module, params.data)),
      actualAmount,
      nHash,
      signature
    );
    IZeroModule(module).repayLoan(params.to, asset, _mintAmount, nonce, data);
    depositAll(asset);
    uint256 _gasRefund = Math.min(_gasBefore.sub(gasleft()), maxGasLoan).mul(maxGasPrice);
    IStrategy(strategies[params.asset]).permissionedEther(tx.origin, _gasRefund);
  }

  function depositAll(address _asset) internal {
    // deposit all of the asset in the vault
    uint256 _balance = IERC20(_asset).balanceOf(address(this));
    IERC20(_asset).safeTransfer(strategies[_asset], _balance);
  }

  function toTypedDataHash(ZeroLib.LoanParams memory params, address underwriter)
    internal
    view
    returns (bytes32 result)
  {
    bytes32 digest = _hashTypedDataV4(
      keccak256(
        abi.encode(
          keccak256(
            "TransferRequest(address asset,uint256 amount,address underwriter,address module,uint256 nonce,bytes data)"
          ),
          params.asset,
          params.amount,
          underwriter,
          params.module,
          params.nonce,
          keccak256(params.data)
        )
      )
    );
    return digest;
  }

  function toMetaTypedDataHash(ZeroLib.MetaParams memory params, address underwriter)
    internal
    view
    returns (bytes32 result)
  {
    result = _hashTypedDataV4(
      keccak256(
        abi.encode(
          keccak256("MetaRequest(address asset,address underwriter,address module,uint256 nonce,bytes data)"),
          params.asset,
          underwriter,
          params.module,
          params.nonce,
          keccak256(params.data)
        )
      )
    );
  }

  function convertGasUsedToRen(uint256 _gasUsed, address asset) internal view returns (uint256 gasUsedInRen) {
    address converter = converters[IStrategy(strategies[asset]).nativeWrapper()][
      IStrategy(strategies[asset]).vaultWant()
    ];
    gasUsedInRen = IConverter(converter).estimate(_gasUsed); //convert txGas from ETH to wBTC
    gasUsedInRen = IConverter(converters[IStrategy(strategies[asset]).vaultWant()][asset]).estimate(gasUsedInRen);
    // ^convert txGas from wBTC to renBTC
  }

  function loan(
    address to,
    address asset,
    uint256 amount,
    uint256 nonce,
    address module,
    bytes memory data,
    bytes memory userSignature
  ) public onlyUnderwriter {
    require(approvedModules[module], "!approved");
    uint256 _gasBefore = gasleft();
    ZeroLib.LoanParams memory params = ZeroLib.LoanParams({
      to: to,
      asset: asset,
      amount: amount,
      nonce: nonce,
      module: module,
      data: data
    });
    bytes32 digest = toTypedDataHash(params, msg.sender);
    require(ECDSA.recover(digest, userSignature) == params.to, "invalid signature");
    require(loanStatus[digest].status == ZeroLib.LoanStatusCode.UNINITIALIZED, "already spent this loan");
    loanStatus[digest] = ZeroLib.LoanStatus({ underwriter: msg.sender, status: ZeroLib.LoanStatusCode.UNPAID });
    uint256 actual = params.amount.sub(params.amount.mul(uint256(25e15)).div(1e18));

    ZeroUnderwriterLock(lockFor(msg.sender)).trackOut(params.module, actual);
    uint256 _txGas = maxGasPrice.mul(maxGasRepay.add(maxGasLoan));
    _txGas = convertGasUsedToRen(_txGas, params.asset);
    // ^convert txGas from ETH to renBTC
    uint256 _amountSent = IStrategy(strategies[params.asset]).permissionedSend(
      module,
      deductFee(params.amount, params.asset).sub(_txGas)
    );
    IZeroModule(module).receiveLoan(params.to, params.asset, _amountSent, params.nonce, params.data);
    uint256 _gasRefund = Math.min(_gasBefore.sub(gasleft()), maxGasLoan).mul(maxGasPrice);
    IStrategy(strategies[params.asset]).permissionedEther(tx.origin, _gasRefund);
  }

  struct MetaLocals {
    uint256 gasUsed;
    uint256 gasUsedInRen;
    bytes32 digest;
    uint256 txGas;
    uint256 gasAtStart;
    uint256 gasRefund;
    uint256 balanceBefore;
    uint256 renBalanceDiff;
  }

  function meta(
    address from,
    address asset,
    address module,
    uint256 nonce,
    bytes memory data,
    bytes memory signature
  ) public onlyUnderwriter returns (uint256 gasValueAndFee) {
    require(approvedModules[module], "!approved");
    MetaLocals memory locals;
    locals.gasAtStart = gasleft();
    ZeroLib.MetaParams memory params = ZeroLib.MetaParams({
      from: from,
      asset: asset,
      module: module,
      nonce: nonce,
      data: data
    });

    ZeroUnderwriterLock lock = ZeroUnderwriterLock(lockFor(msg.sender));
    locals.digest = toMetaTypedDataHash(params, msg.sender);
    address recovered = ECDSA.recover(locals.digest, signature);
    require(recovered == params.from, "invalid signature");
    IZeroMeta(module).receiveMeta(from, asset, nonce, data);
    address converter = converters[IStrategy(strategies[params.asset]).nativeWrapper()][
      IStrategy(strategies[params.asset]).vaultWant()
    ];

    //calculate gas used
    locals.gasUsed = Math.min(locals.gasAtStart.sub(gasleft()), maxGasLoan);
    locals.gasRefund = locals.gasUsed.mul(maxGasPrice);
    locals.gasUsedInRen = convertGasUsedToRen(locals.gasRefund, params.asset);
    //deduct fee on the gas amount
    gasValueAndFee = addFee(locals.gasUsedInRen, params.asset);
    //loan out gas
    console.log(asset);
    IStrategy(strategies[params.asset]).permissionedEther(tx.origin, locals.gasRefund);
    locals.balanceBefore = IERC20(params.asset).balanceOf(address(this));
    console.log(locals.balanceBefore);
    lock.trackIn(gasValueAndFee);
    IZeroMeta(module).repayMeta(gasValueAndFee);
    locals.renBalanceDiff = IERC20(params.asset).balanceOf(address(this)).sub(locals.balanceBefore);
    console.log(IERC20(params.asset).balanceOf(address(this)));
    require(locals.renBalanceDiff >= locals.gasUsedInRen, "not enough provided for gas");
    depositAll(params.asset);
  }

  function toERC20PermitDigest(
    address token,
    address owner,
    address spender,
    uint256 value,
    uint256 deadline
  ) internal view returns (bytes32 result) {
    result = keccak256(
      abi.encodePacked(
        "\x19\x01",
        IERC2612Permit(token).DOMAIN_SEPARATOR(),
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, IERC2612Permit(token).nonces(owner), deadline))
      )
    );
  }

  function computeBurnNonce(
    address asset,
    uint256 amount,
    uint256 deadline,
    uint256 nonce,
    bytes memory destination
  ) public view returns (uint256 result) {
    result = uint256(keccak256(abi.encodePacked(asset, amount, deadline, nonce, destination)));
    while (result < block.timestamp) {
      // negligible probability of this
      result = uint256(keccak256(abi.encodePacked(result)));
    }
  }

  function burn(
    address to,
    address asset,
    uint256 amount,
    uint256 deadline,
    bytes memory destination,
    bytes memory signature
  ) public onlyUnderwriter {
    require(block.timestamp < deadline, "!deadline");
    {
      (uint8 v, bytes32 r, bytes32 s) = SplitSignatureLib.splitSignature(signature);
      uint256 nonce = IERC2612Permit(asset).nonces(to);
      IERC2612Permit(asset).permit(
        to,
        address(this),
        nonce,
        computeBurnNonce(asset, amount, deadline, nonce, destination),
        true,
        v,
        r,
        s
      );
    }
    IERC20(asset).transferFrom(to, address(this), amount);
    uint256 gasUsed = maxGasPrice.mul(maxGasRepay.add(maxGasBurn));
    IStrategy(strategies[asset]).permissionedEther(tx.origin, gasUsed);
    uint256 gasInRen = convertGasUsedToRen(gasUsed, asset);
    uint256 actualAmount = deductFee(amount.sub(gasInRen), asset);
    IGateway gateway = IGatewayRegistry(gatewayRegistry).getGatewayByToken(asset);
    require(IERC20(asset).approve(address(gateway), actualAmount), "!approve");
    gateway.burn(destination, actualAmount);
    depositAll(asset);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity >=0.6.0;

interface IZeroMeta {
  function receiveMeta(
    address from,
    address asset,
    uint256 nonce,
    bytes memory data
  ) external;

  function repayMeta(uint256 value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IZeroModule {
  function repayLoan(
    address _to,
    address _asset,
    uint256 _actualAmount,
    uint256 _amount,
    bytes memory _data
  ) external;

  function receiveLoan(
    address _to,
    address _asset,
    uint256 _actual,
    uint256 _nonce,
    bytes memory _data
  ) external;

  function computeReserveRequirement(uint256 _in) external view returns (uint256);

  function want() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import { IZeroModule } from "../interfaces/IZeroModule.sol";
import { Initializable } from "oz410/proxy/Initializable.sol";
import { IERC20 } from "oz410/token/ERC20/ERC20.sol";
import { IERC721 } from "oz410/token/ERC721/IERC721.sol";
import { SafeMath } from "oz410/math/SafeMath.sol";
import { IyVault } from "../interfaces/IyVault.sol";
import { ZeroController } from "../controllers/ZeroController.sol";
import { ZeroLib } from "../libraries/ZeroLib.sol";
import { SafeERC20 } from "oz410/token/ERC20/SafeERC20.sol";

import "hardhat/console.sol";

/**
@title contract to hold locked underwriter funds while the underwriter is active
@author raymondpulver
*/
contract ZeroUnderwriterLock is Initializable {
  using SafeMath for *;
  using SafeERC20 for *;
  ZeroController public controller;
  address public vault;
  ZeroLib.BalanceSheet internal _balanceSheet;

  modifier onlyController() {
    require(msg.sender == address(controller), "!controller");
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == owner(), "must be called by owner");
    _;
  }

  function balanceSheet()
    public
    view
    returns (
      uint256 loaned,
      uint256 required,
      uint256 repaid
    )
  {
    (loaned, required, repaid) = (uint256(_balanceSheet.loaned), uint256(_balanceSheet.required), _balanceSheet.repaid);
  }

  function owed() public view returns (uint256 result) {
    if (_balanceSheet.loaned >= _balanceSheet.repaid) {
      result = uint256(_balanceSheet.loaned).sub(_balanceSheet.repaid);
    } else {
      result = 0;
    }
  }

  function reserve() public view returns (uint256 result) {
    result = IyVault(vault).balanceOf(address(this)).mul(IyVault(vault).getPricePerFullShare()).div(uint256(1 ether));
  }

  function owner() public view returns (address result) {
    result = IERC721(address(controller)).ownerOf(uint256(uint160(address(this))));
  }

  /**
  @notice sets the owner to the ZeroUnderwriterNFT
  @param _vault the address of the LP token which will be either burned or redeemed when the NFT is destroyed
  */
  function initialize(address _vault) public {
    controller = ZeroController(msg.sender);
    vault = _vault;
  }

  /**
  @notice send back non vault tokens if they are stuck
  @param _token the token to send the entire balance of to the sender
  */
  function skim(address _token) public {
    require(address(vault) != _token, "cannot skim vault token");
    IERC20(_token).safeTransfer(msg.sender, IERC20(_token).balanceOf(address(this)));
  }

  /**
  @notice destroy this contract and send all vault tokens to NFT contract
  */
  function burn(address receiver) public onlyController {
    require(
      IyVault(vault).transfer(receiver, IyVault(vault).balanceOf(address(this))),
      "failed to transfer vault token to receiver"
    );
    selfdestruct(payable(msg.sender));
  }

  function trackOut(address module, uint256 amount) public {
    require(msg.sender == address(controller), "!controller");
    uint256 loanedAfter = uint256(_balanceSheet.loaned).add(amount);
    uint256 _owed = owed();
    (_balanceSheet.loaned, _balanceSheet.required) = (
      uint128(loanedAfter),
      uint128(
        uint256(_balanceSheet.required).mul(_owed).div(uint256(1 ether)).add(
          IZeroModule(module).computeReserveRequirement(amount).mul(uint256(1 ether)).div(_owed.add(amount))
        )
      )
    );
  }

  function _logSheet() internal view {
    console.log("required", _balanceSheet.required);
    console.log("loaned", _balanceSheet.loaned);
    console.log("repaid", _balanceSheet.repaid);
  }

  function trackIn(uint256 amount) public {
    require(msg.sender == address(controller), "!controller");
    uint256 _owed = owed();
    uint256 _adjusted = uint256(_balanceSheet.required).mul(_owed).div(uint256(1 ether));
    _balanceSheet.required = _owed < amount || _adjusted < amount
      ? uint128(0)
      : uint128(_adjusted.sub(amount).mul(uint256(1 ether)).div(_owed.sub(amount)));
    _balanceSheet.repaid = _balanceSheet.repaid.add(amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

import "oz410/token/ERC20/IERC20.sol";
import "oz410/math/SafeMath.sol";
import "oz410/utils/Address.sol";
import "oz410/token/ERC20/SafeERC20.sol";
import "oz410/proxy/Initializable.sol";

import "../interfaces/IConverter.sol";
import "../interfaces/IOneSplitAudit.sol";
import "../interfaces/IStrategy.sol";

contract ControllerUpgradeable {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  address public governance;
  address public strategist;

  address public onesplit;
  address public rewards;
  mapping(address => address) public vaults;
  mapping(address => address) public strategies;
  mapping(address => mapping(address => address)) public converters;

  mapping(address => mapping(address => bool)) public approvedStrategies;

  uint256 public split = 500;
  uint256 public constant max = 10000;

  function __Controller_init_unchained(address _rewards) internal {
    governance = msg.sender;
    strategist = msg.sender;
    onesplit = address(0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e);
    rewards = _rewards;
  }

  function setRewards(address _rewards) public {
    require(msg.sender == governance, "!governance");
    rewards = _rewards;
  }

  function setStrategist(address _strategist) public {
    require(msg.sender == governance, "!governance");
    strategist = _strategist;
  }

  function setSplit(uint256 _split) public {
    require(msg.sender == governance, "!governance");
    split = _split;
  }

  function setOneSplit(address _onesplit) public {
    require(msg.sender == governance, "!governance");
    onesplit = _onesplit;
  }

  function setGovernance(address _governance) public {
    require(msg.sender == governance, "!governance");
    governance = _governance;
  }

  function setVault(address _token, address _vault) public {
    require(msg.sender == strategist || msg.sender == governance, "!strategist");
    require(vaults[_token] == address(0), "vault");
    vaults[_token] = _vault;
  }

  function approveStrategy(address _token, address _strategy) public {
    require(msg.sender == governance, "!governance");
    approvedStrategies[_token][_strategy] = true;
  }

  function revokeStrategy(address _token, address _strategy) public {
    require(msg.sender == governance, "!governance");
    approvedStrategies[_token][_strategy] = false;
  }

  function setConverter(
    address _input,
    address _output,
    address _converter
  ) public {
    require(msg.sender == strategist || msg.sender == governance, "!strategist");
    converters[_input][_output] = _converter;
  }

  function setStrategy(
    address _token,
    address _strategy,
    bool _abandon
  ) public {
    require(msg.sender == strategist || msg.sender == governance, "!strategist");
    require(approvedStrategies[_token][_strategy] == true, "!approved");

    address _current = strategies[_token];
    if (_current != address(0) || _abandon) {
      IStrategy(_current).withdrawAll();
    }
    strategies[_token] = _strategy;
  }

  function earn(address _token, uint256 _amount) public {
    address _strategy = strategies[_token];
    address _want = IStrategy(_strategy).want();
    if (_want != _token) {
      address converter = converters[_token][_want];
      IERC20(_token).safeTransfer(converter, _amount);
      _amount = IConverter(converter).convert(_strategy);
      IERC20(_want).safeTransfer(_strategy, _amount);
    } else {
      IERC20(_token).safeTransfer(_strategy, _amount);
    }
    IStrategy(_strategy).deposit();
  }

  function _balanceOf(address _token) internal view virtual returns (uint256) {
    return IStrategy(strategies[_token]).balanceOf();
  }

  function balanceOf(address _token) public view virtual returns (uint256) {
    return _balanceOf(_token);
  }

  function withdrawAll(address _token) public {
    require(msg.sender == strategist || msg.sender == governance, "!strategist");
    IStrategy(strategies[_token]).withdrawAll();
  }

  function inCaseTokensGetStuck(address _token, uint256 _amount) public {
    require(msg.sender == strategist || msg.sender == governance, "!governance");
    IERC20(_token).safeTransfer(msg.sender, _amount);
  }

  function inCaseStrategyTokenGetStuck(address _strategy, address _token) public {
    require(msg.sender == strategist || msg.sender == governance, "!governance");
    IStrategy(_strategy).withdraw(_token);
  }

  function getExpectedReturn(
    address _strategy,
    address _token,
    uint256 parts
  ) public view returns (uint256 expected) {
    uint256 _balance = IERC20(_token).balanceOf(_strategy);
    address _want = IStrategy(_strategy).want();
    (expected, ) = IOneSplitAudit(onesplit).getExpectedReturn(_token, _want, _balance, parts, 0);
  }

  // Only allows to withdraw non-core strategy tokens ~ this is over and above normal yield
  function yearn(
    address _strategy,
    address _token,
    uint256 parts
  ) public {
    require(msg.sender == strategist || msg.sender == governance, "!governance");
    // This contract should never have value in it, but just incase since this is a public call
    uint256 _before = IERC20(_token).balanceOf(address(this));
    IStrategy(_strategy).withdraw(_token);
    uint256 _after = IERC20(_token).balanceOf(address(this));
    if (_after > _before) {
      uint256 _amount = _after.sub(_before);
      address _want = IStrategy(_strategy).want();
      uint256[] memory _distribution;
      uint256 _expected;
      _before = IERC20(_want).balanceOf(address(this));
      IERC20(_token).safeApprove(onesplit, 0);
      IERC20(_token).safeApprove(onesplit, _amount);
      (_expected, _distribution) = IOneSplitAudit(onesplit).getExpectedReturn(_token, _want, _amount, parts, 0);
      IOneSplitAudit(onesplit).swap(_token, _want, _amount, _expected, _distribution, 0);
      _after = IERC20(_want).balanceOf(address(this));
      if (_after > _before) {
        _amount = _after.sub(_before);
        uint256 _reward = _amount.mul(split).div(max);
        earn(_want, _amount.sub(_reward));
        IERC20(_want).safeTransfer(rewards, _reward);
      }
    }
  }

  function _withdraw(address _token, uint256 _amount) internal virtual {
    IStrategy(strategies[_token]).withdraw(_amount);
  }

  function withdraw(address _token, uint256 _amount) public {
    require(msg.sender == vaults[_token], "!vault");
    _withdraw(_token, _amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;
    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = _getChainId();
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view virtual returns (bytes32) {
        if (_getChainId() == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                _getChainId(),
                address(this)
            )
        );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _getChainId() private view returns (uint256 chainId) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

import { Implementation } from "./Implementation.sol";
import { Create2 } from "oz410/utils/Create2.sol";

/**
@title clone factory library
@notice deploys implementation or clones
*/
library FactoryLib {
  function assembleCreationCode(address implementation) internal pure returns (bytes memory result) {
    result = new bytes(0x37);
    bytes20 targetBytes = bytes20(implementation);
    assembly {
      let clone := add(result, 0x20)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
    }
  }

  function computeAddress(
    address creator,
    address implementation,
    bytes32 salt
  ) internal pure returns (address result) {
    result = Create2.computeAddress(salt, keccak256(assembleCreationCode(implementation)), creator);
  }

  function computeImplementationAddress(
    address creator,
    bytes32 bytecodeHash,
    string memory id
  ) internal pure returns (address result) {
    result = Create2.computeAddress(keccak256(abi.encodePacked(id)), bytecodeHash, creator);
  }

  /// @notice Deploys a given master Contract as a clone.
  /// Any ETH transferred with this call is forwarded to the new clone.
  /// Emits `LogDeploy`.
  /// @param implementation Address of implementation
  /// @param salt Salt to use
  /// @return cloneAddress Address of the created clone contract.
  function deploy(address implementation, bytes32 salt) internal returns (address cloneAddress) {
    bytes memory creationCode = assembleCreationCode(implementation);
    assembly {
      cloneAddress := create2(0, add(0x20, creationCode), 0x37, salt)
    }
  }

  function deployImplementation(bytes memory creationCode, string memory id) internal returns (address implementation) {
    bytes32 salt = keccak256(abi.encodePacked(id));
    assembly {
      implementation := create2(0, add(0x20, creationCode), mload(creationCode), salt)
    }
  }
}

// SPDX-License-Identifier: MIT

import { ZeroUnderwriterLock } from "../../underwriter/ZeroUnderwriterLock.sol";

library ZeroUnderwriterLockBytecodeLib {
  function get() external pure returns (bytes memory result) {
    result = type(ZeroUnderwriterLock).creationCode;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import { IERC20 } from "oz410/token/ERC20/IERC20.sol";

import "./IGateway.sol";

/// @notice GatewayRegistry is a mapping from assets to their associated
/// RenERC20 and Gateway contracts.
interface IGatewayRegistry {
  /// @dev The symbol is included twice because strings have to be hashed
  /// first in order to be used as a log index/topic.
  event LogGatewayRegistered(
    string _symbol,
    string indexed _indexedSymbol,
    address indexed _tokenAddress,
    address indexed _gatewayAddress
  );
  event LogGatewayDeregistered(
    string _symbol,
    string indexed _indexedSymbol,
    address indexed _tokenAddress,
    address indexed _gatewayAddress
  );
  event LogGatewayUpdated(
    address indexed _tokenAddress,
    address indexed _currentGatewayAddress,
    address indexed _newGatewayAddress
  );

  /// @dev To get all the registered gateways use count = 0.
  function getGateways(address _start, uint256 _count) external view returns (address[] memory);

  /// @dev To get all the registered RenERC20s use count = 0.
  function getRenTokens(address _start, uint256 _count) external view returns (address[] memory);

  /// @notice Returns the Gateway contract for the given RenERC20
  ///         address.
  ///
  /// @param _tokenAddress The address of the RenERC20 contract.
  function getGatewayByToken(address _tokenAddress) external view returns (IGateway);

  /// @notice Returns the Gateway contract for the given RenERC20
  ///         symbol.
  ///
  /// @param _tokenSymbol The symbol of the RenERC20 contract.
  function getGatewayBySymbol(string calldata _tokenSymbol) external view returns (IGateway);

  /// @notice Returns the RenERC20 address for the given token symbol.
  ///
  /// @param _tokenSymbol The symbol of the RenERC20 contract to
  ///        lookup.
  function getTokenBySymbol(string calldata _tokenSymbol) external view returns (IERC20);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface StrategyAPI {
  function name() external view returns (string memory);

  function vault() external view returns (address);

  function nativeWrapper() external view returns (address);

  function want() external view returns (address);

  function vaultWant() external view returns (address);

  function apiVersion() external pure returns (string memory);

  function keeper() external view returns (address);

  function isActive() external view returns (bool);

  function delegatedAssets() external view returns (uint256);

  function estimatedTotalAssets() external view returns (uint256);

  function tendTrigger(uint256 callCost) external view returns (bool);

  function tend() external;

  function harvestTrigger(uint256 callCost) external view returns (bool);

  function harvest() external;

  event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);
}

abstract contract IStrategy is StrategyAPI {
  function permissionedSend(address _module, uint256 _amount) external virtual returns (uint256);

  function withdrawAll() external virtual;

  function deposit() external virtual;

  function balanceOf() external view virtual returns (uint256);

  function withdraw(uint256) external virtual;

  function withdraw(address) external virtual;

  function permissionedEther(address, uint256) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

import { FactoryLib } from "./factory/FactoryLib.sol";
import { ZeroUnderwriterLock } from "../underwriter/ZeroUnderwriterLock.sol";

/**
@title lockFor implementation
@author raymondpulver
*/
library LockForImplLib {
  function lockFor(
    address nft,
    address underwriterLockImpl,
    address underwriter
  ) internal view returns (ZeroUnderwriterLock result) {
    result = ZeroUnderwriterLock(
      FactoryLib.computeAddress(nft, underwriterLockImpl, bytes32(uint256(uint160(underwriter))))
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.8.0;

interface IConverter {
  function convert(address) external returns (uint256);

  function estimate(uint256) external view returns (uint256);
}

pragma solidity >=0.6.0;
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ControllerUpgradeable } from "./ControllerUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/drafts/EIP712Upgradeable.sol";
import { ZeroLib } from "../libraries/ZeroLib.sol";

contract ZeroControllerTemplate is ControllerUpgradeable, OwnableUpgradeable, EIP712Upgradeable {
  uint256 internal maxGasPrice = 100e9;
  uint256 internal maxGasRepay = 250000;
  uint256 internal maxGasLoan = 500000;
  string internal constant UNDERWRITER_LOCK_IMPLEMENTATION_ID = "zero.underwriter.lock-implementation";
  address internal underwriterLockImpl;
  mapping(bytes32 => ZeroLib.LoanStatus) public loanStatus;
  bytes32 internal constant ZERO_DOMAIN_SALT = 0xb225c57bf2111d6955b97ef0f55525b5a400dc909a5506e34b102e193dd53406;
  bytes32 internal constant ZERO_DOMAIN_NAME_HASH = keccak256("ZeroController.RenVMBorrowMessage");
  bytes32 internal constant ZERO_DOMAIN_VERSION_HASH = keccak256("v2");
  bytes32 internal constant ZERO_RENVM_BORROW_MESSAGE_TYPE_HASH =
    keccak256("RenVMBorrowMessage(address module,uint256 amount,address underwriter,uint256 pNonce,bytes pData)");
  bytes32 internal constant TYPE_HASH = keccak256("TransferRequest(address asset,uint256 amount)");
  bytes32 internal ZERO_DOMAIN_SEPARATOR;
  bytes32 internal constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
  mapping(uint256 => address) public ownerOf;

  uint256 public fee;
  address public gatewayRegistry;
  mapping(address => uint256) public baseFeeByAsset;
  mapping(address => bool) public approvedModules;
  uint256 internal maxGasBurn = 500000;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.8.0;

interface IOneSplitAudit {
  function swap(
    address fromToken,
    address destToken,
    uint256 amount,
    uint256 minReturn,
    uint256[] calldata distribution,
    uint256 flags
  ) external payable returns (uint256 returnAmount);

  function getExpectedReturn(
    address fromToken,
    address destToken,
    uint256 amount,
    uint256 parts,
    uint256 flags // See constants in IOneSplit.sol
  ) external view returns (uint256 returnAmount, uint256[] memory distribution);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

/**
@title must be inherited by a contract that will be deployed with ZeroFactoryLib
@author raymondpulver
*/
abstract contract Implementation {
  /**
  @notice ensure the contract cannot be initialized twice
  */
  function lock() public virtual {
    // no other logic
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: MIT

import { Ownable } from "oz410/access/Ownable.sol";
import { ZeroController } from "../controllers/ZeroController.sol";

/**
@title contract that is the simplest underwriter, just a proxy with an owner tag
@author raymondpulver
*/
contract TrivialUnderwriter is Ownable {
  address payable public immutable controller;

  constructor(address payable _controller) Ownable() {
    controller = _controller;
  }

  function bubble(bool success, bytes memory response) internal pure {
    assembly {
      if iszero(success) {
        revert(add(0x20, response), mload(response))
      }
      return(add(0x20, response), mload(response))
    }
  }

  /**
  @notice proxy a regular call to an arbitrary contract
  @param target the to address of the transaction
  @param data the calldata for the transaction
  */
  function proxy(address payable target, bytes memory data) public payable onlyOwner {
    (bool success, bytes memory response) = target.call{ value: msg.value }(data);
    bubble(success, response);
  }

  function loan(
    address to,
    address asset,
    uint256 amount,
    uint256 nonce,
    address module,
    bytes memory data,
    bytes memory userSignature
  ) public {
    require(msg.sender == owner(), "must be called by owner");
    ZeroController(controller).loan(to, asset, amount, nonce, module, data, userSignature);
  }

  function repay(
    address underwriter,
    address to,
    address asset,
    uint256 amount,
    uint256 actualAmount,
    uint256 nonce,
    address module,
    bytes32 nHash,
    bytes memory data,
    bytes memory signature
  ) public {
    require(msg.sender == owner(), "must be called by owner");
    ZeroController(controller).repay(
      underwriter,
      to,
      asset,
      amount,
      actualAmount,
      nonce,
      module,
      nHash,
      data,
      signature
    );
  }

  /**
  @notice handles any other call and forwards to the controller
  */
  fallback() external payable {
    require(msg.sender == owner(), "must be called by owner");
    (bool success, bytes memory response) = controller.call{ value: msg.value }(msg.data);
    bubble(success, response);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import "oz410/token/ERC20/IERC20.sol";
import "oz410/math/SafeMath.sol";
import "oz410/utils/Address.sol";
import "oz410/token/ERC20/SafeERC20.sol";
import "oz410/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "oz410/access/Ownable.sol";

import "../interfaces/yearn/IController.sol";

contract yVaultUpgradeable is ERC20Upgradeable {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  IERC20 public token;

  uint256 public min = 25;
  uint256 public constant max = 30;

  address public governance;
  address public controller;

  mapping(address => bool) public whitelist;

  modifier isWhitelisted() {
    require(whitelist[msg.sender], "!whitelist");
    _;
  }

  modifier onlyGovernance() {
    require(msg.sender == governance);
    _;
  }

  function addToWhitelist(address[] calldata entries) external onlyGovernance {
    for (uint256 i = 0; i < entries.length; i++) {
      address entry = entries[i];
      require(entry != address(0));

      whitelist[entry] = true;
    }
  }

  function removeFromWhitelist(address[] calldata entries) external onlyGovernance {
    for (uint256 i = 0; i < entries.length; i++) {
      address entry = entries[i];
      whitelist[entry] = false;
    }
  }

  function __yVault_init_unchained(
    address _token,
    address _controller,
    string memory _name,
    string memory _symbol
  ) public initializer {
    __ERC20_init_unchained(_name, _symbol);
    token = IERC20(_token);
    governance = msg.sender;
    controller = _controller;
  }

  function decimals() public view override returns (uint8) {
    return ERC20(address(token)).decimals();
  }

  function balance() public view returns (uint256) {
    return token.balanceOf(address(this)).add(IController(controller).balanceOf(address(token)));
  }

  function setMin(uint256 _min) external {
    require(msg.sender == governance, "!governance");
    min = _min;
  }

  function setGovernance(address _governance) public {
    require(msg.sender == governance, "!governance");
    governance = _governance;
  }

  function setController(address _controller) public {
    require(msg.sender == governance, "!governance");
    controller = _controller;
  }

  // Custom logic in here for how much the vault allows to be borrowed
  // Sets minimum required on-hand to keep small withdrawals cheap
  function available() public view returns (uint256) {
    return token.balanceOf(address(this)).mul(min).div(max);
  }

  function earn() public {
    uint256 _bal = available();
    token.safeTransfer(controller, _bal);
    IController(controller).earn(address(token), _bal);
  }

  function depositAll() external {
    deposit(token.balanceOf(msg.sender));
  }

  function deposit(uint256 _amount) public {
    uint256 _pool = balance();
    uint256 _before = token.balanceOf(address(this));
    token.safeTransferFrom(msg.sender, address(this), _amount);
    uint256 _after = token.balanceOf(address(this));
    _amount = _after.sub(_before); // Additional check for deflationary tokens
    uint256 shares = 0;
    if (totalSupply() == 0) {
      shares = _amount;
    } else {
      shares = (_amount.mul(totalSupply())).div(_pool);
    }
    _mint(msg.sender, shares);
  }

  function withdrawAll() external {
    withdraw(balanceOf(msg.sender));
  }

  // Used to swap any borrowed reserve over the debt limit to liquidate to 'token'
  function harvest(address reserve, uint256 amount) external {
    require(msg.sender == controller, "!controller");
    require(reserve != address(token), "token");
    IERC20(reserve).safeTransfer(controller, amount);
  }

  // No rebalance implementation for lower fees and faster swaps
  function withdraw(uint256 _shares) public {
    uint256 r = (balance().mul(_shares)).div(totalSupply());
    _burn(msg.sender, _shares);

    // Check balance
    uint256 b = token.balanceOf(address(this));
    if (b < r) {
      uint256 _withdraw = r.sub(b);
      IController(controller).withdraw(address(token), _withdraw);
      uint256 _after = token.balanceOf(address(this));
      uint256 _diff = _after.sub(b);
      if (_diff < _withdraw) {
        r = b.add(_diff);
      }
    }

    token.safeTransfer(msg.sender, r);
  }

  function getPricePerFullShare() public view returns (uint256) {
    return balance().mul(1e18).div(totalSupply());
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.8.0;

interface IController {
  function withdraw(address, uint256) external;

  function balanceOf(address) external view returns (uint256);

  function earn(address, uint256) external;

  function want(address) external view returns (address);

  function rewards() external view returns (address);

  function vaults(address) external view returns (address);

  function strategies(address) external view returns (address);

  function approvedStrategies(address, address) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import "oz410/token/ERC20/IERC20.sol";
import "oz410/math/SafeMath.sol";
import "oz410/utils/Address.sol";
import "oz410/token/ERC20/SafeERC20.sol";
import "oz410/token/ERC20/ERC20.sol";
import "oz410/access/Ownable.sol";

import "../interfaces/yearn/IController.sol";

contract yVault is ERC20 {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  IERC20 public token;

  uint256 public min = 25;
  uint256 public constant max = 30;

  address public governance;
  address public controller;

  constructor(
    address _token,
    address _controller,
    string memory _name,
    string memory _symbol
  ) ERC20(_name, _symbol) {
    token = IERC20(_token);
    governance = msg.sender;
    controller = _controller;
  }

  function decimals() public view override returns (uint8) {
    return ERC20(address(token)).decimals();
  }

  function balance() public view returns (uint256) {
    return token.balanceOf(address(this)).add(IController(controller).balanceOf(address(token)));
  }

  function setMin(uint256 _min) external {
    require(msg.sender == governance, "!governance");
    min = _min;
  }

  function setGovernance(address _governance) public {
    require(msg.sender == governance, "!governance");
    governance = _governance;
  }

  function setController(address _controller) public {
    require(msg.sender == governance, "!governance");
    controller = _controller;
  }

  // Custom logic in here for how much the vault allows to be borrowed
  // Sets minimum required on-hand to keep small withdrawals cheap
  function available() public view returns (uint256) {
    return token.balanceOf(address(this)).mul(min).div(max);
  }

  function earn() public {
    uint256 _bal = available();
    token.safeTransfer(controller, _bal);
    IController(controller).earn(address(token), _bal);
  }

  function depositAll() external {
    deposit(token.balanceOf(msg.sender));
  }

  function deposit(uint256 _amount) public {
    uint256 _pool = balance();
    uint256 _before = token.balanceOf(address(this));
    token.safeTransferFrom(msg.sender, address(this), _amount);
    uint256 _after = token.balanceOf(address(this));
    _amount = _after.sub(_before); // Additional check for deflationary tokens
    uint256 shares = 0;
    if (totalSupply() == 0) {
      shares = _amount;
    } else {
      shares = (_amount.mul(totalSupply())).div(_pool);
    }
    _mint(msg.sender, shares);
  }

  function withdrawAll() external {
    withdraw(balanceOf(msg.sender));
  }

  // Used to swap any borrowed reserve over the debt limit to liquidate to 'token'
  function harvest(address reserve, uint256 amount) external {
    require(msg.sender == controller, "!controller");
    require(reserve != address(token), "token");
    IERC20(reserve).safeTransfer(controller, amount);
  }

  // No rebalance implementation for lower fees and faster swaps
  function withdraw(uint256 _shares) public {
    uint256 r = (balance().mul(_shares)).div(totalSupply());
    _burn(msg.sender, _shares);

    // Check balance
    uint256 b = token.balanceOf(address(this));
    if (b < r) {
      uint256 _withdraw = r.sub(b);
      IController(controller).withdraw(address(token), _withdraw);
      uint256 _after = token.balanceOf(address(this));
      uint256 _diff = _after.sub(b);
      if (_diff < _withdraw) {
        r = b.add(_diff);
      }
    }

    token.safeTransfer(msg.sender, r);
  }

  function getPricePerFullShare() public view returns (uint256) {
    return balance().mul(1e18).div(totalSupply());
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import { yVault } from "../vendor/yearn/vaults/yVault.sol";
import { IERC20 } from "oz410/token/ERC20/IERC20.sol";
import { ERC20 } from "oz410/token/ERC20/ERC20.sol";

contract DummyVault is ERC20 {
  address public immutable want;
  address public immutable controller;

  constructor(
    address _want,
    address _controller,
    string memory _name,
    string memory _symbol
  ) ERC20(_name, _symbol) {
    want = _want;
    controller = _controller;
  }

  function estimateShares(uint256 _amount) external view returns (uint256) {
    return _amount;
  }

  function deposit(uint256 _amount) public returns (uint256) {
    IERC20(want).transferFrom(msg.sender, address(this), _amount);
    _mint(msg.sender, _amount);
    return _amount;
  }

  function withdraw(uint256 _amount) public returns (uint256) {
    _burn(msg.sender, _amount);
    IERC20(want).transfer(msg.sender, _amount);
    return _amount;
  }

  function pricePerShare() public pure returns (uint256) {
    return uint256(1e18);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "oz410/token/ERC20/IERC20.sol";
import "oz410/math/SafeMath.sol";
import "oz410/utils/Address.sol";
import "oz410/token/ERC20/SafeERC20.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IyVault.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IConverter.sol";
import { StrategyAPI } from "../interfaces/IStrategy.sol";
import { IController } from "../interfaces/IController.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { ICurvePool } from "../interfaces/ICurvePool.sol";
import { IZeroModule } from "../interfaces/IZeroModule.sol";

contract StrategyRenVMEthereum {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  address public immutable vault;
  address public immutable nativeWrapper;
  address public immutable want;
  int128 public constant wantIndex = 0;

  address public immutable vaultWant;
  int128 public constant vaultWantIndex = 1;

  string public constant name = "0confirmation RenVM Strategy";
  bool public constant isActive = true;

  uint256 public constant wantReserve = 1000000;
  uint256 public constant gasReserve = uint256(1e17);
  address public immutable controller;
  address public governance;
  address public strategist;

  modifier onlyController() {
    require(msg.sender == controller, "!controller");
    _;
  }

  constructor(
    address _controller,
    address _want,
    address _nativeWrapper,
    address _vault,
    address _vaultWant
  ) {
    nativeWrapper = _nativeWrapper;
    want = _want;
    vault = _vault;
    vaultWant = _vaultWant;
    governance = msg.sender;
    strategist = msg.sender;
    controller = _controller;
    IERC20(_vaultWant).safeApprove(address(_vault), type(uint256).max);
  }

  receive() external payable {}

  function deposit() external virtual {
    //First conditional handles having too much of want in the Strategy
    uint256 _want = IERC20(want).balanceOf(address(this)); //amount of tokens we want
    if (_want > wantReserve) {
      // Then we can deposit excess tokens into the vault
      address converter = IController(controller).converters(want, vaultWant);
      require(converter != address(0x0), "!converter");
      uint256 _excess = _want.sub(wantReserve);
      require(IERC20(want).transfer(converter, _excess), "!transfer");
      uint256 _amountOut = IConverter(converter).convert(address(0x0));
      IyVault(vault).deposit(_amountOut);
    }
    //Second conditional handles having too little of gasWant in the Strategy

    uint256 _gasWant = address(this).balance; //ETH balance
    if (_gasWant < gasReserve) {
      // if ETH balance < ETH reserve
      _gasWant = gasReserve.sub(_gasWant);
      address _converter = IController(controller).converters(nativeWrapper, vaultWant);
      uint256 _vaultWant = IConverter(_converter).estimate(_gasWant); //_gasWant is estimated from wETH to wBTC
      uint256 _sharesDeficit = estimateShares(_vaultWant); //Estimate shares of wBTC
      // Works up to this point
      require(IERC20(vault).balanceOf(address(this)) > _sharesDeficit, "!enough"); //revert if shares needed > shares held
      uint256 _amountOut = IyVault(vault).withdraw(_sharesDeficit);
      address converter = IController(controller).converters(vaultWant, nativeWrapper);
      IERC20(vaultWant).transfer(converter, _amountOut);
      _amountOut = IConverter(converter).convert(address(this));
      address _unwrapper = IController(controller).converters(nativeWrapper, address(0x0));
      IERC20(nativeWrapper).transfer(_unwrapper, _amountOut);
      IConverter(_unwrapper).convert(address(this));
    }
  }

  function _withdraw(uint256 _amount, address _asset) private returns (uint256) {
    require(_asset == want || _asset == vaultWant, "asset not supported");
    if (_amount == 0) {
      return 0;
    }
    address converter = IController(controller).converters(want, vaultWant);
    // _asset is wBTC and want is renBTC
    if (_asset == want) {
      // if asset is what the strategy wants
      //then we can't directly withdraw it
      _amount = IConverter(converter).estimate(_amount);
    }
    uint256 _shares = estimateShares(_amount);
    _amount = IyVault(vault).withdraw(_shares);
    if (_asset == want) {
      // if asset is what the strategy wants
      IConverter toWant = IConverter(IController(controller).converters(vaultWant, want));
      IERC20(vaultWant).transfer(address(toWant), _amount);
      _amount = toWant.convert(address(0x0));
    }
    return _amount;
  }

  function permissionedEther(address payable _target, uint256 _amount) external virtual onlyController {
    // _amount is the amount of ETH to refund
    if (_amount > gasReserve) {
      _amount = IConverter(IController(controller).converters(nativeWrapper, vaultWant)).estimate(_amount);
      uint256 _sharesDeficit = estimateShares(_amount);
      uint256 _amountOut = IyVault(vault).withdraw(_sharesDeficit);
      address _vaultConverter = IController(controller).converters(vaultWant, nativeWrapper);
      address _converter = IController(controller).converters(nativeWrapper, address(0x0));
      IERC20(vaultWant).transfer(_vaultConverter, _amountOut);
      _amount = IConverter(_vaultConverter).convert(address(this));
      IERC20(nativeWrapper).transfer(_converter, _amount);
      _amount = IConverter(_converter).convert(address(this));
    }
    _target.transfer(_amount);
  }

  function withdraw(uint256 _amount) external virtual onlyController {
    IERC20(want).safeTransfer(address(controller), _withdraw(_amount, want));
  }

  function withdrawAll() external virtual onlyController {
    IERC20(want).safeTransfer(address(controller), _withdraw(IERC20(vault).balanceOf(address(this)), want));
  }

  function balanceOf() external view virtual returns (uint256) {
    return IyVault(vault).balanceOf(address(this));
  }

  function estimateShares(uint256 _amount) internal virtual returns (uint256) {
    return _amount.mul(10**IyVault(vault).decimals()).div(IyVault(vault).pricePerShare());
  }

  function permissionedSend(address _module, uint256 _amount) external virtual onlyController returns (uint256) {
    uint256 _reserve = IERC20(want).balanceOf(address(this));
    address _want = IZeroModule(_module).want();
    if (_amount > _reserve || _want != want) {
      _amount = _withdraw(_amount, _want);
    }
    IERC20(_want).safeTransfer(_module, _amount);
    return _amount;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

interface IController {
  function governance() external view returns (address);

  function rewards() external view returns (address);

  function withdraw(address, uint256) external;

  function balanceOf(address) external view returns (uint256);

  function earn(address, uint256) external;

  function want(address) external view returns (address);

  function vaults(address) external view returns (address);

  function strategies(address) external view returns (address);

  function approvedStrategies(address, address) external view returns (bool);

  function converters(address, address) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

interface ICurvePool {
  function get_dy(
    int128,
    int128,
    uint256
  ) external view returns (uint256);

  function get_dy(
    uint256,
    uint256,
    uint256
  ) external view returns (uint256);

  function get_dy_underlying(
    int128,
    int128,
    uint256
  ) external view returns (uint256);

  function get_dy_underlying(
    uint256,
    uint256,
    uint256
  ) external view returns (uint256);

  function exchange(
    int128,
    int128,
    uint256,
    uint256
  ) external;

  function exchange(
    uint256,
    uint256,
    uint256,
    uint256
  ) external;

  function exchange_underlying(
    int128,
    int128,
    uint256,
    uint256
  ) external;

  function exchange_underlying(
    uint256,
    uint256,
    uint256,
    uint256
  ) external;

  function coins(int128) external view returns (address);

  function coins(int256) external view returns (address);

  function coins(uint128) external view returns (address);

  function coins(uint256) external view returns (address);

  function underlying_coins(int128) external view returns (address);

  function underlying_coins(uint128) external view returns (address);

  function underlying_coins(int256) external view returns (address);

  function underlying_coins(uint256) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "oz410/token/ERC20/IERC20.sol";
import "oz410/math/SafeMath.sol";
import "oz410/utils/Address.sol";
import "oz410/token/ERC20/SafeERC20.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IyVault.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IConverter.sol";
import { StrategyAPI } from "../interfaces/IStrategy.sol";
import { IController } from "../interfaces/IController.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { ICurvePool } from "../interfaces/ICurvePool.sol";
import { IZeroModule } from "../interfaces/IZeroModule.sol";

contract StrategyRenVMArbitrum {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  address public immutable vault;
  address public immutable nativeWrapper;
  address public immutable want;
  int128 public constant wantIndex = 0;

  address public immutable vaultWant;
  int128 public constant vaultWantIndex = 1;

  string public constant name = "0confirmation RenVM Strategy";
  bool public constant isActive = true;

  uint256 public constant wantReserve = 1000000;
  uint256 public constant gasReserve = uint256(1e17);
  address public immutable controller;
  address public governance;
  address public strategist;

  modifier onlyController() {
    require(msg.sender == controller, "!controller");
    _;
  }

  constructor(
    address _controller,
    address _want,
    address _nativeWrapper,
    address _vault,
    address _vaultWant
  ) {
    nativeWrapper = _nativeWrapper;
    want = _want;
    vault = _vault;
    vaultWant = _vaultWant;
    governance = msg.sender;
    strategist = msg.sender;
    controller = _controller;
    IERC20(_vaultWant).safeApprove(address(_vault), type(uint256).max);
  }

  receive() external payable {}

  function deposit() external virtual {
    //First conditional handles having too much of want in the Strategy
    uint256 _want = IERC20(want).balanceOf(address(this)); //amount of tokens we want
    if (_want > wantReserve) {
      // Then we can deposit excess tokens into the vault
      address converter = IController(controller).converters(want, vaultWant);
      require(converter != address(0x0), "!converter");
      uint256 _excess = _want.sub(wantReserve);
      require(IERC20(want).transfer(converter, _excess), "!transfer");
      uint256 _amountOut = IConverter(converter).convert(address(0x0));
      IyVault(vault).deposit(_amountOut);
    }
    //Second conditional handles having too little of gasWant in the Strategy

    uint256 _gasWant = address(this).balance; //ETH balance
    if (_gasWant < gasReserve) {
      // if ETH balance < ETH reserve
      _gasWant = gasReserve.sub(_gasWant);
      address _converter = IController(controller).converters(nativeWrapper, vaultWant);
      uint256 _vaultWant = IConverter(_converter).estimate(_gasWant); //_gasWant is estimated from wETH to wBTC
      uint256 _sharesDeficit = estimateShares(_vaultWant); //Estimate shares of wBTC
      // Works up to this point
      require(IERC20(vault).balanceOf(address(this)) > _sharesDeficit, "!enough"); //revert if shares needed > shares held
      uint256 _amountOut = IyVault(vault).withdraw(_sharesDeficit);
      address converter = IController(controller).converters(vaultWant, nativeWrapper);
      IERC20(vaultWant).transfer(converter, _amountOut);
      _amountOut = IConverter(converter).convert(address(this));
      address _unwrapper = IController(controller).converters(nativeWrapper, address(0x0));
      IERC20(nativeWrapper).transfer(_unwrapper, _amountOut);
      IConverter(_unwrapper).convert(address(this));
    }
  }

  function _withdraw(uint256 _amount, address _asset) private returns (uint256) {
    require(_asset == want || _asset == vaultWant, "asset not supported");
    if (_amount == 0) {
      return 0;
    }
    address converter = IController(controller).converters(want, vaultWant);
    // _asset is wBTC and want is renBTC
    if (_asset == want) {
      // if asset is what the strategy wants
      //then we can't directly withdraw it
      _amount = IConverter(converter).estimate(_amount);
    }
    uint256 _shares = estimateShares(_amount);
    _amount = IyVault(vault).withdraw(_shares);
    if (_asset == want) {
      // if asset is what the strategy wants
      IConverter toWant = IConverter(IController(controller).converters(vaultWant, want));
      IERC20(vaultWant).transfer(address(toWant), _amount);
      _amount = toWant.convert(address(0x0));
    }
    return _amount;
  }

  function permissionedEther(address payable _target, uint256 _amount) external virtual onlyController {
    // _amount is the amount of ETH to refund
    if (_amount > gasReserve) {
      _amount = IConverter(IController(controller).converters(nativeWrapper, vaultWant)).estimate(_amount);
      uint256 _sharesDeficit = estimateShares(_amount);
      uint256 _amountOut = IyVault(vault).withdraw(_sharesDeficit);
      address _vaultConverter = IController(controller).converters(vaultWant, nativeWrapper);
      address _converter = IController(controller).converters(nativeWrapper, address(0x0));
      IERC20(vaultWant).transfer(_vaultConverter, _amountOut);
      _amount = IConverter(_vaultConverter).convert(address(this));
      IERC20(nativeWrapper).transfer(_converter, _amount);
      _amount = IConverter(_converter).convert(address(this));
    }
    _target.transfer(_amount);
  }

  function withdraw(uint256 _amount) external virtual onlyController {
    IERC20(want).safeTransfer(address(controller), _withdraw(_amount, want));
  }

  function withdrawAll() external virtual onlyController {
    IERC20(want).safeTransfer(address(controller), _withdraw(IERC20(vault).balanceOf(address(this)), want));
  }

  function balanceOf() external view virtual returns (uint256) {
    return IyVault(vault).balanceOf(address(this));
  }

  function estimateShares(uint256 _amount) internal virtual returns (uint256) {
    return _amount.mul(10**IyVault(vault).decimals()).div(IyVault(vault).pricePerShare());
  }

  function permissionedSend(address _module, uint256 _amount) external virtual onlyController returns (uint256) {
    uint256 _reserve = IERC20(want).balanceOf(address(this));
    address _want = IZeroModule(_module).want();
    if (_amount > _reserve || _want != want) {
      _amount = _withdraw(_amount, _want);
    }
    IERC20(_want).safeTransfer(_module, _amount);
    return _amount;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "oz410/token/ERC20/IERC20.sol";
import "oz410/math/SafeMath.sol";
import "oz410/utils/Address.sol";
import "oz410/token/ERC20/SafeERC20.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IyVault.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IConverter.sol";
import { StrategyAPI } from "../interfaces/IStrategy.sol";
import { IController } from "../interfaces/IController.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { ICurvePool } from "../interfaces/ICurvePool.sol";
import { IZeroModule } from "../interfaces/IZeroModule.sol";

contract StrategyRenVM {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  address public immutable vault;
  address public immutable nativeWrapper;
  address public immutable want;
  int128 public constant wantIndex = 0;

  address public immutable vaultWant;
  int128 public constant vaultWantIndex = 1;

  string public constant name = "0confirmation RenVM Strategy";
  bool public constant isActive = true;

  uint256 public constant wantReserve = 1000000;
  uint256 public constant gasReserve = uint256(5 ether);
  address public immutable controller;
  address public governance;
  address public strategist;

  modifier onlyController() {
    require(msg.sender == controller, "!controller");
    _;
  }

  constructor(
    address _controller,
    address _want,
    address _nativeWrapper,
    address _vault,
    address _vaultWant
  ) {
    nativeWrapper = _nativeWrapper;
    want = _want;
    vault = _vault;
    vaultWant = _vaultWant;
    governance = msg.sender;
    strategist = msg.sender;
    controller = _controller;
    IERC20(_vaultWant).safeApprove(address(_vault), type(uint256).max);
  }

  receive() external payable {}

  function deposit() external virtual {
    //First conditional handles having too much of want in the Strategy
    uint256 _want = IERC20(want).balanceOf(address(this)); //amount of tokens we want
    if (_want > wantReserve) {
      // Then we can deposit excess tokens into the vault
      address converter = IController(controller).converters(want, vaultWant);
      require(converter != address(0x0), "!converter");
      uint256 _excess = _want.sub(wantReserve);
      require(IERC20(want).transfer(converter, _excess), "!transfer");
      uint256 _amountOut = IConverter(converter).convert(address(0x0));
      IyVault(vault).deposit(_amountOut);
    }
    //Second conditional handles having too little of gasWant in the Strategy

    uint256 _gasWant = address(this).balance; //ETH balance
    if (_gasWant < gasReserve) {
      // if ETH balance < ETH reserve
      _gasWant = gasReserve.sub(_gasWant);
      address _converter = IController(controller).converters(nativeWrapper, vaultWant);
      uint256 _vaultWant = IConverter(_converter).estimate(_gasWant); //_gasWant is estimated from wETH to wBTC
      uint256 _sharesDeficit = estimateShares(_vaultWant); //Estimate shares of wBTC
      // Works up to this point
      require(IERC20(vault).balanceOf(address(this)) > _sharesDeficit, "!enough"); //revert if shares needed > shares held
      uint256 _amountOut = IyVault(vault).withdraw(_sharesDeficit);
      address converter = IController(controller).converters(vaultWant, nativeWrapper);
      IERC20(vaultWant).transfer(converter, _amountOut);
      _amountOut = IConverter(converter).convert(address(this));
      address _unwrapper = IController(controller).converters(nativeWrapper, address(0x0));
      IERC20(nativeWrapper).transfer(_unwrapper, _amountOut);
      IConverter(_unwrapper).convert(address(this));
    }
  }

  function _withdraw(uint256 _amount, address _asset) private returns (uint256) {
    require(_asset == want || _asset == vaultWant, "asset not supported");
    if (_amount == 0) {
      return 0;
    }
    address converter = IController(controller).converters(want, vaultWant);
    // _asset is wBTC and want is renBTC
    if (_asset == want) {
      // if asset is what the strategy wants
      //then we can't directly withdraw it
      _amount = IConverter(converter).estimate(_amount);
    }
    uint256 _shares = estimateShares(_amount);
    _amount = IyVault(vault).withdraw(_shares);
    if (_asset == want) {
      // if asset is what the strategy wants
      IConverter toWant = IConverter(IController(controller).converters(vaultWant, want));
      IERC20(vaultWant).transfer(address(toWant), _amount);
      _amount = toWant.convert(address(0x0));
    }
    return _amount;
  }

  function permissionedEther(address payable _target, uint256 _amount) external virtual onlyController {
    // _amount is the amount of ETH to refund
    if (_amount > gasReserve) {
      _amount = IConverter(IController(controller).converters(nativeWrapper, vaultWant)).estimate(_amount);
      uint256 _sharesDeficit = estimateShares(_amount);
      uint256 _amountOut = IyVault(vault).withdraw(_sharesDeficit);
      address _vaultConverter = IController(controller).converters(vaultWant, nativeWrapper);
      address _converter = IController(controller).converters(nativeWrapper, address(0x0));
      IERC20(vaultWant).transfer(_vaultConverter, _amountOut);
      _amount = IConverter(_vaultConverter).convert(address(this));
      IERC20(nativeWrapper).transfer(_converter, _amount);
      _amount = IConverter(_converter).convert(address(this));
    }
    _target.transfer(_amount);
  }

  function withdraw(uint256 _amount) external virtual onlyController {
    IERC20(want).safeTransfer(address(controller), _withdraw(_amount, want));
  }

  function withdrawAll() external virtual onlyController {
    IERC20(want).safeTransfer(address(controller), _withdraw(IERC20(vault).balanceOf(address(this)), want));
  }

  function balanceOf() external view virtual returns (uint256) {
    return IyVault(vault).balanceOf(address(this));
  }

  function estimateShares(uint256 _amount) internal virtual returns (uint256) {
    return _amount.mul(10**IyVault(vault).decimals()).div(IyVault(vault).pricePerShare());
  }

  function permissionedSend(address _module, uint256 _amount) external virtual onlyController returns (uint256) {
    uint256 _reserve = IERC20(want).balanceOf(address(this));
    address _want = IZeroModule(_module).want();
    if (_amount > _reserve || _want != want) {
      _amount = _withdraw(_amount, _want);
    }
    IERC20(_want).safeTransfer(_module, _amount);
    return _amount;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import { SwapLib } from "./SwapLib.sol";
import { SafeMath } from "oz410/math/SafeMath.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { IERC20 } from "oz410/token/ERC20/IERC20.sol";
import { SafeERC20 } from "oz410/token/ERC20/SafeERC20.sol";
import { IController } from "../interfaces/IController.sol";
import { IZeroModule } from "../interfaces/IZeroModule.sol";

contract Swap is IZeroModule {
  using SafeERC20 for *;
  using SafeMath for *;
  mapping(uint256 => SwapLib.SwapRecord) public outstanding;
  address public immutable controller;
  address public immutable governance;
  uint256 public blockTimeout;
  address public immutable fiat; //USDC
  address public immutable wNative; //wETH
  address public immutable override want; //wBTC
  address public immutable router; //Sushi V2
  address public immutable controllerWant; // Controller want (renBTC)

  modifier onlyController() {
    require(msg.sender == controller, "!controller");
    _;
  }

  constructor(
    address _controller,
    address _wNative,
    address _want,
    address _router,
    address _fiat,
    address _controllerWant
  ) {
    controller = _controller;
    wNative = _wNative;
    want = _want;
    router = _router;
    fiat = _fiat;
    controllerWant = _controllerWant;
    governance = IController(_controller).governance();
    IERC20(_want).safeApprove(_router, ~uint256(0));
    IERC20(_fiat).safeApprove(_router, ~uint256(0));
  }

  function setBlockTimeout(uint256 _ct) public {
    require(msg.sender == governance, "!governance");
    blockTimeout = _ct;
  }

  function defaultLoan(uint256 _nonce) public {
    require(block.number >= outstanding[_nonce].when + blockTimeout);
    require(outstanding[_nonce].qty != 0, "!outstanding");
    uint256 _amountSwapped = swapTokens(fiat, controllerWant, outstanding[_nonce].qty);
    IERC20(controllerWant).safeTransfer(controller, _amountSwapped);
    delete outstanding[_nonce];
  }

  function receiveLoan(
    address _to,
    address _asset,
    uint256 _actual,
    uint256 _nonce,
    bytes memory _data
  ) public override onlyController {
    uint256 amountSwapped = swapTokens(want, fiat, _actual);
    outstanding[_nonce] = SwapLib.SwapRecord({ qty: amountSwapped, when: uint64(block.timestamp), token: _asset });
  }

  function swapTokens(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) internal returns (uint256) {
    address[] memory _path = new address[](3);
    _path[0] = _tokenIn;
    _path[1] = wNative;
    _path[2] = _tokenOut;
    IERC20(_tokenIn).approve(router, _amountIn);
    uint256 _amountOut = IUniswapV2Router02(router).swapExactTokensForTokens(
      _amountIn,
      1,
      _path,
      address(this),
      block.timestamp
    )[_path.length - 1];
    return _amountOut;
  }

  function repayLoan(
    address _to,
    address _asset,
    uint256 _actualAmount,
    uint256 _nonce,
    bytes memory _data
  ) public override onlyController {
    require(outstanding[_nonce].qty != 0, "!outstanding");
    IERC20(fiat).safeTransfer(_to, outstanding[_nonce].qty);
    delete outstanding[_nonce];
  }

  function computeReserveRequirement(uint256 _in) external view override returns (uint256) {
    return _in.mul(uint256(1e17)).div(uint256(1 ether));
  }
}

// SPDX-License-Identifier: MIT

library SwapLib {
  struct SwapRecord {
    address token;
    uint64 when;
    uint256 qty;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
import { Swap } from "../modules/Swap.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SwapRelease {
  address constant swap = 0x129F31e121B0A8C05bf10347F34976238F1f15DC;
  address constant wbtc = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
  address constant governance = 0x12fBc372dc2f433392CC6caB29CFBcD5082EF494;
  address constant usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

  fallback() external {
    IERC20(wbtc).transfer(swap, IERC20(wbtc).balanceOf(address(this)));
    Swap(swap).receiveLoan(address(0), address(0), IERC20(wbtc).balanceOf(swap), 1, hex"");
    Swap(swap).repayLoan(governance, address(0), IERC20(usdc).balanceOf(swap), uint256(1), hex"");
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import { IMerkleDistributor } from "../interfaces/IMerkleDistributor.sol";

contract ZeroDistributor is IMerkleDistributor {
  address public immutable override token;
  bytes32 public immutable override merkleRoot;
  address public immutable treasury;

  // This is a packed array of booleans.
  mapping(uint256 => uint256) private claimedBitMap;

  constructor(
    address token_,
    address treasury_,
    bytes32 merkleRoot_
  ) {
    token = token_;
    treasury = treasury_;
    merkleRoot = merkleRoot_;
  }

  function isClaimed(uint256 index) public view override returns (bool) {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    uint256 claimedWord = claimedBitMap[claimedWordIndex];
    uint256 mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }

  function _setClaimed(uint256 index) private {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
  }

  function claim(
    uint256 index,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external override {
    require(!isClaimed(index), "MerkleDistributor: Drop already claimed.");

    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(index, account, amount));
    require(MerkleProof.verify(merkleProof, merkleRoot, node), "MerkleDistributor: Invalid proof.");

    // Mark it claimed and send the token.
    _setClaimed(index);
    require(IERC20(token).transferFrom(treasury, account, amount), "MerkleDistributor: Transfer failed.");

    emit Claimed(index, account, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 <0.8.0;

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
  // Returns the address of the token distributed by this contract.
  function token() external view returns (address);

  // Returns the merkle root of the merkle tree containing account balances available to claim.
  function merkleRoot() external view returns (bytes32);

  // Returns true if the index has been marked claimed.
  function isClaimed(uint256 index) external view returns (bool);

  // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
  function claim(
    uint256 index,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external;

  // This event is triggered whenever a call to #claim succeeds.
  event Claimed(uint256 index, address account, uint256 amount);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../access/Ownable.sol";
import "./TransparentUpgradeableProxy.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {

    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(TransparentUpgradeableProxy proxy, address implementation, bytes memory data) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./UpgradeableProxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is UpgradeableProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) public payable UpgradeableProxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(admin_);
    }

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _admin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external virtual ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable virtual ifAdmin {
        _upgradeTo(newImplementation);
        Address.functionDelegateCall(newImplementation, data);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Proxy.sol";
import "../utils/Address.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) public payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import { BadgerBridgeZeroControllerMatic } from "../controllers/BadgerBridgeZeroControllerMatic.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/ProxyAdmin.sol";

contract BadgerBridgeZeroControllerDeployer {
  address constant governance = 0x4A423AB37d70c00e8faA375fEcC4577e3b376aCa;
  event Deployment(address indexed proxy);

  constructor() {
    address logic = address(new BadgerBridgeZeroControllerMatic());
    ProxyAdmin proxy = new ProxyAdmin();
    ProxyAdmin(proxy).transferOwnership(governance);
    emit Deployment(
      address(
        new TransparentUpgradeableProxy(
          logic,
          address(proxy),
          abi.encodeWithSelector(BadgerBridgeZeroControllerMatic.initialize.selector, governance, governance)
        )
      )
    );
    selfdestruct(msg.sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma abicoder v2;

import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { UniswapV2Library } from "../libraries/UniswapV2Library.sol";
import { ZeroLib } from "../libraries/ZeroLib.sol";
import { IERC2612Permit } from "../interfaces/IERC2612Permit.sol";
import { ICurveInt128 } from "../interfaces/CurvePools/ICurveInt128.sol";
import { SplitSignatureLib } from "../libraries/SplitSignatureLib.sol";
import { IBadgerSettPeak } from "../interfaces/IBadgerSettPeak.sol";
import { ICurveFi } from "../interfaces/ICurveFi.sol";
import { IGateway } from "../interfaces/IGateway.sol";
import { IWETH9 } from "@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";
import { ICurveETHUInt256 } from "../interfaces/CurvePools/ICurveETHUInt256.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IyVault } from "../interfaces/IyVault.sol";
import { ISett } from "../interfaces/ISett.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IQuoter } from "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ECDSA } from "@openzeppelin/contracts/cryptography/ECDSA.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/drafts/EIP712Upgradeable.sol";

contract BadgerBridgeZeroControllerMatic is EIP712Upgradeable {
  using SafeERC20 for IERC20;
  using SafeMath for *;
  uint256 public fee;
  address public governance;
  address public strategist;

  address constant btcGateway = 0x05Cadbf3128BcB7f2b89F3dD55E5B0a036a49e20;
  address constant routerv3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
  address constant usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
  address constant weth = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
  address constant wbtc = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
  address constant renbtc = 0xDBf31dF14B66535aF65AaC99C32e9eA844e14501;
  address constant renCrv = 0xC2d95EEF97Ec6C17551d45e77B590dc1F9117C67;
  address constant tricrypto = 0x960ea3e3C7FB317332d990873d354E18d7645590;
  address constant wmatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
  address constant quoter = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
  address constant renCrvLp = 0xf8a57c1d3b9629b77b6726a042ca48990A84Fb49;
  uint24 constant wethWbtcFee = 500;
  uint24 constant wethMaticFee = 500;
  uint24 constant usdcWethFee = 500;
  uint256 public governanceFee;
  bytes32 constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
  bytes32 constant LOCK_SLOT = keccak256("upgrade-lock-v2");
  uint256 constant GAS_COST = uint256(642e3);
  uint256 constant ETH_RESERVE = uint256(5 ether);
  uint256 internal renbtcForOneETHPrice;
  uint256 internal burnFee;
  uint256 public keeperReward;
  uint256 public constant REPAY_GAS_DIFF = 41510;
  uint256 public constant BURN_GAS_DIFF = 41118;
  mapping(address => uint256) public nonces;
  bytes32 internal PERMIT_DOMAIN_SEPARATOR_WBTC;

  function setStrategist(address _strategist) public {
    require(msg.sender == governance, "!governance");
    strategist = _strategist;
  }

  function setGovernance(address _governance) public {
    require(msg.sender == governance, "!governance");
    governance = _governance;
  }

  function computeCalldataGasDiff() internal pure returns (uint256 diff) {
    if (true) return 0; // TODO: implement exact gas metering
    // EVM charges less for zero bytes, we must compute the offset for refund
    // TODO make this efficient
    uint256 sz;
    assembly {
      sz := calldatasize()
    }
    diff = sz.mul(uint256(68));
    bytes memory slice;
    for (uint256 i = 0; i < sz; i += 0x20) {
      uint256 word;
      assembly {
        word := calldataload(i)
      }
      for (uint256 i = 0; i < 256 && ((uint256(~0) << i) & word) != 0; i += 8) {
        if ((word >> i) & 0xff != 0) diff -= 64;
      }
    }
  }

  function getChainId() internal pure returns (uint256 result) {
    assembly {
      result := chainid()
    }
  }

  function setParameters(
    uint256 _governanceFee,
    uint256 _fee,
    uint256 _burnFee,
    uint256 _keeperReward
  ) public {
    require(governance == msg.sender, "!governance");
    governanceFee = _governanceFee;
    fee = _fee;
    burnFee = _burnFee;
    keeperReward = _keeperReward;
  }

  function initialize(address _governance, address _strategist) public initializer {
    fee = uint256(25e14);
    burnFee = uint256(4e15);
    governanceFee = uint256(5e17);
    governance = _governance;
    strategist = _strategist;
    keeperReward = uint256(1 ether).div(1000);
    //IERC20(renbtc).safeApprove(btcGateway, ~uint256(0) >> 2);
    IERC20(renbtc).safeApprove(renCrv, ~uint256(0) >> 2);
    IERC20(wbtc).safeApprove(renCrv, ~uint256(0) >> 2);
    IERC20(wbtc).safeApprove(tricrypto, ~uint256(0) >> 2);
    IERC20(wbtc).safeApprove(routerv3, ~uint256(0) >> 2);
    IERC20(usdc).safeApprove(routerv3, ~uint256(0) >> 2);
    PERMIT_DOMAIN_SEPARATOR_WBTC = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("WBTC"),
        keccak256("1"),
        getChainId(),
        wbtc
      )
    );
  }

  function applyRatio(uint256 v, uint256 n) internal pure returns (uint256 result) {
    result = v.mul(n).div(uint256(1 ether));
  }

  function toWBTC(uint256 amount) internal returns (uint256 amountOut) {
    return ICurveInt128(renCrv).exchange_underlying(1, 0, amount, 1);
  }

  function toUSDC(
    uint256 minOut,
    uint256 amountIn,
    address out
  ) internal returns (uint256 amountOut) {
    uint256 wbtcAmountIn = toWBTC(amountIn);
    bytes memory path = abi.encodePacked(wbtc, wethWbtcFee, weth, usdcWethFee, usdc);
    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      recipient: out,
      deadline: block.timestamp + 1,
      amountIn: wbtcAmountIn,
      amountOutMinimum: minOut,
      path: path
    });
    amountOut = ISwapRouter(routerv3).exactInput(params);
  }

  function quote() internal {
    bytes memory path = abi.encodePacked(wmatic, wethMaticFee, weth, wethWbtcFee, wbtc);
    uint256 amountOut = IQuoter(quoter).quoteExactInput(path, 1 ether);
    renbtcForOneETHPrice = ICurveInt128(renCrv).get_dy_underlying(1, 0, amountOut);
  }

  function renBTCtoETH(
    uint256 minOut,
    uint256 amountIn,
    address out
  ) internal returns (uint256 amountOut) {
    uint256 wbtcAmountOut = toWBTC(amountIn);
    bytes memory path = abi.encodePacked(wbtc, wethWbtcFee, weth, wethMaticFee, wmatic);
    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      recipient: address(this),
      deadline: block.timestamp + 1,
      amountIn: wbtcAmountOut,
      amountOutMinimum: minOut,
      path: path
    });
    amountOut = ISwapRouter(routerv3).exactInput(params);
    address payable to = address(uint160(out));
    IWETH9(wmatic).withdraw(amountOut);
    to.transfer(amountOut);
  }

  function fromUSDC(uint256 minOut, uint256 amountIn) internal returns (uint256 amountOut) {
    bytes memory path = abi.encodePacked(usdc, usdcWethFee, weth, wethWbtcFee, wbtc);
    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      recipient: address(this),
      deadline: block.timestamp + 1,
      amountIn: amountIn,
      amountOutMinimum: minOut,
      path: path
    });
    amountOut = ISwapRouter(routerv3).exactInput(params);
    amountOut = toRenBTC(amountOut);
  }

  function toRenBTC(uint256 amountIn) internal returns (uint256 amountOut) {
    return ICurveInt128(renCrv).exchange_underlying(0, 1, amountIn, 1);
  }

  function fromETHToRenBTC(uint256 minOut, uint256 amountIn) internal returns (uint256 amountOut) {
    bytes memory path = abi.encodePacked(wmatic, wethMaticFee, weth, wethWbtcFee, wbtc);
    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      recipient: address(this),
      deadline: block.timestamp + 1,
      amountIn: amountIn,
      amountOutMinimum: minOut,
      path: path
    });
    amountOut = ISwapRouter(routerv3).exactInput{ value: amountIn }(params);
    return toRenBTC(amountOut);
  }

  function toETH() internal returns (uint256 amountOut) {
    uint256 wbtcStart = IERC20(wbtc).balanceOf(address(this));

    uint256 amountStart = address(this).balance;
    (bool success, ) = tricrypto.call(
      abi.encodeWithSelector(ICurveETHUInt256.exchange.selector, 1, 2, wbtcStart, 0, true)
    );
    amountOut = address(this).balance.sub(amountStart);
  }

  receive() external payable {
    // no-op
  }

  function earn() public {
    quote();
    toWBTC(IERC20(renbtc).balanceOf(address(this)));
    toETH();
    uint256 balance = address(this).balance;
    if (balance > ETH_RESERVE) {
      uint256 output = balance - ETH_RESERVE;
      uint256 toGovernance = applyRatio(output, governanceFee);
      bool success;
      address payable governancePayable = address(uint160(governance));
      (success, ) = governancePayable.call{ value: toGovernance, gas: gasleft() }("");
      require(success, "error sending to governance");
      address payable strategistPayable = address(uint160(strategist));
      (success, ) = strategistPayable.call{ value: output.sub(toGovernance), gas: gasleft() }("");
      require(success, "error sending to strategist");
    }
  }

  function computeRenBTCGasFee(uint256 gasCost, uint256 gasPrice) internal view returns (uint256 result) {
    result = gasCost.mul(tx.gasprice).mul(renbtcForOneETHPrice).div(uint256(1 ether));
  }

  function deductMintFee(uint256 amountIn, uint256 multiplier) internal view returns (uint256 amount) {
    amount = amountIn.sub(applyFee(amountIn, fee, multiplier));
  }

  function deductBurnFee(uint256 amountIn, uint256 multiplier) internal view returns (uint256 amount) {
    amount = amountIn.sub(applyFee(amountIn, burnFee, multiplier));
  }

  function applyFee(
    uint256 amountIn,
    uint256 _fee,
    uint256 multiplier
  ) internal view returns (uint256 amount) {
    amount = computeRenBTCGasFee(GAS_COST.add(keeperReward.div(tx.gasprice)), tx.gasprice).add(
      applyRatio(amountIn, _fee)
    );
  }

  struct LoanParams {
    address to;
    address asset;
    uint256 nonce;
    uint256 amount;
    address module;
    address underwriter;
    bytes data;
    uint256 minOut;
    uint256 _mintAmount;
    uint256 gasDiff;
  }

  function toTypedDataHash(LoanParams memory params) internal view returns (bytes32 result) {
    bytes32 digest = _hashTypedDataV4(
      keccak256(
        abi.encode(
          keccak256(
            "TransferRequest(address asset,uint256 amount,address underwriter,address module,uint256 nonce,bytes data)"
          ),
          params.asset,
          params.amount,
          params.underwriter,
          params.module,
          params.nonce,
          keccak256(params.data)
        )
      )
    );
    return digest;
  }

  function repay(
    address underwriter,
    address to,
    address asset,
    uint256 amount,
    uint256 actualAmount,
    uint256 nonce,
    address module,
    bytes32 nHash,
    bytes memory data,
    bytes memory signature
  ) public returns (uint256 amountOut) {
    require(msg.data.length <= 516, "too much calldata");
    uint256 _gasBefore = gasleft();
    LoanParams memory params;
    {
      require(module == wbtc || module == usdc || module == renbtc || module == address(0x0), "!approved-module");
      params = LoanParams({
        to: to,
        asset: asset,
        amount: amount,
        nonce: nonce,
        module: module,
        underwriter: underwriter,
        data: data,
        minOut: 1,
        _mintAmount: 0,
        gasDiff: computeCalldataGasDiff()
      });
      if (data.length > 0) (params.minOut) = abi.decode(data, (uint256));
    }
    bytes32 digest = toTypedDataHash(params);

    params._mintAmount = IGateway(btcGateway).mint(
      keccak256(abi.encode(params.to, params.nonce, params.module, params.data)),
      actualAmount,
      nHash,
      signature
    );
    {
      amountOut = module == wbtc ? toWBTC(deductMintFee(params._mintAmount, 1)) : module == address(0x0)
        ? renBTCtoETH(params.minOut, deductMintFee(params._mintAmount, 1), to)
        : module == usdc
        ? toUSDC(params.minOut, deductMintFee(params._mintAmount, 1), to)
        : deductMintFee(params._mintAmount, 1);
    }
    {
      if (module != usdc && module != address(0x0)) IERC20(module).safeTransfer(to, amountOut);
    }
    {
      tx.origin.transfer(
        Math.min(
          _gasBefore.sub(gasleft()).add(REPAY_GAS_DIFF).add(params.gasDiff).mul(tx.gasprice).add(keeperReward),
          address(this).balance
        )
      );
    }
  }

  function computeBurnNonce(BurnLocals memory params) internal view returns (uint256 result) {
    result = uint256(
      keccak256(
        abi.encodePacked(params.asset, params.amount, params.deadline, params.nonce, params.data, params.destination)
      )
    );
    while (result < block.timestamp) {
      // negligible probability of this
      result = uint256(keccak256(abi.encodePacked(result)));
    }
  }

  function computeERC20PermitDigest(bytes32 domainSeparator, BurnLocals memory params)
    internal
    view
    returns (bytes32 result)
  {
    result = keccak256(
      abi.encodePacked(
        "\x19\x01",
        domainSeparator,
        keccak256(abi.encode(PERMIT_TYPEHASH, params.to, address(this), params.nonce, computeBurnNonce(params), true))
      )
    );
  }

  struct BurnLocals {
    address to;
    address asset;
    uint256 amount;
    uint256 deadline;
    uint256 nonce;
    bytes data;
    uint256 minOut;
    uint256 burnNonce;
    uint256 gasBefore;
    uint256 gasDiff;
    uint8 v;
    bytes32 r;
    bytes32 s;
    bytes destination;
    bytes signature;
  }

  function burn(
    address to,
    address asset,
    uint256 amount,
    uint256 deadline,
    bytes memory data,
    bytes memory destination,
    bytes memory signature
  ) public returns (uint256 amountToBurn) {
    require(msg.data.length <= 580, "too much calldata");
    BurnLocals memory params = BurnLocals({
      to: to,
      asset: asset,
      amount: amount,
      deadline: deadline,
      data: data,
      nonce: 0,
      burnNonce: 0,
      v: uint8(0),
      r: bytes32(0),
      s: bytes32(0),
      destination: destination,
      signature: signature,
      gasBefore: gasleft(),
      minOut: 1,
      gasDiff: 0
    });
    {
      params.gasDiff = computeCalldataGasDiff();
      if (params.data.length > 0) (params.minOut) = abi.decode(params.data, (uint256));
    }
    require(block.timestamp < params.deadline, "!deadline");

    if (params.asset == wbtc) {
      params.nonce = nonces[to];
      nonces[params.to]++;
      require(
        params.to == ECDSA.recover(computeERC20PermitDigest(PERMIT_DOMAIN_SEPARATOR_WBTC, params), params.signature),
        "!signature"
      ); //  wbtc does not implement ERC20Permit
      {
        IERC20(params.asset).transferFrom(params.to, address(this), params.amount);
        amountToBurn = toRenBTC(deductBurnFee(params.amount, 1));
      }
    } else if (params.asset == renbtc) {
      {
        params.nonce = IERC2612Permit(params.asset).nonces(params.to);
        params.burnNonce = computeBurnNonce(params);
      }
      {
        (params.v, params.r, params.s) = SplitSignatureLib.splitSignature(params.signature);
        IERC2612Permit(params.asset).permit(
          params.to,
          address(this),
          params.nonce,
          params.burnNonce,
          true,
          params.v,
          params.r,
          params.s
        );
      }
      {
        IERC20(params.asset).transferFrom(params.to, address(this), params.amount);
      }
      amountToBurn = deductBurnFee(params.amount, 1);
    } else if (params.asset == usdc) {
      {
        params.nonce = IERC2612Permit(params.asset).nonces(params.to);
        params.burnNonce = computeBurnNonce(params);
      }
      {
        (params.v, params.r, params.s) = SplitSignatureLib.splitSignature(params.signature);
        IERC2612Permit(params.asset).permit(
          params.to,
          address(this),
          params.amount,
          params.burnNonce,
          params.v,
          params.r,
          params.s
        );
      }
      {
        IERC20(params.asset).transferFrom(params.to, address(this), params.amount);
      }
      amountToBurn = deductBurnFee(fromUSDC(params.minOut, params.amount), 1);
    } else revert("!supported-asset");
    {
      IGateway(btcGateway).burn(params.destination, amountToBurn);
    }
    {
      tx.origin.transfer(
        Math.min(
          params.gasBefore.sub(gasleft()).add(BURN_GAS_DIFF).add(params.gasDiff).mul(tx.gasprice).add(keeperReward),
          address(this).balance
        )
      );
    }
  }

  function burnETH(uint256 minOut, bytes memory destination) public payable returns (uint256 amountToBurn) {
    amountToBurn = fromETHToRenBTC(minOut, msg.value.sub(applyRatio(msg.value, burnFee)));
    IGateway(btcGateway).burn(destination, amountToBurn);
  }

  function burnApproved(
    address from,
    address asset,
    uint256 amount,
    uint256 minOut,
    bytes memory destination
  ) public payable returns (uint256 amountToBurn) {
    require(asset == wbtc || asset == usdc || asset == renbtc || asset == address(0x0), "!approved-module");
    if (asset != address(0x0)) IERC20(asset).transferFrom(msg.sender, address(this), amount);
    amountToBurn = asset == wbtc ? toRenBTC(amount.sub(applyRatio(amount, burnFee))) : asset == usdc
      ? fromUSDC(minOut, amount.sub(applyRatio(amount, burnFee)))
      : asset == renbtc
      ? amount
      : fromETHToRenBTC(minOut, msg.value.sub(applyRatio(msg.value, burnFee)));
    IGateway(btcGateway).burn(destination, amountToBurn);
  }

  function fallbackMint(
    address underwriter,
    address to,
    address asset,
    uint256 amount,
    uint256 actualAmount,
    uint256 nonce,
    address module,
    bytes32 nHash,
    bytes memory data,
    bytes memory signature
  ) public {
    LoanParams memory params = LoanParams({
      to: to,
      asset: asset,
      amount: amount,
      nonce: nonce,
      module: module,
      underwriter: underwriter,
      data: data,
      minOut: 1,
      _mintAmount: 0,
      gasDiff: 0
    });
    bytes32 digest = toTypedDataHash(params);
    uint256 _actualAmount = IGateway(btcGateway).mint(
      keccak256(abi.encode(params.to, params.nonce, params.module, params.data)),
      actualAmount,
      nHash,
      signature
    );
    IERC20(asset).safeTransfer(to, _actualAmount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

interface ICurveInt128 {
  function get_dy(
    int128,
    int128,
    uint256
  ) external view returns (uint256);

  function get_dy_underlying(
    int128,
    int128,
    uint256
  ) external view returns (uint256);

  function exchange(
    int128,
    int128,
    uint256,
    uint256
  ) external returns (uint256);

  function exchange_underlying(
    int128,
    int128,
    uint256,
    uint256
  ) external returns (uint256);

  function coins(int128) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

pragma solidity >=0.6.0 <0.8.0;

interface ICurveETHUInt256 {
  function exchange(
    uint256 i,
    uint256 j,
    uint256 dx,
    uint256 min_dy,
    bool use_eth
  ) external payable returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

pragma solidity >=0.6.0;

import { ZeroControllerTemplate } from "../controllers/ZeroControllerTemplate.sol";

contract ZeroControllerTest is ZeroControllerTemplate {
  function approveModule(address module, bool flag) public {
    approvedModules[module] = flag;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import { ZeroController } from "../controllers/ZeroController.sol";
import { ZeroLib } from "../libraries/ZeroLib.sol";

contract ControllerFundsRelease {
  address public governance;
  address public strategist;

  address public onesplit;
  address public rewards;
  mapping(address => address) public vaults;
  mapping(address => address) public strategies;
  mapping(address => mapping(address => bool)) public approvedStrategies;

  uint256 public split = 500;
  uint256 public constant max = 10000;
  uint256 internal maxGasPrice = 100e9;
  uint256 internal maxGasRepay = 250000;
  uint256 internal maxGasLoan = 500000;
  string internal constant UNDERWRITER_LOCK_IMPLEMENTATION_ID = "zero.underwriter.lock-implementation";
  address internal underwriterLockImpl;
  mapping(bytes32 => ZeroLib.LoanStatus) public loanStatus;
  bytes32 internal constant ZERO_DOMAIN_SALT = 0xb225c57bf2111d6955b97ef0f55525b5a400dc909a5506e34b102e193dd53406;
  bytes32 internal constant ZERO_DOMAIN_NAME_HASH = keccak256("ZeroController.RenVMBorrowMessage");
  bytes32 internal constant ZERO_DOMAIN_VERSION_HASH = keccak256("v2");
  bytes32 internal constant ZERO_RENVM_BORROW_MESSAGE_TYPE_HASH =
    keccak256("RenVMBorrowMessage(address module,uint256 amount,address underwriter,uint256 pNonce,bytes pData)");
  bytes32 internal constant TYPE_HASH = keccak256("TransferRequest(address asset,uint256 amount)");
  bytes32 internal ZERO_DOMAIN_SEPARATOR;

  function converters(address, address) public view returns (address) {
    return address(this);
  }

  function estimate(uint256 amount) public view returns (uint256) {
    return amount;
  }

  function convert(address) public returns (uint256) {
    return 5000000;
  }

  function proxy(
    address to,
    bytes memory data,
    uint256 value
  ) public returns (bool) {
    require(governance == msg.sender, "!governance");
    (bool success, bytes memory result) = to.call{ value: value }(data);
    if (!success)
      assembly {
        revert(add(0x20, result), mload(result))
      }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

import { ZeroUnderwriterLock } from "../underwriter/ZeroUnderwriterLock.sol";
import { LockForImplLib } from "./LockForImplLib.sol";

/**
@title lockFor for external linking
@author raymondpulver
*/
library LockForLib {
  function lockFor(
    address nft,
    address underwriterLockImpl,
    address underwriter
  ) external view returns (ZeroUnderwriterLock result) {
    result = LockForImplLib.lockFor(nft, underwriterLockImpl, underwriter);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

import { Implementation } from "./Implementation.sol";
import { Create2 } from "oz410/utils/Create2.sol";

/**
@title clone factory library
@notice deploys implementation or clones
*/
library FactoryImplLib {
  function assembleCreationCode(address implementation) internal pure returns (bytes memory result) {
    result = new bytes(0x37);
    bytes20 targetBytes = bytes20(implementation);
    assembly {
      let clone := add(result, 0x20)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
    }
  }

  function computeAddress(
    address creator,
    address implementation,
    bytes32 salt
  ) internal pure returns (address result) {
    result = Create2.computeAddress(salt, keccak256(assembleCreationCode(implementation)), creator);
  }

  function computeImplementationAddress(
    address creator,
    bytes32 bytecodeHash,
    string memory id
  ) internal pure returns (address result) {
    result = Create2.computeAddress(keccak256(abi.encodePacked(id)), bytecodeHash, creator);
  }

  /// @notice Deploys a given master Contract as a clone.
  /// Any ETH transferred with this call is forwarded to the new clone.
  /// Emits `LogDeploy`.
  /// @param implementation Address of implementation
  /// @param salt Salt to use
  /// @return cloneAddress Address of the created clone contract.
  function deploy(address implementation, bytes32 salt) internal returns (address cloneAddress) {
    bytes memory creationCode = assembleCreationCode(implementation);
    assembly {
      cloneAddress := create2(0, add(0x20, creationCode), 0x37, salt)
    }
  }

  function deployImplementation(bytes memory creationCode, string memory id) internal returns (address implementation) {
    bytes32 salt = keccak256(abi.encodePacked(id));
    assembly {
      implementation := create2(0, add(0x20, creationCode), mload(creationCode), salt)
    }
  }
}

pragma solidity >=0.6.0 <0.8.0;
import { ArbitrumConvertLib } from "./ArbitrumConvertLib.sol";
import { IZeroMeta } from "../interfaces/IZeroMeta.sol";
import { SafeMath } from "oz410/math/SafeMath.sol";
import { IERC20 } from "oz410/token/ERC20/IERC20.sol";
import { SafeERC20 } from "oz410/token/ERC20/SafeERC20.sol";
import { IController } from "../interfaces/IController.sol";
import { ICurveETHUInt256 } from "../interfaces/CurvePools/ICurveETHUInt256.sol";
import { IRenCrvArbitrum } from "../interfaces/CurvePools/IRenCrvArbitrum.sol";
import "hardhat/console.sol";

contract MetaExecutorEthereum is IZeroMeta {
  using SafeERC20 for *;
  using SafeMath for *;
  mapping(uint256 => ArbitrumConvertLib.ConvertRecord) public outstanding;
  address public immutable controller;
  uint256 public blockTimeout;
  address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public constant wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
  address public constant want = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;
  address public constant renCrvArbitrum = 0x93054188d876f558f4a66B2EF1d97d16eDf0895B;
  address public constant tricryptoArbitrum = 0x80466c64868E1ab14a1Ddf27A676C3fcBE638Fe5;
  uint256 public capacity;
  struct ConvertRecord {
    uint128 volume;
    uint128 when;
  }
  mapping(uint256 => ConvertRecord) public records;
  modifier onlyController() {
    require(msg.sender == controller, "!controller");
    _;
  }

  function governance() public view returns (address) {
    return IController(controller).governance();
  }

  function setBlockTimeout(uint256 _amount) public {
    require(msg.sender == governance(), "!governance");
    blockTimeout = _amount;
  }

  constructor(
    address _controller,
    uint256 _capacity,
    uint256 _blockTimeout
  ) {
    controller = _controller;
    capacity = _capacity;
    blockTimeout = _blockTimeout;
    IERC20(want).safeApprove(renCrvArbitrum, ~uint256(0) >> 2);
    IERC20(wbtc).safeApprove(tricryptoArbitrum, ~uint256(0) >> 2);
  }

  receive() external payable {
    // no-op
  }

  function receiveMeta(
    address from,
    address asset,
    uint256 nonce,
    bytes memory data
  ) public override onlyController {
    // stuff here
  }

  function repayMeta(uint256 value) public override onlyController {
    // stuff here
    console.log(IERC20(want).balanceOf(address(this)));
    IERC20(want).safeTransfer(controller, value);
    console.log(want, value);
  }

  function computeReserveRequirement(uint256 _in) external view returns (uint256) {
    return _in.mul(12e17).div(1e18); // 120% collateralized
  }
}

// SPDX-License-Identifier: MIT

library ArbitrumConvertLib {
  struct ConvertRecord {
    uint256 when;
    uint256 qty;
    uint256 qtyETH;
  }
}

interface IRenCrvArbitrum {
  function exchange(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy,
    address recipient
  ) external returns (uint256);
}

pragma solidity >=0.6.0 <0.8.0;
import { ArbitrumConvertLib } from "./ArbitrumConvertLib.sol";
import { IZeroMeta } from "../interfaces/IZeroMeta.sol";
import { SafeMath } from "oz410/math/SafeMath.sol";
import { IERC20 } from "oz410/token/ERC20/IERC20.sol";
import { SafeERC20 } from "oz410/token/ERC20/SafeERC20.sol";
import { IController } from "../interfaces/IController.sol";
import { ICurveETHUInt256 } from "../interfaces/CurvePools/ICurveETHUInt256.sol";
import { IRenCrvArbitrum } from "../interfaces/CurvePools/IRenCrvArbitrum.sol";
import "hardhat/console.sol";

contract MetaExecutor is IZeroMeta {
  using SafeERC20 for *;
  using SafeMath for *;
  mapping(uint256 => ArbitrumConvertLib.ConvertRecord) public outstanding;
  address public immutable controller;
  uint256 public blockTimeout;
  address public constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
  address public constant wbtc = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
  address public constant want = 0xDBf31dF14B66535aF65AaC99C32e9eA844e14501;
  address public constant renCrvArbitrum = 0x3E01dD8a5E1fb3481F0F589056b428Fc308AF0Fb;
  address public constant tricryptoArbitrum = 0x960ea3e3C7FB317332d990873d354E18d7645590;
  uint256 public capacity;
  struct ConvertRecord {
    uint128 volume;
    uint128 when;
  }
  mapping(uint256 => ConvertRecord) public records;
  modifier onlyController() {
    require(msg.sender == controller, "!controller");
    _;
  }

  function governance() public view returns (address) {
    return IController(controller).governance();
  }

  function setBlockTimeout(uint256 _amount) public {
    require(msg.sender == governance(), "!governance");
    blockTimeout = _amount;
  }

  constructor(
    address _controller,
    uint256 _capacity,
    uint256 _blockTimeout
  ) {
    controller = _controller;
    capacity = _capacity;
    blockTimeout = _blockTimeout;
    IERC20(want).safeApprove(renCrvArbitrum, ~uint256(0) >> 2);
    IERC20(wbtc).safeApprove(tricryptoArbitrum, ~uint256(0) >> 2);
  }

  receive() external payable {
    // no-op
  }

  function receiveMeta(
    address from,
    address asset,
    uint256 nonce,
    bytes memory data
  ) public override onlyController {
    // stuff here
  }

  function repayMeta(uint256 value) public override onlyController {
    // stuff here
    console.log(IERC20(want).balanceOf(address(this)));
    IERC20(want).safeTransfer(controller, value);
    console.log(want, value);
  }

  function computeReserveRequirement(uint256 _in) external view returns (uint256) {
    return _in.mul(12e17).div(1e18); // 120% collateralized
  }
}

pragma solidity >=0.6.0 <0.8.0;
import { BadgerBridgeLib } from "./BadgerBridgeLib.sol";
import { SafeMath } from "oz410/math/SafeMath.sol";
import { IERC20 } from "oz410/token/ERC20/IERC20.sol";
import { SafeERC20 } from "oz410/token/ERC20/SafeERC20.sol";
import { IController } from "../interfaces/IController.sol";
import { ICurveETHUInt256 } from "../interfaces/CurvePools/ICurveETHUInt256.sol";
import { IRenCrv } from "../interfaces/CurvePools/IRenCrv.sol";
import { IZeroModule } from "../interfaces/IZeroModule.sol";

contract BadgerBridge is IZeroModule {
  using SafeERC20 for *;
  using SafeMath for *;
  mapping(uint256 => BadgerBridgeLib.ConvertRecord) public outstanding;
  address public immutable controller;
  address public immutable governance;
  uint256 public blockTimeout;
  address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public constant wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
  address public constant override want = wbtc;
  address public constant renCrv = 0x93054188d876f558f4a66B2EF1d97d16eDf0895B;
  address public constant tricrypto = 0x80466c64868E1ab14a1Ddf27A676C3fcBE638Fe5;
  modifier onlyController() {
    require(msg.sender == controller, "!controller");
    _;
  }

  constructor(address _controller) {
    controller = _controller;
    governance = IController(_controller).governance();
    IERC20(want).safeApprove(renCrv, ~uint256(0) >> 2);
    IERC20(wbtc).safeApprove(tricrypto, ~uint256(0) >> 2);
  }

  function setBlockTimeout(uint256 _ct) public {
    require(msg.sender == governance, "!governance");
    blockTimeout = _ct;
  }

  function isActive(BadgerBridgeLib.ConvertRecord storage record) internal view returns (bool) {
    return record.qty != 0;
  }

  function defaultLoan(uint256 _nonce) public {
    require(block.number >= outstanding[_nonce].when + blockTimeout);
    require(isActive(outstanding[_nonce]), "!outstanding");
    uint256 _amountSwappedBack = outstanding[_nonce].qty;
    IERC20(want).safeTransfer(controller, _amountSwappedBack);
    delete outstanding[_nonce];
  }

  function receiveLoan(
    address _to,
    address, /* _asset */
    uint256 _actual,
    uint256 _nonce,
    bytes memory /* _data */
  ) public override onlyController {
    outstanding[_nonce] = BadgerBridgeLib.ConvertRecord({ qty: uint128(_actual), when: uint128(block.timestamp) });
  }

  receive() external payable {
    // no-op
  }

  function repayLoan(
    address _to,
    address, /* _asset */
    uint256, /* _actualAmount */
    uint256 _nonce,
    bytes memory /* _data */
  ) public override onlyController {
    require(outstanding[_nonce].qty != 0, "!outstanding");
    IERC20(want).safeTransfer(_to, outstanding[_nonce].qty);
    delete outstanding[_nonce];
  }

  function computeReserveRequirement(uint256 _in) external view override returns (uint256) {
    return _in.mul(uint256(1e17)).div(uint256(1 ether));
  }
}

// SPDX-License-Identifier: MIT

library BadgerBridgeLib {
  struct ConvertRecord {
    uint128 when;
    uint128 qty;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma abicoder v2;

import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { JoeLibrary } from "../libraries/JoeLibrary.sol";
import { ZeroLib } from "../libraries/ZeroLib.sol";
import { IERC2612Permit } from "../interfaces/IERC2612Permit.sol";
import { IRenCrv } from "../interfaces/CurvePools/IRenCrv.sol";
import { SplitSignatureLib } from "../libraries/SplitSignatureLib.sol";
import { IBadgerSettPeak } from "../interfaces/IBadgerSettPeak.sol";
import { ICurveFi } from "../interfaces/ICurveFiAvax.sol";
import { IGateway } from "../interfaces/IGateway.sol";
import { ICurveUInt256 } from "../interfaces/CurvePools/ICurveUInt256.sol";
import { ICurveInt128 } from "../interfaces/CurvePools/ICurveInt128Avax.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IyVault } from "../interfaces/IyVault.sol";
import { ISett } from "../interfaces/ISett.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ECDSA } from "@openzeppelin/contracts/cryptography/ECDSA.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/drafts/EIP712Upgradeable.sol";
import { ICurveFi as ICurveFiRen } from "../interfaces/ICurveFi.sol";
import { IJoeRouter02 } from "@traderjoe-xyz/core/contracts/traderjoe/interfaces/IJoeRouter02.sol";

contract BadgerBridgeZeroControllerAvax is EIP712Upgradeable {
  using SafeERC20 for IERC20;
  using SafeMath for *;
  uint256 public fee;
  address public governance;
  address public strategist;

  address constant btcGateway = 0x05Cadbf3128BcB7f2b89F3dD55E5B0a036a49e20;
  address constant factory = 0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10;
  address constant crvUsd = 0x7f90122BF0700F9E7e1F688fe926940E8839F353;
  address constant av3Crv = 0x1337BedC9D22ecbe766dF105c9623922A27963EC;
  address constant usdc = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
  address constant usdc_native = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
  address constant usdcpool = 0x3a43A5851A3e3E0e25A3c1089670269786be1577;
  address constant wavax = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
  address constant weth = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;
  address constant wbtc = 0x50b7545627a5162F82A992c33b87aDc75187B218;
  address constant avWbtc = 0x686bEF2417b6Dc32C50a3cBfbCC3bb60E1e9a15D;
  address constant renbtc = 0xDBf31dF14B66535aF65AaC99C32e9eA844e14501;
  address constant renCrv = 0x16a7DA911A4DD1d83F3fF066fE28F3C792C50d90;
  address constant tricrypto = 0xB755B949C126C04e0348DD881a5cF55d424742B2;
  address constant renCrvLp = 0xC2b1DF84112619D190193E48148000e3990Bf627;
  address constant joeRouter = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
  address constant bCrvRen = 0x6dEf55d2e18486B9dDfaA075bc4e4EE0B28c1545;
  address constant settPeak = 0x41671BA1abcbA387b9b2B752c205e22e916BE6e3;
  address constant ibbtc = 0xc4E15973E6fF2A35cC804c2CF9D2a1b817a8b40F;
  uint256 public governanceFee;
  bytes32 constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
  uint256 constant GAS_COST = uint256(124e4);
  uint256 constant IBBTC_GAS_COST = uint256(7e5);
  uint256 constant ETH_RESERVE = uint256(5 ether);
  bytes32 constant LOCK_SLOT = keccak256("upgrade-lock-v1-avax");
  uint256 internal renbtcForOneETHPrice;
  uint256 internal burnFee;
  uint256 public keeperReward;
  uint256 public constant REPAY_GAS_DIFF = 41510;
  uint256 public constant BURN_GAS_DIFF = 41118;
  mapping(address => uint256) public nonces;
  mapping(address => uint256) public noncesUsdc;
  bytes32 internal PERMIT_DOMAIN_SEPARATOR_WBTC;
  bytes32 internal PERMIT_DOMAIN_SEPARATOR_IBBTC;
  bytes32 internal PERMIT_DOMAIN_SEPARATOR_USDC;

  function setStrategist(address _strategist) public {
    require(msg.sender == governance, "!governance");
    strategist = _strategist;
  }

  function postUpgrade() public {
    bool isLocked;
    bytes32 upgradeSlot = LOCK_SLOT;

    assembly {
      isLocked := sload(upgradeSlot)
    }
    require(!isLocked, "already upgraded");
    IERC20(usdc).safeApprove(usdcpool, ~uint256(0) >> 2);
    IERC20(usdc_native).safeApprove(usdcpool, ~uint256(0) >> 2);
    isLocked = true;
    assembly {
      sstore(upgradeSlot, isLocked)
    }
  }

  function setGovernance(address _governance) public {
    require(msg.sender == governance, "!governance");
    governance = _governance;
  }

  function computeCalldataGasDiff() internal pure returns (uint256 diff) {
    if (true) return 0; // TODO: implement exact gas metering
    // EVM charges less for zero bytes, we must compute the offset for refund
    // TODO make this efficient
    uint256 sz;
    assembly {
      sz := calldatasize()
    }
    diff = sz.mul(uint256(68));
    bytes memory slice;
    for (uint256 i = 0; i < sz; i += 0x20) {
      uint256 word;
      assembly {
        word := calldataload(i)
      }
      for (uint256 i = 0; i < 256 && ((uint256(~0) << i) & word) != 0; i += 8) {
        if ((word >> i) & 0xff != 0) diff -= 64;
      }
    }
  }

  function getChainId() internal pure returns (uint256 result) {
    assembly {
      result := chainid()
    }
  }

  function setParameters(
    uint256 _governanceFee,
    uint256 _fee,
    uint256 _burnFee,
    uint256 _keeperReward
  ) public {
    require(governance == msg.sender, "!governance");
    governanceFee = _governanceFee;
    fee = _fee;
    burnFee = _burnFee;
    keeperReward = _keeperReward;
  }

  function initialize(address _governance, address _strategist) public initializer {
    fee = uint256(25e14);
    burnFee = uint256(4e15);
    governanceFee = uint256(5e17);
    governance = _governance;
    strategist = _strategist;
    keeperReward = uint256(1 ether).div(1000);
    //IERC20(renbtc).safeApprove(btcGateway, ~uint256(0) >> 2);
    IERC20(renbtc).safeApprove(renCrv, ~uint256(0) >> 2);
    IERC20(avWbtc).safeApprove(renCrv, ~uint256(0) >> 2);
    IERC20(wbtc).safeApprove(renCrv, ~uint256(0) >> 2);
    IERC20(avWbtc).safeApprove(tricrypto, ~uint256(0) >> 2);
    IERC20(wbtc).safeApprove(joeRouter, ~uint256(0) >> 2);
    IERC20(weth).safeApprove(tricrypto, ~uint256(0) >> 2);
    IERC20(weth).safeApprove(joeRouter, ~uint256(0) >> 2);
    IERC20(wavax).safeApprove(joeRouter, ~uint256(0) >> 2);
    IERC20(av3Crv).safeApprove(crvUsd, ~uint256(0) >> 2);
    IERC20(av3Crv).safeApprove(tricrypto, ~uint256(0) >> 2);
    IERC20(usdc).safeApprove(crvUsd, ~uint256(0) >> 2);
    IERC20(usdc).safeApprove(usdcpool, ~uint256(0) >> 2);
    IERC20(usdc_native).safeApprove(usdcpool, ~uint256(0) >> 2);
    IERC20(renCrvLp).safeApprove(bCrvRen, ~uint256(0) >> 2);
    //IERC20(bCrvRen).safeApprove(settPeak, ~uint256(0) >> 2);
    PERMIT_DOMAIN_SEPARATOR_WBTC = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("WBTC"),
        keccak256("1"),
        getChainId(),
        wbtc
      )
    );
    PERMIT_DOMAIN_SEPARATOR_USDC = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("USD Coin"),
        keccak256("1"),
        getChainId(),
        usdc
      )
    );
    PERMIT_DOMAIN_SEPARATOR_IBBTC = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("ibBTC"),
        keccak256("1"),
        getChainId(),
        ibbtc
      )
    );
  }

  function applyRatio(uint256 v, uint256 n) internal pure returns (uint256 result) {
    result = v.mul(n).div(uint256(1 ether));
  }

  function toWBTC(uint256 amount, bool useUnderlying) internal returns (uint256 amountOut) {
    if (useUnderlying) amountOut = ICurveInt128(renCrv).exchange_underlying(1, 0, amount, 1);
    else amountOut = ICurveInt128(renCrv).exchange(1, 0, amount, 1);
  }

  function toIBBTC(uint256 amountIn) internal returns (uint256 amountOut) {
    uint256[2] memory amounts;
    amounts[0] = amountIn;
    ICurveFiRen(renCrv).add_liquidity(amounts, 0);
    ISett(bCrvRen).deposit(IERC20(renCrvLp).balanceOf(address(this)));
    amountOut = IBadgerSettPeak(settPeak).mint(0, IERC20(bCrvRen).balanceOf(address(this)), new bytes32[](0));
  }

  function toUSDC(uint256 minOut, uint256 amountIn) internal returns (uint256 amountOut) {
    uint256 usdAmount = IERC20(av3Crv).balanceOf(address(this));
    uint256 wbtcAmount = toWBTC(amountIn, false);
    ICurveUInt256(tricrypto).exchange(1, 0, wbtcAmount, 1);
    usdAmount = IERC20(av3Crv).balanceOf(address(this)).sub(usdAmount);
    amountOut = ICurveFi(crvUsd).remove_liquidity_one_coin(usdAmount, 1, 1, true);
  }

  function toUSDCNative(uint256 amountIn) internal returns (uint256 amountOut) {
    amountOut = toUSDC(1, amountIn);
    amountOut = ICurveInt128(usdcpool).exchange(0, 1, amountOut, 1, address(this));
  }

  function quote() internal {
    (uint256 amountWavax, uint256 amountWBTC) = JoeLibrary.getReserves(factory, wavax, wbtc);
    uint256 amount = JoeLibrary.quote(1 ether, amountWavax, amountWBTC);
    renbtcForOneETHPrice = ICurveInt128(renCrv).get_dy(1, 0, amount);
  }

  function toRenBTC(uint256 amountIn, bool useUnderlying) internal returns (uint256 amountOut) {
    if (useUnderlying) amountOut = ICurveInt128(renCrv).exchange_underlying(0, 1, amountIn, 1);
    else amountOut = ICurveInt128(renCrv).exchange(0, 1, amountIn, 1);
  }

  function renBTCtoETH(
    uint256 minOut,
    uint256 amountIn,
    address out
  ) internal returns (uint256 amountOut) {
    uint256 wbtcAmount = toWBTC(amountIn, true);
    address[] memory path = new address[](2);
    path[0] = wbtc;
    path[1] = wavax;
    uint256[] memory amounts = IJoeRouter02(joeRouter).swapExactTokensForAVAX(
      wbtcAmount,
      minOut,
      path,
      out,
      block.timestamp + 1
    );
    amountOut = amounts[1];
  }

  function fromIBBTC(uint256 amountIn) internal returns (uint256 amountOut) {
    uint256 amountStart = IERC20(renbtc).balanceOf(address(this));
    IBadgerSettPeak(settPeak).redeem(0, amountIn);
    ISett(bCrvRen).withdraw(IERC20(bCrvRen).balanceOf(address(this)));
    ICurveFiRen(renCrv).remove_liquidity_one_coin(IERC20(renCrvLp).balanceOf(address(this)), 0, 0);
    amountOut = IERC20(renbtc).balanceOf(address(this)).sub(amountStart);
  }

  function fromUSDC(uint256 minOut, uint256 amountIn) internal returns (uint256 amountOut) {
    uint256 wbtcAmount = IERC20(avWbtc).balanceOf(address(this));
    uint256[3] memory amounts;
    amounts[1] = amountIn;
    amountOut = ICurveFi(crvUsd).add_liquidity(amounts, 1, true);
    ICurveUInt256(tricrypto).exchange(0, 1, amountOut, 1);
    wbtcAmount = IERC20(avWbtc).balanceOf(address(this)).sub(wbtcAmount);
    amountOut = toRenBTC(wbtcAmount, false);
  }

  function fromUSDCNative(uint256 amountIn) internal returns (uint256 amountOut) {
    uint256 usdceAmountIn = ICurveInt128(usdcpool).exchange(1, 0, amountIn, 1, address(this));
    return fromUSDC(1, usdceAmountIn);
  }

  function fromETHToRenBTC(uint256 minOut, uint256 amountIn) internal returns (uint256 amountOut) {
    address[] memory path = new address[](2);
    path[0] = wavax;
    path[1] = wbtc;

    uint256[] memory amounts = IJoeRouter02(joeRouter).swapExactAVAXForTokens{ value: amountIn }(
      minOut,
      path,
      address(this),
      block.timestamp + 1
    );
    amountOut = toRenBTC(amounts[1], true);
  }

  function toETH() internal returns (uint256 amountOut) {
    uint256 wbtcAmount = IERC20(wbtc).balanceOf(address(this));
    address[] memory path = new address[](2);
    path[0] = wbtc;
    path[1] = wavax;
    uint256[] memory amounts = IJoeRouter02(joeRouter).swapExactTokensForAVAX(
      wbtcAmount,
      1,
      path,
      address(this),
      block.timestamp + 1
    );
    amountOut = amounts[1];
  }

  receive() external payable {
    // no-op
  }

  function earn() public {
    quote();
    toWBTC(IERC20(renbtc).balanceOf(address(this)), true);
    toETH();
    uint256 balance = address(this).balance;
    if (balance > ETH_RESERVE) {
      uint256 output = balance - ETH_RESERVE;
      uint256 toGovernance = applyRatio(output, governanceFee);
      bool success;
      address payable governancePayable = address(uint160(governance));
      (success, ) = governancePayable.call{ value: toGovernance, gas: gasleft() }("");
      require(success, "error sending to governance");
      address payable strategistPayable = address(uint160(strategist));
      (success, ) = strategistPayable.call{ value: output.sub(toGovernance), gas: gasleft() }("");
      require(success, "error sending to strategist");
    }
  }

  function computeRenBTCGasFee(uint256 gasCost, uint256 gasPrice) internal view returns (uint256 result) {
    result = gasCost.mul(tx.gasprice).mul(renbtcForOneETHPrice).div(uint256(1 ether));
  }

  function deductMintFee(uint256 amountIn, uint256 multiplier) internal view returns (uint256 amount) {
    amount = amountIn.sub(applyFee(amountIn, fee, multiplier));
  }

  function deductIBBTCMintFee(uint256 amountIn, uint256 multiplier) internal view returns (uint256 amount) {
    amount = amountIn.sub(applyIBBTCFee(amountIn, fee, multiplier));
  }

  function deductBurnFee(uint256 amountIn, uint256 multiplier) internal view returns (uint256 amount) {
    amount = amountIn.sub(applyFee(amountIn, burnFee, multiplier));
  }

  function deductIBBTCBurnFee(uint256 amountIn, uint256 multiplier) internal view returns (uint256 amount) {
    amount = amountIn.sub(applyIBBTCFee(amountIn, burnFee, multiplier));
  }

  function applyFee(
    uint256 amountIn,
    uint256 _fee,
    uint256 multiplier
  ) internal view returns (uint256 amount) {
    amount = computeRenBTCGasFee(GAS_COST.add(keeperReward.div(tx.gasprice)), tx.gasprice).add(
      applyRatio(amountIn, _fee)
    );
  }

  function applyIBBTCFee(
    uint256 amountIn,
    uint256 _fee,
    uint256 multiplier
  ) internal view returns (uint256 amount) {
    amount = computeRenBTCGasFee(IBBTC_GAS_COST.add(keeperReward.div(tx.gasprice)), tx.gasprice).add(
      applyRatio(amountIn, _fee)
    );
  }

  struct LoanParams {
    address to;
    address asset;
    uint256 nonce;
    uint256 amount;
    address module;
    address underwriter;
    bytes data;
    uint256 minOut;
    uint256 _mintAmount;
    uint256 gasDiff;
  }

  function toTypedDataHash(LoanParams memory params) internal view returns (bytes32 result) {
    bytes32 digest = _hashTypedDataV4(
      keccak256(
        abi.encode(
          keccak256(
            "TransferRequest(address asset,uint256 amount,address underwriter,address module,uint256 nonce,bytes data)"
          ),
          params.asset,
          params.amount,
          params.underwriter,
          params.module,
          params.nonce,
          keccak256(params.data)
        )
      )
    );
    return digest;
  }

  function repay(
    address underwriter,
    address to,
    address asset,
    uint256 amount,
    uint256 actualAmount,
    uint256 nonce,
    address module,
    bytes32 nHash,
    bytes memory data,
    bytes memory signature
  ) public returns (uint256 amountOut) {
    require(msg.data.length <= 516, "too much calldata");
    uint256 _gasBefore = gasleft();
    LoanParams memory params;
    {
      require(
        module == wbtc || module == usdc || module == renbtc || module == address(0x0) || module == usdc_native,
        "!approved-module"
      );
      params = LoanParams({
        to: to,
        asset: asset,
        amount: amount,
        nonce: nonce,
        module: module,
        underwriter: underwriter,
        data: data,
        minOut: 1,
        _mintAmount: 0,
        gasDiff: computeCalldataGasDiff()
      });
      if (data.length > 0) (params.minOut) = abi.decode(data, (uint256));
    }
    bytes32 digest = toTypedDataHash(params);

    params._mintAmount = IGateway(btcGateway).mint(
      keccak256(abi.encode(params.to, params.nonce, params.module, params.data)),
      actualAmount,
      nHash,
      signature
    );
    {
      amountOut = module == wbtc ? toWBTC(deductMintFee(params._mintAmount, 1), true) : module == address(0x0)
        ? renBTCtoETH(params.minOut, deductMintFee(params._mintAmount, 1), to)
        : module == usdc
        ? toUSDC(params.minOut, deductMintFee(params._mintAmount, 1))
        : module == usdc_native
        ? toUSDCNative(deductMintFee(params._mintAmount, 1))
        : deductMintFee(params._mintAmount, 1);
    }
    {
      if (module != address(0x0)) IERC20(module).safeTransfer(to, amountOut);
    }
    {
      tx.origin.transfer(
        Math.min(
          _gasBefore.sub(gasleft()).add(REPAY_GAS_DIFF).add(params.gasDiff).mul(tx.gasprice).add(keeperReward),
          address(this).balance
        )
      );
    }
  }

  function computeBurnNonce(BurnLocals memory params) internal view returns (uint256 result) {
    result = uint256(
      keccak256(
        abi.encodePacked(params.asset, params.amount, params.deadline, params.nonce, params.data, params.destination)
      )
    );
    while (result < block.timestamp) {
      // negligible probability of this
      result = uint256(keccak256(abi.encodePacked(result)));
    }
  }

  function computeERC20PermitDigest(bytes32 domainSeparator, BurnLocals memory params)
    internal
    view
    returns (bytes32 result)
  {
    result = keccak256(
      abi.encodePacked(
        "\x19\x01",
        domainSeparator,
        keccak256(abi.encode(PERMIT_TYPEHASH, params.to, address(this), params.nonce, computeBurnNonce(params), true))
      )
    );
  }

  struct BurnLocals {
    address to;
    address asset;
    uint256 amount;
    uint256 deadline;
    uint256 nonce;
    bytes data;
    uint256 minOut;
    uint256 burnNonce;
    uint256 gasBefore;
    uint256 gasDiff;
    uint8 v;
    bytes32 r;
    bytes32 s;
    bytes destination;
    bytes signature;
  }

  function burn(
    address to,
    address asset,
    uint256 amount,
    uint256 deadline,
    bytes memory data,
    bytes memory destination,
    bytes memory signature
  ) public returns (uint256 amountToBurn) {
    require(msg.data.length <= 580, "too much calldata");
    BurnLocals memory params = BurnLocals({
      to: to,
      asset: asset,
      amount: amount,
      deadline: deadline,
      data: data,
      nonce: 0,
      burnNonce: 0,
      v: uint8(0),
      r: bytes32(0),
      s: bytes32(0),
      destination: destination,
      signature: signature,
      gasBefore: gasleft(),
      minOut: 1,
      gasDiff: 0
    });
    {
      params.gasDiff = computeCalldataGasDiff();
      if (params.data.length > 0) (params.minOut) = abi.decode(params.data, (uint256));
    }
    require(block.timestamp < params.deadline, "!deadline");

    if (params.asset == wbtc) {
      params.nonce = nonces[to];
      nonces[params.to]++;
      require(
        params.to == ECDSA.recover(computeERC20PermitDigest(PERMIT_DOMAIN_SEPARATOR_WBTC, params), params.signature),
        "!signature"
      ); //  wbtc does not implement ERC20Permit
      {
        IERC20(params.asset).transferFrom(params.to, address(this), params.amount);
        amountToBurn = toRenBTC(deductBurnFee(params.amount, 1), true);
      }
    } else if (asset == usdc_native) {
      {
        params.nonce = IERC2612Permit(params.asset).nonces(params.to);
        params.burnNonce = computeBurnNonce(params);
      }
      {
        (params.v, params.r, params.s) = SplitSignatureLib.splitSignature(params.signature);
        IERC2612Permit(params.asset).permit(
          params.to,
          address(this),
          params.amount,
          params.burnNonce,
          params.v,
          params.r,
          params.s
        );
      }
      {
        IERC20(params.asset).transferFrom(params.to, address(this), params.amount);
        amountToBurn = deductBurnFee(fromUSDCNative(params.amount), 1);
      }
    } else if (params.asset == renbtc) {
      {
        params.nonce = IERC2612Permit(params.asset).nonces(params.to);
        params.burnNonce = computeBurnNonce(params);
      }
      {
        (params.v, params.r, params.s) = SplitSignatureLib.splitSignature(params.signature);
        IERC2612Permit(params.asset).permit(
          params.to,
          address(this),
          params.nonce,
          params.burnNonce,
          true,
          params.v,
          params.r,
          params.s
        );
      }
      {
        IERC20(params.asset).transferFrom(params.to, address(this), params.amount);
      }
      amountToBurn = deductBurnFee(params.amount, 1);
    } else if (params.asset == usdc) {
      params.nonce = noncesUsdc[to];
      noncesUsdc[params.to]++;
      require(
        params.to == ECDSA.recover(computeERC20PermitDigest(PERMIT_DOMAIN_SEPARATOR_USDC, params), params.signature),
        "!signature"
      ); //  usdc.e does not implement ERC20Permit
      {
        IERC20(params.asset).transferFrom(params.to, address(this), params.amount);
      }
      amountToBurn = deductBurnFee(fromUSDC(params.minOut, params.amount), 1);
    } else revert("!supported-asset");
    {
      IGateway(btcGateway).burn(params.destination, amountToBurn);
    }
    {
      tx.origin.transfer(
        Math.min(
          params.gasBefore.sub(gasleft()).add(BURN_GAS_DIFF).add(params.gasDiff).mul(tx.gasprice).add(keeperReward),
          address(this).balance
        )
      );
    }
  }

  function burnETH(uint256 minOut, bytes memory destination) public payable returns (uint256 amountToBurn) {
    amountToBurn = fromETHToRenBTC(minOut, msg.value.sub(applyRatio(msg.value, burnFee)));
    IGateway(btcGateway).burn(destination, amountToBurn);
  }

  function burnApproved(
    address from,
    address asset,
    uint256 amount,
    uint256 minOut,
    bytes memory destination
  ) public payable returns (uint256 amountToBurn) {
    require(asset == wbtc || asset == usdc || asset == renbtc || asset == address(0x0), "!approved-module");
    if (asset != address(0x0)) IERC20(asset).transferFrom(msg.sender, address(this), amount);
    amountToBurn = asset == wbtc ? toRenBTC(amount.sub(applyRatio(amount, burnFee)), true) : asset == usdc
      ? fromUSDC(minOut, amount.sub(applyRatio(amount, burnFee)))
      : asset == renbtc
      ? amount
      : fromETHToRenBTC(minOut, msg.value.sub(applyRatio(msg.value, burnFee)));
    IGateway(btcGateway).burn(destination, amountToBurn);
  }

  function fallbackMint(
    address underwriter,
    address to,
    address asset,
    uint256 amount,
    uint256 actualAmount,
    uint256 nonce,
    address module,
    bytes32 nHash,
    bytes memory data,
    bytes memory signature
  ) public {
    LoanParams memory params = LoanParams({
      to: to,
      asset: asset,
      amount: amount,
      nonce: nonce,
      module: module,
      underwriter: underwriter,
      data: data,
      minOut: 1,
      _mintAmount: 0,
      gasDiff: 0
    });
    bytes32 digest = toTypedDataHash(params);
    uint256 _actualAmount = IGateway(btcGateway).mint(
      keccak256(abi.encode(params.to, params.nonce, params.module, params.data)),
      actualAmount,
      nHash,
      signature
    );
    IERC20(asset).safeTransfer(to, _actualAmount);
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import "@traderjoe-xyz/core/contracts/traderjoe/interfaces/IJoePair.sol";

import "oz410/math/SafeMath.sol";

library JoeLibrary {
  using SafeMath for uint256;

  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
    require(tokenA != tokenB, "JoeLibrary: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "JoeLibrary: ZERO_ADDRESS");
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = address(
      uint256(
        keccak256(
          abi.encodePacked(
            hex"ff",
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex"0bbca9af0511ad1a1da383135cf3a8d2ac620e549ef9f6ae3a4c33c2fed0af91" // init code fuji
          )
        )
      )
    );
  }

  // fetches and sorts the reserves for a pair
  function getReserves(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (uint256 reserveA, uint256 reserveB) {
    (address token0, ) = sortTokens(tokenA, tokenB);
    (uint256 reserve0, uint256 reserve1, ) = IJoePair(pairFor(factory, tokenA, tokenB)).getReserves();
    (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) internal pure returns (uint256 amountB) {
    require(amountA > 0, "JoeLibrary: INSUFFICIENT_AMOUNT");
    require(reserveA > 0 && reserveB > 0, "JoeLibrary: INSUFFICIENT_LIQUIDITY");
    amountB = amountA.mul(reserveB) / reserveA;
  }

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountOut) {
    require(amountIn > 0, "JoeLibrary: INSUFFICIENT_INPUT_AMOUNT");
    require(reserveIn > 0 && reserveOut > 0, "JoeLibrary: INSUFFICIENT_LIQUIDITY");
    uint256 amountInWithFee = amountIn.mul(997);
    uint256 numerator = amountInWithFee.mul(reserveOut);
    uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
    amountOut = numerator / denominator;
  }

  // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountIn) {
    require(amountOut > 0, "JoeLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
    require(reserveIn > 0 && reserveOut > 0, "JoeLibrary: INSUFFICIENT_LIQUIDITY");
    uint256 numerator = reserveIn.mul(amountOut).mul(1000);
    uint256 denominator = reserveOut.sub(amountOut).mul(997);
    amountIn = (numerator / denominator).add(1);
  }

  // performs chained getAmountOut calculations on any number of pairs
  function getAmountsOut(
    address factory,
    uint256 amountIn,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "JoeLibrary: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[0] = amountIn;
    for (uint256 i; i < path.length - 1; i++) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  // performs chained getAmountIn calculations on any number of pairs
  function getAmountsIn(
    address factory,
    uint256 amountOut,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "JoeLibrary: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint256 i = path.length - 1; i > 0; i--) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface ICurveFi {
  function add_liquidity(
    uint256[3] calldata amounts,
    uint256 min_amount,
    bool use_underlying
  ) external returns (uint256);

  function remove_liquidity_one_coin(
    uint256,
    int128,
    uint256,
    bool
  ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

interface ICurveUInt256 {
  function get_dy(
    uint256,
    uint256,
    uint256
  ) external view returns (uint256);

  function exchange(
    uint256,
    uint256,
    uint256,
    uint256
  ) external returns (uint256);

  function coins(uint256) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

interface ICurveInt128 {
  function get_dy(
    int128,
    int128,
    uint256
  ) external view returns (uint256);

  function get_dy_underlying(
    int128,
    int128,
    uint256
  ) external view returns (uint256);

  function exchange(
    int128,
    int128,
    uint256,
    uint256
  ) external returns (uint256);

  function exchange(
    int128,
    int128,
    uint256,
    uint256,
    address
  ) external returns (uint256);

  function exchange_underlying(
    int128,
    int128,
    uint256,
    uint256
  ) external returns (uint256);

  function coins(int128) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import "./IJoeRouter01.sol";

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IJoePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma abicoder v2;

import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { UniswapV2Library } from "../libraries/UniswapV2Library.sol";
import { ZeroLib } from "../libraries/ZeroLib.sol";
import { IERC2612Permit } from "../interfaces/IERC2612Permit.sol";
import { ICurveInt128 } from "../interfaces/CurvePools/ICurveInt128.sol";
import { SplitSignatureLib } from "../libraries/SplitSignatureLib.sol";
import { IBadgerSettPeak } from "../interfaces/IBadgerSettPeak.sol";
import { ICurveFi } from "../interfaces/ICurveFi.sol";
import { IGateway } from "../interfaces/IGateway.sol";
import { IWETH9 } from "@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";
import { ICurveETHUInt256 } from "../interfaces/CurvePools/ICurveETHUInt256.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IyVault } from "../interfaces/IyVault.sol";
import { ISett } from "../interfaces/ISett.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IQuoter } from "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ECDSA } from "@openzeppelin/contracts/cryptography/ECDSA.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/drafts/EIP712Upgradeable.sol";

contract BadgerBridgeZeroControllerOptimism is EIP712Upgradeable {
  using SafeERC20 for IERC20;
  using SafeMath for *;
  uint256 public fee;
  address public governance;
  address public strategist;

  address constant btcGateway = 0xB538901719936e628A9b9AF64A5a4Dbc273305cd;
  address constant renbtc = 0x85f6583762Bc76d775eAB9A7456db344f12409F7;
  uint256 public governanceFee;
  bytes32 constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
  bytes32 constant LOCK_SLOT = keccak256("upgrade-lock-v2");
  uint256 constant GAS_COST = uint256(642e3);
  uint256 constant ETH_RESERVE = uint256(5 ether);
  uint256 internal renbtcForOneETHPrice;
  uint256 internal burnFee;
  uint256 public keeperReward;
  uint256 public constant REPAY_GAS_DIFF = 41510;
  uint256 public constant BURN_GAS_DIFF = 41118;

  function setStrategist(address _strategist) public {
    require(msg.sender == governance, "!governance");
    strategist = _strategist;
  }

  function setGovernance(address _governance) public {
    require(msg.sender == governance, "!governance");
    governance = _governance;
  }

  function computeCalldataGasDiff() internal pure returns (uint256 diff) {
    if (true) return 0; // TODO: implement exact gas metering
    // EVM charges less for zero bytes, we must compute the offset for refund
    // TODO make this efficient
    uint256 sz;
    assembly {
      sz := calldatasize()
    }
    diff = sz.mul(uint256(68));
    bytes memory slice;
    for (uint256 i = 0; i < sz; i += 0x20) {
      uint256 word;
      assembly {
        word := calldataload(i)
      }
      for (uint256 i = 0; i < 256 && ((uint256(~0) << i) & word) != 0; i += 8) {
        if ((word >> i) & 0xff != 0) diff -= 64;
      }
    }
  }

  function getChainId() internal pure returns (uint256 result) {
    assembly {
      result := chainid()
    }
  }

  function setParameters(
    uint256 _governanceFee,
    uint256 _fee,
    uint256 _burnFee,
    uint256 _keeperReward
  ) public {
    require(governance == msg.sender, "!governance");
    governanceFee = _governanceFee;
    fee = _fee;
    burnFee = _burnFee;
    keeperReward = _keeperReward;
  }

  function initialize(address _governance, address _strategist) public initializer {
    fee = uint256(25e14);
    burnFee = uint256(4e15);
    governanceFee = uint256(5e17);
    governance = _governance;
    strategist = _strategist;
    keeperReward = uint256(1 ether).div(1000);
  }

  function applyRatio(uint256 v, uint256 n) internal pure returns (uint256 result) {
    result = v.mul(n).div(uint256(1 ether));
  }

  function quote() internal {}

  receive() external payable {
    // no-op
  }

  function earn() public {
    quote();
    uint256 balance = address(this).balance;
    if (balance > ETH_RESERVE) {
      uint256 output = balance - ETH_RESERVE;
      uint256 toGovernance = applyRatio(output, governanceFee);
      bool success;
      address payable governancePayable = address(uint160(governance));
      (success, ) = governancePayable.call{ value: toGovernance, gas: gasleft() }("");
      require(success, "error sending to governance");
      address payable strategistPayable = address(uint160(strategist));
      (success, ) = strategistPayable.call{ value: output.sub(toGovernance), gas: gasleft() }("");
      require(success, "error sending to strategist");
    }
  }

  function computeRenBTCGasFee(uint256 gasCost, uint256 gasPrice) internal view returns (uint256 result) {
    result = gasCost.mul(tx.gasprice).mul(renbtcForOneETHPrice).div(uint256(1 ether));
  }

  function deductMintFee(uint256 amountIn, uint256 multiplier) internal view returns (uint256 amount) {
    amount = amountIn.sub(applyFee(amountIn, fee, multiplier));
  }

  function deductBurnFee(uint256 amountIn, uint256 multiplier) internal view returns (uint256 amount) {
    amount = amountIn.sub(applyFee(amountIn, burnFee, multiplier));
  }

  function applyFee(
    uint256 amountIn,
    uint256 _fee,
    uint256 multiplier
  ) internal view returns (uint256 amount) {
    amount = computeRenBTCGasFee(GAS_COST.add(keeperReward.div(tx.gasprice)), tx.gasprice).add(
      applyRatio(amountIn, _fee)
    );
  }

  struct LoanParams {
    address to;
    address asset;
    uint256 nonce;
    uint256 amount;
    address module;
    address underwriter;
    bytes data;
    uint256 minOut;
    uint256 _mintAmount;
    uint256 gasDiff;
  }

  function toTypedDataHash(LoanParams memory params) internal view returns (bytes32 result) {
    bytes32 digest = _hashTypedDataV4(
      keccak256(
        abi.encode(
          keccak256(
            "TransferRequest(address asset,uint256 amount,address underwriter,address module,uint256 nonce,bytes data)"
          ),
          params.asset,
          params.amount,
          params.underwriter,
          params.module,
          params.nonce,
          keccak256(params.data)
        )
      )
    );
    return digest;
  }

  function repay(
    address underwriter,
    address to,
    address asset,
    uint256 amount,
    uint256 actualAmount,
    uint256 nonce,
    address module,
    bytes32 nHash,
    bytes memory data,
    bytes memory signature
  ) public returns (uint256 amountOut) {
    require(msg.data.length <= 516, "too much calldata");
    uint256 _gasBefore = gasleft();
    LoanParams memory params;
    {
      require(module == renbtc, "!approved-module");
      params = LoanParams({
        to: to,
        asset: asset,
        amount: amount,
        nonce: nonce,
        module: module,
        underwriter: underwriter,
        data: data,
        minOut: 1,
        _mintAmount: 0,
        gasDiff: computeCalldataGasDiff()
      });
      if (data.length > 0) (params.minOut) = abi.decode(data, (uint256));
    }
    bytes32 digest = toTypedDataHash(params);

    params._mintAmount = IGateway(btcGateway).mint(
      keccak256(abi.encode(params.to, params.nonce, params.module, params.data)),
      actualAmount,
      nHash,
      signature
    );
    {
      amountOut = deductMintFee(params._mintAmount, 1);
    }
    {
      IERC20(module).safeTransfer(to, amountOut);
    }
    {
      tx.origin.transfer(
        Math.min(
          _gasBefore.sub(gasleft()).add(REPAY_GAS_DIFF).add(params.gasDiff).mul(tx.gasprice).add(keeperReward),
          address(this).balance
        )
      );
    }
  }

  function computeBurnNonce(BurnLocals memory params) internal view returns (uint256 result) {
    result = uint256(
      keccak256(
        abi.encodePacked(params.asset, params.amount, params.deadline, params.nonce, params.data, params.destination)
      )
    );
    while (result < block.timestamp) {
      // negligible probability of this
      result = uint256(keccak256(abi.encodePacked(result)));
    }
  }

  function computeERC20PermitDigest(bytes32 domainSeparator, BurnLocals memory params)
    internal
    view
    returns (bytes32 result)
  {
    result = keccak256(
      abi.encodePacked(
        "\x19\x01",
        domainSeparator,
        keccak256(abi.encode(PERMIT_TYPEHASH, params.to, address(this), params.nonce, computeBurnNonce(params), true))
      )
    );
  }

  struct BurnLocals {
    address to;
    address asset;
    uint256 amount;
    uint256 deadline;
    uint256 nonce;
    bytes data;
    uint256 minOut;
    uint256 burnNonce;
    uint256 gasBefore;
    uint256 gasDiff;
    uint8 v;
    bytes32 r;
    bytes32 s;
    bytes destination;
    bytes signature;
  }

  function burn(
    address to,
    address asset,
    uint256 amount,
    uint256 deadline,
    bytes memory data,
    bytes memory destination,
    bytes memory signature
  ) public returns (uint256 amountToBurn) {
    require(msg.data.length <= 580, "too much calldata");
    BurnLocals memory params = BurnLocals({
      to: to,
      asset: asset,
      amount: amount,
      deadline: deadline,
      data: data,
      nonce: 0,
      burnNonce: 0,
      v: uint8(0),
      r: bytes32(0),
      s: bytes32(0),
      destination: destination,
      signature: signature,
      gasBefore: gasleft(),
      minOut: 1,
      gasDiff: 0
    });
    {
      params.gasDiff = computeCalldataGasDiff();
      if (params.data.length > 0) (params.minOut) = abi.decode(params.data, (uint256));
    }
    require(block.timestamp < params.deadline, "!deadline");

    if (params.asset == renbtc) {
      {
        params.nonce = IERC2612Permit(params.asset).nonces(params.to);
        params.burnNonce = computeBurnNonce(params);
      }
      {
        (params.v, params.r, params.s) = SplitSignatureLib.splitSignature(params.signature);
        IERC2612Permit(params.asset).permit(
          params.to,
          address(this),
          params.nonce,
          params.burnNonce,
          true,
          params.v,
          params.r,
          params.s
        );
      }
      {
        IERC20(params.asset).transferFrom(params.to, address(this), params.amount);
      }
      amountToBurn = deductBurnFee(params.amount, 1);
    } else revert("!supported-asset");
    {
      IGateway(btcGateway).burn(params.destination, amountToBurn);
    }
    {
      tx.origin.transfer(
        Math.min(
          params.gasBefore.sub(gasleft()).add(BURN_GAS_DIFF).add(params.gasDiff).mul(tx.gasprice).add(keeperReward),
          address(this).balance
        )
      );
    }
  }

  function fallbackMint(
    address underwriter,
    address to,
    address asset,
    uint256 amount,
    uint256 actualAmount,
    uint256 nonce,
    address module,
    bytes32 nHash,
    bytes memory data,
    bytes memory signature
  ) public {
    LoanParams memory params = LoanParams({
      to: to,
      asset: asset,
      amount: amount,
      nonce: nonce,
      module: module,
      underwriter: underwriter,
      data: data,
      minOut: 1,
      _mintAmount: 0,
      gasDiff: 0
    });
    bytes32 digest = toTypedDataHash(params);
    uint256 _actualAmount = IGateway(btcGateway).mint(
      keccak256(abi.encode(params.to, params.nonce, params.module, params.data)),
      actualAmount,
      nHash,
      signature
    );
    IERC20(asset).safeTransfer(to, _actualAmount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma abicoder v2;

import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { UniswapV2Library } from "../libraries/UniswapV2Library.sol";
import { ZeroLib } from "../libraries/ZeroLib.sol";
import { IERC2612Permit } from "../interfaces/IERC2612Permit.sol";
import { SplitSignatureLib } from "../libraries/SplitSignatureLib.sol";
import { IWETH } from "../interfaces/IWETH.sol";
import { IGateway } from "../interfaces/IGateway.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ECDSA } from "@openzeppelin/contracts/cryptography/ECDSA.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/drafts/EIP712Upgradeable.sol";

contract RenZECController is EIP712Upgradeable {
  using SafeERC20 for IERC20;
  using SafeMath for *;
  uint256 public fee;
  address public governance;
  address public strategist;

  address constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address constant renzec = 0x1C5db575E2Ff833E46a2E9864C22F4B22E0B37C2;
  address constant zecGateway = 0xc3BbD5aDb611dd74eCa6123F05B18acc886e122D;
  address constant routerv3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
  address constant factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
  address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
  address constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address constant quoter = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
  uint24 constant uniswapv3Fee = 500;
  uint256 public governanceFee;
  bytes32 constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
  uint256 constant GAS_COST = uint256(36e4);
  bytes32 constant LOCK_SLOT = keccak256("upgrade-v1");
  uint256 constant ETH_RESERVE = uint256(5 ether);
  uint256 internal renzecForOneETHPrice;
  uint256 internal burnFee;
  uint256 public keeperReward;
  uint256 public constant REPAY_GAS_DIFF = 41510;
  uint256 public constant BURN_GAS_DIFF = 41118;
  bytes32 internal PERMIT_DOMAIN_SEPARATOR_USDT;
  mapping(address => uint256) public noncesUsdt;

  function setStrategist(address _strategist) public {
    require(msg.sender == governance, "!governance");
    strategist = _strategist;
  }

  function setGovernance(address _governance) public {
    require(msg.sender == governance, "!governance");
    governance = _governance;
  }

  function computeCalldataGasDiff() internal pure returns (uint256 diff) {
    if (true) return 0; // TODO: implement exact gas metering
    // EVM charges less for zero bytes, we must compute the offset for refund
    // TODO make this efficient
    uint256 sz;
    assembly {
      sz := calldatasize()
    }
    diff = sz.mul(uint256(68));
    bytes memory slice;
    for (uint256 i = 0; i < sz; i += 0x20) {
      uint256 word;
      assembly {
        word := calldataload(i)
      }
      for (uint256 i = 0; i < 256 && ((uint256(~0) << i) & word) != 0; i += 8) {
        if ((word >> i) & 0xff != 0) diff -= 64;
      }
    }
  }

  function getChainId() internal pure returns (uint256 result) {
    assembly {
      result := chainid()
    }
  }

  function setParameters(
    uint256 _governanceFee,
    uint256 _fee,
    uint256 _burnFee,
    uint256 _keeperReward
  ) public {
    require(governance == msg.sender, "!governance");
    governanceFee = _governanceFee;
    fee = _fee;
    burnFee = _burnFee;
    keeperReward = _keeperReward;
  }

  function initialize(address _governance, address _strategist) public initializer {
    fee = uint256(25e14);
    burnFee = uint256(4e15);
    governanceFee = uint256(5e17);
    governance = _governance;
    strategist = _strategist;
    keeperReward = uint256(1 ether).div(1000);
    IERC20(weth).safeApprove(routerv3, ~uint256(0) >> 2);
    IERC20(usdc).safeApprove(routerv3, ~uint256(0) >> 2);
    IERC20(usdt).safeApprove(routerv3, ~uint256(0) >> 2);
    IERC20(weth).safeApprove(router, ~uint256(0) >> 2);
    IERC20(renzec).safeApprove(router, ~uint256(0) >> 2);
    PERMIT_DOMAIN_SEPARATOR_USDT = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("USDT"),
        keccak256("1"),
        getChainId(),
        usdt
      )
    );
  }

  function postUpgrade() public {
    bool isLocked;
    bytes32 upgradeSlot = LOCK_SLOT;

    assembly {
      isLocked := sload(upgradeSlot)
    }

    require(!isLocked, "already upgraded");
    PERMIT_DOMAIN_SEPARATOR_USDT = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("USDT"),
        keccak256("1"),
        getChainId(),
        usdt
      )
    );
    IERC20(usdc).safeApprove(routerv3, ~uint256(0) >> 2);
    IERC20(usdt).safeApprove(routerv3, ~uint256(0) >> 2);

    isLocked = true;
    assembly {
      sstore(upgradeSlot, isLocked)
    }
  }

  function applyRatio(uint256 v, uint256 n) internal pure returns (uint256 result) {
    result = v.mul(n).div(uint256(1 ether));
  }

  function quote() internal {
    (uint256 amountWeth, uint256 amountRenZEC) = UniswapV2Library.getReserves(factory, weth, renzec);
    renzecForOneETHPrice = UniswapV2Library.quote(uint256(1 ether), amountWeth, amountRenZEC);
  }

  function renZECtoETH(
    uint256 minOut,
    uint256 amountIn,
    address out
  ) internal returns (uint256 amountOut) {
    address[] memory path = new address[](2);
    path[0] = renzec;
    path[1] = weth;
    uint256[] memory amounts = new uint256[](2);
    amounts = IUniswapV2Router02(router).swapExactTokensForETH(amountIn, minOut, path, out, block.timestamp + 1);
    return amounts[1];
  }

  function fromETHToRenZEC(uint256 minOut, uint256 amountIn) internal returns (uint256) {
    address[] memory path = new address[](2);
    path[0] = weth;
    path[1] = renzec;
    uint256[] memory amounts = new uint256[](2);
    amounts = IUniswapV2Router02(router).swapExactETHForTokens{ value: amountIn }(
      minOut,
      path,
      address(this),
      block.timestamp + 1
    );
    return amounts[1];
  }

  function fromUSDC(uint256 minOut, uint256 amountIn) internal returns (uint256 amountOut) {
    bytes memory path = abi.encodePacked(usdc, uniswapv3Fee, weth);
    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      recipient: address(this),
      deadline: block.timestamp + 1,
      amountIn: amountIn,
      amountOutMinimum: 1,
      path: path
    });
    amountOut = ISwapRouter(routerv3).exactInput(params);
    IWETH(weth).withdraw(amountOut);
    amountOut = fromETHToRenZEC(minOut, amountOut);
  }

  function fromUSDT(uint256 minOut, uint256 amountIn) internal returns (uint256 amountOut) {
    bytes memory path = abi.encodePacked(usdt, uniswapv3Fee, weth);
    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      recipient: address(this),
      deadline: block.timestamp + 1,
      amountIn: amountIn,
      amountOutMinimum: 1,
      path: path
    });
    amountOut = ISwapRouter(routerv3).exactInput(params);
    IWETH(weth).withdraw(amountOut);
    amountOut = fromETHToRenZEC(minOut, amountOut);
  }

  function toUSDC(
    uint256 minOut,
    uint256 amountIn,
    address out
  ) internal returns (uint256 amountOut) {
    bytes memory path = abi.encodePacked(weth, uniswapv3Fee, usdc);
    amountOut = renZECtoETH(1, amountIn, address(this));
    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      recipient: out,
      deadline: block.timestamp + 1,
      amountIn: amountOut,
      amountOutMinimum: minOut,
      path: path
    });
    amountOut = ISwapRouter(routerv3).exactInput{ value: amountOut }(params);
  }

  function toUSDT(
    uint256 minOut,
    uint256 amountIn,
    address out
  ) internal returns (uint256 amountOut) {
    bytes memory path = abi.encodePacked(weth, uniswapv3Fee, usdt);
    amountOut = renZECtoETH(1, amountIn, address(this));
    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      recipient: out,
      deadline: block.timestamp + 1,
      amountIn: amountOut,
      amountOutMinimum: minOut,
      path: path
    });
    amountOut = ISwapRouter(routerv3).exactInput{ value: amountOut }(params);
  }

  function toETH() internal returns (uint256 amountOut) {
    address[] memory path = new address[](2);
    path[0] = renzec;
    path[1] = weth;
    uint256[] memory amounts = new uint256[](2);
    IUniswapV2Router02(router).swapExactTokensForETH(
      IERC20(renzec).balanceOf(address(this)),
      1,
      path,
      address(this),
      block.timestamp + 1
    );
  }

  receive() external payable {
    // no-op
  }

  function earn() public {
    quote();
    toETH();
    uint256 balance = address(this).balance;
    if (balance > ETH_RESERVE) {
      uint256 output = balance - ETH_RESERVE;
      uint256 toGovernance = applyRatio(output, governanceFee);
      bool success;
      address payable governancePayable = address(uint160(governance));
      (success, ) = governancePayable.call{ value: toGovernance, gas: gasleft() }("");
      require(success, "error sending to governance");
      address payable strategistPayable = address(uint160(strategist));
      (success, ) = strategistPayable.call{ value: output.sub(toGovernance), gas: gasleft() }("");
      require(success, "error sending to strategist");
    }
  }

  function computeRenZECGasFee(uint256 gasCost, uint256 gasPrice) internal view returns (uint256 result) {
    result = gasCost.mul(tx.gasprice).mul(renzecForOneETHPrice).div(uint256(1 ether));
  }

  function deductMintFee(uint256 amountIn, uint256 multiplier) internal view returns (uint256 amount) {
    amount = amountIn.sub(applyFee(amountIn, fee, multiplier));
  }

  function deductBurnFee(uint256 amountIn, uint256 multiplier) internal view returns (uint256 amount) {
    amount = amountIn.sub(applyFee(amountIn, burnFee, multiplier));
  }

  function applyFee(
    uint256 amountIn,
    uint256 _fee,
    uint256 multiplier
  ) internal view returns (uint256 amount) {
    amount = computeRenZECGasFee(GAS_COST.add(keeperReward.div(tx.gasprice)), tx.gasprice).add(
      applyRatio(amountIn, _fee)
    );
  }

  struct LoanParams {
    address to;
    address asset;
    uint256 nonce;
    uint256 amount;
    address module;
    address underwriter;
    bytes data;
    uint256 minOut;
    uint256 _mintAmount;
    uint256 gasDiff;
  }

  function toTypedDataHash(LoanParams memory params) internal view returns (bytes32 result) {
    bytes32 digest = _hashTypedDataV4(
      keccak256(
        abi.encode(
          keccak256(
            "TransferRequest(address asset,uint256 amount,address underwriter,address module,uint256 nonce,bytes data)"
          ),
          params.asset,
          params.amount,
          params.underwriter,
          params.module,
          params.nonce,
          keccak256(params.data)
        )
      )
    );
    return digest;
  }

  function repay(
    address underwriter,
    address to,
    address asset,
    uint256 amount,
    uint256 actualAmount,
    uint256 nonce,
    address module,
    bytes32 nHash,
    bytes memory data,
    bytes memory signature
  ) public returns (uint256 amountOut) {
    require(msg.data.length <= 516, "too much calldata");
    uint256 _gasBefore = gasleft();
    LoanParams memory params;
    {
      require(module == usdc || module == usdt || module == address(0x0) || module == renzec, "!approved-module");
      params = LoanParams({
        to: to,
        asset: asset,
        amount: amount,
        nonce: nonce,
        module: module,
        underwriter: underwriter,
        data: data,
        minOut: 1,
        _mintAmount: 0,
        gasDiff: computeCalldataGasDiff()
      });
      if (data.length > 0) (params.minOut) = abi.decode(data, (uint256));
    }
    bytes32 digest = toTypedDataHash(params);

    params._mintAmount = IGateway(zecGateway).mint(
      keccak256(abi.encode(params.to, params.nonce, params.module, params.data)),
      actualAmount,
      nHash,
      signature
    );

    {
      amountOut = module == address(0x0)
        ? renZECtoETH(params.minOut, deductMintFee(params._mintAmount, 1), to)
        : module == usdc
        ? toUSDC(params.minOut, deductMintFee(params._mintAmount, 1), to)
        : module == usdt
        ? toUSDT(params.minOut, deductMintFee(params._mintAmount, 1), to)
        : deductMintFee(params._mintAmount, 1);
    }
    {
      if (module == renzec) IERC20(module).safeTransfer(to, amountOut);
    }
    {
      tx.origin.transfer(
        Math.min(
          _gasBefore.sub(gasleft()).add(REPAY_GAS_DIFF).add(params.gasDiff).mul(tx.gasprice).add(keeperReward),
          address(this).balance
        )
      );
    }
  }

  function burnETH(uint256 minOut, bytes memory destination) public payable returns (uint256 amountToBurn) {
    amountToBurn = fromETHToRenZEC(minOut, msg.value.sub(applyRatio(msg.value, burnFee)));
    IGateway(zecGateway).burn(destination, amountToBurn);
  }

  function computeBurnNonce(BurnLocals memory params) internal view returns (uint256 result) {
    result = uint256(
      keccak256(
        abi.encodePacked(params.asset, params.amount, params.deadline, params.nonce, params.data, params.destination)
      )
    );
    while (result < block.timestamp) {
      // negligible probability of this
      result = uint256(keccak256(abi.encodePacked(result)));
    }
  }

  function computeERC20PermitDigest(bytes32 domainSeparator, BurnLocals memory params)
    internal
    view
    returns (bytes32 result)
  {
    result = keccak256(
      abi.encodePacked(
        "\x19\x01",
        domainSeparator,
        keccak256(abi.encode(PERMIT_TYPEHASH, params.to, address(this), params.nonce, computeBurnNonce(params), true))
      )
    );
  }

  struct BurnLocals {
    address to;
    address asset;
    uint256 amount;
    uint256 deadline;
    uint256 nonce;
    bytes data;
    uint256 minOut;
    uint256 burnNonce;
    uint256 gasBefore;
    uint256 gasDiff;
    uint8 v;
    bytes32 r;
    bytes32 s;
    bytes destination;
    bytes signature;
  }

  function burn(
    address to,
    address asset,
    uint256 amount,
    uint256 deadline,
    bytes memory data,
    bytes memory destination,
    bytes memory signature
  ) public returns (uint256 amountToBurn) {
    require(msg.data.length <= 580, "too much calldata");
    BurnLocals memory params = BurnLocals({
      to: to,
      asset: asset,
      amount: amount,
      deadline: deadline,
      data: data,
      nonce: 0,
      burnNonce: 0,
      v: uint8(0),
      r: bytes32(0),
      s: bytes32(0),
      destination: destination,
      signature: signature,
      gasBefore: gasleft(),
      minOut: 1,
      gasDiff: 0
    });
    {
      params.gasDiff = computeCalldataGasDiff();
      if (params.data.length > 0) (params.minOut) = abi.decode(params.data, (uint256));
    }
    require(block.timestamp < params.deadline, "!deadline");
    if (params.asset == renzec) {
      {
        params.nonce = IERC2612Permit(params.asset).nonces(params.to);
        params.burnNonce = computeBurnNonce(params);
      }
      {
        (params.v, params.r, params.s) = SplitSignatureLib.splitSignature(params.signature);
        IERC2612Permit(params.asset).permit(
          params.to,
          address(this),
          params.nonce,
          params.burnNonce,
          true,
          params.v,
          params.r,
          params.s
        );
      }
      {
        IERC20(params.asset).transferFrom(params.to, address(this), params.amount);
      }
      amountToBurn = deductBurnFee(params.amount, 1);
    } else if (params.asset == usdc) {
      {
        params.nonce = IERC2612Permit(params.asset).nonces(params.to);
        params.burnNonce = computeBurnNonce(params);
      }
      {
        (params.v, params.r, params.s) = SplitSignatureLib.splitSignature(params.signature);
        IERC2612Permit(params.asset).permit(
          params.to,
          address(this),
          params.amount,
          params.burnNonce,
          params.v,
          params.r,
          params.s
        );
      }
      {
        IERC20(params.asset).safeTransferFrom(params.to, address(this), params.amount);
      }
      amountToBurn = deductBurnFee(fromUSDC(params.minOut, params.amount), 1);
    } else if (params.asset == usdt) {
      params.nonce = noncesUsdt[to];
      noncesUsdt[params.to]++;
      require(
        params.to == ECDSA.recover(computeERC20PermitDigest(PERMIT_DOMAIN_SEPARATOR_USDT, params), params.signature),
        "!signature"
      ); //  usdt does not implement ERC20Permit
      {
        (bool success, ) = params.asset.call(
          abi.encodeWithSelector(IERC20.transferFrom.selector, params.to, address(this), params.amount)
        );
        require(success, "!usdt");
      }
      amountToBurn = deductBurnFee(fromUSDT(params.minOut, params.amount), 1);
    } else revert("!supported-asset");
    {
      IGateway(zecGateway).burn(params.destination, amountToBurn);
    }
    {
      tx.origin.transfer(
        Math.min(
          params.gasBefore.sub(gasleft()).add(BURN_GAS_DIFF).add(params.gasDiff).mul(tx.gasprice).add(keeperReward),
          address(this).balance
        )
      );
    }
  }

  function burnApproved(
    address from,
    address asset,
    uint256 amount,
    uint256 minOut,
    bytes memory destination
  ) public payable returns (uint256 amountToBurn) {
    require(asset == renzec || asset == address(0x0), "!approved-module");
    if (asset != address(0x0)) IERC20(asset).transferFrom(msg.sender, address(this), amount);
    amountToBurn = asset == renzec ? amount : fromETHToRenZEC(minOut, msg.value.sub(applyRatio(msg.value, burnFee)));
    IGateway(zecGateway).burn(destination, amountToBurn);
  }

  function fallbackMint(
    address underwriter,
    address to,
    address asset,
    uint256 amount,
    uint256 actualAmount,
    uint256 nonce,
    address module,
    bytes32 nHash,
    bytes memory data,
    bytes memory signature
  ) public {
    LoanParams memory params = LoanParams({
      to: to,
      asset: asset,
      amount: amount,
      nonce: nonce,
      module: module,
      underwriter: underwriter,
      data: data,
      minOut: 1,
      _mintAmount: 0,
      gasDiff: 0
    });
    bytes32 digest = toTypedDataHash(params);
    uint256 _actualAmount = IGateway(zecGateway).mint(
      keccak256(abi.encode(params.to, params.nonce, params.module, params.data)),
      actualAmount,
      nHash,
      signature
    );
    IERC20(asset).safeTransfer(to, _actualAmount);
  }
}

pragma solidity >=0.6.0;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import { RenZECController } from "./RenZECController.sol";

contract RenZECControllerDeployer {
  event Deployed(address indexed controller);

  constructor() {
    emit Deployed(
      address(
        new TransparentUpgradeableProxy(
          address(new RenZECController()),
          address(0xFF727BDFa7608d7Fd12Cd2cDA1e7736ACbfCdB7B),
          abi.encodeWithSelector(
            RenZECController.initialize.selector,
            address(0x5E9B37149b7d7611bD0Eb070194dDA78EB11EfdC),
            address(0x5E9B37149b7d7611bD0Eb070194dDA78EB11EfdC)
          )
        )
      )
    );
    selfdestruct(msg.sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma abicoder v2;

import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { IQuoter } from "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import { UniswapV2Library } from "../libraries/UniswapV2Library.sol";
import { ZeroLib } from "../libraries/ZeroLib.sol";
import { IERC2612Permit } from "../interfaces/IERC2612Permit.sol";
import { IRenCrvArbitrum } from "../interfaces/CurvePools/IRenCrvArbitrum.sol";
import { SplitSignatureLib } from "../libraries/SplitSignatureLib.sol";
import { IBadgerSettPeak } from "../interfaces/IBadgerSettPeak.sol";
import { ICurveFi } from "../interfaces/ICurveFi.sol";
import { IGateway } from "../interfaces/IGateway.sol";
import { IWETH9 } from "@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";
import { ICurveETHUInt256 } from "../interfaces/CurvePools/ICurveETHUInt256.sol";
import { ICurveInt128 } from "../interfaces/CurvePools/ICurveInt128.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IyVault } from "../interfaces/IyVault.sol";
import { ISett } from "../interfaces/ISett.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ECDSA } from "@openzeppelin/contracts/cryptography/ECDSA.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/drafts/EIP712Upgradeable.sol";

contract BadgerBridgeZeroControllerArb is EIP712Upgradeable {
  using SafeERC20 for IERC20;
  using SafeMath for *;
  uint256 public fee;
  address public governance;
  address public strategist;

  address constant btcGateway = 0x05Cadbf3128BcB7f2b89F3dD55E5B0a036a49e20;
  address constant routerv3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
  address constant factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
  address constant usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
  address constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
  address constant wbtc = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
  address constant renbtc = 0xDBf31dF14B66535aF65AaC99C32e9eA844e14501;
  address constant renCrv = 0x3E01dD8a5E1fb3481F0F589056b428Fc308AF0Fb;
  address constant threepool = 0x7f90122BF0700F9E7e1F688fe926940E8839F353;
  address constant tricrypto = 0x960ea3e3C7FB317332d990873d354E18d7645590;
  address constant renCrvLp = 0x3E01dD8a5E1fb3481F0F589056b428Fc308AF0Fb;
  address constant bCrvRen = 0x6dEf55d2e18486B9dDfaA075bc4e4EE0B28c1545;
  address constant settPeak = 0x41671BA1abcbA387b9b2B752c205e22e916BE6e3;
  address constant quoter = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
  address constant ibbtc = 0xc4E15973E6fF2A35cC804c2CF9D2a1b817a8b40F;
  uint24 constant wethWbtcFee = 500;
  uint24 constant usdcWethFee = 500;
  uint256 public governanceFee;
  bytes32 constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
  bytes32 constant LOCK_SLOT = keccak256("upgrade-lock-v2");
  uint256 constant GAS_COST = uint256(48e4);
  uint256 constant IBBTC_GAS_COST = uint256(7e5);
  uint256 constant ETH_RESERVE = uint256(5 ether);
  uint256 internal renbtcForOneETHPrice;
  uint256 internal burnFee;
  uint256 public keeperReward;
  uint256 public constant REPAY_GAS_DIFF = 41510;
  uint256 public constant BURN_GAS_DIFF = 41118;
  mapping(address => uint256) public nonces;
  bytes32 internal PERMIT_DOMAIN_SEPARATOR_WBTC;
  bytes32 internal PERMIT_DOMAIN_SEPARATOR_IBBTC;

  function setStrategist(address _strategist) public {
    require(msg.sender == governance, "!governance");
    strategist = _strategist;
  }

  function setGovernance(address _governance) public {
    require(msg.sender == governance, "!governance");
    governance = _governance;
  }

  function approveUpgrade(bool lock) public {
    bool isLocked;
    bytes32 lock_slot = LOCK_SLOT;

    assembly {
      isLocked := sload(lock_slot)
    }
    require(!isLocked, "cannot run upgrade function");
    assembly {
      sstore(lock_slot, lock)
    }
  }

  function computeCalldataGasDiff() internal pure returns (uint256 diff) {
    if (true) return 0; // TODO: implement exact gas metering
    // EVM charges less for zero bytes, we must compute the offset for refund
    // TODO make this efficient
    uint256 sz;
    assembly {
      sz := calldatasize()
    }
    diff = sz.mul(uint256(68));
    bytes memory slice;
    for (uint256 i = 0; i < sz; i += 0x20) {
      uint256 word;
      assembly {
        word := calldataload(i)
      }
      for (uint256 i = 0; i < 256 && ((uint256(~0) << i) & word) != 0; i += 8) {
        if ((word >> i) & 0xff != 0) diff -= 64;
      }
    }
  }

  function getChainId() internal pure returns (uint256 result) {
    assembly {
      result := chainid()
    }
  }

  function setParameters(
    uint256 _governanceFee,
    uint256 _fee,
    uint256 _burnFee,
    uint256 _keeperReward
  ) public {
    require(governance == msg.sender, "!governance");
    governanceFee = _governanceFee;
    fee = _fee;
    burnFee = _burnFee;
    keeperReward = _keeperReward;
  }

  function initialize(address _governance, address _strategist) public initializer {
    fee = uint256(25e14);
    burnFee = uint256(4e15);
    governanceFee = uint256(5e17);
    governance = _governance;
    strategist = _strategist;
    keeperReward = uint256(1 ether).div(1000);
    //IERC20(renbtc).safeApprove(btcGateway, ~uint256(0) >> 2);
    IERC20(renbtc).safeApprove(renCrv, ~uint256(0) >> 2);
    IERC20(wbtc).safeApprove(renCrv, ~uint256(0) >> 2);
    IERC20(wbtc).safeApprove(tricrypto, ~uint256(0) >> 2);
    IERC20(renCrvLp).safeApprove(bCrvRen, ~uint256(0) >> 2);
    IERC20(wbtc).safeApprove(routerv3, ~uint256(0) >> 2);
    IERC20(usdc).safeApprove(routerv3, ~uint256(0) >> 2);
    //IERC20(bCrvRen).safeApprove(settPeak, ~uint256(0) >> 2);
    PERMIT_DOMAIN_SEPARATOR_WBTC = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("WBTC"),
        keccak256("1"),
        getChainId(),
        wbtc
      )
    );
    PERMIT_DOMAIN_SEPARATOR_IBBTC = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("ibBTC"),
        keccak256("1"),
        getChainId(),
        ibbtc
      )
    );
  }

  function applyRatio(uint256 v, uint256 n) internal pure returns (uint256 result) {
    result = v.mul(n).div(uint256(1 ether));
  }

  function toWBTC(uint256 amount) internal returns (uint256 amountOut) {
    uint256 amountStart = IERC20(wbtc).balanceOf(address(this));
    IRenCrvArbitrum(renCrv).exchange(1, 0, amount, 1, address(this));
    amountOut = IERC20(wbtc).balanceOf(address(this)).sub(amountStart);
  }

  function toIBBTC(uint256 amountIn) internal returns (uint256 amountOut) {
    uint256[2] memory amounts;
    amounts[0] = amountIn;
    (bool success, ) = renCrv.call(abi.encodeWithSelector(ICurveFi.add_liquidity.selector, amounts, 0));
    require(success, "!curve");
    ISett(bCrvRen).deposit(IERC20(renCrvLp).balanceOf(address(this)));
    amountOut = IBadgerSettPeak(settPeak).mint(0, IERC20(bCrvRen).balanceOf(address(this)), new bytes32[](0));
  }

  function toUSDC(
    uint256 minOut,
    uint256 amountIn,
    address out
  ) internal returns (uint256 amountOut) {
    uint256 wbtcAmountIn = toWBTC(amountIn);
    bytes memory path = abi.encodePacked(wbtc, wethWbtcFee, weth, usdcWethFee, usdc);
    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      recipient: out,
      deadline: block.timestamp + 1,
      amountIn: wbtcAmountIn,
      amountOutMinimum: minOut,
      path: path
    });
    amountOut = ISwapRouter(routerv3).exactInput(params);
  }

  function quote() internal {
    bytes memory path = abi.encodePacked(wbtc, uint24(500), weth);
    uint256 wbtcForEthPrice = IQuoter(quoter).quoteExactInput(path, 1 ether);
    renbtcForOneETHPrice = ICurveInt128(renCrv).get_dy(1, 0, wbtcForEthPrice);
  }

  function renBTCtoETH(
    uint256 minOut,
    uint256 amountIn,
    address out
  ) internal returns (uint256 amountOut) {
    uint256 wbtcAmountOut = toWBTC(amountIn);
    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
      tokenIn: wbtc,
      tokenOut: weth,
      fee: wethWbtcFee,
      recipient: address(this),
      deadline: block.timestamp + 1,
      amountIn: wbtcAmountOut,
      amountOutMinimum: minOut,
      sqrtPriceLimitX96: 0
    });
    amountOut = ISwapRouter(routerv3).exactInputSingle(params);
    address payable to = address(uint160(out));
    IWETH9(weth).withdraw(amountOut);
    to.transfer(amountOut);
  }

  function fromIBBTC(uint256 amountIn) internal returns (uint256 amountOut) {
    uint256 amountStart = IERC20(renbtc).balanceOf(address(this));
    IBadgerSettPeak(settPeak).redeem(0, amountIn);
    ISett(bCrvRen).withdraw(IERC20(bCrvRen).balanceOf(address(this)));
    (bool success, ) = renCrv.call(
      abi.encodeWithSelector(
        ICurveFi.remove_liquidity_one_coin.selector,
        IERC20(renCrvLp).balanceOf(address(this)),
        0,
        0
      )
    );
    require(success, "!curve");
    amountOut = IERC20(renbtc).balanceOf(address(this)).sub(amountStart);
  }

  function fromUSDC(uint256 minOut, uint256 amountIn) internal returns (uint256 amountOut) {
    bytes memory path = abi.encodePacked(usdc, usdcWethFee, weth, wethWbtcFee, wbtc);
    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      recipient: address(this),
      deadline: block.timestamp + 1,
      amountIn: amountIn,
      amountOutMinimum: minOut,
      path: path
    });
    amountOut = ISwapRouter(routerv3).exactInput(params);
    amountOut = toRenBTC(amountOut);
  }

  function toRenBTC(uint256 amountIn) internal returns (uint256 amountOut) {
    uint256 balanceStart = IERC20(renbtc).balanceOf(address(this));
    IRenCrvArbitrum(renCrv).exchange(0, 1, amountIn, 1, address(this));
    amountOut = IERC20(renbtc).balanceOf(address(this)).sub(balanceStart);
  }

  function fromETHToRenBTC(uint256 minOut, uint256 amountIn) internal returns (uint256 amountOut) {
    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
      tokenIn: weth,
      tokenOut: wbtc,
      fee: wethWbtcFee,
      recipient: address(this),
      deadline: block.timestamp + 1,
      amountIn: amountIn,
      amountOutMinimum: minOut,
      sqrtPriceLimitX96: 0
    });
    amountOut = ISwapRouter(routerv3).exactInputSingle{ value: amountIn }(params);
    return toRenBTC(amountOut);
  }

  function toETH() internal returns (uint256 amountOut) {
    uint256 wbtcStart = IERC20(wbtc).balanceOf(address(this));

    uint256 amountStart = address(this).balance;
    (bool success, ) = tricrypto.call(
      abi.encodeWithSelector(ICurveETHUInt256.exchange.selector, 1, 2, wbtcStart, 0, true)
    );
    amountOut = address(this).balance.sub(amountStart);
  }

  receive() external payable {
    // no-op
  }

  function earn() public {
    quote();
    toWBTC(IERC20(renbtc).balanceOf(address(this)));
    toETH();
    uint256 balance = address(this).balance;
    if (balance > ETH_RESERVE) {
      uint256 output = balance - ETH_RESERVE;
      uint256 toGovernance = applyRatio(output, governanceFee);
      bool success;
      address payable governancePayable = address(uint160(governance));
      (success, ) = governancePayable.call{ value: toGovernance, gas: gasleft() }("");
      require(success, "error sending to governance");
      address payable strategistPayable = address(uint160(strategist));
      (success, ) = strategistPayable.call{ value: output.sub(toGovernance), gas: gasleft() }("");
      require(success, "error sending to strategist");
    }
  }

  function computeRenBTCGasFee(uint256 gasCost, uint256 gasPrice) internal view returns (uint256 result) {
    result = gasCost.mul(tx.gasprice).mul(renbtcForOneETHPrice).div(uint256(1 ether));
  }

  function deductMintFee(uint256 amountIn, uint256 multiplier) internal view returns (uint256 amount) {
    amount = amountIn.sub(applyFee(amountIn, fee, multiplier));
  }

  function deductIBBTCMintFee(uint256 amountIn, uint256 multiplier) internal view returns (uint256 amount) {
    amount = amountIn.sub(applyIBBTCFee(amountIn, fee, multiplier));
  }

  function deductBurnFee(uint256 amountIn, uint256 multiplier) internal view returns (uint256 amount) {
    amount = amountIn.sub(applyFee(amountIn, burnFee, multiplier));
  }

  function deductIBBTCBurnFee(uint256 amountIn, uint256 multiplier) internal view returns (uint256 amount) {
    amount = amountIn.sub(applyIBBTCFee(amountIn, burnFee, multiplier));
  }

  function applyFee(
    uint256 amountIn,
    uint256 _fee,
    uint256 multiplier
  ) internal view returns (uint256 amount) {
    amount = computeRenBTCGasFee(GAS_COST.add(keeperReward.div(tx.gasprice)), tx.gasprice).add(
      applyRatio(amountIn, _fee)
    );
  }

  function applyIBBTCFee(
    uint256 amountIn,
    uint256 _fee,
    uint256 multiplier
  ) internal view returns (uint256 amount) {
    amount = computeRenBTCGasFee(IBBTC_GAS_COST.add(keeperReward.div(tx.gasprice)), tx.gasprice).add(
      applyRatio(amountIn, _fee)
    );
  }

  struct LoanParams {
    address to;
    address asset;
    uint256 nonce;
    uint256 amount;
    address module;
    address underwriter;
    bytes data;
    uint256 minOut;
    uint256 _mintAmount;
    uint256 gasDiff;
  }

  function toTypedDataHash(LoanParams memory params) internal view returns (bytes32 result) {
    bytes32 digest = _hashTypedDataV4(
      keccak256(
        abi.encode(
          keccak256(
            "TransferRequest(address asset,uint256 amount,address underwriter,address module,uint256 nonce,bytes data)"
          ),
          params.asset,
          params.amount,
          params.underwriter,
          params.module,
          params.nonce,
          keccak256(params.data)
        )
      )
    );
    return digest;
  }

  function repay(
    address underwriter,
    address to,
    address asset,
    uint256 amount,
    uint256 actualAmount,
    uint256 nonce,
    address module,
    bytes32 nHash,
    bytes memory data,
    bytes memory signature
  ) public returns (uint256 amountOut) {
    require(msg.data.length <= 516, "too much calldata");
    uint256 _gasBefore = gasleft();
    LoanParams memory params;
    {
      require(
        module == wbtc || module == usdc || module == ibbtc || module == renbtc || module == address(0x0),
        "!approved-module"
      );
      params = LoanParams({
        to: to,
        asset: asset,
        amount: amount,
        nonce: nonce,
        module: module,
        underwriter: underwriter,
        data: data,
        minOut: 1,
        _mintAmount: 0,
        gasDiff: computeCalldataGasDiff()
      });
      if (data.length > 0) (params.minOut) = abi.decode(data, (uint256));
    }
    bytes32 digest = toTypedDataHash(params);

    params._mintAmount = IGateway(btcGateway).mint(
      keccak256(abi.encode(params.to, params.nonce, params.module, params.data)),
      actualAmount,
      nHash,
      signature
    );
    {
      amountOut = module == wbtc ? toWBTC(deductMintFee(params._mintAmount, 1)) : module == address(0x0)
        ? renBTCtoETH(params.minOut, deductMintFee(params._mintAmount, 1), to)
        : module == usdc
        ? toUSDC(params.minOut, deductMintFee(params._mintAmount, 1), to)
        : module == ibbtc
        ? toIBBTC(deductIBBTCMintFee(params._mintAmount, 3))
        : deductMintFee(params._mintAmount, 1);
    }
    {
      if (module != usdc && module != address(0x0)) IERC20(module).safeTransfer(to, amountOut);
    }
    {
      tx.origin.transfer(
        Math.min(
          _gasBefore.sub(gasleft()).add(REPAY_GAS_DIFF).add(params.gasDiff).mul(tx.gasprice).add(keeperReward),
          address(this).balance
        )
      );
    }
  }

  function computeBurnNonce(BurnLocals memory params) internal view returns (uint256 result) {
    result = uint256(
      keccak256(
        abi.encodePacked(params.asset, params.amount, params.deadline, params.nonce, params.data, params.destination)
      )
    );
    while (result < block.timestamp) {
      // negligible probability of this
      result = uint256(keccak256(abi.encodePacked(result)));
    }
  }

  function computeERC20PermitDigest(bytes32 domainSeparator, BurnLocals memory params)
    internal
    view
    returns (bytes32 result)
  {
    result = keccak256(
      abi.encodePacked(
        "\x19\x01",
        domainSeparator,
        keccak256(abi.encode(PERMIT_TYPEHASH, params.to, address(this), params.nonce, computeBurnNonce(params), true))
      )
    );
  }

  struct BurnLocals {
    address to;
    address asset;
    uint256 amount;
    uint256 deadline;
    uint256 nonce;
    bytes data;
    uint256 minOut;
    uint256 burnNonce;
    uint256 gasBefore;
    uint256 gasDiff;
    uint8 v;
    bytes32 r;
    bytes32 s;
    bytes destination;
    bytes signature;
  }

  function burn(
    address to,
    address asset,
    uint256 amount,
    uint256 deadline,
    bytes memory data,
    bytes memory destination,
    bytes memory signature
  ) public returns (uint256 amountToBurn) {
    require(msg.data.length <= 580, "too much calldata");
    BurnLocals memory params = BurnLocals({
      to: to,
      asset: asset,
      amount: amount,
      deadline: deadline,
      data: data,
      nonce: 0,
      burnNonce: 0,
      v: uint8(0),
      r: bytes32(0),
      s: bytes32(0),
      destination: destination,
      signature: signature,
      gasBefore: gasleft(),
      minOut: 1,
      gasDiff: 0
    });
    {
      params.gasDiff = computeCalldataGasDiff();
      if (params.data.length > 0) (params.minOut) = abi.decode(params.data, (uint256));
    }
    require(block.timestamp < params.deadline, "!deadline");

    if (params.asset == wbtc) {
      params.nonce = nonces[to];
      nonces[params.to]++;
      require(
        params.to == ECDSA.recover(computeERC20PermitDigest(PERMIT_DOMAIN_SEPARATOR_WBTC, params), params.signature),
        "!signature"
      ); //  wbtc does not implement ERC20Permit
      {
        IERC20(params.asset).transferFrom(params.to, address(this), params.amount);
        amountToBurn = toRenBTC(deductBurnFee(params.amount, 1));
      }
    } else if (asset == ibbtc) {
      params.nonce = nonces[to];
      nonces[to]++;
      require(
        params.to == ECDSA.recover(computeERC20PermitDigest(PERMIT_DOMAIN_SEPARATOR_IBBTC, params), params.signature),
        "!signature"
      ); //  wbtc ibbtc do not implement ERC20Permit
      {
        IERC20(params.asset).transferFrom(params.to, address(this), params.amount);
        amountToBurn = deductIBBTCBurnFee(fromIBBTC(params.amount), 3);
      }
    } else if (params.asset == renbtc) {
      {
        params.nonce = IERC2612Permit(params.asset).nonces(params.to);
        params.burnNonce = computeBurnNonce(params);
      }
      {
        (params.v, params.r, params.s) = SplitSignatureLib.splitSignature(params.signature);
        IERC2612Permit(params.asset).permit(
          params.to,
          address(this),
          params.nonce,
          params.burnNonce,
          true,
          params.v,
          params.r,
          params.s
        );
      }
      {
        IERC20(params.asset).transferFrom(params.to, address(this), params.amount);
      }
      amountToBurn = deductBurnFee(params.amount, 1);
    } else if (params.asset == usdc) {
      {
        params.nonce = IERC2612Permit(params.asset).nonces(params.to);
        params.burnNonce = computeBurnNonce(params);
      }
      {
        (params.v, params.r, params.s) = SplitSignatureLib.splitSignature(params.signature);
        IERC2612Permit(params.asset).permit(
          params.to,
          address(this),
          params.amount,
          params.burnNonce,
          params.v,
          params.r,
          params.s
        );
      }
      {
        IERC20(params.asset).transferFrom(params.to, address(this), params.amount);
      }
      amountToBurn = deductBurnFee(fromUSDC(params.minOut, params.amount), 1);
    } else revert("!supported-asset");
    {
      IGateway(btcGateway).burn(params.destination, amountToBurn);
    }
    {
      tx.origin.transfer(
        Math.min(
          params.gasBefore.sub(gasleft()).add(BURN_GAS_DIFF).add(params.gasDiff).mul(tx.gasprice).add(keeperReward),
          address(this).balance
        )
      );
    }
  }

  function burnETH(uint256 minOut, bytes memory destination) public payable returns (uint256 amountToBurn) {
    amountToBurn = fromETHToRenBTC(minOut, msg.value.sub(applyRatio(msg.value, burnFee)));
    IGateway(btcGateway).burn(destination, amountToBurn);
  }

  function burnApproved(
    address from,
    address asset,
    uint256 amount,
    uint256 minOut,
    bytes memory destination
  ) public payable returns (uint256 amountToBurn) {
    require(asset == wbtc || asset == usdc || asset == renbtc || asset == address(0x0), "!approved-module");
    if (asset != address(0x0)) IERC20(asset).transferFrom(msg.sender, address(this), amount);
    amountToBurn = asset == wbtc ? toRenBTC(amount.sub(applyRatio(amount, burnFee))) : asset == usdc
      ? fromUSDC(minOut, amount.sub(applyRatio(amount, burnFee)))
      : asset == renbtc
      ? amount
      : fromETHToRenBTC(minOut, msg.value.sub(applyRatio(msg.value, burnFee)));
    IGateway(btcGateway).burn(destination, amountToBurn);
  }

  function fallbackMint(
    address underwriter,
    address to,
    address asset,
    uint256 amount,
    uint256 actualAmount,
    uint256 nonce,
    address module,
    bytes32 nHash,
    bytes memory data,
    bytes memory signature
  ) public {
    LoanParams memory params = LoanParams({
      to: to,
      asset: asset,
      amount: amount,
      nonce: nonce,
      module: module,
      underwriter: underwriter,
      data: data,
      minOut: 1,
      _mintAmount: 0,
      gasDiff: 0
    });
    bytes32 digest = toTypedDataHash(params);
    uint256 _actualAmount = IGateway(btcGateway).mint(
      keccak256(abi.encode(params.to, params.nonce, params.module, params.data)),
      actualAmount,
      nHash,
      signature
    );
    IERC20(asset).safeTransfer(to, _actualAmount);
  }
}

pragma solidity >=0.6.0 <0.8.0;
import { PolygonConvertLib } from "./PolygonConvertLib.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { SafeMath } from "oz410/math/SafeMath.sol";
import { IERC20 } from "oz410/token/ERC20/IERC20.sol";
import { SafeERC20 } from "oz410/token/ERC20/SafeERC20.sol";
import { IZeroModule } from "../interfaces/IZeroModule.sol";
import { IController } from "../interfaces/IController.sol";
import { IConverter } from "../interfaces/IConverter.sol";
import { ICurveUInt256 } from "../interfaces/CurvePools/ICurveUInt256.sol";
import { IController } from "../interfaces/IController.sol";
import { ICurveUnderlyingUInt256 } from "../interfaces/CurvePools/ICurveUnderlyingUInt256.sol";
import { ICurveInt128 } from "../interfaces/CurvePools/ICurveInt128.sol";
import { IRenCrvPolygon } from "../interfaces/CurvePools/IRenCrvPolygon.sol";

contract PolygonConvert is IZeroModule {
  using SafeERC20 for *;
  using SafeMath for *;
  mapping(uint256 => PolygonConvertLib.ConvertRecord) public outstanding;
  address public immutable controller;
  address public immutable governance;
  uint256 public blockTimeout;
  address public constant router = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
  address public constant wMatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
  address public constant weth = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
  address public constant wbtc = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
  address public constant override want = 0xDBf31dF14B66535aF65AaC99C32e9eA844e14501;
  address public constant renCrvPolygon = 0xC2d95EEF97Ec6C17551d45e77B590dc1F9117C67;
  address public constant tricryptoPolygon = 0x92215849c439E1f8612b6646060B4E3E5ef822cC;

  modifier onlyController() {
    require(msg.sender == controller, "!controller");
    _;
  }

  constructor(address _controller) {
    controller = _controller;
    governance = IController(_controller).governance();
    IERC20(want).safeApprove(router, ~uint256(0) >> 2);
  }

  function setBlockTimeout(uint256 _ct) public {
    require(msg.sender == governance, "!governance");
    blockTimeout = _ct;
  }

  function isActive(PolygonConvertLib.ConvertRecord storage record) internal view returns (bool) {
    return record.qty != 0 || record.qtyETH != 0;
  }

  function defaultLoan(uint256 _nonce) public {
    require(block.number >= outstanding[_nonce].when + blockTimeout);
    require(isActive(outstanding[_nonce]), "!outstanding");
    uint256 _amountSwappedBack = swapTokensBack(outstanding[_nonce]);
    IERC20(want).safeTransfer(controller, _amountSwappedBack);
    delete outstanding[_nonce];
  }

  function receiveLoan(
    address _to,
    address _asset,
    uint256 _actual,
    uint256 _nonce,
    bytes memory _data
  ) public override onlyController {
    uint256 ratio = abi.decode(_data, (uint256));
    (uint256 amountSwappedETH, uint256 amountSwappedBTC) = swapTokens(_actual, ratio);
    outstanding[_nonce] = PolygonConvertLib.ConvertRecord({
      qty: amountSwappedBTC,
      when: uint64(block.timestamp),
      qtyETH: amountSwappedETH
    });
  }

  function swapTokens(uint256 _amountIn, uint256 _ratio)
    internal
    returns (uint256 amountSwappedETH, uint256 amountSwappedBTC)
  {
    uint256 amountToETH = _ratio.mul(_amountIn).div(uint256(1 ether));
    if (amountToETH != 0) {
      address[] memory path = new address[](2);
      path[0] = want;
      path[1] = wMatic;
      uint256[] memory toMaticResult = IUniswapV2Router02(router).swapExactTokensForETH(
        amountToETH,
        1,
        path,
        address(this),
        block.timestamp + 1
      );
      amountSwappedETH = toMaticResult[1];
      amountSwappedBTC = _amountIn.sub(amountToETH);
    } else {
      amountSwappedBTC = _amountIn;
    }
  }

  receive() external payable {
    //
  }

  function swapTokensBack(PolygonConvertLib.ConvertRecord storage record) internal returns (uint256 amountReturned) {
    uint256 _amountStart = IERC20(wbtc).balanceOf(address(this));
    (bool success, ) = tricryptoPolygon.call{ value: record.qtyETH }(
      abi.encodeWithSelector(ICurveUInt256.exchange.selector, 2, 1, record.qtyETH, 0)
    );
    require(success, "!exchange");
    uint256 wbtcOut = IERC20(wbtc).balanceOf(address(this));
    amountReturned = IRenCrvPolygon(renCrvPolygon).exchange(0, 1, wbtcOut, 0).add(record.qty);
  }

  function repayLoan(
    address _to,
    address _asset,
    uint256 _actualAmount,
    uint256 _nonce,
    bytes memory _data
  ) public override onlyController {
    require(outstanding[_nonce].qty != 0 || outstanding[_nonce].qtyETH != 0, "!outstanding");
    IERC20(want).safeTransfer(_to, outstanding[_nonce].qty);
    address payable to = address(uint160(_to));
    to.transfer(outstanding[_nonce].qtyETH);
    delete outstanding[_nonce];
  }

  function computeReserveRequirement(uint256 _in) external view override returns (uint256) {
    return _in.mul(uint256(1e17)).div(uint256(1 ether));
  }
}

// SPDX-License-Identifier: MIT

library PolygonConvertLib {
  struct ConvertRecord {
    uint64 when;
    uint256 qtyETH;
    uint256 qty;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

interface ICurveUnderlyingUInt256 {
  function get_dy_underlying(
    uint256,
    uint256,
    uint256
  ) external view returns (uint256);

  function exchange_underlying(
    uint256,
    uint256,
    uint256,
    uint256
  ) external returns (uint256);

  function underlying_coins(uint256) external view returns (address);
}

interface IRenCrvPolygon {
  function exchange(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external returns (uint256);
}

pragma solidity >=0.6.0 <0.8.0;

import { ICurveInt128 } from "../interfaces/CurvePools/ICurveInt128.sol";
import { ICurveUInt128 } from "../interfaces/CurvePools/ICurveUInt128.sol";

import { ICurveInt256 } from "../interfaces/CurvePools/ICurveInt256.sol";

import { ICurveUInt256 } from "../interfaces/CurvePools/ICurveUInt256.sol";
import { ICurveETHUInt256 } from "../interfaces/CurvePools/ICurveETHUInt256.sol";
import { ICurveUnderlyingUInt128 } from "../interfaces/CurvePools/ICurveUnderlyingUInt128.sol";
import { ICurveUnderlyingUInt256 } from "../interfaces/CurvePools/ICurveUnderlyingUInt256.sol";
import { ICurveUnderlyingInt128 } from "../interfaces/CurvePools/ICurveUnderlyingInt128.sol";
import { ICurveUnderlyingInt256 } from "../interfaces/CurvePools/ICurveUnderlyingInt256.sol";
import { RevertCaptureLib } from "./RevertCaptureLib.sol";

library CurveLib {
  address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  struct ICurve {
    address pool;
    bool underlying;
    bytes4 coinsSelector;
    bytes4 exchangeSelector;
    bytes4 getDySelector;
    bytes4 coinsUnderlyingSelector;
  }

  function hasWETH(address pool, bytes4 coinsSelector) internal returns (bool) {
    for (uint256 i = 0; ; i++) {
      (bool success, bytes memory result) = pool.staticcall{ gas: 2e5 }(abi.encodePacked(coinsSelector, i));
      if (!success || result.length == 0) return false;
      address coin = abi.decode(result, (address));
      if (coin == weth) return true;
    }
  }

  function coins(ICurve memory curve, uint256 i) internal view returns (address result) {
    (bool success, bytes memory returnData) = curve.pool.staticcall(abi.encodeWithSelector(curve.coinsSelector, i));
    require(success, "!coins");
    (result) = abi.decode(returnData, (address));
  }

  function underlying_coins(ICurve memory curve, uint256 i) internal view returns (address result) {
    (bool success, bytes memory returnData) = curve.pool.staticcall(
      abi.encodeWithSelector(curve.coinsUnderlyingSelector, i)
    );
    require(success, "!underlying_coins");
    (result) = abi.decode(returnData, (address));
  }

  function get_dy(
    ICurve memory curve,
    uint256 i,
    uint256 j,
    uint256 amount
  ) internal view returns (uint256 result) {
    (bool success, bytes memory returnData) = curve.pool.staticcall(
      abi.encodeWithSelector(curve.getDySelector, i, j, amount)
    );
    require(success, "!get_dy");
    (result) = abi.decode(returnData, (uint256));
  }

  function exchange(
    ICurve memory curve,
    uint256 i,
    uint256 j,
    uint256 dx,
    uint256 min_dy
  ) internal {
    (bool success, bytes memory returnData) = curve.pool.call{ gas: gasleft() }(
      abi.encodeWithSelector(curve.exchangeSelector, i, j, dx, min_dy)
    );
    if (!success) revert(RevertCaptureLib.decodeError(returnData));
  }

  function toDynamic(bytes4[4] memory ary) internal pure returns (bytes4[] memory result) {
    result = new bytes4[](ary.length);
    for (uint256 i = 0; i < ary.length; i++) {
      result[i] = ary[i];
    }
  }

  function toDynamic(bytes4[5] memory ary) internal pure returns (bytes4[] memory result) {
    result = new bytes4[](ary.length);
    for (uint256 i = 0; i < ary.length; i++) {
      result[i] = ary[i];
    }
  }

  function testSignatures(
    address target,
    bytes4[] memory signatures,
    bytes memory callData
  ) internal returns (bytes4 result) {
    for (uint256 i = 0; i < signatures.length; i++) {
      (, bytes memory returnData) = target.staticcall(abi.encodePacked(signatures[i], callData));
      if (returnData.length != 0) return signatures[i];
    }
    return bytes4(0x0);
  }

  function testExchangeSignatures(
    address target,
    bytes4[] memory signatures,
    bytes memory callData
  ) internal returns (bytes4 result) {
    for (uint256 i = 0; i < signatures.length; i++) {
      uint256 gasStart = gasleft();
      (bool success, ) = target.call{ gas: 2e5 }(abi.encodePacked(signatures[i], callData));
      uint256 gasUsed = gasStart - gasleft();
      if (gasUsed > 10000) return signatures[i];
    }
    return bytes4(0x0);
  }

  function toBytes(bytes4 sel) internal pure returns (bytes memory result) {
    result = new bytes(4);
    bytes32 selWord = bytes32(sel);
    assembly {
      mstore(add(0x20, result), selWord)
    }
  }

  function duckPool(address pool, bool underlying) internal returns (ICurve memory result) {
    result.pool = pool;
    result.underlying = underlying;
    result.coinsSelector = result.underlying
      ? testSignatures(
        pool,
        toDynamic(
          [
            ICurveUnderlyingInt128.underlying_coins.selector,
            ICurveUnderlyingInt256.underlying_coins.selector,
            ICurveUnderlyingUInt128.underlying_coins.selector,
            ICurveUnderlyingUInt256.underlying_coins.selector
          ]
        ),
        abi.encode(0)
      )
      : testSignatures(
        pool,
        toDynamic(
          [
            ICurveInt128.coins.selector,
            ICurveInt256.coins.selector,
            ICurveUInt128.coins.selector,
            ICurveUInt256.coins.selector
          ]
        ),
        abi.encode(0)
      );
    result.exchangeSelector = result.underlying
      ? testExchangeSignatures(
        pool,
        toDynamic(
          [
            ICurveUnderlyingUInt256.exchange_underlying.selector,
            ICurveUnderlyingInt128.exchange_underlying.selector,
            ICurveUnderlyingInt256.exchange_underlying.selector,
            ICurveUnderlyingUInt128.exchange_underlying.selector
          ]
        ),
        abi.encode(0, 0, 1000000000, type(uint256).max / 0x10, false)
      )
      : testExchangeSignatures(
        pool,
        toDynamic(
          [
            ICurveUInt256.exchange.selector,
            ICurveInt128.exchange.selector,
            ICurveInt256.exchange.selector,
            ICurveUInt128.exchange.selector,
            ICurveETHUInt256.exchange.selector
          ]
        ),
        abi.encode(0, 0, 1000000000, type(uint256).max / 0x10, false)
      );
    if (result.exchangeSelector == bytes4(0x0)) result.exchangeSelector = ICurveUInt256.exchange.selector; //hasWETH(pool, result.coinsSelector) ? ICurveETHUInt256.exchange.selector : ICurveUInt256.exchange.selector;
    result.getDySelector = testSignatures(
      pool,
      toDynamic(
        [
          ICurveInt128.get_dy.selector,
          ICurveInt256.get_dy.selector,
          ICurveUInt128.get_dy.selector,
          ICurveUInt256.get_dy.selector
        ]
      ),
      abi.encode(0, 1, 1000000000)
    );
  }

  function fromSelectors(
    address pool,
    bool underlying,
    bytes4 coinsSelector,
    bytes4 coinsUnderlyingSelector,
    bytes4 exchangeSelector,
    bytes4 getDySelector
  ) internal pure returns (ICurve memory result) {
    result.pool = pool;
    result.coinsSelector = coinsSelector;
    result.coinsUnderlyingSelector = coinsUnderlyingSelector;
    result.exchangeSelector = exchangeSelector;
    result.getDySelector = getDySelector;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

interface ICurveUInt128 {
  function get_dy(
    uint128,
    uint128,
    uint256
  ) external view returns (uint256);

  function exchange(
    uint128,
    uint128,
    uint256,
    uint256
  ) external returns (uint256);

  function coins(uint128) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

interface ICurveInt256 {
  function get_dy(
    int256,
    int256,
    uint256
  ) external view returns (uint256);

  function exchange(
    int256,
    int256,
    uint256,
    uint256
  ) external returns (uint256);

  function coins(int256) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

interface ICurveUnderlyingUInt128 {
  function get_dy_underlying(
    uint128,
    uint128,
    uint256
  ) external view returns (uint256);

  function exchange_underlying(
    uint128,
    uint128,
    uint256,
    uint256
  ) external returns (uint256);

  function underlying_coins(uint128) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

interface ICurveUnderlyingInt128 {
  function get_dy_underlying(
    int128,
    int128,
    uint256
  ) external view returns (uint256);

  function exchange_underlying(
    int128,
    int128,
    uint256,
    uint256
  ) external returns (uint256);

  function underlying_coins(int128) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

interface ICurveUnderlyingInt256 {
  function get_dy_underlying(
    int256,
    int256,
    uint256
  ) external view returns (uint256);

  function exchange_underlying(
    int256,
    int256,
    uint256,
    uint256
  ) external returns (uint256);

  function underlying_coins(int256) external view returns (address);
}

pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import { SliceLib } from "./SliceLib.sol";

library RevertCaptureLib {
  using SliceLib for *;
  uint32 constant REVERT_WITH_REASON_MAGIC = 0x08c379a0; // keccak256("Error(string)")

  function decodeString(bytes memory input) internal pure returns (string memory retval) {
    (retval) = abi.decode(input, (string));
  }

  function decodeError(bytes memory buffer) internal pure returns (string memory) {
    if (buffer.length == 0) return "captured empty revert buffer";
    if (uint32(uint256(bytes32(buffer.toSlice(0, 4).asWord()))) != REVERT_WITH_REASON_MAGIC)
      return "captured a revert error, but it doesn't conform to the standard";
    bytes memory revertMessageEncoded = buffer.toSlice(4).copy();
    if (revertMessageEncoded.length == 0) return "captured empty revert message";
    string memory revertMessage = decodeString(revertMessageEncoded);
    return revertMessage;
  }
}

pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import { MemcpyLib } from "./MemcpyLib.sol";

library SliceLib {
  struct Slice {
    uint256 data;
    uint256 length;
    uint256 offset;
  }

  function toPtr(bytes memory input, uint256 offset) internal pure returns (uint256 data) {
    assembly {
      data := add(input, add(offset, 0x20))
    }
  }

  function toSlice(
    bytes memory input,
    uint256 offset,
    uint256 length
  ) internal pure returns (Slice memory retval) {
    retval.data = toPtr(input, offset);
    retval.length = length;
    retval.offset = offset;
  }

  function toSlice(bytes memory input) internal pure returns (Slice memory) {
    return toSlice(input, 0);
  }

  function toSlice(bytes memory input, uint256 offset) internal pure returns (Slice memory) {
    if (input.length < offset) offset = input.length;
    return toSlice(input, offset, input.length - offset);
  }

  function toSlice(
    Slice memory input,
    uint256 offset,
    uint256 length
  ) internal pure returns (Slice memory) {
    return Slice({ data: input.data + offset, offset: input.offset + offset, length: length });
  }

  function toSlice(Slice memory input, uint256 offset) internal pure returns (Slice memory) {
    return toSlice(input, offset, input.length - offset);
  }

  function toSlice(Slice memory input) internal pure returns (Slice memory) {
    return toSlice(input, 0);
  }

  function maskLastByteOfWordAt(uint256 data) internal pure returns (uint8 lastByte) {
    assembly {
      lastByte := and(mload(data), 0xff)
    }
  }

  function get(Slice memory slice, uint256 index) internal pure returns (bytes1 result) {
    return bytes1(maskLastByteOfWordAt(slice.data - 0x1f + index));
  }

  function setByteAt(uint256 ptr, uint8 value) internal pure {
    assembly {
      mstore8(ptr, value)
    }
  }

  function set(
    Slice memory slice,
    uint256 index,
    uint8 value
  ) internal pure {
    setByteAt(slice.data + index, value);
  }

  function wordAt(uint256 ptr, uint256 length) internal pure returns (bytes32 word) {
    assembly {
      let mask := sub(shl(mul(length, 0x8), 0x1), 0x1)
      word := and(mload(sub(ptr, sub(0x20, length))), mask)
    }
  }

  function asWord(Slice memory slice) internal pure returns (bytes32 word) {
    uint256 data = slice.data;
    uint256 length = slice.length;
    return wordAt(data, length);
  }

  function toDataStart(bytes memory input) internal pure returns (bytes32 start) {
    assembly {
      start := add(input, 0x20)
    }
  }

  function copy(Slice memory slice) internal pure returns (bytes memory retval) {
    uint256 length = slice.length;
    retval = new bytes(length);
    bytes32 src = bytes32(slice.data);
    bytes32 dest = toDataStart(retval);
    MemcpyLib.memcpy(dest, src, length);
  }

  function keccakAt(uint256 data, uint256 length) internal pure returns (bytes32 result) {
    assembly {
      result := keccak256(data, length)
    }
  }

  function toKeccak(Slice memory slice) internal pure returns (bytes32 result) {
    return keccakAt(slice.data, slice.length);
  }
}

pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library MemcpyLib {
  function memcpy(
    bytes32 dest,
    bytes32 src,
    uint256 len
  ) internal pure {
    assembly {
      for {

      } iszero(lt(len, 0x20)) {
        len := sub(len, 0x20)
      } {
        mstore(dest, mload(src))
        dest := add(dest, 0x20)
        src := add(src, 0x20)
      }
      let mask := sub(shl(mul(sub(32, len), 8), 1), 1)
      mstore(dest, or(and(mload(src), not(mask)), and(mload(dest), mask)))
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;
import { ICurvePool } from "../interfaces/ICurvePool.sol";
import { IERC20 } from "oz410/token/ERC20/IERC20.sol";
import { ZeroCurveWrapper } from "./ZeroCurveWrapper.sol";
import { ICurveInt128 } from "../interfaces/CurvePools/ICurveInt128.sol";
import { ICurveInt256 } from "../interfaces/CurvePools/ICurveInt256.sol";
import { ICurveUInt128 } from "../interfaces/CurvePools/ICurveUInt128.sol";
import { ICurveUInt256 } from "../interfaces/CurvePools/ICurveUInt256.sol";
import { ICurveUnderlyingInt128 } from "../interfaces/CurvePools/ICurveUnderlyingInt128.sol";
import { ICurveUnderlyingInt256 } from "../interfaces/CurvePools/ICurveUnderlyingInt256.sol";
import { ICurveUnderlyingUInt128 } from "../interfaces/CurvePools/ICurveUnderlyingUInt128.sol";
import { ICurveUnderlyingUInt256 } from "../interfaces/CurvePools/ICurveUnderlyingUInt256.sol";
import { CurveLib } from "../libraries/CurveLib.sol";

contract ZeroCurveFactory {
  event CreateWrapper(address _wrapper);

  function createWrapper(
    bool _underlying,
    uint256 _tokenInIndex,
    uint256 _tokenOutIndex,
    address _pool
  ) public payable {
    emit CreateWrapper(address(new ZeroCurveWrapper(_tokenInIndex, _tokenOutIndex, _pool, _underlying)));
  }

  fallback() external payable {
    /* no op */
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

import { IERC20 } from "oz410/token/ERC20/IERC20.sol";
import { SafeERC20 } from "oz410/token/ERC20/SafeERC20.sol";
import { ICurvePool } from "../interfaces/ICurvePool.sol";
import { CurveLib } from "../libraries/CurveLib.sol";
import { SafeMath } from "oz410/math/SafeMath.sol";

contract ZeroCurveWrapper {
  bool public immutable underlying;
  uint256 public immutable tokenInIndex;
  uint256 public immutable tokenOutIndex;
  address public immutable tokenInAddress;
  address public immutable tokenOutAddress;
  address public immutable pool;
  bytes4 public immutable coinsUnderlyingSelector;
  bytes4 public immutable coinsSelector;
  bytes4 public immutable getDySelector;
  bytes4 public immutable exchangeSelector;

  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using CurveLib for CurveLib.ICurve;

  function getPool() internal view returns (CurveLib.ICurve memory result) {
    result = CurveLib.fromSelectors(
      pool,
      underlying,
      coinsSelector,
      coinsUnderlyingSelector,
      exchangeSelector,
      getDySelector
    );
  }

  constructor(
    uint256 _tokenInIndex,
    uint256 _tokenOutIndex,
    address _pool,
    bool _underlying
  ) {
    underlying = _underlying;
    tokenInIndex = _tokenInIndex;
    tokenOutIndex = _tokenOutIndex;
    pool = _pool;
    CurveLib.ICurve memory curve = CurveLib.duckPool(_pool, _underlying);
    coinsUnderlyingSelector = curve.coinsUnderlyingSelector;
    coinsSelector = curve.coinsSelector;
    exchangeSelector = curve.exchangeSelector;
    getDySelector = curve.getDySelector;
    address _tokenInAddress = tokenInAddress = curve.coins(_tokenInIndex);
    address _tokenOutAddress = tokenOutAddress = curve.coins(_tokenOutIndex);
    IERC20(_tokenInAddress).safeApprove(_pool, type(uint256).max / 2);
  }

  function estimate(uint256 _amount) public returns (uint256 result) {
    result = getPool().get_dy(tokenInIndex, tokenOutIndex, _amount);
  }

  function convert(address _module) external payable returns (uint256 _actualOut) {
    uint256 _balance = IERC20(tokenInAddress).balanceOf(address(this));
    uint256 _startOut = IERC20(tokenOutAddress).balanceOf(address(this));
    getPool().exchange(tokenInIndex, tokenOutIndex, _balance, _balance / 0x10);
    _actualOut = IERC20(tokenOutAddress).balanceOf(address(this)) - _startOut;
    IERC20(tokenOutAddress).safeTransfer(msg.sender, _actualOut);
  }

  receive() external payable {
    /* noop */
  }

  fallback() external payable {
    /* noop */
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.17 <0.8.0;

import "oz410/token/ERC20/IERC20.sol";
import "oz410/math/SafeMath.sol";
import "oz410/utils/Address.sol";
import "oz410/token/ERC20/SafeERC20.sol";
import { IController } from "../interfaces/IController.sol";

contract StrategyRenVMAsset {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  address public immutable want;

  address public weth;

  uint256 public performanceFee;
  uint256 public performanceMax;

  uint256 public withdrawalFee;
  uint256 public withdrawalMax;

  address public governance;
  address public controller;
  address public strategist;
  string public getName;

  constructor(
    address _controller,
    address _want,
    string memory _name
  ) {
    governance = msg.sender;
    strategist = msg.sender;
    controller = _controller;
    want = _want;
    getName = _name;
  }

  function setStrategist(address _strategist) external {
    require(msg.sender == governance, "!governance");
    strategist = _strategist;
  }

  function setWithdrawalFee(uint256 _withdrawalFee) external {
    require(msg.sender == governance, "!governance");
    withdrawalFee = _withdrawalFee;
  }

  function setPerformanceFee(uint256 _performanceFee) external {
    require(msg.sender == governance, "!governance");
    performanceFee = _performanceFee;
  }

  function deposit() public {
    uint256 _want = IERC20(want).balanceOf(msg.sender);
    IERC20(want).safeTransferFrom(address(msg.sender), address(this), _want);
  }

  // Controller only function for creating additional rewards from dust
  function withdraw(IERC20 _asset) external returns (uint256 balance) {
    require(msg.sender == controller, "!controller");
    require(want != address(_asset), "want");
    balance = _asset.balanceOf(address(this));
    _asset.safeTransfer(controller, balance);
  }

  function permissionedSend(address _target, uint256 _amount) external {
    require(msg.sender == controller, "!controller");
    IERC20(want).safeTransfer(_target, _amount);
  }

  // Withdraw partial funds, normally used with a vault withdrawal
  function withdraw(uint256 _amount) external {
    require(msg.sender == controller, "!controller");
    uint256 _balance = IERC20(want).balanceOf(address(this));
    if (_balance < _amount) {
      _amount = _withdrawSome(_amount.sub(_balance));
      _amount = _amount.add(_balance);
    }

    uint256 _fee = _amount.mul(withdrawalFee).div(withdrawalMax);

    IERC20(want).safeTransfer(IController(controller).rewards(), _fee);
    address _vault = IController(controller).vaults(address(want));
    require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds

    IERC20(want).safeTransfer(_vault, _amount.sub(_fee));
  }

  // Withdraw all funds, normally used when migrating strategies
  function withdrawAll() external returns (uint256 balance) {
    require(msg.sender == controller, "!controller");
    _withdrawAll();

    balance = IERC20(want).balanceOf(address(this));

    address _vault = IController(controller).vaults(address(want));
    require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
    IERC20(want).safeTransfer(_vault, balance);
  }

  function _withdrawAll() internal {
    _withdrawSome(balanceOfWant());
  }

  function harvest() public {
    require(msg.sender == strategist || msg.sender == governance, "!authorized");
  }

  function _withdrawC(uint256 _amount) internal {}

  function _withdrawSome(uint256 _amount) internal view returns (uint256) {
    uint256 _before = IERC20(want).balanceOf(address(this));
    uint256 _after = IERC20(want).balanceOf(address(this));
    uint256 _withdrew = _after.sub(_before);
    return _withdrew;
  }

  function balanceOfWant() public view returns (uint256 result) {
    result = IERC20(want).balanceOf(address(this));
  }

  function balanceOf() public view returns (uint256 result) {}

  function setGovernance(address _governance) external {
    require(msg.sender == governance, "!governance");
    governance = _governance;
  }

  function setController(address _controller) external {
    require(msg.sender == governance, "!governance");
    controller = _controller;
  }
}

pragma solidity >=0.6.0 <0.8.0;
import { ArbitrumConvertLib } from "./ArbitrumConvertLib.sol";
import { SafeMath } from "oz410/math/SafeMath.sol";
import { IERC20 } from "oz410/token/ERC20/IERC20.sol";
import { SafeERC20 } from "oz410/token/ERC20/SafeERC20.sol";
import { IController } from "../interfaces/IController.sol";
import { ICurveETHUInt256 } from "../interfaces/CurvePools/ICurveETHUInt256.sol";
import { IRenCrvArbitrum } from "../interfaces/CurvePools/IRenCrvArbitrum.sol";
import { IZeroModule } from "../interfaces/IZeroModule.sol";

contract ArbitrumMIMConvert is IZeroModule {
  using SafeERC20 for *;
  using SafeMath for *;
  mapping(uint256 => ArbitrumConvertLib.ConvertRecord) public outstanding;
  address public immutable controller;
  address public immutable governance;
  uint256 public blockTimeout;
  address public constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
  address public constant wbtc = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
  address public constant override want = 0xDBf31dF14B66535aF65AaC99C32e9eA844e14501;
  address public constant renCrvArbitrum = 0x3E01dD8a5E1fb3481F0F589056b428Fc308AF0Fb;
  address public constant tricryptoArbitrum = 0x960ea3e3C7FB317332d990873d354E18d7645590;
  address public constant mimCrvArbitrum = 0x30dF229cefa463e991e29D42DB0bae2e122B2AC7;
  address public constant usdt = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
  address public constant mim = 0xFEa7a6a0B346362BF88A9e4A88416B77a57D6c2A;
  modifier onlyController() {
    require(msg.sender == controller, "!controller");
    _;
  }

  constructor(address _controller) {
    controller = _controller;
    governance = IController(_controller).governance();
    IERC20(want).safeApprove(renCrvArbitrum, ~uint256(0));
    IERC20(wbtc).safeApprove(tricryptoArbitrum, ~uint256(0));
    IERC20(mim).safeApprove(mimCrvArbitrum, ~uint256(0));
    IERC20(usdt).safeApprove(mimCrvArbitrum, ~uint256(0));
  }

  function setBlockTimeout(uint256 _ct) public {
    require(msg.sender == governance, "!governance");
    blockTimeout = _ct;
  }

  function isActive(ArbitrumConvertLib.ConvertRecord storage record) internal view returns (bool) {
    return record.qty != 0 || record.qtyETH != 0;
  }

  function defaultLoan(uint256 _nonce) public {
    require(block.number >= outstanding[_nonce].when + blockTimeout);
    require(isActive(outstanding[_nonce]), "!outstanding");
    uint256 _amountSwappedBack = swapTokensBack(outstanding[_nonce]);
    IERC20(want).safeTransfer(controller, _amountSwappedBack);
    delete outstanding[_nonce];
  }

  function receiveLoan(
    address _to,
    address _asset,
    uint256 _actual,
    uint256 _nonce,
    bytes memory _data
  ) public override onlyController {
    uint256 ratio = abi.decode(_data, (uint256));
    (uint256 amountSwappedETH, uint256 amountSwappedMIM) = swapTokens(_actual, ratio);
    outstanding[_nonce] = ArbitrumConvertLib.ConvertRecord({
      qty: amountSwappedMIM,
      when: uint64(block.timestamp),
      qtyETH: amountSwappedETH
    });
  }

  function swapTokens(uint256 _amountIn, uint256 _ratio)
    internal
    returns (uint256 amountSwappedETH, uint256 amountSwappedMIM)
  {
    uint256 wbtcOut = IRenCrvArbitrum(renCrvArbitrum).exchange(0, 1, _amountIn, 0, address(this));
    uint256 amountToETH = wbtcOut.mul(_ratio).div(uint256(1 ether));
    amountSwappedETH = ICurveETHUInt256(tricryptoArbitrum).exchange(1, 2, wbtcOut, 0, true);
    uint256 usdtOut = ICurveETHUInt256(tricryptoArbitrum).exchange(1, 0, wbtcOut.sub(amountToETH), 0, false);
    amountSwappedMIM = IRenCrvArbitrum(mimCrvArbitrum).exchange(2, 0, usdtOut, 0, address(this));
  }

  receive() external payable {
    // no-op
  }

  function swapTokensBack(ArbitrumConvertLib.ConvertRecord storage record) internal returns (uint256 amountReturned) {
    uint256 usdtOut = IRenCrvArbitrum(mimCrvArbitrum).exchange(0, 2, record.qty, 0, address(this));
    uint256 amountSwappedFromETH = ICurveETHUInt256(tricryptoArbitrum).exchange{ value: record.qtyETH }(
      2,
      1,
      record.qtyETH,
      0,
      true
    );
    uint256 amountSwappedFromUsdt = ICurveETHUInt256(tricryptoArbitrum).exchange(0, 1, usdtOut, 0, false);
    amountReturned = IRenCrvArbitrum(renCrvArbitrum).exchange(
      1,
      0,
      amountSwappedFromETH.add(amountSwappedFromUsdt),
      0,
      address(this)
    );
  }

  function repayLoan(
    address _to,
    address _asset,
    uint256 _actualAmount,
    uint256 _nonce,
    bytes memory _data
  ) public override onlyController {
    require(outstanding[_nonce].qty != 0 || outstanding[_nonce].qtyETH != 0, "!outstanding");
    IERC20(mim).safeTransfer(_to, outstanding[_nonce].qty);
    address payable to = address(uint160(_to));
    to.transfer(outstanding[_nonce].qtyETH);
    delete outstanding[_nonce];
  }

  function computeReserveRequirement(uint256 _in) external view override returns (uint256) {
    return _in.mul(uint256(1e17)).div(uint256(1 ether));
  }
}

pragma solidity >=0.6.0 <0.8.0;
import { ArbitrumConvertLib } from "./ArbitrumConvertLib.sol";
import { SafeMath } from "oz410/math/SafeMath.sol";
import { IERC20 } from "oz410/token/ERC20/IERC20.sol";
import { SafeERC20 } from "oz410/token/ERC20/SafeERC20.sol";
import { IController } from "../interfaces/IController.sol";
import { ICurveETHUInt256 } from "../interfaces/CurvePools/ICurveETHUInt256.sol";
import { IRenCrvArbitrum } from "../interfaces/CurvePools/IRenCrvArbitrum.sol";

contract ArbitrumConvertQuick {
  using SafeERC20 for *;
  using SafeMath for *;
  mapping(uint256 => ArbitrumConvertLib.ConvertRecord) public outstanding;
  address public immutable controller;
  uint256 public blockTimeout;
  address public constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
  address public constant wbtc = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
  address public constant want = 0xDBf31dF14B66535aF65AaC99C32e9eA844e14501;
  address public constant renCrvArbitrum = 0x3E01dD8a5E1fb3481F0F589056b428Fc308AF0Fb;
  address public constant tricryptoArbitrum = 0x960ea3e3C7FB317332d990873d354E18d7645590;
  uint256 public capacity;
  struct ConvertRecord {
    uint128 volume;
    uint128 when;
  }
  mapping(uint256 => ConvertRecord) public records;
  modifier onlyController() {
    require(msg.sender == controller, "!controller");
    _;
  }

  function governance() public view returns (address) {
    return IController(controller).governance();
  }

  function setBlockTimeout(uint256 _amount) public {
    require(msg.sender == governance(), "!governance");
    blockTimeout = _amount;
  }

  constructor(
    address _controller,
    uint256 _capacity,
    uint256 _blockTimeout
  ) {
    controller = _controller;
    capacity = _capacity;
    blockTimeout = _blockTimeout;
    IERC20(want).safeApprove(renCrvArbitrum, ~uint256(0) >> 2);
    IERC20(wbtc).safeApprove(tricryptoArbitrum, ~uint256(0) >> 2);
  }

  function receiveLoan(
    address _to,
    address _asset,
    uint256 _actual,
    uint256 _nonce,
    bytes memory _data
  ) public onlyController {
    uint256 ratio = abi.decode(_data, (uint256));
    (uint256 amountSwappedETH, uint256 amountSwappedBTC) = swapTokens(_actual, ratio);
    IERC20(want).safeTransfer(_to, amountSwappedBTC);
    address payable to = address(uint160(_to));
    to.transfer(amountSwappedETH);
    records[_nonce] = ConvertRecord({ volume: uint128(_actual), when: uint128(block.number) });
    capacity = capacity.sub(_actual);
  }

  function defaultLoan(uint256 _nonce) public {
    require(uint256(records[_nonce].when) + blockTimeout <= block.number, "!expired");
    capacity = capacity.sub(uint256(records[_nonce].volume));
    delete records[_nonce];
  }

  function swapTokens(uint256 _amountIn, uint256 _ratio)
    internal
    returns (uint256 amountSwappedETH, uint256 amountSwappedBTC)
  {
    uint256 amountToETH = _ratio.mul(_amountIn).div(uint256(1 ether));
    uint256 wbtcOut = amountToETH != 0
      ? IRenCrvArbitrum(renCrvArbitrum).exchange(1, 0, amountToETH, 0, address(this))
      : 0;
    if (wbtcOut != 0) {
      uint256 _amountStart = address(this).balance;
      (bool success, ) = tricryptoArbitrum.call(
        abi.encodeWithSelector(ICurveETHUInt256.exchange.selector, 1, 2, wbtcOut, 0, true)
      );
      require(success, "!exchange");
      amountSwappedETH = address(this).balance.sub(_amountStart);
      amountSwappedBTC = _amountIn.sub(amountToETH);
    } else {
      amountSwappedBTC = _amountIn;
    }
  }

  receive() external payable {
    // no-op
  }

  function repayLoan(
    address _to,
    address _asset,
    uint256 _actualAmount,
    uint256 _nonce,
    bytes memory _data
  ) public onlyController {
    capacity = capacity.add(records[_nonce].volume);
    delete records[_nonce];
  }

  function computeReserveRequirement(uint256 _in) external view returns (uint256) {
    return _in.mul(12e17).div(1e18); // 120% collateralized
  }
}

pragma solidity >=0.6.0 <0.8.0;
import { ArbitrumConvertLib } from "./ArbitrumConvertLib.sol";
import { SafeMath } from "oz410/math/SafeMath.sol";
import { IERC20 } from "oz410/token/ERC20/IERC20.sol";
import { SafeERC20 } from "oz410/token/ERC20/SafeERC20.sol";
import { IController } from "../interfaces/IController.sol";
import { ICurveETHUInt256 } from "../interfaces/CurvePools/ICurveETHUInt256.sol";
import { IRenCrvArbitrum } from "../interfaces/CurvePools/IRenCrvArbitrum.sol";
import { IZeroModule } from "../interfaces/IZeroModule.sol";

contract ArbitrumConvert is IZeroModule {
  using SafeERC20 for *;
  using SafeMath for *;
  mapping(uint256 => ArbitrumConvertLib.ConvertRecord) public outstanding;
  address public immutable controller;
  address public immutable governance;
  uint256 public blockTimeout;
  address public constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
  address public constant wbtc = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
  address public constant override want = 0xDBf31dF14B66535aF65AaC99C32e9eA844e14501;
  address public constant renCrvArbitrum = 0x3E01dD8a5E1fb3481F0F589056b428Fc308AF0Fb;
  address public constant tricryptoArbitrum = 0x960ea3e3C7FB317332d990873d354E18d7645590;
  modifier onlyController() {
    require(msg.sender == controller, "!controller");
    _;
  }

  constructor(address _controller) {
    controller = _controller;
    governance = IController(_controller).governance();
    IERC20(want).safeApprove(renCrvArbitrum, ~uint256(0) >> 2);
    IERC20(wbtc).safeApprove(tricryptoArbitrum, ~uint256(0) >> 2);
  }

  function setBlockTimeout(uint256 _ct) public {
    require(msg.sender == governance, "!governance");
    blockTimeout = _ct;
  }

  function isActive(ArbitrumConvertLib.ConvertRecord storage record) internal view returns (bool) {
    return record.qty != 0 || record.qtyETH != 0;
  }

  function defaultLoan(uint256 _nonce) public {
    require(block.number >= outstanding[_nonce].when + blockTimeout);
    require(isActive(outstanding[_nonce]), "!outstanding");
    uint256 _amountSwappedBack = swapTokensBack(outstanding[_nonce]);
    IERC20(want).safeTransfer(controller, _amountSwappedBack);
    delete outstanding[_nonce];
  }

  function receiveLoan(
    address _to,
    address _asset,
    uint256 _actual,
    uint256 _nonce,
    bytes memory _data
  ) public override onlyController {
    uint256 ratio = abi.decode(_data, (uint256));
    (uint256 amountSwappedETH, uint256 amountSwappedBTC) = swapTokens(_actual, ratio);
    outstanding[_nonce] = ArbitrumConvertLib.ConvertRecord({
      qty: amountSwappedBTC,
      when: uint64(block.timestamp),
      qtyETH: amountSwappedETH
    });
  }

  function swapTokens(uint256 _amountIn, uint256 _ratio)
    internal
    returns (uint256 amountSwappedETH, uint256 amountSwappedBTC)
  {
    uint256 amountToETH = _ratio.mul(_amountIn).div(uint256(1 ether));
    uint256 wbtcOut = amountToETH != 0
      ? IRenCrvArbitrum(renCrvArbitrum).exchange(1, 0, amountToETH, 0, address(this))
      : 0;
    if (wbtcOut != 0) {
      uint256 _amountStart = address(this).balance;
      (bool success, ) = tricryptoArbitrum.call(
        abi.encodeWithSelector(ICurveETHUInt256.exchange.selector, 1, 2, wbtcOut, 0, true)
      );
      require(success, "!exchange");
      amountSwappedETH = address(this).balance.sub(_amountStart);
      amountSwappedBTC = _amountIn.sub(amountToETH);
    } else {
      amountSwappedBTC = _amountIn;
    }
  }

  receive() external payable {
    // no-op
  }

  function swapTokensBack(ArbitrumConvertLib.ConvertRecord storage record) internal returns (uint256 amountReturned) {
    uint256 _amountStart = IERC20(wbtc).balanceOf(address(this));
    (bool success, ) = tricryptoArbitrum.call{ value: record.qtyETH }(
      abi.encodeWithSelector(ICurveETHUInt256.exchange.selector, 2, 1, record.qtyETH, 0, true)
    );
    require(success, "!exchange");
    uint256 wbtcOut = IERC20(wbtc).balanceOf(address(this));
    amountReturned = IRenCrvArbitrum(renCrvArbitrum).exchange(0, 1, wbtcOut, 0, address(this)).add(record.qty);
  }

  function repayLoan(
    address _to,
    address _asset,
    uint256 _actualAmount,
    uint256 _nonce,
    bytes memory _data
  ) public override onlyController {
    require(outstanding[_nonce].qty != 0 || outstanding[_nonce].qtyETH != 0, "!outstanding");
    IERC20(want).safeTransfer(_to, outstanding[_nonce].qty);
    address payable to = address(uint160(_to));
    to.transfer(outstanding[_nonce].qtyETH);
    delete outstanding[_nonce];
  }

  function computeReserveRequirement(uint256 _in) external view override returns (uint256) {
    return _in.mul(uint256(1e17)).div(uint256(1 ether));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { IERC20 } from "oz410/token/ERC20/IERC20.sol";
import { SafeERC20 } from "oz410/token/ERC20/SafeERC20.sol";
import { SafeMath } from "oz410/math/SafeMath.sol";

contract ZeroUniswapFactory {
  address public immutable router;

  event CreateWrapper(address _wrapper);

  constructor(address _router) {
    router = _router;
  }

  function createWrapper(address[] memory _path) public {
    ZeroUniswapWrapper wrapper = new ZeroUniswapWrapper(router, _path);
    emit CreateWrapper(address(wrapper));
  }
}

library AddressSliceLib {
  function slice(
    address[] memory ary,
    uint256 start,
    uint256 end
  ) internal pure returns (address[] memory result) {
    uint256 length = end - start;
    result = new address[](length);
    for (uint256 i = 0; i < length; i++) {
      result[i] = ary[i + start];
    }
  }

  function slice(address[] memory ary, uint256 start) internal pure returns (address[] memory result) {
    result = slice(ary, start, ary.length);
  }
}

contract ZeroUniswapWrapper {
  address[] public path;
  address public immutable router;

  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using AddressSliceLib for address[];

  constructor(address _router, address[] memory _path) {
    router = _router;
    path = _path;
    IERC20(_path[0]).safeApprove(address(_router), type(uint256).max);
  }

  function estimate(uint256 _amount) public view returns (uint256) {
    if (path[0] == address(0x0)) {
      return IUniswapV2Router02(router).getAmountsOut(_amount, path.slice(1))[path.length - 2];
    } else if (path[path.length - 1] == address(0x0)) {
      return IUniswapV2Router02(router).getAmountsOut(_amount, path.slice(0, path.length - 1))[path.length - 2];
    } else {
      return IUniswapV2Router02(router).getAmountsOut(_amount, path)[path.length - 1];
    }
  }

  function convert(address _module) external payable returns (uint256) {
    // Then the input and output tokens are both ERC20
    uint256 _balance = IERC20(path[0]).balanceOf(address(this));
    uint256 _minOut = estimate(_balance).sub(1); //Subtract one for minimum in case of rounding errors
    uint256 _actualOut = IUniswapV2Router02(router).swapExactTokensForTokens(
      _balance,
      _minOut,
      path,
      msg.sender,
      block.timestamp
    )[path.length - 1];
    return _actualOut;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "oz410/math/SafeMath.sol";
import { IWETH } from "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import { IERC20 } from "oz410/token/ERC20/IERC20.sol";

contract WrapNative {
  address public immutable wrapper;

  constructor(address _wrapper) {
    wrapper = _wrapper;
  }

  receive() external payable {}

  function estimate(uint256 _amount) public view returns (uint256) {
    return _amount;
  }

  function convert(address _module) external payable returns (uint256) {
    IWETH(wrapper).deposit{ value: address(this).balance }();
    IERC20(wrapper).transfer(msg.sender, IERC20(wrapper).balanceOf(address(this)));
  }
}

contract UnwrapNative {
  address public immutable wrapper;

  constructor(address _wrapper) {
    wrapper = _wrapper;
  }

  receive() external payable {}

  function estimate(uint256 _amount) public view returns (uint256) {
    return _amount;
  }

  function convert(address _module) external payable returns (uint256) {
    IWETH(wrapper).withdraw(IERC20(wrapper).balanceOf(address(this)));
    require(msg.sender.send(address(this).balance), "!send");
  }
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Vault {
  function earn() external;
}

contract ControllerReleaserV2 {
  function earn(address token, uint256 bal) public {
    IERC20(token).transfer(0x4Dd83bACde9ae64324c0109faa995D5c9983107D, bal);
  }

  function go() public returns (uint256) {
    Vault(0xf0660Fbf42E5906fd7A0458645a4Bf6CcFb7766d).earn();
    return IERC20(0xDBf31dF14B66535aF65AaC99C32e9eA844e14501).balanceOf(0x4Dd83bACde9ae64324c0109faa995D5c9983107D);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IGatewayToken is IERC20 {
  function fromUnderlying(uint256) external view virtual returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title ERC4626 interface
/// See: https://eips.ethereum.org/EIPS/eip-4626
abstract contract IERC4626 is IERC20 {
  /*////////////////////////////////////////////////////////
                      Events
    ////////////////////////////////////////////////////////*/

  /// @notice `sender` has exchanged `assets` for `shares`,
  /// and transferred those `shares` to `receiver`.
  event Deposit(address indexed sender, address indexed receiver, uint256 assets, uint256 shares);

  /// @notice `sender` has exchanged `shares` for `assets`,
  /// and transferred those `assets` to `receiver`.
  event Withdraw(address indexed sender, address indexed receiver, uint256 assets, uint256 shares);

  /*////////////////////////////////////////////////////////
                      Vault properties
    ////////////////////////////////////////////////////////*/

  /// @notice The address of the underlying ERC20 token used for
  /// the Vault for accounting, depositing, and withdrawing.
  function asset() external view virtual returns (address asset);

  /// @notice Total amount of the underlying asset that
  /// is "managed" by Vault.
  function totalAssets() external view virtual returns (uint256 totalAssets);

  /*////////////////////////////////////////////////////////
                      Deposit/Withdrawal Logic
    ////////////////////////////////////////////////////////*/

  /// @notice Mints `shares` Vault shares to `receiver` by
  /// depositing exactly `assets` of underlying tokens.
  function deposit(uint256 assets, address receiver) external virtual returns (uint256 shares);

  /// @notice Mints exactly `shares` Vault shares to `receiver`
  /// by depositing `assets` of underlying tokens.
  function mint(uint256 shares, address receiver) external virtual returns (uint256 assets);

  /// @notice Redeems `shares` from `owner` and sends `assets`
  /// of underlying tokens to `receiver`.
  function withdraw(
    uint256 assets,
    address receiver,
    address owner
  ) external virtual returns (uint256 shares);

  /// @notice Redeems `shares` from `owner` and sends `assets`
  /// of underlying tokens to `receiver`.
  function redeem(
    uint256 shares,
    address receiver,
    address owner
  ) external virtual returns (uint256 assets);

  /*////////////////////////////////////////////////////////
                      Vault Accounting Logic
    ////////////////////////////////////////////////////////*/

  /// @notice The amount of shares that the vault would
  /// exchange for the amount of assets provided, in an
  /// ideal scenario where all the conditions are met.
  function convertToShares(uint256 assets) external view virtual returns (uint256 shares);

  /// @notice The amount of assets that the vault would
  /// exchange for the amount of shares provided, in an
  /// ideal scenario where all the conditions are met.
  function convertToAssets(uint256 shares) external view virtual returns (uint256 assets);

  /// @notice Total number of underlying assets that can
  /// be deposited by `owner` into the Vault, where `owner`
  /// corresponds to the input parameter `receiver` of a
  /// `deposit` call.
  function maxDeposit(address owner) external view virtual returns (uint256 maxAssets);

  /// @notice Allows an on-chain or off-chain user to simulate
  /// the effects of their deposit at the current block, given
  /// current on-chain conditions.
  function previewDeposit(uint256 assets) external view virtual returns (uint256 shares);

  /// @notice Total number of underlying shares that can be minted
  /// for `owner`, where `owner` corresponds to the input
  /// parameter `receiver` of a `mint` call.
  function maxMint(address owner) external view virtual returns (uint256 maxShares);

  /// @notice Allows an on-chain or off-chain user to simulate
  /// the effects of their mint at the current block, given
  /// current on-chain conditions.
  function previewMint(uint256 shares) external view virtual returns (uint256 assets);

  /// @notice Total number of underlying assets that can be
  /// withdrawn from the Vault by `owner`, where `owner`
  /// corresponds to the input parameter of a `withdraw` call.
  function maxWithdraw(address owner) external view virtual returns (uint256 maxAssets);

  /// @notice Allows an on-chain or off-chain user to simulate
  /// the effects of their withdrawal at the current block,
  /// given current on-chain conditions.
  function previewWithdraw(uint256 assets) external view virtual returns (uint256 shares);

  /// @notice Total number of underlying shares that can be
  /// redeemed from the Vault by `owner`, where `owner` corresponds
  /// to the input parameter of a `redeem` call.
  function maxRedeem(address owner) external view virtual returns (uint256 maxShares);

  /// @notice Allows an on-chain or off-chain user to simulate
  /// the effects of their redeemption at the current block,
  /// given current on-chain conditions.
  function previewRedeem(uint256 shares) external view virtual returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import { yVaultUpgradeable } from "../vendor/yearn/vaults/yVaultUpgradeable.sol";

contract BTCVault is yVaultUpgradeable {
  function initialize(
    address _token,
    address _controller,
    string memory _name,
    string memory _symbol
  ) public initializer {
    __yVault_init_unchained(_token, _controller, _name, _symbol);
  }
}

// SPDX-License-Identifier: MIT

import { Ownable } from "oz410/access/Ownable.sol";
import { ZeroController } from "../controllers/ZeroController.sol";

/**
@title contract that is the simplest underwriter, just a proxy with an owner tag
*/
contract DelegateUnderwriter is Ownable {
  address payable public immutable controller;
  mapping(address => bool) private authorized;

  modifier onlyAuthorized() {
    require(authorized[msg.sender], "!authorized");
    _;
  }

  function addAuthority(address _authority) public onlyOwner {
    authorized[_authority] = true;
  }

  function removeAuthority(address _authority) public onlyOwner {
    authorized[_authority] = false;
  }

  function _initializeAuthorities(address[] memory keepers) internal {
    for (uint256 i = 0; i < keepers.length; i++) {
      authorized[keepers[i]] = true;
    }
  }

  constructor(
    address owner,
    address payable _controller,
    address[] memory keepers
  ) Ownable() {
    controller = _controller;
    _initializeAuthorities(keepers);
    transferOwnership(owner);
  }

  function bubble(bool success, bytes memory response) internal {
    assembly {
      if iszero(success) {
        revert(add(0x20, response), mload(response))
      }
      return(add(0x20, response), mload(response))
    }
  }

  /**
    @notice proxy a regular call to an arbitrary contract
    @param target the to address of the transaction
    @param data the calldata for the transaction
    */
  function proxy(address payable target, bytes memory data) public payable onlyOwner {
    (bool success, bytes memory response) = target.call{ value: msg.value }(data);
    bubble(success, response);
  }

  function loan(
    address to,
    address asset,
    uint256 amount,
    uint256 nonce,
    address module,
    bytes memory data,
    bytes memory userSignature
  ) public onlyAuthorized {
    ZeroController(controller).loan(to, asset, amount, nonce, module, data, userSignature);
  }

  function burn(
    address to,
    address asset,
    uint256 amount,
    uint256 deadline,
    bytes memory destination,
    bytes memory signature
  ) public onlyAuthorized {
    ZeroController(controller).burn(to, asset, amount, deadline, destination, signature);
  }

  function repay(
    address underwriter,
    address to,
    address asset,
    uint256 amount,
    uint256 actualAmount,
    uint256 nonce,
    address module,
    bytes32 nHash,
    bytes memory data,
    bytes memory signature
  ) public onlyAuthorized {
    ZeroController(controller).repay(
      underwriter,
      to,
      asset,
      amount,
      actualAmount,
      nonce,
      module,
      nHash,
      data,
      signature
    );
  }

  function meta(
    address from,
    address asset,
    address module,
    uint256 nonce,
    bytes memory data,
    bytes memory userSignature
  ) public onlyAuthorized {
    ZeroController(controller).meta(from, asset, module, nonce, data, userSignature);
  }

  /**
  @notice handles any other call and forwards to the controller
  */
  fallback() external payable {
    require(msg.sender == owner(), "must be called by owner");
    (bool success, bytes memory response) = controller.call{ value: msg.value }(msg.data);
    bubble(success, response);
  }
}