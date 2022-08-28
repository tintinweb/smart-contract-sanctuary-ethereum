// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "./interfaces/lightweight/IUniswapV2Factory.sol";
import "./interfaces/lightweight/IUniswapV2Pair.sol";
import "./interfaces/lightweight/IUniswapV2Router02.sol";
import "./interfaces/IContractDeployerV1.sol";
import "./interfaces/IFeeCollectorV1.sol";
import "./interfaces/ISignerVaultV1.sol";
import "./interfaces/ISignerVaultFactoryV1.sol";
import "./library/AddressArrayHelper.sol";
import "./library/ERC721LockMapHelper.sol";
import "./library/TokenLockMapHelper.sol";
import "./library/TransferHelper.sol";
import "./structs/SwapLiquidityLocalVariables.sol";
import "./structs/Vote.sol";

contract SignerVaultV1 is ISignerVaultV1 {
  using AddressArrayHelper for address[];
  using ERC721LockMapHelper for LockMap;
  using TokenLockMapHelper for LockMap;

  uint constant private UINT_MAX_VALUE = 2 ** 256 - 1;
  string constant private IDENTIFIER = "SignerVault";
  uint constant private VERSION = 1;

  address immutable private _deployer;
  Dependency[] _dependencies;

  bool _implementationInitialized;

  address private _signerVaultFactory;

  address[] private _signersArray;
  mapping (address => bool) _signers;
  mapping (address => LockMap) private _lockMaps;
  Vote private _vote;

  bool private _locked;

  constructor() {
    _deployer = msg.sender;
  }

  receive() external payable {}
  fallback() external payable {}

  modifier lock() {
    require(!_locked, "SignerVault: reentrancy");
    _locked = true;
    _;
    _locked = false;
  }

  modifier onlyDeployer() {
    require(msg.sender == _deployer, "SignerVault: caller must be the deployer");
    _;
  }

  function onlyThis() private view {
    require(msg.sender == address(this), "SignerVault: caller must be this");
  }

  function onlyVault() private view {
    require(msg.sender == ISignerVaultFactoryV1(_signerVaultFactory).vault(), "SignerVault: caller must be the vault");
  }

  function onlySigners() private view {
    require(_signers[msg.sender], "SignerVault: caller must be a signer");
  }

  function onlyVaultOrSigners() private view {
    require(msg.sender == ISignerVaultFactoryV1(_signerVaultFactory).vault() || _signers[msg.sender], "SignerVault: caller must be the vault or a signer");
  }

  function ensureFee(uint fee) private {
    if (msg.sender != ISignerVaultFactoryV1(_signerVaultFactory).vault()) {
      require(msg.value >= fee, "SignerVault: insufficient value");
      if (fee > 0)
        IFeeCollectorV1(ISignerVaultFactoryV1(_signerVaultFactory).feeCollector()).payFee{ value: fee }(fee);
      if (msg.value > fee) 
        TransferHelper.safeTransferETH(msg.sender, msg.value - fee);
    }
  }

  function ensureAmountAndFee(uint amount, uint fee) private {
    if (msg.sender != ISignerVaultFactoryV1(_signerVaultFactory).vault()) {
      require(msg.value >= amount + fee, "SignerVault: insufficient value");
      if (fee > 0)
        IFeeCollectorV1(ISignerVaultFactoryV1(_signerVaultFactory).feeCollector()).payFee{ value: fee }(fee);
      if (msg.value > amount + fee) 
        TransferHelper.safeTransferETH(msg.sender, msg.value - amount - fee);
    } else {
      require(msg.value >= amount, "SignerVault: insufficient value");
      if (msg.value > amount) 
        TransferHelper.safeTransferETH(msg.sender, msg.value - amount);
    }
  }

  function ensureVoter(address voter) private view {
    require(_signers[voter], "SignerVault: voter must be a signer");
  }

  function ensureRecipient(address recipient) private view {
    require(_signers[recipient], "SignerVault: recipient must be a signer");
  }

  function ensureUntil(uint until) private view {
    require(until > block.timestamp, "SignerVault: until must be greater than the current block timestamp");
  }

  function ensureToken(address token) private pure {
    require(token != address(0), "SignerVault: token can't be the null address");
  }

  function ensureERC721(address erc721) private pure {
    require(erc721 != address(0), "SignerVault: erc721 can't be the null address");
  }

  function identifier() external pure returns (string memory) {
    return IDENTIFIER;
  }

  function version() external pure returns (uint) {
    return VERSION;
  }

  function dependencies() external view returns (Dependency[] memory) {
    return _dependencies;
  }

  function updateDependencies(Dependency[] calldata dependencies_) external onlyDeployer {
    delete _dependencies;
    for (uint index = 0; index < dependencies_.length; index++)
      _dependencies.push(dependencies_[index]);
  }

  function deployer() external view returns (address) {
    return _deployer;
  }

  function initialize(bytes calldata data) external onlyDeployer {}

  function initializeImplementation(address signerVaultFactory_, address signer_) external {
    require(!_implementationInitialized);
    _implementationInitialized = true;
    _signerVaultFactory = signerVaultFactory_;
    _signersArray.push(signer_);
    _signers[signer_] = true;
  }

  function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }

  function signerVaultFactory() external view returns (address) {
    return _signerVaultFactory;
  }

  function signers() external view returns (address[] memory) {
    return _signersArray;
  }

  function signer(address candidate) external view returns (bool) {
    return _signers[candidate];
  }

  function addSignerViaVote(address nominee) external {
    onlyThis();
    _addSigner(nominee);
  }

  function removeSignerViaVote(address nominee) external {
    onlyThis();
    _removeSigner(nominee);
  }

  function unlockETHViaVote(uint amount, address recipient) external {
    onlyThis();
    _unlockETH(amount, recipient);
  }

  function unlockTokenViaVote(address token, uint amount, address recipient) external {
    onlyThis();
    _unlockToken(token, amount, recipient);
  }

  function unlockERC721ViaVote(address erc721, uint tokenId, address recipient) external {
    onlyThis();
    _unlockERC721(erc721, tokenId, recipient);
  }

  function vote(address voter) external view returns (bytes memory data, uint quorom, uint accepts, uint rejects, bool voted) {
    data = _vote.data;
    quorom = _vote.quorom;
    accepts = _vote.accepts;
    rejects = _vote.rejects;
    voted = _vote.voted[voter];
  }

  function castVote(bool accept) external {
    onlySigners();
    _castVote(accept, msg.sender);
  }

  function castVote(bool accept, address voter) external {
    onlyVault();
    _castVote(accept, voter);
  }

  function addSigner(address nominee) external {
    onlySigners();
    _addSignerWithVote(nominee, msg.sender);
  }

  function addSigner(address nominee, address voter) external {
    onlyVault();
    _addSignerWithVote(nominee, voter);
  }

  function removeSigner(address nominee) external {
    onlySigners();
    _removeSignerWithVote(nominee, msg.sender);
  }

  function removeSigner(address nominee, address voter) external {
    onlyVault();
    _removeSignerWithVote(nominee, voter);
  }

  function lockMapETH() external view returns (LockMap memory) {
    return _getLockMapUnsafe(address(0));
  }

  function claimETH() external {
    onlySigners();
    _claimETH(msg.sender);
  }

  function claimETH(address recipient) external {
    onlyVaultOrSigners();
    _claimETH(recipient);
  }

  function unlockETH(uint amount) external {
    onlySigners();
    _unlockETHWithVote(amount, msg.sender, msg.sender);
  }

  function unlockETH(uint amount, address recipient) external {
    onlySigners();
    _unlockETHWithVote(amount, recipient, msg.sender);
  }

  function unlockETH(uint amount, address recipient, address voter) external {
    onlyVault();
    _unlockETHWithVote(amount, recipient, voter);
  }

  function lockETH(uint amount, uint until) external payable {
    _lockETH(amount, until);
  }

  function lockETHPermanently(uint amount) external payable {
    _lockETH(amount, UINT_MAX_VALUE);
  }

  function lockMapToken(address token) external view returns (LockMap memory) {
    return _getLockMapUnsafe(token);
  }

  function claimToken(address token) external {
    onlySigners();
    _claimToken(token, msg.sender);
  }

  function claimToken(address token, address recipient) external {
    onlyVaultOrSigners();
    _claimToken(token, recipient);
  }

  function unlockToken(address token, uint amount) external {
    onlySigners();
    _unlockTokenWithVote(token, amount, msg.sender, msg.sender);
  }

  function unlockToken(address token, uint amount, address recipient) external {
    onlySigners();
    _unlockTokenWithVote(token, amount, recipient, msg.sender);
  }

  function unlockToken(address token, uint amount, address recipient, address voter) external {
    onlyVault();
    _unlockTokenWithVote(token, amount, recipient, voter);
  }

  function lockToken(address token, uint amount, uint until) external payable {
    _lockToken(token, amount, until);
  }

  function lockTokenPermanently(address token, uint amount) external payable {
    _lockToken(token, amount, UINT_MAX_VALUE);
  }

  function lockMapERC721(address erc721) external view returns (LockMap memory) {
    return _getLockMapUnsafe(erc721);
  }

  function claimERC721(address erc721, uint tokenId) external {
    onlySigners();
    _claimERC721(erc721, tokenId, msg.sender);
  }

  function claimERC721(address erc721, uint tokenId, address recipient) external {
    onlyVaultOrSigners();
    _claimERC721(erc721, tokenId, recipient);
  }

  function unlockERC721(address erc721, uint tokenId) external {
    onlySigners();
    _unlockERC721WithVote(erc721, tokenId, msg.sender, msg.sender);
  }

  function unlockERC721(address erc721, uint tokenId, address recipient) external {
    onlySigners();
    _unlockERC721WithVote(erc721, tokenId, recipient, msg.sender);
  }

  function unlockERC721(address erc721, uint tokenId, address recipient, address voter) external {
    onlyVault();
    _unlockERC721WithVote(erc721, tokenId, recipient, voter);
  }

  function lockERC721(address erc721, uint tokenId, uint until) external payable {
    _lockERC721(erc721, tokenId, until);
  }

  function lockERC721Permanently(address erc721, uint tokenId) external payable {
    _lockERC721(erc721, tokenId, UINT_MAX_VALUE);
  }

  function swapLiquidity(address token, uint removeLiquidity, address[] calldata swapPath, uint deadline) external payable {
    _swapLiquidity(token, removeLiquidity, 0, 0, 0, swapPath, 0, 0, deadline);
  }

  function swapLiquidity(address token, uint removeLiquidity, uint swapAmountOutMin, address[] calldata swapPath, uint deadline) external payable {
    _swapLiquidity(token, removeLiquidity, 0, 0, swapAmountOutMin, swapPath, 0, 0, deadline);
  }

  function swapLiquidity(address token, uint removeLiquidity, uint removeAmountAMin, uint removeAmountBMin, uint swapAmountOutMin, address[] calldata swapPath, uint addAmountAMin, uint addAmountBMin, uint deadline) external payable {
    _swapLiquidity(token, removeLiquidity, removeAmountAMin, removeAmountBMin, swapAmountOutMin, swapPath, addAmountAMin, addAmountBMin, deadline);
  }

  function _getLockMapUnsafe(address id) private view returns (LockMap memory) {
    return _lockMaps[id];
  }

  function _getLockMap(address id) private returns (LockMap storage lockMap) {
    lockMap = _lockMaps[id];
    if (!lockMap.initialized) {
        lockMap.id = id;
        lockMap.initialized = true;
    }
  }

  function _initVote(address voter, bytes memory data) private {
    ensureVoter(voter);
    require(_vote.data.length == 0, "SignerVault: a vote can't be pending");
    _vote.data = data;
    _vote.quorom = _signersArray.length / 2;
    _vote.accepts = 1;
    _vote.voted[voter] = true;
  }

  function _castVote(bool accept, address voter) private lock {
    ensureVoter(voter);
    require(!_vote.voted[voter], "SignerVault: voter can't have voted");
    require(_vote.data.length > 0, "SignerVault: a vote must be pending");

    if (accept)
      _vote.accepts++;
    else
      _vote.rejects++;
    _vote.voted[voter] = true;

    if (_vote.accepts >= _vote.quorom || _vote.rejects >= _vote.quorom) {
      for (uint index = 0; index < _signersArray.length; index++)
        _vote.voted[_signersArray[index]] = false;

      string memory revertReason;
      if (_vote.accepts >= _vote.quorom) {
        (bool success, bytes memory data) = address(this).call(_vote.data);
        if (!success) {
            uint length = data.length;
            if (length >= 68) {
              uint l;
              assembly {
                data := add(data, 4)
                l := mload(data)
                mstore(data, sub(length, 4))
              }

              revertReason = abi.decode(data, (string));
              assembly {
                mstore(data, l)
              }
            }
        }

        emit VoteOperationExecuted(_vote.data, success, revertReason);
      }

      delete _vote;
    }
  }

  function _addSignerWithVote(address nominee, address voter) private lock {
    if (_signersArray.length > 2) {
      require(!_signers[nominee], "SignerVault: nominee can't be a signer");
      ensureVoter(voter);
      _initVote(voter, abi.encodeWithSelector(this.addSignerViaVote.selector, nominee));
      return;
    }

    _addSigner(nominee);
  }

  function _addSigner(address nominee) private {
    require(!_signers[nominee], "SignerVault: nominee can't be a signer");
    _signersArray.push(nominee);
    _signers[nominee] = true;
    ISignerVaultFactoryV1(_signerVaultFactory).addLinking(nominee);
  }

  function _removeSignerWithVote(address nominee, address voter) private lock {
    if (_signersArray.length > 2) {
      require(_signers[nominee], "SignerVault: nominee must be a signer");
      ensureVoter(voter);
      _initVote(voter, abi.encodeWithSelector(this.removeSignerViaVote.selector, nominee));
      return;
    }

    revert("SignerVault: removing a signer is only allowed for 3 or more signers");
  }

  function _removeSigner(address nominee) private {
    require(_signers[nominee], "SignerVault: nominee must be a signer");
    _signersArray.remove(nominee);
    _signers[nominee] = false;
    ISignerVaultFactoryV1(_signerVaultFactory).removeLinking(nominee);
  }

  function _claimETH(address recipient) private lock {
    ensureRecipient(recipient);
    TransferHelper.safeTransferETH(recipient, address(this).balance - _getLockMap(address(0)).balanceTokens());
    _getLockMap(address(0)).validateTokens();
  }

  function _unlockETHWithVote(uint amount, address recipient, address voter) private lock {
    if (_signersArray.length > 2) {
      ensureRecipient(recipient);
      ensureVoter(voter);
      _initVote(voter, abi.encodeWithSelector(this.unlockETHViaVote.selector, amount, recipient));
      return;
    }

    _unlockETH(amount, recipient);
  }

  function _unlockETH(uint amount,address recipient) private {
    ensureRecipient(recipient);
    TransferHelper.safeTransferETH(recipient, amount);
    _getLockMap(address(0)).removeTokens(amount);
  }

  function _lockETH(uint amount, uint until) private lock {
    ensureAmountAndFee(amount, IFeeCollectorV1(ISignerVaultFactoryV1(_signerVaultFactory).feeCollector()).lockETHFee(address(this), msg.sender));
    ensureUntil(until);
    _getLockMap(address(0)).addTokens(amount, until);
  }

  function _claimToken(address token, address recipient) private lock {
    ensureToken(token);
    ensureRecipient(recipient);
    TransferHelper.safeTransfer(token, recipient, IERC20(token).balanceOf(address(this)) - _getLockMap(token).balanceTokens());
    _getLockMap(token).validateTokens();
  }

  function _unlockTokenWithVote(address token, uint amount, address recipient, address voter) private lock {
    if (_signersArray.length > 2) {
      ensureToken(token);
      ensureRecipient(recipient);
      ensureVoter(voter);
      _initVote(voter, abi.encodeWithSelector(this.unlockTokenViaVote.selector, token, amount, recipient));
      return;
    }

    _unlockToken(token, amount, recipient);
  }

  function _unlockToken(address token, uint amount, address recipient) private {
    ensureToken(token);
    ensureRecipient(recipient);
    uint balanceBefore = IERC20(token).balanceOf(address(this));
    TransferHelper.safeTransfer(token, recipient, amount);
    amount = balanceBefore - IERC20(token).balanceOf(address(this));
    _getLockMap(token).removeTokens(amount);
  }

  function _lockToken(address token, uint amount, uint until) private lock {
    ensureFee(IFeeCollectorV1(ISignerVaultFactoryV1(_signerVaultFactory).feeCollector()).lockTokenFee(address(this), msg.sender));
    ensureToken(token);
    ensureUntil(until);
    if (msg.sender != ISignerVaultFactoryV1(_signerVaultFactory).vault()) {
      uint balanceBefore = IERC20(token).balanceOf(address(this));
      TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
      amount = IERC20(token).balanceOf(address(this)) - balanceBefore;
    }
    _getLockMap(token).addTokens(amount, until);
  }

  function _claimERC721(address erc721, uint tokenId, address recipient) private lock {
    ensureERC721(erc721);
    ensureRecipient(recipient);
    TransferHelper.safeTransferFrom(erc721, address(this), recipient, tokenId);
    _getLockMap(erc721).validateERC721s();
  }

  function _unlockERC721WithVote(address erc721, uint tokenId, address recipient, address voter) private lock {
    if (_signersArray.length > 2) {
      ensureERC721(erc721);
      ensureRecipient(recipient);
      ensureVoter(voter);
      _initVote(voter, abi.encodeWithSelector(this.unlockERC721ViaVote.selector, erc721, tokenId, recipient));
      return;
    }

    _unlockERC721(erc721, tokenId, recipient);
  }

  function _unlockERC721(address erc721, uint tokenId, address recipient) private {
    ensureERC721(erc721);
    ensureRecipient(recipient);
    TransferHelper.safeTransferFrom(erc721, address(this), recipient, tokenId);
    _getLockMap(erc721).removeERC721(tokenId);
  }

  function _lockERC721(address erc721, uint tokenId, uint until) private lock {
    ensureFee(IFeeCollectorV1(ISignerVaultFactoryV1(_signerVaultFactory).feeCollector()).lockERC721Fee(address(this), msg.sender));
    ensureERC721(erc721);
    ensureUntil(until);
    if (msg.sender != ISignerVaultFactoryV1(_signerVaultFactory).vault())
      TransferHelper.safeTransferFrom(erc721, msg.sender, address(this), tokenId);
    _getLockMap(erc721).addERC721(tokenId, until);
  }

  function _swapLiquidity(address token, uint removeLiquidity, uint removeAmountAMin, uint removeAmountBMin, uint swapAmountOutMin, address[] calldata swapPath, uint addAmountAMin, uint addAmountBMin, uint deadline) private lock {
    onlyVaultOrSigners();
    ensureFee(IFeeCollectorV1(ISignerVaultFactoryV1(_signerVaultFactory).feeCollector()).swapLiquidityFee(address(this), msg.sender));

    ensureToken(token);
    require(removeLiquidity > 0, "SignerVault: removeLiquidity must be greater than 0");
    require(swapPath.length > 1, "SignerVault: swapPath must contain atleast 2 entries");
    require(deadline >= block.timestamp, "SignerVault: deadline must be greater or equal than the current block timestamp");

    SwapLiquidityLocalVariables memory localVariables;

    IUniswapV2Router02 uniswapV2Router02 = IUniswapV2Router02(IContractDeployerV1(ISignerVaultFactoryV1(_signerVaultFactory).contractDeployer()).router());
    (localVariables.amountA, localVariables.amountB, localVariables.until) = _removeLiquidity(uniswapV2Router02, IUniswapV2Pair(token).token0(), IUniswapV2Pair(token).token1(), removeLiquidity, removeAmountAMin, removeAmountBMin, deadline);
    localVariables.addAmountBDesired = _swapExactTokensForTokensSupportingFeeOnTransferTokens(uniswapV2Router02, swapPath[0] == IUniswapV2Pair(token).token0() ? localVariables.amountA : localVariables.amountB, swapAmountOutMin, swapPath, deadline, localVariables.until);
    _addLiquidity(uniswapV2Router02, swapPath[0] == IUniswapV2Pair(token).token0() ? IUniswapV2Pair(token).token1() : IUniswapV2Pair(token).token0(), swapPath[swapPath.length - 1], swapPath[0] == IUniswapV2Pair(token).token0() ? localVariables.amountB : localVariables.amountA, localVariables.addAmountBDesired, addAmountAMin, addAmountBMin, deadline, localVariables.until);
  }

  function _removeLiquidity(IUniswapV2Router02 uniswapV2Router02, address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, uint deadline) private returns (uint amountA, uint amountB, uint until) {
    address tokenPair = IUniswapV2Factory(uniswapV2Router02.factory()).getPair(tokenA, tokenB);
    TransferHelper.safeApprove(tokenPair, address(uniswapV2Router02), liquidity);
    uint balancePairBefore = IUniswapV2Pair(tokenPair).balanceOf(address(this));
    uint balanceABefore = IERC20(tokenA).balanceOf(address(this));
    uint balanceBBefore = IERC20(tokenB).balanceOf(address(this));
    uniswapV2Router02.removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, address(this), deadline);
    amountA = IERC20(tokenA).balanceOf(address(this)) - balanceABefore;
    amountB = IERC20(tokenB).balanceOf(address(this)) - balanceBBefore;
    until = TokenLockMapHelper.removeTokens(_getLockMap(tokenPair), balancePairBefore - IUniswapV2Pair(tokenPair).balanceOf(address(this)), true);
    TokenLockMapHelper.addTokens(_getLockMap(tokenA), amountA, until);
    TokenLockMapHelper.addTokens(_getLockMap(tokenB), amountB, until);
  }

  function _swapExactTokensForTokensSupportingFeeOnTransferTokens(IUniswapV2Router02 uniswapV2Router02, uint amountIn, uint amountOutMin, address[] calldata path, uint deadline, uint until) private returns (uint amount) {
    TransferHelper.safeApprove(path[0], address(uniswapV2Router02), amountIn);
    uint[] memory balancesBefore = new uint[](path.length);
    for (uint i = 0; i < path.length; i++)
      balancesBefore[i] = IERC20(path[i]).balanceOf(address(this));
    uniswapV2Router02.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, address(this), deadline);
    amount = IERC20(path[path.length - 1]).balanceOf(address(this)) - balancesBefore[path.length - 1];
    TokenLockMapHelper.removeTokens(_getLockMap(path[0]), balancesBefore[0] - IERC20(path[0]).balanceOf(address(this)), true);
    for (uint i = 1; i < path.length - 1; i++)
      TokenLockMapHelper.addTokens(_getLockMap(path[i]), IERC20(path[i]).balanceOf(address(this)) - balancesBefore[i], until);
    TokenLockMapHelper.addTokens(_getLockMap(path[path.length - 1]), amount, until);
  }

  function _addLiquidity(IUniswapV2Router02 uniswapV2Router02, address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, uint deadline, uint until) private {
    address tokenPair = IUniswapV2Factory(uniswapV2Router02.factory()).getPair(tokenA, tokenB);
    TransferHelper.safeApprove(tokenA, address(uniswapV2Router02), amountADesired);
    TransferHelper.safeApprove(tokenB, address(uniswapV2Router02), amountBDesired);
    uint balanceABefore = IERC20(tokenA).balanceOf(address(this));
    uint balanceBBefore = IERC20(tokenB).balanceOf(address(this));
    uint balancePairBefore = IUniswapV2Pair(tokenPair).balanceOf(address(this));
    uniswapV2Router02.addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, address(this), deadline);
    TokenLockMapHelper.removeTokens(_getLockMap(tokenA), balanceABefore - IERC20(tokenA).balanceOf(address(this)), true);
    TokenLockMapHelper.removeTokens(_getLockMap(tokenB), balanceBBefore - IERC20(tokenB).balanceOf(address(this)), true);
    TokenLockMapHelper.addTokens(_getLockMap(tokenPair), IUniswapV2Pair(tokenPair).balanceOf(address(this)) - balancePairBefore, until);
  }
}

// lightweight version of @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

// SPDX-License-Identifier: GPL-3.0-or-later
// Uniswap Contracts

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// lightweight version of @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

// SPDX-License-Identifier: GPL-3.0-or-later
// Uniswap Contracts

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
  function balanceOf(address owner) external view returns (uint);

  function token0() external view returns (address);
  function token1() external view returns (address);
}

// @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

// SPDX-License-Identifier: GPL-3.0-or-later
// Uniswap Contracts

pragma solidity >=0.6.2;

interface IUniswapV2Router02 {
  function factory() external pure returns (address);

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
  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;
}

// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "./IVersion.sol";

interface IContractDeployerV1 is IVersion {
  function router() external view returns (address);
  function feeSetter() external view returns (address);

  function addressOf(string memory identifier_, uint version_) external view returns (address);
  function deploy(string memory identifier_, uint version_, bytes memory bytecode) external;
  function initialize(string memory identifier_, uint version_) external;
}

// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "./IVersion.sol";
import "../structs/Collaborations.sol";
import "../structs/Shareholders.sol";

interface IFeeCollectorV1 is IVersion {
  function contractDeployer() external view returns (address);

  function shares() external view returns (Shareholders memory);
  function setShares(address shareholder, uint share) external;

  function reductions() external view returns (Collaborations memory);
  function setReductions(address collaboration, uint minBalance, Fees calldata reduction) external;

  function partnerOf(address partner) external view returns (uint);
  function setPartnerOf(address partner, uint fee) external;

  function exemptOf(address vaultOrSigner) external view returns (bool);
  function setExemptOf(address vaultOrSigner, bool exempt) external;

  function lockETHFee() external view returns (uint);
  function lockETHFee(address vault, address signer) external view returns (uint);
  function setLockETHFee(uint lockETHFee_) external;

  function lockTokenFee() external view returns (uint);
  function lockTokenFee(address vault, address signer) external view returns (uint);
  function setLockTokenFee(uint lockTokenFee_) external;

  function lockERC721Fee() external view returns (uint);
  function lockERC721Fee(address vault, address signer) external view returns (uint);
  function setLockERC721Fee(uint lockERC721Fee_) external;

  function swapLiquidityFee() external view returns (uint);
  function swapLiquidityFee(address vault, address signer) external view returns (uint);
  function setSwapLiquidityFee(uint swapLiquidityFee_) external;

  function fees() external view returns (Fees memory);
  function fees(address vault, address signer) external view returns (Fees memory);
  function setFees(Fees calldata fees_) external;

  function payFee(uint fee) external payable;
  function payFeeOnPartner(uint fee, address partner) external payable;
}

// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "./lightweight/IERC721Receiver.sol";
import "./IVersion.sol";
import "../structs/LockMap.sol";

interface ISignerVaultV1 is IVersion, IERC721Receiver {
  event VoteOperationExecuted(bytes data, bool success, string revertReason);

  function initializeImplementation(address signerVaultFactory_, address signer_) external;

  function signerVaultFactory() external view returns (address);
  function signers() external view returns (address[] memory);
  function signer(address candidate) external view returns (bool);

  function vote(address voter) external view returns (bytes memory data, uint quorom, uint accepts, uint rejects, bool voted);
  function castVote(bool accept) external;
  function castVote(bool accept, address voter) external;

  function addSigner(address nominee) external;
  function addSigner(address nominee, address voter) external;
  function removeSigner(address nominee) external;
  function removeSigner(address nominee, address voter) external;

  function lockMapETH() external view returns (LockMap memory);
  function claimETH() external;
  function claimETH(address recipient) external;
  function unlockETH(uint amount) external;
  function unlockETH(uint amount, address recipient) external;
  function unlockETH(uint amount, address recipient, address voter) external;
  function lockETH(uint amount, uint until) external payable;
  function lockETHPermanently(uint amount) external payable;

  function lockMapToken(address token) external view returns (LockMap memory);
  function claimToken(address token) external;
  function claimToken(address token, address recipient) external;
  function unlockToken(address token, uint amount) external;
  function unlockToken(address token, uint amount, address recipient) external;
  function unlockToken(address token, uint amount, address recipient, address voter) external;
  function lockToken(address token, uint amount, uint until) external payable;
  function lockTokenPermanently(address token, uint amount) external payable;

  function lockMapERC721(address erc721) external view returns (LockMap memory);
  function claimERC721(address erc721, uint tokenId) external;
  function claimERC721(address erc721, uint tokenId, address recipient) external;
  function unlockERC721(address erc721, uint tokenId) external;
  function unlockERC721(address erc721, uint tokenId, address recipient) external;
  function unlockERC721(address erc721, uint tokenId, address recipient, address voter) external;
  function lockERC721(address erc721, uint tokenId, uint until) external payable;
  function lockERC721Permanently(address erc721, uint tokenId) external payable;

  function swapLiquidity(address token, uint removeLiquidity, address[] calldata swapPath, uint deadline) external payable;
  function swapLiquidity(address token, uint removeLiquidity, uint swapAmountOutMin, address[] calldata swapPath, uint deadline) external payable;
  function swapLiquidity(address token, uint removeLiquidity, uint removeAmountAMin, uint removeAmountBMin, uint swapAmountOutMin, address[] calldata swapPath, uint addAmountAMin, uint addAmountBMin, uint deadline) external payable;
}

// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "./IVersion.sol";

interface ISignerVaultFactoryV1 is IVersion {
  event VaultCreated(address indexed signer, address vault, uint length, uint signerLength);

  function contractDeployer() external view returns (address);
  function feeCollector() external view returns (address);
  function vault() external view returns (address);
  function signerVault() external view returns (address);

  function contains(address vault_) external view returns (bool);

  function vaults() external view returns (address[] memory);
  function vaultsLength() external view returns (uint);
  function getVault(uint index) external view returns (address);

  function vaultsOf(address signer) external view returns (address[] memory);
  function vaultsLengthOf(address signer) external view returns (uint);
  function getVaultOf(address signer, uint index) external view returns (address);

  function createVault(address signer) external returns (address);

  function addLinking(address newSigner) external;
  function removeLinking(address oldSigner) external;
}

// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

library AddressArrayHelper {
  function remove(address[] storage array, address item) internal returns (bool) {
    for (uint index = 0; index < array.length; index++) {
      if (array[index] == item) {
        uint lastIndex = array.length - 1;
        if (index != lastIndex)
          array[index] = array[lastIndex];
        array.pop();
        return true;
      }
    }

    return false;
  }
}

// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "../interfaces/lightweight/IERC721.sol";
import "../structs/LockMap.sol";

library ERC721LockMapHelper {
  function addERC721(LockMap storage lockMap, uint tokenId, uint until) internal {
    lockMap.untils.push(until);
    lockMap.values.push(tokenId);
    lockMap.length++;
    validateERC721s(lockMap);
  }

  function removeERC721(LockMap storage lockMap, uint tokenId) internal {
    removeERC721(lockMap, tokenId, false);
  }

  function removeERC721(LockMap storage lockMap, uint tokenId, bool forced) internal returns (uint) {
    uint length = lockMap.length;
    uint indexToRemove = length;
    uint until;

    for (uint index = 0; index < length; index++) {
      if (lockMap.values[index] == tokenId && (forced || lockMap.untils[index] <= block.timestamp)) {
        until = lockMap.untils[index];
        indexToRemove = index;
        break;
      }
    }

    require(indexToRemove != length, "ERC721LockMapHelper: INSUFFICIENT_UNLOCKABLE_BALANCE");

    uint lastIndex = lockMap.length - 1;
    if (indexToRemove != lastIndex) {
      lockMap.untils[indexToRemove] = lockMap.untils[lastIndex];
      lockMap.values[indexToRemove] = lockMap.values[lastIndex];
    }

    lockMap.untils.pop();
    lockMap.values.pop();
    lockMap.length--;
    validateERC721s(lockMap);
    return until;
  }

  function validateERC721s(LockMap storage lockMap) internal view {
    uint length = lockMap.length;

    uint expectedBalance = length;
    uint balance = IERC721(lockMap.id).balanceOf(address(this));
    require(expectedBalance <= balance, "ERC721LockMapHelper: BALANCE_MISMATCH");

    for (uint index = 0; index < length; index++)
      require(address(this) == IERC721(lockMap.id).ownerOf(lockMap.values[index]), "ERC721LockMapHelper: OWNER_MISMATCH");
  }

  function canUnlockERC721(LockMap storage lockMap, uint tokenId) internal view returns (bool) {
    uint length = lockMap.length;

    for (uint index = 0; index < length; index++)
      if (lockMap.values[index] == tokenId && lockMap.untils[index] <= block.timestamp)
        return true;

    return false;
  }

  function balanceERC721s(LockMap storage lockMap) internal view returns (uint) {
    return lockMap.length;
  }
}

// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "../interfaces/lightweight/IERC20.sol";
import "../structs/LockMap.sol";

library TokenLockMapHelper {
  function addTokens(LockMap storage lockMap, uint amount, uint until) internal {
    uint length = lockMap.length;

    for (uint index = 0; index < length; index++) {
      if (lockMap.untils[index] == until) {
        lockMap.values[index] += amount;
        validateTokens(lockMap);
        return;
      }
    }

    lockMap.untils.push(until);
    lockMap.values.push(amount);
    lockMap.length++;
    validateTokens(lockMap);
  }

  function removeTokens(LockMap storage lockMap, uint amount) internal {
    removeTokens(lockMap, amount, false);
  }

  function removeTokens(LockMap storage lockMap, uint amount, bool forced) internal returns (uint) {
    uint length = lockMap.length;
    bool[] memory indicesToRemove = new bool[](length);
    uint until;

    uint amountToRemove;
    for (uint index = 0; index < length; index++) {
      if (forced || lockMap.untils[index] <= block.timestamp) {
        amountToRemove = amount > lockMap.values[index] ? lockMap.values[index] : amount;
        amount -= amountToRemove;
        lockMap.values[index] -= amountToRemove;
        if (lockMap.untils[index] > until)
          until = lockMap.untils[index];
        if (lockMap.values[index] == 0)
          indicesToRemove[index] = true;
        if (amount == 0)
          break;
      }
    }

    require(amount == 0, "TokenLockMapHelper: INSUFFICIENT_UNLOCKABLE_BALANCE");

    uint lastIndex; 
    uint indexToRemove;
    for (uint index = length; index > 0; index--) {
      indexToRemove = index - 1;
      if (indicesToRemove[indexToRemove]) {
        lastIndex = lockMap.length - 1;
        if (indexToRemove != lastIndex) {
          lockMap.untils[indexToRemove] = lockMap.untils[lastIndex];
          lockMap.values[indexToRemove] = lockMap.values[lastIndex];
        }

        lockMap.untils.pop();
        lockMap.values.pop();
        lockMap.length--;
      }
    }
    validateTokens(lockMap);
    return until;
  }

  function validateTokens(LockMap storage lockMap) internal view {
    uint length = lockMap.length;

    uint expectedBalance = 0;
    for (uint index = 0; index < length; index++)
      expectedBalance += lockMap.values[index];

    uint balance = lockMap.id == address(0) ? address(this).balance : IERC20(lockMap.id).balanceOf(address(this));
    require(expectedBalance <= balance, "TokenLockMapHelper: BALANCE_MISMATCH");
  }

  function canUnlockTokens(LockMap storage lockMap, uint amount) internal view returns (bool) {
    uint length = lockMap.length;

    uint balance = 0;
    for (uint index = 0; index < length; index++)
      if (lockMap.untils[index] <= block.timestamp)
        balance += lockMap.values[index];

    return balance >= amount;
  }

  function balanceTokens(LockMap storage lockMap) internal view returns (uint) {
    uint length = lockMap.length;
    uint balance;

    for (uint index = 0; index < length; index++)
      balance += lockMap.values[index];

    return balance;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0;

library TransferHelper {
  function safeApprove(address token, address to, uint value) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
  }

  function safeTransfer(address token, address to, uint value) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
  }

  function safeTransferFrom(address token, address from, address to, uint value) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
  }

  function safeTransferETH(address to, uint value) internal {
    (bool success,) = to.call{value:value}(new bytes(0));
    require(success, "TransferHelper: TRANSFER_ETH_FAILED");
  }
}

// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

struct SwapLiquidityLocalVariables {
  uint amountA;
  uint amountB;
  uint until;
  uint addAmountBDesired;
}

// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

struct Vote {
  bytes data;
  uint quorom;
  uint accepts;
  uint rejects;
  mapping (address => bool) voted;
}

// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "../structs/Dependency.sol";

interface IVersion {
  function identifier() external pure returns (string memory);
  function version() external pure returns (uint);

  function dependencies() external view returns (Dependency[] memory);
  function updateDependencies(Dependency[] calldata dependencies_) external;

  function deployer() external view returns (address);

  function initialize(bytes calldata data) external;
}

// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

struct Dependency {
  string identifier;
  uint version;
}

// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "./Fees.sol";

struct Collaborations {
  uint length;
  address[] addresses;
  uint[] minBalances;
  Fees[] reductions;
}

// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

struct Shareholders {
  uint length;
  address[] addresses;
  uint[] shares;
  uint totalShares;
}

// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

struct Fees {
  uint lockETH;
  uint lockToken;
  uint lockERC721;
  uint swapLiquidity;
}

// lightweight version of @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

struct LockMap {
  bool initialized;
  address id;
  uint length;
  uint[] untils;
  uint[] values;
}

// lightweight version of @openzeppelin/contracts/token/ERC721/IERC721.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

interface IERC721 {
  function balanceOf(address owner) external view returns (uint256 balance);
  function ownerOf(uint256 tokenId) external view returns (address owner);
}

// lightweight version of @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
}