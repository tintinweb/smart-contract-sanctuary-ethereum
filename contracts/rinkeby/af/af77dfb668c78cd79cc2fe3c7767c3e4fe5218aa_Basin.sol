// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

// Standard library imports
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// Custom contract imports
import {IBasin} from "@contracts-V1/interfaces/IBasin.sol";
import {Errors} from "@contracts-V1/interfaces/Errors.sol";
import {Events} from "@contracts-V1/interfaces/Events.sol";
import {ChannelStruct, Status, PackageItem, ItemType} from "@contracts-V1/lib/StructsAndEnums.sol";
import {Channel} from "@contracts-V1/utils/Channel.sol";
import "@contracts-V1/utils/TokenTransferer.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";

/**
 * @title Basin
 * @author waint.eth
 * @notice This contract acts as a distribution factory. Where users can create
 *         distribution channels to transfer ownership of digital assets to
 *         recipients dynamically based on off chain events.
 */
contract Basin is ReentrancyGuard, TokenTransferer, Channel, IBasin {
    using SafeTransferLib for address;

    // Channel ID
    uint256 public nextChannelId = 1;

    // Mapping of hash to channel ID.
    mapping(bytes32 => uint256) internal hashToChannelId;

    // Amount of eth held by fees
    uint256 public feeHoldings;

    // Maximum protocol fee that can be set.
    uint256 internal constant MAX_FEE = 0.01 ether;

    // Fee to host a channel.
    uint256 public protocolFee = 0.001 ether;

    // Boolean to determine if the fee is enabled or not, can be toggled.
    bool public feeEnabled = false;

    // Address of the beneficiary of Channel fees.
    address payable public beneficiary;

    /**
     * @notice Confirms whether a set of recipients and packages can create a valid channel.
     *
     * @param recipients Addresses of the valid recipients in a channel.
     * @param packages PackageItem array of digital assets to be distributed in a channel.
     *
     */
    modifier validChannel(
        address[] calldata recipients,
        PackageItem[] calldata packages
    ) {
        uint256 recipientsLength = recipients.length;
        uint256 packagesLength = packages.length;

        // Too large of a channel
        if (recipientsLength >= 256 || packagesLength >= 256) {
            revert Basin__InvalidChannel__TooManyRecipientsOrPackages(
                recipientsLength,
                packagesLength
            );
        }

        if (recipientsLength < 2)
            revert Basin__InvalidChannel__TooFewRecipients(recipientsLength);

        if (recipientsLength != packagesLength)
            revert Basin__InvalidChannel__RecipientsAndPackagesMismatch(
                recipientsLength,
                packagesLength
            );

        delete recipientsLength;
        delete packagesLength;
        _;
    }

    /**
     * @notice Confirms if the given inputs hashes to a valid channels hash.
     *
     * @param channelId ID of the channel to check controller of.
     * @param recipients Addresses of the valid recipients in a channel.
     * @param packages PackageItem array of digital assets to be distributed in a channel.
     *
     */
    modifier validHash(
        uint256 channelId,
        address[] calldata recipients,
        PackageItem[] calldata packages
    ) {
        bytes32 channelHash = _hashChannel(channelId, recipients, packages);
        if (hashToChannelId[channelHash] == 0) {
            revert Basin__InvalidChannel__InvalidHash(
                recipients,
                packages,
                channelHash,
                "Channel does not exist, ID is 0."
            );
        }
        require(
            channels[hashToChannelId[channelHash]].size == recipients.length,
            "Mismatch between channel size and recipients length."
        );

        delete channelHash;
        _;
    }

    /**
     * @notice Ensure the caller for a given channel is the channel controller.
     *
     * @param channelId ID of the channel to check controller of.
     *
     */
    modifier onlyChannelController(uint256 channelId) {
        if (msg.sender != channels[channelId].controller)
            revert Basin__UnauthorizedChannelController(msg.sender);
        _;
    }

    /**
     * @notice Constructor sets the immutable channel implementation and beneficiary to the sender.
     */
    constructor() {
        beneficiary = payable(msg.sender);
    }

    /**
     * @notice Toggle is feeEnabled is true or false, only called by beneficiary.
     *
     */
    function toggleFee() public {
        require(msg.sender == beneficiary, "Not the beneficiary of the fee.");
        feeEnabled = feeEnabled ? false : true;
        emit Basin__FeeToggled(feeEnabled);
    }

    /**
     * @notice Primary functionality of Basin. This function allows you to create a new channel to distribute assets.
     *         The function will charge the protocolFee if feeEnabled is set to true. The function transfers all input packages
     *         to this contract for holding until they're distributed. A new channel is then created and mappings are updated
     *         with all the new information and hashes. The channel contract is then initialized and ready for distribution.
     *         The outcome is a new Channel contract with its own address and Basin having ownership of all package items taken as
     *         input. The channel can be canceled while its status is still in Open, but when the status is switched to Started
     *         the assets will only be deliverable to the recipients in the channel. This function is externally facing and requires
     *         payment and depositting of assets.
     *
     * @param recipients Addresses of the valid recipients in a channel.
     * @param packages PackageItem array of digital assets to be distributed in a channel.
     * @param controller Address of who will be controlling the channel.
     *
     * @return channelId ID of the channel created.
     */
    function createChannel(
        address[] calldata recipients,
        PackageItem[] calldata packages,
        address controller
    )
        external
        payable
        validChannel(recipients, packages)
        returns (uint256 channelId)
    {
        // Deposit all packages from the caller of the function
        bool success;
        if (feeEnabled) {
            require(msg.value >= protocolFee, "Not enough ETH sent for fee");
            feeHoldings += protocolFee;
            success = depositPackages(
                packages,
                address(this),
                msg.sender,
                msg.value - protocolFee
            );
        } else {
            success = depositPackages(
                packages,
                address(this),
                msg.sender,
                msg.value
            );
        }
        require(success, "Failed to deposit packages.");

        // Create channel hash
        bytes32 channelHash = _hashChannel(nextChannelId, recipients, packages);

        // Hash collision should never occur since we use the
        // Channel address in the hash algo
        require(
            hashToChannelId[channelHash] == 0,
            "Hash collision, reverting creation of channel"
        );
        require(
            channels[nextChannelId].controller == address(0x0),
            "Channel already in use."
        );

        // Initialize the channel
        initializeChannel(controller, recipients, channelHash, nextChannelId);

        hashToChannelId[channelHash] = nextChannelId;

        emit Basin__CreateChannel(channelId, channels[channelId]);
        ++nextChannelId;
        return nextChannelId - 1;
    }

    /**
     * @notice This function acts as a safety net for the creator of a channel. Before the channel is started, the
     *         controller of the channel has the ability to cancel it and return all the assets Basin controls back to them.
     *         This is the only time the user can withdraw items from a channel unless they're delivering the package to the
     *         recipient.
     *
     * @param channelId Address of the channel being executed.
     * @param recipients Addresses of the valid recipients in a channel.
     * @param packages PackageItem array of digital assets to be distributed in a channel.
     *
     */
    function cancelChannel(
        uint256 channelId,
        address[] calldata recipients,
        PackageItem[] calldata packages
    )
        external
        validHash(channelId, recipients, packages)
        onlyChannelController(channelId)
        nonReentrant
    {
        require(
            channels[channelId].channelStatus == Status.Open,
            "Channel is not open, cannot cancel."
        );
        address _to = channels[channelId].controller;
        distributePackagesForCancel(packages, _to);
        delete channels[channelId];
        delete hashToChannelId[_hashChannel(channelId, recipients, packages)];
    }

    /**
     * @notice This function distributes a package to a recipient. The function first determines if the
     *         given inputs hash to a valid channel, which would confirm the packages and recipients are valid.
     *         The function then uses indexes for recipients and packages instead of taking addresses which
     *         forces the reciever to be valid in the channel, and also forces the package to be one which is
     *         already deposited. The function also sets if the reciever of the package is still eligible on
     *         the channel contract. This flag allows a single recipient to recieve multiple packages, or be
     *         restricted to a single package. The function calls _pairRecipientWithPackage which alters the
     *         storage on the channel contract to confirm distribution of a package and reception from a recipient.
     *         The function then distributes the package which protects against re-entrancy. Then the function
     *         transfers the package from Basin to the recipient.
     *
     * @param channelId ID of the channel to process.
     * @param recipients Addresses of the valid recipients in a channel.
     * @param packages PackageItem array of digital assets to be distributed in a channel.
     * @param recipientIndex Index in the recipients array to deliver the package to.
     * @param packageIndex Index in the package array to determine which package to deliver.
     * @param recieverStillEligible Bool to set on the Channel contract to block a user from recieveing more packages.
     *
     */
    function distributeToRecipient(
        uint256 channelId,
        address[] calldata recipients,
        PackageItem[] calldata packages,
        uint256 recipientIndex,
        uint256 packageIndex,
        bool recieverStillEligible
    )
        external
        validHash(channelId, recipients, packages)
        onlyChannelController(channelId)
        nonReentrant
    {
        if (recipientIndex >= recipients.length) {
            revert Basin__InvalidRecipientIndex(
                recipientIndex,
                recipients.length
            );
        }

        if (packageIndex >= packages.length) {
            revert Basin__InvalidPlaceIndex(packageIndex, packages.length);
        }

        _pairRecipientWithPackage(
            channelId,
            recipients[recipientIndex],
            packageIndex,
            recieverStillEligible
        );

        bool delivered = _deliverPackageToRecipient(
            recipients[recipientIndex],
            packages[packageIndex]
        );

        if (delivered == false) {
            revert Basin__FailedToDeliverPackage(
                recipients[recipientIndex],
                packages[packageIndex]
            );
        }
    }

    /**
     * @notice This function will deliver a set of packages to a set of recipients 1:1.
     *         The length of the recipients and the length of the packages must be the same.
     *         Package[0] will be delivered to recipient[0], package[1] - recipient[1], and
     *         so on. This function does not create a channel, this is a single execution
     *         function. All ItemTypes are valid (ETH, ERC20, ERC721, ERC1155).
     *
     * @param recipients Addresses of the people recieving packages.
     * @param packages Packages to be distributed to the recipients.
     *
     */
    function deliverPackages(
        address[] calldata recipients,
        PackageItem[] calldata packages
    ) external payable nonReentrant returns (bool) {
        // Make sure recipients and packages have same length;
        uint256 recipientsLength = recipients.length;
        require(
            recipientsLength == packages.length,
            "Packages and recipients mismatch."
        );

        uint256 ethInPackages = 0;

        for (uint256 i = 0; i < recipientsLength; i++) {
            // If the packages is ETH
            if (packages[i].itemType == ItemType.NATIVE) {
                ethInPackages += packages[i].amount;
                (bool sent, ) = address(recipients[i]).call{
                    value: packages[i].amount
                }("");
                require(sent, "Failed to send Ether");
            } else {
                require(
                    digestPackageDeposit(
                        packages[i],
                        recipients[i],
                        msg.sender
                    ),
                    "Package distribution failed"
                );
            }
        }

        require(ethInPackages == msg.value, "Incorrect Eth Deposit amount");
        return true;
    }

    /**
     * @notice This function changes the status of a Channel. The status are Open, Started, and Completed.
     *         The channel status can progress from Open -> Started -> Completed, this is the only way
     *         the statuses can progress. The channel contract asserts this progression.
     *
     * @param channelId ID of the channel to process.
     * @param recipients Addresses of the valid recipients in a channel.
     * @param packages PackageItem array of digital assets to be distributed in a channel.
     * @param newStatus Status enum value to set for the channel.
     *
     */
    function changeChannelStatus(
        uint256 channelId,
        address[] calldata recipients,
        PackageItem[] calldata packages,
        Status newStatus
    )
        external
        validHash(channelId, recipients, packages)
        onlyChannelController(channelId)
        nonReentrant
    {
        _changeChannelStatus(channelId, newStatus);
    }

    function getChannelStatus(uint256 channelId)
        public
        view
        returns (Status stat)
    {
        return channels[channelId].channelStatus;
    }

    /**
     * @notice This function allows for the changing of the beneficiary. Only the beneficiary can
     *         call this function. The beneficiary is the address which recieves the fees.
     *
     * @param newBeneficiary Address of the new beneficiary to recieve the fees.
     *
     */
    function setBeneficiary(address payable newBeneficiary) external {
        require(
            msg.sender == beneficiary,
            "Not the beneficiary, cannot execute."
        );
        emit Basin__SetBeneficiary(newBeneficiary);
        beneficiary = newBeneficiary;
    }

    /**
     * @notice This function sets the protocolFee which is paid out to the beneficiary.
     *
     * @param newFee New uint256 value for the fee.
     *
     */
    function setProtocolFee(uint256 newFee) external {
        require(
            msg.sender == beneficiary,
            "Not the beneficiary, cannot execute."
        );
        require(newFee <= MAX_FEE, "Fee too high.");
        emit Basin__SetProtocolFee(newFee);
        protocolFee = newFee;
    }

    /**
     * @notice This function allows for the withdrawing of the fees collected by the protocol.
     *         This function is callable by anyone, but only sends the fees to the beneficiary
     *
     */
    function withdrawFee() public nonReentrant {
        uint256 holdingFees = feeHoldings;
        feeHoldings = 0;
        emit Basin__BeneficiaryWithdraw(holdingFees);
        address(beneficiary).safeTransferETH(holdingFees);
    }

    /**
     * @dev Internal function that calls the channels function pairRecipientAndPackage
     *
     * @param channelId ID of the channel to process.
     * @param recipient Address of the recipient derived from the recipients array in the calling function.
     * @param packageIndex Index in the package array to determine which package to deliver.
     * @param recieverStillEligible Bool to set on the Channel contract to block a user from recieveing more packages.
     *
     */
    function _pairRecipientWithPackage(
        uint256 channelId,
        address recipient,
        uint256 packageIndex,
        bool recieverStillEligible
    ) internal {
        emit Basin__RecipientPairedWithPackage(recipient, packageIndex);

        pairRecipientAndPackage(
            channelId,
            recipient,
            packageIndex,
            recieverStillEligible
        );
    }

    /**
     * @dev Internal function that calls the channels function changeStatus.
     *
     * @param channelId ID of the channel to process.
     * @param newStatus New Status enum to change the status in the channel to.
     *
     */
    function _changeChannelStatus(uint256 channelId, Status newStatus) private {
        emit Basin__ChannelStatusChanged(channelId, newStatus);

        changeStatus(channelId, newStatus);
    }

    /**
     * @dev Internal function which delivers a package to a recipient. This calls the TokenTransferer.sol contract.
     *      This function returns a boolean value to confirm the delivery of a package.
     *
     * @param recipient Address of the package recipient.
     * @param package PackageItem outlining what asset is being transfered to the recipient.
     *
     * @return success Boolean value confirming delivery of a package.
     *
     */
    function _deliverPackageToRecipient(
        address recipient,
        PackageItem calldata package
    ) internal returns (bool success) {
        return distributePackage(package, recipient);
    }

    /**
     * @dev Internal function which delivers a package to a recipient. This calls the TokenTransferer.sol contract.
     *      This function returns a boolean value to confirm the delivery of a package.
     *
     * @param recipients Addresses of the valid recipients in a channel.
     * @param packages PackageItem array of digital assets to be distributed in a channel.
     *
     * @return Bytes32 value of the hash of the inputs.
     *
     */
    function _hashChannel(
        uint256 id,
        address[] memory recipients,
        PackageItem[] memory packages
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(id, recipients, packages));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

// Custom contract imports
import {ChannelStruct, Status, PackageItem, ItemType} from "@contracts-V1/lib/StructsAndEnums.sol";

/**
 * @title IBasin
 * @author waint.eth
 * @notice This is the interface to Basin.sol
 */
interface IBasin {
    /**
     * @notice Primary functionality of Basin. This function allows you to create a new channel to distribute assets.
     *         The function will charge the protocolFee if feeEnabled is set to true. The function transfers all input packages
     *         to this contract for holding until they're distributed. A new channel is then created and mappings are updated
     *         with all the new information and hashes. The channel contract is then initialized and ready for distribution.
     *         The outcome is a new Channel contract with its own address and Basin having ownership of all package items taken as
     *         input. The channel can be canceled while its status is still in Open, but when the status is switched to Started
     *         the assets will only be deliverable to the recipients in the channel. This function is externally facing and requires
     *         payment and depositting of assets.
     *
     * @param recipients Addresses of the valid recipients in a channel.
     * @param packages PackageItem array of digital assets to be distributed in a channel.
     * @param controller Address of who will be controlling the channel.
     *
     * @return channelId ID of the channel created.
     */
    function createChannel(
        address[] calldata recipients,
        PackageItem[] calldata packages,
        address controller
    ) external payable returns (uint256 channelId);

    /**
     * @notice This function acts as a safety net for the creator of a channel. Before the channel is started, the
     *         controller of the channel has the ability to cancel it and return all the assets Basin controls back to them.
     *         This is the only time the user can withdraw items from a channel unless they're delivering the package to the
     *         recipient.
     *
     * @param channelId Address of the channel being executed.
     * @param recipients Addresses of the valid recipients in a channel.
     * @param packages PackageItem array of digital assets to be distributed in a channel.
     *
     */
    function cancelChannel(
        uint256 channelId,
        address[] calldata recipients,
        PackageItem[] calldata packages
    ) external;

    /**
     * @notice This function distributes a package to a recipient. The function first determines if the
     *         given inputs hash to a valid channel, which would confirm the packages and recipients are valid.
     *         The function then uses indexes for recipients and packages instead of taking addresses which
     *         forces the reciever to be valid in the channel, and also forces the package to be one which is
     *         already deposited. The function also sets if the reciever of the package is still eligible on
     *         the channel contract. This flag allows a single recipient to recieve multiple packages, or be
     *         restricted to a single package. The function calls _pairRecipientWithPackage which alters the
     *         storage on the channel contract to confirm distribution of a package and reception from a recipient.
     *         The function then distributes the package which protects against re-entrancy. Then the function
     *         transfers the package from Basin to the recipient.
     *
     * @param channelId ID of the channel to process.
     * @param recipients Addresses of the valid recipients in a channel.
     * @param packages PackageItem array of digital assets to be distributed in a channel.
     * @param recipientIndex Index in the recipients array to deliver the package to.
     * @param packageIndex Index in the package array to determine which package to deliver.
     * @param recieverStillEligible Bool to set on the Channel contract to block a user from recieveing more packages.
     *
     */
    function distributeToRecipient(
        uint256 channelId,
        address[] calldata recipients,
        PackageItem[] calldata packages,
        uint256 recipientIndex,
        uint256 packageIndex,
        bool recieverStillEligible
    ) external;

    /**
     * @notice This function changes the status of a Channel. The status are Open, Started, and Completed.
     *         The channel status can progress from Open -> Started -> Completed, this is the only way
     *         the statuses can progress. The channel contract asserts this progression.
     *
     * @param channelId ID of the channel to process.
     * @param recipients Addresses of the valid recipients in a channel.
     * @param packages PackageItem array of digital assets to be distributed in a channel.
     * @param newStatus Status enum value to set for the channel.
     *
     */
    function changeChannelStatus(
        uint256 channelId,
        address[] calldata recipients,
        PackageItem[] calldata packages,
        Status newStatus
    ) external;

    /**
     * @notice Toggle is feeEnabled is true or false, only called by beneficiary.
     *
     */
    function toggleFee() external;

    /**
     * @notice This function allows for the changing of the beneficiary. Only the beneficiary can
     *         call this function. The beneficiary is the address which recieves the fees.
     *
     * @param newBeneficiary Address of the new beneficiary to recieve the fees.
     *
     */
    function setBeneficiary(address payable newBeneficiary) external;

    /**
     * @notice This function sets the protocolFee which is paid out to the beneficiary.
     *
     * @param newFee New uint256 value for the fee.
     *
     */
    function setProtocolFee(uint256 newFee) external;

    /**
     * @notice This function allows for the withdrawing of the fees collected by the protocol.
     *         This function is callable by anyone, but only sends the fees to the beneficiary
     *
     */
    function withdrawFee() external;

    /**
     * @notice This function will deliver a set of packages to a set of recipients 1:1.
     *         The length of the recipients and the length of the packages must be the same.
     *         Package[0] will be delivered to recipient[0], package[1] - recipient[1], and
     *         so on. This function does not create a channel, this is a single execution
     *         function. All ItemTypes are valid (ETH, ERC20, ERC721, ERC1155).
     */
    function deliverPackages(
        address[] calldata recipients,
        PackageItem[] calldata packages
    ) external payable returns (bool);

    /**
     * @notice Get the status of a given Channel
     *
     */
    function getChannelStatus(uint256 channelId)
        external
        view
        returns (Status stat);
}

pragma solidity ^0.8.0;

import {PackageItem} from "@contracts-V1/lib/StructsAndEnums.sol";

/**
 * @title ChannelErrors
 * @author eucliss
 * @notice ChannelErrors contains errors related to channels
 */
interface Errors {
    // ChannelsFactory.sol
    /// @notice Invalid number of players `playersLength`, must have at least 2
    /// @param playersLength Length of players array
    error Basin__InvalidChannel__TooFewRecipients(uint256 playersLength);

    error Basin__InvalidChannel__TooManyRecipientsOrPackages(
        uint256 playersLength,
        uint256 payoutsLength
    );
    /// @notice Array lengths of players & payouts don't match (`playersLength` != `payoutsLength`)
    /// @param playersLength Length of players array
    /// @param payoutsLength Length of payouts array
    error Basin__InvalidChannel__RecipientsAndPackagesMismatch(
        uint256 playersLength,
        uint256 payoutsLength
    );

    /// @notice Sum of payouts != 100%
    /// @param payoutsSum Sum of all payouts for the Channel
    error InvalidChannel__InvalidPackagesSum(uint32 payoutsSum);

    /// @notice Package value for `index` is negative
    /// @param index Index for the negative payout value
    error InvalidChannel__PackagesMustBePositive(uint256 index);

    /// @notice Invalid distributorFee `distributorFee` cannot be greater than 10% (1e5)
    /// @param distributorFee Invalid distributorFee amount
    error InvalidChannel__InvalidDistributorFee(uint32 distributorFee);

    /// @notice Unauthorized sender `sender`
    /// @param sender Transaction sender
    error Basin__UnauthorizedChannelController(address sender);

    error Basin__InvalidChannel__InvalidHash(
        address[] players,
        PackageItem[] payouts,
        bytes32 channelHash,
        string mes
    );

    error Basin__InvalidRecipientIndex(
        uint256 playerIndex,
        uint256 playersLength
    );

    error Basin__InvalidPlaceIndex(uint256 placeIndex, uint256 placeLength);

    error TokenTransferer__InvalidTokenType(PackageItem item);

    error TokenTransferer__FailedTokenDeposit(PackageItem item, address from);

    error TokenTransferer__IncorrectEthValueSentWithPackages(
        uint256 ethSent,
        uint256 ethInPackages
    );
    error TokenTransferer__NoneTypeItemDeposit(
        address from,
        PackageItem reward
    );

    error Basin__FailedToDeliverPackage(address player, PackageItem item);
}

pragma solidity ^0.8.0;

import {ChannelStruct, ChannelDetails, Status, PackageItem} from "@contracts-V1/lib/StructsAndEnums.sol";

/**
 * @title ChannelErrors
 * @author eucliss
 * @notice ChannelErrors contains errors related to channels
 */
interface Events {
    event Basin__SetBeneficiary(address beneficiary);
    event Basin__SetProtocolFee(uint256 newFee);
    event Basin__RecipientPairedWithPackage(address player, uint256 place);
    event Basin__ChannelStatusChanged(uint256 channelId, Status newStatus);
    event Basin__CreateChannel(
        uint256 channelId,
        ChannelStruct _createdChannel
    );
    event Basin__CreateDynamicChannel(
        address _channelAddress,
        ChannelStruct _createdChannel
    );
    event Basin__RecipientAddedToDynamicChannel(
        uint256 channelId,
        address player,
        uint256 size
    );

    event Basin__RecipientRemovedFromChannel(
        uint256 channelId,
        address player,
        uint256 size
    );
    event Basin__RecipientAccepted(uint256 channelId, address player);
    event Basin__RecipientDeclined(uint256 channelId, address player);
    event Basin__RecipientRescindedAcceptance(
        uint256 channelId,
        address player
    );
    event Basin__DynamicChannelStarted(uint256 channelId, address[] player);
    event Basin__FeeToggled(bool feeStatus);
    event Basin__BeneficiaryWithdraw(uint256 fees);

    // event Channel__ChannelStatusChanged(uint256 channelId, Status newStatus);
    // event Channel__NewChannelInitiated(uint256 channelId);
    // event Channel__RecipientPlaced(address player, uint256 place);

    event TokenTransferer__PackagesDeposited(
        PackageItem[] payouts,
        uint256 ethValue
    );
}

pragma solidity ^0.8.0;

enum ItemType {
    NATIVE,
    ERC20,
    ERC721,
    ERC1155,
    NONE
}

enum Status {
    Open,
    Started,
    Completed
}

struct ChannelStruct {
    bytes32 hash;
    address controller;
    uint256 size;
    bytes32 recipients;
    bytes32 packages;
    uint256 id;
    Status channelStatus;
}

struct ChannelDetails {
    address[] players;
    uint32[] payouts;
    uint prizepool;
}

struct RecipientStatus {
    bool placed;
    uint32 place;
    uint payout;
    bool eligible;
}

struct PackageItem {
    ItemType itemType;
    address token;
    uint256 identifier;
    uint256 amount;
}

struct EligibleRecipient {
    bool eligible;
    bool accepted;
    bool deposited;
    bool payoutDepositRequired;
    PackageItem deposit;
}

pragma solidity ^0.8.14;

import {ChannelStruct, PackageItem, ItemType, Status} from "@contracts-V1/lib/StructsAndEnums.sol";
import {ChannelEventsAndErrors} from "@contracts-V1/interfaces/ChannelEventsAndErrors.sol";

/**
 * @title Channel
 * @author waint.eth
 * @notice This contract contains the logic to execute a channel. A channel consists of
 *         a Bytes32 representation of the recipients and packages, the size of the channel,
 *         and the status of the channel. When a channel is initialized, a bitmap is created
 *         for the recipients, this essentially maps the array of recipients to binary bits
 *         the bits are used for tracking whether a recipient can recieve a package or not.
 *         if the bit associated with a recipient index is 1, they can recieve a package, if
 *         it is 0, they cannot. The packages storage works in a similar way, although we dont
 *         need to store the packageItem associated with that bit like we do addresses for
 *         recipients. Basin will take care of that. Here is a representation of a bitmap:
 *
 *                  Bit map from recipient address to bits
 *                      [addr0, addr1, addr2, addr3, addr4] => 1 1 1 1 1
 *                      Flip the list so
 *                      0 => 2^0 bit
 *                      1 => 2^1 bit
 *                      2 => 2^2 bit ...
 *
 *         When a recipient is paired with a package, they have the option to mark the recipient
 *         as not eligible for other packages, if this is the case then we will flip the recipients
 *         bit in the recipients bytes32 storage. Next we need to flip the package bit as well since
 *         the package will be delivered and Basin will not own it any longer.
 */
contract Channel is ChannelEventsAndErrors {
    // Mapping of channel address to struct containing hash and controller.
    mapping(uint256 => ChannelStruct) public channels;
    mapping(uint256 => mapping(address => uint256))
        public channelRecipientBitmap;

    //     struct ChannelStruct {
    //     bytes32 hash;
    //     address controller;
    //     uint256 size;
    //     bytes32 recipients;
    //     bytes32 packages;
    //     mapping(address => uint256) recipientBitMap;
    //     uint256 id;
    //     Status channelStatus;
    // }

    /**
     * @notice This is the initialization function, only called once during createChannel from Basin.
     *         This function sets the size of the channel to the length of the recipients and sets the
     *         recipientBitMap. It goes through and initializes the bytes32 recipients storage to 2**size -1
     *         and the bytes32 packages storage to 0.
     *
     * @param _recipientsList Address array of recipients to initialize the channel with.
     *
     */
    function initializeChannel(
        address controller,
        address[] memory _recipientsList,
        bytes32 channelHash,
        uint256 channelId
    ) internal {
        channels[channelId] = ChannelStruct({
            hash: channelHash,
            controller: controller,
            size: _recipientsList.length,
            recipients: bytes32(2**_recipientsList.length - 1),
            packages: 0,
            id: channelId,
            channelStatus: Status.Open
        });
        _createRecipientBitMap(channelId, _recipientsList);
        emit Channel__NewChannelInitiated(channelId);
    }

    /**
     * @notice Helper function to initialize the bitmap with. This function takes the recipients
     *         and the size of the channel and maps each address recipient to a bit index. This
     *         allows us to flip a specific bit when an address is being paired with a package.
     *
     * @param _recipients Address array of recipients to initialize the bitmap with.
     *
     */
    function _createRecipientBitMap(
        uint256 channelId,
        address[] memory _recipients
    ) internal {
        // Init all recipients to 1's
        // recipients = channels[channelId].recipients;
        uint256 size = channels[channelId].size;

        unchecked {
            for (uint256 i = 0; i < size; i++) {
                // TODO: this actually should be an indexed error for reporting
                // Fix v1/test/Channel.t.sol test testCreateRecipientBitMapError when fixed
                require(
                    channelRecipientBitmap[channelId][_recipients[i]] == 0,
                    "Bit already set for recipient, error initiating channel."
                );
                channelRecipientBitmap[channelId][_recipients[i]] = i;
            }
        }
    }

    /**
     * @notice This function takes a recipient and pairs them with a package. It does this by flipping
     *         bits in the recipients and packages storage. If the bool recieverStillEligible is false,
     *         then we flip the recipient bit to a 0 to mark them as uneligible for future packages.
     *         Regardless of this boolean value we flip the package bit to mark that Basin does
     *         not own that package any longer.
     *
     * @param _recipient Address of the recipient of a package.
     * @param _packageIndex Index of the package to be delivered in the package array.
     * @param recieverStillEligible Bool to set to mark a reciever as eligible in the future or not.
     *
     */
    function pairRecipientAndPackage(
        uint256 channelId,
        address _recipient,
        uint256 _packageIndex,
        bool recieverStillEligible
    ) internal {
        // Confirm the recipient is eligible for a package still
        bytes32 recipientBit = bytes32(
            2**(channelRecipientBitmap[channelId][_recipient])
        );
        require(
            (channels[channelId].recipients & recipientBit) == recipientBit,
            "Recipient not eligible to recieve packages in this Channel."
        );

        // If they are no longer eligible, flip the bit
        if (!recieverStillEligible) {
            flipRecipientBit(channelId, _recipient);
        }

        flipPackageBit(channelId, _packageIndex);
        emit Channel__RecipientPlaced(_recipient, _packageIndex);
    }

    /**
     * @notice This function flips a recipients bit. A recipients bit must be a 1.
     *
     * @param channelId ID of the channel to change
     * @param _recipient Address of the recipient of a package.
     *
     */
    function flipRecipientBit(uint256 channelId, address _recipient) internal {
        // Bit operations to take recipient index and set to 0 in bitmap
        bytes32 recipientBit = bytes32(
            2**(channelRecipientBitmap[channelId][_recipient])
        );

        // And the recipients
        channels[channelId].recipients =
            channels[channelId].recipients ^
            recipientBit;
    }

    /**
     * @notice This function flips a package bit. A package bit must be 0.
     *
     * @param packageIndex Index in packages to flip.
     *
     */
    function flipPackageBit(uint256 channelId, uint256 packageIndex) internal {
        // Must be less than the size of the recipients
        require(
            packageIndex < channels[channelId].size,
            "Package index too high"
        );

        // Get the package bit
        // Package 0 = bit 0 == 2^0 == 1 -> 00001
        // Package 1 = bit 1 == 2^1 == 2 -> 00010
        // Package 2 = bit 3 == 2^2 == 4 -> 00100
        // 0  .... 0  0  0
        // pX .... p2 p1 p0
        bytes32 packageBit = bytes32(2**packageIndex);

        if (packageBit & channels[channelId].packages == packageBit) {
            revert Channel__PackageAlreadyDelivered(packageIndex);
        }

        channels[channelId].packages =
            channels[channelId].packages |
            packageBit;
    }

    /**
     * @notice This function changes the status of the Channel.
     *         Status changes from Open -> Started -> Completed.
     *
     * @param newStatus New status to set the channel to.
     *
     */
    function changeStatus(uint256 channelId, Status newStatus) internal {
        // If newStatus is Open, revert. Cant re-open a channel.
        if (newStatus == Status.Open) {
            revert Channel__StatusCannotBeSetToOpen();
        }

        // If new status is started
        // Confirm channel is going from Open -> Started
        // Confirm channel is not Completed.
        if (newStatus == Status.Started) {
            require(
                channels[channelId].channelStatus == Status.Open,
                "Channel is not open."
            );
            require(
                channels[channelId].channelStatus != Status.Completed,
                "Channel is completed."
            );
        }

        // If new status is Completed
        // Confirm channel status is Started, must be Started -> Completed
        if (newStatus == Status.Completed) {
            require(
                channels[channelId].channelStatus == Status.Started,
                "Channel is not started."
            );

            // Require all packages delivered before completing channel
            require(
                channels[channelId].packages ==
                    bytes32(2**channels[channelId].size - 1),
                "Not all packages delivered."
            );
        }

        // Set status
        channels[channelId].channelStatus = newStatus;
        emit Channel__ChannelStatusChanged(channelId, newStatus);
    }
}

/*

    What is a channel ??

A channel has
- Recipients
    - Recipients are eliminated and payed out
- Matches
    - Matches are played and leads to eliminations
- Prizepool
    - Prizepool gets paid to recipients
- Package structure
    - Determines how prizepool is distributed


    recipient1 - x
    x
    recipient2 -----------------|
                            |    recipient2    ___WINNER___
    recipient3 - x              | ---- x -------| Recipient 4 |
    x                     |    recipient4    ------------
    recipient4 -|     recipient4 --|
            | ------ x 
    recipient5 -|     recipient5


recipients = [1, 2, 3, 4, 5] 
packages = [50, 30, 10, 10, 0]
len = 5
    

*/

/*
    Requirements for allchannels

    - Recipients == Package Distribution
    - Packages == 100% of prizepool
    - Prizepool > 0 ether
    - Recipients cannot be paid out twice
    - Packages cannot be repeated
*/

pragma solidity ^0.8.14;

import {PackageItem, ItemType} from "@contracts-V1/lib/StructsAndEnums.sol";

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {ERC721, ERC721TokenReceiver} from "@solmate/tokens/ERC721.sol";
import {ERC1155, ERC1155TokenReceiver} from "@solmate/tokens/ERC1155.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "@contracts-V1/interfaces/Errors.sol";
import "@contracts-V1/interfaces/Events.sol";

/**
 * @title TokenTransferer
 * @author waint.eth
 * @notice This contract contains the token transfer capability for Basin.sol. This will be
 *         used to transfer PackageItem struct type values containing ERC standard tokens (20, 721, 1155, ETH)
 *         to recipients in channels or to Basin itself. This contract allows for
 *         depositing multiple packages and distributing packages to recipients.
 */
contract TokenTransferer is
    Errors,
    Events,
    ERC721TokenReceiver,
    ERC1155TokenReceiver
{
    using SafeTransferLib for ERC20;
    using SafeTransferLib for address;

    /**
     * @notice Deposit an array of PackageItems into the Basin contract. This function takes a to
     *         parameter which is always set to the address of Basin. The packages can include ETH
     *         as well as any ERC(20, 721, 1155) thus the function validates the amount of ETH sent
     *         in the msg.value of the transaction matches what is defined in the packages themselves.
     *         The function then digests each package deposit by sending the package to Basin. The
     *         function requires depositing of all packages and correct ETH amount or it fails.
     *
     * @param packages PackageItem array of digital assets to be deposited.
     * @param to To address of where the packages are being deposited.
     * @param from Address where the packages are being transfered from.
     * @param ethValue ETH value that was sent with the message, must align with all package value.
     *
     * @return success Boolean value confirming the depositing of all packages.
     */
    function depositPackages(
        PackageItem[] calldata packages,
        address to,
        address from,
        uint256 ethValue
    ) internal returns (bool success) {
        // ) internal payable returns (bool success) {
        // Initiate values for later
        uint256 len = packages.length;
        uint256 packageEth = 0;
        bool ethInPackages = false;

        // Loop through all packages
        for (uint256 i = 0; i < len; i++) {
            // If the package is ETH, track the amount and flip the ethInPackages flag.
            if (packages[i].itemType == ItemType.NATIVE) {
                packageEth += packages[i].amount;
                ethInPackages = true;

                // Else we need to digest the package and confirm depositing.
            } else {
                success = digestPackageDeposit(packages[i], to, from);
                if (success == false) {
                    revert TokenTransferer__FailedTokenDeposit(
                        packages[i],
                        from
                    );
                }
            }
        }

        // If no eth in the packages, but eth sent with msg, revert
        if (ethInPackages == false && ethValue != 0) {
            revert TokenTransferer__IncorrectEthValueSentWithPackages(
                ethValue,
                packageEth
            );
        }

        // If eth is in the packages but the eth in the package doesnt equal eth sent, revert
        if (ethInPackages && packageEth != ethValue) {
            revert TokenTransferer__IncorrectEthValueSentWithPackages(
                ethValue,
                packageEth
            );
        }

        emit TokenTransferer__PackagesDeposited(packages, ethValue);
        return true;
    }

    /**
     * @notice Distributes a single package to a recipient.
     *
     * @param item PackageItem to be distributed to the to param address.
     * @param to To address of where the package is getting distributed.
     *
     * @return success Boolean value confirming the distribution of the package.
     */
    function distributePackage(PackageItem calldata item, address to)
        internal
        returns (bool success)
    {
        success = digestPackageDistribute(item, payable(to));
        require(success, "Failed to distribute payout.");
    }

    /**
     * @notice Distribute packages for a channel in the event of a cancelation.
     *         This function distributes all the packages to one address.
     *
     * @param items PackageItems to be distributed to the to param address.
     * @param to To address of where the package is getting distributed.
     *
     * @return success Boolean value confirming the distribution of the package.
     */
    function distributePackagesForCancel(
        PackageItem[] calldata items,
        address to
    ) internal returns (bool success) {
        // Loop through all packages and send to the to address.
        for (uint256 i = 0; i < items.length; i++) {
            success = digestPackageDistribute(items[i], payable(to));
            require(success, "Failed to distribute payout.");
        }
    }

    /**
     * @notice Take a PackageItem being deposited and execute the deposit. This function
     *         will handle ERC(20, 721, 1155) but not ETH - that is handled elsewhere.
     *         The function transfers assets to Basin. If it fails, reverts.
     *
     * @param item PackageItem to be deposited to the to param address.
     * @param to To address of where the package is getting deposited.
     * @param from Address to transfer the item from.
     *
     * @return success Boolean value confirming the distribution of the package.
     */
    function digestPackageDeposit(
        PackageItem calldata item,
        address to,
        address from
    ) internal returns (bool success) {
        // ERC20
        if (item.itemType == ItemType.ERC20) {
            success = transferERC20(item, to, from);
            return success;
        }

        // ERC721
        if (item.itemType == ItemType.ERC721) {
            success = transferERC721(item, to, from);
            return success;
        }

        // ERC1155
        if (item.itemType == ItemType.ERC1155) {
            success = transferERC1155(item, to, from);
            return success;
        }
        if (success == false || item.itemType == ItemType.NATIVE) {
            revert TokenTransferer__InvalidTokenType(item);
        }
    }

    /**
     * @notice Take a PackageItem being distributed and execute the distribution. This function
     *         will handle ERC(20, 721, 1155) and also ETH. The function transfers the package
     *         to the param to. Will revert if it fails.
     *
     * @param item PackageItem to be distributed to the to param address.
     * @param to To address of where the package is getting distributed.
     *
     * @return success Boolean value confirming the distribution of the package.
     */
    function digestPackageDistribute(
        PackageItem calldata item,
        address payable to
    ) internal returns (bool success) {
        // ETH
        if (item.itemType == ItemType.NATIVE) {
            address(to).safeTransferETH(item.amount);
            return true;
        }

        // ERC20
        if (item.itemType == ItemType.ERC20) {
            success = transferERC20Out(item, to);
            return success;
        }

        // ERC721
        if (item.itemType == ItemType.ERC721) {
            success = transferERC721(item, to, address(this));
            return success;
        }

        // ERC1155
        if (item.itemType == ItemType.ERC1155) {
            success = transferERC1155(item, to, address(this));
            return success;
        }

        // Revert if it fails
        if (success == false) {
            revert TokenTransferer__InvalidTokenType(item);
        }
    }

    /**
     * @dev Transfer an ERC20 PackageItem to Basin from a channel owner. This function
     *      handles in the inbound package deposits.
     *
     * @param item PackageItem to be distributed to the to param address.
     * @param to To address of where the package is getting distributed.
     * @param from Address to transfer the item from.
     *
     * @return success Boolean value confirming the distribution of the package.
     */
    function transferERC20(
        PackageItem memory item,
        address to,
        address from
    ) internal returns (bool success) {
        success = ERC20(item.token).transferFrom(from, to, item.amount);
        require(success, "Safe transfer for ERC20 failed.");
    }

    /**
     * @dev Transfer an ERC20 PackageItem to a recipient from Basin. This function
     *      handles only the outbound package distributions.
     *
     * @param item PackageItem to be distributed to the to param address.
     * @param to To address of where the package is getting distributed.
     *
     * @return success Boolean value confirming the distribution of the package.
     */
    function transferERC20Out(PackageItem memory item, address to)
        internal
        returns (bool success)
    {
        success = ERC20(item.token).transfer(to, item.amount);
        require(success, "Safe transfer for ERC20 failed.");
    }

    /**
     * @dev Transfer an ERC721 PackageItem to an address from another address. This function
     *      handles both deposits and distribution of packages.
     *
     * @param item PackageItem to be distributed to the to param address.
     * @param to To address of where the package is getting distributed.
     * @param from Address to transfer the item from.
     *
     * @return success Boolean value confirming the distribution of the package.
     */
    function transferERC721(
        PackageItem memory item,
        address to,
        address from
    ) internal returns (bool success) {
        ERC721(item.token).safeTransferFrom(from, to, item.identifier);
        return true;
    }

    /**
     * @dev Transfer an ERC1155 PackageItem to an address from another address. This function
     *      handles both deposits and distribution of packages.
     *
     * @param item PackageItem to be distributed to the to param address.
     * @param to To address of where the package is getting distributed.
     * @param from Address to transfer the item from.
     *
     * @return success Boolean value confirming the distribution of the package.
     */
    function transferERC1155(
        PackageItem memory item,
        address to,
        address from
    ) internal returns (bool success) {
        ERC1155(item.token).safeTransferFrom(
            from,
            to,
            item.identifier,
            item.amount,
            ""
        );
        return true;
    }
}

/**
 * @notice Deposits a single package into Basin. This function takes a PackegeItem from the
 *         user and deposits it into the address defined in the to parameter.
 *
 *
 */
// function depositPackage(
//     PackageItem calldata package,
//     address to,
//     address from,
//     uint256 ethValue
// ) public payable returns (bool success) {
//     if (package.itemType == ItemType.NONE) {
//         revert TokenTransferer__NoneTypeItemDeposit(from, package);
//     }
//     bool ethInPackages = false;
//     if (package.itemType == ItemType.NATIVE) {
//         if (ethValue != package.amount) {
//             ethInPackages = true;
//             revert TokenTransferer__IncorrectEthValueSentWithPackages(
//                 ethValue,
//                 package.amount
//             );
//         }
//     } else {
//         success = digestPackageDeposit(package, to, from);
//         if (success == false) {
//             revert TokenTransferer__FailedTokenDeposit(package, from);
//         }
//     }
//     // emit TokenTransferer__PackagesDeposited(package, ethValue);
//     return true;
// }

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

pragma solidity ^0.8.0;

import {PackageItem} from "@contracts-V1/lib/StructsAndEnums.sol";

import {Status} from "@contracts-V1/lib/StructsAndEnums.sol";

/**
 * @title ChannelErrors
 * @author eucliss
 * @notice ChannelErrors contains errors related to channels
 */
interface ChannelEventsAndErrors {
    error Channel__PackageAlreadyDelivered(uint256 placeIndex);

    // Channel & Binary
    error Channel__StatusCannotBeSetToOpen();

    event Channel__ChannelStatusChanged(uint256 channelId, Status newStatus);
    event Channel__NewChannelInitiated(uint256 channelId);
    event Channel__RecipientPlaced(address player, uint256 place);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}