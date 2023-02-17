// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

// Chainlink Automation
import { AutomationCompatibleInterface } from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

// Local
import { IVestedAlloc } from "../interfaces/IVestedAlloc.sol";

/**************************************

    Team Allocation Unlock contract

    ------------------------------

    This contract is deployed and prepared for Chainlink Automation (https://automation.chain.link)
    to track Vested Allocation smart contract and trigger unlocking Team Reserve when Tholos will reach 1 USDT price.

**************************************/

contract TeamAllocUnlock is AutomationCompatibleInterface {

    // constants
    uint8 constant public TEAM_PRICE_RELEASE_NO = 0;
    uint32 constant public ONE_USDT = 1000000;

    // contracts
    IVestedAlloc public vestedAlloc;

    // storage
    bool public allocUnlocked = false;

    /**************************************

        Constructor

    **************************************/

    constructor (address _vestedAllocAddress) {

        // storage
        vestedAlloc = IVestedAlloc(_vestedAllocAddress);

    }

    /**************************************

        Check upkeep

    **************************************/

    function checkUpkeep(bytes calldata _bytes) public view
    returns (bool, bytes memory) {

        // exit if already unlocked
        if (allocUnlocked == true) {
            return (false, _bytes);
        }

        // return
        return (isTholToUsdtOne(), _bytes);

    }

    /**************************************

        Perform upkeep

    **************************************/

    function performUpkeep(bytes calldata) external override {

        // revalidate check upkeep
        if (allocUnlocked == false && isTholToUsdtOne()) {

            // unlock
            vestedAlloc.unlockReserve(IVestedAlloc.ReserveType.TEAM, TEAM_PRICE_RELEASE_NO);

            // set storage
            allocUnlocked = true;

        }

    }

    /**************************************

        Is price equal 1 USDT

    **************************************/

    function isTholToUsdtOne() public view
    returns (bool) {

        // return
        return vestedAlloc.tholToUsdt() >= ONE_USDT;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

/**************************************

    Vested Allocation interface

 **************************************/

abstract contract IVestedAlloc {

    // enums
    enum ReserveType {
        PRESALE_PRIVATE, // populate + claim
        PRESALE_COMMUNITY, // fetch + claim
        AIRDROP, // fetch + claim
        STAKING, // forward -> pool
        DEX, // forward -> admin
        TREASURY, // forward -> pool
        TEAM, // populate + claim
        ADVISORS, // populate + claim
        PARTNERS // populate + claim || forward -> treasury
    }
    enum ReleaseType {
        TIMESTAMP,
        PRICE
    }

    // structs: low level
    struct Release {
        ReleaseType releaseType;
        uint256 requirement; // @dev value based on release type (timestamp or price)
        uint256 amount;
    }
    struct Recipient {
        address owner;
        uint256 share;
    }

    // structs: containers
    struct Allocation {
        uint256 totalReserve;
        Release[] releases;
    }

    // structs: requests
    struct AllocationRequest {
        ReserveType reserveType;
        Allocation allocation;
    }

    struct Shareholder {
        uint256 shares; // applies to all shareholders
        uint256 claimed; // applies to shareholders who already claimed some tokens
        bool isCompromised; // applies to shareholders with team vesting
    }
    
    // structs: storage
    struct VestedReserve {
        Allocation allocation;
        mapping (address => Shareholder) shareholders;
        mapping (uint8 => bool) unlocked; // @dev Used to track price-based ReleaseType
    }

    // events
    event RecipientsAdded(ReserveType reserveType, Recipient[] recipients);
    event DexPoolSet(address sender, address[2] poolPath, address[3] tokenPath);
    event Forwarded(ReserveType reserveType, address forwarder, address shareholder, uint256 amount);
    event Claimed(ReserveType reserveType, address shareholder, uint256 amount);
    event Safeguarded(address forwarder, address shareholder, uint256 amount);
    event ShareholderCompromised(address shareholder);

    // errors
    error InvalidAllocation(AllocationRequest[9] allocation); // FIXME: Hard-coding of ALL_RESERVES
    error InvalidReleaseType(Release release, uint8 ordering);
    error SumNotEqualSupply(uint256 sum, uint256 supply);
    error InvalidRecipientSum(ReserveType reserveType, uint256 sum); // 0x5fc4d0d8
    error InvalidTokens(uint256 balance, uint256 supply); // 0x9fe0a320
    error CannotForwardClaimableFunds(ReserveType reserveType, address recipient);
    error NothingToForward(ReserveType reserveType, address shareholder);
    error NothingToClaim(ReserveType reserveType, address shareholder);
    error NotAllowedToClaim(address shareholder);
    error NothingToSafeguard(address shareholder);
    error ShareholderIsNotCompromised(address shareholder);
    error PriceNotMet(uint256 lastAvg4Hours, uint256 requirement);
    error DexPathsNotSet();
    error CannotTransferThol();
    error UnlockedLessThanClaimed(uint256 unlocked, uint256 claimed, uint256 sum);
    error WrongShareholder(address shareholder);

    /**************************************

         Abstract functions

     **************************************/

    // Unlock Reserve
    function unlockReserve(ReserveType _reserveType, uint8 _releaseNo) external virtual;


    // Thol to USDT conversion
    function tholToUsdt() public virtual view returns (uint256);

}