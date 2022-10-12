// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "./external/aave/IStaticATokenLM.sol";
import "./external/aave/IAaveIncentivesController.sol";

/**
 * @title StkAaveRetrieval
 * @author Llama
 * @notice This contract is used to claim stkAave rewards on behalf of the Balancer DAO contract
 * @notice It sends those funds to the Balancer Multisig
 * @notice Aave proposal to whitelist this contract:
 * @notice https://governance.aave.com/t/arc-whitelist-balancer-s-liquidity-mining-claim/9724
 * @dev The Balancer Multisig should call retrieve()
 */
contract StkAaveRetrieval {
    /// @dev this is msg.sender
    address public constant BALANCER_MULTISIG = 0x10A19e7eE7d7F8a52822f6817de8ea18204F2e4f;

    /// @dev this is the address we're claiming on behalf of
    address public constant BALANCER_DAO = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    /// @dev this is the address of the Aave Incentives Controller, which manages and stores the claimers
    address public constant INCENTIVES_CONTROLLER = 0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;

    /// @dev these are the tokens which have accrued LM rewards
    address public constant WRAPPED_ADAI = 0x02d60b84491589974263d922D9cC7a3152618Ef6;
    address public constant WRAPPED_AUSDC = 0xd093fA4Fb80D09bB30817FDcd442d4d02eD3E5de;
    address public constant WRAPPED_AUSDT = 0xf8Fd466F12e236f4c96F7Cce6c79EAdB819abF58;
    address[] public WRAPPED_TOKENS = [WRAPPED_ADAI, WRAPPED_AUSDC, WRAPPED_AUSDT];

    /**
     * @dev This is the core function. We check that only the multisig can execute this and that proper whitelisting has been set up.
     * @notice We call this function to claim the rewards and send them to the multisig
     */
    function retrieve() external {
        require(msg.sender == BALANCER_MULTISIG, "Only Balancer Multisig");
        require(
            IAaveIncentivesController(INCENTIVES_CONTROLLER).getClaimer(BALANCER_DAO) == address(this),
            "Contract not set as claimer"
        );
        for (uint256 i = 0; i < WRAPPED_TOKENS.length; i++) {
            IStaticATokenLM(WRAPPED_TOKENS[i]).claimRewardsOnBehalf(BALANCER_DAO, BALANCER_MULTISIG, true);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

// relevant functions from https://etherscan.io/address/0x1dc16f168b0a2bb3fbda0fe1a1787f8b22c0aed8#code

interface IStaticATokenLM {
    /**
     * @notice Claim rewards on behalf of a user and send them to a receiver
     * @dev Only callable by if sender is onBehalfOf or sender is approved claimer
     * @param onBehalfOf The address to claim on behalf of
     * @param receiver The address to receive the rewards
     * @param forceUpdate Flag to retrieve latest rewards from `INCENTIVES_CONTROLLER`
     */
    function claimRewardsOnBehalf(
        address onBehalfOf,
        address receiver,
        bool forceUpdate
    ) external;

    /**
     * @notice The unclaimed rewards for a user in WAD
     * @param user The address of the user
     * @return The unclaimed amount of rewards in WAD
     */
    function getUnclaimedRewards(address user) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

// relevant function from https://etherscan.io/address/0xd9ed413bcf58c266f95fe6ba63b13cf79299ce31#code

interface IAaveIncentivesController {
    /**
     * @dev Whitelists an address to claim the rewards on behalf of another address
     * @param user The address of the user
     * @param claimer The address of the claimer
     */
    function setClaimer(address user, address claimer) external;

    /**
     * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
     * @param user The address of the user
     * @return The claimer address
     */
    function getClaimer(address user) external view returns (address);
}