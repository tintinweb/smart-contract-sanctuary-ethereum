// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "./interfaces/IContractDeployerV1.sol";
import "./interfaces/IFeeCollectorV1.sol";
import "./library/TransferHelper.sol";

contract FeeCollectorV1 is IFeeCollectorV1 {
  uint constant private UINT_MAX_VALUE = 2 ** 256 - 1;
  string constant private IDENTIFIER = "FeeCollector";
  uint constant private VERSION = 1;

  address private immutable _deployer;
  Dependency[] _dependencies;

  address private _contractDeployer;

  Shareholders private _shareholders;
  Collaborations private _collaborations;
  mapping(address => uint) private _partnerOf;
  mapping(address => bool) private _exemptOf;

  Fees private _fees;

  bool private _locked;

  constructor() {
    _deployer = msg.sender;
    _dependencies.push(Dependency("ContractDeployer", 1));
  }

  receive() external payable { TransferHelper.safeTransferETH(IContractDeployerV1(_contractDeployer).feeSetter(), msg.value); }
  fallback() external payable { TransferHelper.safeTransferETH(IContractDeployerV1(_contractDeployer).feeSetter(), msg.value); }

  modifier lock() {
    require(!_locked, "FeeCollector: reentrancy");
    _locked = true;
    _;
    _locked = false;
  }

  modifier onlyDeployer() {
    require(msg.sender == _deployer, "FeeCollector: caller must be the deployer");
    _;
  }

  function onlyFeeSetter() private view {
    require(msg.sender == IContractDeployerV1(_contractDeployer).feeSetter(), "FeeCollector: caller must be the feeSetter");
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
    address contractDeployer_ = addresses[0];

    _contractDeployer = contractDeployer_;
  }

  function contractDeployer() external view returns (address) {
    return _contractDeployer;
  }

  function shares() external view returns (Shareholders memory) {
    return _shareholders;
  }

  function setShares(address shareholder, uint share) external lock {
    onlyFeeSetter();
    for (uint index = 0; index < _shareholders.length; index++) {
      if (_shareholders.addresses[index] == shareholder) {
        uint currentShare = _shareholders.shares[index];
        if (share != currentShare) {
          if (share > currentShare)
            _shareholders.totalShares += share - currentShare;
          else
            _shareholders.totalShares -=  currentShare - share;
          _shareholders.shares[index] = share;
        }
        return;
      }
    }

    _shareholders.totalShares += share;
    _shareholders.addresses.push(shareholder);
    _shareholders.shares.push(share);
    _shareholders.length++;
  }

  function reductions() external view returns (Collaborations memory) {
    return _collaborations;
  }

  function setReductions(address collaboration, uint minBalance, Fees calldata reduction) external lock {
    onlyFeeSetter();
    require(minBalance > 0, "FeeCollector: minBalance must be greater than 0");
    require(reduction.lockETH <= 10000, "FeeCollector: reduction.lockETH can't exceed 100%");
    require(reduction.lockToken <= 10000, "FeeCollector: reduction.lockToken can't exceed 100%");
    require(reduction.lockERC721 <= 10000, "FeeCollector: reduction.lockERC721 can't exceed 100%");
    require(reduction.swapLiquidity <= 10000, "FeeCollector: reduction.swapLiquidity can't exceed 100%");
    for (uint index = 0; index < _collaborations.length; index++) {
      if (_collaborations.addresses[index] == collaboration) {
        _collaborations.minBalances[index] = minBalance;
        _collaborations.reductions[index] = reduction;
        return;
      }
    }

    _collaborations.addresses.push(collaboration);
    _collaborations.minBalances.push(minBalance);
    _collaborations.reductions.push(reduction);
    _collaborations.length++;
  }

  function partnerOf(address partner) external view returns (uint) {
    return _partnerOf[partner];
  }

  function setPartnerOf(address partner, uint fee) external lock {
    onlyFeeSetter();
    require(fee <= 10000, "FeeCollector: fee can't exceed 100%");
    _partnerOf[partner] = fee;
  }

  function exemptOf(address vaultOrSigner) external view returns (bool) {
    return _exemptOf[vaultOrSigner];
  }

  function setExemptOf(address vaultOrSigner, bool exempt) external lock {
    onlyFeeSetter();
    _exemptOf[vaultOrSigner] = exempt;
  }

  function lockETHFee() external view returns (uint) {
    return _fees.lockETH;
  }

  function lockETHFee(address vault, address signer) external view returns (uint) {
    return _exemptOf[vault] || _exemptOf[signer] ? 0 : _getReductedFees(vault, signer).lockETH;
  }

  function setLockETHFee(uint lockETHFee_) external lock {
    onlyFeeSetter();
    _fees.lockETH = lockETHFee_;
  }

  function lockTokenFee() external view returns (uint) {
    return _fees.lockToken;
  }

  function lockTokenFee(address vault, address signer) external view returns (uint) {
    return _exemptOf[vault] || _exemptOf[signer] ? 0 : _getReductedFees(vault, signer).lockToken;
  }

  function setLockTokenFee(uint lockTokenFee_) external lock {
    onlyFeeSetter();
    _fees.lockToken = lockTokenFee_;
  }

  function lockERC721Fee() external view returns (uint) {
    return _fees.lockERC721;
  }

  function lockERC721Fee(address vault, address signer) external view returns (uint) {
    return _exemptOf[vault] || _exemptOf[signer] ? 0 : _getReductedFees(vault, signer).lockERC721;
  }

  function setLockERC721Fee(uint lockERC721Fee_) external lock {
    onlyFeeSetter();
    _fees.lockERC721 = lockERC721Fee_;
  }

  function swapLiquidityFee() external view returns (uint) {
    return _fees.swapLiquidity;
  }

  function swapLiquidityFee(address vault, address signer) external view returns (uint) {
    return _exemptOf[vault] || _exemptOf[signer] ? 0 : _getReductedFees(vault, signer).swapLiquidity;
  }

  function setSwapLiquidityFee(uint swapLiquidityFee_) external lock {
    onlyFeeSetter();
    _fees.swapLiquidity = swapLiquidityFee_;
  }

  function fees() external view returns (Fees memory) {
    return _fees;
  }

  function fees(address vault, address signer) external view returns (Fees memory) {
    return _exemptOf[vault] || _exemptOf[signer] ? Fees(0, 0, 0, 0) : _getReductedFees(vault, signer);
  }

  function setFees(Fees calldata fees_) external lock {
    onlyFeeSetter();
    _fees = fees_;
  }

  function payFee(uint fee) external payable lock {
    require(msg.value >= fee, "FeeCollector: insufficient value provided");
    _payFee(fee);
  }

  function payFeeOnPartner(uint fee, address partner) external payable lock {
    require(msg.value >= fee, "FeeCollector: insufficient value provided");

    uint partnerFee = _partnerOf[partner];
    if (partnerFee > 0) {
      uint partnerFeeShare = fee * partnerFee / 10000;
      TransferHelper.safeTransferETH(partner, partnerFeeShare);
      fee -= partnerFeeShare;
    }

    _payFee(fee);
  }

  function _getReductedFees(address vault, address signer) private view returns (Fees memory) {
    if (_collaborations.length > 0) {
      bool hasReduction;
      Fees memory reductions_ = Fees(0, 0, 0, 0);

      for (uint index = 0; index < _collaborations.length; index++) {
        uint balance = _safeBalanceOf(_collaborations.addresses[index], vault) + _safeBalanceOf(_collaborations.addresses[index], signer);
        if (balance >= _collaborations.minBalances[index]) {
          Fees memory collaborationReduction = _collaborations.reductions[index];   
          hasReduction = true;
          reductions_ = Fees(
            collaborationReduction.lockETH > reductions_.lockETH ? collaborationReduction.lockETH : reductions_.lockETH,
            collaborationReduction.lockToken > reductions_.lockToken ? collaborationReduction.lockToken : reductions_.lockToken,
            collaborationReduction.lockERC721 > reductions_.lockERC721 ? collaborationReduction.lockERC721 : reductions_.lockERC721,
            collaborationReduction.swapLiquidity > reductions_.swapLiquidity ? collaborationReduction.swapLiquidity : reductions_.swapLiquidity
          );
        }
      }

      if (hasReduction)
        return Fees(
          _fees.lockETH * (10000 - reductions_.lockETH) / 10000,
          _fees.lockToken * (10000 - reductions_.lockToken) / 10000,
          _fees.lockERC721 * (10000 - reductions_.lockERC721) / 10000,
          _fees.swapLiquidity * (10000 - reductions_.swapLiquidity) / 10000
        );
    }

    return _fees;
  }

  function _payFee(uint fee) private {
    if (_shareholders.length > 0 && fee > 0) {
      for (uint index = 0; index < _shareholders.length; index++) {
        if (_shareholders.shares[index] > 0) {
          uint sharePercentage = (_shareholders.shares[index] * 10000) / _shareholders.totalShares;
          uint feeShare = fee * sharePercentage / 10000;
          TransferHelper.safeTransferETH(_shareholders.addresses[index], feeShare);
        }
      }
    }

    if (address(this).balance > 0)
      TransferHelper.safeTransferETH(IContractDeployerV1(_contractDeployer).feeSetter(), address(this).balance);
  }

  function _safeBalanceOf(address token, address owner) private view returns (uint) {
    if (token == address(0))
      return address(owner).balance;

    (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(0x70a08231, owner));
    return success ? abi.decode(data, (uint)) : 0;
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

import "./IVersion.sol";

interface IContractDeployerV1 is IVersion {
  function router() external view returns (address);
  function feeSetter() external view returns (address);

  function addressOf(string memory identifier_, uint version_) external view returns (address);
  function deploy(string memory identifier_, uint version_, bytes memory bytecode) external;
  function initialize(string memory identifier_, uint version_) external;
}