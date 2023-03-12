/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ISplitMain {
  event DistributeETH(address indexed split, uint256 grossAmount, address indexed distributorAddress);
  event DistributeERC20(address indexed split, address indexed token, uint256 amount, address indexed distributorAddress);

  function getController(address split) external view returns (address);
  function getNewPotentialController(address split) external view returns (address);
  function getETHBalance(address account) external view returns (uint256);
  function getERC20Balance(address account, address token) external view returns (uint256);
  function createSplit(
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address controller
  ) external returns (address);
  function updateAndDistributeETH(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;
  function updateAndDistributeERC20(
    address split,
    address token,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;
  function updateSplit(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee
  ) external;
  function makeSplitImmutable(address split) external;
  function transferControl(address split, address newController) external;
  function acceptControl(address split) external;
  function initiateControlTransfer(address split, address newPotentialController) external;
  function cancelControlTransfer(address split) external;
  function withdraw(address account, uint256 withdrawETH, address[] calldata tokens) external;
}

interface ISplitFactory {
  function createSplitMain(address walletImplementation) external returns (address);
  function walletImplementation() external view returns (address);
}

contract SplitChecker {
  ISplitFactory public immutable splitFactory;
  mapping(address => bool) public isSplitMain;

  constructor(ISplitFactory _splitFactory) {
    splitFactory = _splitFactory;
  }

  function check(address split) external view returns (bool) {
    return isSplitMain[split];
  }

  function createSplit(
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address controller
  ) external payable returns (address) {
    address splitMain = splitFactory.createSplitMain(address(this));
    isSplitMain[splitMain] = true;
    ISplitMain(splitMain).createSplit(accounts, percentAllocations, distributorFee, controller);
    if (msg.value > 0) {
      ISplitMain(splitMain).updateAndDistributeETH(
        splitMain,
        accounts,
        percentAllocations,
        distributorFee,
        address(0)
      );
    }
    return splitMain;
  }

  function updateAndDistributeETH(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external payable {
    ISplitMain(split).updateAndDistributeETH(
      split,
      accounts,
      percentAllocations,
      distributorFee,
      distributorAddress
    );
  }
}