/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

interface IAaveEcosystemReserveController {
    function approve(
        address collector,
        IERC20 token,
        address recipient,
        uint256 amount
    ) external;
}


interface IProposalGenericExecutor {
    function execute() external;
}

contract AllowanceRenewalSMPayload is IProposalGenericExecutor {
    IERC20 public constant AAVE =
        IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);

    address public constant STKAAVE =
        0x4da27a545c0c5B758a6BA100e3a049001de870f5;
    address public constant STKABPT =
        0xa1116930326D21fB917d5A27F1E9943A9595fb47;
    IAaveEcosystemReserveController
        public constant ECOSYSTEM_RESERVE_CONTROLLER =
        IAaveEcosystemReserveController(
            0x3d569673dAa0575c936c7c67c4E6AedA69CC630C
        );
    address public constant ECOSYSTEM_RESERVE =
        0x25F2226B597E8F9514B3F68F00f494cF4f286491;

    function execute() external override {
        // For requirement of the controller, first we reset allowance
        ECOSYSTEM_RESERVE_CONTROLLER.approve(
            ECOSYSTEM_RESERVE,
            AAVE,
            STKAAVE,
            0
        );
        ECOSYSTEM_RESERVE_CONTROLLER.approve(
            ECOSYSTEM_RESERVE,
            AAVE,
            STKABPT,
            0
        );

        ECOSYSTEM_RESERVE_CONTROLLER.approve(
            ECOSYSTEM_RESERVE,
            AAVE,
            STKAAVE,
            401_500 ether
        );

        ECOSYSTEM_RESERVE_CONTROLLER.approve(
            ECOSYSTEM_RESERVE,
            AAVE,
            STKABPT,
            401_500 ether
        );
    }
}