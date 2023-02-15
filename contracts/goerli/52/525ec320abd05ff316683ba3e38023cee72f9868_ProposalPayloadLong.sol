// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IInitializableAdminUpgradeabilityProxy } from "../contracts/interfaces/IInitializableAdminUpgradeabilityProxy.sol";

contract ProposalPayloadLong {
    address public immutable AAVE_MERKLE_DISTRIBUTOR;
    address public immutable AAVE_TOKEN_IMPL;
    address public immutable STK_AAVE_IMPL;

    address public constant LEND = 0x80fB784B7eD66730e8b1DBd9820aFD29931aab03;

    // tokens and amounts to rescue
    address public constant AAVE_TOKEN =
        0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    uint256 public constant AAVE_RESCUE_AMOUNT = 28420317154904044370842;
    address public constant USDT_TOKEN =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;
    uint256 public constant USDT_RESCUE_AMOUNT = 15631946764;
    address public constant UNI_TOKEN =
        0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    uint256 public constant UNI_RESCUE_AMOUNT = 110947986090000000000;

    // stk rescue
    uint256 public constant AAVE_STK_RESCUE_AMOUNT = 768271398516378775101;
    address public constant STK_AAVE_TOKEN =
        0x4da27a545c0c5B758a6BA100e3a049001de870f5;
    uint256 public constant STK_AAVE_RESCUE_AMOUNT = 107412975567454603565;

    uint256 public constant LEND_TO_AAVE_RESCUE_AMOUNT =
        19845132947543342156792;

    constructor(
        address aaveMerkleDistributor,
        address aaveTokenV2Impl,
        address stkAaveImpl
    ) public {
        AAVE_MERKLE_DISTRIBUTOR = aaveMerkleDistributor;
        AAVE_TOKEN_IMPL = aaveTokenV2Impl;
        STK_AAVE_IMPL = stkAaveImpl;
    }

    function execute() external {
        // initialization AAVE TOKEN params
        address[] memory tokens = new address[](3);
        tokens[0] = AAVE_TOKEN;
        tokens[1] = USDT_TOKEN;
        tokens[2] = UNI_TOKEN;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = AAVE_RESCUE_AMOUNT;
        amounts[1] = USDT_RESCUE_AMOUNT;
        amounts[2] = UNI_RESCUE_AMOUNT;

        // update AaveTokenV2 implementation with initializer params
        IInitializableAdminUpgradeabilityProxy aaveProxy = IInitializableAdminUpgradeabilityProxy(
                AAVE_TOKEN
            );
        aaveProxy.upgradeToAndCall(
            AAVE_TOKEN_IMPL,
            abi.encodeWithSignature(
                "initialize(address[],uint256[],address,address,uint256)",
                tokens,
                amounts,
                AAVE_MERKLE_DISTRIBUTOR,
                LEND,
                LEND_TO_AAVE_RESCUE_AMOUNT
            )
        );

        // initialization STKAAVE TOKEN params
        address[] memory tokensStk = new address[](2);
        tokensStk[0] = AAVE_TOKEN;
        tokensStk[1] = STK_AAVE_TOKEN;

        uint256[] memory amountsStk = new uint256[](2);
        amountsStk[0] = AAVE_STK_RESCUE_AMOUNT;
        amountsStk[1] = STK_AAVE_RESCUE_AMOUNT;

        // update StakedTokenV2Rev4 implementation with initializer params
        IInitializableAdminUpgradeabilityProxy proxyStake = IInitializableAdminUpgradeabilityProxy(
                STK_AAVE_TOKEN
            );
        proxyStake.upgradeToAndCall(
            STK_AAVE_IMPL,
            abi.encodeWithSignature(
                "initialize(address[],uint256[],address)",
                tokensStk,
                amountsStk,
                AAVE_MERKLE_DISTRIBUTOR
            )
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.0 <0.9.0;


interface IInitializableAdminUpgradeabilityProxy {
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
    function admin() external returns (address);
    function REVISION() external returns (uint256);
    function changeAdmin(address newAdmin) external;
}