// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {ISplitMain} from "./interfaces/ISplitMain.sol";
import {IWaterfallModuleFactory} from "./interfaces/IWaterfallModuleFactory.sol";
import {IWaterfallModule} from "./interfaces/IWaterfallModule.sol";

/// @title Recoup
/// @author 0xSplits
/// @notice A contract for efficiently combining splits together with a waterfall
contract Recoup {
    /// -----------------------------------------------------------------------
    /// errors
    /// -----------------------------------------------------------------------

    /// Invalid non waterfall recipient tranche index, cannot be larger than tranches length
    error InvalidRecoup__NonWaterfallRecipientTrancheIndexTooLarge();

    /// Invalid non waterfall recipient, address and tranche both set
    error InvalidRecoup__NonWaterfallRecipientSetTwice();

    /// Invalid number of accounts for a recoup tranche; must be at least one
    error InvalidRecoup__TooFewAccounts(uint256 index);

    /// Invalid recipient and percent allocation lengths for a tranche; must be equal
    error InvalidRecoup__TrancheAccountsAndPercentAllocationsMismatch(uint256 index);

    /// Invalid percent allocation for a single address; must equal PERCENTAGE_SCALE
    error InvalidRecoup__SingleAddressPercentAllocation(uint256 index, uint32 percentAllocation);

    /// -----------------------------------------------------------------------
    /// structs
    /// -----------------------------------------------------------------------

    struct Tranche {
        address[] recipients;
        uint32[] percentAllocations;
        address controller;
        uint32 distributorFee;
    }

    /// -----------------------------------------------------------------------
    /// events
    /// -----------------------------------------------------------------------

    /// Emitted after a new recoup is deployed
    /// @param waterfallModule Address of newly created WaterfallModule
    event CreateRecoup(address waterfallModule);

    /// -----------------------------------------------------------------------
    /// storage
    /// -----------------------------------------------------------------------

    ISplitMain public immutable splitMain;
    IWaterfallModuleFactory public immutable waterfallModuleFactory;

    uint256 public constant PERCENTAGE_SCALE = 1e6;

    /// -----------------------------------------------------------------------
    /// constructor
    /// -----------------------------------------------------------------------

    constructor(address _splitMain, address _waterfallModuleFactory) {
        splitMain = ISplitMain(_splitMain);
        waterfallModuleFactory = IWaterfallModuleFactory(_waterfallModuleFactory);
    }

    /// -----------------------------------------------------------------------
    /// functions
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// functions - public & external
    /// -----------------------------------------------------------------------

    /// Creates a waterfall module and possibly multiple splits given the input parameters
    /// @param token Address of ERC20 to waterfall (0x0 used for ETH)
    /// @param nonWaterfallRecipientAddress Address to recover non-waterfall tokens to
    /// @param nonWaterfallRecipientTrancheIndex Tranche number to recover non-waterfall tokens to
    /// @param tranches Split data for each tranche. A single address will just be used (no split created)
    /// @param thresholds Absolute payment thresholds for waterfall tranches
    /// (last recipient has no threshold & receives all residual flows)
    /// @dev A single address in a split recipient array with a matching single 1e6 value in the percentAllocations
    /// array means that tranche will be a single address and not a split. The nonWaterfallRecipient
    /// will be set to the passed in address, except for when that is address(0) and the
    /// non waterfall tranche is set. In that case the nonWaterfallRecipient will be set to the address
    /// at that tranche index.
    function createRecoup(
        address token,
        address nonWaterfallRecipientAddress,
        uint256 nonWaterfallRecipientTrancheIndex, // Must be set to tranches.length if not being used
        Tranche[] calldata tranches,
        uint256[] calldata thresholds
    ) external {
        /// checks

        uint256 tranchesLength = tranches.length;

        if (nonWaterfallRecipientTrancheIndex > tranchesLength) {
            revert InvalidRecoup__NonWaterfallRecipientTrancheIndexTooLarge();
        }
        if (nonWaterfallRecipientAddress != address(0) && nonWaterfallRecipientTrancheIndex != tranchesLength) {
            revert InvalidRecoup__NonWaterfallRecipientSetTwice();
        }

        uint256 i = 0;
        for (; i < tranchesLength;) {
            uint256 recipientsLength = tranches[i].recipients.length;

            if (recipientsLength == 0) {
                revert InvalidRecoup__TooFewAccounts(i);
            }
            if (recipientsLength != tranches[i].percentAllocations.length) {
                revert InvalidRecoup__TrancheAccountsAndPercentAllocationsMismatch(i);
            }
            if (recipientsLength == 1 && tranches[i].percentAllocations[0] != PERCENTAGE_SCALE) {
                revert InvalidRecoup__SingleAddressPercentAllocation(i, tranches[i].percentAllocations[0]);
            }
            // Other recipient/percent allocation combos are splits and will get validated in the create split call

            unchecked {
                ++i;
            }
        }

        /// effects
        address[] memory waterfallRecipients = new address[](tranchesLength);

        // Create splits
        i = 0;
        for (; i < tranchesLength;) {
            Tranche calldata t = tranches[i];
            if (t.recipients.length == 1) {
                waterfallRecipients[i] = t.recipients[0];
            } else {
                // Will fail if it's an immutable split that already exists. The caller
                // should just pass in the split address (with percent = 100%) in that case
                waterfallRecipients[i] = splitMain.createSplit({
                    accounts: t.recipients,
                    percentAllocations: t.percentAllocations,
                    distributorFee: t.distributorFee,
                    controller: t.controller
                });
            }

            unchecked {
                ++i;
            }
        }

        // Set non-waterfall recipient
        // If nonWaterfallRecipientAddress is set, that is used. If it's not set and a valid tranche index
        // is set, the address at the tranche index is used. Otherwise, address(0) is used which means
        // that non-waterfall tokens can be recovered to any tranche recipient address.
        address nonWaterfallRecipient = nonWaterfallRecipientAddress;
        if (nonWaterfallRecipientAddress == address(0) && nonWaterfallRecipientTrancheIndex < tranchesLength) {
            nonWaterfallRecipient = waterfallRecipients[nonWaterfallRecipientTrancheIndex];
        }

        // Create waterfall
        IWaterfallModule wm = waterfallModuleFactory.createWaterfallModule({
            token: token,
            nonWaterfallRecipient: nonWaterfallRecipient,
            recipients: waterfallRecipients,
            thresholds: thresholds
        });

        emit CreateRecoup(address(wm));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface ISplitMain {
    error InvalidSplit__TooFewAccounts(uint256 accountsLength);

    function createSplit(
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee,
        address controller
    ) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface IWaterfallModule {
    function waterfallFunds() external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IWaterfallModule} from "./IWaterfallModule.sol";

interface IWaterfallModuleFactory {
    function createWaterfallModule(
        address token,
        address nonWaterfallRecipient,
        address[] calldata recipients,
        uint256[] calldata thresholds
    ) external returns (IWaterfallModule); // Should this be address?
}