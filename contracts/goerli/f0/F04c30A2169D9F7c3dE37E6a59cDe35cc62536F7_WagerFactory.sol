// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/wagers/IWagerModule.sol";
import "../interfaces/IWagerRegistry.sol";

/**
 @title WagerFactory
 @author Henry Wrightman

 @notice factory contract for wager creation
 */

contract WagerFactory {
    struct WagerParameters {
        address partyOne;
        bytes partyOneWager;
        address partyTwo;
        bytes partyTwoWager;
        uint256 partyWagerAmount;
        uint80 expirationBlock;
        string moduleName;
        address aggregatorFeedAddr;
    }

    address public registry;

    constructor(address _registry) {
        registry = _registry;
    }

    mapping(string => address) private wagerModules;

    /// @notice createWager
    /// @dev name must be valid
    /// @param params wager params constructed from WagerParameters
    function createWager(
        WagerParameters memory params
    ) external payable returns (uint256) {
        address moduleAddr = wagerModules[params.moduleName];
        require(moduleAddr != address(0), "invalid wagerModule");
        Wager memory wager = Wager(
            params.partyOne,
            params.partyOneWager,
            params.partyTwo != address(0) ? params.partyTwo : address(0),
            params.partyTwoWager,
            params.partyWagerAmount,
            block.number,
            params.expirationBlock,
            WagerState.created,
            IWagerModule(moduleAddr),
            IWagerOracle(params.aggregatorFeedAddr)
        );

        return IWagerRegistry(registry).createWager{value: msg.value}(wager);
    }

    /// @notice setWagerModule
    /// @dev name must be valid
    /// @param name string name of the wager module's key
    /// @param wagerModuleAddr address wager module's contract address
    function setWagerModule(
        string memory name,
        address wagerModuleAddr
    ) external {
        wagerModules[name] = wagerModuleAddr;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./wagers/IWagerModule.sol";

interface IWagerRegistry {
    // -- events --
    event WagerCreated(
        address indexed partyAddr,
        uint256 indexed partyWagerAmount,
        bytes partyWager,
        uint256 createdBlock,
        uint256 expirationBlock,
        address wagerModule,
        uint256 wagerId
    );
    event WagerEntered(
        address indexed partyAddr,
        uint256 indexed partyWagerAmount,
        bytes partyWager,
        uint256 expirationBlock,
        address wagerModule,
        uint256 wagerId
    );
    event WagerCompleted(
        address indexed winner,
        uint256 indexed amount,
        uint256 indexed wagerId
    );
    event WagerWithdraw(
        address recipient,
        uint256 amount,
        uint256 indexed wagerId
    );
    event WagerVoided(uint256 indexed wagerId);

    // -- methods --
    function executeWinner(uint256 wagerId) external;

    function executeBlockRange(uint256 startBlock, uint256 endBlock) external;

    function enterWager(
        uint256 wagerId,
        bytes memory partyTwoWager
    ) external payable;

    function createWager(Wager memory wager) external payable returns (uint256);

    function voidWager(uint256 wagerId) external;

    function withdraw(uint256 wagerId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../wagers/IWagerModule.sol";

interface IWagerOracle {
    // -- methods --
    function getResult(Wager memory wager) external returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../oracles/IWagerOracle.sol";

// -- structs --
struct Wager {
    address partyOne;
    bytes partyOneWager;
    address partyTwo;
    bytes partyTwoWager;
    uint256 partyWagerAmount;
    uint256 createdBlock;
    uint80 expirationBlock;
    WagerState state;
    IWagerModule wagerModule; // wager semantics
    IWagerOracle oracleImpl; // oracle impl
}

// -- wager states
enum WagerState {
    active,
    created,
    completed,
    voided
}

interface IWagerModule {
    // -- methods --
    function calculateWinner(Wager memory wager) external returns (address);
}