// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0x902e195f(bytes32 c__0x902e195f) pure {}


import { ConduitInterface } from "../interfaces/ConduitInterface.sol";

import { ConduitItemType } from "./lib/ConduitEnums.sol";

import { TokenTransferrer } from "../lib/TokenTransferrer.sol";

import {
    ConduitTransfer,
    ConduitBatch1155Transfer
} from "./lib/ConduitStructs.sol";

import "./lib/ConduitConstants.sol";

/**
 * @title Conduit
 * @author 0age
 * @notice This contract serves as an originator for "proxied" transfers. Each
 *         conduit is deployed and controlled by a "conduit controller" that can
 *         add and remove "channels" or contracts that can instruct the conduit
 *         to transfer approved ERC20/721/1155 tokens. *IMPORTANT NOTE: each
 *         conduit has an owner that can arbitrarily add or remove channels, and
 *         a malicious or negligent owner can add a channel that allows for any
 *         approved ERC20/721/1155 tokens to be taken immediately — be extremely
 *         cautious with what conduits you give token approvals to!*
 */
contract Conduit is ConduitInterface, TokenTransferrer {
function c_0x724f62b5(bytes32 c__0x724f62b5) internal pure {}

    // Set deployer as an immutable controller that can update channel statuses.
    address private immutable _controller;

    // Track the status of each channel.
    mapping(address => bool) private _channels;

    /**
     * @notice Ensure that the caller is currently registered as an open channel
     *         on the conduit.
     */
    modifier onlyOpenChannel() {c_0x724f62b5(0x235c40549a7ae06cf09498506fa6dfb7d5c0a2c64a5cda3ed588bde7ade9af59); /* function */ 

        // Utilize assembly to access channel storage mapping directly.
c_0x724f62b5(0xafd7297b497ed1f9a3a09d52389c18cd2901a8a273d3c8bd68359813c52ddda1); /* line */ 
        assembly {
            // Write the caller to scratch space.
            mstore(ChannelKey_channel_ptr, caller())

            // Write the storage slot for _channels to scratch space.
            mstore(ChannelKey_slot_ptr, _channels.slot)

            // Derive the position in storage of _channels[msg.sender]
            // and check if the stored value is zero.
            if iszero(
                sload(keccak256(ChannelKey_channel_ptr, ChannelKey_length))
            ) {
                // The caller is not an open channel; revert with
                // ChannelClosed(caller). First, set error signature in memory.
                mstore(ChannelClosed_error_ptr, ChannelClosed_error_signature)

                // Next, set the caller as the argument.
                mstore(ChannelClosed_channel_ptr, caller())

                // Finally, revert, returning full custom error with argument.
                revert(ChannelClosed_error_ptr, ChannelClosed_error_length)
            }
        }

        // Continue with function execution.
c_0x724f62b5(0x3c9ae660a1370cec53b50b2941b9a9208eb41d03199c2fb7bf2b4817b4007187); /* line */ 
        _;
    }

    /**
     * @notice In the constructor, set the deployer as the controller.
     */
    constructor() {c_0x724f62b5(0x6bd0f72d249145cc7597fb80c2f67394f24fce8d21df3d72506917561cdcf46a); /* function */ 

        // Set the deployer as the controller.
c_0x724f62b5(0x05ea25b29e62a457f138bb003831d3cefc335c79c991ed6d5dce3f28e495ea73); /* line */ 
        c_0x724f62b5(0xcb88a03c737a7e5d358660d1b55468d60a86a95b696b575fd1a366b1f28b04d9); /* statement */ 
_controller = msg.sender;
    }

    /**
     * @notice Execute a sequence of ERC20/721/1155 transfers. Only a caller
     *         with an open channel can call this function. Note that channels
     *         are expected to implement reentrancy protection if desired, and
     *         that cross-channel reentrancy may be possible if the conduit has
     *         multiple open channels at once. Also note that channels are
     *         expected to implement checks against transferring any zero-amount
     *         items if that constraint is desired.
     *
     * @param transfers The ERC20/721/1155 transfers to perform.
     *
     * @return magicValue A magic value indicating that the transfers were
     *                    performed successfully.
     */
    function execute(ConduitTransfer[] calldata transfers)
        external
        override
        onlyOpenChannel
        returns (bytes4 magicValue)
    {c_0x724f62b5(0xd5a302ef48703bee28d33678801c3609929985f2bfe7a397f93c4bb1990f1d78); /* function */ 

        // Retrieve the total number of transfers and place on the stack.
c_0x724f62b5(0x59a1a6c98c261845a22ce099126cd8ffdcdede8902dc64cc2e6f744fd136b10a); /* line */ 
        c_0x724f62b5(0xc366c04ead8dd67c369e7f07e38cb10d956101ad5d2989d6a63847e5b43b13cd); /* statement */ 
uint256 totalStandardTransfers = transfers.length;

        // Iterate over each transfer.
c_0x724f62b5(0x1ed80c820d0f7443f75f2131b17561917cc9ee99a3038225c2cbb2e6b017b641); /* line */ 
        c_0x724f62b5(0x60d8c307e6883b8977e04c5f64d35d7ba77d2079593969046ad10e4ea18a0b19); /* statement */ 
for (uint256 i = 0; i < totalStandardTransfers; ) {
            // Retrieve the transfer in question and perform the transfer.
c_0x724f62b5(0x52ba22659b595d8ed2de4f0c185634faf129e296383113ef832d068d8b0990d4); /* line */ 
            c_0x724f62b5(0x0038f4e9687e90b696daebe63c5b7024a270dba0ec87925f7324d2fd2d352853); /* statement */ 
_transfer(transfers[i]);

            // Skip overflow check as for loop is indexed starting at zero.
c_0x724f62b5(0x3b13d9318e8a694d17aa5144daaff2129d2c9105dd9d6dcd7ca3e8e32257f106); /* line */ 
            unchecked {
c_0x724f62b5(0x27d1c0dbfae3239ad2cd503fe2ba24311da520362166abf8626948b963a4d54a); /* line */ 
                ++i;
            }
        }

        // Return a magic value indicating that the transfers were performed.
c_0x724f62b5(0x45d00fe1b72062ebbc7cdffc18c906dc60dd505ec37db7ba3ab70ef777ae5c36); /* line */ 
        c_0x724f62b5(0xa0426ec17edfabb43da9cf44f87240a79f6a0c12479f48a8eeb8b1263ecdd907); /* statement */ 
magicValue = this.execute.selector;
    }

    /**
     * @notice Execute a sequence of batch 1155 item transfers. Only a caller
     *         with an open channel can call this function. Note that channels
     *         are expected to implement reentrancy protection if desired, and
     *         that cross-channel reentrancy may be possible if the conduit has
     *         multiple open channels at once. Also note that channels are
     *         expected to implement checks against transferring any zero-amount
     *         items if that constraint is desired.
     *
     * @param batchTransfers The 1155 batch item transfers to perform.
     *
     * @return magicValue A magic value indicating that the item transfers were
     *                    performed successfully.
     */
    function executeBatch1155(
        ConduitBatch1155Transfer[] calldata batchTransfers
    ) external override onlyOpenChannel returns (bytes4 magicValue) {c_0x724f62b5(0x682d8e9fca43a2c3dfe1f8aa95ad8a7157ba46beaddc08bf032f04258e727e69); /* function */ 

        // Perform 1155 batch transfers. Note that memory should be considered
        // entirely corrupted from this point forward.
c_0x724f62b5(0x435ab014643715564a0bcd0619643dc0c369cd8108654551c0f005d539d435b6); /* line */ 
        c_0x724f62b5(0x71d2016b0095f86255fa0b1f0ba6a6e79cc24303990ebec4ebb58e473799106c); /* statement */ 
_performERC1155BatchTransfers(batchTransfers);

        // Return a magic value indicating that the transfers were performed.
c_0x724f62b5(0x4319282f2d72c375670b5b34296521b5ad49b695b7da08270334ae69161aac3e); /* line */ 
        c_0x724f62b5(0x7146d46c029edf65bb345fde1f3faa4ddafa1e3852a2ef4627953c596efaed93); /* statement */ 
magicValue = this.executeBatch1155.selector;
    }

    /**
     * @notice Execute a sequence of transfers, both single ERC20/721/1155 item
     *         transfers as well as batch 1155 item transfers. Only a caller
     *         with an open channel can call this function. Note that channels
     *         are expected to implement reentrancy protection if desired, and
     *         that cross-channel reentrancy may be possible if the conduit has
     *         multiple open channels at once. Also note that channels are
     *         expected to implement checks against transferring any zero-amount
     *         items if that constraint is desired.
     *
     * @param standardTransfers The ERC20/721/1155 item transfers to perform.
     * @param batchTransfers    The 1155 batch item transfers to perform.
     *
     * @return magicValue A magic value indicating that the item transfers were
     *                    performed successfully.
     */
    function executeWithBatch1155(
        ConduitTransfer[] calldata standardTransfers,
        ConduitBatch1155Transfer[] calldata batchTransfers
    ) external override onlyOpenChannel returns (bytes4 magicValue) {c_0x724f62b5(0x6c30633b2cb26e6ed271c3ac204b446a06957dc276cecadf602101ab821eb9c7); /* function */ 

        // Retrieve the total number of transfers and place on the stack.
c_0x724f62b5(0x17760f0eec8bfa81b3ec0cc8bff7e6de729e4bc3f34329bd1a24a0e9d3525be9); /* line */ 
        c_0x724f62b5(0x8e5bfd708f2b6d6fd974b111b3a6cd8ebd156145d3e46ec361df3db3039fcd8d); /* statement */ 
uint256 totalStandardTransfers = standardTransfers.length;

        // Iterate over each standard transfer.
c_0x724f62b5(0x3270f1c5afb4d89773b7eb452b0f1c3cfc07ff0bba0c3b7561516aefb481adbb); /* line */ 
        c_0x724f62b5(0x5d3c33c0b3d1f1bce6beb6ae77da414aa4f1b4b93436aa24e70774e1d79dda55); /* statement */ 
for (uint256 i = 0; i < totalStandardTransfers; ) {
            // Retrieve the transfer in question and perform the transfer.
c_0x724f62b5(0x4137660ebf150575b4e48120dd3d44d4e99b4aa2df368267aecb751249bac124); /* line */ 
            c_0x724f62b5(0xacf9f0602eda4c75aff41fc2b72b63b520474e6da4d897c0efa40a3062c65415); /* statement */ 
_transfer(standardTransfers[i]);

            // Skip overflow check as for loop is indexed starting at zero.
c_0x724f62b5(0xc3719090e896372dab9707c4d9d4d9d5a977535e55a4e3ec291761dd7c79096d); /* line */ 
            unchecked {
c_0x724f62b5(0x125a56ab1dd4742ac8050b4b021d514c9701d4cad31bd3dc4db6bdd563dd2a29); /* line */ 
                ++i;
            }
        }

        // Perform 1155 batch transfers. Note that memory should be considered
        // entirely corrupted from this point forward aside from the free memory
        // pointer having the default value.
c_0x724f62b5(0xc7ba82d1a66cdc2d1afeff4dd965b05bfd3132b6fcb8423656814ebcfb75ad4d); /* line */ 
        c_0x724f62b5(0xc086d0ef772f23eb9dc4ea8dce8837b0ca8d12f2bb79a081bf0dcf22f845e7f9); /* statement */ 
_performERC1155BatchTransfers(batchTransfers);

        // Return a magic value indicating that the transfers were performed.
c_0x724f62b5(0x148f8c38ec324e608267c3b84722d7b8c8cd2baaecb712a9337579c865c74cd5); /* line */ 
        c_0x724f62b5(0xde03c904ba4816e7ebd31d043c3c42d0567b69cd2f20159667f7c0ec843412d0); /* statement */ 
magicValue = this.executeWithBatch1155.selector;
    }

    /**
     * @notice Open or close a given channel. Only callable by the controller.
     *
     * @param channel The channel to open or close.
     * @param isOpen  The status of the channel (either open or closed).
     */
    function updateChannel(address channel, bool isOpen) external override {c_0x724f62b5(0xb39f71e0af97a5f2a3bf78da1a687cf5019a0469e45b04e5b0d1f21a4ca31d5d); /* function */ 

        // Ensure that the caller is the controller of this contract.
c_0x724f62b5(0x6e7c0890ef1a684d9c0b47d6fcd0b39bcad6ffff38e19dac1cd2f8531455a446); /* line */ 
        c_0x724f62b5(0x9a4d4482b4430d4da224274cace9c7e4c2b06c7a458904d973d86abe583740f5); /* statement */ 
if (msg.sender != _controller) {c_0x724f62b5(0x998bccfe7f8fb1f0a898ae8966531e859b2fe62a528d99a86d6fc1542cb13e95); /* branch */ 

c_0x724f62b5(0xf72f55a4a60e2a9f01fbddf32e130aa874344b51e50a68fd213a629d7c676239); /* line */ 
            revert InvalidController();
        }else { c_0x724f62b5(0xafa51b605e7205bfed6fc1f7d0304293ba7e2714209aed913f3232b2b864d6bd); /* branch */ 
}

        // Ensure that the channel does not already have the indicated status.
c_0x724f62b5(0x3881527854797b92c33d4aef297281836851b490f797f80c7300dc56601487e0); /* line */ 
        c_0x724f62b5(0xc7e52291159e1e5653681ece7a2d92836dc097b55d152aa76d10acc192574044); /* statement */ 
if (_channels[channel] == isOpen) {c_0x724f62b5(0x573e481226d00d6a1af18d5633a99f95ffa33dea9d47992defdea12f9d23072d); /* branch */ 

c_0x724f62b5(0x2441acd82177fcc78fae4c5b0d780693d76b7d8a6639a683deaf61eda2f6a477); /* line */ 
            revert ChannelStatusAlreadySet(channel, isOpen);
        }else { c_0x724f62b5(0xf111c31cbef52ecf4fd59cd467e163feac6e4ef85b37a24ffd2fe0c160d42cd0); /* branch */ 
}

        // Update the status of the channel.
c_0x724f62b5(0x8ff23d25413156f66a6b81ff59f2d5fc0e344c2ec0bc2d0a918cb27097cf90d6); /* line */ 
        c_0x724f62b5(0x69d2e26602bd32ca37419a4e478068b0a5cc76246784c93d5af62d1ed8154f72); /* statement */ 
_channels[channel] = isOpen;

        // Emit a corresponding event.
c_0x724f62b5(0xad51a28019cedfc0a0e4a731c7def6c81bc0577eefdb60a53f691b58799f497b); /* line */ 
        c_0x724f62b5(0x34ef9e17992738b03560c7ee4043d2b415da49d8e6b605b8541fee0d15f537f7); /* statement */ 
emit ChannelUpdated(channel, isOpen);
    }

    /**
     * @dev Internal function to transfer a given ERC20/721/1155 item. Note that
     *      channels are expected to implement checks against transferring any
     *      zero-amount items if that constraint is desired.
     *
     * @param item The ERC20/721/1155 item to transfer.
     */
    function _transfer(ConduitTransfer calldata item) internal {c_0x724f62b5(0xd51b8ed1b73e9f5dbb1cdbb00adad7846c86adb0fa6992e97f472c135d127060); /* function */ 

        // Determine the transfer method based on the respective item type.
c_0x724f62b5(0x6afc746ed0ac26d13dad99e9b7abf2d4f3608994b56d1e435ac2b5cb99f31f5e); /* line */ 
        c_0x724f62b5(0xf1677a81f1ea1e33efb89f6c436f1f9b34b1bfb15344dcf88bed13acfdfd9b6d); /* statement */ 
if (item.itemType == ConduitItemType.ERC20) {c_0x724f62b5(0x97c1b3c769622550c849fca7af62b4c5cd38755f2fd0eec5a0afb4a2a9eba43c); /* branch */ 

            // Transfer ERC20 token. Note that item.identifier is ignored and
            // therefore ERC20 transfer items are potentially malleable — this
            // check should be performed by the calling channel if a constraint
            // on item malleability is desired.
c_0x724f62b5(0x7157fae3bc54d35e320c3599e2c244de29e19950baa6a6f6c686a030b334e3a9); /* line */ 
            c_0x724f62b5(0xfe64953e103f3eff1ebdd6825085f43b916d2190cd32720b1df304188ed9bffc); /* statement */ 
_performERC20Transfer(item.token, item.from, item.to, item.amount);
        } else {c_0x724f62b5(0x745398debe64478d058862f4761b4b58018b71f86598a9a15b625c2e0aa76511); /* statement */ 
c_0x724f62b5(0xac47055dddafb4e48b7f56f02e00edf13614d39b3e0e8860ad51ba3c3e22b78a); /* branch */ 
if (item.itemType == ConduitItemType.ERC721) {c_0x724f62b5(0x4da0334e6aab95f4411a4b28ca05f1c7cd41167eae577d4bb01f5d5b6b7a43ad); /* branch */ 

            // Ensure that exactly one 721 item is being transferred.
c_0x724f62b5(0x35c610f706061bda756cedbbbdfe160834f0a65f02e3dacbdc2f5e1f2d03d03e); /* line */ 
            c_0x724f62b5(0xc0da08893437e785ec6dffa08d91f331444e18381a1a1e5ba41e24a25ef7bd26); /* statement */ 
if (item.amount != 1) {c_0x724f62b5(0x1859fbe3e605248bca50f0b9c0c771a66c94ffde25d53e3cf045d1e527cf379c); /* branch */ 

c_0x724f62b5(0x3556c55ee483c2b3bd7aa54dca4d42c460b9da546f55c04b2bb26c3935374713); /* line */ 
                revert InvalidERC721TransferAmount();
            }else { c_0x724f62b5(0x93709447df661c610fef55ae28cdeeff0ea9ec919685504b816cc49e96197824); /* branch */ 
}

            // Transfer ERC721 token.
c_0x724f62b5(0xe01ae93f93bd88db9b7e5225063682972281097550a84d5fd3a37cb0c95b71b5); /* line */ 
            c_0x724f62b5(0xdcb58ef35f509ec0844ecbb7bb9c97649811a29f777e955ed0cdeab746493927); /* statement */ 
_performERC721Transfer(
                item.token,
                item.from,
                item.to,
                item.identifier
            );
        } else {c_0x724f62b5(0x69abc349a5c117fcfe6df2dfc13f4319c53b19c08af5ea31352cfd317348ba21); /* statement */ 
c_0x724f62b5(0xa4b426dea43ed4d3640917bf65b2e33f16499c7a5e599b34149858592b92dc73); /* branch */ 
if (item.itemType == ConduitItemType.ERC1155) {c_0x724f62b5(0x2e046eecc58d65c674ae83c55d25f554f40bdadc313d660b25b61a5aa93cd44e); /* branch */ 

            // Transfer ERC1155 token.
c_0x724f62b5(0xd3dfff48852ab579549ddf0ac990bba029cd266c3b8cb987fdec5551249233e4); /* line */ 
            c_0x724f62b5(0x416d185776e68bf8491acd05b9adb0118c1897d704a1feb56baea7d0a8cc1a50); /* statement */ 
_performERC1155Transfer(
                item.token,
                item.from,
                item.to,
                item.identifier,
                item.amount
            );
        } else {c_0x724f62b5(0xd7841f7b22e61803990490a9448e6231a2f66e01562c8e15eb41c63abf8c0e08); /* branch */ 

            // Throw with an error.
c_0x724f62b5(0x5b8aa34fa75ea0e86b3d1551fe3a75bd802a26b66760ece6d90c359e3ce3b053); /* line */ 
            revert InvalidItemType();
        }}}
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {
    ConduitTransfer,
    ConduitBatch1155Transfer
} from "../conduit/lib/ConduitStructs.sol";

/**
 * @title ConduitInterface
 * @author 0age
 * @notice ConduitInterface contains all external function interfaces, events,
 *         and errors for conduit contracts.
 */
interface ConduitInterface {
    /**
     * @dev Revert with an error when attempting to execute transfers using a
     *      caller that does not have an open channel.
     */
    error ChannelClosed(address channel);

    /**
     * @dev Revert with an error when attempting to update a channel to the
     *      current status of that channel.
     */
    error ChannelStatusAlreadySet(address channel, bool isOpen);

    /**
     * @dev Revert with an error when attempting to execute a transfer for an
     *      item that does not have an ERC20/721/1155 item type.
     */
    error InvalidItemType();

    /**
     * @dev Revert with an error when attempting to update the status of a
     *      channel from a caller that is not the conduit controller.
     */
    error InvalidController();

    /**
     * @dev Emit an event whenever a channel is opened or closed.
     *
     * @param channel The channel that has been updated.
     * @param open    A boolean indicating whether the conduit is open or not.
     */
    event ChannelUpdated(address indexed channel, bool open);

    /**
     * @notice Execute a sequence of ERC20/721/1155 transfers. Only a caller
     *         with an open channel can call this function.
     *
     * @param transfers The ERC20/721/1155 transfers to perform.
     *
     * @return magicValue A magic value indicating that the transfers were
     *                    performed successfully.
     */
    function execute(ConduitTransfer[] calldata transfers)
        external
        returns (bytes4 magicValue);

    /**
     * @notice Execute a sequence of batch 1155 transfers. Only a caller with an
     *         open channel can call this function.
     *
     * @param batch1155Transfers The 1155 batch transfers to perform.
     *
     * @return magicValue A magic value indicating that the transfers were
     *                    performed successfully.
     */
    function executeBatch1155(
        ConduitBatch1155Transfer[] calldata batch1155Transfers
    ) external returns (bytes4 magicValue);

    /**
     * @notice Execute a sequence of transfers, both single and batch 1155. Only
     *         a caller with an open channel can call this function.
     *
     * @param standardTransfers  The ERC20/721/1155 transfers to perform.
     * @param batch1155Transfers The 1155 batch transfers to perform.
     *
     * @return magicValue A magic value indicating that the transfers were
     *                    performed successfully.
     */
    function executeWithBatch1155(
        ConduitTransfer[] calldata standardTransfers,
        ConduitBatch1155Transfer[] calldata batch1155Transfers
    ) external returns (bytes4 magicValue);

    /**
     * @notice Open or close a given channel. Only callable by the controller.
     *
     * @param channel The channel to open or close.
     * @param isOpen  The status of the channel (either open or closed).
     */
    function updateChannel(address channel, bool isOpen) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

enum ConduitItemType {
    NATIVE, // unused
    ERC20,
    ERC721,
    ERC1155
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0xffbafec7(bytes32 c__0xffbafec7) pure {}


import "./TokenTransferrerConstants.sol";

import {
    TokenTransferrerErrors
} from "../interfaces/TokenTransferrerErrors.sol";

import { ConduitBatch1155Transfer } from "../conduit/lib/ConduitStructs.sol";

/**
 * @title TokenTransferrer
 * @author 0age
 * @custom:coauthor d1ll0n
 * @custom:coauthor transmissions11
 * @notice TokenTransferrer is a library for performing optimized ERC20, ERC721,
 *         ERC1155, and batch ERC1155 transfers, used by both Seaport as well as
 *         by conduits deployed by the ConduitController. Use great caution when
 *         considering these functions for use in other codebases, as there are
 *         significant side effects and edge cases that need to be thoroughly
 *         understood and carefully addressed.
 */
contract TokenTransferrer is TokenTransferrerErrors {
function c_0x5e9b24d6(bytes32 c__0x5e9b24d6) internal pure {}

    /**
     * @dev Internal function to transfer ERC20 tokens from a given originator
     *      to a given recipient. Sufficient approvals must be set on the
     *      contract performing the transfer.
     *
     * @param token      The ERC20 token to transfer.
     * @param from       The originator of the transfer.
     * @param to         The recipient of the transfer.
     * @param amount     The amount to transfer.
     */
    function _performERC20Transfer(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {c_0x5e9b24d6(0x3b111dd8b928b18363ef7a860d0c84ab48f40a831910755738a57a6385f344a4); /* function */ 

        // Utilize assembly to perform an optimized ERC20 token transfer.
c_0x5e9b24d6(0x161f3645d97edaa3b582be5614b66307c0d79918ad662a40968e71863ab977f9); /* line */ 
        assembly {
            // The free memory pointer memory slot will be used when populating
            // call data for the transfer; read the value and restore it later.
            let memPointer := mload(FreeMemoryPointerSlot)

            // Write call data into memory, starting with function selector.
            mstore(ERC20_transferFrom_sig_ptr, ERC20_transferFrom_signature)
            mstore(ERC20_transferFrom_from_ptr, from)
            mstore(ERC20_transferFrom_to_ptr, to)
            mstore(ERC20_transferFrom_amount_ptr, amount)

            // Make call & copy up to 32 bytes of return data to scratch space.
            // Scratch space does not need to be cleared ahead of time, as the
            // subsequent check will ensure that either at least a full word of
            // return data is received (in which case it will be overwritten) or
            // that no data is received (in which case scratch space will be
            // ignored) on a successful call to the given token.
            let callStatus := call(
                gas(),
                token,
                0,
                ERC20_transferFrom_sig_ptr,
                ERC20_transferFrom_length,
                0,
                OneWord
            )

            // Determine whether transfer was successful using status & result.
            let success := and(
                // Set success to whether the call reverted, if not check it
                // either returned exactly 1 (can't just be non-zero data), or
                // had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                callStatus
            )

            // Handle cases where either the transfer failed or no data was
            // returned. Group these, as most transfers will succeed with data.
            // Equivalent to `or(iszero(success), iszero(returndatasize()))`
            // but after it's inverted for JUMPI this expression is cheaper.
            if iszero(and(success, iszero(iszero(returndatasize())))) {
                // If the token has no code or the transfer failed: Equivalent
                // to `or(iszero(success), iszero(extcodesize(token)))` but
                // after it's inverted for JUMPI this expression is cheaper.
                if iszero(and(iszero(iszero(extcodesize(token))), success)) {
                    // If the transfer failed:
                    if iszero(success) {
                        // If it was due to a revert:
                        if iszero(callStatus) {
                            // If it returned a message, bubble it up as long as
                            // sufficient gas remains to do so:
                            if returndatasize() {
                                // Ensure that sufficient gas is available to
                                // copy returndata while expanding memory where
                                // necessary. Start by computing the word size
                                // of returndata and allocated memory. Round up
                                // to the nearest full word.
                                let returnDataWords := div(
                                    add(returndatasize(), AlmostOneWord),
                                    OneWord
                                )

                                // Note: use the free memory pointer in place of
                                // msize() to work around a Yul warning that
                                // prevents accessing msize directly when the IR
                                // pipeline is activated.
                                let msizeWords := div(memPointer, OneWord)

                                // Next, compute the cost of the returndatacopy.
                                let cost := mul(CostPerWord, returnDataWords)

                                // Then, compute cost of new memory allocation.
                                if gt(returnDataWords, msizeWords) {
                                    cost := add(
                                        cost,
                                        add(
                                            mul(
                                                sub(
                                                    returnDataWords,
                                                    msizeWords
                                                ),
                                                CostPerWord
                                            ),
                                            div(
                                                sub(
                                                    mul(
                                                        returnDataWords,
                                                        returnDataWords
                                                    ),
                                                    mul(msizeWords, msizeWords)
                                                ),
                                                MemoryExpansionCoefficient
                                            )
                                        )
                                    )
                                }

                                // Finally, add a small constant and compare to
                                // gas remaining; bubble up the revert data if
                                // enough gas is still available.
                                if lt(add(cost, ExtraGasBuffer), gas()) {
                                    // Copy returndata to memory; overwrite
                                    // existing memory.
                                    returndatacopy(0, 0, returndatasize())

                                    // Revert, specifying memory region with
                                    // copied returndata.
                                    revert(0, returndatasize())
                                }
                            }

                            // Otherwise revert with a generic error message.
                            mstore(
                                TokenTransferGenericFailure_error_sig_ptr,
                                TokenTransferGenericFailure_error_signature
                            )
                            mstore(
                                TokenTransferGenericFailure_error_token_ptr,
                                token
                            )
                            mstore(
                                TokenTransferGenericFailure_error_from_ptr,
                                from
                            )
                            mstore(TokenTransferGenericFailure_error_to_ptr, to)
                            mstore(TokenTransferGenericFailure_error_id_ptr, 0)
                            mstore(
                                TokenTransferGenericFailure_error_amount_ptr,
                                amount
                            )
                            revert(
                                TokenTransferGenericFailure_error_sig_ptr,
                                TokenTransferGenericFailure_error_length
                            )
                        }

                        // Otherwise revert with a message about the token
                        // returning false or non-compliant return values.
                        mstore(
                            BadReturnValueFromERC20OnTransfer_error_sig_ptr,
                            BadReturnValueFromERC20OnTransfer_error_signature
                        )
                        mstore(
                            BadReturnValueFromERC20OnTransfer_error_token_ptr,
                            token
                        )
                        mstore(
                            BadReturnValueFromERC20OnTransfer_error_from_ptr,
                            from
                        )
                        mstore(
                            BadReturnValueFromERC20OnTransfer_error_to_ptr,
                            to
                        )
                        mstore(
                            BadReturnValueFromERC20OnTransfer_error_amount_ptr,
                            amount
                        )
                        revert(
                            BadReturnValueFromERC20OnTransfer_error_sig_ptr,
                            BadReturnValueFromERC20OnTransfer_error_length
                        )
                    }

                    // Otherwise, revert with error about token not having code:
                    mstore(NoContract_error_sig_ptr, NoContract_error_signature)
                    mstore(NoContract_error_token_ptr, token)
                    revert(NoContract_error_sig_ptr, NoContract_error_length)
                }

                // Otherwise, the token just returned no data despite the call
                // having succeeded; no need to optimize for this as it's not
                // technically ERC20 compliant.
            }

            // Restore the original free memory pointer.
            mstore(FreeMemoryPointerSlot, memPointer)

            // Restore the zero slot to zero.
            mstore(ZeroSlot, 0)
        }
    }

    /**
     * @dev Internal function to transfer an ERC721 token from a given
     *      originator to a given recipient. Sufficient approvals must be set on
     *      the contract performing the transfer. Note that this function does
     *      not check whether the receiver can accept the ERC721 token (i.e. it
     *      does not use `safeTransferFrom`).
     *
     * @param token      The ERC721 token to transfer.
     * @param from       The originator of the transfer.
     * @param to         The recipient of the transfer.
     * @param identifier The tokenId to transfer.
     */
    function _performERC721Transfer(
        address token,
        address from,
        address to,
        uint256 identifier
    ) internal {c_0x5e9b24d6(0x5862dd378a15978a4db822219b213b304374839eef146791eac339b8841982bc); /* function */ 

        // Utilize assembly to perform an optimized ERC721 token transfer.
c_0x5e9b24d6(0xad81200370897e629dccc9d6764b5a1b370b3e237da02ebc72403a7a2e236c64); /* line */ 
        assembly {
            // If the token has no code, revert.
            if iszero(extcodesize(token)) {
                mstore(NoContract_error_sig_ptr, NoContract_error_signature)
                mstore(NoContract_error_token_ptr, token)
                revert(NoContract_error_sig_ptr, NoContract_error_length)
            }

            // The free memory pointer memory slot will be used when populating
            // call data for the transfer; read the value and restore it later.
            let memPointer := mload(FreeMemoryPointerSlot)

            // Write call data to memory starting with function selector.
            mstore(ERC721_transferFrom_sig_ptr, ERC721_transferFrom_signature)
            mstore(ERC721_transferFrom_from_ptr, from)
            mstore(ERC721_transferFrom_to_ptr, to)
            mstore(ERC721_transferFrom_id_ptr, identifier)

            // Perform the call, ignoring return data.
            let success := call(
                gas(),
                token,
                0,
                ERC721_transferFrom_sig_ptr,
                ERC721_transferFrom_length,
                0,
                0
            )

            // If the transfer reverted:
            if iszero(success) {
                // If it returned a message, bubble it up as long as sufficient
                // gas remains to do so:
                if returndatasize() {
                    // Ensure that sufficient gas is available to copy
                    // returndata while expanding memory where necessary. Start
                    // by computing word size of returndata & allocated memory.
                    // Round up to the nearest full word.
                    let returnDataWords := div(
                        add(returndatasize(), AlmostOneWord),
                        OneWord
                    )

                    // Note: use the free memory pointer in place of msize() to
                    // work around a Yul warning that prevents accessing msize
                    // directly when the IR pipeline is activated.
                    let msizeWords := div(memPointer, OneWord)

                    // Next, compute the cost of the returndatacopy.
                    let cost := mul(CostPerWord, returnDataWords)

                    // Then, compute cost of new memory allocation.
                    if gt(returnDataWords, msizeWords) {
                        cost := add(
                            cost,
                            add(
                                mul(
                                    sub(returnDataWords, msizeWords),
                                    CostPerWord
                                ),
                                div(
                                    sub(
                                        mul(returnDataWords, returnDataWords),
                                        mul(msizeWords, msizeWords)
                                    ),
                                    MemoryExpansionCoefficient
                                )
                            )
                        )
                    }

                    // Finally, add a small constant and compare to gas
                    // remaining; bubble up the revert data if enough gas is
                    // still available.
                    if lt(add(cost, ExtraGasBuffer), gas()) {
                        // Copy returndata to memory; overwrite existing memory.
                        returndatacopy(0, 0, returndatasize())

                        // Revert, giving memory region with copied returndata.
                        revert(0, returndatasize())
                    }
                }

                // Otherwise revert with a generic error message.
                mstore(
                    TokenTransferGenericFailure_error_sig_ptr,
                    TokenTransferGenericFailure_error_signature
                )
                mstore(TokenTransferGenericFailure_error_token_ptr, token)
                mstore(TokenTransferGenericFailure_error_from_ptr, from)
                mstore(TokenTransferGenericFailure_error_to_ptr, to)
                mstore(TokenTransferGenericFailure_error_id_ptr, identifier)
                mstore(TokenTransferGenericFailure_error_amount_ptr, 1)
                revert(
                    TokenTransferGenericFailure_error_sig_ptr,
                    TokenTransferGenericFailure_error_length
                )
            }

            // Restore the original free memory pointer.
            mstore(FreeMemoryPointerSlot, memPointer)

            // Restore the zero slot to zero.
            mstore(ZeroSlot, 0)
        }
    }

    /**
     * @dev Internal function to transfer ERC1155 tokens from a given
     *      originator to a given recipient. Sufficient approvals must be set on
     *      the contract performing the transfer and contract recipients must
     *      implement the ERC1155TokenReceiver interface to indicate that they
     *      are willing to accept the transfer.
     *
     * @param token      The ERC1155 token to transfer.
     * @param from       The originator of the transfer.
     * @param to         The recipient of the transfer.
     * @param identifier The id to transfer.
     * @param amount     The amount to transfer.
     */
    function _performERC1155Transfer(
        address token,
        address from,
        address to,
        uint256 identifier,
        uint256 amount
    ) internal {c_0x5e9b24d6(0x0e5a1e605c4e6a22607bd34ebc52da9dcc587e84d10f542627aa669154413f8f); /* function */ 

        // Utilize assembly to perform an optimized ERC1155 token transfer.
c_0x5e9b24d6(0xdcdeeece9841560aef73dac89e0b45c40a493fcf20a9cb482aff0200bc44a37c); /* line */ 
        assembly {
            // If the token has no code, revert.
            if iszero(extcodesize(token)) {
                mstore(NoContract_error_sig_ptr, NoContract_error_signature)
                mstore(NoContract_error_token_ptr, token)
                revert(NoContract_error_sig_ptr, NoContract_error_length)
            }

            // The following memory slots will be used when populating call data
            // for the transfer; read the values and restore them later.
            let memPointer := mload(FreeMemoryPointerSlot)
            let slot0x80 := mload(Slot0x80)
            let slot0xA0 := mload(Slot0xA0)
            let slot0xC0 := mload(Slot0xC0)

            // Write call data into memory, beginning with function selector.
            mstore(
                ERC1155_safeTransferFrom_sig_ptr,
                ERC1155_safeTransferFrom_signature
            )
            mstore(ERC1155_safeTransferFrom_from_ptr, from)
            mstore(ERC1155_safeTransferFrom_to_ptr, to)
            mstore(ERC1155_safeTransferFrom_id_ptr, identifier)
            mstore(ERC1155_safeTransferFrom_amount_ptr, amount)
            mstore(
                ERC1155_safeTransferFrom_data_offset_ptr,
                ERC1155_safeTransferFrom_data_length_offset
            )
            mstore(ERC1155_safeTransferFrom_data_length_ptr, 0)

            // Perform the call, ignoring return data.
            let success := call(
                gas(),
                token,
                0,
                ERC1155_safeTransferFrom_sig_ptr,
                ERC1155_safeTransferFrom_length,
                0,
                0
            )

            // If the transfer reverted:
            if iszero(success) {
                // If it returned a message, bubble it up as long as sufficient
                // gas remains to do so:
                if returndatasize() {
                    // Ensure that sufficient gas is available to copy
                    // returndata while expanding memory where necessary. Start
                    // by computing word size of returndata & allocated memory.
                    // Round up to the nearest full word.
                    let returnDataWords := div(
                        add(returndatasize(), AlmostOneWord),
                        OneWord
                    )

                    // Note: use the free memory pointer in place of msize() to
                    // work around a Yul warning that prevents accessing msize
                    // directly when the IR pipeline is activated.
                    let msizeWords := div(memPointer, OneWord)

                    // Next, compute the cost of the returndatacopy.
                    let cost := mul(CostPerWord, returnDataWords)

                    // Then, compute cost of new memory allocation.
                    if gt(returnDataWords, msizeWords) {
                        cost := add(
                            cost,
                            add(
                                mul(
                                    sub(returnDataWords, msizeWords),
                                    CostPerWord
                                ),
                                div(
                                    sub(
                                        mul(returnDataWords, returnDataWords),
                                        mul(msizeWords, msizeWords)
                                    ),
                                    MemoryExpansionCoefficient
                                )
                            )
                        )
                    }

                    // Finally, add a small constant and compare to gas
                    // remaining; bubble up the revert data if enough gas is
                    // still available.
                    if lt(add(cost, ExtraGasBuffer), gas()) {
                        // Copy returndata to memory; overwrite existing memory.
                        returndatacopy(0, 0, returndatasize())

                        // Revert, giving memory region with copied returndata.
                        revert(0, returndatasize())
                    }
                }

                // Otherwise revert with a generic error message.
                mstore(
                    TokenTransferGenericFailure_error_sig_ptr,
                    TokenTransferGenericFailure_error_signature
                )
                mstore(TokenTransferGenericFailure_error_token_ptr, token)
                mstore(TokenTransferGenericFailure_error_from_ptr, from)
                mstore(TokenTransferGenericFailure_error_to_ptr, to)
                mstore(TokenTransferGenericFailure_error_id_ptr, identifier)
                mstore(TokenTransferGenericFailure_error_amount_ptr, amount)
                revert(
                    TokenTransferGenericFailure_error_sig_ptr,
                    TokenTransferGenericFailure_error_length
                )
            }

            mstore(Slot0x80, slot0x80) // Restore slot 0x80.
            mstore(Slot0xA0, slot0xA0) // Restore slot 0xA0.
            mstore(Slot0xC0, slot0xC0) // Restore slot 0xC0.

            // Restore the original free memory pointer.
            mstore(FreeMemoryPointerSlot, memPointer)

            // Restore the zero slot to zero.
            mstore(ZeroSlot, 0)
        }
    }

    /**
     * @dev Internal function to transfer ERC1155 tokens from a given
     *      originator to a given recipient. Sufficient approvals must be set on
     *      the contract performing the transfer and contract recipients must
     *      implement the ERC1155TokenReceiver interface to indicate that they
     *      are willing to accept the transfer. NOTE: this function is not
     *      memory-safe; it will overwrite existing memory, restore the free
     *      memory pointer to the default value, and overwrite the zero slot.
     *      This function should only be called once memory is no longer
     *      required and when uninitialized arrays are not utilized, and memory
     *      should be considered fully corrupted (aside from the existence of a
     *      default-value free memory pointer) after calling this function.
     *
     * @param batchTransfers The group of 1155 batch transfers to perform.
     */
    function _performERC1155BatchTransfers(
        ConduitBatch1155Transfer[] calldata batchTransfers
    ) internal {c_0x5e9b24d6(0x7bfe94735d8f02affe4d7eb3e07a4f6cddd2c670ea672381f6cdb9033beed4f9); /* function */ 

        // Utilize assembly to perform optimized batch 1155 transfers.
c_0x5e9b24d6(0x401a4a1df32a0eb2b970f08ba86341636cab85421c2c96abce307c829e074115); /* line */ 
        assembly {
            let len := batchTransfers.length
            // Pointer to first head in the array, which is offset to the struct
            // at each index. This gets incremented after each loop to avoid
            // multiplying by 32 to get the offset for each element.
            let nextElementHeadPtr := batchTransfers.offset

            // Pointer to beginning of the head of the array. This is the
            // reference position each offset references. It's held static to
            // let each loop calculate the data position for an element.
            let arrayHeadPtr := nextElementHeadPtr

            // Write the function selector, which will be reused for each call:
            // safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)
            mstore(
                ConduitBatch1155Transfer_from_offset,
                ERC1155_safeBatchTransferFrom_signature
            )

            // Iterate over each batch transfer.
            for {
                let i := 0
            } lt(i, len) {
                i := add(i, 1)
            } {
                // Read the offset to the beginning of the element and add
                // it to pointer to the beginning of the array head to get
                // the absolute position of the element in calldata.
                let elementPtr := add(
                    arrayHeadPtr,
                    calldataload(nextElementHeadPtr)
                )

                // Retrieve the token from calldata.
                let token := calldataload(elementPtr)

                // If the token has no code, revert.
                if iszero(extcodesize(token)) {
                    mstore(NoContract_error_sig_ptr, NoContract_error_signature)
                    mstore(NoContract_error_token_ptr, token)
                    revert(NoContract_error_sig_ptr, NoContract_error_length)
                }

                // Get the total number of supplied ids.
                let idsLength := calldataload(
                    add(elementPtr, ConduitBatch1155Transfer_ids_length_offset)
                )

                // Determine the expected offset for the amounts array.
                let expectedAmountsOffset := add(
                    ConduitBatch1155Transfer_amounts_length_baseOffset,
                    mul(idsLength, OneWord)
                )

                // Validate struct encoding.
                let invalidEncoding := iszero(
                    and(
                        // ids.length == amounts.length
                        eq(
                            idsLength,
                            calldataload(add(elementPtr, expectedAmountsOffset))
                        ),
                        and(
                            // ids_offset == 0xa0
                            eq(
                                calldataload(
                                    add(
                                        elementPtr,
                                        ConduitBatch1155Transfer_ids_head_offset
                                    )
                                ),
                                ConduitBatch1155Transfer_ids_length_offset
                            ),
                            // amounts_offset == 0xc0 + ids.length*32
                            eq(
                                calldataload(
                                    add(
                                        elementPtr,
                                        ConduitBatchTransfer_amounts_head_offset
                                    )
                                ),
                                expectedAmountsOffset
                            )
                        )
                    )
                )

                // Revert with an error if the encoding is not valid.
                if invalidEncoding {
                    mstore(
                        Invalid1155BatchTransferEncoding_ptr,
                        Invalid1155BatchTransferEncoding_selector
                    )
                    revert(
                        Invalid1155BatchTransferEncoding_ptr,
                        Invalid1155BatchTransferEncoding_length
                    )
                }

                // Update the offset position for the next loop
                nextElementHeadPtr := add(nextElementHeadPtr, OneWord)

                // Copy the first section of calldata (before dynamic values).
                calldatacopy(
                    BatchTransfer1155Params_ptr,
                    add(elementPtr, ConduitBatch1155Transfer_from_offset),
                    ConduitBatch1155Transfer_usable_head_size
                )

                // Determine size of calldata required for ids and amounts. Note
                // that the size includes both lengths as well as the data.
                let idsAndAmountsSize := add(TwoWords, mul(idsLength, TwoWords))

                // Update the offset for the data array in memory.
                mstore(
                    BatchTransfer1155Params_data_head_ptr,
                    add(
                        BatchTransfer1155Params_ids_length_offset,
                        idsAndAmountsSize
                    )
                )

                // Set the length of the data array in memory to zero.
                mstore(
                    add(
                        BatchTransfer1155Params_data_length_basePtr,
                        idsAndAmountsSize
                    ),
                    0
                )

                // Determine the total calldata size for the call to transfer.
                let transferDataSize := add(
                    BatchTransfer1155Params_calldata_baseSize,
                    idsAndAmountsSize
                )

                // Copy second section of calldata (including dynamic values).
                calldatacopy(
                    BatchTransfer1155Params_ids_length_ptr,
                    add(elementPtr, ConduitBatch1155Transfer_ids_length_offset),
                    idsAndAmountsSize
                )

                // Perform the call to transfer 1155 tokens.
                let success := call(
                    gas(),
                    token,
                    0,
                    ConduitBatch1155Transfer_from_offset, // Data portion start.
                    transferDataSize, // Location of the length of callData.
                    0,
                    0
                )

                // If the transfer reverted:
                if iszero(success) {
                    // If it returned a message, bubble it up as long as
                    // sufficient gas remains to do so:
                    if returndatasize() {
                        // Ensure that sufficient gas is available to copy
                        // returndata while expanding memory where necessary.
                        // Start by computing word size of returndata and
                        // allocated memory. Round up to the nearest full word.
                        let returnDataWords := div(
                            add(returndatasize(), AlmostOneWord),
                            OneWord
                        )

                        // Note: use transferDataSize in place of msize() to
                        // work around a Yul warning that prevents accessing
                        // msize directly when the IR pipeline is activated.
                        // The free memory pointer is not used here because
                        // this function does almost all memory management
                        // manually and does not update it, and transferDataSize
                        // should be the largest memory value used (unless a
                        // previous batch was larger).
                        let msizeWords := div(transferDataSize, OneWord)

                        // Next, compute the cost of the returndatacopy.
                        let cost := mul(CostPerWord, returnDataWords)

                        // Then, compute cost of new memory allocation.
                        if gt(returnDataWords, msizeWords) {
                            cost := add(
                                cost,
                                add(
                                    mul(
                                        sub(returnDataWords, msizeWords),
                                        CostPerWord
                                    ),
                                    div(
                                        sub(
                                            mul(
                                                returnDataWords,
                                                returnDataWords
                                            ),
                                            mul(msizeWords, msizeWords)
                                        ),
                                        MemoryExpansionCoefficient
                                    )
                                )
                            )
                        }

                        // Finally, add a small constant and compare to gas
                        // remaining; bubble up the revert data if enough gas is
                        // still available.
                        if lt(add(cost, ExtraGasBuffer), gas()) {
                            // Copy returndata to memory; overwrite existing.
                            returndatacopy(0, 0, returndatasize())

                            // Revert with memory region containing returndata.
                            revert(0, returndatasize())
                        }
                    }

                    // Set the error signature.
                    mstore(
                        0,
                        ERC1155BatchTransferGenericFailure_error_signature
                    )

                    // Write the token.
                    mstore(ERC1155BatchTransferGenericFailure_token_ptr, token)

                    // Increase the offset to ids by 32.
                    mstore(
                        BatchTransfer1155Params_ids_head_ptr,
                        ERC1155BatchTransferGenericFailure_ids_offset
                    )

                    // Increase the offset to amounts by 32.
                    mstore(
                        BatchTransfer1155Params_amounts_head_ptr,
                        add(
                            OneWord,
                            mload(BatchTransfer1155Params_amounts_head_ptr)
                        )
                    )

                    // Return modified region. The total size stays the same as
                    // `token` uses the same number of bytes as `data.length`.
                    revert(0, transferDataSize)
                }
            }

            // Reset the free memory pointer to the default value; memory must
            // be assumed to be dirtied and not reused from this point forward.
            // Also note that the zero slot is not reset to zero, meaning empty
            // arrays cannot be safely created or utilized until it is restored.
            mstore(FreeMemoryPointerSlot, DefaultFreeMemoryPointer)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { ConduitItemType } from "./ConduitEnums.sol";

struct ConduitTransfer {
    ConduitItemType itemType;
    address token;
    address from;
    address to;
    uint256 identifier;
    uint256 amount;
}

struct ConduitBatch1155Transfer {
    address token;
    address from;
    address to;
    uint256[] ids;
    uint256[] amounts;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0x4bb76530(bytes32 c__0x4bb76530) pure {}


// error ChannelClosed(address channel)
uint256 constant ChannelClosed_error_signature = (
    0x93daadf200000000000000000000000000000000000000000000000000000000
);
uint256 constant ChannelClosed_error_ptr = 0x00;
uint256 constant ChannelClosed_channel_ptr = 0x4;
uint256 constant ChannelClosed_error_length = 0x24;

// For the mapping:
// mapping(address => bool) channels
// The position in storage for a particular account is:
// keccak256(abi.encode(account, channels.slot))
uint256 constant ChannelKey_channel_ptr = 0x00;
uint256 constant ChannelKey_slot_ptr = 0x20;
uint256 constant ChannelKey_length = 0x40;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0x5c8a1401(bytes32 c__0x5c8a1401) pure {}


/*
 * -------------------------- Disambiguation & Other Notes ---------------------
 *    - The term "head" is used as it is in the documentation for ABI encoding,
 *      but only in reference to dynamic types, i.e. it always refers to the
 *      offset or pointer to the body of a dynamic type. In calldata, the head
 *      is always an offset (relative to the parent object), while in memory,
 *      the head is always the pointer to the body. More information found here:
 *      https://docs.soliditylang.org/en/v0.8.14/abi-spec.html#argument-encoding
 *        - Note that the length of an array is separate from and precedes the
 *          head of the array.
 *
 *    - The term "body" is used in place of the term "head" used in the ABI
 *      documentation. It refers to the start of the data for a dynamic type,
 *      e.g. the first word of a struct or the first word of the first element
 *      in an array.
 *
 *    - The term "pointer" is used to describe the absolute position of a value
 *      and never an offset relative to another value.
 *        - The suffix "_ptr" refers to a memory pointer.
 *        - The suffix "_cdPtr" refers to a calldata pointer.
 *
 *    - The term "offset" is used to describe the position of a value relative
 *      to some parent value. For example, OrderParameters_conduit_offset is the
 *      offset to the "conduit" value in the OrderParameters struct relative to
 *      the start of the body.
 *        - Note: Offsets are used to derive pointers.
 *
 *    - Some structs have pointers defined for all of their fields in this file.
 *      Lines which are commented out are fields that are not used in the
 *      codebase but have been left in for readability.
 */

uint256 constant AlmostOneWord = 0x1f;
uint256 constant OneWord = 0x20;
uint256 constant TwoWords = 0x40;
uint256 constant ThreeWords = 0x60;

uint256 constant FreeMemoryPointerSlot = 0x40;
uint256 constant ZeroSlot = 0x60;
uint256 constant DefaultFreeMemoryPointer = 0x80;

uint256 constant Slot0x80 = 0x80;
uint256 constant Slot0xA0 = 0xa0;
uint256 constant Slot0xC0 = 0xc0;

// abi.encodeWithSignature("transferFrom(address,address,uint256)")
uint256 constant ERC20_transferFrom_signature = (
    0x23b872dd00000000000000000000000000000000000000000000000000000000
);
uint256 constant ERC20_transferFrom_sig_ptr = 0x0;
uint256 constant ERC20_transferFrom_from_ptr = 0x04;
uint256 constant ERC20_transferFrom_to_ptr = 0x24;
uint256 constant ERC20_transferFrom_amount_ptr = 0x44;
uint256 constant ERC20_transferFrom_length = 0x64; // 4 + 32 * 3 == 100

// abi.encodeWithSignature(
//     "safeTransferFrom(address,address,uint256,uint256,bytes)"
// )
uint256 constant ERC1155_safeTransferFrom_signature = (
    0xf242432a00000000000000000000000000000000000000000000000000000000
);
uint256 constant ERC1155_safeTransferFrom_sig_ptr = 0x0;
uint256 constant ERC1155_safeTransferFrom_from_ptr = 0x04;
uint256 constant ERC1155_safeTransferFrom_to_ptr = 0x24;
uint256 constant ERC1155_safeTransferFrom_id_ptr = 0x44;
uint256 constant ERC1155_safeTransferFrom_amount_ptr = 0x64;
uint256 constant ERC1155_safeTransferFrom_data_offset_ptr = 0x84;
uint256 constant ERC1155_safeTransferFrom_data_length_ptr = 0xa4;
uint256 constant ERC1155_safeTransferFrom_length = 0xc4; // 4 + 32 * 6 == 196
uint256 constant ERC1155_safeTransferFrom_data_length_offset = 0xa0;

// abi.encodeWithSignature(
//     "safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)"
// )
uint256 constant ERC1155_safeBatchTransferFrom_signature = (
    0x2eb2c2d600000000000000000000000000000000000000000000000000000000
);

bytes4 constant ERC1155_safeBatchTransferFrom_selector = bytes4(
    bytes32(ERC1155_safeBatchTransferFrom_signature)
);

uint256 constant ERC721_transferFrom_signature = ERC20_transferFrom_signature;
uint256 constant ERC721_transferFrom_sig_ptr = 0x0;
uint256 constant ERC721_transferFrom_from_ptr = 0x04;
uint256 constant ERC721_transferFrom_to_ptr = 0x24;
uint256 constant ERC721_transferFrom_id_ptr = 0x44;
uint256 constant ERC721_transferFrom_length = 0x64; // 4 + 32 * 3 == 100

// abi.encodeWithSignature("NoContract(address)")
uint256 constant NoContract_error_signature = (
    0x5f15d67200000000000000000000000000000000000000000000000000000000
);
uint256 constant NoContract_error_sig_ptr = 0x0;
uint256 constant NoContract_error_token_ptr = 0x4;
uint256 constant NoContract_error_length = 0x24; // 4 + 32 == 36

// abi.encodeWithSignature(
//     "TokenTransferGenericFailure(address,address,address,uint256,uint256)"
// )
uint256 constant TokenTransferGenericFailure_error_signature = (
    0xf486bc8700000000000000000000000000000000000000000000000000000000
);
uint256 constant TokenTransferGenericFailure_error_sig_ptr = 0x0;
uint256 constant TokenTransferGenericFailure_error_token_ptr = 0x4;
uint256 constant TokenTransferGenericFailure_error_from_ptr = 0x24;
uint256 constant TokenTransferGenericFailure_error_to_ptr = 0x44;
uint256 constant TokenTransferGenericFailure_error_id_ptr = 0x64;
uint256 constant TokenTransferGenericFailure_error_amount_ptr = 0x84;

// 4 + 32 * 5 == 164
uint256 constant TokenTransferGenericFailure_error_length = 0xa4;

// abi.encodeWithSignature(
//     "BadReturnValueFromERC20OnTransfer(address,address,address,uint256)"
// )
uint256 constant BadReturnValueFromERC20OnTransfer_error_signature = (
    0x9889192300000000000000000000000000000000000000000000000000000000
);
uint256 constant BadReturnValueFromERC20OnTransfer_error_sig_ptr = 0x0;
uint256 constant BadReturnValueFromERC20OnTransfer_error_token_ptr = 0x4;
uint256 constant BadReturnValueFromERC20OnTransfer_error_from_ptr = 0x24;
uint256 constant BadReturnValueFromERC20OnTransfer_error_to_ptr = 0x44;
uint256 constant BadReturnValueFromERC20OnTransfer_error_amount_ptr = 0x64;

// 4 + 32 * 4 == 132
uint256 constant BadReturnValueFromERC20OnTransfer_error_length = 0x84;

uint256 constant ExtraGasBuffer = 0x20;
uint256 constant CostPerWord = 3;
uint256 constant MemoryExpansionCoefficient = 0x200;

// Values are offset by 32 bytes in order to write the token to the beginning
// in the event of a revert
uint256 constant BatchTransfer1155Params_ptr = 0x24;
uint256 constant BatchTransfer1155Params_ids_head_ptr = 0x64;
uint256 constant BatchTransfer1155Params_amounts_head_ptr = 0x84;
uint256 constant BatchTransfer1155Params_data_head_ptr = 0xa4;
uint256 constant BatchTransfer1155Params_data_length_basePtr = 0xc4;
uint256 constant BatchTransfer1155Params_calldata_baseSize = 0xc4;

uint256 constant BatchTransfer1155Params_ids_length_ptr = 0xc4;

uint256 constant BatchTransfer1155Params_ids_length_offset = 0xa0;
uint256 constant BatchTransfer1155Params_amounts_length_baseOffset = 0xc0;
uint256 constant BatchTransfer1155Params_data_length_baseOffset = 0xe0;

uint256 constant ConduitBatch1155Transfer_usable_head_size = 0x80;

uint256 constant ConduitBatch1155Transfer_from_offset = 0x20;
uint256 constant ConduitBatch1155Transfer_ids_head_offset = 0x60;
uint256 constant ConduitBatch1155Transfer_amounts_head_offset = 0x80;
uint256 constant ConduitBatch1155Transfer_ids_length_offset = 0xa0;
uint256 constant ConduitBatch1155Transfer_amounts_length_baseOffset = 0xc0;
uint256 constant ConduitBatch1155Transfer_calldata_baseSize = 0xc0;

// Note: abbreviated version of above constant to adhere to line length limit.
uint256 constant ConduitBatchTransfer_amounts_head_offset = 0x80;

uint256 constant Invalid1155BatchTransferEncoding_ptr = 0x00;
uint256 constant Invalid1155BatchTransferEncoding_length = 0x04;
uint256 constant Invalid1155BatchTransferEncoding_selector = (
    0xeba2084c00000000000000000000000000000000000000000000000000000000
);

uint256 constant ERC1155BatchTransferGenericFailure_error_signature = (
    0xafc445e200000000000000000000000000000000000000000000000000000000
);
uint256 constant ERC1155BatchTransferGenericFailure_token_ptr = 0x04;
uint256 constant ERC1155BatchTransferGenericFailure_ids_offset = 0xc0;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0xa669d7fb(bytes32 c__0xa669d7fb) pure {}


/**
 * @title TokenTransferrerErrors
 */
interface TokenTransferrerErrors {
    /**
     * @dev Revert with an error when an ERC721 transfer with amount other than
     *      one is attempted.
     */
    error InvalidERC721TransferAmount();

    /**
     * @dev Revert with an error when attempting to fulfill an order where an
     *      item has an amount of zero.
     */
    error MissingItemAmount();

    /**
     * @dev Revert with an error when attempting to fulfill an order where an
     *      item has unused parameters. This includes both the token and the
     *      identifier parameters for native transfers as well as the identifier
     *      parameter for ERC20 transfers. Note that the conduit does not
     *      perform this check, leaving it up to the calling channel to enforce
     *      when desired.
     */
    error UnusedItemParameters();

    /**
     * @dev Revert with an error when an ERC20, ERC721, or ERC1155 token
     *      transfer reverts.
     *
     * @param token      The token for which the transfer was attempted.
     * @param from       The source of the attempted transfer.
     * @param to         The recipient of the attempted transfer.
     * @param identifier The identifier for the attempted transfer.
     * @param amount     The amount for the attempted transfer.
     */
    error TokenTransferGenericFailure(
        address token,
        address from,
        address to,
        uint256 identifier,
        uint256 amount
    );

    /**
     * @dev Revert with an error when a batch ERC1155 token transfer reverts.
     *
     * @param token       The token for which the transfer was attempted.
     * @param from        The source of the attempted transfer.
     * @param to          The recipient of the attempted transfer.
     * @param identifiers The identifiers for the attempted transfer.
     * @param amounts     The amounts for the attempted transfer.
     */
    error ERC1155BatchTransferGenericFailure(
        address token,
        address from,
        address to,
        uint256[] identifiers,
        uint256[] amounts
    );

    /**
     * @dev Revert with an error when an ERC20 token transfer returns a falsey
     *      value.
     *
     * @param token      The token for which the ERC20 transfer was attempted.
     * @param from       The source of the attempted ERC20 transfer.
     * @param to         The recipient of the attempted ERC20 transfer.
     * @param amount     The amount for the attempted ERC20 transfer.
     */
    error BadReturnValueFromERC20OnTransfer(
        address token,
        address from,
        address to,
        uint256 amount
    );

    /**
     * @dev Revert with an error when an account being called as an assumed
     *      contract does not have code and returns no data.
     *
     * @param account The account that should contain code.
     */
    error NoContract(address account);

    /**
     * @dev Revert with an error when attempting to execute an 1155 batch
     *      transfer using calldata not produced by default ABI encoding or with
     *      different lengths for ids and amounts arrays.
     */
    error Invalid1155BatchTransferEncoding();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0xbfa668b7(bytes32 c__0xbfa668b7) pure {}


import { IERC721Receiver } from "../interfaces/IERC721Receiver.sol";

import "./TransferHelperStructs.sol";

import { ConduitInterface } from "../interfaces/ConduitInterface.sol";

import {
    ConduitControllerInterface
} from "../interfaces/ConduitControllerInterface.sol";

import { Conduit } from "../conduit/Conduit.sol";

import { ConduitTransfer } from "../conduit/lib/ConduitStructs.sol";

import {
    TransferHelperInterface
} from "../interfaces/TransferHelperInterface.sol";

import { TransferHelperErrors } from "../interfaces/TransferHelperErrors.sol";

/**
 * @title TransferHelper
 * @author stephankmin, stuckinaboot, ryanio
 * @notice TransferHelper is a utility contract for transferring
 *         ERC20/ERC721/ERC1155 items in bulk to specific recipients.
 */
contract TransferHelper is TransferHelperInterface, TransferHelperErrors {
function c_0xedfe966c(bytes32 c__0xedfe966c) internal pure {}

    // Allow for interaction with the conduit controller.
    ConduitControllerInterface internal immutable _CONDUIT_CONTROLLER;

    // Set conduit creation code and runtime code hashes as immutable arguments.
    bytes32 internal immutable _CONDUIT_CREATION_CODE_HASH;
    bytes32 internal immutable _CONDUIT_RUNTIME_CODE_HASH;

    /**
     * @dev Set the supplied conduit controller and retrieve its
     *      conduit creation code hash.
     *
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     */
    constructor(address conduitController) {c_0xedfe966c(0x4fe739f23bea8ff04a7fdb8c5377a59798c64ddec95ccc859c64e2ed46da7223); /* function */ 

        // Get the conduit creation code and runtime code hashes from the
        // supplied conduit controller and set them as an immutable.
c_0xedfe966c(0x1ec0cc862956da18f4bfd59b9aee87b91052089e8cd69e8c4c915b7508586cca); /* line */ 
        c_0xedfe966c(0x6271445a454da829d7170df18bb31ab3bfe565bcaad1791c3aa7fe9f59179a36); /* statement */ 
ConduitControllerInterface controller = ConduitControllerInterface(
            conduitController
        );
c_0xedfe966c(0x676e0733d2f94a19c9a1119f3c5d96a162ba70506e21c003a9b66d18e0bc5902); /* line */ 
        c_0xedfe966c(0xaeb779d3dcca7535525993b2ca531af08bf3afc4a2ff52b284db796b0e93d986); /* statement */ 
(_CONDUIT_CREATION_CODE_HASH, _CONDUIT_RUNTIME_CODE_HASH) = controller
            .getConduitCodeHashes();

        // Set the supplied conduit controller as an immutable.
c_0xedfe966c(0xd70e3d0a7477646896395b59847aee091607ae162971685e3c563e6977da2bd7); /* line */ 
        c_0xedfe966c(0x9868409b343447a92646bbd9908c1a0f699f2db000c18b2e665adead57539e3a); /* statement */ 
_CONDUIT_CONTROLLER = controller;
    }

    /**
     * @notice Transfer multiple ERC20/ERC721/ERC1155 items to
     *         specified recipients.
     *
     * @param items      The items to transfer to an intended recipient.
     * @param conduitKey An optional conduit key referring to a conduit through
     *                   which the bulk transfer should occur.
     *
     * @return magicValue A value indicating that the transfers were successful.
     */
    function bulkTransfer(
        TransferHelperItemsWithRecipient[] calldata items,
        bytes32 conduitKey
    ) external override returns (bytes4 magicValue) {c_0xedfe966c(0x5e1ef6cf019c5a54397d8e8dd75e6ad9213a723f632301e032975166bcae3b15); /* function */ 

        // Ensure that a conduit key has been supplied.
c_0xedfe966c(0x1c041c513b987cd35caa5cb2257d215b9c1d490fc96df88b15108e0eb7075b84); /* line */ 
        c_0xedfe966c(0x464ad37d212a044d3139eca2d0b4e3add50ac1a64cd85051d4ccb4a39a963970); /* statement */ 
if (conduitKey == bytes32(0)) {c_0xedfe966c(0x95287547cade1708157d812bd627ca77cebbc269207d33a9b841bd2a904e6206); /* branch */ 

c_0xedfe966c(0x70430ad58a975379333075f2723bdd101b35fe94f53fa67759fd651010b3a382); /* line */ 
            revert InvalidConduit(conduitKey, address(0));
        }else { c_0xedfe966c(0x5f798db0cbb70ce253bd7646f7fb0cb6688b34fa54370117182d46663ff7670e); /* branch */ 
}

        // Use conduit derived from supplied conduit key to perform transfers.
c_0xedfe966c(0xe8cabc2bebbb23c7d11659a99303b3baaed93c0aed4c44316271ff4329bace39); /* line */ 
        c_0xedfe966c(0xa734eadebb652ab5fdf2da576499d694ea19bdf6dddd83c3d5d66fba023ab2bd); /* statement */ 
_performTransfersWithConduit(items, conduitKey);

        // Return a magic value indicating that the transfers were performed.
c_0xedfe966c(0x74c1a94fcfee37740afe9f5e3268d78d7d6b28a83e94c7092b5d14c4ab6bcedd); /* line */ 
        c_0xedfe966c(0xd4c4a07f1a8b6c77e384dab1c05b22fcd25ab24a7170e53577b92859f4e934b9); /* statement */ 
magicValue = this.bulkTransfer.selector;
    }

    /**
     * @notice Perform multiple transfers to specified recipients via the
     *         conduit derived from the provided conduit key.
     *
     * @param transfers  The items to transfer.
     * @param conduitKey The conduit key referring to the conduit through
     *                   which the bulk transfer should occur.
     */
    function _performTransfersWithConduit(
        TransferHelperItemsWithRecipient[] calldata transfers,
        bytes32 conduitKey
    ) internal {c_0xedfe966c(0x274ecf62b3489ddc79dc5d6484e9bf8d3dcccd136b3d078b8734caad62ac8de8); /* function */ 

        // Retrieve total number of transfers and place on stack.
c_0xedfe966c(0x176bcd8e468001c25450dfc555f186ec9db02097c36af8d74cfdac68c26fc3b3); /* line */ 
        c_0xedfe966c(0x2752e037e3c9fc204f9e7972564129d6cb3e2fd7d40abe4afb128d626894b08c); /* statement */ 
uint256 numTransfers = transfers.length;

        // Derive the conduit address from the deployer, conduit key
        // and creation code hash.
c_0xedfe966c(0x55f0f90640f8cd969df15ce203f57e7138c97c54eeee0857a7b3b1ddd3133d00); /* line */ 
        c_0xedfe966c(0xe8a5a8fb953e05b87f33e6832bfd7d8f94e7b7bad38e76578f1d8ad2a4de46ee); /* statement */ 
address conduit = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(_CONDUIT_CONTROLLER),
                            conduitKey,
                            _CONDUIT_CREATION_CODE_HASH
                        )
                    )
                )
            )
        );

        // Declare a variable to store the sum of all items across transfers.
c_0xedfe966c(0x960a270db341900ddf7d802da3e5aae62dcda6345e31eb0ec14bee8227fa86c4); /* line */ 
        c_0xedfe966c(0xfd69e1ba42cf677565146105ab3bc495016ee5ac1c1fc92faf58aa24157d9661); /* statement */ 
uint256 sumOfItemsAcrossAllTransfers;

        // Skip overflow checks: all for loops are indexed starting at zero.
c_0xedfe966c(0xa4c002c679b2b5afcc7e2bf98749350c57230269901bbd1892b4591b0235c490); /* line */ 
        unchecked {
            // Iterate over each transfer.
c_0xedfe966c(0x1c4ba646d8d1323fbd9a43b169bf0d9a3c0dae72099643f157c0a4af88ac2785); /* line */ 
            c_0xedfe966c(0x06967ba2adf94423267c554782a8875d815cb4cf78c83a124af8a0e33c40bbfd); /* statement */ 
for (uint256 i = 0; i < numTransfers; ++i) {
                // Retrieve the transfer in question.
c_0xedfe966c(0xce58865a794397cee3c1af9b7be93a71f2eae574baac1e094d61fb7f5449b7cc); /* line */ 
                c_0xedfe966c(0x17796d8cfa547b8bc92406d82f2f864b221b5b787df47e7d276970ac63ce0599); /* statement */ 
TransferHelperItemsWithRecipient calldata transfer = transfers[
                    i
                ];

                // Increment totalItems by the number of items in the transfer.
c_0xedfe966c(0xb9495935fb061c04f8be9367b1b0abd0e12ab49b49416d0f7f12b95e11fdf009); /* line */ 
                c_0xedfe966c(0xd4278a986461e1cb3071e75701a982941a644d6de97d12a682c93cf9e7aeffff); /* statement */ 
sumOfItemsAcrossAllTransfers += transfer.items.length;
            }
        }

        // Declare a new array in memory with length totalItems to populate with
        // each conduit transfer.
c_0xedfe966c(0x622a19e7b479f9808b8d689e79127fe3245e90489b758917d1d986fc7899fd2e); /* line */ 
        c_0xedfe966c(0x893e637d64c89f6291c6e5822b86f4e523a2460d1e637bd52d3af7dc5fa8f244); /* statement */ 
ConduitTransfer[] memory conduitTransfers = new ConduitTransfer[](
            sumOfItemsAcrossAllTransfers
        );

        // Declare an index for storing ConduitTransfers in conduitTransfers.
c_0xedfe966c(0xf8039de39495b25ecbb9e840242a057283b15e20f5aa2f6b2e70d1d57cdc6305); /* line */ 
        c_0xedfe966c(0x604c6cecb7521e91ccfe971cbca545583478694aa2f67f6a60ed0bc733503172); /* statement */ 
uint256 itemIndex;

        // Skip overflow checks: all for loops are indexed starting at zero.
c_0xedfe966c(0x8acb4979bd3688da51172fac2cc59a7322c5b233fbbf2495b1e47e3f72abd5b8); /* line */ 
        unchecked {
            // Iterate over each transfer.
c_0xedfe966c(0xc973acf0a3d5939f6f01e4250f30393b35a560cb3127229038c95e532745baac); /* line */ 
            c_0xedfe966c(0x45ba6c07fc0e2fc5ec5bfc446401bee6b4afa926f836af1cc9d82a0d1a97dc2b); /* statement */ 
for (uint256 i = 0; i < numTransfers; ++i) {
                // Retrieve the transfer in question.
c_0xedfe966c(0xbbb760aa7ad42ae6add65a6c9b014ecb34e43be79ec157525fb75306497150f4); /* line */ 
                c_0xedfe966c(0x86671a7cc2b0f71fb579375063de10f77d4dcd3b2d59c855bb9b963647bf6e14); /* statement */ 
TransferHelperItemsWithRecipient calldata transfer = transfers[
                    i
                ];

                // Retrieve the items of the transfer in question.
c_0xedfe966c(0x4dd8961e1b06a7cafff44a32ea2433ae60a0c9386a5aa0ef646df1c3fd5b85e5); /* line */ 
                c_0xedfe966c(0xa37b954bb73c3d217bbab9ceafb39236a91faf1a2ce00fd3173e1b1a9bbcbdc7); /* statement */ 
TransferHelperItem[] calldata transferItems = transfer.items;

                // Ensure recipient is not the zero address.
c_0xedfe966c(0xcef2e1cb00faeb6bee44bae4c0fc46c9f26d244a9df6539b6ee9ad8b558370ac); /* line */ 
                c_0xedfe966c(0xde82f66205ae22d1247d4b8ede41d07bb129fa535b928fbdeb0103b83b8cb37d); /* statement */ 
_checkRecipientIsNotZeroAddress(transfer.recipient);

                // Create a boolean indicating whether validateERC721Receiver
                // is true and recipient is a contract.
c_0xedfe966c(0x34b0242655a2777aed6d72265ff5a6d6c88e47a36e2b72111ae9d2dfe30bdb17); /* line */ 
                c_0xedfe966c(0x3af2d5ae1f2f63ba377764ca472a7c4151e7b73d4b9d964c195d1de87d5fe8b0); /* statement */ 
bool callERC721Receiver = transfer.validateERC721Receiver &&
                    transfer.recipient.code.length != 0;

                // Retrieve the total number of items in the transfer and
                // place on stack.
c_0xedfe966c(0x6ad2c95ce22df4b914892854dfd1ce6e1825091157002e02e1d25d527d74a3db); /* line */ 
                c_0xedfe966c(0x1eafa791d29a915fe370c4f8cfe17845a981a1e19eaf76c61a62933353465eb1); /* statement */ 
uint256 numItemsInTransfer = transferItems.length;

                // Iterate over each item in the transfer to create a
                // corresponding ConduitTransfer.
c_0xedfe966c(0x2a7040c8fd4850700672f1a186a361586884209375e8e928a066da8d973a537e); /* line */ 
                c_0xedfe966c(0x031c31ceacc6d61b2b84d1323d04101ac77080260aa22ce7505add06ca55e87e); /* statement */ 
for (uint256 j = 0; j < numItemsInTransfer; ++j) {
                    // Retrieve the item from the transfer.
c_0xedfe966c(0x36cc8ebfdb97ddecc93f35f73e87894034dc3c02a84f1a56adbd8a408c83f5cc); /* line */ 
                    c_0xedfe966c(0x4f17d845952a24134f12041f182d9c023a08f797977b8fdcbca93a5b84d9bc0b); /* statement */ 
TransferHelperItem calldata item = transferItems[j];

c_0xedfe966c(0xa2e16b885044db9f94192babd1925f928dffac268683224485ec8c4994a28171); /* line */ 
                    c_0xedfe966c(0x745bfe238e0b4c179701e715c3dfa1e69b92bf66487e3b497bca4f3653d7d7f9); /* statement */ 
if (item.itemType == ConduitItemType.ERC20) {c_0xedfe966c(0x2704902080538869227ed625554e06452f8430ab6d1b25649bcff6f732a723e5); /* branch */ 

                        // Ensure that the identifier of an ERC20 token is 0.
c_0xedfe966c(0x12d4590efb7318ac67297ca37623622ec0a778f4985d87969908488b148aee7f); /* line */ 
                        c_0xedfe966c(0x5b534236324384dfe46a9d09f0c55023059198bfec95e25d44b71a36603a9828); /* statement */ 
if (item.identifier != 0) {c_0xedfe966c(0x1889ac66fbede186beb8cfc7c171a63d17c2d169997847fa77035a947444a7bf); /* branch */ 

c_0xedfe966c(0xabc3a72e2ce0ff391561e1e8eeb82183a7932eab4e5e7ac1ca452f51090483f7); /* line */ 
                            revert InvalidERC20Identifier();
                        }else { c_0xedfe966c(0xbe3ced8b4c927518c895378dc0cb9ceae6951479a5ac137c736cf7496837c92b); /* branch */ 
}
                    }else { c_0xedfe966c(0x9118967cbe74db1a2cf6ba40bff05023239fb56102936068c0f23b593e92c4b8); /* branch */ 
}

                    // If the item is an ERC721 token and
                    // callERC721Receiver is true...
c_0xedfe966c(0xe6ddac5238542a10541531bee109436aeab7e21c2d473bd0063c72d526caf12f); /* line */ 
                    c_0xedfe966c(0x0e2f486ada3c668fd242629897a6b89cd772e775e831158a40ee35344e1f82bb); /* statement */ 
if (item.itemType == ConduitItemType.ERC721) {c_0xedfe966c(0x6d842ad7f497ea143dbcfdcf6fa759f1060bd3d832357127ddd899e53fbad433); /* branch */ 

c_0xedfe966c(0xd55d2294477f0be02c7183bd47ace542a69fa6a85b69709052abf4c21b882638); /* line */ 
                        c_0xedfe966c(0x3b328b15e0a446a8845f31cc0d9b60a71ffff4e659753726bf1ba64dead42284); /* statement */ 
if (callERC721Receiver) {c_0xedfe966c(0xc91fb8531c51043c4c1d48f04f3f682b9da0191b96924d21c42d27643c4b680a); /* branch */ 

                            // Check if the recipient implements
                            // onERC721Received for the given tokenId.
c_0xedfe966c(0x7aad37a3f58d0332e1336497dbf6596866f225e0eba0c6c528dad98d73a599ba); /* line */ 
                            c_0xedfe966c(0xf8f84de838c9b6a6dd9ac146de14eca00870696e76bc22f1388454f41d5de11b); /* statement */ 
_checkERC721Receiver(
                                conduit,
                                transfer.recipient,
                                item.identifier
                            );
                        }else { c_0xedfe966c(0xb82a4a9198cc9c1c86c36b6b61a36e24391c1a473676ca36dc1b564258404007); /* branch */ 
}
                    }else { c_0xedfe966c(0x0838bb851042effe4ad2b76261ff399867a8fa5b26293a5547a9760be1338367); /* branch */ 
}

                    // Create a ConduitTransfer corresponding to each
                    // TransferHelperItem.
c_0xedfe966c(0x00e330c08fa3a70ac4021c6ae3d511d431f163cc3f3cbdd9d4c6033a75dd70cb); /* line */ 
                    c_0xedfe966c(0x1d6d813cb692db1b037774a08c8153a637909c5846e88c3404c4faa9aae16091); /* statement */ 
conduitTransfers[itemIndex] = ConduitTransfer(
                        item.itemType,
                        item.token,
                        msg.sender,
                        transfer.recipient,
                        item.identifier,
                        item.amount
                    );

                    // Increment the index for storing ConduitTransfers.
c_0xedfe966c(0x5e19f61507b72f6cd2542e307315cb41c85a7ec86e69784eff062d8cba82815f); /* line */ 
                    ++itemIndex;
                }
            }
        }

        // Attempt the external call to transfer tokens via the derived conduit.
c_0xedfe966c(0x69bb29ad5ce75b1bb921beaf518f9c402eac8cb6cdcd7f66cce4e0964f52bacd); /* line */ 
        c_0xedfe966c(0x777152c0d78b046b77bc55a5ca448c1884ad208b7143b160d090384d75e9d71e); /* statement */ 
try ConduitInterface(conduit).execute(conduitTransfers) returns (
            bytes4 conduitMagicValue
        ) {
            // Check if the value returned from the external call matches
            // the conduit `execute` selector.
c_0xedfe966c(0x91bcbd7476901672b1249557264b73497677e2ad86aa840c3a7edc16ef7c6746); /* line */ 
            c_0xedfe966c(0x8dbc5becd1c9c9b9bd93fc25bd7df76a6c4a0d92c19dca026c75a965f29dc27f); /* statement */ 
if (conduitMagicValue != ConduitInterface.execute.selector) {c_0xedfe966c(0xeb73d0c0c10c86a45362caee6066f98e04955c5ed6f646e4da9132c66249af36); /* branch */ 

                // If the external call fails, revert with the conduit key
                // and conduit address.
c_0xedfe966c(0xfdfb9834c00d2651ec6bc2b22e60bd906a03e01f66f76fd71681ac70bccbb0b0); /* line */ 
                revert InvalidConduit(conduitKey, conduit);
            }else { c_0xedfe966c(0x653776cae8dc9aadb8d2b6baee502ef13e52b5c80d5968bb9c31802d32f1499f); /* branch */ 
}
        } catch Error(string memory reason) {
            // Catch reverts with a provided reason string and
            // revert with the reason, conduit key and conduit address.
c_0xedfe966c(0x29b3d4a0483bc9f4ed6f156f0c914532fabc416a4cc403729fc4c3d2dd8ce111); /* line */ 
            revert ConduitErrorRevertString(reason, conduitKey, conduit);
        } catch (bytes memory data) {
            // Conduits will throw a custom error when attempting to transfer
            // native token item types or an ERC721 item amount other than 1.
            // Bubble up these custom errors when encountered. Note that the
            // conduit itself will bubble up revert reasons from transfers as
            // well, meaning that these errors are not necessarily indicative of
            // an issue with the item type or amount in cases where the same
            // custom error signature is encountered during a conduit transfer.

            // Set initial value of first four bytes of revert data to the mask.
c_0xedfe966c(0xc0d3fe94826397507d1ac1f308ffe3d07d8f1f52462273a1d8a7113711267d97); /* line */ 
            c_0xedfe966c(0x68bc2efe393f43dee0c79fd53cbac1c52b81f1616b1a92acd047c42a34563567); /* statement */ 
bytes4 customErrorSelector = bytes4(0xffffffff);

            // Utilize assembly to read first four bytes (if present) directly.
c_0xedfe966c(0xa69c124aede21c91b9bf4402842277540c921a5dc560d89ca25843d8a1af64a1); /* line */ 
            assembly {
                // Combine original mask with first four bytes of revert data.
                customErrorSelector := and(
                    mload(add(data, 0x20)), // Data begins after length offset.
                    customErrorSelector
                )
            }

            // Pass through the custom error in question if the revert data is
            // the correct length and matches an expected custom error selector.
c_0xedfe966c(0xa23b02da31b9c33a708fe5b0e6c3093e70230365cc4bf841cd78dd3f92936240); /* line */ 
            c_0xedfe966c(0xccc95c0bd527539c74b07429ef4b1a491e114d6924b49bdf258a1f189e426b14); /* statement */ 
if (
                data.length == 4 &&
                (customErrorSelector == InvalidItemType.selector ||
                    customErrorSelector == InvalidERC721TransferAmount.selector)
            ) {c_0xedfe966c(0xf67c6cb0e2a0b5789ef866229ae1270f26cadc96eade55688161ff62d85cc709); /* branch */ 

                // "Bubble up" the revert reason.
c_0xedfe966c(0x94f818451b61c8c3406935b629893eb9d98270a257a6126df80779ea0f64a5fa); /* line */ 
                assembly {
                    revert(add(data, 0x20), 0x04)
                }
            }else { c_0xedfe966c(0x27d6507d163504f176107dd03845da458e825330431eba453740483660ca2086); /* branch */ 
}

            // Catch all other reverts from the external call to the conduit and
            // include the conduit's raw revert reason as a data argument to a
            // new custom error.
c_0xedfe966c(0xf41368a0ea3a71154330036203fb7fad7221b56bff210bc9c6d03c15c34c4df3); /* line */ 
            revert ConduitErrorRevertBytes(data, conduitKey, conduit);
        }
    }

    /**
     * @notice An internal function to check if a recipient address implements
     *         onERC721Received for a given tokenId. Note that this check does
     *         not adhere to the safe transfer specification and is only meant
     *         to provide an additional layer of assurance that the recipient
     *         can receive the tokens — any hooks or post-transfer checks will
     *         fail and the caller will be the transfer helper rather than the
     *         ERC721 contract. Note that the conduit is set as the operator, as
     *         it will be the caller once the transfer is performed.
     *
     * @param conduit   The conduit to provide as the operator when calling
     *                  onERC721Received.
     * @param recipient The ERC721 recipient on which to call onERC721Received.
     * @param tokenId   The ERC721 tokenId of the token being transferred.
     */
    function _checkERC721Receiver(
        address conduit,
        address recipient,
        uint256 tokenId
    ) internal {c_0xedfe966c(0x7a64fda3754a4b27d83306ceedc70b997a007c11ec268e3d496e6a8b0e79d05c); /* function */ 

        // Check if recipient can receive ERC721 tokens.
c_0xedfe966c(0x48436a4bba73e8c27049b758a4651abffdfd5ab06f0d7a2c41d866cc766d882d); /* line */ 
        c_0xedfe966c(0x47e053907cc4ff7282fe052da183c4ebabeef443c8d867ebdba8ecb2872a7309); /* statement */ 
try
            IERC721Receiver(recipient).onERC721Received(
                conduit,
                msg.sender,
                tokenId,
                ""
            )
        returns (bytes4 selector) {
            // Check if onERC721Received selector is valid.
c_0xedfe966c(0x53f15e97fc30c0c4d63ccceed4e4fa27bfdea2017a616b7bec69b446cd4478cb); /* line */ 
            c_0xedfe966c(0xe50f5ed74c151262b09869db4fc94ff9f9be47ca4503f857013701513ec42897); /* statement */ 
if (selector != IERC721Receiver.onERC721Received.selector) {c_0xedfe966c(0x5794ac11712e3aa3a1a1532e3563cda824f386210f3dc3a78bd22bd31a1d798a); /* branch */ 

                // Revert if recipient cannot accept
                // ERC721 tokens.
c_0xedfe966c(0x76b2576e7f000110768cfe0ab5288634ec6a0d8cc67d56ba7c9b52fab946b345); /* line */ 
                revert InvalidERC721Recipient(recipient);
            }else { c_0xedfe966c(0xea2e4e0f728bd870bc7ac3a877aff3737efb73d120e6f0d1204630bea76b4300); /* branch */ 
}
        } catch (bytes memory data) {
            // "Bubble up" recipient's revert reason.
c_0xedfe966c(0x6f2880c269b18400e7a9230bf8284226031d1a4b958be38d2cb0b75fd3b4ccf3); /* line */ 
            revert ERC721ReceiverErrorRevertBytes(
                data,
                recipient,
                msg.sender,
                tokenId
            );
        } catch Error(string memory reason) {
            // "Bubble up" recipient's revert reason.
c_0xedfe966c(0xf6bf41aabe21d0ebfc6d8a05473f55c445c92b1ecd79124f4faf59e9821d7eec); /* line */ 
            revert ERC721ReceiverErrorRevertString(
                reason,
                recipient,
                msg.sender,
                tokenId
            );
        }
    }

    /**
     * @notice An internal function that reverts if the passed-in recipient
     *         is the zero address.
     *
     * @param recipient The recipient on which to perform the check.
     */
    function _checkRecipientIsNotZeroAddress(address recipient) internal pure {c_0xedfe966c(0xf6da9c214cb2a7a58e62c84263cc07ebd0d5df849a91c8feeb51a446061d58c3); /* function */ 

        // Revert if the recipient is the zero address.
c_0xedfe966c(0xe1cd686cfe139705ae230e9f45958ed19767da35d6a76a48d822b6d0a5a084c4); /* line */ 
        c_0xedfe966c(0x0587e0d316762ea420a15ba99d072056c70a68350bb10f72ebd611142ff0f481); /* statement */ 
if (recipient == address(0x0)) {c_0xedfe966c(0x3e089ecd8d2fb947096df8c85bf21395613ea01372f99191d25c2b8501d963a4); /* branch */ 

c_0xedfe966c(0xbbd01d2c1f5ac35672102b619ef3e4c624c95ee8dd405349bcd2980eec8cbc8e); /* line */ 
            revert RecipientCannotBeZeroAddress();
        }else { c_0xedfe966c(0x4a84daff82a45ed74fea52809a9c6130971de96c46296c0ec4ac6329e3b388d8); /* branch */ 
}
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0x0ff6fc6b(bytes32 c__0x0ff6fc6b) pure {}


interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0x6885cea4(bytes32 c__0x6885cea4) pure {}


import { ConduitItemType } from "../conduit/lib/ConduitEnums.sol";

/**
 * @dev A TransferHelperItem specifies the itemType (ERC20/ERC721/ERC1155),
 *      token address, token identifier, and amount of the token to be
 *      transferred via the TransferHelper. For ERC20 tokens, identifier
 *      must be 0. For ERC721 tokens, amount must be 1.
 */
struct TransferHelperItem {
    ConduitItemType itemType;
    address token;
    uint256 identifier;
    uint256 amount;
}

/**
 * @dev A TransferHelperItemsWithRecipient specifies the tokens to transfer
 *      via the TransferHelper, their intended recipient, and a boolean flag
 *      indicating whether onERC721Received should be called on a recipient
 *      contract.
 */
struct TransferHelperItemsWithRecipient {
    TransferHelperItem[] items;
    address recipient;
    bool validateERC721Receiver;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title ConduitControllerInterface
 * @author 0age
 * @notice ConduitControllerInterface contains all external function interfaces,
 *         structs, events, and errors for the conduit controller.
 */
interface ConduitControllerInterface {
    /**
     * @dev Track the conduit key, current owner, new potential owner, and open
     *      channels for each deployed conduit.
     */
    struct ConduitProperties {
        bytes32 key;
        address owner;
        address potentialOwner;
        address[] channels;
        mapping(address => uint256) channelIndexesPlusOne;
    }

    /**
     * @dev Emit an event whenever a new conduit is created.
     *
     * @param conduit    The newly created conduit.
     * @param conduitKey The conduit key used to create the new conduit.
     */
    event NewConduit(address conduit, bytes32 conduitKey);

    /**
     * @dev Emit an event whenever conduit ownership is transferred.
     *
     * @param conduit       The conduit for which ownership has been
     *                      transferred.
     * @param previousOwner The previous owner of the conduit.
     * @param newOwner      The new owner of the conduit.
     */
    event OwnershipTransferred(
        address indexed conduit,
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Emit an event whenever a conduit owner registers a new potential
     *      owner for that conduit.
     *
     * @param newPotentialOwner The new potential owner of the conduit.
     */
    event PotentialOwnerUpdated(address indexed newPotentialOwner);

    /**
     * @dev Revert with an error when attempting to create a new conduit using a
     *      conduit key where the first twenty bytes of the key do not match the
     *      address of the caller.
     */
    error InvalidCreator();

    /**
     * @dev Revert with an error when attempting to create a new conduit when no
     *      initial owner address is supplied.
     */
    error InvalidInitialOwner();

    /**
     * @dev Revert with an error when attempting to set a new potential owner
     *      that is already set.
     */
    error NewPotentialOwnerAlreadySet(
        address conduit,
        address newPotentialOwner
    );

    /**
     * @dev Revert with an error when attempting to cancel ownership transfer
     *      when no new potential owner is currently set.
     */
    error NoPotentialOwnerCurrentlySet(address conduit);

    /**
     * @dev Revert with an error when attempting to interact with a conduit that
     *      does not yet exist.
     */
    error NoConduit();

    /**
     * @dev Revert with an error when attempting to create a conduit that
     *      already exists.
     */
    error ConduitAlreadyExists(address conduit);

    /**
     * @dev Revert with an error when attempting to update channels or transfer
     *      ownership of a conduit when the caller is not the owner of the
     *      conduit in question.
     */
    error CallerIsNotOwner(address conduit);

    /**
     * @dev Revert with an error when attempting to register a new potential
     *      owner and supplying the null address.
     */
    error NewPotentialOwnerIsZeroAddress(address conduit);

    /**
     * @dev Revert with an error when attempting to claim ownership of a conduit
     *      with a caller that is not the current potential owner for the
     *      conduit in question.
     */
    error CallerIsNotNewPotentialOwner(address conduit);

    /**
     * @dev Revert with an error when attempting to retrieve a channel using an
     *      index that is out of range.
     */
    error ChannelOutOfRange(address conduit);

    /**
     * @notice Deploy a new conduit using a supplied conduit key and assigning
     *         an initial owner for the deployed conduit. Note that the first
     *         twenty bytes of the supplied conduit key must match the caller
     *         and that a new conduit cannot be created if one has already been
     *         deployed using the same conduit key.
     *
     * @param conduitKey   The conduit key used to deploy the conduit. Note that
     *                     the first twenty bytes of the conduit key must match
     *                     the caller of this contract.
     * @param initialOwner The initial owner to set for the new conduit.
     *
     * @return conduit The address of the newly deployed conduit.
     */
    function createConduit(bytes32 conduitKey, address initialOwner)
        external
        returns (address conduit);

    /**
     * @notice Open or close a channel on a given conduit, thereby allowing the
     *         specified account to execute transfers against that conduit.
     *         Extreme care must be taken when updating channels, as malicious
     *         or vulnerable channels can transfer any ERC20, ERC721 and ERC1155
     *         tokens where the token holder has granted the conduit approval.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to open or close the channel.
     * @param channel The channel to open or close on the conduit.
     * @param isOpen  A boolean indicating whether to open or close the channel.
     */
    function updateChannel(
        address conduit,
        address channel,
        bool isOpen
    ) external;

    /**
     * @notice Initiate conduit ownership transfer by assigning a new potential
     *         owner for the given conduit. Once set, the new potential owner
     *         may call `acceptOwnership` to claim ownership of the conduit.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to initiate ownership transfer.
     * @param newPotentialOwner The new potential owner of the conduit.
     */
    function transferOwnership(address conduit, address newPotentialOwner)
        external;

    /**
     * @notice Clear the currently set potential owner, if any, from a conduit.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to cancel ownership transfer.
     */
    function cancelOwnershipTransfer(address conduit) external;

    /**
     * @notice Accept ownership of a supplied conduit. Only accounts that the
     *         current owner has set as the new potential owner may call this
     *         function.
     *
     * @param conduit The conduit for which to accept ownership.
     */
    function acceptOwnership(address conduit) external;

    /**
     * @notice Retrieve the current owner of a deployed conduit.
     *
     * @param conduit The conduit for which to retrieve the associated owner.
     *
     * @return owner The owner of the supplied conduit.
     */
    function ownerOf(address conduit) external view returns (address owner);

    /**
     * @notice Retrieve the conduit key for a deployed conduit via reverse
     *         lookup.
     *
     * @param conduit The conduit for which to retrieve the associated conduit
     *                key.
     *
     * @return conduitKey The conduit key used to deploy the supplied conduit.
     */
    function getKey(address conduit) external view returns (bytes32 conduitKey);

    /**
     * @notice Derive the conduit associated with a given conduit key and
     *         determine whether that conduit exists (i.e. whether it has been
     *         deployed).
     *
     * @param conduitKey The conduit key used to derive the conduit.
     *
     * @return conduit The derived address of the conduit.
     * @return exists  A boolean indicating whether the derived conduit has been
     *                 deployed or not.
     */
    function getConduit(bytes32 conduitKey)
        external
        view
        returns (address conduit, bool exists);

    /**
     * @notice Retrieve the potential owner, if any, for a given conduit. The
     *         current owner may set a new potential owner via
     *         `transferOwnership` and that owner may then accept ownership of
     *         the conduit in question via `acceptOwnership`.
     *
     * @param conduit The conduit for which to retrieve the potential owner.
     *
     * @return potentialOwner The potential owner, if any, for the conduit.
     */
    function getPotentialOwner(address conduit)
        external
        view
        returns (address potentialOwner);

    /**
     * @notice Retrieve the status (either open or closed) of a given channel on
     *         a conduit.
     *
     * @param conduit The conduit for which to retrieve the channel status.
     * @param channel The channel for which to retrieve the status.
     *
     * @return isOpen The status of the channel on the given conduit.
     */
    function getChannelStatus(address conduit, address channel)
        external
        view
        returns (bool isOpen);

    /**
     * @notice Retrieve the total number of open channels for a given conduit.
     *
     * @param conduit The conduit for which to retrieve the total channel count.
     *
     * @return totalChannels The total number of open channels for the conduit.
     */
    function getTotalChannels(address conduit)
        external
        view
        returns (uint256 totalChannels);

    /**
     * @notice Retrieve an open channel at a specific index for a given conduit.
     *         Note that the index of a channel can change as a result of other
     *         channels being closed on the conduit.
     *
     * @param conduit      The conduit for which to retrieve the open channel.
     * @param channelIndex The index of the channel in question.
     *
     * @return channel The open channel, if any, at the specified channel index.
     */
    function getChannel(address conduit, uint256 channelIndex)
        external
        view
        returns (address channel);

    /**
     * @notice Retrieve all open channels for a given conduit. Note that calling
     *         this function for a conduit with many channels will revert with
     *         an out-of-gas error.
     *
     * @param conduit The conduit for which to retrieve open channels.
     *
     * @return channels An array of open channels on the given conduit.
     */
    function getChannels(address conduit)
        external
        view
        returns (address[] memory channels);

    /**
     * @dev Retrieve the conduit creation code and runtime code hashes.
     */
    function getConduitCodeHashes()
        external
        view
        returns (bytes32 creationCodeHash, bytes32 runtimeCodeHash);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0x41a3f1da(bytes32 c__0x41a3f1da) pure {}


import {
    TransferHelperItem,
    TransferHelperItemsWithRecipient
} from "../helpers/TransferHelperStructs.sol";

interface TransferHelperInterface {
    /**
     * @notice Transfer multiple items to a single recipient.
     *
     * @param items The items to transfer.
     * @param conduitKey  The key of the conduit performing the bulk transfer.
     */
    function bulkTransfer(
        TransferHelperItemsWithRecipient[] calldata items,
        bytes32 conduitKey
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0x643d1765(bytes32 c__0x643d1765) pure {}


/**
 * @title TransferHelperErrors
 */
interface TransferHelperErrors {
    /**
     * @dev Revert with an error when attempting to execute transfers with a
     *      NATIVE itemType.
     */
    error InvalidItemType();

    /**
     * @dev Revert with an error when an ERC721 transfer with amount other than
     *      one is attempted.
     */
    error InvalidERC721TransferAmount();

    /**
     * @dev Revert with an error when attempting to execute an ERC721 transfer
     *      to an invalid recipient.
     */
    error InvalidERC721Recipient(address recipient);

    /**
     * @dev Revert with an error when a call to a ERC721 receiver reverts with
     *      bytes data.
     */
    error ERC721ReceiverErrorRevertBytes(
        bytes reason,
        address receiver,
        address sender,
        uint256 identifier
    );

    /**
     * @dev Revert with an error when a call to a ERC721 receiver reverts with
     *      string reason.
     */
    error ERC721ReceiverErrorRevertString(
        string reason,
        address receiver,
        address sender,
        uint256 identifier
    );

    /**
     * @dev Revert with an error when an ERC20 token has an invalid identifier.
     */
    error InvalidERC20Identifier();

    /**
     * @dev Revert with an error if the recipient is the zero address.
     */
    error RecipientCannotBeZeroAddress();

    /**
     * @dev Revert with an error when attempting to fill an order referencing an
     *      invalid conduit (i.e. one that has not been deployed).
     */
    error InvalidConduit(bytes32 conduitKey, address conduit);

    /**
     * @dev Revert with an error when a call to a conduit reverts with a
     *      reason string.
     */
    error ConduitErrorRevertString(
        string reason,
        bytes32 conduitKey,
        address conduit
    );

    /**
     * @dev Revert with an error when a call to a conduit reverts with bytes
     *      data.
     */
    error ConduitErrorRevertBytes(
        bytes reason,
        bytes32 conduitKey,
        address conduit
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0x8c359844(bytes32 c__0x8c359844) pure {}


import { ConduitInterface } from "../interfaces/ConduitInterface.sol";

import { ConduitItemType } from "../conduit/lib/ConduitEnums.sol";

import { ItemType } from "./ConsiderationEnums.sol";

import { ReceivedItem } from "./ConsiderationStructs.sol";

import { Verifiers } from "./Verifiers.sol";

import { TokenTransferrer } from "./TokenTransferrer.sol";

import "./ConsiderationConstants.sol";

/**
 * @title Executor
 * @author 0age
 * @notice Executor contains functions related to processing executions (i.e.
 *         transferring items, either directly or via conduits).
 */
contract Executor is Verifiers, TokenTransferrer {
function c_0xfdb977c0(bytes32 c__0xfdb977c0) internal pure {}

    /**
     * @dev Derive and set hashes, reference chainId, and associated domain
     *      separator during deployment.
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     */
    constructor(address conduitController) Verifiers(conduitController) {c_0xfdb977c0(0x66e882065e7f47c0221bf15bf46a25ca50cac1003ab2b924d3fa6cb16e5291b0); /* function */ 
}

    /**
     * @dev Internal function to transfer a given item, either directly or via
     *      a corresponding conduit.
     *
     * @param item        The item to transfer, including an amount and a
     *                    recipient.
     * @param from        The account supplying the item.
     * @param conduitKey  A bytes32 value indicating what corresponding conduit,
     *                    if any, to source token approvals from. The zero hash
     *                    signifies that no conduit should be used, with direct
     *                    approvals set on this contract.
     * @param accumulator An open-ended array that collects transfers to execute
     *                    against a given conduit in a single call.
     */
    function _transfer(
        ReceivedItem memory item,
        address from,
        bytes32 conduitKey,
        bytes memory accumulator
    ) internal {c_0xfdb977c0(0x4af8bc1d55a837281c4a3a3f3debef07ac5858c6a7defc5cdd44fa7299227f96); /* function */ 

        // If the item type indicates Ether or a native token...
c_0xfdb977c0(0x5e85b642e57a455293223d678d81c727ad8ac1fec3179a8419d6e2131b99a818); /* line */ 
        c_0xfdb977c0(0x90ae0b2149541243058f0752cd6874e8ac05ef3059948651bc43cd0ac38d7e36); /* statement */ 
if (item.itemType == ItemType.NATIVE) {c_0xfdb977c0(0xff84740169486ff9f7071907ffde142fba5f59f433729b682632e2f54e9a91ac); /* branch */ 

            // Ensure neither the token nor the identifier parameters are set.
c_0xfdb977c0(0x046493bd19e32fd800da93df9a32a73bf1b6da9137a8514975d974195ca2a49f); /* line */ 
            c_0xfdb977c0(0xbcf05f6359cd5dc544aaf838cf9ed43791fcd76bbc01cbe20cbf716bb5289c4c); /* statement */ 
if ((uint160(item.token) | item.identifier) != 0) {c_0xfdb977c0(0x274b75650d584d81aad4ce9fbe6b34144e5d4e1f91f36d470a350a29e02a8ea9); /* branch */ 

c_0xfdb977c0(0xe8deedc81a0070d694e3601d784d4969f8a2255d40df70c07076efcead2d3e9d); /* line */ 
                revert UnusedItemParameters();
            }else { c_0xfdb977c0(0x0c49721f5fb13dc7151ef77792bce0578146b31c683c06a6990a941cf7aa13b6); /* branch */ 
}

            // transfer the native tokens to the recipient.
c_0xfdb977c0(0x5d27df1c4888454fd78dcb9774018cfdd5a7f06b78a3d9cc537c5a770b02b6a1); /* line */ 
            c_0xfdb977c0(0x9adf230f01a69765acbf12a654b44d363b8f92c05d66b1a399091b7fec936d5a); /* statement */ 
_transferEth(item.recipient, item.amount);
        } else {c_0xfdb977c0(0x47431a1e1263c0340851f22ed2eb487cd5d69fb502f436ca54ff2b79b47866bf); /* statement */ 
c_0xfdb977c0(0xc57b6540e3020bf1066e005ec998552688b6031bd1569b15a271fc37eb12ce36); /* branch */ 
if (item.itemType == ItemType.ERC20) {c_0xfdb977c0(0xb1e0dff3268a6ae93b3eb266e27f304c6bebef28cc705fb281d71917824e798e); /* branch */ 

            // Ensure that no identifier is supplied.
c_0xfdb977c0(0x242a73241aaf668e97403d87dad06bd3a4695e7db3be5973ff497a7c4a3ebdc4); /* line */ 
            c_0xfdb977c0(0x307b4b7b5f482c674cee4afea5252651b8e84c5521578be4be87d5444a6eacaa); /* statement */ 
if (item.identifier != 0) {c_0xfdb977c0(0x5f8d514d7e03315a2e1aec2863d1d9c32c3d0a01c105a5f9e4cb47d3a1765333); /* branch */ 

c_0xfdb977c0(0x682b76b96ce4a6309f81aa159dea21f22d951430120191375bbdc5e5f9c3ff91); /* line */ 
                revert UnusedItemParameters();
            }else { c_0xfdb977c0(0x9299aa24132add107aebae3b76a15d51ae27661f7d3155b997a8de45ebcfef01); /* branch */ 
}

            // Transfer ERC20 tokens from the source to the recipient.
c_0xfdb977c0(0x0358df51cdaa120f0eed697ea6a4e65f7dd2b1c09ef97c1b907234fe64349ee0); /* line */ 
            c_0xfdb977c0(0x9a21b043222c3667f7e9e050442abbd9e9220f6ba68d7732bb6e298830256d8b); /* statement */ 
_transferERC20(
                item.token,
                from,
                item.recipient,
                item.amount,
                conduitKey,
                accumulator
            );
        } else {c_0xfdb977c0(0x2273ed040777b819e8ccbd20a56e562a55b0983c79feb158b2c008e93ca6e483); /* statement */ 
c_0xfdb977c0(0xc4ae6bc317f4147c3a80627618bb012dee5fb5c33bc1f496d57b50a1738fcabe); /* branch */ 
if (item.itemType == ItemType.ERC721) {c_0xfdb977c0(0x4ecbbd900742a0299c9e71573176d1c7763168f5b6c07738aa0f8a345d526110); /* branch */ 

            // Transfer ERC721 token from the source to the recipient.
c_0xfdb977c0(0xf6c887241d2d61b7922e151eb3f185d7bfc7262ffccdd905d2309fe110b40ebc); /* line */ 
            c_0xfdb977c0(0x5c6217bd243cdc8a57f010d6e7cf8e6e3480bb091484b62837bb76aef24d578f); /* statement */ 
_transferERC721(
                item.token,
                from,
                item.recipient,
                item.identifier,
                item.amount,
                conduitKey,
                accumulator
            );
        } else {c_0xfdb977c0(0x79d4074a5d57858fd0951c99b89236e8bcaf6e80e52362a99f3c73530319dbce); /* branch */ 

            // Transfer ERC1155 token from the source to the recipient.
c_0xfdb977c0(0xdb4b15b7125a05c726191546a512f457984878ee9ce2f57074e58ed68ed5997e); /* line */ 
            c_0xfdb977c0(0x5171552f73edd9c866cc7c638f703ec5541710f050a2a85e2aa2824c91b5e3fc); /* statement */ 
_transferERC1155(
                item.token,
                from,
                item.recipient,
                item.identifier,
                item.amount,
                conduitKey,
                accumulator
            );
        }}}
    }

    /**
     * @dev Internal function to transfer an individual ERC721 or ERC1155 item
     *      from a given originator to a given recipient. The accumulator will
     *      be bypassed, meaning that this function should be utilized in cases
     *      where multiple item transfers can be accumulated into a single
     *      conduit call. Sufficient approvals must be set, either on the
     *      respective conduit or on this contract itself.
     *
     * @param itemType   The type of item to transfer, either ERC721 or ERC1155.
     * @param token      The token to transfer.
     * @param from       The originator of the transfer.
     * @param to         The recipient of the transfer.
     * @param identifier The tokenId to transfer.
     * @param amount     The amount to transfer.
     * @param conduitKey A bytes32 value indicating what corresponding conduit,
     *                   if any, to source token approvals from. The zero hash
     *                   signifies that no conduit should be used, with direct
     *                   approvals set on this contract.
     */
    function _transferIndividual721Or1155Item(
        ItemType itemType,
        address token,
        address from,
        address to,
        uint256 identifier,
        uint256 amount,
        bytes32 conduitKey
    ) internal {c_0xfdb977c0(0x01d1d7727e098515ace4a5dc80421385f6581a6e00c98d3142fce619c7e97112); /* function */ 

        // Determine if the transfer is to be performed via a conduit.
c_0xfdb977c0(0x0bc3ffbe18dfd62dd338e3b74012b37107297e6e8cecad60c661de386d3f9034); /* line */ 
        c_0xfdb977c0(0x615651568a2a94488843a54b53ba3aa6169a0a23f234739c722bb5cb2c810513); /* statement */ 
if (conduitKey != bytes32(0)) {c_0xfdb977c0(0x9d57427a8781c72b612bc8f37e4ca67affa7fbe89596c2c53c3237b5c7dd09e3); /* branch */ 

            // Use free memory pointer as calldata offset for the conduit call.
c_0xfdb977c0(0x0753032043d366ad8ec702cbc9f2c1fba2412d7d6ada6bda4e3e5ccbea51c4d6); /* line */ 
            c_0xfdb977c0(0x18f910d8923c9e36c54488b1697dc57eb96c13a868df33a1467a00e870379306); /* statement */ 
uint256 callDataOffset;

            // Utilize assembly to place each argument in free memory.
c_0xfdb977c0(0xfe7c3ffcf87f8a2a6102b77aabc15f64e378011fc4c65a5467d0d2342989fd1f); /* line */ 
            assembly {
                // Retrieve the free memory pointer and use it as the offset.
                callDataOffset := mload(FreeMemoryPointerSlot)

                // Write ConduitInterface.execute.selector to memory.
                mstore(callDataOffset, Conduit_execute_signature)

                // Write the offset to the ConduitTransfer array in memory.
                mstore(
                    add(
                        callDataOffset,
                        Conduit_execute_ConduitTransfer_offset_ptr
                    ),
                    Conduit_execute_ConduitTransfer_ptr
                )

                // Write the length of the ConduitTransfer array to memory.
                mstore(
                    add(
                        callDataOffset,
                        Conduit_execute_ConduitTransfer_length_ptr
                    ),
                    Conduit_execute_ConduitTransfer_length
                )

                // Write the item type to memory.
                mstore(
                    add(callDataOffset, Conduit_execute_transferItemType_ptr),
                    itemType
                )

                // Write the token to memory.
                mstore(
                    add(callDataOffset, Conduit_execute_transferToken_ptr),
                    token
                )

                // Write the transfer source to memory.
                mstore(
                    add(callDataOffset, Conduit_execute_transferFrom_ptr),
                    from
                )

                // Write the transfer recipient to memory.
                mstore(add(callDataOffset, Conduit_execute_transferTo_ptr), to)

                // Write the token identifier to memory.
                mstore(
                    add(callDataOffset, Conduit_execute_transferIdentifier_ptr),
                    identifier
                )

                // Write the transfer amount to memory.
                mstore(
                    add(callDataOffset, Conduit_execute_transferAmount_ptr),
                    amount
                )
            }

            // Perform the call to the conduit.
c_0xfdb977c0(0x330d84f49f0f4f0898292bc900825b61ff3718846236b74376669e2e09cb1404); /* line */ 
            c_0xfdb977c0(0x8b4a3fca7016de9c4813e492cea7d54c5f56ce457e990b45995c151e9c9c3799); /* statement */ 
_callConduitUsingOffsets(
                conduitKey,
                callDataOffset,
                OneConduitExecute_size
            );
        } else {c_0xfdb977c0(0x9850a1b6883e1dbab3e32dc17862aee2d6259b8746a7a267434dee192ce35f85); /* branch */ 

            // Otherwise, determine whether it is an ERC721 or ERC1155 item.
c_0xfdb977c0(0xfef32f004a178809a4d1c910aa6d744a51addcf550410b8e0ed3d3b8e528580a); /* line */ 
            c_0xfdb977c0(0xea8410db29df0a6e9a4dcb36cbfd1694feb2317fb80652f25923a4c9abc37545); /* statement */ 
if (itemType == ItemType.ERC721) {c_0xfdb977c0(0x410b6dd967d62822fa7eca55713d113e28a4d8ad3b1609978e60bddf269337a3); /* branch */ 

                // Ensure that exactly one 721 item is being transferred.
c_0xfdb977c0(0x171918b13470b034ef25ba45c090c81246a0d8813a36f88c1e5aa564becd9023); /* line */ 
                c_0xfdb977c0(0xe6571e1a894aea99afbe51318ab5f19d57718dc4e4616a9a0ac96a82b4f638eb); /* statement */ 
if (amount != 1) {c_0xfdb977c0(0x7529ee01950877010e1ebbed89d1df72500f052c49c2ef84b8cc1b9be5fc8fbe); /* branch */ 

c_0xfdb977c0(0xb7f6bf0fb0a72c19c482492e5d91ac1139ae8ca8e0fbff5a311d8ef50696d33e); /* line */ 
                    revert InvalidERC721TransferAmount();
                }else { c_0xfdb977c0(0xbdf39ed572cdbf3d8eae6fb2d2e9879a4e692d6449a14178dec67c3ab32679a6); /* branch */ 
}

                // Perform transfer via the token contract directly.
c_0xfdb977c0(0x17b371ce3a7ca89c1d5677c037149a60901580fa65c6c72c2a5f12e5aa4b23c3); /* line */ 
                c_0xfdb977c0(0x2570a4790136c2e52b4356980f7a21672d7d8ce495c163e324354e55b9c6918a); /* statement */ 
_performERC721Transfer(token, from, to, identifier);
            } else {c_0xfdb977c0(0x7e732e43197f65831f18d033d5784e8a35378074f3997762044daf265e51394b); /* branch */ 

                // Perform transfer via the token contract directly.
c_0xfdb977c0(0xc75bd3c70ae06fc169836ad12d07307b4997179530de4ba325aa54ddf593c82d); /* line */ 
                c_0xfdb977c0(0x5893cf4cd7fb89045e29e7e85ffcefabf8b6c863ce600c1f368e59f152951113); /* statement */ 
_performERC1155Transfer(token, from, to, identifier, amount);
            }
        }
    }

    /**
     * @dev Internal function to transfer Ether or other native tokens to a
     *      given recipient.
     *
     * @param to     The recipient of the transfer.
     * @param amount The amount to transfer.
     */
    function _transferEth(address payable to, uint256 amount) internal {c_0xfdb977c0(0x31cbaf161fc1c78a395aec6bb6186272bd7d4d4bb089dfc70a596bbc51cdfc87); /* function */ 

        // Ensure that the supplied amount is non-zero.
c_0xfdb977c0(0x3712415f0afce9d7659a857d8eec55ef9095eddadd34da643b5242b646cb6ea4); /* line */ 
        c_0xfdb977c0(0x5e1dbef1135b1be9671887dc33242b327078a8ae0644a405fcafbfe5b4a68d90); /* statement */ 
_assertNonZeroAmount(amount);

        // Declare a variable indicating whether the call was successful or not.
c_0xfdb977c0(0x6b242308d2e53ff736e4c616373eb61e2e2fb70af7f5be30f0740baac9e21064); /* line */ 
        c_0xfdb977c0(0x4faab39802b8c43dd54be177278da9b1f066c20fc1b70509655a270f5dda683a); /* statement */ 
bool success;

c_0xfdb977c0(0x9b9e9e391d7aa8fbbf2dd58637d8e717fcc13a0e96cd7921f3636de9fb7d819d); /* line */ 
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        // If the call fails...
c_0xfdb977c0(0xc3bf1bb26d862c5c92149e93a3d522991cc878fcd281b39026e9cea07c8f1d4a); /* line */ 
        c_0xfdb977c0(0x4edd8a0e4dd52d820872d1e04861643de58bb0a2af0c95cb6c2e500f0ac1cdff); /* statement */ 
if (!success) {c_0xfdb977c0(0xb18b24a674dfaebcfec8012785b93ddc55e92da214436161ff42c7ea629ecca5); /* branch */ 

            // Revert and pass the revert reason along if one was returned.
c_0xfdb977c0(0x366ff93a0e49dc6d23ad9a6e997a3609057d76bb2bc43f2fa30f96702870d2fa); /* line */ 
            c_0xfdb977c0(0xc2fd92f2374ccc7a6a813230e56d2ed2a3543c4b21715844a6313ac11dbf7f41); /* statement */ 
_revertWithReasonIfOneIsReturned();

            // Otherwise, revert with a generic error message.
c_0xfdb977c0(0x0c0d777792fca379996a4b1fb34840d1c14be87b45089fe9d6ff18fcbef78c97); /* line */ 
            revert EtherTransferGenericFailure(to, amount);
        }else { c_0xfdb977c0(0x20b90a4f0bea29a6dec15b7959c34e8c6986ba6ef5e3eef013a35c31ad2d3b40); /* branch */ 
}
    }

    /**
     * @dev Internal function to transfer ERC20 tokens from a given originator
     *      to a given recipient using a given conduit if applicable. Sufficient
     *      approvals must be set on this contract or on a respective conduit.
     *
     * @param token       The ERC20 token to transfer.
     * @param from        The originator of the transfer.
     * @param to          The recipient of the transfer.
     * @param amount      The amount to transfer.
     * @param conduitKey  A bytes32 value indicating what corresponding conduit,
     *                    if any, to source token approvals from. The zero hash
     *                    signifies that no conduit should be used, with direct
     *                    approvals set on this contract.
     * @param accumulator An open-ended array that collects transfers to execute
     *                    against a given conduit in a single call.
     */
    function _transferERC20(
        address token,
        address from,
        address to,
        uint256 amount,
        bytes32 conduitKey,
        bytes memory accumulator
    ) internal {c_0xfdb977c0(0x8cc3f33ea7f9a8ba1239c1e3e22824ea92cdc8c48f365381016cf4d400f23fcf); /* function */ 

        // Ensure that the supplied amount is non-zero.
c_0xfdb977c0(0xcc018ef7029b68c95b24dc4e897af3a9b469b8bd1895c36c023055f1e1c675d9); /* line */ 
        c_0xfdb977c0(0xbca9812bd84b43741a9c168328ccd11bb9ab5191d51b4a336bd0c8c4a74a8dd7); /* statement */ 
_assertNonZeroAmount(amount);

        // Trigger accumulated transfers if the conduits differ.
c_0xfdb977c0(0x862ccbd7a80e277b608a27f2054500962b37a91df1de1d2c6963917ed5fa3207); /* line */ 
        c_0xfdb977c0(0x02030fd05d253ed46529c07842059925e2387379389b52414ae645ee1c100a65); /* statement */ 
_triggerIfArmedAndNotAccumulatable(accumulator, conduitKey);

        // If no conduit has been specified...
c_0xfdb977c0(0xe09594411ef7fc000cbd846f99aacad28e517eff6cc043ced436944734efae5e); /* line */ 
        c_0xfdb977c0(0x339ab15110dc049f450fd5b21caa106233348143944e88ed2184daeaca5e4539); /* statement */ 
if (conduitKey == bytes32(0)) {c_0xfdb977c0(0x95118cd45966ca0d424fed3894e172d6d6f8a28bfc65fd86186da40dd1ac148c); /* branch */ 

            // Perform the token transfer directly.
c_0xfdb977c0(0x1499e4ccc40a2f5b61938e6f1ad1fa542d52f3fa5f1afc183ba972f9977e5410); /* line */ 
            c_0xfdb977c0(0x20dfcca8de3c30fea4c03df635be70e8e585c273916e94589e2944d8c2d600e8); /* statement */ 
_performERC20Transfer(token, from, to, amount);
        } else {c_0xfdb977c0(0x455ae180123d2871e3caf8f9b73491f5889c5f1ac699532f168660e79cb8aa3d); /* branch */ 

            // Insert the call to the conduit into the accumulator.
c_0xfdb977c0(0x7f49d15e059328e2fa0623a9c5e088a4340f6abcc06ba57a94b669baa937fb5f); /* line */ 
            c_0xfdb977c0(0x20d444ff735deb6167023f1003c1d58b01b42a4c7c9cccdbe58e1c718b9d5184); /* statement */ 
_insert(
                conduitKey,
                accumulator,
                ConduitItemType.ERC20,
                token,
                from,
                to,
                uint256(0),
                amount
            );
        }
    }

    /**
     * @dev Internal function to transfer a single ERC721 token from a given
     *      originator to a given recipient. Sufficient approvals must be set,
     *      either on the respective conduit or on this contract itself.
     *
     * @param token       The ERC721 token to transfer.
     * @param from        The originator of the transfer.
     * @param to          The recipient of the transfer.
     * @param identifier  The tokenId to transfer (must be 1 for ERC721).
     * @param amount      The amount to transfer.
     * @param conduitKey  A bytes32 value indicating what corresponding conduit,
     *                    if any, to source token approvals from. The zero hash
     *                    signifies that no conduit should be used, with direct
     *                    approvals set on this contract.
     * @param accumulator An open-ended array that collects transfers to execute
     *                    against a given conduit in a single call.
     */
    function _transferERC721(
        address token,
        address from,
        address to,
        uint256 identifier,
        uint256 amount,
        bytes32 conduitKey,
        bytes memory accumulator
    ) internal {c_0xfdb977c0(0xe0f86afdfd2a2b5f58a0a34417167d1341d6d70262b2258ffe2919c75f6c2a42); /* function */ 

        // Trigger accumulated transfers if the conduits differ.
c_0xfdb977c0(0x6cec7e6b04daafa84278061002f45b8f432973c3bc0a2c388a1848ba4e3081aa); /* line */ 
        c_0xfdb977c0(0xa6680679842e92657cb8da8f648674e0cc48bf978ad79adc9b174efb02db4b8a); /* statement */ 
_triggerIfArmedAndNotAccumulatable(accumulator, conduitKey);

        // If no conduit has been specified...
c_0xfdb977c0(0xb9b82992186ab52f9d251a4704abcf510009dd39dcf7ba735260af9091e7be88); /* line */ 
        c_0xfdb977c0(0xc9e4b97a2127409eeaa27487ff92d2f96fcc1f881f6d842dc9c99907c02c279c); /* statement */ 
if (conduitKey == bytes32(0)) {c_0xfdb977c0(0xd5c631a4b020e885342dbeb4c6dc7385043c794d2abc6cd3d86b1e310c3cac29); /* branch */ 

            // Ensure that exactly one 721 item is being transferred.
c_0xfdb977c0(0x66ed39245c7b2012cf934b08594b03db261e6ff0b2f1a0a80ef85333de0a4426); /* line */ 
            c_0xfdb977c0(0x18342a1452ea5acacef5eae791b13b98d5151588ee07e9b2b447ece893c51b51); /* statement */ 
if (amount != 1) {c_0xfdb977c0(0xe8aeac0e0e940ca178c28819a54e9449e7a455d03999a41dbdbf98bd33852b03); /* branch */ 

c_0xfdb977c0(0x94fcfbec096b70b86a8ff28d1da7b84f60ab510da84c8b6f1ae3e0a49c3f53c9); /* line */ 
                revert InvalidERC721TransferAmount();
            }else { c_0xfdb977c0(0x3d014130a82fb73fb8a4c21d2c6271bd3af9da6c59afa9f7367f1fbd80acf8ba); /* branch */ 
}

            // Perform transfer via the token contract directly.
c_0xfdb977c0(0x5a66d10de5ebe2cb6c99a0d9e130dc10f7263d67b06483319190562bffb05524); /* line */ 
            c_0xfdb977c0(0x24f3716cf8b529659ca413226ecef8c594f396fe362034c33e3b9c9520aeab7b); /* statement */ 
_performERC721Transfer(token, from, to, identifier);
        } else {c_0xfdb977c0(0x29e734623203a79001272c666891712ea5620461b80c5a94e4d896251b2421d7); /* branch */ 

            // Insert the call to the conduit into the accumulator.
c_0xfdb977c0(0x73695057ee7096fd8b3e41725980794671066d20279ad4fcf48fb4ea460ad6d3); /* line */ 
            c_0xfdb977c0(0x2669be8964456d391c56672773282c814dd13c6f6e020ceeb34ca9d3136b276a); /* statement */ 
_insert(
                conduitKey,
                accumulator,
                ConduitItemType.ERC721,
                token,
                from,
                to,
                identifier,
                amount
            );
        }
    }

    /**
     * @dev Internal function to transfer ERC1155 tokens from a given originator
     *      to a given recipient. Sufficient approvals must be set, either on
     *      the respective conduit or on this contract itself.
     *
     * @param token       The ERC1155 token to transfer.
     * @param from        The originator of the transfer.
     * @param to          The recipient of the transfer.
     * @param identifier  The id to transfer.
     * @param amount      The amount to transfer.
     * @param conduitKey  A bytes32 value indicating what corresponding conduit,
     *                    if any, to source token approvals from. The zero hash
     *                    signifies that no conduit should be used, with direct
     *                    approvals set on this contract.
     * @param accumulator An open-ended array that collects transfers to execute
     *                    against a given conduit in a single call.
     */
    function _transferERC1155(
        address token,
        address from,
        address to,
        uint256 identifier,
        uint256 amount,
        bytes32 conduitKey,
        bytes memory accumulator
    ) internal {c_0xfdb977c0(0x5d55b9ad0a4dc30e68f5dd7751e1ab049f5a6848293f55d6238cd20ddf6ae2d2); /* function */ 

        // Ensure that the supplied amount is non-zero.
c_0xfdb977c0(0x0a5e1efa9899e4213e8bdba7f03a9c6220e0f1e1176f7e8fd5210b7aa7a8794c); /* line */ 
        c_0xfdb977c0(0xfed9549b334b3224fc9810ab86075b73c532c852602e61c496c19bdeef24097b); /* statement */ 
_assertNonZeroAmount(amount);

        // Trigger accumulated transfers if the conduits differ.
c_0xfdb977c0(0xc29e84abc76fd94ba5a78a1c37dd9d426a2278d1fb622b8276bcf2cf9cae0541); /* line */ 
        c_0xfdb977c0(0x0b03c671a7355c6305e50ee661e44113b187fc7c5f0429471233cdc01676bbab); /* statement */ 
_triggerIfArmedAndNotAccumulatable(accumulator, conduitKey);

        // If no conduit has been specified...
c_0xfdb977c0(0x18ee2d3c8447c2f9b24f477fe1ab222a8cfc9e1337c75fa98b2b938cc4e80ae8); /* line */ 
        c_0xfdb977c0(0xfd48b757fe0c80c39721e373f531d410fe46ceefcd46d5f066449a10e08882f2); /* statement */ 
if (conduitKey == bytes32(0)) {c_0xfdb977c0(0x54ff22fb6f4515083479784138730de6200fc63fe1c76e9b99cf7e3d69b9d75e); /* branch */ 

            // Perform transfer via the token contract directly.
c_0xfdb977c0(0x833b778f2cf50bb687aaab13a692bc9d9f80c8fa24fd45a5b15d4a075cd34e8a); /* line */ 
            c_0xfdb977c0(0xdfdd19e9e41fe970e4a0115a2dbf0cce268390079d59f1e077e8ee724db8a07c); /* statement */ 
_performERC1155Transfer(token, from, to, identifier, amount);
        } else {c_0xfdb977c0(0xab88e80e724197dbba6e256f97b397c873592dab65f3db942a93a5e4a82433e6); /* branch */ 

            // Insert the call to the conduit into the accumulator.
c_0xfdb977c0(0xf9dd7a82bbbade62257c89d86a55504e9db675fb6ccbf48592d117bcd98c99c0); /* line */ 
            c_0xfdb977c0(0x65fca80d5481c97dfb9eb9946a1ce5fd569afe68423aa2f9e08b77ade3421c04); /* statement */ 
_insert(
                conduitKey,
                accumulator,
                ConduitItemType.ERC1155,
                token,
                from,
                to,
                identifier,
                amount
            );
        }
    }

    /**
     * @dev Internal function to trigger a call to the conduit currently held by
     *      the accumulator if the accumulator contains item transfers (i.e. it
     *      is "armed") and the supplied conduit key does not match the key held
     *      by the accumulator.
     *
     * @param accumulator An open-ended array that collects transfers to execute
     *                    against a given conduit in a single call.
     * @param conduitKey  A bytes32 value indicating what corresponding conduit,
     *                    if any, to source token approvals from. The zero hash
     *                    signifies that no conduit should be used, with direct
     *                    approvals set on this contract.
     */
    function _triggerIfArmedAndNotAccumulatable(
        bytes memory accumulator,
        bytes32 conduitKey
    ) internal {c_0xfdb977c0(0x013a7fa95d15d3a7c244bd46b94f93c158167184c250f45a929f3afb012aad22); /* function */ 

        // Retrieve the current conduit key from the accumulator.
c_0xfdb977c0(0x93a47648af2a2aef08a713554511e2bf6a53a5825c3e1eda0042c6a68e763029); /* line */ 
        c_0xfdb977c0(0xd25142ff3a0239e722974ea5e719b09b45350ba2f850c7332f5e20aca75b49e1); /* statement */ 
bytes32 accumulatorConduitKey = _getAccumulatorConduitKey(accumulator);

        // Perform conduit call if the set key does not match the supplied key.
c_0xfdb977c0(0x3ef3f35cc8eeb7c6e04aba22d9b04aed2274872aa3c9a56329275dbb1afa093c); /* line */ 
        c_0xfdb977c0(0x513289db31ee96e77502f6413f40ed29ab93f12f8daf5774452065c35b5cedc9); /* statement */ 
if (accumulatorConduitKey != conduitKey) {c_0xfdb977c0(0xa17f85791a9f1a54c0dfe2c4ce9ca3dada13de9706044879a7345e8518291eba); /* branch */ 

c_0xfdb977c0(0xe8b252f7b84da3113a773400506d73a263bc1d38788d5c9751cf4acc9debe277); /* line */ 
            c_0xfdb977c0(0x3e44030ea2dcb24cbc633d9875c98529fa72b2df3c63e1f0c37387101180c568); /* statement */ 
_triggerIfArmed(accumulator);
        }else { c_0xfdb977c0(0x6c313db80fc784d16d73fb58457ed13006eb357b50c09fc8cb4d1f257a93360f); /* branch */ 
}
    }

    /**
     * @dev Internal function to trigger a call to the conduit currently held by
     *      the accumulator if the accumulator contains item transfers (i.e. it
     *      is "armed").
     *
     * @param accumulator An open-ended array that collects transfers to execute
     *                    against a given conduit in a single call.
     */
    function _triggerIfArmed(bytes memory accumulator) internal {c_0xfdb977c0(0x57a3cf1a73598de395e9ec2ae42c993ea40c33ae2e843bf6fe0abea34df7b78b); /* function */ 

        // Exit if the accumulator is not "armed".
c_0xfdb977c0(0x2307fe8b4e09b9fe4452b3fea92f079bd05f7a216ffff2173810a7098f27a53b); /* line */ 
        c_0xfdb977c0(0xf200516258661bf8e869d5360b62384fe69c86a583057856b7e8c59c7ba13b26); /* statement */ 
if (accumulator.length != AccumulatorArmed) {c_0xfdb977c0(0xd3ccc04a3163443357493a00f05b9a539545ce84b069ef11063a916466afe563); /* branch */ 

c_0xfdb977c0(0xdb294ed65c3ac907876a3211a3ff296d15f147a3fe3eaceaa0003196c2e9321f); /* line */ 
            c_0xfdb977c0(0x957b6053f5b24f1b0113147e7869191aa39404b601dac6fc3ed236a59c3b8128); /* statement */ 
return;
        }else { c_0xfdb977c0(0xdce399b5de0855f2913fb8135d72a5ee8ed4e44908dc22034bea2cebce4d9624); /* branch */ 
}

        // Retrieve the current conduit key from the accumulator.
c_0xfdb977c0(0xa636093b17f61b482f657f4da7459deacc792d1c24d8c31587e0d09f5c6760f5); /* line */ 
        c_0xfdb977c0(0xe7f0b88e0827cb50733efb1766516cfc26c102c97f5d28f47b1b6bcc6ffc5463); /* statement */ 
bytes32 accumulatorConduitKey = _getAccumulatorConduitKey(accumulator);

        // Perform conduit call.
c_0xfdb977c0(0x2266d26bb6681494f91fe640bcd3370cefb639d3c915c7d2ae65b3531efb03e2); /* line */ 
        c_0xfdb977c0(0xe1e615bac676501fd2a8edd5f983f835f0b63348fdc620bb6f4ac5399a54d97b); /* statement */ 
_trigger(accumulatorConduitKey, accumulator);
    }

    /**
     * @dev Internal function to trigger a call to the conduit corresponding to
     *      a given conduit key, supplying all accumulated item transfers. The
     *      accumulator will be "disarmed" and reset in the process.
     *
     * @param conduitKey  A bytes32 value indicating what corresponding conduit,
     *                    if any, to source token approvals from. The zero hash
     *                    signifies that no conduit should be used, with direct
     *                    approvals set on this contract.
     * @param accumulator An open-ended array that collects transfers to execute
     *                    against a given conduit in a single call.
     */
    function _trigger(bytes32 conduitKey, bytes memory accumulator) internal {c_0xfdb977c0(0x14e5f3a93cd8f20f55a5ee01e92484de88c0ee6d8428e0a1fffa36e6d0f8fcf4); /* function */ 

        // Declare variables for offset in memory & size of calldata to conduit.
c_0xfdb977c0(0x9f89acd220831ea8a56275951a76de6860b7f4f0d7a17ee6935d1343a2652abb); /* line */ 
        c_0xfdb977c0(0xdf3222aa09b08ead6a2a3684e14a3fe4ff9a39d714639a93db55975fdbfc0f76); /* statement */ 
uint256 callDataOffset;
c_0xfdb977c0(0x910a68c5f40d06d1dbbe9d95bc69eb0cad59eb93bcaf0cf22b60c28bee685295); /* line */ 
        c_0xfdb977c0(0x2b1dbf73c04519b65b2a104eb62713f21aa4c59f52282f50a627efb60da5b103); /* statement */ 
uint256 callDataSize;

        // Call the conduit with all the accumulated transfers.
c_0xfdb977c0(0x3e40502e0bd63a53cfdc3f8492396cd8f2480799db31eae27fda6c71a0b52719); /* line */ 
        assembly {
            // Call begins at third word; the first is length or "armed" status,
            // and the second is the current conduit key.
            callDataOffset := add(accumulator, TwoWords)

            // 68 + items * 192
            callDataSize := add(
                Accumulator_array_offset_ptr,
                mul(
                    mload(add(accumulator, Accumulator_array_length_ptr)),
                    Conduit_transferItem_size
                )
            )
        }

        // Call conduit derived from conduit key & supply accumulated transfers.
c_0xfdb977c0(0x56a4f51576e931d36504f063b0b848045d17ae868f383e5234b67da8d7812226); /* line */ 
        c_0xfdb977c0(0x220ebb9f06ff48ec0494a78c52400e84f8b49a6abf5922640432c36421a8c837); /* statement */ 
_callConduitUsingOffsets(conduitKey, callDataOffset, callDataSize);

        // Reset accumulator length to signal that it is now "disarmed".
c_0xfdb977c0(0x3db8c6d9395869de44e733be545d6b7583c6e94cddf0cccf63b22506cc56c5c7); /* line */ 
        assembly {
            mstore(accumulator, AccumulatorDisarmed)
        }
    }

    /**
     * @dev Internal function to perform a call to the conduit corresponding to
     *      a given conduit key based on the offset and size of the calldata in
     *      question in memory.
     *
     * @param conduitKey     A bytes32 value indicating what corresponding
     *                       conduit, if any, to source token approvals from.
     *                       The zero hash signifies that no conduit should be
     *                       used, with direct approvals set on this contract.
     * @param callDataOffset The memory pointer where calldata is contained.
     * @param callDataSize   The size of calldata in memory.
     */
    function _callConduitUsingOffsets(
        bytes32 conduitKey,
        uint256 callDataOffset,
        uint256 callDataSize
    ) internal {c_0xfdb977c0(0x606799c67114339d0c92815ce5544ad9bf76771ae9ecc688508d22c611f7d215); /* function */ 

        // Derive the address of the conduit using the conduit key.
c_0xfdb977c0(0xe31c90cdd1a92e93903e5815cda5341a6f5ecba9349da6b31aaf99c24aca1fd3); /* line */ 
        c_0xfdb977c0(0x642acc00b0891d5af43145195a332ee7529dcc7404bc6301488ae64c5de5b7e5); /* statement */ 
address conduit = _deriveConduit(conduitKey);

c_0xfdb977c0(0x594d4bc5ba1ea863f8f2774330de251699d57a109f79b3f146a35e6522e110ab); /* line */ 
        c_0xfdb977c0(0x2b06340efca1b26c7a7dd0961f5d278a16be778d130de5f7d621b93bdc96283d); /* statement */ 
bool success;
c_0xfdb977c0(0xff4b765a0c9b083666481928269071ebb6f91d7d52957a154fe9c1725a00db87); /* line */ 
        c_0xfdb977c0(0x800fc0e6beb28e00c6fa98d723ffda26223f22a1848a850f7bcb3d39141e8b04); /* statement */ 
bytes4 result;

        // call the conduit.
c_0xfdb977c0(0x07dacd6ccc338a4b51cfd73df1b6b7d1987db044a1f042e120ca4cd1fef935aa); /* line */ 
        assembly {
            // Ensure first word of scratch space is empty.
            mstore(0, 0)

            // Perform call, placing first word of return data in scratch space.
            success := call(
                gas(),
                conduit,
                0,
                callDataOffset,
                callDataSize,
                0,
                OneWord
            )

            // Take value from scratch space and place it on the stack.
            result := mload(0)
        }

        // If the call failed...
c_0xfdb977c0(0xf1a33e00e80b67c243d985797e6be903d1eb7fae4d3de0a57fa38e02c6ddd182); /* line */ 
        c_0xfdb977c0(0x023f7fa68cd7962ce2624047ff25df14f0a72d9e6b4a985a808b8066c966b7bc); /* statement */ 
if (!success) {c_0xfdb977c0(0xe2d39222e18382b1a46073d7ce5c479b6a5894354844fc90ddc30576d32531e0); /* branch */ 

            // Pass along whatever revert reason was given by the conduit.
c_0xfdb977c0(0x3f05ae79f8c8b77caf3800e9f1c95b1756d334afc2a864024d3d0657f7052f59); /* line */ 
            c_0xfdb977c0(0x31ef9cc7122b8392d2e7a7529fc5a71825915d4b1c899970c6814d8cb7d5c516); /* statement */ 
_revertWithReasonIfOneIsReturned();

            // Otherwise, revert with a generic error.
c_0xfdb977c0(0xf6720302d8606dfafe16fb8e905f82ef1936a46bf30868a3fb6dc2b8045cdf90); /* line */ 
            revert InvalidCallToConduit(conduit);
        }else { c_0xfdb977c0(0xd047a93cdf80464413ffa388f5bb5f0c792780b741686bd379c224a4567b959b); /* branch */ 
}

        // Ensure result was extracted and matches EIP-1271 magic value.
c_0xfdb977c0(0x46c12313c54601f1a1b6770a25ac8ea03a137085cf825a39e68f841546de5e24); /* line */ 
        c_0xfdb977c0(0x0653c1863213308a7e0659370b9c1391ea030ebd3ad9e137aa213222a8bea9c9); /* statement */ 
if (result != ConduitInterface.execute.selector) {c_0xfdb977c0(0x370df1e9ae26d9a7d1f08ea22005114f745da5f33c042796dfb24f3eae472a03); /* branch */ 

c_0xfdb977c0(0x4bab9b5cebec698379f421fb7af01fc73bc8d57c2d786f60f5b5e3808946b623); /* line */ 
            revert InvalidConduit(conduitKey, conduit);
        }else { c_0xfdb977c0(0xa892b398469b71c918a3061f1973a5b6612e3205b8993b3013c72e620a98852b); /* branch */ 
}
    }

    /**
     * @dev Internal pure function to retrieve the current conduit key set for
     *      the accumulator.
     *
     * @param accumulator An open-ended array that collects transfers to execute
     *                    against a given conduit in a single call.
     *
     * @return accumulatorConduitKey The conduit key currently set for the
     *                               accumulator.
     */
    function _getAccumulatorConduitKey(bytes memory accumulator)
        internal
        pure
        returns (bytes32 accumulatorConduitKey)
    {c_0xfdb977c0(0x4fdbc3d027f9c6a8ef4651fada89472cf99ef60e7e1c879ed6d07a6682463490); /* function */ 

        // Retrieve the current conduit key from the accumulator.
c_0xfdb977c0(0x06b49ed4e5d24bb6a245ad7df3045eafe63cd123623ae4623f860e4952b7be78); /* line */ 
        assembly {
            accumulatorConduitKey := mload(
                add(accumulator, Accumulator_conduitKey_ptr)
            )
        }
    }

    /**
     * @dev Internal pure function to place an item transfer into an accumulator
     *      that collects a series of transfers to execute against a given
     *      conduit in a single call.
     *
     * @param conduitKey  A bytes32 value indicating what corresponding conduit,
     *                    if any, to source token approvals from. The zero hash
     *                    signifies that no conduit should be used, with direct
     *                    approvals set on this contract.
     * @param accumulator An open-ended array that collects transfers to execute
     *                    against a given conduit in a single call.
     * @param itemType    The type of the item to transfer.
     * @param token       The token to transfer.
     * @param from        The originator of the transfer.
     * @param to          The recipient of the transfer.
     * @param identifier  The tokenId to transfer.
     * @param amount      The amount to transfer.
     */
    function _insert(
        bytes32 conduitKey,
        bytes memory accumulator,
        ConduitItemType itemType,
        address token,
        address from,
        address to,
        uint256 identifier,
        uint256 amount
    ) internal pure {c_0xfdb977c0(0x3d6f7a1b8b5fcf5092c86acdcf32a0b370d7c939475b5fdb2bd3cb06bd0f6984); /* function */ 

c_0xfdb977c0(0x1c4791b6b4e38e7d959a600d35e8b960f7005759c7bac48c0f111546a65df81e); /* line */ 
        c_0xfdb977c0(0xbd51fe5a9e137fc77388e9473ccb16bdf9ce3ef0a0299b92a3e7a0b403010071); /* statement */ 
uint256 elements;
        // "Arm" and prime accumulator if it's not already armed. The sentinel
        // value is held in the length of the accumulator array.
c_0xfdb977c0(0x766f2136f2db1c7a290340277c180d63dd12e24b9fef1efb56e1cdb2f1ce19bc); /* line */ 
        c_0xfdb977c0(0x38f3de19dc4b9fcd7b983af7d6ea11655478b6fe8e374a3a38bb2bd582781b42); /* statement */ 
if (accumulator.length == AccumulatorDisarmed) {c_0xfdb977c0(0xd51f9ca773ee8f6b9a5f7c059797038c9afabe85ada04658f08640060a618efa); /* branch */ 

c_0xfdb977c0(0x1dbadd4cee6f6f7e81d00b2aec177346203c5c66151e28fd767757127af295de); /* line */ 
            c_0xfdb977c0(0x15851a16c292744e01fdcbd73ca1185fdcc331f55d52640bfa53bd530d16442c); /* statement */ 
elements = 1;
c_0xfdb977c0(0xfdb90b7669604e33f582932e5322a4af4fb4f0965ef6520bfbddef31e5da5cf8); /* line */ 
            c_0xfdb977c0(0x75c4a5c7b8ef34fa853fee295ff0ba44a5f68af7e5bec7d4945c5964130d89f5); /* statement */ 
bytes4 selector = ConduitInterface.execute.selector;
c_0xfdb977c0(0xab19148e360ec9cc388f67e3cafaae5b915d9cd01d8a325d4c7a8cc08299d08d); /* line */ 
            assembly {
                mstore(accumulator, AccumulatorArmed) // "arm" the accumulator.
                mstore(add(accumulator, Accumulator_conduitKey_ptr), conduitKey)
                mstore(add(accumulator, Accumulator_selector_ptr), selector)
                mstore(
                    add(accumulator, Accumulator_array_offset_ptr),
                    Accumulator_array_offset
                )
                mstore(add(accumulator, Accumulator_array_length_ptr), elements)
            }
        } else {c_0xfdb977c0(0x97396044e02bd08fd768ccf4983996f8c833d9559816a2781b792ac834ee5d60); /* branch */ 

            // Otherwise, increase the number of elements by one.
c_0xfdb977c0(0x782a019766c3cdb9a7b6ddb286f06bb98fa82d4f80b210147318c83d555005c5); /* line */ 
            assembly {
                elements := add(
                    mload(add(accumulator, Accumulator_array_length_ptr)),
                    1
                )
                mstore(add(accumulator, Accumulator_array_length_ptr), elements)
            }
        }

        // Insert the item.
c_0xfdb977c0(0xfbfd71e3e5e8ddfe0bba1e9161bd24c72be85d49a53ad3e2cefc3f86e29cee43); /* line */ 
        assembly {
            let itemPointer := sub(
                add(accumulator, mul(elements, Conduit_transferItem_size)),
                Accumulator_itemSizeOffsetDifference
            )
            mstore(itemPointer, itemType)
            mstore(add(itemPointer, Conduit_transferItem_token_ptr), token)
            mstore(add(itemPointer, Conduit_transferItem_from_ptr), from)
            mstore(add(itemPointer, Conduit_transferItem_to_ptr), to)
            mstore(
                add(itemPointer, Conduit_transferItem_identifier_ptr),
                identifier
            )
            mstore(add(itemPointer, Conduit_transferItem_amount_ptr), amount)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// prettier-ignore
enum OrderType {
    // 0: no partial fills, anyone can execute
    FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    PARTIAL_RESTRICTED
}

// prettier-ignore
enum BasicOrderType {
    // 0: no partial fills, anyone can execute
    ETH_TO_ERC721_FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    ETH_TO_ERC721_PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    ETH_TO_ERC721_FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    ETH_TO_ERC721_PARTIAL_RESTRICTED,

    // 4: no partial fills, anyone can execute
    ETH_TO_ERC1155_FULL_OPEN,

    // 5: partial fills supported, anyone can execute
    ETH_TO_ERC1155_PARTIAL_OPEN,

    // 6: no partial fills, only offerer or zone can execute
    ETH_TO_ERC1155_FULL_RESTRICTED,

    // 7: partial fills supported, only offerer or zone can execute
    ETH_TO_ERC1155_PARTIAL_RESTRICTED,

    // 8: no partial fills, anyone can execute
    ERC20_TO_ERC721_FULL_OPEN,

    // 9: partial fills supported, anyone can execute
    ERC20_TO_ERC721_PARTIAL_OPEN,

    // 10: no partial fills, only offerer or zone can execute
    ERC20_TO_ERC721_FULL_RESTRICTED,

    // 11: partial fills supported, only offerer or zone can execute
    ERC20_TO_ERC721_PARTIAL_RESTRICTED,

    // 12: no partial fills, anyone can execute
    ERC20_TO_ERC1155_FULL_OPEN,

    // 13: partial fills supported, anyone can execute
    ERC20_TO_ERC1155_PARTIAL_OPEN,

    // 14: no partial fills, only offerer or zone can execute
    ERC20_TO_ERC1155_FULL_RESTRICTED,

    // 15: partial fills supported, only offerer or zone can execute
    ERC20_TO_ERC1155_PARTIAL_RESTRICTED,

    // 16: no partial fills, anyone can execute
    ERC721_TO_ERC20_FULL_OPEN,

    // 17: partial fills supported, anyone can execute
    ERC721_TO_ERC20_PARTIAL_OPEN,

    // 18: no partial fills, only offerer or zone can execute
    ERC721_TO_ERC20_FULL_RESTRICTED,

    // 19: partial fills supported, only offerer or zone can execute
    ERC721_TO_ERC20_PARTIAL_RESTRICTED,

    // 20: no partial fills, anyone can execute
    ERC1155_TO_ERC20_FULL_OPEN,

    // 21: partial fills supported, anyone can execute
    ERC1155_TO_ERC20_PARTIAL_OPEN,

    // 22: no partial fills, only offerer or zone can execute
    ERC1155_TO_ERC20_FULL_RESTRICTED,

    // 23: partial fills supported, only offerer or zone can execute
    ERC1155_TO_ERC20_PARTIAL_RESTRICTED
}

// prettier-ignore
enum BasicOrderRouteType {
    // 0: provide Ether (or other native token) to receive offered ERC721 item.
    ETH_TO_ERC721,

    // 1: provide Ether (or other native token) to receive offered ERC1155 item.
    ETH_TO_ERC1155,

    // 2: provide ERC20 item to receive offered ERC721 item.
    ERC20_TO_ERC721,

    // 3: provide ERC20 item to receive offered ERC1155 item.
    ERC20_TO_ERC1155,

    // 4: provide ERC721 item to receive offered ERC20 item.
    ERC721_TO_ERC20,

    // 5: provide ERC1155 item to receive offered ERC20 item.
    ERC1155_TO_ERC20
}

// prettier-ignore
enum ItemType {
    // 0: ETH on mainnet, MATIC on polygon, etc.
    NATIVE,

    // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
    ERC20,

    // 2: ERC721 items
    ERC721,

    // 3: ERC1155 items
    ERC1155,

    // 4: ERC721 items where a number of tokenIds are supported
    ERC721_WITH_CRITERIA,

    // 5: ERC1155 items where a number of ids are supported
    ERC1155_WITH_CRITERIA
}

// prettier-ignore
enum Side {
    // 0: Items that can be spent
    OFFER,

    // 1: Items that must be received
    CONSIDERATION
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {
    OrderType,
    BasicOrderType,
    ItemType,
    Side
} from "./ConsiderationEnums.sol";

/**
 * @dev An order contains eleven components: an offerer, a zone (or account that
 *      can cancel the order or restrict who can fulfill the order depending on
 *      the type), the order type (specifying partial fill support as well as
 *      restricted order status), the start and end time, a hash that will be
 *      provided to the zone when validating restricted orders, a salt, a key
 *      corresponding to a given conduit, a counter, and an arbitrary number of
 *      offer items that can be spent along with consideration items that must
 *      be received by their respective recipient.
 */
struct OrderComponents {
    address offerer;
    address zone;
    OfferItem[] offer;
    ConsiderationItem[] consideration;
    OrderType orderType;
    uint256 startTime;
    uint256 endTime;
    bytes32 zoneHash;
    uint256 salt;
    bytes32 conduitKey;
    uint256 counter;
}

/**
 * @dev An offer item has five components: an item type (ETH or other native
 *      tokens, ERC20, ERC721, and ERC1155, as well as criteria-based ERC721 and
 *      ERC1155), a token address, a dual-purpose "identifierOrCriteria"
 *      component that will either represent a tokenId or a merkle root
 *      depending on the item type, and a start and end amount that support
 *      increasing or decreasing amounts over the duration of the respective
 *      order.
 */
struct OfferItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
}

/**
 * @dev A consideration item has the same five components as an offer item and
 *      an additional sixth component designating the required recipient of the
 *      item.
 */
struct ConsiderationItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
    address payable recipient;
}

/**
 * @dev A spent item is translated from a utilized offer item and has four
 *      components: an item type (ETH or other native tokens, ERC20, ERC721, and
 *      ERC1155), a token address, a tokenId, and an amount.
 */
struct SpentItem {
    ItemType itemType;
    address token;
    uint256 identifier;
    uint256 amount;
}

/**
 * @dev A received item is translated from a utilized consideration item and has
 *      the same four components as a spent item, as well as an additional fifth
 *      component designating the required recipient of the item.
 */
struct ReceivedItem {
    ItemType itemType;
    address token;
    uint256 identifier;
    uint256 amount;
    address payable recipient;
}

/**
 * @dev For basic orders involving ETH / native / ERC20 <=> ERC721 / ERC1155
 *      matching, a group of six functions may be called that only requires a
 *      subset of the usual order arguments. Note the use of a "basicOrderType"
 *      enum; this represents both the usual order type as well as the "route"
 *      of the basic order (a simple derivation function for the basic order
 *      type is `basicOrderType = orderType + (4 * basicOrderRoute)`.)
 */
struct BasicOrderParameters {
    // calldata offset
    address considerationToken; // 0x24
    uint256 considerationIdentifier; // 0x44
    uint256 considerationAmount; // 0x64
    address payable offerer; // 0x84
    address zone; // 0xa4
    address offerToken; // 0xc4
    uint256 offerIdentifier; // 0xe4
    uint256 offerAmount; // 0x104
    BasicOrderType basicOrderType; // 0x124
    uint256 startTime; // 0x144
    uint256 endTime; // 0x164
    bytes32 zoneHash; // 0x184
    uint256 salt; // 0x1a4
    bytes32 offererConduitKey; // 0x1c4
    bytes32 fulfillerConduitKey; // 0x1e4
    uint256 totalOriginalAdditionalRecipients; // 0x204
    AdditionalRecipient[] additionalRecipients; // 0x224
    bytes signature; // 0x244
    // Total length, excluding dynamic array data: 0x264 (580)
}

/**
 * @dev Basic orders can supply any number of additional recipients, with the
 *      implied assumption that they are supplied from the offered ETH (or other
 *      native token) or ERC20 token for the order.
 */
struct AdditionalRecipient {
    uint256 amount;
    address payable recipient;
}

/**
 * @dev The full set of order components, with the exception of the counter,
 *      must be supplied when fulfilling more sophisticated orders or groups of
 *      orders. The total number of original consideration items must also be
 *      supplied, as the caller may specify additional consideration items.
 */
struct OrderParameters {
    address offerer; // 0x00
    address zone; // 0x20
    OfferItem[] offer; // 0x40
    ConsiderationItem[] consideration; // 0x60
    OrderType orderType; // 0x80
    uint256 startTime; // 0xa0
    uint256 endTime; // 0xc0
    bytes32 zoneHash; // 0xe0
    uint256 salt; // 0x100
    bytes32 conduitKey; // 0x120
    uint256 totalOriginalConsiderationItems; // 0x140
    // offer.length                          // 0x160
}

/**
 * @dev Orders require a signature in addition to the other order parameters.
 */
struct Order {
    OrderParameters parameters;
    bytes signature;
}

/**
 * @dev Advanced orders include a numerator (i.e. a fraction to attempt to fill)
 *      and a denominator (the total size of the order) in addition to the
 *      signature and other order parameters. It also supports an optional field
 *      for supplying extra data; this data will be included in a staticcall to
 *      `isValidOrderIncludingExtraData` on the zone for the order if the order
 *      type is restricted and the offerer or zone are not the caller.
 */
struct AdvancedOrder {
    OrderParameters parameters;
    uint120 numerator;
    uint120 denominator;
    bytes signature;
    bytes extraData;
}

/**
 * @dev Orders can be validated (either explicitly via `validate`, or as a
 *      consequence of a full or partial fill), specifically cancelled (they can
 *      also be cancelled in bulk via incrementing a per-zone counter), and
 *      partially or fully filled (with the fraction filled represented by a
 *      numerator and denominator).
 */
struct OrderStatus {
    bool isValidated;
    bool isCancelled;
    uint120 numerator;
    uint120 denominator;
}

/**
 * @dev A criteria resolver specifies an order, side (offer vs. consideration),
 *      and item index. It then provides a chosen identifier (i.e. tokenId)
 *      alongside a merkle proof demonstrating the identifier meets the required
 *      criteria.
 */
struct CriteriaResolver {
    uint256 orderIndex;
    Side side;
    uint256 index;
    uint256 identifier;
    bytes32[] criteriaProof;
}

/**
 * @dev A fulfillment is applied to a group of orders. It decrements a series of
 *      offer and consideration items, then generates a single execution
 *      element. A given fulfillment can be applied to as many offer and
 *      consideration items as desired, but must contain at least one offer and
 *      at least one consideration that match. The fulfillment must also remain
 *      consistent on all key parameters across all offer items (same offerer,
 *      token, type, tokenId, and conduit preference) as well as across all
 *      consideration items (token, type, tokenId, and recipient).
 */
struct Fulfillment {
    FulfillmentComponent[] offerComponents;
    FulfillmentComponent[] considerationComponents;
}

/**
 * @dev Each fulfillment component contains one index referencing a specific
 *      order and another referencing a specific offer or consideration item.
 */
struct FulfillmentComponent {
    uint256 orderIndex;
    uint256 itemIndex;
}

/**
 * @dev An execution is triggered once all consideration items have been zeroed
 *      out. It sends the item in question from the offerer to the item's
 *      recipient, optionally sourcing approvals from either this contract
 *      directly or from the offerer's chosen conduit if one is specified. An
 *      execution is not provided as an argument, but rather is derived via
 *      orders, criteria resolvers, and fulfillments (where the total number of
 *      executions will be less than or equal to the total number of indicated
 *      fulfillments) and returned as part of `matchOrders`.
 */
struct Execution {
    ReceivedItem item;
    address offerer;
    bytes32 conduitKey;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0x35ddea53(bytes32 c__0x35ddea53) pure {}


import { OrderStatus } from "./ConsiderationStructs.sol";

import { Assertions } from "./Assertions.sol";

import { SignatureVerification } from "./SignatureVerification.sol";

/**
 * @title Verifiers
 * @author 0age
 * @notice Verifiers contains functions for performing verifications.
 */
contract Verifiers is Assertions, SignatureVerification {
function c_0x0f1dd0fa(bytes32 c__0x0f1dd0fa) internal pure {}

    /**
     * @dev Derive and set hashes, reference chainId, and associated domain
     *      separator during deployment.
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     */
    constructor(address conduitController) Assertions(conduitController) {c_0x0f1dd0fa(0x00a7a8177b920265404c8744f43dbd35cb157323e72d62177dabdf54872d8798); /* function */ 
}

    /**
     * @dev Internal view function to ensure that the current time falls within
     *      an order's valid timespan.
     *
     * @param startTime       The time at which the order becomes active.
     * @param endTime         The time at which the order becomes inactive.
     * @param revertOnInvalid A boolean indicating whether to revert if the
     *                        order is not active.
     *
     * @return valid A boolean indicating whether the order is active.
     */
    function _verifyTime(
        uint256 startTime,
        uint256 endTime,
        bool revertOnInvalid
    ) internal view returns (bool valid) {c_0x0f1dd0fa(0x5fd0e3753bbf24f9db923928cf3eeecb4470dcccccd355c7d09daaca141ac231); /* function */ 

        // Revert if order's timespan hasn't started yet or has already ended.
c_0x0f1dd0fa(0x89e72d99d6d7691e8e8100302a8ed9974fa863ce777bd935067d7961aadf6fcc); /* line */ 
        c_0x0f1dd0fa(0xcd7bec9ccaf763138edf60dd4846de5fa212c1e01ef31d78ad3ed8f671b01de5); /* statement */ 
if (startTime > block.timestamp || endTime <= block.timestamp) {c_0x0f1dd0fa(0x97757db8649a501d248540927974d5784e7f6218ba09f4eef9508dd1bd7142c6); /* branch */ 

            // Only revert if revertOnInvalid has been supplied as true.
c_0x0f1dd0fa(0xfc95b71178405d7ba2891e835fe4d7e783119010551803083c22d61a01b5df38); /* line */ 
            c_0x0f1dd0fa(0x91e8dd78869457f8bf8406474533e35024a4da2ce16509d8591670d232c4849b); /* statement */ 
if (revertOnInvalid) {c_0x0f1dd0fa(0x9f69cb54464d4a3d306bc76959b5cdb9f6e6ea206fb40066649114e580694dc0); /* branch */ 

c_0x0f1dd0fa(0xc293fc09f62fcf44cdea2bfc04359959c749537fcdb0e3f321e1260447f962e9); /* line */ 
                revert InvalidTime();
            }else { c_0x0f1dd0fa(0xce0247fe9449d15a7fecb4ebed3aa2fbbd794118d0cb04a8d2fc6b00fa5aeb6f); /* branch */ 
}

            // Return false as the order is invalid.
c_0x0f1dd0fa(0xf44ac67ae51fe3cc4d16f4fe915677a6b37acfe517bb3da934d434f211603a4a); /* line */ 
            c_0x0f1dd0fa(0xbddb75340f270c27a93b44a55ffdf358aace631ab4e596f43f2459ba64243e50); /* statement */ 
return false;
        }else { c_0x0f1dd0fa(0x7505569eb9d44c08934f3ff14383bd313b2a2c6d7cf3bbba4f7718b73281dda9); /* branch */ 
}

        // Return true as the order time is valid.
c_0x0f1dd0fa(0x022b50b750afa9fe0a82f85e3f3a4d713c0ac67d4be42d0ac366d86f75cf4a1f); /* line */ 
        c_0x0f1dd0fa(0xf67b733795b9914ce866045f0bbd9db7e453eebd18732a7bb262d20cd98433d1); /* statement */ 
valid = true;
    }

    /**
     * @dev Internal view function to verify the signature of an order. An
     *      ERC-1271 fallback will be attempted if either the signature length
     *      is not 64 or 65 bytes or if the recovered signer does not match the
     *      supplied offerer. Note that in cases where a 64 or 65 byte signature
     *      is supplied, only standard ECDSA signatures that recover to a
     *      non-zero address are supported.
     *
     * @param offerer   The offerer for the order.
     * @param orderHash The order hash.
     * @param signature A signature from the offerer indicating that the order
     *                  has been approved.
     */
    function _verifySignature(
        address offerer,
        bytes32 orderHash,
        bytes memory signature
    ) internal view {c_0x0f1dd0fa(0x2a6ea87ac0ae1d4b1ceb0912c6362497b9d4038b964707f5596ac0ce61abfa3d); /* function */ 

        // Skip signature verification if the offerer is the caller.
c_0x0f1dd0fa(0xfbd99133fba1110a1bed2b36dc6d7ab5f3c8cb463a7781eb6b259dea06359e2f); /* line */ 
        c_0x0f1dd0fa(0xaee6f0a92e7403a30d414c3c354a674cfb1b278d0eb0708784fda79e81f312c3); /* statement */ 
if (offerer == msg.sender) {c_0x0f1dd0fa(0xcba393ca420e8e271a5ff5a27db3ad1c8a3850a921e7ca4fe190bf322a8b6304); /* branch */ 

c_0x0f1dd0fa(0xd12cfb6c80a89c60b0719dcb990133b98bd51ef5bcfdea7c4e27bcd7ea0888e4); /* line */ 
            c_0x0f1dd0fa(0x0edfafbf7fa35acce67972ffaf0cf95d805197459e34077f4e4de550f27f63c6); /* statement */ 
return;
        }else { c_0x0f1dd0fa(0x0e8790935216c2be6f7ffe2dfa8278b059b822d264d0fbc62a1a8db986f4fdf8); /* branch */ 
}

        // Derive EIP-712 digest using the domain separator and the order hash.
c_0x0f1dd0fa(0x9921364099709280f0aa877fda5761a87611170fafc22a31c764b2968d63604c); /* line */ 
        c_0x0f1dd0fa(0x9861f4c0e06a39a83a89692333b38ddbe999e0a953174877c67abe3798d02b6c); /* statement */ 
bytes32 digest = _deriveEIP712Digest(_domainSeparator(), orderHash);

        // Ensure that the signature for the digest is valid for the offerer.
c_0x0f1dd0fa(0x6d323ab6fa7d020230025e1a356dd0fd895b607f98298e8975df4cab46d705e5); /* line */ 
        c_0x0f1dd0fa(0xea8529f649fcd7abdb353382c6878111b58e02814ac51ff0ccaa3f49bd0178d2); /* statement */ 
_assertValidSignature(offerer, digest, signature);
    }

    /**
     * @dev Internal view function to validate that a given order is fillable
     *      and not cancelled based on the order status.
     *
     * @param orderHash       The order hash.
     * @param orderStatus     The status of the order, including whether it has
     *                        been cancelled and the fraction filled.
     * @param onlyAllowUnused A boolean flag indicating whether partial fills
     *                        are supported by the calling function.
     * @param revertOnInvalid A boolean indicating whether to revert if the
     *                        order has been cancelled or filled beyond the
     *                        allowable amount.
     *
     * @return valid A boolean indicating whether the order is valid.
     */
    function _verifyOrderStatus(
        bytes32 orderHash,
        OrderStatus storage orderStatus,
        bool onlyAllowUnused,
        bool revertOnInvalid
    ) internal view returns (bool valid) {c_0x0f1dd0fa(0xee49a2a8e24eae68bd6e52d6959f2f6274f30fb4dc93ca1c14da477fedbaf3c4); /* function */ 

        // Ensure that the order has not been cancelled.
c_0x0f1dd0fa(0xfa9cf18203e0606f77c8bace75d34eac591a3f1bd8533c39aa44496de71540c9); /* line */ 
        c_0x0f1dd0fa(0xcf8145f5b0420a02dab211a79ff948c19e621747fce52578f5b31d0e6d74ee94); /* statement */ 
if (orderStatus.isCancelled) {c_0x0f1dd0fa(0xb572fa2e2be369b5055fd723712cade404b46acf5d6b80955de54ccc47262f97); /* branch */ 

            // Only revert if revertOnInvalid has been supplied as true.
c_0x0f1dd0fa(0x7cf835fdf2e0a264ce69dc6a87aba6fe44bab1628a7fb165f68ce04eab8fcdc6); /* line */ 
            c_0x0f1dd0fa(0x046128aef961a223e8ed948ed70b319b94614bb582c5d8b68edfdef441796650); /* statement */ 
if (revertOnInvalid) {c_0x0f1dd0fa(0x880a7c5ae7222d61079ffbc3546ab3a45c9ec401b4e02795f175691d99d25200); /* branch */ 

c_0x0f1dd0fa(0xbc60e5534ebef80cf3ceca303939ae5ddf40eaf8ebbe0885ea6d017b3f14ff20); /* line */ 
                revert OrderIsCancelled(orderHash);
            }else { c_0x0f1dd0fa(0x2e5567a338b31a65d41264d7baff5ae5556573b6417bb513bcd5cd8c284ee01e); /* branch */ 
}

            // Return false as the order status is invalid.
c_0x0f1dd0fa(0x0edf6adae5364114a2f4567d9a92f8514e2d27b783c9d70506ef6bb66746d7c8); /* line */ 
            c_0x0f1dd0fa(0x231e770803045798659e1367e6158314d5fe54e9434e597f1bf8b6d6eec90771); /* statement */ 
return false;
        }else { c_0x0f1dd0fa(0xf47ea5d48a2b4ba89eec27e7d93028efc8ae2b7e82e50ea2f743c56e6a2ab532); /* branch */ 
}

        // Read order status numerator from storage and place on stack.
c_0x0f1dd0fa(0x13647b2a8eee1efb738911f93edda6f0e940bc7050218d67a9bc3910b9c5d0ce); /* line */ 
        c_0x0f1dd0fa(0xb1cbfcc6b786dad8c4df0a16a486048c43850e6836704fa5d8b02069d2760e11); /* statement */ 
uint256 orderStatusNumerator = orderStatus.numerator;

        // If the order is not entirely unused...
c_0x0f1dd0fa(0x2f503490b1d96db2ca321666b0a7368a8059b70abc7b368e363549bda9562889); /* line */ 
        c_0x0f1dd0fa(0xdf0a660e445326684e9db51b8212a9d18492b03063dd82716fd3c016e36aa775); /* statement */ 
if (orderStatusNumerator != 0) {c_0x0f1dd0fa(0x1cc372fd2f1421b321d15ba1925b1749d1cd47d4287c97d5ae61b5d97efa7036); /* branch */ 

            // ensure the order has not been partially filled when not allowed.
c_0x0f1dd0fa(0x686389cac45ce37ce9094ee80212c0c845c25dd4a4192d99ddea5f379b4ba8b3); /* line */ 
            c_0x0f1dd0fa(0xcb128f73983b12f55d57844afdad921d0917a7eb4fcb625fed2afb81abb85156); /* statement */ 
if (onlyAllowUnused) {c_0x0f1dd0fa(0x69a1088ebbbc770ebf6592550c6622ce12827d9a761360391ba99e0b1f4c353c); /* branch */ 

                // Always revert on partial fills when onlyAllowUnused is true.
c_0x0f1dd0fa(0xfb62e68e71eeec6223c16a2e45b6ac168cc77301684dab39b17880868f9dff60); /* line */ 
                revert OrderPartiallyFilled(orderHash);
            }
            // Otherwise, ensure that order has not been entirely filled.
            else {c_0x0f1dd0fa(0xbc56641b8a72a01fe3f75042b0e9a602f8d6bd6b439cc1381fa6a2fd1902b739); /* statement */ 
c_0x0f1dd0fa(0x0ef7d8ee19c76931cc234dacae1b4425a9818281136ace09222788e66921f9d3); /* branch */ 
if (orderStatusNumerator >= orderStatus.denominator) {c_0x0f1dd0fa(0x133fba19270a1611826b8e80c9cd7bcd604499293858c771dbb1d76d6d84c083); /* branch */ 

                // Only revert if revertOnInvalid has been supplied as true.
c_0x0f1dd0fa(0xcb61126266a7592b04b4d3e599106a81b49f13a5b767e3b5f04633419aaa967b); /* line */ 
                c_0x0f1dd0fa(0x9df65f7244c211815f0d8c2696e13a5826bc0c857737cfb73feb5fb4be9fdc79); /* statement */ 
if (revertOnInvalid) {c_0x0f1dd0fa(0xeb21714bc98e44ae7fd1d33ee1df0347e52a0235a56177da4741ac953a4671ac); /* branch */ 

c_0x0f1dd0fa(0x30fe804a3cfafc41048ddf62d9158c4232280e94038a629f40c4bfbfacd0bf41); /* line */ 
                    revert OrderAlreadyFilled(orderHash);
                }else { c_0x0f1dd0fa(0x624bc1e32f0d9879e99eec23de2d2a6fb29036c5cda4db867f1b911b8550d7a5); /* branch */ 
}

                // Return false as the order status is invalid.
c_0x0f1dd0fa(0xac9250d7687d920e6a6195b854c12e965e0062cb6e64b7deee026bebfe5138d2); /* line */ 
                c_0x0f1dd0fa(0x74a010bae1eb428f50b11cc0b3f44f68db994504175e3ba61de0086c919dc5af); /* statement */ 
return false;
            }else { c_0x0f1dd0fa(0x5e66b7d4503ceca2793a353874abe982fae6526c8540e759c4d94a89b9b1f8eb); /* branch */ 
}}
        }else { c_0x0f1dd0fa(0xc4e3e97c9240466c8186bc9d63905e977f501f6cb3d0ac7dd95833e730cb5c27); /* branch */ 
}

        // Return true as the order status is valid.
c_0x0f1dd0fa(0x8a12461d679506b0f445b1d1ac975db38e4d69fe67b63c5bc8d48a4979a0f9be); /* line */ 
        c_0x0f1dd0fa(0xf6bcd0a58be8727d8bf7434a12c2350cb7e09946dc3ae28f1b0b5d8a385dd5b3); /* statement */ 
valid = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*
 * -------------------------- Disambiguation & Other Notes ---------------------
 *    - The term "head" is used as it is in the documentation for ABI encoding,
 *      but only in reference to dynamic types, i.e. it always refers to the
 *      offset or pointer to the body of a dynamic type. In calldata, the head
 *      is always an offset (relative to the parent object), while in memory,
 *      the head is always the pointer to the body. More information found here:
 *      https://docs.soliditylang.org/en/v0.8.14/abi-spec.html#argument-encoding
 *        - Note that the length of an array is separate from and precedes the
 *          head of the array.
 *
 *    - The term "body" is used in place of the term "head" used in the ABI
 *      documentation. It refers to the start of the data for a dynamic type,
 *      e.g. the first word of a struct or the first word of the first element
 *      in an array.
 *
 *    - The term "pointer" is used to describe the absolute position of a value
 *      and never an offset relative to another value.
 *        - The suffix "_ptr" refers to a memory pointer.
 *        - The suffix "_cdPtr" refers to a calldata pointer.
 *
 *    - The term "offset" is used to describe the position of a value relative
 *      to some parent value. For example, OrderParameters_conduit_offset is the
 *      offset to the "conduit" value in the OrderParameters struct relative to
 *      the start of the body.
 *        - Note: Offsets are used to derive pointers.
 *
 *    - Some structs have pointers defined for all of their fields in this file.
 *      Lines which are commented out are fields that are not used in the
 *      codebase but have been left in for readability.
 */

// Declare constants for name, version, and reentrancy sentinel values.

// Name is right padded, so it touches the length which is left padded. This
// enables writing both values at once. Length goes at byte 95 in memory, and
// name fills bytes 96-109, so both values can be written left-padded to 77.
uint256 constant NameLengthPtr = 77;
uint256 constant NameWithLength = 0x0d436F6E73696465726174696F6E;

uint256 constant Version = 0x312e31;
uint256 constant Version_length = 3;
uint256 constant Version_shift = 0xe8;

uint256 constant _NOT_ENTERED = 1;
uint256 constant _ENTERED = 2;

// Common Offsets
// Offsets for identically positioned fields shared by:
// OfferItem, ConsiderationItem, SpentItem, ReceivedItem

uint256 constant Common_token_offset = 0x20;
uint256 constant Common_identifier_offset = 0x40;
uint256 constant Common_amount_offset = 0x60;

uint256 constant ReceivedItem_size = 0xa0;
uint256 constant ReceivedItem_amount_offset = 0x60;
uint256 constant ReceivedItem_recipient_offset = 0x80;

uint256 constant ReceivedItem_CommonParams_size = 0x60;

uint256 constant ConsiderationItem_recipient_offset = 0xa0;
// Store the same constant in an abbreviated format for a line length fix.
uint256 constant ConsiderItem_recipient_offset = 0xa0;

uint256 constant Execution_offerer_offset = 0x20;
uint256 constant Execution_conduit_offset = 0x40;

uint256 constant InvalidFulfillmentComponentData_error_signature = (
    0x7fda727900000000000000000000000000000000000000000000000000000000
);
uint256 constant InvalidFulfillmentComponentData_error_len = 0x04;

uint256 constant Panic_error_signature = (
    0x4e487b7100000000000000000000000000000000000000000000000000000000
);
uint256 constant Panic_error_offset = 0x04;
uint256 constant Panic_error_length = 0x24;
uint256 constant Panic_arithmetic = 0x11;

uint256 constant MissingItemAmount_error_signature = (
    0x91b3e51400000000000000000000000000000000000000000000000000000000
);
uint256 constant MissingItemAmount_error_len = 0x04;

uint256 constant OrderParameters_offer_head_offset = 0x40;
uint256 constant OrderParameters_consideration_head_offset = 0x60;
uint256 constant OrderParameters_conduit_offset = 0x120;
uint256 constant OrderParameters_counter_offset = 0x140;

uint256 constant Fulfillment_itemIndex_offset = 0x20;

uint256 constant AdvancedOrder_numerator_offset = 0x20;

uint256 constant AlmostOneWord = 0x1f;
uint256 constant OneWord = 0x20;
uint256 constant TwoWords = 0x40;
uint256 constant ThreeWords = 0x60;
uint256 constant FourWords = 0x80;
uint256 constant FiveWords = 0xa0;

uint256 constant FreeMemoryPointerSlot = 0x40;
uint256 constant ZeroSlot = 0x60;
uint256 constant DefaultFreeMemoryPointer = 0x80;

uint256 constant Slot0x80 = 0x80;
uint256 constant Slot0xA0 = 0xa0;

uint256 constant BasicOrder_endAmount_cdPtr = 0x104;
uint256 constant BasicOrder_common_params_size = 0xa0;
uint256 constant BasicOrder_considerationHashesArray_ptr = 0x160;

uint256 constant EIP712_Order_size = 0x180;
uint256 constant EIP712_OfferItem_size = 0xc0;
uint256 constant EIP712_ConsiderationItem_size = 0xe0;
uint256 constant AdditionalRecipients_size = 0x40;

uint256 constant EIP712_DomainSeparator_offset = 0x02;
uint256 constant EIP712_OrderHash_offset = 0x22;
uint256 constant EIP712_DigestPayload_size = 0x42;

uint256 constant receivedItemsHash_ptr = 0x60;

/*
 *  Memory layout in _prepareBasicFulfillmentFromCalldata of
 *  data for OrderFulfilled
 *
 *   event OrderFulfilled(
 *     bytes32 orderHash,
 *     address indexed offerer,
 *     address indexed zone,
 *     address fulfiller,
 *     SpentItem[] offer,
 *       > (itemType, token, id, amount)
 *     ReceivedItem[] consideration
 *       > (itemType, token, id, amount, recipient)
 *   )
 *
 *  - 0x00: orderHash
 *  - 0x20: fulfiller
 *  - 0x40: offer offset (0x80)
 *  - 0x60: consideration offset (0x120)
 *  - 0x80: offer.length (1)
 *  - 0xa0: offerItemType
 *  - 0xc0: offerToken
 *  - 0xe0: offerIdentifier
 *  - 0x100: offerAmount
 *  - 0x120: consideration.length (1 + additionalRecipients.length)
 *  - 0x140: considerationItemType
 *  - 0x160: considerationToken
 *  - 0x180: considerationIdentifier
 *  - 0x1a0: considerationAmount
 *  - 0x1c0: considerationRecipient
 *  - ...
 */

// Minimum length of the OrderFulfilled event data.
// Must be added to the size of the ReceivedItem array for additionalRecipients
// (0xa0 * additionalRecipients.length) to calculate full size of the buffer.
uint256 constant OrderFulfilled_baseSize = 0x1e0;
uint256 constant OrderFulfilled_selector = (
    0x9d9af8e38d66c62e2c12f0225249fd9d721c54b83f48d9352c97c6cacdcb6f31
);

// Minimum offset in memory to OrderFulfilled event data.
// Must be added to the size of the EIP712 hash array for additionalRecipients
// (32 * additionalRecipients.length) to calculate the pointer to event data.
uint256 constant OrderFulfilled_baseOffset = 0x180;
uint256 constant OrderFulfilled_consideration_length_baseOffset = 0x2a0;
uint256 constant OrderFulfilled_offer_length_baseOffset = 0x200;

// uint256 constant OrderFulfilled_orderHash_offset = 0x00;
uint256 constant OrderFulfilled_fulfiller_offset = 0x20;
uint256 constant OrderFulfilled_offer_head_offset = 0x40;
uint256 constant OrderFulfilled_offer_body_offset = 0x80;
uint256 constant OrderFulfilled_consideration_head_offset = 0x60;
uint256 constant OrderFulfilled_consideration_body_offset = 0x120;

// BasicOrderParameters
uint256 constant BasicOrder_parameters_cdPtr = 0x04;
uint256 constant BasicOrder_considerationToken_cdPtr = 0x24;
// uint256 constant BasicOrder_considerationIdentifier_cdPtr = 0x44;
uint256 constant BasicOrder_considerationAmount_cdPtr = 0x64;
uint256 constant BasicOrder_offerer_cdPtr = 0x84;
uint256 constant BasicOrder_zone_cdPtr = 0xa4;
uint256 constant BasicOrder_offerToken_cdPtr = 0xc4;
// uint256 constant BasicOrder_offerIdentifier_cdPtr = 0xe4;
uint256 constant BasicOrder_offerAmount_cdPtr = 0x104;
uint256 constant BasicOrder_basicOrderType_cdPtr = 0x124;
uint256 constant BasicOrder_startTime_cdPtr = 0x144;
// uint256 constant BasicOrder_endTime_cdPtr = 0x164;
// uint256 constant BasicOrder_zoneHash_cdPtr = 0x184;
// uint256 constant BasicOrder_salt_cdPtr = 0x1a4;
uint256 constant BasicOrder_offererConduit_cdPtr = 0x1c4;
uint256 constant BasicOrder_fulfillerConduit_cdPtr = 0x1e4;
uint256 constant BasicOrder_totalOriginalAdditionalRecipients_cdPtr = 0x204;
uint256 constant BasicOrder_additionalRecipients_head_cdPtr = 0x224;
uint256 constant BasicOrder_signature_cdPtr = 0x244;
uint256 constant BasicOrder_additionalRecipients_length_cdPtr = 0x264;
uint256 constant BasicOrder_additionalRecipients_data_cdPtr = 0x284;

uint256 constant BasicOrder_parameters_ptr = 0x20;

uint256 constant BasicOrder_basicOrderType_range = 0x18; // 24 values

/*
 *  Memory layout in _prepareBasicFulfillmentFromCalldata of
 *  EIP712 data for ConsiderationItem
 *   - 0x80: ConsiderationItem EIP-712 typehash (constant)
 *   - 0xa0: itemType
 *   - 0xc0: token
 *   - 0xe0: identifier
 *   - 0x100: startAmount
 *   - 0x120: endAmount
 *   - 0x140: recipient
 */
uint256 constant BasicOrder_considerationItem_typeHash_ptr = 0x80; // memoryPtr
uint256 constant BasicOrder_considerationItem_itemType_ptr = 0xa0;
uint256 constant BasicOrder_considerationItem_token_ptr = 0xc0;
uint256 constant BasicOrder_considerationItem_identifier_ptr = 0xe0;
uint256 constant BasicOrder_considerationItem_startAmount_ptr = 0x100;
uint256 constant BasicOrder_considerationItem_endAmount_ptr = 0x120;
// uint256 constant BasicOrder_considerationItem_recipient_ptr = 0x140;

/*
 *  Memory layout in _prepareBasicFulfillmentFromCalldata of
 *  EIP712 data for OfferItem
 *   - 0x80:  OfferItem EIP-712 typehash (constant)
 *   - 0xa0:  itemType
 *   - 0xc0:  token
 *   - 0xe0:  identifier (reused for offeredItemsHash)
 *   - 0x100: startAmount
 *   - 0x120: endAmount
 */
uint256 constant BasicOrder_offerItem_typeHash_ptr = DefaultFreeMemoryPointer;
uint256 constant BasicOrder_offerItem_itemType_ptr = 0xa0;
uint256 constant BasicOrder_offerItem_token_ptr = 0xc0;
// uint256 constant BasicOrder_offerItem_identifier_ptr = 0xe0;
// uint256 constant BasicOrder_offerItem_startAmount_ptr = 0x100;
uint256 constant BasicOrder_offerItem_endAmount_ptr = 0x120;

/*
 *  Memory layout in _prepareBasicFulfillmentFromCalldata of
 *  EIP712 data for Order
 *   - 0x80:   Order EIP-712 typehash (constant)
 *   - 0xa0:   orderParameters.offerer
 *   - 0xc0:   orderParameters.zone
 *   - 0xe0:   keccak256(abi.encodePacked(offerHashes))
 *   - 0x100:  keccak256(abi.encodePacked(considerationHashes))
 *   - 0x120:  orderType
 *   - 0x140:  startTime
 *   - 0x160:  endTime
 *   - 0x180:  zoneHash
 *   - 0x1a0:  salt
 *   - 0x1c0:  conduit
 *   - 0x1e0:  _counters[orderParameters.offerer] (from storage)
 */
uint256 constant BasicOrder_order_typeHash_ptr = 0x80;
uint256 constant BasicOrder_order_offerer_ptr = 0xa0;
// uint256 constant BasicOrder_order_zone_ptr = 0xc0;
uint256 constant BasicOrder_order_offerHashes_ptr = 0xe0;
uint256 constant BasicOrder_order_considerationHashes_ptr = 0x100;
uint256 constant BasicOrder_order_orderType_ptr = 0x120;
uint256 constant BasicOrder_order_startTime_ptr = 0x140;
// uint256 constant BasicOrder_order_endTime_ptr = 0x160;
// uint256 constant BasicOrder_order_zoneHash_ptr = 0x180;
// uint256 constant BasicOrder_order_salt_ptr = 0x1a0;
// uint256 constant BasicOrder_order_conduitKey_ptr = 0x1c0;
uint256 constant BasicOrder_order_counter_ptr = 0x1e0;
uint256 constant BasicOrder_additionalRecipients_head_ptr = 0x240;
uint256 constant BasicOrder_signature_ptr = 0x260;

// Signature-related
bytes32 constant EIP2098_allButHighestBitMask = (
    0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
);
bytes32 constant ECDSA_twentySeventhAndTwentyEighthBytesSet = (
    0x0000000000000000000000000000000000000000000000000000000101000000
);
uint256 constant ECDSA_MaxLength = 65;
uint256 constant ECDSA_signature_s_offset = 0x40;
uint256 constant ECDSA_signature_v_offset = 0x60;

bytes32 constant EIP1271_isValidSignature_selector = (
    0x1626ba7e00000000000000000000000000000000000000000000000000000000
);
uint256 constant EIP1271_isValidSignature_signatureHead_negativeOffset = 0x20;
uint256 constant EIP1271_isValidSignature_digest_negativeOffset = 0x40;
uint256 constant EIP1271_isValidSignature_selector_negativeOffset = 0x44;
uint256 constant EIP1271_isValidSignature_calldata_baseLength = 0x64;

uint256 constant EIP1271_isValidSignature_signature_head_offset = 0x40;

// abi.encodeWithSignature("NoContract(address)")
uint256 constant NoContract_error_signature = (
    0x5f15d67200000000000000000000000000000000000000000000000000000000
);
uint256 constant NoContract_error_sig_ptr = 0x0;
uint256 constant NoContract_error_token_ptr = 0x4;
uint256 constant NoContract_error_length = 0x24; // 4 + 32 == 36

uint256 constant EIP_712_PREFIX = (
    0x1901000000000000000000000000000000000000000000000000000000000000
);

uint256 constant ExtraGasBuffer = 0x20;
uint256 constant CostPerWord = 3;
uint256 constant MemoryExpansionCoefficient = 0x200; // 512

uint256 constant Create2AddressDerivation_ptr = 0x0b;
uint256 constant Create2AddressDerivation_length = 0x55;

uint256 constant MaskOverByteTwelve = (
    0x0000000000000000000000ff0000000000000000000000000000000000000000
);

uint256 constant MaskOverLastTwentyBytes = (
    0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff
);

uint256 constant MaskOverFirstFourBytes = (
    0xffffffff00000000000000000000000000000000000000000000000000000000
);

uint256 constant Conduit_execute_signature = (
    0x4ce34aa200000000000000000000000000000000000000000000000000000000
);

uint256 constant MaxUint8 = 0xff;
uint256 constant MaxUint120 = 0xffffffffffffffffffffffffffffff;

uint256 constant Conduit_execute_ConduitTransfer_ptr = 0x20;
uint256 constant Conduit_execute_ConduitTransfer_length = 0x01;

uint256 constant Conduit_execute_ConduitTransfer_offset_ptr = 0x04;
uint256 constant Conduit_execute_ConduitTransfer_length_ptr = 0x24;
uint256 constant Conduit_execute_transferItemType_ptr = 0x44;
uint256 constant Conduit_execute_transferToken_ptr = 0x64;
uint256 constant Conduit_execute_transferFrom_ptr = 0x84;
uint256 constant Conduit_execute_transferTo_ptr = 0xa4;
uint256 constant Conduit_execute_transferIdentifier_ptr = 0xc4;
uint256 constant Conduit_execute_transferAmount_ptr = 0xe4;

uint256 constant OneConduitExecute_size = 0x104;

// Sentinel value to indicate that the conduit accumulator is not armed.
uint256 constant AccumulatorDisarmed = 0x20;
uint256 constant AccumulatorArmed = 0x40;
uint256 constant Accumulator_conduitKey_ptr = 0x20;
uint256 constant Accumulator_selector_ptr = 0x40;
uint256 constant Accumulator_array_offset_ptr = 0x44;
uint256 constant Accumulator_array_length_ptr = 0x64;

uint256 constant Accumulator_itemSizeOffsetDifference = 0x3c;

uint256 constant Accumulator_array_offset = 0x20;
uint256 constant Conduit_transferItem_size = 0xc0;
uint256 constant Conduit_transferItem_token_ptr = 0x20;
uint256 constant Conduit_transferItem_from_ptr = 0x40;
uint256 constant Conduit_transferItem_to_ptr = 0x60;
uint256 constant Conduit_transferItem_identifier_ptr = 0x80;
uint256 constant Conduit_transferItem_amount_ptr = 0xa0;

// Declare constant for errors related to amount derivation.
// error InexactFraction() @ AmountDerivationErrors.sol
uint256 constant InexactFraction_error_signature = (
    0xc63cf08900000000000000000000000000000000000000000000000000000000
);
uint256 constant InexactFraction_error_len = 0x04;

// Declare constant for errors related to signature verification.
uint256 constant Ecrecover_precompile = 1;
uint256 constant Ecrecover_args_size = 0x80;
uint256 constant Signature_lower_v = 27;

// error BadSignatureV(uint8) @ SignatureVerificationErrors.sol
uint256 constant BadSignatureV_error_signature = (
    0x1f003d0a00000000000000000000000000000000000000000000000000000000
);
uint256 constant BadSignatureV_error_offset = 0x04;
uint256 constant BadSignatureV_error_length = 0x24;

// error InvalidSigner() @ SignatureVerificationErrors.sol
uint256 constant InvalidSigner_error_signature = (
    0x815e1d6400000000000000000000000000000000000000000000000000000000
);
uint256 constant InvalidSigner_error_length = 0x04;

// error InvalidSignature() @ SignatureVerificationErrors.sol
uint256 constant InvalidSignature_error_signature = (
    0x8baa579f00000000000000000000000000000000000000000000000000000000
);
uint256 constant InvalidSignature_error_length = 0x04;

// error BadContractSignature() @ SignatureVerificationErrors.sol
uint256 constant BadContractSignature_error_signature = (
    0x4f7fb80d00000000000000000000000000000000000000000000000000000000
);
uint256 constant BadContractSignature_error_length = 0x04;

uint256 constant NumBitsAfterSelector = 0xe0;

// 69 is the lowest modulus for which the remainder
// of every selector other than the two match functions
// is greater than those of the match functions.
uint256 constant NonMatchSelector_MagicModulus = 69;
// Of the two match function selectors, the highest
// remainder modulo 69 is 29.
uint256 constant NonMatchSelector_MagicRemainder = 0x1d;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0x6d7f7c19(bytes32 c__0x6d7f7c19) pure {}


import { OrderParameters } from "./ConsiderationStructs.sol";

import { GettersAndDerivers } from "./GettersAndDerivers.sol";

import {
    TokenTransferrerErrors
} from "../interfaces/TokenTransferrerErrors.sol";

import { CounterManager } from "./CounterManager.sol";

import "./ConsiderationConstants.sol";

/**
 * @title Assertions
 * @author 0age
 * @notice Assertions contains logic for making various assertions that do not
 *         fit neatly within a dedicated semantic scope.
 */
contract Assertions is
    GettersAndDerivers,
    CounterManager,
    TokenTransferrerErrors
{
function c_0x153f1102(bytes32 c__0x153f1102) internal pure {}

    /**
     * @dev Derive and set hashes, reference chainId, and associated domain
     *      separator during deployment.
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     */
    constructor(address conduitController)
        GettersAndDerivers(conduitController)
    {c_0x153f1102(0xa59aa9d75ea0e3970ca2a3995c1fe3b163c4beae1dd36f082b62ddd2b364a18c); /* function */ 
}

    /**
     * @dev Internal view function to ensure that the supplied consideration
     *      array length on a given set of order parameters is not less than the
     *      original consideration array length for that order and to retrieve
     *      the current counter for a given order's offerer and zone and use it
     *      to derive the order hash.
     *
     * @param orderParameters The parameters of the order to hash.
     *
     * @return The hash.
     */
    function _assertConsiderationLengthAndGetOrderHash(
        OrderParameters memory orderParameters
    ) internal view returns (bytes32) {c_0x153f1102(0xb780291709753e97d0b506cd1c29a6bce4d691aa94c38827f19d210d53e91ed6); /* function */ 

        // Ensure supplied consideration array length is not less than original.
c_0x153f1102(0x18e0acc8752c5acb495aa60e18e671f975ccfeec4f03e2b05154c8be56ae044a); /* line */ 
        c_0x153f1102(0x1f8fbc9edf28cf6e57cd00fbe40204a93a2ba415ad8acfb35b04b971863a17d7); /* statement */ 
_assertConsiderationLengthIsNotLessThanOriginalConsiderationLength(
            orderParameters.consideration.length,
            orderParameters.totalOriginalConsiderationItems
        );

        // Derive and return order hash using current counter for the offerer.
c_0x153f1102(0xa45c93d8d853c18547191bdc9916831f51baed5d35694abbfe9ac70a27f9c998); /* line */ 
        c_0x153f1102(0x422c3cca6b0e790a5a03a62d55ed8454f0c3d910b72e3e8d7c0c36bd09ff86f7); /* statement */ 
return
            _deriveOrderHash(
                orderParameters,
                _getCounter(orderParameters.offerer)
            );
    }

    /**
     * @dev Internal pure function to ensure that the supplied consideration
     *      array length for an order to be fulfilled is not less than the
     *      original consideration array length for that order.
     *
     * @param suppliedConsiderationItemTotal The number of consideration items
     *                                       supplied when fulfilling the order.
     * @param originalConsiderationItemTotal The number of consideration items
     *                                       supplied on initial order creation.
     */
    function _assertConsiderationLengthIsNotLessThanOriginalConsiderationLength(
        uint256 suppliedConsiderationItemTotal,
        uint256 originalConsiderationItemTotal
    ) internal pure {c_0x153f1102(0x9fe707d47084c1b486c346be69ac80b6ed879ca89659f030d45c962e34fb5949); /* function */ 

        // Ensure supplied consideration array length is not less than original.
c_0x153f1102(0x4b9eb82e01748c32423e5aa25446c14842212a424457ae171c45e056d7fd8d82); /* line */ 
        c_0x153f1102(0xbd3e3cedb68da65d54ebe30212f5158be57704233f71427a0ee47423ed1e9183); /* statement */ 
if (suppliedConsiderationItemTotal < originalConsiderationItemTotal) {c_0x153f1102(0x19a68f7fddded2c4702448810586eb5316316b80924e26de8abf706d36f4ffdc); /* branch */ 

c_0x153f1102(0x550531d5834902e5b6522db99642430adb7d1821793cbe84c2c7f05d580faef7); /* line */ 
            revert MissingOriginalConsiderationItems();
        }else { c_0x153f1102(0x63b6746e4385c467c19dd859e2150b64c2127e067ef3c4074644192d7c660710); /* branch */ 
}
    }

    /**
     * @dev Internal pure function to ensure that a given item amount is not
     *      zero.
     *
     * @param amount The amount to check.
     */
    function _assertNonZeroAmount(uint256 amount) internal pure {c_0x153f1102(0x2c3e7ab25b1d27fe9faf8b76825954a2f25ee913b4c2ec209e1c5556a7040222); /* function */ 

        // Revert if the supplied amount is equal to zero.
c_0x153f1102(0x7b382ea5636bc19d46aae5ffd468e8cb20734c0be0c68d939d084141b3bde4b3); /* line */ 
        c_0x153f1102(0x4e1d2b456b40e4b36d658bc91e027aab4b4e3168e89c27c4864063004d0bf57e); /* statement */ 
if (amount == 0) {c_0x153f1102(0x86600a58741fafb81e2cb3e03189aed8f7961752bfa91ebb0d9c92c35b4739f9); /* branch */ 

c_0x153f1102(0x1c1906eda52e514c867c5dc8fc6985c036ef9114c12a890b4e9a6141ff99dd59); /* line */ 
            revert MissingItemAmount();
        }else { c_0x153f1102(0x6310d0876a19f87b6f941551035ddfa99faee773e78cf875fd7f13d455e3866f); /* branch */ 
}
    }

    /**
     * @dev Internal pure function to validate calldata offsets for dynamic
     *      types in BasicOrderParameters and other parameters. This ensures
     *      that functions using the calldata object normally will be using the
     *      same data as the assembly functions and that values that are bound
     *      to a given range are within that range. Note that no parameters are
     *      supplied as all basic order functions use the same calldata
     *      encoding.
     */
    function _assertValidBasicOrderParameters() internal pure {c_0x153f1102(0x660e52f868013017c79f867826d581c2f899685bb174e437e033923f121132e6); /* function */ 

        // Declare a boolean designating basic order parameter offset validity.
c_0x153f1102(0x22e570705522e1891201adea37208c97920aea5e6242840edcbc78ae9d2a4d47); /* line */ 
        c_0x153f1102(0x5abde0f0ef6ccfd3ebc16d98f004be59516a2d3462724ffb4650b8010f8ff46d); /* statement */ 
bool validOffsets;

        // Utilize assembly in order to read offset data directly from calldata.
c_0x153f1102(0xab205e6cc858c3c361e5719119c141624d32c2432b6df4ba390f895535837e63); /* line */ 
        assembly {
            /*
             * Checks:
             * 1. Order parameters struct offset == 0x20
             * 2. Additional recipients arr offset == 0x240
             * 3. Signature offset == 0x260 + (recipients.length * 0x40)
             * 4. BasicOrderType between 0 and 23 (i.e. < 24)
             */
            validOffsets := and(
                // Order parameters at calldata 0x04 must have offset of 0x20.
                eq(
                    calldataload(BasicOrder_parameters_cdPtr),
                    BasicOrder_parameters_ptr
                ),
                // Additional recipients at cd 0x224 must have offset of 0x240.
                eq(
                    calldataload(BasicOrder_additionalRecipients_head_cdPtr),
                    BasicOrder_additionalRecipients_head_ptr
                )
            )

            validOffsets := and(
                validOffsets,
                eq(
                    // Load signature offset from calldata 0x244.
                    calldataload(BasicOrder_signature_cdPtr),
                    // Derive expected offset as start of recipients + len * 64.
                    add(
                        BasicOrder_signature_ptr,
                        mul(
                            // Additional recipients length at calldata 0x264.
                            calldataload(
                                BasicOrder_additionalRecipients_length_cdPtr
                            ),
                            // Each additional recipient has a length of 0x40.
                            AdditionalRecipients_size
                        )
                    )
                )
            )

            validOffsets := and(
                validOffsets,
                lt(
                    // BasicOrderType parameter at calldata offset 0x124.
                    calldataload(BasicOrder_basicOrderType_cdPtr),
                    // Value should be less than 24.
                    BasicOrder_basicOrderType_range
                )
            )
        }

        // Revert with an error if basic order parameter offsets are invalid.
c_0x153f1102(0xd0a309974fbc6bb37e5f476fa6bd42d33cb7eb6e99e4280b73768e26f98a083b); /* line */ 
        c_0x153f1102(0x320eac317f09cf6a553e1da61dde92228c55876729566f284d88b9c435e18f2b); /* statement */ 
if (!validOffsets) {c_0x153f1102(0x91b49aa6ed144be5147b25cf83012ecd58587fe123f87c748083125e310af684); /* branch */ 

c_0x153f1102(0xd6fbe236bcffae2aa50cd7bff31600632bda6887ff03ebff01b347e03d3bb184); /* line */ 
            revert InvalidBasicOrderParameterEncoding();
        }else { c_0x153f1102(0xd81fa34c06374f73d320f5c8b73c2fc22f1dbe4d6e1aee4a5d9fc04ccf9a51c9); /* branch */ 
}
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0x94accbfc(bytes32 c__0x94accbfc) pure {}


import { EIP1271Interface } from "../interfaces/EIP1271Interface.sol";

import {
    SignatureVerificationErrors
} from "../interfaces/SignatureVerificationErrors.sol";

import { LowLevelHelpers } from "./LowLevelHelpers.sol";

import "./ConsiderationConstants.sol";

/**
 * @title SignatureVerification
 * @author 0age
 * @notice SignatureVerification contains logic for verifying signatures.
 */
contract SignatureVerification is SignatureVerificationErrors, LowLevelHelpers {
function c_0xef3ac4a5(bytes32 c__0xef3ac4a5) internal pure {}

    /**
     * @dev Internal view function to verify the signature of an order. An
     *      ERC-1271 fallback will be attempted if either the signature length
     *      is not 64 or 65 bytes or if the recovered signer does not match the
     *      supplied signer.
     *
     * @param signer    The signer for the order.
     * @param digest    The digest to verify the signature against.
     * @param signature A signature from the signer indicating that the order
     *                  has been approved.
     */
    function _assertValidSignature(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view {c_0xef3ac4a5(0x69529481098b050c4b95592e79101e02c089121fbf07bc97f2895da6f92eeb25); /* function */ 

        // Declare value for ecrecover equality or 1271 call success status.
c_0xef3ac4a5(0x7608abd2dbad823756a579135c3f34bd9fb952ffe872a3bf610f809cf7dcbce3); /* line */ 
        c_0xef3ac4a5(0xc2b3ceb084bf1f7ea5ca7e9d51c4ec78bca480e895ef53b4928c864da20981be); /* statement */ 
bool success;

        // Utilize assembly to perform optimized signature verification check.
c_0xef3ac4a5(0x54030e532c9fd31fa7b05f61a85016fe7a5aff227b3f46c41f1bf66c0bc9f62d); /* line */ 
        assembly {
            // Ensure that first word of scratch space is empty.
            mstore(0, 0)

            // Declare value for v signature parameter.
            let v

            // Get the length of the signature.
            let signatureLength := mload(signature)

            // Get the pointer to the value preceding the signature length.
            // This will be used for temporary memory overrides - either the
            // signature head for isValidSignature or the digest for ecrecover.
            let wordBeforeSignaturePtr := sub(signature, OneWord)

            // Cache the current value behind the signature to restore it later.
            let cachedWordBeforeSignature := mload(wordBeforeSignaturePtr)

            // Declare lenDiff + recoveredSigner scope to manage stack pressure.
            {
                // Take the difference between the max ECDSA signature length
                // and the actual signature length. Overflow desired for any
                // values > 65. If the diff is not 0 or 1, it is not a valid
                // ECDSA signature - move on to EIP1271 check.
                let lenDiff := sub(ECDSA_MaxLength, signatureLength)

                // Declare variable for recovered signer.
                let recoveredSigner

                // If diff is 0 or 1, it may be an ECDSA signature.
                // Try to recover signer.
                if iszero(gt(lenDiff, 1)) {
                    // Read the signature `s` value.
                    let originalSignatureS := mload(
                        add(signature, ECDSA_signature_s_offset)
                    )

                    // Read the first byte of the word after `s`. If the
                    // signature is 65 bytes, this will be the real `v` value.
                    // If not, it will need to be modified - doing it this way
                    // saves an extra condition.
                    v := byte(
                        0,
                        mload(add(signature, ECDSA_signature_v_offset))
                    )

                    // If lenDiff is 1, parse 64-byte signature as ECDSA.
                    if lenDiff {
                        // Extract yParity from highest bit of vs and add 27 to
                        // get v.
                        v := add(
                            shr(MaxUint8, originalSignatureS),
                            Signature_lower_v
                        )

                        // Extract canonical s from vs, all but the highest bit.
                        // Temporarily overwrite the original `s` value in the
                        // signature.
                        mstore(
                            add(signature, ECDSA_signature_s_offset),
                            and(
                                originalSignatureS,
                                EIP2098_allButHighestBitMask
                            )
                        )
                    }
                    // Temporarily overwrite the signature length with `v` to
                    // conform to the expected input for ecrecover.
                    mstore(signature, v)

                    // Temporarily overwrite the word before the length with
                    // `digest` to conform to the expected input for ecrecover.
                    mstore(wordBeforeSignaturePtr, digest)

                    // Attempt to recover the signer for the given signature. Do
                    // not check the call status as ecrecover will return a null
                    // address if the signature is invalid.
                    pop(
                        staticcall(
                            gas(),
                            Ecrecover_precompile, // Call ecrecover precompile.
                            wordBeforeSignaturePtr, // Use data memory location.
                            Ecrecover_args_size, // Size of digest, v, r, and s.
                            0, // Write result to scratch space.
                            OneWord // Provide size of returned result.
                        )
                    )

                    // Restore cached word before signature.
                    mstore(wordBeforeSignaturePtr, cachedWordBeforeSignature)

                    // Restore cached signature length.
                    mstore(signature, signatureLength)

                    // Restore cached signature `s` value.
                    mstore(
                        add(signature, ECDSA_signature_s_offset),
                        originalSignatureS
                    )

                    // Read the recovered signer from the buffer given as return
                    // space for ecrecover.
                    recoveredSigner := mload(0)
                }

                // Set success to true if the signature provided was a valid
                // ECDSA signature and the signer is not the null address. Use
                // gt instead of direct as success is used outside of assembly.
                success := and(eq(signer, recoveredSigner), gt(signer, 0))
            }

            // If the signature was not verified with ecrecover, try EIP1271.
            if iszero(success) {
                // Temporarily overwrite the word before the signature length
                // and use it as the head of the signature input to
                // `isValidSignature`, which has a value of 64.
                mstore(
                    wordBeforeSignaturePtr,
                    EIP1271_isValidSignature_signature_head_offset
                )

                // Get pointer to use for the selector of `isValidSignature`.
                let selectorPtr := sub(
                    signature,
                    EIP1271_isValidSignature_selector_negativeOffset
                )

                // Cache the value currently stored at the selector pointer.
                let cachedWordOverwrittenBySelector := mload(selectorPtr)

                // Get pointer to use for `digest` input to `isValidSignature`.
                let digestPtr := sub(
                    signature,
                    EIP1271_isValidSignature_digest_negativeOffset
                )

                // Cache the value currently stored at the digest pointer.
                let cachedWordOverwrittenByDigest := mload(digestPtr)

                // Write the selector first, since it overlaps the digest.
                mstore(selectorPtr, EIP1271_isValidSignature_selector)

                // Next, write the digest.
                mstore(digestPtr, digest)

                // Call signer with `isValidSignature` to validate signature.
                success := staticcall(
                    gas(),
                    signer,
                    selectorPtr,
                    add(
                        signatureLength,
                        EIP1271_isValidSignature_calldata_baseLength
                    ),
                    0,
                    OneWord
                )

                // Determine if the signature is valid on successful calls.
                if success {
                    // If first word of scratch space does not contain EIP-1271
                    // signature selector, revert.
                    if iszero(eq(mload(0), EIP1271_isValidSignature_selector)) {
                        // Revert with bad 1271 signature if signer has code.
                        if extcodesize(signer) {
                            // Bad contract signature.
                            mstore(0, BadContractSignature_error_signature)
                            revert(0, BadContractSignature_error_length)
                        }

                        // Check if signature length was invalid.
                        if gt(sub(ECDSA_MaxLength, signatureLength), 1) {
                            // Revert with generic invalid signature error.
                            mstore(0, InvalidSignature_error_signature)
                            revert(0, InvalidSignature_error_length)
                        }

                        // Check if v was invalid.
                        if iszero(
                            byte(v, ECDSA_twentySeventhAndTwentyEighthBytesSet)
                        ) {
                            // Revert with invalid v value.
                            mstore(0, BadSignatureV_error_signature)
                            mstore(BadSignatureV_error_offset, v)
                            revert(0, BadSignatureV_error_length)
                        }

                        // Revert with generic invalid signer error message.
                        mstore(0, InvalidSigner_error_signature)
                        revert(0, InvalidSigner_error_length)
                    }
                }

                // Restore the cached values overwritten by selector, digest and
                // signature head.
                mstore(wordBeforeSignaturePtr, cachedWordBeforeSignature)
                mstore(selectorPtr, cachedWordOverwrittenBySelector)
                mstore(digestPtr, cachedWordOverwrittenByDigest)
            }
        }

        // If the call failed...
c_0xef3ac4a5(0x64dca4455de8d1849d5ebefe4bca7214164aff6248a6bc169df39a658145a2b0); /* line */ 
        c_0xef3ac4a5(0x6f8aac3681e3e572337de4e3b06e5447881767c3dbb1876be5aeeaeaf379152f); /* statement */ 
if (!success) {c_0xef3ac4a5(0x8cbda0c297e7d9aae7f2291ae1c0b223ff74488ddcfafe5bc88e01bbc08c4af9); /* branch */ 

            // Revert and pass reason along if one was returned.
c_0xef3ac4a5(0xd44a6374e157a1537d23079739173041487a5e3e97c90b9c55113776ba3b2fb2); /* line */ 
            c_0xef3ac4a5(0x6a9caa76b177a78ebb0e316686701de905afec9468167c2b4ce936b564644433); /* statement */ 
_revertWithReasonIfOneIsReturned();

            // Otherwise, revert with error indicating bad contract signature.
c_0xef3ac4a5(0x5bf5e1eb872bd365d7922fd7c11c226054671ecadab7207b5612ca4c55d6dc82); /* line */ 
            assembly {
                mstore(0, BadContractSignature_error_signature)
                revert(0, BadContractSignature_error_length)
            }
        }else { c_0xef3ac4a5(0xe47d96b6b93875e5e8c68960531fef33102aaf43f2dcf3323ddd7a42a13d4e6f); /* branch */ 
}
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0x42665e6d(bytes32 c__0x42665e6d) pure {}


import { OrderParameters } from "./ConsiderationStructs.sol";

import { ConsiderationBase } from "./ConsiderationBase.sol";

import "./ConsiderationConstants.sol";

/**
 * @title GettersAndDerivers
 * @author 0age
 * @notice ConsiderationInternal contains pure and internal view functions
 *         related to getting or deriving various values.
 */
contract GettersAndDerivers is ConsiderationBase {
function c_0xc7416ee6(bytes32 c__0xc7416ee6) internal pure {}

    /**
     * @dev Derive and set hashes, reference chainId, and associated domain
     *      separator during deployment.
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     */
    constructor(address conduitController)
        ConsiderationBase(conduitController)
    {c_0xc7416ee6(0xa851172cb685900209f3500ffca7d72deb3ec8a1642d449e53b1d634524c84b4); /* function */ 
}

    /**
     * @dev Internal view function to derive the order hash for a given order.
     *      Note that only the original consideration items are included in the
     *      order hash, as additional consideration items may be supplied by the
     *      caller.
     *
     * @param orderParameters The parameters of the order to hash.
     * @param counter           The counter of the order to hash.
     *
     * @return orderHash The hash.
     */
    function _deriveOrderHash(
        OrderParameters memory orderParameters,
        uint256 counter
    ) internal view returns (bytes32 orderHash) {c_0xc7416ee6(0xdf5a953319ee64dca5f99d38448c026be6ddd80c66a9bc6401a1cdd1fcb466b7); /* function */ 

        // Get length of original consideration array and place it on the stack.
c_0xc7416ee6(0x88466e0a637a7677921d76fd3e97825380a632cb8d3269ed8f242c00cb432aba); /* line */ 
        c_0xc7416ee6(0x169cf63230724f8e38892c851071df3e3c866128ab1414a405ff5f28276878b6); /* statement */ 
uint256 originalConsiderationLength = (
            orderParameters.totalOriginalConsiderationItems
        );

        /*
         * Memory layout for an array of structs (dynamic or not) is similar
         * to ABI encoding of dynamic types, with a head segment followed by
         * a data segment. The main difference is that the head of an element
         * is a memory pointer rather than an offset.
         */

        // Declare a variable for the derived hash of the offer array.
c_0xc7416ee6(0x149b5cdfea6b5bfb15579b05edbda81a479fac2f699f8921832410c2faaea500); /* line */ 
        c_0xc7416ee6(0x672c4889f4a277ecb95163ac0bc357e26a0986c8e4423b20a5ce4bfee164e909); /* statement */ 
bytes32 offerHash;

        // Read offer item EIP-712 typehash from runtime code & place on stack.
c_0xc7416ee6(0x1f05c62c2374c7803ea9c15a329b5fb6160707bbbe4292cfde9c31156dcfd0da); /* line */ 
        c_0xc7416ee6(0x50d7b54481b1e3041f4b408833c541d76691232d77a1383339a7d2e8c5cd9ca3); /* statement */ 
bytes32 typeHash = _OFFER_ITEM_TYPEHASH;

        // Utilize assembly so that memory regions can be reused across hashes.
c_0xc7416ee6(0x3c2f37a86fa1f4467800fd83a28c018bf572b74e91f4bdcb97c442ab45f224c0); /* line */ 
        assembly {
            // Retrieve the free memory pointer and place on the stack.
            let hashArrPtr := mload(FreeMemoryPointerSlot)

            // Get the pointer to the offers array.
            let offerArrPtr := mload(
                add(orderParameters, OrderParameters_offer_head_offset)
            )

            // Load the length.
            let offerLength := mload(offerArrPtr)

            // Set the pointer to the first offer's head.
            offerArrPtr := add(offerArrPtr, OneWord)

            // Iterate over the offer items.
            // prettier-ignore
            for { let i := 0 } lt(i, offerLength) {
                i := add(i, 1)
            } {
                // Read the pointer to the offer data and subtract one word
                // to get typeHash pointer.
                let ptr := sub(mload(offerArrPtr), OneWord)

                // Read the current value before the offer data.
                let value := mload(ptr)

                // Write the type hash to the previous word.
                mstore(ptr, typeHash)

                // Take the EIP712 hash and store it in the hash array.
                mstore(hashArrPtr, keccak256(ptr, EIP712_OfferItem_size))

                // Restore the previous word.
                mstore(ptr, value)

                // Increment the array pointers by one word.
                offerArrPtr := add(offerArrPtr, OneWord)
                hashArrPtr := add(hashArrPtr, OneWord)
            }

            // Derive the offer hash using the hashes of each item.
            offerHash := keccak256(
                mload(FreeMemoryPointerSlot),
                mul(offerLength, OneWord)
            )
        }

        // Declare a variable for the derived hash of the consideration array.
c_0xc7416ee6(0xad68fa5f541b5a87d219c4a62e766334e58441f3c67607f8e578d80ef7fb16a9); /* line */ 
        c_0xc7416ee6(0x61244d0b2180624323acc7399a7e5bb7439e4b910a014188e3e7c0b2665043cc); /* statement */ 
bytes32 considerationHash;

        // Read consideration item typehash from runtime code & place on stack.
c_0xc7416ee6(0x200bb825a39a7ee05293af32909eb63f5ef58bb26c64bc5cfb76074ba224eba9); /* line */ 
        c_0xc7416ee6(0x4747c3ad31423c29da08639cca0229ac9410e50e29771b6550eb3fbd1142ff3b); /* statement */ 
typeHash = _CONSIDERATION_ITEM_TYPEHASH;

        // Utilize assembly so that memory regions can be reused across hashes.
c_0xc7416ee6(0x43d155fe25cafe150222bf3f71d47421ca33417346732414123e4b218ce2e868); /* line */ 
        assembly {
            // Retrieve the free memory pointer and place on the stack.
            let hashArrPtr := mload(FreeMemoryPointerSlot)

            // Get the pointer to the consideration array.
            let considerationArrPtr := add(
                mload(
                    add(
                        orderParameters,
                        OrderParameters_consideration_head_offset
                    )
                ),
                OneWord
            )

            // Iterate over the consideration items (not including tips).
            // prettier-ignore
            for { let i := 0 } lt(i, originalConsiderationLength) {
                i := add(i, 1)
            } {
                // Read the pointer to the consideration data and subtract one
                // word to get typeHash pointer.
                let ptr := sub(mload(considerationArrPtr), OneWord)

                // Read the current value before the consideration data.
                let value := mload(ptr)

                // Write the type hash to the previous word.
                mstore(ptr, typeHash)

                // Take the EIP712 hash and store it in the hash array.
                mstore(
                    hashArrPtr,
                    keccak256(ptr, EIP712_ConsiderationItem_size)
                )

                // Restore the previous word.
                mstore(ptr, value)

                // Increment the array pointers by one word.
                considerationArrPtr := add(considerationArrPtr, OneWord)
                hashArrPtr := add(hashArrPtr, OneWord)
            }

            // Derive the consideration hash using the hashes of each item.
            considerationHash := keccak256(
                mload(FreeMemoryPointerSlot),
                mul(originalConsiderationLength, OneWord)
            )
        }

        // Read order item EIP-712 typehash from runtime code & place on stack.
c_0xc7416ee6(0xce2c461d24b7d076969d69d5894f1646ae013bcaab64893b656316f217fa35ba); /* line */ 
        c_0xc7416ee6(0x4cfede84260f12530dd9cc3596755fe7a27c67bcddf299a003d59519a0fcf97d); /* statement */ 
typeHash = _ORDER_TYPEHASH;

        // Utilize assembly to access derived hashes & other arguments directly.
c_0xc7416ee6(0xf26f7b09121fb41705429abe16d69a1ec542fef1194ccb04f17e54a92867d296); /* line */ 
        assembly {
            // Retrieve pointer to the region located just behind parameters.
            let typeHashPtr := sub(orderParameters, OneWord)

            // Store the value at that pointer location to restore later.
            let previousValue := mload(typeHashPtr)

            // Store the order item EIP-712 typehash at the typehash location.
            mstore(typeHashPtr, typeHash)

            // Retrieve the pointer for the offer array head.
            let offerHeadPtr := add(
                orderParameters,
                OrderParameters_offer_head_offset
            )

            // Retrieve the data pointer referenced by the offer head.
            let offerDataPtr := mload(offerHeadPtr)

            // Store the offer hash at the retrieved memory location.
            mstore(offerHeadPtr, offerHash)

            // Retrieve the pointer for the consideration array head.
            let considerationHeadPtr := add(
                orderParameters,
                OrderParameters_consideration_head_offset
            )

            // Retrieve the data pointer referenced by the consideration head.
            let considerationDataPtr := mload(considerationHeadPtr)

            // Store the consideration hash at the retrieved memory location.
            mstore(considerationHeadPtr, considerationHash)

            // Retrieve the pointer for the counter.
            let counterPtr := add(
                orderParameters,
                OrderParameters_counter_offset
            )

            // Store the counter at the retrieved memory location.
            mstore(counterPtr, counter)

            // Derive the order hash using the full range of order parameters.
            orderHash := keccak256(typeHashPtr, EIP712_Order_size)

            // Restore the value previously held at typehash pointer location.
            mstore(typeHashPtr, previousValue)

            // Restore offer data pointer at the offer head pointer location.
            mstore(offerHeadPtr, offerDataPtr)

            // Restore consideration data pointer at the consideration head ptr.
            mstore(considerationHeadPtr, considerationDataPtr)

            // Restore consideration item length at the counter pointer.
            mstore(counterPtr, originalConsiderationLength)
        }
    }

    /**
     * @dev Internal view function to derive the address of a given conduit
     *      using a corresponding conduit key.
     *
     * @param conduitKey A bytes32 value indicating what corresponding conduit,
     *                   if any, to source token approvals from. This value is
     *                   the "salt" parameter supplied by the deployer (i.e. the
     *                   conduit controller) when deploying the given conduit.
     *
     * @return conduit The address of the conduit associated with the given
     *                 conduit key.
     */
    function _deriveConduit(bytes32 conduitKey)
        internal
        view
        returns (address conduit)
    {c_0xc7416ee6(0xc660d08e998bf8bdf2c30c1d44ae8cf57f9178f6ce104184d56fbaccfc87963b); /* function */ 

        // Read conduit controller address from runtime and place on the stack.
c_0xc7416ee6(0x631b03f6d090622e14a5e716d8f9592010b135eb7729a6c53d12c0cc3e93b13f); /* line */ 
        c_0xc7416ee6(0x9124ef77b241441ded2e2a76a9e854ce37bd809d2f112625e31deee66c586f34); /* statement */ 
address conduitController = address(_CONDUIT_CONTROLLER);

        // Read conduit creation code hash from runtime and place on the stack.
c_0xc7416ee6(0xdb9bf363853c5edf3298e07d5f3e32d3b401cf850e819bb218fe48be2dc16f78); /* line */ 
        c_0xc7416ee6(0xe7ec5e99843606a00466e01d24adac4d4a27d5f5909447621c44bc12da9507b4); /* statement */ 
bytes32 conduitCreationCodeHash = _CONDUIT_CREATION_CODE_HASH;

        // Leverage scratch space to perform an efficient hash.
c_0xc7416ee6(0xff81e2ef9da60ef29f543f6fdde956f4eac5717cbbabe8c24c4cb3281aff6130); /* line */ 
        assembly {
            // Retrieve the free memory pointer; it will be replaced afterwards.
            let freeMemoryPointer := mload(FreeMemoryPointerSlot)

            // Place the control character and the conduit controller in scratch
            // space; note that eleven bytes at the beginning are left unused.
            mstore(0, or(MaskOverByteTwelve, conduitController))

            // Place the conduit key in the next region of scratch space.
            mstore(OneWord, conduitKey)

            // Place conduit creation code hash in free memory pointer location.
            mstore(TwoWords, conduitCreationCodeHash)

            // Derive conduit by hashing and applying a mask over last 20 bytes.
            conduit := and(
                // Hash the relevant region.
                keccak256(
                    // The region starts at memory pointer 11.
                    Create2AddressDerivation_ptr,
                    // The region is 85 bytes long (1 + 20 + 32 + 32).
                    Create2AddressDerivation_length
                ),
                // The address equals the last twenty bytes of the hash.
                MaskOverLastTwentyBytes
            )

            // Restore the free memory pointer.
            mstore(FreeMemoryPointerSlot, freeMemoryPointer)
        }
    }

    /**
     * @dev Internal view function to get the EIP-712 domain separator. If the
     *      chainId matches the chainId set on deployment, the cached domain
     *      separator will be returned; otherwise, it will be derived from
     *      scratch.
     *
     * @return The domain separator.
     */
    function _domainSeparator() internal view returns (bytes32) {c_0xc7416ee6(0x009b35befa427b4ea090f239da877adeec45a37bc13680ddc209a3f094163d90); /* function */ 

        // prettier-ignore
c_0xc7416ee6(0x80119948a18793d2733a4587142c45e9cd238bc5767642868a68e565b91d0ce3); /* line */ 
        c_0xc7416ee6(0xd61c106402290b965f768500b64a03ada2f2f8a4bae2c4fd51c94ec1e1fa2fa3); /* statement */ 
return block.chainid == _CHAIN_ID
            ? _DOMAIN_SEPARATOR
            : _deriveDomainSeparator();
    }

    /**
     * @dev Internal view function to retrieve configuration information for
     *      this contract.
     *
     * @return version           The contract version.
     * @return domainSeparator   The domain separator for this contract.
     * @return conduitController The conduit Controller set for this contract.
     */
    function _information()
        internal
        view
        returns (
            string memory version,
            bytes32 domainSeparator,
            address conduitController
        )
    {c_0xc7416ee6(0x04469604e1a546b42f281a38844ff17d5f0ebb9f9b0428ca7bff97265566e2c3); /* function */ 

        // Derive the domain separator.
c_0xc7416ee6(0x6b09fd5d9a59f3908c570cbfbed9f5c3dde2bad6481abc938ee6899a592789f4); /* line */ 
        c_0xc7416ee6(0xfaf158f19e569ef859a6002337d118f62e67d26f62f6ff972a7f83991411bc67); /* statement */ 
domainSeparator = _domainSeparator();

        // Declare variable as immutables cannot be accessed within assembly.
c_0xc7416ee6(0x8830e10f53de7b56f9a45fd41f6e693e1ca2e74ce30aebd819c2fb153ce5c980); /* line */ 
        c_0xc7416ee6(0x67e7789b0064a7097b005fecec70fc2cc66693d038fa2f3fc9f10606caa0eb4f); /* statement */ 
conduitController = address(_CONDUIT_CONTROLLER);

        // Allocate a string with the intended length.
c_0xc7416ee6(0x941e53ed72017b4d115395680cd28c1938835fdabe5b838489306d58c9db0f1a); /* line */ 
        c_0xc7416ee6(0xe3f6e6f5d3b5d2219f239dcbde88498c657c23e9f6684e44b3fd294f1cb4a4e3); /* statement */ 
version = new string(Version_length);

        // Set the version as data on the newly allocated string.
c_0xc7416ee6(0xac7510c56a9e4ce1136603ece63d4d85f7a1f14f2e72561d43408b6ddfde62dd); /* line */ 
        assembly {
            mstore(add(version, OneWord), shl(Version_shift, Version))
        }
    }

    /**
     * @dev Internal pure function to efficiently derive an digest to sign for
     *      an order in accordance with EIP-712.
     *
     * @param domainSeparator The domain separator.
     * @param orderHash       The order hash.
     *
     * @return value The hash.
     */
    function _deriveEIP712Digest(bytes32 domainSeparator, bytes32 orderHash)
        internal
        pure
        returns (bytes32 value)
    {c_0xc7416ee6(0xb300e653d763262f04750b97fa5b05bb0c53df138f39d983bb6ddbaef029a51f); /* function */ 

        // Leverage scratch space to perform an efficient hash.
c_0xc7416ee6(0x350d0c59a01512abc1876b81cbeb26f2ae11e6edc8a558fc839404be4ea767e2); /* line */ 
        assembly {
            // Place the EIP-712 prefix at the start of scratch space.
            mstore(0, EIP_712_PREFIX)

            // Place the domain separator in the next region of scratch space.
            mstore(EIP712_DomainSeparator_offset, domainSeparator)

            // Place the order hash in scratch space, spilling into the first
            // two bytes of the free memory pointer — this should never be set
            // as memory cannot be expanded to that size, and will be zeroed out
            // after the hash is performed.
            mstore(EIP712_OrderHash_offset, orderHash)

            // Hash the relevant region (65 bytes).
            value := keccak256(0, EIP712_DigestPayload_size)

            // Clear out the dirtied bits in the memory pointer.
            mstore(EIP712_OrderHash_offset, 0)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0x7e078d70(bytes32 c__0x7e078d70) pure {}


import {
    ConsiderationEventsAndErrors
} from "../interfaces/ConsiderationEventsAndErrors.sol";

import { ReentrancyGuard } from "./ReentrancyGuard.sol";

/**
 * @title CounterManager
 * @author 0age
 * @notice CounterManager contains a storage mapping and related functionality
 *         for retrieving and incrementing a per-offerer counter.
 */
contract CounterManager is ConsiderationEventsAndErrors, ReentrancyGuard {
function c_0xadd067ae(bytes32 c__0xadd067ae) internal pure {}

    // Only orders signed using an offerer's current counter are fulfillable.
    mapping(address => uint256) private _counters;

    /**
     * @dev Internal function to cancel all orders from a given offerer with a
     *      given zone in bulk by incrementing a counter. Note that only the
     *      offerer may increment the counter.
     *
     * @return newCounter The new counter.
     */
    function _incrementCounter() internal returns (uint256 newCounter) {c_0xadd067ae(0x0a22fa2668e412144b4586c7e491a17fb40db020a6a3a011dca8b3c6eeb24be8); /* function */ 

        // Ensure that the reentrancy guard is not currently set.
c_0xadd067ae(0xe521c9afade7349f12fea2ac132853bd4254670afbdb2e2d01ae062fd71d08cf); /* line */ 
        c_0xadd067ae(0x864a8e8148bcee11d3f47e8b0677a8cafe821b965d26622dc4d2d8d4e3c597d3); /* statement */ 
_assertNonReentrant();

        // Skip overflow check as counter cannot be incremented that far.
c_0xadd067ae(0xe9b87996117b514b2c4ef5c19899e741bffd9a324e8ae71675a43cda87083715); /* line */ 
        unchecked {
            // Increment current counter for the supplied offerer.
c_0xadd067ae(0x26c75c892489bcccef3725d2444ab6daaf0daf2a11d4ff226124c61ab9b65b0e); /* line */ 
            c_0xadd067ae(0xdccab599645571f0d814c5f3e23ec3e2e39d6b4648bab1b1445a290efdfc5b83); /* statement */ 
newCounter = ++_counters[msg.sender];
        }

        // Emit an event containing the new counter.
c_0xadd067ae(0x635d01363133d333171dbdcc7c76a8023863615ea665ae6446ea0374e6adac72); /* line */ 
        c_0xadd067ae(0x4a56b482472005e528e3e15404a84bc535a43a787036278c5753489207f4d632); /* statement */ 
emit CounterIncremented(newCounter, msg.sender);
    }

    /**
     * @dev Internal view function to retrieve the current counter for a given
     *      offerer.
     *
     * @param offerer The offerer in question.
     *
     * @return currentCounter The current counter.
     */
    function _getCounter(address offerer)
        internal
        view
        returns (uint256 currentCounter)
    {c_0xadd067ae(0xf7b33cc258a4a37a79b1761ae0c92dcec75245512a97b0de5620fde733cac153); /* function */ 

        // Return the counter for the supplied offerer.
c_0xadd067ae(0xc9e877f7b5a7a97a037920f7244b74faf914b1db571376d3f619971b51e4202d); /* line */ 
        c_0xadd067ae(0x1d910eebf664e6dabcb3d8118aa51e307a5561a06d8a980d61e2f01e0453e619); /* statement */ 
currentCounter = _counters[offerer];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0x94e36458(bytes32 c__0x94e36458) pure {}


import {
    ConduitControllerInterface
} from "../interfaces/ConduitControllerInterface.sol";

import {
    ConsiderationEventsAndErrors
} from "../interfaces/ConsiderationEventsAndErrors.sol";

import "./ConsiderationConstants.sol";

/**
 * @title ConsiderationBase
 * @author 0age
 * @notice ConsiderationBase contains immutable constants and constructor logic.
 */
contract ConsiderationBase is ConsiderationEventsAndErrors {
function c_0x2323d794(bytes32 c__0x2323d794) internal pure {}

    // Precompute hashes, original chainId, and domain separator on deployment.
    bytes32 internal immutable _NAME_HASH;
    bytes32 internal immutable _VERSION_HASH;
    bytes32 internal immutable _EIP_712_DOMAIN_TYPEHASH;
    bytes32 internal immutable _OFFER_ITEM_TYPEHASH;
    bytes32 internal immutable _CONSIDERATION_ITEM_TYPEHASH;
    bytes32 internal immutable _ORDER_TYPEHASH;
    uint256 internal immutable _CHAIN_ID;
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    // Allow for interaction with the conduit controller.
    ConduitControllerInterface internal immutable _CONDUIT_CONTROLLER;

    // Cache the conduit creation code hash used by the conduit controller.
    bytes32 internal immutable _CONDUIT_CREATION_CODE_HASH;

    /**
     * @dev Derive and set hashes, reference chainId, and associated domain
     *      separator during deployment.
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     */
    constructor(address conduitController) {c_0x2323d794(0x80b4887de9d43dc50d34e6b435916f8118026b3bb55f1b3bf444e9fb95802892); /* function */ 

        // Derive name and version hashes alongside required EIP-712 typehashes.
c_0x2323d794(0xf8ec3714e6835170788ac955a5f2b78bdfebfbc33b2e636fbd77c7f37d36a71c); /* line */ 
        c_0x2323d794(0x729992fa1c3e64e220683104a39eb2e2da4204215db22fff6ccd54090cabd5e9); /* statement */ 
(
            _NAME_HASH,
            _VERSION_HASH,
            _EIP_712_DOMAIN_TYPEHASH,
            _OFFER_ITEM_TYPEHASH,
            _CONSIDERATION_ITEM_TYPEHASH,
            _ORDER_TYPEHASH
        ) = _deriveTypehashes();

        // Store the current chainId and derive the current domain separator.
c_0x2323d794(0x83bb9802fec574ba686d1d646692c5ad848ae352341c1f358011c35c768a2dfa); /* line */ 
        c_0x2323d794(0x6417f1691922596cd3fbf4335676a2ec9de13dc5765e79a42e1d64dd4c6507e8); /* statement */ 
_CHAIN_ID = block.chainid;
c_0x2323d794(0x77a3133adad8590c7f8a321075549e92894536a7d64320eaa4af1a3e8b9e2521); /* line */ 
        c_0x2323d794(0x6a1416e316c7709631ba4e8e0eef10c27223e7f25e32d7aa094c45cf6c689e69); /* statement */ 
_DOMAIN_SEPARATOR = _deriveDomainSeparator();

        // Set the supplied conduit controller.
c_0x2323d794(0x9736355c657c7ec640e68d98f9de3038ccd9b0e5cefda8f798d0ed82833982c3); /* line */ 
        c_0x2323d794(0x7ba7aedd9e0049ba7e2db762137f7ac72ac626f73dd7b7204cfe186b863091f5); /* statement */ 
_CONDUIT_CONTROLLER = ConduitControllerInterface(conduitController);

        // Retrieve the conduit creation code hash from the supplied controller.
c_0x2323d794(0xe24764c63f225f2483db072746d2e80676bb8fe4b4f892c9605c39d141086874); /* line */ 
        c_0x2323d794(0x13924e26051893c307269bc1cec038f40ff850881400afe36639159e21b6d5c0); /* statement */ 
(_CONDUIT_CREATION_CODE_HASH, ) = (
            _CONDUIT_CONTROLLER.getConduitCodeHashes()
        );
    }

    /**
     * @dev Internal view function to derive the EIP-712 domain separator.
     *
     * @return The derived domain separator.
     */
    function _deriveDomainSeparator() internal view returns (bytes32) {c_0x2323d794(0x71ad5f74404b76db20d41ab2bea879b0231bdaba6c868d6b0a9a2375aedd5967); /* function */ 

        // prettier-ignore
c_0x2323d794(0xf90bf310cf4d42fefd2c678dfaa296790f14ea5b8b357498cf195701d3a4ece5); /* line */ 
        c_0x2323d794(0xa128dcb4e01d87a5a8e9075f9acfa6c0b43b9dd54a6fba96ee75d5be779e9f08); /* statement */ 
return keccak256(
            abi.encode(
                _EIP_712_DOMAIN_TYPEHASH,
                _NAME_HASH,
                _VERSION_HASH,
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @dev Internal pure function to retrieve the default name of this
     *      contract and return.
     *
     * @return The name of this contract.
     */
    function _name() internal pure virtual returns (string memory) {c_0x2323d794(0xa7b4045b96d8e3990f1533b1d787f0f6aa69978d5c7ebece9b8ae8d90026d2d0); /* function */ 

        // Return the name of the contract.
c_0x2323d794(0x01e0cc9697c4a705c3364444e3b8ec0a591e61e2fbb0a57cef53b21ee34250d7); /* line */ 
        assembly {
            // First element is the offset for the returned string. Offset the
            // value in memory by one word so that the free memory pointer will
            // be overwritten by the next write.
            mstore(OneWord, OneWord)

            // Name is right padded, so it touches the length which is left
            // padded. This enables writing both values at once. The free memory
            // pointer will be overwritten in the process.
            mstore(NameLengthPtr, NameWithLength)

            // Standard ABI encoding pads returned data to the nearest word. Use
            // the already empty zero slot memory region for this purpose and
            // return the final name string, offset by the original single word.
            return(OneWord, ThreeWords)
        }
    }

    /**
     * @dev Internal pure function to retrieve the default name of this contract
     *      as a string that can be used internally.
     *
     * @return The name of this contract.
     */
    function _nameString() internal pure virtual returns (string memory) {c_0x2323d794(0xfb4d242a240d2033411cccb1c32409e3f6404309633fdfc64ee935a42c691bef); /* function */ 

        // Return the name of the contract.
c_0x2323d794(0xe43b74175686a6ff6df442f8e39568b7c5b79f1416c19971c4d8d2864430ae6e); /* line */ 
        c_0x2323d794(0xdcaa6701f88237bbd2ca04e960e1f64a8c8b2721f02e73f93bc3984f8a63483a); /* statement */ 
return "Consideration";
    }

    /**
     * @dev Internal pure function to derive required EIP-712 typehashes and
     *      other hashes during contract creation.
     *
     * @return nameHash                  The hash of the name of the contract.
     * @return versionHash               The hash of the version string of the
     *                                   contract.
     * @return eip712DomainTypehash      The primary EIP-712 domain typehash.
     * @return offerItemTypehash         The EIP-712 typehash for OfferItem
     *                                   types.
     * @return considerationItemTypehash The EIP-712 typehash for
     *                                   ConsiderationItem types.
     * @return orderTypehash             The EIP-712 typehash for Order types.
     */
    function _deriveTypehashes()
        internal
        pure
        returns (
            bytes32 nameHash,
            bytes32 versionHash,
            bytes32 eip712DomainTypehash,
            bytes32 offerItemTypehash,
            bytes32 considerationItemTypehash,
            bytes32 orderTypehash
        )
    {c_0x2323d794(0x4dd25154ea0aeee717ac30e40d77e4cd25d8ea4639706e33ad056f20d7149961); /* function */ 

        // Derive hash of the name of the contract.
c_0x2323d794(0xfa82ad0d580c10962fc456f0644832cfd0591be09abdb3011796661ef3ca9013); /* line */ 
        c_0x2323d794(0xbf1d98aa02547cf7468b16ebaed7016ece0810c801009def31b79a991e49da86); /* statement */ 
nameHash = keccak256(bytes(_nameString()));

        // Derive hash of the version string of the contract.
c_0x2323d794(0xccc59a36153887c2fa6235056629282fa351662b482cded1f480df061982df0c); /* line */ 
        c_0x2323d794(0x61786cab9a1418ad2f5023545f807d9da4c6171eb04f409beaf62ffe39a9a8dc); /* statement */ 
versionHash = keccak256(bytes("1.1"));

        // Construct the OfferItem type string.
        // prettier-ignore
c_0x2323d794(0xc116933e45ba11e29a5bbf59e7142ce73e8f13f51a1ead58c48a760a7989287c); /* line */ 
        c_0x2323d794(0x69904478843991dd3e7c2e42453053a07f0a16143ac58e3694808f1f13ae4bb3); /* statement */ 
bytes memory offerItemTypeString = abi.encodePacked(
            "OfferItem(",
                "uint8 itemType,",
                "address token,",
                "uint256 identifierOrCriteria,",
                "uint256 startAmount,",
                "uint256 endAmount",
            ")"
        );

        // Construct the ConsiderationItem type string.
        // prettier-ignore
c_0x2323d794(0x12d70c8184422a291b1e4ce4edef541c9b8ffb92688ffe65a049224983bf60b8); /* line */ 
        c_0x2323d794(0xdde91c035f067d414e20c5279b73c2de339153e24365bd4fdd6dfc699c7bbb86); /* statement */ 
bytes memory considerationItemTypeString = abi.encodePacked(
            "ConsiderationItem(",
                "uint8 itemType,",
                "address token,",
                "uint256 identifierOrCriteria,",
                "uint256 startAmount,",
                "uint256 endAmount,",
                "address recipient",
            ")"
        );

        // Construct the OrderComponents type string, not including the above.
        // prettier-ignore
c_0x2323d794(0xf055e79f69c394db1f0ab26d26f5d2fc358f39cc25356b0fba8e361350b097ad); /* line */ 
        c_0x2323d794(0x0b53ef1f9e705d26fd5f5a2e389f35a836bb2d412bd52c1e2b8a36f7ce63d5a4); /* statement */ 
bytes memory orderComponentsPartialTypeString = abi.encodePacked(
            "OrderComponents(",
                "address offerer,",
                "address zone,",
                "OfferItem[] offer,",
                "ConsiderationItem[] consideration,",
                "uint8 orderType,",
                "uint256 startTime,",
                "uint256 endTime,",
                "bytes32 zoneHash,",
                "uint256 salt,",
                "bytes32 conduitKey,",
                "uint256 counter",
            ")"
        );

        // Construct the primary EIP-712 domain type string.
        // prettier-ignore
c_0x2323d794(0xd091ffd40913703f84423341a982cd3413e58c10ce5fa322b136f92365429986); /* line */ 
        c_0x2323d794(0x34e517ec3dd15731cae9cf6ccf8b8add372950165fdb318fc717871645585db5); /* statement */ 
eip712DomainTypehash = keccak256(
            abi.encodePacked(
                "EIP712Domain(",
                    "string name,",
                    "string version,",
                    "uint256 chainId,",
                    "address verifyingContract",
                ")"
            )
        );

        // Derive the OfferItem type hash using the corresponding type string.
c_0x2323d794(0xa1a3832aa5d0552171b581db7f8b05ad62aa462eeae47560bd5a7e3208f9ca74); /* line */ 
        c_0x2323d794(0x01bcbfa176541d2c02b906b7ae14ed1b29d45886869d9ebe1fc94aadbcb03d13); /* statement */ 
offerItemTypehash = keccak256(offerItemTypeString);

        // Derive ConsiderationItem type hash using corresponding type string.
c_0x2323d794(0xe17481fca59b3ef4b3ffa07f49e5c8674d73d3e5ace7fb057b06d1c721714491); /* line */ 
        c_0x2323d794(0x606d3173da8893f6512a72294deb20d65abce8f052fcccdee2d2998b3bb490b1); /* statement */ 
considerationItemTypehash = keccak256(considerationItemTypeString);

        // Derive OrderItem type hash via combination of relevant type strings.
c_0x2323d794(0xd622d6ee7e70ee8da5d971f293144d4ac3eaca4697ff56e8fde850a33bf436ce); /* line */ 
        c_0x2323d794(0x9480421c865d6aefcae617784db7c8a6cb8050e6f544c85e05aa1402fcdbfa28); /* statement */ 
orderTypehash = keccak256(
            abi.encodePacked(
                orderComponentsPartialTypeString,
                considerationItemTypeString,
                offerItemTypeString
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { SpentItem, ReceivedItem } from "../lib/ConsiderationStructs.sol";

/**
 * @title ConsiderationEventsAndErrors
 * @author 0age
 * @notice ConsiderationEventsAndErrors contains all events and errors.
 */
interface ConsiderationEventsAndErrors {
    /**
     * @dev Emit an event whenever an order is successfully fulfilled.
     *
     * @param orderHash     The hash of the fulfilled order.
     * @param offerer       The offerer of the fulfilled order.
     * @param zone          The zone of the fulfilled order.
     * @param recipient     The recipient of each spent item on the fulfilled
     *                      order, or the null address if there is no specific
     *                      fulfiller (i.e. the order is part of a group of
     *                      orders). Defaults to the caller unless explicitly
     *                      specified otherwise by the fulfiller.
     * @param offer         The offer items spent as part of the order.
     * @param consideration The consideration items received as part of the
     *                      order along with the recipients of each item.
     */
    event OrderFulfilled(
        bytes32 orderHash,
        address indexed offerer,
        address indexed zone,
        address recipient,
        SpentItem[] offer,
        ReceivedItem[] consideration
    );

    /**
     * @dev Emit an event whenever an order is successfully cancelled.
     *
     * @param orderHash The hash of the cancelled order.
     * @param offerer   The offerer of the cancelled order.
     * @param zone      The zone of the cancelled order.
     */
    event OrderCancelled(
        bytes32 orderHash,
        address indexed offerer,
        address indexed zone
    );

    /**
     * @dev Emit an event whenever an order is explicitly validated. Note that
     *      this event will not be emitted on partial fills even though they do
     *      validate the order as part of partial fulfillment.
     *
     * @param orderHash The hash of the validated order.
     * @param offerer   The offerer of the validated order.
     * @param zone      The zone of the validated order.
     */
    event OrderValidated(
        bytes32 orderHash,
        address indexed offerer,
        address indexed zone
    );

    /**
     * @dev Emit an event whenever a counter for a given offerer is incremented.
     *
     * @param newCounter The new counter for the offerer.
     * @param offerer  The offerer in question.
     */
    event CounterIncremented(uint256 newCounter, address indexed offerer);

    /**
     * @dev Revert with an error when attempting to fill an order that has
     *      already been fully filled.
     *
     * @param orderHash The order hash on which a fill was attempted.
     */
    error OrderAlreadyFilled(bytes32 orderHash);

    /**
     * @dev Revert with an error when attempting to fill an order outside the
     *      specified start time and end time.
     */
    error InvalidTime();

    /**
     * @dev Revert with an error when attempting to fill an order referencing an
     *      invalid conduit (i.e. one that has not been deployed).
     */
    error InvalidConduit(bytes32 conduitKey, address conduit);

    /**
     * @dev Revert with an error when an order is supplied for fulfillment with
     *      a consideration array that is shorter than the original array.
     */
    error MissingOriginalConsiderationItems();

    /**
     * @dev Revert with an error when a call to a conduit fails with revert data
     *      that is too expensive to return.
     */
    error InvalidCallToConduit(address conduit);

    /**
     * @dev Revert with an error if a consideration amount has not been fully
     *      zeroed out after applying all fulfillments.
     *
     * @param orderIndex         The index of the order with the consideration
     *                           item with a shortfall.
     * @param considerationIndex The index of the consideration item on the
     *                           order.
     * @param shortfallAmount    The unfulfilled consideration amount.
     */
    error ConsiderationNotMet(
        uint256 orderIndex,
        uint256 considerationIndex,
        uint256 shortfallAmount
    );

    /**
     * @dev Revert with an error when insufficient ether is supplied as part of
     *      msg.value when fulfilling orders.
     */
    error InsufficientEtherSupplied();

    /**
     * @dev Revert with an error when an ether transfer reverts.
     */
    error EtherTransferGenericFailure(address account, uint256 amount);

    /**
     * @dev Revert with an error when a partial fill is attempted on an order
     *      that does not specify partial fill support in its order type.
     */
    error PartialFillsNotEnabledForOrder();

    /**
     * @dev Revert with an error when attempting to fill an order that has been
     *      cancelled.
     *
     * @param orderHash The hash of the cancelled order.
     */
    error OrderIsCancelled(bytes32 orderHash);

    /**
     * @dev Revert with an error when attempting to fill a basic order that has
     *      been partially filled.
     *
     * @param orderHash The hash of the partially used order.
     */
    error OrderPartiallyFilled(bytes32 orderHash);

    /**
     * @dev Revert with an error when attempting to cancel an order as a caller
     *      other than the indicated offerer or zone.
     */
    error InvalidCanceller();

    /**
     * @dev Revert with an error when supplying a fraction with a value of zero
     *      for the numerator or denominator, or one where the numerator exceeds
     *      the denominator.
     */
    error BadFraction();

    /**
     * @dev Revert with an error when a caller attempts to supply callvalue to a
     *      non-payable basic order route or does not supply any callvalue to a
     *      payable basic order route.
     */
    error InvalidMsgValue(uint256 value);

    /**
     * @dev Revert with an error when attempting to fill a basic order using
     *      calldata not produced by default ABI encoding.
     */
    error InvalidBasicOrderParameterEncoding();

    /**
     * @dev Revert with an error when attempting to fulfill any number of
     *      available orders when none are fulfillable.
     */
    error NoSpecifiedOrdersAvailable();

    /**
     * @dev Revert with an error when attempting to fulfill an order with an
     *      offer for ETH outside of matching orders.
     */
    error InvalidNativeOfferItem();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0x27eba86f(bytes32 c__0x27eba86f) pure {}


import { ReentrancyErrors } from "../interfaces/ReentrancyErrors.sol";

import "./ConsiderationConstants.sol";

/**
 * @title ReentrancyGuard
 * @author 0age
 * @notice ReentrancyGuard contains a storage variable and related functionality
 *         for protecting against reentrancy.
 */
contract ReentrancyGuard is ReentrancyErrors {
function c_0xfbb8c0dc(bytes32 c__0xfbb8c0dc) internal pure {}

    // Prevent reentrant calls on protected functions.
    uint256 private _reentrancyGuard;

    /**
     * @dev Initialize the reentrancy guard during deployment.
     */
    constructor() {c_0xfbb8c0dc(0x92acefc20093d2937f4917aa397085874b27720f0128e0bc007e5af4ca3ebc35); /* function */ 

        // Initialize the reentrancy guard in a cleared state.
c_0xfbb8c0dc(0x34719e2800e29a05be71f8a70a5d4c2fe1dc1203b186043a4f3641a3f11b3cd0); /* line */ 
        c_0xfbb8c0dc(0xd8b556973948d640743953ded4b9f93ed008567d875c020af78120c081435204); /* statement */ 
_reentrancyGuard = _NOT_ENTERED;
    }

    /**
     * @dev Internal function to ensure that the sentinel value for the
     *      reentrancy guard is not currently set and, if not, to set the
     *      sentinel value for the reentrancy guard.
     */
    function _setReentrancyGuard() internal {c_0xfbb8c0dc(0xeee710e13992da9fd263235e609ca7770717d3a5050c5ffcb8721ba80f7a6fd9); /* function */ 

        // Ensure that the reentrancy guard is not already set.
c_0xfbb8c0dc(0xea5b53a65c23c334ab70d71da106761803a6911196d5fa16ba7c3d01b5085243); /* line */ 
        c_0xfbb8c0dc(0x5fb4ae256e6bdec18f87c379283832f3c96588d9dfd711377746525179e5f707); /* statement */ 
_assertNonReentrant();

        // Set the reentrancy guard.
c_0xfbb8c0dc(0xf60fae8f070debdaed0033a93f1db145df30a37ba3797552b99b1b03bc1fcd38); /* line */ 
        c_0xfbb8c0dc(0x68bf140276c08faa6342350f82dda72fb751a1e32045d776ae101da559ff95c4); /* statement */ 
_reentrancyGuard = _ENTERED;
    }

    /**
     * @dev Internal function to unset the reentrancy guard sentinel value.
     */
    function _clearReentrancyGuard() internal {c_0xfbb8c0dc(0x7c75d4980c26ceb52f3a6bf3dcf57d7c0f84cbcde019f394e38e6dcaac9de1ab); /* function */ 

        // Clear the reentrancy guard.
c_0xfbb8c0dc(0x26d1c36565c24ff32e9e1b1dddfeda67176c6bf76576134e9afa83a16ee142ee); /* line */ 
        c_0xfbb8c0dc(0x2f19e6c0ff46f2bda1da0d50166f6c41905f6fdb95a3eeda62cea71776c2cffc); /* statement */ 
_reentrancyGuard = _NOT_ENTERED;
    }

    /**
     * @dev Internal view function to ensure that the sentinel value for the
            reentrancy guard is not currently set.
     */
    function _assertNonReentrant() internal view {c_0xfbb8c0dc(0x27e4d56f078586ee284a0d3fc21e6074d7b09a4e4b1075f569936cc181e9ccca); /* function */ 

        // Ensure that the reentrancy guard is not currently set.
c_0xfbb8c0dc(0x3007c36b58fb4a1d106e3e17989223e4d89bcb6fc59573b859e03302792cf2de); /* line */ 
        c_0xfbb8c0dc(0x7656e9ef83bf643a13b0dca4cd88015c612e367be1854467ea19c417e66197b3); /* statement */ 
if (_reentrancyGuard != _NOT_ENTERED) {c_0xfbb8c0dc(0xb8bf5b7d820d4c442ca89708c54befa8510e6ae8771f87adb9e94b7cd2f51c05); /* branch */ 

c_0xfbb8c0dc(0x50799ef02da8729125e718b7ca205e722288233febb86967f07397e0f01e7f15); /* line */ 
            revert NoReentrantCalls();
        }else { c_0xfbb8c0dc(0xe12c4f69e872bc7714051a4a11f404868a3710e9053e3c04e6c76b968f3c0836); /* branch */ 
}
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0xe9ca6f2e(bytes32 c__0xe9ca6f2e) pure {}


/**
 * @title ReentrancyErrors
 * @author 0age
 * @notice ReentrancyErrors contains errors related to reentrancy.
 */
interface ReentrancyErrors {
    /**
     * @dev Revert with an error when a caller attempts to reenter a protected
     *      function.
     */
    error NoReentrantCalls();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface EIP1271Interface {
    function isValidSignature(bytes32 digest, bytes calldata signature)
        external
        view
        returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0xf024bb56(bytes32 c__0xf024bb56) pure {}


/**
 * @title SignatureVerificationErrors
 * @author 0age
 * @notice SignatureVerificationErrors contains all errors related to signature
 *         verification.
 */
interface SignatureVerificationErrors {
    /**
     * @dev Revert with an error when a signature that does not contain a v
     *      value of 27 or 28 has been supplied.
     *
     * @param v The invalid v value.
     */
    error BadSignatureV(uint8 v);

    /**
     * @dev Revert with an error when the signer recovered by the supplied
     *      signature does not match the offerer or an allowed EIP-1271 signer
     *      as specified by the offerer in the event they are a contract.
     */
    error InvalidSigner();

    /**
     * @dev Revert with an error when a signer cannot be recovered from the
     *      supplied signature.
     */
    error InvalidSignature();

    /**
     * @dev Revert with an error when an EIP-1271 call to an account fails.
     */
    error BadContractSignature();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0xbf249037(bytes32 c__0xbf249037) pure {}


import "./ConsiderationConstants.sol";

/**
 * @title LowLevelHelpers
 * @author 0age
 * @notice LowLevelHelpers contains logic for performing various low-level
 *         operations.
 */
contract LowLevelHelpers {
function c_0x10cfad03(bytes32 c__0x10cfad03) internal pure {}

    /**
     * @dev Internal view function to staticcall an arbitrary target with given
     *      calldata. Note that no data is written to memory and no contract
     *      size check is performed.
     *
     * @param target   The account to staticcall.
     * @param callData The calldata to supply when staticcalling the target.
     *
     * @return success The status of the staticcall to the target.
     */
    function _staticcall(address target, bytes memory callData)
        internal
        view
        returns (bool success)
    {c_0x10cfad03(0x883a2ef64812292bba329badbd7006ac717aaff54896df539be318d9a399a082); /* function */ 

c_0x10cfad03(0xaed036ce3ac2f2d82611d012e41aad7c7333b623a8159ed662e0ab152901965a); /* line */ 
        assembly {
            // Perform the staticcall.
            success := staticcall(
                gas(),
                target,
                add(callData, OneWord),
                mload(callData),
                0,
                0
            )
        }
    }

    /**
     * @dev Internal view function to revert and pass along the revert reason if
     *      data was returned by the last call and that the size of that data
     *      does not exceed the currently allocated memory size.
     */
    function _revertWithReasonIfOneIsReturned() internal view {c_0x10cfad03(0x621b2f4695939211e766173c25139cd7749ebb6c6bd983a845c1063ace7e57c5); /* function */ 

c_0x10cfad03(0x17709c1575d0759e3d0fba2a78882bee40cf31a706aeeb2cde401d07c6bc2b74); /* line */ 
        assembly {
            // If it returned a message, bubble it up as long as sufficient gas
            // remains to do so:
            if returndatasize() {
                // Ensure that sufficient gas is available to copy returndata
                // while expanding memory where necessary. Start by computing
                // the word size of returndata and allocated memory.
                let returnDataWords := div(
                    add(returndatasize(), AlmostOneWord),
                    OneWord
                )

                // Note: use the free memory pointer in place of msize() to work
                // around a Yul warning that prevents accessing msize directly
                // when the IR pipeline is activated.
                let msizeWords := div(mload(FreeMemoryPointerSlot), OneWord)

                // Next, compute the cost of the returndatacopy.
                let cost := mul(CostPerWord, returnDataWords)

                // Then, compute cost of new memory allocation.
                if gt(returnDataWords, msizeWords) {
                    cost := add(
                        cost,
                        add(
                            mul(sub(returnDataWords, msizeWords), CostPerWord),
                            div(
                                sub(
                                    mul(returnDataWords, returnDataWords),
                                    mul(msizeWords, msizeWords)
                                ),
                                MemoryExpansionCoefficient
                            )
                        )
                    )
                }

                // Finally, add a small constant and compare to gas remaining;
                // bubble up the revert data if enough gas is still available.
                if lt(add(cost, ExtraGasBuffer), gas()) {
                    // Copy returndata to memory; overwrite existing memory.
                    returndatacopy(0, 0, returndatasize())

                    // Revert, specifying memory region with copied returndata.
                    revert(0, returndatasize())
                }
            }
        }
    }

    /**
     * @dev Internal pure function to determine if the first word of returndata
     *      matches an expected magic value.
     *
     * @param expected The expected magic value.
     *
     * @return A boolean indicating whether the expected value matches the one
     *         located in the first word of returndata.
     */
    function _doesNotMatchMagic(bytes4 expected) internal pure returns (bool) {c_0x10cfad03(0x843689d06e6593fabe606376e3c073b0c73c6cd1fd1af4186f50694b90015071); /* function */ 

        // Declare a variable for the value held by the return data buffer.
c_0x10cfad03(0xce95068391bb8d218ea6cf3e331b6660ff33066d6e1bd9d4e63f6b8a49aeb1b3); /* line */ 
        c_0x10cfad03(0xf3852de511515cc1ddb89097f0e016a05616e4b5adc2ef0697a8274cd753bbaf); /* statement */ 
bytes4 result;

        // Utilize assembly in order to read directly from returndata buffer.
c_0x10cfad03(0x14e668a2d8473a73febdfac1f8b2ab7f2cbbbe14a1d8efbfef4180dc8e19dfb9); /* line */ 
        assembly {
            // Only put result on stack if return data is exactly one word.
            if eq(returndatasize(), OneWord) {
                // Copy the word directly from return data into scratch space.
                returndatacopy(0, 0, OneWord)

                // Take value from scratch space and place it on the stack.
                result := mload(0)
            }
        }

        // Return a boolean indicating whether expected and located value match.
c_0x10cfad03(0x5f626a3603c503fcf2f7b158a4d9b93c45819ae6031e4c365baa9e3125d4c98e); /* line */ 
        c_0x10cfad03(0x25fad2394efb63d42d549d0aaa4b77c15bc478b5ea72015becdf224e1874af8e); /* statement */ 
return result != expected;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0xbfe87386(bytes32 c__0xbfe87386) pure {}


import { ItemType, Side } from "./ConsiderationEnums.sol";

import {
    OfferItem,
    ConsiderationItem,
    ReceivedItem,
    OrderParameters,
    AdvancedOrder,
    Execution,
    FulfillmentComponent
} from "./ConsiderationStructs.sol";

import "./ConsiderationConstants.sol";

import {
    FulfillmentApplicationErrors
} from "../interfaces/FulfillmentApplicationErrors.sol";

/**
 * @title FulfillmentApplier
 * @author 0age
 * @notice FulfillmentApplier contains logic related to applying fulfillments,
 *         both as part of order matching (where offer items are matched to
 *         consideration items) as well as fulfilling available orders (where
 *         order items and consideration items are independently aggregated).
 */
contract FulfillmentApplier is FulfillmentApplicationErrors {
function c_0xbf2c56ed(bytes32 c__0xbf2c56ed) internal pure {}

    /**
     * @dev Internal pure function to match offer items to consideration items
     *      on a group of orders via a supplied fulfillment.
     *
     * @param advancedOrders          The orders to match.
     * @param offerComponents         An array designating offer components to
     *                                match to consideration components.
     * @param considerationComponents An array designating consideration
     *                                components to match to offer components.
     *                                Note that each consideration amount must
     *                                be zero in order for the match operation
     *                                to be valid.
     *
     * @return execution The transfer performed as a result of the fulfillment.
     */
    function _applyFulfillment(
        AdvancedOrder[] memory advancedOrders,
        FulfillmentComponent[] calldata offerComponents,
        FulfillmentComponent[] calldata considerationComponents
    ) internal pure returns (Execution memory execution) {c_0xbf2c56ed(0x5cc595facbce138051b06d27a5430e1fc9d4cd9ff15b4a7f6721c7e9381312a5); /* function */ 

        // Ensure 1+ of both offer and consideration components are supplied.
c_0xbf2c56ed(0x3f7902f9a99c5dbd188c89fd0db0bde6d78c7591dda80d608cadd1345b3a1ee9); /* line */ 
        c_0xbf2c56ed(0x6473c5b7e57ef7ea7f2f1a7763b3bed0b634f71d40a9f12f1463c622ffd92b2e); /* statement */ 
if (
            offerComponents.length == 0 || considerationComponents.length == 0
        ) {c_0xbf2c56ed(0x68451ebf3779961e7c21eb4b74cd0df002af849a1c6a9bec79cf8230c41a672c); /* branch */ 

c_0xbf2c56ed(0x146fe0d86fdf4597196bd10c612f6b635d5fd45d48588c437dc2ed903faec069); /* line */ 
            revert OfferAndConsiderationRequiredOnFulfillment();
        }else { c_0xbf2c56ed(0x05cc288e643a4723f6cb71244aade9d5711f9f6f0ce6613e6aa8ef285be41d2e); /* branch */ 
}

        // Declare a new Execution struct.
c_0xbf2c56ed(0x8f146971feb0f626092e2ba01f528ec6f8ace048249a9421784bf4e994c45ce7); /* line */ 
        c_0xbf2c56ed(0x8a53594467db55db45004b614374e1849cd0591e75013d6bda75229d52f8532d); /* statement */ 
Execution memory considerationExecution;

        // Validate & aggregate consideration items to new Execution object.
c_0xbf2c56ed(0xab3d39f169f09bf5099b1502de2b0e430b23d5cf6b47c30d47aab0c2a2db26f7); /* line */ 
        c_0xbf2c56ed(0x777695b65b0f8c37ed8c8fb1975a41b16f2625f61d10cbb128236cefbd39cf98); /* statement */ 
_aggregateValidFulfillmentConsiderationItems(
            advancedOrders,
            considerationComponents,
            considerationExecution
        );

        // Retrieve the consideration item from the execution struct.
c_0xbf2c56ed(0xa18b05585a62ab6c706cc95eafc0e02c109cf01893bdc9e29536a941a9f64583); /* line */ 
        c_0xbf2c56ed(0x101f2a5ab33e3e23b9f46eadf2c6830a1767d44e893bf1972e1960506eb87535); /* statement */ 
ReceivedItem memory considerationItem = considerationExecution.item;

        // Recipient does not need to be specified because it will always be set
        // to that of the consideration.
        // Validate & aggregate offer items to Execution object.
c_0xbf2c56ed(0x78758b31b825ad13b87e83e32e43a195b3e882519da8a10dcb15e51d14ff2db4); /* line */ 
        c_0xbf2c56ed(0x64341907eb9f742d01081603cd120424346f42379a1d83600e5a47cd12c690c3); /* statement */ 
_aggregateValidFulfillmentOfferItems(
            advancedOrders,
            offerComponents,
            execution
        );

        // Ensure offer and consideration share types, tokens and identifiers.
c_0xbf2c56ed(0xe49b72adc95191d99e295e9d25a6714c882f022a194a3c471d9b1d5de3295fdb); /* line */ 
        c_0xbf2c56ed(0x43e370f089be986ef6d41fb56f90d27a81cf6e8a2d11cab1780da99a4cd856a0); /* statement */ 
if (
            execution.item.itemType != considerationItem.itemType ||
            execution.item.token != considerationItem.token ||
            execution.item.identifier != considerationItem.identifier
        ) {c_0xbf2c56ed(0xbb58c1d3dcc5e872fee68ccc52a4b6a26ab0a87b4c1a0c107889d1b2ee7c1932); /* branch */ 

c_0xbf2c56ed(0xffe4b644a2b51352767e0fb09ff4b6d8aab01a6c6825a49f1ac8e2bfbbee6e90); /* line */ 
            revert MismatchedFulfillmentOfferAndConsiderationComponents();
        }else { c_0xbf2c56ed(0x25b06a61fe9338271fa0b788b32a8734c1b5cbdae5942bf63691fc188c9faa05); /* branch */ 
}

        // If total consideration amount exceeds the offer amount...
c_0xbf2c56ed(0x4d497d707fd916eec0528d74195aaf430f0aa8ad7c380ca53eb96e44efdb3e07); /* line */ 
        c_0xbf2c56ed(0x339fd70772eaad6e8e553c2967d5164f910da9d5ba29c92bd92a40e7b8d65467); /* statement */ 
if (considerationItem.amount > execution.item.amount) {c_0xbf2c56ed(0xdb628ce30dc29953176c7e6120ee0517c0a0deda0f9c2d82616056488fbc24e4); /* branch */ 

            // Retrieve the first consideration component from the fulfillment.
c_0xbf2c56ed(0xc748cd2d836775c5aea26f25b466857a4d9983fa4d0347c9bc8afa1e08da4e76); /* line */ 
            c_0xbf2c56ed(0x5e15172b5167cefd855f8bafde12b357f4c2f2233777fafd0a12423efdaa54a1); /* statement */ 
FulfillmentComponent memory targetComponent = (
                considerationComponents[0]
            );

            // Skip underflow check as the conditional being true implies that
            // considerationItem.amount > execution.item.amount.
c_0xbf2c56ed(0xba2a9497eb3a73aeec6f4087999da699e3e40828b22bfeb9fdefe9505c580a49); /* line */ 
            unchecked {
                // Add excess consideration item amount to original order array.
c_0xbf2c56ed(0x37b7a1ff05eec64cae14b8acb461ac3c28968f5368e53a468a87277e46ff4b3b); /* line */ 
                c_0xbf2c56ed(0x344d3963604cdfd4e966330962b2417db95c9ae97856a7d84ab613a0de93015f); /* statement */ 
advancedOrders[targetComponent.orderIndex]
                    .parameters
                    .consideration[targetComponent.itemIndex]
                    .startAmount = (considerationItem.amount -
                    execution.item.amount);
            }

            // Reduce total consideration amount to equal the offer amount.
c_0xbf2c56ed(0x2a153c624b16655f46f851a2c02de717a02a72a69351eb932a9b5a8ff0cfbb96); /* line */ 
            c_0xbf2c56ed(0x39cc779c7c2dd9f30f949dc755494e062d2cd916e2fa27e07f16ba02c86716ff); /* statement */ 
considerationItem.amount = execution.item.amount;
        } else {c_0xbf2c56ed(0x39e596babcd30c7048847b1f2004c44d5ff44df03fec8411cf53914a2ab43862); /* branch */ 

            // Retrieve the first offer component from the fulfillment.
c_0xbf2c56ed(0xc5922c51f1d2b79db4b5fa5c1ed6e1ec651ca0a6976ac4b0f2d3b3a6002e91b5); /* line */ 
            c_0xbf2c56ed(0xf1bedd84d8195700714a126d1925c91b9763eec7bcf260d383c5631a06138fcb); /* statement */ 
FulfillmentComponent memory targetComponent = offerComponents[0];

            // Skip underflow check as the conditional being false implies that
            // execution.item.amount >= considerationItem.amount.
c_0xbf2c56ed(0xb14236b6e4060473245fcb49cac67899c4ba28222ba4925ef3234c99ab1f675e); /* line */ 
            unchecked {
                // Add excess offer item amount to the original array of orders.
c_0xbf2c56ed(0x18e0fef7a315d136789b1bb647b62eb25b20de8a46c39ef474d1e55b2f403908); /* line */ 
                c_0xbf2c56ed(0xd7f480cfa535b2f36fcf2984a6407dbf746f3b73090a5e1333e51693c4781f6d); /* statement */ 
advancedOrders[targetComponent.orderIndex]
                    .parameters
                    .offer[targetComponent.itemIndex]
                    .startAmount = (execution.item.amount -
                    considerationItem.amount);
            }

            // Reduce total offer amount to equal the consideration amount.
c_0xbf2c56ed(0x702cc5ae5d85484dc4d881be663d4a437bf6a014b7fcb360662cc32bec6d6561); /* line */ 
            c_0xbf2c56ed(0x1113f39190428c73d287464c4045bd49bd9d56c8a7bd396eb8cd0eebfb26d1bc); /* statement */ 
execution.item.amount = considerationItem.amount;
        }

        // Reuse consideration recipient.
c_0xbf2c56ed(0xa46fbd046f1588750dcce698216a6b7f997504795f210ad57ab13d1b4d34f422); /* line */ 
        c_0xbf2c56ed(0x5689bb4a1fd783d04626fbadb9900e317a7a486133e0c3628e7b169024e85ca2); /* statement */ 
execution.item.recipient = considerationItem.recipient;

        // Return the final execution that will be triggered for relevant items.
c_0xbf2c56ed(0x9cd52648a0495de1fad86c381b79ca5f3ec8197d325db205c4dbe976c2736526); /* line */ 
        c_0xbf2c56ed(0x1564b062a57000b317dd4ce93cabb1271b653f6811a152fe0fa75db3175bbac1); /* statement */ 
return execution; // Execution(considerationItem, offerer, conduitKey);
    }

    /**
     * @dev Internal view function to aggregate offer or consideration items
     *      from a group of orders into a single execution via a supplied array
     *      of fulfillment components. Items that are not available to aggregate
     *      will not be included in the aggregated execution.
     *
     * @param advancedOrders        The orders to aggregate.
     * @param side                  The side (i.e. offer or consideration).
     * @param fulfillmentComponents An array designating item components to
     *                              aggregate if part of an available order.
     * @param fulfillerConduitKey   A bytes32 value indicating what conduit, if
     *                              any, to source the fulfiller's token
     *                              approvals from. The zero hash signifies that
     *                              no conduit should be used, with approvals
     *                              set directly on this contract.
     * @param recipient             The intended recipient for all received
     *                              items.
     *
     * @return execution The transfer performed as a result of the fulfillment.
     */
    function _aggregateAvailable(
        AdvancedOrder[] memory advancedOrders,
        Side side,
        FulfillmentComponent[] memory fulfillmentComponents,
        bytes32 fulfillerConduitKey,
        address recipient
    ) internal view returns (Execution memory execution) {c_0xbf2c56ed(0x7f86de56e457b6b686e87de01b3701f4d73f6a7452d30e8c3c20c6d170bf9abe); /* function */ 

        // Skip overflow / underflow checks; conditions checked or unreachable.
c_0xbf2c56ed(0x169ddf3088ec0cbdc6df6512ee42cf6863b929b646898683bf3966cfbd314e0d); /* line */ 
        unchecked {
            // Retrieve fulfillment components array length and place on stack.
            // Ensure at least one fulfillment component has been supplied.
c_0xbf2c56ed(0x9553c1f4161b9c72d6df0c5d846f013d7d15224cf8a0f5cc755afb5ef68e0892); /* line */ 
            c_0xbf2c56ed(0x5fbaa075e1f344c023c15f87dd97a081cf253bb50813594853d8eaf345be6a0c); /* statement */ 
if (fulfillmentComponents.length == 0) {c_0xbf2c56ed(0xe34df7d1c420eb816bd2513fbc1571c4cedb9738f75506aa888c0946a7b7816e); /* branch */ 

c_0xbf2c56ed(0xc43e82e379c8bf0bb2ad4bc23f712e916b7cc842fc3db7714f6a49019153240f); /* line */ 
                revert MissingFulfillmentComponentOnAggregation(side);
            }else { c_0xbf2c56ed(0x5bace4aec6de9c74aa9c2a5c1ffd537d7ea8816c3ae39a759a69a08778098000); /* branch */ 
}

            // If the fulfillment components are offer components...
c_0xbf2c56ed(0xbf56d408c0cf9eaa5052b780f30045287b39f553ad30a1b11d00fc2154d8c3e8); /* line */ 
            c_0xbf2c56ed(0xf421458c0e4f111524620e28303119b1acb9f3d1967e9270dc44cb277828f772); /* statement */ 
if (side == Side.OFFER) {c_0xbf2c56ed(0xee63da111226757a47aa1155847b468034a58984a5b6e61ed9d163ed571807a2); /* branch */ 

                // Set the supplied recipient on the execution item.
c_0xbf2c56ed(0xa1f6059698fc33ac6cf80c3069794bc21918c00fde662dbc8493e564705bb85e); /* line */ 
                c_0xbf2c56ed(0xcca5be7e5cee5e953569db0a16d32b5fb983a5947e9784dbbae045d1592447e2); /* statement */ 
execution.item.recipient = payable(recipient);

                // Return execution for aggregated items provided by offerer.
c_0xbf2c56ed(0xcdc281fec765eae2f6bdaa5b80b920fadcbefc6759498fb834082227c5e0dc39); /* line */ 
                c_0xbf2c56ed(0xf85062d2cd8e44c5da0efefe4fed839d153e1e059c3f2c9f24907f1d105dc3f2); /* statement */ 
_aggregateValidFulfillmentOfferItems(
                    advancedOrders,
                    fulfillmentComponents,
                    execution
                );
            } else {c_0xbf2c56ed(0x1ee0d4d555d461b860af129b0936410053fcaa38369e33bbf8905fb3bb1a1856); /* branch */ 

                // Otherwise, fulfillment components are consideration
                // components. Return execution for aggregated items provided by
                // the fulfiller.
c_0xbf2c56ed(0x5282ec6cfb6eb66e9d33a6f4b5a28b7c872b1f3a6a5dbe1cc77d2d6fb73dbe2d); /* line */ 
                c_0xbf2c56ed(0x71ddae668ae6361d86c2bc2fdfd7b772d1f75a97ef84fdfe68363b8e6f3a8da8); /* statement */ 
_aggregateValidFulfillmentConsiderationItems(
                    advancedOrders,
                    fulfillmentComponents,
                    execution
                );

                // Set the caller as the offerer on the execution.
c_0xbf2c56ed(0xfe51504bbe2cd2c445ecae5705542f9743c69e3e1d9f3052f43d78184c91d47f); /* line */ 
                c_0xbf2c56ed(0xb06f8ea5ba30a90fa44c0170653a996ba43cf1367c0cecebd8ffea1d8019654f); /* statement */ 
execution.offerer = msg.sender;

                // Set fulfiller conduit key as the conduit key on execution.
c_0xbf2c56ed(0xf08bb32d303346efc5ac0e84d5d206e101a47d62bc4c842394aedf848eee644b); /* line */ 
                c_0xbf2c56ed(0x32def0b6b510239e34d8adb51c3bd4df4563b495af30503bc330a6ce9d21080f); /* statement */ 
execution.conduitKey = fulfillerConduitKey;
            }

            // Set the offerer and recipient to null address if execution
            // amount is zero. This will cause the execution item to be skipped.
c_0xbf2c56ed(0x75a5a1a25f310ca9b6a981a44051d4ed94200429db7aaab7a6dc8a27d9d83921); /* line */ 
            c_0xbf2c56ed(0x66a5a56a54133c02954f229fee18d39f0141a948a9f0edf2b28f7fbaab7f8703); /* statement */ 
if (execution.item.amount == 0) {c_0xbf2c56ed(0x52150a14bf4b0175591dd0f959c86ee50fa61309453c9d5be35fd0d78294fdeb); /* branch */ 

c_0xbf2c56ed(0xb54f62f274ecd7123c46de2f35580cda47a55c5c23b5b312a90db60aad5ee7b1); /* line */ 
                c_0xbf2c56ed(0x14aab84cb7f703e98a9238988ee9fe2926e3d6b371eac20df64b27b0edb4c902); /* statement */ 
execution.offerer = address(0);
c_0xbf2c56ed(0xf50006865fe1178d38fac15f190e554934722ac8df417ef68861ed856f36c803); /* line */ 
                c_0xbf2c56ed(0x301d6485b23d749d84fc75e1a811f330f2b357f11fe947b2336a9e06a9c373b4); /* statement */ 
execution.item.recipient = payable(0);
            }else { c_0xbf2c56ed(0x50ac532d4eb90cc46d54c4968d20ffdbe2c88c16b4bd769f15b30a28e717958b); /* branch */ 
}
        }
    }

    /**
     * @dev Internal pure function to aggregate a group of offer items using
     *      supplied directives on which component items are candidates for
     *      aggregation, skipping items on orders that are not available.
     *
     * @param advancedOrders  The orders to aggregate offer items from.
     * @param offerComponents An array of FulfillmentComponent structs
     *                        indicating the order index and item index of each
     *                        candidate offer item for aggregation.
     * @param execution       The execution to apply the aggregation to.
     */
    function _aggregateValidFulfillmentOfferItems(
        AdvancedOrder[] memory advancedOrders,
        FulfillmentComponent[] memory offerComponents,
        Execution memory execution
    ) internal pure {c_0xbf2c56ed(0xbf423f80fed77352176647546208ec0def20d347e004aaf58059fe11c74592b1); /* function */ 

c_0xbf2c56ed(0xe49bbf33358d98e6a9dbc207eaf6dd9ca9ad325a87262a8e41d20ac12e6e1401); /* line */ 
        assembly {
            // Declare function for reverts on invalid fulfillment data.
            function throwInvalidFulfillmentComponentData() {
                // Store the InvalidFulfillmentComponentData error signature.
                mstore(0, InvalidFulfillmentComponentData_error_signature)

                // Return, supplying InvalidFulfillmentComponentData signature.
                revert(0, InvalidFulfillmentComponentData_error_len)
            }

            // Declare function for reverts due to arithmetic overflows.
            function throwOverflow() {
                // Store the Panic error signature.
                mstore(0, Panic_error_signature)

                // Store the arithmetic (0x11) panic code as initial argument.
                mstore(Panic_error_offset, Panic_arithmetic)

                // Return, supplying Panic signature and arithmetic code.
                revert(0, Panic_error_length)
            }

            // Get position in offerComponents head.
            let fulfillmentHeadPtr := add(offerComponents, OneWord)

            // Retrieve the order index using the fulfillment pointer.
            let orderIndex := mload(mload(fulfillmentHeadPtr))

            // Ensure that the order index is not out of range.
            if iszero(lt(orderIndex, mload(advancedOrders))) {
                throwInvalidFulfillmentComponentData()
            }

            // Read advancedOrders[orderIndex] pointer from its array head.
            let orderPtr := mload(
                // Calculate head position of advancedOrders[orderIndex].
                add(add(advancedOrders, OneWord), mul(orderIndex, OneWord))
            )

            // Read the pointer to OrderParameters from the AdvancedOrder.
            let paramsPtr := mload(orderPtr)

            // Load the offer array pointer.
            let offerArrPtr := mload(
                add(paramsPtr, OrderParameters_offer_head_offset)
            )

            // Retrieve item index using an offset of the fulfillment pointer.
            let itemIndex := mload(
                add(mload(fulfillmentHeadPtr), Fulfillment_itemIndex_offset)
            )

            // Only continue if the fulfillment is not invalid.
            if iszero(lt(itemIndex, mload(offerArrPtr))) {
                throwInvalidFulfillmentComponentData()
            }

            // Retrieve consideration item pointer using the item index.
            let offerItemPtr := mload(
                add(
                    // Get pointer to beginning of receivedItem.
                    add(offerArrPtr, OneWord),
                    // Calculate offset to pointer for desired order.
                    mul(itemIndex, OneWord)
                )
            )

            // Declare a variable for the final aggregated item amount.
            let amount := 0

            // Create variable to track errors encountered with amount.
            let errorBuffer := 0

            // Only add offer amount to execution amount on a nonzero numerator.
            if mload(add(orderPtr, AdvancedOrder_numerator_offset)) {
                // Retrieve amount pointer using consideration item pointer.
                let amountPtr := add(offerItemPtr, Common_amount_offset)

                // Set the amount.
                amount := mload(amountPtr)

                // Zero out amount on item to indicate it is credited.
                mstore(amountPtr, 0)

                // Buffer indicating whether issues were found.
                errorBuffer := iszero(amount)
            }

            // Retrieve the received item pointer.
            let receivedItemPtr := mload(execution)

            // Set the item type on the received item.
            mstore(receivedItemPtr, mload(offerItemPtr))

            // Set the token on the received item.
            mstore(
                add(receivedItemPtr, Common_token_offset),
                mload(add(offerItemPtr, Common_token_offset))
            )

            // Set the identifier on the received item.
            mstore(
                add(receivedItemPtr, Common_identifier_offset),
                mload(add(offerItemPtr, Common_identifier_offset))
            )

            // Set the offerer on returned execution using order pointer.
            mstore(add(execution, Execution_offerer_offset), mload(paramsPtr))

            // Set conduitKey on returned execution via offset of order pointer.
            mstore(
                add(execution, Execution_conduit_offset),
                mload(add(paramsPtr, OrderParameters_conduit_offset))
            )

            // Calculate the hash of (itemType, token, identifier).
            let dataHash := keccak256(
                receivedItemPtr,
                ReceivedItem_CommonParams_size
            )

            // Get position one word past last element in head of array.
            let endPtr := add(
                offerComponents,
                mul(mload(offerComponents), OneWord)
            )

            // Iterate over remaining offer components.
            // prettier-ignore
            for {} lt(fulfillmentHeadPtr,  endPtr) {} {
                // Increment the pointer to the fulfillment head by one word.
                fulfillmentHeadPtr := add(fulfillmentHeadPtr, OneWord)

                // Get the order index using the fulfillment pointer.
                orderIndex := mload(mload(fulfillmentHeadPtr))

                // Ensure the order index is in range.
                if iszero(lt(orderIndex, mload(advancedOrders))) {
                  throwInvalidFulfillmentComponentData()
                }

                // Get pointer to AdvancedOrder element.
                orderPtr := mload(
                    add(
                        add(advancedOrders, OneWord),
                        mul(orderIndex, OneWord)
                    )
                )

                // Only continue if numerator is not zero.
                if iszero(mload(
                    add(orderPtr, AdvancedOrder_numerator_offset)
                )) {
                  continue
                }

                // Read the pointer to OrderParameters from the AdvancedOrder.
                paramsPtr := mload(orderPtr)

                // Load offer array pointer.
                offerArrPtr := mload(
                    add(
                        paramsPtr,
                        OrderParameters_offer_head_offset
                    )
                )

                // Get the item index using the fulfillment pointer.
                itemIndex := mload(add(mload(fulfillmentHeadPtr), OneWord))

                // Throw if itemIndex is out of the range of array.
                if iszero(
                    lt(itemIndex, mload(offerArrPtr))
                ) {
                    throwInvalidFulfillmentComponentData()
                }

                // Retrieve offer item pointer using index.
                offerItemPtr := mload(
                    add(
                        // Get pointer to beginning of receivedItem.
                        add(offerArrPtr, OneWord),
                        // Use offset to pointer for desired order.
                        mul(itemIndex, OneWord)
                    )
                )

                // Retrieve amount pointer using offer item pointer.
                let amountPtr := add(
                      offerItemPtr,
                      Common_amount_offset
                )

                // Add offer amount to execution amount.
                let newAmount := add(amount, mload(amountPtr))

                // Update error buffer: 1 = zero amount, 2 = overflow, 3 = both.
                errorBuffer := or(
                  errorBuffer,
                  or(
                    shl(1, lt(newAmount, amount)),
                    iszero(mload(amountPtr))
                  )
                )

                // Update the amount to the new, summed amount.
                amount := newAmount

                // Zero out amount on original item to indicate it is credited.
                mstore(amountPtr, 0)

                // Ensure the indicated item matches original item.
                if iszero(
                    and(
                        and(
                          // The offerer must match on both items.
                          eq(
                              mload(paramsPtr),
                              mload(
                                  add(execution, Execution_offerer_offset)
                              )
                          ),
                          // The conduit key must match on both items.
                          eq(
                              mload(
                                  add(
                                      paramsPtr,
                                      OrderParameters_conduit_offset
                                  )
                              ),
                              mload(
                                  add(
                                      execution,
                                      Execution_conduit_offset
                                  )
                              )
                          )
                        ),
                        // The itemType, token, and identifier must match.
                        eq(
                            dataHash,
                            keccak256(
                                offerItemPtr,
                                ReceivedItem_CommonParams_size
                            )
                        )
                    )
                ) {
                    // Throw if any of the requirements are not met.
                    throwInvalidFulfillmentComponentData()
                }
            }
            // Write final amount to execution.
            mstore(add(mload(execution), Common_amount_offset), amount)

            // Determine whether the error buffer contains a nonzero error code.
            if errorBuffer {
                // If errorBuffer is 1, an item had an amount of zero.
                if eq(errorBuffer, 1) {
                    // Store the MissingItemAmount error signature.
                    mstore(0, MissingItemAmount_error_signature)

                    // Return, supplying MissingItemAmount signature.
                    revert(0, MissingItemAmount_error_len)
                }

                // If errorBuffer is not 1 or 0, the sum overflowed.
                // Panic!
                throwOverflow()
            }
        }
    }

    /**
     * @dev Internal pure function to aggregate a group of consideration items
     *      using supplied directives on which component items are candidates
     *      for aggregation, skipping items on orders that are not available.
     *
     * @param advancedOrders          The orders to aggregate consideration
     *                                items from.
     * @param considerationComponents An array of FulfillmentComponent structs
     *                                indicating the order index and item index
     *                                of each candidate consideration item for
     *                                aggregation.
     * @param execution       The execution to apply the aggregation to.
     */
    function _aggregateValidFulfillmentConsiderationItems(
        AdvancedOrder[] memory advancedOrders,
        FulfillmentComponent[] memory considerationComponents,
        Execution memory execution
    ) internal pure {c_0xbf2c56ed(0x31f860e036d7950210539a1848284f9cff1c1cd77401ad1f0301f9ac3fdc1706); /* function */ 

        // Utilize assembly in order to efficiently aggregate the items.
c_0xbf2c56ed(0x509b35592e6ab3dd9bb4b6f6c3eac9dac5f3dd09dd1a510a1e1faf6f0020fc54); /* line */ 
        assembly {
            // Declare function for reverts on invalid fulfillment data.
            function throwInvalidFulfillmentComponentData() {
                // Store the InvalidFulfillmentComponentData error signature.
                mstore(0, InvalidFulfillmentComponentData_error_signature)

                // Return, supplying InvalidFulfillmentComponentData signature.
                revert(0, InvalidFulfillmentComponentData_error_len)
            }

            // Declare function for reverts due to arithmetic overflows.
            function throwOverflow() {
                // Store the Panic error signature.
                mstore(0, Panic_error_signature)

                // Store the arithmetic (0x11) panic code as initial argument.
                mstore(Panic_error_offset, Panic_arithmetic)

                // Return, supplying Panic signature and arithmetic code.
                revert(0, Panic_error_length)
            }

            // Get position in considerationComponents head.
            let fulfillmentHeadPtr := add(considerationComponents, OneWord)

            // Retrieve the order index using the fulfillment pointer.
            let orderIndex := mload(mload(fulfillmentHeadPtr))

            // Ensure that the order index is not out of range.
            if iszero(lt(orderIndex, mload(advancedOrders))) {
                throwInvalidFulfillmentComponentData()
            }

            // Read advancedOrders[orderIndex] pointer from its array head.
            let orderPtr := mload(
                // Calculate head position of advancedOrders[orderIndex].
                add(add(advancedOrders, OneWord), mul(orderIndex, OneWord))
            )

            // Load consideration array pointer.
            let considerationArrPtr := mload(
                add(
                    // Read pointer to OrderParameters from the AdvancedOrder.
                    mload(orderPtr),
                    OrderParameters_consideration_head_offset
                )
            )

            // Retrieve item index using an offset of the fulfillment pointer.
            let itemIndex := mload(
                add(mload(fulfillmentHeadPtr), Fulfillment_itemIndex_offset)
            )

            // Ensure that the order index is not out of range.
            if iszero(lt(itemIndex, mload(considerationArrPtr))) {
                throwInvalidFulfillmentComponentData()
            }

            // Retrieve consideration item pointer using the item index.
            let considerationItemPtr := mload(
                add(
                    // Get pointer to beginning of receivedItem.
                    add(considerationArrPtr, OneWord),
                    // Calculate offset to pointer for desired order.
                    mul(itemIndex, OneWord)
                )
            )

            // Declare a variable for the final aggregated item amount.
            let amount := 0

            // Create variable to track errors encountered with amount.
            let errorBuffer := 0

            // Only add consideration amount to execution amount if numerator is
            // greater than zero.
            if mload(add(orderPtr, AdvancedOrder_numerator_offset)) {
                // Retrieve amount pointer using consideration item pointer.
                let amountPtr := add(considerationItemPtr, Common_amount_offset)

                // Set the amount.
                amount := mload(amountPtr)

                // Set error bit if amount is zero.
                errorBuffer := iszero(amount)

                // Zero out amount on item to indicate it is credited.
                mstore(amountPtr, 0)
            }

            // Retrieve ReceivedItem pointer from Execution.
            let receivedItem := mload(execution)

            // Set the item type on the received item.
            mstore(receivedItem, mload(considerationItemPtr))

            // Set the token on the received item.
            mstore(
                add(receivedItem, Common_token_offset),
                mload(add(considerationItemPtr, Common_token_offset))
            )

            // Set the identifier on the received item.
            mstore(
                add(receivedItem, Common_identifier_offset),
                mload(add(considerationItemPtr, Common_identifier_offset))
            )

            // Set the recipient on the received item.
            mstore(
                add(receivedItem, ReceivedItem_recipient_offset),
                mload(
                    add(
                        considerationItemPtr,
                        ConsiderationItem_recipient_offset
                    )
                )
            )

            // Calculate the hash of (itemType, token, identifier).
            let dataHash := keccak256(
                receivedItem,
                ReceivedItem_CommonParams_size
            )

            // Get position one word past last element in head of array.
            let endPtr := add(
                considerationComponents,
                mul(mload(considerationComponents), OneWord)
            )

            // Iterate over remaining offer components.
            // prettier-ignore
            for {} lt(fulfillmentHeadPtr,  endPtr) {} {
                // Increment position in considerationComponents head.
                fulfillmentHeadPtr := add(fulfillmentHeadPtr, OneWord)

                // Get the order index using the fulfillment pointer.
                orderIndex := mload(mload(fulfillmentHeadPtr))

                // Ensure the order index is in range.
                if iszero(lt(orderIndex, mload(advancedOrders))) {
                  throwInvalidFulfillmentComponentData()
                }

                // Get pointer to AdvancedOrder element.
                orderPtr := mload(
                    add(
                        add(advancedOrders, OneWord),
                        mul(orderIndex, OneWord)
                    )
                )

                // Only continue if numerator is not zero.
                if iszero(
                    mload(add(orderPtr, AdvancedOrder_numerator_offset))
                ) {
                  continue
                }

                // Load consideration array pointer from OrderParameters.
                considerationArrPtr := mload(
                    add(
                        // Get pointer to OrderParameters from AdvancedOrder.
                        mload(orderPtr),
                        OrderParameters_consideration_head_offset
                    )
                )

                // Get the item index using the fulfillment pointer.
                itemIndex := mload(add(mload(fulfillmentHeadPtr), OneWord))

                // Check if itemIndex is within the range of array.
                if iszero(lt(itemIndex, mload(considerationArrPtr))) {
                    throwInvalidFulfillmentComponentData()
                }

                // Retrieve consideration item pointer using index.
                considerationItemPtr := mload(
                    add(
                        // Get pointer to beginning of receivedItem.
                        add(considerationArrPtr, OneWord),
                        // Use offset to pointer for desired order.
                        mul(itemIndex, OneWord)
                    )
                )

                // Retrieve amount pointer using consideration item pointer.
                let amountPtr := add(
                      considerationItemPtr,
                      Common_amount_offset
                )

                // Add offer amount to execution amount.
                let newAmount := add(amount, mload(amountPtr))

                // Update error buffer: 1 = zero amount, 2 = overflow, 3 = both.
                errorBuffer := or(
                  errorBuffer,
                  or(
                    shl(1, lt(newAmount, amount)),
                    iszero(mload(amountPtr))
                  )
                )

                // Update the amount to the new, summed amount.
                amount := newAmount

                // Zero out amount on original item to indicate it is credited.
                mstore(amountPtr, 0)

                // Ensure the indicated item matches original item.
                if iszero(
                    and(
                        // Item recipients must match.
                        eq(
                            mload(
                                add(
                                    considerationItemPtr,
                                    ConsiderItem_recipient_offset
                                )
                            ),
                            mload(
                                add(
                                    receivedItem,
                                    ReceivedItem_recipient_offset
                                )
                            )
                        ),
                        // The itemType, token, identifier must match.
                        eq(
                          dataHash,
                          keccak256(
                            considerationItemPtr,
                            ReceivedItem_CommonParams_size
                          )
                        )
                    )
                ) {
                    // Throw if any of the requirements are not met.
                    throwInvalidFulfillmentComponentData()
                }
            }
            // Write final amount to execution.
            mstore(add(receivedItem, Common_amount_offset), amount)

            // Determine whether the error buffer contains a nonzero error code.
            if errorBuffer {
                // If errorBuffer is 1, an item had an amount of zero.
                if eq(errorBuffer, 1) {
                    // Store the MissingItemAmount error signature.
                    mstore(0, MissingItemAmount_error_signature)

                    // Return, supplying MissingItemAmount signature.
                    revert(0, MissingItemAmount_error_len)
                }

                // If errorBuffer is not 1 or 0, the sum overflowed.
                // Panic!
                throwOverflow()
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0xfe1497fe(bytes32 c__0xfe1497fe) pure {}


import { Side } from "../lib/ConsiderationEnums.sol";

/**
 * @title FulfillmentApplicationErrors
 * @author 0age
 * @notice FulfillmentApplicationErrors contains errors related to fulfillment
 *         application and aggregation.
 */
interface FulfillmentApplicationErrors {
    /**
     * @dev Revert with an error when a fulfillment is provided that does not
     *      declare at least one component as part of a call to fulfill
     *      available orders.
     */
    error MissingFulfillmentComponentOnAggregation(Side side);

    /**
     * @dev Revert with an error when a fulfillment is provided that does not
     *      declare at least one offer component and at least one consideration
     *      component.
     */
    error OfferAndConsiderationRequiredOnFulfillment();

    /**
     * @dev Revert with an error when the initial offer item named by a
     *      fulfillment component does not match the type, token, identifier,
     *      or conduit preference of the initial consideration item.
     */
    error MismatchedFulfillmentOfferAndConsiderationComponents();

    /**
     * @dev Revert with an error when an order or item index are out of range
     *      or a fulfillment component does not match the type, token,
     *      identifier, or conduit preference of the initial consideration item.
     */
    error InvalidFulfillmentComponentData();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0xa7b494b0(bytes32 c__0xa7b494b0) pure {}


import { ItemType, Side } from "./ConsiderationEnums.sol";

import {
    OfferItem,
    ConsiderationItem,
    OrderParameters,
    AdvancedOrder,
    CriteriaResolver
} from "./ConsiderationStructs.sol";

import "./ConsiderationConstants.sol";

import {
    CriteriaResolutionErrors
} from "../interfaces/CriteriaResolutionErrors.sol";

/**
 * @title CriteriaResolution
 * @author 0age
 * @notice CriteriaResolution contains a collection of pure functions related to
 *         resolving criteria-based items.
 */
contract CriteriaResolution is CriteriaResolutionErrors {
function c_0xdc632245(bytes32 c__0xdc632245) internal pure {}

    /**
     * @dev Internal pure function to apply criteria resolvers containing
     *      specific token identifiers and associated proofs to order items.
     *
     * @param advancedOrders     The orders to apply criteria resolvers to.
     * @param criteriaResolvers  An array where each element contains a
     *                           reference to a specific order as well as that
     *                           order's offer or consideration, a token
     *                           identifier, and a proof that the supplied token
     *                           identifier is contained in the order's merkle
     *                           root. Note that a root of zero indicates that
     *                           any transferable token identifier is valid and
     *                           that no proof needs to be supplied.
     */
    function _applyCriteriaResolvers(
        AdvancedOrder[] memory advancedOrders,
        CriteriaResolver[] memory criteriaResolvers
    ) internal pure {c_0xdc632245(0x24b5d3a9beaadff52b4cffca2d50222f9044b3827c1f3dbb50e238e1be9f7b04); /* function */ 

        // Skip overflow checks as all for loops are indexed starting at zero.
c_0xdc632245(0xbdf6c8f62740f9669891f8303641f3ab7afb02b15a54eaa4ddcad918d19c8915); /* line */ 
        unchecked {
            // Retrieve length of criteria resolvers array and place on stack.
c_0xdc632245(0x051bd7eaec07af4bf918f4fcd50198c3e96a95f95c82d93ba5ca934df97a5cf1); /* line */ 
            c_0xdc632245(0x2a153eed557b24d6404291459a6bd68fbb707ac25046838470400bcd3b387793); /* statement */ 
uint256 totalCriteriaResolvers = criteriaResolvers.length;

            // Retrieve length of orders array and place on stack.
c_0xdc632245(0x9ea0296239ba03f02588392777a62194e962d2caaa7ef5b1216653fba69ea61d); /* line */ 
            c_0xdc632245(0x56e692fd497cbfce825f295cca4d7c77e6d72c639f243dea69c1378c84e51b43); /* statement */ 
uint256 totalAdvancedOrders = advancedOrders.length;

            // Iterate over each criteria resolver.
c_0xdc632245(0x249c70741568aa48d1c17bffded9e452b218d74615b4b533e1f24d80fa445303); /* line */ 
            c_0xdc632245(0x486a18d25e4e17a3bc25ade8b467c23a292d14a7b56f73b89af2a4684e213a6f); /* statement */ 
for (uint256 i = 0; i < totalCriteriaResolvers; ++i) {
                // Retrieve the criteria resolver.
c_0xdc632245(0xc10765d9821379366f9f3c7cf72501e3ea2448d20011fb636e4a4a74a483d94e); /* line */ 
                c_0xdc632245(0x0f5e0427ec8311301930c6de4f1520b0da3ab0ed62885c017732af1b5eb99baa); /* statement */ 
CriteriaResolver memory criteriaResolver = (
                    criteriaResolvers[i]
                );

                // Read the order index from memory and place it on the stack.
c_0xdc632245(0x1fc2f3c577f78d3f343863e19b192b4aa4326a6a4c2d2a7ea83011abb2bc3df6); /* line */ 
                c_0xdc632245(0x3018449eb52ec16e193ee53672d9355320bf83eaec74c4b2f48373123715aa35); /* statement */ 
uint256 orderIndex = criteriaResolver.orderIndex;

                // Ensure that the order index is in range.
c_0xdc632245(0x8b24a0439d79bd09aa01eff1b2960fc7f37dfb6d80fe1297582db9d817cbd53d); /* line */ 
                c_0xdc632245(0xb5251516166d96736f59308a849bd0f0a2d0cf1f1cc8a47575ea37b069d852d0); /* statement */ 
if (orderIndex >= totalAdvancedOrders) {c_0xdc632245(0x7f49f87a4a8ac5adb694e65715f479d8a15bf5c5544f3b6c14db1ce23b9d265e); /* branch */ 

c_0xdc632245(0x12e9b982b3df49d7638362960bae4fbe846f45225025f28735f2eb7b4bc861ce); /* line */ 
                    revert OrderCriteriaResolverOutOfRange();
                }else { c_0xdc632245(0xa83f81bae648987ef097c17adf34100981d3ed2ddf5931cabad371cd207d1de9); /* branch */ 
}

                // Skip criteria resolution for order if not fulfilled.
c_0xdc632245(0xe081747189181645b9b6d8c3ea93943fd79033bbe56bd670cf41417bf7c0592d); /* line */ 
                c_0xdc632245(0xfc6c06ce247b81d4ece50afe2d1c09e13f565373328a272cf64e458d54cadc66); /* statement */ 
if (advancedOrders[orderIndex].numerator == 0) {c_0xdc632245(0x083105969747ff7c105b6e5bf6473e11a9933a18a37a1ed149725554c02a2d4b); /* branch */ 

c_0xdc632245(0x0d765a8563f6c5ec044fba99fd5de32d48cf110b186a5ec24492b5658eafef00); /* line */ 
                    continue;
                }else { c_0xdc632245(0x9437052b3654caa68ef9b7568678a63cf506094d6c6e889898fcb554d5e60532); /* branch */ 
}

                // Retrieve the parameters for the order.
c_0xdc632245(0x33173b1c00951e6eaf2188381a90dd1043358f5156d4586c295f093884fcd7fb); /* line */ 
                c_0xdc632245(0x6a94a6ba21df1adc0061a2209ac8b96e46d79a22dc58e6a58da0f5cffde3bf5e); /* statement */ 
OrderParameters memory orderParameters = (
                    advancedOrders[orderIndex].parameters
                );

                // Read component index from memory and place it on the stack.
c_0xdc632245(0x87f83374d2e66b44fb6d06373304fa08f160f8d66540802cec064aee633e9391); /* line */ 
                c_0xdc632245(0x9f8f282b18d90057fbd51141a4714f1a088ebc018923c7463789c5eaf2f2e399); /* statement */ 
uint256 componentIndex = criteriaResolver.index;

                // Declare values for item's type and criteria.
c_0xdc632245(0x34e7895199e590151317db4e5f1059f2eb98562c9dce98d8fdcd2db2a9be74bd); /* line */ 
                c_0xdc632245(0xc9d3b364e1d589905e1549f2b9aaa488a028522d1ae3468757c4acae51187020); /* statement */ 
ItemType itemType;
c_0xdc632245(0xb24380d57128c3efd9ed29b6fc34c3fea0c93deb5ac962d4833316e5cb583647); /* line */ 
                c_0xdc632245(0x644c339a6f3b7ce79c3a5d8c37e8b63e66878f4ade380dcaacb1cfa6c8ad6a38); /* statement */ 
uint256 identifierOrCriteria;

                // If the criteria resolver refers to an offer item...
c_0xdc632245(0x53789834a16297986dff3cf513cd4b9c3d1b80eda67a9eb169c7027bf085162c); /* line */ 
                c_0xdc632245(0x8bec085f9e5f538eb549968157e3415dd6e3e3228fad593228b98f7477c61316); /* statement */ 
if (criteriaResolver.side == Side.OFFER) {c_0xdc632245(0x8d449ec2c8892ef5bcb99d510fb61f83e9aa29bebb39d69637459c6d38e89c1f); /* branch */ 

                    // Retrieve the offer.
c_0xdc632245(0xe4f7628e7e118d6ec3cadf5f6b3a758c14d0d29768e78bbbf088c973ae4e771c); /* line */ 
                    c_0xdc632245(0x9be8234519eec58cc7fd69580aee8b3ac067add65bd334814d6cdba31439f760); /* statement */ 
OfferItem[] memory offer = orderParameters.offer;

                    // Ensure that the component index is in range.
c_0xdc632245(0x2f5358d3feff4af2151d331f7b670b7152a784971237619f6ddb884b29d134a8); /* line */ 
                    c_0xdc632245(0xeb585b15c5019942c8072f940819d546a7e353ed7ea52fa72f9615bf7542c462); /* statement */ 
if (componentIndex >= offer.length) {c_0xdc632245(0x9325f81f8db80471f85343e8a80cc42c5e759e2e26f1fe3cedb780a61eea9bbe); /* branch */ 

c_0xdc632245(0x99954d197bb8776c8b8888c94fd389fcfbe64d2f244ebb8d6eb51fff4de87782); /* line */ 
                        revert OfferCriteriaResolverOutOfRange();
                    }else { c_0xdc632245(0xe50426c28f4e3e728580c6bb1ef7a6842e0c245340228e78ab04295dcf8bebfb); /* branch */ 
}

                    // Retrieve relevant item using the component index.
c_0xdc632245(0x69b1bc4aeb936582085ac80669681bb313a17e247f4937e1a3300bf69820a45b); /* line */ 
                    c_0xdc632245(0xae9fa114e0007d36a5831e7fa4ac34ccb4a5b26f55ab91deac9ce0e21b59f8db); /* statement */ 
OfferItem memory offerItem = offer[componentIndex];

                    // Read item type and criteria from memory & place on stack.
c_0xdc632245(0x4d69bc4b56c52e71e01f6ac9c4e753d2f3ba3bfd9589049578ffbade980176da); /* line */ 
                    c_0xdc632245(0xa0b0b0fe4ac937d2db0ab95b675501101c95c97984defbc389718df4278b268e); /* statement */ 
itemType = offerItem.itemType;
c_0xdc632245(0x37c606aa4ac550244efdcd4c71d1f0fa1ef6d1580cf320feba8336cd33f8bea6); /* line */ 
                    c_0xdc632245(0xa3713ad469d4ebbbb861814330e4aecb4696a518a08c6671151296b32183fb5a); /* statement */ 
identifierOrCriteria = offerItem.identifierOrCriteria;

                    // Optimistically update item type to remove criteria usage.
                    // Use assembly to operate on ItemType enum as a number.
c_0xdc632245(0xbda9b38ad879b83a102f617d38c09ec9136a6ee26b98539f850f61c8834cb66b); /* line */ 
                    c_0xdc632245(0xa282b3f974ff8f9d04d43dfdd3ab07b3dff18c1e0eeef350c6b4e8c5455c5751); /* statement */ 
ItemType newItemType;
c_0xdc632245(0xe3d12e93dc6ba92d3b2dbcf70226085d2d8068d684dce2c3391c3990d8252bc3); /* line */ 
                    assembly {
                        // Item type 4 becomes 2 and item type 5 becomes 3.
                        newItemType := sub(3, eq(itemType, 4))
                    }
c_0xdc632245(0xd7ddfb28ed7cfd2fe4824eddba37498ccd596c6f373a9413d5024fbbea9108dd); /* line */ 
                    c_0xdc632245(0x55ffabd861ce5b9ba52009de46d09e1ae608d9293aa4e96b6550876c4febd5f1); /* statement */ 
offerItem.itemType = newItemType;

                    // Optimistically update identifier w/ supplied identifier.
c_0xdc632245(0xd9c19cec4fc9f500a7e2e6334af231a0e0fc03dc2b5d5fc5cc9c983b7cdb6733); /* line */ 
                    c_0xdc632245(0x51dc8a89a3c9c0867ec9d309020ceca8305c19a5ce065471e2e0310d603df6e9); /* statement */ 
offerItem.identifierOrCriteria = criteriaResolver
                        .identifier;
                } else {c_0xdc632245(0x315fc71fcd94b00acdd3e90fd62d4d7ebd8091bd300a35e0a21abc550dfd2c2e); /* branch */ 

                    // Otherwise, the resolver refers to a consideration item.
c_0xdc632245(0xac8752171afa55bfb52761619ddf1787260e10a55466ec6b8a3c23ea0c581d21); /* line */ 
                    c_0xdc632245(0xe8ad7c13ebf1a99467b48e33071a1f1aa0b658a0ddb4f4ee23f42092338607cf); /* statement */ 
ConsiderationItem[] memory consideration = (
                        orderParameters.consideration
                    );

                    // Ensure that the component index is in range.
c_0xdc632245(0xea0a60e880df6ff650b86c50eeb8dba963fc519e75f68b3d3c9db46186a4dc34); /* line */ 
                    c_0xdc632245(0xfc6041f706366f58d3c9f4918f8820cc72547998a675d586b4ea324c8a5fe8ac); /* statement */ 
if (componentIndex >= consideration.length) {c_0xdc632245(0xb9ad5b25244cbb616424943223aef65bedfb6bf1e9cd706eb5016ffaf2ad4ea2); /* branch */ 

c_0xdc632245(0xe26d67f64733219d574159c3240cfe8ec33fbf75fd6d0decee18fc2dfadc2ebe); /* line */ 
                        revert ConsiderationCriteriaResolverOutOfRange();
                    }else { c_0xdc632245(0xb700394949d81038120171b3a22a2f08a8e1b6a2ca26faf8c5624a95dafd5479); /* branch */ 
}

                    // Retrieve relevant item using order and component index.
c_0xdc632245(0x0ddf67ff5ec00079d61e836e6123de73fef05e0922628c004bac0a977e94d9f4); /* line */ 
                    c_0xdc632245(0xcdcc6957f2d0ae279ad614e4c249f38404dff471255a19f1215997d39088a559); /* statement */ 
ConsiderationItem memory considerationItem = (
                        consideration[componentIndex]
                    );

                    // Read item type and criteria from memory & place on stack.
c_0xdc632245(0xb54cfcb86526c23cc5b07bb269d87383dc21b8e25674e082c45b73fc03def82b); /* line */ 
                    c_0xdc632245(0x47aa850dbb118265de1aac1d7298beed5531d8d7baab97c9a842ee506e08bb75); /* statement */ 
itemType = considerationItem.itemType;
c_0xdc632245(0x6df2dfbf7ebd2fb3bdd118945940b344d9204f0957c5e0a1a10a812dba99ed33); /* line */ 
                    c_0xdc632245(0xe6eda0b24ee63f08851dd6de0c880e64b2828210cbe167a44b71b9531350d423); /* statement */ 
identifierOrCriteria = (
                        considerationItem.identifierOrCriteria
                    );

                    // Optimistically update item type to remove criteria usage.
                    // Use assembly to operate on ItemType enum as a number.
c_0xdc632245(0xcd3fb7dc602c0ecf1cf19207c3bed5764b85a30e3d18100c22290905b2b40e9d); /* line */ 
                    c_0xdc632245(0xd78e804a4a5f9abb2b3f4662e181791079bf3799270ea53e88f45387ede1b6f1); /* statement */ 
ItemType newItemType;
c_0xdc632245(0xef2d8c524562846ff28d24874500183ada9ac333302f6f8fa98cc858ef9c0ae8); /* line */ 
                    assembly {
                        // Item type 4 becomes 2 and item type 5 becomes 3.
                        newItemType := sub(3, eq(itemType, 4))
                    }
c_0xdc632245(0x1602814e76d0508ae1bb220476d7623d3508ede82b5463a579d568bde5f2da76); /* line */ 
                    c_0xdc632245(0x81775aad95992eb9011c26a2b7f94883d07311c6c7196dce84a83bf7be634e55); /* statement */ 
considerationItem.itemType = newItemType;

                    // Optimistically update identifier w/ supplied identifier.
c_0xdc632245(0x38fa3d9000773f54872231bc251f7529861de73cb8e65ac9cffb9eabb1844dd3); /* line */ 
                    c_0xdc632245(0xe4f903520055d8928010a5c618aa10a2aff2f444a8b9512f2b8a2f9bfedb42a1); /* statement */ 
considerationItem.identifierOrCriteria = (
                        criteriaResolver.identifier
                    );
                }

                // Ensure the specified item type indicates criteria usage.
c_0xdc632245(0x80405ef1d8be7985980cbc73bc0168f3c943e37171d72befd1e080790f2a673d); /* line */ 
                c_0xdc632245(0x160a5f3b9613514e51687ae4dea0c6c8853b01993590c97483faf5307a98a992); /* statement */ 
if (!_isItemWithCriteria(itemType)) {c_0xdc632245(0x69beb74dbd14dfff9e19905010f2d6d28c28d9bd4edd7031ce95c10a5f01ca32); /* branch */ 

c_0xdc632245(0x01248a93f729d6a77410c9a9eb86063c0ad85b64dfc193db2de64e413c5e7a42); /* line */ 
                    revert CriteriaNotEnabledForItem();
                }else { c_0xdc632245(0x4a9b66a3102602e2095266beff8869ebaef92ec91247f1905fe6210c1b8395b7); /* branch */ 
}

                // If criteria is not 0 (i.e. a collection-wide offer)...
c_0xdc632245(0x381ed957f157296485a48cfc01f3086bfe76c49ef6bc174ba88ae85a1204dad0); /* line */ 
                c_0xdc632245(0xdc5605704185fec0cba3140f17eb45139b443635dd3af87f38ed5f083981f5b5); /* statement */ 
if (identifierOrCriteria != uint256(0)) {c_0xdc632245(0xfdc3ae98df14e064f6764f9f4ae331f35c1dc6c8655df73046fc6d847f56cf99); /* branch */ 

                    // Verify identifier inclusion in criteria root using proof.
c_0xdc632245(0x335838056d632eaa0e77747ee47e78a3bf5bebc20c6bee9776006bbf6dc5b365); /* line */ 
                    c_0xdc632245(0x8570f7fb36cb98508cdf4b3bb107109c7ae6a04a33221077468f3718e843e7ac); /* statement */ 
_verifyProof(
                        criteriaResolver.identifier,
                        identifierOrCriteria,
                        criteriaResolver.criteriaProof
                    );
                }else { c_0xdc632245(0x5f8f45e12d07505babf713cdbb0faf43a00bb0c611aa8bdca15b9efd4e43d6cf); /* branch */ 
}
            }

            // Iterate over each advanced order.
c_0xdc632245(0xa5dcf4b6be24ebd51d94bef5d3a8b5c937a1bf28ccaaca725af1b369f917e3d1); /* line */ 
            c_0xdc632245(0x4783cd7fa3a0f3f3df3b50b7e9d16528bc9a1f925fc61edc94b047321554ffe1); /* statement */ 
for (uint256 i = 0; i < totalAdvancedOrders; ++i) {
                // Retrieve the advanced order.
c_0xdc632245(0x026e80fd7ec2f0e8300a846c6fe5a45183383fb2ed9d01f9752ca486850c1e0c); /* line */ 
                c_0xdc632245(0x9406ae0be36880771662ea2ee0bba5317ec6abcb6f9a72769796beb568f9e179); /* statement */ 
AdvancedOrder memory advancedOrder = advancedOrders[i];

                // Skip criteria resolution for order if not fulfilled.
c_0xdc632245(0xf49009cccc7c6a6115b9c0ffc31cb53e6dfc5424103d82e941c9dcfcdb4257ab); /* line */ 
                c_0xdc632245(0xa486d698772985f06e74c4e0092e8e31fbd348fb401ae2199d49ab1829a46c56); /* statement */ 
if (advancedOrder.numerator == 0) {c_0xdc632245(0xff44d854841d6eaab7d9e09d33b8940fa292c2e66c292a9d3a2c320131caceef); /* branch */ 

c_0xdc632245(0x033c2a00eb334d080671689de4e958fda2e80753ba79b91eaf6119099bd13b83); /* line */ 
                    continue;
                }else { c_0xdc632245(0x86509e69a96ee8c3d992b4a6c7b98b3a216803809d8259e31770a9f846a26bfc); /* branch */ 
}

                // Retrieve the parameters for the order.
c_0xdc632245(0x0681393771c12198f851a4c59bc71c6f04dd3b11bdae2d92c6b380db34fa37ee); /* line */ 
                c_0xdc632245(0x1a63378e0acf252dc8ccf0b3a71627c287cca7708042d8849e0838da241e744d); /* statement */ 
OrderParameters memory orderParameters = (
                    advancedOrder.parameters
                );

                // Read consideration length from memory and place on stack.
c_0xdc632245(0x5e95a01a2e31359e8958440b01ffcf67d2edf3f9a5cca80982f7c36801a6029e); /* line */ 
                c_0xdc632245(0xd6e2b4b4ca62edcf27ab0ece98b39e69e4c6ae8740a45bbe84ac19db7fb6249d); /* statement */ 
uint256 totalItems = orderParameters.consideration.length;

                // Iterate over each consideration item on the order.
c_0xdc632245(0x4e69dcb09d6c36923c3fbb0d9a545cd5a2b7f1d76dc59a60ed63b35233ea7076); /* line */ 
                c_0xdc632245(0x0eb7a00049d53667d12ec35d6e758f2f593ad2e1bb77c981fa274510947d6e07); /* statement */ 
for (uint256 j = 0; j < totalItems; ++j) {
                    // Ensure item type no longer indicates criteria usage.
c_0xdc632245(0x41056f558b05424edc4f13ab6599294a8bb70b98f0d64440b52ae7486bf4cc6f); /* line */ 
                    c_0xdc632245(0xc3956fcc1abd414574864b7b387ea4c9a7acba70362169473ff19480624b6617); /* statement */ 
if (
                        _isItemWithCriteria(
                            orderParameters.consideration[j].itemType
                        )
                    ) {c_0xdc632245(0xf592fdbd073bc2b823b084e94eccaae897dbe17a8fa8bd03d5d425cf7f9d495d); /* branch */ 

c_0xdc632245(0xea9cbc130319a4bdd2f2ecdbb4c8ddd066c49f4dfdc395db78b418f5398d8ad2); /* line */ 
                        revert UnresolvedConsiderationCriteria();
                    }else { c_0xdc632245(0xccc580c9f8920f43c5dca75331a767f3dc8ea69fe6c9ee16e2751e930f17a504); /* branch */ 
}
                }

                // Read offer length from memory and place on stack.
c_0xdc632245(0x04403d59f012205a70a5da2f1ce2ef87de0c7fa96252342b691b622bfbcae742); /* line */ 
                c_0xdc632245(0x18c862df1ccb25ec3278f54ed509245ad6ff69356e5bea715fe247f297a23e52); /* statement */ 
totalItems = orderParameters.offer.length;

                // Iterate over each offer item on the order.
c_0xdc632245(0x9c4b682ae94294b5c1e492d0a20bb649222200d25439368ffd2b75fc61c18d66); /* line */ 
                c_0xdc632245(0x19317d95b13594e18c23a6afb62690d2bcb060193e88a1d212474947de060b80); /* statement */ 
for (uint256 j = 0; j < totalItems; ++j) {
                    // Ensure item type no longer indicates criteria usage.
c_0xdc632245(0xb5d031567673b47cc5f6917aaac0e9900c15fa2a9df6a6bcb98c9462b3ebdcff); /* line */ 
                    c_0xdc632245(0x134520231094c479f9d2b0ed0c0da653adb732909b71a4987e384f36fc849c5d); /* statement */ 
if (
                        _isItemWithCriteria(orderParameters.offer[j].itemType)
                    ) {c_0xdc632245(0x735a56d0a786cea640d30aade1e47c1cf037d6cc392958090a4e42b9099230ef); /* branch */ 

c_0xdc632245(0x8de44f43e166fa761d342dae14c3d78b874425e148b6a9c011533993a28b6f7a); /* line */ 
                        revert UnresolvedOfferCriteria();
                    }else { c_0xdc632245(0xd837ca51437d094323a77ba8112596897d6e209ed6e71670b957b2958667e7ef); /* branch */ 
}
                }
            }
        }
    }

    /**
     * @dev Internal pure function to check whether a given item type represents
     *      a criteria-based ERC721 or ERC1155 item (e.g. an item that can be
     *      resolved to one of a number of different identifiers at the time of
     *      order fulfillment).
     *
     * @param itemType The item type in question.
     *
     * @return withCriteria A boolean indicating that the item type in question
     *                      represents a criteria-based item.
     */
    function _isItemWithCriteria(ItemType itemType)
        internal
        pure
        returns (bool withCriteria)
    {c_0xdc632245(0xc351e7516d700f51f6634b090ee97fd86a3293b40933b415027a739b5d486e8d); /* function */ 

        // ERC721WithCriteria is ItemType 4. ERC1155WithCriteria is ItemType 5.
c_0xdc632245(0x66c813014a4ecf152c21697bfa9765f7c24b34f9beebbfe46c9e6999bd0087bf); /* line */ 
        assembly {
            withCriteria := gt(itemType, 3)
        }
    }

    /**
     * @dev Internal pure function to ensure that a given element is contained
     *      in a merkle root via a supplied proof.
     *
     * @param leaf  The element for which to prove inclusion.
     * @param root  The merkle root that inclusion will be proved against.
     * @param proof The merkle proof.
     */
    function _verifyProof(
        uint256 leaf,
        uint256 root,
        bytes32[] memory proof
    ) internal pure {c_0xdc632245(0x449d0cef60a422b619bccc57e49ecdade23b39744ffe064e9eefbbf11ddfefbb); /* function */ 

        // Declare a variable that will be used to determine proof validity.
c_0xdc632245(0xcd0cd0156a94f7ee327e48553e79fe4c999d87fd7b15d9e07f87b2e42dc66d74); /* line */ 
        c_0xdc632245(0x0798ba1ba7f1814c71b1a3ca6eb1e9a06dbe08c379012b4f744ba2bfac8e766b); /* statement */ 
bool isValid;

        // Utilize assembly to efficiently verify the proof against the root.
c_0xdc632245(0xbf95ab054d620425db98e9e6b955e0986af40b1b2259ca7bf123e31a90c1e9f4); /* line */ 
        assembly {
            // Store the leaf at the beginning of scratch space.
            mstore(0, leaf)

            // Derive the hash of the leaf to use as the initial proof element.
            let computedHash := keccak256(0, OneWord)

            // Based on: https://github.com/Rari-Capital/solmate/blob/v7/src/utils/MerkleProof.sol
            // Get memory start location of the first element in proof array.
            let data := add(proof, OneWord)

            // Iterate over each proof element to compute the root hash.
            for {
                // Left shift by 5 is equivalent to multiplying by 0x20.
                let end := add(data, shl(5, mload(proof)))
            } lt(data, end) {
                // Increment by one word at a time.
                data := add(data, OneWord)
            } {
                // Get the proof element.
                let loadedData := mload(data)

                // Sort proof elements and place them in scratch space.
                // Slot of `computedHash` in scratch space.
                // If the condition is true: 0x20, otherwise: 0x00.
                let scratch := shl(5, gt(computedHash, loadedData))

                // Store elements to hash contiguously in scratch space. Scratch
                // space is 64 bytes (0x00 - 0x3f) & both elements are 32 bytes.
                mstore(scratch, computedHash)
                mstore(xor(scratch, OneWord), loadedData)

                // Derive the updated hash.
                computedHash := keccak256(0, TwoWords)
            }

            // Compare the final hash to the supplied root.
            isValid := eq(computedHash, root)
        }

        // Revert if computed hash does not equal supplied root.
c_0xdc632245(0xe45e1ae8a32edac549ee67272bd5e48f7a5956d598ff6831eac8f626eda5551e); /* line */ 
        c_0xdc632245(0x980b0d84fcbf81d3252564069a3721c90568943dc2e9cb73fe3e364dedadba06); /* statement */ 
if (!isValid) {c_0xdc632245(0xc09b6eb4a01ea75db07fdd7eb5b8841953abc1bb36940f1667387174ef56f06b); /* branch */ 

c_0xdc632245(0x2feee03303a9b72ebc47db9eb3bcd560aabfb4ada590050becbe1e4c630f9a74); /* line */ 
            revert InvalidProof();
        }else { c_0xdc632245(0x62c4b12ee1debccb6c6210e5e130a50f8c90a06c3d0c46a081b7257661a02aac); /* branch */ 
}
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0x5ac93adc(bytes32 c__0x5ac93adc) pure {}


/**
 * @title CriteriaResolutionErrors
 * @author 0age
 * @notice CriteriaResolutionErrors contains all errors related to criteria
 *         resolution.
 */
interface CriteriaResolutionErrors {
    /**
     * @dev Revert with an error when providing a criteria resolver that refers
     *      to an order that has not been supplied.
     */
    error OrderCriteriaResolverOutOfRange();

    /**
     * @dev Revert with an error if an offer item still has unresolved criteria
     *      after applying all criteria resolvers.
     */
    error UnresolvedOfferCriteria();

    /**
     * @dev Revert with an error if a consideration item still has unresolved
     *      criteria after applying all criteria resolvers.
     */
    error UnresolvedConsiderationCriteria();

    /**
     * @dev Revert with an error when providing a criteria resolver that refers
     *      to an order with an offer item that has not been supplied.
     */
    error OfferCriteriaResolverOutOfRange();

    /**
     * @dev Revert with an error when providing a criteria resolver that refers
     *      to an order with a consideration item that has not been supplied.
     */
    error ConsiderationCriteriaResolverOutOfRange();

    /**
     * @dev Revert with an error when providing a criteria resolver that refers
     *      to an order with an item that does not expect a criteria to be
     *      resolved.
     */
    error CriteriaNotEnabledForItem();

    /**
     * @dev Revert with an error when providing a criteria resolver that
     *      contains an invalid proof with respect to the given item and
     *      chosen identifier.
     */
    error InvalidProof();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0x927a2374(bytes32 c__0x927a2374) pure {}


import { PausableZone } from "./PausableZone.sol";

import {
    PausableZoneControllerInterface
} from "./interfaces/PausableZoneControllerInterface.sol";

import {
    PausableZoneEventsAndErrors
} from "./interfaces/PausableZoneEventsAndErrors.sol";

import {
    Order,
    Fulfillment,
    OrderComponents,
    AdvancedOrder,
    CriteriaResolver,
    Execution
} from "../lib/ConsiderationStructs.sol";

import { SeaportInterface } from "../interfaces/SeaportInterface.sol";

/**
 * @title  PausableZoneController
 * @author cupOJoseph, BCLeFevre, stuckinaboot, stephankmin
 * @notice PausableZoneController enables deploying, pausing and executing
 *         orders on PausableZones. This deployer is designed to be owned
 *         by a gnosis safe, DAO, or trusted party.
 */
contract PausableZoneController is
    PausableZoneControllerInterface,
    PausableZoneEventsAndErrors
{
function c_0x889211a1(bytes32 c__0x889211a1) internal pure {}

    // Set the owner that can deploy, pause and execute orders on PausableZones.
    address internal _owner;

    // Set the address of the new potential owner of the zone.
    address private _potentialOwner;

    // Set the address with the ability to pause the zone.
    address internal _pauser;

    // Set the immutable zone creation code hash.
    bytes32 public immutable zoneCreationCode;

    /**
     * @dev Throws if called by any account other than the owner or pauser.
     */
    modifier isPauser() {c_0x889211a1(0x3cfdf37de98214e685ffed8ed83cb2077f8daa1dd4ff957c12f43d045ba1c1d5); /* function */ 

c_0x889211a1(0xbbc37798ca3b9b5e8f10daba96714ef1eda6b8ec23a28114530393874f91c925); /* line */ 
        c_0x889211a1(0x0dae60ff8dd64f7d5e9b5de19a9927b30270188c95fb4e152582b500efef35be); /* statement */ 
if (msg.sender != _pauser && msg.sender != _owner) {c_0x889211a1(0xb4617a501970409e74c4d15ce2c186667e7b51ab57b63c35773c39ad4c59ef96); /* branch */ 

c_0x889211a1(0x82f32e3fc1b56b32571164da3a7eba9e630fee33cabe8f5adf4e2528e4e204fa); /* line */ 
            revert InvalidPauser();
        }else { c_0x889211a1(0xe29757ad3debd2bc071051f72818985638dd6888a0c1cd2e8f8f0753ad798f30); /* branch */ 
}
c_0x889211a1(0xe4e70f3be8c425f4d71f279d621bb62fb40625e8699a49351dc3fd2c6f53c9d7); /* line */ 
        _;
    }

    /**
     * @notice Set the owner of the controller and store
     *         the zone creation code.
     *
     * @param ownerAddress The deployer to be set as the owner.
     */
    constructor(address ownerAddress) {c_0x889211a1(0x9602751fe42e28313e4f3b87f5238ebf76e9e23b8f6f921bf1bd9de87e4b3445); /* function */ 

        // Set the owner address as the owner.
c_0x889211a1(0xd5775e54d63919b2955f7309d10a59acf86ceee37216a42dfef7bdb4aa4e00e8); /* line */ 
        c_0x889211a1(0xc0743f80dd527e595f6912fbbb323d8f2b6fedb42284271479728943ef690e54); /* statement */ 
_owner = ownerAddress;

        // Hash and store the zone creation code.
c_0x889211a1(0xa4baaacb5cc165abe97f822d3a9e6f28ad48eeb6eeebef829ca512134c460824); /* line */ 
        c_0x889211a1(0xcb43d72dbf165eaed5a6b9ffd498c59c6fad202b25549f7f754145b3275b663b); /* statement */ 
zoneCreationCode = keccak256(type(PausableZone).creationCode);
    }

    /**
     * @notice Deploy a PausableZone to a precomputed address.
     *
     * @param salt The salt to be used to derive the zone address
     *
     * @return derivedAddress The derived address for the zone.
     */
    function createZone(bytes32 salt)
        external
        override
        returns (address derivedAddress)
    {c_0x889211a1(0xe03a9c478c6f628b89e582a8a01a60496cb12f0d51857125e6c7946ee8a08207); /* function */ 

        // Ensure the caller is the owner.
c_0x889211a1(0x174a34013a9c4c4c8621487b611223700e1fd2e35b55286b52c0abad4bd1b1fe); /* line */ 
        c_0x889211a1(0xa0e4d3267b88c4d9fb807893ed9588b830d01962ef9adfd4726dcafc9555b9db); /* statement */ 
if (msg.sender != _owner) {c_0x889211a1(0x0d2382b4787eb903add84bbb2ffc2c713e11fdb1337c5a12858bc93111ae448d); /* branch */ 

c_0x889211a1(0x61e972c09f8a56aa1cbd6bc141bfbf3aff94f78d40a8ed08cfcd18ea934ed2e7); /* line */ 
            revert CallerIsNotOwner();
        }else { c_0x889211a1(0x9a195203b944c1654307061545042f79fe9b5a42ec1f98c2250589216b0be23a); /* branch */ 
}

        // Derive the PausableZone address.
        // This expression demonstrates address computation but is not required.
c_0x889211a1(0xadb4a3156ac976059b8e924e9d163131e2c68feba30b89caab1f4240893a4bb4); /* line */ 
        c_0x889211a1(0xba1f9158252f8957de9b56e2d95d4efcfd9fd51145823267c2552a7e18a76b16); /* statement */ 
derivedAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt,
                            zoneCreationCode
                        )
                    )
                )
            )
        );

        // Revert if a zone is currently deployed to the derived address.
c_0x889211a1(0x7529936ed9d98ae1a252e16caaca4c8f4cf8207a794f1276d49688093d675620); /* line */ 
        c_0x889211a1(0xe4163b9aa787c5ae85d7c3c5cb8acb3fa3bacd146e81e1dc4fb35a63be979834); /* statement */ 
if (derivedAddress.code.length != 0) {c_0x889211a1(0xd4e9f9027c99918549babf33b38c5d0c0ee6d82ec4e39ed9bef1a242929dc76d); /* branch */ 

c_0x889211a1(0x016846606b90200e74e71bc043e28e542487798974023df49861bc154424c70f); /* line */ 
            revert ZoneAlreadyExists(derivedAddress);
        }else { c_0x889211a1(0x196db16a6c31485e959512af34d5d92576bdda498d1a24c48f48780191c11244); /* branch */ 
}

        // Deploy the zone using the supplied salt.
c_0x889211a1(0x112faa349e891faa6ed2504ec0a7484be5884df040c90d33dcd538671b2692df); /* line */ 
        c_0x889211a1(0xd89c9e85272496e50a22396bfa6d86836c0f38e46f6534dcb8b796d7506850cb); /* statement */ 
new PausableZone{ salt: salt }();

        // Emit an event signifying that the zone was created.
c_0x889211a1(0x4708b1a68155ae3a1ddf458c69ec2d0c74deccb5b5148afbbd8a335fb04296ea); /* line */ 
        c_0x889211a1(0x234467aee7b0137a6d44eea6824d0915ee9065832536aaa369d547cc18a98f89); /* statement */ 
emit ZoneCreated(derivedAddress, salt);
    }

    /**
     * @notice Pause orders on a given zone.
     *
     * @param zone The address of the zone to be paused.
     *
     * @return success A boolean indicating the zone has been paused.
     */
    function pause(address zone)
        external
        override
        isPauser
        returns (bool success)
    {c_0x889211a1(0x654f018c0a890184e083413fa74d06f52014a42fbdde069c92adc823d3576b51); /* function */ 

        // Call pause on the given zone.
c_0x889211a1(0xb1441be03a58487b25d27426ba41b794c056155c55b474c57ad1f97832224180); /* line */ 
        c_0x889211a1(0x69b1797ab7537ecfb13774c79af2eb60c7a4fd7d6fd7f7ef5dc19d301205af45); /* statement */ 
PausableZone(zone).pause(msg.sender);

        // Return a boolean indicating the pause was successful.
c_0x889211a1(0xa4f1a2a368b8659f8cbe150985e93dc33df7c04d4939287a46000a75584aebb6); /* line */ 
        c_0x889211a1(0xd0c59e309c1ac0d159db961d3b86a3a33802304fcdc649e1119eba4eb3e99878); /* statement */ 
success = true;
    }

    /**
     * @notice Cancel Seaport orders on a given zone.
     *
     * @param pausableZoneAddress The zone that manages the
     * orders to be cancelled.
     * @param seaportAddress      The Seaport address.
     * @param orders              The orders to cancel.
     */
    function cancelOrders(
        address pausableZoneAddress,
        SeaportInterface seaportAddress,
        OrderComponents[] calldata orders
    ) external override {c_0x889211a1(0x55f7b20633b1527fe1d5b1a70c8b73a6bd868e74b40ec43fa0c1c18203bdbee0); /* function */ 

        // Ensure the caller is the owner.
c_0x889211a1(0xa24c6f3e3b40611b79259e10fc555499d40fee75a552c28885e2432be075c19b); /* line */ 
        c_0x889211a1(0x436f49fe97e2ecd0f0e66035a880c07371f517cc2cc3aea5b93cb810671f787c); /* statement */ 
if (msg.sender != _owner) {c_0x889211a1(0x3fb9f258a4621344aaa5d63490dd515fb79cfea08c0dc3721dca71f8756ea526); /* branch */ 

c_0x889211a1(0xb24d47deff88459df1cd6e198fb491335e518852230f86b2b1dfd03c83c70742); /* line */ 
            revert CallerIsNotOwner();
        }else { c_0x889211a1(0x7f3178bb6996e56714e35e59b1cab80766db30c114e760e6f78b8a62a341fa41); /* branch */ 
}

        // Create a zone object from the zone address.
c_0x889211a1(0xc416df58177146662eca3b209f884d327d4a46f163ed04e8bccd976c31db5c66); /* line */ 
        c_0x889211a1(0x30032953f63b8c6843e3525a1c328bf9f6c7a5dd2a4fee1ac116e52468052620); /* statement */ 
PausableZone zone = PausableZone(pausableZoneAddress);

        // Call cancelOrders on the given zone.
c_0x889211a1(0x614dd201cb38c821f7ef23bc1a1036f28af49d6c47560bb3b223ce24bf06d54a); /* line */ 
        c_0x889211a1(0x77d84c6ba144094ec4fb99443e5717b49c49dc9f384267a77dde905594b9fc49); /* statement */ 
zone.cancelOrders(seaportAddress, orders);
    }

    /**
     * @notice Execute an arbitrary number of matched orders on a given zone.
     *
     * @param pausableZoneAddress The zone that manages the orders
     * to be cancelled.
     * @param seaportAddress      The Seaport address.
     * @param orders              The orders to match.
     * @param fulfillments        An array of elements allocating offer
     *                            components to consideration components.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders.
     */
    function executeMatchOrders(
        address pausableZoneAddress,
        SeaportInterface seaportAddress,
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments
    ) external payable override returns (Execution[] memory executions) {c_0x889211a1(0x7b45390e5c40c0fd2721d3ec8930c4f375d664d1ecc7b0326549d6bb6ff21fb6); /* function */ 

        // Ensure the caller is the owner.
c_0x889211a1(0x53c32fecd3dad159903c224a137fefdbfc3765b021bc276a3d05dd3ade59ba99); /* line */ 
        c_0x889211a1(0x83df012f83073cb754429093d83f006cc75173b6ed81c836600e9ff1c6f03abc); /* statement */ 
if (msg.sender != _owner) {c_0x889211a1(0xee325266239612f3e2285e073dc4a0f82c210a0cec22446285b29bc1d1d14ae4); /* branch */ 

c_0x889211a1(0x2b8b9be1685bad9411beb66860371471861f064633fe3d4bc03b3dbcdb4d914e); /* line */ 
            revert CallerIsNotOwner();
        }else { c_0x889211a1(0x5e065a0ffd58fd30a0d3bca47ccebc1ba67a7453ebb2613cde0f72af92f125c3); /* branch */ 
}

        // Create a zone object from the zone address.
c_0x889211a1(0xf30c92c406b2f04f0dabb4585cd3503b335f869716d635ed8e786b5971bd27ab); /* line */ 
        c_0x889211a1(0x015929800957a50d4a7451a09638c42c9093ba87225dc8e8b8c52bf3a528b2f0); /* statement */ 
PausableZone zone = PausableZone(pausableZoneAddress);

        // Call executeMatchOrders on the given zone and return the sequence
        // of transfers performed as part of matching the given orders.
c_0x889211a1(0x176efb3640b5f28f317763bbf562676a12c1016bd10d2c50586cc9096e52c1ea); /* line */ 
        c_0x889211a1(0x774cb708b4fc5189524d1b51c9043f9143d46781de17c9590c24cb2293960001); /* statement */ 
executions = zone.executeMatchOrders{ value: msg.value }(
            seaportAddress,
            orders,
            fulfillments
        );
    }

    /**
     * @notice Execute an arbitrary number of matched advanced orders on a given
     *         zone.
     *
     * @param pausableZoneAddress The zone that manages the orders to be
     *                            cancelled.
     * @param seaportAddress      The Seaport address.
     * @param orders              The orders to match.
     * @param criteriaResolvers   An array where each element contains a
     *                            reference to a specific order as well as that
     *                            order's offer or consideration, a token
     *                            identifier, and a proof that the supplied
     *                            token identifier is contained in the
     *                            order's merkle root.
     * @param fulfillments        An array of elements allocating offer
     *                            components to consideration components.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders.
     */
    function executeMatchAdvancedOrders(
        address pausableZoneAddress,
        SeaportInterface seaportAddress,
        AdvancedOrder[] calldata orders,
        CriteriaResolver[] calldata criteriaResolvers,
        Fulfillment[] calldata fulfillments
    ) external payable override returns (Execution[] memory executions) {c_0x889211a1(0xf2e820d6869496df52b577b541c1a6f0def0a14887e37778be1cf484dfe68787); /* function */ 

        // Ensure the caller is the owner.
c_0x889211a1(0xd94a9672033dded69f34975cfcae051e70357dc24cd9fb6baa2ad62759273d3d); /* line */ 
        c_0x889211a1(0x37beb2687838b5b58c964bb0f95465c297cfc68f5ba5f163024326cc476c581d); /* statement */ 
if (msg.sender != _owner) {c_0x889211a1(0xf5955a04b400c3831386582478f620772de3fcea536c425ceeec76580b0ee3c8); /* branch */ 

c_0x889211a1(0x6c1949d3fccfabcfd72e63e1cbf4cfe53dc65803e205ffe76d8d356c863ba97e); /* line */ 
            revert CallerIsNotOwner();
        }else { c_0x889211a1(0x5e6ab7cca5bdbce44fa2da97ac6145a2ef9c432640ab98aa6b5d133237767bdb); /* branch */ 
}

        // Create a zone object from the zone address.
c_0x889211a1(0xb7545dfd0ae642ea4a1d2bd4e40ed85606b34e52360e9741ac66dfc0f8b887ea); /* line */ 
        c_0x889211a1(0x2762df640345bc6c3a99f05b9d2c93efdeff03c5556167d661c4e2eca7f49cee); /* statement */ 
PausableZone zone = PausableZone(pausableZoneAddress);

        // Call executeMatchOrders on the given zone and return the sequence
        // of transfers performed as part of matching the given orders.
c_0x889211a1(0x0c98e7d53381325fb5e6eb59c0ac5e5ef463cdc52245f91fad20d8464ac0c183); /* line */ 
        c_0x889211a1(0xb50cdd2c4c9e29570a96b0456e7b3ea38e662085602aac8966325e61e0cce90e); /* statement */ 
executions = zone.executeMatchAdvancedOrders{ value: msg.value }(
            seaportAddress,
            orders,
            criteriaResolvers,
            fulfillments
        );
    }

    /**
     * @notice Initiate Zone ownership transfer by assigning a new potential
     *         owner this contract. Once set, the new potential owner
     *         may call `acceptOwnership` to claim ownership.
     *         Only the owner in question may call this function.
     *
     * @param newPotentialOwner The address for which to initiate ownership
     *                          transfer to.
     */
    function transferOwnership(address newPotentialOwner) external override {c_0x889211a1(0xdc2fb622284f0681d8375fabccb1e0cb1b54355e8d702411aef260525d27e5e8); /* function */ 

        // Ensure the caller is the owner.
c_0x889211a1(0x268fa9c56a3975a10089ef46d551edaec780c13fd9e0e8e8d2f16fda1284e516); /* line */ 
        c_0x889211a1(0x95ff91b4ee9853029288ccc3cbacd38082f0e95084d84fce2d36e9e48cf1024f); /* statement */ 
if (msg.sender != _owner) {c_0x889211a1(0x50c4496a417992c6f531a745e6817191a2bdfd103bfd4a4074fc13c19b7bacea); /* branch */ 

c_0x889211a1(0x78fff2859be4229826f5c7d2970bdeeb50111b5fa17f417543409852a54876ee); /* line */ 
            revert CallerIsNotOwner();
        }else { c_0x889211a1(0xe2052a4a59dfc8665f67e3f3b6d905b20a214402bfcabee9e2401a93f07ce0a4); /* branch */ 
}
        // Ensure the new potential owner is not an invalid address.
c_0x889211a1(0x576b3060124e445c1316e87cedf677fdb9fa72d7ee65f6aa2af57df2d8c24b82); /* line */ 
        c_0x889211a1(0xdd19b61bb736968afffc6266e9ee0f89fe0d9aa78c5d57b09efe4869dec245bb); /* statement */ 
if (newPotentialOwner == address(0)) {c_0x889211a1(0x910988460dd530d417c797610764cec697309df16270d95b04d50fd65033fcf2); /* branch */ 

c_0x889211a1(0x047c80cc47bd14aa2b53d3b0ae8634046632b89faefb9769efa985071553d81c); /* line */ 
            revert OwnerCanNotBeSetAsZero();
        }else { c_0x889211a1(0x52ba5f2719dfea3bf10909f6e1c91733604d9c2ee57634b0b2b3179f0641eacf); /* branch */ 
}

        // Emit an event indicating that the potential owner has been updated.
c_0x889211a1(0x03857eee569300cbaabad7d6c7eb826a70d9f8f2021fb89598ef00bcaf4aa9a9); /* line */ 
        c_0x889211a1(0x43169941f0352aa5d048f8380a2d76c261fc05fd23adc95fcf69534bc619ee64); /* statement */ 
emit PotentialOwnerUpdated(newPotentialOwner);

        // Set the new potential owner as the potential owner.
c_0x889211a1(0x89f2ef8cb10f692cfb1dbc78291cca2a4465ced95937bfc943066d30c080bca6); /* line */ 
        c_0x889211a1(0x7ba45ff9e2367f1338f3ebd9c60314a89aabc8763ca750b2935fb8c5979af324); /* statement */ 
_potentialOwner = newPotentialOwner;
    }

    /**
     * @notice Clear the currently set potential owner, if any.
     *         Only the owner of this contract may call this function.
     */
    function cancelOwnershipTransfer() external override {c_0x889211a1(0x9bc9e7dd8b477e33128275f5c196b6db20049dd881bc2a9eab6ed69a1a1c99a4); /* function */ 

        // Ensure the caller is the current owner.
c_0x889211a1(0x1966439905cbd1772307edf52d96946e8ff90ef219d1c6d673b4ce1eae2d61e6); /* line */ 
        c_0x889211a1(0xbdaceaee8a5f8c8585c4f9d811a998696addad4e02cd0aaa1455f48844389cdb); /* statement */ 
if (msg.sender != _owner) {c_0x889211a1(0x57ac95b7b350a478b246dac8fbc057dfb108c78ea1b30ffc32ecfed08160913e); /* branch */ 

c_0x889211a1(0x7385a331cf5d4cc40e0d448f49015cedf8a8204413c479f5c70104dd28b40fbb); /* line */ 
            revert CallerIsNotOwner();
        }else { c_0x889211a1(0xdcda59a0e46b45d2a84830fca2e861ee7f376e8adcac73cf5e33962b24938535); /* branch */ 
}

        // Emit an event indicating that the potential owner has been cleared.
c_0x889211a1(0x4bfdc13a0e335a2145216ae857a081f768a3a345433cc621027de5082b92cd4b); /* line */ 
        c_0x889211a1(0x08c744f8af410a86b58f5fa6bcff5ae5384df1c075de1926ceb0a252b5de4c53); /* statement */ 
emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner.
c_0x889211a1(0x18da8fac4ca23ec23afe4bf3d5ce444ff3492b8518cfb0844ed5d3c8066be54a); /* line */ 
        delete _potentialOwner;
    }

    /**
     * @notice Accept ownership of this contract. Only the account that the
     *         current owner has set as the new potential owner may call this
     *         function.
     */
    function acceptOwnership() external override {c_0x889211a1(0xf2980f96be9083578978901f94a8361ef85c198afbb72d61eb13d72e2804bf5a); /* function */ 

        // Ensure the caller is the potential owner.
c_0x889211a1(0x799f5ec00e1a5bad0022c9b165635c34227ca4a06efdcde219c742e0e940d118); /* line */ 
        c_0x889211a1(0x7ad3ab80786839b2c0d1a263ba061fc5c266e437257ae7595389aa53d1bbdbf4); /* statement */ 
if (msg.sender != _potentialOwner) {c_0x889211a1(0x13e2bf4e226cf478d03535b280acfef371efe63ab9beee85aa9468fcfe9c5656); /* branch */ 

c_0x889211a1(0xc2202db3de71230a7a4f1cf869dbfed6d2a1f38c5837e0fc9ba41f31d4813a33); /* line */ 
            revert CallerIsNotPotentialOwner();
        }else { c_0x889211a1(0xbbc845b7c7950f50d616228a1b196bc16dcec6e0fda7eaee7ad2530075aeb9dd); /* branch */ 
}

        // Emit an event indicating that the potential owner has been cleared.
c_0x889211a1(0x11e5a11976afa49c8ed59af0186e2915d039ebf9c16a4c6b6fb7050c130e3e94); /* line */ 
        c_0x889211a1(0x07da2b03608fbe83377c8410cce32a1c6c472fa1c0c05ca4141c013177adaebb); /* statement */ 
emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner
c_0x889211a1(0x71e1b503bb517bb1238acd8b2d9e4ac3371bfa650bb30fe91dbb91af843f121e); /* line */ 
        delete _potentialOwner;

        // Emit an event indicating ownership has been transferred.
c_0x889211a1(0xbe6ffb58b1101a61a8b35fa80c1ff70c730d733d3971f227a5a2761729d725f7); /* line */ 
        c_0x889211a1(0xc04a34d4cce3c0fae96823637489e42b362ef8b5e0921bb1e84d60f4bfad34cd); /* statement */ 
emit OwnershipTransferred(_owner, msg.sender);

        // Set the caller as the owner of this contract.
c_0x889211a1(0x1219d3dd78c81d7621d040fd81c4933a6a0d70d79e719c2131690351f105a1ba); /* line */ 
        c_0x889211a1(0x9a2739cf4b31066c45a3317282c8af100d75844088e2239369e0273f5384018e); /* statement */ 
_owner = msg.sender;
    }

    /**
     * @notice Assign the given address with the ability to pause the zone.
     *
     * @param pauserToAssign The address to assign the pauser role.
     */
    function assignPauser(address pauserToAssign) external override {c_0x889211a1(0xbb47777603480f78ff761c4a7adb008dcad757e3b1567bb333ae86199b980f62); /* function */ 

        // Ensure the caller is the owner.
c_0x889211a1(0x3afd0235aebe5b2809ddf45c44360b8b0c2d9518e19df8ea55e6306c10684fcf); /* line */ 
        c_0x889211a1(0xea54f5b28418fdfc6baa97f23951854aafc3dd710d27cf05eceeb67ea11c9136); /* statement */ 
if (msg.sender != _owner) {c_0x889211a1(0xc1d3bb0c7a495693f1dac32373a5e91ec51e4274f074bed2dc7a0548458a4349); /* branch */ 

c_0x889211a1(0xea81447c1f6611b75bf9c34098e1e75ae47e73a70943fd8fcbf35ea001094a07); /* line */ 
            revert CallerIsNotOwner();
        }else { c_0x889211a1(0x3d8ee2229930d07a4eb0960da9b6d9842f0f61ec7c85617bce4d244ba79c5725); /* branch */ 
}
        // Ensure the pauser to assign is not an invalid address.
c_0x889211a1(0xd28fbb9e74eab8e0a58e3035f971d94602c2b720771b2ae82e320b26868427e9); /* line */ 
        c_0x889211a1(0x59f751423bae2d7ecdff9d9b623e1ff6ae02d62ce6675b3cf4327702b37e2de2); /* statement */ 
if (pauserToAssign == address(0)) {c_0x889211a1(0x4329176180654e84b73e3bb027146bd4d0698249af2a07c53e08d7bdf4fa39f8); /* branch */ 

c_0x889211a1(0x122c43f7bf2f1a3ab375e5a6c4960011255fde56d2b604c48ff2c76d61880572); /* line */ 
            revert PauserCanNotBeSetAsZero();
        }else { c_0x889211a1(0x623b6be337b59dd436a322dc1fef7a09b49338cff5592358e440e160a9005def); /* branch */ 
}

        // Set the given account as the pauser.
c_0x889211a1(0x8e60d1bd0adb4026e5be02ad374b3c69e6e4da79045bb320773cfbf01c53f2dc); /* line */ 
        c_0x889211a1(0x4e282d8a4b1bdbd14d1c033dd34d9809c678c91c484e9705be793a4ee8d588ae); /* statement */ 
_pauser = pauserToAssign;

        // Emit an event indicating the pauser has been assigned.
c_0x889211a1(0x7c8ddecd5b6c9ba9af26db0c5a3141868d53e1908375085d442a1aeb37ccb0b1); /* line */ 
        c_0x889211a1(0x86aa348250372602ddb530bc631b34e6947cdf758135201f79f020f3ebd7ea6c); /* statement */ 
emit PauserUpdated(_pauser);
    }

    /**
     * @notice Assign the given address with the ability to operate the
     *         given zone.
     *
     * @param pausableZoneAddress The zone address to assign operator role.
     * @param operatorToAssign    The address to assign as operator.
     */
    function assignOperator(
        address pausableZoneAddress,
        address operatorToAssign
    ) external override {c_0x889211a1(0x70b7e2c5a3ebf69b8c37212cbb2da76c1899761b7b472b6526192eb74e044209); /* function */ 

        // Ensure the caller is the owner.
c_0x889211a1(0x3576444b5c90e8ed9ed8128ca56712e51d92ce44a79cfb692477df877df77bfe); /* line */ 
        c_0x889211a1(0x169472169e2421243401cbd9a69e8e0bec94593e330d895c2176090ae5a3d3b5); /* statement */ 
if (msg.sender != _owner) {c_0x889211a1(0xe3dc820f81ed2126a1b08e4dc2e790f000f7d3093b44ba19a8ea736268dc3e1c); /* branch */ 

c_0x889211a1(0xf8663d1d0f3cefafe453809c8a6556d982e639fad99ef5b322a9dfe53812efdd); /* line */ 
            revert CallerIsNotOwner();
        }else { c_0x889211a1(0x328c3c0b01af3655a1f9669a2d3762222139b82554a67776f6b2f9cf764680ff); /* branch */ 
}
        // Create a zone object from the zone address.
c_0x889211a1(0xa5a26768c45f33d8a8ef4dbc4e1ba0bdaf957973e269e1969a66d2b44c75d040); /* line */ 
        c_0x889211a1(0x54d71350a40b5d425b2e11829268aa123cf3c2e6b9737a1327d0706eb6afa5cf); /* statement */ 
PausableZone zone = PausableZone(pausableZoneAddress);

        // Call assignOperator on the zone by passing in the given
        // operator address.
c_0x889211a1(0xa6c1c9ac7e1ba60adf5c36f34cf7d9f83b64f2a3669d666e564d251853036c99); /* line */ 
        c_0x889211a1(0x0d792691251fab2c53789c238aefef0bdc3defb0c32bd12333b3e256a83e242c); /* statement */ 
zone.assignOperator(operatorToAssign);
    }

    /**
     * @notice An external view function that returns the owner.
     *
     * @return The address of the owner.
     */
    function owner() external view override returns (address) {c_0x889211a1(0x24814311428756b6d101a6e181b6a0aff4eb3c723de42c11d6a19161b006a606); /* function */ 

c_0x889211a1(0xbc4092a76fc8576fb3ff0567ffeb9fe63f1850936b8d9dbcd1bee9aa50f15bef); /* line */ 
        c_0x889211a1(0xe5ce0dd89e1c8d900acd1d9aa9956ea1d7de8dd647720bf9a07bb8c3de8028c7); /* statement */ 
return _owner;
    }

    /**
     * @notice An external view function that return the potential owner.
     *
     * @return The address of the potential owner.
     */
    function potentialOwner() external view override returns (address) {c_0x889211a1(0x8e52d6b90c54b30295414d144678e71cfacaddb7c0cc686410a36a5704ec24b0); /* function */ 

c_0x889211a1(0x89f6daa91d598df3710f970cc21b83332685eed32d5ae6df7f4dbc48410ec080); /* line */ 
        c_0x889211a1(0x0b2b105eea6e7cccc56a2adf71463e134cb4bfb85fca595fb472c5356ced3b18); /* statement */ 
return _potentialOwner;
    }

    /**
     * @notice An external view function that returns the pauser.
     *
     * @return The address of the pauser.
     */
    function pauser() external view override returns (address) {c_0x889211a1(0xf2195bba9d7f86e7cc98bcb923924652c3210393c74027421855fb98732c3b51); /* function */ 

c_0x889211a1(0xc5aaa55e9af40053d715e3a667fc057f062f930dbbde292bf75405cd23e88bbf); /* line */ 
        c_0x889211a1(0x77ac13e339134cdd1d12e3f9f9cbfbd9115bfd4e55cf1e6752bf52127091408a); /* statement */ 
return _pauser;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0x95bcb44e(bytes32 c__0x95bcb44e) pure {}


import { ZoneInterface } from "../interfaces/ZoneInterface.sol";
import { ZoneInteractionErrors } from "../interfaces/ZoneInteractionErrors.sol";

import {
    PausableZoneEventsAndErrors
} from "./interfaces/PausableZoneEventsAndErrors.sol";

import { SeaportInterface } from "../interfaces/SeaportInterface.sol";

import {
    AdvancedOrder,
    CriteriaResolver,
    Order,
    OrderComponents,
    Fulfillment,
    Execution
} from "../lib/ConsiderationStructs.sol";

import { PausableZoneInterface } from "./interfaces/PausableZoneInterface.sol";

/**
 * @title  PausableZone
 * @author cupOJoseph, BCLeFevre, ryanio
 * @notice PausableZone is a simple zone implementation that approves every
 *         order. It can be self-destructed by its controller to pause
 *         restricted orders that have it set as their zone.
 */
contract PausableZone is
    PausableZoneEventsAndErrors,
    ZoneInterface,
    PausableZoneInterface
{
function c_0xaa9fbec0(bytes32 c__0xaa9fbec0) internal pure {}

    // Set an immutable controller that can pause the zone & update an operator.
    address internal immutable _controller;

    // Set an operator that can instruct the zone to cancel or execute orders.
    address public operator;

    /**
     * @dev Ensure that the caller is either the operator or controller.
     */
    modifier isOperator() {c_0xaa9fbec0(0x79d49cabf207a951940205b30c1ecca7bbc3bd574cf6c6ccea9ed28e5d1f1a4b); /* function */ 

        // Ensure that the caller is either the operator or the controller.
c_0xaa9fbec0(0x9a171b7a1d71c7c263863c4cd68332327f17a4800634e7f9116e3b9db38358a1); /* line */ 
        c_0xaa9fbec0(0x8bd31ecdc6533fa6ce643290e662545999c0c4836327b8ffcc98911ab5c15441); /* statement */ 
if (msg.sender != operator && msg.sender != _controller) {c_0xaa9fbec0(0x5228a1ac0ffd12deee917048853fa19f610a499e40264cf97d303d978cb3e96b); /* branch */ 

c_0xaa9fbec0(0x4f403d9f1d7b91d4f31be044d52bd5bf871a985c545ad10a926d831d97f2b720); /* line */ 
            revert InvalidOperator();
        }else { c_0xaa9fbec0(0xbb38720fd065f8d60f8ed63f4db641bbf7a4aedd447b3f31ea8f1d87526ab767); /* branch */ 
}

        // Continue with function execution.
c_0xaa9fbec0(0x124a9ca0bd31f23e24b430e4d2e9de17ba2bafa25926f7977a1b6caa0a35ab66); /* line */ 
        _;
    }

    /**
     * @dev Ensure that the caller is the controller.
     */
    modifier isController() {c_0xaa9fbec0(0xc8ede8b1d37a0d61f3908358e35bcbbab25739fb3561b2e069350b8a0a972110); /* function */ 

        // Ensure that the caller is the controller.
c_0xaa9fbec0(0xb380aebc09fdb9c5234295dd5f3d67a548c009a4be46ba9a0973efb5d8afb15f); /* line */ 
        c_0xaa9fbec0(0xb4a86a2abec152578fa77e875717648657a3d81395e8e3c8f072142e16751d3e); /* statement */ 
if (msg.sender != _controller) {c_0xaa9fbec0(0x5ee6b9da17c5a059d4c7e078024313bc07a310398fb9a0d51f01778ea7f6d86a); /* branch */ 

c_0xaa9fbec0(0x77243a6d81f983c6768910abebdd516dd0dc4269047ac28e88714544a9818cc0); /* line */ 
            revert InvalidController();
        }else { c_0xaa9fbec0(0x92bd03bc76bcf990d20a097545be56e9e6289af006a3dcd71c5429bfd463850a); /* branch */ 
}

        // Continue with function execution.
c_0xaa9fbec0(0x8e24e9970e656c5e61cb12df3f3eaaba6a5fb9703a73486f0cd441a3a5bbef77); /* line */ 
        _;
    }

    /**
     * @notice Set the deployer as the controller of the zone.
     */
    constructor() {c_0xaa9fbec0(0x5fe8d45ab858d271bb093a94503700588f84b732f2173210798abef874d91bb6); /* function */ 

        // Set the controller to the deployer.
c_0xaa9fbec0(0x6619432a7859d6fc7eafa3e4df07821fa3356e12b1ea55ef3a705c8fa181e2ad); /* line */ 
        c_0xaa9fbec0(0x32461c2de06665fef795cf32b6a208069f13a01fc850fb74160fe781046792bb); /* statement */ 
_controller = msg.sender;

        // Emit an event signifying that the zone is unpaused.
c_0xaa9fbec0(0xfc0d67648aa39f54d63130e7eecac39c5569d858efbe05e1270ba85dec2ff0a5); /* line */ 
        c_0xaa9fbec0(0x8bf79ba405796f5ec4658a77e511181a9121eb35ff16b701ade129c5345bac33); /* statement */ 
emit Unpaused();
    }

    /**
     * @notice Cancel an arbitrary number of orders that have agreed to use the
     *         contract as their zone.
     *
     * @param seaport  The Seaport address.
     * @param orders   The orders to cancel.
     *
     * @return cancelled A boolean indicating whether the supplied orders have
     *                   been successfully cancelled.
     */
    function cancelOrders(
        SeaportInterface seaport,
        OrderComponents[] calldata orders
    ) external override isOperator returns (bool cancelled) {c_0xaa9fbec0(0x51af1cd51da5f17904eb1b67d99d6fe255e18915a80e516aaeff840904a06810); /* function */ 

        // Call cancel on Seaport and return its boolean value.
c_0xaa9fbec0(0x12f8df186ba1525513d9819f68b6b211c481a4b4ad621560b323a3a310418bb3); /* line */ 
        c_0xaa9fbec0(0x98848802745e656a696231f5289ea1cb97e79fbb582731f782d67ada41a8c90e); /* statement */ 
cancelled = seaport.cancel(orders);
    }

    /**
     * @notice Pause this contract, safely stopping orders from using
     *         the contract as a zone. Restricted orders with this address as a
     *         zone will not be fulfillable unless the zone is redeployed to the
     *         same address.
     */
    function pause(address payee) external override isController {c_0xaa9fbec0(0x8f720b0b6acd7fa449338d51984614a39b610f8b8cb3d63d3a77b83b023092bb); /* function */ 

        // Emit an event signifying that the zone is paused.
c_0xaa9fbec0(0xb5995f41690931766249c568c6331a71bbe3d0117a9d0fbf7538009775cf801c); /* line */ 
        c_0xaa9fbec0(0x826601724bebfc9031c3ccdbea45bbe780a751d49e41118b06be222f438a5d29); /* statement */ 
emit Paused();

        // Destroy the zone, sending any ether to the transaction submitter.
c_0xaa9fbec0(0x275e6a2fc23318b44f2d1242571481ab508bc71035c894dc41a29e8c31b6c2bd); /* line */ 
        c_0xaa9fbec0(0x2e4fc47abf1de9a5ba3b760a27b46da626ec1927334a794ff5453b0197504600); /* statement */ 
selfdestruct(payable(payee));
    }

    /**
     * @notice Assign the given address with the ability to operate the zone.
     *
     * @param operatorToAssign The address to assign as the operator.
     */
    function assignOperator(address operatorToAssign)
        external
        override
        isController
    {c_0xaa9fbec0(0xda6cd501e3ec82b1f44b3660759f8434a798cc8cac0e838335c4d7868defcfff); /* function */ 

        // Ensure the operator being assigned is not the null address.
c_0xaa9fbec0(0xc976a3c4e57ec277eeb927c60c8ca1f783ac3980674cea47bb1b74a68834bc42); /* line */ 
        c_0xaa9fbec0(0xeae7b6c114430744c2cb394ac872ceaf6ebf789208fdb09969c13598441ba7bb); /* statement */ 
if (operatorToAssign == address(0)) {c_0xaa9fbec0(0x0841458b84f0cb5764a8b64ca12dbf9ce0f9a0e20b2f0dc0ad733153b9b02bf0); /* branch */ 

c_0xaa9fbec0(0xbf7092b53241a266e513b28ead8579e5cc0aae017ff2f152859b70bd67ac4283); /* line */ 
            revert PauserCanNotBeSetAsZero();
        }else { c_0xaa9fbec0(0xde64ba970bf9f8aa46fc99fe9ddac23b0d5f7f3a3d09f55727287480f87f4f99); /* branch */ 
}

        // Set the given address as the new operator.
c_0xaa9fbec0(0x4aa2649b02ef6f0bed5cd5e0c4e9c29982e381720a4deb98aada8fafd1dbabd7); /* line */ 
        c_0xaa9fbec0(0x9ed3f464ea8ce0a40a9d1e5e35ef011901785da701c307110e004843e4a0e698); /* statement */ 
operator = operatorToAssign;

        // Emit an event indicating the operator has been updated.
c_0xaa9fbec0(0xc7d686c89df79e961d6d900d249509c9a66192d1c16c5a77ae841fb4c15cfd6b); /* line */ 
        c_0xaa9fbec0(0x71415fd1e4490e9f57c40d528433117d87e27120a4f68aa9c954652aac49f06a); /* statement */ 
emit OperatorUpdated(operator);
    }

    /**
     * @notice Execute an arbitrary number of matched orders, each with
     *         an arbitrary number of items for offer and consideration
     *         along with a set of fulfillments allocating offer components
     *         to consideration components.
     *
     * @param seaport      The Seaport address.
     * @param orders       The orders to match.
     * @param fulfillments An array of elements allocating offer components
     *                     to consideration components.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders.
     */
    function executeMatchOrders(
        SeaportInterface seaport,
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments
    )
        external
        payable
        override
        isOperator
        returns (Execution[] memory executions)
    {c_0xaa9fbec0(0x809ea7474c94d4b17d928bae19d3c7657f0f65d523686b1d5f47793d2ee0d933); /* function */ 

        // Call matchOrders on Seaport and return the sequence of transfers
        // performed as part of matching the given orders.
c_0xaa9fbec0(0x2bc0a85f1f550c7c1366e91f0adc5da13df2e36fdc8508c41bb58a8ef43b4892); /* line */ 
        c_0xaa9fbec0(0xeadc36cd5e1042e21f5282074c9fdaa04c7bc4fab142f148b8546cf09f114dd2); /* statement */ 
executions = seaport.matchOrders{ value: msg.value }(
            orders,
            fulfillments
        );
    }

    /**
     * @notice Execute an arbitrary number of matched advanced orders,
     *         each with an arbitrary number of items for offer and
     *         consideration along with a set of fulfillments allocating
     *         offer components to consideration components.
     *
     * @param seaport           The Seaport address.
     * @param orders            The orders to match.
     * @param criteriaResolvers An array where each element contains a reference
     *                          to a specific order as well as that order's
     *                          offer or consideration, a token identifier, and
     *                          a proof that the supplied token identifier is
     *                          contained in the order's merkle root.
     * @param fulfillments      An array of elements allocating offer components
     *                          to consideration components.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders.
     */
    function executeMatchAdvancedOrders(
        SeaportInterface seaport,
        AdvancedOrder[] calldata orders,
        CriteriaResolver[] calldata criteriaResolvers,
        Fulfillment[] calldata fulfillments
    )
        external
        payable
        override
        isOperator
        returns (Execution[] memory executions)
    {c_0xaa9fbec0(0x99ef15451d5497a6c22df4ea19ca655540f0da4ae597fd4d568ade715aff15c6); /* function */ 

        // Call matchAdvancedOrders on Seaport and return the sequence of
        // transfers performed as part of matching the given orders.
c_0xaa9fbec0(0x1cb437e46090d6cf4c0642fbc98d31701ae388c220482def58a47a860b52a60f); /* line */ 
        c_0xaa9fbec0(0xe77cfa942a1647aab2e9ab9600221aa764f59b4cfb346c8830b3f5a14cb42c61); /* statement */ 
executions = seaport.matchAdvancedOrders{ value: msg.value }(
            orders,
            criteriaResolvers,
            fulfillments
        );
    }

    /**
     * @notice Check if a given order is currently valid.
     *
     * @dev This function is called by Seaport whenever extraData is not
     *      provided by the caller.
     *
     * @param orderHash The hash of the order.
     * @param caller    The caller in question.
     * @param offerer   The offerer in question.
     * @param zoneHash  The hash to provide upon calling the zone.
     *
     * @return validOrderMagicValue A magic value indicating if the order is
     *                              currently valid.
     */
    function isValidOrder(
        bytes32 orderHash,
        address caller,
        address offerer,
        bytes32 zoneHash
    ) external pure override returns (bytes4 validOrderMagicValue) {c_0xaa9fbec0(0x39d101a059bd5568c9451be2c117911fd3a751916375677a1e4fbf5fe457b245); /* function */ 

c_0xaa9fbec0(0x06302f907f9eb3ef4720ef56941c7fef9b13f4cd06ed165ffc2cb25994d876d9); /* line */ 
        orderHash;
c_0xaa9fbec0(0x5c57e9bf4aa68c5a3be7cb1236ac4f8be32d09db1e436964aa7d51fb89c463d7); /* line */ 
        caller;
c_0xaa9fbec0(0x905a33c9c3820690adae32f1bc301a80401a9bc0908bf2217a4b52a35ea629f0); /* line */ 
        offerer;
c_0xaa9fbec0(0xfaa846fcbaf08ea4970064347866bcd4d915b0298001c710d4dc6a523b130844); /* line */ 
        zoneHash;

        // Return the selector of isValidOrder as the magic value.
c_0xaa9fbec0(0xda9b0440891bcf250482aa942964c72a347f797dd0985b846172dfb9941fc492); /* line */ 
        c_0xaa9fbec0(0x767d3ab36805cc26f19bcf446a98e19ce1c2f3cc32d0608bb3faaca761d832d7); /* statement */ 
validOrderMagicValue = ZoneInterface.isValidOrder.selector;
    }

    /**
     * @notice Check if a given order including extraData is currently valid.
     *
     * @dev This function is called by Seaport whenever any extraData is
     *      provided by the caller.
     *
     * @param orderHash         The hash of the order.
     * @param caller            The caller in question.
     * @param order             The order in question.
     * @param priorOrderHashes  The order hashes of each order supplied prior to
     *                          the current order as part of a "match" variety
     *                          of order fulfillment.
     * @param criteriaResolvers The criteria resolvers corresponding to
     *                          the order.
     *
     * @return validOrderMagicValue A magic value indicating if the order is
     *                              currently valid.
     */
    function isValidOrderIncludingExtraData(
        bytes32 orderHash,
        address caller,
        AdvancedOrder calldata order,
        bytes32[] calldata priorOrderHashes,
        CriteriaResolver[] calldata criteriaResolvers
    ) external pure override returns (bytes4 validOrderMagicValue) {c_0xaa9fbec0(0x31d4a47a2a98d4d0311b0dead616fee2ee50208aca1e9cac4955ba8cd861e3fa); /* function */ 

c_0xaa9fbec0(0xd74f447f885f2c71e4352431b62605aaada153c79f7934ffdb0f58d77d249ac8); /* line */ 
        orderHash;
c_0xaa9fbec0(0x841aee9619f4f1dccf461319ac1a7da387888ec670f86ab66fc253d416708f55); /* line */ 
        caller;
c_0xaa9fbec0(0x75652587d60325b8d0cbc3e4a7cde2a69fdc2092a1fe268c94adc211460fa4e1); /* line */ 
        order;
c_0xaa9fbec0(0x9966c19591fc10ff511521f089c66937d53fa4bd9cdf316a5ac6055a5763ad91); /* line */ 
        priorOrderHashes;
c_0xaa9fbec0(0x568d0114b01d2e843e2451942921884943a1f3be8676e09556857d4ff9b75394); /* line */ 
        criteriaResolvers;

        // Return the selector of isValidOrder as the magic value.
c_0xaa9fbec0(0x0a5e088676489a4e43b910958a1adce02c688155e06af1ca4bab6cd99adf7fbe); /* line */ 
        c_0xaa9fbec0(0xe6379495ccc5a516a9c5bfc904774a0b2f7a583cb6bca1e45392f393f455a76d); /* statement */ 
validOrderMagicValue = ZoneInterface.isValidOrder.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0xb3f55ed5(bytes32 c__0xb3f55ed5) pure {}


import { PausableZone } from "../PausableZone.sol";

import { PausableZoneEventsAndErrors } from "./PausableZoneEventsAndErrors.sol";

import {
    Order,
    Fulfillment,
    OrderComponents,
    AdvancedOrder,
    CriteriaResolver,
    Execution
} from "../../lib/ConsiderationStructs.sol";

import { SeaportInterface } from "../../interfaces/SeaportInterface.sol";

/**
 * @title  PausableZoneController
 * @author cupOJoseph, BCLeFevre, stuckinaboot
 * @notice PausableZoneController enables deploying, pausing and executing
 *         orders on PausableZones. This deployer is designed to be owned
 *         by a gnosis safe, DAO, or trusted party.
 */
interface PausableZoneControllerInterface {
    /**
     * @notice Deploy a PausableZone to a precomputed address.
     *
     * @param salt The salt to be used to derive the zone address
     *
     * @return derivedAddress The derived address for the zone.
     */
    function createZone(bytes32 salt) external returns (address derivedAddress);

    /**
     * @notice Pause orders on a given zone.
     *
     * @param zone The address of the zone to be paused.
     *
     * @return success A boolean indicating the zone has been paused.
     */
    function pause(address zone) external returns (bool success);

    /**
     * @notice Cancel Seaport offers on a given zone.
     *
     * @param pausableZoneAddress The zone that manages the orders to be
     *                            cancelled.
     * @param seaportAddress      The Seaport address.
     * @param orders              The orders to cancel.
     */
    function cancelOrders(
        address pausableZoneAddress,
        SeaportInterface seaportAddress,
        OrderComponents[] calldata orders
    ) external;

    /**
     * @notice Execute an arbitrary number of matched orders on a given zone.
     *
     * @param pausableZoneAddress The zone that manages the orders to be
     *                            cancelled.
     * @param seaportAddress      The Seaport address.
     * @param orders              The orders to match.
     * @param fulfillments        An array of elements allocating offer
     *                            components to consideration components.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders.
     */
    function executeMatchOrders(
        address pausableZoneAddress,
        SeaportInterface seaportAddress,
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments
    ) external payable returns (Execution[] memory executions);

    /**
     * @notice Execute an arbitrary number of matched advanced orders on a
     *         given zone.
     *
     * @param pausableZoneAddress The zone that manages the orders to be
     *                            cancelled.
     * @param seaportAddress      The Seaport address.
     * @param orders              The orders to match.
     * @param criteriaResolvers   An array where each element contains a
     *                            reference to a specific order as well as
     *                            that order's offer or consideration,
     *                            a token identifier, and a proof that
     *                            the supplied token identifier is
     *                            contained in the order's merkle root.
     * @param fulfillments        An array of elements allocating offer
     *                            components to consideration components.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders.
     */
    function executeMatchAdvancedOrders(
        address pausableZoneAddress,
        SeaportInterface seaportAddress,
        AdvancedOrder[] calldata orders,
        CriteriaResolver[] calldata criteriaResolvers,
        Fulfillment[] calldata fulfillments
    ) external payable returns (Execution[] memory executions);

    /**
     * @notice Initiate Zone ownership transfer by assigning a new potential
     *         owner this contract. Once set, the new potential owner
     *         may call `acceptOwnership` to claim ownership.
     *         Only the owner in question may call this function.
     *
     * @param newPotentialOwner The address for which to initiate ownership
     *                          transfer to.
     */
    function transferOwnership(address newPotentialOwner) external;

    /**
     * @notice Clear the currently set potential owner, if any.
     *         Only the owner of this contract may call this function.
     */
    function cancelOwnershipTransfer() external;

    /**
     * @notice Accept ownership of this contract. Only the account that the
     *         current owner has set as the new potential owner may call this
     *         function.
     */
    function acceptOwnership() external;

    /**
     * @notice Assign the given address with the ability to pause the zone.
     *
     * @param pauserToAssign The address to assign the pauser role.
     */
    function assignPauser(address pauserToAssign) external;

    /**
     * @notice Assign the given address with the ability to operate the
     *         given zone.
     *
     * @param pausableZoneAddress The zone address to assign operator role.
     * @param operatorToAssign    The address to assign as operator.
     */
    function assignOperator(
        address pausableZoneAddress,
        address operatorToAssign
    ) external;

    /**
     * @notice An external view function that returns the owner.
     *
     * @return The address of the owner.
     */
    function owner() external view returns (address);

    /**
     * @notice An external view function that return the potential owner.
     *
     * @return The address of the potential owner.
     */
    function potentialOwner() external view returns (address);

    /**
     * @notice An external view function that returns the pauser.
     *
     * @return The address of the pauser.
     */
    function pauser() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0x67d7e2b8(bytes32 c__0x67d7e2b8) pure {}


/**
 * @notice PausableZoneEventsAndErrors contains errors and events
 *         related to zone interaction.
 */
interface PausableZoneEventsAndErrors {
    /**
     * @dev Emit an event whenever a zone is successfully paused.
     */
    event Paused();

    /**
     * @dev Emit an event whenever a zone is successfully unpaused (created).
     */
    event Unpaused();

    /**
     * @dev Emit an event whenever a zone owner registers a new potential
     *      owner for that zone.
     *
     * @param newPotentialOwner The new potential owner of the zone.
     */
    event PotentialOwnerUpdated(address newPotentialOwner);

    /**
     * @dev Emit an event whenever zone ownership is transferred.
     *
     * @param previousOwner The previous owner of the zone.
     * @param newOwner      The new owner of the zone.
     */
    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev Emit an event whenever a new zone is created.
     *
     * @param zone The address of the zone.
     * @param salt The salt used to deploy the zone.
     */
    event ZoneCreated(address zone, bytes32 salt);

    /**
     * @dev Emit an event whenever a zone owner assigns a new pauser
     *
     * @param newPauser The new pausear of the zone.
     */
    event PauserUpdated(address newPauser);

    /**
     * @dev Emit an event whenever a zone owner assigns a new operator
     *
     * @param newOperator The new operator of the zone.
     */
    event OperatorUpdated(address newOperator);

    /**
     * @dev Revert with an error when attempting to pause the zone
     *      while the caller is not the owner or pauser of the zone.
     */
    error InvalidPauser();

    /**
     * @dev Revert with an error when attempting to call an operation
     *      while the caller is not the controller or operator of the zone.
     */
    error InvalidOperator();

    /**
     * @dev Revert with an error when attempting to pause the zone or update the
     *      operator while the caller is not the controller of the zone.
     */
    error InvalidController();
    /**
     * @dev Revert with an error when attempting to deploy a zone that is
     *      currently deployed.
     */
    error ZoneAlreadyExists(address zone);

    /**
     * @dev Revert with an error when the caller does not have the _owner role
     *
     */
    error CallerIsNotOwner();

    /**
     * @dev Revert with an error when the caller does not have the operator role
     *
     */
    error CallerIsNotOperator();

    /**
     * @dev Revert with an error when attempting to set the new potential owner
     *      as the 0 address.
     *
     */
    error OwnerCanNotBeSetAsZero();

    /**
     * @dev Revert with an error when attempting to set the new potential pauser
     *      as the 0 address.
     *
     */
    error PauserCanNotBeSetAsZero();

    /**
     * @dev Revert with an error when the caller does not have
     *      the potentialOwner role.
     */
    error CallerIsNotPotentialOwner();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {
    BasicOrderParameters,
    OrderComponents,
    Fulfillment,
    FulfillmentComponent,
    Execution,
    Order,
    AdvancedOrder,
    OrderStatus,
    CriteriaResolver
} from "../lib/ConsiderationStructs.sol";

/**
 * @title SeaportInterface
 * @author 0age
 * @custom:version 1.1
 * @notice Seaport is a generalized ETH/ERC20/ERC721/ERC1155 marketplace. It
 *         minimizes external calls to the greatest extent possible and provides
 *         lightweight methods for common routes as well as more flexible
 *         methods for composing advanced orders.
 *
 * @dev SeaportInterface contains all external function interfaces for Seaport.
 */
interface SeaportInterface {
    /**
     * @notice Fulfill an order offering an ERC721 token by supplying Ether (or
     *         the native token for the given chain) as consideration for the
     *         order. An arbitrary number of "additional recipients" may also be
     *         supplied which will each receive native tokens from the fulfiller
     *         as consideration.
     *
     * @param parameters Additional information on the fulfilled order. Note
     *                   that the offerer must first approve this contract (or
     *                   their preferred conduit if indicated by the order) for
     *                   their offered ERC721 token to be transferred.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillBasicOrder(BasicOrderParameters calldata parameters)
        external
        payable
        returns (bool fulfilled);

    /**
     * @notice Fulfill an order with an arbitrary number of items for offer and
     *         consideration. Note that this function does not support
     *         criteria-based orders or partial filling of orders (though
     *         filling the remainder of a partially-filled order is supported).
     *
     * @param order               The order to fulfill. Note that both the
     *                            offerer and the fulfiller must first approve
     *                            this contract (or the corresponding conduit if
     *                            indicated) to transfer any relevant tokens on
     *                            their behalf and that contracts must implement
     *                            `onERC1155Received` to receive ERC1155 tokens
     *                            as consideration.
     * @param fulfillerConduitKey A bytes32 value indicating what conduit, if
     *                            any, to source the fulfiller's token approvals
     *                            from. The zero hash signifies that no conduit
     *                            should be used, with direct approvals set on
     *                            Seaport.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillOrder(Order calldata order, bytes32 fulfillerConduitKey)
        external
        payable
        returns (bool fulfilled);

    /**
     * @notice Fill an order, fully or partially, with an arbitrary number of
     *         items for offer and consideration alongside criteria resolvers
     *         containing specific token identifiers and associated proofs.
     *
     * @param advancedOrder       The order to fulfill along with the fraction
     *                            of the order to attempt to fill. Note that
     *                            both the offerer and the fulfiller must first
     *                            approve this contract (or their preferred
     *                            conduit if indicated by the order) to transfer
     *                            any relevant tokens on their behalf and that
     *                            contracts must implement `onERC1155Received`
     *                            to receive ERC1155 tokens as consideration.
     *                            Also note that all offer and consideration
     *                            components must have no remainder after
     *                            multiplication of the respective amount with
     *                            the supplied fraction for the partial fill to
     *                            be considered valid.
     * @param criteriaResolvers   An array where each element contains a
     *                            reference to a specific offer or
     *                            consideration, a token identifier, and a proof
     *                            that the supplied token identifier is
     *                            contained in the merkle root held by the item
     *                            in question's criteria element. Note that an
     *                            empty criteria indicates that any
     *                            (transferable) token identifier on the token
     *                            in question is valid and that no associated
     *                            proof needs to be supplied.
     * @param fulfillerConduitKey A bytes32 value indicating what conduit, if
     *                            any, to source the fulfiller's token approvals
     *                            from. The zero hash signifies that no conduit
     *                            should be used, with direct approvals set on
     *                            Seaport.
     * @param recipient           The intended recipient for all received items,
     *                            with `address(0)` indicating that the caller
     *                            should receive the items.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillAdvancedOrder(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient
    ) external payable returns (bool fulfilled);

    /**
     * @notice Attempt to fill a group of orders, each with an arbitrary number
     *         of items for offer and consideration. Any order that is not
     *         currently active, has already been fully filled, or has been
     *         cancelled will be omitted. Remaining offer and consideration
     *         items will then be aggregated where possible as indicated by the
     *         supplied offer and consideration component arrays and aggregated
     *         items will be transferred to the fulfiller or to each intended
     *         recipient, respectively. Note that a failing item transfer or an
     *         issue with order formatting will cause the entire batch to fail.
     *         Note that this function does not support criteria-based orders or
     *         partial filling of orders (though filling the remainder of a
     *         partially-filled order is supported).
     *
     * @param orders                    The orders to fulfill. Note that both
     *                                  the offerer and the fulfiller must first
     *                                  approve this contract (or the
     *                                  corresponding conduit if indicated) to
     *                                  transfer any relevant tokens on their
     *                                  behalf and that contracts must implement
     *                                  `onERC1155Received` to receive ERC1155
     *                                  tokens as consideration.
     * @param offerFulfillments         An array of FulfillmentComponent arrays
     *                                  indicating which offer items to attempt
     *                                  to aggregate when preparing executions.
     * @param considerationFulfillments An array of FulfillmentComponent arrays
     *                                  indicating which consideration items to
     *                                  attempt to aggregate when preparing
     *                                  executions.
     * @param fulfillerConduitKey       A bytes32 value indicating what conduit,
     *                                  if any, to source the fulfiller's token
     *                                  approvals from. The zero hash signifies
     *                                  that no conduit should be used, with
     *                                  direct approvals set on this contract.
     * @param maximumFulfilled          The maximum number of orders to fulfill.
     *
     * @return availableOrders An array of booleans indicating if each order
     *                         with an index corresponding to the index of the
     *                         returned boolean was fulfillable or not.
     * @return executions      An array of elements indicating the sequence of
     *                         transfers performed as part of matching the given
     *                         orders.
     */
    function fulfillAvailableOrders(
        Order[] calldata orders,
        FulfillmentComponent[][] calldata offerFulfillments,
        FulfillmentComponent[][] calldata considerationFulfillments,
        bytes32 fulfillerConduitKey,
        uint256 maximumFulfilled
    )
        external
        payable
        returns (bool[] memory availableOrders, Execution[] memory executions);

    /**
     * @notice Attempt to fill a group of orders, fully or partially, with an
     *         arbitrary number of items for offer and consideration per order
     *         alongside criteria resolvers containing specific token
     *         identifiers and associated proofs. Any order that is not
     *         currently active, has already been fully filled, or has been
     *         cancelled will be omitted. Remaining offer and consideration
     *         items will then be aggregated where possible as indicated by the
     *         supplied offer and consideration component arrays and aggregated
     *         items will be transferred to the fulfiller or to each intended
     *         recipient, respectively. Note that a failing item transfer or an
     *         issue with order formatting will cause the entire batch to fail.
     *
     * @param advancedOrders            The orders to fulfill along with the
     *                                  fraction of those orders to attempt to
     *                                  fill. Note that both the offerer and the
     *                                  fulfiller must first approve this
     *                                  contract (or their preferred conduit if
     *                                  indicated by the order) to transfer any
     *                                  relevant tokens on their behalf and that
     *                                  contracts must implement
     *                                  `onERC1155Received` to enable receipt of
     *                                  ERC1155 tokens as consideration. Also
     *                                  note that all offer and consideration
     *                                  components must have no remainder after
     *                                  multiplication of the respective amount
     *                                  with the supplied fraction for an
     *                                  order's partial fill amount to be
     *                                  considered valid.
     * @param criteriaResolvers         An array where each element contains a
     *                                  reference to a specific offer or
     *                                  consideration, a token identifier, and a
     *                                  proof that the supplied token identifier
     *                                  is contained in the merkle root held by
     *                                  the item in question's criteria element.
     *                                  Note that an empty criteria indicates
     *                                  that any (transferable) token
     *                                  identifier on the token in question is
     *                                  valid and that no associated proof needs
     *                                  to be supplied.
     * @param offerFulfillments         An array of FulfillmentComponent arrays
     *                                  indicating which offer items to attempt
     *                                  to aggregate when preparing executions.
     * @param considerationFulfillments An array of FulfillmentComponent arrays
     *                                  indicating which consideration items to
     *                                  attempt to aggregate when preparing
     *                                  executions.
     * @param fulfillerConduitKey       A bytes32 value indicating what conduit,
     *                                  if any, to source the fulfiller's token
     *                                  approvals from. The zero hash signifies
     *                                  that no conduit should be used, with
     *                                  direct approvals set on this contract.
     * @param recipient                 The intended recipient for all received
     *                                  items, with `address(0)` indicating that
     *                                  the caller should receive the items.
     * @param maximumFulfilled          The maximum number of orders to fulfill.
     *
     * @return availableOrders An array of booleans indicating if each order
     *                         with an index corresponding to the index of the
     *                         returned boolean was fulfillable or not.
     * @return executions      An array of elements indicating the sequence of
     *                         transfers performed as part of matching the given
     *                         orders.
     */
    function fulfillAvailableAdvancedOrders(
        AdvancedOrder[] calldata advancedOrders,
        CriteriaResolver[] calldata criteriaResolvers,
        FulfillmentComponent[][] calldata offerFulfillments,
        FulfillmentComponent[][] calldata considerationFulfillments,
        bytes32 fulfillerConduitKey,
        address recipient,
        uint256 maximumFulfilled
    )
        external
        payable
        returns (bool[] memory availableOrders, Execution[] memory executions);

    /**
     * @notice Match an arbitrary number of orders, each with an arbitrary
     *         number of items for offer and consideration along with as set of
     *         fulfillments allocating offer components to consideration
     *         components. Note that this function does not support
     *         criteria-based or partial filling of orders (though filling the
     *         remainder of a partially-filled order is supported).
     *
     * @param orders       The orders to match. Note that both the offerer and
     *                     fulfiller on each order must first approve this
     *                     contract (or their conduit if indicated by the order)
     *                     to transfer any relevant tokens on their behalf and
     *                     each consideration recipient must implement
     *                     `onERC1155Received` to enable ERC1155 token receipt.
     * @param fulfillments An array of elements allocating offer components to
     *                     consideration components. Note that each
     *                     consideration component must be fully met for the
     *                     match operation to be valid.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders.
     */
    function matchOrders(
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments
    ) external payable returns (Execution[] memory executions);

    /**
     * @notice Match an arbitrary number of full or partial orders, each with an
     *         arbitrary number of items for offer and consideration, supplying
     *         criteria resolvers containing specific token identifiers and
     *         associated proofs as well as fulfillments allocating offer
     *         components to consideration components.
     *
     * @param orders            The advanced orders to match. Note that both the
     *                          offerer and fulfiller on each order must first
     *                          approve this contract (or a preferred conduit if
     *                          indicated by the order) to transfer any relevant
     *                          tokens on their behalf and each consideration
     *                          recipient must implement `onERC1155Received` in
     *                          order to receive ERC1155 tokens. Also note that
     *                          the offer and consideration components for each
     *                          order must have no remainder after multiplying
     *                          the respective amount with the supplied fraction
     *                          in order for the group of partial fills to be
     *                          considered valid.
     * @param criteriaResolvers An array where each element contains a reference
     *                          to a specific order as well as that order's
     *                          offer or consideration, a token identifier, and
     *                          a proof that the supplied token identifier is
     *                          contained in the order's merkle root. Note that
     *                          an empty root indicates that any (transferable)
     *                          token identifier is valid and that no associated
     *                          proof needs to be supplied.
     * @param fulfillments      An array of elements allocating offer components
     *                          to consideration components. Note that each
     *                          consideration component must be fully met in
     *                          order for the match operation to be valid.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders.
     */
    function matchAdvancedOrders(
        AdvancedOrder[] calldata orders,
        CriteriaResolver[] calldata criteriaResolvers,
        Fulfillment[] calldata fulfillments
    ) external payable returns (Execution[] memory executions);

    /**
     * @notice Cancel an arbitrary number of orders. Note that only the offerer
     *         or the zone of a given order may cancel it. Callers should ensure
     *         that the intended order was cancelled by calling `getOrderStatus`
     *         and confirming that `isCancelled` returns `true`.
     *
     * @param orders The orders to cancel.
     *
     * @return cancelled A boolean indicating whether the supplied orders have
     *                   been successfully cancelled.
     */
    function cancel(OrderComponents[] calldata orders)
        external
        returns (bool cancelled);

    /**
     * @notice Validate an arbitrary number of orders, thereby registering their
     *         signatures as valid and allowing the fulfiller to skip signature
     *         verification on fulfillment. Note that validated orders may still
     *         be unfulfillable due to invalid item amounts or other factors;
     *         callers should determine whether validated orders are fulfillable
     *         by simulating the fulfillment call prior to execution. Also note
     *         that anyone can validate a signed order, but only the offerer can
     *         validate an order without supplying a signature.
     *
     * @param orders The orders to validate.
     *
     * @return validated A boolean indicating whether the supplied orders have
     *                   been successfully validated.
     */
    function validate(Order[] calldata orders)
        external
        returns (bool validated);

    /**
     * @notice Cancel all orders from a given offerer with a given zone in bulk
     *         by incrementing a counter. Note that only the offerer may
     *         increment the counter.
     *
     * @return newCounter The new counter.
     */
    function incrementCounter() external returns (uint256 newCounter);

    /**
     * @notice Retrieve the order hash for a given order.
     *
     * @param order The components of the order.
     *
     * @return orderHash The order hash.
     */
    function getOrderHash(OrderComponents calldata order)
        external
        view
        returns (bytes32 orderHash);

    /**
     * @notice Retrieve the status of a given order by hash, including whether
     *         the order has been cancelled or validated and the fraction of the
     *         order that has been filled.
     *
     * @param orderHash The order hash in question.
     *
     * @return isValidated A boolean indicating whether the order in question
     *                     has been validated (i.e. previously approved or
     *                     partially filled).
     * @return isCancelled A boolean indicating whether the order in question
     *                     has been cancelled.
     * @return totalFilled The total portion of the order that has been filled
     *                     (i.e. the "numerator").
     * @return totalSize   The total size of the order that is either filled or
     *                     unfilled (i.e. the "denominator").
     */
    function getOrderStatus(bytes32 orderHash)
        external
        view
        returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        );

    /**
     * @notice Retrieve the current counter for a given offerer.
     *
     * @param offerer The offerer in question.
     *
     * @return counter The current counter.
     */
    function getCounter(address offerer)
        external
        view
        returns (uint256 counter);

    /**
     * @notice Retrieve configuration information for this contract.
     *
     * @return version           The contract version.
     * @return domainSeparator   The domain separator for this contract.
     * @return conduitController The conduit Controller set for this contract.
     */
    function information()
        external
        view
        returns (
            string memory version,
            bytes32 domainSeparator,
            address conduitController
        );

    /**
     * @notice Retrieve the name of this contract.
     *
     * @return contractName The name of this contract.
     */
    function name() external view returns (string memory contractName);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {
    AdvancedOrder,
    CriteriaResolver
} from "../lib/ConsiderationStructs.sol";

interface ZoneInterface {
    // Called by Consideration whenever extraData is not provided by the caller.
    function isValidOrder(
        bytes32 orderHash,
        address caller,
        address offerer,
        bytes32 zoneHash
    ) external view returns (bytes4 validOrderMagicValue);

    // Called by Consideration whenever any extraData is provided by the caller.
    function isValidOrderIncludingExtraData(
        bytes32 orderHash,
        address caller,
        AdvancedOrder calldata order,
        bytes32[] calldata priorOrderHashes,
        CriteriaResolver[] calldata criteriaResolvers
    ) external view returns (bytes4 validOrderMagicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0x455d7adc(bytes32 c__0x455d7adc) pure {}


/**
 * @title ZoneInteractionErrors
 * @author 0age
 * @notice ZoneInteractionErrors contains errors related to zone interaction.
 */
interface ZoneInteractionErrors {
    /**
     * @dev Revert with an error when attempting to fill an order that specifies
     *      a restricted submitter as its order type when not submitted by
     *      either the offerer or the order's zone or approved as valid by the
     *      zone in question via a staticcall to `isValidOrder`.
     *
     * @param orderHash The order hash for the invalid restricted order.
     */
    error InvalidRestrictedOrder(bytes32 orderHash);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0xaab8cdb6(bytes32 c__0xaab8cdb6) pure {}


import { SeaportInterface } from "../../interfaces/SeaportInterface.sol";

import {
    AdvancedOrder,
    CriteriaResolver,
    Order,
    OrderComponents,
    Fulfillment,
    Execution
} from "../../lib/ConsiderationStructs.sol";

/**
 * @title  PausableZone
 * @author cupOJoseph, BCLeFevre, ryanio
 * @notice PausableZone is a simple zone implementation that approves every
 *         order. It can be self-destructed by its controller to pause
 *         restricted orders that have it set as their zone.
 */
interface PausableZoneInterface {
    /**
     * @notice Cancel an arbitrary number of orders that have agreed to use the
     *         contract as their zone.
     *
     * @param seaport  The Seaport address.
     * @param orders   The orders to cancel.
     *
     * @return cancelled A boolean indicating whether the supplied orders have
     *                   been successfully cancelled.
     */
    function cancelOrders(
        SeaportInterface seaport,
        OrderComponents[] calldata orders
    ) external returns (bool cancelled);

    /**
     * @notice Execute an arbitrary number of matched orders, each with
     *         an arbitrary number of items for offer and consideration
     *         along with a set of fulfillments allocating offer components
     *         to consideration components.
     *
     * @param seaport      The Seaport address.
     * @param orders       The orders to match.
     * @param fulfillments An array of elements allocating offer components
     *                     to consideration components.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders.
     */
    function executeMatchOrders(
        SeaportInterface seaport,
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments
    ) external payable returns (Execution[] memory executions);

    /**
     * @notice Execute an arbitrary number of matched advanced orders,
     *         each with an arbitrary number of items for offer and
     *         consideration along with a set of fulfillments allocating
     *         offer components to consideration components.
     *
     * @param seaport           The Seaport address.
     * @param orders            The orders to match.
     * @param criteriaResolvers An array where each element contains a reference
     *                          to a specific order as well as that order's
     *                          offer or consideration, a token identifier, and
     *                          a proof that the supplied token identifier is
     *                          contained in the order's merkle root.
     * @param fulfillments      An array of elements allocating offer components
     *                          to consideration components.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders.
     */
    function executeMatchAdvancedOrders(
        SeaportInterface seaport,
        AdvancedOrder[] calldata orders,
        CriteriaResolver[] calldata criteriaResolvers,
        Fulfillment[] calldata fulfillments
    ) external payable returns (Execution[] memory executions);

    /**
     * @notice Pause this contract, safely stopping orders from using
     *         the contract as a zone. Restricted orders with this address as a
     *         zone will not be fulfillable unless the zone is redeployed to the
     *         same address.
     */
    function pause(address payee) external;

    /**
     * @notice Assign the given address with the ability to operate the zone.
     *
     * @param operatorToAssign The address to assign as the operator.
     */
    function assignOperator(address operatorToAssign) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0xb496e903(bytes32 c__0xb496e903) pure {}


import { ZoneInterface } from "../interfaces/ZoneInterface.sol";

import { OrderType } from "./ConsiderationEnums.sol";

import { AdvancedOrder, CriteriaResolver } from "./ConsiderationStructs.sol";

import "./ConsiderationConstants.sol";

import { ZoneInteractionErrors } from "../interfaces/ZoneInteractionErrors.sol";

import { LowLevelHelpers } from "./LowLevelHelpers.sol";

/**
 * @title ZoneInteraction
 * @author 0age
 * @notice ZoneInteraction contains logic related to interacting with zones.
 */
contract ZoneInteraction is ZoneInteractionErrors, LowLevelHelpers {
function c_0x92abeda9(bytes32 c__0x92abeda9) internal pure {}

    /**
     * @dev Internal view function to determine if an order has a restricted
     *      order type and, if so, to ensure that either the offerer or the zone
     *      are the fulfiller or that a staticcall to `isValidOrder` on the zone
     *      returns a magic value indicating that the order is currently valid.
     *
     * @param orderHash The hash of the order.
     * @param zoneHash  The hash to provide upon calling the zone.
     * @param orderType The type of the order.
     * @param offerer   The offerer in question.
     * @param zone      The zone in question.
     */
    function _assertRestrictedBasicOrderValidity(
        bytes32 orderHash,
        bytes32 zoneHash,
        OrderType orderType,
        address offerer,
        address zone
    ) internal view {c_0x92abeda9(0x0910d4b127096f6b0fff3e36650f2b5a64a518c7dae3a6c25f99f661ee650734); /* function */ 

        // Order type 2-3 require zone or offerer be caller or zone to approve.
c_0x92abeda9(0x384ace159edc768c00100c07756c7c92b336c77319aaf3f07daff02acb7a52d2); /* line */ 
        c_0x92abeda9(0x7890efab223f7c57d18807c9c9b9952bdeded4455aabe7b3b02863f908df5dc6); /* statement */ 
if (
            uint256(orderType) > 1 &&
            msg.sender != zone &&
            msg.sender != offerer
        ) {c_0x92abeda9(0x21fcb4f82fba002019f52d71633cee47f6c4d2d1bd80e23b6349e0854291b356); /* branch */ 

            // Perform minimal staticcall to the zone.
c_0x92abeda9(0x22f32ed1660e8c481854c95d7385316573afb05c072c24ba3f88e01005da9ec9); /* line */ 
            c_0x92abeda9(0x84047fd7825c3b2f1ccb2ae7859f00d936a73dd81e5824c16ff3b2b2fc5c4c13); /* statement */ 
_callIsValidOrder(zone, orderHash, offerer, zoneHash);
        }else { c_0x92abeda9(0x376c5d341bebfc873e9b4dc6d065fd9f40ad1c07af1f4d6f61a815f5fe9f135f); /* branch */ 
}
    }

    function _callIsValidOrder(
        address zone,
        bytes32 orderHash,
        address offerer,
        bytes32 zoneHash
    ) internal view {c_0x92abeda9(0x5e8ab36375f069f981e5f8b4a2c4656cb02be17c6f7743c7a03b4a9334aa38b9); /* function */ 

        // Perform minimal staticcall to the zone.
c_0x92abeda9(0x58259c1fd6cfa9cc38a5d41bc8fac20ae425ee6c4b7f1e88e4d99a6017f4b532); /* line */ 
        c_0x92abeda9(0x99b37be6f86b184f4b996c5b461712d06402ba0ee254591e3cea1a759c47c6a6); /* statement */ 
bool success = _staticcall(
            zone,
            abi.encodeWithSelector(
                ZoneInterface.isValidOrder.selector,
                orderHash,
                msg.sender,
                offerer,
                zoneHash
            )
        );

        // Ensure call was successful and returned the correct magic value.
c_0x92abeda9(0x54ce170d2b8499ccffc21453f4d4b2a1f54afb56f306ff8f05eeb99e4fdbf76a); /* line */ 
        c_0x92abeda9(0x2347c8212eb39afbc58d1ab3643efd1b58ae3c9d2e06fbd3262c53ba55d96c9f); /* statement */ 
_assertIsValidOrderStaticcallSuccess(success, orderHash);
    }

    /**
     * @dev Internal view function to determine whether an order is a restricted
     *      order and, if so, to ensure that it was either submitted by the
     *      offerer or the zone for the order, or that the zone returns the
     *      expected magic value upon performing a staticcall to `isValidOrder`
     *      or `isValidOrderIncludingExtraData` depending on whether the order
     *      fulfillment specifies extra data or criteria resolvers.
     *
     * @param advancedOrder     The advanced order in question.
     * @param criteriaResolvers An array where each element contains a reference
     *                          to a specific offer or consideration, a token
     *                          identifier, and a proof that the supplied token
     *                          identifier is contained in the order's merkle
     *                          root. Note that a criteria of zero indicates
     *                          that any (transferable) token identifier is
     *                          valid and that no proof needs to be supplied.
     * @param priorOrderHashes  The order hashes of each order supplied prior to
     *                          the current order as part of a "match" variety
     *                          of order fulfillment (e.g. this array will be
     *                          empty for single or "fulfill available").
     * @param orderHash         The hash of the order.
     * @param zoneHash          The hash to provide upon calling the zone.
     * @param orderType         The type of the order.
     * @param offerer           The offerer in question.
     * @param zone              The zone in question.
     */
    function _assertRestrictedAdvancedOrderValidity(
        AdvancedOrder memory advancedOrder,
        CriteriaResolver[] memory criteriaResolvers,
        bytes32[] memory priorOrderHashes,
        bytes32 orderHash,
        bytes32 zoneHash,
        OrderType orderType,
        address offerer,
        address zone
    ) internal view {c_0x92abeda9(0xf6d7a814b2bff58b3bd7ff256b288c792b6b409c3d4ef83930034431fbd9882f); /* function */ 

        // Order type 2-3 require zone or offerer be caller or zone to approve.
c_0x92abeda9(0x0d410bef3547273ce3257b0e09f672a78d72fd45a37bfb9f54b4ec27cbb74f8a); /* line */ 
        c_0x92abeda9(0x37069b40d700e1ea07b5d9fa55b447170e0ac75f9a05c4bfd47cca69a3600a9c); /* statement */ 
if (
            uint256(orderType) > 1 &&
            msg.sender != zone &&
            msg.sender != offerer
        ) {c_0x92abeda9(0xc4d539130c7a53127b2eb963c418a1d22af2e736ad0bc28f6286c7c44f4c0dc4); /* branch */ 

            // If no extraData or criteria resolvers are supplied...
c_0x92abeda9(0x88598ec4687619d52ead7cfe12db2794ec82fcdda1690978cf59cde3266c33e6); /* line */ 
            c_0x92abeda9(0x8521e31534bc6bbc9652745388070e89df2db81a2e04185a54686a4af561fa62); /* statement */ 
if (
                advancedOrder.extraData.length == 0 &&
                criteriaResolvers.length == 0
            ) {c_0x92abeda9(0x70afc357984fe4c713ea4ae07676787ae8ddf9b578cbe550f3dd88668f2b7675); /* branch */ 

                // Perform minimal staticcall to the zone.
c_0x92abeda9(0xee5955c79f4c248bf055f73ab639218bcd599991217634cef8cd3493b28f7935); /* line */ 
                c_0x92abeda9(0x482c6699a474ccf340bb424716f19598c4e6c8f2b6de9037e496738dea657274); /* statement */ 
_callIsValidOrder(zone, orderHash, offerer, zoneHash);
            } else {c_0x92abeda9(0x73c3989e52975bfc3226a6f60d4cfc9714127738eaa2b74fc5801ff63e4c9219); /* branch */ 

                // Otherwise, extra data or criteria resolvers were supplied; in
                // that event, perform a more verbose staticcall to the zone.
c_0x92abeda9(0xdb136d0d586e8850f5ddc04d453b2aca46697f9e28c04e1b2d1b03d75a8ca8e7); /* line */ 
                c_0x92abeda9(0x933fe92ca0e86eef5b81f90b46588271adf2d843d8d88ea66a7d506a43f216ce); /* statement */ 
bool success = _staticcall(
                    zone,
                    abi.encodeWithSelector(
                        ZoneInterface.isValidOrderIncludingExtraData.selector,
                        orderHash,
                        msg.sender,
                        advancedOrder,
                        priorOrderHashes,
                        criteriaResolvers
                    )
                );

                // Ensure call was successful and returned correct magic value.
c_0x92abeda9(0x70db61783d13c9bece44ee1fbcd845162e5d009253df3e10e3f8811aa236c500); /* line */ 
                c_0x92abeda9(0x577f31082f1576f750f1fbf3e28be8090392b8f0a2e76e5f1137216ea78958cf); /* statement */ 
_assertIsValidOrderStaticcallSuccess(success, orderHash);
            }
        }else { c_0x92abeda9(0x82b4cc8ad0d26e054878d43b718663aaf6355f4e3f912750945e8d1eb00f0cd1); /* branch */ 
}
    }

    /**
     * @dev Internal view function to ensure that a staticcall to `isValidOrder`
     *      or `isValidOrderIncludingExtraData` as part of validating a
     *      restricted order that was not submitted by the named offerer or zone
     *      was successful and returned the required magic value.
     *
     * @param success   A boolean indicating the status of the staticcall.
     * @param orderHash The order hash of the order in question.
     */
    function _assertIsValidOrderStaticcallSuccess(
        bool success,
        bytes32 orderHash
    ) internal view {c_0x92abeda9(0x1d94b7248f251f3f044ec026c810c8479709e0fd4da8ddb5d2c88ab3171be6ca); /* function */ 

        // If the call failed...
c_0x92abeda9(0x1c2c0cf03816581dc40f97603924d0d0454f053d178f486fe6442a31774e2d20); /* line */ 
        c_0x92abeda9(0xe42076783b98bf4800317fa3338c6734dbf4466cd9ce7bba9171df5051074493); /* statement */ 
if (!success) {c_0x92abeda9(0x2f815c429d13187f84217cb48a08813e47851181cfe83ed33fbfc42f42350e12); /* branch */ 

            // Revert and pass reason along if one was returned.
c_0x92abeda9(0xec3d1b7d51635984b497867af20dc756e358a9b4eeaebe8143953d45becd0d28); /* line */ 
            c_0x92abeda9(0xf0ebaa127bd50bec704c112896bab9f4a13f2d6523d1c14231fcb0df1748b534); /* statement */ 
_revertWithReasonIfOneIsReturned();

            // Otherwise, revert with a generic error message.
c_0x92abeda9(0x09be78ad5928a108e68f14dc3572dc82d8a427bd33d71cdfe4f175cbc7b2aa8c); /* line */ 
            revert InvalidRestrictedOrder(orderHash);
        }else { c_0x92abeda9(0x7938b5a49a70f5c3158d3df3c1eba928b3eed707c74507ba93476562e6a2bd43); /* branch */ 
}

        // Ensure result was extracted and matches isValidOrder magic value.
c_0x92abeda9(0xc81960bb94188a8feec24f96f9d002967c7eebbde0211a0f24abacd96ecf6251); /* line */ 
        c_0x92abeda9(0x1f840b2e90a8541e856399af864e3cbf07619e32f8ad3d057ffd5eabba0b53ff); /* statement */ 
if (_doesNotMatchMagic(ZoneInterface.isValidOrder.selector)) {c_0x92abeda9(0x7838673ee4a9bb45791239c33678164a8e1aa1e97330c7405bb331c45f2b2bc6); /* branch */ 

c_0x92abeda9(0x8e6519323f9425b4f4d2d461eca693f3d5ef30126d08ff3416465559c3b0333d); /* line */ 
            revert InvalidRestrictedOrder(orderHash);
        }else { c_0x92abeda9(0x44bd3e3d4bb0a4ea437c13d79ea7485f0f121be7a96e30547775779bbe5fad0d); /* branch */ 
}
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {
    ConduitControllerInterface
} from "../interfaces/ConduitControllerInterface.sol";

import { ConduitInterface } from "../interfaces/ConduitInterface.sol";

import { ConduitController } from "../conduit/ConduitController.sol";

import { ConduitMock } from "../test/ConduitMock.sol";

import { ConduitMockInvalidMagic } from "../test/ConduitMockInvalidMagic.sol";

import {
    ConduitMockRevertNoReason
} from "../test/ConduitMockRevertNoReason.sol";

import { ConduitMockRevertBytes } from "../test/ConduitMockRevertBytes.sol";

contract ConduitControllerMock is ConduitControllerInterface {
    // Register keys, owners, new potential owners, and channels by conduit.
    mapping(address => ConduitProperties) internal _conduits;

    // Set conduit creation code and runtime code hashes as immutable arguments.
    bytes32 internal immutable _CONDUIT_CREATION_CODE_HASH;
    bytes32 internal immutable _CONDUIT_RUNTIME_CODE_HASH;

    uint256 private conduitNum;

    /**
     * @dev Initialize contract by deploying a conduit and setting the creation
     *      code and runtime code hashes as immutable arguments.
     */
    constructor(uint256 _conduitNum) {
        conduitNum = _conduitNum;

        bytes32 creationCodeHash;
        bytes32 runtimeCodeHash;

        if (conduitNum == 0) {
            creationCodeHash = keccak256(type(ConduitMock).creationCode);
            ConduitMock zeroConduit = new ConduitMock{ salt: bytes32(0) }();
            runtimeCodeHash = address(zeroConduit).codehash;
        } else if (conduitNum == 1) {
            creationCodeHash = keccak256(
                type(ConduitMockRevertNoReason).creationCode
            );
            ConduitMockRevertNoReason zeroConduit = new ConduitMockRevertNoReason{
                    salt: bytes32(0)
                }();
            runtimeCodeHash = address(zeroConduit).codehash;
        } else if (conduitNum == 2) {
            creationCodeHash = keccak256(
                type(ConduitMockInvalidMagic).creationCode
            );
            ConduitMockInvalidMagic zeroConduit = new ConduitMockInvalidMagic{
                salt: bytes32(0)
            }();
            runtimeCodeHash = address(zeroConduit).codehash;
        } else if (conduitNum == 3) {
            creationCodeHash = keccak256(
                type(ConduitMockRevertBytes).creationCode
            );
            ConduitMockRevertBytes zeroConduit = new ConduitMockRevertBytes{
                salt: bytes32(0)
            }();
            runtimeCodeHash = address(zeroConduit).codehash;
        }
        _CONDUIT_CREATION_CODE_HASH = creationCodeHash;
        _CONDUIT_RUNTIME_CODE_HASH = runtimeCodeHash;
    }

    /**
     * @notice Deploy a new conduit using a supplied conduit key and assigning
     *         an initial owner for the deployed conduit. Note that the first
     *         twenty bytes of the supplied conduit key must match the caller
     *         and that a new conduit cannot be created if one has already been
     *         deployed using the same conduit key.
     *
     * @param conduitKey   The conduit key used to deploy the conduit. Note that
     *                     the first twenty bytes of the conduit key must match
     *                     the caller of this contract.
     * @param initialOwner The initial owner to set for the new conduit.
     *
     * @return conduit The address of the newly deployed conduit.
     */
    function createConduit(bytes32 conduitKey, address initialOwner)
        external
        override
        returns (address conduit)
    {
        // Ensure that an initial owner has been supplied.
        if (initialOwner == address(0)) {
            revert InvalidInitialOwner();
        }

        // If the first 20 bytes of the conduit key do not match the caller...
        if (address(uint160(bytes20(conduitKey))) != msg.sender) {
            // Revert with an error indicating that the creator is invalid.
            revert InvalidCreator();
        }

        // Derive address from deployer, conduit key and creation code hash.
        conduit = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            conduitKey,
                            _CONDUIT_CREATION_CODE_HASH
                        )
                    )
                )
            )
        );

        // If derived conduit exists, as evidenced by comparing runtime code...
        if (conduit.codehash == _CONDUIT_RUNTIME_CODE_HASH) {
            // Revert with an error indicating that the conduit already exists.
            revert ConduitAlreadyExists(conduit);
        }

        // Deploy the conduit via CREATE2 using the conduit key as the salt.
        if (conduitNum == 0) {
            new ConduitMock{ salt: conduitKey }();
        } else if (conduitNum == 1) {
            new ConduitMockRevertNoReason{ salt: conduitKey }();
        } else if (conduitNum == 2) {
            new ConduitMockInvalidMagic{ salt: conduitKey }();
        } else if (conduitNum == 3) {
            new ConduitMockRevertBytes{ salt: conduitKey }();
        }
        // Initialize storage variable referencing conduit properties.
        ConduitProperties storage conduitProperties = _conduits[conduit];

        // Set the supplied initial owner as the owner of the conduit.
        conduitProperties.owner = initialOwner;

        // Set conduit key used to deploy the conduit to enable reverse lookup.
        conduitProperties.key = conduitKey;

        // Emit an event indicating that the conduit has been deployed.
        emit NewConduit(conduit, conduitKey);

        // Emit an event indicating that conduit ownership has been assigned.
        emit OwnershipTransferred(conduit, address(0), initialOwner);
    }

    /**
     * @notice Open or close a channel on a given conduit, thereby allowing the
     *         specified account to execute transfers against that conduit.
     *         Extreme care must be taken when updating channels, as malicious
     *         or vulnerable channels can transfer any ERC20, ERC721 and ERC1155
     *         tokens where the token holder has granted the conduit approval.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to open or close the channel.
     * @param channel The channel to open or close on the conduit.
     * @param isOpen  A boolean indicating whether to open or close the channel.
     */
    function updateChannel(
        address conduit,
        address channel,
        bool isOpen
    ) external override {
        // Ensure the caller is the current owner of the conduit in question.
        _assertCallerIsConduitOwner(conduit);

        // Call the conduit, updating the channel.
        ConduitInterface(conduit).updateChannel(channel, isOpen);

        // Retrieve storage region where channels for the conduit are tracked.
        ConduitProperties storage conduitProperties = _conduits[conduit];

        // Retrieve the index, if one currently exists, for the updated channel.
        uint256 channelIndexPlusOne = (
            conduitProperties.channelIndexesPlusOne[channel]
        );

        // Determine whether the updated channel is already tracked as open.
        bool channelPreviouslyOpen = channelIndexPlusOne != 0;

        // If the channel has been set to open and was previously closed...
        if (isOpen && !channelPreviouslyOpen) {
            // Add the channel to the channels array for the conduit.
            conduitProperties.channels.push(channel);

            // Add new open channel length to associated mapping as index + 1.
            conduitProperties.channelIndexesPlusOne[channel] = (
                conduitProperties.channels.length
            );
        } else if (!isOpen && channelPreviouslyOpen) {
            // Set a previously open channel as closed via "swap & pop" method.
            // Decrement located index to get the index of the closed channel.
            uint256 removedChannelIndex;

            // Skip underflow check as channelPreviouslyOpen being true ensures
            // that channelIndexPlusOne is nonzero.
            unchecked {
                removedChannelIndex = channelIndexPlusOne - 1;
            }

            // Use length of channels array to determine index of last channel.
            uint256 finalChannelIndex = conduitProperties.channels.length - 1;

            // If closed channel is not last channel in the channels array...
            if (finalChannelIndex != removedChannelIndex) {
                // Retrieve the final channel and place the value on the stack.
                address finalChannel = (
                    conduitProperties.channels[finalChannelIndex]
                );

                // Overwrite the removed channel using the final channel value.
                conduitProperties.channels[removedChannelIndex] = finalChannel;

                // Update final index in associated mapping to removed index.
                conduitProperties.channelIndexesPlusOne[finalChannel] = (
                    channelIndexPlusOne
                );
            }

            // Remove the last channel from the channels array for the conduit.
            conduitProperties.channels.pop();

            // Remove the closed channel from associated mapping of indexes.
            delete conduitProperties.channelIndexesPlusOne[channel];
        }
    }

    /**
     * @notice Initiate conduit ownership transfer by assigning a new potential
     *         owner for the given conduit. Once set, the new potential owner
     *         may call `acceptOwnership` to claim ownership of the conduit.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to initiate ownership transfer.
     * @param newPotentialOwner The new potential owner of the conduit.
     */
    function transferOwnership(address conduit, address newPotentialOwner)
        external
        override
    {
        // Ensure the caller is the current owner of the conduit in question.
        _assertCallerIsConduitOwner(conduit);

        // Ensure the new potential owner is not an invalid address.
        if (newPotentialOwner == address(0)) {
            revert NewPotentialOwnerIsZeroAddress(conduit);
        }

        // Ensure the new potential owner is not already set.
        if (newPotentialOwner == _conduits[conduit].potentialOwner) {
            revert NewPotentialOwnerAlreadySet(conduit, newPotentialOwner);
        }

        // Emit an event indicating that the potential owner has been updated.
        emit PotentialOwnerUpdated(newPotentialOwner);

        // Set the new potential owner as the potential owner of the conduit.
        _conduits[conduit].potentialOwner = newPotentialOwner;
    }

    /**
     * @notice Clear the currently set potential owner, if any, from a conduit.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to cancel ownership transfer.
     */
    function cancelOwnershipTransfer(address conduit) external override {
        // Ensure the caller is the current owner of the conduit in question.
        _assertCallerIsConduitOwner(conduit);

        // Ensure that ownership transfer is currently possible.
        if (_conduits[conduit].potentialOwner == address(0)) {
            revert NoPotentialOwnerCurrentlySet(conduit);
        }

        // Emit an event indicating that the potential owner has been cleared.
        emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner from the conduit.
        _conduits[conduit].potentialOwner = address(0);
    }

    /**
     * @notice Accept ownership of a supplied conduit. Only accounts that the
     *         current owner has set as the new potential owner may call this
     *         function.
     *
     * @param conduit The conduit for which to accept ownership.
     */
    function acceptOwnership(address conduit) external override {
        // Ensure that the conduit in question exists.
        _assertConduitExists(conduit);

        // If caller does not match current potential owner of the conduit...
        if (msg.sender != _conduits[conduit].potentialOwner) {
            // Revert, indicating that caller is not current potential owner.
            revert CallerIsNotNewPotentialOwner(conduit);
        }

        // Emit an event indicating that the potential owner has been cleared.
        emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner from the conduit.
        _conduits[conduit].potentialOwner = address(0);

        // Emit an event indicating conduit ownership has been transferred.
        emit OwnershipTransferred(
            conduit,
            _conduits[conduit].owner,
            msg.sender
        );

        // Set the caller as the owner of the conduit.
        _conduits[conduit].owner = msg.sender;
    }

    /**
     * @notice Retrieve the current owner of a deployed conduit.
     *
     * @param conduit The conduit for which to retrieve the associated owner.
     *
     * @return owner The owner of the supplied conduit.
     */
    function ownerOf(address conduit)
        external
        view
        override
        returns (address owner)
    {
        // Ensure that the conduit in question exists.
        _assertConduitExists(conduit);

        // Retrieve the current owner of the conduit in question.
        owner = _conduits[conduit].owner;
    }

    /**
     * @notice Retrieve the conduit key for a deployed conduit via reverse
     *         lookup.
     *
     * @param conduit The conduit for which to retrieve the associated conduit
     *                key.
     *
     * @return conduitKey The conduit key used to deploy the supplied conduit.
     */
    function getKey(address conduit)
        external
        view
        override
        returns (bytes32 conduitKey)
    {
        // Attempt to retrieve a conduit key for the conduit in question.
        conduitKey = _conduits[conduit].key;

        // Revert if no conduit key was located.
        if (conduitKey == bytes32(0)) {
            revert NoConduit();
        }
    }

    /**
     * @notice Derive the conduit associated with a given conduit key and
     *         determine whether that conduit exists (i.e. whether it has been
     *         deployed).
     *
     * @param conduitKey The conduit key used to derive the conduit.
     *
     * @return conduit The derived address of the conduit.
     * @return exists  A boolean indicating whether the derived conduit has been
     *                 deployed or not.
     */
    function getConduit(bytes32 conduitKey)
        external
        view
        override
        returns (address conduit, bool exists)
    {
        // Derive address from deployer, conduit key and creation code hash.
        conduit = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            conduitKey,
                            _CONDUIT_CREATION_CODE_HASH
                        )
                    )
                )
            )
        );

        // Determine whether conduit exists by retrieving its runtime code.
        exists = (conduit.codehash == _CONDUIT_RUNTIME_CODE_HASH);
    }

    /**
     * @notice Retrieve the potential owner, if any, for a given conduit. The
     *         current owner may set a new potential owner via
     *         `transferOwnership` and that owner may then accept ownership of
     *         the conduit in question via `acceptOwnership`.
     *
     * @param conduit The conduit for which to retrieve the potential owner.
     *
     * @return potentialOwner The potential owner, if any, for the conduit.
     */
    function getPotentialOwner(address conduit)
        external
        view
        override
        returns (address potentialOwner)
    {
        // Ensure that the conduit in question exists.
        _assertConduitExists(conduit);

        // Retrieve the current potential owner of the conduit in question.
        potentialOwner = _conduits[conduit].potentialOwner;
    }

    /**
     * @notice Retrieve the status (either open or closed) of a given channel on
     *         a conduit.
     *
     * @param conduit The conduit for which to retrieve the channel status.
     * @param channel The channel for which to retrieve the status.
     *
     * @return isOpen The status of the channel on the given conduit.
     */
    function getChannelStatus(address conduit, address channel)
        external
        view
        override
        returns (bool isOpen)
    {
        // Ensure that the conduit in question exists.
        _assertConduitExists(conduit);

        // Retrieve the current channel status for the conduit in question.
        isOpen = _conduits[conduit].channelIndexesPlusOne[channel] != 0;
    }

    /**
     * @notice Retrieve the total number of open channels for a given conduit.
     *
     * @param conduit The conduit for which to retrieve the total channel count.
     *
     * @return totalChannels The total number of open channels for the conduit.
     */
    function getTotalChannels(address conduit)
        external
        view
        override
        returns (uint256 totalChannels)
    {
        // Ensure that the conduit in question exists.
        _assertConduitExists(conduit);

        // Retrieve the total open channel count for the conduit in question.
        totalChannels = _conduits[conduit].channels.length;
    }

    /**
     * @notice Retrieve an open channel at a specific index for a given conduit.
     *         Note that the index of a channel can change as a result of other
     *         channels being closed on the conduit.
     *
     * @param conduit      The conduit for which to retrieve the open channel.
     * @param channelIndex The index of the channel in question.
     *
     * @return channel The open channel, if any, at the specified channel index.
     */
    function getChannel(address conduit, uint256 channelIndex)
        external
        view
        override
        returns (address channel)
    {
        // Ensure that the conduit in question exists.
        _assertConduitExists(conduit);

        // Retrieve the total open channel count for the conduit in question.
        uint256 totalChannels = _conduits[conduit].channels.length;

        // Ensure that the supplied index is within range.
        if (channelIndex >= totalChannels) {
            revert ChannelOutOfRange(conduit);
        }

        // Retrieve the channel at the given index.
        channel = _conduits[conduit].channels[channelIndex];
    }

    /**
     * @notice Retrieve all open channels for a given conduit. Note that calling
     *         this function for a conduit with many channels will revert with
     *         an out-of-gas error.
     *
     * @param conduit The conduit for which to retrieve open channels.
     *
     * @return channels An array of open channels on the given conduit.
     */
    function getChannels(address conduit)
        external
        view
        override
        returns (address[] memory channels)
    {
        // Ensure that the conduit in question exists.
        _assertConduitExists(conduit);

        // Retrieve all of the open channels on the conduit in question.
        channels = _conduits[conduit].channels;
    }

    /**
     * @dev Retrieve the conduit creation code and runtime code hashes.
     */
    function getConduitCodeHashes()
        external
        view
        override
        returns (bytes32 creationCodeHash, bytes32 runtimeCodeHash)
    {
        // Retrieve the conduit creation code hash from runtime.
        creationCodeHash = _CONDUIT_CREATION_CODE_HASH;

        // Retrieve the conduit runtime code hash from runtime.
        runtimeCodeHash = _CONDUIT_RUNTIME_CODE_HASH;
    }

    /**
     * @dev Private view function to revert if the caller is not the owner of a
     *      given conduit.
     *
     * @param conduit The conduit for which to assert ownership.
     */
    function _assertCallerIsConduitOwner(address conduit) private view {
        // Ensure that the conduit in question exists.
        _assertConduitExists(conduit);

        // If the caller does not match the current owner of the conduit...
        if (msg.sender != _conduits[conduit].owner) {
            // Revert, indicating that the caller is not the owner.
            revert CallerIsNotOwner(conduit);
        }
    }

    /**
     * @dev Private view function to revert if a given conduit does not exist.
     *
     * @param conduit The conduit for which to assert existence.
     */
    function _assertConduitExists(address conduit) private view {
        // Attempt to retrieve a conduit key for the conduit in question.
        if (_conduits[conduit].key == bytes32(0)) {
            // Revert if no conduit key was located.
            revert NoConduit();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0xd36702a3(bytes32 c__0xd36702a3) pure {}


import {
    ConduitControllerInterface
} from "../interfaces/ConduitControllerInterface.sol";

import { ConduitInterface } from "../interfaces/ConduitInterface.sol";

import { Conduit } from "./Conduit.sol";

/**
 * @title ConduitController
 * @author 0age
 * @notice ConduitController enables deploying and managing new conduits, or
 *         contracts that allow registered callers (or open "channels") to
 *         transfer approved ERC20/721/1155 tokens on their behalf.
 */
contract ConduitController is ConduitControllerInterface {
function c_0x86e1449e(bytes32 c__0x86e1449e) internal pure {}

    // Register keys, owners, new potential owners, and channels by conduit.
    mapping(address => ConduitProperties) internal _conduits;

    // Set conduit creation code and runtime code hashes as immutable arguments.
    bytes32 internal immutable _CONDUIT_CREATION_CODE_HASH;
    bytes32 internal immutable _CONDUIT_RUNTIME_CODE_HASH;

    /**
     * @dev Initialize contract by deploying a conduit and setting the creation
     *      code and runtime code hashes as immutable arguments.
     */
    constructor() {c_0x86e1449e(0x2e9e65c399a9ecb1f4296bb4963ed9dbee555327852d60433fdf2469db9bc658); /* function */ 

        // Derive the conduit creation code hash and set it as an immutable.
c_0x86e1449e(0x7a4b3ddf85e348094824caca1929044029946f90ac2f57aaa529fc3706d9e915); /* line */ 
        c_0x86e1449e(0xdbdfaf52889948b7644f33dff8f3f6c2b4cc2f3ddcf3891731a72c1ecd0e5ff2); /* statement */ 
_CONDUIT_CREATION_CODE_HASH = keccak256(type(Conduit).creationCode);

        // Deploy a conduit with the zero hash as the salt.
c_0x86e1449e(0xd44776002fdab556dd75c0fad90ecc16b2c574f70fc9213f2c5f38cef067b9cd); /* line */ 
        c_0x86e1449e(0xb79d76468eb82363cf48be070c5c975b0dcfd1259f944584bcb66e948ebe5d0b); /* statement */ 
Conduit zeroConduit = new Conduit{ salt: bytes32(0) }();

        // Retrieve the conduit runtime code hash and set it as an immutable.
c_0x86e1449e(0xd55211677976eb5b9406affe4972291947a18e1767f530975e84d225ab7aeb27); /* line */ 
        c_0x86e1449e(0x8f7b11b7c940f999ebe6eb8d3016776b83228fda7d46d742d94571fb039e0cee); /* statement */ 
_CONDUIT_RUNTIME_CODE_HASH = address(zeroConduit).codehash;
    }

    /**
     * @notice Deploy a new conduit using a supplied conduit key and assigning
     *         an initial owner for the deployed conduit. Note that the first
     *         twenty bytes of the supplied conduit key must match the caller
     *         and that a new conduit cannot be created if one has already been
     *         deployed using the same conduit key.
     *
     * @param conduitKey   The conduit key used to deploy the conduit. Note that
     *                     the first twenty bytes of the conduit key must match
     *                     the caller of this contract.
     * @param initialOwner The initial owner to set for the new conduit.
     *
     * @return conduit The address of the newly deployed conduit.
     */
    function createConduit(bytes32 conduitKey, address initialOwner)
        external
        override
        returns (address conduit)
    {c_0x86e1449e(0x8ba94d4965a81529e635f6e1d75f46c19ff77a241515d9a549eba795b5573548); /* function */ 

        // Ensure that an initial owner has been supplied.
c_0x86e1449e(0x0568b17506bdf935e662006af73e06cc9875af59e5871e947a5a2936db41925c); /* line */ 
        c_0x86e1449e(0x8fa5a32a57fefdc00dc6ced4ef21cb1f5ecf5afca998181f6e43929a14b19fad); /* statement */ 
if (initialOwner == address(0)) {c_0x86e1449e(0x5fa6b7c6dff1676153a7bfe6434e2e65aeb6ae8b0cf7a74de76042c1e563ab1a); /* branch */ 

c_0x86e1449e(0xcaba1a8fbbbf1eb8ff39cdd510f05055128ed1f086a6a8774d3df4c01bcbda8d); /* line */ 
            revert InvalidInitialOwner();
        }else { c_0x86e1449e(0xa0b980756b12db3c7fc24f63fa1ae7cd46bd6ee74c553377710240d1fbe8fa9a); /* branch */ 
}

        // If the first 20 bytes of the conduit key do not match the caller...
c_0x86e1449e(0x55df0d49c3010af256e5e70ea0659c102ef077e2dabe7f520d682e1bcf570c7e); /* line */ 
        c_0x86e1449e(0x85392c9cf441401d276dd5ba9f5ea1f62d481f89acaef456f43fc7c2fdb971c9); /* statement */ 
if (address(uint160(bytes20(conduitKey))) != msg.sender) {c_0x86e1449e(0x4e321d7b98dafc085d8a54ca49cbea2723da72433452113d262a4f88fc444fb2); /* branch */ 

            // Revert with an error indicating that the creator is invalid.
c_0x86e1449e(0x2ccf33e78a969ec5ec1d08a8e3e67f27cbb7c87ab1ec22a3e13512c825223403); /* line */ 
            revert InvalidCreator();
        }else { c_0x86e1449e(0x4bbf909b60f49c9a3efa7de72b78b3f87b2397d62e17621fa8c45fbc266550c7); /* branch */ 
}

        // Derive address from deployer, conduit key and creation code hash.
c_0x86e1449e(0x0cd974690dc76520f7d77fe095be39e25a0445e67630eec6b88b2ef95adda782); /* line */ 
        c_0x86e1449e(0x6d41ae3ab5abe94c293d20f5d16b257d8ae8264d764a5e1e4ebfcb55f0d5f072); /* statement */ 
conduit = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            conduitKey,
                            _CONDUIT_CREATION_CODE_HASH
                        )
                    )
                )
            )
        );

        // If derived conduit exists, as evidenced by comparing runtime code...
c_0x86e1449e(0x8b2b0a7a7d5e0271a4bb8b0b05d58d17d5093817f248e2ba3f15238be8f331ce); /* line */ 
        c_0x86e1449e(0x2c0ecac56eed4052ed6da08a7b836a18cf41ed67fb4d2482bd8940dffcfc89d2); /* statement */ 
if (conduit.codehash == _CONDUIT_RUNTIME_CODE_HASH) {c_0x86e1449e(0x88b2d30ae62626192dba644ad2ad883e2635883da67ed9050034ba34f4c8f28d); /* branch */ 

            // Revert with an error indicating that the conduit already exists.
c_0x86e1449e(0xd90c0ee226eed0fdacdb7dd0f2c49b9b2bade134e67e11c3a08aa4db0e60d13e); /* line */ 
            revert ConduitAlreadyExists(conduit);
        }else { c_0x86e1449e(0x7d083a5244bfe6fc1d5aaa5cd6a4e0cedd698764649a9c18137a21f173891ee9); /* branch */ 
}

        // Deploy the conduit via CREATE2 using the conduit key as the salt.
c_0x86e1449e(0xa76980ea7efa9ac289ab8c5a1c0ce33411ba6335b8ff2f79f7b79708b0861238); /* line */ 
        c_0x86e1449e(0x08cc91b97a059f208f427f76c492a775ef936e9793de322662fdfe3ae94e3ffa); /* statement */ 
new Conduit{ salt: conduitKey }();

        // Initialize storage variable referencing conduit properties.
c_0x86e1449e(0x8f272c9a508197258dd1fa3045034ed1010e3b37fe1bd2bf5360813074023f64); /* line */ 
        c_0x86e1449e(0xd883d8647a59e3205fd7617f9188dab964166894baa875761785c3e8d87c1669); /* statement */ 
ConduitProperties storage conduitProperties = _conduits[conduit];

        // Set the supplied initial owner as the owner of the conduit.
c_0x86e1449e(0x4336d22782966e16715c52cf9554c9d2247587dc07921b3de186b29fadf5b846); /* line */ 
        c_0x86e1449e(0xe279919fc4085287087c58f24425e464aefb033e4945422d99176e1538d6cb35); /* statement */ 
conduitProperties.owner = initialOwner;

        // Set conduit key used to deploy the conduit to enable reverse lookup.
c_0x86e1449e(0xd859086ef48783183af057caba76172cb7c808ebcf8a264aa666de740d95b0ef); /* line */ 
        c_0x86e1449e(0x8888889a9ff7865352b4772f2a289935ed89372999eaa25b6ef292e0288ac67b); /* statement */ 
conduitProperties.key = conduitKey;

        // Emit an event indicating that the conduit has been deployed.
c_0x86e1449e(0x365ebedb655d2fbd2cf7ddfe3a5861c2feb3fe74aa292caf7bca6c302f709bb2); /* line */ 
        c_0x86e1449e(0x1377b0ebf07d6e8866d8a424c074380f5e3ca6fc9d2b826c56e16653a6e0083e); /* statement */ 
emit NewConduit(conduit, conduitKey);

        // Emit an event indicating that conduit ownership has been assigned.
c_0x86e1449e(0x441d7fbcc37e48d038c747cb0cee504152174c54d4317d3e8cc24a45ce2c606f); /* line */ 
        c_0x86e1449e(0xb9c3d6803ccb7589ba48688cbb6c9d459c5d81a56ce1439b9e1ee1ba137c9df8); /* statement */ 
emit OwnershipTransferred(conduit, address(0), initialOwner);
    }

    /**
     * @notice Open or close a channel on a given conduit, thereby allowing the
     *         specified account to execute transfers against that conduit.
     *         Extreme care must be taken when updating channels, as malicious
     *         or vulnerable channels can transfer any ERC20, ERC721 and ERC1155
     *         tokens where the token holder has granted the conduit approval.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to open or close the channel.
     * @param channel The channel to open or close on the conduit.
     * @param isOpen  A boolean indicating whether to open or close the channel.
     */
    function updateChannel(
        address conduit,
        address channel,
        bool isOpen
    ) external override {c_0x86e1449e(0xd7327300906b678342976b7bdd85886c4acd19659590702b01727173c1e00b5a); /* function */ 

        // Ensure the caller is the current owner of the conduit in question.
c_0x86e1449e(0x245286b1f5cded65bd8a86e9c293d503762650f9fdfea65b38a1ed6e9da26ba8); /* line */ 
        c_0x86e1449e(0xb8e29e16ae3a851735ab0aff827273be01fa61a5c06535aa2be95d0554f4256f); /* statement */ 
_assertCallerIsConduitOwner(conduit);

        // Call the conduit, updating the channel.
c_0x86e1449e(0x313200312b824db4f5f3d188a68cccb900b76fa9521241649d61d0a172e04f43); /* line */ 
        c_0x86e1449e(0x41c4d93936a8ff249a07702ecd14fba43fb848c0ee995b1bf0af1b3ce8ce0abe); /* statement */ 
ConduitInterface(conduit).updateChannel(channel, isOpen);

        // Retrieve storage region where channels for the conduit are tracked.
c_0x86e1449e(0x723446cd5be615ba8986f5e556722677d7db5abd137f898d97560dedd7e3378d); /* line */ 
        c_0x86e1449e(0xd4546a9dfa4efa66a028c00f6425df04bdb40a832b5f53a7bd905e2abe8050d9); /* statement */ 
ConduitProperties storage conduitProperties = _conduits[conduit];

        // Retrieve the index, if one currently exists, for the updated channel.
c_0x86e1449e(0x4d988bb5e8289ce55a76200734c63d033182dfb95a22c4352ed34866dbb40440); /* line */ 
        c_0x86e1449e(0x590a3457247f208739ee17cdd433743528da5d85e32c5b0c2f64797de2b59954); /* statement */ 
uint256 channelIndexPlusOne = (
            conduitProperties.channelIndexesPlusOne[channel]
        );

        // Determine whether the updated channel is already tracked as open.
c_0x86e1449e(0xec89112ba479e8d74f68717a6465154a01865a30ea30f0c01a0d8ebd88909747); /* line */ 
        c_0x86e1449e(0x5b04cdee1e63e135f68365a11a3843ab7f0585b6a70fda488bc8a3014ba1a995); /* statement */ 
bool channelPreviouslyOpen = channelIndexPlusOne != 0;

        // If the channel has been set to open and was previously closed...
c_0x86e1449e(0xd536876c31b0c3ae9d98efceb34d478c0dcfca4358b6201cc81e2496cfcd4984); /* line */ 
        c_0x86e1449e(0xa09b74d6a4f3e6351ad60f148bbf6122cc2c4c697628d46de608b72d0f390b12); /* statement */ 
if (isOpen && !channelPreviouslyOpen) {c_0x86e1449e(0xc5c1b7dcedbf428632709a1c7d6546b4a96cefbfceb84f7550eae80a084ef609); /* branch */ 

            // Add the channel to the channels array for the conduit.
c_0x86e1449e(0xe4ecefa38fd352a58c777b4183dce92927e7eb1c897e4f24dbf3c156a2908cd0); /* line */ 
            c_0x86e1449e(0x01ea15c5bb866878e7e1c4387847379d06c7d4f7b7311ba10585baa81a5e53a3); /* statement */ 
conduitProperties.channels.push(channel);

            // Add new open channel length to associated mapping as index + 1.
c_0x86e1449e(0x6509a08ff86f07ce0d68d9043833343f91c80ad41b607e38280a71cca2ed0d24); /* line */ 
            c_0x86e1449e(0x09fdd0d081ed37d53493fc7412e4620b78a826cb751ae06d5334f2bcf6191c29); /* statement */ 
conduitProperties.channelIndexesPlusOne[channel] = (
                conduitProperties.channels.length
            );
        } else {c_0x86e1449e(0x7facee4456a93df79fd068d98dc1022428d1791118d4d13837017e56edcef26a); /* statement */ 
c_0x86e1449e(0x3470f626e09b89cbf645a77125e30d621062f8ccccedef91e45a51f4be34228a); /* branch */ 
if (!isOpen && channelPreviouslyOpen) {c_0x86e1449e(0xd8cfe2a54500cf8e834c922775d9e98438715e756dff2238505672e98c5124bf); /* branch */ 

            // Set a previously open channel as closed via "swap & pop" method.
            // Decrement located index to get the index of the closed channel.
c_0x86e1449e(0xf7e228d732347680712156963ce4b69e6ba15c166a820d72ea56f111d3fcf47c); /* line */ 
            c_0x86e1449e(0x3f2b22480b3e980ee2bbff11308808d65045bc9c93414bcb8ee6dea584f06d1a); /* statement */ 
uint256 removedChannelIndex;

            // Skip underflow check as channelPreviouslyOpen being true ensures
            // that channelIndexPlusOne is nonzero.
c_0x86e1449e(0xaa461b616f313661a43c2311a8bdcf1e850d59c43a65a636f037a772bce962aa); /* line */ 
            unchecked {
c_0x86e1449e(0xe99a35eb7b935ec978ba30831c9369deb0a4a5c6c9bf095c4afa0c36e427164c); /* line */ 
                c_0x86e1449e(0x7baec4f986601474502cdcb6d00d3fde0cfd5f2817da1ef477b9774fe4bbd076); /* statement */ 
removedChannelIndex = channelIndexPlusOne - 1;
            }

            // Use length of channels array to determine index of last channel.
c_0x86e1449e(0x6941b1247b836197d116466ee08c0675ea8ae90b0925c25e42ab1300d54f7a6b); /* line */ 
            c_0x86e1449e(0x3d7cc7db79d5806525763db0015535971e48b8ad0ea2368a16336a794efb46dd); /* statement */ 
uint256 finalChannelIndex = conduitProperties.channels.length - 1;

            // If closed channel is not last channel in the channels array...
c_0x86e1449e(0x001aac0b07a4da47bcf8448357441de46d2d2b04a74b5b85d7ece14d46bfcf35); /* line */ 
            c_0x86e1449e(0x7f1f719ab1d31b7f1a72dfc9db21b414d47b00c2bb5e95b714cc1ce4b87f2f65); /* statement */ 
if (finalChannelIndex != removedChannelIndex) {c_0x86e1449e(0x3abdbcf3710a5f9b98ae55af47cadc708d4d023941138354e6bba8437af3962e); /* branch */ 

                // Retrieve the final channel and place the value on the stack.
c_0x86e1449e(0xdc00907825daeb734b36b336ccb10381104e715a70561cce73ac4f4b78e65325); /* line */ 
                c_0x86e1449e(0xdfe2cac85f65a86e35e3925bc161ed9d36d6cf98efbf79c56d6c9a8cb22464ea); /* statement */ 
address finalChannel = (
                    conduitProperties.channels[finalChannelIndex]
                );

                // Overwrite the removed channel using the final channel value.
c_0x86e1449e(0xba645415209e001c6567beab18dcbdec2e62348887023b08cc71edc11546097b); /* line */ 
                c_0x86e1449e(0x0c686470c74500f010090dbb696946d3f35234ae417ead162012017e03ae2c1d); /* statement */ 
conduitProperties.channels[removedChannelIndex] = finalChannel;

                // Update final index in associated mapping to removed index.
c_0x86e1449e(0x04285887718cf6b5cd980d0102e670a4f568e086c9d4d1ecf808e1edad461e24); /* line */ 
                c_0x86e1449e(0x11c25a8f33af593e7955c7cf8636a5c5d67537998e59a37c1765dc1e689386c8); /* statement */ 
conduitProperties.channelIndexesPlusOne[finalChannel] = (
                    channelIndexPlusOne
                );
            }else { c_0x86e1449e(0xb85147f96b94af08b530d39d1013b9ed2c9e03e4f758588d0600c85b4b7f755b); /* branch */ 
}

            // Remove the last channel from the channels array for the conduit.
c_0x86e1449e(0x52e66422ec66086236bffc9e3fa2400f0f33a0170c3f0caf40daee8dd4f37a3a); /* line */ 
            c_0x86e1449e(0x3017de7d728aa8047a0e1cbdbc54b44994f72a5fb88181192008af35706f6c07); /* statement */ 
conduitProperties.channels.pop();

            // Remove the closed channel from associated mapping of indexes.
c_0x86e1449e(0x0265000b25e166cedb99f13af10a425131c2cfa8c856654c65d010c53e3e8742); /* line */ 
            delete conduitProperties.channelIndexesPlusOne[channel];
        }else { c_0x86e1449e(0xe03eba41686e09c8c2cc68d69138853b0a0d3dd82d655f7a15ee4fdd27e4b791); /* branch */ 
}}
    }

    /**
     * @notice Initiate conduit ownership transfer by assigning a new potential
     *         owner for the given conduit. Once set, the new potential owner
     *         may call `acceptOwnership` to claim ownership of the conduit.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to initiate ownership transfer.
     * @param newPotentialOwner The new potential owner of the conduit.
     */
    function transferOwnership(address conduit, address newPotentialOwner)
        external
        override
    {c_0x86e1449e(0x0172ba137721b6ef2f6a2119bf439038debb27909a6a1643b582e60e47489a91); /* function */ 

        // Ensure the caller is the current owner of the conduit in question.
c_0x86e1449e(0xde50d0ed2920f9e2212496b929f53d28f05d879c1750ab1234519d877c7886f1); /* line */ 
        c_0x86e1449e(0x3fc483309d53060a29716b63d7c96b76501aeb603e38029d08b525cac94edd43); /* statement */ 
_assertCallerIsConduitOwner(conduit);

        // Ensure the new potential owner is not an invalid address.
c_0x86e1449e(0xf7c3789c9f135eab0eaa6e3fdd910430833bc11301dc4db63b452382d51c9d05); /* line */ 
        c_0x86e1449e(0x20c2e781b9bf46bf9eb9397a8d1014c064b0f0f01ce5445cbd7024324de9b9e1); /* statement */ 
if (newPotentialOwner == address(0)) {c_0x86e1449e(0xc8d0ef1a33a64b6c28cf6d1cc6ccc0814bf0ddc3dc0372d6fc29d2b2fbd44647); /* branch */ 

c_0x86e1449e(0x3576b6a05dfb2c0a56aa596846ae849a0a6a9d5a1c22d4189db0571e7ef118e8); /* line */ 
            revert NewPotentialOwnerIsZeroAddress(conduit);
        }else { c_0x86e1449e(0xeaf885ddcc3a466e58e246b498daf6ea3e1294f8ba6af2f917fce911ba7338bf); /* branch */ 
}

        // Ensure the new potential owner is not already set.
c_0x86e1449e(0xbb857757c6ad6219888a3abba09a0a5bdeba9a2f1af333fa240b02a79423bf8a); /* line */ 
        c_0x86e1449e(0x13b01f03e33b88e43c5ba5853d94bf3a4a164ee622d7c5b75017052ed97af147); /* statement */ 
if (newPotentialOwner == _conduits[conduit].potentialOwner) {c_0x86e1449e(0xb040af60feb2bf4a25a13b1996c227d54c072aea4272096b19552c0befbb2584); /* branch */ 

c_0x86e1449e(0x8409ec55636fd0d31562568a2f9f56ddd7ccf04b0abc94e60e01baa67dfd8e20); /* line */ 
            revert NewPotentialOwnerAlreadySet(conduit, newPotentialOwner);
        }else { c_0x86e1449e(0x623adaac8ea26cea8907db911cdc15cc58688f2f017f71c70701625485ac5308); /* branch */ 
}

        // Emit an event indicating that the potential owner has been updated.
c_0x86e1449e(0xcbf908f94d5af26e16bb3b17b6f06a0d3563cb31ca858b65204082844c2a69fe); /* line */ 
        c_0x86e1449e(0xe3225877093d94b84ffb02441a16e0c3382bac4b1d7231119a97422c34cd0529); /* statement */ 
emit PotentialOwnerUpdated(newPotentialOwner);

        // Set the new potential owner as the potential owner of the conduit.
c_0x86e1449e(0x48c6d6f4fe58bd9f9f16b9a0a69775c4301366574d73a4858ccc69e527a522bd); /* line */ 
        c_0x86e1449e(0x6e36a3e7a4a9c7b23f6013fd1b9b97b22ec9e1f19e4cd9c2b8a7d20ef5e1e18b); /* statement */ 
_conduits[conduit].potentialOwner = newPotentialOwner;
    }

    /**
     * @notice Clear the currently set potential owner, if any, from a conduit.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to cancel ownership transfer.
     */
    function cancelOwnershipTransfer(address conduit) external override {c_0x86e1449e(0xcd8e71377d7b4f7b70f3f30ff513705fa0f53e8ab8151815b779f9e5edaf152f); /* function */ 

        // Ensure the caller is the current owner of the conduit in question.
c_0x86e1449e(0xb19b4640b1a396f8bbbe77564813a6ca2099faf302abae5eb90958527ba572c5); /* line */ 
        c_0x86e1449e(0x7ca83acfb78afa412fdf1630b4057e8d2f42c86cad2e69507fec73600fd17ecd); /* statement */ 
_assertCallerIsConduitOwner(conduit);

        // Ensure that ownership transfer is currently possible.
c_0x86e1449e(0x39ba07dd411d2126bd1f94a4a3aa4a1f750cb24caf3a4d5240b7d16639b88948); /* line */ 
        c_0x86e1449e(0x32bd67b4888f4b3db635193802897349c8646f13c4511f1afe2cd29de9e32928); /* statement */ 
if (_conduits[conduit].potentialOwner == address(0)) {c_0x86e1449e(0x68f6ecc50d580b4435729141d6b655a953d38d937d4504b431d94acf1c42e243); /* branch */ 

c_0x86e1449e(0xf35d468139763258cc06a6391192ea540f2a50d52182d38d29a970aca91a33ed); /* line */ 
            revert NoPotentialOwnerCurrentlySet(conduit);
        }else { c_0x86e1449e(0xaef4266c1ff6400f9cba2f36ffca5d208c368b7d8382bd0abfc4653b84e00ffa); /* branch */ 
}

        // Emit an event indicating that the potential owner has been cleared.
c_0x86e1449e(0x6038961f7778e00975c1aa9dc80ed47f7f19d44688d5d803db425e9d2092464f); /* line */ 
        c_0x86e1449e(0x23121cf28d82fe3f3d2295f0872c9b6a12507c480d09dc53dea7b9b524201015); /* statement */ 
emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner from the conduit.
c_0x86e1449e(0x31fce9a173f6c191ed4bd9351d87859d1771529e96bca2dd41709964cdb29c29); /* line */ 
        c_0x86e1449e(0x85b16bc90bb57cefd28a4ca134bba017ef9214e77b45a411db34f2404f9a7db4); /* statement */ 
_conduits[conduit].potentialOwner = address(0);
    }

    /**
     * @notice Accept ownership of a supplied conduit. Only accounts that the
     *         current owner has set as the new potential owner may call this
     *         function.
     *
     * @param conduit The conduit for which to accept ownership.
     */
    function acceptOwnership(address conduit) external override {c_0x86e1449e(0x7c599c487cbb70b67726bc2e9865045b2281ee25555a0354f2a19b506fd81767); /* function */ 

        // Ensure that the conduit in question exists.
c_0x86e1449e(0x7fd14d42e124f0bf1eaada6c25adb26194c068c143a3decef6ad9750c5556a3a); /* line */ 
        c_0x86e1449e(0xca6c558ff6202febdd6abb965c7d691b7216e607b6f899eaaacc14176b9da8b1); /* statement */ 
_assertConduitExists(conduit);

        // If caller does not match current potential owner of the conduit...
c_0x86e1449e(0x624c02a7d51f6cac0a1d2173c9af6999862fbd4a3fb4752f797a88f395f2a612); /* line */ 
        c_0x86e1449e(0xdba23d2b6ee52051502b60884d6a95db510ac45fbc8ddc6a9741d6baf85b743f); /* statement */ 
if (msg.sender != _conduits[conduit].potentialOwner) {c_0x86e1449e(0x9aa707affbf7e4dd0c80f0c18cc36bb235e2e88ef810e221c16cc3381b22ff1f); /* branch */ 

            // Revert, indicating that caller is not current potential owner.
c_0x86e1449e(0x74c10fb96b4320d544ab812fb48b7b06375ae5153bd8ddef6671d459d18b33a2); /* line */ 
            revert CallerIsNotNewPotentialOwner(conduit);
        }else { c_0x86e1449e(0x63e859f5a5ef82887f42257b64c6f162ba929870ce2b0b7be4edc32c86e7c53a); /* branch */ 
}

        // Emit an event indicating that the potential owner has been cleared.
c_0x86e1449e(0x58e937c3234f30c9234a2c1518a85f1fd128d534c262402ac7b628987596ac6e); /* line */ 
        c_0x86e1449e(0x88c0a43c50627aea07be1a29a73273d16ad93eab93dbe36a8a00171858e19d1f); /* statement */ 
emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner from the conduit.
c_0x86e1449e(0xaabfdd27622fac8d8d76c7e0b9ab5e1a601d27a7ba9e20e1c3110ed040e1f745); /* line */ 
        c_0x86e1449e(0x4cac116705dc5ed9d93fd6aa528d1c3fd55ea6e37c367cdec148d2dd71dd8a4a); /* statement */ 
_conduits[conduit].potentialOwner = address(0);

        // Emit an event indicating conduit ownership has been transferred.
c_0x86e1449e(0xcc02d781779f87d1fe6ceeb81f5a0cb19faf392159ea46707815606dd4889c61); /* line */ 
        c_0x86e1449e(0xbc18ec286d065487c184e7c1b01b8b0f7241087ba4512a3be98b2b82510585e0); /* statement */ 
emit OwnershipTransferred(
            conduit,
            _conduits[conduit].owner,
            msg.sender
        );

        // Set the caller as the owner of the conduit.
c_0x86e1449e(0x1d48dfe32a38fd1c0892c540321f77f3a8f2fa6ca4ca02f31888634aee410a00); /* line */ 
        c_0x86e1449e(0x3731850c2b554acce6319b4d73518b3d2fedb89416dd7f9576b578452b89b5b6); /* statement */ 
_conduits[conduit].owner = msg.sender;
    }

    /**
     * @notice Retrieve the current owner of a deployed conduit.
     *
     * @param conduit The conduit for which to retrieve the associated owner.
     *
     * @return owner The owner of the supplied conduit.
     */
    function ownerOf(address conduit)
        external
        view
        override
        returns (address owner)
    {c_0x86e1449e(0x3e13d2a3ebaa346bb247fe29de1a9b87bc4b537ab08188a87a2376fd104533eb); /* function */ 

        // Ensure that the conduit in question exists.
c_0x86e1449e(0x12a755e2ad4fbd45e62d6e5ed159fd935d3d845f8b120f340299ffb0aa0e404e); /* line */ 
        c_0x86e1449e(0xd2549157c2f01162a4ba34b20cc5e8709b61c72fed1c7624dd5f4505e9cd13e5); /* statement */ 
_assertConduitExists(conduit);

        // Retrieve the current owner of the conduit in question.
c_0x86e1449e(0x2a58e646551f275502fb24fc642a26c3b7734640acfda6dfb35a5e4283fb1461); /* line */ 
        c_0x86e1449e(0xbd5301e1d7552a76d8bad6a06213fd1b78fa42388a21c726f682181b46e824a4); /* statement */ 
owner = _conduits[conduit].owner;
    }

    /**
     * @notice Retrieve the conduit key for a deployed conduit via reverse
     *         lookup.
     *
     * @param conduit The conduit for which to retrieve the associated conduit
     *                key.
     *
     * @return conduitKey The conduit key used to deploy the supplied conduit.
     */
    function getKey(address conduit)
        external
        view
        override
        returns (bytes32 conduitKey)
    {c_0x86e1449e(0x6c69e242ba40373d3d9a9b0b50f51f5c219186001ff1828cf13a819b3b71e7d2); /* function */ 

        // Attempt to retrieve a conduit key for the conduit in question.
c_0x86e1449e(0x686ba0820a16ebaa1a284aa56cdb03a85ad2d583dac67beccfe812398bc47c88); /* line */ 
        c_0x86e1449e(0x040947755882d88f88cb4bc2aea91923af0c50c1eb405f1a8a52fa859b56dee2); /* statement */ 
conduitKey = _conduits[conduit].key;

        // Revert if no conduit key was located.
c_0x86e1449e(0x68ca11f3876b3d98ca181d6deec239c97ef4a456c031af0db6236d37317a7b56); /* line */ 
        c_0x86e1449e(0x3ee20bef3492cfa828ab4682f01ac70f79f6731e89702ce4b449dbc9bd4c6638); /* statement */ 
if (conduitKey == bytes32(0)) {c_0x86e1449e(0xaf6ebfa2515aa773e0fb51b114208ed23d110a6a11c3dff3814c09d7ff6545eb); /* branch */ 

c_0x86e1449e(0x888be229b0b3bb5a39b66be143d4682016d02700ae2df0ec039e8baaaba92b88); /* line */ 
            revert NoConduit();
        }else { c_0x86e1449e(0xb62428fb4329514f94e23633679469cff6b3cb85970410f6baea3b638c1167ee); /* branch */ 
}
    }

    /**
     * @notice Derive the conduit associated with a given conduit key and
     *         determine whether that conduit exists (i.e. whether it has been
     *         deployed).
     *
     * @param conduitKey The conduit key used to derive the conduit.
     *
     * @return conduit The derived address of the conduit.
     * @return exists  A boolean indicating whether the derived conduit has been
     *                 deployed or not.
     */
    function getConduit(bytes32 conduitKey)
        external
        view
        override
        returns (address conduit, bool exists)
    {c_0x86e1449e(0x3744c561c95161d0f3601c7e116c5e8270f158c076a7cafbb27903ada84872de); /* function */ 

        // Derive address from deployer, conduit key and creation code hash.
c_0x86e1449e(0xd7ff716b7dc1db7b88c66a31e2fa157c8c060fe25063252d7d8d1967ba6f193e); /* line */ 
        c_0x86e1449e(0x7ec5b29130946b9526a2be13968b31aae00632b0e9960ea6b121cdf3ed4ba06a); /* statement */ 
conduit = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            conduitKey,
                            _CONDUIT_CREATION_CODE_HASH
                        )
                    )
                )
            )
        );

        // Determine whether conduit exists by retrieving its runtime code.
c_0x86e1449e(0x50c0cc41bcd858c606500ad9093d3f53977892e1758f8175c00255fbd6f1d284); /* line */ 
        c_0x86e1449e(0xad21dd4f6c57f2371f1227c3bb8a63b6d2e238f4157141caa248cc6d6bf4451f); /* statement */ 
exists = (conduit.codehash == _CONDUIT_RUNTIME_CODE_HASH);
    }

    /**
     * @notice Retrieve the potential owner, if any, for a given conduit. The
     *         current owner may set a new potential owner via
     *         `transferOwnership` and that owner may then accept ownership of
     *         the conduit in question via `acceptOwnership`.
     *
     * @param conduit The conduit for which to retrieve the potential owner.
     *
     * @return potentialOwner The potential owner, if any, for the conduit.
     */
    function getPotentialOwner(address conduit)
        external
        view
        override
        returns (address potentialOwner)
    {c_0x86e1449e(0x470ae37f2de4af49b12d9640dd3b0214a6fc89b52892b3daf1f2e3dd13a3f92a); /* function */ 

        // Ensure that the conduit in question exists.
c_0x86e1449e(0xa5f4f386d7aa357634f389466369fe04d509fd8f1360c32a2eb9be9cb0f737c1); /* line */ 
        c_0x86e1449e(0xda9cbc59edd3ecaface2aaf06534370dfd64d3cfb791c3b6d1f866def8fcd590); /* statement */ 
_assertConduitExists(conduit);

        // Retrieve the current potential owner of the conduit in question.
c_0x86e1449e(0xf16b991db1cc967a07b5df5d954ba78546938ee38574b9436f0fe2ac0e2fb8fd); /* line */ 
        c_0x86e1449e(0x892dc314a44665513171d913799607bf276cef4d82332bf4593f046efcf31290); /* statement */ 
potentialOwner = _conduits[conduit].potentialOwner;
    }

    /**
     * @notice Retrieve the status (either open or closed) of a given channel on
     *         a conduit.
     *
     * @param conduit The conduit for which to retrieve the channel status.
     * @param channel The channel for which to retrieve the status.
     *
     * @return isOpen The status of the channel on the given conduit.
     */
    function getChannelStatus(address conduit, address channel)
        external
        view
        override
        returns (bool isOpen)
    {c_0x86e1449e(0xb42db1fe2869ccd59e756a91d2e48f80fd66a9f6646101162c4b7e76b2015f2a); /* function */ 

        // Ensure that the conduit in question exists.
c_0x86e1449e(0x4756e3b4e2e833ee1c1ed93a3e41537456b99083f88566eb81422e8229193af9); /* line */ 
        c_0x86e1449e(0x2177984b663cea42ff99da082ae9996e682aeda31a638c2e2f833a8d7e5d846f); /* statement */ 
_assertConduitExists(conduit);

        // Retrieve the current channel status for the conduit in question.
c_0x86e1449e(0xa82f87c31c990b961f88ff80e3865e52113feabf3e2ab355ee5f4950676aab66); /* line */ 
        c_0x86e1449e(0xdaa10309805fb0cbb687946ccacd5ce2067d366d5179127309b09e33640f2b4f); /* statement */ 
isOpen = _conduits[conduit].channelIndexesPlusOne[channel] != 0;
    }

    /**
     * @notice Retrieve the total number of open channels for a given conduit.
     *
     * @param conduit The conduit for which to retrieve the total channel count.
     *
     * @return totalChannels The total number of open channels for the conduit.
     */
    function getTotalChannels(address conduit)
        external
        view
        override
        returns (uint256 totalChannels)
    {c_0x86e1449e(0xfcb785a80b3a8731ee528825640b1d24d3cd5a2b4c6aaddb357b9d07e1727270); /* function */ 

        // Ensure that the conduit in question exists.
c_0x86e1449e(0x04f25497d6155a5552677c21b29a707b8a6893f55da680e2702545e06856f762); /* line */ 
        c_0x86e1449e(0xfa54082c51dd446e6ca4d06fe8f5dc5f152b509ffcf93b1127483d0e0b845aa7); /* statement */ 
_assertConduitExists(conduit);

        // Retrieve the total open channel count for the conduit in question.
c_0x86e1449e(0x80963c36a245cf898cf4d45e350384aca5498ec277da0e1aae0c92af0bb5c8d8); /* line */ 
        c_0x86e1449e(0x3513e22cfb40eb7a6ce5a53f61fd396f2b25707906e9586d3c3b1272127e6546); /* statement */ 
totalChannels = _conduits[conduit].channels.length;
    }

    /**
     * @notice Retrieve an open channel at a specific index for a given conduit.
     *         Note that the index of a channel can change as a result of other
     *         channels being closed on the conduit.
     *
     * @param conduit      The conduit for which to retrieve the open channel.
     * @param channelIndex The index of the channel in question.
     *
     * @return channel The open channel, if any, at the specified channel index.
     */
    function getChannel(address conduit, uint256 channelIndex)
        external
        view
        override
        returns (address channel)
    {c_0x86e1449e(0x0ef92be9da6fbc5e3f74ac1fe2011c06124fe30f6d8e9b194cf1b380cee06d90); /* function */ 

        // Ensure that the conduit in question exists.
c_0x86e1449e(0x0d06ff8ea39b0246596af848d61fe7ecfbf5ed89b01947b37836aaa7cb64c353); /* line */ 
        c_0x86e1449e(0x9fb25414300bc7244d4e3c1c576c4ae029e133131db070c590e7d799b9d093f8); /* statement */ 
_assertConduitExists(conduit);

        // Retrieve the total open channel count for the conduit in question.
c_0x86e1449e(0xa06cf95ef56e2b14c15bd615bc051002c49c8024d1cb24888ff636119e001a12); /* line */ 
        c_0x86e1449e(0x959763fb8d622569571585980e32a23192cfe934c00d95db3d2b11bffeb8ca8f); /* statement */ 
uint256 totalChannels = _conduits[conduit].channels.length;

        // Ensure that the supplied index is within range.
c_0x86e1449e(0x7c243fb54c6937c3f071affb61468d6955b4e8db72621913b0dadccd73d8b0af); /* line */ 
        c_0x86e1449e(0x10cf5e6f677fb1072a8fc3172178693c40124ddf17da59141c1b36c000976f96); /* statement */ 
if (channelIndex >= totalChannels) {c_0x86e1449e(0xcbebe07ab5f8d75f8a57dbda54bb7560916ac145b5e0e5c8ecb1041d0638b9df); /* branch */ 

c_0x86e1449e(0xf35ebd3ee48af7c6427edfaa86980d835cd8bbe0b4cd2bff730aa5ee76aee822); /* line */ 
            revert ChannelOutOfRange(conduit);
        }else { c_0x86e1449e(0x5e00c2ea58863b1f3e38e1fc4dfba43784b4479bd50812b1c0d473e85350037a); /* branch */ 
}

        // Retrieve the channel at the given index.
c_0x86e1449e(0x705f0ce59277d6eb225fd8969e99f9c89cb47aa7f68b2bb1363b156786a113ce); /* line */ 
        c_0x86e1449e(0x71be051c92104b1bbed7d1396263515f40a7a7d5db1c268d1d786bbb7421b6a5); /* statement */ 
channel = _conduits[conduit].channels[channelIndex];
    }

    /**
     * @notice Retrieve all open channels for a given conduit. Note that calling
     *         this function for a conduit with many channels will revert with
     *         an out-of-gas error.
     *
     * @param conduit The conduit for which to retrieve open channels.
     *
     * @return channels An array of open channels on the given conduit.
     */
    function getChannels(address conduit)
        external
        view
        override
        returns (address[] memory channels)
    {c_0x86e1449e(0xa0fbd64243870527f2c2241b0b7abf5de5d5fa41c6acc26e4a6dc61699991532); /* function */ 

        // Ensure that the conduit in question exists.
c_0x86e1449e(0xa8d464064000cd7ad536915a259f7032331a76841b09e8a2359e044d467c1cbd); /* line */ 
        c_0x86e1449e(0xfd9c5c9b5a392287c5a163d1b949e5b6dbd6cca3c9c98d7cf218ada71d06d60f); /* statement */ 
_assertConduitExists(conduit);

        // Retrieve all of the open channels on the conduit in question.
c_0x86e1449e(0xdc5cce92052f70f45332ea89e352e7b8719e1f940d190975c57597c9ee4d1262); /* line */ 
        c_0x86e1449e(0xa08cf1a392f929a27205736a49a22a863bda49a1b71e12d34863fddb28419c79); /* statement */ 
channels = _conduits[conduit].channels;
    }

    /**
     * @dev Retrieve the conduit creation code and runtime code hashes.
     */
    function getConduitCodeHashes()
        external
        view
        override
        returns (bytes32 creationCodeHash, bytes32 runtimeCodeHash)
    {c_0x86e1449e(0x8d79527d76d207fd992fcb0be09311fd7b2793956f089c443d939a8a62fe6b09); /* function */ 

        // Retrieve the conduit creation code hash from runtime.
c_0x86e1449e(0xeb5c3f56844bff81763058d55a5291325a8864b063d8821ddc30112f076cfb11); /* line */ 
        c_0x86e1449e(0xbbc5193af8d7c9e12c378bbcd647175cceefc35c18ec93b92f03043230488b65); /* statement */ 
creationCodeHash = _CONDUIT_CREATION_CODE_HASH;

        // Retrieve the conduit runtime code hash from runtime.
c_0x86e1449e(0xcd3c48a0f15c738963afecbb23c797ab94464c63a1bb32d33b67e016c2d3fe30); /* line */ 
        c_0x86e1449e(0x09eac45c9b258bb308aa3598650b92d214249f1e5cfeac9285857c92db36c17b); /* statement */ 
runtimeCodeHash = _CONDUIT_RUNTIME_CODE_HASH;
    }

    /**
     * @dev Private view function to revert if the caller is not the owner of a
     *      given conduit.
     *
     * @param conduit The conduit for which to assert ownership.
     */
    function _assertCallerIsConduitOwner(address conduit) private view {c_0x86e1449e(0xb1d3b3f79f6e17ae66c0441f42433a43725d7310e7bec17c7a49a4ff5330528e); /* function */ 

        // Ensure that the conduit in question exists.
c_0x86e1449e(0xb284722c52865289764e87f12fd8cc9b58d0dfef36587893d28d8bee5d87b27c); /* line */ 
        c_0x86e1449e(0x7d00b025fe621a2deae1969a827daadb97b177ea4b1ed50857850d9130d660d3); /* statement */ 
_assertConduitExists(conduit);

        // If the caller does not match the current owner of the conduit...
c_0x86e1449e(0xa953b050def72c494b53d29a92238acad92b2bca39ded9f488203634113c6d5d); /* line */ 
        c_0x86e1449e(0x456ed73cfbccd26e3d81d96bb3664bdfc30d61671ab79168fb66336d695aef09); /* statement */ 
if (msg.sender != _conduits[conduit].owner) {c_0x86e1449e(0xc97a5acd698ec0ecb0b2706feae427129e92e961b4ed53f4f914e405e5f78d80); /* branch */ 

            // Revert, indicating that the caller is not the owner.
c_0x86e1449e(0x7aa19c3f565665c89126ecff2fe27457c9db57d60b3de09bafe53eef45a60c04); /* line */ 
            revert CallerIsNotOwner(conduit);
        }else { c_0x86e1449e(0x9e69dadf86f8f83c50d804884b66fc3df9499a6dd1c28900259a4fdcb100aa59); /* branch */ 
}
    }

    /**
     * @dev Private view function to revert if a given conduit does not exist.
     *
     * @param conduit The conduit for which to assert existence.
     */
    function _assertConduitExists(address conduit) private view {c_0x86e1449e(0x92f1c5c28d099ecdc9dd5d64b3dc3b097edb33e5617bc4e18d6597393ef8ea6a); /* function */ 

        // Attempt to retrieve a conduit key for the conduit in question.
c_0x86e1449e(0x744595f6129b6dd5d730e3912957e4e50ee2d868b7d342e6191a36def768a9fa); /* line */ 
        c_0x86e1449e(0xf864d7bb8916c4afd94343ee2011cc218932c40c4d56ca9a02cb676a1e1a07b1); /* statement */ 
if (_conduits[conduit].key == bytes32(0)) {c_0x86e1449e(0x9ac977b436b882e0d15c3794b9d7cbef3159e475bb28f78148ea3cffcaf7005b); /* branch */ 

            // Revert if no conduit key was located.
c_0x86e1449e(0xaec3b9ad18423be09962a055c6de0d7dad6e36c764813542b703cfe55056e55c); /* line */ 
            revert NoConduit();
        }else { c_0x86e1449e(0xdf393502e26a168e3e8a7c66eb47009b1bad71fcf62c4b625b8feaa392862057); /* branch */ 
}
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { ConduitInterface } from "../interfaces/ConduitInterface.sol";

import { TokenTransferrer } from "../lib/TokenTransferrer.sol";

import {
    ConduitTransfer,
    ConduitBatch1155Transfer
} from "../conduit/lib/ConduitStructs.sol";

contract ConduitMock is ConduitInterface {
    constructor() {}

    function execute(
        ConduitTransfer[] calldata /* transfers */
    ) external pure override returns (bytes4) {
        // Return the valid magic value.
        return 0x4ce34aa2;
    }

    function executeBatch1155(
        ConduitBatch1155Transfer[] calldata /*  batch1155Transfers */
    ) external view override returns (bytes4 magicValue) {}

    function executeWithBatch1155(
        ConduitTransfer[] calldata, /* standardTransfers */
        ConduitBatch1155Transfer[] calldata /*  batch1155Transfers */
    ) external view override returns (bytes4 magicValue) {}

    function updateChannel(address channel, bool isOpen) external override {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { ConduitInterface } from "../interfaces/ConduitInterface.sol";

import { TokenTransferrer } from "../lib/TokenTransferrer.sol";

import {
    ConduitTransfer,
    ConduitBatch1155Transfer
} from "../conduit/lib/ConduitStructs.sol";

contract ConduitMockInvalidMagic is ConduitInterface {
    constructor() {}

    function execute(
        ConduitTransfer[] calldata /* transfers */
    ) external pure override returns (bytes4) {
        return 0xabcd0000;
    }

    function executeBatch1155(
        ConduitBatch1155Transfer[] calldata /*  batch1155Transfers */
    ) external view override returns (bytes4 magicValue) {}

    function executeWithBatch1155(
        ConduitTransfer[] calldata, /* standardTransfers */
        ConduitBatch1155Transfer[] calldata /*  batch1155Transfers */
    ) external view override returns (bytes4 magicValue) {}

    function updateChannel(address channel, bool isOpen) external override {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { ConduitInterface } from "../interfaces/ConduitInterface.sol";

import { TokenTransferrer } from "../lib/TokenTransferrer.sol";

import {
    ConduitTransfer,
    ConduitBatch1155Transfer
} from "../conduit/lib/ConduitStructs.sol";

contract ConduitMockRevertNoReason is ConduitInterface {
    constructor() {}

    function execute(
        ConduitTransfer[] calldata /* transfers */
    ) external pure override returns (bytes4) {
        // Revert without reason string.
        revert();
    }

    function executeBatch1155(
        ConduitBatch1155Transfer[] calldata /*  batch1155Transfers */
    ) external view override returns (bytes4 magicValue) {}

    function executeWithBatch1155(
        ConduitTransfer[] calldata, /* standardTransfers */
        ConduitBatch1155Transfer[] calldata /*  batch1155Transfers */
    ) external view override returns (bytes4 magicValue) {}

    function updateChannel(address channel, bool isOpen) external override {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { ConduitInterface } from "../interfaces/ConduitInterface.sol";

import { TokenTransferrer } from "../lib/TokenTransferrer.sol";

import {
    ConduitTransfer,
    ConduitBatch1155Transfer
} from "../conduit/lib/ConduitStructs.sol";

contract ConduitMockRevertBytes is ConduitInterface {
    constructor() {}

    error CustomError();

    function execute(
        ConduitTransfer[] calldata /* transfers */
    ) external pure override returns (bytes4) {
        revert CustomError();
    }

    function executeBatch1155(
        ConduitBatch1155Transfer[] calldata /*  batch1155Transfers */
    ) external view override returns (bytes4 magicValue) {}

    function executeWithBatch1155(
        ConduitTransfer[] calldata, /* standardTransfers */
        ConduitBatch1155Transfer[] calldata /*  batch1155Transfers */
    ) external view override returns (bytes4 magicValue) {}

    function updateChannel(address channel, bool isOpen) external override {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0x5bb58afb(bytes32 c__0x5bb58afb) pure {}


import { ConduitInterface } from "../interfaces/ConduitInterface.sol";

import {
    OrderType,
    ItemType,
    BasicOrderRouteType
} from "./ConsiderationEnums.sol";

import {
    AdditionalRecipient,
    BasicOrderParameters,
    OfferItem,
    ConsiderationItem,
    SpentItem,
    ReceivedItem
} from "./ConsiderationStructs.sol";

import { OrderValidator } from "./OrderValidator.sol";

import "./ConsiderationConstants.sol";

/**
 * @title BasicOrderFulfiller
 * @author 0age
 * @notice BasicOrderFulfiller contains functionality for fulfilling "basic"
 *         orders with minimal overhead. See documentation for details on what
 *         qualifies as a basic order.
 */
contract BasicOrderFulfiller is OrderValidator {
function c_0xc512bb96(bytes32 c__0xc512bb96) internal pure {}

    /**
     * @dev Derive and set hashes, reference chainId, and associated domain
     *      separator during deployment.
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     */
    constructor(address conduitController) OrderValidator(conduitController) {c_0xc512bb96(0xdfb82b290e489625af713859d5a381cda22147a43cfc824d9e9714a9d997f95a); /* function */ 
}

    /**
     * @dev Internal function to fulfill an order offering an ERC20, ERC721, or
     *      ERC1155 item by supplying Ether (or other native tokens), ERC20
     *      tokens, an ERC721 item, or an ERC1155 item as consideration. Six
     *      permutations are supported: Native token to ERC721, Native token to
     *      ERC1155, ERC20 to ERC721, ERC20 to ERC1155, ERC721 to ERC20, and
     *      ERC1155 to ERC20 (with native tokens supplied as msg.value). For an
     *      order to be eligible for fulfillment via this method, it must
     *      contain a single offer item (though that item may have a greater
     *      amount if the item is not an ERC721). An arbitrary number of
     *      "additional recipients" may also be supplied which will each receive
     *      native tokens or ERC20 items from the fulfiller as consideration.
     *      Refer to the documentation for a more comprehensive summary of how
     *      to utilize this method and what orders are compatible with it.
     *
     * @param parameters Additional information on the fulfilled order. Note
     *                   that the offerer and the fulfiller must first approve
     *                   this contract (or their chosen conduit if indicated)
     *                   before any tokens can be transferred. Also note that
     *                   contract recipients of ERC1155 consideration items must
     *                   implement `onERC1155Received` in order to receive those
     *                   items.
     *
     * @return A boolean indicating whether the order has been fulfilled.
     */
    function _validateAndFulfillBasicOrder(
        BasicOrderParameters calldata parameters
    ) internal returns (bool) {c_0xc512bb96(0xeeac5ec39e2e8223c622a096e99a65379fb9803d6865c6a6c77eb17074fc19ed); /* function */ 

        // Declare enums for order type & route to extract from basicOrderType.
c_0xc512bb96(0xcf41e02e084c51efe8bd88f956a74db505f1542646dd11d0eb38833583a24e60); /* line */ 
        c_0xc512bb96(0xe6e0832444f732ab7aaa293e8046946e3df0e67467621ade0212be85b4c370ae); /* statement */ 
BasicOrderRouteType route;
c_0xc512bb96(0xaa7ffe2b37315c74c0c05f4587c4b76eb7976727aae60ea25cb0d7f1f3c30978); /* line */ 
        c_0xc512bb96(0x1b9a6d4b619ed17de96fb95af1f756dfec0fd86b16713f5bbcc225d718764d84); /* statement */ 
OrderType orderType;

        // Declare additional recipient item type to derive from the route type.
c_0xc512bb96(0xe95218e4784399233c60fb57152e4f359c2d4590a0e66bd05bd31af12d05438d); /* line */ 
        c_0xc512bb96(0x30fc873548469a615a761049f2352f6cb8f316d01d38e3b91e3f82b3600325ee); /* statement */ 
ItemType additionalRecipientsItemType;

        // Utilize assembly to extract the order type and the basic order route.
c_0xc512bb96(0x388876b5ca386c770d48025b8ea45b66b6469e90b5912f9821565286afb5a2f9); /* line */ 
        assembly {
            // Read basicOrderType from calldata.
            let basicOrderType := calldataload(BasicOrder_basicOrderType_cdPtr)

            // Mask all but 2 least-significant bits to derive the order type.
            orderType := and(basicOrderType, 3)

            // Divide basicOrderType by four to derive the route.
            route := shr(2, basicOrderType)

            // If route > 1 additionalRecipient items are ERC20 (1) else Eth (0)
            additionalRecipientsItemType := gt(route, 1)
        }

c_0xc512bb96(0x557df0021d2291545374aa21764692d2454d81ce525e868920706db65a487840); /* line */ 
        {
            // Declare temporary variable for enforcing payable status.
c_0xc512bb96(0xc5a897bd4c10cb6efb7306768a60b394adbef614e04852236e07ace281f57c36); /* line */ 
            c_0xc512bb96(0xd2b28d204e9e43330bbbe380bb0d7003b22e20d477643e5543ef996c505af272); /* statement */ 
bool correctPayableStatus;

            // Utilize assembly to compare the route to the callvalue.
c_0xc512bb96(0x98957aaa504b6a39bcb388459f5e268fb89b4e0168a168b1201bc769bce94e67); /* line */ 
            assembly {
                // route 0 and 1 are payable, otherwise route is not payable.
                correctPayableStatus := eq(
                    additionalRecipientsItemType,
                    iszero(callvalue())
                )
            }

            // Revert if msg.value has not been supplied as part of payable
            // routes or has been supplied as part of non-payable routes.
c_0xc512bb96(0x614c4b82d1c8ae6ebb1ab316f3c5f60c982ca797f3720d44531a00510f0ad07e); /* line */ 
            c_0xc512bb96(0x37b5c1a0cd884236ed2094acdaab09febb95e07cdde88bab573774a61ec29f75); /* statement */ 
if (!correctPayableStatus) {c_0xc512bb96(0x3a52c8ecc89186fcbc3d72a7cda9ce2fd60ea014f391bd9f36ad8ebb2e503d77); /* branch */ 

c_0xc512bb96(0xa28d2eed3898b104e9f8962cf34b180dc19d02615c491734c3640480aa03c73c); /* line */ 
                revert InvalidMsgValue(msg.value);
            }else { c_0xc512bb96(0xf4d45ba349d5c049b0be9c0389df9e387ff95e78382be07c8cb686fbca6c2616); /* branch */ 
}
        }

        // Declare more arguments that will be derived from route and calldata.
c_0xc512bb96(0x4890ad10d5c97ec4ade83725e46b7b04f9095e1170ca118f17896d37bdf5c345); /* line */ 
        c_0xc512bb96(0x083dea501d49d7c676a266d952104340dd77d8cfbf6f45ea433a39b0bc8da897); /* statement */ 
address additionalRecipientsToken;
c_0xc512bb96(0x995ccbeed59e349a372aedf2c823c66d2380a87682b6e04ff7fa7f4916442a60); /* line */ 
        c_0xc512bb96(0xaefb35ee9efe0cf77c5035447f108f3e642177fd259706d2df0b8a854206638a); /* statement */ 
ItemType offeredItemType;
c_0xc512bb96(0xae5ff8e4948c9e5f22363f385fb00ea8e4ab26dcede9474bfd41685408bbc350); /* line */ 
        c_0xc512bb96(0x910a48afde95ecc29c1547f89527d7eb1d368ccb0003da7d1acf6a48c5e3bf3b); /* statement */ 
bool offerTypeIsAdditionalRecipientsType;

        // Declare scope for received item type to manage stack pressure.
c_0xc512bb96(0x66e8f43172a53b806f47172f25ba4bbe3eafbda68ab50f0c3b5e634a05893d6e); /* line */ 
        {
c_0xc512bb96(0x32585c49183964b3a64666d675c2a88be2edfd932b1d0a248c6de1a7c42f9780); /* line */ 
            c_0xc512bb96(0x73cf247588d144991b09082ba43aeda53091cb1da6538c04d01effd851d55283); /* statement */ 
ItemType receivedItemType;

            // Utilize assembly to retrieve function arguments and cast types.
c_0xc512bb96(0xa54adad58836bcf034d5953b91840ec798931e07a6ea058ae9d2ef5dffbe8095); /* line */ 
            assembly {
                // Check if offered item type == additional recipient item type.
                offerTypeIsAdditionalRecipientsType := gt(route, 3)

                // If route > 3 additionalRecipientsToken is at 0xc4 else 0x24.
                additionalRecipientsToken := calldataload(
                    add(
                        BasicOrder_considerationToken_cdPtr,
                        mul(
                            offerTypeIsAdditionalRecipientsType,
                            BasicOrder_common_params_size
                        )
                    )
                )

                // If route > 2, receivedItemType is route - 2. If route is 2,
                // the receivedItemType is ERC20 (1). Otherwise, it is Eth (0).
                receivedItemType := add(
                    mul(sub(route, 2), gt(route, 2)),
                    eq(route, 2)
                )

                // If route > 3, offeredItemType is ERC20 (1). Route is 2 or 3,
                // offeredItemType = route. Route is 0 or 1, it is route + 2.
                offeredItemType := sub(
                    add(route, mul(iszero(additionalRecipientsItemType), 2)),
                    mul(
                        offerTypeIsAdditionalRecipientsType,
                        add(receivedItemType, 1)
                    )
                )
            }

            // Derive & validate order using parameters and update order status.
c_0xc512bb96(0x1cad82dc8e8e4a7a1e5e3fcb813a1b782a02f56e27a6e043881d114d0612a921); /* line */ 
            c_0xc512bb96(0xe0c607c226a81ee8890bc8b08bfe1301c77438b4e72c4950d3c240cc0bc7fdf2); /* statement */ 
_prepareBasicFulfillmentFromCalldata(
                parameters,
                orderType,
                receivedItemType,
                additionalRecipientsItemType,
                additionalRecipientsToken,
                offeredItemType
            );
        }

        // Declare conduitKey argument used by transfer functions.
c_0xc512bb96(0xaaa6d6590341332705a23da203053555ad3af018e4ce2d7f6ce7e03ae7e96d9b); /* line */ 
        c_0xc512bb96(0xf521f68555da5550a0f8bf6f5173082d9c9888bdcf245b1254ff02102551bcde); /* statement */ 
bytes32 conduitKey;

        // Utilize assembly to derive conduit (if relevant) based on route.
c_0xc512bb96(0x84be959e4ff1dee19dd8f10a1062e1c60a1a2bd81bd73131d765c551a05ea288); /* line */ 
        assembly {
            // use offerer conduit for routes 0-3, fulfiller conduit otherwise.
            conduitKey := calldataload(
                add(
                    BasicOrder_offererConduit_cdPtr,
                    mul(offerTypeIsAdditionalRecipientsType, OneWord)
                )
            )
        }

        // Transfer tokens based on the route.
c_0xc512bb96(0x2e68f165c453ef50e1c8e9abfe9e44e401ca3d08989d2fe24ac2cc3fb8f8703c); /* line */ 
        c_0xc512bb96(0x8de0b97ed7bbc4da84e942292c29532c21a7bf11fc3cd3cd0cd3dcea86a998be); /* statement */ 
if (additionalRecipientsItemType == ItemType.NATIVE) {c_0xc512bb96(0x653a3d760948e25ffeae69f03123c8748d1929b7f8888a8121877e110a798669); /* branch */ 

            // Ensure neither the token nor the identifier parameters are set.
c_0xc512bb96(0xac0992de9b1cf005ba1f9ef794955a48d5728bb51eec6cb2eafd3bf50dff440e); /* line */ 
            c_0xc512bb96(0xad140c8d66c06fd4f7ee888b202e208186d2a5d1d869a0425b6b438db19312f5); /* statement */ 
if (
                (uint160(parameters.considerationToken) |
                    parameters.considerationIdentifier) != 0
            ) {c_0xc512bb96(0xffd5a7d536423cd74355ed9af38bb5f1cee8ee5b738a762c09a98fcae2f837e2); /* branch */ 

c_0xc512bb96(0xcbb66bc57810480cb10dc0302502b4dab34eeca646934fadb681e47268917a59); /* line */ 
                revert UnusedItemParameters();
            }else { c_0xc512bb96(0xd84babb98fc09f6ead9af59419719abaec73163fc9f1a639f26783a3523501c6); /* branch */ 
}

            // Transfer the ERC721 or ERC1155 item, bypassing the accumulator.
c_0xc512bb96(0xaabae0ff22640434b3c6dc00fb84699baedfd2f2d8dc24df633ba4707fd86034); /* line */ 
            c_0xc512bb96(0x82d94fa1f063527516bd7cb82c3847f8e921953469b04a745be9a8eee0c2eaa4); /* statement */ 
_transferIndividual721Or1155Item(
                offeredItemType,
                parameters.offerToken,
                parameters.offerer,
                msg.sender,
                parameters.offerIdentifier,
                parameters.offerAmount,
                conduitKey
            );

            // Transfer native to recipients, return excess to caller & wrap up.
c_0xc512bb96(0xfaceb0f0098940a72a97915b5b2a0107a272519edcef07d38eff3cfbbab31a4a); /* line */ 
            c_0xc512bb96(0xd313ee500dd046aed947495b088347f565b469808fa07e12adb277b8f70ccec6); /* statement */ 
_transferEthAndFinalize(
                parameters.considerationAmount,
                parameters.offerer,
                parameters.additionalRecipients
            );
        } else {c_0xc512bb96(0xba776d85a191aa1ed57ece8ef958dd426208fb25dbf08c9d6a194cf3f0f8b83f); /* branch */ 

            // Initialize an accumulator array. From this point forward, no new
            // memory regions can be safely allocated until the accumulator is
            // no longer being utilized, as the accumulator operates in an
            // open-ended fashion from this memory pointer; existing memory may
            // still be accessed and modified, however.
c_0xc512bb96(0x3f53ca5df473cbab6507219216aee6bdfff53a202511b346b7ff9b6da3f9c174); /* line */ 
            c_0xc512bb96(0xb97ebc5bbe51e3b479a57cbb795866b853cfed0778a510030aa0621a03504027); /* statement */ 
bytes memory accumulator = new bytes(AccumulatorDisarmed);

            // Choose transfer method for ERC721 or ERC1155 item based on route.
c_0xc512bb96(0x87f0e567cd4451459f06016496ae4d705de7be8ca79764b0a714f4b0817e9b84); /* line */ 
            c_0xc512bb96(0x74b2ba175172298e286a38f6104e65fb27c5a54db6c3c6c01f028e8b200c185f); /* statement */ 
if (route == BasicOrderRouteType.ERC20_TO_ERC721) {c_0xc512bb96(0xdd47b771320f513ce80cb74b397f6997f3bdb123b0789fab4e65b4f12da1e13b); /* branch */ 

                // Transfer ERC721 to caller using offerer's conduit preference.
c_0xc512bb96(0xc070d01390e8fb58c340d5fd963a79dcb6d2e25e39a476122f09433e85a04516); /* line */ 
                c_0xc512bb96(0x4e916bb41071e7fb8e25a75ba1f58f5e9c6d81db3a04e9f1fbd0d0de3a076b94); /* statement */ 
_transferERC721(
                    parameters.offerToken,
                    parameters.offerer,
                    msg.sender,
                    parameters.offerIdentifier,
                    parameters.offerAmount,
                    conduitKey,
                    accumulator
                );
            } else {c_0xc512bb96(0x75f94ec765f5b2b3898fd8dd350762b094b9c9c7b1668841650f04b7400747bb); /* statement */ 
c_0xc512bb96(0xcc84716a01efa0001c554004c533ebc50a6b289859f1d7f23b47bb9ad5212d97); /* branch */ 
if (route == BasicOrderRouteType.ERC20_TO_ERC1155) {c_0xc512bb96(0xb432b397239f0298c69acdc846defe87b1f80bef78645f95a0dd8818ac4ac20f); /* branch */ 

                // Transfer ERC1155 to caller with offerer's conduit preference.
c_0xc512bb96(0x222a1ebc3742f32863ffaf77462b87fbe1b505ee4225ac7372433d0f61ea22ac); /* line */ 
                c_0xc512bb96(0x827914ee614f0ef64f291aee4d8afa1220b41d2abb7b0d1f724ee877863baf0b); /* statement */ 
_transferERC1155(
                    parameters.offerToken,
                    parameters.offerer,
                    msg.sender,
                    parameters.offerIdentifier,
                    parameters.offerAmount,
                    conduitKey,
                    accumulator
                );
            } else {c_0xc512bb96(0x0b8145fe3d381a73226baa883a7ad8af00571f4a22d51c5069764d5e25d30af9); /* statement */ 
c_0xc512bb96(0x1a3e23bb7488f04b26875388206faf34bef1d94e9e36ab85369226a53e5c5e57); /* branch */ 
if (route == BasicOrderRouteType.ERC721_TO_ERC20) {c_0xc512bb96(0xc488d2b2a89fa02fdb09a80a07a4348ee54c63f7c88555d351235c8963b3b5bf); /* branch */ 

                // Transfer ERC721 to offerer using caller's conduit preference.
c_0xc512bb96(0x8d27cd87210afb4432f46886f05ec9dc209f28eefca22e8215da6e5be25ccd5b); /* line */ 
                c_0xc512bb96(0x609751839e9b7592a0b5994d198cb0d261b226c657393e53fcc865c9f8d9d5f1); /* statement */ 
_transferERC721(
                    parameters.considerationToken,
                    msg.sender,
                    parameters.offerer,
                    parameters.considerationIdentifier,
                    parameters.considerationAmount,
                    conduitKey,
                    accumulator
                );
            } else {c_0xc512bb96(0xd2e3441070600a0d99dd5090f7e6ed411e7a57422c1271605689178a50a9c91c); /* branch */ 

                // route == BasicOrderRouteType.ERC1155_TO_ERC20

                // Transfer ERC1155 to offerer with caller's conduit preference.
c_0xc512bb96(0x62983db010d6f3895d03abae8b644987a022ce79ce91a0f517bfc40cabbe50fc); /* line */ 
                c_0xc512bb96(0x6cd7ac587f61e6f9dcbe2dbc366a22559c963201d7bf4f09e6943a74ad7b292b); /* statement */ 
_transferERC1155(
                    parameters.considerationToken,
                    msg.sender,
                    parameters.offerer,
                    parameters.considerationIdentifier,
                    parameters.considerationAmount,
                    conduitKey,
                    accumulator
                );
            }}}

            // Transfer ERC20 tokens to all recipients and wrap up.
c_0xc512bb96(0x89e32c12c5e2f1c9dd355d1db72fcc3b6b7ee321ccebe7a181e8ba4db6d67ace); /* line */ 
            c_0xc512bb96(0x009cf0a94abd15e02a07e7bccaf978d95cb2cc0c6a29dc71291330454a8b3d69); /* statement */ 
_transferERC20AndFinalize(
                parameters.offerer,
                parameters,
                offerTypeIsAdditionalRecipientsType,
                accumulator
            );

            // Trigger any remaining accumulated transfers via call to conduit.
c_0xc512bb96(0x849cad70a820e74b2c2e894055cdb1f0805903f6735f6b4bb5dc3b01f84d2ce8); /* line */ 
            c_0xc512bb96(0xa912a1ab9503f4d36cda5486d22606ac52354f3c5b89a7a93755c312eac8c8a6); /* statement */ 
_triggerIfArmed(accumulator);
        }

        // Clear the reentrancy guard.
c_0xc512bb96(0x0b643f16add324273e14507f1e1834acbeccc1f15527631297125910865212d7); /* line */ 
        c_0xc512bb96(0x5152ec9c94d367cf05d83892dd1bb0d04ce5633594cc3fe8c48db32c8cd19a78); /* statement */ 
_clearReentrancyGuard();

c_0xc512bb96(0x977be5cdbb390d17fe4237d1860f8b29dd2b2620e40e7e17a9abbfa881d18399); /* line */ 
        c_0xc512bb96(0x0a81ada67f7c10bde95910d441e77f7acc340af32b15bddf3ef67db7bffc18ac); /* statement */ 
return true;
    }

    /**
     * @dev Internal function to prepare fulfillment of a basic order with
     *      manual calldata and memory access. This calculates the order hash,
     *      emits an OrderFulfilled event, and asserts basic order validity.
     *      Note that calldata offsets must be validated as this function
     *      accesses constant calldata pointers for dynamic types that match
     *      default ABI encoding, but valid ABI encoding can use arbitrary
     *      offsets. Checking that the offsets were produced by default encoding
     *      will ensure that other functions using Solidity's calldata accessors
     *      (which calculate pointers from the stored offsets) are reading the
     *      same data as the order hash is derived from. Also note that This
     *      function accesses memory directly. It does not clear the expanded
     *      memory regions used, nor does it update the free memory pointer, so
     *      other direct memory access must not assume that unused memory is
     *      empty.
     *
     * @param parameters                   The parameters of the basic order.
     * @param orderType                    The order type.
     * @param receivedItemType             The item type of the initial
     *                                     consideration item on the order.
     * @param additionalRecipientsItemType The item type of any additional
     *                                     consideration item on the order.
     * @param additionalRecipientsToken    The ERC20 token contract address (if
     *                                     applicable) for any additional
     *                                     consideration item on the order.
     * @param offeredItemType              The item type of the offered item on
     *                                     the order.
     */
    function _prepareBasicFulfillmentFromCalldata(
        BasicOrderParameters calldata parameters,
        OrderType orderType,
        ItemType receivedItemType,
        ItemType additionalRecipientsItemType,
        address additionalRecipientsToken,
        ItemType offeredItemType
    ) internal {c_0xc512bb96(0x0d331790af79c1f5daeb55da870ec2c6e377229682637cde06b7afecac1ac7e3); /* function */ 

        // Ensure this function cannot be triggered during a reentrant call.
c_0xc512bb96(0xd77a471bb9eef26a89a44c7d9ce18dbfb0d1a7f5791d7fe95cc67f955460cc53); /* line */ 
        c_0xc512bb96(0xf7db998688fbc2a9047b6b96365feed48b71450b50b05af48c2453fabb4227cb); /* statement */ 
_setReentrancyGuard();

        // Ensure current timestamp falls between order start time and end time.
c_0xc512bb96(0xd0294577d93981bdcd61895263460137cb257b3a6db515a2a9e427f5d85fc56c); /* line */ 
        c_0xc512bb96(0xb80cf83db3f21d4e0f558e779d1fa4cac94356e53adca5fbc1cb19982ff44de1); /* statement */ 
_verifyTime(parameters.startTime, parameters.endTime, true);

        // Verify that calldata offsets for all dynamic types were produced by
        // default encoding. This ensures that the constants we use for calldata
        // pointers to dynamic types are the same as those calculated by
        // Solidity using their offsets. Also verify that the basic order type
        // is within range.
c_0xc512bb96(0xf8f7a2ed16dacaa8115b9ed12d32cf70a2028fd575c2e12fe487c70de85a8e5a); /* line */ 
        c_0xc512bb96(0xcaae37cb12bc60254d941cdbfceddaff2ac017a972e406f90df5468b481a5a29); /* statement */ 
_assertValidBasicOrderParameters();

        // Ensure supplied consideration array length is not less than original.
c_0xc512bb96(0x13f1928d7d088f765cb96b598f3e93adce4491fdc0b375618cb20e6200e75deb); /* line */ 
        c_0xc512bb96(0x41d4f1bd13088072d643a6593ca1ce96e0b6beddc82651a4bc6e2b2bde52ecd4); /* statement */ 
_assertConsiderationLengthIsNotLessThanOriginalConsiderationLength(
            parameters.additionalRecipients.length,
            parameters.totalOriginalAdditionalRecipients
        );

        // Declare stack element for the order hash.
c_0xc512bb96(0xbe4536b1d9d1bd84141a9a70a0c4c6c93a6718ff6998c6b37bb744570d9ea5cb); /* line */ 
        c_0xc512bb96(0xc7b32829d348eebe433861d616938536e3e73d2e3ce8f8623208a1f9ff3d9276); /* statement */ 
bytes32 orderHash;

c_0xc512bb96(0x4166004f8a3454d9e1b08427cb2141af7d4439a0d7214cb0dfcc32faf9eeab1a); /* line */ 
        {
            /**
             * First, handle consideration items. Memory Layout:
             *  0x60: final hash of the array of consideration item hashes
             *  0x80-0x160: reused space for EIP712 hashing of each item
             *   - 0x80: ConsiderationItem EIP-712 typehash (constant)
             *   - 0xa0: itemType
             *   - 0xc0: token
             *   - 0xe0: identifier
             *   - 0x100: startAmount
             *   - 0x120: endAmount
             *   - 0x140: recipient
             *  0x160-END_ARR: array of consideration item hashes
             *   - 0x160: primary consideration item EIP712 hash
             *   - 0x180-END_ARR: additional recipient item EIP712 hashes
             *  END_ARR: beginning of data for OrderFulfilled event
             *   - END_ARR + 0x120: length of ReceivedItem array
             *   - END_ARR + 0x140: beginning of data for first ReceivedItem
             * (Note: END_ARR = 0x180 + RECIPIENTS_LENGTH * 0x20)
             */

            // Load consideration item typehash from runtime and place on stack.
c_0xc512bb96(0xa0d7b304025e726e23ff7ba0c80b431668d1c3dee91ccf4746425f56f65f2f33); /* line */ 
            c_0xc512bb96(0x46483639a5e3e16214c92bdf311c28381998005bd5ee14d2af9a10275d5e907a); /* statement */ 
bytes32 typeHash = _CONSIDERATION_ITEM_TYPEHASH;

            // Utilize assembly to enable reuse of memory regions and use
            // constant pointers when possible.
c_0xc512bb96(0x7b665789c3de448a07b96383a71fe70ffd0db00e938005d2845a05a6c63dd83d); /* line */ 
            assembly {
                /*
                 * 1. Calculate the EIP712 ConsiderationItem hash for the
                 * primary consideration item of the basic order.
                 */

                // Write ConsiderationItem type hash and item type to memory.
                mstore(BasicOrder_considerationItem_typeHash_ptr, typeHash)
                mstore(
                    BasicOrder_considerationItem_itemType_ptr,
                    receivedItemType
                )

                // Copy calldata region with (token, identifier, amount) from
                // BasicOrderParameters to ConsiderationItem. The
                // considerationAmount is written to startAmount and endAmount
                // as basic orders do not have dynamic amounts.
                calldatacopy(
                    BasicOrder_considerationItem_token_ptr,
                    BasicOrder_considerationToken_cdPtr,
                    ThreeWords
                )

                // Copy calldata region with considerationAmount and offerer
                // from BasicOrderParameters to endAmount and recipient in
                // ConsiderationItem.
                calldatacopy(
                    BasicOrder_considerationItem_endAmount_ptr,
                    BasicOrder_considerationAmount_cdPtr,
                    TwoWords
                )

                // Calculate EIP712 ConsiderationItem hash and store it in the
                // array of EIP712 consideration hashes.
                mstore(
                    BasicOrder_considerationHashesArray_ptr,
                    keccak256(
                        BasicOrder_considerationItem_typeHash_ptr,
                        EIP712_ConsiderationItem_size
                    )
                )

                /*
                 * 2. Write a ReceivedItem struct for the primary consideration
                 * item to the consideration array in OrderFulfilled.
                 */

                // Get the length of the additional recipients array.
                let totalAdditionalRecipients := calldataload(
                    BasicOrder_additionalRecipients_length_cdPtr
                )

                // Calculate pointer to length of OrderFulfilled consideration
                // array.
                let eventConsiderationArrPtr := add(
                    OrderFulfilled_consideration_length_baseOffset,
                    mul(totalAdditionalRecipients, OneWord)
                )

                // Set the length of the consideration array to the number of
                // additional recipients, plus one for the primary consideration
                // item.
                mstore(
                    eventConsiderationArrPtr,
                    add(
                        calldataload(
                            BasicOrder_additionalRecipients_length_cdPtr
                        ),
                        1
                    )
                )

                // Overwrite the consideration array pointer so it points to the
                // body of the first element
                eventConsiderationArrPtr := add(
                    eventConsiderationArrPtr,
                    OneWord
                )

                // Set itemType at start of the ReceivedItem memory region.
                mstore(eventConsiderationArrPtr, receivedItemType)

                // Copy calldata region (token, identifier, amount & recipient)
                // from BasicOrderParameters to ReceivedItem memory.
                calldatacopy(
                    add(eventConsiderationArrPtr, Common_token_offset),
                    BasicOrder_considerationToken_cdPtr,
                    FourWords
                )

                /*
                 * 3. Calculate EIP712 ConsiderationItem hashes for original
                 * additional recipients and add a ReceivedItem for each to the
                 * consideration array in the OrderFulfilled event. The original
                 * additional recipients are all the considerations signed by
                 * the offerer aside from the primary consideration of the
                 * order. Uses memory region from 0x80-0x160 as a buffer for
                 * calculating EIP712 ConsiderationItem hashes.
                 */

                // Put pointer to consideration hashes array on the stack.
                // This will be updated as each additional recipient is hashed
                let
                    considerationHashesPtr
                := BasicOrder_considerationHashesArray_ptr

                // Write item type, token, & identifier for additional recipient
                // to memory region for hashing EIP712 ConsiderationItem; these
                // values will be reused for each recipient.
                mstore(
                    BasicOrder_considerationItem_itemType_ptr,
                    additionalRecipientsItemType
                )
                mstore(
                    BasicOrder_considerationItem_token_ptr,
                    additionalRecipientsToken
                )
                mstore(BasicOrder_considerationItem_identifier_ptr, 0)

                // Read length of the additionalRecipients array from calldata
                // and iterate.
                totalAdditionalRecipients := calldataload(
                    BasicOrder_totalOriginalAdditionalRecipients_cdPtr
                )
                let i := 0
                // prettier-ignore
                for {} lt(i, totalAdditionalRecipients) {
                    i := add(i, 1)
                } {
                    /*
                     * Calculate EIP712 ConsiderationItem hash for recipient.
                     */

                    // Retrieve calldata pointer for additional recipient.
                    let additionalRecipientCdPtr := add(
                        BasicOrder_additionalRecipients_data_cdPtr,
                        mul(AdditionalRecipients_size, i)
                    )

                    // Copy startAmount from calldata to the ConsiderationItem
                    // struct.
                    calldatacopy(
                        BasicOrder_considerationItem_startAmount_ptr,
                        additionalRecipientCdPtr,
                        OneWord
                    )

                    // Copy endAmount and recipient from calldata to the
                    // ConsiderationItem struct.
                    calldatacopy(
                        BasicOrder_considerationItem_endAmount_ptr,
                        additionalRecipientCdPtr,
                        AdditionalRecipients_size
                    )

                    // Add 1 word to the pointer as part of each loop to reduce
                    // operations needed to get local offset into the array.
                    considerationHashesPtr := add(
                        considerationHashesPtr,
                        OneWord
                    )

                    // Calculate EIP712 ConsiderationItem hash and store it in
                    // the array of consideration hashes.
                    mstore(
                        considerationHashesPtr,
                        keccak256(
                            BasicOrder_considerationItem_typeHash_ptr,
                            EIP712_ConsiderationItem_size
                        )
                    )

                    /*
                     * Write ReceivedItem to OrderFulfilled data.
                     */

                    // At this point, eventConsiderationArrPtr points to the
                    // beginning of the ReceivedItem struct of the previous
                    // element in the array. Increase it by the size of the
                    // struct to arrive at the pointer for the current element.
                    eventConsiderationArrPtr := add(
                        eventConsiderationArrPtr,
                        ReceivedItem_size
                    )

                    // Write itemType to the ReceivedItem struct.
                    mstore(
                        eventConsiderationArrPtr,
                        additionalRecipientsItemType
                    )

                    // Write token to the next word of the ReceivedItem struct.
                    mstore(
                        add(eventConsiderationArrPtr, OneWord),
                        additionalRecipientsToken
                    )

                    // Copy endAmount & recipient words to ReceivedItem struct.
                    calldatacopy(
                        add(
                            eventConsiderationArrPtr,
                            ReceivedItem_amount_offset
                        ),
                        additionalRecipientCdPtr,
                        TwoWords
                    )
                }

                /*
                 * 4. Hash packed array of ConsiderationItem EIP712 hashes:
                 *   `keccak256(abi.encodePacked(receivedItemHashes))`
                 * Note that it is set at 0x60 — all other memory begins at
                 * 0x80. 0x60 is the "zero slot" and will be restored at the end
                 * of the assembly section and before required by the compiler.
                 */
                mstore(
                    receivedItemsHash_ptr,
                    keccak256(
                        BasicOrder_considerationHashesArray_ptr,
                        mul(add(totalAdditionalRecipients, 1), OneWord)
                    )
                )

                /*
                 * 5. Add a ReceivedItem for each tip to the consideration array
                 * in the OrderFulfilled event. The tips are all the
                 * consideration items that were not signed by the offerer and
                 * were provided by the fulfiller.
                 */

                // Overwrite length to length of the additionalRecipients array.
                totalAdditionalRecipients := calldataload(
                    BasicOrder_additionalRecipients_length_cdPtr
                )
                // prettier-ignore
                for {} lt(i, totalAdditionalRecipients) {
                    i := add(i, 1)
                } {
                    // Retrieve calldata pointer for additional recipient.
                    let additionalRecipientCdPtr := add(
                        BasicOrder_additionalRecipients_data_cdPtr,
                        mul(AdditionalRecipients_size, i)
                    )

                    // At this point, eventConsiderationArrPtr points to the
                    // beginning of the ReceivedItem struct of the previous
                    // element in the array. Increase it by the size of the
                    // struct to arrive at the pointer for the current element.
                    eventConsiderationArrPtr := add(
                        eventConsiderationArrPtr,
                        ReceivedItem_size
                    )

                    // Write itemType to the ReceivedItem struct.
                    mstore(
                        eventConsiderationArrPtr,
                        additionalRecipientsItemType
                    )

                    // Write token to the next word of the ReceivedItem struct.
                    mstore(
                        add(eventConsiderationArrPtr, OneWord),
                        additionalRecipientsToken
                    )

                    // Copy endAmount & recipient words to ReceivedItem struct.
                    calldatacopy(
                        add(
                            eventConsiderationArrPtr,
                            ReceivedItem_amount_offset
                        ),
                        additionalRecipientCdPtr,
                        TwoWords
                    )
                }
            }
        }

c_0xc512bb96(0x0a9c95689ab781ea17c5bee2122278e80fb93aa8a347141c157ab3c290f4ce4c); /* line */ 
        {
            /**
             * Next, handle offered items. Memory Layout:
             *  EIP712 data for OfferItem
             *   - 0x80:  OfferItem EIP-712 typehash (constant)
             *   - 0xa0:  itemType
             *   - 0xc0:  token
             *   - 0xe0:  identifier (reused for offeredItemsHash)
             *   - 0x100: startAmount
             *   - 0x120: endAmount
             */

            // Place offer item typehash on the stack.
c_0xc512bb96(0x269706659a648da9c77a8ca94bfaf6c7104c5fa8a630cbf362ef753e23facba1); /* line */ 
            c_0xc512bb96(0xc2eaabcb99850f79e01a73f35198e5764d1d13f506c4cea91f2a327c26779f70); /* statement */ 
bytes32 typeHash = _OFFER_ITEM_TYPEHASH;

            // Utilize assembly to enable reuse of memory regions when possible.
c_0xc512bb96(0xf0edbd017f18c30511d651b1981b7dac069387a001f0efbeb463bd4dd0c6aafa); /* line */ 
            assembly {
                /*
                 * 1. Calculate OfferItem EIP712 hash
                 */

                // Write the OfferItem typeHash to memory.
                mstore(BasicOrder_offerItem_typeHash_ptr, typeHash)

                // Write the OfferItem item type to memory.
                mstore(BasicOrder_offerItem_itemType_ptr, offeredItemType)

                // Copy calldata region with (offerToken, offerIdentifier,
                // offerAmount) from OrderParameters to (token, identifier,
                // startAmount) in OfferItem struct. The offerAmount is written
                // to startAmount and endAmount as basic orders do not have
                // dynamic amounts.
                calldatacopy(
                    BasicOrder_offerItem_token_ptr,
                    BasicOrder_offerToken_cdPtr,
                    ThreeWords
                )

                // Copy offerAmount from calldata to endAmount in OfferItem
                // struct.
                calldatacopy(
                    BasicOrder_offerItem_endAmount_ptr,
                    BasicOrder_offerAmount_cdPtr,
                    OneWord
                )

                // Compute EIP712 OfferItem hash, write result to scratch space:
                //   `keccak256(abi.encode(offeredItem))`
                mstore(
                    0,
                    keccak256(
                        BasicOrder_offerItem_typeHash_ptr,
                        EIP712_OfferItem_size
                    )
                )

                /*
                 * 2. Calculate hash of array of EIP712 hashes and write the
                 * result to the corresponding OfferItem struct:
                 *   `keccak256(abi.encodePacked(offerItemHashes))`
                 */
                mstore(BasicOrder_order_offerHashes_ptr, keccak256(0, OneWord))

                /*
                 * 3. Write SpentItem to offer array in OrderFulfilled event.
                 */
                let eventConsiderationArrPtr := add(
                    OrderFulfilled_offer_length_baseOffset,
                    mul(
                        calldataload(
                            BasicOrder_additionalRecipients_length_cdPtr
                        ),
                        OneWord
                    )
                )

                // Set a length of 1 for the offer array.
                mstore(eventConsiderationArrPtr, 1)

                // Write itemType to the SpentItem struct.
                mstore(add(eventConsiderationArrPtr, OneWord), offeredItemType)

                // Copy calldata region with (offerToken, offerIdentifier,
                // offerAmount) from OrderParameters to (token, identifier,
                // amount) in SpentItem struct.
                calldatacopy(
                    add(eventConsiderationArrPtr, AdditionalRecipients_size),
                    BasicOrder_offerToken_cdPtr,
                    ThreeWords
                )
            }
        }

c_0xc512bb96(0x2c6cc0723c43153fbf2ad82577bb642cb7b3b9749c14c0e71d16e19c95ca3de8); /* line */ 
        {
            /**
             * Once consideration items and offer items have been handled,
             * derive the final order hash. Memory Layout:
             *  0x80-0x1c0: EIP712 data for order
             *   - 0x80:   Order EIP-712 typehash (constant)
             *   - 0xa0:   orderParameters.offerer
             *   - 0xc0:   orderParameters.zone
             *   - 0xe0:   keccak256(abi.encodePacked(offerHashes))
             *   - 0x100:  keccak256(abi.encodePacked(considerationHashes))
             *   - 0x120:  orderParameters.basicOrderType (% 4 = orderType)
             *   - 0x140:  orderParameters.startTime
             *   - 0x160:  orderParameters.endTime
             *   - 0x180:  orderParameters.zoneHash
             *   - 0x1a0:  orderParameters.salt
             *   - 0x1c0:  orderParameters.conduitKey
             *   - 0x1e0:  _counters[orderParameters.offerer] (from storage)
             */

            // Read the offerer from calldata and place on the stack.
c_0xc512bb96(0x6ddf502e03232e2b00a0e4d31419fb23ac1a768c87958286f80df7a43cd5ca33); /* line */ 
            c_0xc512bb96(0xbafb7b4698abf6fdab9f66def56a4223b8c27b90bb32a6d84b51a4eec43c9759); /* statement */ 
address offerer;
c_0xc512bb96(0xb4584b8849559cf4b4dfcff95e7606d88513ca1657f2b980a6a5ff2bba3a3b16); /* line */ 
            assembly {
                offerer := calldataload(BasicOrder_offerer_cdPtr)
            }

            // Read offerer's current counter from storage and place on stack.
c_0xc512bb96(0x3f31b744ec1451feb1314e186f5cecf827aa46e6f9addcc457d501b62b7a7fa2); /* line */ 
            c_0xc512bb96(0x5cff834c0c975441b52eaa9e1c186b5c370c866338150fa50a2ba28496438347); /* statement */ 
uint256 counter = _getCounter(offerer);

            // Load order typehash from runtime code and place on stack.
c_0xc512bb96(0x7c275a0299f64196888234ca9382aeb5d173bd08ae1d7b321cf1b24fa68c8fdf); /* line */ 
            c_0xc512bb96(0xa67398311a36d1c3cbdbf0b2ca92660f97d62c6fd3fc928e3b13fea0d31fd2a9); /* statement */ 
bytes32 typeHash = _ORDER_TYPEHASH;

c_0xc512bb96(0xf1f651e2ad6eb03b5363372140b68c1a693961aed08f47cf1640a6ffbe2cf1ec); /* line */ 
            assembly {
                // Set the OrderItem typeHash in memory.
                mstore(BasicOrder_order_typeHash_ptr, typeHash)

                // Copy offerer and zone from OrderParameters in calldata to the
                // Order struct.
                calldatacopy(
                    BasicOrder_order_offerer_ptr,
                    BasicOrder_offerer_cdPtr,
                    TwoWords
                )

                // Copy receivedItemsHash from zero slot to the Order struct.
                mstore(
                    BasicOrder_order_considerationHashes_ptr,
                    mload(receivedItemsHash_ptr)
                )

                // Write the supplied orderType to the Order struct.
                mstore(BasicOrder_order_orderType_ptr, orderType)

                // Copy startTime, endTime, zoneHash, salt & conduit from
                // calldata to the Order struct.
                calldatacopy(
                    BasicOrder_order_startTime_ptr,
                    BasicOrder_startTime_cdPtr,
                    FiveWords
                )

                // Write offerer's counter, retrieved from storage, to struct.
                mstore(BasicOrder_order_counter_ptr, counter)

                // Compute the EIP712 Order hash.
                orderHash := keccak256(
                    BasicOrder_order_typeHash_ptr,
                    EIP712_Order_size
                )
            }
        }

c_0xc512bb96(0x8d2a65da3ba4620cce22445d040b6547369fab00f3ee39b9d8ec9b52eb6e71ae); /* line */ 
        assembly {
            /**
             * After the order hash has been derived, emit OrderFulfilled event:
             *   event OrderFulfilled(
             *     bytes32 orderHash,
             *     address indexed offerer,
             *     address indexed zone,
             *     address fulfiller,
             *     SpentItem[] offer,
             *       > (itemType, token, id, amount)
             *     ReceivedItem[] consideration
             *       > (itemType, token, id, amount, recipient)
             *   )
             * topic0 - OrderFulfilled event signature
             * topic1 - offerer
             * topic2 - zone
             * data:
             *  - 0x00: orderHash
             *  - 0x20: fulfiller
             *  - 0x40: offer arr ptr (0x80)
             *  - 0x60: consideration arr ptr (0x120)
             *  - 0x80: offer arr len (1)
             *  - 0xa0: offer.itemType
             *  - 0xc0: offer.token
             *  - 0xe0: offer.identifier
             *  - 0x100: offer.amount
             *  - 0x120: 1 + recipients.length
             *  - 0x140: recipient 0
             */

            // Derive pointer to start of OrderFulfilled event data
            let eventDataPtr := add(
                OrderFulfilled_baseOffset,
                mul(
                    calldataload(BasicOrder_additionalRecipients_length_cdPtr),
                    OneWord
                )
            )

            // Write the order hash to the head of the event's data region.
            mstore(eventDataPtr, orderHash)

            // Write the fulfiller (i.e. the caller) next for receiver argument.
            mstore(add(eventDataPtr, OrderFulfilled_fulfiller_offset), caller())

            // Write the SpentItem and ReceivedItem array offsets (constants).
            mstore(
                // SpentItem array offset
                add(eventDataPtr, OrderFulfilled_offer_head_offset),
                OrderFulfilled_offer_body_offset
            )
            mstore(
                // ReceivedItem array offset
                add(eventDataPtr, OrderFulfilled_consideration_head_offset),
                OrderFulfilled_consideration_body_offset
            )

            // Derive total data size including SpentItem and ReceivedItem data.
            // SpentItem portion is already included in the baseSize constant,
            // as there can only be one element in the array.
            let dataSize := add(
                OrderFulfilled_baseSize,
                mul(
                    calldataload(BasicOrder_additionalRecipients_length_cdPtr),
                    ReceivedItem_size
                )
            )

            // Emit OrderFulfilled log with three topics (the event signature
            // as well as the two indexed arguments, the offerer and the zone).
            log3(
                // Supply the pointer for event data in memory.
                eventDataPtr,
                // Supply the size of event data in memory.
                dataSize,
                // Supply the OrderFulfilled event signature.
                OrderFulfilled_selector,
                // Supply the first topic (the offerer).
                calldataload(BasicOrder_offerer_cdPtr),
                // Supply the second topic (the zone).
                calldataload(BasicOrder_zone_cdPtr)
            )

            // Restore the zero slot.
            mstore(ZeroSlot, 0)
        }

        // Determine whether order is restricted and, if so, that it is valid.
c_0xc512bb96(0xd876d84ee36bdf55a5ba76ecc75b778bc6946ecdd0b4328704c5fffa504eec41); /* line */ 
        c_0xc512bb96(0x3781a1debe12d8316f5d9d8a9fb161b6494a67533b714f5771e9c624bbf0eccc); /* statement */ 
_assertRestrictedBasicOrderValidity(
            orderHash,
            parameters.zoneHash,
            orderType,
            parameters.offerer,
            parameters.zone
        );

        // Verify and update the status of the derived order.
c_0xc512bb96(0x3df1424e5318b09ab231f9c6057109151bbc8072813a9dc937f55b8dd2a7eac4); /* line */ 
        c_0xc512bb96(0x14c69ecbc64d9bff3835d966b3168c42143ff95621fb433966848b1a446bf6dc); /* statement */ 
_validateBasicOrderAndUpdateStatus(
            orderHash,
            parameters.offerer,
            parameters.signature
        );
    }

    /**
     * @dev Internal function to transfer Ether (or other native tokens) to a
     *      given recipient as part of basic order fulfillment. Note that
     *      conduits are not utilized for native tokens as the transferred
     *      amount must be provided as msg.value.
     *
     * @param amount               The amount to transfer.
     * @param to                   The recipient of the native token transfer.
     * @param additionalRecipients The additional recipients of the order.
     */
    function _transferEthAndFinalize(
        uint256 amount,
        address payable to,
        AdditionalRecipient[] calldata additionalRecipients
    ) internal {c_0xc512bb96(0x9760a8a427bed45a04e023772393d15637d8cf81a704f55850bc09cf730a32ab); /* function */ 

        // Put ether value supplied by the caller on the stack.
c_0xc512bb96(0xe31d7d7947562caefbe552223640587cea10116f64a8f33a404e749ebc88ed69); /* line */ 
        c_0xc512bb96(0xa907b6060e622e8700480d2d4299ad45b0956e552adf68a1473d3fd86e4f3ebc); /* statement */ 
uint256 etherRemaining = msg.value;

        // Retrieve total number of additional recipients and place on stack.
c_0xc512bb96(0x754fcca5a75091b7ccd802c452c50d8fc3f4ed72c35f05849abc59a610aa8856); /* line */ 
        c_0xc512bb96(0xbba26998ecf2aa8d7218f7e7bcb4acfe03e71fb518194027cfea75b936bc2a58); /* statement */ 
uint256 totalAdditionalRecipients = additionalRecipients.length;

        // Skip overflow check as for loop is indexed starting at zero.
c_0xc512bb96(0xae8305cb601fd4c082aa0f4416e185ea166c93e929405a1ad72fb380415d061b); /* line */ 
        unchecked {
            // Iterate over each additional recipient.
c_0xc512bb96(0x2609e4d63f1a10ef1cfa5a11c1bc0d47ca8ca61ebb291b4be747696c1214ced1); /* line */ 
            c_0xc512bb96(0xf3316f7845a8295cd92138bc3dc710442d1f31571aac15261f6c799a5cdb9a32); /* statement */ 
for (uint256 i = 0; i < totalAdditionalRecipients; ++i) {
                // Retrieve the additional recipient.
c_0xc512bb96(0x9ca0e5dd2f5a9975178a5b056a201cfda1ef93204d8a7e0a88c1ea1e028b019f); /* line */ 
                c_0xc512bb96(0xf85f66422c23f5ca1445f5f6eede66c053ecc6b507ab5ad21640a848f76528bd); /* statement */ 
AdditionalRecipient calldata additionalRecipient = (
                    additionalRecipients[i]
                );

                // Read ether amount to transfer to recipient & place on stack.
c_0xc512bb96(0x8f0713e8b88406b644bdaa095105091df0ad8bbe9148a4f70d805a9ac52d0417); /* line */ 
                c_0xc512bb96(0x093ca02a38ba1a4a1be93bb2360e9785b56836a6f65996c609b715fe7e3ecb21); /* statement */ 
uint256 additionalRecipientAmount = additionalRecipient.amount;

                // Ensure that sufficient Ether is available.
c_0xc512bb96(0x4174fb15102cef3af12965f723f2a0ca7d8582199ca26ea11e4964f66696bf33); /* line */ 
                c_0xc512bb96(0x4191f9899ee31301e6e693fd0f02af0239abad9ebfe6b3c6b558459a45fa9b47); /* statement */ 
if (additionalRecipientAmount > etherRemaining) {c_0xc512bb96(0xd83a98ea18c355d3735cab585b6afa4aca75c298ba406bde6f1d09bb177ab56b); /* branch */ 

c_0xc512bb96(0x5484ad33f179f8056b6a9b62d3a3f4307c98ad1dfdf0460653608e0b6e1fa540); /* line */ 
                    revert InsufficientEtherSupplied();
                }else { c_0xc512bb96(0x054fd06048219c8368403476f43be6102efb7ebf651a822a3864588f3e026949); /* branch */ 
}

                // Transfer Ether to the additional recipient.
c_0xc512bb96(0x12e59d8db87b844ab4e261779ef036d5f54072fb5253e5d80b3f854a3542d382); /* line */ 
                c_0xc512bb96(0xaceaab3b694f235c5d7024e47eefe404ffb19bfcb7cec76658a7e00b0701d5ac); /* statement */ 
_transferEth(
                    additionalRecipient.recipient,
                    additionalRecipientAmount
                );

                // Reduce ether value available. Skip underflow check as
                // subtracted value is confirmed above as less than remaining.
c_0xc512bb96(0x39b5d1fcd705f05d6f9010e45f9a25aa513eebd9c3893ab10c512682be73b140); /* line */ 
                c_0xc512bb96(0xd57900be037713ea9cab0e784fb6b291bd631a9c059f091e2e94fc7b483f18e5); /* statement */ 
etherRemaining -= additionalRecipientAmount;
            }
        }

        // Ensure that sufficient Ether is still available.
c_0xc512bb96(0x6efebd1872e1166eb1a16d4f7316e19273975d13645e4699e0126fa9dea68677); /* line */ 
        c_0xc512bb96(0x847c67900ba607e6ccbf8186b08c533b7d31c7cb0686c5d675be26201f258e81); /* statement */ 
if (amount > etherRemaining) {c_0xc512bb96(0xa72e71e78102366cdaa101ff02ff17f4e9ef83473f4ce9552002a00f066691ec); /* branch */ 

c_0xc512bb96(0x04d018afc09dfc32e39991617245ed3d38e7e334056edeea8748c9f78898619b); /* line */ 
            revert InsufficientEtherSupplied();
        }else { c_0xc512bb96(0xade8bb047ab87c859ab08903eef42b079c0e13db41ab0b744f81980e0f828911); /* branch */ 
}

        // Transfer Ether to the offerer.
c_0xc512bb96(0xd6aeeea56e8d64a56d6f59fb4ee996519afd13115a7ccb359e2d750e71a65186); /* line */ 
        c_0xc512bb96(0x95583838486eea764ec0d9338a5f8604ba5d521781f4e9cd39c7fc88bd836447); /* statement */ 
_transferEth(to, amount);

        // If any Ether remains after transfers, return it to the caller.
c_0xc512bb96(0xc259ec89bd6ec518fbd402838bdbc3643e56b560391f9146dd422198e57b94db); /* line */ 
        c_0xc512bb96(0xfde2f40f2463a3c10e8592f494abc77161ad71e45954fd0e3783f611351b3351); /* statement */ 
if (etherRemaining > amount) {c_0xc512bb96(0x70a02eef1685336e2a37416c22e4738777ee672daed521aa77acc0350177a8d4); /* branch */ 

            // Skip underflow check as etherRemaining > amount.
c_0xc512bb96(0x4e1ec1171f6f471e81070c54eca97df7b147dde5fbed8d37f74455df3b126967); /* line */ 
            unchecked {
                // Transfer remaining Ether to the caller.
c_0xc512bb96(0x7ef951cd1b52808c4f81a93fd5e8d3d6e3b43026b9ad6f4779476db0f26f73d9); /* line */ 
                c_0xc512bb96(0x515b9efe24871a357d8a11282104cee08330e4962e47dbe8593ff7b62128b272); /* statement */ 
_transferEth(payable(msg.sender), etherRemaining - amount);
            }
        }else { c_0xc512bb96(0x6b12f833ce528609bf1e278ab9d2ab7689ae2526b62a9839d0f3ce7255ef3b1d); /* branch */ 
}
    }

    /**
     * @dev Internal function to transfer ERC20 tokens to a given recipient as
     *      part of basic order fulfillment.
     *
     * @param offerer     The offerer of the fulfiller order.
     * @param parameters  The basic order parameters.
     * @param fromOfferer A boolean indicating whether to decrement amount from
     *                    the offered amount.
     * @param accumulator An open-ended array that collects transfers to execute
     *                    against a given conduit in a single call.
     */
    function _transferERC20AndFinalize(
        address offerer,
        BasicOrderParameters calldata parameters,
        bool fromOfferer,
        bytes memory accumulator
    ) internal {c_0xc512bb96(0x98423bee818fc94ed3c41852e422414a913cf7d6a84d6724fe7460aa3d8a9f4e); /* function */ 

        // Declare from and to variables determined by fromOfferer value.
c_0xc512bb96(0x635ef1e4558fb23756f4e28071f2dcbb77755e6ebcd5d11f8bfc19a5acc50d20); /* line */ 
        c_0xc512bb96(0x5bc00605b13f424e06463b093aa413647c1e58434b16ee18012c62d892fbd6e2); /* statement */ 
address from;
c_0xc512bb96(0x45ab542e7c2e5d305a5b39ebbedcad2b360e008bcd20d1b60d9a26144f6971dc); /* line */ 
        c_0xc512bb96(0xc1b6c8aacdb4a78e6bb30abd4eb8568d005a915199314ea38c91d33cb8333cf9); /* statement */ 
address to;

        // Declare token and amount variables determined by fromOfferer value.
c_0xc512bb96(0x5f7f5ed77dbd298bfb42cf0d4a482e69920dfbf50f20f3552aa01b5f5fdabe1f); /* line */ 
        c_0xc512bb96(0x4e9d0288d71c6b98c5edac00315649673896c2f73990617f2b83b6e5c3f7f9bd); /* statement */ 
address token;
c_0xc512bb96(0xb3989f4c28edaf48b5e2f0eccf0a5694d4bd85d686d741fd361111a22266333d); /* line */ 
        c_0xc512bb96(0x9d46c3d31848fe5c9e0c284700973487740fe82b15365d6cf39f38d8b7f41c7a); /* statement */ 
uint256 amount;

        // Declare and check identifier variable within an isolated scope.
c_0xc512bb96(0x9dfa731c74d9f9f8a740791b9332f5cddc79619673b58b5066c506b2c038849d); /* line */ 
        {
            // Declare identifier variable determined by fromOfferer value.
c_0xc512bb96(0x5f42275e642462ec10eca4e716fd0ff7aa2d9351ecad77b0a493aaa3d1e43555); /* line */ 
            c_0xc512bb96(0xb162d9380e3c243c3e052ca6e79ca93a4832c49bb2e0c93ce926d0750a2e4cc5); /* statement */ 
uint256 identifier;

            // Set ERC20 token transfer variables based on fromOfferer boolean.
c_0xc512bb96(0xbe370da8590febd87d9db2b539f8e8eea10c68617e4fab81e128d2413b476620); /* line */ 
            c_0xc512bb96(0x16e61b72e785e2bdbae35f62210647cfee55329ec0a4f6209db94115ee9079ce); /* statement */ 
if (fromOfferer) {c_0xc512bb96(0x23594ee66834f9066289fc76cf412a6cf7b05c3a9fd757d0d1a968b55c654942); /* branch */ 

                // Use offerer as from value and msg.sender as to value.
c_0xc512bb96(0x1f1b68fec522c1604759a7af02216cf88a02637e287750094c956683ab5f74fb); /* line */ 
                c_0xc512bb96(0x97d9cd0c52fc5d297d5bb16deb5b10ffabfebf2f38c9da2f67d7f2d29cf246d9); /* statement */ 
from = offerer;
c_0xc512bb96(0xf3a6b2a54db437238986e49839c106292a07a0781acbb3b7c49e02115179c571); /* line */ 
                c_0xc512bb96(0x492b4b6a4cffa5fb4eb040a79873efb23c72982169ad974226d38691baa561f9); /* statement */ 
to = msg.sender;

                // Use offer token and related values if token is from offerer.
c_0xc512bb96(0x8498a8aab205f7a6e1c7f2a94b718aa1cac938f82477269e12994ace50f9a3ce); /* line */ 
                c_0xc512bb96(0x28781e16a8cf7c7050abd858e58c8b2b51202282c1435875cfa26f72b46460ba); /* statement */ 
token = parameters.offerToken;
c_0xc512bb96(0xa683553b4b60654ff6a6aaf52c28e75405dcc1905e92a0be4843fdff37fdd29e); /* line */ 
                c_0xc512bb96(0xa3bea6d2090acfb042e26be7d943ad8e7fe720f4fe3049b2daf1ce2687935cbc); /* statement */ 
identifier = parameters.offerIdentifier;
c_0xc512bb96(0x2907328268a5e90df9b65ad9349f4aa8502852283c1627c82ddac30acb5cabda); /* line */ 
                c_0xc512bb96(0x3da97222c6019fc1b2071dc525a826cf14f46a1e1cfb46a3dacaa9f7b4139a7f); /* statement */ 
amount = parameters.offerAmount;
            } else {c_0xc512bb96(0xd88d63e9a244c43feacc68086699b3636349c2f495bc04bc122d118b74292dc1); /* branch */ 

                // Use msg.sender as from value and offerer as to value.
c_0xc512bb96(0xd7237338fe6c72f841a8891f82d90fb984a98d67be50a6fb88f4f1f8bbc989d6); /* line */ 
                c_0xc512bb96(0xa55cb421647b10a9c30e92d1015c454403025f92772b742a7e071eca6c6d2278); /* statement */ 
from = msg.sender;
c_0xc512bb96(0xe87d6c05613af58c7eed722d01e939a453c06f19c185ad9708e12f23db56d193); /* line */ 
                c_0xc512bb96(0xd9af2ae721abfce87855d84d415e528f3de132ef2891d9e3b3c5248765cb7e9b); /* statement */ 
to = offerer;

                // Otherwise, use consideration token and related values.
c_0xc512bb96(0xff5b7a4a64942b74ab9baf03a12eb478eb7c26c01078fd71acbdf189b1d5ab77); /* line */ 
                c_0xc512bb96(0x9559211dfa853d673f935709973534e2a0b6bd10baa8663894bfad862f7b61ae); /* statement */ 
token = parameters.considerationToken;
c_0xc512bb96(0x1e3f656c80da77df75c863679b5c05c2c860ea3962c1f9c6d9c825cc24b474d2); /* line */ 
                c_0xc512bb96(0xcc26dfe46991e0dd411200b142fa39d9a48f84b45fddecc03298357b7c9f5d2b); /* statement */ 
identifier = parameters.considerationIdentifier;
c_0xc512bb96(0x4fd9cdf35a0109bccded33b636ceb878910465f378d861f8a50a0876bd13c126); /* line */ 
                c_0xc512bb96(0x224fb1be11a97723f6c3daac89d6d312ec19ab22d856b644ea108ec300bd934b); /* statement */ 
amount = parameters.considerationAmount;
            }

            // Ensure that no identifier is supplied.
c_0xc512bb96(0x7de3d0a1bb3caea26b3200549c46a45141518f2d668eeae2f3e3f4153e8509d6); /* line */ 
            c_0xc512bb96(0x2893bf458b7bda1e8bf7fc67fbed70dd0623d5e97986993c9f70d4789cadb70e); /* statement */ 
if (identifier != 0) {c_0xc512bb96(0x3e596bcbfc8aa1d1fd2fd2ea30ce492d6cd8b18f54cbef73184c43aa0163dae8); /* branch */ 

c_0xc512bb96(0x8fc263567d08296895a48b9411ba17073a90bfbc103f413bd8f3ff15a8405372); /* line */ 
                revert UnusedItemParameters();
            }else { c_0xc512bb96(0x61d1039bae245c467e5dd7aae59305b09e0f47c9ae615edae7fdb397b7694468); /* branch */ 
}
        }

        // Determine the appropriate conduit to utilize.
c_0xc512bb96(0x035a55d2db7701850b344c762c4fd61c34d104b3ed491572951d95ed778414ee); /* line */ 
        c_0xc512bb96(0x31218c797bb6dda0914ccceab54e50241b11489fd3cd7928f8c091f8caada92e); /* statement */ 
bytes32 conduitKey;

        // Utilize assembly to derive conduit (if relevant) based on route.
c_0xc512bb96(0x9293c39f7deecf0854d1dc407b1b55eaf140887880c1ed8d345be5f6d8c04716); /* line */ 
        assembly {
            // Use offerer conduit if fromOfferer, fulfiller conduit otherwise.
            conduitKey := calldataload(
                sub(
                    BasicOrder_fulfillerConduit_cdPtr,
                    mul(fromOfferer, OneWord)
                )
            )
        }

        // Retrieve total number of additional recipients and place on stack.
c_0xc512bb96(0xe84ff7fa9e99ad1dd91c7d73431028681b26d87205fbe52058d54f0df6ea1406); /* line */ 
        c_0xc512bb96(0x115d4f6d68a2d274459c9e8a6e7d95608ce850cdbc189cf29583cce7b60d357d); /* statement */ 
uint256 totalAdditionalRecipients = (
            parameters.additionalRecipients.length
        );

        // Iterate over each additional recipient.
c_0xc512bb96(0x835a327c2f7f16403223311c58879bd2f650d273529b79c903e78c50a1115947); /* line */ 
        c_0xc512bb96(0xb3eedeafb439d75d7b0ab191e9245b586570c64f49972a44ea173a17b3abc1b0); /* statement */ 
for (uint256 i = 0; i < totalAdditionalRecipients; ) {
            // Retrieve the additional recipient.
c_0xc512bb96(0x888392d4674f685985896da00d0a7247bf7843178f2d7fd4ef7eae953f6637fc); /* line */ 
            c_0xc512bb96(0xc0aedf766455dc7cf741e67a6a051f3bd5eae36c5133d8086c86e7f10e039327); /* statement */ 
AdditionalRecipient calldata additionalRecipient = (
                parameters.additionalRecipients[i]
            );

c_0xc512bb96(0x5cf52e458ec7d970d5dfd2bf2b9e09fceb672905780326dc3fc16a64e4382bcf); /* line */ 
            c_0xc512bb96(0xd9335f108b12156e187cd1f0f1dd0ea2db6b6fe02bcc99cf1b14f0d1698136f5); /* statement */ 
uint256 additionalRecipientAmount = additionalRecipient.amount;

            // Decrement the amount to transfer to fulfiller if indicated.
c_0xc512bb96(0x44b7efde70b4440d48b57d83a6d8f3a311d8b7248035ad592c57b66fbb929dd0); /* line */ 
            c_0xc512bb96(0xead466954bcc8c1e1b85dd9415ef8604b041b42c027b71b58e1cb870777cfd2e); /* statement */ 
if (fromOfferer) {c_0xc512bb96(0xb12d1cc2df96e3840fb033f36b866fba8689bfe5b556ef3cbc7b1344f3f3131b); /* branch */ 

c_0xc512bb96(0x2230e22597f8eeb9e923c52f27d9bcbfa9fce3f72079b4de8063bd85666fd1bb); /* line */ 
                c_0xc512bb96(0x5c67b02b3ccd96bb06d413f24cef82c2890b58de0c82a3dfac31ceea3b928958); /* statement */ 
amount -= additionalRecipientAmount;
            }else { c_0xc512bb96(0x2453c0ab28f955b66e255da0953a78462c70e1e687125092508e090ee43c47b6); /* branch */ 
}

            // Transfer ERC20 tokens to additional recipient given approval.
c_0xc512bb96(0x1c3ba1c2df2a1c29f8e0280510e91989942dc0d81360058b74b8215f762e1605); /* line */ 
            c_0xc512bb96(0x764d5575ac1f3f6389b160e469ee8ce9daaaddbb9de4fbe3144e1682b583dcd1); /* statement */ 
_transferERC20(
                token,
                from,
                additionalRecipient.recipient,
                additionalRecipientAmount,
                conduitKey,
                accumulator
            );

            // Skip overflow check as for loop is indexed starting at zero.
c_0xc512bb96(0x17644a80ba53f1271260e66f0c75d9410daaaab9857aeef2b4758d91e94a1b4e); /* line */ 
            unchecked {
c_0xc512bb96(0xfd26befead2dc1509c1244e492285542f11936f2fb8030cd43f53d2055ad3bb8); /* line */ 
                ++i;
            }
        }

        // Transfer ERC20 token amount (from account must have proper approval).
c_0xc512bb96(0x17746c04fbd488d2b680c22733c1b152b5ea75b045beb203194443f2f8040057); /* line */ 
        c_0xc512bb96(0x7e04cab6afd0b26faa845e5c4b6c38e66ba76c2ac2aef364b53dd66776a6f793); /* statement */ 
_transferERC20(token, from, to, amount, conduitKey, accumulator);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0x89f016c5(bytes32 c__0x89f016c5) pure {}


import { OrderType } from "./ConsiderationEnums.sol";

import {
    OrderParameters,
    Order,
    AdvancedOrder,
    OrderComponents,
    OrderStatus,
    CriteriaResolver
} from "./ConsiderationStructs.sol";

import "./ConsiderationConstants.sol";

import { Executor } from "./Executor.sol";

import { ZoneInteraction } from "./ZoneInteraction.sol";

/**
 * @title OrderValidator
 * @author 0age
 * @notice OrderValidator contains functionality related to validating orders
 *         and updating their status.
 */
contract OrderValidator is Executor, ZoneInteraction {
function c_0x545a32c6(bytes32 c__0x545a32c6) internal pure {}

    // Track status of each order (validated, cancelled, and fraction filled).
    mapping(bytes32 => OrderStatus) private _orderStatus;

    /**
     * @dev Derive and set hashes, reference chainId, and associated domain
     *      separator during deployment.
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     */
    constructor(address conduitController) Executor(conduitController) {c_0x545a32c6(0x921d91661a6af0c6c576aded3f06e7069190179d8132691e5613d723dad4d6ba); /* function */ 
}

    /**
     * @dev Internal function to verify and update the status of a basic order.
     *
     * @param orderHash The hash of the order.
     * @param offerer   The offerer of the order.
     * @param signature A signature from the offerer indicating that the order
     *                  has been approved.
     */
    function _validateBasicOrderAndUpdateStatus(
        bytes32 orderHash,
        address offerer,
        bytes memory signature
    ) internal {c_0x545a32c6(0xd0c7cdf909ee65fa90401f03c85fdb5fbca21b5bc550942af7c60fec4f086b78); /* function */ 

        // Retrieve the order status for the given order hash.
c_0x545a32c6(0x6e98c6b9b62900358f85c163bf479a5c25c4fdb0f01b0ed208e1d2bc38ecde42); /* line */ 
        c_0x545a32c6(0x88d7644073498bb7a89e46a3f28b36bf24062a7be99ad904b3ee9b424bdc5d71); /* statement */ 
OrderStatus storage orderStatus = _orderStatus[orderHash];

        // Ensure order is fillable and is not cancelled.
c_0x545a32c6(0xa46ff9c2d19d4792b6c7b366bf5841921a51aab9e36eab2e6c929945234abbdb); /* line */ 
        c_0x545a32c6(0xb7236bf3cbe477d84d927cc1a006317333d41ae9bdb8a1863df97a32b396f3b5); /* statement */ 
_verifyOrderStatus(
            orderHash,
            orderStatus,
            true, // Only allow unused orders when fulfilling basic orders.
            true // Signifies to revert if the order is invalid.
        );

        // If the order is not already validated, verify the supplied signature.
c_0x545a32c6(0x27ff61f2edaa7b68fe25bc90daf4a1612a09d6e0d6d470b6a918f89b65a99f07); /* line */ 
        c_0x545a32c6(0x54801040023cd7ab8464911b123c9acf8f80bd9d9aa1007ca7b24e17e6ff3acf); /* statement */ 
if (!orderStatus.isValidated) {c_0x545a32c6(0x2ffe082ae2c0edb3a5fedffdbede8e7bdf1061fd0be2535b4e20a43b1e4e0703); /* branch */ 

c_0x545a32c6(0xf1a5c47bc8acdb39b422340d91f759f9a10ed2b23d7a67830ccbfaf62b3caa5d); /* line */ 
            c_0x545a32c6(0xb17004ac3827ac2d4d49c9a524c1edc7b30e11b9a4dd53bd240004b1cdc897a1); /* statement */ 
_verifySignature(offerer, orderHash, signature);
        }else { c_0x545a32c6(0xb94abd05dc9660334a6d784cfbcce6ada7ffd8816c6c3d8e5028bdcacc09709f); /* branch */ 
}

        // Update order status as fully filled, packing struct values.
c_0x545a32c6(0x34bc7ec3d660bc66ba4b836900f0f21b5d57a3dd60fc9af8354b328874bc5b11); /* line */ 
        c_0x545a32c6(0xfdb8d34456e38d3201d410dafa4f3eec8ee39d7101505a3258eaf04bf2629755); /* statement */ 
orderStatus.isValidated = true;
c_0x545a32c6(0xcea530a337646b6e018870dc5b46be9a43e9dc04cded8672484af013ae6e1547); /* line */ 
        c_0x545a32c6(0x355f35b1aa5520f97c576edc589d9c8aa01b550a51703c41b94f9f7a453f9c6d); /* statement */ 
orderStatus.isCancelled = false;
c_0x545a32c6(0xa7d5b4e4c4118ea114a5c2f2e38e0ca611b5841c6adba178a03b970853e740b6); /* line */ 
        c_0x545a32c6(0x1b030baddb5913a567a3acaeaa593f3fd126b24dbb3ab3c8f071248001fa3179); /* statement */ 
orderStatus.numerator = 1;
c_0x545a32c6(0xb22329f6891b1fe6bf679ba03dd73682e5898c36ed168a0b9332476a5cd58f48); /* line */ 
        c_0x545a32c6(0xe9fdd8a96b4a3f35f47af068744cc0ae7b14f829a9e60acf5fb48a02fe00455c); /* statement */ 
orderStatus.denominator = 1;
    }

    /**
     * @dev Internal function to validate an order, determine what portion to
     *      fill, and update its status. The desired fill amount is supplied as
     *      a fraction, as is the returned amount to fill.
     *
     * @param advancedOrder     The order to fulfill as well as the fraction to
     *                          fill. Note that all offer and consideration
     *                          amounts must divide with no remainder in order
     *                          for a partial fill to be valid.
     * @param criteriaResolvers An array where each element contains a reference
     *                          to a specific offer or consideration, a token
     *                          identifier, and a proof that the supplied token
     *                          identifier is contained in the order's merkle
     *                          root. Note that a criteria of zero indicates
     *                          that any (transferable) token identifier is
     *                          valid and that no proof needs to be supplied.
     * @param revertOnInvalid   A boolean indicating whether to revert if the
     *                          order is invalid due to the time or status.
     * @param priorOrderHashes  The order hashes of each order supplied prior to
     *                          the current order as part of a "match" variety
     *                          of order fulfillment (e.g. this array will be
     *                          empty for single or "fulfill available").
     *
     * @return orderHash      The order hash.
     * @return newNumerator   A value indicating the portion of the order that
     *                        will be filled.
     * @return newDenominator A value indicating the total size of the order.
     */
    function _validateOrderAndUpdateStatus(
        AdvancedOrder memory advancedOrder,
        CriteriaResolver[] memory criteriaResolvers,
        bool revertOnInvalid,
        bytes32[] memory priorOrderHashes
    )
        internal
        returns (
            bytes32 orderHash,
            uint256 newNumerator,
            uint256 newDenominator
        )
    {c_0x545a32c6(0x707f6e225a0b42595f935b4fa7ed8ffbf19497cda87fbe18befa537227c8a945); /* function */ 

        // Retrieve the parameters for the order.
c_0x545a32c6(0xf01be10197cfb3d1409ffebeb82dc94cc4b38ec6f8017287e89a1cb074b976ae); /* line */ 
        c_0x545a32c6(0xd2cd72f73b9679ed91b07e3a67505a5cddc32375688caad7c267fded0e9c5075); /* statement */ 
OrderParameters memory orderParameters = advancedOrder.parameters;

        // Ensure current timestamp falls between order start time and end time.
c_0x545a32c6(0x1c742e4854479bc4ca73e4111a69dc02bc872f8bb93d5da3d2060cdc810a8bef); /* line */ 
        c_0x545a32c6(0x2b638684c182994dd1dfac0230746f6792520e6e7aa2ec81a19a0fb262827056); /* statement */ 
if (
            !_verifyTime(
                orderParameters.startTime,
                orderParameters.endTime,
                revertOnInvalid
            )
        ) {c_0x545a32c6(0xe2f40f3c1de0f71b644ae1cd2fde2f7eb580d492afda6f88cd67714d74bc1cbf); /* branch */ 

            // Assuming an invalid time and no revert, return zeroed out values.
c_0x545a32c6(0x06e5870d4c72fde22e5415970216cf96d935b79fc6ee909b1957efdff0e9557a); /* line */ 
            c_0x545a32c6(0xb2d41942c2086f8da6b4d2ffda899bebfd0ba8c50981689cf6c206a50f33680c); /* statement */ 
return (bytes32(0), 0, 0);
        }else { c_0x545a32c6(0x6482e63aa1eab2468e79387d58f0cf1c39bb0bb44de2f0327a0648bbc1b28e1c); /* branch */ 
}

        // Read numerator and denominator from memory and place on the stack.
c_0x545a32c6(0xbfe27085c6434e3d67a5d317e2eb31ca49f1a34238f7abeea5fb1a2207b79e34); /* line */ 
        c_0x545a32c6(0xa0b8aa653b9f047f482ecbd924aa67874e2317550ea71d213db18ca805085a25); /* statement */ 
uint256 numerator = uint256(advancedOrder.numerator);
c_0x545a32c6(0x37f7d9f11b74a129783c3bd63c25950b3921f8ebf2d4144dc5785ebc5157ffcf); /* line */ 
        c_0x545a32c6(0x8db8d608588eb0212c27a4b69bca4b36c619369e293f69c414115ee3e3a51c13); /* statement */ 
uint256 denominator = uint256(advancedOrder.denominator);

        // Ensure that the supplied numerator and denominator are valid.
c_0x545a32c6(0x8f6f7c9058da258471fb65347d97d9d6aedcc070a0cfde013eebd18634f83ae5); /* line */ 
        c_0x545a32c6(0x5674f1c7c04b53285883cc457ee86f3ccfd226f3a97590bc965dedbdfabdd9e4); /* statement */ 
if (numerator > denominator || numerator == 0) {c_0x545a32c6(0xb057982278fa1288edd4cd9b9a44ce9e79c73976d7656a0f5790852128c7d809); /* branch */ 

c_0x545a32c6(0xa93aed8289c3807431e019b82ff800f8ac07de63627e50ab3acfd8c805017e82); /* line */ 
            revert BadFraction();
        }else { c_0x545a32c6(0x64fe608d353814214e48c2f4e5350de1e1b8ec74d82bf47622086bd0346fae50); /* branch */ 
}

        // If attempting partial fill (n < d) check order type & ensure support.
c_0x545a32c6(0x069d026e119c6b73690290aa144e42aaa1623037e7956c76c8f35f0a50340ae8); /* line */ 
        c_0x545a32c6(0xbbdedc24e50bb0e6c8934f37da62b2718454fb9960b54e8803d8fb4d2a705fbd); /* statement */ 
if (
            numerator < denominator &&
            _doesNotSupportPartialFills(orderParameters.orderType)
        ) {c_0x545a32c6(0x50a91dbe9ac0085ce28e421a4dc68f3bdd127cdf982392404ecb659fa59073d8); /* branch */ 

            // Revert if partial fill was attempted on an unsupported order.
c_0x545a32c6(0xe062be05af13e35458b79feeb47f08e302eb3f9b4067eff91708242f39dbe85b); /* line */ 
            revert PartialFillsNotEnabledForOrder();
        }else { c_0x545a32c6(0x472e9801645f9191ffee35e58a11bb9340643e603d41bcc1e87c20c04f65b151); /* branch */ 
}

        // Retrieve current counter & use it w/ parameters to derive order hash.
c_0x545a32c6(0x6a455a902e883687a3d5cd7f092dd27911a288e4b460be3a4392a77aa6af376f); /* line */ 
        c_0x545a32c6(0x2f09cc9defdc902c680d94613c9a6d49f3616257e64ac65675534d3823f19e85); /* statement */ 
orderHash = _assertConsiderationLengthAndGetOrderHash(orderParameters);

        // Ensure restricted orders have a valid submitter or pass a zone check.
c_0x545a32c6(0xe2274cfa2bc7bd2d992742d41011c7abd8f4517ad44e6d4523cf334054b78b71); /* line */ 
        c_0x545a32c6(0xb22352ad2d923aa1742075cf97622d985d9f82685e509bf12f10587707ea55c9); /* statement */ 
_assertRestrictedAdvancedOrderValidity(
            advancedOrder,
            criteriaResolvers,
            priorOrderHashes,
            orderHash,
            orderParameters.zoneHash,
            orderParameters.orderType,
            orderParameters.offerer,
            orderParameters.zone
        );

        // Retrieve the order status using the derived order hash.
c_0x545a32c6(0x0bd73728a85fdbdaf4eeb6746dfd9fb5659ed104946a5680dcab852fceae2e25); /* line */ 
        c_0x545a32c6(0x6684ac55c5ba74000e64d1d57a0b5e64b7f8a9c85eef4e495a0a2e47cf86ccad); /* statement */ 
OrderStatus storage orderStatus = _orderStatus[orderHash];

        // Ensure order is fillable and is not cancelled.
c_0x545a32c6(0x84f494b4be7bd712eb2af0a2d08826628e3a0f3752237932971b50b20dfe0380); /* line */ 
        c_0x545a32c6(0x96a54731f9ed8fd5cfdfa1c48ac8c453380d6f35f823200276b889b0725032f7); /* statement */ 
if (
            !_verifyOrderStatus(
                orderHash,
                orderStatus,
                false, // Allow partially used orders to be filled.
                revertOnInvalid
            )
        ) {c_0x545a32c6(0xe999a168b4820862ec974b946d847c7e36ae7891ac22886ff3914fa697584024); /* branch */ 

            // Assuming an invalid order status and no revert, return zero fill.
c_0x545a32c6(0x7a7a371b9508ae49afaea07a8eb5ec75e9d3d2c485c9cc4b7fd24e0b07acdb8c); /* line */ 
            c_0x545a32c6(0x4e051ee98a5fcb8785d968a41151eddc84bacbbbb428e94e311e8a28f437d4bc); /* statement */ 
return (orderHash, 0, 0);
        }else { c_0x545a32c6(0x81cda066a49bb670662fd8d07ee33cecbfbde6eae45aeb0d45152f1fc239dfe6); /* branch */ 
}

        // If the order is not already validated, verify the supplied signature.
c_0x545a32c6(0x15e3af64d8cd1d2e90845d7e06b1aa7ce23dff4b59d7922e08f4187cfb661335); /* line */ 
        c_0x545a32c6(0xd0f823c08ac70dc16e06a5542928d1f8129dea6ddf9638588ba6ac5c8f3fad35); /* statement */ 
if (!orderStatus.isValidated) {c_0x545a32c6(0x7e85f58068baadb95d939d42ee3ea081a1fe736a5774db76aed50c22caa51cc0); /* branch */ 

c_0x545a32c6(0x231835271b1096710ac4ad648b9ec2bf5e981ab8e5c03ae87f684cbbeb7492a8); /* line */ 
            c_0x545a32c6(0x9f654363a674fdef806f8cbd99a065fb90607e960b7597ec503ae10605e06720); /* statement */ 
_verifySignature(
                orderParameters.offerer,
                orderHash,
                advancedOrder.signature
            );
        }else { c_0x545a32c6(0xd498eb44ac0fcb389f7cc21dad28d250c64fd728020e532b3c18f7c3640d8ece); /* branch */ 
}

        // Read filled amount as numerator and denominator and put on the stack.
c_0x545a32c6(0x7f41bd1ea7d64ec4b2dbe67698c82fcfc7fc4ca1d1678d47097650e5d261df13); /* line */ 
        c_0x545a32c6(0x24e4783c2ab98d7d3123d48edb652d132b4f859475eae18f831ff0633ee94655); /* statement */ 
uint256 filledNumerator = orderStatus.numerator;
c_0x545a32c6(0x69ff3e22e962d625314625b599da95239cbea10154468cbad69bbabc3395b7d4); /* line */ 
        c_0x545a32c6(0x1874c33e35f48feb5fc9b4c20ea7b9ff42dee48e78092c1b709bacaa5e0273a3); /* statement */ 
uint256 filledDenominator = orderStatus.denominator;

        // If order (orderStatus) currently has a non-zero denominator it is
        // partially filled.
c_0x545a32c6(0x8900c0a96c6552c4d1d52543b435bcc3ec41314afa74a809ff42130c71dd4b9b); /* line */ 
        c_0x545a32c6(0x8906ab56e38dfa1df90c9b311ac774c50bd30b1bf9d074d194a9df20dd687566); /* statement */ 
if (filledDenominator != 0) {c_0x545a32c6(0xf2aed10833d8ed6c2afca2060b4f90cb7fec95895cfece54a70ad32aac146ac2); /* branch */ 

            // If denominator of 1 supplied, fill all remaining amount on order.
c_0x545a32c6(0x322eb9299fbb0439febfecf89c530cfe6da7bfac438dee7ab0bf86ea1ec7cd21); /* line */ 
            c_0x545a32c6(0x57f1117e05192b05720e0238793617a10378a1377937b1755f4eef583d83d4bb); /* statement */ 
if (denominator == 1) {c_0x545a32c6(0x12faf3e03d83f428c300c028d4aa1d157cd423d6b0be11b7e6064b9e5e95eda2); /* branch */ 

                // Scale numerator & denominator to match current denominator.
c_0x545a32c6(0xa4b171ba0bc5a88c3c7173e559c74c653d619b24ed644cb1dcacaf4ce52a90e7); /* line */ 
                c_0x545a32c6(0x76c41f8fe1452438d2c0615eaac8cd4c0025297f40d9917d48a725b97df2a4dd); /* statement */ 
numerator = filledDenominator;
c_0x545a32c6(0x1a3f0f69d3d8a1ad79d99116217a33d43ad63954b7235f75b3f396e5c84000f6); /* line */ 
                c_0x545a32c6(0x61b389b5fa946ed640f38ad762079e3ca298af9e7a53879ec569b67fa665ee50); /* statement */ 
denominator = filledDenominator;
            }
            // Otherwise, if supplied denominator differs from current one...
            else {c_0x545a32c6(0x288ed1b1ace53742162c2785fd0cfe8c1a13b200f6a05cbec71a88bc2652f3c1); /* statement */ 
c_0x545a32c6(0xe9fcf59a9084bc48a50ba41ffb78767eedf2b907b39bf5c46d097cf10c55c92e); /* branch */ 
if (filledDenominator != denominator) {c_0x545a32c6(0xe8295ee8be88067be47235db16144a1e0acd808a0adc749f83f103ab80d1edab); /* branch */ 

                // scale current numerator by the supplied denominator, then...
c_0x545a32c6(0xff5172d61cedf5e0c9da337e892e67377e7f4f03bd4df9f5937c5c5ba8cc33d9); /* line */ 
                c_0x545a32c6(0x3e6c0dd391bc914645f595180ea73b15300f005f76dd3eeea3b56e7dda395a3b); /* statement */ 
filledNumerator *= denominator;

                // the supplied numerator & denominator by current denominator.
c_0x545a32c6(0x33a303528431782f5d397d461efae2315b020818ac89075429d8469f76540626); /* line */ 
                c_0x545a32c6(0xd9ec86dcf2047289052153c340dfe2bcefb052a042298597d93cf568079b9ac3); /* statement */ 
numerator *= filledDenominator;
c_0x545a32c6(0x38418b14fc6f582210a9000b68438f1367224d5ca22475cd356cd3b0fccd156a); /* line */ 
                c_0x545a32c6(0xa737e879e82a1c15c21f0b7f05bccd53c3d7e89ae34653ef7509030f9ed5699c); /* statement */ 
denominator *= filledDenominator;
            }else { c_0x545a32c6(0x8c1c2fdb35138b231fb09fa1fe1c3fe1f5ae6c195ad00645d4744fa7d75c98a0); /* branch */ 
}}

            // Once adjusted, if current+supplied numerator exceeds denominator:
c_0x545a32c6(0x1ddfc83ab43aa73040082ef918b7255933fcf40d4eafc83931944076ce570ab5); /* line */ 
            c_0x545a32c6(0x99f28dedcbd800b701e6b31d4b0c7519f5e7f41d5fc5a8c0bb25add12fdcbe52); /* statement */ 
if (filledNumerator + numerator > denominator) {c_0x545a32c6(0xb2428cec4ea1f254e929f958477c80740b89962e31a1791855bc729148c9ecd4); /* branch */ 

                // Skip underflow check: denominator >= orderStatus.numerator
c_0x545a32c6(0x93528b215e82e3bcdd435289d5afcd771b0621f11696b8143f453ddeb8b5fcec); /* line */ 
                unchecked {
                    // Reduce current numerator so it + supplied = denominator.
c_0x545a32c6(0xf4a8f0b6416f6041d7f934f5953740784de284c468472e355fcedd3a4bb359ca); /* line */ 
                    c_0x545a32c6(0x02a982d957473ffa43610b2e9ccaaad7a91b578076fcbea6b709656156003870); /* statement */ 
numerator = denominator - filledNumerator;
                }
            }else { c_0x545a32c6(0x8f4cdec7d43cce3f965ef8579788e3482a472a065613cbc07e6e75e1f9f6f646); /* branch */ 
}

            // Increment the filled numerator by the new numerator.
c_0x545a32c6(0x743f38d6650d0f2bd69ecffe94b116edbd1dd505b58cded0ecef154edc8f6a68); /* line */ 
            c_0x545a32c6(0x4040f3775935949a4251f7a10c75a5822a7260fac4d202008e77a54b51b963f5); /* statement */ 
filledNumerator += numerator;

            // Use assembly to ensure fractional amounts are below max uint120.
c_0x545a32c6(0x009281297012f516ea3c8dfe7df8d410a7656e46d5b0cb678b65fa46f19a2275); /* line */ 
            assembly {
                // Check filledNumerator and denominator for uint120 overflow.
                if or(
                    gt(filledNumerator, MaxUint120),
                    gt(denominator, MaxUint120)
                ) {
                    // Derive greatest common divisor using euclidean algorithm.
                    function gcd(_a, _b) -> out {
                        for {

                        } _b {

                        } {
                            let _c := _b
                            _b := mod(_a, _c)
                            _a := _c
                        }
                        out := _a
                    }
                    let scaleDown := gcd(
                        numerator,
                        gcd(filledNumerator, denominator)
                    )

                    // Ensure that the divisor is at least one.
                    let safeScaleDown := add(scaleDown, iszero(scaleDown))

                    // Scale all fractional values down by gcd.
                    numerator := div(numerator, safeScaleDown)
                    filledNumerator := div(filledNumerator, safeScaleDown)
                    denominator := div(denominator, safeScaleDown)

                    // Perform the overflow check a second time.
                    if or(
                        gt(filledNumerator, MaxUint120),
                        gt(denominator, MaxUint120)
                    ) {
                        // Store the Panic error signature.
                        mstore(0, Panic_error_signature)

                        // Set arithmetic (0x11) panic code as initial argument.
                        mstore(Panic_error_offset, Panic_arithmetic)

                        // Return, supplying Panic signature & arithmetic code.
                        revert(0, Panic_error_length)
                    }
                }
            }
            // Skip overflow check: checked above unless numerator is reduced.
c_0x545a32c6(0x030cc6c10f55c4bb299e45d8ddbd007d0ea419e3f826839550d754410930c516); /* line */ 
            unchecked {
                // Update order status and fill amount, packing struct values.
c_0x545a32c6(0x404603bbd072a99bd9eaf43d0fd928391e44c9dd38f3066d1d9d1a2c02bd1ee2); /* line */ 
                c_0x545a32c6(0x2c6cc4e5630d9d5917864e13a7e672b1259be5a6e7d7a0ae8dbb6afcd6e2fcbe); /* statement */ 
orderStatus.isValidated = true;
c_0x545a32c6(0x1580be1befd6b384ddf88ed88904c89e0957de2ea03bc5daf17723333bc9cbc9); /* line */ 
                c_0x545a32c6(0x1e588223b9c760ec96125d5a20e57539271eaaa4e9cfd56ef380cd4193eb4d52); /* statement */ 
orderStatus.isCancelled = false;
c_0x545a32c6(0x87dbffe3c62f3054d00d3097ce1424093ba2e646f95597f8a9cbd20418636ce6); /* line */ 
                c_0x545a32c6(0x1e342a688536a4e2a599f4debaddd26326d805fcdddd319862010e0a8cc1b9c6); /* statement */ 
orderStatus.numerator = uint120(filledNumerator);
c_0x545a32c6(0x3fb2ed1b8a15a7b63b99e4f9aaf01f67a0aa5ae54eeed07e5def46a13d72ef51); /* line */ 
                c_0x545a32c6(0x4182f8842505c6c962e06dfcf6bafd7d8c68805014bb18597f1348ce50feaa21); /* statement */ 
orderStatus.denominator = uint120(denominator);
            }
        } else {c_0x545a32c6(0x0742661a7d61803471f2d678a88166aa7d3e0912c36187a0709b1d87ed6c9121); /* branch */ 

            // Update order status and fill amount, packing struct values.
c_0x545a32c6(0xe7bfcdb6207250ea7f9cb1e675483b7e5a503394b6a7c86d3f35e2b4251d2df0); /* line */ 
            c_0x545a32c6(0xc18bca261ae05a8bb2912a76717f0c355f3b2e8390db6e971aba6d2e4a98c64b); /* statement */ 
orderStatus.isValidated = true;
c_0x545a32c6(0xdadba6a7a08aa3da5861f28029ec5cf1dfc983fa937ba7b5ad37164201d5258e); /* line */ 
            c_0x545a32c6(0x50291b2037eefa52990685f9718ff15d563c4775296bc51afe5cff783e7d032d); /* statement */ 
orderStatus.isCancelled = false;
c_0x545a32c6(0xa14b1b20c93a8279d39f78b98cd483446718704b8886ef4158a41eafd8dc2e14); /* line */ 
            c_0x545a32c6(0x3cf4cfbb3044f5e24b9773caf3924db5b3f8d972000ad4bcd076c5e9c50c4ded); /* statement */ 
orderStatus.numerator = uint120(numerator);
c_0x545a32c6(0xbcde370567b944f3794cbf55cb25582dfd430cbfad7b3279b3bcdc90957964fd); /* line */ 
            c_0x545a32c6(0x28f2192a286580b22ef1ffc7bef648cce7bf9797ce9bbf45e33cabc1ecbe3868); /* statement */ 
orderStatus.denominator = uint120(denominator);
        }

        // Return order hash, a modified numerator, and a modified denominator.
c_0x545a32c6(0x3b7e8e4971b226e5e9d635438015af75cb4a5bab1923481df5d9d73c1335375a); /* line */ 
        c_0x545a32c6(0x84822d710cf1487cb26db045bd4cfce83b72cc5307cec47b579d4c086f95663c); /* statement */ 
return (orderHash, numerator, denominator);
    }

    /**
     * @dev Internal function to cancel an arbitrary number of orders. Note that
     *      only the offerer or the zone of a given order may cancel it. Callers
     *      should ensure that the intended order was cancelled by calling
     *      `getOrderStatus` and confirming that `isCancelled` returns `true`.
     *
     * @param orders The orders to cancel.
     *
     * @return cancelled A boolean indicating whether the supplied orders were
     *                   successfully cancelled.
     */
    function _cancel(OrderComponents[] calldata orders)
        internal
        returns (bool cancelled)
    {c_0x545a32c6(0xf6a3ae36304a6a5a93afadec6289faa639b7f25372ccbf4138b9ac01f0e59b03); /* function */ 

        // Ensure that the reentrancy guard is not currently set.
c_0x545a32c6(0x30ea22a51cf6a03efeaaebfa9301af13355130e53b1614b74b80f186a1891366); /* line */ 
        c_0x545a32c6(0x50a3877f203ae289305832cef74fc636c5e8be71295b7892220d8ca4496b0cc3); /* statement */ 
_assertNonReentrant();

        // Declare variables outside of the loop.
c_0x545a32c6(0x3832e817984ae3ac1fc9d8a24e0000277f07c075f7792a264f749bb8156f5e27); /* line */ 
        c_0x545a32c6(0x3490208035e01365a31a7e8b7b7db1f74c2099ff3002968bcea5ae019a9bf9ba); /* statement */ 
OrderStatus storage orderStatus;
c_0x545a32c6(0x529341b6f5a31cabf14268e1d997c2cfb0ee7e4af86a06ff4db5cba9bf4d08f7); /* line */ 
        c_0x545a32c6(0x3c7e2f4628de0dcbb0dad95c371d22063f4c00070418a90aa31862bd3658de43); /* statement */ 
address offerer;
c_0x545a32c6(0x933775273994c07eae34dad411715f693443a0b8c09ffbedb528efba086b93d2); /* line */ 
        c_0x545a32c6(0xb0c823f6cd4143911d820f7da45189011b5516e70ee7f767d3f2be2924e20aba); /* statement */ 
address zone;

        // Skip overflow check as for loop is indexed starting at zero.
c_0x545a32c6(0x56848b24552fb863d75aeaf17d889f685d056460120c24dc7d24ca9df448d493); /* line */ 
        unchecked {
            // Read length of the orders array from memory and place on stack.
c_0x545a32c6(0x8f8a52ee226846d101e0abd5dfdaf65b18e19305b6aa4d0777d70b03fe762ba5); /* line */ 
            c_0x545a32c6(0xd390023da554f84c6d9250c82fe871916d236e2b9a432886e72e6c07dfe2e249); /* statement */ 
uint256 totalOrders = orders.length;

            // Iterate over each order.
c_0x545a32c6(0xa040cded68ab71871ccf47597b760ffc62247600ae639a7371fcba9e286c478c); /* line */ 
            c_0x545a32c6(0xeecf4828e706c4a668cb9ba5db81719eedfcd69388b8903b2e866d748cd9bb71); /* statement */ 
for (uint256 i = 0; i < totalOrders; ) {
                // Retrieve the order.
c_0x545a32c6(0x84d795f860d3e4fb6dd1bcf3e511cd3858dfe507ac24c6e02b1a66b72776452e); /* line */ 
                c_0x545a32c6(0x6c5fb5fa1afb69bc59a803ce33f6be1693a2fa5fac2c3f475ac315db0fabfb39); /* statement */ 
OrderComponents calldata order = orders[i];

c_0x545a32c6(0x6425b0dadd3fa4f090e9e2576f2e52ee3570e0edbe4811bf881c4c14bb78a0f8); /* line */ 
                c_0x545a32c6(0x414ee89e0fad1991fbd19a8475b25fe78196fb637a18eed1d7d7d5ba8fbb75d7); /* statement */ 
offerer = order.offerer;
c_0x545a32c6(0x83799579c881db70e8d8b2d9533917d50a770eabb56abbff8c87f28232071903); /* line */ 
                c_0x545a32c6(0xcc9b2bd7448cfa213e019e0ead93d3185fd6b09a7e310cd20da712c92145bf52); /* statement */ 
zone = order.zone;

                // Ensure caller is either offerer or zone of the order.
c_0x545a32c6(0xf22ebfbea57ce16a14da1d513c185326a5727ed9c1e9f177deb386d61c118e09); /* line */ 
                c_0x545a32c6(0x6ca7fa77c191e81d25abe6e35c7ffa093540edde1e9e6037a75fe0006e396c71); /* statement */ 
if (msg.sender != offerer && msg.sender != zone) {c_0x545a32c6(0xed758e22d3e89d20d752241e0974c4e88c09a95a67169ce6e9c4f349c2f389be); /* branch */ 

c_0x545a32c6(0x5642cf1cc7c97278db6ad6efd65e628b60b07baf3fdb0643966d7eae20554d5b); /* line */ 
                    revert InvalidCanceller();
                }else { c_0x545a32c6(0xa0c50b468865485a017e6963d6d159acff80378cef361d00ee38ce7d504ab29b); /* branch */ 
}

                // Derive order hash using the order parameters and the counter.
c_0x545a32c6(0x211be0fee7c2a3225f84dedf24198b9e90156f917244440b8ffb7454bd081057); /* line */ 
                c_0x545a32c6(0x9feb38448c6ef85bed7e95ada1a855988c8d7d33596e318b8e6f6abeebf62626); /* statement */ 
bytes32 orderHash = _deriveOrderHash(
                    OrderParameters(
                        offerer,
                        zone,
                        order.offer,
                        order.consideration,
                        order.orderType,
                        order.startTime,
                        order.endTime,
                        order.zoneHash,
                        order.salt,
                        order.conduitKey,
                        order.consideration.length
                    ),
                    order.counter
                );

                // Retrieve the order status using the derived order hash.
c_0x545a32c6(0xa0b7e4a852e21ac642f52a698ab783b9e0841ed9294979cb100b2b9d13b7a8b6); /* line */ 
                c_0x545a32c6(0x44ebd5d03c5c390235d02c81c0d4479f0f31210d2b084cd03ae0e6ca6a988b49); /* statement */ 
orderStatus = _orderStatus[orderHash];

                // Update the order status as not valid and cancelled.
c_0x545a32c6(0xf608c515ba1a085c4ac883a41a67c4a45377091ca50b03f424982ce71503c416); /* line */ 
                c_0x545a32c6(0x00ccf8a6309fb27042654ae39775ab2593230277224c40ca325bdd74b5728ec5); /* statement */ 
orderStatus.isValidated = false;
c_0x545a32c6(0x8ccb4c57b01e4d71e70773f76a8ccb38006f801864906f932f82f3b7a58d92a4); /* line */ 
                c_0x545a32c6(0xb48015b72b81ee69fe84b53c38ab3d22e85a2d1cfe3c39e412194d7531566cae); /* statement */ 
orderStatus.isCancelled = true;

                // Emit an event signifying that the order has been cancelled.
c_0x545a32c6(0x0ab635e3217f08db9c6f45dbd987039d3da441f882374bc07e2fbb32b7dc90e1); /* line */ 
                c_0x545a32c6(0xded19b0509a61b337e25abd73f7160546de3191f0c7e4e5c7c69a6ca582b6b82); /* statement */ 
emit OrderCancelled(orderHash, offerer, zone);

                // Increment counter inside body of loop for gas efficiency.
c_0x545a32c6(0x402176c92ed233f4f3378d942a771d5319da7d66042ae52c33d4d47889c419e5); /* line */ 
                ++i;
            }
        }

        // Return a boolean indicating that orders were successfully cancelled.
c_0x545a32c6(0x807cf9066f029f9d5a2e98169cf1df504538d2816586084c8848779b330e7591); /* line */ 
        c_0x545a32c6(0xbbe640af6f54181804bec9eff922761b73e929474111ec9495f7a3dddea64e47); /* statement */ 
cancelled = true;
    }

    /**
     * @dev Internal function to validate an arbitrary number of orders, thereby
     *      registering their signatures as valid and allowing the fulfiller to
     *      skip signature verification on fulfillment. Note that validated
     *      orders may still be unfulfillable due to invalid item amounts or
     *      other factors; callers should determine whether validated orders are
     *      fulfillable by simulating the fulfillment call prior to execution.
     *      Also note that anyone can validate a signed order, but only the
     *      offerer can validate an order without supplying a signature.
     *
     * @param orders The orders to validate.
     *
     * @return validated A boolean indicating whether the supplied orders were
     *                   successfully validated.
     */
    function _validate(Order[] calldata orders)
        internal
        returns (bool validated)
    {c_0x545a32c6(0x77820f4feb1d40fceff57fc2eea13da71c5bbeaf68b58e027ffaecd301b63aa3); /* function */ 

        // Ensure that the reentrancy guard is not currently set.
c_0x545a32c6(0x371eb3ec7f5de4661c1670b6729a73c78d67feeccaf52403ed58b32b7767edef); /* line */ 
        c_0x545a32c6(0xbaff7927c8319466d2449aa3b225b209129a976d69b0df70b8940e4a76e33971); /* statement */ 
_assertNonReentrant();

        // Declare variables outside of the loop.
c_0x545a32c6(0xff1d2f8b7601a3e7dd4f56a78ff3376854bfed9d7a7863ad45cbc8d0d7a46418); /* line */ 
        c_0x545a32c6(0x9928bae5350a1cfef5ceeca1474bdc59df5268a9eb6af24950c9201c3d9d780e); /* statement */ 
OrderStatus storage orderStatus;
c_0x545a32c6(0x167b0d32b294e91102059c3ae925f29e68dc754cb15327f70de4b54c770aec11); /* line */ 
        c_0x545a32c6(0x41ee44ea8326674856d39293f8e810c005ae2412bc9b2c5a48f1461332896069); /* statement */ 
bytes32 orderHash;
c_0x545a32c6(0x2041568afcbf16264486226f3e5907d206231efb61ad7a1e25ecc99f28fdb925); /* line */ 
        c_0x545a32c6(0xdbd099a1c3e90ac4f0b598b7b34ae18a0a2fb70331c468fdc884d3c23ef33edc); /* statement */ 
address offerer;

        // Skip overflow check as for loop is indexed starting at zero.
c_0x545a32c6(0xcccf3e3a05b17c83543eef8bcbd141fec656718afc090138741577a05aed83aa); /* line */ 
        unchecked {
            // Read length of the orders array from memory and place on stack.
c_0x545a32c6(0x64695733aebffe85350ef224226175b581aba8e205a9801289175580200a73fb); /* line */ 
            c_0x545a32c6(0x58fc1ecf11fa244c17abd43455aa2fa69afe6e07dc88d4399aa7884f725a8d2a); /* statement */ 
uint256 totalOrders = orders.length;

            // Iterate over each order.
c_0x545a32c6(0x2382ed37c8a2d9cbcc328f3d84adecb2d250e0eba165b6cc47a07426f428170b); /* line */ 
            c_0x545a32c6(0x5d9b43ff13bf869d3d0714774fd7f8b11355a427235f82d6470a1b1e994e9ab2); /* statement */ 
for (uint256 i = 0; i < totalOrders; ) {
                // Retrieve the order.
c_0x545a32c6(0x39523610c0e5b6e1444c03a742546e8f0c1a203df8b0d732b1c609a36978405e); /* line */ 
                c_0x545a32c6(0x683113e1221409d12dcd1a9101cf20657efda1ad921f2254da140a1c37774be7); /* statement */ 
Order calldata order = orders[i];

                // Retrieve the order parameters.
c_0x545a32c6(0x293c56592a51bb0ca8538e3424a2fec2a3b9daaaaca503d84307af8d86fbf883); /* line */ 
                c_0x545a32c6(0xcd2fd2a987a7a9c672c22b351d4215d2e875c24175ae574e74eeefc1ca1af289); /* statement */ 
OrderParameters calldata orderParameters = order.parameters;

                // Move offerer from memory to the stack.
c_0x545a32c6(0x64df868a164f03a427e035846fe7a97c49f9c44c44fab867fcc3c752aaaa84c8); /* line */ 
                c_0x545a32c6(0x15e6914578c325bab5e541eb1ab6839c4d22490f172ba349a74fa630901c11a9); /* statement */ 
offerer = orderParameters.offerer;

                // Get current counter & use it w/ params to derive order hash.
c_0x545a32c6(0x3f8548b9506bf1c290576bda9dee7ec368751c5c083fb875228ca23f31716ad1); /* line */ 
                c_0x545a32c6(0x43233f4014927ce8afff2cb20abf654dc6b705560cdaca7c16a7c83452782bf8); /* statement */ 
orderHash = _assertConsiderationLengthAndGetOrderHash(
                    orderParameters
                );

                // Retrieve the order status using the derived order hash.
c_0x545a32c6(0x8a907a120eb8503bfc82abe0359d0df6898c3054a55f356799d0708554ab2801); /* line */ 
                c_0x545a32c6(0xa4fd47b6dfb8e3f243402e39415c4db316567066fb11068beda830bda2db3e98); /* statement */ 
orderStatus = _orderStatus[orderHash];

                // Ensure order is fillable and retrieve the filled amount.
c_0x545a32c6(0x9959e9d24b61c948495e280db2454822a96e59a2568180c6e70b48a557d0a5e2); /* line */ 
                c_0x545a32c6(0xcd52f6156f960bb8e0a7b0a08c965f578dc5264c701a16862ba4edfb947e204c); /* statement */ 
_verifyOrderStatus(
                    orderHash,
                    orderStatus,
                    false, // Signifies that partially filled orders are valid.
                    true // Signifies to revert if the order is invalid.
                );

                // If the order has not already been validated...
c_0x545a32c6(0x41aa4cdc1842103596fbfacebddbbffd25e8f800554b0943c9f3368fe5957a47); /* line */ 
                c_0x545a32c6(0x2059f9a56e2ef1f6dbce818803e775787fb873bd1f4858c9e99af3e24e931b21); /* statement */ 
if (!orderStatus.isValidated) {c_0x545a32c6(0xdf2b5bf57e1a2659f0d2342fb4d139da020b305703196a398184f3ca410be975); /* branch */ 

                    // Verify the supplied signature.
c_0x545a32c6(0xd54ebc5c416b91c61b02577f732b049620ccb07b75edef55a4c062a2e43f46ea); /* line */ 
                    c_0x545a32c6(0x16b42da49d7971001b9f9d2b3396d532965160635ba208e0ac09f2ead72efe10); /* statement */ 
_verifySignature(offerer, orderHash, order.signature);

                    // Update order status to mark the order as valid.
c_0x545a32c6(0xc2aa719056610620f614e237ae9114c212e54e88dfd2c7cdbf865a722a8eca0b); /* line */ 
                    c_0x545a32c6(0xcee99ae1744ce8c366c0db733587b4a6b92582b18463725984fd13ab6d7b15a6); /* statement */ 
orderStatus.isValidated = true;

                    // Emit an event signifying the order has been validated.
c_0x545a32c6(0x7309df302c3bff2822f615e308fb88195f89d730017c133f7d94475a255af559); /* line */ 
                    c_0x545a32c6(0x9b439b67825ef660b5470e526458f533fb583645417fd42cfe7864896929bf20); /* statement */ 
emit OrderValidated(
                        orderHash,
                        offerer,
                        orderParameters.zone
                    );
                }else { c_0x545a32c6(0xe36a6ce882a3ea12284aa990553aafc2da133a808342ce3a459ba7265b57c163); /* branch */ 
}

                // Increment counter inside body of the loop for gas efficiency.
c_0x545a32c6(0x823585933e4c735aeaa63611cf36efd190c838219bbd48d05fae5f7122502c40); /* line */ 
                ++i;
            }
        }

        // Return a boolean indicating that orders were successfully validated.
c_0x545a32c6(0x3148694fbb10b1f52bb712a50650d5bd4f71922e320b7d0b50ea1981b14a447a); /* line */ 
        c_0x545a32c6(0x2790b36a79b89edcd6b197d7e3a94dbd7a891de495a413e99b7f5451b71521c9); /* statement */ 
validated = true;
    }

    /**
     * @dev Internal view function to retrieve the status of a given order by
     *      hash, including whether the order has been cancelled or validated
     *      and the fraction of the order that has been filled.
     *
     * @param orderHash The order hash in question.
     *
     * @return isValidated A boolean indicating whether the order in question
     *                     has been validated (i.e. previously approved or
     *                     partially filled).
     * @return isCancelled A boolean indicating whether the order in question
     *                     has been cancelled.
     * @return totalFilled The total portion of the order that has been filled
     *                     (i.e. the "numerator").
     * @return totalSize   The total size of the order that is either filled or
     *                     unfilled (i.e. the "denominator").
     */
    function _getOrderStatus(bytes32 orderHash)
        internal
        view
        returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        )
    {c_0x545a32c6(0xf06b1041ce1b247c3d845cdc260f5a7d2a196dbd91be612aee16516cefa7c4e8); /* function */ 

        // Retrieve the order status using the order hash.
c_0x545a32c6(0xaabddd7340c9f09711e5aa3c215ce9b22f95552af2df70612484e03ffeae3f78); /* line */ 
        c_0x545a32c6(0x0f176397e5a5b922443674c5aeb6a495472c667b91dda4ef820e7986c7e60ae6); /* statement */ 
OrderStatus storage orderStatus = _orderStatus[orderHash];

        // Return the fields on the order status.
c_0x545a32c6(0xf7826cf92308726b91aca896183bfc6506f3cb57ba540f0da83f2f47072d3ec4); /* line */ 
        c_0x545a32c6(0x876c0bb338c45be63c4b9973379dbebe1c61f02ad8a8dc9e68d2a34c5375bed5); /* statement */ 
return (
            orderStatus.isValidated,
            orderStatus.isCancelled,
            orderStatus.numerator,
            orderStatus.denominator
        );
    }

    /**
     * @dev Internal pure function to check whether a given order type indicates
     *      that partial fills are not supported (e.g. only "full fills" are
     *      allowed for the order in question).
     *
     * @param orderType The order type in question.
     *
     * @return isFullOrder A boolean indicating whether the order type only
     *                     supports full fills.
     */
    function _doesNotSupportPartialFills(OrderType orderType)
        internal
        pure
        returns (bool isFullOrder)
    {c_0x545a32c6(0x6e396e45775d0c894c2db80579f2fbe1fae55c46797f299d537042278d174fdb); /* function */ 

        // The "full" order types are even, while "partial" order types are odd.
        // Bitwise and by 1 is equivalent to modulo by 2, but 2 gas cheaper.
c_0x545a32c6(0x58f402a123033e2426f026ebc09df9cd32c6ddc586768381b420752c1e543f5f); /* line */ 
        assembly {
            // Equivalent to `uint256(orderType) & 1 == 0`.
            isFullOrder := iszero(and(orderType, 1))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0x143b5c0a(bytes32 c__0x143b5c0a) pure {}


import { ItemType } from "./ConsiderationEnums.sol";

import {
    OfferItem,
    ConsiderationItem,
    SpentItem,
    ReceivedItem,
    OrderParameters,
    Order,
    AdvancedOrder,
    CriteriaResolver
} from "./ConsiderationStructs.sol";

import { BasicOrderFulfiller } from "./BasicOrderFulfiller.sol";

import { CriteriaResolution } from "./CriteriaResolution.sol";

import { AmountDeriver } from "./AmountDeriver.sol";

import "./ConsiderationConstants.sol";

/**
 * @title OrderFulfiller
 * @author 0age
 * @notice OrderFulfiller contains logic related to order fulfillment where a
 *         single order is being fulfilled and where basic order fulfillment is
 *         not available as an option.
 */
contract OrderFulfiller is
    BasicOrderFulfiller,
    CriteriaResolution,
    AmountDeriver
{
function c_0xf182e2aa(bytes32 c__0xf182e2aa) internal pure {}

    /**
     * @dev Derive and set hashes, reference chainId, and associated domain
     *      separator during deployment.
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     */
    constructor(address conduitController)
        BasicOrderFulfiller(conduitController)
    {c_0xf182e2aa(0x0b7c5f1f4cf5abd59e98a22e07244270ed7958dbef29e1a7f5f3c151ee3fb585); /* function */ 
}

    /**
     * @dev Internal function to validate an order and update its status, adjust
     *      prices based on current time, apply criteria resolvers, determine
     *      what portion to fill, and transfer relevant tokens.
     *
     * @param advancedOrder       The order to fulfill as well as the fraction
     *                            to fill. Note that all offer and consideration
     *                            components must divide with no remainder for
     *                            the partial fill to be valid.
     * @param criteriaResolvers   An array where each element contains a
     *                            reference to a specific offer or
     *                            consideration, a token identifier, and a proof
     *                            that the supplied token identifier is
     *                            contained in the order's merkle root. Note
     *                            that a criteria of zero indicates that any
     *                            (transferable) token identifier is valid and
     *                            that no proof needs to be supplied.
     * @param fulfillerConduitKey A bytes32 value indicating what conduit, if
     *                            any, to source the fulfiller's token approvals
     *                            from. The zero hash signifies that no conduit
     *                            should be used, with direct approvals set on
     *                            Consideration.
     * @param recipient           The intended recipient for all received items.
     *
     * @return A boolean indicating whether the order has been fulfilled.
     */
    function _validateAndFulfillAdvancedOrder(
        AdvancedOrder memory advancedOrder,
        CriteriaResolver[] memory criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient
    ) internal returns (bool) {c_0xf182e2aa(0x760f38b1aad098e21ca0fed088dd46a86cdbf1395af1f3ab83fd8c2a456c3bb3); /* function */ 

        // Ensure this function cannot be triggered during a reentrant call.
c_0xf182e2aa(0xd4831c4678f9af47f076e8f6c5003ae4da994baeef4118f89b06617543dcc46d); /* line */ 
        c_0xf182e2aa(0xaa5ea15de56778f61b49e3f860ae5e37132c19193c299e932efc1e100798912c); /* statement */ 
_setReentrancyGuard();

        // Declare empty bytes32 array (unused, will remain empty).
c_0xf182e2aa(0xd5e88d686b5e81840a080154a921a8d69e0f46d7164e7607f0ea77ab77c2cfb0); /* line */ 
        c_0xf182e2aa(0x8f26d12620656432ba72f94deb823093d626abddb1a5cae29710c923e19b0264); /* statement */ 
bytes32[] memory priorOrderHashes;

        // Validate order, update status, and determine fraction to fill.
c_0xf182e2aa(0x89068ec34254238b734874793d8b408c8aec985292aa2410d799c5dafcd3e0c6); /* line */ 
        c_0xf182e2aa(0x4066dc785f7d5edaac7d79b33d8a0292091a7508372545180f623bb23f0f6991); /* statement */ 
(
            bytes32 orderHash,
            uint256 fillNumerator,
            uint256 fillDenominator
        ) = _validateOrderAndUpdateStatus(
                advancedOrder,
                criteriaResolvers,
                true,
                priorOrderHashes
            );

        // Create an array with length 1 containing the order.
c_0xf182e2aa(0xec1dbe19e5a061453a3e063497270d06010ba6c2053e179ba5b0863ae948294d); /* line */ 
        c_0xf182e2aa(0x1e4527108522115fd40fc58ec31fc70b161fcdbc1fd9e63a51a0c40f1e27ede9); /* statement */ 
AdvancedOrder[] memory advancedOrders = new AdvancedOrder[](1);

        // Populate the order as the first and only element of the new array.
c_0xf182e2aa(0xbb502fb9bfc4a64fda62e9cbc584cb5d62afed17fa920f867c12d220d7651a7f); /* line */ 
        c_0xf182e2aa(0x98ec3aa120980f09373671ea5ecf82901416e8ee556e134b1d3acbb37c45b34a); /* statement */ 
advancedOrders[0] = advancedOrder;

        // Apply criteria resolvers using generated orders and details arrays.
c_0xf182e2aa(0xfc67d14c398a65f0b3fa1f4c42baaeff86fe30139ee3905b06fdd598dd542bcb); /* line */ 
        c_0xf182e2aa(0x1f7a4c00ce00b7a0de1a04c1efe815bf3fe2f4b2923b73e3dc4c04b064714ae3); /* statement */ 
_applyCriteriaResolvers(advancedOrders, criteriaResolvers);

        // Retrieve the order parameters after applying criteria resolvers.
c_0xf182e2aa(0x4e21f2ff8cc7cb204478fbf50402dfdcbfe926c3bda35d7327ab99902954ea84); /* line */ 
        c_0xf182e2aa(0xd52644e59582dd6606eb0837c079b8f64e8546e635c340509d1c717fe27522e3); /* statement */ 
OrderParameters memory orderParameters = advancedOrders[0].parameters;

        // Perform each item transfer with the appropriate fractional amount.
c_0xf182e2aa(0x17ce92b84eabc234b4a9959ec975c94910af61c7240fd4cdcd2b8e3c1cf6b8b5); /* line */ 
        c_0xf182e2aa(0x26ee368662c8f55e63c62bb2a02ffcea0c6fcea3398efc6f4534b961d990e009); /* statement */ 
_applyFractionsAndTransferEach(
            orderParameters,
            fillNumerator,
            fillDenominator,
            fulfillerConduitKey,
            recipient
        );

        // Emit an event signifying that the order has been fulfilled.
c_0xf182e2aa(0xe1637aa75b6eb9e40f8d927e026b16fe5e50315db0fa0448205d998a4ab44ebc); /* line */ 
        c_0xf182e2aa(0xee904032cf90c8505dc46d2e63c3d38f5b03bca27626c11321f9b928a62c6221); /* statement */ 
_emitOrderFulfilledEvent(
            orderHash,
            orderParameters.offerer,
            orderParameters.zone,
            recipient,
            orderParameters.offer,
            orderParameters.consideration
        );

        // Clear the reentrancy guard.
c_0xf182e2aa(0x2b63e5e925050bae7426f699cefc973047298eeb27ad3511fa614048c2b930db); /* line */ 
        c_0xf182e2aa(0x85516f57989e40b11b26257622d182cc5a248c498171ab3bb57068ea00ca8d46); /* statement */ 
_clearReentrancyGuard();

c_0xf182e2aa(0x8a71a1c5c3f2b9c4ce1fced6bfda149759112759f74300c6d0b7ae1a8b62420b); /* line */ 
        c_0xf182e2aa(0x38aca38f0dcf4e402cd5fc32d16ea278388492bc9dd0e02385e2a127fb00aa96); /* statement */ 
return true;
    }

    /**
     * @dev Internal function to transfer each item contained in a given single
     *      order fulfillment after applying a respective fraction to the amount
     *      being transferred.
     *
     * @param orderParameters     The parameters for the fulfilled order.
     * @param numerator           A value indicating the portion of the order
     *                            that should be filled.
     * @param denominator         A value indicating the total order size.
     * @param fulfillerConduitKey A bytes32 value indicating what conduit, if
     *                            any, to source the fulfiller's token approvals
     *                            from. The zero hash signifies that no conduit
     *                            should be used, with direct approvals set on
     *                            Consideration.
     * @param recipient           The intended recipient for all received items.
     */
    function _applyFractionsAndTransferEach(
        OrderParameters memory orderParameters,
        uint256 numerator,
        uint256 denominator,
        bytes32 fulfillerConduitKey,
        address recipient
    ) internal {c_0xf182e2aa(0xd602703b8fc4c1ef0c0a2136909cfa322e27b8c04a958b6c0c1d50abbeb4b29a); /* function */ 

        // Read start time & end time from order parameters and place on stack.
c_0xf182e2aa(0xe7e3f42147db6466ac493f04097fae4e7dc362ccf312559a4db42f2b6eb2d537); /* line */ 
        c_0xf182e2aa(0x82fc5e404d84dae97fb20328e4b1bba2edab6e22cc94bea6ccfd9affe7e8c581); /* statement */ 
uint256 startTime = orderParameters.startTime;
c_0xf182e2aa(0x82324b5776b3d958090d3efd2c2b2986d3f63feafaef00e7c2a1dbafe5357177); /* line */ 
        c_0xf182e2aa(0x8c32f2860284814299421fb46ff375e4f08a498d39653bd51b783e95d9606338); /* statement */ 
uint256 endTime = orderParameters.endTime;

        // Initialize an accumulator array. From this point forward, no new
        // memory regions can be safely allocated until the accumulator is no
        // longer being utilized, as the accumulator operates in an open-ended
        // fashion from this memory pointer; existing memory may still be
        // accessed and modified, however.
c_0xf182e2aa(0x3d19637af3043ecc3d5a745c2eaecb97419a1a5588db5128ca7095cc45d939a4); /* line */ 
        c_0xf182e2aa(0x738521b2f0cdb18d9d46763b652001a69120451b20a700074ee59b717bfbe07e); /* statement */ 
bytes memory accumulator = new bytes(AccumulatorDisarmed);

        // As of solidity 0.6.0, inline assembly cannot directly access function
        // definitions, but can still access locally scoped function variables.
        // This means that in order to recast the type of a function, we need to
        // create a local variable to reference the internal function definition
        // (using the same type) and a local variable with the desired type,
        // and then cast the original function pointer to the desired type.

        /**
         * Repurpose existing OfferItem memory regions on the offer array for
         * the order by overriding the _transfer function pointer to accept a
         * modified OfferItem argument in place of the usual ReceivedItem:
         *
         *   ========= OfferItem ==========   ====== ReceivedItem ======
         *   ItemType itemType; ------------> ItemType itemType;
         *   address token; ----------------> address token;
         *   uint256 identifierOrCriteria; -> uint256 identifier;
         *   uint256 startAmount; ----------> uint256 amount;
         *   uint256 endAmount; ------------> address recipient;
         */

        // Declare a nested scope to minimize stack depth.
c_0xf182e2aa(0xcdfc3bd2e81501852fd156f078a07171c7822ef9aaba701ec88a7faa8f81dd5e); /* line */ 
        unchecked {
            // Declare a virtual function pointer taking an OfferItem argument.
c_0xf182e2aa(0x4a8bfbf5ffc78d9dbcfe0b3f68e4a69b19134f56287a957438ef2a5ccd523da2); /* line */ 
            c_0xf182e2aa(0x9feba0c805b4c0d1b20f94e6b5a43bda100cf0a085df25702e77857601e2d64a); /* statement */ 
function(OfferItem memory, address, bytes32, bytes memory)
                internal _transferOfferItem;

c_0xf182e2aa(0x3c80217111cf14876dfdb2187b5d9d89f88f41f5aab1d9bf1ad1613de1bc8d54); /* line */ 
            {
                // Assign _transfer function to a new function pointer (it takes
                // a ReceivedItem as its initial argument)
c_0xf182e2aa(0xbeeefbe2c786f2e1b33f9563466f1c6cf836de5e225c58eb67f4966faeb05319); /* line */ 
                c_0xf182e2aa(0x14df25188597e6e01562c89db4d3c168c92c030b472660dd4bb1c45abc8105ff); /* statement */ 
function(ReceivedItem memory, address, bytes32, bytes memory)
                    internal _transferReceivedItem = _transfer;

                // Utilize assembly to override the virtual function pointer.
c_0xf182e2aa(0x02a1ce5862484fa7e98c4d3f17c40c6cbb5e964d5ce49aae4703a0b449af37e0); /* line */ 
                assembly {
                    // Cast initial ReceivedItem type to an OfferItem type.
                    _transferOfferItem := _transferReceivedItem
                }
            }

            // Read offer array length from memory and place on stack.
c_0xf182e2aa(0x307c119988b115c5e01a69fdbb0de00c212aa495e2e29cac46855b1864bf71df); /* line */ 
            c_0xf182e2aa(0xbba9ee58b46de245138808a92813fc085d9f22146996bddaeb3758e84ca7be40); /* statement */ 
uint256 totalOfferItems = orderParameters.offer.length;

            // Iterate over each offer on the order.
            // Skip overflow check as for loop is indexed starting at zero.
c_0xf182e2aa(0x12856e9e5bbd703adf930aa81e3a47c1af24f0d27fc72f0806d42dfa20af9bbd); /* line */ 
            c_0xf182e2aa(0x073ed979f7b4f9c63ff7a1d4d0ba9d5d0ae35ffac3d2a0ae4566a0d104b4746e); /* statement */ 
for (uint256 i = 0; i < totalOfferItems; ++i) {
                // Retrieve the offer item.
c_0xf182e2aa(0xa7754fb6d8129129c40e0ea2c4aad3ff00caea43a75d8a4e1dae0f2f162290b2); /* line */ 
                c_0xf182e2aa(0xa4ed534c3ce140c4f0e65cba011765d3a8e6f9e30ac2ebee929c91ed109bee47); /* statement */ 
OfferItem memory offerItem = orderParameters.offer[i];

                // Offer items for the native token can not be received
                // outside of a match order function.
c_0xf182e2aa(0x65c777d6b5b42bfc5a0eddc4ee0d1cb725aac0649eb47fcaab29b4bf4925c1ba); /* line */ 
                c_0xf182e2aa(0x540119a277e08c520019b21910a76113899d6eee149c35119e30e194fc29ef8d); /* statement */ 
if (offerItem.itemType == ItemType.NATIVE) {c_0xf182e2aa(0xf15cfcb404fccd7858cb227073d316be8acb4ae0d9486ba63dc34b4dfb6a90f0); /* branch */ 

c_0xf182e2aa(0x2397bdb7ed41f6cc725884de01129e93070f8b11ad1af48ddd6467d09836ef86); /* line */ 
                    revert InvalidNativeOfferItem();
                }else { c_0xf182e2aa(0x1c9e50cbde7db8afd820269834c283f3b4b2fd2ea8c8cc2dbe6d2fce7c4c9586); /* branch */ 
}

                // Declare an additional nested scope to minimize stack depth.
c_0xf182e2aa(0x958d02ec66a51c1e27f2afaa7f758343c360f6136be5c2eaa17cce7d4ae75125); /* line */ 
                {
                    // Apply fill fraction to get offer item amount to transfer.
c_0xf182e2aa(0x741ef03a56c56074fbf90c3b32b92c9421ea0bf73b4e5b7c17eadb6610440203); /* line */ 
                    c_0xf182e2aa(0xed611edb2ba0c84330b58db2d0831b5eebb696e9039e6761ea292c084a85fa1d); /* statement */ 
uint256 amount = _applyFraction(
                        offerItem.startAmount,
                        offerItem.endAmount,
                        numerator,
                        denominator,
                        startTime,
                        endTime,
                        false
                    );

                    // Utilize assembly to set overloaded offerItem arguments.
c_0xf182e2aa(0xac9bbb5e691159436285c4a5433b1e62972cedbf14d064b56b04844b599ad36c); /* line */ 
                    assembly {
                        // Write new fractional amount to startAmount as amount.
                        mstore(
                            add(offerItem, ReceivedItem_amount_offset),
                            amount
                        )

                        // Write recipient to endAmount.
                        mstore(
                            add(offerItem, ReceivedItem_recipient_offset),
                            recipient
                        )
                    }
                }

                // Transfer the item from the offerer to the recipient.
c_0xf182e2aa(0xe8d29aefe7f620b32cd4f485be50d32a1ecd561fa70be7cb5f7a66346a5a2c2d); /* line */ 
                c_0xf182e2aa(0x90cffc20757c4e83ccb5eb31b52ad3b5d970b4c3efd01a6424d4c5d83d8bc713); /* statement */ 
_transferOfferItem(
                    offerItem,
                    orderParameters.offerer,
                    orderParameters.conduitKey,
                    accumulator
                );
            }
        }

        // Put ether value supplied by the caller on the stack.
c_0xf182e2aa(0xfe35657dd69a9cc921028153c8621ee7333e21a94e106c1273eff93e5c3343d0); /* line */ 
        c_0xf182e2aa(0xe6d7bab83652716d7d09380e68082cdbe5be95c96e75d8fdc5882b7a5701c231); /* statement */ 
uint256 etherRemaining = msg.value;

        /**
         * Repurpose existing ConsiderationItem memory regions on the
         * consideration array for the order by overriding the _transfer
         * function pointer to accept a modified ConsiderationItem argument in
         * place of the usual ReceivedItem:
         *
         *   ====== ConsiderationItem =====   ====== ReceivedItem ======
         *   ItemType itemType; ------------> ItemType itemType;
         *   address token; ----------------> address token;
         *   uint256 identifierOrCriteria;--> uint256 identifier;
         *   uint256 startAmount; ----------> uint256 amount;
         *   uint256 endAmount;        /----> address recipient;
         *   address recipient; ------/
         */

        // Declare a nested scope to minimize stack depth.
c_0xf182e2aa(0x25689287f664ba65fd6d7f7fbb9f5188bfa252cbc3c6cb7cfd9db65d6f6af35c); /* line */ 
        unchecked {
            // Declare virtual function pointer with ConsiderationItem argument.
c_0xf182e2aa(0x1b636ae37f53cf45bff4600777f2e096da18bcfb9a2479328aac2c97bc12cd8d); /* line */ 
            c_0xf182e2aa(0xbdca0650bd7d87c326e8cd7fc22f0213093be496fa386acbfba3eca342552234); /* statement */ 
function(ConsiderationItem memory, address, bytes32, bytes memory)
                internal _transferConsiderationItem;
c_0xf182e2aa(0x39ca1a3a9c5ee86900472e373482bef977448f64753605d4f3a1b6f28dbf35cc); /* line */ 
            {
                // Reassign _transfer function to a new function pointer (it
                // takes a ReceivedItem as its initial argument).
c_0xf182e2aa(0x4aae4d972c9780adc270bbf04eee9c8b477ad5f29a21ed89d9ca2b45265a7a5b); /* line */ 
                c_0xf182e2aa(0xa06c1b334dcaa9eb097ef8e308dc15d767ba232b17a7bf5917eb3a22cf2c0ec3); /* statement */ 
function(ReceivedItem memory, address, bytes32, bytes memory)
                    internal _transferReceivedItem = _transfer;

                // Utilize assembly to override the virtual function pointer.
c_0xf182e2aa(0xff8f7e5f61180f875c5946cb4ec192b6c5300e22f3121dc48b8c469381399047); /* line */ 
                assembly {
                    // Cast ReceivedItem type to ConsiderationItem type.
                    _transferConsiderationItem := _transferReceivedItem
                }
            }

            // Read consideration array length from memory and place on stack.
c_0xf182e2aa(0x78fde8da62c49bec2089d6d2e3037ae96cab090caab9bd36479d266b3a3082a7); /* line */ 
            c_0xf182e2aa(0x9fa84eeac4c1b8ddd82af0ee289e0e4f3e8b27cd06bdcf7301b257bdddcda37f); /* statement */ 
uint256 totalConsiderationItems = orderParameters
                .consideration
                .length;

            // Iterate over each consideration item on the order.
            // Skip overflow check as for loop is indexed starting at zero.
c_0xf182e2aa(0xe43b02ea4b8702ce795fb7a423d1a10cb631c800f1d35edcf6c796322d873e61); /* line */ 
            c_0xf182e2aa(0x8f26bd3e4a5a8c93758390b799e89e3ff05998033771d287f290a2515d4790ea); /* statement */ 
for (uint256 i = 0; i < totalConsiderationItems; ++i) {
                // Retrieve the consideration item.
c_0xf182e2aa(0x0f7de8883fb9737b83fc527428d844ab7fa9801da7d332d1a86b4f777bfcbf06); /* line */ 
                c_0xf182e2aa(0x3fa77496c1c64e342313b6644662995da5ee70b2729f176e06dde66e837b0c8c); /* statement */ 
ConsiderationItem memory considerationItem = (
                    orderParameters.consideration[i]
                );

                // Apply fraction & derive considerationItem amount to transfer.
c_0xf182e2aa(0x99067383ab2f84a7bd3173404f2215789f5f2ab9185ff2bf14202b6cfa40dd76); /* line */ 
                c_0xf182e2aa(0x3d1d67fed44a59e24e9d2f03caeb6e2b6a8a27b13021816cc407625387f7be67); /* statement */ 
uint256 amount = _applyFraction(
                    considerationItem.startAmount,
                    considerationItem.endAmount,
                    numerator,
                    denominator,
                    startTime,
                    endTime,
                    true
                );

                // Use assembly to set overloaded considerationItem arguments.
c_0xf182e2aa(0x5f2436f4b7c4177c4d804034ef76d1e93dafcea0d667e05cd826d24728e1ada1); /* line */ 
                assembly {
                    // Write derived fractional amount to startAmount as amount.
                    mstore(
                        add(considerationItem, ReceivedItem_amount_offset),
                        amount
                    )

                    // Write original recipient to endAmount as recipient.
                    mstore(
                        add(considerationItem, ReceivedItem_recipient_offset),
                        mload(
                            add(
                                considerationItem,
                                ConsiderationItem_recipient_offset
                            )
                        )
                    )
                }

                // Reduce available value if offer spent ETH or a native token.
c_0xf182e2aa(0xa16b98c39394e8cba8ede2100f6706fcbb6d0a64f9d7143ea9710864e97200e4); /* line */ 
                c_0xf182e2aa(0x4fed4c50c32f9851532901b58b2f943699c81c418dae7bffc0185a18f50dc352); /* statement */ 
if (considerationItem.itemType == ItemType.NATIVE) {c_0xf182e2aa(0x05bd19a6168f3972272f8b5c18e37e1980710ae7f931650292aa911c9715f7d0); /* branch */ 

                    // Ensure that sufficient native tokens are still available.
c_0xf182e2aa(0xa8d047d7bbca72e081862107c345d6f6d85ed7b03536c6f998eb358204389f7f); /* line */ 
                    c_0xf182e2aa(0xcc763fd42cae40d2a53966117990a891873a0cd01b80951fcef94929b8da331d); /* statement */ 
if (amount > etherRemaining) {c_0xf182e2aa(0x24d4b9d57382e643821ad50049265a1556c4c7f5c6b12545d5bdad588eeec714); /* branch */ 

c_0xf182e2aa(0x94e95c6b582d6270a86c75f924d74bb0ba741e644f3e2ca94c2346f605630574); /* line */ 
                        revert InsufficientEtherSupplied();
                    }else { c_0xf182e2aa(0x4f57b18a3f33e1c7c1f649846e95de989009295074610f10024276aa6a8c32c5); /* branch */ 
}

                    // Skip underflow check as a comparison has just been made.
c_0xf182e2aa(0xc020eab1c94243a0c14507506b60f3af2094e5d53609c63eb5ca33fb24d714fa); /* line */ 
                    c_0xf182e2aa(0xc1ae7d02b58288e7a70081e62ae915892ab045ef1585244f8802970e4efdecde); /* statement */ 
etherRemaining -= amount;
                }else { c_0xf182e2aa(0x6e025482e7f52fb3bf0dd62d944fdfed570ffeed969fd8b46db4166bd2764439); /* branch */ 
}

                // Transfer item from caller to recipient specified by the item.
c_0xf182e2aa(0x8a9ea41cfd3faefde0578219866ba87c94b0fc12937a309b2e929a47658ff9e9); /* line */ 
                c_0xf182e2aa(0x1e65bdb70686a98fad3a97f1afd71a902ec7d576f824099fc741058fbfa90433); /* statement */ 
_transferConsiderationItem(
                    considerationItem,
                    msg.sender,
                    fulfillerConduitKey,
                    accumulator
                );
            }
        }

        // Trigger any remaining accumulated transfers via call to the conduit.
c_0xf182e2aa(0x34d0829dd4c4bdbe463f4f9316dd79900935db73a66da881428d794c03208bfd); /* line */ 
        c_0xf182e2aa(0x11497fdf51829bb6b21397afa063c4fcb387e38e821905ad34f9b18918dc191d); /* statement */ 
_triggerIfArmed(accumulator);

        // If any ether remains after fulfillments...
c_0xf182e2aa(0x53c280ac27fff1e13ba861d096e09cebd33a51ade5f122ced9a009d2de2ff059); /* line */ 
        c_0xf182e2aa(0x87ffe971a53c03bf598fbe5b5d73f7b715c5369fe95859d9f95b08e89212389a); /* statement */ 
if (etherRemaining != 0) {c_0xf182e2aa(0xeb695d71d0d6341490a65f09a1484e21a01bca415ce6a8746b4834f1cf9ef22b); /* branch */ 

            // return it to the caller.
c_0xf182e2aa(0x3864fb640d5edaaccd2723669763aca96eabf9e5354c1827ef82b318008f5649); /* line */ 
            c_0xf182e2aa(0xad21025fa961236101733a6fdb34991ef0b92a2a6bfadd387daa3c896dd3295a); /* statement */ 
_transferEth(payable(msg.sender), etherRemaining);
        }else { c_0xf182e2aa(0x0c3cfe2ac03c2ce8b0f0eda0c5f573a67b6ce5ec6aebf01332b4ead8b2c3bf62); /* branch */ 
}
    }

    /**
     * @dev Internal function to emit an OrderFulfilled event. OfferItems are
     *      translated into SpentItems and ConsiderationItems are translated
     *      into ReceivedItems.
     *
     * @param orderHash     The order hash.
     * @param offerer       The offerer for the order.
     * @param zone          The zone for the order.
     * @param fulfiller     The fulfiller of the order, or the null address if
     *                      the order was fulfilled via order matching.
     * @param offer         The offer items for the order.
     * @param consideration The consideration items for the order.
     */
    function _emitOrderFulfilledEvent(
        bytes32 orderHash,
        address offerer,
        address zone,
        address fulfiller,
        OfferItem[] memory offer,
        ConsiderationItem[] memory consideration
    ) internal {c_0xf182e2aa(0xf90a1a855df5ea6a45c11fa316dd0cdfb7b4bcaaccc2a763e3f8c634265f845f); /* function */ 

        // Cast already-modified offer memory region as spent items.
c_0xf182e2aa(0x05be77e5a895c1c9311ab37117b6f5cc13add9e6edb1d3a739d62fffe37bca2f); /* line */ 
        c_0xf182e2aa(0x1432c38b27685871ebce10ece0047d3eed20d969ca051e3c5cc166ea7910168c); /* statement */ 
SpentItem[] memory spentItems;
c_0xf182e2aa(0x54cea0e546bed3deb6f55a1379b3248225c622e1d2d726386faeffe0e8cc24d4); /* line */ 
        assembly {
            spentItems := offer
        }

        // Cast already-modified consideration memory region as received items.
c_0xf182e2aa(0x628180b46eb5fc0241a823efa1381bc718840e2cca357329c5ae519fe70d02ff); /* line */ 
        c_0xf182e2aa(0x2271e8c8dda82a0256e70795f46bd17510f565ed6f651a56056d451ebe137ef1); /* statement */ 
ReceivedItem[] memory receivedItems;
c_0xf182e2aa(0x9ef095c908c045735c50e457d826300683d31ed03df1cbfed00e2c982446958e); /* line */ 
        assembly {
            receivedItems := consideration
        }

        // Emit an event signifying that the order has been fulfilled.
c_0xf182e2aa(0x38541ad39b8cf74097f9a1d7dde1f5f3b5ff26f0e8bc3adaadee6d80ea9d86a6); /* line */ 
        c_0xf182e2aa(0xbd512124fa1b20e88e189e544d8399a8a21e1d200dda8a07604aa8d24e47b946); /* statement */ 
emit OrderFulfilled(
            orderHash,
            offerer,
            zone,
            fulfiller,
            spentItems,
            receivedItems
        );
    }

    /**
     * @dev Internal pure function to convert an order to an advanced order with
     *      numerator and denominator of 1 and empty extraData.
     *
     * @param order The order to convert.
     *
     * @return advancedOrder The new advanced order.
     */
    function _convertOrderToAdvanced(Order calldata order)
        internal
        pure
        returns (AdvancedOrder memory advancedOrder)
    {c_0xf182e2aa(0xf79bb198220a2cbcb9789f6f51fb96f5bdff3673d23ef21cb90039e9df7ee241); /* function */ 

        // Convert to partial order (1/1 or full fill) and return new value.
c_0xf182e2aa(0x0c747a6fe4c8d9ad7fb52a665f865d66554ea7db6d2613f3174fdaca71cdc224); /* line */ 
        c_0xf182e2aa(0xf6a082980dd9fe1f853f5057a6680e584130c08cddf4a70094fa210686f93ec4); /* statement */ 
advancedOrder = AdvancedOrder(
            order.parameters,
            1,
            1,
            order.signature,
            ""
        );
    }

    /**
     * @dev Internal pure function to convert an array of orders to an array of
     *      advanced orders with numerator and denominator of 1.
     *
     * @param orders The orders to convert.
     *
     * @return advancedOrders The new array of partial orders.
     */
    function _convertOrdersToAdvanced(Order[] calldata orders)
        internal
        pure
        returns (AdvancedOrder[] memory advancedOrders)
    {c_0xf182e2aa(0xbba494656167771cb9a3dd2ef8984e4a80803f71f3f8e73a51c655d009ad9d23); /* function */ 

        // Read the number of orders from calldata and place on the stack.
c_0xf182e2aa(0x52f3e4a6e592fcd687859f6c054acc421b3dc46a951e55ee5d220e3e1ae70bee); /* line */ 
        c_0xf182e2aa(0x2aca905acc09d244c62a397196e89a91ab643cbcd680af167c2a6a8745a86068); /* statement */ 
uint256 totalOrders = orders.length;

        // Allocate new empty array for each partial order in memory.
c_0xf182e2aa(0x89f80df7428ea6c6a89ccd0454873efea77b4e1632732c399504c1a6703789f0); /* line */ 
        c_0xf182e2aa(0xbeb230d9fa7abff76a9b7ebbc47f408244b228f94c7f5ab7be5629876762c99b); /* statement */ 
advancedOrders = new AdvancedOrder[](totalOrders);

        // Skip overflow check as the index for the loop starts at zero.
c_0xf182e2aa(0xc02738a4a5ea950d38775c17e33e9a4387389552f05396453927ddc0dfda01f3); /* line */ 
        unchecked {
            // Iterate over the given orders.
c_0xf182e2aa(0x355ba1569f7bc8209a43c8ac409a0bb781d5fc1361936cb696b6af2f1cc3b1c8); /* line */ 
            c_0xf182e2aa(0x94f769ffd5f303ceb7943fbf0592b887451a956fd49ee733f9e132f5962cc835); /* statement */ 
for (uint256 i = 0; i < totalOrders; ++i) {
                // Convert to partial order (1/1 or full fill) and update array.
c_0xf182e2aa(0xa2cbd89ac8c5e366e5be1bf81f82f3899651e1eb5624993571cb42d2d220cf91); /* line */ 
                c_0xf182e2aa(0x40acb29aaf68c43d06633d4b0d996ade18367c4923117844908c34b3bc5b611f); /* statement */ 
advancedOrders[i] = _convertOrderToAdvanced(orders[i]);
            }
        }

        // Return the array of advanced orders.
c_0xf182e2aa(0x662769af143b081748113bc6a4b6ad7778a654f57ee85e767a7dc01e769d9ec8); /* line */ 
        c_0xf182e2aa(0xbf9e81d5b7e1a3a66a4a8f95f93bd164b8f4b1081540c20c0348867ba56be1aa); /* statement */ 
return advancedOrders;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0xff179ef5(bytes32 c__0xff179ef5) pure {}


import {
    AmountDerivationErrors
} from "../interfaces/AmountDerivationErrors.sol";

import "./ConsiderationConstants.sol";

/**
 * @title AmountDeriver
 * @author 0age
 * @notice AmountDeriver contains view and pure functions related to deriving
 *         item amounts based on partial fill quantity and on linear
 *         interpolation based on current time when the start amount and end
 *         amount differ.
 */
contract AmountDeriver is AmountDerivationErrors {
function c_0x338ab061(bytes32 c__0x338ab061) internal pure {}

    /**
     * @dev Internal view function to derive the current amount of a given item
     *      based on the current price, the starting price, and the ending
     *      price. If the start and end prices differ, the current price will be
     *      interpolated on a linear basis. Note that this function expects that
     *      the startTime parameter of orderParameters is not greater than the
     *      current block timestamp and that the endTime parameter is greater
     *      than the current block timestamp. If this condition is not upheld,
     *      duration / elapsed / remaining variables will underflow.
     *
     * @param startAmount The starting amount of the item.
     * @param endAmount   The ending amount of the item.
     * @param startTime   The starting time of the order.
     * @param endTime     The end time of the order.
     * @param roundUp     A boolean indicating whether the resultant amount
     *                    should be rounded up or down.
     *
     * @return amount The current amount.
     */
    function _locateCurrentAmount(
        uint256 startAmount,
        uint256 endAmount,
        uint256 startTime,
        uint256 endTime,
        bool roundUp
    ) internal view returns (uint256 amount) {c_0x338ab061(0xc99f8d2d6dce22bb107869924069c8d4aee142df25ebfb909bbcbee35fd2fe70); /* function */ 

        // Only modify end amount if it doesn't already equal start amount.
c_0x338ab061(0xe605e894f8d961c70e4c6eead74f9e25dc7834ff7aef712ea92750a6f6e134ea); /* line */ 
        c_0x338ab061(0x8e37243b753eda35824729a7a63d35861f1eb745cbe0b010d1cabd4908aa5527); /* statement */ 
if (startAmount != endAmount) {c_0x338ab061(0x092886c1ca65a24e9166a801a5570bd6ebb3f3b5bd98a4040d0db87b6f595db2); /* branch */ 

            // Declare variables to derive in the subsequent unchecked scope.
c_0x338ab061(0x0315416b9e5db3ab843092086f637575b76e2569dc927547917b71ba8fa2d71f); /* line */ 
            c_0x338ab061(0xa39bd4e1160f2b47197b2d8ac4366751a4597e33e0243540306954a5f6b2830d); /* statement */ 
uint256 duration;
c_0x338ab061(0x987ead94e9ee193d82ac613344c713a3f1f38175df4991bb3054bafe42f97f7b); /* line */ 
            c_0x338ab061(0x10fa31549e1e758a265aff73bbb29fbc2b2543091b6fc2e65494120f54acfef4); /* statement */ 
uint256 elapsed;
c_0x338ab061(0x194bc141972b5add1fc82346cb36f7c1c62218b2bae76ce7b91ba04dd917f91c); /* line */ 
            c_0x338ab061(0xb8fd8e4c1b6384b7179e0e7df4c2684de2ea341cf2533d470509bb23829372ac); /* statement */ 
uint256 remaining;

            // Skip underflow checks as startTime <= block.timestamp < endTime.
c_0x338ab061(0x4a3712cfa56efefd0412b5c521dd0a5bd1334fa14ba5d954bcbf64892a88908a); /* line */ 
            unchecked {
                // Derive the duration for the order and place it on the stack.
c_0x338ab061(0x203734b74418a7c08efc882dac6c426fd04e889e7c199e0f59393de10d809784); /* line */ 
                c_0x338ab061(0xc7b56469c2205fc4c98ff5f9ebc138a4d1087595a59c667e8638c1a44596103d); /* statement */ 
duration = endTime - startTime;

                // Derive time elapsed since the order started & place on stack.
c_0x338ab061(0x0dbb375f7b065f84b07a4f6ef402113f12f51207172cec0d8329d687882b1ed3); /* line */ 
                c_0x338ab061(0xbf6ec3acecb0e8d184d34664c821e53cf19fe92ce38977cc7e8dbfee9abe296b); /* statement */ 
elapsed = block.timestamp - startTime;

                // Derive time remaining until order expires and place on stack.
c_0x338ab061(0xca3d6b22cc3392d2b456452f522674a680d91ca12a0ade51120246e548f525fb); /* line */ 
                c_0x338ab061(0x39180fc77b8585814754c1ded8e18fd5c0966fbe5ef3ed8bbfe89ae1f78774e1); /* statement */ 
remaining = duration - elapsed;
            }

            // Aggregate new amounts weighted by time with rounding factor.
c_0x338ab061(0xb8ae158dda4da84faf6da37c9fcceeac5daa8a09e0d1137b102e2f42a8e4dad8); /* line */ 
            c_0x338ab061(0x3f24b751e331202efdce1af84c03574c223710e435f9a17cf4ad1f6d132ce070); /* statement */ 
uint256 totalBeforeDivision = ((startAmount * remaining) +
                (endAmount * elapsed));

            // Use assembly to combine operations and skip divide-by-zero check.
c_0x338ab061(0x777d62bc1cb48ab907c983bef7080babe2d64678e9f82f9e63a0784922fa98e6); /* line */ 
            assembly {
                // Multiply by iszero(iszero(totalBeforeDivision)) to ensure
                // amount is set to zero if totalBeforeDivision is zero,
                // as intermediate overflow can occur if it is zero.
                amount := mul(
                    iszero(iszero(totalBeforeDivision)),
                    // Subtract 1 from the numerator and add 1 to the result if
                    // roundUp is true to get the proper rounding direction.
                    // Division is performed with no zero check as duration
                    // cannot be zero as long as startTime < endTime.
                    add(
                        div(sub(totalBeforeDivision, roundUp), duration),
                        roundUp
                    )
                )
            }

            // Return the current amount.
c_0x338ab061(0xb0c7da0c9c16be080ea757237dc14654b5dd2eb1adf94bd2cbbfb892a86e9c5d); /* line */ 
            c_0x338ab061(0x7ee23ea79ff84dbfcf6c007db856adc486d1e667bc2c2eb9c9319c9f7aa45c52); /* statement */ 
return amount;
        }else { c_0x338ab061(0x6306bd0fe7bb102edf3599422d5c16ef35827b09cddce4636be91e00703b48fc); /* branch */ 
}

        // Return the original amount as startAmount == endAmount.
c_0x338ab061(0xb9ffa52bbb72a0d39dc9d944e806a5a838ce60cb854fc5fc8cffee63b298f5ba); /* line */ 
        c_0x338ab061(0xd422513239b3d83935d0f6fa79cd312a9f8294fbc4124119e903f01be2e1d657); /* statement */ 
return endAmount;
    }

    /**
     * @dev Internal pure function to return a fraction of a given value and to
     *      ensure the resultant value does not have any fractional component.
     *      Note that this function assumes that zero will never be supplied as
     *      the denominator parameter; invalid / undefined behavior will result
     *      should a denominator of zero be provided.
     *
     * @param numerator   A value indicating the portion of the order that
     *                    should be filled.
     * @param denominator A value indicating the total size of the order. Note
     *                    that this value cannot be equal to zero.
     * @param value       The value for which to compute the fraction.
     *
     * @return newValue The value after applying the fraction.
     */
    function _getFraction(
        uint256 numerator,
        uint256 denominator,
        uint256 value
    ) internal pure returns (uint256 newValue) {c_0x338ab061(0xe040c44451a1dc20fc556c50a47db02873a4acaa70c560fc39f11104c84f1bda); /* function */ 

        // Return value early in cases where the fraction resolves to 1.
c_0x338ab061(0x9b39ebdb59208318fc3b854604ecdee209f340e916c4bc5957a9458157d1d623); /* line */ 
        c_0x338ab061(0x80fabe3919b26319b5bcee7f36a5779dbd03bee72b6362e9c0b4e1cd18c9e5f3); /* statement */ 
if (numerator == denominator) {c_0x338ab061(0x28d7877326df3654f72673114df38b17297ba8a21d2275338cf8e7c2968aeb39); /* branch */ 

c_0x338ab061(0xb9059a7726bbbe9a398511ac66ef50bdfbd75bc692b9ead866caaf479d895a32); /* line */ 
            c_0x338ab061(0x9494924d95c51c7d73476bcc04a705f9ecdff67c4ce70c3a91b697147551a998); /* statement */ 
return value;
        }else { c_0x338ab061(0x231f041615a7821ee366aba96f1ac319b476a3baffe874cdc84713f2cee8c4c3); /* branch */ 
}

        // Ensure fraction can be applied to the value with no remainder. Note
        // that the denominator cannot be zero.
c_0x338ab061(0xf5f790162bab62972a62e903f652407d6b727d02426c6d4ac1e59889be1bb6a0); /* line */ 
        assembly {
            // Ensure new value contains no remainder via mulmod operator.
            // Credit to @hrkrshnn + @axic for proposing this optimal solution.
            if mulmod(value, numerator, denominator) {
                mstore(0, InexactFraction_error_signature)
                revert(0, InexactFraction_error_len)
            }
        }

        // Multiply the numerator by the value and ensure no overflow occurs.
c_0x338ab061(0xc7eeb272ba4eec0a285340201a7a11c04d770e3f27122ae20654bf826d642021); /* line */ 
        c_0x338ab061(0x4df15ff407d6ae50fcb7060e495830359412509174c9d7a2935353c9b1af3f57); /* statement */ 
uint256 valueTimesNumerator = value * numerator;

        // Divide and check for remainder. Note that denominator cannot be zero.
c_0x338ab061(0x93c3206b845539d5c85c0cfb323e6748dcaceb4139ca95cd19173ba91b1f993d); /* line */ 
        assembly {
            // Perform division without zero check.
            newValue := div(valueTimesNumerator, denominator)
        }
    }

    /**
     * @dev Internal view function to apply a fraction to a consideration
     * or offer item.
     *
     * @param startAmount     The starting amount of the item.
     * @param endAmount       The ending amount of the item.
     * @param numerator       A value indicating the portion of the order that
     *                        should be filled.
     * @param denominator     A value indicating the total size of the order.
     * @param startTime       The starting time of the order.
     * @param endTime         The end time of the order.
     * @param roundUp         A boolean indicating whether the resultant
     *                        amount should be rounded up or down.
     *
     * @return amount The received item to transfer with the final amount.
     */
    function _applyFraction(
        uint256 startAmount,
        uint256 endAmount,
        uint256 numerator,
        uint256 denominator,
        uint256 startTime,
        uint256 endTime,
        bool roundUp
    ) internal view returns (uint256 amount) {c_0x338ab061(0x66e7e45edb58f7447fbb639b4974c2d8a886ffd9f48d9fffeb93de15c4d9d904); /* function */ 

        // If start amount equals end amount, apply fraction to end amount.
c_0x338ab061(0x651b79e1632a9fc5289a44bf0c7e859745cf38af2a9d87c5050576520d081d50); /* line */ 
        c_0x338ab061(0x0ecdc8a21497539e6c7ffac140c116cb806dcaf87789bc755b1e80d098242b15); /* statement */ 
if (startAmount == endAmount) {c_0x338ab061(0x657748b95628088bc26d70ced742ed40f099fbfbb82badd78233660ab7372685); /* branch */ 

            // Apply fraction to end amount.
c_0x338ab061(0xd841d8a647099b769a15f5ce2e3e9d3a9a62fac405b60bbc07087f699e376836); /* line */ 
            c_0x338ab061(0xf119e4f2060bf2b347de389286778f3380c0e5ae6f8701b375a757a21a7dbb17); /* statement */ 
amount = _getFraction(numerator, denominator, endAmount);
        } else {c_0x338ab061(0x7935d106904c819dc67d62ec18cf4572eee82169340a8eed9d25baaab6c19d1f); /* branch */ 

            // Otherwise, apply fraction to both and interpolated final amount.
c_0x338ab061(0xed28aeae71831ccb46697262430c9340ccacf57304f1a54cbd2012c23b61b804); /* line */ 
            c_0x338ab061(0xaf3ab5741fd5da36c006810116066687353cec3d20b9cbb30adf0bce5cc97089); /* statement */ 
amount = _locateCurrentAmount(
                _getFraction(numerator, denominator, startAmount),
                _getFraction(numerator, denominator, endAmount),
                startTime,
                endTime,
                roundUp
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0x955f3e5f(bytes32 c__0x955f3e5f) pure {}


/**
 * @title AmountDerivationErrors
 * @author 0age
 * @notice AmountDerivationErrors contains errors related to amount derivation.
 */
interface AmountDerivationErrors {
    /**
     * @dev Revert with an error when attempting to apply a fraction as part of
     *      a partial fill that does not divide the target amount cleanly.
     */
    error InexactFraction();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0xda773aff(bytes32 c__0xda773aff) pure {}


import { Side, ItemType } from "./ConsiderationEnums.sol";

import {
    OfferItem,
    ConsiderationItem,
    ReceivedItem,
    OrderParameters,
    Fulfillment,
    FulfillmentComponent,
    Execution,
    Order,
    AdvancedOrder,
    CriteriaResolver
} from "./ConsiderationStructs.sol";

import { OrderFulfiller } from "./OrderFulfiller.sol";

import { FulfillmentApplier } from "./FulfillmentApplier.sol";

import "./ConsiderationConstants.sol";

/**
 * @title OrderCombiner
 * @author 0age
 * @notice OrderCombiner contains logic for fulfilling combinations of orders,
 *         either by matching offer items to consideration items or by
 *         fulfilling orders where available.
 */
contract OrderCombiner is OrderFulfiller, FulfillmentApplier {
function c_0xf9f9b178(bytes32 c__0xf9f9b178) internal pure {}

    /**
     * @dev Derive and set hashes, reference chainId, and associated domain
     *      separator during deployment.
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     */
    constructor(address conduitController) OrderFulfiller(conduitController) {c_0xf9f9b178(0x881958472e208f0fd20f9ca69e809596b175d580562c6635fe1937ed5c78e095); /* function */ 
}

    /**
     * @notice Internal function to attempt to fill a group of orders, fully or
     *         partially, with an arbitrary number of items for offer and
     *         consideration per order alongside criteria resolvers containing
     *         specific token identifiers and associated proofs. Any order that
     *         is not currently active, has already been fully filled, or has
     *         been cancelled will be omitted. Remaining offer and consideration
     *         items will then be aggregated where possible as indicated by the
     *         supplied offer and consideration component arrays and aggregated
     *         items will be transferred to the fulfiller or to each intended
     *         recipient, respectively. Note that a failing item transfer or an
     *         issue with order formatting will cause the entire batch to fail.
     *
     * @param advancedOrders            The orders to fulfill along with the
     *                                  fraction of those orders to attempt to
     *                                  fill. Note that both the offerer and the
     *                                  fulfiller must first approve this
     *                                  contract (or a conduit if indicated by
     *                                  the order) to transfer any relevant
     *                                  tokens on their behalf and that
     *                                  contracts must implement
     *                                  `onERC1155Received` in order to receive
     *                                  ERC1155 tokens as consideration. Also
     *                                  note that all offer and consideration
     *                                  components must have no remainder after
     *                                  multiplication of the respective amount
     *                                  with the supplied fraction for an
     *                                  order's partial fill amount to be
     *                                  considered valid.
     * @param criteriaResolvers         An array where each element contains a
     *                                  reference to a specific offer or
     *                                  consideration, a token identifier, and a
     *                                  proof that the supplied token identifier
     *                                  is contained in the merkle root held by
     *                                  the item in question's criteria element.
     *                                  Note that an empty criteria indicates
     *                                  that any (transferable) token
     *                                  identifier on the token in question is
     *                                  valid and that no associated proof needs
     *                                  to be supplied.
     * @param offerFulfillments         An array of FulfillmentComponent arrays
     *                                  indicating which offer items to attempt
     *                                  to aggregate when preparing executions.
     * @param considerationFulfillments An array of FulfillmentComponent arrays
     *                                  indicating which consideration items to
     *                                  attempt to aggregate when preparing
     *                                  executions.
     * @param fulfillerConduitKey       A bytes32 value indicating what conduit,
     *                                  if any, to source the fulfiller's token
     *                                  approvals from. The zero hash signifies
     *                                  that no conduit should be used (and
     *                                  direct approvals set on Consideration).
     * @param recipient                 The intended recipient for all received
     *                                  items.
     * @param maximumFulfilled          The maximum number of orders to fulfill.
     *
     * @return availableOrders An array of booleans indicating if each order
     *                         with an index corresponding to the index of the
     *                         returned boolean was fulfillable or not.
     * @return executions      An array of elements indicating the sequence of
     *                         transfers performed as part of matching the given
     *                         orders.
     */
    function _fulfillAvailableAdvancedOrders(
        AdvancedOrder[] memory advancedOrders,
        CriteriaResolver[] memory criteriaResolvers,
        FulfillmentComponent[][] calldata offerFulfillments,
        FulfillmentComponent[][] calldata considerationFulfillments,
        bytes32 fulfillerConduitKey,
        address recipient,
        uint256 maximumFulfilled
    )
        internal
        returns (bool[] memory availableOrders, Execution[] memory executions)
    {c_0xf9f9b178(0x5101d0f7edb95adea919eef74da7dafffc5201293764131aeff9928eaa7b48a3); /* function */ 

        // Validate orders, apply amounts, & determine if they utilize conduits.
c_0xf9f9b178(0x63a750e9cb3de3927b22d62bf715136e6bef34226165ac6ff88f3de94aa81059); /* line */ 
        c_0xf9f9b178(0xfa37d6555957cd614857c19f9a0c2d62c65e4bd5db5996b81f493f29f852db5a); /* statement */ 
_validateOrdersAndPrepareToFulfill(
            advancedOrders,
            criteriaResolvers,
            false, // Signifies that invalid orders should NOT revert.
            maximumFulfilled,
            recipient
        );

        // Aggregate used offer and consideration items and execute transfers.
c_0xf9f9b178(0xd73eb4b4d2ef7c6ed5fc6da7a42cc6a0b4c0392fdb225a5461edbc7cebb36571); /* line */ 
        c_0xf9f9b178(0x3817ad3eb679fdb7be9dbcbe70e78b2069aa75a86ba24ec3370b8b2c48e70ec0); /* statement */ 
(availableOrders, executions) = _executeAvailableFulfillments(
            advancedOrders,
            offerFulfillments,
            considerationFulfillments,
            fulfillerConduitKey,
            recipient
        );

        // Return order fulfillment details and executions.
c_0xf9f9b178(0x72bf47f245a8d007eefbe94f16b1edb5e0dada14921624c31747ec2c8c481564); /* line */ 
        c_0xf9f9b178(0xe9017f777da2e086739449df543bf48a5802c81b28f721c5c632de29f4c775f9); /* statement */ 
return (availableOrders, executions);
    }

    /**
     * @dev Internal function to validate a group of orders, update their
     *      statuses, reduce amounts by their previously filled fractions, apply
     *      criteria resolvers, and emit OrderFulfilled events.
     *
     * @param advancedOrders    The advanced orders to validate and reduce by
     *                          their previously filled amounts.
     * @param criteriaResolvers An array where each element contains a reference
     *                          to a specific order as well as that order's
     *                          offer or consideration, a token identifier, and
     *                          a proof that the supplied token identifier is
     *                          contained in the order's merkle root. Note that
     *                          a root of zero indicates that any transferable
     *                          token identifier is valid and that no proof
     *                          needs to be supplied.
     * @param revertOnInvalid   A boolean indicating whether to revert on any
     *                          order being invalid; setting this to false will
     *                          instead cause the invalid order to be skipped.
     * @param maximumFulfilled  The maximum number of orders to fulfill.
     * @param recipient         The intended recipient for all received items.
     */
    function _validateOrdersAndPrepareToFulfill(
        AdvancedOrder[] memory advancedOrders,
        CriteriaResolver[] memory criteriaResolvers,
        bool revertOnInvalid,
        uint256 maximumFulfilled,
        address recipient
    ) internal {c_0xf9f9b178(0x11cb0a1fb5c0af714a17ec0d96599d844b8a6d43104e6cb7c085b37b74e8323f); /* function */ 

        // Ensure this function cannot be triggered during a reentrant call.
c_0xf9f9b178(0x8962f5bed3539ff642288cf916f80157d67442dca882ab52b93ce5c08bc98c1d); /* line */ 
        c_0xf9f9b178(0xb0b36d67b8b300c57b97b0cec951e17a42b221a41abdf1a03474f839637d02bb); /* statement */ 
_setReentrancyGuard();

        // Read length of orders array and place on the stack.
c_0xf9f9b178(0x3c44e6be7a7b018376b387884478622d81596af12943ae6b11c176bf9f355e40); /* line */ 
        c_0xf9f9b178(0xf83281fbd5ffa22cedd0e9230305db01a3535e3424ba2b07ed8c2fcf5a4c7262); /* statement */ 
uint256 totalOrders = advancedOrders.length;

        // Track the order hash for each order being fulfilled.
c_0xf9f9b178(0xafbe7d0bbc2ff245201af76dd3f95482b46c403dc1d7c904193b93edeb9f5403); /* line */ 
        c_0xf9f9b178(0xa84b5c55a167a4964190215dbb0a38d54490b7207561313cd076c9ee4b7fbedc); /* statement */ 
bytes32[] memory orderHashes = new bytes32[](totalOrders);

        // Override orderHashes length to zero after memory has been allocated.
c_0xf9f9b178(0xd62635d731c99cc5c310f5262c5c7cadace605fe3ffd4b51a34ea98b4cd3d60b); /* line */ 
        assembly {
            mstore(orderHashes, 0)
        }

        // Declare an error buffer indicating status of any native offer items.
        // {00} == 0 => In a match function, no native offer items: allow.
        // {01} == 1 => In a match function, some native offer items: allow.
        // {10} == 2 => Not in a match function, no native offer items: allow.
        // {11} == 3 => Not in a match function, some native offer items: THROW.
c_0xf9f9b178(0xe66a5370460cfecedae370652d0922bc72acf0111c6797fd399fba8b61665bac); /* line */ 
        c_0xf9f9b178(0x20673f631c17c221bac3de9d2684903b1eece1b82a380d56380da0971cf62192); /* statement */ 
uint256 invalidNativeOfferItemErrorBuffer;

        // Use assembly to set the value for the second bit of the error buffer.
c_0xf9f9b178(0xfab38f66f605f7482954391b6b888097825b59ab9454eeb6ee08603f1cba65cf); /* line */ 
        assembly {
            // Use the second bit of the error buffer to indicate whether the
            // current function is not matchAdvancedOrders or matchOrders.
            invalidNativeOfferItemErrorBuffer := shl(
                1,
                gt(
                    // Take the remainder of the selector modulo a magic value.
                    mod(
                        shr(NumBitsAfterSelector, calldataload(0)),
                        NonMatchSelector_MagicModulus
                    ),
                    // Check if remainder is higher than the greatest remainder
                    // of the two match selectors modulo the magic value.
                    NonMatchSelector_MagicRemainder
                )
            )
        }

        // Skip overflow checks as all for loops are indexed starting at zero.
c_0xf9f9b178(0xbf5d7f5bf10cf89e2c73056de8d4beaa13522633b247505b6d0e83c6223055e8); /* line */ 
        unchecked {
            // Iterate over each order.
c_0xf9f9b178(0x371e854ba20c868f8ffda13f9a3a04c5c05808c43ffc4ccc698194a0db529c4e); /* line */ 
            c_0xf9f9b178(0x6e35ba2dea64c7aa54dbbac2a1469702b0569fe632bcfadf758f0ace0ff9bf80); /* statement */ 
for (uint256 i = 0; i < totalOrders; ++i) {
                // Retrieve the current order.
c_0xf9f9b178(0x6e8285f73e61ed626d8fa83ca4d2cfce0c9db40a40cff9f903d1a3fe9d564090); /* line */ 
                c_0xf9f9b178(0x40cdea07eb9c4e3823fa6bc0ff33f85cd12d98888d0452e3bcfa80c1df566cc4); /* statement */ 
AdvancedOrder memory advancedOrder = advancedOrders[i];

                // Determine if max number orders have already been fulfilled.
c_0xf9f9b178(0x4c2b831a8d877d74bdc1b06282e31a903d7f16b8e487e7bf3367a512df57ccbe); /* line */ 
                c_0xf9f9b178(0x5a604387ca39b425ad6162b2824f8fb73f00e161b728b2a166199f0a71edabd4); /* statement */ 
if (maximumFulfilled == 0) {c_0xf9f9b178(0xa4591e9945cebc5bb6519fa2dc3e580a96583f819f40940e6b746907fcc9699c); /* branch */ 

                    // Mark fill fraction as zero as the order will not be used.
c_0xf9f9b178(0xd0cd0cd461dd2149bc5d3941d060da23761166e9cea0a5907028c6bcc3581e5a); /* line */ 
                    c_0xf9f9b178(0x5f8009b0d3abdae12f71dc91e9d2cd9488b7f2d5380b1bf254333beb1c1e1cc3); /* statement */ 
advancedOrder.numerator = 0;

                    // Update the length of the orderHashes array.
c_0xf9f9b178(0xde8dd2ab2b1c5241f7220972cd745cbde648c045069f37a62d5ae7a01fb0ab16); /* line */ 
                    assembly {
                        mstore(orderHashes, add(i, 1))
                    }

                    // Continue iterating through the remaining orders.
c_0xf9f9b178(0x419342e8d597a84a67e05960f746c18549666e9afe976db9d065e43252d3260e); /* line */ 
                    continue;
                }else { c_0xf9f9b178(0x3e851d255e91b424e93e90fbfad6576303d8521ff3aac16b0632e471dff8bc9f); /* branch */ 
}

                // Validate it, update status, and determine fraction to fill.
c_0xf9f9b178(0x1c0bb8a80ee73f51865c0a296eeab378d88fce3c5337de3602e32da2198f362b); /* line */ 
                c_0xf9f9b178(0xddea51d597121c90f3083fb376d29f44f3c37cfab6cf8d342eae6d896c8dbff8); /* statement */ 
(
                    bytes32 orderHash,
                    uint256 numerator,
                    uint256 denominator
                ) = _validateOrderAndUpdateStatus(
                        advancedOrder,
                        criteriaResolvers,
                        revertOnInvalid,
                        orderHashes
                    );

                // Update the length of the orderHashes array.
c_0xf9f9b178(0x48b7af36ddf084fe6508a4c1c3bf582ad061d19d05a03f356fa7b7b386827b8a); /* line */ 
                assembly {
                    mstore(orderHashes, add(i, 1))
                }

                // Do not track hash or adjust prices if order is not fulfilled.
c_0xf9f9b178(0xf9a7491308958f17440b186013e1307294f5280c3032cd21967e3d893aafdc3b); /* line */ 
                c_0xf9f9b178(0xcbc712bdb1b826eed0912051800ceec6388f165ed7691632e3d87b75d3b46f60); /* statement */ 
if (numerator == 0) {c_0xf9f9b178(0xc06708017ec3543ea7ec98b27daecce51f460d7c8129de16c673807747221d58); /* branch */ 

                    // Mark fill fraction as zero if the order is not fulfilled.
c_0xf9f9b178(0xcc7d3011bc4ca93cc37cf3ab13077257a7e2b839ddcb835d7bdf201c40a22353); /* line */ 
                    c_0xf9f9b178(0x3c1dc888f1ea486c8553f9713b49afb2dd584781d495efa0b1844d1f07a2f5a1); /* statement */ 
advancedOrder.numerator = 0;

                    // Continue iterating through the remaining orders.
c_0xf9f9b178(0xf0b735af85d26af5efe6be4f22fd9a8b19142641c42938958b5176c477dd93f3); /* line */ 
                    continue;
                }else { c_0xf9f9b178(0x5efe3affd0f9efc574f5335df1af0d87aebbef5dfabcd9bea2c1f78a65e39721); /* branch */ 
}

                // Otherwise, track the order hash in question.
c_0xf9f9b178(0xa34dd899f0ea2767c65d036c6736da98491984fcd2a37e653048a913f2ebe598); /* line */ 
                c_0xf9f9b178(0x7227188572ff8a03fbb6dfe7186a744f3076c9b29c5097f008e2c96d28e1b85c); /* statement */ 
orderHashes[i] = orderHash;

                // Decrement the number of fulfilled orders.
                // Skip underflow check as the condition before
                // implies that maximumFulfilled > 0.
c_0xf9f9b178(0x8b35800eaccc68ee3f51d19a925ce7b8f4433b254328abae3ed4110ed718009a); /* line */ 
                maximumFulfilled--;

                // Place the start time for the order on the stack.
c_0xf9f9b178(0xc38c2150ac67d1aa19fb34f5eff8dd218f55afc763e91017acfd275f8d32cd3f); /* line */ 
                c_0xf9f9b178(0x0e7297316e5464c63b54d546789faf15ee7ccea511a64250c92129ed35a6b1a5); /* statement */ 
uint256 startTime = advancedOrder.parameters.startTime;

                // Place the end time for the order on the stack.
c_0xf9f9b178(0xfa22be4d40f6c206d9d253908f72990d49dd74bbcfb3d718e705aa5c0bcffd24); /* line */ 
                c_0xf9f9b178(0x7e3c5f13c5057c8a5d3cedcd7f5369cf26279a940742c8e808939b69aa97fdec); /* statement */ 
uint256 endTime = advancedOrder.parameters.endTime;

                // Retrieve array of offer items for the order in question.
c_0xf9f9b178(0x3329c241b98dc2db6fdae65069da1633480a90b687fb130ab4a5749b6ef4e3a5); /* line */ 
                c_0xf9f9b178(0xfe8a15e52ab8e9a5e0ef4d55bec32e67125d2f20fb1d9904abb5276f2eb41182); /* statement */ 
OfferItem[] memory offer = advancedOrder.parameters.offer;

                // Read length of offer array and place on the stack.
c_0xf9f9b178(0xec7d85f91f74f9ef1f77f5e5c889cdf5538e6b2c29f0cef96100eae101246597); /* line */ 
                c_0xf9f9b178(0xc1e8914b2bed389b0841f77fae1a991c7671a85edff91bcfad2ea08340e4bb9d); /* statement */ 
uint256 totalOfferItems = offer.length;

                // Iterate over each offer item on the order.
c_0xf9f9b178(0xfc8b528d8c741365e7b4982653a5c72d3ccf2b2aa33add6aca6fc3e4407b540b); /* line */ 
                c_0xf9f9b178(0x59c62630f499d03380a4a393e471dab04e2c472b6e091f5886162fe898a5579b); /* statement */ 
for (uint256 j = 0; j < totalOfferItems; ++j) {
                    // Retrieve the offer item.
c_0xf9f9b178(0xa7d405c82c5b59d5d3643fbd1f0dcbfd88beed2ce211a2d125f12e2505b3f679); /* line */ 
                    c_0xf9f9b178(0x42da94b33a0b131308529e1afd7382513573bb24ea1b1d773f3d8bb42dc589bd); /* statement */ 
OfferItem memory offerItem = offer[j];

c_0xf9f9b178(0x2208ec4e4ab5619646339f15ec7c22d5dfdacb9d4c30ab2a776686da5ec1cfe7); /* line */ 
                    assembly {
                        // If the offer item is for the native token, set the
                        // first bit of the error buffer to true.
                        invalidNativeOfferItemErrorBuffer := or(
                            invalidNativeOfferItemErrorBuffer,
                            iszero(mload(offerItem))
                        )
                    }

                    // Apply order fill fraction to offer item end amount.
c_0xf9f9b178(0x468b38660de97439a7d08aaa6f364f9ee5376886e5ebf7e6d538872181c5ebfb); /* line */ 
                    c_0xf9f9b178(0x652d6472b75f36a4d3a95c5aa49b60186528a8800eb348d77eea5a10a26ef387); /* statement */ 
uint256 endAmount = _getFraction(
                        numerator,
                        denominator,
                        offerItem.endAmount
                    );

                    // Reuse same fraction if start and end amounts are equal.
c_0xf9f9b178(0x464fae8bf6a3a772dd1d77d4bc0646085d6358df4ebe2fd643126829991d13e4); /* line */ 
                    c_0xf9f9b178(0x862602bbd0b4afd5e9b4001199db6783a959a781f954a5af7254c1ebd1ce527a); /* statement */ 
if (offerItem.startAmount == offerItem.endAmount) {c_0xf9f9b178(0x4d614fdf26cab31385e39caeca769a8f7d423563ef0e6bab5df365bf6dc67038); /* branch */ 

                        // Apply derived amount to both start and end amount.
c_0xf9f9b178(0x1927aafd0ad1534826f5f8e1d404495e3bfdc3a5b02d7a2a0ecad3e1bf3fba5d); /* line */ 
                        c_0xf9f9b178(0xe6be90e6f2cce21f615d70879cd9c511ca6a3d157960f2dad340ea99c640a7c1); /* statement */ 
offerItem.startAmount = endAmount;
                    } else {c_0xf9f9b178(0x0cf9eeb0017f88bbe407ec5ed930f5d9657ea851bcd1c539a6f965ad6af85d9e); /* branch */ 

                        // Apply order fill fraction to offer item start amount.
c_0xf9f9b178(0xe648f64c38e14e3c7f0044d68375d79f4adda06e47cfa2a807e40e02b59508b8); /* line */ 
                        c_0xf9f9b178(0x7e57633bdcf458fc65f98319f82226ec35f8c83bd5c545de58ef907544a3cc94); /* statement */ 
offerItem.startAmount = _getFraction(
                            numerator,
                            denominator,
                            offerItem.startAmount
                        );
                    }

                    // Update end amount in memory to match the derived amount.
c_0xf9f9b178(0xf9689b9f1c167eb761c38b1e0ff3b3ea982b9b0b1d04e43c1f4b75be994e0ada); /* line */ 
                    c_0xf9f9b178(0xd9f76750b5bd5c45b7d2828ad34d404f35670ef9c028bd96b191362eb538fc44); /* statement */ 
offerItem.endAmount = endAmount;

                    // Adjust offer amount using current time; round down.
c_0xf9f9b178(0x1bb88adb507141163a3b2577cc3696eb1e1a6886396efd8f243dfdd6072bc5ef); /* line */ 
                    c_0xf9f9b178(0x1b4793600a202f373dd8e873363ca3558f1d1d217c0006a02a630c59e407df47); /* statement */ 
offerItem.startAmount = _locateCurrentAmount(
                        offerItem.startAmount,
                        offerItem.endAmount,
                        startTime,
                        endTime,
                        false // round down
                    );
                }

                // Retrieve array of consideration items for order in question.
c_0xf9f9b178(0x53fb7b85c24c62b92822e6c088525d862887d2cfe462f799724c57f45590d357); /* line */ 
                c_0xf9f9b178(0x8508594ecd33f5c556a994cfac37f1127b57beecb65efe5fe9c59e0ccf0cda78); /* statement */ 
ConsiderationItem[] memory consideration = (
                    advancedOrder.parameters.consideration
                );

                // Read length of consideration array and place on the stack.
c_0xf9f9b178(0xe0eca9bf38bfe3f8f4289fb6a134e928b60f94f0beb3ceccd222d392f9e9d850); /* line */ 
                c_0xf9f9b178(0x9a8be8db64395ce99e317acfeb9cfc0f8c6d62ca32e99218193a569418e23078); /* statement */ 
uint256 totalConsiderationItems = consideration.length;

                // Iterate over each consideration item on the order.
c_0xf9f9b178(0xc86dca52ed2c3b50b33e403c0569bcfb653d52e0f0a100025a7da9ab9357f2cf); /* line */ 
                c_0xf9f9b178(0x23dabd17a0a8b582eb8df25b2715ba113d119baf9c11ee7415746a5149eac9aa); /* statement */ 
for (uint256 j = 0; j < totalConsiderationItems; ++j) {
                    // Retrieve the consideration item.
c_0xf9f9b178(0x2db41d331662a39977c8aa9f5c8ecb79a81cdfc700569ec889f3d05fbcf052d8); /* line */ 
                    c_0xf9f9b178(0xcfd421b2414688ddc8cebe7ee27f49510d20e52046738dcdc0147381eed736bb); /* statement */ 
ConsiderationItem memory considerationItem = (
                        consideration[j]
                    );

                    // Apply fraction to consideration item end amount.
c_0xf9f9b178(0xa28b2fff1fff1df8f1535bf3d7d4e3feff9ce5a53bc2df76ff1b4131340386c5); /* line */ 
                    c_0xf9f9b178(0x46fd98b813df6fdc5ee086425bd8164f3f666ab06fa87bf0f9a2171bb1ba9c26); /* statement */ 
uint256 endAmount = _getFraction(
                        numerator,
                        denominator,
                        considerationItem.endAmount
                    );

                    // Reuse same fraction if start and end amounts are equal.
c_0xf9f9b178(0x91f29a6d2426ef6fb19ecfff74e39689cae9491bcfff208901e929542ecb4b0e); /* line */ 
                    c_0xf9f9b178(0xac31f9579b89130c59553f1ab982fad2c101f3ab344808057d061d8e54e26d76); /* statement */ 
if (
                        considerationItem.startAmount ==
                        considerationItem.endAmount
                    ) {c_0xf9f9b178(0x027e54ba3a88f1f43648916db432eec9b5311aac2ac1553003e216ca48e978a8); /* branch */ 

                        // Apply derived amount to both start and end amount.
c_0xf9f9b178(0x9c7a5ad84e0dc1d6c216797a51cf316d04cfeb0625de779c01e7d9d5e1c6ff5f); /* line */ 
                        c_0xf9f9b178(0x8c68003d7ee01eff383d95cad515df8a3d5d42a8465793cd3003f35987d06905); /* statement */ 
considerationItem.startAmount = endAmount;
                    } else {c_0xf9f9b178(0xf64a18d920e9430fe8a02e96e72ca2cfa3770580cccd8e14bed3be6ab088cf1e); /* branch */ 

                        // Apply fraction to consideration item start amount.
c_0xf9f9b178(0xb6328e18097b86a4a0434fcd2381c7851f43fcc1272b73c754d976116fb420a8); /* line */ 
                        c_0xf9f9b178(0x6763a0a6356d4d143139593fa73939b236ad25acd4aa90835bd772abd4f154db); /* statement */ 
considerationItem.startAmount = _getFraction(
                            numerator,
                            denominator,
                            considerationItem.startAmount
                        );
                    }

                    // Update end amount in memory to match the derived amount.
c_0xf9f9b178(0x633c80d94744b7a31641704fef283766ab3deaf809bbef2bb3b2c34e6054dbe2); /* line */ 
                    c_0xf9f9b178(0x5abb070f3b1fc15c54fe44d6f7495d27b4571cabe0830c3d6e9b2a1ccc48b6fc); /* statement */ 
considerationItem.endAmount = endAmount;

                    // Adjust consideration amount using current time; round up.
c_0xf9f9b178(0x56f415bbf8e24d0185f557eb022f024d44c53d0e1735e4780fbf7f848a100eea); /* line */ 
                    c_0xf9f9b178(0x0f972976ea21fcd4cb63ebdf8fa30cd9339780fe1fbf4b90b0e7d7d88ffd3c2d); /* statement */ 
considerationItem.startAmount = (
                        _locateCurrentAmount(
                            considerationItem.startAmount,
                            considerationItem.endAmount,
                            startTime,
                            endTime,
                            true // round up
                        )
                    );

                    // Utilize assembly to manually "shift" the recipient value.
c_0xf9f9b178(0x0f2cf075b6f86f1b02bdfb0de6cf205c05e185fe1356c1ea3b5c2c074e233501); /* line */ 
                    assembly {
                        // Write recipient to endAmount, as endAmount is not
                        // used from this point on and can be repurposed to fit
                        // the layout of a ReceivedItem.
                        mstore(
                            add(
                                considerationItem,
                                ReceivedItem_recipient_offset // old endAmount
                            ),
                            mload(
                                add(
                                    considerationItem,
                                    ConsiderationItem_recipient_offset
                                )
                            )
                        )
                    }
                }
            }
        }

        // If the first bit is set, a native offer item was encountered. If the
        // second bit is set in the error buffer, the current function is not
        // matchOrders or matchAdvancedOrders. If the value is three, both the
        // first and second bits were set; in that case, revert with an error.
c_0xf9f9b178(0x9cd4ace74cbe4058ca2630fb5045adb81daaafd3f71872ededc442a295b0652e); /* line */ 
        c_0xf9f9b178(0xbdf19e773cdcf3290670287e043532f972dd765b2b88dce114a887c2b8b26e68); /* statement */ 
if (invalidNativeOfferItemErrorBuffer == 3) {c_0xf9f9b178(0x2b1f012d1f2e193944c144a3bab31d4038905a3a233cea1287ab5516229b28be); /* branch */ 

c_0xf9f9b178(0x945abf7f37deaad8a2ca1efc484b51193f720ed810789087f8d7b8670347e75d); /* line */ 
            revert InvalidNativeOfferItem();
        }else { c_0xf9f9b178(0x9c6c76fb9d93b38ac8aab60e13cfda1a0ee39a7681753a0f092847c7a866b939); /* branch */ 
}

        // Apply criteria resolvers to each order as applicable.
c_0xf9f9b178(0xf84fd725634dcfdfe9b9d3134e74fa4129f6914c0142ccdeb971b6e99da1a91e); /* line */ 
        c_0xf9f9b178(0x871ec7e144059d1da805ee80cfde67b5e847c74e0062a04c3e39389752a6f1a2); /* statement */ 
_applyCriteriaResolvers(advancedOrders, criteriaResolvers);

        // Emit an event for each order signifying that it has been fulfilled.
        // Skip overflow checks as all for loops are indexed starting at zero.
c_0xf9f9b178(0xce3c2ff2a3be39c22976a3f03ed2263ff180543453f581bc416982b12b14ad6b); /* line */ 
        unchecked {
            // Iterate over each order.
c_0xf9f9b178(0xf383f93595834881b1ba2eb9fd560f00b419026db92c4f3006b6ad8debeffa81); /* line */ 
            c_0xf9f9b178(0xbb3c70e81c39e7ce297765220a232ab68b09b7a40e65c4d23764c26c97507ddf); /* statement */ 
for (uint256 i = 0; i < totalOrders; ++i) {
                // Do not emit an event if no order hash is present.
c_0xf9f9b178(0x01b76ba60d2ea199bb242f05d2ad9fe130ee905bf28d85e1f10771b6c8f6bc81); /* line */ 
                c_0xf9f9b178(0x8062fcf2e725da5a45f184ceb5037575d455e0496a8b3dc3387d6979efc5d6e8); /* statement */ 
if (orderHashes[i] == bytes32(0)) {c_0xf9f9b178(0x3b6f1ced36d51fd7e1cb86a15a79fdc2d3bbb7a25e7335d10953540c92a387df); /* branch */ 

c_0xf9f9b178(0xd3d6af53c9d20957a719821a08f9fd22872010b2299dfceec12a70ed27db666e); /* line */ 
                    continue;
                }else { c_0xf9f9b178(0xcec2bf1574c49236243084a173e0ca58c61893d6c517540b9a54093f3763315b); /* branch */ 
}

                // Retrieve parameters for the order in question.
c_0xf9f9b178(0x6d498ba888b18e0aa2018309e91e1d680f07af95b284d275500cca1f6d564019); /* line */ 
                c_0xf9f9b178(0x95988f3a583048dade9f1e3461e09383ed942d1902b95b8a2b35a48d95ef41c6); /* statement */ 
OrderParameters memory orderParameters = (
                    advancedOrders[i].parameters
                );

                // Emit an OrderFulfilled event.
c_0xf9f9b178(0x4ea8575910d09760a8095509e76e3cded24b665ab5af9f0d6c1ca85cc11c2508); /* line */ 
                c_0xf9f9b178(0xe7c034a0ebd1cc738095522887738a2eadf8394865bf910414c74fd2cde73e86); /* statement */ 
_emitOrderFulfilledEvent(
                    orderHashes[i],
                    orderParameters.offerer,
                    orderParameters.zone,
                    recipient,
                    orderParameters.offer,
                    orderParameters.consideration
                );
            }
        }
    }

    /**
     * @dev Internal function to fulfill a group of validated orders, fully or
     *      partially, with an arbitrary number of items for offer and
     *      consideration per order and to execute transfers. Any order that is
     *      not currently active, has already been fully filled, or has been
     *      cancelled will be omitted. Remaining offer and consideration items
     *      will then be aggregated where possible as indicated by the supplied
     *      offer and consideration component arrays and aggregated items will
     *      be transferred to the fulfiller or to each intended recipient,
     *      respectively. Note that a failing item transfer or an issue with
     *      order formatting will cause the entire batch to fail.
     *
     * @param advancedOrders            The orders to fulfill along with the
     *                                  fraction of those orders to attempt to
     *                                  fill. Note that both the offerer and the
     *                                  fulfiller must first approve this
     *                                  contract (or the conduit if indicated by
     *                                  the order) to transfer any relevant
     *                                  tokens on their behalf and that
     *                                  contracts must implement
     *                                  `onERC1155Received` in order to receive
     *                                  ERC1155 tokens as consideration. Also
     *                                  note that all offer and consideration
     *                                  components must have no remainder after
     *                                  multiplication of the respective amount
     *                                  with the supplied fraction for an
     *                                  order's partial fill amount to be
     *                                  considered valid.
     * @param offerFulfillments         An array of FulfillmentComponent arrays
     *                                  indicating which offer items to attempt
     *                                  to aggregate when preparing executions.
     * @param considerationFulfillments An array of FulfillmentComponent arrays
     *                                  indicating which consideration items to
     *                                  attempt to aggregate when preparing
     *                                  executions.
     * @param fulfillerConduitKey       A bytes32 value indicating what conduit,
     *                                  if any, to source the fulfiller's token
     *                                  approvals from. The zero hash signifies
     *                                  that no conduit should be used, with
     *                                  direct approvals set on Consideration.
     * @param recipient                 The intended recipient for all received
     *                                  items.
     *
     * @return availableOrders An array of booleans indicating if each order
     *                         with an index corresponding to the index of the
     *                         returned boolean was fulfillable or not.
     * @return executions      An array of elements indicating the sequence of
     *                         transfers performed as part of matching the given
     *                         orders.
     */
    function _executeAvailableFulfillments(
        AdvancedOrder[] memory advancedOrders,
        FulfillmentComponent[][] memory offerFulfillments,
        FulfillmentComponent[][] memory considerationFulfillments,
        bytes32 fulfillerConduitKey,
        address recipient
    )
        internal
        returns (bool[] memory availableOrders, Execution[] memory executions)
    {c_0xf9f9b178(0x1dfd416090586cf3292e975a25690dfec34b5c6c54837b4ffe46756b9d447240); /* function */ 

        // Retrieve length of offer fulfillments array and place on the stack.
c_0xf9f9b178(0x15dbd0f9ae6017f81d352683dd7ce1c9b929058bc52c9cfb85d7c249e8d03a67); /* line */ 
        c_0xf9f9b178(0xdc829ba26f1ae39df54e706ff68c949217cef4e3efce966b3f20b6fda0179240); /* statement */ 
uint256 totalOfferFulfillments = offerFulfillments.length;

        // Retrieve length of consideration fulfillments array & place on stack.
c_0xf9f9b178(0x3bc09f3e4f7bdc9556b303e24697d380d838a8ed21b479e76da61702eb5e762a); /* line */ 
        c_0xf9f9b178(0x51013ef412aa9a83c383faf86d4a1dabbfb91a78f1a486c853f7eca853268d89); /* statement */ 
uint256 totalConsiderationFulfillments = (
            considerationFulfillments.length
        );

        // Allocate an execution for each offer and consideration fulfillment.
c_0xf9f9b178(0xd2efe9d3020328a43e696c7bc0ca4662596fca7a37cca51eac93ccc79df00dd8); /* line */ 
        c_0xf9f9b178(0x8768fa792fd5914e9a67a213867d6fa8db599902decd16fba1dfc89eeac682da); /* statement */ 
executions = new Execution[](
            totalOfferFulfillments + totalConsiderationFulfillments
        );

        // Skip overflow checks as all for loops are indexed starting at zero.
c_0xf9f9b178(0x251f5809755ab3ecd7ecee9270c2ffa8fa18f434fce15c8b60082e4779c5ef5d); /* line */ 
        unchecked {
            // Track number of filtered executions.
c_0xf9f9b178(0x41132daf95260a5cd933a15df06716fdf54098897c217cba698df9708a7cc727); /* line */ 
            c_0xf9f9b178(0xfd93588ecf75cee704820a398cf74f6ff0133cc8a3c5672338e7006ea76fb781); /* statement */ 
uint256 totalFilteredExecutions = 0;

            // Iterate over each offer fulfillment.
c_0xf9f9b178(0x3c077d61585e03f84d2908514fd5703236a1a2e30482c7838b2bd6296679e028); /* line */ 
            c_0xf9f9b178(0x13b72adadf4166cfef2b9dca9eaa081f8a51f3d7e04ab6dd94c4e886b2b07e00); /* statement */ 
for (uint256 i = 0; i < totalOfferFulfillments; ++i) {
                /// Retrieve the offer fulfillment components in question.
c_0xf9f9b178(0x9993216e6087f004e21cc044aaa8d32c38ddcfbbcd5eefc79bda6492187bcfed); /* line */ 
                c_0xf9f9b178(0xf70a4715de626cbcb57420ec3a3b4a839ae17d1d5a7df98bfb720c28759a1832); /* statement */ 
FulfillmentComponent[] memory components = (
                    offerFulfillments[i]
                );

                // Derive aggregated execution corresponding with fulfillment.
c_0xf9f9b178(0x71de01924abb8ef9f1fb74669009fb3671732c4e1208c97e2cb36482e1efdcda); /* line */ 
                c_0xf9f9b178(0x9bbf190c57ce124a5bb8d4e57705d863d45d2539e1571a60e1742b230f53b8e5); /* statement */ 
Execution memory execution = _aggregateAvailable(
                    advancedOrders,
                    Side.OFFER,
                    components,
                    fulfillerConduitKey,
                    recipient
                );

                // If offerer and recipient on the execution are the same...
c_0xf9f9b178(0xf55d703f49a814be4c2b1faa1950b06ef213a8cd3fac4d5c13e38df46e235713); /* line */ 
                c_0xf9f9b178(0x451b45efee04f125ab3a67e6968496d8d558c64ffb141a3fac4684140f38ad13); /* statement */ 
if (execution.item.recipient == execution.offerer) {c_0xf9f9b178(0xe661d7222a07cb71d8a9e3dec6961b0832344341a0246a9bae4fffabc7d1ed90); /* branch */ 

                    // Increment total filtered executions.
c_0xf9f9b178(0xa21de0b01edef08eaee5a9583da59ea7f04b97271641f5aef2a0902515efe84a); /* line */ 
                    ++totalFilteredExecutions;
                } else {c_0xf9f9b178(0xfd9d088e4463e35b412f9217a33fd20de164ea8a28ffe57069bb31b084970b4c); /* branch */ 

                    // Otherwise, assign the execution to the executions array.
c_0xf9f9b178(0x9417ee5434bde765e4ce798d26a58401256c09183c1e3d15c9b45e3ea9a64b17); /* line */ 
                    c_0xf9f9b178(0x2a4e93464bb48eb041726853d28e1bc6641660ddc6ba613eb70c537ef315da94); /* statement */ 
executions[i - totalFilteredExecutions] = execution;
                }
            }

            // Iterate over each consideration fulfillment.
c_0xf9f9b178(0x8dea4b3abf5c4d1dea78dad46a1804a41a13a0065e038c85d5a356bc7f839921); /* line */ 
            c_0xf9f9b178(0x7372af923e789ed4be9dfb6c5adc0fb6d94c0ba1324be8f91ab82c2d4b6a5e2b); /* statement */ 
for (uint256 i = 0; i < totalConsiderationFulfillments; ++i) {
                /// Retrieve consideration fulfillment components in question.
c_0xf9f9b178(0x00adbb66dc23ac29e716c7065ebf648c5345003330d124753c919f2f384069ca); /* line */ 
                c_0xf9f9b178(0xb087feb5d116c11c4978bb9d202ea56d3afad1f5dc6fa6e60fd58f072eb9fb05); /* statement */ 
FulfillmentComponent[] memory components = (
                    considerationFulfillments[i]
                );

                // Derive aggregated execution corresponding with fulfillment.
c_0xf9f9b178(0x0c0503058eb21ced48623d82fc5cfbf3efb88670919faedee0da78a8048d7915); /* line */ 
                c_0xf9f9b178(0xa08face1f90bc0e2a0dbbb5534605f1172e85e769f3d2929396b0ec500cf8240); /* statement */ 
Execution memory execution = _aggregateAvailable(
                    advancedOrders,
                    Side.CONSIDERATION,
                    components,
                    fulfillerConduitKey,
                    address(0) // unused
                );

                // If offerer and recipient on the execution are the same...
c_0xf9f9b178(0x1ebe367aed63fac030b4ffed8fd0b0cbadf1e19755bca602170817c0e43cb016); /* line */ 
                c_0xf9f9b178(0x12825231a43779f9463d62b0808f251622529c73b7d91e3a92b7ef31c02adb40); /* statement */ 
if (execution.item.recipient == execution.offerer) {c_0xf9f9b178(0x044876172de4b8e04d64aa67a8107b1e35ae4470911cb3b884d4e926f69ae6d0); /* branch */ 

                    // Increment total filtered executions.
c_0xf9f9b178(0x15f3a37d379618cac490e8a4cc3e2ca41aae7cc90cd17f4ddd888499a3377e07); /* line */ 
                    ++totalFilteredExecutions;
                } else {c_0xf9f9b178(0xc59fc4ceb42129b66bfa623851c6c7d2568c1352329fa5e969ce6aeb95d0e213); /* branch */ 

                    // Otherwise, assign the execution to the executions array.
c_0xf9f9b178(0xfb3d51aadfb37d1d7c171719204dcde0be79508649934131a438695d391909f2); /* line */ 
                    c_0xf9f9b178(0x5e490227e3bda5696e0fd53fa551928f6b78763132abaa322f53c68cc00155c1); /* statement */ 
executions[
                        i + totalOfferFulfillments - totalFilteredExecutions
                    ] = execution;
                }
            }

            // If some number of executions have been filtered...
c_0xf9f9b178(0x1a358f62c306982e992aac99075d1b3874b0f3ba2a029658b49d8f9d81ac374a); /* line */ 
            c_0xf9f9b178(0xbd5d9f841516ba5a7db93641b9ee1f8cba042ea601c77b4f69d6e22a6aa580fd); /* statement */ 
if (totalFilteredExecutions != 0) {c_0xf9f9b178(0xb8709550548d74a6a1b3bbcff4669130e967602677f1691b8e265ea00acbf1da); /* branch */ 

                // reduce the total length of the executions array.
c_0xf9f9b178(0x70bba3b69ef554565446f1ed558f07b031828cc7a249c45db4777ff1a48a2b3d); /* line */ 
                assembly {
                    mstore(
                        executions,
                        sub(mload(executions), totalFilteredExecutions)
                    )
                }
            }else { c_0xf9f9b178(0xcb4c16b0058613f7a0ec4491500ef6cb382fbf2ac29e9066a8f092e8d6606b34); /* branch */ 
}
        }

        // Revert if no orders are available.
c_0xf9f9b178(0xbf7f60f8b95d35bf41d8323538a29d66b44451708e7308c7ed3295c49cd3f9ed); /* line */ 
        c_0xf9f9b178(0xdef4b4d6c3b42d9635b1e908f2a443f5d9d074cee9e165f0017d59e494f65528); /* statement */ 
if (executions.length == 0) {c_0xf9f9b178(0xce04bbbed63ce00772215eed5c6fbc86fd34b7e642361be07b81e84f87a09fa4); /* branch */ 

c_0xf9f9b178(0x47a487c4765b7f04c4b406209111d67dcf6ee8df8392bc5d39b08b6688862439); /* line */ 
            revert NoSpecifiedOrdersAvailable();
        }else { c_0xf9f9b178(0x5eb3a7b01e0c458c894985b69bad413b4bab88b880e1ea851a8dbadcd6518968); /* branch */ 
}

        // Perform final checks and return.
c_0xf9f9b178(0x17818e7121d42326530a44c273137cd97a7d6aa51240ea37cc98d223833b56cc); /* line */ 
        c_0xf9f9b178(0x2a5b13dc70f3003936ed71aa0e1586382df0bf0dde1bf73cdb80586d6bcf6abd); /* statement */ 
availableOrders = _performFinalChecksAndExecuteOrders(
            advancedOrders,
            executions
        );

c_0xf9f9b178(0x447906e1bf2b50ba4835094dd0899aa839c7cd0f1492eca1cb83a5abb692d347); /* line */ 
        c_0xf9f9b178(0x27a92411e52577a44ada0ace10af15ac22773d6f24fb7a79938725cb9a0cafbe); /* statement */ 
return (availableOrders, executions);
    }

    /**
     * @dev Internal function to perform a final check that each consideration
     *      item for an arbitrary number of fulfilled orders has been met and to
     *      trigger associated executions, transferring the respective items.
     *
     * @param advancedOrders     The orders to check and perform executions for.
     * @param executions         An array of elements indicating the sequence of
     *                           transfers to perform when fulfilling the given
     *                           orders.
     *
     * @return availableOrders An array of booleans indicating if each order
     *                         with an index corresponding to the index of the
     *                         returned boolean was fulfillable or not.
     */
    function _performFinalChecksAndExecuteOrders(
        AdvancedOrder[] memory advancedOrders,
        Execution[] memory executions
    ) internal returns (bool[] memory availableOrders) {c_0xf9f9b178(0x39e79d05704c621e3026a61393d1dacf4d1431ae6ee0580410303e26191b80c4); /* function */ 

        // Retrieve the length of the advanced orders array and place on stack.
c_0xf9f9b178(0xed21c0b9e716583a71b81ba3cc8b6ca36d532a07c36e8a7d877bfbeec5575ad3); /* line */ 
        c_0xf9f9b178(0xb4a37bbbb0f3a68ee4c150a6c559fdf6972f6aeed54bcdaf403514bbd6a76ed6); /* statement */ 
uint256 totalOrders = advancedOrders.length;

        // Initialize array for tracking available orders.
c_0xf9f9b178(0x5a8d565df2dd564b0fa4c979d95e8d55bc54bcfa47d8fab4df7b29fd6b4e40e0); /* line */ 
        c_0xf9f9b178(0x1d4d4eb614b098c41805d92108f7734f44a404b4f5ab07ceceee5e1684632ab6); /* statement */ 
availableOrders = new bool[](totalOrders);

        // Skip overflow checks as all for loops are indexed starting at zero.
c_0xf9f9b178(0xe6fd1142b738074f7cdf6b72979ed8b70799d22b5e5cdd1e95f8401d5abaf4d5); /* line */ 
        unchecked {
            // Iterate over orders to ensure all considerations are met.
c_0xf9f9b178(0xe350b5d0ed02b8b5c58eac5c8df3e9c21c883c16b71fb90d8061b9f84321e9bc); /* line */ 
            c_0xf9f9b178(0x28a9ba5e44bd81a321b1a6767df373a0727a85456aab5bd78fa6bed70c6f1e45); /* statement */ 
for (uint256 i = 0; i < totalOrders; ++i) {
                // Retrieve the order in question.
c_0xf9f9b178(0xb206ab31cec8aa03514496f3920d3bff56e4d7fa76234d2760072a35f6369020); /* line */ 
                c_0xf9f9b178(0xe72272c4220581032cf6a3d1898c7424a7614b9c1c54b2234a9d57e2527792b5); /* statement */ 
AdvancedOrder memory advancedOrder = advancedOrders[i];

                // Skip consideration item checks for order if not fulfilled.
c_0xf9f9b178(0x72aa13654f0deec2031a8ad42c48fd5d186c379f7371af851e096cf217dfebad); /* line */ 
                c_0xf9f9b178(0xe350efffa8679ed3e08934ccb16c92a3ef2c354898fccc2c566e3f008edf001c); /* statement */ 
if (advancedOrder.numerator == 0) {c_0xf9f9b178(0xdabcc30fcbf81d3d7b3c8cb2eb174bdc1a117bcaa2045fe27d68469a699270e6); /* branch */ 

                    // Note: orders do not need to be marked as unavailable as a
                    // new memory region has been allocated. Review carefully if
                    // altering compiler version or managing memory manually.
c_0xf9f9b178(0xe068cfbae9557fc623ecacee3a283ac8a4544b3268ae06d74f315fcab165a715); /* line */ 
                    continue;
                }else { c_0xf9f9b178(0x0a838e11578ccba20cd358952a5237086cb32aa3653ac137d17b5da06ea63e75); /* branch */ 
}

                // Mark the order as available.
c_0xf9f9b178(0x9676b37a9a18b512bda28f6da0c6de6ffefa29d07bb074c403a3a222988c3097); /* line */ 
                c_0xf9f9b178(0xa8a42744368f74408e37c708ebbf8f159e1d3655eaf82ec310a41b476d93fb26); /* statement */ 
availableOrders[i] = true;

                // Retrieve consideration items to ensure they are fulfilled.
c_0xf9f9b178(0xc5cce2be2776f712d384c2a2d96c8652fd3e5993575da4977391034e11018b3f); /* line */ 
                c_0xf9f9b178(0xeddd137ffffe64cb0614211acd499e0e6b50e8ccbab5554af004a589e4feb99d); /* statement */ 
ConsiderationItem[] memory consideration = (
                    advancedOrder.parameters.consideration
                );

                // Read length of consideration array and place on the stack.
c_0xf9f9b178(0x48144d06d0d0b6bc61fac1331f68fe0764d55b5f8d5e49962ee7ff23c8218d55); /* line */ 
                c_0xf9f9b178(0x0fd6a680a601096f0feb679b8a12b9be6545608ba7afe1be4c26dd52f5d05ef7); /* statement */ 
uint256 totalConsiderationItems = consideration.length;

                // Iterate over each consideration item to ensure it is met.
c_0xf9f9b178(0x24dac2ea96db229de8c20e062e26413c535ebe6bf16f09ca0516a215f88f1252); /* line */ 
                c_0xf9f9b178(0x4afad488722b8e317c9c576c6dbb0694d47863a256c8a7cd369716d51a557ea4); /* statement */ 
for (uint256 j = 0; j < totalConsiderationItems; ++j) {
                    // Retrieve remaining amount on the consideration item.
c_0xf9f9b178(0x962ae98b77efe624f8dc9e59125cd6141e8ad6b96316006d143b4df1714ada2a); /* line */ 
                    c_0xf9f9b178(0xaa4cda3a003f8a9864b3c559dba19ceccb1b72ab9c988579ae33cc558e4986ae); /* statement */ 
uint256 unmetAmount = consideration[j].startAmount;

                    // Revert if the remaining amount is not zero.
c_0xf9f9b178(0x76c511c9f836c3d683d5501472f7e4b462806e0ea0eef90cbeca61220576c2bc); /* line */ 
                    c_0xf9f9b178(0x7019d97f0ac56367c7eed29f229dc4e8f7f9560f5f20288398592d7ce3d7c8ac); /* statement */ 
if (unmetAmount != 0) {c_0xf9f9b178(0xa151b4020d554aeaedbd3cb3eee3be6c021feeca9f6c8b70c2f4478a41b69c18); /* branch */ 

c_0xf9f9b178(0x418bbd39337e40b1f84965373b1cbb0edfc3188a10570b9f78d6506fe44271da); /* line */ 
                        revert ConsiderationNotMet(i, j, unmetAmount);
                    }else { c_0xf9f9b178(0xa41f83c823b164b892dba613419ca8aaf027d1a4df7048de40ef6fd3088c2b8e); /* branch */ 
}
                }
            }
        }

        // Put ether value supplied by the caller on the stack.
c_0xf9f9b178(0x9acc65867d80e351186c71e3a5f9dd20c5bc36316bdc662eab59d13f8d355f45); /* line */ 
        c_0xf9f9b178(0xb9947a5b8df1fd2b4439cfe55a268234ee98878a59687fa6a902062d7dce09ad); /* statement */ 
uint256 etherRemaining = msg.value;

        // Initialize an accumulator array. From this point forward, no new
        // memory regions can be safely allocated until the accumulator is no
        // longer being utilized, as the accumulator operates in an open-ended
        // fashion from this memory pointer; existing memory may still be
        // accessed and modified, however.
c_0xf9f9b178(0x24b990964a66efbe0fc5e0919b00f18a17c3b9512ecf682ddff0da0ddcfcf015); /* line */ 
        c_0xf9f9b178(0x22e6578150571a27110329a8e40ed1c4cf9c97b9a8497556bf4dfee31739869d); /* statement */ 
bytes memory accumulator = new bytes(AccumulatorDisarmed);

        // Retrieve the length of the executions array and place on stack.
c_0xf9f9b178(0x6d41aa5b07bbb4c569c83fb204bfc326f374d55d26cebc98084689a790ba725f); /* line */ 
        c_0xf9f9b178(0xa7f06dc63c13e3a7aaf8e943a2c22052e956be9574ab0f4d42d5a024e350aabd); /* statement */ 
uint256 totalExecutions = executions.length;

        // Iterate over each execution.
c_0xf9f9b178(0xf5623e9c049e6d6eca29490d53f8c6cbeb1ad0744c5fc1970b4c338275f285db); /* line */ 
        c_0xf9f9b178(0x4a2dc6f49741d5e3140cd99d2bdd240b2c3b6150a6defab0009437d0294d9cbf); /* statement */ 
for (uint256 i = 0; i < totalExecutions; ) {
            // Retrieve the execution and the associated received item.
c_0xf9f9b178(0x2bba96c19e1312d4ce1179b6c1961a7d25398fb7ab134c89bf08399bde3cf522); /* line */ 
            c_0xf9f9b178(0x114d09b3fd55223cb0c23a8860354f46c8356b0243cf4aee330dcdf0dff6f2b6); /* statement */ 
Execution memory execution = executions[i];
c_0xf9f9b178(0x1363b2750edeaf28935232ea5fa1ef02a2146e5b9b2faa3116f552c86ca1e2a5); /* line */ 
            c_0xf9f9b178(0x079723e159df03e86bba71ce25eece0e297c8c72687f8405c930d976c3581d85); /* statement */ 
ReceivedItem memory item = execution.item;

            // If execution transfers native tokens, reduce value available.
c_0xf9f9b178(0xc37343d107c85a8cf2b3054df922a142aba65f0d94763073c384b45f257200c8); /* line */ 
            c_0xf9f9b178(0x3398a2e85c0e3a80a84da930283f09f7ec2bfea712f193e57129e863fe681c43); /* statement */ 
if (item.itemType == ItemType.NATIVE) {c_0xf9f9b178(0xda3b5ce7518066bf310bf17cc43def9ae33c02b348d09f9c9370cc6182364f0c); /* branch */ 

                // Ensure that sufficient native tokens are still available.
c_0xf9f9b178(0x087413f97f4ba29bea9238af5dc076305e09064e47dbf1808c54bb8ed5e621a6); /* line */ 
                c_0xf9f9b178(0x9048c66307c2ded5bf4edc4efc8aeeabe957f1c3b1f8ae305797192d8b94967f); /* statement */ 
if (item.amount > etherRemaining) {c_0xf9f9b178(0x64baeeb39d2901219e6bd3063186551a35f5e50b766b46e42d96e875feba2d1c); /* branch */ 

c_0xf9f9b178(0x03ac595ff5f89032ca8b100ea4073fd47398ae41eaf8c30e5c0db073d2b6114a); /* line */ 
                    revert InsufficientEtherSupplied();
                }else { c_0xf9f9b178(0x744f485939e0b2c19885c48c1aa5c19f357c4e9e33862fdf373ddda851a18f67); /* branch */ 
}

                // Skip underflow check as amount is less than ether remaining.
c_0xf9f9b178(0x3edb121e09cd8e8e10e2e2379f2eea2dc6568719447d5e53c5323a5a898eead7); /* line */ 
                unchecked {
c_0xf9f9b178(0xb8a5e22cbb6bf9a63cc8aaa6c8f4d194a0469347ba810d75e34c456db132da3c); /* line */ 
                    c_0xf9f9b178(0x32328e1a3ea875a23f84c93338371cc98cdaa16b935f006387c6d301d2c49d55); /* statement */ 
etherRemaining -= item.amount;
                }
            }else { c_0xf9f9b178(0xbb992c1cd3a0c9fbd26bd6dfeefb21dcd23abb96d668c411442b6c054099b6e0); /* branch */ 
}

            // Transfer the item specified by the execution.
c_0xf9f9b178(0x9c01e8128326c1e9fc443433c0fc4ea7beac2e5729d97e45c9a831adc21ef777); /* line */ 
            c_0xf9f9b178(0x511252b6c9242c20bbba46d699b507a40af2ff0e4d51caf4b9ed693ee64d4fe7); /* statement */ 
_transfer(
                item,
                execution.offerer,
                execution.conduitKey,
                accumulator
            );

            // Skip overflow check as for loop is indexed starting at zero.
c_0xf9f9b178(0x57097cb414502044ee4c39b21382a55450cd2d7373be3ff3084918a8f738ef41); /* line */ 
            unchecked {
c_0xf9f9b178(0x5ac34bc67fab95ec3b73cf8c992a43edc2168530132dd5e319cf9f63101b4c0a); /* line */ 
                ++i;
            }
        }

        // Trigger any remaining accumulated transfers via call to the conduit.
c_0xf9f9b178(0xb07dc117e8e17d33dc61185b700ead5469a0344fa10f419b591e5839934bd05a); /* line */ 
        c_0xf9f9b178(0x8e5f0f40afc46831c5a479c4859215b73c0ff24916225358c275b7d1064a9f5d); /* statement */ 
_triggerIfArmed(accumulator);

        // If any ether remains after fulfillments, return it to the caller.
c_0xf9f9b178(0x4118f13ec756cb13cb4bee72f185c51c15b6a48a46f6e465e9c9265082ac47d7); /* line */ 
        c_0xf9f9b178(0xaff162a2b0b0e2383e140193d01528c2d57f60871fa650118351556fe1eabb90); /* statement */ 
if (etherRemaining != 0) {c_0xf9f9b178(0x1b1a020fb2c97fbd40707b33c7eb3929e30e6dbbacae2c8439215e07cdb26bb1); /* branch */ 

c_0xf9f9b178(0x85858e1eba21b21ddc320888dc0f979663434637a014a61d15e50b396f11e261); /* line */ 
            c_0xf9f9b178(0x06bfe0d7048c6da4899219dba4ad14545078cbc3f64ef6b74455ad7d4174f99d); /* statement */ 
_transferEth(payable(msg.sender), etherRemaining);
        }else { c_0xf9f9b178(0xe0fc67139f4178989cd63e9a3d65c4f58f66b6b67d01c8c1fb8bf3169e3a99f9); /* branch */ 
}

        // Clear the reentrancy guard.
c_0xf9f9b178(0x11d09f02fa2bf426c13a1fee17e5dc700b444464cc377e69d34600393b8beb81); /* line */ 
        c_0xf9f9b178(0x79826083a3c7a6d17170735f3bd6cc729fab8de7d6482442547faface36e1146); /* statement */ 
_clearReentrancyGuard();

        // Return the array containing available orders.
c_0xf9f9b178(0xea3b6d80acb7363a38dbad0714e112bc29cccf55bb0a94e093054ab2cdc7cc51); /* line */ 
        c_0xf9f9b178(0x58ca65fa19e925740ad4fb7a25c6005d5eaa667440d024be0c634cd7f6691c09); /* statement */ 
return (availableOrders);
    }

    /**
     * @dev Internal function to match an arbitrary number of full or partial
     *      orders, each with an arbitrary number of items for offer and
     *      consideration, supplying criteria resolvers containing specific
     *      token identifiers and associated proofs as well as fulfillments
     *      allocating offer components to consideration components.
     *
     * @param advancedOrders    The advanced orders to match. Note that both the
     *                          offerer and fulfiller on each order must first
     *                          approve this contract (or their conduit if
     *                          indicated by the order) to transfer any relevant
     *                          tokens on their behalf and each consideration
     *                          recipient must implement `onERC1155Received` in
     *                          order to receive ERC1155 tokens. Also note that
     *                          the offer and consideration components for each
     *                          order must have no remainder after multiplying
     *                          the respective amount with the supplied fraction
     *                          in order for the group of partial fills to be
     *                          considered valid.
     * @param criteriaResolvers An array where each element contains a reference
     *                          to a specific order as well as that order's
     *                          offer or consideration, a token identifier, and
     *                          a proof that the supplied token identifier is
     *                          contained in the order's merkle root. Note that
     *                          an empty root indicates that any (transferable)
     *                          token identifier is valid and that no associated
     *                          proof needs to be supplied.
     * @param fulfillments      An array of elements allocating offer components
     *                          to consideration components. Note that each
     *                          consideration component must be fully met in
     *                          order for the match operation to be valid.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders.
     */
    function _matchAdvancedOrders(
        AdvancedOrder[] memory advancedOrders,
        CriteriaResolver[] memory criteriaResolvers,
        Fulfillment[] calldata fulfillments
    ) internal returns (Execution[] memory executions) {c_0xf9f9b178(0x9aebd3662cf4c1e2bc7767c2a9e18911e35fdc4c09f07b97475dffa75ce65cb9); /* function */ 

        // Validate orders, update order status, and determine item amounts.
c_0xf9f9b178(0xff157bff4c2abcb1ef921116f48aef89a3c905bbfc74a6aba802cca43f83f038); /* line */ 
        c_0xf9f9b178(0x7b657f194ec31fe277a405cd9204f4dbf2df9ba9fbfeab4a66c5a6a1dd6b7e92); /* statement */ 
_validateOrdersAndPrepareToFulfill(
            advancedOrders,
            criteriaResolvers,
            true, // Signifies that invalid orders should revert.
            advancedOrders.length,
            address(0) // OrderFulfilled event has no recipient when matching.
        );

        // Fulfill the orders using the supplied fulfillments.
c_0xf9f9b178(0x3f2b70eb0edbbd1c384d3a07c51887e3f1fdcf363c3b522cb138ab0534681f12); /* line */ 
        c_0xf9f9b178(0xdbd65efdd3acb79acc20e342fe140335fb7dd37592accaf56aea02823ca07a03); /* statement */ 
return _fulfillAdvancedOrders(advancedOrders, fulfillments);
    }

    /**
     * @dev Internal function to fulfill an arbitrary number of orders, either
     *      full or partial, after validating, adjusting amounts, and applying
     *      criteria resolvers.
     *
     * @param advancedOrders     The orders to match, including a fraction to
     *                           attempt to fill for each order.
     * @param fulfillments       An array of elements allocating offer
     *                           components to consideration components. Note
     *                           that the final amount of each consideration
     *                           component must be zero for a match operation to
     *                           be considered valid.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders.
     */
    function _fulfillAdvancedOrders(
        AdvancedOrder[] memory advancedOrders,
        Fulfillment[] calldata fulfillments
    ) internal returns (Execution[] memory executions) {c_0xf9f9b178(0x6b7a756a220ef726b5eed6e791979a16f5b5372710098ae4fea1c460cdb69366); /* function */ 

        // Retrieve fulfillments array length and place on the stack.
c_0xf9f9b178(0x6fa34f7b8cd9b325c77bbd77aaf01c4498d478dd03070409be5e877c5518eca7); /* line */ 
        c_0xf9f9b178(0xf33d84d920119771aa78ee1655d645a9c4b94f90fe4674ff053bc117ae61e53c); /* statement */ 
uint256 totalFulfillments = fulfillments.length;

        // Allocate executions by fulfillment and apply them to each execution.
c_0xf9f9b178(0xb13879ca8cea04783d60a0ef5097b0a74a48d566e0799c991b6e8f2815c6cde7); /* line */ 
        c_0xf9f9b178(0x1d2e48a40c85644845fb045a5fccb42dd6b54f70f543505aa84cbede73fe13bc); /* statement */ 
executions = new Execution[](totalFulfillments);

        // Skip overflow checks as all for loops are indexed starting at zero.
c_0xf9f9b178(0x7a48de933d2038cbc5523ff917303284e57ad3fb9f86dfb41ade3400b07a8454); /* line */ 
        unchecked {
            // Track number of filtered executions.
c_0xf9f9b178(0xf7acfd599dfd1809728e87e76a52d854a11389d4a2d6e01d6c4ceb2eedf31599); /* line */ 
            c_0xf9f9b178(0x9f6884bc097b3b404cbcfe28fd019c848c98bfbbc4f291fb5e9a2e17c94fef0c); /* statement */ 
uint256 totalFilteredExecutions = 0;

            // Iterate over each fulfillment.
c_0xf9f9b178(0x981b71177a6e26fa7f40081220741a97118fa60a080b5901522ec0ccaa172d8c); /* line */ 
            c_0xf9f9b178(0x34bdad5eebc95d0b6bd031e3044413ed0bf53ba335aaaa61a7a511472ff1f6e9); /* statement */ 
for (uint256 i = 0; i < totalFulfillments; ++i) {
                /// Retrieve the fulfillment in question.
c_0xf9f9b178(0xe35e0f8f63b1fbcf4e9bd19e63fb8a985cb1b1c3a191bade30db23b713cfbcf4); /* line */ 
                c_0xf9f9b178(0x73a2fcd94926a283536f798c5e4d8034f56448ce870208e0ca1c29f67f29f645); /* statement */ 
Fulfillment calldata fulfillment = fulfillments[i];

                // Derive the execution corresponding with the fulfillment.
c_0xf9f9b178(0x64bb6a81bc811279aa7c71b74d1934947b969720d3e135012e42d2c66f4b14fa); /* line */ 
                c_0xf9f9b178(0x9665a264a0f879e4bfe3a6a19235d5b9ac707d7ecbfb5198764a69ccade7337e); /* statement */ 
Execution memory execution = _applyFulfillment(
                    advancedOrders,
                    fulfillment.offerComponents,
                    fulfillment.considerationComponents
                );

                // If offerer and recipient on the execution are the same...
c_0xf9f9b178(0xf5ad6086bb6635f3e6d9ccdb018460c81a96e4a1a0e77e29f3a19a396075c4ab); /* line */ 
                c_0xf9f9b178(0x4584432ba93521ebb7e61029de5aee66f816c8bacfece7f4a6a79fe24f310b74); /* statement */ 
if (execution.item.recipient == execution.offerer) {c_0xf9f9b178(0x94bac9795fe4ffbc9d737027eb9116a5574af7d7c862013a04fcf6e80d0cdb12); /* branch */ 

                    // Increment total filtered executions.
c_0xf9f9b178(0x522df5f0b6f8b8d475ed1786829ddfa2bad75ecbbb620b3aef202253d0dafe04); /* line */ 
                    ++totalFilteredExecutions;
                } else {c_0xf9f9b178(0x1282dcae8c814d61a8d9715e56449a5c4f987180a0fa26d25e8068f61530ce8f); /* branch */ 

                    // Otherwise, assign the execution to the executions array.
c_0xf9f9b178(0xafe142e0178616e08464c6f2d8c5a66f5461d0fc036cf2dc7d0c45532414a8dc); /* line */ 
                    c_0xf9f9b178(0x7db1be9915358d17b12e48337119b64921c49cc7fc7e2863da9cefc3cf7a4ec9); /* statement */ 
executions[i - totalFilteredExecutions] = execution;
                }
            }

            // If some number of executions have been filtered...
c_0xf9f9b178(0x73d3179b8303a7aaae7b9e2dc158e9b17b2e1e65fe8b2aad3b63fcb18c07a133); /* line */ 
            c_0xf9f9b178(0xcc437277903215b1140748d67015eee01bd7f260009c718cea0ff7e1f1967cae); /* statement */ 
if (totalFilteredExecutions != 0) {c_0xf9f9b178(0x328f84e98e70874f7a115fb4650095243880effcf9700720825c551ee105dd58); /* branch */ 

                // reduce the total length of the executions array.
c_0xf9f9b178(0x33f823452110c8301a3397e0fefb2567fc7000ff5645f7c287fbe4bb55a0be57); /* line */ 
                assembly {
                    mstore(
                        executions,
                        sub(mload(executions), totalFilteredExecutions)
                    )
                }
            }else { c_0xf9f9b178(0xe36e568bec09e1bbeebf2ff0cd7c421c630db5ddae680d19848f3d5e371f5e95); /* branch */ 
}
        }

        // Perform final checks and execute orders.
c_0xf9f9b178(0x3beacef5fd215dfc6686d9510594f9279bf28f11ea15a28111070a310037dabd); /* line */ 
        c_0xf9f9b178(0x3a675feec8404e1ceb3843ba94d2a857f6277fc70c0b51d68202627cff920aeb); /* statement */ 
_performFinalChecksAndExecuteOrders(advancedOrders, executions);

        // Return the executions array.
c_0xf9f9b178(0xb742efc43ae6b349f63ffa4633d2ff27a8df56e23277b285e9e380740fb6dec1); /* line */ 
        c_0xf9f9b178(0x3595556f9a9cbb90c35849119f78597a9dde5bd2c3c14292322a61a86ec148e5); /* statement */ 
return (executions);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0x008a7fc9(bytes32 c__0x008a7fc9) pure {}


import {
    ConsiderationInterface
} from "../interfaces/ConsiderationInterface.sol";

import {
    OrderComponents,
    BasicOrderParameters,
    OrderParameters,
    Order,
    AdvancedOrder,
    OrderStatus,
    CriteriaResolver,
    Fulfillment,
    FulfillmentComponent,
    Execution
} from "./ConsiderationStructs.sol";

import { OrderCombiner } from "./OrderCombiner.sol";

/**
 * @title Consideration
 * @author 0age
 * @custom:coauthor d1ll0n
 * @custom:coauthor transmissions11
 * @custom:version 1.1
 * @notice Consideration is a generalized ETH/ERC20/ERC721/ERC1155 marketplace.
 *         It minimizes external calls to the greatest extent possible and
 *         provides lightweight methods for common routes as well as more
 *         flexible methods for composing advanced orders or groups of orders.
 *         Each order contains an arbitrary number of items that may be spent
 *         (the "offer") along with an arbitrary number of items that must be
 *         received back by the indicated recipients (the "consideration").
 */
contract Consideration is ConsiderationInterface, OrderCombiner {
function c_0x4156fe78(bytes32 c__0x4156fe78) internal pure {}

    /**
     * @notice Derive and set hashes, reference chainId, and associated domain
     *         separator during deployment.
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     */
    constructor(address conduitController) OrderCombiner(conduitController) {c_0x4156fe78(0x39024a967ace5ebb11bcca1c763da08cd39b6efe6e84dfb30955c84e5103bf98); /* function */ 
}

    /**
     * @notice Fulfill an order offering an ERC20, ERC721, or ERC1155 item by
     *         supplying Ether (or other native tokens), ERC20 tokens, an ERC721
     *         item, or an ERC1155 item as consideration. Six permutations are
     *         supported: Native token to ERC721, Native token to ERC1155, ERC20
     *         to ERC721, ERC20 to ERC1155, ERC721 to ERC20, and ERC1155 to
     *         ERC20 (with native tokens supplied as msg.value). For an order to
     *         be eligible for fulfillment via this method, it must contain a
     *         single offer item (though that item may have a greater amount if
     *         the item is not an ERC721). An arbitrary number of "additional
     *         recipients" may also be supplied which will each receive native
     *         tokens or ERC20 items from the fulfiller as consideration. Refer
     *         to the documentation for a more comprehensive summary of how to
     *         utilize this method and what orders are compatible with it.
     *
     * @param parameters Additional information on the fulfilled order. Note
     *                   that the offerer and the fulfiller must first approve
     *                   this contract (or their chosen conduit if indicated)
     *                   before any tokens can be transferred. Also note that
     *                   contract recipients of ERC1155 consideration items must
     *                   implement `onERC1155Received` in order to receive those
     *                   items.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillBasicOrder(BasicOrderParameters calldata parameters)
        external
        payable
        override
        returns (bool fulfilled)
    {c_0x4156fe78(0x822f141a9c032d7811449f1e2f3146929e1b8ef0cdad68c7ccaa52cc0ed5a096); /* function */ 

        // Validate and fulfill the basic order.
c_0x4156fe78(0x68794a52a74b434af3f17d33ee84294b82003e92573d4627cd3f251445c6558a); /* line */ 
        c_0x4156fe78(0x7514900767a75e2c016d58240e67904e509afcd978e1d242e9560a549a803bb3); /* statement */ 
fulfilled = _validateAndFulfillBasicOrder(parameters);
    }

    /**
     * @notice Fulfill an order with an arbitrary number of items for offer and
     *         consideration. Note that this function does not support
     *         criteria-based orders or partial filling of orders (though
     *         filling the remainder of a partially-filled order is supported).
     *
     * @param order               The order to fulfill. Note that both the
     *                            offerer and the fulfiller must first approve
     *                            this contract (or the corresponding conduit if
     *                            indicated) to transfer any relevant tokens on
     *                            their behalf and that contracts must implement
     *                            `onERC1155Received` to receive ERC1155 tokens
     *                            as consideration.
     * @param fulfillerConduitKey A bytes32 value indicating what conduit, if
     *                            any, to source the fulfiller's token approvals
     *                            from. The zero hash signifies that no conduit
     *                            should be used (and direct approvals set on
     *                            Consideration).
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillOrder(Order calldata order, bytes32 fulfillerConduitKey)
        external
        payable
        override
        returns (bool fulfilled)
    {c_0x4156fe78(0x53c08dbf839e0667ebeb8b791154a02c0e996efab1b80a2efd08ac856c600cca); /* function */ 

        // Convert order to "advanced" order, then validate and fulfill it.
c_0x4156fe78(0x9900536e5c8418bd2d9ddaec9a886cbfe0433fab87b0a6e5a89e32c7a5ec7b95); /* line */ 
        c_0x4156fe78(0x8044997c5c059bde29dc9b056cfdd0839454d4e408229d5c063ea397b9da76cb); /* statement */ 
fulfilled = _validateAndFulfillAdvancedOrder(
            _convertOrderToAdvanced(order),
            new CriteriaResolver[](0), // No criteria resolvers supplied.
            fulfillerConduitKey,
            msg.sender
        );
    }

    /**
     * @notice Fill an order, fully or partially, with an arbitrary number of
     *         items for offer and consideration alongside criteria resolvers
     *         containing specific token identifiers and associated proofs.
     *
     * @param advancedOrder       The order to fulfill along with the fraction
     *                            of the order to attempt to fill. Note that
     *                            both the offerer and the fulfiller must first
     *                            approve this contract (or their conduit if
     *                            indicated by the order) to transfer any
     *                            relevant tokens on their behalf and that
     *                            contracts must implement `onERC1155Received`
     *                            to receive ERC1155 tokens as consideration.
     *                            Also note that all offer and consideration
     *                            components must have no remainder after
     *                            multiplication of the respective amount with
     *                            the supplied fraction for the partial fill to
     *                            be considered valid.
     * @param criteriaResolvers   An array where each element contains a
     *                            reference to a specific offer or
     *                            consideration, a token identifier, and a proof
     *                            that the supplied token identifier is
     *                            contained in the merkle root held by the item
     *                            in question's criteria element. Note that an
     *                            empty criteria indicates that any
     *                            (transferable) token identifier on the token
     *                            in question is valid and that no associated
     *                            proof needs to be supplied.
     * @param fulfillerConduitKey A bytes32 value indicating what conduit, if
     *                            any, to source the fulfiller's token approvals
     *                            from. The zero hash signifies that no conduit
     *                            should be used (and direct approvals set on
     *                            Consideration).
     * @param recipient           The intended recipient for all received items,
     *                            with `address(0)` indicating that the caller
     *                            should receive the items.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillAdvancedOrder(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient
    ) external payable override returns (bool fulfilled) {c_0x4156fe78(0x2d0e265d55361fd01acc5cf9ba930c0f683b3d110dcc44f291dc3e2e13da0487); /* function */ 

        // Validate and fulfill the order.
c_0x4156fe78(0xf38bf8c8be07d08a047fa039b54e24897cf2cf427a7e64b5aba260945e4ec0d2); /* line */ 
        c_0x4156fe78(0x32120ca5c30e4b0b1f212a27a92d886fdf718594595c6d875a61719d09cddb43); /* statement */ 
fulfilled = _validateAndFulfillAdvancedOrder(
            advancedOrder,
            criteriaResolvers,
            fulfillerConduitKey,
            recipient == address(0) ? msg.sender : recipient
        );
    }

    /**
     * @notice Attempt to fill a group of orders, each with an arbitrary number
     *         of items for offer and consideration. Any order that is not
     *         currently active, has already been fully filled, or has been
     *         cancelled will be omitted. Remaining offer and consideration
     *         items will then be aggregated where possible as indicated by the
     *         supplied offer and consideration component arrays and aggregated
     *         items will be transferred to the fulfiller or to each intended
     *         recipient, respectively. Note that a failing item transfer or an
     *         issue with order formatting will cause the entire batch to fail.
     *         Note that this function does not support criteria-based orders or
     *         partial filling of orders (though filling the remainder of a
     *         partially-filled order is supported).
     *
     * @param orders                    The orders to fulfill. Note that both
     *                                  the offerer and the fulfiller must first
     *                                  approve this contract (or the
     *                                  corresponding conduit if indicated) to
     *                                  transfer any relevant tokens on their
     *                                  behalf and that contracts must implement
     *                                  `onERC1155Received` to receive ERC1155
     *                                  tokens as consideration.
     * @param offerFulfillments         An array of FulfillmentComponent arrays
     *                                  indicating which offer items to attempt
     *                                  to aggregate when preparing executions.
     * @param considerationFulfillments An array of FulfillmentComponent arrays
     *                                  indicating which consideration items to
     *                                  attempt to aggregate when preparing
     *                                  executions.
     * @param fulfillerConduitKey       A bytes32 value indicating what conduit,
     *                                  if any, to source the fulfiller's token
     *                                  approvals from. The zero hash signifies
     *                                  that no conduit should be used (and
     *                                  direct approvals set on Consideration).
     * @param maximumFulfilled          The maximum number of orders to fulfill.
     *
     * @return availableOrders An array of booleans indicating if each order
     *                         with an index corresponding to the index of the
     *                         returned boolean was fulfillable or not.
     * @return executions      An array of elements indicating the sequence of
     *                         transfers performed as part of matching the given
     *                         orders.
     */
    function fulfillAvailableOrders(
        Order[] calldata orders,
        FulfillmentComponent[][] calldata offerFulfillments,
        FulfillmentComponent[][] calldata considerationFulfillments,
        bytes32 fulfillerConduitKey,
        uint256 maximumFulfilled
    )
        external
        payable
        override
        returns (bool[] memory availableOrders, Execution[] memory executions)
    {c_0x4156fe78(0x76b62b68214abc3ab334777bb0962a9f9d9ccc87d0d56e1d434d1e30c1504888); /* function */ 

        // Convert orders to "advanced" orders and fulfill all available orders.
c_0x4156fe78(0x9608b08800ebbe19610ba2bbbd0054da3a7d62e0a3b555df51d7a77b96937059); /* line */ 
        c_0x4156fe78(0x025b04b542340f7a6e39f3df9fffbdedc990b7842db8ad33bf02b6a3acfa4e47); /* statement */ 
return
            _fulfillAvailableAdvancedOrders(
                _convertOrdersToAdvanced(orders), // Convert to advanced orders.
                new CriteriaResolver[](0), // No criteria resolvers supplied.
                offerFulfillments,
                considerationFulfillments,
                fulfillerConduitKey,
                msg.sender,
                maximumFulfilled
            );
    }

    /**
     * @notice Attempt to fill a group of orders, fully or partially, with an
     *         arbitrary number of items for offer and consideration per order
     *         alongside criteria resolvers containing specific token
     *         identifiers and associated proofs. Any order that is not
     *         currently active, has already been fully filled, or has been
     *         cancelled will be omitted. Remaining offer and consideration
     *         items will then be aggregated where possible as indicated by the
     *         supplied offer and consideration component arrays and aggregated
     *         items will be transferred to the fulfiller or to each intended
     *         recipient, respectively. Note that a failing item transfer or an
     *         issue with order formatting will cause the entire batch to fail.
     *
     * @param advancedOrders            The orders to fulfill along with the
     *                                  fraction of those orders to attempt to
     *                                  fill. Note that both the offerer and the
     *                                  fulfiller must first approve this
     *                                  contract (or their conduit if indicated
     *                                  by the order) to transfer any relevant
     *                                  tokens on their behalf and that
     *                                  contracts must implement
     *                                  `onERC1155Received` in order to receive
     *                                  ERC1155 tokens as consideration. Also
     *                                  note that all offer and consideration
     *                                  components must have no remainder after
     *                                  multiplication of the respective amount
     *                                  with the supplied fraction for an
     *                                  order's partial fill amount to be
     *                                  considered valid.
     * @param criteriaResolvers         An array where each element contains a
     *                                  reference to a specific offer or
     *                                  consideration, a token identifier, and a
     *                                  proof that the supplied token identifier
     *                                  is contained in the merkle root held by
     *                                  the item in question's criteria element.
     *                                  Note that an empty criteria indicates
     *                                  that any (transferable) token
     *                                  identifier on the token in question is
     *                                  valid and that no associated proof needs
     *                                  to be supplied.
     * @param offerFulfillments         An array of FulfillmentComponent arrays
     *                                  indicating which offer items to attempt
     *                                  to aggregate when preparing executions.
     * @param considerationFulfillments An array of FulfillmentComponent arrays
     *                                  indicating which consideration items to
     *                                  attempt to aggregate when preparing
     *                                  executions.
     * @param fulfillerConduitKey       A bytes32 value indicating what conduit,
     *                                  if any, to source the fulfiller's token
     *                                  approvals from. The zero hash signifies
     *                                  that no conduit should be used (and
     *                                  direct approvals set on Consideration).
     * @param recipient                 The intended recipient for all received
     *                                  items, with `address(0)` indicating that
     *                                  the caller should receive the items.
     * @param maximumFulfilled          The maximum number of orders to fulfill.
     *
     * @return availableOrders An array of booleans indicating if each order
     *                         with an index corresponding to the index of the
     *                         returned boolean was fulfillable or not.
     * @return executions      An array of elements indicating the sequence of
     *                         transfers performed as part of matching the given
     *                         orders.
     */
    function fulfillAvailableAdvancedOrders(
        AdvancedOrder[] memory advancedOrders,
        CriteriaResolver[] calldata criteriaResolvers,
        FulfillmentComponent[][] calldata offerFulfillments,
        FulfillmentComponent[][] calldata considerationFulfillments,
        bytes32 fulfillerConduitKey,
        address recipient,
        uint256 maximumFulfilled
    )
        external
        payable
        override
        returns (bool[] memory availableOrders, Execution[] memory executions)
    {c_0x4156fe78(0x3da90b3dfac610c64d860369b1b141831fbcec7f511f1fafa00f89dd62ad04f1); /* function */ 

        // Fulfill all available orders.
c_0x4156fe78(0x5f75d7c80277ba54ee1f1f82483b7fc75aa9a34df934d439e2b3fb07f9e6e0cf); /* line */ 
        c_0x4156fe78(0xa572df971c7916a14abacc7c90e8a4fc035eb8a9450cd966d108fab68efaac87); /* statement */ 
return
            _fulfillAvailableAdvancedOrders(
                advancedOrders,
                criteriaResolvers,
                offerFulfillments,
                considerationFulfillments,
                fulfillerConduitKey,
                recipient == address(0) ? msg.sender : recipient,
                maximumFulfilled
            );
    }

    /**
     * @notice Match an arbitrary number of orders, each with an arbitrary
     *         number of items for offer and consideration along with a set of
     *         fulfillments allocating offer components to consideration
     *         components. Note that this function does not support
     *         criteria-based or partial filling of orders (though filling the
     *         remainder of a partially-filled order is supported).
     *
     * @param orders            The orders to match. Note that both the offerer
     *                          and fulfiller on each order must first approve
     *                          this contract (or their conduit if indicated by
     *                          the order) to transfer any relevant tokens on
     *                          their behalf and each consideration recipient
     *                          must implement `onERC1155Received` in order to
     *                          receive ERC1155 tokens.
     * @param fulfillments      An array of elements allocating offer components
     *                          to consideration components. Note that each
     *                          consideration component must be fully met in
     *                          order for the match operation to be valid.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders.
     */
    function matchOrders(
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments
    ) external payable override returns (Execution[] memory executions) {c_0x4156fe78(0xe9d5dcde23abd2cce67419c478fbdc7609f1a61aacb0203d6ab130547f1f1e67); /* function */ 

        // Convert to advanced, validate, and match orders using fulfillments.
c_0x4156fe78(0x7f61f44b0fe59653ddca4468987acf1574dd4ec420b479ce59659297dfe9e1de); /* line */ 
        c_0x4156fe78(0x9881fcda0f59785f70e144e52f6cd88727d565bf04689ceeb67102663038c856); /* statement */ 
return
            _matchAdvancedOrders(
                _convertOrdersToAdvanced(orders),
                new CriteriaResolver[](0), // No criteria resolvers supplied.
                fulfillments
            );
    }

    /**
     * @notice Match an arbitrary number of full or partial orders, each with an
     *         arbitrary number of items for offer and consideration, supplying
     *         criteria resolvers containing specific token identifiers and
     *         associated proofs as well as fulfillments allocating offer
     *         components to consideration components.
     *
     * @param advancedOrders    The advanced orders to match. Note that both the
     *                          offerer and fulfiller on each order must first
     *                          approve this contract (or their conduit if
     *                          indicated by the order) to transfer any relevant
     *                          tokens on their behalf and each consideration
     *                          recipient must implement `onERC1155Received` in
     *                          order to receive ERC1155 tokens. Also note that
     *                          the offer and consideration components for each
     *                          order must have no remainder after multiplying
     *                          the respective amount with the supplied fraction
     *                          in order for the group of partial fills to be
     *                          considered valid.
     * @param criteriaResolvers An array where each element contains a reference
     *                          to a specific order as well as that order's
     *                          offer or consideration, a token identifier, and
     *                          a proof that the supplied token identifier is
     *                          contained in the order's merkle root. Note that
     *                          an empty root indicates that any (transferable)
     *                          token identifier is valid and that no associated
     *                          proof needs to be supplied.
     * @param fulfillments      An array of elements allocating offer components
     *                          to consideration components. Note that each
     *                          consideration component must be fully met in
     *                          order for the match operation to be valid.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders.
     */
    function matchAdvancedOrders(
        AdvancedOrder[] memory advancedOrders,
        CriteriaResolver[] calldata criteriaResolvers,
        Fulfillment[] calldata fulfillments
    ) external payable override returns (Execution[] memory executions) {c_0x4156fe78(0x43ef4d692923d3f814d16e49231f0f834043e83fedaecc7ca4d0ed8f4d8a32f4); /* function */ 

        // Validate and match the advanced orders using supplied fulfillments.
c_0x4156fe78(0x0668c6fe23f30d4fcb0b1b8a5c0e40e74d72464376fc6180de85711493740d79); /* line */ 
        c_0x4156fe78(0x64bb6336f63ac6b9a7a4270291ccb1d84575733a11ba9f096a37ab0397b26634); /* statement */ 
return
            _matchAdvancedOrders(
                advancedOrders,
                criteriaResolvers,
                fulfillments
            );
    }

    /**
     * @notice Cancel an arbitrary number of orders. Note that only the offerer
     *         or the zone of a given order may cancel it. Callers should ensure
     *         that the intended order was cancelled by calling `getOrderStatus`
     *         and confirming that `isCancelled` returns `true`.
     *
     * @param orders The orders to cancel.
     *
     * @return cancelled A boolean indicating whether the supplied orders have
     *                   been successfully cancelled.
     */
    function cancel(OrderComponents[] calldata orders)
        external
        override
        returns (bool cancelled)
    {c_0x4156fe78(0x7fa1afacbc2bcb10b2a8a612a3c847860b6603ddd544bab0238a9ed52575f05c); /* function */ 

        // Cancel the orders.
c_0x4156fe78(0xcbf568990dcb1bcba04857d028166570f756edd3c744378746f81e0257528ed6); /* line */ 
        c_0x4156fe78(0x4a8499f89c4ecd90bda762118b5e1af91f1ff2f029908bca2803cf0c181dee64); /* statement */ 
cancelled = _cancel(orders);
    }

    /**
     * @notice Validate an arbitrary number of orders, thereby registering their
     *         signatures as valid and allowing the fulfiller to skip signature
     *         verification on fulfillment. Note that validated orders may still
     *         be unfulfillable due to invalid item amounts or other factors;
     *         callers should determine whether validated orders are fulfillable
     *         by simulating the fulfillment call prior to execution. Also note
     *         that anyone can validate a signed order, but only the offerer can
     *         validate an order without supplying a signature.
     *
     * @param orders The orders to validate.
     *
     * @return validated A boolean indicating whether the supplied orders have
     *                   been successfully validated.
     */
    function validate(Order[] calldata orders)
        external
        override
        returns (bool validated)
    {c_0x4156fe78(0xeed5fdd9acd3e500bb8a4558e8922aebfdcd1dbb482f60df51bcadacf8c69b8d); /* function */ 

        // Validate the orders.
c_0x4156fe78(0x8cefe5f8616a7b2a91c1e1299cfd8cc243ff47749e463b34e6fc0749182d2218); /* line */ 
        c_0x4156fe78(0x637a10d07abc40ee12fedba7521ada8f0dffbe10444f6b148cb014e7d91cece7); /* statement */ 
validated = _validate(orders);
    }

    /**
     * @notice Cancel all orders from a given offerer with a given zone in bulk
     *         by incrementing a counter. Note that only the offerer may
     *         increment the counter.
     *
     * @return newCounter The new counter.
     */
    function incrementCounter() external override returns (uint256 newCounter) {c_0x4156fe78(0x120aa6c921626da4afd5bbcdc5372d615529549c8fa6e28d760d1a702218d369); /* function */ 

        // Increment current counter for the supplied offerer.
c_0x4156fe78(0x2535e6fcf4920fbd7a2b7c5565d30ee7c3fa0007e6156865fa6a0024d5bb3181); /* line */ 
        c_0x4156fe78(0x3f40ec207eda388a08fbece99159b20d9e277c4f69a19a1e370fbd47dbbfe8bc); /* statement */ 
newCounter = _incrementCounter();
    }

    /**
     * @notice Retrieve the order hash for a given order.
     *
     * @param order The components of the order.
     *
     * @return orderHash The order hash.
     */
    function getOrderHash(OrderComponents calldata order)
        external
        view
        override
        returns (bytes32 orderHash)
    {c_0x4156fe78(0x742a5a133af3b8d1a850df0b74d7b62840b1cb09bc8ac39739c7898108b20177); /* function */ 

        // Derive order hash by supplying order parameters along with counter.
c_0x4156fe78(0x4258f7198ebecf355eb87d33fec6b172fb082c56bf5a240f7f314a62c4d2d785); /* line */ 
        c_0x4156fe78(0xb6b68afd1428151d681e1765b779ccd58716180f109ba4c85c2806171d4ab5b8); /* statement */ 
orderHash = _deriveOrderHash(
            OrderParameters(
                order.offerer,
                order.zone,
                order.offer,
                order.consideration,
                order.orderType,
                order.startTime,
                order.endTime,
                order.zoneHash,
                order.salt,
                order.conduitKey,
                order.consideration.length
            ),
            order.counter
        );
    }

    /**
     * @notice Retrieve the status of a given order by hash, including whether
     *         the order has been cancelled or validated and the fraction of the
     *         order that has been filled.
     *
     * @param orderHash The order hash in question.
     *
     * @return isValidated A boolean indicating whether the order in question
     *                     has been validated (i.e. previously approved or
     *                     partially filled).
     * @return isCancelled A boolean indicating whether the order in question
     *                     has been cancelled.
     * @return totalFilled The total portion of the order that has been filled
     *                     (i.e. the "numerator").
     * @return totalSize   The total size of the order that is either filled or
     *                     unfilled (i.e. the "denominator").
     */
    function getOrderStatus(bytes32 orderHash)
        external
        view
        override
        returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        )
    {c_0x4156fe78(0xf25a992d3ce96f45dcee10fa4700c2011978e283d76bdbbc81ff3b2f0e8cb59f); /* function */ 

        // Retrieve the order status using the order hash.
c_0x4156fe78(0x9630eefc9ba7651a6a3b1b04edf50ea5d1a165cc4f523bd83b13e05f95f4277f); /* line */ 
        c_0x4156fe78(0x0581911bb1ffa178806fc80c0fc0cb24a942c6866a1c91b8364fe288214d839d); /* statement */ 
return _getOrderStatus(orderHash);
    }

    /**
     * @notice Retrieve the current counter for a given offerer.
     *
     * @param offerer The offerer in question.
     *
     * @return counter The current counter.
     */
    function getCounter(address offerer)
        external
        view
        override
        returns (uint256 counter)
    {c_0x4156fe78(0xb7de6e61508b2b4d20c0b8cb094b89da6a85ada5c1f551dc1dbbf7102a23e934); /* function */ 

        // Return the counter for the supplied offerer.
c_0x4156fe78(0xb39b754aae47dc3c4b05ff9d7083e78e7ca0a15d357b26c3c76d2bc89376a513); /* line */ 
        c_0x4156fe78(0xb83c6fa41b4e156d1c933bd62da80446d0ded630f85a6e2d8912b8699d1890ef); /* statement */ 
counter = _getCounter(offerer);
    }

    /**
     * @notice Retrieve configuration information for this contract.
     *
     * @return version           The contract version.
     * @return domainSeparator   The domain separator for this contract.
     * @return conduitController The conduit Controller set for this contract.
     */
    function information()
        external
        view
        override
        returns (
            string memory version,
            bytes32 domainSeparator,
            address conduitController
        )
    {c_0x4156fe78(0x3245b7679efb0b0adff3a82d4e052745dce8ffd54ada7489261f175c926035d6); /* function */ 

        // Return the information for this contract.
c_0x4156fe78(0x35b6cc8d0c4247579ed712d5e695a5355d06b51db8b91651208d2c0542a8e3bb); /* line */ 
        c_0x4156fe78(0xc843a8edcb2628c4f94a6ba56dd6b9ea76468c2fdc1c9e87d8ad92223b9da2bd); /* statement */ 
return _information();
    }

    /**
     * @notice Retrieve the name of this contract.
     *
     * @return contractName The name of this contract.
     */
    function name()
        external
        pure
        override
        returns (string memory contractName)
    {c_0x4156fe78(0xf28d8cda594035d4b8a49d88eca1cc9077256eff4511a2c249ebea6d64283108); /* function */ 

        // Return the name of the contract.
c_0x4156fe78(0xfdc038b68b510093d41fc9df5a543dba6f27fe99b2829b1173b28cd7c4869053); /* line */ 
        c_0x4156fe78(0x19c760279e38d0f7d07fbc01ea2c0ca2e46adef57421433c72403b6efed095ca); /* statement */ 
contractName = _name();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {
    BasicOrderParameters,
    OrderComponents,
    Fulfillment,
    FulfillmentComponent,
    Execution,
    Order,
    AdvancedOrder,
    OrderStatus,
    CriteriaResolver
} from "../lib/ConsiderationStructs.sol";

/**
 * @title ConsiderationInterface
 * @author 0age
 * @custom:version 1.1
 * @notice Consideration is a generalized ETH/ERC20/ERC721/ERC1155 marketplace.
 *         It minimizes external calls to the greatest extent possible and
 *         provides lightweight methods for common routes as well as more
 *         flexible methods for composing advanced orders.
 *
 * @dev ConsiderationInterface contains all external function interfaces for
 *      Consideration.
 */
interface ConsiderationInterface {
    /**
     * @notice Fulfill an order offering an ERC721 token by supplying Ether (or
     *         the native token for the given chain) as consideration for the
     *         order. An arbitrary number of "additional recipients" may also be
     *         supplied which will each receive native tokens from the fulfiller
     *         as consideration.
     *
     * @param parameters Additional information on the fulfilled order. Note
     *                   that the offerer must first approve this contract (or
     *                   their preferred conduit if indicated by the order) for
     *                   their offered ERC721 token to be transferred.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillBasicOrder(BasicOrderParameters calldata parameters)
        external
        payable
        returns (bool fulfilled);

    /**
     * @notice Fulfill an order with an arbitrary number of items for offer and
     *         consideration. Note that this function does not support
     *         criteria-based orders or partial filling of orders (though
     *         filling the remainder of a partially-filled order is supported).
     *
     * @param order               The order to fulfill. Note that both the
     *                            offerer and the fulfiller must first approve
     *                            this contract (or the corresponding conduit if
     *                            indicated) to transfer any relevant tokens on
     *                            their behalf and that contracts must implement
     *                            `onERC1155Received` to receive ERC1155 tokens
     *                            as consideration.
     * @param fulfillerConduitKey A bytes32 value indicating what conduit, if
     *                            any, to source the fulfiller's token approvals
     *                            from. The zero hash signifies that no conduit
     *                            should be used, with direct approvals set on
     *                            Consideration.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillOrder(Order calldata order, bytes32 fulfillerConduitKey)
        external
        payable
        returns (bool fulfilled);

    /**
     * @notice Fill an order, fully or partially, with an arbitrary number of
     *         items for offer and consideration alongside criteria resolvers
     *         containing specific token identifiers and associated proofs.
     *
     * @param advancedOrder       The order to fulfill along with the fraction
     *                            of the order to attempt to fill. Note that
     *                            both the offerer and the fulfiller must first
     *                            approve this contract (or their preferred
     *                            conduit if indicated by the order) to transfer
     *                            any relevant tokens on their behalf and that
     *                            contracts must implement `onERC1155Received`
     *                            to receive ERC1155 tokens as consideration.
     *                            Also note that all offer and consideration
     *                            components must have no remainder after
     *                            multiplication of the respective amount with
     *                            the supplied fraction for the partial fill to
     *                            be considered valid.
     * @param criteriaResolvers   An array where each element contains a
     *                            reference to a specific offer or
     *                            consideration, a token identifier, and a proof
     *                            that the supplied token identifier is
     *                            contained in the merkle root held by the item
     *                            in question's criteria element. Note that an
     *                            empty criteria indicates that any
     *                            (transferable) token identifier on the token
     *                            in question is valid and that no associated
     *                            proof needs to be supplied.
     * @param fulfillerConduitKey A bytes32 value indicating what conduit, if
     *                            any, to source the fulfiller's token approvals
     *                            from. The zero hash signifies that no conduit
     *                            should be used, with direct approvals set on
     *                            Consideration.
     * @param recipient           The intended recipient for all received items,
     *                            with `address(0)` indicating that the caller
     *                            should receive the items.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillAdvancedOrder(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient
    ) external payable returns (bool fulfilled);

    /**
     * @notice Attempt to fill a group of orders, each with an arbitrary number
     *         of items for offer and consideration. Any order that is not
     *         currently active, has already been fully filled, or has been
     *         cancelled will be omitted. Remaining offer and consideration
     *         items will then be aggregated where possible as indicated by the
     *         supplied offer and consideration component arrays and aggregated
     *         items will be transferred to the fulfiller or to each intended
     *         recipient, respectively. Note that a failing item transfer or an
     *         issue with order formatting will cause the entire batch to fail.
     *         Note that this function does not support criteria-based orders or
     *         partial filling of orders (though filling the remainder of a
     *         partially-filled order is supported).
     *
     * @param orders                    The orders to fulfill. Note that both
     *                                  the offerer and the fulfiller must first
     *                                  approve this contract (or the
     *                                  corresponding conduit if indicated) to
     *                                  transfer any relevant tokens on their
     *                                  behalf and that contracts must implement
     *                                  `onERC1155Received` to receive ERC1155
     *                                  tokens as consideration.
     * @param offerFulfillments         An array of FulfillmentComponent arrays
     *                                  indicating which offer items to attempt
     *                                  to aggregate when preparing executions.
     * @param considerationFulfillments An array of FulfillmentComponent arrays
     *                                  indicating which consideration items to
     *                                  attempt to aggregate when preparing
     *                                  executions.
     * @param fulfillerConduitKey       A bytes32 value indicating what conduit,
     *                                  if any, to source the fulfiller's token
     *                                  approvals from. The zero hash signifies
     *                                  that no conduit should be used, with
     *                                  direct approvals set on this contract.
     * @param maximumFulfilled          The maximum number of orders to fulfill.
     *
     * @return availableOrders An array of booleans indicating if each order
     *                         with an index corresponding to the index of the
     *                         returned boolean was fulfillable or not.
     * @return executions      An array of elements indicating the sequence of
     *                         transfers performed as part of matching the given
     *                         orders.
     */
    function fulfillAvailableOrders(
        Order[] calldata orders,
        FulfillmentComponent[][] calldata offerFulfillments,
        FulfillmentComponent[][] calldata considerationFulfillments,
        bytes32 fulfillerConduitKey,
        uint256 maximumFulfilled
    )
        external
        payable
        returns (bool[] memory availableOrders, Execution[] memory executions);

    /**
     * @notice Attempt to fill a group of orders, fully or partially, with an
     *         arbitrary number of items for offer and consideration per order
     *         alongside criteria resolvers containing specific token
     *         identifiers and associated proofs. Any order that is not
     *         currently active, has already been fully filled, or has been
     *         cancelled will be omitted. Remaining offer and consideration
     *         items will then be aggregated where possible as indicated by the
     *         supplied offer and consideration component arrays and aggregated
     *         items will be transferred to the fulfiller or to each intended
     *         recipient, respectively. Note that a failing item transfer or an
     *         issue with order formatting will cause the entire batch to fail.
     *
     * @param advancedOrders            The orders to fulfill along with the
     *                                  fraction of those orders to attempt to
     *                                  fill. Note that both the offerer and the
     *                                  fulfiller must first approve this
     *                                  contract (or their preferred conduit if
     *                                  indicated by the order) to transfer any
     *                                  relevant tokens on their behalf and that
     *                                  contracts must implement
     *                                  `onERC1155Received` to enable receipt of
     *                                  ERC1155 tokens as consideration. Also
     *                                  note that all offer and consideration
     *                                  components must have no remainder after
     *                                  multiplication of the respective amount
     *                                  with the supplied fraction for an
     *                                  order's partial fill amount to be
     *                                  considered valid.
     * @param criteriaResolvers         An array where each element contains a
     *                                  reference to a specific offer or
     *                                  consideration, a token identifier, and a
     *                                  proof that the supplied token identifier
     *                                  is contained in the merkle root held by
     *                                  the item in question's criteria element.
     *                                  Note that an empty criteria indicates
     *                                  that any (transferable) token
     *                                  identifier on the token in question is
     *                                  valid and that no associated proof needs
     *                                  to be supplied.
     * @param offerFulfillments         An array of FulfillmentComponent arrays
     *                                  indicating which offer items to attempt
     *                                  to aggregate when preparing executions.
     * @param considerationFulfillments An array of FulfillmentComponent arrays
     *                                  indicating which consideration items to
     *                                  attempt to aggregate when preparing
     *                                  executions.
     * @param fulfillerConduitKey       A bytes32 value indicating what conduit,
     *                                  if any, to source the fulfiller's token
     *                                  approvals from. The zero hash signifies
     *                                  that no conduit should be used, with
     *                                  direct approvals set on this contract.
     * @param recipient                 The intended recipient for all received
     *                                  items, with `address(0)` indicating that
     *                                  the caller should receive the items.
     * @param maximumFulfilled          The maximum number of orders to fulfill.
     *
     * @return availableOrders An array of booleans indicating if each order
     *                         with an index corresponding to the index of the
     *                         returned boolean was fulfillable or not.
     * @return executions      An array of elements indicating the sequence of
     *                         transfers performed as part of matching the given
     *                         orders.
     */
    function fulfillAvailableAdvancedOrders(
        AdvancedOrder[] calldata advancedOrders,
        CriteriaResolver[] calldata criteriaResolvers,
        FulfillmentComponent[][] calldata offerFulfillments,
        FulfillmentComponent[][] calldata considerationFulfillments,
        bytes32 fulfillerConduitKey,
        address recipient,
        uint256 maximumFulfilled
    )
        external
        payable
        returns (bool[] memory availableOrders, Execution[] memory executions);

    /**
     * @notice Match an arbitrary number of orders, each with an arbitrary
     *         number of items for offer and consideration along with as set of
     *         fulfillments allocating offer components to consideration
     *         components. Note that this function does not support
     *         criteria-based or partial filling of orders (though filling the
     *         remainder of a partially-filled order is supported).
     *
     * @param orders       The orders to match. Note that both the offerer and
     *                     fulfiller on each order must first approve this
     *                     contract (or their conduit if indicated by the order)
     *                     to transfer any relevant tokens on their behalf and
     *                     each consideration recipient must implement
     *                     `onERC1155Received` to enable ERC1155 token receipt.
     * @param fulfillments An array of elements allocating offer components to
     *                     consideration components. Note that each
     *                     consideration component must be fully met for the
     *                     match operation to be valid.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders.
     */
    function matchOrders(
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments
    ) external payable returns (Execution[] memory executions);

    /**
     * @notice Match an arbitrary number of full or partial orders, each with an
     *         arbitrary number of items for offer and consideration, supplying
     *         criteria resolvers containing specific token identifiers and
     *         associated proofs as well as fulfillments allocating offer
     *         components to consideration components.
     *
     * @param orders            The advanced orders to match. Note that both the
     *                          offerer and fulfiller on each order must first
     *                          approve this contract (or a preferred conduit if
     *                          indicated by the order) to transfer any relevant
     *                          tokens on their behalf and each consideration
     *                          recipient must implement `onERC1155Received` in
     *                          order to receive ERC1155 tokens. Also note that
     *                          the offer and consideration components for each
     *                          order must have no remainder after multiplying
     *                          the respective amount with the supplied fraction
     *                          in order for the group of partial fills to be
     *                          considered valid.
     * @param criteriaResolvers An array where each element contains a reference
     *                          to a specific order as well as that order's
     *                          offer or consideration, a token identifier, and
     *                          a proof that the supplied token identifier is
     *                          contained in the order's merkle root. Note that
     *                          an empty root indicates that any (transferable)
     *                          token identifier is valid and that no associated
     *                          proof needs to be supplied.
     * @param fulfillments      An array of elements allocating offer components
     *                          to consideration components. Note that each
     *                          consideration component must be fully met in
     *                          order for the match operation to be valid.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders.
     */
    function matchAdvancedOrders(
        AdvancedOrder[] calldata orders,
        CriteriaResolver[] calldata criteriaResolvers,
        Fulfillment[] calldata fulfillments
    ) external payable returns (Execution[] memory executions);

    /**
     * @notice Cancel an arbitrary number of orders. Note that only the offerer
     *         or the zone of a given order may cancel it. Callers should ensure
     *         that the intended order was cancelled by calling `getOrderStatus`
     *         and confirming that `isCancelled` returns `true`.
     *
     * @param orders The orders to cancel.
     *
     * @return cancelled A boolean indicating whether the supplied orders have
     *                   been successfully cancelled.
     */
    function cancel(OrderComponents[] calldata orders)
        external
        returns (bool cancelled);

    /**
     * @notice Validate an arbitrary number of orders, thereby registering their
     *         signatures as valid and allowing the fulfiller to skip signature
     *         verification on fulfillment. Note that validated orders may still
     *         be unfulfillable due to invalid item amounts or other factors;
     *         callers should determine whether validated orders are fulfillable
     *         by simulating the fulfillment call prior to execution. Also note
     *         that anyone can validate a signed order, but only the offerer can
     *         validate an order without supplying a signature.
     *
     * @param orders The orders to validate.
     *
     * @return validated A boolean indicating whether the supplied orders have
     *                   been successfully validated.
     */
    function validate(Order[] calldata orders)
        external
        returns (bool validated);

    /**
     * @notice Cancel all orders from a given offerer with a given zone in bulk
     *         by incrementing a counter. Note that only the offerer may
     *         increment the counter.
     *
     * @return newCounter The new counter.
     */
    function incrementCounter() external returns (uint256 newCounter);

    /**
     * @notice Retrieve the order hash for a given order.
     *
     * @param order The components of the order.
     *
     * @return orderHash The order hash.
     */
    function getOrderHash(OrderComponents calldata order)
        external
        view
        returns (bytes32 orderHash);

    /**
     * @notice Retrieve the status of a given order by hash, including whether
     *         the order has been cancelled or validated and the fraction of the
     *         order that has been filled.
     *
     * @param orderHash The order hash in question.
     *
     * @return isValidated A boolean indicating whether the order in question
     *                     has been validated (i.e. previously approved or
     *                     partially filled).
     * @return isCancelled A boolean indicating whether the order in question
     *                     has been cancelled.
     * @return totalFilled The total portion of the order that has been filled
     *                     (i.e. the "numerator").
     * @return totalSize   The total size of the order that is either filled or
     *                     unfilled (i.e. the "denominator").
     */
    function getOrderStatus(bytes32 orderHash)
        external
        view
        returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        );

    /**
     * @notice Retrieve the current counter for a given offerer.
     *
     * @param offerer The offerer in question.
     *
     * @return counter The current counter.
     */
    function getCounter(address offerer)
        external
        view
        returns (uint256 counter);

    /**
     * @notice Retrieve configuration information for this contract.
     *
     * @return version           The contract version.
     * @return domainSeparator   The domain separator for this contract.
     * @return conduitController The conduit Controller set for this contract.
     */
    function information()
        external
        view
        returns (
            string memory version,
            bytes32 domainSeparator,
            address conduitController
        );

    /**
     * @notice Retrieve the name of this contract.
     *
     * @return contractName The name of this contract.
     */
    function name() external view returns (string memory contractName);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0x462d2faa(bytes32 c__0x462d2faa) pure {}


import { Consideration } from "./lib/Consideration.sol";

/**
 * @title Seaport
 * @custom:version 1.1
 * @author 0age (0age.eth)
 * @custom:coauthor d1ll0n (d1ll0n.eth)
 * @custom:coauthor transmissions11 (t11s.eth)
 * @custom:contributor Kartik (slokh.eth)
 * @custom:contributor LeFevre (lefevre.eth)
 * @custom:contributor Joseph Schiarizzi (CupOJoseph.eth)
 * @custom:contributor Aspyn Palatnick (stuckinaboot.eth)
 * @custom:contributor James Wenzel (emo.eth)
 * @custom:contributor Stephan Min (stephanm.eth)
 * @custom:contributor Ryan Ghods (ralxz.eth)
 * @custom:contributor hack3r-0m (hack3r-0m.eth)
 * @custom:contributor Diego Estevez (antidiego.eth)
 * @custom:contributor Chomtana (chomtana.eth)
 * @custom:contributor Saw-mon and Natalie (sawmonandnatalie.eth)
 * @custom:contributor 0xBeans (0xBeans.eth)
 * @custom:contributor 0x4non (punkdev.eth)
 * @custom:contributor Laurence E. Day (norsefire.eth)
 * @custom:contributor vectorized.eth (vectorized.eth)
 * @custom:contributor karmacoma (karmacoma.eth)
 * @custom:contributor horsefacts (horsefacts.eth)
 * @custom:contributor UncarvedBlock (uncarvedblock.eth)
 * @custom:contributor Zoraiz Mahmood (zorz.eth)
 * @custom:contributor William Poulin (wpoulin.eth)
 * @custom:contributor Rajiv Patel-O'Connor (rajivpoc.eth)
 * @custom:contributor tserg (tserg.eth)
 * @custom:contributor cygaar (cygaar.eth)
 * @custom:contributor Meta0xNull (meta0xnull.eth)
 * @custom:contributor gpersoon (gpersoon.eth)
 * @custom:contributor Matt Solomon (msolomon.eth)
 * @custom:contributor Weikang Song (weikangs.eth)
 * @custom:contributor zer0dot (zer0dot.eth)
 * @custom:contributor Mudit Gupta (mudit.eth)
 * @custom:contributor leonardoalt (leoalt.eth)
 * @custom:contributor cmichel (cmichel.eth)
 * @custom:contributor PraneshASP (pranesh.eth)
 * @custom:contributor JasperAlexander (jasperalexander.eth)
 * @custom:contributor Ellahi (ellahi.eth)
 * @custom:contributor zaz (1zaz1.eth)
 * @custom:contributor berndartmueller (berndartmueller.eth)
 * @custom:contributor dmfxyz (dmfxyz.eth)
 * @custom:contributor daltoncoder (dontkillrobots.eth)
 * @custom:contributor 0xf4ce (0xf4ce.eth)
 * @custom:contributor phaze (phaze.eth)
 * @custom:contributor hrkrshnn (hrkrshnn.eth)
 * @custom:contributor axic (axic.eth)
 * @custom:contributor leastwood (leastwood.eth)
 * @custom:contributor 0xsanson (sanson.eth)
 * @custom:contributor blockdev (blockd3v.eth)
 * @custom:contributor fiveoutofnine (fiveoutofnine.eth)
 * @custom:contributor shuklaayush (shuklaayush.eth)
 * @custom:contributor 0xPatissier
 * @custom:contributor pcaversaccio
 * @custom:contributor David Eiber
 * @custom:contributor csanuragjain
 * @custom:contributor sach1r0
 * @custom:contributor twojoy0
 * @custom:contributor ori_dabush
 * @custom:contributor Daniel Gelfand
 * @custom:contributor okkothejawa
 * @custom:contributor FlameHorizon
 * @custom:contributor vdrg
 * @custom:contributor dmitriia
 * @custom:contributor bokeh-eth
 * @custom:contributor asutorufos
 * @custom:contributor rfart(rfa)
 * @custom:contributor Riley Holterhus
 * @custom:contributor big-tech-sux
 * @notice Seaport is a generalized ETH/ERC20/ERC721/ERC1155 marketplace. It
 *         minimizes external calls to the greatest extent possible and provides
 *         lightweight methods for common routes as well as more flexible
 *         methods for composing advanced orders or groups of orders. Each order
 *         contains an arbitrary number of items that may be spent (the "offer")
 *         along with an arbitrary number of items that must be received back by
 *         the indicated recipients (the "consideration").
 */
contract Seaport is Consideration {
function c_0x0039749f(bytes32 c__0x0039749f) internal pure {}

    /**
     * @notice Derive and set hashes, reference chainId, and associated domain
     *         separator during deployment.
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     */
    constructor(address conduitController) Consideration(conduitController) {c_0x0039749f(0xe8d57c968dc5837c03b53f1237a0d146a18d4162226bdc5fce54b0ee330d3f47); /* function */ 
}

    /**
     * @dev Internal pure function to retrieve and return the name of this
     *      contract.
     *
     * @return The name of this contract.
     */
    function _name() internal pure override returns (string memory) {c_0x0039749f(0xad26f386295d7c3d96d26d74f91115927b354f5107ba2d73a2ec634437673bea); /* function */ 

        // Return the name of the contract.
c_0x0039749f(0x34f3b51b33e461d77da113a988d7e524f29c7aa0e4ecbb8226230d29665d8baf); /* line */ 
        assembly {
            mstore(0x20, 0x20)
            mstore(0x47, 0x07536561706f7274)
            return(0x20, 0x60)
        }
    }

    /**
     * @dev Internal pure function to retrieve the name of this contract as a
     *      string that will be used to derive the name hash in the constructor.
     *
     * @return The name of this contract as a string.
     */
    function _nameString() internal pure override returns (string memory) {c_0x0039749f(0x4c8a2e15fb6388595e4b64ee4d31ad9edadd35eccda4b969c7433abf3581447a); /* function */ 

        // Return the name of the contract.
c_0x0039749f(0xc4015efcf18aa940fc6cd9c42393bd4e4b82516ffa729221776fa985f798c3b7); /* line */ 
        c_0x0039749f(0x40a13cca3ac95b28595a1cee4a13ab70fae4db480bf70cabf3843f7e7d598085); /* statement */ 
return "Seaport";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { ZoneInterface } from "../interfaces/ZoneInterface.sol";

import {
    AdvancedOrder,
    CriteriaResolver
} from "../lib/ConsiderationStructs.sol";

contract TestZone is ZoneInterface {
    function isValidOrder(
        bytes32 orderHash,
        address caller,
        address offerer,
        bytes32 zoneHash
    ) external pure override returns (bytes4 validOrderMagicValue) {
        orderHash;
        caller;
        offerer;

        if (zoneHash == bytes32(uint256(1))) {
            revert("Revert on zone hash 1");
        } else if (zoneHash == bytes32(uint256(2))) {
            assembly {
                revert(0, 0)
            }
        }

        validOrderMagicValue = zoneHash != bytes32(uint256(3))
            ? ZoneInterface.isValidOrder.selector
            : bytes4(0xffffffff);
    }

    function isValidOrderIncludingExtraData(
        bytes32 orderHash,
        address caller,
        AdvancedOrder calldata order,
        bytes32[] calldata priorOrderHashes,
        CriteriaResolver[] calldata criteriaResolvers
    ) external pure override returns (bytes4 validOrderMagicValue) {
        orderHash;
        caller;
        order;
        priorOrderHashes;
        criteriaResolvers;

        if (order.extraData.length == 4) {
            revert("Revert on extraData length 4");
        } else if (order.extraData.length == 5) {
            assembly {
                revert(0, 0)
            }
        }

        validOrderMagicValue = order.parameters.zoneHash != bytes32(uint256(3))
            ? ZoneInterface.isValidOrder.selector
            : bytes4(0xffffffff);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import { IERC721Receiver } from "../interfaces/IERC721Receiver.sol";

contract ERC721ReceiverMock is IERC721Receiver {
    enum Error {
        None,
        RevertWithMessage,
        RevertWithoutMessage,
        Panic
    }

    bytes4 private immutable _retval;
    Error private immutable _error;

    event Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes data,
        uint256 gas
    );

    constructor(bytes4 retval, Error error) {
        _retval = retval;
        _error = error;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public override returns (bytes4) {
        if (_error == Error.RevertWithMessage) {
            revert("ERC721ReceiverMock: reverting");
        } else if (_error == Error.RevertWithoutMessage) {
            revert();
        } else if (_error == Error.Panic) {
            uint256 a = uint256(0) / uint256(0);
            a;
        }
        emit Received(operator, from, tokenId, data, gasleft());
        return _retval;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ERC20Interface {
    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
}

interface ERC721Interface {
    function transferFrom(
        address,
        address,
        uint256
    ) external;
}

interface ERC1155Interface {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0xb7e5ce92(bytes32 c__0xb7e5ce92) pure {}


/**
 * @title ImmutableCreate2FactoryInterface
 * @author 0age
 * @notice This contract provides a safeCreate2 function that takes a salt value
 *         and a block of initialization code as arguments and passes them into
 *         inline assembly. The contract prevents redeploys by maintaining a
 *         mapping of all contracts that have already been deployed, and
 *         prevents frontrunning or other collisions by requiring that the first
 *         20 bytes of the salt are equal to the address of the caller (this can
 *         be bypassed by setting the first 20 bytes to the null address). There
 *         is also a view function that computes the address of the contract
 *         that will be created when submitting a given salt or nonce along with
 *         a given block of initialization code.
 */
interface ImmutableCreate2FactoryInterface {
    /**
     * @dev Create a contract using CREATE2 by submitting a given salt or nonce
     *      along with the initialization code for the contract. Note that the
     *      first 20 bytes of the salt must match those of the calling address,
     *      which prevents contract creation events from being submitted by
     *      unintended parties.
     *
     * @param salt               The nonce that will be passed into the CREATE2
     *                           call.
     * @param initializationCode The initialization code that will be passed
     *                           into the CREATE2 call.
     *
     * @return deploymentAddress Address of the contract that will be created.
     */
    function safeCreate2(bytes32 salt, bytes calldata initializationCode)
        external
        payable
        returns (address deploymentAddress);

    /**
     * @dev Compute the address of the contract that will be created when
     *      submitting a given salt or nonce to the contract along with the
     *      contract's initialization code. The CREATE2 address is computed in
     *      accordance with EIP-1014, and adheres to the formula therein of
     *      `keccak256( 0xff ++ address ++ salt ++ keccak256(init_code)))[12:]`
     *      when performing the computation. The computed address is then
     *      checked for any existing contract code - if so, the null address
     *      will be returned instead.
     *
     * @param salt     The nonce passed into the CREATE2 address calculation.
     * @param initCode The contract initialization code to be used that will be
     *                 passed into the CREATE2 address calculation.
     *
     * @return deploymentAddress Address of the contract that will be created,
     *                           or the null address if a contract already
     *                           exists at that address.
     */
    function findCreate2Address(bytes32 salt, bytes calldata initCode)
        external
        view
        returns (address deploymentAddress);

    /**
     * @dev Compute the address of the contract that will be created when
     *      submitting a given salt or nonce to the contract along with the
     *      keccak256 hash of the contract's initialization code. The CREATE2
     *      address is computed in accordance with EIP-1014, and adheres to the
     *      `keccak256( 0xff ++ address ++ salt ++ keccak256(init_code)))[12:]`
     *      formula when performing the computation. The computed address is
     *      then checked for any existing contract code - if so, the null
     *      address will be returned instead.
     *
     * @param salt         The nonce passed into the CREATE2 address
     *                     calculation.
     * @param initCodeHash The keccak256 hash of the initialization code that
     *                     will be passed into the CREATE2 address calculation.
     *
     * @return deploymentAddress Address of the contract that will be created,
     *                           or the null address if a contract already
     *                           exists at that address.
     */
    function findCreate2AddressViaHash(bytes32 salt, bytes32 initCodeHash)
        external
        view
        returns (address deploymentAddress);

    /**
     * @dev Determine if a contract has already been deployed by the factory to
     *      a given address.
     *
     * @param deploymentAddress The contract address to check.
     *
     * @return True if the contract has been deployed, false otherwise.
     */
    function hasBeenDeployed(address deploymentAddress)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ERC20ApprovalInterface {
    function approve(address, uint256) external returns (bool);
}

interface NFTApprovalInterface {
    function setApprovalForAll(address, bool) external;
}

contract EIP1271Wallet {
    bytes4 private constant _EIP_1271_MAGIC_VALUE = 0x1626ba7e;

    address public immutable owner;

    bool public showRevertMessage;

    mapping(bytes32 => bool) public digestApproved;

    bool public isValid;

    constructor(address _owner) {
        owner = _owner;
        showRevertMessage = true;
        isValid = true;
    }

    function setValid(bool valid) external {
        isValid = valid;
    }

    function revertWithMessage(bool showMessage) external {
        showRevertMessage = showMessage;
    }

    function registerDigest(bytes32 digest, bool approved) external {
        digestApproved[digest] = approved;
    }

    function approveERC20(
        ERC20ApprovalInterface token,
        address operator,
        uint256 amount
    ) external {
        if (msg.sender != owner) {
            revert("Only owner");
        }

        token.approve(operator, amount);
    }

    function approveNFT(NFTApprovalInterface token, address operator) external {
        if (msg.sender != owner) {
            revert("Only owner");
        }

        token.setApprovalForAll(operator, true);
    }

    function isValidSignature(bytes32 digest, bytes memory signature)
        external
        view
        returns (bytes4)
    {
        if (digestApproved[digest]) {
            return _EIP_1271_MAGIC_VALUE;
        }

        // NOTE: this is obviously not secure, do not use outside of testing.
        if (signature.length == 64) {
            // All signatures of length 64 are OK as long as valid is true
            return isValid ? _EIP_1271_MAGIC_VALUE : bytes4(0xffffffff);
        }

        if (signature.length != 65) {
            revert();
        }

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert();
        }

        if (v != 27 && v != 28) {
            revert();
        }

        address signer = ecrecover(digest, v, r, s);

        if (signer == address(0)) {
            revert();
        }

        if (signer != owner) {
            if (showRevertMessage) {
                revert("BAD SIGNER");
            }

            revert();
        }

        return isValid ? _EIP_1271_MAGIC_VALUE : bytes4(0xffffffff);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ERC1155BatchRecipient {
    error UnexpectedBatchData();

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes memory data
    ) external pure returns (bytes4) {
        if (data.length != 0) {
            revert UnexpectedBatchData();
        }
        return ERC1155BatchRecipient.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

contract ExcessReturnDataRecipient {
    uint256 private revertDataSize;

    function setRevertDataSize(uint256 size) external {
        revertDataSize = size;
    }

    // Code created with the help of Stack Exchange question
    // https://ethereum.stackexchange.com/questions/8086
    // Question by Doug King:
    // https://ethereum.stackexchange.com/users/2041/doug-king
    // Answer by Tjaden Hess:
    // https://ethereum.stackexchange.com/users/131/tjaden-hess
    // Modified to use Yul instead of Solidity and added change of
    // base to convert to natural logarithm
    function ln(uint256 x) internal pure returns (uint256 y) {
        assembly {
            let arg := x
            x := sub(x, 1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
            let m := mload(0x40)
            mstore(
                m,
                0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd
            )
            mstore(
                add(m, 0x20),
                0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe
            )
            mstore(
                add(m, 0x40),
                0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616
            )
            mstore(
                add(m, 0x60),
                0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff
            )
            mstore(
                add(m, 0x80),
                0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e
            )
            mstore(
                add(m, 0xa0),
                0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707
            )
            mstore(
                add(m, 0xc0),
                0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606
            )
            mstore(
                add(m, 0xe0),
                0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100
            )
            mstore(0x40, add(m, 0x100))
            let
                magic
            := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let
                shift
            := 0x100000000000000000000000000000000000000000000000000000000000000
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m, sub(255, a))), shift)
            y := add(
                y,
                mul(
                    256,
                    gt(
                        arg,
                        0x8000000000000000000000000000000000000000000000000000000000000000
                    )
                )
            )
            y := mul(y, 10000000000000000)
            y := div(y, 14426950408889632)
        }
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        assembly {
            switch gt(y, 3)
            case 1 {
                z := y
                let x := div(add(y, 1), 2)
                for {

                } lt(x, z) {

                } {
                    z := x
                    x := div(add(div(y, x), x), 2)
                }
            }
            case 0 {
                z := 1
            }
        }
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external view returns (bytes4 magic) {
        magic = this.onERC1155Received.selector;
        if (revertDataSize > 0) {
            uint256 gasToCalculateSqrt = (54 * ln(gasleft())) + 1200;
            uint256 w = (sqrt(
                2048 * (gasleft() - gasToCalculateSqrt) + 9431040
            ) - 3072) / 4;

            assembly {
                let size := mul(w, 32)
                calldatacopy(0, 0, mul(w, 32))
                revert(0, size)
            }
        }
    }

    receive() external payable {
        if (revertDataSize > 0) {
            uint256 gasToCalculateSqrt = (54 * ln(gasleft())) + 1200;
            uint256 w = (sqrt(
                2048 * (gasleft() - gasToCalculateSqrt) + 9431040
            ) - 3072) / 2;

            assembly {
                let size := mul(w, 32)
                calldatacopy(0, 0, mul(w, 32))
                revert(0, size)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4);
}

contract InvalidERC721Recipient is IERC721Receiver {
    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* tokenId */
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return 0xabcd0000;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Reenterer {
    address public target;
    uint256 public msgValue;
    bytes public callData;

    event Reentered(bytes returnData);

    function prepare(
        address targetToUse,
        uint256 msgValueToUse,
        bytes calldata callDataToUse
    ) external {
        target = targetToUse;
        msgValue = msgValueToUse;
        callData = callDataToUse;
    }

    receive() external payable {
        (bool success, bytes memory returnData) = target.call{
            value: msgValue
        }(callData);

        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        emit Reentered(returnData);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "@rari-capital/solmate/src/tokens/ERC1155.sol";

// Used for minting test ERC1155s in our tests
contract TestERC1155 is ERC1155 {
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) public returns (bool) {
        _mint(to, tokenId, amount, "");
        return true;
    }

    function uri(uint256) public pure override returns (string memory) {
        return "uri";
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
                            ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
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
        bytes memory data
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
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        for (uint256 i = 0; i < idsLength; ) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
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

    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        uint256 ownersLength = owners.length; // Saves MLOADs.

        require(ownersLength == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < ownersLength; i++) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
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
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
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
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
interface ERC1155TokenReceiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "@rari-capital/solmate/src/tokens/ERC20.sol";

// Used for minting test ERC20s in our tests
contract TestERC20 is ERC20("Test20", "TST20", 18) {
    bool public blocked;

    bool public noReturnData;

    constructor() {
        blocked = false;
        noReturnData = false;
    }

    function blockTransfer(bool blocking) external {
        blocked = blocking;
    }

    function setNoReturnData(bool noReturn) external {
        noReturnData = noReturn;
    }

    function mint(address to, uint256 amount) external returns (bool) {
        _mint(to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool ok) {
        if (blocked) {
            return false;
        }

        super.transferFrom(from, to, amount);

        if (noReturnData) {
            assembly {
                return(0, 0)
            }
        }

        ok = true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

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

    /*///////////////////////////////////////////////////////////////
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@rari-capital/solmate/src/tokens/ERC20.sol";

contract TestERC20Revert is ERC20("TestRevert", "REVERT", 18) {
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function transferFrom(
        address, /* from */
        address, /* to */
        uint256 /* amount */
    ) public pure override returns (bool) {
        revert();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@rari-capital/solmate/src/tokens/ERC20.sol";

contract TestERC20Panic is ERC20("TestPanic", "PANIC", 18) {
    function mint(address to, uint256 amount) external returns (bool) {
        _mint(to, amount);
        return true;
    }

    function transferFrom(
        address, /* from */
        address, /* to */
        uint256 /* amount */
    ) public pure override returns (bool) {
        uint256 a = uint256(0) / uint256(0);
        a;

        return true;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "@rari-capital/solmate/src/tokens/ERC721.sol";

// Used for minting test ERC721s in our tests
contract TestERC721 is ERC721("Test721", "TST721") {
    function mint(address to, uint256 tokenId) public returns (bool) {
        _mint(to, tokenId);
        return true;
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "tokenURI";
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

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
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

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
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
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
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}