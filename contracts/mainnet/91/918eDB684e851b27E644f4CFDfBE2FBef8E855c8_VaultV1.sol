// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "./interfaces/lightweight/IERC20.sol";
import "./interfaces/IFeeCollectorV1.sol";
import "./interfaces/ISignerVaultV1.sol";
import "./interfaces/ISignerVaultFactoryV1.sol";
import "./interfaces/IVaultV1.sol";
import "./library/TransferHelper.sol";

contract VaultV1 is IVaultV1 {
  uint constant private UINT_MAX_VALUE = 2 ** 256 - 1;
  string constant private IDENTIFIER = "Vault";
  uint constant private VERSION = 1;

  address private immutable _deployer;
  Dependency[] _dependencies;

  address private _signerVaultFactory;
  address private _feeCollector;

  bool private _locked;

  constructor() {
    _deployer = msg.sender;
    _dependencies.push(Dependency("SignerVaultFactory", 1));
    _dependencies.push(Dependency("FeeCollector", 1));
  }

  receive() external payable { TransferHelper.safeTransferETH(_feeCollector, msg.value); }
  fallback() external payable { TransferHelper.safeTransferETH(_feeCollector, msg.value); }

  modifier lock() {
    require(!_locked, "Vault: reentrancy");
    _locked = true;
    _;
    _locked = false;
  }

  modifier onlyDeployer() {
    require(msg.sender == _deployer, "Vault: caller must be the deployer");
    _;
  }

  function ensureVault(address vault) private view {
    require(ISignerVaultFactoryV1(_signerVaultFactory).contains(vault), "Vault: unknown vault");
    require(ISignerVaultV1(vault).signer(msg.sender), "Vault: caller must be a signer of the vault");
  }

  function ensureFee(uint fee) private {
    require(msg.value >= fee, "SignerVault: insufficient value");
    if (fee > 0)
      IFeeCollectorV1(_feeCollector).payFee{ value: fee }(fee);
    if (msg.value > fee) 
      TransferHelper.safeTransferETH(msg.sender, msg.value - fee);
  }

  function ensureFeeOnPartner(uint fee, address partner) private {
    require(msg.value >= fee, "SignerVault: insufficient value");
    if (fee > 0)
      IFeeCollectorV1(_feeCollector).payFeeOnPartner{ value: fee }(fee, partner);
    if (msg.value > fee) 
      TransferHelper.safeTransferETH(msg.sender, msg.value - fee);
  }

  function ensureAmountAndFee(uint amount, uint fee) private {
    require(msg.value >= amount + fee, "SignerVault: insufficient value");
    if (fee > 0)
      IFeeCollectorV1(_feeCollector).payFee{ value: fee }(fee);
    if (msg.value > amount + fee) 
      TransferHelper.safeTransferETH(msg.sender, msg.value - amount - fee);
  }

  function ensureAmountAndFeeOnPartner(uint amount, uint fee, address partner) private {
    require(msg.value >= amount + fee, "SignerVault: insufficient value");
    if (fee > 0)
      IFeeCollectorV1(_feeCollector).payFeeOnPartner{ value: fee }(fee, partner);
    if (msg.value > amount + fee) 
      TransferHelper.safeTransferETH(msg.sender, msg.value - amount - fee);
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

  function initialize(bytes calldata data) external onlyDeployer {
    address[] memory addresses = abi.decode(data, (address[]));
    address signerVaultFactory_ = addresses[0];
    address feeCollector_ = addresses[1];

    _signerVaultFactory = signerVaultFactory_;
    _feeCollector = feeCollector_;
  }

  function signerVaultFactory() external view returns (address) {
    return _signerVaultFactory;
  }

  function feeCollector() external view returns (address) {
    return _feeCollector;
  }

  function partnerOf(address partner) external view returns (uint) { return IFeeCollectorV1(_feeCollector).partnerOf(partner); }

  function fees() external view returns (Fees memory) { return IFeeCollectorV1(_feeCollector).fees(); }
  function fees(address signerVault) external view returns (Fees memory) { return IFeeCollectorV1(_feeCollector).fees(signerVault, msg.sender); }

  function vaults() external view returns (address[] memory) { return ISignerVaultFactoryV1(_signerVaultFactory).vaultsOf(msg.sender); }
  function vaultsLength() external view returns (uint) { return ISignerVaultFactoryV1(_signerVaultFactory).vaultsLengthOf(msg.sender); }
  function getVault(uint index) external view returns (address) { return ISignerVaultFactoryV1(_signerVaultFactory).getVaultOf(msg.sender, index); }

  function createVault() external lock returns (address) { return ISignerVaultFactoryV1(_signerVaultFactory).createVault(msg.sender); }

  function vote(address vault) external view returns (bytes memory data, uint quorom, uint accepts, uint rejects, bool voted) { (data, quorom, accepts, rejects, voted) = ISignerVaultV1(vault).vote(msg.sender); }
  function castVote(address vault, bool accept) external lock { ensureVault(vault); ISignerVaultV1(vault).castVote(accept, msg.sender); }

  function addSigner(address vault, address nominee) external lock { ensureVault(vault); ISignerVaultV1(vault).addSigner(nominee, msg.sender); }
  function removeSigner(address vault, address nominee) external lock { ensureVault(vault); ISignerVaultV1(vault).removeSigner(nominee, msg.sender); }

  function lockMapETH(address vault) external view returns (LockMap memory) { return ISignerVaultV1(vault).lockMapETH(); }
  function claimETH(address vault) external lock { ensureVault(vault); ISignerVaultV1(vault).claimETH(msg.sender); }
  function claimETH(address vault, address recipient) external lock { ensureVault(vault); ISignerVaultV1(vault).claimETH(recipient); }
  function unlockETH(address vault, uint amount) external lock { ensureVault(vault); ISignerVaultV1(vault).unlockETH(amount, msg.sender, msg.sender); }
  function unlockETH(address vault, uint amount, address recipient) external lock { ensureVault(vault); ISignerVaultV1(vault).unlockETH(amount, recipient, msg.sender); }
  function lockETH(address vault, uint amount, uint until) external payable { _lockETH(vault, amount, until, false, address(0)); }
  function lockETHOnPartner(address vault, uint amount, uint until, address partner) external payable { _lockETH(vault, amount, until, true, partner); }
  function lockETHPermanently(address vault, uint amount) external payable { _lockETH(vault, amount, UINT_MAX_VALUE, false, address(0)); }
  function lockETHPermanentlyOnPartner(address vault, uint amount, address partner) external payable { _lockETH(vault, amount, UINT_MAX_VALUE, true, partner); }

  function lockMapToken(address vault, address token) external view returns (LockMap memory) { return ISignerVaultV1(vault).lockMapToken(token); }
  function claimToken(address vault, address token) external lock { ensureVault(vault); ISignerVaultV1(vault).claimToken(token, msg.sender); }
  function claimToken(address vault, address token, address recipient) external lock { ensureVault(vault); ISignerVaultV1(vault).claimToken(token, recipient); }
  function unlockToken(address vault, address token, uint amount) external lock { ensureVault(vault); ISignerVaultV1(vault).unlockToken(token, amount, msg.sender, msg.sender); }
  function unlockToken(address vault, address token, uint amount, address recipient) external lock { ensureVault(vault); ISignerVaultV1(vault).unlockToken(token, amount, recipient, msg.sender); }
  function lockToken(address vault, address token, uint amount, uint until) external payable { _lockToken(vault, token, amount, until, false, address(0)); }
  function lockTokenOnPartner(address vault, address token, uint amount, uint until, address partner) external payable { _lockToken(vault, token, amount, until, true, partner); }
  function lockTokenPermanently(address vault, address token, uint amount) external payable { _lockToken(vault, token, amount, UINT_MAX_VALUE, false, address(0)); }
  function lockTokenPermanentlyOnPartner(address vault, address token, uint amount, address partner) external payable { _lockToken(vault, token, amount, UINT_MAX_VALUE, true, partner); }

  function lockMapERC721(address vault, address erc721) external view returns (LockMap memory) { return ISignerVaultV1(vault).lockMapERC721(erc721); }
  function claimERC721(address vault, address erc721, uint tokenId) external lock { ensureVault(vault); ISignerVaultV1(vault).claimERC721(erc721, tokenId, msg.sender); }
  function claimERC721(address vault, address erc721, uint tokenId, address recipient) external lock { ensureVault(vault); ISignerVaultV1(vault).claimERC721(erc721, tokenId, recipient); }
  function unlockERC721(address vault, address erc721, uint tokenId) external lock { ensureVault(vault); ISignerVaultV1(vault).unlockERC721(erc721, tokenId, msg.sender, msg.sender); }
  function unlockERC721(address vault, address erc721, uint tokenId, address recipient) external lock { ensureVault(vault); ISignerVaultV1(vault).unlockERC721(erc721, tokenId, recipient, msg.sender); }
  function lockERC721(address vault, address erc721, uint tokenId, uint until) external payable { _lockERC721(vault, erc721, tokenId, until, false, address(0)); }
  function lockERC721OnPartner(address vault, address erc721, uint tokenId, uint until, address partner) external payable { _lockERC721(vault, erc721, tokenId, until, true, partner); }
  function lockERC721Permanently(address vault, address erc721, uint tokenId) external payable { _lockERC721(vault, erc721, tokenId, UINT_MAX_VALUE, false, address(0)); }
  function lockERC721PermanentlyOnPartner(address vault, address erc721, uint tokenId, address partner) external payable { _lockERC721(vault, erc721, tokenId, UINT_MAX_VALUE, true, partner); }

  function swapLiquidity(address vault, address token, uint removeLiquidity, address[] calldata swapPath, uint deadline) external payable  { _swapLiquidity(vault, token, removeLiquidity, 0, 0, 0, swapPath, 0, 0, deadline, false, address(0)); }
  function swapLiquidityOnPartner(address vault, address token, uint removeLiquidity, address[] calldata swapPath, uint deadline, address partner) external payable  { _swapLiquidity(vault, token, removeLiquidity, 0, 0, 0, swapPath, 0, 0, deadline, true, partner); }
  function swapLiquidity(address vault, address token, uint removeLiquidity, uint swapAmountOutMin, address[] calldata swapPath, uint deadline) external payable  { _swapLiquidity(vault, token, removeLiquidity, 0, 0, swapAmountOutMin, swapPath, 0, 0, deadline, false, address(0)); }
  function swapLiquidityOnPartner(address vault, address token, uint removeLiquidity, uint swapAmountOutMin, address[] calldata swapPath, uint deadline, address partner) external payable  { _swapLiquidity(vault, token, removeLiquidity, 0, 0, swapAmountOutMin, swapPath, 0, 0, deadline, true, partner); }
  function swapLiquidity(address vault, address token, uint removeLiquidity, uint removeAmountAMin, uint removeAmountBMin, uint swapAmountOutMin, address[] calldata swapPath, uint addAmountAMin, uint addAmountBMin, uint deadline) external payable { _swapLiquidity(vault, token, removeLiquidity, removeAmountAMin, removeAmountBMin, swapAmountOutMin, swapPath, addAmountAMin, addAmountBMin, deadline, false, address(0)); }
  function swapLiquidityOnPartner(address vault, address token, uint removeLiquidity, uint removeAmountAMin, uint removeAmountBMin, uint swapAmountOutMin, address[] calldata swapPath, uint addAmountAMin, uint addAmountBMin, uint deadline, address partner) external payable { _swapLiquidity(vault, token, removeLiquidity, removeAmountAMin, removeAmountBMin, swapAmountOutMin, swapPath, addAmountAMin, addAmountBMin, deadline, true, partner); }

  function _lockETH(address vault, uint amount, uint until, bool onPartner, address partner) private lock {
    ensureVault(vault);

    if (onPartner)
      ensureAmountAndFeeOnPartner(amount, IFeeCollectorV1(_feeCollector).lockETHFee(vault, msg.sender), partner);
    else
      ensureAmountAndFee(amount, IFeeCollectorV1(_feeCollector).lockETHFee(vault, msg.sender));

    ISignerVaultV1(vault).lockETH{value:amount}(amount, until);
  }

  function _lockToken(address vault, address token, uint amount, uint until, bool onPartner, address partner) private lock {
    ensureVault(vault);

    if (onPartner)
      ensureFeeOnPartner(IFeeCollectorV1(_feeCollector).lockTokenFee(vault, msg.sender), partner);
    else
      ensureFee(IFeeCollectorV1(_feeCollector).lockTokenFee(vault, msg.sender));

    uint balanceBefore = IERC20(token).balanceOf(vault);
    TransferHelper.safeTransferFrom(token, msg.sender, vault, amount);
    amount = IERC20(token).balanceOf(vault) - balanceBefore;

    ISignerVaultV1(vault).lockToken(token, amount, until);
  }

  function _lockERC721(address vault, address erc721, uint tokenId, uint until, bool onPartner, address partner) private lock {
    ensureVault(vault);

    if (onPartner)
      ensureFeeOnPartner(IFeeCollectorV1(_feeCollector).lockERC721Fee(vault, msg.sender), partner);
    else
      ensureFee(IFeeCollectorV1(_feeCollector).lockERC721Fee(vault, msg.sender));

    TransferHelper.safeTransferFrom(erc721, msg.sender, vault, tokenId);

    ISignerVaultV1(vault).lockERC721(erc721, tokenId, until);
  }

  function _swapLiquidity(address vault, address token, uint removeLiquidity, uint removeAmountAMin, uint removeAmountBMin, uint swapAmountOutMin, address[] calldata swapPath, uint addAmountAMin, uint addAmountBMin, uint deadline, bool onPartner, address partner) private lock {
    ensureVault(vault);

    if (onPartner)
      ensureFeeOnPartner(IFeeCollectorV1(_feeCollector).lockERC721Fee(vault, msg.sender), partner);
    else
      ensureFee(IFeeCollectorV1(_feeCollector).swapLiquidityFee(vault, msg.sender));

    ISignerVaultV1(vault).swapLiquidity(token, removeLiquidity, removeAmountAMin, removeAmountBMin, swapAmountOutMin, swapPath, addAmountAMin, addAmountBMin, deadline);
  }
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

struct LockMap {
  bool initialized;
  address id;
  uint length;
  uint[] untils;
  uint[] values;
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

// lightweight version of @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
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

import "./IVersion.sol";
import "../structs/Fees.sol";
import "../structs/LockMap.sol";

interface IVaultV1 is IVersion {
  function signerVaultFactory() external view returns (address);
  function feeCollector() external view returns (address);

  function partnerOf(address partner) external view returns (uint);

  function fees() external view returns (Fees memory);
  function fees(address vault) external view returns (Fees memory);

  function vaults() external view returns (address[] memory);
  function vaultsLength() external view returns (uint);
  function getVault(uint index) external view returns (address);

  function createVault() external returns (address);

  function vote(address vault) external view returns (bytes memory data, uint quorom, uint accepts, uint rejects, bool voted);
  function castVote(address vault, bool accept) external;

  function addSigner(address vault, address nominee) external;
  function removeSigner(address vault, address nominee) external;

  function lockMapETH(address vault) external view returns (LockMap memory);
  function claimETH(address vault) external;
  function claimETH(address vault, address recipient) external;
  function unlockETH(address vault, uint amount) external;
  function unlockETH(address vault, uint amount, address recipient) external;
  function lockETH(address vault, uint amount, uint until) external payable;
  function lockETHOnPartner(address vault, uint amount, uint until, address partner) external payable;
  function lockETHPermanently(address vault, uint amount) external payable;
  function lockETHPermanentlyOnPartner(address vault, uint amount, address partner) external payable;

  function lockMapToken(address vault, address token) external view returns (LockMap memory);
  function claimToken(address vault, address token) external;
  function claimToken(address vault, address token, address recipient) external;
  function unlockToken(address vault, address token, uint amount) external;
  function unlockToken(address vault, address token, uint amount, address recipient) external;
  function lockToken(address vault, address token, uint amount, uint until) external payable;
  function lockTokenOnPartner(address vault, address token, uint amount, uint until, address partner) external payable;
  function lockTokenPermanently(address vault, address token, uint amount) external payable;
  function lockTokenPermanentlyOnPartner(address vault, address token, uint amount, address partner) external payable;

  function lockMapERC721(address vault, address erc721) external view returns (LockMap memory);
  function claimERC721(address vault, address erc721, uint tokenId) external;
  function claimERC721(address vault, address erc721, uint tokenId, address recipient) external;
  function unlockERC721(address vault, address erc721, uint tokenId) external;
  function unlockERC721(address vault, address erc721, uint tokenId, address recipient) external;
  function lockERC721(address vault, address erc721, uint tokenId, uint until) external payable;
  function lockERC721OnPartner(address vault, address erc721, uint tokenId, uint until, address partner) external payable;
  function lockERC721Permanently(address vault, address erc721, uint tokenId) external payable;
  function lockERC721PermanentlyOnPartner(address vault, address erc721, uint tokenId, address partner) external payable;

  function swapLiquidity(address vault, address token, uint removeLiquidity, address[] calldata swapPath, uint deadline) external payable;
  function swapLiquidityOnPartner(address vault, address token, uint removeLiquidity, address[] calldata swapPath, uint deadline, address partner) external payable;
  function swapLiquidity(address vault, address token, uint removeLiquidity, uint swapAmountOutMin, address[] calldata swapPath, uint deadline) external payable;
  function swapLiquidityOnPartner(address vault, address token, uint removeLiquidity, uint swapAmountOutMin, address[] calldata swapPath, uint deadline, address partner) external payable;
  function swapLiquidity(address vault, address token, uint removeLiquidity, uint removeAmountAMin, uint removeAmountBMin, uint swapAmountOutMin, address[] calldata swapPath, uint addAmountAMin, uint addAmountBMin, uint deadline) external payable;
  function swapLiquidityOnPartner(address vault, address token, uint removeLiquidity, uint removeAmountAMin, uint removeAmountBMin, uint swapAmountOutMin, address[] calldata swapPath, uint addAmountAMin, uint addAmountBMin, uint deadline, address partner) external payable;
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