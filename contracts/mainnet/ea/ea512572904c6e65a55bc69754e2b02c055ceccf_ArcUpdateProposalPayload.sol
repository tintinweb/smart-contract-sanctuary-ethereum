// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import { IArcTimelock } from  "./interfaces/IArcTimelock.sol";
import { IEcosystemReserveController } from "./interfaces/IEcosystemReserveController.sol";
import { ILendingPoolConfigurator } from "./interfaces/ILendingPoolConfigurator.sol";

/// @title ArcUpdateProposalPayload
/// @author Governance House
/// @notice Aave ARC parameter update proposal
contract ArcUpdateProposalPayload {

    /// @notice AAVE ARC LendingPoolConfigurator
    ILendingPoolConfigurator constant configurator = ILendingPoolConfigurator(0x4e1c7865e7BE78A7748724Fa0409e88dc14E67aA);

    /// @notice AAVE ARC timelock
    IArcTimelock constant arcTimelock = IArcTimelock(0xAce1d11d836cb3F51Ef658FD4D353fFb3c301218);

    /// @notice AAVE Ecosystem Reserve Controller
    IEcosystemReserveController constant reserveController = IEcosystemReserveController(0x3d569673dAa0575c936c7c67c4E6AedA69CC630C);

    /// @notice AAVE Ecosystem Reserve
    address constant reserve = 0x25F2226B597E8F9514B3F68F00f494cF4f286491;

    /// @notice Governance House Multisig
    address constant govHouse = 0x82cD339Fa7d6f22242B31d5f7ea37c1B721dB9C3;

    /// @notice usdc token
    address constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    /// @notice weth token
    address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @notice wbtc token
    address constant wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    /// @notice aave token
    address constant aave = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

    /// @notice address of current contract
    address immutable self;

    constructor() {
        self = address(this);
    }
    
    /// @notice The AAVE governance contract calls this to queue up an
    /// @notice action to the AAVE ARC timelock
    function executeQueueTimelock() external {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        string[] memory signatures = new string[](1);
        bytes[] memory calldatas = new bytes[](1);
        bool[] memory withDelegatecalls = new bool[](1);

        targets[0] = self;
        signatures[0] = "execute()";
        withDelegatecalls[0] = true;

        arcTimelock.queue(targets, values, signatures, calldatas, withDelegatecalls);

        // reimburse gas costs from ecosystem reserve
        reserveController.transfer(reserve, aave, govHouse, 15 ether);
    }

    /// @notice The AAVE ARC timelock delegateCalls this
    function execute() external {
        // address, ltv, liqthresh, bonus
        configurator.configureReserveAsCollateral(usdc, 8550, 8800, 10450);
        configurator.configureReserveAsCollateral(weth, 8250, 8500, 10500);
        configurator.configureReserveAsCollateral(wbtc, 7000, 7500, 10650);
        configurator.configureReserveAsCollateral(aave, 6250, 7000, 10750);
    }
}

pragma solidity 0.8.10;

interface IArcTimelock {
    function queue(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        bool[] memory withDelegatecalls
    ) external;

    function getActionsSetCount() external returns (uint256);
    
    function execute(uint256) external payable;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.4.22 <0.9.0;

interface IEcosystemReserveController {
    function transfer(address collector, address token, address guy, uint256 wad) external;
}

pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;

interface ILendingPoolConfigurator {

    function configureReserveAsCollateral(
        address asset,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus
    ) external;

    function setReserveFactor(address asset, uint256 reserveFactor) external;
}