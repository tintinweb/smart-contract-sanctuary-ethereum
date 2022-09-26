// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IInitializableAdminUpgradeabilityProxy} from './interfaces/IInitializableAdminUpgradeabilityProxy.sol';
import {IAaveGovernanceV2} from './interfaces/IAaveGovernanceV2.sol';
import {IOwnable} from './interfaces/IOwnable.sol';

/**
 * @title ProposalPayloadNewLongExecutor
 * @author BGD Labs
 * @dev Proposal to deploy a new LongExecutor and authorize it on the Aave Governance.
 * - Introduces a new voting delay aplied between proposal creation and voting.
 *   This delay is of 1 day in blocks (7200) taking into account 1 block per 12 sec (Ethereum merge proof)
 * - Moves all the permission held on the old long executor to the new one.
 * - Moves the permissions on ABPT and stkABPT to the ShortExecutor as they don't influence on the Aave Governance
 *   and they belong to Level 1.
 * - The old long executor is not de-authorized on the Aave Governance, in case there would be any permission left there.
 */
contract ProposalPayloadNewLongExecutor {
  IAaveGovernanceV2 constant AAVE_GOVERNANCE_V2 =
    IAaveGovernanceV2(0xEC568fffba86c094cf06b22134B23074DFE2252c);
  uint256 public constant VOTING_DELAY = 7200;
  address public constant SHORT_EXECUTOR =
    0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;
  address public immutable NEW_LONG_EXECUTOR;

  IInitializableAdminUpgradeabilityProxy constant AAVE_PROXY =
    IInitializableAdminUpgradeabilityProxy(
      0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9
    );
  IInitializableAdminUpgradeabilityProxy constant ABPT_PROXY =
    IInitializableAdminUpgradeabilityProxy(
      0x41A08648C3766F9F9d85598fF102a08f4ef84F84
    );
  IInitializableAdminUpgradeabilityProxy constant STK_AAVE_PROXY =
    IInitializableAdminUpgradeabilityProxy(
      0x4da27a545c0c5B758a6BA100e3a049001de870f5
    );
  IInitializableAdminUpgradeabilityProxy constant STK_ABPT_PROXY =
    IInitializableAdminUpgradeabilityProxy(
      0xa1116930326D21fB917d5A27F1E9943A9595fb47
    );

  constructor(address longExecutor) {
    NEW_LONG_EXECUTOR = longExecutor;
  }

  function execute() external {
    AAVE_GOVERNANCE_V2.setVotingDelay(VOTING_DELAY);

    address[] memory executorsToAuthorize = new address[](1);
    executorsToAuthorize[0] = NEW_LONG_EXECUTOR;
    AAVE_GOVERNANCE_V2.authorizeExecutors(executorsToAuthorize);

    IOwnable(address(AAVE_GOVERNANCE_V2)).transferOwnership(NEW_LONG_EXECUTOR);
    AAVE_PROXY.changeAdmin(NEW_LONG_EXECUTOR);
    STK_AAVE_PROXY.changeAdmin(NEW_LONG_EXECUTOR);

    ABPT_PROXY.changeAdmin(SHORT_EXECUTOR);
    STK_ABPT_PROXY.changeAdmin(SHORT_EXECUTOR);
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;


interface IAaveGovernanceV2 {
  struct ProposalWithoutVotes {
    uint256 id;
    address creator;
    address executor;
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] calldatas;
    bool[] withDelegatecalls;
    uint256 startBlock;
    uint256 endBlock;
    uint256 executionTime;
    uint256 forVotes;
    uint256 againstVotes;
    bool executed;
    bool canceled;
    address strategy;
    bytes32 ipfsHash;
  }

  /**
   * @dev Set new Voting Delay (delay before a newly created proposal can be voted on)
   * Note: owner should be a timelocked executor, so needs to make a proposal
   * @param votingDelay new voting delay in seconds
   **/
  function setVotingDelay(uint256 votingDelay) external;

  /**
   * @dev Add new addresses to the list of authorized executors
   * @param executors list of new addresses to be authorized executors
   **/
  function authorizeExecutors(address[] memory executors) external;

  /**
   * @dev Remove addresses to the list of authorized executors
   * @param executors list of addresses to be removed as authorized executors
   **/
  function unauthorizeExecutors(address[] memory executors) external;

  /**
   * @dev Getter of the current Voting Delay (delay before a created proposal can be voted on)
   * Different from the voting duration
   * @return The voting delay in seconds
   **/
  function getVotingDelay() external view returns (uint256);

  /**
   * @dev Returns whether an address is an authorized executor
   * @param executor address to evaluate as authorized executor
   * @return true if authorized
   **/
  function isExecutorAuthorized(address executor) external view returns (bool);

  /**
   * @dev Getter of the current GovernanceStrategy address
   * @return The address of the current GovernanceStrategy contracts
   **/
   function getGovernanceStrategy() external view returns (address);
  
   /**
   * @dev Getter of a proposal by id
   * @param proposalId id of the proposal to get
   * @return the proposal as ProposalWithoutVotes memory object
   **/
   function getProposalById(uint256 proposalId) external view returns (ProposalWithoutVotes memory);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOwnable {
  /**
   * @dev Returns the address of the current owner.
   */
  function owner() external view returns (address);

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) external;
}