// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0xcdf251a9(bytes32 c__0xcdf251a9) pure {}


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
function c_0xbacc508b(bytes32 c__0xbacc508b) internal pure {}

    // Set deployer as an immutable controller that can update channel statuses.
    address private immutable _controller;

    // Track the status of each channel.
    mapping(address => bool) private _channels;

    /**
     * @notice Ensure that the caller is currently registered as an open channel
     *         on the conduit.
     */
    modifier onlyOpenChannel() {c_0xbacc508b(0xd88f41f99095aeab41b1f91c2a386680996f85eb2872b00f3caf02925c8129dc); /* function */ 

        // Utilize assembly to access channel storage mapping directly.
c_0xbacc508b(0xe25c583fc773eadef9ef28a723fb40d5e934aba8b8c2e97dcc14cebe80904318); /* line */ 
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
c_0xbacc508b(0x5a299ec3fe2a039bea8a4db682cda320ac298c0d5ff49baaac7e1b365eeae1fc); /* line */ 
        _;
    }

    /**
     * @notice In the constructor, set the deployer as the controller.
     */
    constructor() {c_0xbacc508b(0xec60fc2f34848c37c34f7b9a668a9b0f29e63ece975827a7debcb7b91218d9f5); /* function */ 

        // Set the deployer as the controller.
c_0xbacc508b(0x18b9e95b03c16f2e260777c08ba1d1c21066d581321d5211bfc84640587a1136); /* line */ 
        c_0xbacc508b(0x1712e351b8df27bb297eccfd800c104fe5c2e61a75c3e94fa5c9c59909ae92fe); /* statement */ 
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
    {c_0xbacc508b(0x6b21d9c86fe4486f092b477a284dc7a37a8483a65b1c7bac6659116fff81707b); /* function */ 

        // Retrieve the total number of transfers and place on the stack.
c_0xbacc508b(0xc57df01bad06619da99d80cfa8f58253fd232b664f54e8fb34cfc0bc4cfe6547); /* line */ 
        c_0xbacc508b(0x256c047f61d4892321958c8e2ee19fab0c1fb423eeb118618ac747f113d26787); /* statement */ 
uint256 totalStandardTransfers = transfers.length;

        // Iterate over each transfer.
c_0xbacc508b(0xf8f4b8a9a3d9a9c1125b02c926bd2a0b1fb5776956c6e26c16cbd0192abd677d); /* line */ 
        c_0xbacc508b(0xc592b9b7bbb04c3ea0f7953d17383658d2b7a25cd6a5da1a24e31537765c7275); /* statement */ 
for (uint256 i = 0; i < totalStandardTransfers; ) {
            // Retrieve the transfer in question and perform the transfer.
c_0xbacc508b(0x5980e5754d7284a407745a1558db8dc5e0b57dc48f6253eaedc68b35239c8e7c); /* line */ 
            c_0xbacc508b(0xc1a85a8d032b602917ac875ed0b7708543ddfda1039a79656ea303d7dc359e34); /* statement */ 
_transfer(transfers[i]);

            // Skip overflow check as for loop is indexed starting at zero.
c_0xbacc508b(0x91954c1b6947ba405723823f5793bbcd8a342802012794e05eb994df6631db60); /* line */ 
            unchecked {
c_0xbacc508b(0x5a52af1a94a1543b21fee76587ae7bc4e63326a807c3c193b0bf60f5c32c3255); /* line */ 
                ++i;
            }
        }

        // Return a magic value indicating that the transfers were performed.
c_0xbacc508b(0xbc11a996b00624828342e0b3859f57e4430de1a49c8fd995a9d1538997b43518); /* line */ 
        c_0xbacc508b(0xe369af6d1e1294150aec7ed15a69c2e77849d7029a227660d896e0cffc773866); /* statement */ 
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
    ) external override onlyOpenChannel returns (bytes4 magicValue) {c_0xbacc508b(0x466ff417422ce8cb49b9abc4c18b0e6de7a44157bf1f9d91d9f9266c4043f68d); /* function */ 

        // Perform 1155 batch transfers. Note that memory should be considered
        // entirely corrupted from this point forward.
c_0xbacc508b(0x80e8be54803129cdb6a6eaf69a435d0a1370cbff3232bb50f826321260d700ac); /* line */ 
        c_0xbacc508b(0xcea8d45a02d0c16c533b760d0d565d1ae397ab0132dc5aacd1eb4f8061fb164c); /* statement */ 
_performERC1155BatchTransfers(batchTransfers);

        // Return a magic value indicating that the transfers were performed.
c_0xbacc508b(0x89bd31fe0c19049e1068140a74729cda2b25dfbd1e1e74ea4cf40c73b3207d43); /* line */ 
        c_0xbacc508b(0x57a7cf3de628c27684ba944ec273b9a18319dfa7758ff64eabe08b106a481c51); /* statement */ 
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
    ) external override onlyOpenChannel returns (bytes4 magicValue) {c_0xbacc508b(0xbacffff86fb4d7df94a4c69e8692730aa24b45c042a21bac10df3909576a5379); /* function */ 

        // Retrieve the total number of transfers and place on the stack.
c_0xbacc508b(0xfd7965211f487f8f44694f7fd71a7e96c225d13f08e3df22a54cb063b3efdadf); /* line */ 
        c_0xbacc508b(0xa4a9b031e0441136945a57779e96260cd5f3e02a945da16a6cbae264f30260ff); /* statement */ 
uint256 totalStandardTransfers = standardTransfers.length;

        // Iterate over each standard transfer.
c_0xbacc508b(0x734c891950d6838bc92e620e67227b03578874d4099eb52c0fc08352adbd5b59); /* line */ 
        c_0xbacc508b(0xf7cbc237e06cf1f4cf26e88049c0ed679b668bde22d324b0d235d1d189bc9517); /* statement */ 
for (uint256 i = 0; i < totalStandardTransfers; ) {
            // Retrieve the transfer in question and perform the transfer.
c_0xbacc508b(0x2a82fea85213a8b93510296607a8ef179154a11a5095c3e917208e1cd468f6d6); /* line */ 
            c_0xbacc508b(0x063b59ab7cf1e81e5edc45d54d6e15f01946e85314699dc079bb0ea714cbd239); /* statement */ 
_transfer(standardTransfers[i]);

            // Skip overflow check as for loop is indexed starting at zero.
c_0xbacc508b(0x069193ce9f45ad22ae28f9580d7b087f4910403044bb03006b6571a610a449ce); /* line */ 
            unchecked {
c_0xbacc508b(0x1026e19591b4b4d5b86e53ae1c4d00c83ad5e6799fed0aa9a87cec584732c028); /* line */ 
                ++i;
            }
        }

        // Perform 1155 batch transfers. Note that memory should be considered
        // entirely corrupted from this point forward aside from the free memory
        // pointer having the default value.
c_0xbacc508b(0x6e2e47c4619eff9b9b93abdf40b719c7e9125496ee3fbd00ac13b20d73790b82); /* line */ 
        c_0xbacc508b(0x046115ee5c51feb49e0bd8425a5e87e4a137497e6439c252e81b12270c9962e9); /* statement */ 
_performERC1155BatchTransfers(batchTransfers);

        // Return a magic value indicating that the transfers were performed.
c_0xbacc508b(0x02bffb48fe4a875758a3cfe39940d80d5e23e05575f96319e269f93ad9261afb); /* line */ 
        c_0xbacc508b(0xc90e8a738cd91b303519cbc9e1a858bfae51770cc5c5712dba35230c5b7af605); /* statement */ 
magicValue = this.executeWithBatch1155.selector;
    }

    /**
     * @notice Open or close a given channel. Only callable by the controller.
     *
     * @param channel The channel to open or close.
     * @param isOpen  The status of the channel (either open or closed).
     */
    function updateChannel(address channel, bool isOpen) external override {c_0xbacc508b(0x1c95479cdcc8cfc824ac4565520077ec8676b167bfff056d7bcca4f790846b81); /* function */ 

        // Ensure that the caller is the controller of this contract.
c_0xbacc508b(0x1dfbd9d5fc1e72f1bfdc79714958ef2701ce38670d6fb53de9e9ecf1c521c99e); /* line */ 
        c_0xbacc508b(0xa1b6eb6aa95049ac99539a97b06de2753deccbc73c904f5ca2a2ef2ecc9f3cf8); /* statement */ 
if (msg.sender != _controller) {c_0xbacc508b(0x0d5d9bbadc043b6cf0100a7add8c230435a41a94dc3c5ee01007b51973168d1d); /* branch */ 

c_0xbacc508b(0x2467f2c768cbf689d7fbbdb3dcbad024b4d15e601e97e42e414fe71b196a469a); /* line */ 
            revert InvalidController();
        }else { c_0xbacc508b(0x7f44f4287013dffce0166028106f32ef64b1f2117c6250896e211e18d7358af4); /* branch */ 
}

        // Ensure that the channel does not already have the indicated status.
c_0xbacc508b(0x93b8a1179ead97401fbf838891e1cc5377dc2151dde644004b47e038bbbfd149); /* line */ 
        c_0xbacc508b(0xae9dd3e9b92ef79469988df5a3e7ede5ad679f290bacc1433444cfd7119f2506); /* statement */ 
if (_channels[channel] == isOpen) {c_0xbacc508b(0x646abc1f173ee7fb2298f13e81e4e88bb33f74ab52c32669923b167684a113e1); /* branch */ 

c_0xbacc508b(0xb757413c4ebdcdd7e681c8c9be0bda91ab693cf3df6e0aafafac982dd3d186ea); /* line */ 
            revert ChannelStatusAlreadySet(channel, isOpen);
        }else { c_0xbacc508b(0x526efaf9f69c2e465059a3f71b292a52ca696d5de33557afb85901d04880ba70); /* branch */ 
}

        // Update the status of the channel.
c_0xbacc508b(0xc17b25053981db58e1fb97d5b2ff88a9670f89552edc221f8a44361f0dc12042); /* line */ 
        c_0xbacc508b(0x6c81440d65458e2460b000ae5a6af899a1fe7d84c2fa0bf9b275a9f982423b0d); /* statement */ 
_channels[channel] = isOpen;

        // Emit a corresponding event.
c_0xbacc508b(0xf3faccabd7a0af09d21d08d0909d579f76deceb0f38f8f67c68c049f1d69cd34); /* line */ 
        c_0xbacc508b(0x7ea6534f48788a390ced8ac48df821f110f17fd3727e2e37be47d59fe00ba783); /* statement */ 
emit ChannelUpdated(channel, isOpen);
    }

    /**
     * @dev Internal function to transfer a given ERC20/721/1155 item. Note that
     *      channels are expected to implement checks against transferring any
     *      zero-amount items if that constraint is desired.
     *
     * @param item The ERC20/721/1155 item to transfer.
     */
    function _transfer(ConduitTransfer calldata item) internal {c_0xbacc508b(0x9cfc9e2c92dbe0920a50d3f223124772f9734b1b5137113e90c310be20a87b77); /* function */ 

        // Determine the transfer method based on the respective item type.
c_0xbacc508b(0x1b9ecdfcb4c8cedf54f0ec23a10910aab69bd2a072ef538d0a246f4ba97c908b); /* line */ 
        c_0xbacc508b(0x87f036849b51050dfacc7993e7beb618c56a11c0242ce76c3fb4fc216a140c7f); /* statement */ 
if (item.itemType == ConduitItemType.ERC20) {c_0xbacc508b(0x7cc88a60d16d7a0bef4e16f36c7589291ba6862b7472a1d51838576b887fb8f1); /* branch */ 

            // Transfer ERC20 token. Note that item.identifier is ignored and
            // therefore ERC20 transfer items are potentially malleable — this
            // check should be performed by the calling channel if a constraint
            // on item malleability is desired.
c_0xbacc508b(0x781cb125207b2b8a41969b9f82a2dc6b9b14f4dd6981b67794b60d6b967df87c); /* line */ 
            c_0xbacc508b(0x0eef712ffa3bc1073718b84f1ce48192c0f8e93f9c2fa8950eb95e6a233e69ac); /* statement */ 
_performERC20Transfer(item.token, item.from, item.to, item.amount);
        } else {c_0xbacc508b(0x383f989389f6d55b80e4fb58df0a947b27d67ba94f9a7cec5700c9a05e340ff2); /* statement */ 
c_0xbacc508b(0x35177b0846899d374d327ae4e751458324e2725918ac416af69f818c63889e8a); /* branch */ 
if (item.itemType == ConduitItemType.ERC721) {c_0xbacc508b(0xbfa1ab653b0a0b99da7760f05555ab1c835655e77b68fba32fd6b4896a9eb9ea); /* branch */ 

            // Ensure that exactly one 721 item is being transferred.
c_0xbacc508b(0x0b31d172ae625198b9eb109df189e0f3d58d02f9340c932d2bd45fe5c2afe5aa); /* line */ 
            c_0xbacc508b(0xb2fc56a8e9a2feb84032287832c209f0119b114cd6b525496e969ba1c8a9b525); /* statement */ 
if (item.amount != 1) {c_0xbacc508b(0xbfabb93348982a159ee0ee18eb6f9e3aa91d0649ffefdab8df0ccf3ebd338295); /* branch */ 

c_0xbacc508b(0xd507a422f5e013d35e674ee471ae10471ff83c12bd783136277dcc1c7d4141e8); /* line */ 
                revert InvalidERC721TransferAmount();
            }else { c_0xbacc508b(0x4dfcd61aa9d119f4b4622624ebadb133ac90e8245ea3b7d6a74464ca2582efae); /* branch */ 
}

            // Transfer ERC721 token.
c_0xbacc508b(0xe014b0d6224158802d5d7425297322e78cb1de248e4b1ddd79a45dd031b18799); /* line */ 
            c_0xbacc508b(0xd085e9615b2367a70115f597482313b171cf8bb218961131212d0722719c4184); /* statement */ 
_performERC721Transfer(
                item.token,
                item.from,
                item.to,
                item.identifier
            );
        } else {c_0xbacc508b(0xe7b17a1942ac57f813ab7048bed6ef758fbde7d010d25e559788d54bf7750e12); /* statement */ 
c_0xbacc508b(0x8ebca1deaec0fc88361f3bad026a7eb7088fab95d8825116f71bd68c446d8733); /* branch */ 
if (item.itemType == ConduitItemType.ERC1155) {c_0xbacc508b(0xb3887a32cecd74304f6c6961ea08cae419ad20922ada0f287ac0b279fef306e2); /* branch */ 

            // Transfer ERC1155 token.
c_0xbacc508b(0x92fdbb00c486ffb7739a6b2908f1de93ed4f1641f8a237dd53bb934ba3cbcdde); /* line */ 
            c_0xbacc508b(0xf4289867c053a79d8cf0895cab2abfd82983db1ec032e163c5d61a505293b663); /* statement */ 
_performERC1155Transfer(
                item.token,
                item.from,
                item.to,
                item.identifier,
                item.amount
            );
        } else {c_0xbacc508b(0xf6572b46a67b6160bce30c82c800b11182ce1b69237960d942d04f4581b26c91); /* branch */ 

            // Throw with an error.
c_0xbacc508b(0x01ff13a7f23bbaa92d184b1c6e062721ae07bbd6dd67f5b7dfb3a8a3dbd967f7); /* line */ 
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
function c_0xf848fd0c(bytes32 c__0xf848fd0c) pure {}


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
function c_0x3551e425(bytes32 c__0x3551e425) internal pure {}

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
    ) internal {c_0x3551e425(0x6f7eb1724fd4f70e54998523ae0926e0be2c59dd9a283eea0aa094d5d301c5b7); /* function */ 

        // Utilize assembly to perform an optimized ERC20 token transfer.
c_0x3551e425(0x1adaddf1500208ac752e3ed5c671e2baf618929fdea3c11f121821ee0bfda30f); /* line */ 
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
    ) internal {c_0x3551e425(0x31a5b6d7218867228f67dd388f945715a5e02189f7f64838cc294c7ffc298ccf); /* function */ 

        // Utilize assembly to perform an optimized ERC721 token transfer.
c_0x3551e425(0x11e5e010a0492a2c1effc64dbb7d786dbaffa2ffaf05f143b196f6575dbccd43); /* line */ 
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
    ) internal {c_0x3551e425(0x54019209d8e4527301653ae1b1523bd6f783ce54640c9c426674112e9ef512c3); /* function */ 

        // Utilize assembly to perform an optimized ERC1155 token transfer.
c_0x3551e425(0x6fa2f1c4d979b681b16e13d8d6ac35b624c5d1792ab6f95e223a495fbb232d22); /* line */ 
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
    ) internal {c_0x3551e425(0x4537822cc28886411965339f3d0436cfec8662693dd191352dac64c77ce7a1f3); /* function */ 

        // Utilize assembly to perform optimized batch 1155 transfers.
c_0x3551e425(0x2c538cdc6e486bf948d5ca11630151cf3df09413b3c38dd2f660e02a93c1d90b); /* line */ 
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
function c_0x7eb28504(bytes32 c__0x7eb28504) pure {}


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
function c_0xf896d1d9(bytes32 c__0xf896d1d9) pure {}


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
function c_0x434201a2(bytes32 c__0x434201a2) pure {}


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
function c_0x9001a252(bytes32 c__0x9001a252) pure {}


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
function c_0xec0e7bff(bytes32 c__0xec0e7bff) internal pure {}

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
    constructor(address conduitController) {c_0xec0e7bff(0x7334b7111132256320d970b8a480ba1f5aae0d7efe232dc83d501f43e9d42ecb); /* function */ 

        // Get the conduit creation code and runtime code hashes from the
        // supplied conduit controller and set them as an immutable.
c_0xec0e7bff(0x569cf56d86b15ac1e491e14bed9bc0dddc4c47b236ec8d69dc7f96f1632bc1d1); /* line */ 
        c_0xec0e7bff(0x9551b906b395d2e7d3cad0c6cbe972e3723e7d8389970108fc69980f32df1dd0); /* statement */ 
ConduitControllerInterface controller = ConduitControllerInterface(
            conduitController
        );
c_0xec0e7bff(0x7ebbc10fffda2f22d774d4054ccf6dc4f35211c3233520f7c7f9a10727233b75); /* line */ 
        c_0xec0e7bff(0x478e06da0797e356bb63a5aba716dc954ddc0918c6a132c0cfa9430d6f80d590); /* statement */ 
(_CONDUIT_CREATION_CODE_HASH, _CONDUIT_RUNTIME_CODE_HASH) = controller
            .getConduitCodeHashes();

        // Set the supplied conduit controller as an immutable.
c_0xec0e7bff(0xcd74f82a6b2e84cf8f03dd519b7f7f7732141ab62e917d35ca8008413bc2d25a); /* line */ 
        c_0xec0e7bff(0x5d37dc5ab9e1b625bd8687f53be45309e8b00f8a6aa76627ba77058cf40e4b6c); /* statement */ 
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
    ) external override returns (bytes4 magicValue) {c_0xec0e7bff(0x257cfff3d3e826d4c0adfffdbec1376b7653835a89ebdc9ccb388703bd4b057f); /* function */ 

        // Ensure that a conduit key has been supplied.
c_0xec0e7bff(0x84790ce960877674bebeef8cbce4b6b56b0fa764dd7c400a160e28fae155bcd5); /* line */ 
        c_0xec0e7bff(0xf3a602f1a2d2895a9090c12ca1c5472e2e3bdfd5855b6c305657b0dbbb464d88); /* statement */ 
if (conduitKey == bytes32(0)) {c_0xec0e7bff(0x1ebecd9de09a9258ebe5f9e0c9e777722b7e600c80eba6e8fd538dcfd0bc0618); /* branch */ 

c_0xec0e7bff(0x7671e3f1248a401e1bffcf162be115bf7b5113308f0a74422762b7888a3a1b94); /* line */ 
            revert InvalidConduit(conduitKey, address(0));
        }else { c_0xec0e7bff(0x5d97057ec4e43036d8d04fcb140c8c09b91e1746d2ec788c088c63b13ba1499e); /* branch */ 
}

        // Use conduit derived from supplied conduit key to perform transfers.
c_0xec0e7bff(0x30414213735ab4d69c9bbab0b438962c173b7adb1ed0085d2f501d67706c0383); /* line */ 
        c_0xec0e7bff(0xc41a808b0e306e36241fe3332e448201900894fe8816123f047e6be37308a77d); /* statement */ 
_performTransfersWithConduit(items, conduitKey);

        // Return a magic value indicating that the transfers were performed.
c_0xec0e7bff(0xe328ca36a06f48afb736344b3111377df32e6fd52d27e60e6e5992b2cc4436a7); /* line */ 
        c_0xec0e7bff(0xb1738861199b16fb77f37db1ac15914ea35ce87044f189fa20bd0718016e628d); /* statement */ 
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
    ) internal {c_0xec0e7bff(0x77145b58a9f844822de6ddf38475a719990e7c178aaa3ce205156c4ba11d5805); /* function */ 

        // Retrieve total number of transfers and place on stack.
c_0xec0e7bff(0xd1a0339d1b060005a9e62c609dc88e1723097aff5697fbd2fe633e9434e1ac6c); /* line */ 
        c_0xec0e7bff(0xd87c490640ed2fa05a66d2e0b9a0bca1fd1fc67c024fd28763f414bbb752e269); /* statement */ 
uint256 numTransfers = transfers.length;

        // Derive the conduit address from the deployer, conduit key
        // and creation code hash.
c_0xec0e7bff(0xef6d0cf17ba249262f3ea97d49412ac5390547e0207261a179587509c57feb72); /* line */ 
        c_0xec0e7bff(0x3094e838979bf84e608661dee144d8df7c50a52ec9a8e8966102be89181c3e90); /* statement */ 
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
c_0xec0e7bff(0x5da4b635feae24972022364dcf2a92c73d71fd2e409d3a4180a2cf24c595b61e); /* line */ 
        c_0xec0e7bff(0x0bb327477969451a197fc41c1376585ece636d7102a8c79adc971ab3026de6a9); /* statement */ 
uint256 sumOfItemsAcrossAllTransfers;

        // Skip overflow checks: all for loops are indexed starting at zero.
c_0xec0e7bff(0xc456c747e1aa9ef03a72fd24e53d0774a2cc5f544b96d53130bf5bb2bd76bd24); /* line */ 
        unchecked {
            // Iterate over each transfer.
c_0xec0e7bff(0xf1cc1a5ee6edff3a83965917d97c860b3f1b955cf39b73c6c90a13e243861b7f); /* line */ 
            c_0xec0e7bff(0x68c78008d838d9d695f2b4f262311b95fab62ef0319becfe5da22727df732299); /* statement */ 
for (uint256 i = 0; i < numTransfers; ++i) {
                // Retrieve the transfer in question.
c_0xec0e7bff(0x584224227a46b8a416b4df2bba74c5f838d0a431ca8fbf24e982f7dc91fa191f); /* line */ 
                c_0xec0e7bff(0x6abd060063d8e01523cee27c0205c67e79b121fd0aee7a90686ebf50c3c1f431); /* statement */ 
TransferHelperItemsWithRecipient calldata transfer = transfers[
                    i
                ];

                // Increment totalItems by the number of items in the transfer.
c_0xec0e7bff(0xb52eb107bbf5cfd19ae002a98310554389ec7185fede1e211fcdb473224cb829); /* line */ 
                c_0xec0e7bff(0x9b8d3ceba0048090051ce4439dfbdf3a4b0ebc67902b78c6fd27d8d87d2bb489); /* statement */ 
sumOfItemsAcrossAllTransfers += transfer.items.length;
            }
        }

        // Declare a new array in memory with length totalItems to populate with
        // each conduit transfer.
c_0xec0e7bff(0x3af2237b124a92671c08ce04fda77983da79e6770071c556692349fcd8ad0862); /* line */ 
        c_0xec0e7bff(0x25d3629dada428ce893d9e08fbb3764740369534f93acd359fe50c74a5c78f0a); /* statement */ 
ConduitTransfer[] memory conduitTransfers = new ConduitTransfer[](
            sumOfItemsAcrossAllTransfers
        );

        // Declare an index for storing ConduitTransfers in conduitTransfers.
c_0xec0e7bff(0x85e52c82ceb3ae0efd53fde188734a14c4591250e98000b639c9239a1227f0f4); /* line */ 
        c_0xec0e7bff(0x11bd8d66236e00c7a8c98c3dbcef1718b26aac5dd7758cc56d6257ab30222ff6); /* statement */ 
uint256 itemIndex;

        // Skip overflow checks: all for loops are indexed starting at zero.
c_0xec0e7bff(0xae9a02400ed33f9701ff98985b17af96f9dbe799ee23e1266bdd2d6262013daf); /* line */ 
        unchecked {
            // Iterate over each transfer.
c_0xec0e7bff(0x7ed686f6e8f8c3151a3451eb6be4160b424c35a31334747339a4437dee8a2c55); /* line */ 
            c_0xec0e7bff(0xc4a01e4a1b5f52a2ded6afdf5fd3b635674a518e8560aff3a4af16d38179583b); /* statement */ 
for (uint256 i = 0; i < numTransfers; ++i) {
                // Retrieve the transfer in question.
c_0xec0e7bff(0x57c0722a2e662bb0db8eed25c1feaf38ecf4314e3e9c512869d6d0ef6deecd09); /* line */ 
                c_0xec0e7bff(0x772761e187475d335fb28c5fa16eac0ab4a81717910f41e71eeb23f12525abb8); /* statement */ 
TransferHelperItemsWithRecipient calldata transfer = transfers[
                    i
                ];

                // Retrieve the items of the transfer in question.
c_0xec0e7bff(0x7cd74646c957c01ec3d278273537dd775be6c43f982c2c1680434639f7d884b6); /* line */ 
                c_0xec0e7bff(0xf938d951c65597578a7e50d5107914c1b95c8da3f2dd75a014de6e3645d6981b); /* statement */ 
TransferHelperItem[] calldata transferItems = transfer.items;

                // Ensure recipient is not the zero address.
c_0xec0e7bff(0x79330e76ced325bbd2ac94b7dd60de66c0ad09dff8df5c96a1f6d63f708ef54e); /* line */ 
                c_0xec0e7bff(0x6ae11e83c109f7859c01a373b554da0798a4864b64919936b7a53a566d69ccb8); /* statement */ 
_checkRecipientIsNotZeroAddress(transfer.recipient);

                // Create a boolean indicating whether validateERC721Receiver
                // is true and recipient is a contract.
c_0xec0e7bff(0xf8918c50c07647a4c10349d19f358b38c3c60ab39dcfc70a8ec425d4ccfff3cc); /* line */ 
                c_0xec0e7bff(0xf5621aa4519e41c9a5e15cad3a87a819f0b19e38aae697bf3891e04681b1f467); /* statement */ 
bool callERC721Receiver = transfer.validateERC721Receiver &&
                    transfer.recipient.code.length != 0;

                // Retrieve the total number of items in the transfer and
                // place on stack.
c_0xec0e7bff(0xeed36b80abe45d25220f359241ee74ee1d748fe2a7edcb4bd7b470107641dbb9); /* line */ 
                c_0xec0e7bff(0x5174bd768888695e9b6445a8a72d1a89bf991f901ec89697a4f2ce820e7a7c44); /* statement */ 
uint256 numItemsInTransfer = transferItems.length;

                // Iterate over each item in the transfer to create a
                // corresponding ConduitTransfer.
c_0xec0e7bff(0x7d5907aba46687bfe9f1665673ea8e6be34828cedea1f6542126683a7e65ecd7); /* line */ 
                c_0xec0e7bff(0x30b96b0bc3dd013988e7f04faaba3ce942188a8fc1524d3d38e5d22e8374a034); /* statement */ 
for (uint256 j = 0; j < numItemsInTransfer; ++j) {
                    // Retrieve the item from the transfer.
c_0xec0e7bff(0x1721a8a6bc5cf080bcaf55c3bb2fe8c50bc76c387875cbbe2bec5d4da39155a4); /* line */ 
                    c_0xec0e7bff(0x9b55ebeeebd77c6512528ef75583f01f99afba97b77af660d899a40cb073532b); /* statement */ 
TransferHelperItem calldata item = transferItems[j];

c_0xec0e7bff(0x9879c6afd05fa666b7d2307c4d8e4bdd47dc433781f5766d31580c63a281f0ab); /* line */ 
                    c_0xec0e7bff(0x8a5f8e35c7035240d6dd200114e14c17cd594afb63e4f8392e3e24ffaf29c746); /* statement */ 
if (item.itemType == ConduitItemType.ERC20) {c_0xec0e7bff(0x7484e13acfd793b5cdf2c91f3a5e5c1acc81d62e3ce65bbfcc83ab7bd0bada3f); /* branch */ 

                        // Ensure that the identifier of an ERC20 token is 0.
c_0xec0e7bff(0xdd680a2813005729cb26ab74b75434f37990aed360e9cf4b4302e1c0b662cb61); /* line */ 
                        c_0xec0e7bff(0xcbdb6cae4377df4e83a062f84bf523fc2f58d142de214854483e430cba1e5b45); /* statement */ 
if (item.identifier != 0) {c_0xec0e7bff(0x24edcaacdd6a84b26d4c85c25bbf0520aff0c1e737e0e5fd3ac5a3badb7f96d5); /* branch */ 

c_0xec0e7bff(0x58276d1dc017b5ba338e477815d65439175316d30f41fe9205952235a56762b2); /* line */ 
                            revert InvalidERC20Identifier();
                        }else { c_0xec0e7bff(0xb44e3d652f8b3ea3210002b4665ce275935273ca0b9c13cdbad480ee558182ea); /* branch */ 
}
                    }else { c_0xec0e7bff(0xe56e012950fc700af10913c6b4ff536698e9aeefcc34278bfbca00c19e943e6b); /* branch */ 
}

                    // If the item is an ERC721 token and
                    // callERC721Receiver is true...
c_0xec0e7bff(0x9ebc854aceccfc80980687c3d7414111b0b287e69ae51ef2fd34823226530805); /* line */ 
                    c_0xec0e7bff(0x67ff0456a799140d3647d41e350e86c6ad30be2d970ac5f4d84d24e753466b92); /* statement */ 
if (item.itemType == ConduitItemType.ERC721) {c_0xec0e7bff(0x2be9ffcb42ff3ff8e07bcef46b21d2c36f774f402247cb4e82052a2803d69c73); /* branch */ 

c_0xec0e7bff(0x12a927c7d4aebc42187bb3d08a7261ab369d7b0f2216eb0ec6be2341675afabb); /* line */ 
                        c_0xec0e7bff(0x3c6c27ad11e953ff6876ed51fb136fee51dc4dc120c896236cc5266d45e53b2b); /* statement */ 
if (callERC721Receiver) {c_0xec0e7bff(0x9d6565821d77120915bbe3a20de62e0e204dada0c3c508e02fbcf97f4733545d); /* branch */ 

                            // Check if the recipient implements
                            // onERC721Received for the given tokenId.
c_0xec0e7bff(0x843f184686f456d0c81debd448e6725e5fa4ffb1b33ce70e1d30a91ff7bb1324); /* line */ 
                            c_0xec0e7bff(0xa1fe055221af171bed1061260d69b66e1afabdaa11de18cfbebffe3707b82b28); /* statement */ 
_checkERC721Receiver(
                                conduit,
                                transfer.recipient,
                                item.identifier
                            );
                        }else { c_0xec0e7bff(0xf2085d341b8a4303d95f29f83f64fb1665b6a4567abfae716d0e351740071685); /* branch */ 
}
                    }else { c_0xec0e7bff(0x11104755a62a05491f61fa9cbc3e9ef5557fbf54f74542ffb941d9bd7887325b); /* branch */ 
}

                    // Create a ConduitTransfer corresponding to each
                    // TransferHelperItem.
c_0xec0e7bff(0x304b1f6f405d8df767a28496d9e0bcef461518e3cee918d41fada12f91fbdcf4); /* line */ 
                    c_0xec0e7bff(0x594d4476cd1bd65591a72e5213422968c5bb170b52726adf5ed0bd3ee8d46b99); /* statement */ 
conduitTransfers[itemIndex] = ConduitTransfer(
                        item.itemType,
                        item.token,
                        msg.sender,
                        transfer.recipient,
                        item.identifier,
                        item.amount
                    );

                    // Increment the index for storing ConduitTransfers.
c_0xec0e7bff(0xb83fa66bc293047b4396eb63b208f8974d0063a4bddad19f44b5c9e88754ac55); /* line */ 
                    ++itemIndex;
                }
            }
        }

        // Attempt the external call to transfer tokens via the derived conduit.
c_0xec0e7bff(0x1b13785ed233f3530408f1889e7b188bd335b093a1002fa51961e2b3a03740fe); /* line */ 
        c_0xec0e7bff(0xa982840b65420fcfef7db97385632d7cb023e55c9b739519eff24ccbabe60927); /* statement */ 
try ConduitInterface(conduit).execute(conduitTransfers) returns (
            bytes4 conduitMagicValue
        ) {
            // Check if the value returned from the external call matches
            // the conduit `execute` selector.
c_0xec0e7bff(0x9b2af5da402871abfcfee1fa57af696a71b50632479bf9607ad54d6e8ebedbff); /* line */ 
            c_0xec0e7bff(0x27b11167bd9ddf147455da1a7b11af24d4e399f9e111beef7c455ebc4e51ec47); /* statement */ 
if (conduitMagicValue != ConduitInterface.execute.selector) {c_0xec0e7bff(0xe0048d0acbaa8c8873810c1a6169cc7b2fadf7ae8d7e24e0d43feb739a2dc373); /* branch */ 

                // If the external call fails, revert with the conduit key
                // and conduit address.
c_0xec0e7bff(0x96254244956f27a2613a1ba39c5da4ae755563c717a1621af46d2362637c38d0); /* line */ 
                revert InvalidConduit(conduitKey, conduit);
            }else { c_0xec0e7bff(0xc74f12c93a72ceb04965e0821130192157719352ca2d8a5fe795f0641ea03c46); /* branch */ 
}
        } catch Error(string memory reason) {
            // Catch reverts with a provided reason string and
            // revert with the reason, conduit key and conduit address.
c_0xec0e7bff(0x192cf27fe4cc636820ccce763c674c76aedb49e1e95c08029559fa512e065137); /* line */ 
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
c_0xec0e7bff(0x567f9f427ef5f2087e0691501b873418b85acf9e9f26ab8b696187a0ad362a4a); /* line */ 
            c_0xec0e7bff(0x81813603e629478522c7697764507dc1f95f0749ae35f5a28a9802795b919414); /* statement */ 
bytes4 customErrorSelector = bytes4(0xffffffff);

            // Utilize assembly to read first four bytes (if present) directly.
c_0xec0e7bff(0x40b7f4428f3c558d5cb574020090f94cc6d3d88ade1913a3bf8c445d243dcd97); /* line */ 
            assembly {
                // Combine original mask with first four bytes of revert data.
                customErrorSelector := and(
                    mload(add(data, 0x20)), // Data begins after length offset.
                    customErrorSelector
                )
            }

            // Pass through the custom error in question if the revert data is
            // the correct length and matches an expected custom error selector.
c_0xec0e7bff(0xdf927693592ce8df5e5717aac2fcd8a1a86121f010f1e757b8e4bec3bfe47bc5); /* line */ 
            c_0xec0e7bff(0xd52c5afe401cc2c853d1b609acd70402d5ef8f42e1585c3e97e94a94e608afc8); /* statement */ 
if (
                data.length == 4 &&
                (customErrorSelector == InvalidItemType.selector ||
                    customErrorSelector == InvalidERC721TransferAmount.selector)
            ) {c_0xec0e7bff(0x705785bc6a6386eaee3560d26e34c08fccc46f9255962a5c8b0e2a442846859c); /* branch */ 

                // "Bubble up" the revert reason.
c_0xec0e7bff(0x9bd3809e981f3acf2084a47f04130e5905fdc97d749eb8c43ce23f97c6044b3b); /* line */ 
                assembly {
                    revert(add(data, 0x20), 0x04)
                }
            }else { c_0xec0e7bff(0x2c2fbaae24e440c9d4f53a3d7d223b7c20165191614054c44884d62b96e03b64); /* branch */ 
}

            // Catch all other reverts from the external call to the conduit and
            // include the conduit's raw revert reason as a data argument to a
            // new custom error.
c_0xec0e7bff(0x43afb51e5d7ad41383a94f4de8499e535ffc7069d8312930b9718427005d4f8f); /* line */ 
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
    ) internal {c_0xec0e7bff(0x815982fbc1d8a1ea4b4ac1a21721e81ade797802d4f0733e685f45f9a3f57d63); /* function */ 

        // Check if recipient can receive ERC721 tokens.
c_0xec0e7bff(0xee9eb5e09b595e8d19ebd17f2e6f368a629a9666c64f1365d1090bb1327be52c); /* line */ 
        c_0xec0e7bff(0x811ffd04f545275045a9d4cdb1a280767dbc73e1e9d3f0a8cdd5d3a666ddca82); /* statement */ 
try
            IERC721Receiver(recipient).onERC721Received(
                conduit,
                msg.sender,
                tokenId,
                ""
            )
        returns (bytes4 selector) {
            // Check if onERC721Received selector is valid.
c_0xec0e7bff(0x7586525ea7a70cc719b510ff675613de1ea4dc406e8949ce2fb89e162d125ba8); /* line */ 
            c_0xec0e7bff(0x3d27c3945b4ee27a2c9f4e32d9a784f326bdc427f3f65cebe55ef8a15289aa54); /* statement */ 
if (selector != IERC721Receiver.onERC721Received.selector) {c_0xec0e7bff(0xa00e028f27a884ac67cb0f462837a4ba6ba25e8611d069a5aa631d5ad88a8d5f); /* branch */ 

                // Revert if recipient cannot accept
                // ERC721 tokens.
c_0xec0e7bff(0x4a04935c43b77dda9e488c18abafb8f09ed6cc665f5dc6cd6b298735f66229d8); /* line */ 
                revert InvalidERC721Recipient(recipient);
            }else { c_0xec0e7bff(0x8c847e4f208c939d54c31c4547a6f208e83634626a1954a7f0dc3a47bc0fa0e8); /* branch */ 
}
        } catch (bytes memory data) {
            // "Bubble up" recipient's revert reason.
c_0xec0e7bff(0xa6d935992f219047d29e7cf768eaa20bf8dee6b791fbbc2bc48fddaf30479d2b); /* line */ 
            revert ERC721ReceiverErrorRevertBytes(
                data,
                recipient,
                msg.sender,
                tokenId
            );
        } catch Error(string memory reason) {
            // "Bubble up" recipient's revert reason.
c_0xec0e7bff(0x761e2b942c3a5b60c3f769a4a0057747b1c1bd13273a65331e364a83aef697cb); /* line */ 
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
    function _checkRecipientIsNotZeroAddress(address recipient) internal pure {c_0xec0e7bff(0x0a6be8d1c22e74850d4ed0c219d7ca105e8f5b31f8904ab556e6f02e0b4343a8); /* function */ 

        // Revert if the recipient is the zero address.
c_0xec0e7bff(0xa8c59b8bf7cb0981ccee82fd9f183d161f2cb420638f32d99f20e722983dba8e); /* line */ 
        c_0xec0e7bff(0x88092753e44f9bc7eef9c1b9969fd1705f0482fcf1dffa5ac41d0823bf59b88d); /* statement */ 
if (recipient == address(0x0)) {c_0xec0e7bff(0xe406fc206b9ff8ee567d9709e564837cad03309ca3909e65f8a13a48ee2167fe); /* branch */ 

c_0xec0e7bff(0xa3a1d7073f3e78e9c4e24b71765a8b49f8e5fd8ce226e701f8271b6eb2cc5181); /* line */ 
            revert RecipientCannotBeZeroAddress();
        }else { c_0xec0e7bff(0x422d6c170d8170c1dfc73894938e70d0219bf2e9c760f886e09d8e7a5efd1ae0); /* branch */ 
}
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0x0b8d9399(bytes32 c__0x0b8d9399) pure {}


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
function c_0x9d5190e3(bytes32 c__0x9d5190e3) pure {}


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
function c_0x826fae15(bytes32 c__0x826fae15) pure {}


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
function c_0xc0445f80(bytes32 c__0xc0445f80) pure {}


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
function c_0x4d51fc87(bytes32 c__0x4d51fc87) pure {}


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
function c_0xa1c00d81(bytes32 c__0xa1c00d81) internal pure {}

    /**
     * @dev Derive and set hashes, reference chainId, and associated domain
     *      separator during deployment.
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     */
    constructor(address conduitController) Verifiers(conduitController) {c_0xa1c00d81(0x969bbb73b279cb7876c11e37299ca85d56ef29d83623986db502cb87e2f73196); /* function */ 
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
    ) internal {c_0xa1c00d81(0x5ce19a03bcf3fc1abf8bf13b845a01d84438235e78800008d77701484acacd64); /* function */ 

        // If the item type indicates Ether or a native token...
c_0xa1c00d81(0x02f72078b5d9f033104b3ade6e71ef9635daff01ff939b15dabed1f0e0adf992); /* line */ 
        c_0xa1c00d81(0x0f759fd5912338cac0e3ca590d8e77f557013a08a9a5c1a88d52bb2662dc31e8); /* statement */ 
if (item.itemType == ItemType.NATIVE) {c_0xa1c00d81(0xb5f854291605f9af58080a44afc0713ac32c77b33030bfc8c40157f7d39e357d); /* branch */ 

            // Ensure neither the token nor the identifier parameters are set.
c_0xa1c00d81(0xba75db84d2348c8818d1e1de0fa7093bab8c313433c5732a322e3b5fb7adeaf9); /* line */ 
            c_0xa1c00d81(0xc8180af59d4b0d428ed650b35b1951026e97540796c2a7d25f8470498724a601); /* statement */ 
if ((uint160(item.token) | item.identifier) != 0) {c_0xa1c00d81(0xd53a9437bbcb4ee61b8872689934570cfdf2f4f2a93607d07edb3ee3786e1ec7); /* branch */ 

c_0xa1c00d81(0xaa0e323e3a427a3c61f954156cd65894f204c499fdc6af3481044e134c5996ab); /* line */ 
                revert UnusedItemParameters();
            }else { c_0xa1c00d81(0x02236cb48044e1cd120a730372702a3a28447de41f1a7aaa18bd9aafcd7510b7); /* branch */ 
}

            // transfer the native tokens to the recipient.
c_0xa1c00d81(0xc01f1ab96ff01c6a091d8a72e7d226001e5cf96a5779dd4dc4079a59ee5efeab); /* line */ 
            c_0xa1c00d81(0xdf2837595d0f8831f0f71e60d5a4860d1d4c534a457f1106dbc54df4b3532791); /* statement */ 
_transferEth(item.recipient, item.amount);
        } else {c_0xa1c00d81(0xf269d264f34c2a40cbfba18b16f50777a542c7cc3be6ab0bac8716dc68f69a46); /* statement */ 
c_0xa1c00d81(0x6f2074066676cc09650316d88d138ce5bfa1f10300b217118424f103e31a67aa); /* branch */ 
if (item.itemType == ItemType.ERC20) {c_0xa1c00d81(0xba33aa975e4fd83bbee2c3810708d221aa727553624be1cb4574cd1473a5abf7); /* branch */ 

            // Ensure that no identifier is supplied.
c_0xa1c00d81(0x301ed37aad93246afd5c690181b5a4e4a8c87abde85d83f40e43f25598faf34d); /* line */ 
            c_0xa1c00d81(0xaaf3a1444eba62d5b9ea14a9ccce2d7a54be7afb60f1da21f39fc7392049fcac); /* statement */ 
if (item.identifier != 0) {c_0xa1c00d81(0xff49804eca9426391c395a9fa30cbd61d43cb62310c57de4aadbf8c727f83c78); /* branch */ 

c_0xa1c00d81(0x5352814bffa9245118aa7c804de9bc292981bc39aceddb563901a00c5de9d834); /* line */ 
                revert UnusedItemParameters();
            }else { c_0xa1c00d81(0xe60cc330e0527a1c639dc57f58aea9c1e21e2ba9d40fa412cc02496f56e9d24a); /* branch */ 
}

            // Transfer ERC20 tokens from the source to the recipient.
c_0xa1c00d81(0xecc027aae948569df9cec2f368671c4fef8b394ee451a5a7233485b9c7959508); /* line */ 
            c_0xa1c00d81(0x5053d320d2dc98ad8661e3d4601ffe1bc30c27a4a0fae5b0452442323c3f770c); /* statement */ 
_transferERC20(
                item.token,
                from,
                item.recipient,
                item.amount,
                conduitKey,
                accumulator
            );
        } else {c_0xa1c00d81(0xb6cb3852f010a0ce6ff787eba26fab6e422e3d9b3e9360b236935f2b01cc8980); /* statement */ 
c_0xa1c00d81(0xa398cb94fa8a488d2b9aaa8991679524f92ccfa52caa517c4b9c73531fb3bf12); /* branch */ 
if (item.itemType == ItemType.ERC721) {c_0xa1c00d81(0xa8bfc982a9c9926098fd4a8b5893e68143a41a910cb817f872151567f7708dfa); /* branch */ 

            // Transfer ERC721 token from the source to the recipient.
c_0xa1c00d81(0xd3fa170e9ed34fe4f91a9bb0d3a881266df7ad61914d8a9a28b6816dfae1ab8e); /* line */ 
            c_0xa1c00d81(0x3176760e2d3704c67c48ff80a4b76c49efc4b95d04deb5aab89424f3624504e1); /* statement */ 
_transferERC721(
                item.token,
                from,
                item.recipient,
                item.identifier,
                item.amount,
                conduitKey,
                accumulator
            );
        } else {c_0xa1c00d81(0x217f1d660808e302a033ee05f7e8234f22446b0a50460941ef5f67ce85a43a59); /* branch */ 

            // Transfer ERC1155 token from the source to the recipient.
c_0xa1c00d81(0xfcae6b8cac285ca2ee5d396a994806c7405de4b077c7df1c066c0694eb3e0c34); /* line */ 
            c_0xa1c00d81(0xc9a03dcba4f56420ee5edcc49018565ba990838a9baa9aa0ee382384341eb12e); /* statement */ 
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
    ) internal {c_0xa1c00d81(0xa4710d654d0cf52186e055980b008143b818657015edef21561dfa8ea7cb4b52); /* function */ 

        // Determine if the transfer is to be performed via a conduit.
c_0xa1c00d81(0x4fc7ab0306b4c1d6560b3082575733db3e54a17b2d58bb530b24eea03ffe6772); /* line */ 
        c_0xa1c00d81(0x6860d0335fe5e410917681c6cd44b6609ec1721b5c309477ff57009c31523d3d); /* statement */ 
if (conduitKey != bytes32(0)) {c_0xa1c00d81(0x06eb83b316f698a3970db6ec108f157256be97a854ff8aac3e799f5480e74580); /* branch */ 

            // Use free memory pointer as calldata offset for the conduit call.
c_0xa1c00d81(0xe54601cb564afbd2e398090d77f72004748066f33e851aa068b717108c0a1edb); /* line */ 
            c_0xa1c00d81(0x3eefb7e3cb0df0a4fbd59e2fd8d2eebf672e671b87b0879eaba7389fad504486); /* statement */ 
uint256 callDataOffset;

            // Utilize assembly to place each argument in free memory.
c_0xa1c00d81(0x17aa8dfc9046bd81c2f8a09ab067605da66dca3f8087edd6e1f9de664fe8e5fc); /* line */ 
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
c_0xa1c00d81(0x3f70c0a42e634f7203faa9376c733d0e205185f9b16aafe6257595abeffddd69); /* line */ 
            c_0xa1c00d81(0x32904607e3fba904c55b08944811cfeb4567d3f3b27ac4f80eea1311e64ae42e); /* statement */ 
_callConduitUsingOffsets(
                conduitKey,
                callDataOffset,
                OneConduitExecute_size
            );
        } else {c_0xa1c00d81(0x93599415c6d9f7bc50c486d3968af5e6616485c8d86c8ad2ac768d5743870375); /* branch */ 

            // Otherwise, determine whether it is an ERC721 or ERC1155 item.
c_0xa1c00d81(0xf1e3b91d7e29b5abb56b52a4b6df58e0fd6c95ec1df446e40f5f6a9ab4d07e04); /* line */ 
            c_0xa1c00d81(0xd4bfbf7ed91d1efeb8db9673d704496712944178a66a0ec8d6e9e69b00b7c872); /* statement */ 
if (itemType == ItemType.ERC721) {c_0xa1c00d81(0x04c6dc637b9b98aa91820e3ca5eb0b292278ab7184bac34453bf5699744f7d54); /* branch */ 

                // Ensure that exactly one 721 item is being transferred.
c_0xa1c00d81(0xf3f2ba74522f126faa84c4c5e2d9cb98ad661b029bcfd877626bcb79864bfea9); /* line */ 
                c_0xa1c00d81(0x36ff4b423b8fd3dfa0e05498cc1de7c4204be30303d034fd47d871978d0bf6e5); /* statement */ 
if (amount != 1) {c_0xa1c00d81(0x773d74e1f1e0e7980cfa4577ed186f61c88f7115ebbf5b2959aa20bd3c2efe1c); /* branch */ 

c_0xa1c00d81(0xd719f15eb735247ba3fc756c8a7657189d60beb946ae1dfcd2378aa69355e978); /* line */ 
                    revert InvalidERC721TransferAmount();
                }else { c_0xa1c00d81(0x16392baa2c925afc0da5230e08fb90301eb0b9a22182990d5c570377ac542e80); /* branch */ 
}

                // Perform transfer via the token contract directly.
c_0xa1c00d81(0x1c74d441a7e8858bada227d836061ed0fd6c93ca080ab6fdbd3ad49d44f5d474); /* line */ 
                c_0xa1c00d81(0x842d38ebbaecfb5c9ea5f09508498ae13cd643e334c37863da275461c5552364); /* statement */ 
_performERC721Transfer(token, from, to, identifier);
            } else {c_0xa1c00d81(0x8ee358084654325f39f88c6de9f4d257af1924de20f5a130b83762803988f536); /* branch */ 

                // Perform transfer via the token contract directly.
c_0xa1c00d81(0xd25c389144be178431743491d6af10db83d534fd6d285231bbfcc9a36a1cbe5c); /* line */ 
                c_0xa1c00d81(0xabf5e3b4dfa4cd73ea1af12278aceb31438dbab4ce9c4870adb7c27793e2bc3d); /* statement */ 
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
    function _transferEth(address payable to, uint256 amount) internal {c_0xa1c00d81(0xdaa82317d82bec7528a52f9a77f05e93216b52d85720f5a7153972eef749fc86); /* function */ 

        // Ensure that the supplied amount is non-zero.
c_0xa1c00d81(0x9e8fcea2fbd871aeed6fe6b08c4e49f9f4263a71466c7356703d82d0cdb8ec80); /* line */ 
        c_0xa1c00d81(0x9d45396c120c70ab021fe7d0fd34ffacaa0ff65afb800f6112c19bd122853acd); /* statement */ 
_assertNonZeroAmount(amount);

        // Declare a variable indicating whether the call was successful or not.
c_0xa1c00d81(0x992aafb90a32a3e266782d693440c40fa84a9ebfacf9fb2e1e108bfe6ec2630d); /* line */ 
        c_0xa1c00d81(0x1c2f4cad452750323b253bd34383d0f02c869a0bcd407f04506d57e315be7dfa); /* statement */ 
bool success;

c_0xa1c00d81(0x401194db70df585ca3b1825aff64a438e58f2cd304f445b25fe6bf17bb38226e); /* line */ 
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        // If the call fails...
c_0xa1c00d81(0xd48a6e12089be97acd02b245db691380e3c1ed33dbaeff524308acb0f665e6fb); /* line */ 
        c_0xa1c00d81(0xbd1ba1e977ad625ca1beee4122c4942028660f6c0284fc2a366448ca1aadd8a7); /* statement */ 
if (!success) {c_0xa1c00d81(0x06d3f4eb2b4512e3667d6c2977248134b4d03915943b241ba72ec397a260bf1f); /* branch */ 

            // Revert and pass the revert reason along if one was returned.
c_0xa1c00d81(0xd037e3a9d138c8fb42aad42f85eb25c379e378bb21e51533034b7a7d22b201e4); /* line */ 
            c_0xa1c00d81(0xb1f4dba801627b2b8c682a6e585f457b1b889d6b80fed2f25eed9650e2f75782); /* statement */ 
_revertWithReasonIfOneIsReturned();

            // Otherwise, revert with a generic error message.
c_0xa1c00d81(0x31322f43484f7862528fd7aa20b710a7eb1f1057cdb2a8c0495d130a85de953f); /* line */ 
            revert EtherTransferGenericFailure(to, amount);
        }else { c_0xa1c00d81(0xb2eb42ad78b825329ce42e4a7304c460950f451ae69b56da09bd71e8316ef51f); /* branch */ 
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
    ) internal {c_0xa1c00d81(0x9a040437bc251c98d850190a33f93df0074b4aaa14d87fba8c71b6ddfdedd201); /* function */ 

        // Ensure that the supplied amount is non-zero.
c_0xa1c00d81(0x0dcde96fdd33f1b6f0535c334f5d5c03b742689e76be04461087d5c88f85467f); /* line */ 
        c_0xa1c00d81(0xab50a7257e8e2426d85ce8f038817ecd9cdea1530af4cad8a383a58c2e361b5a); /* statement */ 
_assertNonZeroAmount(amount);

        // Trigger accumulated transfers if the conduits differ.
c_0xa1c00d81(0xf3f454d190f76a72c955544d0f8861c5b07c5e8faf72d0f7a6f40081ab2a61a5); /* line */ 
        c_0xa1c00d81(0xa0759286a0aed407507fddb0af1235b14c03b6b922f2ca214d02599901890755); /* statement */ 
_triggerIfArmedAndNotAccumulatable(accumulator, conduitKey);

        // If no conduit has been specified...
c_0xa1c00d81(0x68ae3e0218ba4627a0183508f18fb3707178cbdcc4dbb392103b7f442058aecd); /* line */ 
        c_0xa1c00d81(0x3c9b39e4caf765a9d242f54112614aa271d44bba7a376c861d8919b8609cc36f); /* statement */ 
if (conduitKey == bytes32(0)) {c_0xa1c00d81(0x8b67d7a386f38c58ff9f3d64cef44dec43dc00e599fe17701e44e20f54988ffb); /* branch */ 

            // Perform the token transfer directly.
c_0xa1c00d81(0x8602792cadb9e5603227ad1157ec7d1686f5281e09fd0a17b25f00e8d36c3f7f); /* line */ 
            c_0xa1c00d81(0x7ff9d804bc9371698c0de1f723406bce8129681b713fde225fa00cf7601f5217); /* statement */ 
_performERC20Transfer(token, from, to, amount);
        } else {c_0xa1c00d81(0xbe1fc4d2d3b3b8afbe0e00fdf042d7fd99f1e81e560e6dcc1f471ecc075f6e74); /* branch */ 

            // Insert the call to the conduit into the accumulator.
c_0xa1c00d81(0xd89696157d035ebcd5eed2e5a52d354b338a1db7ce3f1611acf66f85f1c6ba22); /* line */ 
            c_0xa1c00d81(0x4f629a56a747049ffb4dfc097bd2faabc5bc09e1dc5fe29af45ba15c3105f827); /* statement */ 
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
    ) internal {c_0xa1c00d81(0x68d61c47e928b5cdabb4adc540e308d5fecaf250d384adca233979d662b5ed98); /* function */ 

        // Trigger accumulated transfers if the conduits differ.
c_0xa1c00d81(0xe389d5e79494ba59978ce3a2fcbec5df01cf93b1ec5625d9d9bee31386249965); /* line */ 
        c_0xa1c00d81(0x0b47aafdb70604a930dcf6d17ba7a8f1d7d1ee0be249d39831880c75d4266652); /* statement */ 
_triggerIfArmedAndNotAccumulatable(accumulator, conduitKey);

        // If no conduit has been specified...
c_0xa1c00d81(0xfdcfbaf63004656ac5937e6862fa9a1b3b86b4092ff7ec47169a0e1309560d3b); /* line */ 
        c_0xa1c00d81(0x13a2f2450f3030e5241cc377ecd0d0b8a60ddc52b51d8840ccfae24514dbc27f); /* statement */ 
if (conduitKey == bytes32(0)) {c_0xa1c00d81(0x002f834f355f1111116628368a8479272bedeb5e10179b8a2c4c9f5aadc9d79f); /* branch */ 

            // Ensure that exactly one 721 item is being transferred.
c_0xa1c00d81(0x6e929899866f9b3596d289949749a783f81bbe657eebae1525c918799bd7391c); /* line */ 
            c_0xa1c00d81(0x0bd33a6f9b80f34d93ec42be1e5215a2513f0f6787c27b25b81699aa723d4453); /* statement */ 
if (amount != 1) {c_0xa1c00d81(0xc24d58bf0f70209e8777c7e9cdff468588cadd094e838cdb85b6442b2f4baef1); /* branch */ 

c_0xa1c00d81(0x331577aa9b2b860d4437fb9e1d99690bb9c7242c5b774d0c9621dbca5a9ba34c); /* line */ 
                revert InvalidERC721TransferAmount();
            }else { c_0xa1c00d81(0xe90fd5c588ff0ce989959dc17b944c771fad5abf8a2bc72779c77239a693bf62); /* branch */ 
}

            // Perform transfer via the token contract directly.
c_0xa1c00d81(0x6916698d9de59c88a8fec6c73029bb2e286a3fa43b1c16edca20bc984a460899); /* line */ 
            c_0xa1c00d81(0xb06d8bae5864b69de6b4229acef791f16724e708e4ca9d8a28fe0880ffae8f0e); /* statement */ 
_performERC721Transfer(token, from, to, identifier);
        } else {c_0xa1c00d81(0x29c9c5cb1035e8c6f73de1b16545058ad9e8237203c0a43fcd1aecb9fa15bc80); /* branch */ 

            // Insert the call to the conduit into the accumulator.
c_0xa1c00d81(0xc0477c294550596393ad1cd14a9fda9f9da59709af2382820f25af5cb073715e); /* line */ 
            c_0xa1c00d81(0xf850b9c810290a57461a22adaf5891102f183c450a7fb77550ee1094e5fe5aa7); /* statement */ 
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
    ) internal {c_0xa1c00d81(0x3e4b7509b4e0092d69a0a12965d564d1e27285956ee1ac743e1fe52b26c062f9); /* function */ 

        // Ensure that the supplied amount is non-zero.
c_0xa1c00d81(0x9e5271faaa5c18ac98dc279bb0e2c0e9178cb162500a5f3f40f7a4fe1579a806); /* line */ 
        c_0xa1c00d81(0x202801e6a918464a4b5808575600ba148063be80dfdce4524956ec6a60e6ae5e); /* statement */ 
_assertNonZeroAmount(amount);

        // Trigger accumulated transfers if the conduits differ.
c_0xa1c00d81(0x20926bbbb40244a6302847ce634f40ded4d33126d20aee127f990b9026145815); /* line */ 
        c_0xa1c00d81(0x6a92350ba67682caf5159e391ff99ae026c3260a23b0181de8bc27ca7e322bf3); /* statement */ 
_triggerIfArmedAndNotAccumulatable(accumulator, conduitKey);

        // If no conduit has been specified...
c_0xa1c00d81(0x35fad7487be82fcf8711f9dcde0c8353fe76e8d41328fcde3d1abebe09680079); /* line */ 
        c_0xa1c00d81(0x78d544b1c0a44d854282655abff084aef2159a2e0c14bfa331539e16e4b399ae); /* statement */ 
if (conduitKey == bytes32(0)) {c_0xa1c00d81(0x6e83e2abd2d3c61dfeb2476a3b905ef481e6ffad9ee3e4c8bae2fe722f9b04d9); /* branch */ 

            // Perform transfer via the token contract directly.
c_0xa1c00d81(0xa9a764e20e62dd0c8e971617d6e04f727785628037329c1e070832f22b27d2fe); /* line */ 
            c_0xa1c00d81(0x054ae8a543fb1e999163a79e3c4d1db655f7e561a8be5c2d405e10954463cef2); /* statement */ 
_performERC1155Transfer(token, from, to, identifier, amount);
        } else {c_0xa1c00d81(0x2ea218691a6e4691b384e780a6ff3c333d2ee5ff17a2a6903bd3468c1f86e95a); /* branch */ 

            // Insert the call to the conduit into the accumulator.
c_0xa1c00d81(0x7ce0118063ade2e9830c3acb171fe8d62bb3fea5ee70ef8a3caeeb3e4b97d3f3); /* line */ 
            c_0xa1c00d81(0x13e0e410e5717ada20bc714be66d2abd1fb4554097ae72a6b720225dce7b3fec); /* statement */ 
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
    ) internal {c_0xa1c00d81(0x22ec0c0a87375cd8430e2e9a0f10f1a675eb5623711d9e0c7dbc7049abe7bdfe); /* function */ 

        // Retrieve the current conduit key from the accumulator.
c_0xa1c00d81(0xb716c25693770c195ece4aaff10d387efa18360b8f54976a6af26f77be57cc40); /* line */ 
        c_0xa1c00d81(0xf5c4de6500dcd431d2d7903ba4d9aab9797c4bb57dd54df3fcb8f80a374bea64); /* statement */ 
bytes32 accumulatorConduitKey = _getAccumulatorConduitKey(accumulator);

        // Perform conduit call if the set key does not match the supplied key.
c_0xa1c00d81(0x9f15314acf3a9edc8af643f7d63b6e46cd395196198f899a5d130b09c95eb953); /* line */ 
        c_0xa1c00d81(0xc7e46bb7943ec4d17dc5d13ebdbfa0a664a1f8d373c8d085e8c2d905eea3e31b); /* statement */ 
if (accumulatorConduitKey != conduitKey) {c_0xa1c00d81(0x1659914192fca61d640d0741a085f0bf0469fa9cd857e0781d2f5c19146c4875); /* branch */ 

c_0xa1c00d81(0xaeeca756518764f4882ad3ccd0d730ff91723308dd962d8b25b5f590255afe3a); /* line */ 
            c_0xa1c00d81(0xf9fc6c9f292a458522acfb24e14e0373c2f456a09c9890284a2d7f4ec900eabc); /* statement */ 
_triggerIfArmed(accumulator);
        }else { c_0xa1c00d81(0xadf25797c8ad53a42ad7655f55c87d925cd2d9329aacec76c7a08f5c15ae20ff); /* branch */ 
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
    function _triggerIfArmed(bytes memory accumulator) internal {c_0xa1c00d81(0xd0afb13fe5605619162575912e22c96b6f73d68826717c2bb9cba8b5547b4cc5); /* function */ 

        // Exit if the accumulator is not "armed".
c_0xa1c00d81(0x2b6e7baf206a9ee1dcd40f1965bab59a755999f31e9bd9b9aa4377385188b7a6); /* line */ 
        c_0xa1c00d81(0x24e425403fb32a8123654eac6d788b7154c3466fbc831ade328bd9c05bc8d335); /* statement */ 
if (accumulator.length != AccumulatorArmed) {c_0xa1c00d81(0x0cdbeca771149f7901e1075de5e56e107c4e4fb4cf024c7127aa3366e380347f); /* branch */ 

c_0xa1c00d81(0xc4a7a54c10b7602cb52840edd65e64e0aa9d561d945c828155b8acee2c1273bd); /* line */ 
            c_0xa1c00d81(0x522ed404101398f5e948fd5b9e87908da93a0fd5ab44c073251aece96474a74f); /* statement */ 
return;
        }else { c_0xa1c00d81(0x315c980222dcd6f5d295025486a0ec96e9d51ce2bcdfd63d51fb45b750204e4a); /* branch */ 
}

        // Retrieve the current conduit key from the accumulator.
c_0xa1c00d81(0x6ba3092e3b166d029e2e9627e76543acc662e847823883703543d89c74a0d147); /* line */ 
        c_0xa1c00d81(0x8898059c1807829cc4697f5def009584120e0905003165447db426dcade2b250); /* statement */ 
bytes32 accumulatorConduitKey = _getAccumulatorConduitKey(accumulator);

        // Perform conduit call.
c_0xa1c00d81(0x52347c33126af571cf8ac5ea71cdf4438c9fc54b6d5c02c4d2fff5e3c09477a7); /* line */ 
        c_0xa1c00d81(0x6de2a588a67de2d8f769117790d644c9059ff746ee862fbe7cc898ac16903ece); /* statement */ 
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
    function _trigger(bytes32 conduitKey, bytes memory accumulator) internal {c_0xa1c00d81(0xf6f48da3744d9d56785627bcb0270f82afc255ae080d76d782cf10f155915be6); /* function */ 

        // Declare variables for offset in memory & size of calldata to conduit.
c_0xa1c00d81(0xec1ad2f4cbf0ed66469a9ef0a8aedbe14633f67e105131b406b3fdff68cb1276); /* line */ 
        c_0xa1c00d81(0xa8b23d330851c4a82f858151b3ba9f9f91400eae8570edb59ed33a710f114757); /* statement */ 
uint256 callDataOffset;
c_0xa1c00d81(0x5808d343be4efc181ce412b8ea683effef7a22b52d5f139d81a3de865f0f5775); /* line */ 
        c_0xa1c00d81(0x5a1658651faefbd23aeb46ce76d23f057fd0bf485b8f5a06684356624efa6ee5); /* statement */ 
uint256 callDataSize;

        // Call the conduit with all the accumulated transfers.
c_0xa1c00d81(0xfe86128a70b8dc54b3a36ab57f0618d30c246000c5ca917ce4fe7d4d93899a11); /* line */ 
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
c_0xa1c00d81(0x89faa27ebca8cd9a7048295daf97b7fbbcfba5093336541133e4b95a860719da); /* line */ 
        c_0xa1c00d81(0x76e55bfe4fb506f9e98592a4884ff7c8b8178dd46066fee78bda3bb0e13bf8c6); /* statement */ 
_callConduitUsingOffsets(conduitKey, callDataOffset, callDataSize);

        // Reset accumulator length to signal that it is now "disarmed".
c_0xa1c00d81(0x3c27fbd7b99418362b3f4b88720c5efac0991663b2cb50e164457a8af031f97c); /* line */ 
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
    ) internal {c_0xa1c00d81(0xd98c39745e9f606850d27abf1408b89cdf5fc669c47f5ef24303e09a129406dc); /* function */ 

        // Derive the address of the conduit using the conduit key.
c_0xa1c00d81(0xdd27355536e6a91418fb5b2b079b8adbd72820f42862afaae4aa140276470b5c); /* line */ 
        c_0xa1c00d81(0xd60721ef6e88e428e71b5082df8f201cf009814592d6b7ae4c7b14fcd88f935d); /* statement */ 
address conduit = _deriveConduit(conduitKey);

c_0xa1c00d81(0x5513cb7476f0143998e5d421786ef45fd28ba50f3ec606f4a0a39f5b4024c18b); /* line */ 
        c_0xa1c00d81(0x9bf39981b46106bb0eef0a0d15af0fe0ad0c1e384b86e67f065729351ccee42e); /* statement */ 
bool success;
c_0xa1c00d81(0xd061ef4f496fd04441be1d54af940cc0c576c605f9f98262bb2997f71778afb0); /* line */ 
        c_0xa1c00d81(0xb4a6085f07c30b1902b62f65d6de759456b8e30c37e191220d005d1d395fa4d3); /* statement */ 
bytes4 result;

        // call the conduit.
c_0xa1c00d81(0x09bbcc2763f91e7bff21b23420bc2667482d388e287a9ba99141f4c603d8d1f4); /* line */ 
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
c_0xa1c00d81(0x61b6b9ab37ed5d2296345215d737c53a4719a3206ee10ff615d602e84280e30f); /* line */ 
        c_0xa1c00d81(0x36a818a07229b7ef0b6fc3c90878f633396c4ee5ae06d4261dcfa078bc5b0647); /* statement */ 
if (!success) {c_0xa1c00d81(0x870ddcb318dc88ccb4f7fa32d174817aaf4cce73e2dace25665aea98a5798eed); /* branch */ 

            // Pass along whatever revert reason was given by the conduit.
c_0xa1c00d81(0x5012bd72f7baa17a50ba42cd653d7f44d3eb48d1f550c3c93e2e41bf2d9bd900); /* line */ 
            c_0xa1c00d81(0x2411e2ecb9c4c6a632e86eaa80178dd8a784fef3cda88ac56c7fd2d4616901e1); /* statement */ 
_revertWithReasonIfOneIsReturned();

            // Otherwise, revert with a generic error.
c_0xa1c00d81(0xfa6a50c417f366d3a96c87331f888e6cbf776294838221cd085a26834e2f8a83); /* line */ 
            revert InvalidCallToConduit(conduit);
        }else { c_0xa1c00d81(0x9f86dc1247c19beda548cee78ed6a7a641514e089da9502b56070b187664b401); /* branch */ 
}

        // Ensure result was extracted and matches EIP-1271 magic value.
c_0xa1c00d81(0x7302552d6a2077f48eeb806d7e63813fd03b018eb004259ae19da32e4926ce61); /* line */ 
        c_0xa1c00d81(0xdc6073b7463de20dca151f65bcdc5d50132c4680d53628a4d6fbf8b2c7ce9f38); /* statement */ 
if (result != ConduitInterface.execute.selector) {c_0xa1c00d81(0xe47186f7eadd550e97e686453c3c3a5b1d3a80ced92388d508c983acdaa5f0ae); /* branch */ 

c_0xa1c00d81(0x4764300febbb97ea5dac0f8b3d1b2ae37e18882ebf819fd00774bf38af6ad4eb); /* line */ 
            revert InvalidConduit(conduitKey, conduit);
        }else { c_0xa1c00d81(0x169c741ca9fac3577f0596b4695f1fbf7c4c31beaebb4d086697d4a191360e0a); /* branch */ 
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
    {c_0xa1c00d81(0x2dfe04c3c14c41b4b46d85b79ae91cf9f51492f1748b270fc9f43e0de06c4b91); /* function */ 

        // Retrieve the current conduit key from the accumulator.
c_0xa1c00d81(0xd142eaf53fa92b1b9d0b1a9cb8a5bdb695b3c9b2268e3b91f8bedeeaed32e46f); /* line */ 
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
    ) internal pure {c_0xa1c00d81(0x0278fe17a126a0f05ea81849f1795ca818d237d93f2bd2f0e84f1747ead55e32); /* function */ 

c_0xa1c00d81(0x0101e9a1e1ee7e70acbe9b8f2824941927535d350d74388cbf9d390a6264ffb6); /* line */ 
        c_0xa1c00d81(0xa8ce81e23a07851c190c5b14852eebba7c0e277d600ff5e0ea9dfab09cf0fcbe); /* statement */ 
uint256 elements;
        // "Arm" and prime accumulator if it's not already armed. The sentinel
        // value is held in the length of the accumulator array.
c_0xa1c00d81(0x94915bb5c276ddb1b5be2c972ad0af9acdabb963e9aafe0efcc26a7cb279c7fb); /* line */ 
        c_0xa1c00d81(0x410d709129c44f323bd30c2fecaa777cf1c292e0151cfca8eda60f5324059b27); /* statement */ 
if (accumulator.length == AccumulatorDisarmed) {c_0xa1c00d81(0x8d68877c451abb9bf92b98902e691cdcec28ad0dbcd75d180792ea6047aa3d0f); /* branch */ 

c_0xa1c00d81(0x9bc77d3ad438ec56b34f0f0cd5ba46e4eb404cc59565073b3fb6ebdb5f5b7970); /* line */ 
            c_0xa1c00d81(0x19dff2652bc05c5d0a5d7dd047083978ba0c6080f2e2dc3fbfba84ce2ac493b9); /* statement */ 
elements = 1;
c_0xa1c00d81(0x20599f61b713c08f3aeb91afb8a133efc962a983f4a01cd2e8b20474c0c66292); /* line */ 
            c_0xa1c00d81(0xc65423748128e862e4c72ef636f324c4139500d05b2e4fb26485f7de2ab31f64); /* statement */ 
bytes4 selector = ConduitInterface.execute.selector;
c_0xa1c00d81(0x830ee262b5dc6a9d2df71e37955b9db1969e8c1180811f00c73bd230cff2ff63); /* line */ 
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
        } else {c_0xa1c00d81(0xbb537ad520b4f66d47878bf030eb491fcd6e5c48a18fcbd79295a19426d20c9d); /* branch */ 

            // Otherwise, increase the number of elements by one.
c_0xa1c00d81(0x09d427c7508f427324010a599dc1a559e88ec35a4593d6e2fd4660d53c05d5f8); /* line */ 
            assembly {
                elements := add(
                    mload(add(accumulator, Accumulator_array_length_ptr)),
                    1
                )
                mstore(add(accumulator, Accumulator_array_length_ptr), elements)
            }
        }

        // Insert the item.
c_0xa1c00d81(0x74363d622b13fe74fee3e5c35b77e157cce42807039f025c28754eace6474cb9); /* line */ 
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
function c_0x4d3358a3(bytes32 c__0x4d3358a3) pure {}


import { OrderStatus } from "./ConsiderationStructs.sol";

import { Assertions } from "./Assertions.sol";

import { SignatureVerification } from "./SignatureVerification.sol";

/**
 * @title Verifiers
 * @author 0age
 * @notice Verifiers contains functions for performing verifications.
 */
contract Verifiers is Assertions, SignatureVerification {
function c_0x52b12c65(bytes32 c__0x52b12c65) internal pure {}

    /**
     * @dev Derive and set hashes, reference chainId, and associated domain
     *      separator during deployment.
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     */
    constructor(address conduitController) Assertions(conduitController) {c_0x52b12c65(0x6b6ba5723110cbf61e60bf96c0ff3ef382fcff3b1cd1e92bada613f16a418ce7); /* function */ 
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
    ) internal view returns (bool valid) {c_0x52b12c65(0xa9d485306781a80734a5a9db3f998ea6154cbcd32fcdf5af8907f7443e6a61db); /* function */ 

        // Revert if order's timespan hasn't started yet or has already ended.
c_0x52b12c65(0x2c7339db943c55eab42781eaf53c4855285ebc1e0b6eeb0306345f12d1d01596); /* line */ 
        c_0x52b12c65(0xf7f6ecee4e1e0e4a44cc0d2b2e1decd8ea1677ae9880caaf2896163dd44168ce); /* statement */ 
if (startTime > block.timestamp || endTime <= block.timestamp) {c_0x52b12c65(0xe6ca85115006292dfad0a3705e8e73a6d0f77fa455e977a9dc5fd093608c1246); /* branch */ 

            // Only revert if revertOnInvalid has been supplied as true.
c_0x52b12c65(0x8f4ac7f3d19ec5bbc91f7a00aaa639836ae2f23ff0c88b69aff7f3dda0f2943d); /* line */ 
            c_0x52b12c65(0x1224c925ac82ad6d19f6852b4b9c522c678c9f9f9e69583c5222885338f7f67c); /* statement */ 
if (revertOnInvalid) {c_0x52b12c65(0xb631312ea81bfc93d4529a8cf3d96af04f31ebc9ae6a8133f15619e384849ea6); /* branch */ 

c_0x52b12c65(0x93845a738fc6d07320293601bcf9e995dc44cd41f7af13a18779d1c4f6a4e421); /* line */ 
                revert InvalidTime();
            }else { c_0x52b12c65(0x1ccd4e75a8809df134f06abfa7b64d298f32f6f9bfcc031891d77d37aa2e7f24); /* branch */ 
}

            // Return false as the order is invalid.
c_0x52b12c65(0xe627b0ab4d4a1f8ef6825c87a9ddcfaabc4503db9329a0ffa5995565b5d120a7); /* line */ 
            c_0x52b12c65(0x4a2f6514b67aae1618f202ff40bcc895181e10e608c662de3a17fc796f45f3ca); /* statement */ 
return false;
        }else { c_0x52b12c65(0x8c2a4fba08dd9e3622ee43b9e609e91e6930298c3f6646040995fbba030be66d); /* branch */ 
}

        // Return true as the order time is valid.
c_0x52b12c65(0x76ec85a66137748ddedfa2017c25ec140d69fe55655efe6e8fd688b9d7d57759); /* line */ 
        c_0x52b12c65(0x19ba25dc105e36955c9b2c7bb01df01dcac60b90d817448b8e507af520614a9d); /* statement */ 
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
    ) internal view {c_0x52b12c65(0xd66be15e9dfaaacb3fda4efbc598b8666284b8e43dd4b57f04103123bd0623ca); /* function */ 

        // Skip signature verification if the offerer is the caller.
c_0x52b12c65(0xe9612496833153a5611d95d819e37a45467a98e79e28cf49dc1e35d78d72f4c1); /* line */ 
        c_0x52b12c65(0xb05cf897babfec4b3549e70c727c6cd5600936de429c5e7e9523f95c300c7323); /* statement */ 
if (offerer == msg.sender) {c_0x52b12c65(0x640001b6c56b1bc9b8e71c0fd2316f41cfe321c57ec44a0d46e04930f73e1a23); /* branch */ 

c_0x52b12c65(0x003713104458f6bd4c766498bdc55278a3f38c41712f370f9a36f538bd4fffd5); /* line */ 
            c_0x52b12c65(0xe6dfaaf0224d3059893d6e91d46174575c06526c330ca4490407e9f5c08785ea); /* statement */ 
return;
        }else { c_0x52b12c65(0xcd1107ccb640699f6aa1fd0e8b8cd160b8cada7a7c22fdc0579ad158428d287f); /* branch */ 
}

        // Derive EIP-712 digest using the domain separator and the order hash.
c_0x52b12c65(0xb19b1c38db0656524f67d6a98e8060809314e4a8e8b88125c63e90fbcc4da0ff); /* line */ 
        c_0x52b12c65(0x8dfb062b3b582ad7ac6f3ccd218443a754fba21eb4eb91569add13fa05e5528b); /* statement */ 
bytes32 digest = _deriveEIP712Digest(_domainSeparator(), orderHash);

        // Ensure that the signature for the digest is valid for the offerer.
c_0x52b12c65(0xfc7343ea9dc402397bf43cb7495a7f3d579a0bf781eef05fb471e957fe71d88d); /* line */ 
        c_0x52b12c65(0xd083f96c0a4c5ad438f11dedf5f439c0867a745d89bac45c12360c3d25ac9a72); /* statement */ 
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
    ) internal view returns (bool valid) {c_0x52b12c65(0x778732ae1cb503ebc7fc3bb6893043fbb62ccdae614636194cc3ba71f63a5591); /* function */ 

        // Ensure that the order has not been cancelled.
c_0x52b12c65(0x6f411df8590c463f2ad0d665a33ce09dce619cea5aae77d240e5f953c865e6e0); /* line */ 
        c_0x52b12c65(0x1fed505a45cd484842a5655ec56e5af0964d742b10153a0742f90ec2fb128672); /* statement */ 
if (orderStatus.isCancelled) {c_0x52b12c65(0x19bebb92940712ada17b9c12b3addefad6eec36de1e9a4e2bed8f861a5a1ef18); /* branch */ 

            // Only revert if revertOnInvalid has been supplied as true.
c_0x52b12c65(0x8936cbe6b967d13856b9720b042ed74563aae08287669308697d064103fa476a); /* line */ 
            c_0x52b12c65(0x1f375db618a1416e08b397088c172383e9d6a8d5edd8275ab896418b480c2c63); /* statement */ 
if (revertOnInvalid) {c_0x52b12c65(0x40c180241bf9a52fe29a95bc16cafde3906c6fc1137a32cbd7ccdfbc781339b0); /* branch */ 

c_0x52b12c65(0x48bb4a99334ce9611e30df8c70723be94856cf0122566214b2ee8c0e0cd33287); /* line */ 
                revert OrderIsCancelled(orderHash);
            }else { c_0x52b12c65(0x71bcf1a7d9f1aed7a3bcd43ff56fd472c8ea27964fab6aacaec509699d852690); /* branch */ 
}

            // Return false as the order status is invalid.
c_0x52b12c65(0x7de9881098d8bd76409a41f18c53b6739d088d7477014c3da9aa5a973c9c35ef); /* line */ 
            c_0x52b12c65(0xbfd84628018f25372faee8f980c5e3d59b4f279bd5faa19871365ab379814eb9); /* statement */ 
return false;
        }else { c_0x52b12c65(0x84780f3d0cbdb778fede196e1c02dbf90098d20a3035f10bf12f3694ee1c4017); /* branch */ 
}

        // Read order status numerator from storage and place on stack.
c_0x52b12c65(0xbf351bd1abf3b653f3895735d2145e14abb97ce99434228378c03ee78121b734); /* line */ 
        c_0x52b12c65(0x32c335a7bd1495bc450ee5067c5deec7b7b5c3a9510c7ec51c43c7f5e6b00541); /* statement */ 
uint256 orderStatusNumerator = orderStatus.numerator;

        // If the order is not entirely unused...
c_0x52b12c65(0x3643003034f196a2388586c613adfd60c37da2b622af0e4bea9f9a3d2354638e); /* line */ 
        c_0x52b12c65(0x7082e805e7cc9c635453dc2a46eea2ec22b2b6d71cb1f74764aeb0a7d048f5c4); /* statement */ 
if (orderStatusNumerator != 0) {c_0x52b12c65(0xf4a9bbdc684b271a2c3a83276aeb88dfb703e9444b68bede6827ef2c1eaee6d0); /* branch */ 

            // ensure the order has not been partially filled when not allowed.
c_0x52b12c65(0x5fbc6a65a8b7d8ab945fe587ac11d52a3caaedb16900c549d4c9322b3856babf); /* line */ 
            c_0x52b12c65(0x57fe32d65874e1628ce29d4836383cd74791c099f53c6ed3230c1934f8dc3bc8); /* statement */ 
if (onlyAllowUnused) {c_0x52b12c65(0x0fb331c129ba1a76ae7e6c7ddd787419286caab36103a0cd98b7894045d4992e); /* branch */ 

                // Always revert on partial fills when onlyAllowUnused is true.
c_0x52b12c65(0x768da170f83a2ced6eb2f86b829dbe0e09a0d552daf724814c215c67cebb4077); /* line */ 
                revert OrderPartiallyFilled(orderHash);
            }
            // Otherwise, ensure that order has not been entirely filled.
            else {c_0x52b12c65(0x4227e727c8a6f5a03771581ebd26fb2bb28c4ba48546398d3ec04414582819e7); /* statement */ 
c_0x52b12c65(0xf22d0c266e84547bd493ee40bd57c6cb891a99fc010056200e9e12ad6b9a25bd); /* branch */ 
if (orderStatusNumerator >= orderStatus.denominator) {c_0x52b12c65(0xc10e5782235a88f5b8c8d2686fa32dbd35414b7ef15ef8813d179f5acbf6b5aa); /* branch */ 

                // Only revert if revertOnInvalid has been supplied as true.
c_0x52b12c65(0xb3a113e1f4d05e0d658b2ad737991e71559f6c7d13b27c208a086d04d5ecc3d6); /* line */ 
                c_0x52b12c65(0xc7f9048f0f62a53f96e23c10c149674e1ac69fb7d6988f915a50609dc23ad863); /* statement */ 
if (revertOnInvalid) {c_0x52b12c65(0x3b0fad0a38959bf8c73f0e86ab300b701661adf11719d6c144cdcd6e094ce0ec); /* branch */ 

c_0x52b12c65(0x3c025f979ae09760ba3e97dc1813530de7f37aed84eab2574703948fa89237c1); /* line */ 
                    revert OrderAlreadyFilled(orderHash);
                }else { c_0x52b12c65(0x0e830e3801d46ff54a7dbebb6f30192f62a15672b4ce40d507bd1bf1b80f2dfb); /* branch */ 
}

                // Return false as the order status is invalid.
c_0x52b12c65(0x90c0e3e1799fefea4124f1426fe49e8fa64107678fe31fbdc1a817df31ae75cd); /* line */ 
                c_0x52b12c65(0x3741cf971fd62f6dfcc3024f35658f79df0fc71fd29ff9b361d106165b1a37b1); /* statement */ 
return false;
            }else { c_0x52b12c65(0xce9d9a824f399ef260725f4ecc04f0554a775ebec8be9685110eb18e2851889d); /* branch */ 
}}
        }else { c_0x52b12c65(0xf6304166e0a6055e776cd918e618a2a3f02b756c40059976f1722abcedc6cd80); /* branch */ 
}

        // Return true as the order status is valid.
c_0x52b12c65(0xdfc5132beb959b89c6509424ce6de1310feb130e12d6986fe9f98d27c7ad2d8a); /* line */ 
        c_0x52b12c65(0xba5acdaf5d2f088164c41a1cf85b240b93d993cbd1ed6bc49b56bfa379abb4f3); /* statement */ 
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
function c_0x0808bb3d(bytes32 c__0x0808bb3d) pure {}


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
function c_0x08ef1d49(bytes32 c__0x08ef1d49) internal pure {}

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
    {c_0x08ef1d49(0x6fbe96bcaff392c68ce145c1bab843bebde45d27c0813c3f14df0918bb9fb449); /* function */ 
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
    ) internal view returns (bytes32) {c_0x08ef1d49(0xa2678c71997a1124594a0e290503c3e37aa0b1b5391b3284d099c15387c43db7); /* function */ 

        // Ensure supplied consideration array length is not less than original.
c_0x08ef1d49(0xa5c2c6e7798388227e4c189146b9c6180aeff3bcdd86a56be61a6ace131d0195); /* line */ 
        c_0x08ef1d49(0x1846e12e2e6fc621152c89a993fc0459b11b4dafae12967b241be92696f0e6c2); /* statement */ 
_assertConsiderationLengthIsNotLessThanOriginalConsiderationLength(
            orderParameters.consideration.length,
            orderParameters.totalOriginalConsiderationItems
        );

        // Derive and return order hash using current counter for the offerer.
c_0x08ef1d49(0x27ed2c91f2c3e441e30169c0b9bf9dfebf94481e038b42d7877d837cf142f32e); /* line */ 
        c_0x08ef1d49(0x52c3f8905315dbab360c4e62d7e4a141a5c460079a80e71d1872e505b2c74fe5); /* statement */ 
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
    ) internal pure {c_0x08ef1d49(0x2ea82da33599b3d62cc15131fdc3ef42b0b7bd723feffb6b44a7b6e952ca8aa5); /* function */ 

        // Ensure supplied consideration array length is not less than original.
c_0x08ef1d49(0xd2346e9d2c2c5ff7af2ab2767f53b66a81408775e087cd19e36acfdf0555205a); /* line */ 
        c_0x08ef1d49(0x259a47f6a2cb129d03840a3c634a3123eae3739ec0e6e7b96c461c9d49bd817b); /* statement */ 
if (suppliedConsiderationItemTotal < originalConsiderationItemTotal) {c_0x08ef1d49(0x9c671e14cea183182a4d4233207365b8d4973d175f3d4bd822a22d9ca9e93983); /* branch */ 

c_0x08ef1d49(0x65600869886ce492fba8f45188c76de3b24dd388b9a645044f349b96d83a86e1); /* line */ 
            revert MissingOriginalConsiderationItems();
        }else { c_0x08ef1d49(0xb5b89e80d6e961abc84345869020a72557e86a12a1574a1b03ff4de4071afec5); /* branch */ 
}
    }

    /**
     * @dev Internal pure function to ensure that a given item amount is not
     *      zero.
     *
     * @param amount The amount to check.
     */
    function _assertNonZeroAmount(uint256 amount) internal pure {c_0x08ef1d49(0x29044ad820be7545554942729860fcadf918800989c6895c77b0581f44ff6205); /* function */ 

        // Revert if the supplied amount is equal to zero.
c_0x08ef1d49(0xa7e3b054323c9782e6886447a1bfd487b9bf51e7b3013cf5963aea6eebc54da9); /* line */ 
        c_0x08ef1d49(0xc76d1ac66e5a44f3e8971f0b76fbc3471c6b066277f93a1f56c3155532ecb2a0); /* statement */ 
if (amount == 0) {c_0x08ef1d49(0xbcddc46744e6b33908c47d6aa3ab823b7b00835b75815ad0cdd434ca19714ff2); /* branch */ 

c_0x08ef1d49(0x5d80335fa1cc0f26d80cdd5c8c811b8a81915de966b56cfa9d4f2cd8e5d43091); /* line */ 
            revert MissingItemAmount();
        }else { c_0x08ef1d49(0xaf93f1a1aecf73e4c111c05f069fdad75c530c3f5c23cc06510a9b0b169e6456); /* branch */ 
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
    function _assertValidBasicOrderParameters() internal pure {c_0x08ef1d49(0x572991841a2b8bbd3e017c471bab6ea34cc2dad9361bc9f5701ee3145fe06202); /* function */ 

        // Declare a boolean designating basic order parameter offset validity.
c_0x08ef1d49(0x7ff674a810cbef0fbd10549d14251d264e7eed4977b003b67f89551f4310eef1); /* line */ 
        c_0x08ef1d49(0xc339aa4455fe8526df5fb1a1a441b6c9e557e768ca55736449ba66e192e1b799); /* statement */ 
bool validOffsets;

        // Utilize assembly in order to read offset data directly from calldata.
c_0x08ef1d49(0x6e2391110b516dfa4ba52e1eeea9ec86e16568d4a7933ec7f5d0ac4a69b6e12f); /* line */ 
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
c_0x08ef1d49(0x5ffad8e4badfee51b7ef0df14f3835054d3bd1a8e6ebe92510a4489c36abdd17); /* line */ 
        c_0x08ef1d49(0x48bb488b8c2052af209d68c180dde9bb7b1387467b0982028362ba50e5ca7641); /* statement */ 
if (!validOffsets) {c_0x08ef1d49(0x895b774736509f049d25256e5dbad9541c4807dc16abc1b68890ef2da44f0ffe); /* branch */ 

c_0x08ef1d49(0xfae8ad793e241f870c663b6054c9adba68b590e6591fb5fb06688ec7ca10cb79); /* line */ 
            revert InvalidBasicOrderParameterEncoding();
        }else { c_0x08ef1d49(0x73a82483259df91ff878ad7c65544c7db996a6203b26db80aa7d78ef07161500); /* branch */ 
}
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0x31ad5cb5(bytes32 c__0x31ad5cb5) pure {}


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
function c_0xa47d8e50(bytes32 c__0xa47d8e50) internal pure {}

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
    ) internal view {c_0xa47d8e50(0xcae70fbd6657de6f95507ac68e652d43cc98e97874400afd280d4c761353e150); /* function */ 

        // Declare value for ecrecover equality or 1271 call success status.
c_0xa47d8e50(0x1f329be1e5e190f3a4e3c42b609b10634091479126d34191ccaf8ff60facafb0); /* line */ 
        c_0xa47d8e50(0xb0fef9ed3c6477b375d43f73fd85521a3ef156ad7ea26d1916e0fc76868a8424); /* statement */ 
bool success;

        // Utilize assembly to perform optimized signature verification check.
c_0xa47d8e50(0x551296dbe39c039c637609e1118a434cf1ee5e76ce9ab47a060e91fe5b3fe339); /* line */ 
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
c_0xa47d8e50(0xcecc626cd7c964b00c440d0a446c246714ed208d7c20317aa5b458796a29eef0); /* line */ 
        c_0xa47d8e50(0x6b60088841b9082f9a764818bf71e1e807d7d9560a5c4cdf172c6f0e097dabd8); /* statement */ 
if (!success) {c_0xa47d8e50(0x0f3198d5a26cdca042820bcdd6be6d864659ba9f0109b6c6bd19d6701af4cdd3); /* branch */ 

            // Revert and pass reason along if one was returned.
c_0xa47d8e50(0x8545b528058b139dbe2e57c5f59e78c4a739280e78c7f7f84ecfebba218b63b7); /* line */ 
            c_0xa47d8e50(0xa9f277798d774efbb94a5460fe295fcf38a4ca55bfe2e4c64724cc1e5bfff2e0); /* statement */ 
_revertWithReasonIfOneIsReturned();

            // Otherwise, revert with error indicating bad contract signature.
c_0xa47d8e50(0x85bd40a3365916311099b465b28471a7e35fcae3bc41a13bea3975d41a35f1bf); /* line */ 
            assembly {
                mstore(0, BadContractSignature_error_signature)
                revert(0, BadContractSignature_error_length)
            }
        }else { c_0xa47d8e50(0xf1af3735432a7a43971f5d0dc2a42d0a11114059c076d09100778aea1ac38db7); /* branch */ 
}
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0xfbaf4a7c(bytes32 c__0xfbaf4a7c) pure {}


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
function c_0x5875a93f(bytes32 c__0x5875a93f) internal pure {}

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
    {c_0x5875a93f(0x738b226c832a909d68f7159e6ce8ffc1319ed46fabf7ab0f65227056ac1d0aa4); /* function */ 
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
    ) internal view returns (bytes32 orderHash) {c_0x5875a93f(0xa5b042743c0c8d9cb3fa6974d89e58f7294f8a02315d5accdc8861d01581cdad); /* function */ 

        // Get length of original consideration array and place it on the stack.
c_0x5875a93f(0x2a41396e1e145341d25f5c774cb85d1dac09d9bd902dd1b78a7dbcec6e666880); /* line */ 
        c_0x5875a93f(0xd0646a3d70d8fd0b445b39f2f3b4d7ff8dbb58dbc5280d5f3b78a346ca6d6452); /* statement */ 
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
c_0x5875a93f(0xaa9269b330147735cd4cb243c840e84665a5fcd23c876150c1f86e0bdb0549de); /* line */ 
        c_0x5875a93f(0xfc1943e9985e87af9b391c5672c5069b2e049d1800cdfb6cf2c0f02fd7b8ea3a); /* statement */ 
bytes32 offerHash;

        // Read offer item EIP-712 typehash from runtime code & place on stack.
c_0x5875a93f(0xcd601ee98d289e28e5b499544d5326d4d280fa96b9f750d54749e30d9cf68ba4); /* line */ 
        c_0x5875a93f(0x83c8f395212bc86f4a91468af1a95e239b90070f8cff959d18e6241afbebdf4f); /* statement */ 
bytes32 typeHash = _OFFER_ITEM_TYPEHASH;

        // Utilize assembly so that memory regions can be reused across hashes.
c_0x5875a93f(0x572062117a1adf6aa50b71f052b4c69b34c4d85071a77cf6e571a1f9935fa906); /* line */ 
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
c_0x5875a93f(0x7f3c7da8df26d5df8654cd1b1bc631ff8fbc0d3778e35ee33af954213b8f3bcf); /* line */ 
        c_0x5875a93f(0x295cfd127c19ed28c94fd02711a65d1f0926f0a45b55e556cebd772bd241c9b5); /* statement */ 
bytes32 considerationHash;

        // Read consideration item typehash from runtime code & place on stack.
c_0x5875a93f(0x1bee1ce51057b7ba7ee60df2ee43a495ba1a98d35ca56eb516f3bcb2866991d8); /* line */ 
        c_0x5875a93f(0xa0d72191e77faa5d98f0dc573ac182b042bdd45dd0c359e532bcf3f82744495f); /* statement */ 
typeHash = _CONSIDERATION_ITEM_TYPEHASH;

        // Utilize assembly so that memory regions can be reused across hashes.
c_0x5875a93f(0xba67b3c7dced90b0dc5f70bd94f0b91f5973cae037742eeeeab14f7ed4e87fc2); /* line */ 
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
c_0x5875a93f(0xa2be32b9b389ed8cccb0a403f537c566e34d517062b96ec1540cd19b8db18936); /* line */ 
        c_0x5875a93f(0x586ddd83bb72da077dbe76b4ddf22946f38eaf93795237b056c2b20cf74240a7); /* statement */ 
typeHash = _ORDER_TYPEHASH;

        // Utilize assembly to access derived hashes & other arguments directly.
c_0x5875a93f(0xe2506f21acbc22fedab4644706399b8143d6fe87e5bf803ee48b3fe39421fc66); /* line */ 
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
    {c_0x5875a93f(0xca42456b4f549db57980153d1dd09e87d1fdb3d5ccc4d87afb8ec9ab15ed8507); /* function */ 

        // Read conduit controller address from runtime and place on the stack.
c_0x5875a93f(0x0f970c6dd28be172e6131443ed874bf968037d0fef6726500365ccb53003b685); /* line */ 
        c_0x5875a93f(0x7758a9c52f857ea5167f86859fb94155851c0399ed262cd1d34208a8e28039c3); /* statement */ 
address conduitController = address(_CONDUIT_CONTROLLER);

        // Read conduit creation code hash from runtime and place on the stack.
c_0x5875a93f(0xe1d45eaafc9a462b6b60ab94ecb582f8b32d5bc92e041b280cfe03ecc5a1b28f); /* line */ 
        c_0x5875a93f(0xdb42909139b7d74a71bb1ea6216fd36169bfe029d711431429ee4c06637d6b25); /* statement */ 
bytes32 conduitCreationCodeHash = _CONDUIT_CREATION_CODE_HASH;

        // Leverage scratch space to perform an efficient hash.
c_0x5875a93f(0xd31d87aea13f5270957e5280516be7943ec8e882aedbccc94bf751e25aabeb14); /* line */ 
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
    function _domainSeparator() internal view returns (bytes32) {c_0x5875a93f(0xd13c68629a25feef4df8ede641721e16aa22edf8bb8c9b7d8f4a30acbcb8d216); /* function */ 

        // prettier-ignore
c_0x5875a93f(0xb09114fec75f50373e32df74b823de3418eaaa0ba82c07d9769d827016f1d99b); /* line */ 
        c_0x5875a93f(0x96ef11180bdda8844cc6dd55f84be42c868b707a2604061826d148250c23b706); /* statement */ 
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
    {c_0x5875a93f(0xd0429ac491b0f9ab2302ccb437e2bb9a11eb2643ab136c911506beb81221c089); /* function */ 

        // Derive the domain separator.
c_0x5875a93f(0xab47cbd28396deb6bf6c0c0deb9e0d417c7f9c5abaf2b4c23b5630ca1265ad35); /* line */ 
        c_0x5875a93f(0xbdf0ebf9c5c090631f28543c877832afb7d96a7dde0a15c0629ebeb3c2893f66); /* statement */ 
domainSeparator = _domainSeparator();

        // Declare variable as immutables cannot be accessed within assembly.
c_0x5875a93f(0xc4780fc88c58d4a0cea59dbaa9aff8c591010275c6c45639b8e7262971c0b951); /* line */ 
        c_0x5875a93f(0x359b86eafe60c8b8546a53abcea8641c736f9fc1744602f444b960d5452e7050); /* statement */ 
conduitController = address(_CONDUIT_CONTROLLER);

        // Allocate a string with the intended length.
c_0x5875a93f(0xb2fe6ddfcdf0c5e8b63793ba50a504e75df623d3db75d2f6ed9a4f16e32d2eda); /* line */ 
        c_0x5875a93f(0x02293fd7299a015967cf5cd9ec334f2917bd80b5af56e47ec22aefa13ed93ad0); /* statement */ 
version = new string(Version_length);

        // Set the version as data on the newly allocated string.
c_0x5875a93f(0xe820054a1f74b04a545c6d62a0d98732abaac014bab78dc5257bb282c178e9ca); /* line */ 
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
    {c_0x5875a93f(0x06133ca64d23b8822b47a8ef4d3f31e34348847477237dd4f707a58ededab535); /* function */ 

        // Leverage scratch space to perform an efficient hash.
c_0x5875a93f(0x6798b95d744d36efa7f9212b01bcdb00d4c8134d5fcfd356b1e72b7492bcaa68); /* line */ 
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
function c_0x6ea3c3b2(bytes32 c__0x6ea3c3b2) pure {}


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
function c_0x9e268b12(bytes32 c__0x9e268b12) internal pure {}

    // Only orders signed using an offerer's current counter are fulfillable.
    mapping(address => uint256) private _counters;

    /**
     * @dev Internal function to cancel all orders from a given offerer with a
     *      given zone in bulk by incrementing a counter. Note that only the
     *      offerer may increment the counter.
     *
     * @return newCounter The new counter.
     */
    function _incrementCounter() internal returns (uint256 newCounter) {c_0x9e268b12(0x76a5d1b723b97e9671bfdb214b2bc53774ab729c55659d9be5353649182855cb); /* function */ 

        // Ensure that the reentrancy guard is not currently set.
c_0x9e268b12(0x1373ada979fa71cbe256f724c3cacf41661c591a817f2478d1c0acc1c0160ce3); /* line */ 
        c_0x9e268b12(0xf50169ea4e7954b55e6bec407c69d586e9efa1698bb68c046f005407d30cdeaf); /* statement */ 
_assertNonReentrant();

        // Skip overflow check as counter cannot be incremented that far.
c_0x9e268b12(0xda4dca77dcbdc16bb4397a723c6e5aac15df25c3f813061690c8ca188efe4646); /* line */ 
        unchecked {
            // Increment current counter for the supplied offerer.
c_0x9e268b12(0xf79bc3d7c3a317e97916325a266dd1da61597a531343e76757a12ae7f12d686c); /* line */ 
            c_0x9e268b12(0xaf5e187786a754fc2db5ed9b4f76fc2e325f3a974596366a4d3a4c4a709cd329); /* statement */ 
newCounter = ++_counters[msg.sender];
        }

        // Emit an event containing the new counter.
c_0x9e268b12(0xb9dcd394d839fafc8672a4e0edb04e7ce1ca114d91f772dba594dbd4f06d16dc); /* line */ 
        c_0x9e268b12(0xb44242b9140f7bb46f9a66ef809873612542003d9e66104ef55d78b54be00a0f); /* statement */ 
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
    {c_0x9e268b12(0x3cbb49ff2b0bd03ad86e1ada0960b4e623ff494bcc38bcf0f765f7f0aaa3e3f1); /* function */ 

        // Return the counter for the supplied offerer.
c_0x9e268b12(0x7738a105d2a55fae9350e4aaad758b37583282ad023d912fecc8dff7bbabe0c8); /* line */ 
        c_0x9e268b12(0xa127692b681000def34dcd1d9c737ae690ed9902f93b0964cb3988c299acb3fb); /* statement */ 
currentCounter = _counters[offerer];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0xef7502c7(bytes32 c__0xef7502c7) pure {}


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
function c_0xc86fb97f(bytes32 c__0xc86fb97f) internal pure {}

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
    constructor(address conduitController) {c_0xc86fb97f(0x118b159002cbeff174296b2e1aca333cd2533dea6874030e1857685b71f2a7e9); /* function */ 

        // Derive name and version hashes alongside required EIP-712 typehashes.
c_0xc86fb97f(0xcf9b2b62c1d86df4cb1a5a8034b1e14d7df44983a327954cc7fec0e9d36943be); /* line */ 
        c_0xc86fb97f(0x3cefb8da6e4c96f09fd2a05191092b0d8657d3a1cfe06f81399ccab1f3e3cb26); /* statement */ 
(
            _NAME_HASH,
            _VERSION_HASH,
            _EIP_712_DOMAIN_TYPEHASH,
            _OFFER_ITEM_TYPEHASH,
            _CONSIDERATION_ITEM_TYPEHASH,
            _ORDER_TYPEHASH
        ) = _deriveTypehashes();

        // Store the current chainId and derive the current domain separator.
c_0xc86fb97f(0x452ad8dc089d857b0dc9cc94347c56ce94627f4bf3d6df8ba885395e604af611); /* line */ 
        c_0xc86fb97f(0x1827c434d3dbafcd175280d03ba5fbac5ad19ea7aef0eaede8433fb9407de00d); /* statement */ 
_CHAIN_ID = block.chainid;
c_0xc86fb97f(0xd19701a6f3e75d0bb155739bf2fbdb8aff07c3cfc8ac02fbe2fc321dac32bf74); /* line */ 
        c_0xc86fb97f(0xe0931a88c0a955dc085bd0fc7dd7be6a492666de87d66b22778197ed2bf2eced); /* statement */ 
_DOMAIN_SEPARATOR = _deriveDomainSeparator();

        // Set the supplied conduit controller.
c_0xc86fb97f(0xd5222f608d8826b30083e8170bfc213c1a7236ce0b0782fbf1ba33e9f037594a); /* line */ 
        c_0xc86fb97f(0xb1b6ff8796391f46c97af496f0da2c6a7401845aab459d5e14ee802a51513826); /* statement */ 
_CONDUIT_CONTROLLER = ConduitControllerInterface(conduitController);

        // Retrieve the conduit creation code hash from the supplied controller.
c_0xc86fb97f(0xa5118caa6996f62dc0c1e43bdad0b3c9e4eac00ac59012a58ce11a0d2b1247f4); /* line */ 
        c_0xc86fb97f(0xa232554ae8a34f265a01a36e92ca391703b395fee92a5dbebf1e56a34e766e0d); /* statement */ 
(_CONDUIT_CREATION_CODE_HASH, ) = (
            _CONDUIT_CONTROLLER.getConduitCodeHashes()
        );
    }

    /**
     * @dev Internal view function to derive the EIP-712 domain separator.
     *
     * @return The derived domain separator.
     */
    function _deriveDomainSeparator() internal view returns (bytes32) {c_0xc86fb97f(0x1d7707bbd7efdd1d8b307ce9263cf6dbbaff5feb237e2e645982b961ba9c2a19); /* function */ 

        // prettier-ignore
c_0xc86fb97f(0xc84a0814320be1b45d43b0b0ad9310b7d71f3e813cf384466daf67534f644472); /* line */ 
        c_0xc86fb97f(0x58dabd36146e120e32a92d87b55c18053bae151dc0e099bd7f4efe04728182e4); /* statement */ 
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
    function _name() internal pure virtual returns (string memory) {c_0xc86fb97f(0xc6fdfe0af14c301e7a759d7a7ea6d5d7ed155a4fc7873bf907eb613a945dd457); /* function */ 

        // Return the name of the contract.
c_0xc86fb97f(0xb0478747c6daed0e319a7d05b4b8a044f6df3cd44aa00651270d1a8e35130f85); /* line */ 
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
    function _nameString() internal pure virtual returns (string memory) {c_0xc86fb97f(0x561d2a79e25f60d6adca3ac5b2bb1b3c38b3b194d9e9d3941c7d0857ee92e4fc); /* function */ 

        // Return the name of the contract.
c_0xc86fb97f(0x846d16c0b456aae14360ae99df02056404e96d27043275b3d2d389e3faf2ddcd); /* line */ 
        c_0xc86fb97f(0x8e508396e2acf4f4cb4d2d245a322d2c7edd49d3344ce782b78aac392b4e9b2a); /* statement */ 
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
    {c_0xc86fb97f(0xd6886122ce0f7aafab0d0994faaaed5748afce89620f6f0ff5a0acc5a447faae); /* function */ 

        // Derive hash of the name of the contract.
c_0xc86fb97f(0xba9cc48b2098f6bf6ec32acabcd44bfcb5f9b5c4b7041bc92f6cf97bf57851bf); /* line */ 
        c_0xc86fb97f(0x61ffab4dacf304d286584072766479a62229f012b71cb9086b3dca670f43aed3); /* statement */ 
nameHash = keccak256(bytes(_nameString()));

        // Derive hash of the version string of the contract.
c_0xc86fb97f(0xbadc6332335214b8b710e890141d8db02950e7d078f9b10473dd9a88389ddf50); /* line */ 
        c_0xc86fb97f(0x5ee1eb4db8dd990f7d8e1ac7a1d5ab7b3ff84a569f307183ee8cfe6b37206eb6); /* statement */ 
versionHash = keccak256(bytes("1.1"));

        // Construct the OfferItem type string.
        // prettier-ignore
c_0xc86fb97f(0x0f58f7880c0463e647d779847c652658f194b1954645df9ace7b609029c37789); /* line */ 
        c_0xc86fb97f(0x25116a99cb509bb64a464f5dd09f32a954285618895f9fcefe8eb3f1a2515be7); /* statement */ 
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
c_0xc86fb97f(0x8af7d12cb01f4a28134bd560dc8d57a1ad4823bd0790d214cb7379a6c09c562d); /* line */ 
        c_0xc86fb97f(0x4f01e3254387b511c97d59ede9924ebf14e56b37c0a8f1adb5fcf377f4cc10b6); /* statement */ 
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
c_0xc86fb97f(0x07d673b5adf48eccad08870b4f62230de40c4ee55f024ebf2be61b7f53438ce5); /* line */ 
        c_0xc86fb97f(0xb58daab48f14b39bc779c1d02510ba37302253901635a33c3c9822e4b737f72b); /* statement */ 
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
c_0xc86fb97f(0x45595f73cf7cac64b4756c85d8f67f75494921453c588c020e53f21ecf9f016d); /* line */ 
        c_0xc86fb97f(0x64514764eec74dd46f1eb16155c240192dee951083d1d48870aa068d67da40dc); /* statement */ 
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
c_0xc86fb97f(0x463bb80003a0e514d5b80faa0e37d245d63269c8e27197b5352f4c2a589b3192); /* line */ 
        c_0xc86fb97f(0xee4283877d7c88593eb794e75d1a11e0958c6877e3a8a9c03b4f5e9eeba644a8); /* statement */ 
offerItemTypehash = keccak256(offerItemTypeString);

        // Derive ConsiderationItem type hash using corresponding type string.
c_0xc86fb97f(0x54d7eac609fdc431f6acdadf76b8c0f84f802cc3907360cc864964284bc99d21); /* line */ 
        c_0xc86fb97f(0xcf75970f17b96a060368eec177663db4e1de588751255f393857b7427db3c83c); /* statement */ 
considerationItemTypehash = keccak256(considerationItemTypeString);

        // Derive OrderItem type hash via combination of relevant type strings.
c_0xc86fb97f(0x852b18c2345305bcee294ab8b3c6ab30033430ade421f4a25b2d36355a7cb396); /* line */ 
        c_0xc86fb97f(0xc4e0b55d3140b9b87fc85be432d77dae745b11bc4bcc4b4c6db2f5f87b236c4e); /* statement */ 
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
function c_0x582dbab7(bytes32 c__0x582dbab7) pure {}


import { ReentrancyErrors } from "../interfaces/ReentrancyErrors.sol";

import "./ConsiderationConstants.sol";

/**
 * @title ReentrancyGuard
 * @author 0age
 * @notice ReentrancyGuard contains a storage variable and related functionality
 *         for protecting against reentrancy.
 */
contract ReentrancyGuard is ReentrancyErrors {
function c_0x7a2f3b36(bytes32 c__0x7a2f3b36) internal pure {}

    // Prevent reentrant calls on protected functions.
    uint256 private _reentrancyGuard;

    /**
     * @dev Initialize the reentrancy guard during deployment.
     */
    constructor() {c_0x7a2f3b36(0xda06c736da6589400e0ba65d719d0858b98ea4824acf8b933ad0d290fb757a1a); /* function */ 

        // Initialize the reentrancy guard in a cleared state.
c_0x7a2f3b36(0xc9cea7b8f6dcb810421c3d7cb62d282ad074e46390bc3d82fba9ab4ca76cb925); /* line */ 
        c_0x7a2f3b36(0x32ad7738c60d094ce55776dcf102c4c2a8c8502bfee1685e22e1738737c09d87); /* statement */ 
_reentrancyGuard = _NOT_ENTERED;
    }

    /**
     * @dev Internal function to ensure that the sentinel value for the
     *      reentrancy guard is not currently set and, if not, to set the
     *      sentinel value for the reentrancy guard.
     */
    function _setReentrancyGuard() internal {c_0x7a2f3b36(0x40e2e35567d2a6219f8bce3d488bc92f04663837e99266156e8f1c9aa0dd3b85); /* function */ 

        // Ensure that the reentrancy guard is not already set.
c_0x7a2f3b36(0x0b0a9d2c3473816233245a3de0c9eb0a5c5cc4382c1625be259e7bbb08f08a6c); /* line */ 
        c_0x7a2f3b36(0x5a3efbc230ba2cf3d782db1c4915f48f4e7f9619096bc971285b85eff7a3cf5b); /* statement */ 
_assertNonReentrant();

        // Set the reentrancy guard.
c_0x7a2f3b36(0x88f0b4dcfed1f16ff0d89e9ca7f01195653619b1bbec3a29e9e0bf84c4b5e04c); /* line */ 
        c_0x7a2f3b36(0xb4aaaca9265661ddda326bfc517784ef0ce22e6382468fddc9dcb2687f0ddcd4); /* statement */ 
_reentrancyGuard = _ENTERED;
    }

    /**
     * @dev Internal function to unset the reentrancy guard sentinel value.
     */
    function _clearReentrancyGuard() internal {c_0x7a2f3b36(0x491a15711c27f649946233bfd36f4b916bc6f25b13c682f66fe7a04159c18da8); /* function */ 

        // Clear the reentrancy guard.
c_0x7a2f3b36(0x2803254d1ab388a8bf34c8b17cfc06e23a153436e48d945eafbc0eed255a262b); /* line */ 
        c_0x7a2f3b36(0xb6fd9157712c7becafdd0a83ff9addb1dc3a5c5984225ccb910309ded1e10586); /* statement */ 
_reentrancyGuard = _NOT_ENTERED;
    }

    /**
     * @dev Internal view function to ensure that the sentinel value for the
            reentrancy guard is not currently set.
     */
    function _assertNonReentrant() internal view {c_0x7a2f3b36(0xaf1a0eb7f420a157b6747b6927cd28d628a6c1c89884cf6949d820c8fcbf46ab); /* function */ 

        // Ensure that the reentrancy guard is not currently set.
c_0x7a2f3b36(0x5f6ffa9f15a3f81748a41e4fea1c7459661dd1190df4009d341a10dd92fdcecc); /* line */ 
        c_0x7a2f3b36(0x6d4b5c9828aa400a7e9e088a273b6d43b97f8cd52cd59fb4b7034ed44f0d13dc); /* statement */ 
if (_reentrancyGuard != _NOT_ENTERED) {c_0x7a2f3b36(0x25d9ccaeb535fdbdb47d663d5ec0974736a0156f019f6654f714529f50337c68); /* branch */ 

c_0x7a2f3b36(0xc07fcca0d505389836a8013e7ab2956f8ec15ab3512461f7363fcc66ce4df95a); /* line */ 
            revert NoReentrantCalls();
        }else { c_0x7a2f3b36(0xb8d17a90391a6fa1098e608f54721e1ef79781105bd1858275d03762a9858be8); /* branch */ 
}
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0xd637c1ec(bytes32 c__0xd637c1ec) pure {}


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
function c_0x13c84f94(bytes32 c__0x13c84f94) pure {}


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
function c_0x00935c93(bytes32 c__0x00935c93) pure {}


import "./ConsiderationConstants.sol";

/**
 * @title LowLevelHelpers
 * @author 0age
 * @notice LowLevelHelpers contains logic for performing various low-level
 *         operations.
 */
contract LowLevelHelpers {
function c_0x213e7a09(bytes32 c__0x213e7a09) internal pure {}

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
    {c_0x213e7a09(0xc6a5bac5812fd7779e04861d111cc348f5f4a7e65c00dee42d7d12bb68b282d6); /* function */ 

c_0x213e7a09(0xd547970441468171dd0f4f258505f380fac3ff1d38a0a0d654f47e987d7dac70); /* line */ 
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
    function _revertWithReasonIfOneIsReturned() internal view {c_0x213e7a09(0xabd10a888be119319b93cc1608b443c195f762e931e5d8ed84e2d571d0d60600); /* function */ 

c_0x213e7a09(0x1d098ffc0cd189fd27582c8b612c4a40d20f91bcd1785126ae12ca3a5bc8f2ce); /* line */ 
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
    function _doesNotMatchMagic(bytes4 expected) internal pure returns (bool) {c_0x213e7a09(0x34fa06334f373d25854b7a1af130e4b2f057cfe05bd0791c33bdeba47f9a8b2a); /* function */ 

        // Declare a variable for the value held by the return data buffer.
c_0x213e7a09(0x095c01c2c4a093de57035ae335717764a1184c59b9740baf774965d107183655); /* line */ 
        c_0x213e7a09(0xccc18b5428b98ded26f184e58f2ba6f5498288ff282253f57a5342227bdeabf8); /* statement */ 
bytes4 result;

        // Utilize assembly in order to read directly from returndata buffer.
c_0x213e7a09(0x857f01ce841930e7dca8e6a9655760845cc5017e177a5f1028ec4327e50cc6d5); /* line */ 
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
c_0x213e7a09(0xb5973b28bac61950042488a486f869535e13a62b952b975f85b8becd0044733a); /* line */ 
        c_0x213e7a09(0x4be5930432fe6d87697b9cd1b26a544fb0423df957d365b3a910d4d5a7294f43); /* statement */ 
return result != expected;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0xfce2b31a(bytes32 c__0xfce2b31a) pure {}


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
function c_0xcd5413f6(bytes32 c__0xcd5413f6) internal pure {}

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
    ) internal pure returns (Execution memory execution) {c_0xcd5413f6(0x1d9b400dc83be39e7583656d1f8d232be7c111b2dac4788db16be33bf9784ec6); /* function */ 

        // Ensure 1+ of both offer and consideration components are supplied.
c_0xcd5413f6(0x1469951fc3d6cf73031fcfe4ec1ae0bb2161ebe72e83930d546e1ea1a569f79c); /* line */ 
        c_0xcd5413f6(0x561fb977fdbeb70910de9a880fb991c58ee883a48a665f5e0f7e70b9ae44924a); /* statement */ 
if (
            offerComponents.length == 0 || considerationComponents.length == 0
        ) {c_0xcd5413f6(0xafba446b9d890f4782857e96200f1c4a5c6d92e5b4d0735f4e51c135bcf617bd); /* branch */ 

c_0xcd5413f6(0xff17815402e51b9cb89824ba1ecce7e785156a66944e2e4040dae32d8b309b2f); /* line */ 
            revert OfferAndConsiderationRequiredOnFulfillment();
        }else { c_0xcd5413f6(0x769925386a43532edd0c0006871f64e518a29b4839b159e6857bcb54e81e24e7); /* branch */ 
}

        // Declare a new Execution struct.
c_0xcd5413f6(0xd66f9e3b654bed1d410a6b6440b4dbb0a85d04eff26b8e91382688bddec9ba45); /* line */ 
        c_0xcd5413f6(0x7c5ae90cbde9d39f64053b792086e6f6b2d86eec359ea9c1761062483f1689c8); /* statement */ 
Execution memory considerationExecution;

        // Validate & aggregate consideration items to new Execution object.
c_0xcd5413f6(0x2ac3956cfde78b16d40b7cd1022f80a12874a36e3e47875bbd81eb2c72439a86); /* line */ 
        c_0xcd5413f6(0xa2d45651ba5189dc7818fc6b96e75867540bb37c8482bc910ca371eaa317f795); /* statement */ 
_aggregateValidFulfillmentConsiderationItems(
            advancedOrders,
            considerationComponents,
            considerationExecution
        );

        // Retrieve the consideration item from the execution struct.
c_0xcd5413f6(0x2aa1ff859450b9449a94342f011b731287f3db93defedb73be26cadf96536930); /* line */ 
        c_0xcd5413f6(0xf83df0e0faecfdc3f912fb773e37f95129d5050903015debf77bd78272912bd4); /* statement */ 
ReceivedItem memory considerationItem = considerationExecution.item;

        // Recipient does not need to be specified because it will always be set
        // to that of the consideration.
        // Validate & aggregate offer items to Execution object.
c_0xcd5413f6(0xa7d69435271a9d9d17726f5ac8f986ed0f8d7174ec896940eb534b3f52fbd3d8); /* line */ 
        c_0xcd5413f6(0x364b36409841a087607569ebb6b3fcabac0aac57bf50936f104538b68b815598); /* statement */ 
_aggregateValidFulfillmentOfferItems(
            advancedOrders,
            offerComponents,
            execution
        );

        // Ensure offer and consideration share types, tokens and identifiers.
c_0xcd5413f6(0xff5f28b2f95060ea4386ca6ed430565aa6ac1585520101022a356d888ea9bbe5); /* line */ 
        c_0xcd5413f6(0x72a20387b9094cfe39d7c60b3d3b8ffc6c9da2e274d1954234da89e5d36e18f4); /* statement */ 
if (
            execution.item.itemType != considerationItem.itemType ||
            execution.item.token != considerationItem.token ||
            execution.item.identifier != considerationItem.identifier
        ) {c_0xcd5413f6(0x2f1d66e3ea0d1fd22008f46f3bba76f45f550af7004bb683074d1842b973b899); /* branch */ 

c_0xcd5413f6(0xa44660336e23c94362b6c0ba44e5d0af18f44772845bbecbbfb3d7d9848c73f5); /* line */ 
            revert MismatchedFulfillmentOfferAndConsiderationComponents();
        }else { c_0xcd5413f6(0x70969f3bdcafe907def49e17c1b8ce19b03384ba64507899fb103c7e9e97302c); /* branch */ 
}

        // If total consideration amount exceeds the offer amount...
c_0xcd5413f6(0xcaceb1cb8f8bb67de5438d62b2840676b7e94dbef02606cb86641d5ff9073de0); /* line */ 
        c_0xcd5413f6(0x11dab3b4f6a83a27488914ff66657213cfad15423d31e128e83435857baaa75e); /* statement */ 
if (considerationItem.amount > execution.item.amount) {c_0xcd5413f6(0xee1586715e15cbcded5a1afce2a507c3047db87009224829f798425500c636c3); /* branch */ 

            // Retrieve the first consideration component from the fulfillment.
c_0xcd5413f6(0xd28036fe1d179913fa2850a1a74d647d8861dd8d27928111d11d9df20aaee176); /* line */ 
            c_0xcd5413f6(0x00f6cea9854f5f995ff51193e05c6e13e35430235293ade8c4f947a18c09bb5b); /* statement */ 
FulfillmentComponent memory targetComponent = (
                considerationComponents[0]
            );

            // Skip underflow check as the conditional being true implies that
            // considerationItem.amount > execution.item.amount.
c_0xcd5413f6(0x79c54fe1be67e108770a7f6fc82c777b2d9496424879a8abf31af2acd77cd072); /* line */ 
            unchecked {
                // Add excess consideration item amount to original order array.
c_0xcd5413f6(0xb4ab4ccaad00602ba7cc715953d9c380a9d24483f3f27d6c7bee702d37aa4784); /* line */ 
                c_0xcd5413f6(0x5db5fbd026088c11ac180945dc12d219abe5e98f4ff3203173c9d6c2af38447d); /* statement */ 
advancedOrders[targetComponent.orderIndex]
                    .parameters
                    .consideration[targetComponent.itemIndex]
                    .startAmount = (considerationItem.amount -
                    execution.item.amount);
            }

            // Reduce total consideration amount to equal the offer amount.
c_0xcd5413f6(0x92b277922cf1d096bd7f5a48b8cf1e4c31e3f4e72ad6a506644fa4220ba3b264); /* line */ 
            c_0xcd5413f6(0x5afb9e0121ffbc4ca400c7bde788282919d3068176831e871e8c809345a36292); /* statement */ 
considerationItem.amount = execution.item.amount;
        } else {c_0xcd5413f6(0x268085a18947c447e90bd0a10cc2e049e8b5741f84c8bbdf1a7cd57ebabe99e2); /* branch */ 

            // Retrieve the first offer component from the fulfillment.
c_0xcd5413f6(0xfc989502d7e8a3160951e6e408cb34ffc8bcb741382b936ac67cbc3b1e86fa5e); /* line */ 
            c_0xcd5413f6(0xa54c70b8fdc8be4b13489d23f4c25b0a4d042ac363f88ee969ef0938203abd20); /* statement */ 
FulfillmentComponent memory targetComponent = offerComponents[0];

            // Skip underflow check as the conditional being false implies that
            // execution.item.amount >= considerationItem.amount.
c_0xcd5413f6(0x582116cb905b2c6d5237edaa7a709d72d14e270bc1405b5d5a5bc6ba279e9498); /* line */ 
            unchecked {
                // Add excess offer item amount to the original array of orders.
c_0xcd5413f6(0xf1e8fde7b7a867cb38c69b87f26fa1cf1aae5e68b18d8fa7989b7192d61a8935); /* line */ 
                c_0xcd5413f6(0x73190abceb69f63f6ed7396514bc06fd5d3a0d8eae358fbd57f01231516b198f); /* statement */ 
advancedOrders[targetComponent.orderIndex]
                    .parameters
                    .offer[targetComponent.itemIndex]
                    .startAmount = (execution.item.amount -
                    considerationItem.amount);
            }

            // Reduce total offer amount to equal the consideration amount.
c_0xcd5413f6(0xecbd3700a5b2c764fe8ac3d53790e5a70eb7f173d8491fe8dfa6ae990d1b2d49); /* line */ 
            c_0xcd5413f6(0x0f19de4876240a8525f07b49fe45c92dd99b02d90af34ee017eaeda78925051b); /* statement */ 
execution.item.amount = considerationItem.amount;
        }

        // Reuse consideration recipient.
c_0xcd5413f6(0x5895d05d4be9eb94cf1159d5d90f58fc8cf90fc68f48244894144cf641c73083); /* line */ 
        c_0xcd5413f6(0x7529877cedbf9c6e94c083222aa65675b2feb2c39130530b81feb48270cfd141); /* statement */ 
execution.item.recipient = considerationItem.recipient;

        // Return the final execution that will be triggered for relevant items.
c_0xcd5413f6(0xe9809a026ce63be9fb2e9b0529696a7dbebe57723be272d40a44f815312bd994); /* line */ 
        c_0xcd5413f6(0xcd1f5200971c88fed615b907a2ed1c449eeb3fb984da13bedbca6c5fc634e5f1); /* statement */ 
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
    ) internal view returns (Execution memory execution) {c_0xcd5413f6(0x15a9a8f8ab200f4b3460c81ae43f39a1722013d100c40c2a813b65b62a22f3e4); /* function */ 

        // Skip overflow / underflow checks; conditions checked or unreachable.
c_0xcd5413f6(0xc8a0e8b3ef766c6b67f3d34c0f3e9d5c13921736bcb1f07669f4baf847477cb7); /* line */ 
        unchecked {
            // Retrieve fulfillment components array length and place on stack.
            // Ensure at least one fulfillment component has been supplied.
c_0xcd5413f6(0xbbf0b3e9fc8c01ff2f288c200b187571a3835071fcc9795e858bba4db51beb5a); /* line */ 
            c_0xcd5413f6(0xbcf526d2e37e2a0f2730fa47cbfb97d9dadaa80691edd3a49a239267529da8d5); /* statement */ 
if (fulfillmentComponents.length == 0) {c_0xcd5413f6(0xff81dac2e92456c9c732bc5f87dfa96479d2dd9e5ee202ab91adab887b5f9398); /* branch */ 

c_0xcd5413f6(0x058ddd7dfe8d2a44e8d97c67f6d1d737512bca59961cf18b2e19ef942b4d5564); /* line */ 
                revert MissingFulfillmentComponentOnAggregation(side);
            }else { c_0xcd5413f6(0xfd9de6228de9fa7e920c499c3f01771e7a41a8477cab9bb36eead84f510ca5d8); /* branch */ 
}

            // If the fulfillment components are offer components...
c_0xcd5413f6(0xa936b4c83de90539d56a8a306a203e53cb3b4d00dba5008229703c47f4f617f1); /* line */ 
            c_0xcd5413f6(0x8a653bff7026b13dd0c9af909d8c93dc09a47020188cc648e42f63954abfbc16); /* statement */ 
if (side == Side.OFFER) {c_0xcd5413f6(0x3baf1a6cdb65418ef1feb8c4fe55e5995b6ca33272fe1beed68cc1d9ca1fb09e); /* branch */ 

                // Set the supplied recipient on the execution item.
c_0xcd5413f6(0xb4c7df11c3391d3c24bdb8ce42861951c4a2de94a320b581d26e5fd4b0ba58c1); /* line */ 
                c_0xcd5413f6(0x754498ff0c5c8694894c24b42fc884d0f6e31366d901f632db7162e0a1ac0b91); /* statement */ 
execution.item.recipient = payable(recipient);

                // Return execution for aggregated items provided by offerer.
c_0xcd5413f6(0x54e236adca9620ad4e79dcc8dc2e8109a8d1ddb2ca6ca28ae49c7c6dc3339716); /* line */ 
                c_0xcd5413f6(0x23765ec6790adaffaa413eece1d46c38b9db73d1aab5ce6286280b44ace435ae); /* statement */ 
_aggregateValidFulfillmentOfferItems(
                    advancedOrders,
                    fulfillmentComponents,
                    execution
                );
            } else {c_0xcd5413f6(0xe8bc343314ee59c87f5f6b3e2b8d3c7639a51f91b67e071f06db9ebbb87bf15e); /* branch */ 

                // Otherwise, fulfillment components are consideration
                // components. Return execution for aggregated items provided by
                // the fulfiller.
c_0xcd5413f6(0x0fef5151928cf5ac4f596ba07afed8ccbaabee2219ca0fdf3caa8dd31c6f6346); /* line */ 
                c_0xcd5413f6(0xcb48342218452b3b85b2973d4bf783925b12810e23e68c0a78fe5423ad822203); /* statement */ 
_aggregateValidFulfillmentConsiderationItems(
                    advancedOrders,
                    fulfillmentComponents,
                    execution
                );

                // Set the caller as the offerer on the execution.
c_0xcd5413f6(0xc8d58c153a53a09ce394eb9454bcbc216ee826f0ea073b33560dc97c759577e4); /* line */ 
                c_0xcd5413f6(0xf6db0b222418380468c39f675bca39e7e0c9529d9c018e5aafbbe98a0d0e1372); /* statement */ 
execution.offerer = msg.sender;

                // Set fulfiller conduit key as the conduit key on execution.
c_0xcd5413f6(0x3de20681f265eb792b23ecaa4e66a9437991f168f2f842f307d298ea9314c5d5); /* line */ 
                c_0xcd5413f6(0x49389450e700b1590d253468b8b8fdf17817244d3df7eef7eb1c762bf814d1ee); /* statement */ 
execution.conduitKey = fulfillerConduitKey;
            }

            // Set the offerer and recipient to null address if execution
            // amount is zero. This will cause the execution item to be skipped.
c_0xcd5413f6(0x17bf99ac8bd9397407f35054a24648671ea9ceba5d37fbb29058d76db100b73d); /* line */ 
            c_0xcd5413f6(0x8c269b19599cbd7f8d7edca6d74516d6c62289300cf0a0ae26e30a83f77b9dee); /* statement */ 
if (execution.item.amount == 0) {c_0xcd5413f6(0xf11088b8a7c375296f97b695888c830b871c70817fba3feb5bdf69c833e43988); /* branch */ 

c_0xcd5413f6(0x5e2fc3c7ac7006fe9a367e29b38a96f6b6232fc61d5b405771964a994458b927); /* line */ 
                c_0xcd5413f6(0xea38ea11310f041d73109f92c77174743d79f4ebf29ede36d06f09f1a9243674); /* statement */ 
execution.offerer = address(0);
c_0xcd5413f6(0xa6d327ff1fdaa233a93ee8f40fcc14b677194406269eb6d950260aa655dba4c0); /* line */ 
                c_0xcd5413f6(0x0527dfae3c84b5762ab24b5bb7a450952d7c9d4affbd6b6022f15cbbbe69f25e); /* statement */ 
execution.item.recipient = payable(0);
            }else { c_0xcd5413f6(0xd965bb68d705109a4f3b0fe5fd463788749082869323bfcd1131933396515d47); /* branch */ 
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
    ) internal pure {c_0xcd5413f6(0xfadbf7728a5bb46cda50cf83f39d29dc81ea422d4fed532d9efdd5d9271bf62b); /* function */ 

c_0xcd5413f6(0x7c2435fa62acf05632424773555add552d2b0dfe1cc78504345c2e1a0eb8ff08); /* line */ 
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
    ) internal pure {c_0xcd5413f6(0x34360e4252f9006fbfdf4c473150d58a32f3a0e13accd41869cf3267ef382265); /* function */ 

        // Utilize assembly in order to efficiently aggregate the items.
c_0xcd5413f6(0x650e1d60b45867c8699edc42de57acd4c8452335cca48a0038e85dc96a5f35aa); /* line */ 
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
function c_0xe9767e24(bytes32 c__0xe9767e24) pure {}


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
function c_0xde4e5ff2(bytes32 c__0xde4e5ff2) pure {}


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
function c_0x25384ce4(bytes32 c__0x25384ce4) internal pure {}

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
    ) internal pure {c_0x25384ce4(0x2dd001598a270a07d22c887d66ead72068864b09f7ccffb3aeecb91c9edc4fd6); /* function */ 

        // Skip overflow checks as all for loops are indexed starting at zero.
c_0x25384ce4(0x4e1df2993f25532b0c1ae4536320ad2c6030ccee3b570332397f94fec67c32f2); /* line */ 
        unchecked {
            // Retrieve length of criteria resolvers array and place on stack.
c_0x25384ce4(0xc94b1d3154f8ab7e9c35e55cb2eddf20b5d322fbcf6ca2eb3246ed5bd22bcee3); /* line */ 
            c_0x25384ce4(0x7e72a7c7f398798da87b850cd0f06d5070fb111718b1ace8ceb6ef81c11da213); /* statement */ 
uint256 totalCriteriaResolvers = criteriaResolvers.length;

            // Retrieve length of orders array and place on stack.
c_0x25384ce4(0x413db989ff48eebecb61d8e60080212440cf8dbcc0a0500ce9e690773e6b2394); /* line */ 
            c_0x25384ce4(0xee58b5796a8d6e5daf5e872ab89293e98521d302bf73ed2f0e68de94cc166fe4); /* statement */ 
uint256 totalAdvancedOrders = advancedOrders.length;

            // Iterate over each criteria resolver.
c_0x25384ce4(0x8483be972db03280cc12ff61bf61242fed36bd84ca828eb5af466405ea488f99); /* line */ 
            c_0x25384ce4(0x4bbbae7a503efd9c6f4392ead1d9c72adb526ef1075d9168679b3d7519d16309); /* statement */ 
for (uint256 i = 0; i < totalCriteriaResolvers; ++i) {
                // Retrieve the criteria resolver.
c_0x25384ce4(0xfbc77f6e29561cf3d95d2602203d4ed75abbe418f8d3768c2a65a25b9a30b69b); /* line */ 
                c_0x25384ce4(0x0573360c44b3902ecf99ad29482a529955e3668436b9e591000bb8202d36fc7b); /* statement */ 
CriteriaResolver memory criteriaResolver = (
                    criteriaResolvers[i]
                );

                // Read the order index from memory and place it on the stack.
c_0x25384ce4(0xfd57c193d5bcd52faed6b689aa95b80f69be23690c6a04a41dc3d7d22037089d); /* line */ 
                c_0x25384ce4(0x9a6411f0159bea7eff33e4c3fb6c270ee361b6dec0d5ea17504ed151be39bc9d); /* statement */ 
uint256 orderIndex = criteriaResolver.orderIndex;

                // Ensure that the order index is in range.
c_0x25384ce4(0x0bf01694da1972c08b982d3d489382ca2922cc7feba94a764cb95065f77adf54); /* line */ 
                c_0x25384ce4(0x133a863b37db772bce2c2eb9f50e4d5847d8160e97b46ac8415d0b82b9c93148); /* statement */ 
if (orderIndex >= totalAdvancedOrders) {c_0x25384ce4(0x4cb0e51b316526591702a579b346ce144ab605df22a82db3e1302d4633937037); /* branch */ 

c_0x25384ce4(0x1e82f86fbb776ba58c87d3fa4be4a90bda1811aa90f697c7cf9a283aed76aec5); /* line */ 
                    revert OrderCriteriaResolverOutOfRange();
                }else { c_0x25384ce4(0xbc294d7959dcff34bbf0ba66653f5fc4371d1af26aafa4ac5592152627b4fd7d); /* branch */ 
}

                // Skip criteria resolution for order if not fulfilled.
c_0x25384ce4(0x241d0be0931ba16bbcf1141222c7b9e392d2992487c19564d72cabe103a286e4); /* line */ 
                c_0x25384ce4(0x5215455c637e7a2a22a904f26422f4c23f8e1f7cd3cb4db80681d2987454d328); /* statement */ 
if (advancedOrders[orderIndex].numerator == 0) {c_0x25384ce4(0x9d83b324a679bcacb0ed31a21aba3e5e208a466053855039a337230eb8d8e663); /* branch */ 

c_0x25384ce4(0xb583598ee344dc885ead621f5eb49aae3bd8caf7ac67102d704193a6f1de746d); /* line */ 
                    continue;
                }else { c_0x25384ce4(0x16b15eae3fb1802cd590c1cfdc1834e010783de013bae3cbeb501a8daca25d00); /* branch */ 
}

                // Retrieve the parameters for the order.
c_0x25384ce4(0x5c095bd68699a7cc57646516018cfc2963a5686a9617906c579f61d018b70c84); /* line */ 
                c_0x25384ce4(0x627af9f5b270307639af6fd3f403e1fda440d6a2c52107f108eb592f09f3cb71); /* statement */ 
OrderParameters memory orderParameters = (
                    advancedOrders[orderIndex].parameters
                );

                // Read component index from memory and place it on the stack.
c_0x25384ce4(0xdaec3838960a2739f8e353ee2792bcb183a8998d762e3d8fff1f77788f64dd1a); /* line */ 
                c_0x25384ce4(0x97c020a887ef61871b4ccae35710b55f36fc146e40822f9c61dcf85aeee50a22); /* statement */ 
uint256 componentIndex = criteriaResolver.index;

                // Declare values for item's type and criteria.
c_0x25384ce4(0x65de4388ab04f4cc71a64eaae92d6fcffec1d1189165d2b4e98a59bb814b5507); /* line */ 
                c_0x25384ce4(0xcd401eee00b1b44159b671986f5ddc6db58ac01a04a919bf73c2077eba50624c); /* statement */ 
ItemType itemType;
c_0x25384ce4(0xc59ac032a0364baba013266955b8bcefe5cd8b5017203b9f680677b9f63c9e69); /* line */ 
                c_0x25384ce4(0x9b1eae2ad63d4013cdfb476045e99be5316473fc39cb6fe92782f64d0505c4c9); /* statement */ 
uint256 identifierOrCriteria;

                // If the criteria resolver refers to an offer item...
c_0x25384ce4(0x5ecd4bf847f2867ff242077c1a4bffd0d6dbb8bfee4c5e8bcca26e19d6673325); /* line */ 
                c_0x25384ce4(0xa721422bab27d4509148ac552b52f45b17ca0651c4a7f4cde1420e77db854d45); /* statement */ 
if (criteriaResolver.side == Side.OFFER) {c_0x25384ce4(0xc357a49707ad1c5aaf78df6de87daa024f7d67475270ef74f1ee6e2ab34d3a60); /* branch */ 

                    // Retrieve the offer.
c_0x25384ce4(0x95e4501efd20fd52e7cb7ae0154077872e6c57c34e100644e49399c62ed81ed0); /* line */ 
                    c_0x25384ce4(0xb091aea15c2040a540b113490f713a1de2c34d815299963193a9bf71913934a2); /* statement */ 
OfferItem[] memory offer = orderParameters.offer;

                    // Ensure that the component index is in range.
c_0x25384ce4(0xb3bc5e23297ddc3ee483b17c7607fd5f572dea7ffbff3dc935ed25e014e65c9d); /* line */ 
                    c_0x25384ce4(0x45d3dc00c1c7ab151d1fbbe4177f4945dae025c2e844f83592d462f4c881147a); /* statement */ 
if (componentIndex >= offer.length) {c_0x25384ce4(0x526048acf52a96131cfbda7fb01a23ac23efe33715a7e57646dbead16916ba9c); /* branch */ 

c_0x25384ce4(0x330bdffd843a3c3b34a700eee5a30b20a5b1b8fc8eef64359a5045db781e3fb1); /* line */ 
                        revert OfferCriteriaResolverOutOfRange();
                    }else { c_0x25384ce4(0x18ba72834529db3c4da5db911bcefc92786928d9efcb18ad1dacd4ab81c6beed); /* branch */ 
}

                    // Retrieve relevant item using the component index.
c_0x25384ce4(0x34a41a1d22dddabe8fa48d17338542dcda57b32fcffb4929b55414454b9e0e0c); /* line */ 
                    c_0x25384ce4(0x7db7d5e1935d16d6aef2fd176e08fbf935f47d359f978c2999d60ed6fe7640bc); /* statement */ 
OfferItem memory offerItem = offer[componentIndex];

                    // Read item type and criteria from memory & place on stack.
c_0x25384ce4(0x1ab5584cbebffcbee7bcec3922996320bd2479d07b2ffb46bc118c300ffbac46); /* line */ 
                    c_0x25384ce4(0x380ccb48126143200b26124be59f1edd90bcc91acae315fbdd0a7ee1856b47cf); /* statement */ 
itemType = offerItem.itemType;
c_0x25384ce4(0xacb9e28f3ff2a84cb555611c3372874e9f69280f5d83cfd086c47ad65e4b5e46); /* line */ 
                    c_0x25384ce4(0x3bc41b0ef580600ba8aaf161f3ebea7cd38b6d0294e8511304ac05f22a83100c); /* statement */ 
identifierOrCriteria = offerItem.identifierOrCriteria;

                    // Optimistically update item type to remove criteria usage.
                    // Use assembly to operate on ItemType enum as a number.
c_0x25384ce4(0x0624eba842b1a15a63451894804a274372c92da2178da46724407a72ecc8b5bc); /* line */ 
                    c_0x25384ce4(0xa534cfc3f7238348995370f83ff72ff822c689721423eb2abb75fd3841c9ee2c); /* statement */ 
ItemType newItemType;
c_0x25384ce4(0x41c3ee75df9c59ac7ea584ff093f07b115ebedab1a201be03c5ef5559ec3346a); /* line */ 
                    assembly {
                        // Item type 4 becomes 2 and item type 5 becomes 3.
                        newItemType := sub(3, eq(itemType, 4))
                    }
c_0x25384ce4(0x9e3cb90f246670a2c1d5a70df0f8ee3078cba0a47bdd93724ed309e6fc22e8fc); /* line */ 
                    c_0x25384ce4(0x4febdc3d86869db05a8a5e38a6234c266f23b1af83f9e05196ef97cfd40c4a6a); /* statement */ 
offerItem.itemType = newItemType;

                    // Optimistically update identifier w/ supplied identifier.
c_0x25384ce4(0x10b493782073f8bf2ba4466ee66ca1ba21fa11c349e5d15f6c182285ac09c775); /* line */ 
                    c_0x25384ce4(0xec877ff476240931c9233a3c775c952d965f6308a6451a1de45d3645f51404b7); /* statement */ 
offerItem.identifierOrCriteria = criteriaResolver
                        .identifier;
                } else {c_0x25384ce4(0xdede1228c86a7f4c03f233457246730c770d3ec855fc9679f8b3195356997fe5); /* branch */ 

                    // Otherwise, the resolver refers to a consideration item.
c_0x25384ce4(0x688c1d15332af1eea6c63cd0f4af8995d493d58a66af3cc1f5bd1f4abb5d821f); /* line */ 
                    c_0x25384ce4(0x43b1c08a3a1fd3e8f63c869654e9eeb50a559b5cd7863c29e792101885e49267); /* statement */ 
ConsiderationItem[] memory consideration = (
                        orderParameters.consideration
                    );

                    // Ensure that the component index is in range.
c_0x25384ce4(0xdd83c01b00649ba6600bac88ad6217daf8a197e9f03b7756b7e125cbd282a353); /* line */ 
                    c_0x25384ce4(0x8b95f103b8ddcab50ac77553c3d441604787f84db6c9521bbedd25b2a88eb073); /* statement */ 
if (componentIndex >= consideration.length) {c_0x25384ce4(0x97aabc783bca333435511b7a7f3cd2e045529006d1cc77a5a3be1c381f17b5bf); /* branch */ 

c_0x25384ce4(0x83c3963fc13dde1f71e522a611d0debca9a3f7d122326a4b0ee8616f47081848); /* line */ 
                        revert ConsiderationCriteriaResolverOutOfRange();
                    }else { c_0x25384ce4(0xe99211396bb4ecaeabcc2a5e00b949d7990c5f50865c773e1e90d90d8a173ff6); /* branch */ 
}

                    // Retrieve relevant item using order and component index.
c_0x25384ce4(0x0f2425f6e92f2e4f07ce6a372a135e63f8cd4fb1f569e975309f49f0cc721c97); /* line */ 
                    c_0x25384ce4(0xd7f0ce42242d9fabd63a84c5ba6920daa6a9964c38261e2444a42b15e5594f15); /* statement */ 
ConsiderationItem memory considerationItem = (
                        consideration[componentIndex]
                    );

                    // Read item type and criteria from memory & place on stack.
c_0x25384ce4(0xc1809103eeb53de040c3eaf860bf59f8c6965043f251b3fcf49ee15ee462e2ab); /* line */ 
                    c_0x25384ce4(0xe1441866f2643cedfb46f990f6fb4fdac6a3e9a65cbeb5aa4c8ac844a8282f1e); /* statement */ 
itemType = considerationItem.itemType;
c_0x25384ce4(0x69f3fe904f28a158ee014aac59fe07275f6836daef3894a933937365f59b13a2); /* line */ 
                    c_0x25384ce4(0x399ffa256d27680543f624f33be2a989888767d397a57570a592ade60f538df0); /* statement */ 
identifierOrCriteria = (
                        considerationItem.identifierOrCriteria
                    );

                    // Optimistically update item type to remove criteria usage.
                    // Use assembly to operate on ItemType enum as a number.
c_0x25384ce4(0xd53338ccfa476cc5a93a95feedb1500a0c55269f90ce53b788031cea63a4b2ee); /* line */ 
                    c_0x25384ce4(0xfdaff9b7da82994ca6ed555a57674f5d3ba47721bbb6b49e34776ffe7f668066); /* statement */ 
ItemType newItemType;
c_0x25384ce4(0xfbae750965e6e6144719d0286a049a4ad1624c8113ca7343fa9eb4f2108de0bb); /* line */ 
                    assembly {
                        // Item type 4 becomes 2 and item type 5 becomes 3.
                        newItemType := sub(3, eq(itemType, 4))
                    }
c_0x25384ce4(0x3d12394169fbd20bf1b6dd6397a7baf18f1d5dcb783ee8dbc91fefc17e9ec9d4); /* line */ 
                    c_0x25384ce4(0x6018e7deefb3b760e857eaec9bebd72a416fa431af345e9a921d7d92a8860abe); /* statement */ 
considerationItem.itemType = newItemType;

                    // Optimistically update identifier w/ supplied identifier.
c_0x25384ce4(0xa041a8be829c0dca8683171ffaffb7efd9f6f4f56597bde0255fed8d510eaeeb); /* line */ 
                    c_0x25384ce4(0xde6fba410bd366f1c37ee8543623b32c61b1a8747e58d7f6d7c2f69f18434e49); /* statement */ 
considerationItem.identifierOrCriteria = (
                        criteriaResolver.identifier
                    );
                }

                // Ensure the specified item type indicates criteria usage.
c_0x25384ce4(0xafbb0522cdc5d82fe910398e705be9a144e756440f55eba5d66d5a7ab82bae1c); /* line */ 
                c_0x25384ce4(0x0cc614317c0e01bfe9e4ddaed05b2fbde1d61076a315817c31d123a8ae00f2f8); /* statement */ 
if (!_isItemWithCriteria(itemType)) {c_0x25384ce4(0x1bc234fc7c622b48f4c7a280af57451fe484f92b2db7ea53cb232b9701a69f9f); /* branch */ 

c_0x25384ce4(0xc2e9213cb64947c0dc7ca6f0f68c79deaa83ab85c6e8aae37d5402954ea1746e); /* line */ 
                    revert CriteriaNotEnabledForItem();
                }else { c_0x25384ce4(0xb3421e1ccd2d6eac377b9aa193e4e039b7db0d3a436a45077dc373bb851f1cc9); /* branch */ 
}

                // If criteria is not 0 (i.e. a collection-wide offer)...
c_0x25384ce4(0x49e03a479afc47993b4e77a041061d2df966e248fc561059b598ffdb61fed8dd); /* line */ 
                c_0x25384ce4(0xb69f5ad4cdd2599d7269df439d61f7bab7360fc12cdf2217c860c7e0a089e88a); /* statement */ 
if (identifierOrCriteria != uint256(0)) {c_0x25384ce4(0x8b0cd129ac3337ae3925ae4b991f502890f01d14e025e1fc87dfdcc6a71a1a53); /* branch */ 

                    // Verify identifier inclusion in criteria root using proof.
c_0x25384ce4(0x0926d6668923db7218ec8de886f2123a298229a5d3c20749a9b406ab523a4ac5); /* line */ 
                    c_0x25384ce4(0x15df57dd189fdc7589c9df97ee33ae88cbab582e64890e49e2f86ef30b0f6b62); /* statement */ 
_verifyProof(
                        criteriaResolver.identifier,
                        identifierOrCriteria,
                        criteriaResolver.criteriaProof
                    );
                }else { c_0x25384ce4(0x99796f1261ffb3a3d7fd7c52a384e829d8b7a0393ed82257072fad07fa9acc11); /* branch */ 
}
            }

            // Iterate over each advanced order.
c_0x25384ce4(0x4674012575804463f4e9eb22ffbe556b8a34e20511137ff09316c076483e01bd); /* line */ 
            c_0x25384ce4(0x8df43668c6233f2f2d5662d8fe616d69a678151e829b012060534d2f68ecc22f); /* statement */ 
for (uint256 i = 0; i < totalAdvancedOrders; ++i) {
                // Retrieve the advanced order.
c_0x25384ce4(0x432524dba4d50a2f672f47ab85a8b42c149b94c0a25dec1c6e9915cec5c72916); /* line */ 
                c_0x25384ce4(0x4f4969b757e3dd17fa14471797f8a34029af9f6e9900506f5edb295b6b65db72); /* statement */ 
AdvancedOrder memory advancedOrder = advancedOrders[i];

                // Skip criteria resolution for order if not fulfilled.
c_0x25384ce4(0x7d8581f96d15f5de1da3f715fd40584d5ed651a3d7be5484f7ee48f6af633942); /* line */ 
                c_0x25384ce4(0xec82e33f89a68fea4eace1f3471606d3897fa4236df3608c87e5bf01db19296c); /* statement */ 
if (advancedOrder.numerator == 0) {c_0x25384ce4(0xed605e8ad6ecc4297fd01037260cd4d204c616f02cb03130b2bab4c9cb7837b0); /* branch */ 

c_0x25384ce4(0xc39c3e680299cb0254cba626c5b1bc65722398f374f7335e51e9460e15365a67); /* line */ 
                    continue;
                }else { c_0x25384ce4(0x23e04a24a207afc58b2b7d5996488f246e56b7e0175469b59279758a3e8f0f99); /* branch */ 
}

                // Retrieve the parameters for the order.
c_0x25384ce4(0x876902b109f604865d35ebaa0d86e99b275a1abbe3bc2b036aa5927891203462); /* line */ 
                c_0x25384ce4(0x967156536b28ed0fa233650ca7e6284272319723c3681da9f46487434899eec4); /* statement */ 
OrderParameters memory orderParameters = (
                    advancedOrder.parameters
                );

                // Read consideration length from memory and place on stack.
c_0x25384ce4(0xd27b45818b2158f96305b995bbb9e25e9d342abf2f00fdd4fc69d8bb187fa4d5); /* line */ 
                c_0x25384ce4(0xcdd530d59b570d9b7194b867104e65e4ef64aec17b3234c1deeb783cefd2cd04); /* statement */ 
uint256 totalItems = orderParameters.consideration.length;

                // Iterate over each consideration item on the order.
c_0x25384ce4(0xbadf0e3006a8d2cfc9f28224032fef3de8d2f4bac05d3bca9f6d58fa0a29d223); /* line */ 
                c_0x25384ce4(0x999b9fc867790c6add166bdb62c760240b28d2eb0a70b2e706dfd68e4b0dd66e); /* statement */ 
for (uint256 j = 0; j < totalItems; ++j) {
                    // Ensure item type no longer indicates criteria usage.
c_0x25384ce4(0x6d39994e2098035f3f68295389e0c21bae37dd168b76f13ecaa497a91d42535d); /* line */ 
                    c_0x25384ce4(0x48819531c2700b2ef736e180b2bce91f4cfcb15bb349887ee0266da5eac6e5c1); /* statement */ 
if (
                        _isItemWithCriteria(
                            orderParameters.consideration[j].itemType
                        )
                    ) {c_0x25384ce4(0xd6034c866f8e784fb36cd305883d62eb429b76eac2748081bd5f68ca2a6b06a3); /* branch */ 

c_0x25384ce4(0x3de7b2e3b546d725da15836080cd54ca3d95107dc32946299d8a136827073a18); /* line */ 
                        revert UnresolvedConsiderationCriteria();
                    }else { c_0x25384ce4(0x45b00c6b3d43414f28bc5f2ae13efbac743a767ffb440d3dc200c399f8e353db); /* branch */ 
}
                }

                // Read offer length from memory and place on stack.
c_0x25384ce4(0xbfc5acf19689f1d5ab1dd4a5ff0c5fceee33f82987a5ea479459ef0c8e46a745); /* line */ 
                c_0x25384ce4(0xbf3ee9474a1a2bb46db7115f5e2b8a9cbc7bdb0a8f2e413d151cc89d21295bc0); /* statement */ 
totalItems = orderParameters.offer.length;

                // Iterate over each offer item on the order.
c_0x25384ce4(0x928924988a95b04f52371c8324b30b9633aaad8a7ea064dddc97575ccc80a792); /* line */ 
                c_0x25384ce4(0x18563ae8d00cdf6baaa12cc80b2dbfc7915c4a4031cb827303d224138462e770); /* statement */ 
for (uint256 j = 0; j < totalItems; ++j) {
                    // Ensure item type no longer indicates criteria usage.
c_0x25384ce4(0x8a67064853958c2ede3243a3c01a8da56e5865ef24007b55144d56c37a955bf2); /* line */ 
                    c_0x25384ce4(0xafb1d1689ecc4c861866a076c14131a97e9af17ae01803ea57d935fe11c4bed4); /* statement */ 
if (
                        _isItemWithCriteria(orderParameters.offer[j].itemType)
                    ) {c_0x25384ce4(0xa5a119ee4ddaef1403c980c0b64efaf1ddfbb9dd2b43a9cc798fafba0fcd6d69); /* branch */ 

c_0x25384ce4(0x78dd531f6b380ac9f3f311f051e66db030938cf94a1415071e09323441eeecba); /* line */ 
                        revert UnresolvedOfferCriteria();
                    }else { c_0x25384ce4(0xd136933dc895fca818e5e2e3071d0d4d2a1535d2b97b907e7a05d3e2f5484e6b); /* branch */ 
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
    {c_0x25384ce4(0xac2b6179c8a724606980f8873c908476696b3a2bfc4bca7906e612d248e04030); /* function */ 

        // ERC721WithCriteria is ItemType 4. ERC1155WithCriteria is ItemType 5.
c_0x25384ce4(0xd7b576bb01a40a150784763c171f1eb9dd49301503c023073dfc00723653245e); /* line */ 
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
    ) internal pure {c_0x25384ce4(0x6133e74392aeac032734727e8bd781e06c95c53ead8dad007f7f56deb9c283a2); /* function */ 

        // Declare a variable that will be used to determine proof validity.
c_0x25384ce4(0x9d05390645ed50452d8d3d88333360bf8c81b9a22f0ca61e1329f41fad41f154); /* line */ 
        c_0x25384ce4(0xdcfcc500d4149f5f56eef0fbd09711e19b845b0341aed7d4a54985225d7b19c5); /* statement */ 
bool isValid;

        // Utilize assembly to efficiently verify the proof against the root.
c_0x25384ce4(0x3ae11614abdb7777dcd324ea4eb0fa1d9ae6175601d17c91b07850f67ee091b8); /* line */ 
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
c_0x25384ce4(0x1843512a10154b017c00d344d03611ba2a3db7e25f14b1c2ac4025a6b10491c4); /* line */ 
        c_0x25384ce4(0x3dcc65a106b046d71bb531dd8c7658df27b23d7ad5d9f8e9502425dcebd22854); /* statement */ 
if (!isValid) {c_0x25384ce4(0xab4b871a4517f7819a28f6bb1b805d1aad944823de89700522b5198af90c69ed); /* branch */ 

c_0x25384ce4(0x574d2398ac963e1a8d66c70862bf5f4ca8ccdd463df7e18886d86415283cee8e); /* line */ 
            revert InvalidProof();
        }else { c_0x25384ce4(0x08301aaffc65a7a4e685b82f29b8edd49a8490299d2d9c47807e6cbae24820ed); /* branch */ 
}
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0x7c438cf8(bytes32 c__0x7c438cf8) pure {}


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
function c_0x8cd5bf44(bytes32 c__0x8cd5bf44) pure {}


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
function c_0xbb492952(bytes32 c__0xbb492952) internal pure {}

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
    modifier isPauser() {c_0xbb492952(0x83c6efd39f24cc452017fb42cdf76f5590cdce0b0c9b94a0be6f10d47ca8a874); /* function */ 

c_0xbb492952(0xe23cf1635bf51b75b793a5f922219ce82ebde4b2ade4e2e8a7f36fe5069c9f3d); /* line */ 
        c_0xbb492952(0xc70ecec1efa6518b0d9f54bf0b70fb52f8244013362dd6386ed8ab3e74de6996); /* statement */ 
if (msg.sender != _pauser && msg.sender != _owner) {c_0xbb492952(0x4b18fa3b6bd5d118afeb862b06f560ebe7dbbba9e96b38e1f672204c3b5a4772); /* branch */ 

c_0xbb492952(0xff554aa7901919c7d6499f75c8d6d481b34157691405516c478d4716217983d5); /* line */ 
            revert InvalidPauser();
        }else { c_0xbb492952(0x5fa2ae3792b9299400df91e0f48be8acffc0ad4ed28ce423d0320935aed3552a); /* branch */ 
}
c_0xbb492952(0xdeec8b6a5fa63f05ff3efcd113fcc25e698f9323d472bb2026b8d7ae9796253c); /* line */ 
        _;
    }

    /**
     * @notice Set the owner of the controller and store
     *         the zone creation code.
     *
     * @param ownerAddress The deployer to be set as the owner.
     */
    constructor(address ownerAddress) {c_0xbb492952(0x72591274318fb305c67072d537bb9cce81d46f21044783955541433252dce743); /* function */ 

        // Set the owner address as the owner.
c_0xbb492952(0xe2546c80a5fee1a0e495e2a088514c6ec423badc949c471d83534c4760660cb7); /* line */ 
        c_0xbb492952(0x51664911b4c99e5f33c64cb04b9deb6e57f622457b6d2b20a30f8bc61d3c4329); /* statement */ 
_owner = ownerAddress;

        // Hash and store the zone creation code.
c_0xbb492952(0x491528da4de17538b1f1d0d4664c1d4c88aa1f8afbe23ddd72d413f652784120); /* line */ 
        c_0xbb492952(0x47b11193239db860b94fff75691a1f99c0998194d9072e391e02e3ca57784bc6); /* statement */ 
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
    {c_0xbb492952(0xdcbadf354cbed3db7e7ecbbf7f00cad25d023a7580ebfc5af7c8765af7fada40); /* function */ 

        // Ensure the caller is the owner.
c_0xbb492952(0x52ac194119b25e95f236a07df845f9d7081cf6832c62054a31638b80d75c3426); /* line */ 
        c_0xbb492952(0x27052446ef5e0c9d609cda828f4552e7deb13667fbae397fa5d934c32f7c8703); /* statement */ 
if (msg.sender != _owner) {c_0xbb492952(0x3fc89458b0aecab820f6f87d96fb51daa179d819e50f129f3602e485029c38cb); /* branch */ 

c_0xbb492952(0x8d62ce0ffe9578aa134b9392dcd50fc3f1536aafb58030c51f682dbdf4686bd3); /* line */ 
            revert CallerIsNotOwner();
        }else { c_0xbb492952(0xedee65d64a3db8daea9b8773da9e217b82f5243c1e2f6f60607e7a8ec60576aa); /* branch */ 
}

        // Derive the PausableZone address.
        // This expression demonstrates address computation but is not required.
c_0xbb492952(0x630f4438b484bf6dd4f087279ce6bb88d81d5a38668a3965485830348dccf9d3); /* line */ 
        c_0xbb492952(0x6ae2787732624203e6e4ba7f68d1a5f4305ceb42c1eb0b1f6177c2b62a6d1c6d); /* statement */ 
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
c_0xbb492952(0xb0108b8adc0ceca3a7b166a37595c27c3e75a1ca98a6729188a9cebfc2073a74); /* line */ 
        c_0xbb492952(0x4871931336fe14bcdf30b6f29a22fd425de9f9d0c928c6e6defc1eb090633e49); /* statement */ 
if (derivedAddress.code.length != 0) {c_0xbb492952(0x2357e15d39458fb63f4e37fa8bdb5b814c32044dc9f9a171e062075166c8d223); /* branch */ 

c_0xbb492952(0xeb428362a62a8387b3b90465bef279e43eec01c50727ce2b5c72921307485383); /* line */ 
            revert ZoneAlreadyExists(derivedAddress);
        }else { c_0xbb492952(0x50d2771b4b9bba13ae4b47b0f1b88f5769b605c2f2bf88e0614f7fc5e0b98fd3); /* branch */ 
}

        // Deploy the zone using the supplied salt.
c_0xbb492952(0xaa649a556cae3f0b24bd7c95b11cba55ca5bc7797c385637b276236dcc4a3544); /* line */ 
        c_0xbb492952(0xef10a035445f3421a111bde157d6b676ee736a7d1834e8a1f6d4197f2f255aa8); /* statement */ 
new PausableZone{ salt: salt }();

        // Emit an event signifying that the zone was created.
c_0xbb492952(0x90825826b9f8099fb07a18e7dd85ff70afc537cd55eafecb2048c28d2461fd84); /* line */ 
        c_0xbb492952(0xb3ebb490ac8c44138de788eb782cac8febf3ebc011fb766595318e223fb3d86a); /* statement */ 
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
    {c_0xbb492952(0xe571883a437452508b5a4991fc1baf3235f1a4e08632cb8a8025bd1f2c9177ed); /* function */ 

        // Call pause on the given zone.
c_0xbb492952(0xd7a75928d762079e55339d00985a564120ce0adbfc575bb95b03e2b818fbefc1); /* line */ 
        c_0xbb492952(0x134347ed910ed001d3a210b5f1c9a0a1f6e405a60fdb1da0c5b5d9d8a58a3c01); /* statement */ 
PausableZone(zone).pause(msg.sender);

        // Return a boolean indicating the pause was successful.
c_0xbb492952(0x520d3cb4f806a9c704dceca211ac04067cc41f37381fc581cce713fd2b5f4d95); /* line */ 
        c_0xbb492952(0x196a0aaec79291b88aabe286e0f364508c38740208f07e36f1c137a1952bbe1c); /* statement */ 
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
    ) external override {c_0xbb492952(0x80e64e45c50a738dc8adc4e617ddb76665b4fdb9a5c2cc0fe58e65e7415aefcb); /* function */ 

        // Ensure the caller is the owner.
c_0xbb492952(0x92224a5b17581523dc29eda4d1f3b8a517e8d1007b4e6590e6d947a0e772d720); /* line */ 
        c_0xbb492952(0xdcbd2bc01328a543080c7dd4bbf08fc0574442e0bf09c3cebde490fc2a0318ca); /* statement */ 
if (msg.sender != _owner) {c_0xbb492952(0x679c096b2c7a95ca8bdb3a7b939274c1fa3eed8eca2518fc2fe1783e010d9df0); /* branch */ 

c_0xbb492952(0x36f40123e1530112168c3865b48acfe3d982eee16d78613c778eb13973577a68); /* line */ 
            revert CallerIsNotOwner();
        }else { c_0xbb492952(0x8165109f3a9248fd7d6b49136e8425646dba67ba6f5b8049ca9e93d708f1d1f8); /* branch */ 
}

        // Create a zone object from the zone address.
c_0xbb492952(0x6e85dad8c8b28396607733663f3ff658020a497517f0c1583f190983ca195381); /* line */ 
        c_0xbb492952(0xb2666ca64b9eb43ff4d9fc0d856cd0c86057dda2e6ead29c27f04781f538689d); /* statement */ 
PausableZone zone = PausableZone(pausableZoneAddress);

        // Call cancelOrders on the given zone.
c_0xbb492952(0x7c788dae4dae478c9235ead5b56743cd0457bd9cd05e893daf43b3210124cd61); /* line */ 
        c_0xbb492952(0x25932e123766ce490dbb3bca7bd3ab379babe0cbe43b9642b2fd914e3b04f9ee); /* statement */ 
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
    ) external payable override returns (Execution[] memory executions) {c_0xbb492952(0x89cd655fdedf14c5ed6198bd7911da9de5b386dcb25748fed6b376fd66920551); /* function */ 

        // Ensure the caller is the owner.
c_0xbb492952(0xbdc1ef3cd2c9d13eb289f60927b9531b8399b646d09bca58e0eab2e3087db7bb); /* line */ 
        c_0xbb492952(0xa877da2a8adbfe641895fe2f10f33a05f417a603e50202a9281fc0418f8d807c); /* statement */ 
if (msg.sender != _owner) {c_0xbb492952(0x9984f7acb09aecdd3e5fb58ad641c12b48fbc6d009b669a0cd273a340fee0bd7); /* branch */ 

c_0xbb492952(0x96ec1fd5de54c81619063f1853c3b999e89722425730e2a806f567e56a32d1bd); /* line */ 
            revert CallerIsNotOwner();
        }else { c_0xbb492952(0xafa5712d9515d464ba6aa7073f090df17fe5465d4223bd9b941faa686991f9c9); /* branch */ 
}

        // Create a zone object from the zone address.
c_0xbb492952(0x5910881027bcabb10778e4d5b5d91e951a4e8b963ad4093f5b789dbc8961d8a2); /* line */ 
        c_0xbb492952(0xa5ed20982b33e274b5f4199cceecd94544851a0e8dafc510d1ac5def9da984d2); /* statement */ 
PausableZone zone = PausableZone(pausableZoneAddress);

        // Call executeMatchOrders on the given zone and return the sequence
        // of transfers performed as part of matching the given orders.
c_0xbb492952(0x6b7c579b3aa0d9881151367c2ffe9c037fd327d12f8a428291a4f539b6763a27); /* line */ 
        c_0xbb492952(0x3a819ac589efbf8c2f4390a766646cbf228046b07be91c2951154134f03a8c22); /* statement */ 
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
    ) external payable override returns (Execution[] memory executions) {c_0xbb492952(0xc3423e027741516f724b3b43f27311c2a8b07c28133b85b40141a3b6b7cb369c); /* function */ 

        // Ensure the caller is the owner.
c_0xbb492952(0x1805a99b949405b408619c750b140d30f4b8440411b550ef425c6bfb09db5413); /* line */ 
        c_0xbb492952(0x22870a65e30c0b4ec5404d93af8a333f384f8395af1c05c5762dd3e4dd034055); /* statement */ 
if (msg.sender != _owner) {c_0xbb492952(0x5a731f85fa1b5a4eba8675f3ff0d5dec5094d6ecc298262c6cc356e01438844c); /* branch */ 

c_0xbb492952(0xcb6a45150ed88ffc4c80883a5facf78c26dfaed255f29dd55b38c07657a1ad74); /* line */ 
            revert CallerIsNotOwner();
        }else { c_0xbb492952(0xb5a9efda9850caf963b55722494a8a0e4830327361a985e0f8b9fdf8c25d7b95); /* branch */ 
}

        // Create a zone object from the zone address.
c_0xbb492952(0x33fac074f97a44e56f8fce2aa36ddfed9c9af37ca160ad185a834338b9cea170); /* line */ 
        c_0xbb492952(0xdcea9545b99f09da4a2e935a626b0e471f71127b0215593c8893d3090769e590); /* statement */ 
PausableZone zone = PausableZone(pausableZoneAddress);

        // Call executeMatchOrders on the given zone and return the sequence
        // of transfers performed as part of matching the given orders.
c_0xbb492952(0x0842151949eaf281ab793100ed220bf70d4e9d53c0336cfc7887a31871ff3ea8); /* line */ 
        c_0xbb492952(0xb4b9d433cb0b3e55c555644a5ab6a921c3a142c455bbea4afef8ec83f606b0af); /* statement */ 
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
    function transferOwnership(address newPotentialOwner) external override {c_0xbb492952(0x89222b8291a4c8390f09b000f78129f87560e3277629f7aa8afd3e46dcc56192); /* function */ 

        // Ensure the caller is the owner.
c_0xbb492952(0x3e9bb55a0a10a4e1a569c6fd18781425b1aa0d389c8ce9aa01f923622c442df2); /* line */ 
        c_0xbb492952(0x06f1b58f40f2f5b0e183086fbac3b089952561002870c075d9f35d358d53e55a); /* statement */ 
if (msg.sender != _owner) {c_0xbb492952(0xf175500c181d8cb8bd06d22f68ae417914dda38ce3887009dda2ff607cd9aeaf); /* branch */ 

c_0xbb492952(0x6b7ccaf7ca595b5da220c05d4c8d65bfc15aabc35769a219e53554b6d4bc56ef); /* line */ 
            revert CallerIsNotOwner();
        }else { c_0xbb492952(0xee2f79907d3ac84ed2ffb2f3ee3a4f6bdc1a16e20f26880943756ae2db2a52f9); /* branch */ 
}
        // Ensure the new potential owner is not an invalid address.
c_0xbb492952(0xf671e42ed23cdade490c9eb9c50875f52de595c09423ebe894a80758ea886f0a); /* line */ 
        c_0xbb492952(0xeeb1a839229771507589ab1c9b3db56aed084bcd13fb470fc0344f1b483f8a73); /* statement */ 
if (newPotentialOwner == address(0)) {c_0xbb492952(0xd537d52203e5da27f478f0d3a415631b42f827a7d044235a8e2fa99eb605c34a); /* branch */ 

c_0xbb492952(0x957770a324153979060ecce3f127bc1a2d54464d4b79255e14c977ffb33df8ae); /* line */ 
            revert OwnerCanNotBeSetAsZero();
        }else { c_0xbb492952(0xe20f8286f5184562acc03d48ef474212f15e6e0dab80983fb325b906ef1d387d); /* branch */ 
}

        // Emit an event indicating that the potential owner has been updated.
c_0xbb492952(0x635c69ecb5f86f3ea198c2b02b4e7e314d006a882579dd2b0a85e75cdd194a12); /* line */ 
        c_0xbb492952(0x63a6326698679603a7b2fae63a1fd6ab2da62b9942d5d221bed394749667bd4b); /* statement */ 
emit PotentialOwnerUpdated(newPotentialOwner);

        // Set the new potential owner as the potential owner.
c_0xbb492952(0x6a605a26b63c41a1677ee8e6e1fdf77c74f155a106117fcb05fa35d7a7db0404); /* line */ 
        c_0xbb492952(0x35e8fdb24d367307d605d32a11d05e153a1e16a0c2df39f17adbf220d2838821); /* statement */ 
_potentialOwner = newPotentialOwner;
    }

    /**
     * @notice Clear the currently set potential owner, if any.
     *         Only the owner of this contract may call this function.
     */
    function cancelOwnershipTransfer() external override {c_0xbb492952(0xcb2321a29da295bf0682073e12240c2a1dd36edafb26bd4a16a0ba16f6afbf5a); /* function */ 

        // Ensure the caller is the current owner.
c_0xbb492952(0xc2276ee92a2604b5a6c3912e65ca773c4ff50a80ec7d1a5f4f4ba49544aeda97); /* line */ 
        c_0xbb492952(0xb0327c82b300387544da63cd120272220b90c1606252b891f899725cbc26553f); /* statement */ 
if (msg.sender != _owner) {c_0xbb492952(0x19f6a50e441c29854358ca97d7fde56f2d14b4f7b65c74ceaccc0624f03755b4); /* branch */ 

c_0xbb492952(0xefb68079e422648f9eec27382fbc7fd403a04e04727408e720a3f7d2469539bb); /* line */ 
            revert CallerIsNotOwner();
        }else { c_0xbb492952(0x262c7d8c6a5dd90272e639fd07a608a1d4eff7bdd2a5f5877ccf1e32127951e5); /* branch */ 
}

        // Emit an event indicating that the potential owner has been cleared.
c_0xbb492952(0xb61b431e37f37e19c36c46609431ada9b1a08f9075813421061a6b25f5e9012d); /* line */ 
        c_0xbb492952(0xe92259223b8d5b1c7f4a7d9efe23f5ea99cdd23e4378dcb9ba7162e8ff173a43); /* statement */ 
emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner.
c_0xbb492952(0xe4ade6e71a6df3e766cc4289a30ca015b2c5a24e9bee5f5b4370c7772c975dd1); /* line */ 
        delete _potentialOwner;
    }

    /**
     * @notice Accept ownership of this contract. Only the account that the
     *         current owner has set as the new potential owner may call this
     *         function.
     */
    function acceptOwnership() external override {c_0xbb492952(0x2f4592b338931e5a45dee0dfd56faee55fb12d9468a413fd71e3cde2d5e34a0a); /* function */ 

        // Ensure the caller is the potential owner.
c_0xbb492952(0xc7454ab47449402730165365131855a712e7e2d103fcbb372563ac0836d5c405); /* line */ 
        c_0xbb492952(0x8f4d26bde0a8e2c9bf91a871ca56a8379b829c815e7794acd1477cb5a4e74b85); /* statement */ 
if (msg.sender != _potentialOwner) {c_0xbb492952(0x670d913f882ed0c047df056a9fdbb5aebb309f85f177fea5665a314a0c1aba81); /* branch */ 

c_0xbb492952(0x5aa4ae65ed05cee626ad5f2222231b47f89436b65b5507939d8851b99dbe3863); /* line */ 
            revert CallerIsNotPotentialOwner();
        }else { c_0xbb492952(0x18d6e7a1c92ebec1e83021f2306f5e2891dc150e9d2e9a89435bed6d7f715f03); /* branch */ 
}

        // Emit an event indicating that the potential owner has been cleared.
c_0xbb492952(0xd341d8b8ca30a81d8a0943be18dc44ebe1f8f2c8326660f7dbce4be9ac15829d); /* line */ 
        c_0xbb492952(0x11dc934ac60ec36d48f422f469378050cd529fe5056b95ff508a1741d3f0110b); /* statement */ 
emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner
c_0xbb492952(0x0f63fd8508b65ed8ece9771c4e5b46b5970f0a26a62bba890c888e5474f95817); /* line */ 
        delete _potentialOwner;

        // Emit an event indicating ownership has been transferred.
c_0xbb492952(0x5d0b2c175382d709ca6d1dc8d721f5984191e3c1b3c32d9c28b5f262dd0ad24f); /* line */ 
        c_0xbb492952(0x6fa0e666ebd2a539f6bfd28ff5da32883cbea496bf4f560c29c379b55601ca5c); /* statement */ 
emit OwnershipTransferred(_owner, msg.sender);

        // Set the caller as the owner of this contract.
c_0xbb492952(0x1a2de7f254dd14819f8d70508410e0d55cfeaadf2b3e8de3bea37ffd13c45947); /* line */ 
        c_0xbb492952(0x442f0ff590835b5b0d1fd3a7cdf17e2c053e9f20f45a613fb0df37b5b67b627a); /* statement */ 
_owner = msg.sender;
    }

    /**
     * @notice Assign the given address with the ability to pause the zone.
     *
     * @param pauserToAssign The address to assign the pauser role.
     */
    function assignPauser(address pauserToAssign) external override {c_0xbb492952(0xcc6ae0a1b19ba16dd987044e5833b710bb5f0352e0057368ed8317d7aecf50a2); /* function */ 

        // Ensure the caller is the owner.
c_0xbb492952(0x97f1a9bc36de47460723144e938bb2ad3d8206a32b5a67d00c08e07d75d4783c); /* line */ 
        c_0xbb492952(0x1b0f690822836b06820142ff9e7c2b497374dbfdfcd454dd4018a0f105e0b409); /* statement */ 
if (msg.sender != _owner) {c_0xbb492952(0xcad0eca9fab95f193738150e276af0bfa93e6ed7a52bb21bea8ad914bb8adeb0); /* branch */ 

c_0xbb492952(0xfbf97d5d8745c1e455f22e25d6ca5a5c0b42ad11fe1d5dd8eb4bd6c0660eb003); /* line */ 
            revert CallerIsNotOwner();
        }else { c_0xbb492952(0x91e2ab12ac7bc2c4151d2ba3622cfe7c8afaa75993965aeb0c66bd0fd3d959cd); /* branch */ 
}
        // Ensure the pauser to assign is not an invalid address.
c_0xbb492952(0xeb72b56826de710bedc98e86648c488d882b93f90b75ad88e9902e0b3cd6c710); /* line */ 
        c_0xbb492952(0x3020f24147dd358387ffd0d1b2d0b1e7b3d2d558100645f96516622b6ab21e47); /* statement */ 
if (pauserToAssign == address(0)) {c_0xbb492952(0x3309cc06e8268a9b6da2b008845c98a52ca7791ba75a7a4e16a875934abfa4cf); /* branch */ 

c_0xbb492952(0xd1cea667513464270e6be4ced63e98494f87344ec60ed08a25497a39ea578c25); /* line */ 
            revert PauserCanNotBeSetAsZero();
        }else { c_0xbb492952(0xb974e7f0e18959f68dc60a7a38aca68c850bc63e0f5fe9345db6341d67a4c9a5); /* branch */ 
}

        // Set the given account as the pauser.
c_0xbb492952(0x7870f838f7e2e19917ecd03dfcabbd312296f736f494e85e73c0bfab0e8ad72c); /* line */ 
        c_0xbb492952(0x394eabfb96cd314695f57f73d4d046f97c0d2b4a2fe5f42648906195ab3b358a); /* statement */ 
_pauser = pauserToAssign;

        // Emit an event indicating the pauser has been assigned.
c_0xbb492952(0x4b04d298611b4fe91e77dd1ecb470776d9f0c2c10640a4a0d7e05a50f19452d0); /* line */ 
        c_0xbb492952(0x4c1434e8ebedb7491a099249badd6af5d6770d8cba33fb11d0d6fa66fc7a4a0f); /* statement */ 
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
    ) external override {c_0xbb492952(0xcad8b77dd6b829d1a30630f2d3757c03eb2e8aefce338b13f747f42366d780af); /* function */ 

        // Ensure the caller is the owner.
c_0xbb492952(0x2efa3274177933897655e1522f56ed1f2ee7584249d5fc9b359c606c88c4c024); /* line */ 
        c_0xbb492952(0x1d4add6b30111c5b170f0c525fec4c0f7e34fe6ec4216cee29c913593b3e6a88); /* statement */ 
if (msg.sender != _owner) {c_0xbb492952(0x5a98f11747a1d573f34f6a82d05355c4d1e74f297ac3ad8f289b943b5b7ae998); /* branch */ 

c_0xbb492952(0x3406bc00d792694d78340a01766db49e095414d2a7fdbd01cd94bfdee8c577fd); /* line */ 
            revert CallerIsNotOwner();
        }else { c_0xbb492952(0x4109dc350655b4def8f66f62097f33757379fa67895745e1bf97e782d84cb924); /* branch */ 
}
        // Create a zone object from the zone address.
c_0xbb492952(0x261880374a2b8c8e427e3b378f5e3fe0f3fe23f70c4edba346e55e4296eba53a); /* line */ 
        c_0xbb492952(0xbf86ef46e704358c0a227804e35abf0a5b92fe188416b06aa823129730f656d4); /* statement */ 
PausableZone zone = PausableZone(pausableZoneAddress);

        // Call assignOperator on the zone by passing in the given
        // operator address.
c_0xbb492952(0x594156e72cae9bc86b21d8d2d8a4e0d04de87a3fcea60452b83e5c7bdf92e5f7); /* line */ 
        c_0xbb492952(0x99c092e904ab087784cd0564876bc38cb4fa842aba60c5d2401acf7e7e625a95); /* statement */ 
zone.assignOperator(operatorToAssign);
    }

    /**
     * @notice An external view function that returns the owner.
     *
     * @return The address of the owner.
     */
    function owner() external view override returns (address) {c_0xbb492952(0x8ca4b99f332b47a8f022357119c9927a514ed5eeef9a52a13c30c29a5bcb449d); /* function */ 

c_0xbb492952(0x7b7754b47f5cfe88cdb4ffc22155aede09d3c3285369080ef336a2b9b6dbfcc5); /* line */ 
        c_0xbb492952(0xbe4cf8f71f363bc7815ea1d2c0180a6a3cd7092f80edabb65144791fa5e59318); /* statement */ 
return _owner;
    }

    /**
     * @notice An external view function that return the potential owner.
     *
     * @return The address of the potential owner.
     */
    function potentialOwner() external view override returns (address) {c_0xbb492952(0xe9c93a82fb1b466038e5d3120e1e585838a8ae1134b0e00e20facdc885380031); /* function */ 

c_0xbb492952(0x851ed5830a2633de0376d45e57ceec6d165a1d2732e10f2a4b2c01b26d7f419b); /* line */ 
        c_0xbb492952(0xab265e0e24d640b8a40f42691a7b9bb9b99dc90f45af3a0cb5b1a2d1edfa9af4); /* statement */ 
return _potentialOwner;
    }

    /**
     * @notice An external view function that returns the pauser.
     *
     * @return The address of the pauser.
     */
    function pauser() external view override returns (address) {c_0xbb492952(0xefe6ac705280631c6f4e0a982370883558efbe732c30419c11ed0422fd4932be); /* function */ 

c_0xbb492952(0x21e9dd8726199172794c35fb8214e6f908e16c9cd3f5106c4db5390d1351454d); /* line */ 
        c_0xbb492952(0x42f8bbe734244a607e25ce867d49418b1df17a9f3b9685f0247cd62b7b49b1ef); /* statement */ 
return _pauser;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0x2ec02aca(bytes32 c__0x2ec02aca) pure {}


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
function c_0xe010e1cb(bytes32 c__0xe010e1cb) internal pure {}

    // Set an immutable controller that can pause the zone & update an operator.
    address internal immutable _controller;

    // Set an operator that can instruct the zone to cancel or execute orders.
    address public operator;

    /**
     * @dev Ensure that the caller is either the operator or controller.
     */
    modifier isOperator() {c_0xe010e1cb(0x71a1a6831f6e3ca33e849abb026230bfc263a7b1ca05ab986bc895460deb8a4c); /* function */ 

        // Ensure that the caller is either the operator or the controller.
c_0xe010e1cb(0xc9b9d7a5584880b5e64ae74b1c8ad7a0b982ac38a509fd66af7ea8d4f0f55f6e); /* line */ 
        c_0xe010e1cb(0x271748f5a31b00d52eff22acd28e6a5b8f974cce9b949a1e800b06689ef563a4); /* statement */ 
if (msg.sender != operator && msg.sender != _controller) {c_0xe010e1cb(0x9a6926f2b9f03250afdeb1c57f0d3ca8859bbfc91fb98ec46be6a4258941412f); /* branch */ 

c_0xe010e1cb(0xfa687bfd3e210ba1db58470486ddf4200f0b3e44f453d2b80ce6a5be0b5999a3); /* line */ 
            revert InvalidOperator();
        }else { c_0xe010e1cb(0x58ba16277ac8fc837f48a23ff06f6ad4809c0c25d3aa572548037d3b115d42a9); /* branch */ 
}

        // Continue with function execution.
c_0xe010e1cb(0xa9ef4ce958ca3851059967d45669852446c950f02956ed319b437b88acab43d6); /* line */ 
        _;
    }

    /**
     * @dev Ensure that the caller is the controller.
     */
    modifier isController() {c_0xe010e1cb(0x9f709fabc65aaac16b83b99d66e1a325a494ee374ece421300bc6006bba48982); /* function */ 

        // Ensure that the caller is the controller.
c_0xe010e1cb(0x78cbc6dc30f5fb9ed61b4fe90d8f75af64fc44ef3e2369885abcc2a6fdc11eda); /* line */ 
        c_0xe010e1cb(0x90f44b43183cec983601c85e3a481fbe234033caf9df5c41ef521f133c326c27); /* statement */ 
if (msg.sender != _controller) {c_0xe010e1cb(0xad1f9b667c41953eb03c19c7f3a5fe160c4b5c291ed6410c6e0e054937047b48); /* branch */ 

c_0xe010e1cb(0x72828f93cb427488e3d2d9c09b0363f91318593f14190083e0651eeccc2729c8); /* line */ 
            revert InvalidController();
        }else { c_0xe010e1cb(0x050d2d35813f58792e99d9e2a1e496d2a0626a9a9bfa2fb67b95b628e751b08f); /* branch */ 
}

        // Continue with function execution.
c_0xe010e1cb(0x8281903d0cfd1278020b162f89c59e6c060b6aeaec043c64e4879bfc60488fb8); /* line */ 
        _;
    }

    /**
     * @notice Set the deployer as the controller of the zone.
     */
    constructor() {c_0xe010e1cb(0x61477b84bb18d10b24c5170f74282eeb44f990eb0e47645184d07b34812720b2); /* function */ 

        // Set the controller to the deployer.
c_0xe010e1cb(0x3e4e892e99bcab5c90c4036a92a58c4b205cb4ac50bb086b7a7724701941dadb); /* line */ 
        c_0xe010e1cb(0xea18692938a3c7f41d55c44d466e8586743ac3f37de0aa44c6d465db9b086dc7); /* statement */ 
_controller = msg.sender;

        // Emit an event signifying that the zone is unpaused.
c_0xe010e1cb(0x09b1723a4457cdfe425c0fd0057e5369d92d340a8562eff64ad803ece1f96300); /* line */ 
        c_0xe010e1cb(0x6f7469fbd6b04c6406ed2cbede46fc0158bc8ae5d97ad752c0eecca3d8ef7163); /* statement */ 
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
    ) external override isOperator returns (bool cancelled) {c_0xe010e1cb(0x21d5f1b43765cb703ce02fa46a3de57817b923c21dbe58b326ecaf862ac97b8a); /* function */ 

        // Call cancel on Seaport and return its boolean value.
c_0xe010e1cb(0xb16d49ab934b4e4993203153da010be191caf134ea15b1eb8f461140c332bc10); /* line */ 
        c_0xe010e1cb(0x3d44fe666506df299cafdf87dc09180467035da6bb947a3c597f9cfe60fca5a5); /* statement */ 
cancelled = seaport.cancel(orders);
    }

    /**
     * @notice Pause this contract, safely stopping orders from using
     *         the contract as a zone. Restricted orders with this address as a
     *         zone will not be fulfillable unless the zone is redeployed to the
     *         same address.
     */
    function pause(address payee) external override isController {c_0xe010e1cb(0x7019da723e7d6ee490bcb23cfcf31cc1edf431a29850bcd1acce86f0507c35d7); /* function */ 

        // Emit an event signifying that the zone is paused.
c_0xe010e1cb(0x4d815885dfa96165c1a4db52a9ddf19bf3804adab3da60839dfad58633422185); /* line */ 
        c_0xe010e1cb(0xff68d619769b93fcb0533079cb8a167ed5ee4ba57e9b626a0b9a2300f6936cc6); /* statement */ 
emit Paused();

        // Destroy the zone, sending any ether to the transaction submitter.
c_0xe010e1cb(0xb0019e11a6614f1275c97ea3bdbef774e11d32653409dd8490272150990470ed); /* line */ 
        c_0xe010e1cb(0x06418c306941ca18bcb6b55c94b2a69659c064d31c0f0070c481d9b71812cef4); /* statement */ 
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
    {c_0xe010e1cb(0xd934712b41919a644f42bac9f02792a1f8d91d681c506831006408fac7d72570); /* function */ 

        // Ensure the operator being assigned is not the null address.
c_0xe010e1cb(0x3d6d0878934fc588f212a24c0b19120b5a2ef7f7b9b9f161874fa5c420d2b019); /* line */ 
        c_0xe010e1cb(0x84d280a20ee157e71beec4ff1ed03158f4eeb666dde3e4ce987de78a1806ea3c); /* statement */ 
if (operatorToAssign == address(0)) {c_0xe010e1cb(0x6c39e086f7c5e46ccaa38a7274de0c3599b4b827ffc0e8019d7190cfe93bad8e); /* branch */ 

c_0xe010e1cb(0xb281f1a2cd92167e47cf4b611e655353e5f56b13d42ac867c9dd7b0af5691ced); /* line */ 
            revert PauserCanNotBeSetAsZero();
        }else { c_0xe010e1cb(0x526733e7e0bdce9be2e7f3cdf15f07e97a2fe017e863c9fcf94ba3ebb69ee56d); /* branch */ 
}

        // Set the given address as the new operator.
c_0xe010e1cb(0xe216cd49f268b0f630916e7151c4fe2fbc6277663c7e7966c1baf50b10eb0ffc); /* line */ 
        c_0xe010e1cb(0x5fa60043014f4a377fabd64295c15517fad4dfa0b875811f6c27657a87c23c7a); /* statement */ 
operator = operatorToAssign;

        // Emit an event indicating the operator has been updated.
c_0xe010e1cb(0xf39baa1b3081b8014bbf293c374b32f8b49441185ffb7bbde828d0fd13836caf); /* line */ 
        c_0xe010e1cb(0x0db437392f684ef1502e8a42f8becc101287ec7dd6789af9933bf04ddf9d2be9); /* statement */ 
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
    {c_0xe010e1cb(0x440c814ff53f5bfd57c3fbe042703d19f2510ff9e182ac328c528721f7d1e96f); /* function */ 

        // Call matchOrders on Seaport and return the sequence of transfers
        // performed as part of matching the given orders.
c_0xe010e1cb(0x1b608b9a19d94ad079a89d9ac88c969785b96cbe9182d22f380177b8c7437ed9); /* line */ 
        c_0xe010e1cb(0xefe331386034f25cda1dd8181356d8662bc96c90540244aded24d2eaf617dd5c); /* statement */ 
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
    {c_0xe010e1cb(0xcd788cebe56773fc6453b6719f33cb3758efd014124fdc7a5e2db70a490f089e); /* function */ 

        // Call matchAdvancedOrders on Seaport and return the sequence of
        // transfers performed as part of matching the given orders.
c_0xe010e1cb(0x1a4f284ea01a54026df75e296638d5d7136b1da6923920ad89e24e6b77529551); /* line */ 
        c_0xe010e1cb(0x93cae6a81607ff9b94cd5a6c885f25fa0e7dfa38296192c3b7f844e79747c117); /* statement */ 
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
    ) external pure override returns (bytes4 validOrderMagicValue) {c_0xe010e1cb(0xbb4aee114ef50f72589e152519b8268cdc21446c9e074c7a610b1e32b2e56969); /* function */ 

c_0xe010e1cb(0x03c5cf6a7af6c4d18e0290cca790c0836cd8db15b204a1de35ff21d380cfc2fa); /* line */ 
        orderHash;
c_0xe010e1cb(0x7443042149eafa537d70737d0350878e3340b5bc93ba2c282b178aae3fd41105); /* line */ 
        caller;
c_0xe010e1cb(0x294aa134106496ef23240ac0ca69c3a30fde666e8ad8a4830a69722cf1116248); /* line */ 
        offerer;
c_0xe010e1cb(0x5374a1e690ba28ff7a3a4da404ced2fd7b3bd4f83c5ade3adbd5a79313a62304); /* line */ 
        zoneHash;

        // Return the selector of isValidOrder as the magic value.
c_0xe010e1cb(0xa3b1476735faaf76edf16b9c8212832b77c008653404cfd9a7f824eeb079aa5c); /* line */ 
        c_0xe010e1cb(0xe2171ee9b62244b7574f7888394321a276d6872e9d6a801a9e64ddede337287d); /* statement */ 
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
    ) external pure override returns (bytes4 validOrderMagicValue) {c_0xe010e1cb(0x63caa175d1ba25f27ec5eae6c969239acb9df20dbfede7aa9539c3544ad61339); /* function */ 

c_0xe010e1cb(0xf60c0cb282c8628cfec6f3f602338edc6b1ce82eb8d82297a70443ecbc78d343); /* line */ 
        orderHash;
c_0xe010e1cb(0x5a1c5149dbc0799e1fa9a4860def1a5d5315ccddc31187477b65312986d9fca8); /* line */ 
        caller;
c_0xe010e1cb(0xdfb1970c27162aa479b374d26fdb7cb9c7a0a23e72a64d6ea862f787749a9bf5); /* line */ 
        order;
c_0xe010e1cb(0x4f2f90dd81db2a3102a87a46ab74986d4c754fb77ff4e57a2a3eb8a41104d338); /* line */ 
        priorOrderHashes;
c_0xe010e1cb(0x1230d19a8cf76eab63c7d6179a8dc7c0e74306696ae923ea63aa3e6ddcd15f8c); /* line */ 
        criteriaResolvers;

        // Return the selector of isValidOrder as the magic value.
c_0xe010e1cb(0x6cb5174157578964ec994db75399f8acd2c9ee788fd0d6643bff0e93e075ae33); /* line */ 
        c_0xe010e1cb(0x427aa302840f1e52a3a7bb87063f7ddf6ff3940564546b03415e780d10a678df); /* statement */ 
validOrderMagicValue = ZoneInterface.isValidOrder.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
function c_0x1b3e1972(bytes32 c__0x1b3e1972) pure {}


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
function c_0x163f0b63(bytes32 c__0x163f0b63) pure {}


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
function c_0xe87a24f9(bytes32 c__0xe87a24f9) pure {}


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
function c_0x11b7671a(bytes32 c__0x11b7671a) pure {}


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
function c_0x6eb19d3c(bytes32 c__0x6eb19d3c) pure {}


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
function c_0x52e9c1ed(bytes32 c__0x52e9c1ed) internal pure {}

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
    ) internal view {c_0x52e9c1ed(0x364b664f6b1a0920af399d2e7ac1456197f117da4c5cce34b6d3a9ce4a108c54); /* function */ 

        // Order type 2-3 require zone or offerer be caller or zone to approve.
c_0x52e9c1ed(0x40d95095f20b27864eba153c3b61a76bbdb5a2cc7ccb3aa4d217baedffef7263); /* line */ 
        c_0x52e9c1ed(0x64dc4bf497995909571e6aaf8794fc1a4bbbf8b7d40b7a95bc7b8cef7336db7b); /* statement */ 
if (
            uint256(orderType) > 1 &&
            msg.sender != zone &&
            msg.sender != offerer
        ) {c_0x52e9c1ed(0x6f0ea6d9bcaacf5632bb307548b4b80ab7cbbc2c170eab6887d4a99228e90702); /* branch */ 

            // Perform minimal staticcall to the zone.
c_0x52e9c1ed(0x14c798e3cf94a9fdcd5086263ee695c890f2dc002efbd22d469bbf6afd988fa9); /* line */ 
            c_0x52e9c1ed(0x4d03487f9dcf5e9f07b99d9d4483240c9b8aa70131ef6f675346139ea093c966); /* statement */ 
_callIsValidOrder(zone, orderHash, offerer, zoneHash);
        }else { c_0x52e9c1ed(0x52fea9e2cb9398c6dc82aa91b73e2454dac6bafeec16ee32166b3ce62426042c); /* branch */ 
}
    }

    function _callIsValidOrder(
        address zone,
        bytes32 orderHash,
        address offerer,
        bytes32 zoneHash
    ) internal view {c_0x52e9c1ed(0x8d973ee55b388a1c009b44f6f6fd8dda34f6e86de61376c873d4f56f99d0d8dc); /* function */ 

        // Perform minimal staticcall to the zone.
c_0x52e9c1ed(0xe6dc1c03cedeff4e5e9f43cce468e996b50c0bb3a3c701009ccf3e12600ed026); /* line */ 
        c_0x52e9c1ed(0x25ecfdd8d4719fc690cd60248244e36e5af32ec1b6c6038d15adae9b1536e2cc); /* statement */ 
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
c_0x52e9c1ed(0x03f8facaa4248846c8f9f74b7670587e811c932dca9e8a7640ab6b1fbbb6f387); /* line */ 
        c_0x52e9c1ed(0x73936483219b78f7c073369f37e34b5c4d28fff9324f9285be1ac0527384e3c7); /* statement */ 
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
    ) internal view {c_0x52e9c1ed(0x4ca1cd751cdcde73f76e31c22212e9564baba83848ec9433de19b2947c8a744d); /* function */ 

        // Order type 2-3 require zone or offerer be caller or zone to approve.
c_0x52e9c1ed(0xd8e25d738b77c512a75fdfe5ba397a0b0fbce8fdc1727ab51fd3deeb9f37f0e7); /* line */ 
        c_0x52e9c1ed(0xf24f5bbc8b9fae31090cd20ff472daf1cc78c3cb3c35b87d23c0b4cc9446467e); /* statement */ 
if (
            uint256(orderType) > 1 &&
            msg.sender != zone &&
            msg.sender != offerer
        ) {c_0x52e9c1ed(0xccb19d22d5d91454267b4e40a559074ec1c95e0bafeb7c86afad182720c5c075); /* branch */ 

            // If no extraData or criteria resolvers are supplied...
c_0x52e9c1ed(0x006b3c0b8efff2dc380dcec2a19ceab9cd3105e13396e8cd4d223c7f3f20391b); /* line */ 
            c_0x52e9c1ed(0xb939e525f936944787c896d57d01e71c4db92312140e3d2ed591a6c7e09c6f26); /* statement */ 
if (
                advancedOrder.extraData.length == 0 &&
                criteriaResolvers.length == 0
            ) {c_0x52e9c1ed(0x915efe7b6b75f80da326eca2781becfd74e3a2b78dc43c5472dc4a03c3546043); /* branch */ 

                // Perform minimal staticcall to the zone.
c_0x52e9c1ed(0xab8bfbe992c4cace3128994252f792aecb88d26b99ddd9c31e6996342bcc3b1b); /* line */ 
                c_0x52e9c1ed(0xae626f74d8c20102e50ff7bb06d390d1c5ca4a176c7c1fc825d5e751b0af1cd3); /* statement */ 
_callIsValidOrder(zone, orderHash, offerer, zoneHash);
            } else {c_0x52e9c1ed(0x54d64e63e368e18f53d31cd8d06b4a3bc90e5dc746b0e5600f1e3c545aaa9681); /* branch */ 

                // Otherwise, extra data or criteria resolvers were supplied; in
                // that event, perform a more verbose staticcall to the zone.
c_0x52e9c1ed(0x3960c6b144c35e9ba4f29521274a270b932a36f2d0b76f2a6922050f1278a22f); /* line */ 
                c_0x52e9c1ed(0xc98ed923240a02dce3fdf88c2fc991b095121500815b61965828da5f027cca98); /* statement */ 
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
c_0x52e9c1ed(0x65fabc4346660fea3bc7f47bad36f394db818858b34fd237b59fe337c73f0c04); /* line */ 
                c_0x52e9c1ed(0x4231a28409436054a7ef0d51fc75c3256f288064a2341fc1890b4ca1e0fed942); /* statement */ 
_assertIsValidOrderStaticcallSuccess(success, orderHash);
            }
        }else { c_0x52e9c1ed(0xc948b4f1c5d04b6f1b9ea08c838e068189827b024c4b2ac5f923efd5f4dc5d62); /* branch */ 
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
    ) internal view {c_0x52e9c1ed(0x1fff0ddb7f9b09bddd4f9725f3af788541f769f926a9494fc7ee1903682113a9); /* function */ 

        // If the call failed...
c_0x52e9c1ed(0xb8742b05c59c3a5d41e1aed4230cc8dc3b5c937303371d353f6eab5af8f7905c); /* line */ 
        c_0x52e9c1ed(0xee7f5d809c9a318f73dad2eef8d333595ef26a1f8bfd5f61823f288585b9b823); /* statement */ 
if (!success) {c_0x52e9c1ed(0x880e352f4d84f7128aaa0f0c1fee9a056e84457f01c80ab34c92b7cbcf04363d); /* branch */ 

            // Revert and pass reason along if one was returned.
c_0x52e9c1ed(0x6483034b89ee5b3f4ca359c84ef0d23c5c9c5753009bc39207a29e0b2ba3e4ee); /* line */ 
            c_0x52e9c1ed(0xcf3e8fad829b16a96c906787f07f71ae87e606400648a456ff3f727624eed29f); /* statement */ 
_revertWithReasonIfOneIsReturned();

            // Otherwise, revert with a generic error message.
c_0x52e9c1ed(0x49fb8e2079f35b3189c77c329b4b6f17044e28fd405bb33fa78302e2bc717ae9); /* line */ 
            revert InvalidRestrictedOrder(orderHash);
        }else { c_0x52e9c1ed(0xe194f095df2f937b883deccff926113c73e486f99b552de63bed6f3ff87bf563); /* branch */ 
}

        // Ensure result was extracted and matches isValidOrder magic value.
c_0x52e9c1ed(0x10c91f53a0022b07310df197d8de2c7535a6a6b764317d589d4ee85d4c628db5); /* line */ 
        c_0x52e9c1ed(0xb578bed121332b3f818014562ad16ce354b01f634abf49988ee4b97cb37fa6cd); /* statement */ 
if (_doesNotMatchMagic(ZoneInterface.isValidOrder.selector)) {c_0x52e9c1ed(0xaf134a003fe578402d89623313e721666e49171e821ca279dbcd2d7b5461f84d); /* branch */ 

c_0x52e9c1ed(0xa0b9566450be6fdb46b1960d2c1647852296511539967dbf76ee8021a98f02ef); /* line */ 
            revert InvalidRestrictedOrder(orderHash);
        }else { c_0x52e9c1ed(0x2ee9236bc8dc5c4a5d5883eaec4ae5ed5f133d29ca7a02d5f52ce911516c9df0); /* branch */ 
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
function c_0x5da35ebf(bytes32 c__0x5da35ebf) pure {}


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
function c_0x3c5a9cd5(bytes32 c__0x3c5a9cd5) internal pure {}

    // Register keys, owners, new potential owners, and channels by conduit.
    mapping(address => ConduitProperties) internal _conduits;

    // Set conduit creation code and runtime code hashes as immutable arguments.
    bytes32 internal immutable _CONDUIT_CREATION_CODE_HASH;
    bytes32 internal immutable _CONDUIT_RUNTIME_CODE_HASH;

    /**
     * @dev Initialize contract by deploying a conduit and setting the creation
     *      code and runtime code hashes as immutable arguments.
     */
    constructor() {c_0x3c5a9cd5(0xa1abb89ec5b5b2657b466fc6bad9cb0bef341f71f3f53d0bfcfc6a186d6f3e1b); /* function */ 

        // Derive the conduit creation code hash and set it as an immutable.
c_0x3c5a9cd5(0xb77759d2ac28a1d65b09365cf69b4b5a3180c0ec821380ad02bbfef0753802d9); /* line */ 
        c_0x3c5a9cd5(0xfb3264d1a886ffe1fd77ca836ec235bc64404e253c4514fc9d50eb7d3468f63c); /* statement */ 
_CONDUIT_CREATION_CODE_HASH = keccak256(type(Conduit).creationCode);

        // Deploy a conduit with the zero hash as the salt.
c_0x3c5a9cd5(0xbe7511cc223f10add0e47ff744535d3f1cdf30e9f2098e6a35b89250c11af0b8); /* line */ 
        c_0x3c5a9cd5(0xba0875f63327185be229fe861c9f10d1643e1196d0aac1a2c1f03ff762ae6401); /* statement */ 
Conduit zeroConduit = new Conduit{ salt: bytes32(0) }();

        // Retrieve the conduit runtime code hash and set it as an immutable.
c_0x3c5a9cd5(0xe0e1117227e636c5a49b134b896188e2ab246290913adfdf18d3dc8013d22e9e); /* line */ 
        c_0x3c5a9cd5(0x9e9addc563c3ed7ccc53b587499d860464175864ec34418fd0e50d2873f2832d); /* statement */ 
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
    {c_0x3c5a9cd5(0xb979bb8fec13dc23ea57c618ddfa34896bec10fb1050a87b9d7c8704df66b279); /* function */ 

        // Ensure that an initial owner has been supplied.
c_0x3c5a9cd5(0xad4a73eb0fe75276ee18aaeaa4e89b38a9fa3a0bc6a61e7db76374d2dfb6a1e7); /* line */ 
        c_0x3c5a9cd5(0x82f6cbbb79b86c0b1b88b0e68d0452608f4e24eaa19f81380f637a1bd27f27aa); /* statement */ 
if (initialOwner == address(0)) {c_0x3c5a9cd5(0xb607ca120acacece724b2e8bfd84b33eac85bd30df1851b7a8dce07de07f8b47); /* branch */ 

c_0x3c5a9cd5(0xd0d87d96a95ce1a456b3291c61365998f4bb3175151974f1667babee660f2c49); /* line */ 
            revert InvalidInitialOwner();
        }else { c_0x3c5a9cd5(0x56d96e07bb1b59090c2df3fb4bc51444e4c6fbde595070da29833c523c96e517); /* branch */ 
}

        // If the first 20 bytes of the conduit key do not match the caller...
c_0x3c5a9cd5(0xa0fb0667e6e6ef177c91540487b38cc83a5ab85e6ed699bd2cb935ad897044a0); /* line */ 
        c_0x3c5a9cd5(0x3aba3126c763c40bfcaa3d908d00017df25f5a1fc87ffd9926cd66c1eba85c94); /* statement */ 
if (address(uint160(bytes20(conduitKey))) != msg.sender) {c_0x3c5a9cd5(0xa69ec2bd43b4de104862a436f7e1d83f33d8b9de0d4ad12fb15dcd8f1d6af496); /* branch */ 

            // Revert with an error indicating that the creator is invalid.
c_0x3c5a9cd5(0x0c213eb6cd44536708a73128c6559b03f303edf934ccf8765d10688e178accdc); /* line */ 
            revert InvalidCreator();
        }else { c_0x3c5a9cd5(0x3e5e58a05a63a580ea3edd64acac61690ff01f89d656bba75de920be0c299ea9); /* branch */ 
}

        // Derive address from deployer, conduit key and creation code hash.
c_0x3c5a9cd5(0x946ebbf4fa96e7a167753eb6376a910295d1a1d605b1c44bc60e5ec193c6bfbb); /* line */ 
        c_0x3c5a9cd5(0x011adeb4e13842fc5f037fd33048fe3228965899375f59d8b39a32ff4e59d53b); /* statement */ 
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
c_0x3c5a9cd5(0xdc5ef8b7d36e98a7709d904b9069d2d40efb9322635265c68593036e5f448d83); /* line */ 
        c_0x3c5a9cd5(0x6cdfdadc835a2af3d30b539e82991fb2a9ec374455ede5c609e49a8d1a65b0cd); /* statement */ 
if (conduit.codehash == _CONDUIT_RUNTIME_CODE_HASH) {c_0x3c5a9cd5(0x70c2cc3f160bf27a37d06b75ead2e82f85105bf77a441b48550bf329d366337d); /* branch */ 

            // Revert with an error indicating that the conduit already exists.
c_0x3c5a9cd5(0xcaadc20eaebcc9115c6db806f2203ee49e39a52bc7ce7ae7956319b51161b96d); /* line */ 
            revert ConduitAlreadyExists(conduit);
        }else { c_0x3c5a9cd5(0x97321b4d6516a6b29d542768edac7aca93008b1e895950a77edb9559095765d2); /* branch */ 
}

        // Deploy the conduit via CREATE2 using the conduit key as the salt.
c_0x3c5a9cd5(0x589d396bad8e18a91fd52d02a0dd3ee44525131d455277e23d536eef45e03553); /* line */ 
        c_0x3c5a9cd5(0x1c65699dfdf8b0d7408969581d5d66754d13148b5970f932d0b0da3357774e60); /* statement */ 
new Conduit{ salt: conduitKey }();

        // Initialize storage variable referencing conduit properties.
c_0x3c5a9cd5(0x47db17a7db44fa8202597c4a3c28a1e9fc342c5a6e0319d21bd5de62ef06558d); /* line */ 
        c_0x3c5a9cd5(0x27239141654b6a0ef621a762b218a09a283101eaf54991d93a45fb8a9ed080eb); /* statement */ 
ConduitProperties storage conduitProperties = _conduits[conduit];

        // Set the supplied initial owner as the owner of the conduit.
c_0x3c5a9cd5(0x249d3540c60aceefacdbb531b8e5573485962f1af2476bb99f0d664447cb6e84); /* line */ 
        c_0x3c5a9cd5(0x20259fad253e11ec1030c995d76464b0a63ea9fb5bc28966d31ccb69196d02b3); /* statement */ 
conduitProperties.owner = initialOwner;

        // Set conduit key used to deploy the conduit to enable reverse lookup.
c_0x3c5a9cd5(0x8f467194bdd1ceb1a69b0c0a960ea8bd37c232671651a08b10b7c723fc520130); /* line */ 
        c_0x3c5a9cd5(0x61c7d5e5874f2f16c441a38c03a824a36abe878953d2640cb47899831bf491ea); /* statement */ 
conduitProperties.key = conduitKey;

        // Emit an event indicating that the conduit has been deployed.
c_0x3c5a9cd5(0x8e01a8b5badb8709542e301c90dfca49c8c790ebeffe17e87381f0a2baf25427); /* line */ 
        c_0x3c5a9cd5(0x5afc4645fc898629b79a71f8acf2cd054d6d0753b526a15f97ecda97c6d8d6d8); /* statement */ 
emit NewConduit(conduit, conduitKey);

        // Emit an event indicating that conduit ownership has been assigned.
c_0x3c5a9cd5(0x3d40e5b27f2038ef064530ac20bb66c3a9c94b15ee99d1b3cdddd28b5d6a6e18); /* line */ 
        c_0x3c5a9cd5(0x29e114092d0fd695c58e6f344cdb09a554d65c44ad236732efb2527f589b42cb); /* statement */ 
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
    ) external override {c_0x3c5a9cd5(0x313d6286f3e7636ff9869e7012900ed00baf2cb2163799dc910ede016b5b228e); /* function */ 

        // Ensure the caller is the current owner of the conduit in question.
c_0x3c5a9cd5(0x87ab9a3d4ac3b8ee29c49694090be76351f5d1c57d381f4bf03cc576a03145ec); /* line */ 
        c_0x3c5a9cd5(0xd06b655af69d1c2265f45a1593350d681a90d7b8bd77ae9aa62b15a734a095cb); /* statement */ 
_assertCallerIsConduitOwner(conduit);

        // Call the conduit, updating the channel.
c_0x3c5a9cd5(0x16a27a86328f3fa0069acffbe010f4ba82fb06e9d36db82a1bb0875843bcfcae); /* line */ 
        c_0x3c5a9cd5(0xa26239cffc6ffdb57b85f7aaa0282dbac2293e73fd1a415f9f2b053578b4f3e9); /* statement */ 
ConduitInterface(conduit).updateChannel(channel, isOpen);

        // Retrieve storage region where channels for the conduit are tracked.
c_0x3c5a9cd5(0xdefb146238b75f1d1a75949c57a9c7d51dac4684a1a080cc93070ca3fecd2b93); /* line */ 
        c_0x3c5a9cd5(0x7bb8e6b381c85c1b482fbb07d22ecab2a29768cd8ec16c73311a10449196e7ee); /* statement */ 
ConduitProperties storage conduitProperties = _conduits[conduit];

        // Retrieve the index, if one currently exists, for the updated channel.
c_0x3c5a9cd5(0xe4764033c326358bfeed26531c3b3f13a6c9b1109d0c16003f29b5793e934e86); /* line */ 
        c_0x3c5a9cd5(0xd5912968312bcfc33ab3c7c45d6f6dacf6501082b15e7004ceb738d877185850); /* statement */ 
uint256 channelIndexPlusOne = (
            conduitProperties.channelIndexesPlusOne[channel]
        );

        // Determine whether the updated channel is already tracked as open.
c_0x3c5a9cd5(0xc8603b73948e43d3133a1a24b3dd4857b6efe9bcb5b070a744308a234d316d88); /* line */ 
        c_0x3c5a9cd5(0x4f069b9655bf8aab4c4efb74375b137f2bd043cc6cae15bcd472b7919538bbbf); /* statement */ 
bool channelPreviouslyOpen = channelIndexPlusOne != 0;

        // If the channel has been set to open and was previously closed...
c_0x3c5a9cd5(0x52450e6a14fcf59d9c9ecd0b3c5f07267ef99f8af597a57a0a5248c643a33de3); /* line */ 
        c_0x3c5a9cd5(0xbaeea59653587426ff3d285061aab4c1b4a4c593f0592ad1b1d6545719c3f3b6); /* statement */ 
if (isOpen && !channelPreviouslyOpen) {c_0x3c5a9cd5(0x69c834febd9a8734fbb297d79c611b4775e75737639ce3d1322b47406d6d085b); /* branch */ 

            // Add the channel to the channels array for the conduit.
c_0x3c5a9cd5(0x5e5f9fd75cf9923bbb852653c7bee117c473b12d420c6241f6b998cf83a69b03); /* line */ 
            c_0x3c5a9cd5(0x20243804ac1660b165db98e72fc8f581318c75152ad4bd1fbefa483b712e44e4); /* statement */ 
conduitProperties.channels.push(channel);

            // Add new open channel length to associated mapping as index + 1.
c_0x3c5a9cd5(0x5558d0c4dc309f2f49fff129802de93551d2148e54de82ff383f0494f45c3f21); /* line */ 
            c_0x3c5a9cd5(0xe75ab4c0337d881a7990801b07a050e931cc30832dba2ae8e08c9edc029a8477); /* statement */ 
conduitProperties.channelIndexesPlusOne[channel] = (
                conduitProperties.channels.length
            );
        } else {c_0x3c5a9cd5(0xc256b1e65d3ec22184c164d0c44cecf68b7f9098a0284c4c046710f735a78d11); /* statement */ 
c_0x3c5a9cd5(0x7b296f64666472cf455405cb7cb0179315821ffbc2efd13e4448baab7356e8af); /* branch */ 
if (!isOpen && channelPreviouslyOpen) {c_0x3c5a9cd5(0xb30a14153d261bd8174fdbb2ad73573d56a83af085178fd07640b8ee130b1527); /* branch */ 

            // Set a previously open channel as closed via "swap & pop" method.
            // Decrement located index to get the index of the closed channel.
c_0x3c5a9cd5(0xd1eabc080e5f950a96d8ee16426281729622c8a6737b8b3c7cd46b869123fde2); /* line */ 
            c_0x3c5a9cd5(0xa2c78de5f3321f7e716ba3cc465d13ab80d8916b61ca12cf0572e311d5132ef3); /* statement */ 
uint256 removedChannelIndex;

            // Skip underflow check as channelPreviouslyOpen being true ensures
            // that channelIndexPlusOne is nonzero.
c_0x3c5a9cd5(0x6a354f3b202975fd70abd56b6dddd34e97bfe889302aee52703083d5fd979512); /* line */ 
            unchecked {
c_0x3c5a9cd5(0x426c163a58510c8d614089d43d39b34a766104e552f4866e2fdecf382c6140a4); /* line */ 
                c_0x3c5a9cd5(0x322e8e970c636a704fed6cd33c0af182b12357189411df6ec0a8b6d82003b7e7); /* statement */ 
removedChannelIndex = channelIndexPlusOne - 1;
            }

            // Use length of channels array to determine index of last channel.
c_0x3c5a9cd5(0x7ce3030d3802ed634ca1178e240e5af5a6e75c3e0de80003cd1906aa5d489bce); /* line */ 
            c_0x3c5a9cd5(0x216387327b5c777297b1ca7e58100b0b6e98af876d194af8e65ccf381898ecee); /* statement */ 
uint256 finalChannelIndex = conduitProperties.channels.length - 1;

            // If closed channel is not last channel in the channels array...
c_0x3c5a9cd5(0x2829ee2dda114e0f7b9fa864bcaa8eded1a658734009845a12cb6be89d090a7e); /* line */ 
            c_0x3c5a9cd5(0x0a1d83e7f2dfb2265d102eeb33efd5d3279255a801ad420b92ddc04f20ffba05); /* statement */ 
if (finalChannelIndex != removedChannelIndex) {c_0x3c5a9cd5(0xf8247f797731375f5ff8b1e6a4efe250f388332c62d0fe0cca23296b2387940e); /* branch */ 

                // Retrieve the final channel and place the value on the stack.
c_0x3c5a9cd5(0xc73f82a9d01efbcea3945eca5c4abb3fcf90be7d865ba4949ced65506f52d0ac); /* line */ 
                c_0x3c5a9cd5(0x60643d6603d6c05a8a25e2b8cdd4d1be3d66547c96a8a248fa58fb9f8876f849); /* statement */ 
address finalChannel = (
                    conduitProperties.channels[finalChannelIndex]
                );

                // Overwrite the removed channel using the final channel value.
c_0x3c5a9cd5(0x6e5b0bd4b9fd8acacaa0fd04db8e4fd950ba3e9d473d6ac937dc459c68c5854b); /* line */ 
                c_0x3c5a9cd5(0x96a0fe84c2c69a1c650e261f5b1e9d2d771de38bc930235deccfca68f57f5310); /* statement */ 
conduitProperties.channels[removedChannelIndex] = finalChannel;

                // Update final index in associated mapping to removed index.
c_0x3c5a9cd5(0x53d3f6ad4b126df4a814874cde76391f07dd113436cd74f294b1a5c27c1f51fd); /* line */ 
                c_0x3c5a9cd5(0xc94e2c38ca647e34d797154095eaba4ac104cc3787bd9cd0701ba4ebd710540a); /* statement */ 
conduitProperties.channelIndexesPlusOne[finalChannel] = (
                    channelIndexPlusOne
                );
            }else { c_0x3c5a9cd5(0xa046588fc2507eb2a443eba02f658f8afe0dc3f5525733559fd5edc3f8da8a8a); /* branch */ 
}

            // Remove the last channel from the channels array for the conduit.
c_0x3c5a9cd5(0x90b84be2784933c0c750c6c485d7123b73e513e6ef19a0f77144ea25da2f2d29); /* line */ 
            c_0x3c5a9cd5(0x10bb0320f9bb889872012b14335762fbc64a94af89db3dc9c16f0707db339f30); /* statement */ 
conduitProperties.channels.pop();

            // Remove the closed channel from associated mapping of indexes.
c_0x3c5a9cd5(0xac3638db29a0245177b4ad40095964522303dcd8a6229fe7451c65d3329b5d5e); /* line */ 
            delete conduitProperties.channelIndexesPlusOne[channel];
        }else { c_0x3c5a9cd5(0x9263917d2d9040e5a5323e633edb95e9bf053c5883a0d939b338f008eb3a87e4); /* branch */ 
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
    {c_0x3c5a9cd5(0xc3c5935a618406d59874e5a93481bbff97bd53dbb98d586650ca8b2b2f892b40); /* function */ 

        // Ensure the caller is the current owner of the conduit in question.
c_0x3c5a9cd5(0x60e64791a05b3a784651314f7cf7ad5e2fd659954be70a64f1189dbdddeda1bc); /* line */ 
        c_0x3c5a9cd5(0x7389356246f265d040312b674756a15dafaf322621ecf7624581650610e773bc); /* statement */ 
_assertCallerIsConduitOwner(conduit);

        // Ensure the new potential owner is not an invalid address.
c_0x3c5a9cd5(0xeee1b5635f9155f074bbb4dfe914ede80db736cb00bcae75f81dd8158348c829); /* line */ 
        c_0x3c5a9cd5(0x9933017d60868aa5f4e9e65cc9c738cca86e64165f17556776069abab4862249); /* statement */ 
if (newPotentialOwner == address(0)) {c_0x3c5a9cd5(0xfba9a4f9818fd7337da6141e508066d821bdad0f5f584609e0e748b786a3b12e); /* branch */ 

c_0x3c5a9cd5(0xc7e4e05dea8db5cb6fabd88c382122d63cd403c461aee477cefec5b8eb0f0854); /* line */ 
            revert NewPotentialOwnerIsZeroAddress(conduit);
        }else { c_0x3c5a9cd5(0x2d34fd20477bd95d9407e132a83ae8e46418f600bc4668f1f02786c8a4604ab2); /* branch */ 
}

        // Ensure the new potential owner is not already set.
c_0x3c5a9cd5(0xb1db9edc934a5a1ada84c268107e23e0c98cc3041bf2ee332cf7de490bf0dc09); /* line */ 
        c_0x3c5a9cd5(0xb3644fc27a521dadcf71a22c394503273309138c11a311f9ca5dae76e1715ba4); /* statement */ 
if (newPotentialOwner == _conduits[conduit].potentialOwner) {c_0x3c5a9cd5(0x147425ddb7241dcc1b75818b7ff78a76626f9025788e63b071aeab51c8ada585); /* branch */ 

c_0x3c5a9cd5(0xf4d2a368249b771b910636779ba18a19ea9a2ea312311f1b8ab93b308d59dc2f); /* line */ 
            revert NewPotentialOwnerAlreadySet(conduit, newPotentialOwner);
        }else { c_0x3c5a9cd5(0xf2bd7ae37a2616304874c42d04879fbbcd78d6711a4e01d5286d38ccb089142b); /* branch */ 
}

        // Emit an event indicating that the potential owner has been updated.
c_0x3c5a9cd5(0x1aa807c12df328f8604af4cea37faac7b5c0ad469124bd2b2d7c1af6f12eaf18); /* line */ 
        c_0x3c5a9cd5(0x2f17d223411221f068b8c7074eca8baa9e342681956a84dbd7f8781f718cde21); /* statement */ 
emit PotentialOwnerUpdated(newPotentialOwner);

        // Set the new potential owner as the potential owner of the conduit.
c_0x3c5a9cd5(0xb853b41448314fa57e7c0cdc4c025a57549f37a5bd3d83ba9abaaf98b098717e); /* line */ 
        c_0x3c5a9cd5(0x1920f04e1370e0709906279e3381ed25c5f83ab5e7e1762ef9c5a3ef4246a4b4); /* statement */ 
_conduits[conduit].potentialOwner = newPotentialOwner;
    }

    /**
     * @notice Clear the currently set potential owner, if any, from a conduit.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to cancel ownership transfer.
     */
    function cancelOwnershipTransfer(address conduit) external override {c_0x3c5a9cd5(0xe0605eb722c2f9f9d87476d7b17e51d2242407b9c0cadf98f2a1a2548960a3dc); /* function */ 

        // Ensure the caller is the current owner of the conduit in question.
c_0x3c5a9cd5(0xae0222204a3319b85788297103b708a07d67c9159fe7fb94a7fc10016f6bf242); /* line */ 
        c_0x3c5a9cd5(0xe10a0afc3a526c35c99b1a23db3fcb4aacfdcb0038b6d5d2c5d7934ac9bd2348); /* statement */ 
_assertCallerIsConduitOwner(conduit);

        // Ensure that ownership transfer is currently possible.
c_0x3c5a9cd5(0x10184fa08e09a27c90d121557587784d35a6373d5e842eb3ff290e87854725ac); /* line */ 
        c_0x3c5a9cd5(0xddf4da602a4a20e7b0aef7ebfbb45e614e0096eca6aec29f930977ea0717fedf); /* statement */ 
if (_conduits[conduit].potentialOwner == address(0)) {c_0x3c5a9cd5(0x9c321f46ee0a04e8d14892add9496deeaee3fc31eae8e9761be9749a9814ec24); /* branch */ 

c_0x3c5a9cd5(0x370acfc2c7cb5d1a4534f1a3b6a9ecdcd583e69be2d480c1a72a87c3531d8e52); /* line */ 
            revert NoPotentialOwnerCurrentlySet(conduit);
        }else { c_0x3c5a9cd5(0x565923c4f0c286da7bad5ddc858947fbc823b517020d8829f325c7d2c99a7184); /* branch */ 
}

        // Emit an event indicating that the potential owner has been cleared.
c_0x3c5a9cd5(0x988fc2c61a399c20b4257ee92a47c0203fb9cd912b18b07d1cddcf7bb03eb690); /* line */ 
        c_0x3c5a9cd5(0xb555a50ee6a5d016ef4380f020469a78806b053038a57d833a8fcad673c0c9a3); /* statement */ 
emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner from the conduit.
c_0x3c5a9cd5(0x6c36f56bbc4512f723b1700e6cd7ea2c0b11663622ab0faa8d5ce715f3b38cb4); /* line */ 
        c_0x3c5a9cd5(0xc8c0ebaf0fe9c635ffe2b2ad06480b11da4b6036cfb0519be6c96e30caf4ac93); /* statement */ 
_conduits[conduit].potentialOwner = address(0);
    }

    /**
     * @notice Accept ownership of a supplied conduit. Only accounts that the
     *         current owner has set as the new potential owner may call this
     *         function.
     *
     * @param conduit The conduit for which to accept ownership.
     */
    function acceptOwnership(address conduit) external override {c_0x3c5a9cd5(0x3a72f9b38d0a2757468c444f60b1d66907a9bf0a83f726e1e620a3500c243aad); /* function */ 

        // Ensure that the conduit in question exists.
c_0x3c5a9cd5(0x8e90dac9f520196497af7f6a680a814dd24fbc7257f97e4327b34840d59352c0); /* line */ 
        c_0x3c5a9cd5(0x29354cde0fca58f9e32c4e39b2d700d58b1e7cfa08eb3c28a718769f67333be3); /* statement */ 
_assertConduitExists(conduit);

        // If caller does not match current potential owner of the conduit...
c_0x3c5a9cd5(0x54ed1ba83326a9d78bfc726963a813624e315e6232f38a3fa6c586994007dbf9); /* line */ 
        c_0x3c5a9cd5(0xe957512adb9f2bd3341fd9348ae6ef2644c0af92a7b63bee419c39c3ea531c0c); /* statement */ 
if (msg.sender != _conduits[conduit].potentialOwner) {c_0x3c5a9cd5(0x7469c679ba1eb29dd85cd2aca73443c4acbffdd9f76a437981bc08d196ba0ab0); /* branch */ 

            // Revert, indicating that caller is not current potential owner.
c_0x3c5a9cd5(0x966b7bb6fe0aec2c9ddfec7e15c2c7962d846e4114357f50abc37d3e3bbbd095); /* line */ 
            revert CallerIsNotNewPotentialOwner(conduit);
        }else { c_0x3c5a9cd5(0x597a3e833df1b3b0173e9e2731811efa8b231602e2bd5d9b9c43db51d05d6b7d); /* branch */ 
}

        // Emit an event indicating that the potential owner has been cleared.
c_0x3c5a9cd5(0xa4380e6b0a933b036e2c3c316c4c8009b15548597455b85c1e217cedc12b1f8d); /* line */ 
        c_0x3c5a9cd5(0x76d882cf1c70977cbb033956605afa8a2d63675b887524925cfa058ab17f79f4); /* statement */ 
emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner from the conduit.
c_0x3c5a9cd5(0x6a669249d26d938869ea88463a9ab881a1bcf684781c9fd18e6b18b0cbd0f2db); /* line */ 
        c_0x3c5a9cd5(0xe888290818528894c808cc8b02ba5583258dd136132ced81465300e992b833d2); /* statement */ 
_conduits[conduit].potentialOwner = address(0);

        // Emit an event indicating conduit ownership has been transferred.
c_0x3c5a9cd5(0xf03070ee0f910ce05516b3d333326e56d160d8a91b054b726cf1bd687f74e6f1); /* line */ 
        c_0x3c5a9cd5(0x5adfe86f8cf194647d61a61966d993cd64a050166c1cfd0e18c1a3b486748b04); /* statement */ 
emit OwnershipTransferred(
            conduit,
            _conduits[conduit].owner,
            msg.sender
        );

        // Set the caller as the owner of the conduit.
c_0x3c5a9cd5(0x9df557101472c7be4158d9418d06da2833de88477143da551f607d14255c61db); /* line */ 
        c_0x3c5a9cd5(0x90e8842dea451f3e52143ea95fd33c2aadd4594026b939ef1477baebb7a4ded1); /* statement */ 
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
    {c_0x3c5a9cd5(0xa9405e5cf1f30b5d85352a178d829b1fc8ec47417843ad67e7141d8695bcfaac); /* function */ 

        // Ensure that the conduit in question exists.
c_0x3c5a9cd5(0x7ca1bbe92bf2589f6b7bc48a0fdc62908dae3193fba8c1e0959ebddb1bcb18ea); /* line */ 
        c_0x3c5a9cd5(0x9cb448a1e6d61357443e5ba264dd3962ff13e1e199dac9a53717eab81c4e67b4); /* statement */ 
_assertConduitExists(conduit);

        // Retrieve the current owner of the conduit in question.
c_0x3c5a9cd5(0x9a16a9d323d2483eb5a5cf62660eb3dd7cd99c4af70323f05001dd39f3b8f9e7); /* line */ 
        c_0x3c5a9cd5(0x9f753bc86d41a34c0b1fd15ddb109502ba0a7d8fdd0a96c44f421fa92a04aee8); /* statement */ 
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
    {c_0x3c5a9cd5(0x3dc5bf55898de19ad0bd71db2a7ceee4087aca2e88a99a8505ea180cd9fe65e1); /* function */ 

        // Attempt to retrieve a conduit key for the conduit in question.
c_0x3c5a9cd5(0xac5d184cbb9d606d8e3500ffb28d38c8356f9c3922bbb50393260c5f56056d59); /* line */ 
        c_0x3c5a9cd5(0x87cf15fa4049d2dc6ed749bdec7cdd10a85c72050f3d34d8250d297ce28fa46c); /* statement */ 
conduitKey = _conduits[conduit].key;

        // Revert if no conduit key was located.
c_0x3c5a9cd5(0x2d10279a6917a17cb1606320d7c75d86864cc35f01022d93c50cad7d9b2f3c92); /* line */ 
        c_0x3c5a9cd5(0xbee6ecbc5d6a379e1f451566ffc37d9a9390a0e9f1fb8faf71a45b34cf747f78); /* statement */ 
if (conduitKey == bytes32(0)) {c_0x3c5a9cd5(0x4546da05678796387cde62e78cb934e90ab03e0b576f344a7491666067dc7268); /* branch */ 

c_0x3c5a9cd5(0x72fdb04963e150398c401ff9f4f31c2f54d1259bf74b2019b4ef0cc3972609d9); /* line */ 
            revert NoConduit();
        }else { c_0x3c5a9cd5(0xe261334ae1a2685dc6976191abddf75bc63ee462cefc9e41636008f73dd9259e); /* branch */ 
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
    {c_0x3c5a9cd5(0xf27cfb5e60ad43ef7bf0150618807eab3c430ddd2ec8d33d827882c56a0f4236); /* function */ 

        // Derive address from deployer, conduit key and creation code hash.
c_0x3c5a9cd5(0x2cee925ca0903ca3d237a31f827f656b67309e1f9a903468c831ed9e696aa455); /* line */ 
        c_0x3c5a9cd5(0x4dbd0c3ec72ec81b7999ea188e38b923adcd17b9d2f7768903d7354ce58246f9); /* statement */ 
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
c_0x3c5a9cd5(0xe74f5e07c19808b579b47ed5a87b94a16729051422e16170d5482bb688d827be); /* line */ 
        c_0x3c5a9cd5(0x5b04b75e9f4eb437409b9671dc9404bfa5b401f552ae2489bb52e978cba05be5); /* statement */ 
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
    {c_0x3c5a9cd5(0xeef2a3cb9915ede3c69121f5b86758ce37b479b808e64384c2230107cb8394b0); /* function */ 

        // Ensure that the conduit in question exists.
c_0x3c5a9cd5(0xbadaa8af82e49265ac8b9d44bb210295df6eab0bc2921b71ed6ca9cbafb2496b); /* line */ 
        c_0x3c5a9cd5(0x0efa35e5f71b84e18cf6197d2f468fd1462121df870f470c1bbe8af1409c0041); /* statement */ 
_assertConduitExists(conduit);

        // Retrieve the current potential owner of the conduit in question.
c_0x3c5a9cd5(0xc0b21a07193fc1ba4a703f8387a46e6132cfa9b6ac5232add98946137a0cf435); /* line */ 
        c_0x3c5a9cd5(0xfd4f36ada32603ee372cfe67f3f24ab333ccceaf3ea26cdabfb5ee647b5b3188); /* statement */ 
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
    {c_0x3c5a9cd5(0x42424e8d72ad674be5121878df194f93aa118a3f6321db04f6c1edc651baf993); /* function */ 

        // Ensure that the conduit in question exists.
c_0x3c5a9cd5(0xbb57b17237bbb833fe0b4126b61873be57d4ad22ade093cb4ad01d3cb1525722); /* line */ 
        c_0x3c5a9cd5(0xfc948eb2538e94d0f98790e40d6cc7e3fcefdd5aa9428263ec199e433703561f); /* statement */ 
_assertConduitExists(conduit);

        // Retrieve the current channel status for the conduit in question.
c_0x3c5a9cd5(0xd8c83f36fb8b9872c0209608882d8e8d328e0443b4338665f95c9a713731247e); /* line */ 
        c_0x3c5a9cd5(0x05f78ec58b2dacabf19c1412f9b296261303fcd751b0b8c1af5108d68bcf6c45); /* statement */ 
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
    {c_0x3c5a9cd5(0xd8e0147ef3260e34d7cc2297c50e4d2f1f211d863544ede001685efdc062930d); /* function */ 

        // Ensure that the conduit in question exists.
c_0x3c5a9cd5(0xbb242b2f15111353bc36dfbdd12258d4e1565aa4fa2b17ddd82d5524bef0323c); /* line */ 
        c_0x3c5a9cd5(0xde7e324eed1d3e1bec5acc3c21508f2cb56c9a8bdc6f1a0b878ff51c40b1dabe); /* statement */ 
_assertConduitExists(conduit);

        // Retrieve the total open channel count for the conduit in question.
c_0x3c5a9cd5(0x5d50fd62d972b908365710da90b5fe838f7d4ae47a21e71bcc80f0cc7a5ea4fc); /* line */ 
        c_0x3c5a9cd5(0xdd4824c09ef082255311c08f260361dd904f0389b975c6ac4a29ca92927589a6); /* statement */ 
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
    {c_0x3c5a9cd5(0xf63bd13a5d79a1cd8912eb73f2bb373c81798382a1c2210b488e925a0030160b); /* function */ 

        // Ensure that the conduit in question exists.
c_0x3c5a9cd5(0xa34ff030aa52a15bb56c42d873c5ba1c9dcd00ca33ba18549b93207aa70c98c3); /* line */ 
        c_0x3c5a9cd5(0xb07da21f19f058e87d363cde8d3e5ac8bf292908caf262df54d79ca0a0f65437); /* statement */ 
_assertConduitExists(conduit);

        // Retrieve the total open channel count for the conduit in question.
c_0x3c5a9cd5(0x640351ec8c17325e93f20821d9a6d3e17c295cbcb1c5e63f396ccce3818fd3b6); /* line */ 
        c_0x3c5a9cd5(0x40c5caa23e3eb6acf2301078dbd11e2b72be1cd8b726a24245dd192c99fa5e02); /* statement */ 
uint256 totalChannels = _conduits[conduit].channels.length;

        // Ensure that the supplied index is within range.
c_0x3c5a9cd5(0x7709067cc9c6d8e3ac66d3843b7afed42616bb554f7a5d72f12e5655e6ac43eb); /* line */ 
        c_0x3c5a9cd5(0x2b985aad47563f1f6996a095048258a603a2f97cdf1839f2ae54b01ae56ded2d); /* statement */ 
if (channelIndex >= totalChannels) {c_0x3c5a9cd5(0xd056b5d282eb2fd658a67f61c74c18d8094256524090f2aa601c2ab1fe041edb); /* branch */ 

c_0x3c5a9cd5(0x34136f7857e06a7083ca85a207dffc83fbf0feb9e52a09147d9375ed0acd1f42); /* line */ 
            revert ChannelOutOfRange(conduit);
        }else { c_0x3c5a9cd5(0xf559085de2346d16660c0c0c5d6c063e6a7008bfec5722a5f327dff1a7e9bc89); /* branch */ 
}

        // Retrieve the channel at the given index.
c_0x3c5a9cd5(0xe9a4b734b58f21599c438b5c2285889025c6678b8bfa91aede7f05378ca26588); /* line */ 
        c_0x3c5a9cd5(0x29176e8dbace5bb5417cd02c5d85ae62712cef9134cb27e2f5a215e5fdac3f66); /* statement */ 
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
    {c_0x3c5a9cd5(0x1c902a4024a943cbf8d67cf073ac46cf31eff25edbf378153f801ee5dd508393); /* function */ 

        // Ensure that the conduit in question exists.
c_0x3c5a9cd5(0xcdc970c253ab683e3403699bea7d4636936043aef927dd4c15a410c7f4f9d6f6); /* line */ 
        c_0x3c5a9cd5(0x4bce4d525ec65918aec36f2039b432ad08bff9e5ab72ff4359cc1e3f60adbb95); /* statement */ 
_assertConduitExists(conduit);

        // Retrieve all of the open channels on the conduit in question.
c_0x3c5a9cd5(0x6cae70641e59865017a66208eaf6d916f82c43e160a93552039e24a514696e95); /* line */ 
        c_0x3c5a9cd5(0x57b063eb2a90d8408aabe9e03227d64dd401a2d4a7c18c5f6140dbdc0251695e); /* statement */ 
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
    {c_0x3c5a9cd5(0xe0a02d8ce48ae92b8167bdfc135039b71fc759423d614d5dd600bdd39ad3ac07); /* function */ 

        // Retrieve the conduit creation code hash from runtime.
c_0x3c5a9cd5(0x0a27470864f06f5c801cf9279f14ad203ac909f74bb2c257596c529535f88fae); /* line */ 
        c_0x3c5a9cd5(0x2d78422f0d3a37e0bcc2b007979a7d93a478f9bda1ba2d450f1ea6328e257a79); /* statement */ 
creationCodeHash = _CONDUIT_CREATION_CODE_HASH;

        // Retrieve the conduit runtime code hash from runtime.
c_0x3c5a9cd5(0x53196a3b0fb535c6434a4389cb04c181458b7b084d55d0b89d064f29694da80e); /* line */ 
        c_0x3c5a9cd5(0xc9ef7bc924bcbb295adf498e131aaacc841aa68b54b6bc428bba090c389d7fb2); /* statement */ 
runtimeCodeHash = _CONDUIT_RUNTIME_CODE_HASH;
    }

    /**
     * @dev Private view function to revert if the caller is not the owner of a
     *      given conduit.
     *
     * @param conduit The conduit for which to assert ownership.
     */
    function _assertCallerIsConduitOwner(address conduit) private view {c_0x3c5a9cd5(0x7aab0f0d2585bc1f0276321123d9717f7e268d227509c0d9b6fbbbc0aa1ca475); /* function */ 

        // Ensure that the conduit in question exists.
c_0x3c5a9cd5(0x39f7a5a258f949a2484dd57dc003bf4c106b7fddd9fade336830a8f0eb890450); /* line */ 
        c_0x3c5a9cd5(0x39ed80dc2f68a093ea40872ee73fc85b0a9147122df98fc1aafe02d0cbfe375e); /* statement */ 
_assertConduitExists(conduit);

        // If the caller does not match the current owner of the conduit...
c_0x3c5a9cd5(0xec4c81455c7730b40bb9979560aa29c21e56ec0954599908f1bdf221e9f4a9a2); /* line */ 
        c_0x3c5a9cd5(0x447c1279a880e09fff7d0bb7c428e22a2454a849d127e6c44f9a723e8b8dd5a4); /* statement */ 
if (msg.sender != _conduits[conduit].owner) {c_0x3c5a9cd5(0x3bda1ed371a9f7e7ac34674b0a37a31a36d75bae787d77c92ccd15d8b8ee88ff); /* branch */ 

            // Revert, indicating that the caller is not the owner.
c_0x3c5a9cd5(0x6a866f14e6c4c4e8407487d96d89711f7d5eb8fcf5883586ad0b604b20f00c99); /* line */ 
            revert CallerIsNotOwner(conduit);
        }else { c_0x3c5a9cd5(0x61f5809bff634946144c4cedafbc95a52b57fffabab318802344ad17ae1bcee6); /* branch */ 
}
    }

    /**
     * @dev Private view function to revert if a given conduit does not exist.
     *
     * @param conduit The conduit for which to assert existence.
     */
    function _assertConduitExists(address conduit) private view {c_0x3c5a9cd5(0x0291e52a5e40a33cf087ebbcea1cf5af14393674b1d42f4a99ffa887f188d9d8); /* function */ 

        // Attempt to retrieve a conduit key for the conduit in question.
c_0x3c5a9cd5(0xdd6b8e62af5e40fbe582cd4c2814784f4f5c16162affdb13a3fd0f6d161ab437); /* line */ 
        c_0x3c5a9cd5(0x9821e218ae11943668c71bb31140de052ae0fbd2c1b17fcb3f2c0177ab0dbf2c); /* statement */ 
if (_conduits[conduit].key == bytes32(0)) {c_0x3c5a9cd5(0x14ef1e2383dfe81fa60822b456c578645e9953ffd6826cab1a0ba6f0bd90a3d0); /* branch */ 

            // Revert if no conduit key was located.
c_0x3c5a9cd5(0xc2b4f015af415d4b36c9796d29cff25885b4b61b5ee4e697e59187530104907a); /* line */ 
            revert NoConduit();
        }else { c_0x3c5a9cd5(0x8384fe948fa5e1f66dca5b4c6f621a4a0b8e74d7552322a7c5499a7578cfe0da); /* branch */ 
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
function c_0xcbdafc01(bytes32 c__0xcbdafc01) pure {}


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
function c_0xe43e6203(bytes32 c__0xe43e6203) internal pure {}

    /**
     * @dev Derive and set hashes, reference chainId, and associated domain
     *      separator during deployment.
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     */
    constructor(address conduitController) OrderValidator(conduitController) {c_0xe43e6203(0x4cd0e5fe01bca4e3a46a6b988f65380f71d3dc653bd9b8bb28450525d534101b); /* function */ 
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
    ) internal returns (bool) {c_0xe43e6203(0xd87ed4955918256013f1acced7ccd39433975117daaf802a603aefd252bcdf7b); /* function */ 

        // Declare enums for order type & route to extract from basicOrderType.
c_0xe43e6203(0x91e0c67c03bfabc4adf6f17987aacce6faf84fa004ad480ec536e8339eeb02a3); /* line */ 
        c_0xe43e6203(0x3ae0b054d4314614b9139f7a7bff17dfb197c589a1f879c5ae0a0b09ff17f30b); /* statement */ 
BasicOrderRouteType route;
c_0xe43e6203(0x4f8ed281d6372e80348173ca37ad2db5efbeff6ffd24edb9a3a1ec1a1e687e31); /* line */ 
        c_0xe43e6203(0xec704f3a433e358382830b8a485315c6a676a2fc97f78f8b3532690843ac6eaf); /* statement */ 
OrderType orderType;

        // Declare additional recipient item type to derive from the route type.
c_0xe43e6203(0xf32e63e8dcd45885cacf456857c041962651c6294c7da85e9e61c6cb7bcd3065); /* line */ 
        c_0xe43e6203(0x6f67dd1d776907899a67ee7e1646a0622694c76ff5e47d12098a8c3fe748f22b); /* statement */ 
ItemType additionalRecipientsItemType;

        // Utilize assembly to extract the order type and the basic order route.
c_0xe43e6203(0x8dc8751faa5ab80f2633dd93ec5678e6c32b4d055ba42876661fa35d0b37a5cf); /* line */ 
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

c_0xe43e6203(0xd3ca29d6b351ca4c09756c096219d19ebb583c7aeeee6c95c671495bf97b5da6); /* line */ 
        {
            // Declare temporary variable for enforcing payable status.
c_0xe43e6203(0x0678da38270a7e528dadb92f99ee60bfa23c5dd91c1a79837db8ec4be2071272); /* line */ 
            c_0xe43e6203(0x2522e8c2b54227d324423e542a761a23cd0c635314d06a53d8f770575b1064bb); /* statement */ 
bool correctPayableStatus;

            // Utilize assembly to compare the route to the callvalue.
c_0xe43e6203(0xa6991b8e482b5569500392e8daeebf027ed89ff520953562e704d87c8bfbe6dd); /* line */ 
            assembly {
                // route 0 and 1 are payable, otherwise route is not payable.
                correctPayableStatus := eq(
                    additionalRecipientsItemType,
                    iszero(callvalue())
                )
            }

            // Revert if msg.value has not been supplied as part of payable
            // routes or has been supplied as part of non-payable routes.
c_0xe43e6203(0xd4801b51b5d914bf02122af2735cfbd3104658e2a6fa4d3d0bd600e705a35c9d); /* line */ 
            c_0xe43e6203(0x63d0cb51a4517319c2ffd6ad93f9d10668e01b54a1cb741f3bea018a5ea7471b); /* statement */ 
if (!correctPayableStatus) {c_0xe43e6203(0x785c198fe2a80fb8245fc32f729dffef6418866f301b14f1066d296e19467ad3); /* branch */ 

c_0xe43e6203(0xbfa87d46a8c55730ab312c9ee348825e0eb1f3664562fd3ca050adcbf87e0ebf); /* line */ 
                revert InvalidMsgValue(msg.value);
            }else { c_0xe43e6203(0x3466170f9bda5ba48a88f02e6b585c1cc1c3d2ac4d9c41cbfb05620cbe0d47d6); /* branch */ 
}
        }

        // Declare more arguments that will be derived from route and calldata.
c_0xe43e6203(0xf8f29e01c1dcfc24d66a6ed3d9abdd711eeea68e655b203cc5a68aa9e2e799b6); /* line */ 
        c_0xe43e6203(0x8f0e92577c09bcb9655c28224521e0be95ad178797e716a2998f46d32b2509fa); /* statement */ 
address additionalRecipientsToken;
c_0xe43e6203(0xef72261792c866c91cb354a29cfc4079e1590c085b3b11a9bd00b6435afe7e36); /* line */ 
        c_0xe43e6203(0x89cf71f3183dfc9b8808595999ebaa367e89e0758bf3a9d0c7971d9c151cf454); /* statement */ 
ItemType offeredItemType;
c_0xe43e6203(0xb8f8feb73519f06c473119982aa6194516d7b9089227b2eaba6f7c107c36f8ff); /* line */ 
        c_0xe43e6203(0x7bdf5f15387ce7ef8d67e6056eda807f5447b5c64c090bc89548515f89032071); /* statement */ 
bool offerTypeIsAdditionalRecipientsType;

        // Declare scope for received item type to manage stack pressure.
c_0xe43e6203(0x5ca17208d0d4088fb777955524b4bfebc08c602c0830f13bd19be8c2efcbe7f8); /* line */ 
        {
c_0xe43e6203(0xdc2b278f4ba2903c8f75d7f64f31a6ba775ee66b302feefb03b55f4c22b06f50); /* line */ 
            c_0xe43e6203(0xf4f89c19947f3d338886e894bc27fff1ea6752d737449caa2330db21a491dca2); /* statement */ 
ItemType receivedItemType;

            // Utilize assembly to retrieve function arguments and cast types.
c_0xe43e6203(0x11377dcb18e3a2861604b19a5e895a1cc810d8ea12a43b0e7c6e8961c779aeeb); /* line */ 
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
c_0xe43e6203(0xf33338264bb2c7a3031bdac127aa8a7f5918ba9731ebac1f562fe22897455a02); /* line */ 
            c_0xe43e6203(0x508258dd55b8746a292c576c7502576c8898456c1890849df044cf4c444f65a7); /* statement */ 
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
c_0xe43e6203(0x5246982dc14173a401716f2fd5dd500cb250aeb33bd7cb3ab523bec670deeb97); /* line */ 
        c_0xe43e6203(0x36ed77c8ca1e63d1bb2c12d405cdc5ad59ca0ac934ec74d715f60a60db374a04); /* statement */ 
bytes32 conduitKey;

        // Utilize assembly to derive conduit (if relevant) based on route.
c_0xe43e6203(0xaf172548c67f0bea18339a676d270137abdc396744bf9fc71edd85216a79063e); /* line */ 
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
c_0xe43e6203(0x6dad37cc7ef9b15439f26c8b1401b363bab094824d744d0b2be9689d24efc3cb); /* line */ 
        c_0xe43e6203(0x446cc0df0d532c1a4c6056cc852453c0a81642c5819c1dd508843a6fd3d030de); /* statement */ 
if (additionalRecipientsItemType == ItemType.NATIVE) {c_0xe43e6203(0x47bac2f9b0b62b5c8053ecf52d17e4cc5b25839ca44d440b75c8211ee05262da); /* branch */ 

            // Ensure neither the token nor the identifier parameters are set.
c_0xe43e6203(0xa9f114f6d446e27bcc14ee3388ccea866cd2c30b5cbe67823da7137b670b69f2); /* line */ 
            c_0xe43e6203(0x0e07d46c10dd2eacca441a8ea61a79a95b38ae0edc65c182e4c21614317ef348); /* statement */ 
if (
                (uint160(parameters.considerationToken) |
                    parameters.considerationIdentifier) != 0
            ) {c_0xe43e6203(0x1e80bba36c95cd7dcd3d09514fd881fe8fd07f2dd0a18ef51453cc6e82a91160); /* branch */ 

c_0xe43e6203(0xb59449b73addd6c6ada11e0a924f48f865a15b47cbf2a3bd1d57c667fd6d68bf); /* line */ 
                revert UnusedItemParameters();
            }else { c_0xe43e6203(0x8bd03fcbbc55bf486ea467a74bb3fef88e299ee6dc74a1cfcf544b2f0a822853); /* branch */ 
}

            // Transfer the ERC721 or ERC1155 item, bypassing the accumulator.
c_0xe43e6203(0x78f8dab6d5c62306308b719c0cfeacf792bc3f9debb1bb306667fa646971244a); /* line */ 
            c_0xe43e6203(0x0e9322ce6d36d4f5866b9d86247375e20ab05d99fedaae38ddcb08872fb85246); /* statement */ 
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
c_0xe43e6203(0x606a6a0a633164c35529318c51c252ec865b29eda65ef6099c630e52ba4d2987); /* line */ 
            c_0xe43e6203(0x4d8fb65fb9d5ccc20ca827932b8b391976fa997dc06e004a24f048e28aaabf00); /* statement */ 
_transferEthAndFinalize(
                parameters.considerationAmount,
                parameters.offerer,
                parameters.additionalRecipients
            );
        } else {c_0xe43e6203(0xeaf6fe786ff92911eee86fd1a496b1dcd57b9739e683cc225a75066b488cb914); /* branch */ 

            // Initialize an accumulator array. From this point forward, no new
            // memory regions can be safely allocated until the accumulator is
            // no longer being utilized, as the accumulator operates in an
            // open-ended fashion from this memory pointer; existing memory may
            // still be accessed and modified, however.
c_0xe43e6203(0x234a327125d768f4377ed498659cd6f300baddf4d5f94089914f08c21ef93080); /* line */ 
            c_0xe43e6203(0x9d4fb13cd180da68a9edc439ac1540183726d29b1fa0672bfd6880498c9aa7bf); /* statement */ 
bytes memory accumulator = new bytes(AccumulatorDisarmed);

            // Choose transfer method for ERC721 or ERC1155 item based on route.
c_0xe43e6203(0x7ee8818ca7d204419ccc281e085eaab6def1dcecd5064e496cd2eb9542d8f76f); /* line */ 
            c_0xe43e6203(0xec816835b4f3f8d4ce866734997f453c49c813af83bbbafb8ad213ebe833c830); /* statement */ 
if (route == BasicOrderRouteType.ERC20_TO_ERC721) {c_0xe43e6203(0xd90fb02dfa4b08b46ceb4d4d2d452e5a776738da28f60740069e6c115e61c356); /* branch */ 

                // Transfer ERC721 to caller using offerer's conduit preference.
c_0xe43e6203(0x57d67401820817752bdb252455b39254fc6b7c581579689cafb4772dbef40342); /* line */ 
                c_0xe43e6203(0xfb39a891f436d27322ec87e5e1cffb8fd3247346c47fdd218c046516181856b2); /* statement */ 
_transferERC721(
                    parameters.offerToken,
                    parameters.offerer,
                    msg.sender,
                    parameters.offerIdentifier,
                    parameters.offerAmount,
                    conduitKey,
                    accumulator
                );
            } else {c_0xe43e6203(0xc8b525a472fc3f68b623bd72489ebb92d0c88ef94d5c025a977da7527e6621d1); /* statement */ 
c_0xe43e6203(0x9eb2d2f4ad15fda2d383c9e652950f77ac55c10ba3fd7ee784082068788e812a); /* branch */ 
if (route == BasicOrderRouteType.ERC20_TO_ERC1155) {c_0xe43e6203(0x608d6d3dce5b28f443ecd8dc8385c36f231eec27c66606ec8c94c6c4c884cd38); /* branch */ 

                // Transfer ERC1155 to caller with offerer's conduit preference.
c_0xe43e6203(0x2c47abd1426f7321fc1d9d156e0a7e644278d00c4b0257fac76cda90345e6f96); /* line */ 
                c_0xe43e6203(0x059a073fa85080fb5306eb624f180dd557fc9d0568621de979de8b5bb90e9403); /* statement */ 
_transferERC1155(
                    parameters.offerToken,
                    parameters.offerer,
                    msg.sender,
                    parameters.offerIdentifier,
                    parameters.offerAmount,
                    conduitKey,
                    accumulator
                );
            } else {c_0xe43e6203(0x97d3fcac0064a3f3de4245fccc06dfa5338eea2e5311d15ec46e070e3570f6fd); /* statement */ 
c_0xe43e6203(0x82fd0f79c122db74e6b0217939ed769fddd0cfb8c6befafa34983974073b771c); /* branch */ 
if (route == BasicOrderRouteType.ERC721_TO_ERC20) {c_0xe43e6203(0x1d8963a9c8e0d8fb274e4cba215c43f85dd2d82086e3a9d793bfb197bc4e4905); /* branch */ 

                // Transfer ERC721 to offerer using caller's conduit preference.
c_0xe43e6203(0x659bead66d34d95d4c8052690e41ff6d127d35651dae780b1cda29503d0a32b4); /* line */ 
                c_0xe43e6203(0xb33be06eec476cb4678c52e262f9a87639fe10879b0131504250b00bb5560e82); /* statement */ 
_transferERC721(
                    parameters.considerationToken,
                    msg.sender,
                    parameters.offerer,
                    parameters.considerationIdentifier,
                    parameters.considerationAmount,
                    conduitKey,
                    accumulator
                );
            } else {c_0xe43e6203(0x8814d89d5f5ec47fe8ae15132da634c17714745316da91fcff66d870f12f4dd4); /* branch */ 

                // route == BasicOrderRouteType.ERC1155_TO_ERC20

                // Transfer ERC1155 to offerer with caller's conduit preference.
c_0xe43e6203(0xed48a7bda74ae2dcdfafe84c2fa211844c2c88b582fa5cc8ec4ea983a7143fb8); /* line */ 
                c_0xe43e6203(0xe7207e69283b22dfc8e268ba21cec4113416ada2fb3b22279673857a8448e163); /* statement */ 
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
c_0xe43e6203(0x0a10cbc7efa14645faaf10b23717e5787943c92e596b132e2bb5820478744898); /* line */ 
            c_0xe43e6203(0xde3cb042cb500e39865f05b65a0cf6d21997a806b39dd356df938b32a0c69fcd); /* statement */ 
_transferERC20AndFinalize(
                parameters.offerer,
                parameters,
                offerTypeIsAdditionalRecipientsType,
                accumulator
            );

            // Trigger any remaining accumulated transfers via call to conduit.
c_0xe43e6203(0xb2f32aa4dae9da60a5fef993a4065e8b6511e5cf9b9599858b7eb67cb14ba90d); /* line */ 
            c_0xe43e6203(0x2e32fd88fb0377b44121919a5219f687a3c926bf5ffdd5a116610820ae5835d1); /* statement */ 
_triggerIfArmed(accumulator);
        }

        // Clear the reentrancy guard.
c_0xe43e6203(0xbc85b9102eca6157fa4675be4c2174d1b76b2aaf6718aff111a1c710f51b94d5); /* line */ 
        c_0xe43e6203(0xd7346d25ceca2baaae6fef0fa9744cb61e6271bfcb817b1ac6a2dcf16466f462); /* statement */ 
_clearReentrancyGuard();

c_0xe43e6203(0x7b9dce96f715fe83c4e1e5a64a973fd4dc86e0477c6d48ece390bb9ce5a46474); /* line */ 
        c_0xe43e6203(0xd01b130553bd476261ac47c4eca837ac1d93f7fcf20148825e923326df5df828); /* statement */ 
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
    ) internal {c_0xe43e6203(0x539b096a49d58611d60c283c58d18cc42c458c7563008a28ca12cb4d4a745aea); /* function */ 

        // Ensure this function cannot be triggered during a reentrant call.
c_0xe43e6203(0x49ee9da921ad306b5ffc0cc3f227c01ab699f28d1c4374e0752716e4557d8a5e); /* line */ 
        c_0xe43e6203(0xf866e200066b0b9dc6addbecd31baa4298f1871880065fe64f64132e97ce2bdf); /* statement */ 
_setReentrancyGuard();

        // Ensure current timestamp falls between order start time and end time.
c_0xe43e6203(0x436bc6f9471001c476c7c14d25bacda7dd87031557162a2b49b4aeb0114ba97d); /* line */ 
        c_0xe43e6203(0x52404c2cd23c4c61c403af45aebdb6b4e428b52c9d2b8c0231df3cc711d677d7); /* statement */ 
_verifyTime(parameters.startTime, parameters.endTime, true);

        // Verify that calldata offsets for all dynamic types were produced by
        // default encoding. This ensures that the constants we use for calldata
        // pointers to dynamic types are the same as those calculated by
        // Solidity using their offsets. Also verify that the basic order type
        // is within range.
c_0xe43e6203(0x5f6d6f36a3e1a7ceed8a950da432ed38817444692b3c838377023eaa35ed53fa); /* line */ 
        c_0xe43e6203(0x227331f78d6df1f99bcc405d8429c7398fa44c9ac695f0c504ab73cc6ba6833b); /* statement */ 
_assertValidBasicOrderParameters();

        // Ensure supplied consideration array length is not less than original.
c_0xe43e6203(0x77d3768ed3a29c2e6ee2f66d20d6484b9f447bfab192a97547798424e84355fa); /* line */ 
        c_0xe43e6203(0xb78863748cb68bac1d973fb4d8a09d5a93d9b7bb703607812d4d090d029129b7); /* statement */ 
_assertConsiderationLengthIsNotLessThanOriginalConsiderationLength(
            parameters.additionalRecipients.length,
            parameters.totalOriginalAdditionalRecipients
        );

        // Declare stack element for the order hash.
c_0xe43e6203(0xe64a6e816e7c9325d84033720146485f441fae1fa130aae4660b83ad860641bd); /* line */ 
        c_0xe43e6203(0x4b4a86bef6f91262d5344e1942763fa57192dca7445b4248f9a94d8f2ff08637); /* statement */ 
bytes32 orderHash;

c_0xe43e6203(0x3c20099200d456d7fcae1094bc52a1f3bfa0a8265e182c7819c7dfa8cfabe060); /* line */ 
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
c_0xe43e6203(0x1764cb46c20b66f2470c5db67286a0ef83f1887738b6cfa8c9c127506fe81b52); /* line */ 
            c_0xe43e6203(0x1cc23950cfc10dee444c21a50b4f22b53b10ba9fab2965cade3134890a7d121d); /* statement */ 
bytes32 typeHash = _CONSIDERATION_ITEM_TYPEHASH;

            // Utilize assembly to enable reuse of memory regions and use
            // constant pointers when possible.
c_0xe43e6203(0x030c9cda97bb2628b1846eef4bc518f2ded97f94e29c57c1b89b574035b92c11); /* line */ 
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

c_0xe43e6203(0xe8efa71cf2d8c4f2e896f5fdc00482ca81969ba1d04b6c9579f835616bedbf40); /* line */ 
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
c_0xe43e6203(0x238ba16b1a516cee1e407d9bc8938df00c42097e398e2c0be505482f675ba364); /* line */ 
            c_0xe43e6203(0xe5e6ec68ee31bf073666051b3c224a5bfa455e66c842aedc4ae4def797bf73e1); /* statement */ 
bytes32 typeHash = _OFFER_ITEM_TYPEHASH;

            // Utilize assembly to enable reuse of memory regions when possible.
c_0xe43e6203(0x5662ec445d064da64b01587c3dcd1b984c001c9124fd4f3e2c6a667ff371f080); /* line */ 
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

c_0xe43e6203(0xa808791cd6422ac3f0056ad170ca01b04975cff9faf08b98353b7cbdcd9a3609); /* line */ 
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
c_0xe43e6203(0x973e053112a3a488a71e6d2222c8760f4737b4a8b5fd837732badb239425ed3f); /* line */ 
            c_0xe43e6203(0xf74f2c784e4a1fc355528231fe72bae2f8baed430b8158f4e8256d0b1598574e); /* statement */ 
address offerer;
c_0xe43e6203(0xf7c8d2da0cd95d253381cf244ac43343255eb37fd079717d3c62ff26f75faf38); /* line */ 
            assembly {
                offerer := calldataload(BasicOrder_offerer_cdPtr)
            }

            // Read offerer's current counter from storage and place on stack.
c_0xe43e6203(0x63cf3e9b04e460b56dbbd3b1d71546f49a12aef99e2d6885988d22d9a5ea3039); /* line */ 
            c_0xe43e6203(0x3be1bca9b9f2c630515441fff87c9f6e1e2fb0fe9e3ec3e4c558c9fe3ae5cff9); /* statement */ 
uint256 counter = _getCounter(offerer);

            // Load order typehash from runtime code and place on stack.
c_0xe43e6203(0x65dcc9e979450eeccc1720f2281744ba4a75af8733ba87f3077c73464c0108d5); /* line */ 
            c_0xe43e6203(0xefcfd3b0daae9081011b874000558baec531ecb8847083d91455bb71b4e34743); /* statement */ 
bytes32 typeHash = _ORDER_TYPEHASH;

c_0xe43e6203(0x10a3b62c0e017c1ded216bc8da16da692c54f7db5b8e04d7d02e43c11be9ccfe); /* line */ 
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

c_0xe43e6203(0x18ba04caccb91fe40fd6d7b8d5f5c5c7d17ea7c3d8de8759cef861ff83ce872d); /* line */ 
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
c_0xe43e6203(0xbec2471369e5762cb1d26b9e0de4627350f2e7c6416b0890ba86caa6544f6c2f); /* line */ 
        c_0xe43e6203(0x0cbd4bc76231c71329953974c35d6ee91ebb23028ff591eba1eb72290cd37380); /* statement */ 
_assertRestrictedBasicOrderValidity(
            orderHash,
            parameters.zoneHash,
            orderType,
            parameters.offerer,
            parameters.zone
        );

        // Verify and update the status of the derived order.
c_0xe43e6203(0xffe42acc8aa6857f5a87d6452c1e8b638876540eea86c1ef1083c6fdb49901ce); /* line */ 
        c_0xe43e6203(0x16c97510afce415d6bc9013300fc40476f92934f247b4b0a84c2aa673b19801d); /* statement */ 
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
    ) internal {c_0xe43e6203(0x0e193fc77de332d4f881c6249d70b49216037245bedfacb83cb3dd9dd8dd82a4); /* function */ 

        // Put ether value supplied by the caller on the stack.
c_0xe43e6203(0xb99652735b9727a55c729a5c8d30d72a349bfb65a72005cf01e726c275767afa); /* line */ 
        c_0xe43e6203(0xb744d985e7cff20d52f74b5195bebfc719dd9319e478f921ecacacfc46a6e442); /* statement */ 
uint256 etherRemaining = msg.value;

        // Retrieve total number of additional recipients and place on stack.
c_0xe43e6203(0x3718a6cf28492d540597d1ab7f874ef33cc0612fdf7b15610358e9ddaeb57dfd); /* line */ 
        c_0xe43e6203(0x768d26b9795398a6e6224b497cda300928945af5f420cdd4e248922b5590bc31); /* statement */ 
uint256 totalAdditionalRecipients = additionalRecipients.length;

        // Skip overflow check as for loop is indexed starting at zero.
c_0xe43e6203(0xd9582d8f740f0a43f82c59f7728599b623464fedaa9efcf57b6bd5c922d21abd); /* line */ 
        unchecked {
            // Iterate over each additional recipient.
c_0xe43e6203(0xec5dbd321e3a44d7da064115ae45b79e3e12fffaccc6189640c18b5e2e657d3b); /* line */ 
            c_0xe43e6203(0xce6420fd3c42bd774f5b98eb3ae376a9b342fe1e9e8943923d859a1124dedd31); /* statement */ 
for (uint256 i = 0; i < totalAdditionalRecipients; ++i) {
                // Retrieve the additional recipient.
c_0xe43e6203(0xf95aca112dc75a8b54f85905ffdfad2c41eba3efadae2c96f4a086322e604766); /* line */ 
                c_0xe43e6203(0x87b4afd9bb2b028eeb88ff59c859b0487eb98da6c6d98f8932609d5aa4429a07); /* statement */ 
AdditionalRecipient calldata additionalRecipient = (
                    additionalRecipients[i]
                );

                // Read ether amount to transfer to recipient & place on stack.
c_0xe43e6203(0xdb971f0e06bbe5cce0fd3782ffa23f4b89f319c7194192602f85140147b8360f); /* line */ 
                c_0xe43e6203(0x51d86d83c15ab5446feec6367b70bb6c7581cc955e9f437169a1cabe5d1e22ac); /* statement */ 
uint256 additionalRecipientAmount = additionalRecipient.amount;

                // Ensure that sufficient Ether is available.
c_0xe43e6203(0x585b1be82a27dfef987ee193746d3a33f6f2f21508224fd451cdbea9945e7e5b); /* line */ 
                c_0xe43e6203(0x6eb03248c549b57114bc714f2fa39083d58491b355382fd2ea38882865d39168); /* statement */ 
if (additionalRecipientAmount > etherRemaining) {c_0xe43e6203(0xe09a2ece93d0f23b5567688f423b1e525925b6c0415ff8b344b202578a516438); /* branch */ 

c_0xe43e6203(0x8eb413bd16fd3898b9c85b87de92fd73ac83e879ae3cd2fd6fc49a429a2b22b3); /* line */ 
                    revert InsufficientEtherSupplied();
                }else { c_0xe43e6203(0x7b0b2f3c6f9d2218b3a6311be7c04e0193323c59c709e79746124f17bd6e0ad6); /* branch */ 
}

                // Transfer Ether to the additional recipient.
c_0xe43e6203(0xcba50a940d6f183b3f3c7d439678f06423349c43b3dd4871a4491511ddc429ac); /* line */ 
                c_0xe43e6203(0x371f6c3ce87ba26e4c4dd5bc9d506f54463869019fe9a551577cad214effad98); /* statement */ 
_transferEth(
                    additionalRecipient.recipient,
                    additionalRecipientAmount
                );

                // Reduce ether value available. Skip underflow check as
                // subtracted value is confirmed above as less than remaining.
c_0xe43e6203(0x1ab5e20950131a365d65c5f89484199fac99364f0d985080d6cdea6967f22f90); /* line */ 
                c_0xe43e6203(0x934763bc113a912be5df57e68c6f20de10bbaa6710e4b2b772c302466eae2958); /* statement */ 
etherRemaining -= additionalRecipientAmount;
            }
        }

        // Ensure that sufficient Ether is still available.
c_0xe43e6203(0xa06550541bb8525e1046fdf108bea38486805dbfb17627c39be62ba45e221674); /* line */ 
        c_0xe43e6203(0x6dd192343ee18fe4b43f864a94def268c536b7f7e38d85fd13e14b31195b6f16); /* statement */ 
if (amount > etherRemaining) {c_0xe43e6203(0x0d677db8382b5983dcc0bb7c3fb01f6bb93f15014cb85a560fd2918da2204c91); /* branch */ 

c_0xe43e6203(0x4897e9ba8a02e8bf9992f04325b5c0f298e04241cc1396d98a2f4b42c2f4b36c); /* line */ 
            revert InsufficientEtherSupplied();
        }else { c_0xe43e6203(0xa5aa775f1862c357281957cd87c3750188c786f0df98bb32848aa399994d6b73); /* branch */ 
}

        // Transfer Ether to the offerer.
c_0xe43e6203(0x39d095014b6ba6d5b461aa246f68ef4c05b3e575b799ae93a81e7e2fb8a87e2a); /* line */ 
        c_0xe43e6203(0xd579686946644b95dd428c89bc990a575416c0960bbd0d78d85060bfc24ebba3); /* statement */ 
_transferEth(to, amount);

        // If any Ether remains after transfers, return it to the caller.
c_0xe43e6203(0x48799f2c9bd363a1258d4e8e481cd571f133174a4584dfd3e507456a8e16871e); /* line */ 
        c_0xe43e6203(0xe876c1534e1b68df2e5d3683efc2d0c4d165e418fb499d1a5fb81467ee1cd01e); /* statement */ 
if (etherRemaining > amount) {c_0xe43e6203(0x1f087466dc79696b5f383a5af821d9ac230ce9ac30c4d992253871bf8945734a); /* branch */ 

            // Skip underflow check as etherRemaining > amount.
c_0xe43e6203(0x470604b415f5f8361a12d75e3a2af14e83583bff26381e91a5256ca264a78643); /* line */ 
            unchecked {
                // Transfer remaining Ether to the caller.
c_0xe43e6203(0x344e19f2d580d107dec7ceb06f8d75aef52898d98cc35d5ee263934430f04e8e); /* line */ 
                c_0xe43e6203(0x6202386025cf25916f9e0deca576584cbd7cb83a8654052d0308fb131f234a3c); /* statement */ 
_transferEth(payable(msg.sender), etherRemaining - amount);
            }
        }else { c_0xe43e6203(0x655cec17811a1114b5c8e2a92e4c5cdb0702619a4c13ecb74819e2349e403c2d); /* branch */ 
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
    ) internal {c_0xe43e6203(0xb649476b7676c41b7aa52f439d22e8587038d65faac6069442ad841b468a6250); /* function */ 

        // Declare from and to variables determined by fromOfferer value.
c_0xe43e6203(0xfad81de3805503188f78a9dca2038d903303b55409977fd7de83ae01f509d751); /* line */ 
        c_0xe43e6203(0x6ac35efe03b87e6f0a76ef8c51db85e2f85190b6d515d11097abd7cdf3340ce5); /* statement */ 
address from;
c_0xe43e6203(0x516497d495b22e602405cee4c7228a9b7c8ae0acb156ed333c3e8864fa06515a); /* line */ 
        c_0xe43e6203(0xab71cd063a9339cfafe0efb0e040397e3250689978c1d6344161ab070cb06528); /* statement */ 
address to;

        // Declare token and amount variables determined by fromOfferer value.
c_0xe43e6203(0x35381b890d255ca3df3bdb11e51a313a32515569822c27df842e711f1ce52585); /* line */ 
        c_0xe43e6203(0x687dbe7df6dc10cd0c638feb734c1bb527ae6d534e636c0af1af81cbcb16c32b); /* statement */ 
address token;
c_0xe43e6203(0x64980efe8b3273384f67c6f2193505d4552ead5138701b1ad65886604a85f0ea); /* line */ 
        c_0xe43e6203(0x7ded344396545a07479fdeeefb4473b031f8b8443f934c71507f27f81551c350); /* statement */ 
uint256 amount;

        // Declare and check identifier variable within an isolated scope.
c_0xe43e6203(0xfd44e6409d51f8d7575ac1513c6257312d162e13df34e895a20ca8cd4fd992fe); /* line */ 
        {
            // Declare identifier variable determined by fromOfferer value.
c_0xe43e6203(0xdc6f1907db161bfa6779d0dda94f8c9039d1106ae1f624b65944003f7da65cb5); /* line */ 
            c_0xe43e6203(0xe20072b171a132be2b8a3bfde3ab3ce0dc6395cd1ab780aeb5f66eb15df5fcef); /* statement */ 
uint256 identifier;

            // Set ERC20 token transfer variables based on fromOfferer boolean.
c_0xe43e6203(0xe2ce6a2cfc253a9972adca811bdb3bbd830dffd96ea3e37072a59d16e8ed4ddc); /* line */ 
            c_0xe43e6203(0x486412aaceeda7f30b9f1aa2622e2e297584b9b50d4a39596dc0af8464b53aef); /* statement */ 
if (fromOfferer) {c_0xe43e6203(0x5358c0c13729891af4f6daf5655b19c4c4e5e4825ff8bf532441061dc5625f00); /* branch */ 

                // Use offerer as from value and msg.sender as to value.
c_0xe43e6203(0x94a3caac7851a7b626e8f0200a7d6023df62781b8606ab06f7b6819055b963a1); /* line */ 
                c_0xe43e6203(0x1024820b01ef0f84abe16e70927399ce48413de726c713d850021dfd35bafa24); /* statement */ 
from = offerer;
c_0xe43e6203(0x55d6ec7688bdaedf489dc5c7926566240669933339eebef9e2b15418d883138f); /* line */ 
                c_0xe43e6203(0x258cf531955fbd5c5e4e286eab46ee301172f9cf5cb099dc011b10e6a12ea495); /* statement */ 
to = msg.sender;

                // Use offer token and related values if token is from offerer.
c_0xe43e6203(0xb87f4a143a9dd0cb31f0f1e7f9a1e6cf575967c5f8927036f83cc21ba02da232); /* line */ 
                c_0xe43e6203(0x17e00cc4be418cd766d86f24245973940235a7ab26ef602f1b5446452516a2cb); /* statement */ 
token = parameters.offerToken;
c_0xe43e6203(0x907cec9e7543630866b629e70099b8de62b4bc7d026771f50930247c5e469997); /* line */ 
                c_0xe43e6203(0x4ebc3cd180a6b47722b1929d38f2458541fd26615316d7d33cd31960d7b7cd03); /* statement */ 
identifier = parameters.offerIdentifier;
c_0xe43e6203(0x7f21cbe24b37210987eeca477df2e1200fded46c43c78df0c515196a81434785); /* line */ 
                c_0xe43e6203(0xc56020a0aa3bd4fade88d39cd9dc59c85e19ea36e4d3eae8a148e0afff48f647); /* statement */ 
amount = parameters.offerAmount;
            } else {c_0xe43e6203(0xaafa064bd7f8e4995b1abe90ee33663f5006b1d952e2e870b9f34d09dff021bf); /* branch */ 

                // Use msg.sender as from value and offerer as to value.
c_0xe43e6203(0x9539aa86ca74c57e9d75a08a53ace26eb3adab4cde307bcc755a7c38f7304aaf); /* line */ 
                c_0xe43e6203(0x6885e08279c9fd4ebe1cb42c6bd616455f6ad2def1754c07383a671899a675cb); /* statement */ 
from = msg.sender;
c_0xe43e6203(0xc29880090a6767a65be2930661213deb7753e7155922c5aec1f4eafedf1e0527); /* line */ 
                c_0xe43e6203(0x75e593760042992f82ea1ae78e089ec946ef3628fb773d48d6af122eae872317); /* statement */ 
to = offerer;

                // Otherwise, use consideration token and related values.
c_0xe43e6203(0x99a559ec47b112da272dee406740219bcae48f9e659c795ac1aac576d692e42a); /* line */ 
                c_0xe43e6203(0x5f504e96d3241c8713b41cfc7db1dc3c0d6777a519e970aa508be03d6f38c171); /* statement */ 
token = parameters.considerationToken;
c_0xe43e6203(0x076121d47de2b5b34b454d92fa3354ebb34285522d9a7a01a9f2db529e02f9e1); /* line */ 
                c_0xe43e6203(0x8da3a7fc61e3573f8fb7b4b8a46a6b11b6e2fbbfc1e0776f49f10b5ec93cf201); /* statement */ 
identifier = parameters.considerationIdentifier;
c_0xe43e6203(0xee5c486cb484841f58fced789bcd5e8008f30e8fc785a4bd1c23429de9e53952); /* line */ 
                c_0xe43e6203(0xf889df0c36855754b01b5fdf71b7cd420e2aa5bd44db0295d448458fa71e6081); /* statement */ 
amount = parameters.considerationAmount;
            }

            // Ensure that no identifier is supplied.
c_0xe43e6203(0x54bdcd1480a57bc5c5646c0b038e85d110df2553e0c85a8fe5906cda11ac0de6); /* line */ 
            c_0xe43e6203(0x029a0c80402df67e8f3bde9829e3603a521c20cf7fa916bec4d02d525c1624ab); /* statement */ 
if (identifier != 0) {c_0xe43e6203(0x2efbfc9745a641c6664c6b065e5f8b7995183e3025c9f5e090632efabc59c02f); /* branch */ 

c_0xe43e6203(0x4a705c3f69b7e08d5d65c9b6e47475a2fe6328005b0174f439ddc97635a1a875); /* line */ 
                revert UnusedItemParameters();
            }else { c_0xe43e6203(0x246ce0d9cd49056190099494ebd9bfa82cae8ee86d53945bda18ae72f6a6d6f6); /* branch */ 
}
        }

        // Determine the appropriate conduit to utilize.
c_0xe43e6203(0xf1e9b7bcf7ab7d650019fbe47a5e057911c803888071acaa75d0bf1cbfa1d658); /* line */ 
        c_0xe43e6203(0x85105582b0f316374d6e0f0416ca2983ea1ecf6187ca74f3e7816cd25e3d788e); /* statement */ 
bytes32 conduitKey;

        // Utilize assembly to derive conduit (if relevant) based on route.
c_0xe43e6203(0xc8902fbcce1981372f564e3686328ff73aa3fa060164c0208ca917cfa24a03e7); /* line */ 
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
c_0xe43e6203(0x6162b10ca9d0816aa40367c4082782bdb15a1f840083b9be7db7055409b4c884); /* line */ 
        c_0xe43e6203(0x960fab615063e908eecc8a625b56f5403f7d0f3c60e938b173a764bb308f5a7e); /* statement */ 
uint256 totalAdditionalRecipients = (
            parameters.additionalRecipients.length
        );

        // Iterate over each additional recipient.
c_0xe43e6203(0x9bf3c2ad8c5c0a12c84b91550360d21f7187c624d3fd9ea1486c607e93ba2523); /* line */ 
        c_0xe43e6203(0x6194a7c89bce9b3d4610d4b7924d5fc7f8026382a2e35a04dc40f8c3118b2301); /* statement */ 
for (uint256 i = 0; i < totalAdditionalRecipients; ) {
            // Retrieve the additional recipient.
c_0xe43e6203(0x4c02c6bb19765dc76ef6a2fa0248d97282c298bf67ffc1ce04e698b95387d94e); /* line */ 
            c_0xe43e6203(0x3bde4d65e501aa4b1dd5c14d9d0cea57c1d10d55b89233e35dd9a432abdd210f); /* statement */ 
AdditionalRecipient calldata additionalRecipient = (
                parameters.additionalRecipients[i]
            );

c_0xe43e6203(0x11bfe30b7b65e94e914bd59c8e43121f7ff9fefb79736833f3af650f862f6d89); /* line */ 
            c_0xe43e6203(0x20cf2dcc5fe489372c471937d9fc3770abf5d5ab92395f4406a8563e2da75ed5); /* statement */ 
uint256 additionalRecipientAmount = additionalRecipient.amount;

            // Decrement the amount to transfer to fulfiller if indicated.
c_0xe43e6203(0x32e94b94f735f18ab1b2b4229dfd02b16be45f04b0c3814838fdd0cad65c5dfa); /* line */ 
            c_0xe43e6203(0xff7f3625265e9cd09242149d9491e4a4c19a692247e6ec1c223ea4144bb9a485); /* statement */ 
if (fromOfferer) {c_0xe43e6203(0x921098d43f1e1317e813844c31a1122a5050b93b702095c1946b59cdb3e77937); /* branch */ 

c_0xe43e6203(0xe7308e272f2dd659f60b1c738549d0f9ecb9d0ec7f30de4479e01ea8a69c8300); /* line */ 
                c_0xe43e6203(0xb02ee341dc51ed275bbf2e7f1650f844cbdb80f50c4e048bf73af6d71c2cd047); /* statement */ 
amount -= additionalRecipientAmount;
            }else { c_0xe43e6203(0x6609f46fd0f52fd7b851feb2c4c1d7fbd31d7635d7c6e3405f7a0e864f1102a1); /* branch */ 
}

            // Transfer ERC20 tokens to additional recipient given approval.
c_0xe43e6203(0x6ec1deecae61d3001dedcc26739857b36a284b56e1fc4e561bc233530b6a6013); /* line */ 
            c_0xe43e6203(0x0189c36f593e021b3c0827b75db839d46a279bcb210aa61da2d69f64ecaed782); /* statement */ 
_transferERC20(
                token,
                from,
                additionalRecipient.recipient,
                additionalRecipientAmount,
                conduitKey,
                accumulator
            );

            // Skip overflow check as for loop is indexed starting at zero.
c_0xe43e6203(0xa22f1f86c0916008ce1579e1bcfee78ce3c272601b44620b422ebff97017a551); /* line */ 
            unchecked {
c_0xe43e6203(0x8b66f7017d2f6f1f8848e427fcaa5b6201bb11d4cd442fe93175a9f4c4825f48); /* line */ 
                ++i;
            }
        }

        // Transfer ERC20 token amount (from account must have proper approval).
c_0xe43e6203(0x069c572a5b819d3a9b427d9d684e6580525f120b66075a96aa83fa2a5cb77f5f); /* line */ 
        c_0xe43e6203(0xc627c3891d900cb5ade510f3c5259ecd8b0a3370f4a6cbbf32e762286deda12b); /* statement */ 
_transferERC20(token, from, to, amount, conduitKey, accumulator);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0x60bd62bd(bytes32 c__0x60bd62bd) pure {}


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
function c_0x1d6d0026(bytes32 c__0x1d6d0026) internal pure {}

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
    constructor(address conduitController) Executor(conduitController) {c_0x1d6d0026(0xdde31f3afc037d0b1d58d6713f2da4506d5599b2a4d6a45e57608f2ffdd18694); /* function */ 
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
    ) internal {c_0x1d6d0026(0x8daf44ee96073005b81a9273f6d0471cdbdbc4d27f4edc268e2ec3d1142420b6); /* function */ 

        // Retrieve the order status for the given order hash.
c_0x1d6d0026(0x49b8db4c8862c538281f3382fbaaf11ad06f09ddbb174f8b1839d48e604f0ccb); /* line */ 
        c_0x1d6d0026(0xd1bf2366e144adb2159416213948028c2f82851ce0e9d499e1885664ce7525fd); /* statement */ 
OrderStatus storage orderStatus = _orderStatus[orderHash];

        // Ensure order is fillable and is not cancelled.
c_0x1d6d0026(0x78296035799f8c95d2c0ae4bb8485ce487f62841451504101101f141bd9b481c); /* line */ 
        c_0x1d6d0026(0xaaeb5c936da2f8e37748e8556d89fbd6e5af63722f2c0f4ca17130c3bcfc0d8d); /* statement */ 
_verifyOrderStatus(
            orderHash,
            orderStatus,
            true, // Only allow unused orders when fulfilling basic orders.
            true // Signifies to revert if the order is invalid.
        );

        // If the order is not already validated, verify the supplied signature.
c_0x1d6d0026(0xefbe3c6e8c2bc68c91fb916cdace31bea73c8a568aa29c6688372cf201d6fc63); /* line */ 
        c_0x1d6d0026(0xd504b174f4c6b6ecf495beb9c7c44b66e32a5f25ee6a8ab68c32b0ac5e5155cf); /* statement */ 
if (!orderStatus.isValidated) {c_0x1d6d0026(0x3b2713a9dcf2bfb28de8e5fe66975e9c2b2997b3262f09d31d97dd05cf8698e4); /* branch */ 

c_0x1d6d0026(0x5c87c09d509367637d871f0fd8ad57c40a1811b6e67b0f50108f645bfc3ab4d2); /* line */ 
            c_0x1d6d0026(0xe8f3e877210401c723103f81f3dae16c93c37c9ab40d1952035b1295960ce702); /* statement */ 
_verifySignature(offerer, orderHash, signature);
        }else { c_0x1d6d0026(0x4dbc87a2c74f6589f24654766f17e64e56b7d86f25d0b609e344b92d341935b8); /* branch */ 
}

        // Update order status as fully filled, packing struct values.
c_0x1d6d0026(0x7fd6e2c99030a8308233a9aca15f46b01c8dc6809d3abcbeb0ed2970604e95a5); /* line */ 
        c_0x1d6d0026(0xb93562f2556c5553b46446b6c364c1953754a8ebd803be68386c8d41d071e1ed); /* statement */ 
orderStatus.isValidated = true;
c_0x1d6d0026(0xc35e7da47cd379a46692f2c39bdd6b9b253861fed3e0699973130b2c8befd4e5); /* line */ 
        c_0x1d6d0026(0xbf671e028a8e88e6e5fe9df60f3f99b439e73229e462a55f0895eaa694e042b4); /* statement */ 
orderStatus.isCancelled = false;
c_0x1d6d0026(0x66c57a48ae280d7ba988689d3cadb64cf99396856467ee29744e24afe32ab499); /* line */ 
        c_0x1d6d0026(0x948e92136bf62745cdbbfe586465e322c34d6c08b4dbe0748d67bae26124a25e); /* statement */ 
orderStatus.numerator = 1;
c_0x1d6d0026(0x6c643d9bf61ce01c8650b6d752445ff8ef8ca799dde7c0088acdd79de9632749); /* line */ 
        c_0x1d6d0026(0x8a0c5eefe0405a7375818adf81bcfad4a6deb0dda7238d21851380f5a42ecca7); /* statement */ 
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
    {c_0x1d6d0026(0x75386058e98549390d04b4b51037b7c0bebe6a88c89ee37c95bb42828578bf96); /* function */ 

        // Retrieve the parameters for the order.
c_0x1d6d0026(0xa06047d926bd5a72063ed474474f009811396b063be6695176416238c155c2cc); /* line */ 
        c_0x1d6d0026(0x10f5fcb272cf610e74c3edcd87407a37a22635d917f364ce69b0695184543137); /* statement */ 
OrderParameters memory orderParameters = advancedOrder.parameters;

        // Ensure current timestamp falls between order start time and end time.
c_0x1d6d0026(0x1e08a7f51221c4cb98cb4320c0456217b00befce8866ab1b87dad594fcd3a704); /* line */ 
        c_0x1d6d0026(0x202cbad6c9424fb8f4827019799d86ea91ec7a6095ff77bb39b1f33e3b348f5e); /* statement */ 
if (
            !_verifyTime(
                orderParameters.startTime,
                orderParameters.endTime,
                revertOnInvalid
            )
        ) {c_0x1d6d0026(0xa6f3f09604f85f0428ebc396ee255f01d1b69b36d13b03b2e9ac69cf540937d4); /* branch */ 

            // Assuming an invalid time and no revert, return zeroed out values.
c_0x1d6d0026(0x6be6fa5e26bd37e7528dbeaa1238bb3ec72aef98895339db324da512b4ca210e); /* line */ 
            c_0x1d6d0026(0x81bc2c14c4b1fde774e95ef8c8ead553ff4b101cf81a8af4468bc23c2862352b); /* statement */ 
return (bytes32(0), 0, 0);
        }else { c_0x1d6d0026(0x84f347aa8c9d7075e71164c5a4b88ff94c640098f7f1382e63853bdd70cf294b); /* branch */ 
}

        // Read numerator and denominator from memory and place on the stack.
c_0x1d6d0026(0x507ddb10076d3b4a7e6dd7fb7100a8d4175b90c9ed57b055bc8e55fc5ec4b722); /* line */ 
        c_0x1d6d0026(0xbb05fe9579ef19772deb08a507ecd491f850a865a53f66f856cc042bb4d27961); /* statement */ 
uint256 numerator = uint256(advancedOrder.numerator);
c_0x1d6d0026(0x1e3a01b2f0104e0629c5e79eb5be8c7f874b3666caf1a3850ceeede0a0c56306); /* line */ 
        c_0x1d6d0026(0x6cfa7801b97e5a6c1344fbd4056eff7e5e900b2612dfe2c7590c63eb0ea4ead2); /* statement */ 
uint256 denominator = uint256(advancedOrder.denominator);

        // Ensure that the supplied numerator and denominator are valid.
c_0x1d6d0026(0xe9961f1885e6ced03485c6e87c19c2d5241f79126342265c195a836cb88a9c29); /* line */ 
        c_0x1d6d0026(0xb0d0e0deb7378f50d8ff40fdcfed7f16f4c07b22035eb5502ed17a43553fece1); /* statement */ 
if (numerator > denominator || numerator == 0) {c_0x1d6d0026(0x598d01986c2d8ef6fa4e68af5261ed1e7c0f0d86e0b45be05eb595148532d31c); /* branch */ 

c_0x1d6d0026(0xf9a9b7a591350a91f87241b4c1492c2ed68515069551c6845e179bd23eab36f0); /* line */ 
            revert BadFraction();
        }else { c_0x1d6d0026(0x605ddfb8fbf1115ec3ccaa0352781d40dbde4d8f7fae13f1c49bea39d55a5c9a); /* branch */ 
}

        // If attempting partial fill (n < d) check order type & ensure support.
c_0x1d6d0026(0x2b89ee7d442b35620bbd1453e844cfc092056928574f9edbf223a1555e20d725); /* line */ 
        c_0x1d6d0026(0xa4b23ead47984478719526f4a5aa8ab0d17736957b8b554068fdd468a657755c); /* statement */ 
if (
            numerator < denominator &&
            _doesNotSupportPartialFills(orderParameters.orderType)
        ) {c_0x1d6d0026(0x3fa95f1f3321a3b960537a5e07692c42c37322a1b23c5c59e99dfe2251666b7b); /* branch */ 

            // Revert if partial fill was attempted on an unsupported order.
c_0x1d6d0026(0xae16af0befb339343cf499400240f8fab2bedb9658e330ebddb75c623a20c48d); /* line */ 
            revert PartialFillsNotEnabledForOrder();
        }else { c_0x1d6d0026(0x870c93e63bc0e2e22c51d55d0051a7b14e92b31828d56ad57cdfd9609c5cf73f); /* branch */ 
}

        // Retrieve current counter & use it w/ parameters to derive order hash.
c_0x1d6d0026(0x58fbebb51572dd612cff9c7398bc069b06c32a97159b2fb893bcd0ac87f105f6); /* line */ 
        c_0x1d6d0026(0x9d0e8b9215cecaec05a52b29fa4f1beca773751a7babce54582268e74e957186); /* statement */ 
orderHash = _assertConsiderationLengthAndGetOrderHash(orderParameters);

        // Ensure restricted orders have a valid submitter or pass a zone check.
c_0x1d6d0026(0x9c136f5be180894fa6c6f8c772dd034d02c8503896af99dbc7751523e1aa092b); /* line */ 
        c_0x1d6d0026(0x55f57dc1b5de2d28ce0ad7eaa18ea84853c55f75e30f5d9353d337758ee9fc59); /* statement */ 
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
c_0x1d6d0026(0xb0827c96c6a80dd9e08560f7275e05d27b9616a113beed6bf195c258930257c6); /* line */ 
        c_0x1d6d0026(0x8bb710015943e037d7a31989af5359ed21a0dd4c8d138461acf84c67eb85cb92); /* statement */ 
OrderStatus storage orderStatus = _orderStatus[orderHash];

        // Ensure order is fillable and is not cancelled.
c_0x1d6d0026(0xadb2ad4af3a79d5bd4ca413b4ba73ee0c97455ba67b3dc2bc8db792860be5e70); /* line */ 
        c_0x1d6d0026(0x647d8cea2d49e1005e0a4f51b503342b9fbf9bf874401e20032dfa271fad03cf); /* statement */ 
if (
            !_verifyOrderStatus(
                orderHash,
                orderStatus,
                false, // Allow partially used orders to be filled.
                revertOnInvalid
            )
        ) {c_0x1d6d0026(0xf9d7e99e8322b477ea45016ced338adbb539b7ff793db640475116726c4daf26); /* branch */ 

            // Assuming an invalid order status and no revert, return zero fill.
c_0x1d6d0026(0x997ed64dcd93244398c0a070b431505408ac1ecfb02b3faee37c299b08154653); /* line */ 
            c_0x1d6d0026(0x6118ad781366d97fc34306aed91c26f6e3fc8c0824e7143b843c16889d188400); /* statement */ 
return (orderHash, 0, 0);
        }else { c_0x1d6d0026(0x42b79e5d9f2a071a8a7a115854fb85339c81c042c6a1ac7a1590b141497c9209); /* branch */ 
}

        // If the order is not already validated, verify the supplied signature.
c_0x1d6d0026(0xa64d9d6df6acd390762df070d73f6b659e3bc0bf5acd86b5d70223be0a6bac78); /* line */ 
        c_0x1d6d0026(0x5c4341f8adb0e489b75fc5a1cc26bd23859ce7d4f760d9310a290217ac709956); /* statement */ 
if (!orderStatus.isValidated) {c_0x1d6d0026(0x6aec29ad0fd3e0a5913e704dbdd4c57157abaab59e6cccbd8ce83e3589efd397); /* branch */ 

c_0x1d6d0026(0x79b2b52a6dd2893ff0a745390a1a94cb58cc2c34c5aa97582a31efcd8c87a5fb); /* line */ 
            c_0x1d6d0026(0xb61983ea86b5682ce8d9ff41c4491f3ae6c18449f373ca4cf2beb803f6298f27); /* statement */ 
_verifySignature(
                orderParameters.offerer,
                orderHash,
                advancedOrder.signature
            );
        }else { c_0x1d6d0026(0x6f4ca7570d2263db7a66befaa0210501863c9f692fe128ec9a6b9a47f431abb0); /* branch */ 
}

        // Read filled amount as numerator and denominator and put on the stack.
c_0x1d6d0026(0x2a13ecfdb50592f7a43788734dd897d94701019a966caf93858bb341b0758c63); /* line */ 
        c_0x1d6d0026(0xfb03ccedf0ffd8e43596ae5bf1aa297d9dd9a94197d89c72b9ff5ff176992bc1); /* statement */ 
uint256 filledNumerator = orderStatus.numerator;
c_0x1d6d0026(0xe7bd229a85929d3a9af799340d56d729324e6940136a0b375ff4d1a16fd880a4); /* line */ 
        c_0x1d6d0026(0x3270f5c0420e3cb83bbc928f82b534d1fd168094feb105b83dc7914a120abacd); /* statement */ 
uint256 filledDenominator = orderStatus.denominator;

        // If order (orderStatus) currently has a non-zero denominator it is
        // partially filled.
c_0x1d6d0026(0xa3c900a91544dc10d926a30f0cb5af352c69d1301fad318b884f98121fed013a); /* line */ 
        c_0x1d6d0026(0x3f910d08976a90875e227f5ac51fa08edf7e84f88362265a82d60782c289a000); /* statement */ 
if (filledDenominator != 0) {c_0x1d6d0026(0x585adaf313c5b0d5559bd54fc7d8a4f889b776252f5a834941c0b8ae6f77c32a); /* branch */ 

            // If denominator of 1 supplied, fill all remaining amount on order.
c_0x1d6d0026(0x432b5b609c4a27b26a0092fc078a6926fc095f27d4cb372a862c950a5c6a10d7); /* line */ 
            c_0x1d6d0026(0x45e3e2dff78af026c2c133478b13e596b1e89d088ffe791dbf5b6608bd410a4b); /* statement */ 
if (denominator == 1) {c_0x1d6d0026(0x1acc3cf191657cf1fdd5bb37bcbea909db15039a2bef342b021961f7fef3dfa4); /* branch */ 

                // Scale numerator & denominator to match current denominator.
c_0x1d6d0026(0x1c607f3242cefe7976f37e6cae03d73de5dd885ae59ad2aad11c0a2f51376b7e); /* line */ 
                c_0x1d6d0026(0xb23d654285ce3a4ce238464933124616f9cd83253c05eb874bdf71e39654f7ce); /* statement */ 
numerator = filledDenominator;
c_0x1d6d0026(0x2c99fabb9b731db7b919751224366fea9f617a5664974ed4e7ce0074da8ef67d); /* line */ 
                c_0x1d6d0026(0x724f6894c6011ddc4d389d581d687c5b6d320582b3f8758c430fb253ab3a6e8c); /* statement */ 
denominator = filledDenominator;
            }
            // Otherwise, if supplied denominator differs from current one...
            else {c_0x1d6d0026(0x45885f777e92746cae5bb82456f5ab9ebfb3b82101bdcad5677069bfdfe198c5); /* statement */ 
c_0x1d6d0026(0x15a35c55bafd6738c84020e909da740997d95e74909199c782813cf56f3ff191); /* branch */ 
if (filledDenominator != denominator) {c_0x1d6d0026(0xb14bad57a5e36c8c86f4de87cf6af0aca5333cc33586b20c5cf32b314641b3b9); /* branch */ 

                // scale current numerator by the supplied denominator, then...
c_0x1d6d0026(0xca6073a412b2e397d7a298dc2730e7e41616cbe77b50112ac57657f3262866f1); /* line */ 
                c_0x1d6d0026(0x3cc59fb9467af105a7c493591402510d271562e07c894708ca014dbc649fb204); /* statement */ 
filledNumerator *= denominator;

                // the supplied numerator & denominator by current denominator.
c_0x1d6d0026(0xd4a89f317094cfd8a6462d09fbb66409eaf8d745116c860cd4296a2c25497276); /* line */ 
                c_0x1d6d0026(0xb159906c81648720044267e98a2592af2b7f993280c8ca0b61ecbadf6a250494); /* statement */ 
numerator *= filledDenominator;
c_0x1d6d0026(0xce1dcfe79b07f9e001b079ac3cd1d1b5e5656230c591c572c37498514b9c2de7); /* line */ 
                c_0x1d6d0026(0xdb2207bc69ea428f738a573df6c17e50167c1f3abac0316953d3b01113f8a162); /* statement */ 
denominator *= filledDenominator;
            }else { c_0x1d6d0026(0x441802f57bfb21b7bdc5b495f3e037d5111f8eabd39c577f940c371277333dc0); /* branch */ 
}}

            // Once adjusted, if current+supplied numerator exceeds denominator:
c_0x1d6d0026(0x9606a603becca1b79ec79b6e471abdf24cc058ba269a6be88775927b5b4f779f); /* line */ 
            c_0x1d6d0026(0x2893718c26b2ef6617296b64e6db5fff727f59473d129e1a4cfda6f4e9b77d4e); /* statement */ 
if (filledNumerator + numerator > denominator) {c_0x1d6d0026(0x919fd700cd36893f106f3007c400f70aaacc715d8ea9580bb64bb4c98bc1f1e2); /* branch */ 

                // Skip underflow check: denominator >= orderStatus.numerator
c_0x1d6d0026(0x34ce7776fc1a616e972caf687d93b4c2818a15c304e850aa32df3423ed4cdfa0); /* line */ 
                unchecked {
                    // Reduce current numerator so it + supplied = denominator.
c_0x1d6d0026(0x5aa206c002dba1032aac4a27a6398ae970284ccca7f9e9ba3186ef418c44cb03); /* line */ 
                    c_0x1d6d0026(0x24757949e868bb346a3bb4be52df23a428da6efd918bca09e1a7efe18f6c52fe); /* statement */ 
numerator = denominator - filledNumerator;
                }
            }else { c_0x1d6d0026(0x1784b5ff5f7d698214af6e05dfc3f8206016a30dcd13107e1f9c163b7af13eca); /* branch */ 
}

            // Increment the filled numerator by the new numerator.
c_0x1d6d0026(0x0f7f90a17db00e92135db54478a11134425b35d156af3d26ec7b3503edf98c3b); /* line */ 
            c_0x1d6d0026(0x29556a8c7c4e20e9bf4a0d1793af3bb97e39f9c982dde86dd10d388c92a1da78); /* statement */ 
filledNumerator += numerator;

            // Use assembly to ensure fractional amounts are below max uint120.
c_0x1d6d0026(0x96a09a5be0037193696d70351dd3c115b97b98a9e15af8f1a34444d413897e26); /* line */ 
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
c_0x1d6d0026(0x81e6e6cdf17747fb16539f88395a15747d61e2cea95c2d2869c0d44f6d91e78b); /* line */ 
            unchecked {
                // Update order status and fill amount, packing struct values.
c_0x1d6d0026(0x41b5c85352ddf7e6db31caf7445063912f894ecf77735ed112fb8b71215bbe9a); /* line */ 
                c_0x1d6d0026(0xeef567ca546e08359f05fd2a0ff08c7240550deb498f6eb94c1f283f03c2f98a); /* statement */ 
orderStatus.isValidated = true;
c_0x1d6d0026(0x7d2fa741f29c3e0218dcd5fee306f812233f972b891132de4385ef642b799ee0); /* line */ 
                c_0x1d6d0026(0x63e881f01ac9b366b77feefde87d2dc48605fa0b53ae93625568f7c5b1105de5); /* statement */ 
orderStatus.isCancelled = false;
c_0x1d6d0026(0x9cdcbff7265cd5d4cfabb83003f2b7280f243b9d5f7e7d36fef6a4c7eeda7d0c); /* line */ 
                c_0x1d6d0026(0x796f99f5ed16c70ed75fee09d3b027ba436a5fbe5f97eb48754f213c6293e287); /* statement */ 
orderStatus.numerator = uint120(filledNumerator);
c_0x1d6d0026(0x11bd5666b13e9b600ebd328a83daaf7cd62e73c2ccae68a461c1b23a732de199); /* line */ 
                c_0x1d6d0026(0x06ebb128746897d03f3b8aa4089980bb70bc4d6e705bac94a3a9d2c510ebdc61); /* statement */ 
orderStatus.denominator = uint120(denominator);
            }
        } else {c_0x1d6d0026(0x8c80f0974f474bd610db87b0037d1de1ff92c0d400b82014ddb553fb1a9a44f0); /* branch */ 

            // Update order status and fill amount, packing struct values.
c_0x1d6d0026(0x59f09bfa18fe6745e01799cb4a5bf30036cf30b4010a28604236b157353ed327); /* line */ 
            c_0x1d6d0026(0x24a2b615c1111223a61f8104da62bf21d58d6f46b18556a3cb9e26e72fb87cc0); /* statement */ 
orderStatus.isValidated = true;
c_0x1d6d0026(0x9aceeea3159717177411cdd87a45c30f7ec3f29facbe9b0215c8d58c0aa9f985); /* line */ 
            c_0x1d6d0026(0x20b3d65363c0dfd7342f1ae00df74b18b66fe007d604556b9c4c7f1397724a9f); /* statement */ 
orderStatus.isCancelled = false;
c_0x1d6d0026(0xa6030cee3b8a9002263b19837bf94484650c6e98a90ab62e7ca2bb8f6a6d0e41); /* line */ 
            c_0x1d6d0026(0xbf8a81430a524116a308355cc20eff5b660657aa43d1424fabf56ff2f56e1ac6); /* statement */ 
orderStatus.numerator = uint120(numerator);
c_0x1d6d0026(0xe058ead81e489ceaf2f3402827844060b998b0c12b663d4e611667fdbf37392d); /* line */ 
            c_0x1d6d0026(0x97fbb5569612b03698c92296ae2c8c96618104cf701526a515e46a93677acb51); /* statement */ 
orderStatus.denominator = uint120(denominator);
        }

        // Return order hash, a modified numerator, and a modified denominator.
c_0x1d6d0026(0x6aa069be60bd26614a5f81421565657d0132e3524fbbea479335efb5b0962d85); /* line */ 
        c_0x1d6d0026(0xa3bae6f4ae2d391e75c90be6fa7685409fc3fbcdd06e03b33b1da570f7a30e8d); /* statement */ 
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
    {c_0x1d6d0026(0xe11b48b94a8b91ba3109973784cea52485c9ae576737ab5246b98c19d0a02252); /* function */ 

        // Ensure that the reentrancy guard is not currently set.
c_0x1d6d0026(0xcace137073ed5c09bc515f188ca2a0b4c395f38661aefb93ed552376759301c4); /* line */ 
        c_0x1d6d0026(0x0b7f66785619e1d31b2d69a6624b0841b04e98e61d55b84bf4f56249c3136b39); /* statement */ 
_assertNonReentrant();

        // Declare variables outside of the loop.
c_0x1d6d0026(0x142b160fafd39cf20da4f79a0c973d4047bf45a5c6bc480326116cbfd09385d0); /* line */ 
        c_0x1d6d0026(0xebe0764ecf18e33f0d784997692110b7eaed34c6948c4b4a47c54147e49f1fce); /* statement */ 
OrderStatus storage orderStatus;
c_0x1d6d0026(0xf7f71c16df28e4a98a2afba8efca919c6e64ac2ca1cab1d608ce23e48c3d04a0); /* line */ 
        c_0x1d6d0026(0x4fde60a952098460278281a4e985cfaac5809ae5cab8e7cb6a00c374e5c38fa8); /* statement */ 
address offerer;
c_0x1d6d0026(0x749c4d861f5762223f625cc7ae92fa0e17cdf17a975a80fbb5339ba4c1eb191d); /* line */ 
        c_0x1d6d0026(0x2e81dbc73b00c6bb734c1377f65cec42ee5abbe7b5b90f46a6a573d2bc518c0c); /* statement */ 
address zone;

        // Skip overflow check as for loop is indexed starting at zero.
c_0x1d6d0026(0xa74c093c23d7d57c5d94bb8421b8c705787403a6f8e0fca7a7f9779dc2ef8049); /* line */ 
        unchecked {
            // Read length of the orders array from memory and place on stack.
c_0x1d6d0026(0xa66ccefa8ba086c179b3984421999fda5d151076ef79e8bfcce42f4f7f7948b6); /* line */ 
            c_0x1d6d0026(0x9141c21d2fe26197494a9b616abed5eb3e4cd5a3f29b668f43bcb2397c452fb3); /* statement */ 
uint256 totalOrders = orders.length;

            // Iterate over each order.
c_0x1d6d0026(0x18042a153a0ca33e87cd01dcbddacfec7b325e69aa7212673084357b728ff540); /* line */ 
            c_0x1d6d0026(0x068e84f451e217aca5a9bb058bbbdab9e00cd2c87079630d79bfaff3820d611e); /* statement */ 
for (uint256 i = 0; i < totalOrders; ) {
                // Retrieve the order.
c_0x1d6d0026(0x0c0affdd8980a1995c63bcca41e06f59d720da8d975aacd6f7a190b92f507164); /* line */ 
                c_0x1d6d0026(0x6076d0c770451684070f7606a29b778eb9edc1f4a8d3124972791c7aa70d9f95); /* statement */ 
OrderComponents calldata order = orders[i];

c_0x1d6d0026(0x048938cc278285673a365e5414d236c73fd0d9e3acd4a9e94971083ae8048d5a); /* line */ 
                c_0x1d6d0026(0x4fb0f8c1703d0bd529dbaf1dbd64a664dd4ad059a893b21d52395d7fc11cd610); /* statement */ 
offerer = order.offerer;
c_0x1d6d0026(0xa5925e9a8a2f0fa9cc19451e09cccd54aff40af53ebc6d5c602165908d54f6d0); /* line */ 
                c_0x1d6d0026(0xde611aba5501296d9599dbe4690aff80ef97b52f7be7b5047504a744fce75d67); /* statement */ 
zone = order.zone;

                // Ensure caller is either offerer or zone of the order.
c_0x1d6d0026(0x7dea9015a90147a8a345c0922145f757fdb52f70e0b4b30a41cd33cb1c0f4aab); /* line */ 
                c_0x1d6d0026(0x88c49d09c85201fdaed762a75daa6b0ba43d1253cbe6b42d64257f16423a43ec); /* statement */ 
if (msg.sender != offerer && msg.sender != zone) {c_0x1d6d0026(0x8ee028dae1832c1491733339fb272478556f53101e1f96189bc5b437fe8af5c7); /* branch */ 

c_0x1d6d0026(0xe18b03ddc07418de766406d9c35f7c97349262e9fe827f680ffcdaf650099e54); /* line */ 
                    revert InvalidCanceller();
                }else { c_0x1d6d0026(0x96aa78e717a9ded1be742a8d9a4a49f70ca34970f5c3a25c5e3eb9d6339a69de); /* branch */ 
}

                // Derive order hash using the order parameters and the counter.
c_0x1d6d0026(0x8120402410d6f03ef1d446793d102b480a76f34ad97fcac78759abf543dd988f); /* line */ 
                c_0x1d6d0026(0x515b7d988679532fc1e4657d4f2d501bd83b2fac870fa46ecaf86080744efafa); /* statement */ 
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
c_0x1d6d0026(0x6e0b3462531bbfda659c8a862c172bf4ee0d747b210ba8548611412b958cd2b6); /* line */ 
                c_0x1d6d0026(0xec1f43a94f43c2751098728ca0b5802466e61e7e22b1b2356ecac50ad2cda917); /* statement */ 
orderStatus = _orderStatus[orderHash];

                // Update the order status as not valid and cancelled.
c_0x1d6d0026(0xadca9a150d97d8111d4663bedfa532bf763758a6b261041a6dad868e3daa4618); /* line */ 
                c_0x1d6d0026(0xa91440910f9163f3bc66c04eadbc3cf42879e0f1c1e1bd32e4716ed9bf20acd0); /* statement */ 
orderStatus.isValidated = false;
c_0x1d6d0026(0xab2af02f96f97205cf96b0875f35b66bf128033070b36592de9ecb0b8f3b7a08); /* line */ 
                c_0x1d6d0026(0x9e59ea5d64cee733ae18fdf80efd2f97ee57f07c33968821191ea7b7729253ae); /* statement */ 
orderStatus.isCancelled = true;

                // Emit an event signifying that the order has been cancelled.
c_0x1d6d0026(0xce82ec3a19789a9681c6f504e1f9ec63b90b3c077587720f7209e603b5fe22f0); /* line */ 
                c_0x1d6d0026(0xe37509065dbc80c261220d743416ab01f0dd3dcf488bdbab298f73fe29fbb0bb); /* statement */ 
emit OrderCancelled(orderHash, offerer, zone);

                // Increment counter inside body of loop for gas efficiency.
c_0x1d6d0026(0xb4c70abda9665f35f07122965359a78edf85aa3d1c28643e3cc7487722464d5c); /* line */ 
                ++i;
            }
        }

        // Return a boolean indicating that orders were successfully cancelled.
c_0x1d6d0026(0x0fbdcec5350568466f961e1a7fffc623a0e9623149ef9daad3836c04e7df28f7); /* line */ 
        c_0x1d6d0026(0x9faeb0a6f9b91b6becc2f4f505ef9a88a563392e5433a05c715a2948d38ef5b4); /* statement */ 
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
    {c_0x1d6d0026(0x4108645bd82d1dec4305e85af72f509898490b276bfe30f1681e1ba9d5f73ce2); /* function */ 

        // Ensure that the reentrancy guard is not currently set.
c_0x1d6d0026(0x1e4f87c8670573f14584d3ecda0dd049b8e95b749dc7a9f9ef7a82ea4a8a3836); /* line */ 
        c_0x1d6d0026(0x6da3aa9975036d892f2aad2fcdb0551d642bbbf3aa49bc642b93a5851dfb3e4e); /* statement */ 
_assertNonReentrant();

        // Declare variables outside of the loop.
c_0x1d6d0026(0x2c450f3259a5c3eb40b6884bd589feab6f71cea1b7f06a7d3724c4d0ddbc2440); /* line */ 
        c_0x1d6d0026(0x377ec01febd1f64e73c0389eb3ed30458b1d45a1f86bbdbd41a4b7a2d7f0bbfe); /* statement */ 
OrderStatus storage orderStatus;
c_0x1d6d0026(0x990e53bf36a4e30d3c687003b44ced77048e00a609c662d4232c39408f783405); /* line */ 
        c_0x1d6d0026(0x737944e5c8a78749ffc8f8c49fbe4a784ec43ff3bf1688e77c494f24a26d6f40); /* statement */ 
bytes32 orderHash;
c_0x1d6d0026(0x9d9495d2141aceddc4d5584ce9e301844fc9ae48e5525e62a4e27d0f6883a1b1); /* line */ 
        c_0x1d6d0026(0x1d1d0730d587508f6c9b0602bc3598791e2fb5ce6616899deeb3ad7c3a0e0c83); /* statement */ 
address offerer;

        // Skip overflow check as for loop is indexed starting at zero.
c_0x1d6d0026(0x222620a3350413f0b7f825287d5e3c9245856d1e5001d1193d1099b05c01b72e); /* line */ 
        unchecked {
            // Read length of the orders array from memory and place on stack.
c_0x1d6d0026(0x893f6e35cd69ca0d9d1ca1c7bc47b2273fe5cfc978910d071e914a41fb974d89); /* line */ 
            c_0x1d6d0026(0x781a73112ed2e3ce3324e15606553a742b4886fb1e7217e1fd45ee35ccc8dc85); /* statement */ 
uint256 totalOrders = orders.length;

            // Iterate over each order.
c_0x1d6d0026(0x65cd43758711ddb44ae4b8158a11903a1774f60d59bed7312e66899d4473325a); /* line */ 
            c_0x1d6d0026(0x5334b1300ec46a8ed13df9239b6d6693f091e9ba484ed257613de5e968a59e45); /* statement */ 
for (uint256 i = 0; i < totalOrders; ) {
                // Retrieve the order.
c_0x1d6d0026(0x06f8f611442c97cf15e6dce91a3dff55835222cb88eeefd87c4271dfddf9e92f); /* line */ 
                c_0x1d6d0026(0x81b8249d4815a10959f5ea7cee3de72de960b2674690bf4abc711e4888830dcd); /* statement */ 
Order calldata order = orders[i];

                // Retrieve the order parameters.
c_0x1d6d0026(0x8c61a36a2af284760f3de1afe4229f4f5a710010ac194b3c8af924f05fc14f8a); /* line */ 
                c_0x1d6d0026(0x0542a716fc6fd5cdd299b5aba97ee057acd73a5d438ecaceade51061687dae0d); /* statement */ 
OrderParameters calldata orderParameters = order.parameters;

                // Move offerer from memory to the stack.
c_0x1d6d0026(0x9adfc9b6718ae5b6d0e21d9d1835a4612b2ff82b98b7dc5755ab1d65b0fd6f60); /* line */ 
                c_0x1d6d0026(0x18799d9e6280963a3a7a705a87e2d87c02c3963c130d7ee41feebe6bfd00670b); /* statement */ 
offerer = orderParameters.offerer;

                // Get current counter & use it w/ params to derive order hash.
c_0x1d6d0026(0xb09cc2235ff0668bf8afc0436d0966a8dbd1d25af8449ef279d07b23e362b3c2); /* line */ 
                c_0x1d6d0026(0x342868b918919f4a5194e1dab8ab13bb394067074c814f29445cde143415fd01); /* statement */ 
orderHash = _assertConsiderationLengthAndGetOrderHash(
                    orderParameters
                );

                // Retrieve the order status using the derived order hash.
c_0x1d6d0026(0x87649bd3bc076b01dbae8958c10132429fe9f5d5051649182bf85426cd469eb6); /* line */ 
                c_0x1d6d0026(0xbf4d0839f161ba398cb306fd56fe52a8c0a8fa12ad29c1169ae155e5df213db1); /* statement */ 
orderStatus = _orderStatus[orderHash];

                // Ensure order is fillable and retrieve the filled amount.
c_0x1d6d0026(0xa1158780c76a97537caaa3743886c91206e694b9e793d8266a8bfc1641069c4c); /* line */ 
                c_0x1d6d0026(0x8b2d8969343cb0e5c9af763db7d28c1db77e30ca55f1742818a228674d8c81ed); /* statement */ 
_verifyOrderStatus(
                    orderHash,
                    orderStatus,
                    false, // Signifies that partially filled orders are valid.
                    true // Signifies to revert if the order is invalid.
                );

                // If the order has not already been validated...
c_0x1d6d0026(0x1b2f98a2b54ed194465545b06b4d4ba085dabf0e827b84b38f6bfba01da4a56b); /* line */ 
                c_0x1d6d0026(0x1c1c553bc2ce03fa6f949e80b376728420483257b508b576954d93c2bd0ee36f); /* statement */ 
if (!orderStatus.isValidated) {c_0x1d6d0026(0x443a4e19fdea5cedcbaecaba702dcef520f85e38d7838a44d8ceae7fc861a775); /* branch */ 

                    // Verify the supplied signature.
c_0x1d6d0026(0xc3fc5ce05cb7e302d737af79178ba22243af2792ac5b14538adfdb09f2b8faa9); /* line */ 
                    c_0x1d6d0026(0xd73ab9c34c947bef5457978f098b6104f2014fa9cbd06670dbc152131576a33d); /* statement */ 
_verifySignature(offerer, orderHash, order.signature);

                    // Update order status to mark the order as valid.
c_0x1d6d0026(0x0096af64f696b806c06f996b31b4f269838bf089f4366ed3f948bd9cb53c4b73); /* line */ 
                    c_0x1d6d0026(0x96d513132b74f372e4c549d102da4959d76a9fe4cd78c1a7b7fa1520d2fddf95); /* statement */ 
orderStatus.isValidated = true;

                    // Emit an event signifying the order has been validated.
c_0x1d6d0026(0x51420c94c88fc138e0873f99b0c6a44f1c02750d57b4cfd3dcd00663187c8b76); /* line */ 
                    c_0x1d6d0026(0xafcc6c717855c253422077999d682b6176cd6d78b08ac78191997f161be60e6d); /* statement */ 
emit OrderValidated(
                        orderHash,
                        offerer,
                        orderParameters.zone
                    );
                }else { c_0x1d6d0026(0x4bff8725896749046d5dbae171a9263483271411418cb005296cbd101fb781a0); /* branch */ 
}

                // Increment counter inside body of the loop for gas efficiency.
c_0x1d6d0026(0x3e3ef229c519a35e90919660b06a23bbc66f6406fb2d77873d272dd8407fe085); /* line */ 
                ++i;
            }
        }

        // Return a boolean indicating that orders were successfully validated.
c_0x1d6d0026(0xf32459e8eaf095b48c13e3aeb14cdaab925fe59d4179c44f3a28ebf8723d55fb); /* line */ 
        c_0x1d6d0026(0x5456a511385026926569263c020c27afd829e1cf752b4d9e6dcc8a5f656b83d2); /* statement */ 
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
    {c_0x1d6d0026(0x272418325fac7159f7a2e9089676f46d741441962b8441ae395a11ca57068097); /* function */ 

        // Retrieve the order status using the order hash.
c_0x1d6d0026(0x27debbd5388a2fd042d93f924c5f6b0338e3cbb66725fb408ebef51f208fb202); /* line */ 
        c_0x1d6d0026(0x6ad9eed07bf5dfff4ababa7e14c199621b88e4e6f77ae53ee1db9864e8b441a3); /* statement */ 
OrderStatus storage orderStatus = _orderStatus[orderHash];

        // Return the fields on the order status.
c_0x1d6d0026(0x2566f64b101d720fa9b2d8339c1a391a92c655a6fda1ca72d471a74fff204d01); /* line */ 
        c_0x1d6d0026(0xc5659de502506caf3356af6f614b31e5b4384c1090b407cc69218196f74582d1); /* statement */ 
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
    {c_0x1d6d0026(0x0308bb9993e14dcea29125518137bb08f83d6ad38a65dc8aaacc8c1e3e3fa5a2); /* function */ 

        // The "full" order types are even, while "partial" order types are odd.
        // Bitwise and by 1 is equivalent to modulo by 2, but 2 gas cheaper.
c_0x1d6d0026(0xe8a916c53e1b8444d0852993cb0e355fcbd4b0480f095e5ca0ceb0442a6afd57); /* line */ 
        assembly {
            // Equivalent to `uint256(orderType) & 1 == 0`.
            isFullOrder := iszero(and(orderType, 1))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0x3438cbe7(bytes32 c__0x3438cbe7) pure {}


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
function c_0x359c53b5(bytes32 c__0x359c53b5) internal pure {}

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
    {c_0x359c53b5(0x8ac4dfe7ce8babbc739a53fdecc3f11aeb3529b560aff71e6595f824cc7e1e51); /* function */ 
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
    ) internal returns (bool) {c_0x359c53b5(0xe00a39e331e24b434f01869587b7296671b5817cd0a5a5c9af6bfa77becbf20e); /* function */ 

        // Ensure this function cannot be triggered during a reentrant call.
c_0x359c53b5(0x1de20341c90b8112515bb57196e85f7d489d8f2afaa5d0dcd95f87272d85a0c3); /* line */ 
        c_0x359c53b5(0xea5a8de2e407e76d48861b6ce64d7321573bb0d7db48e28b1d26d97d75677416); /* statement */ 
_setReentrancyGuard();

        // Declare empty bytes32 array (unused, will remain empty).
c_0x359c53b5(0x7c444fc3b59309a9f8fb0608a63d2a16869e014cd4ee6827af84c92db0fa3794); /* line */ 
        c_0x359c53b5(0xf0c2387a2c05eaaedc4ab528bce7697853946f9b3e7778603ccf5abf1b04e9ba); /* statement */ 
bytes32[] memory priorOrderHashes;

        // Validate order, update status, and determine fraction to fill.
c_0x359c53b5(0xfeb1bfd61384256a7906b0eeb7965f2c6ec0257bb2592c0f3bc7d4ef7126c35b); /* line */ 
        c_0x359c53b5(0x6de2d6cb4d95eeafd92fb59683af9a7ea625d038cab8afaab77392a0dc78ce3b); /* statement */ 
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
c_0x359c53b5(0x3a3abbcecb244ce83bc36cb6bf1b7ad608125e4985773f37372e9c3df21b069b); /* line */ 
        c_0x359c53b5(0x22ab5ee2474e8f194a51e8dfcb0326e177148900fd15fdad927873c337a9b41c); /* statement */ 
AdvancedOrder[] memory advancedOrders = new AdvancedOrder[](1);

        // Populate the order as the first and only element of the new array.
c_0x359c53b5(0xb85ea68b00bc0c968eae52e4151d6b68743da2361abfca2af5ba1d3a06656721); /* line */ 
        c_0x359c53b5(0x8d27482375308eb77918d9d9f06bb1e2d0b697d58977105ddbe4dd9db901db50); /* statement */ 
advancedOrders[0] = advancedOrder;

        // Apply criteria resolvers using generated orders and details arrays.
c_0x359c53b5(0x07eda7c0f3862ae277f6bbe5c73d8c8a47b50618ba005d3e3fe001c71b2e8e0b); /* line */ 
        c_0x359c53b5(0x9f5cabda8d71649b2ae43f5d575bf4dd384fe6054dd52462ac9fbfe8b86aa1b7); /* statement */ 
_applyCriteriaResolvers(advancedOrders, criteriaResolvers);

        // Retrieve the order parameters after applying criteria resolvers.
c_0x359c53b5(0x261b61871b87694b13ccd3932888ecf3eb16e38ec74b57e2b6dc857be64a06bb); /* line */ 
        c_0x359c53b5(0x1d9c15dfe42688d3515d82df8c17d74aa52d9cd78be26f0b3327c2fb82c061b7); /* statement */ 
OrderParameters memory orderParameters = advancedOrders[0].parameters;

        // Perform each item transfer with the appropriate fractional amount.
c_0x359c53b5(0x4f6838b63c881dcd439454da96f74164d9f038c37f873a61f0d5ca94ce0342c1); /* line */ 
        c_0x359c53b5(0xb0a0dabac02944583454d463089ca826e5576b07e2fd8f137694ab0d4bf1fb86); /* statement */ 
_applyFractionsAndTransferEach(
            orderParameters,
            fillNumerator,
            fillDenominator,
            fulfillerConduitKey,
            recipient
        );

        // Emit an event signifying that the order has been fulfilled.
c_0x359c53b5(0xd199f51ae67478579c4a2a8580d6becaab093b636e9463e58eb78f10780f9b3c); /* line */ 
        c_0x359c53b5(0x4074dbca2eb82204ff4f8ee2c5c5221f7f9f0332a0ce7915210b0fb92c93570f); /* statement */ 
_emitOrderFulfilledEvent(
            orderHash,
            orderParameters.offerer,
            orderParameters.zone,
            recipient,
            orderParameters.offer,
            orderParameters.consideration
        );

        // Clear the reentrancy guard.
c_0x359c53b5(0xa35f0ec685d37f09a2f584df9c2893a81dc4edf3385660f39d69b1ea5991f129); /* line */ 
        c_0x359c53b5(0x9be2d7de67e946915a9a803d67027fec431c1467276a5870b6626c53ea303d2b); /* statement */ 
_clearReentrancyGuard();

c_0x359c53b5(0x35f05d72b4406800a7eaf1d9b5986a4d082876834659eb097f05670d14bd6413); /* line */ 
        c_0x359c53b5(0x8b221fa601bd5533174270387abbe8c5635674ae779efcdb7f1b2825e11591ce); /* statement */ 
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
    ) internal {c_0x359c53b5(0x648d61715a6cda9d87950aacea037f21cc2feeb5b18be7e577f634e84b6f2334); /* function */ 

        // Read start time & end time from order parameters and place on stack.
c_0x359c53b5(0xa303572df20690bd64bd6063d01cf1dd3a8273289923a8cf169618f78d45e6f5); /* line */ 
        c_0x359c53b5(0x91cbce93c8a62552bc2efea8d8fc04372d2b54b2973601f19431479137c12312); /* statement */ 
uint256 startTime = orderParameters.startTime;
c_0x359c53b5(0x1726cc45a44c7352a5ba89ec560a199978b1c8228f25f2443f89db0725101c15); /* line */ 
        c_0x359c53b5(0xb147698dd051f4368454509744213e4a4b3d64f926b42e747a217585db7bc96c); /* statement */ 
uint256 endTime = orderParameters.endTime;

        // Initialize an accumulator array. From this point forward, no new
        // memory regions can be safely allocated until the accumulator is no
        // longer being utilized, as the accumulator operates in an open-ended
        // fashion from this memory pointer; existing memory may still be
        // accessed and modified, however.
c_0x359c53b5(0xbd69370f1d2d28786068de7492e916ab0b46e87f71c8373bea4b3885c7a052af); /* line */ 
        c_0x359c53b5(0xcc020148ce09dadf54a3a39db7504698cbe20dece684895ed6bc4fe9992ac180); /* statement */ 
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
c_0x359c53b5(0x49c548916965088dd468508f1459ec8b1fe0722151cb762e7f7b5f62fd9ba67e); /* line */ 
        unchecked {
            // Declare a virtual function pointer taking an OfferItem argument.
c_0x359c53b5(0x561477e9d917bc17a2baa0510c9e57880b4883349f75670c3bbdda4dae271b04); /* line */ 
            c_0x359c53b5(0x844eef1f2476e1653a5a2575be6d135c2cb8276b4f57f4d41333ce56d9c02020); /* statement */ 
function(OfferItem memory, address, bytes32, bytes memory)
                internal _transferOfferItem;

c_0x359c53b5(0x4a69983f5a7b4cf4e4c12444a18bc7a8aaa2c33e324875bf83d590823b43430b); /* line */ 
            {
                // Assign _transfer function to a new function pointer (it takes
                // a ReceivedItem as its initial argument)
c_0x359c53b5(0xef7d5ebf7dd629bc0672ad30151bc908fd9c30d3a2a304284b7f90ebf6b83f9b); /* line */ 
                c_0x359c53b5(0x6078078989e4c16375cd95bcbda35676d44be064149bd4b305eb8d7494b52818); /* statement */ 
function(ReceivedItem memory, address, bytes32, bytes memory)
                    internal _transferReceivedItem = _transfer;

                // Utilize assembly to override the virtual function pointer.
c_0x359c53b5(0x344c09aa01b8107ae74b030bfb0efb7f6df73c189fa8c64a8721dadf9f14227a); /* line */ 
                assembly {
                    // Cast initial ReceivedItem type to an OfferItem type.
                    _transferOfferItem := _transferReceivedItem
                }
            }

            // Read offer array length from memory and place on stack.
c_0x359c53b5(0xe73992831d855d1d41de112f3368bb100461a1a09f7f4e3b85a2c57f22c2aed6); /* line */ 
            c_0x359c53b5(0x01cdc5f883d07a5db3901c1681b0adca432afb47cd8b372d7bbb22e822cbe67d); /* statement */ 
uint256 totalOfferItems = orderParameters.offer.length;

            // Iterate over each offer on the order.
            // Skip overflow check as for loop is indexed starting at zero.
c_0x359c53b5(0xbbf4c6be9bde68a5814178540e4c6049669cef39958460649e24f9d5a7866cfa); /* line */ 
            c_0x359c53b5(0x91c28586ee7e33212938db26b89654c22bc5adc25416628d8559c6f038a5a40f); /* statement */ 
for (uint256 i = 0; i < totalOfferItems; ++i) {
                // Retrieve the offer item.
c_0x359c53b5(0x04dce80df3d1e31b583375a3801208128173bd522483b42eb09717dabbb3c1fe); /* line */ 
                c_0x359c53b5(0x7d4dc522b55b6c9d7aee62b0346dc6cd0f659aab385f52266bc8ff85fcad4908); /* statement */ 
OfferItem memory offerItem = orderParameters.offer[i];

                // Offer items for the native token can not be received
                // outside of a match order function.
c_0x359c53b5(0x376776b3786f9837441bfb48362c21839a296e14f5a990e5509adba534e08f9e); /* line */ 
                c_0x359c53b5(0x15271b909052bdb859c447b42a2a4577c94e0a3d60bbf09c659257d07fbf29e5); /* statement */ 
if (offerItem.itemType == ItemType.NATIVE) {c_0x359c53b5(0xdb2b9a579342b1bceb45ca642c0854fb575f0634e1e0b66c15ca815ee07aef2e); /* branch */ 

c_0x359c53b5(0xb945dc64ece8b0d06307af78c105f8e87da91b079899178d9bae963d6a39c0cb); /* line */ 
                    revert InvalidNativeOfferItem();
                }else { c_0x359c53b5(0xb832f4cf7ec023d9b6f8ea22354b7dc9280ee804d3c8c45d678e03c8ffe4f0f7); /* branch */ 
}

                // Declare an additional nested scope to minimize stack depth.
c_0x359c53b5(0xcc6a3af573ebee4865e04eaa1cf044e6d923dae0a476043fc5c45819d564f988); /* line */ 
                {
                    // Apply fill fraction to get offer item amount to transfer.
c_0x359c53b5(0x07c3357a9affd2d287bc5064f2eff4e75620917617ccc0d96d6b06bfe870024a); /* line */ 
                    c_0x359c53b5(0xfb2e39d04a9df8907bf39016ce357f6fc56641aad31347d7f2d31576a64cd55a); /* statement */ 
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
c_0x359c53b5(0x664750ccfcfd775d38772ac21329ebe73613d6ec8b9b8874e6b0af72ad38a531); /* line */ 
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
c_0x359c53b5(0x6cca894c7011e7a2469ab7aa5bf17bf98a1ebf965b5d2c843b9b8183d4f6dfd8); /* line */ 
                c_0x359c53b5(0xc8a144ee0b6f57c78719c2ea7245a72247c25f3620bdafceb0056d001483f58a); /* statement */ 
_transferOfferItem(
                    offerItem,
                    orderParameters.offerer,
                    orderParameters.conduitKey,
                    accumulator
                );
            }
        }

        // Put ether value supplied by the caller on the stack.
c_0x359c53b5(0xc928420f346882e314cc43726b73a4405ebe0246f30bb45a52cf5414f9d61a6a); /* line */ 
        c_0x359c53b5(0x9321b4f8f16be36ed1beac4b4a7fe2c44ff6dc0c2d26177301f471c40cce541f); /* statement */ 
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
c_0x359c53b5(0xda7180b000b4557fb43c4cca2ca26461823a40a38eaf3689e65ba90287e433c8); /* line */ 
        unchecked {
            // Declare virtual function pointer with ConsiderationItem argument.
c_0x359c53b5(0xe402f5a8f1e0df983c44019d1d5e4790a8cbbc24afc6805128d45bd87a169391); /* line */ 
            c_0x359c53b5(0xf4aa0f04ca9ca5dd1a2e3f17739ee6afd3f141f4c3eb637da5c72736f8ffaa99); /* statement */ 
function(ConsiderationItem memory, address, bytes32, bytes memory)
                internal _transferConsiderationItem;
c_0x359c53b5(0x4cf60fba21a0953a2106a576307fc0c091a877c78f2a9239cbcf8376031e632a); /* line */ 
            {
                // Reassign _transfer function to a new function pointer (it
                // takes a ReceivedItem as its initial argument).
c_0x359c53b5(0x23d0fdde7cbb7f35672658475329ca8ba0036149626317e96d4b8ae231c50abe); /* line */ 
                c_0x359c53b5(0x2358443a029f2d63037217e2aebf9477d2d23280f167382c46fbcfc2718455b5); /* statement */ 
function(ReceivedItem memory, address, bytes32, bytes memory)
                    internal _transferReceivedItem = _transfer;

                // Utilize assembly to override the virtual function pointer.
c_0x359c53b5(0x91591a45cd130886b4dceaee3bf0ea565c7ede95380c799d08a29f8df6590d6a); /* line */ 
                assembly {
                    // Cast ReceivedItem type to ConsiderationItem type.
                    _transferConsiderationItem := _transferReceivedItem
                }
            }

            // Read consideration array length from memory and place on stack.
c_0x359c53b5(0xc78f5eac549df8b22827a6f023a7081193f9148ed679b538dd95076ae29c75c8); /* line */ 
            c_0x359c53b5(0x95a03f1017392615e530663b3c87228ce447ec318d5c04b0ccd2afd0129b92f5); /* statement */ 
uint256 totalConsiderationItems = orderParameters
                .consideration
                .length;

            // Iterate over each consideration item on the order.
            // Skip overflow check as for loop is indexed starting at zero.
c_0x359c53b5(0x31b42af918beb32c342ec915489249d046d8ff78b4162add94fde729ba304579); /* line */ 
            c_0x359c53b5(0x59af89f737e60f58d298276bfaa759a829ec7f06bdf4ad8bc2c52a5035854953); /* statement */ 
for (uint256 i = 0; i < totalConsiderationItems; ++i) {
                // Retrieve the consideration item.
c_0x359c53b5(0xcb378e8532e61ac0e3b58a08386b36651ee8a253c0f3087bd5a4b8a19828ac1e); /* line */ 
                c_0x359c53b5(0x23e043283ab27288f222290ffcad24ecbe0262e06df70cf5f77841988a628f31); /* statement */ 
ConsiderationItem memory considerationItem = (
                    orderParameters.consideration[i]
                );

                // Apply fraction & derive considerationItem amount to transfer.
c_0x359c53b5(0x2af965090d6e157aaeff8a18eddbb5c009e77a8f1e29d5ec045afeb504ea9c58); /* line */ 
                c_0x359c53b5(0xa888d563b716511a6113543ae6d1d2b8b87809d842abf8e8a32101b753eff307); /* statement */ 
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
c_0x359c53b5(0x404f42f9f00ee47dbf7210904ac801b242e3c07c99f52bb9133b6a7218a4f337); /* line */ 
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
c_0x359c53b5(0x503b8fde0730eac5ff5ad29ae9f6a4905263746f952c3c724c0c6b83fb3af09f); /* line */ 
                c_0x359c53b5(0xa24d32b902914cf2786d324a8b4187248e80a4134eea726cac742c7d86ef39c8); /* statement */ 
if (considerationItem.itemType == ItemType.NATIVE) {c_0x359c53b5(0x1085d8193a4cbe08a6e2afa5f0951830372aa8402866002087784ea7865f5a1d); /* branch */ 

                    // Ensure that sufficient native tokens are still available.
c_0x359c53b5(0x164aa494b524e9699f50408c06458fcf7d7c4d35c8f79ebc6f8eb08400c5cec1); /* line */ 
                    c_0x359c53b5(0xd39b7474d8ec19d900ca81cfa18ee149e5dc563dab06c8b5e57f414bd7b54dd9); /* statement */ 
if (amount > etherRemaining) {c_0x359c53b5(0x48782133492b06ceec991446dd5710e67cfb8de82654043cbbcfed57f3f30421); /* branch */ 

c_0x359c53b5(0xb5d838361d022ca18668e30d64b4ad9f2be36d3e859f94f3e594df6f89b365bf); /* line */ 
                        revert InsufficientEtherSupplied();
                    }else { c_0x359c53b5(0x227028abfd83cb7ddaa91d64ceb94ef0113a59245f84cb6bbda66323ac0bba6d); /* branch */ 
}

                    // Skip underflow check as a comparison has just been made.
c_0x359c53b5(0x21a632b9419a1e1c2ff9242dc0a1f5bffeececd5da0a188322765e7e6f20157d); /* line */ 
                    c_0x359c53b5(0x901d525cbef4bbcc61e76e5ba87cfc0b0f34248382d16ab2ed1c79a534f4d332); /* statement */ 
etherRemaining -= amount;
                }else { c_0x359c53b5(0x4cc5bf7bfe0fea08d9045e01511436bd5708db7eba714de52df26118ed6429b0); /* branch */ 
}

                // Transfer item from caller to recipient specified by the item.
c_0x359c53b5(0x840f88701505b9b67b29e3117b285bff42a3a25f09aa7483eeb5c03c1ffaa728); /* line */ 
                c_0x359c53b5(0x437582158592cffadf4d34e0e5c47cdd3eb837b6e29bb4d2a7933ab53593866f); /* statement */ 
_transferConsiderationItem(
                    considerationItem,
                    msg.sender,
                    fulfillerConduitKey,
                    accumulator
                );
            }
        }

        // Trigger any remaining accumulated transfers via call to the conduit.
c_0x359c53b5(0x29ed200d559f27891e8f3430cea1d610dfd94ec319119e7b7d294569d6eaa6dd); /* line */ 
        c_0x359c53b5(0xd1122a1dede0af4d202ea96cf319bf8562515652e9fbdfe3616280befa6782e9); /* statement */ 
_triggerIfArmed(accumulator);

        // If any ether remains after fulfillments...
c_0x359c53b5(0x6f5244ee23a3f2fc0c224c6584a964805d9216eecd64b6a9189814696ff9b32a); /* line */ 
        c_0x359c53b5(0x8f15d0305a9b8f974f378ad6f9e6ae6084ae9573f24217ec570c215720f2d5aa); /* statement */ 
if (etherRemaining != 0) {c_0x359c53b5(0x7f2a22266fc46f673f588969a7b9ef6816af5af91c5252de262562b22b4b9e9b); /* branch */ 

            // return it to the caller.
c_0x359c53b5(0x0fcde0cd78d822b1e679267454e19b5ca771e4a3868f45d9f440c5387e76c1ca); /* line */ 
            c_0x359c53b5(0xdc12598c777e45d28374782c7e3fe560b0cb03a7e3bd8f0ad68b1e63fb4aedaa); /* statement */ 
_transferEth(payable(msg.sender), etherRemaining);
        }else { c_0x359c53b5(0x1ffbd35cf44bc112bed5ee58515519fbb55c9a0f98c3b8234e81efd14ec78941); /* branch */ 
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
    ) internal {c_0x359c53b5(0x52d1aef14ff1a918d35ba831d28e3a1d495ed1488b79fab2d0d7781c55cd7b6f); /* function */ 

        // Cast already-modified offer memory region as spent items.
c_0x359c53b5(0xede67125269af5136edfe305e39e6ae9545f7284a4ed876f5dcc3c3e3ef1ffa0); /* line */ 
        c_0x359c53b5(0x5ae7ca92395c64194b6e2ec753ce596734268fa9d21d2b25c1e70a9f166600ab); /* statement */ 
SpentItem[] memory spentItems;
c_0x359c53b5(0x97fa8d4387562c6f493347b790de46a4243a6126ff6b676c53755b97e9c57d2b); /* line */ 
        assembly {
            spentItems := offer
        }

        // Cast already-modified consideration memory region as received items.
c_0x359c53b5(0x0fba530f9683f9bb19e6e1c83b0a9a2ee014f9675eafb562400af674d93c68c6); /* line */ 
        c_0x359c53b5(0x57a3fd62499b6334a98ab43513051ea1d4e672fe64cbdec9f856c62745aa8436); /* statement */ 
ReceivedItem[] memory receivedItems;
c_0x359c53b5(0x279ea8d3bf305ad2d29692342e19112f09953a29da9f5f609e5b55b9ebe1911b); /* line */ 
        assembly {
            receivedItems := consideration
        }

        // Emit an event signifying that the order has been fulfilled.
c_0x359c53b5(0xf23c46c3de52f177563cf481786e67a6667a340a297dd32937b33c24f05a508a); /* line */ 
        c_0x359c53b5(0xdcc5216377caeb05b79f8e6f60183110d09ea51bc7a6956dd77a56e14069cbb4); /* statement */ 
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
    {c_0x359c53b5(0xee2d8fb3abb2b8cded0a9b8b6b87f28c978d2633dc3e47d6c609f26f9f962833); /* function */ 

        // Convert to partial order (1/1 or full fill) and return new value.
c_0x359c53b5(0x44450c2709d87bf942ded39d7de4c47298418a107803406d7da62ec940fe2a85); /* line */ 
        c_0x359c53b5(0x4199272fe5432087dd8c007133840385e60f2db528e4530d788435c1860e5c73); /* statement */ 
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
    {c_0x359c53b5(0xcb61be3ba61d6b4413cb3d00d29edbf2bc63d377bd43e62f6245c4292808802e); /* function */ 

        // Read the number of orders from calldata and place on the stack.
c_0x359c53b5(0x70cfb5907ab7df06eaa1b64656925e5461d60c76d5bf7b231827155d07b0b5d4); /* line */ 
        c_0x359c53b5(0x180c8b24548700d0b739108237d83760eec57a3a1ea5499467398ba30d0f1bc5); /* statement */ 
uint256 totalOrders = orders.length;

        // Allocate new empty array for each partial order in memory.
c_0x359c53b5(0xdf026c440bccd756ea1e28d8c47abf73b186d7e164c96fd5adc6d2fc49853027); /* line */ 
        c_0x359c53b5(0x91acd7fbcd804f20feeed0ec6002790fe475e6f52afa7c6c738856ec5c7d8e5a); /* statement */ 
advancedOrders = new AdvancedOrder[](totalOrders);

        // Skip overflow check as the index for the loop starts at zero.
c_0x359c53b5(0xbbc1167a2d16e91f851f67c9fd50a2737858e1b936661b0ae52290de934f1137); /* line */ 
        unchecked {
            // Iterate over the given orders.
c_0x359c53b5(0xda1331f7dce98be2a282c86327fa96d27a4afa46cb90e134f06449ba9e0a7bbc); /* line */ 
            c_0x359c53b5(0x6ccc6047a8617c8aafafd635c2bcff6ca3786d81c9cf7021111adcdc5708b1b4); /* statement */ 
for (uint256 i = 0; i < totalOrders; ++i) {
                // Convert to partial order (1/1 or full fill) and update array.
c_0x359c53b5(0xddb26efe590122c6ea9e008205df15aa04c7d945e4dab951fc4a593945a0b784); /* line */ 
                c_0x359c53b5(0x7f33515a838832ff128a9ba7d7f0c1b324a054adc22fe8683d570fac59f6d748); /* statement */ 
advancedOrders[i] = _convertOrderToAdvanced(orders[i]);
            }
        }

        // Return the array of advanced orders.
c_0x359c53b5(0xdd359e5c7e6e562999a40a50a70ee20f82bc452897f8b5e015e0e4d0c3a6e3c8); /* line */ 
        c_0x359c53b5(0x7696b7de446e7818d621e22add8372ee22b0eb1995f0b3c53dd6d384df962c84); /* statement */ 
return advancedOrders;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0x1e922be1(bytes32 c__0x1e922be1) pure {}


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
function c_0x9395db55(bytes32 c__0x9395db55) internal pure {}

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
    ) internal view returns (uint256 amount) {c_0x9395db55(0x88e69a5e6fe38cabee1ee2b03841448dc4c6a841104d6b29835b0fd8de8ed07d); /* function */ 

        // Only modify end amount if it doesn't already equal start amount.
c_0x9395db55(0x0790835bb5c7cb2fe58a72a61152feadffa26079625b0dd02e0bd0c98421e423); /* line */ 
        c_0x9395db55(0xac3626710cec2b2d7b934c666e83afc13dcb8a096aa6a8dc61b4241cf8950f53); /* statement */ 
if (startAmount != endAmount) {c_0x9395db55(0xe1f17775ef0863e4fdbb3953604b29706bf9f498eee12824f805f3a518a610a9); /* branch */ 

            // Declare variables to derive in the subsequent unchecked scope.
c_0x9395db55(0x1378ecd9d238a19566cf0bb86b9029e203f8dedf46532d5d0380ba6312f6a209); /* line */ 
            c_0x9395db55(0xe65408230eac322081f20af29e341534ff2e45f6afa0b327493b22df4ec3f68a); /* statement */ 
uint256 duration;
c_0x9395db55(0xa665c9f3e9829e14f9830207ab700fd21562123e04f0a484a4469b4bbf6ca369); /* line */ 
            c_0x9395db55(0x45d2c3c789cb5a393ba439d6a91da1fa00b95d7a584c0d8fb65fd414bfe53201); /* statement */ 
uint256 elapsed;
c_0x9395db55(0x589af34b54217a27e8fb8049b519290e047810cb0e2b3f459296552120ff063e); /* line */ 
            c_0x9395db55(0x6813c3ad8773822c6074e7933c8638120f6ae10f4e298c0003d17abd029fd6ff); /* statement */ 
uint256 remaining;

            // Skip underflow checks as startTime <= block.timestamp < endTime.
c_0x9395db55(0xa6f06565e506d3c7964a5d6866b8c3e2c61a68798e4668d13ad455b5dd52ee7d); /* line */ 
            unchecked {
                // Derive the duration for the order and place it on the stack.
c_0x9395db55(0xba3039851096b36bf884769bc91cde26fa9f1a5f0a04748abc749a53257809b5); /* line */ 
                c_0x9395db55(0xf29990cd5c9d94cf50464bcca8d5916b05cdb710ddeecdfe17a1fde4ed698c82); /* statement */ 
duration = endTime - startTime;

                // Derive time elapsed since the order started & place on stack.
c_0x9395db55(0xb288f88e9029f166c3a54a523312f4db5798b50e97e0cd1ac81b0ecd1f096f27); /* line */ 
                c_0x9395db55(0x14c5d5691c7ef6a191a0b0cc68c73d5a4372b8892bfd79b361e9a48988865367); /* statement */ 
elapsed = block.timestamp - startTime;

                // Derive time remaining until order expires and place on stack.
c_0x9395db55(0x07341b7139e3b2643f13d4655d8e7dd1c5e1d46aea3115aabc4365eeac818917); /* line */ 
                c_0x9395db55(0x0855404eae5633b781996d9b1c86e171f5b27b88cf40eb7666befd39946f9148); /* statement */ 
remaining = duration - elapsed;
            }

            // Aggregate new amounts weighted by time with rounding factor.
c_0x9395db55(0x831c32238fd68686a5a7e4b1f64b995a38dbcc522ba99b3a8aca547a8a4136c3); /* line */ 
            c_0x9395db55(0xbdf6fb1cd1005aa02b532f85249216253631b8c66e8d88ac9a371495e967b0ea); /* statement */ 
uint256 totalBeforeDivision = ((startAmount * remaining) +
                (endAmount * elapsed));

            // Use assembly to combine operations and skip divide-by-zero check.
c_0x9395db55(0x82408503453874d5f82c93764b9e1153cb7aa5942ccdbba28486239070d82d29); /* line */ 
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
c_0x9395db55(0x0d48a5aa4742ed2a37b2a28e8750ce974d224b6094150cf4309675c239a88310); /* line */ 
            c_0x9395db55(0xc43e64f211fc8d1c5f14306e25192b1d40e98a709559e80a046ed595b7a32da2); /* statement */ 
return amount;
        }else { c_0x9395db55(0x3bad2b55b6e01295c347bfab584f16ecb2961a958027f22017f6559506c8db76); /* branch */ 
}

        // Return the original amount as startAmount == endAmount.
c_0x9395db55(0xe979d435b0711ef3a4bba65b75f59e4953536b00228b05f8b931c24c5badf153); /* line */ 
        c_0x9395db55(0x6ad510e26ee9aece42db1405b0bffb86e94962b609877b67b753250642f2aacc); /* statement */ 
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
    ) internal pure returns (uint256 newValue) {c_0x9395db55(0x4ee9bac752fd7961ee01c33dbc5da7c098073de9321debbbe6075e62570bcd06); /* function */ 

        // Return value early in cases where the fraction resolves to 1.
c_0x9395db55(0xe4d8b9cc2570e03e2599c36a841df80c68df7e0e4a9e5915fb67a77563c399a5); /* line */ 
        c_0x9395db55(0x4e2da594d286f7516e99d70ca97698344ad7647bc4d57ab322ece12b5e57b83c); /* statement */ 
if (numerator == denominator) {c_0x9395db55(0x155a17afd64f5c2b8e612d48d145e46a9233a7e211c5453722878026e62d3a5f); /* branch */ 

c_0x9395db55(0x23e2926a280030426a46de5c05184e1537f980a95b0a51459c89cba19dc3be56); /* line */ 
            c_0x9395db55(0x7f21a3f1ccf421da3ecc8adfa07201ecb0a7ba98673f55c43098e19281bfa613); /* statement */ 
return value;
        }else { c_0x9395db55(0x60d61d28b9c67505b7a8d485577ca015b7c0eb7f0598824658d03c9a4050a52a); /* branch */ 
}

        // Ensure fraction can be applied to the value with no remainder. Note
        // that the denominator cannot be zero.
c_0x9395db55(0x09511afebdf42b823c7f743ec17128622593363a86204d9fefa7a6705b21a5dc); /* line */ 
        assembly {
            // Ensure new value contains no remainder via mulmod operator.
            // Credit to @hrkrshnn + @axic for proposing this optimal solution.
            if mulmod(value, numerator, denominator) {
                mstore(0, InexactFraction_error_signature)
                revert(0, InexactFraction_error_len)
            }
        }

        // Multiply the numerator by the value and ensure no overflow occurs.
c_0x9395db55(0xbda6aecef11246c48cee2e2c99257a49bd6713dea1a44036cf5d9e87787155d7); /* line */ 
        c_0x9395db55(0x3e7d783a00ec3d01dec2295f617b16cbb17572c0bde6bc8206bff11202064f0b); /* statement */ 
uint256 valueTimesNumerator = value * numerator;

        // Divide and check for remainder. Note that denominator cannot be zero.
c_0x9395db55(0x3561ce723bf1bc94cd74ecda9e7b76486c15aea38bec152c2f3457e9d553d395); /* line */ 
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
    ) internal view returns (uint256 amount) {c_0x9395db55(0xb936a2d59c8d73c5d3117ad236f44b39047fd7de376b11cb26f4be456fd0694f); /* function */ 

        // If start amount equals end amount, apply fraction to end amount.
c_0x9395db55(0x26252ab7089936b074362213f8b7de785631f6db31559d2d0ace7a7115cb31af); /* line */ 
        c_0x9395db55(0x21b7b954463ae4b46a95d0e32445a0f8496086268f1be591cced671947044065); /* statement */ 
if (startAmount == endAmount) {c_0x9395db55(0x19e824d0e047499ba52bdee9ff88d521bacb143718e7033025aaba13a0cd0c79); /* branch */ 

            // Apply fraction to end amount.
c_0x9395db55(0x43acb6da38c92f0338c070e5fd674d9ae457e34cf05baece592b12e96b132c3f); /* line */ 
            c_0x9395db55(0x2ac57992cdbd93fac4e6f0f32494c156faf8e094689f0b0fee707716f46c2690); /* statement */ 
amount = _getFraction(numerator, denominator, endAmount);
        } else {c_0x9395db55(0x76c375e4745c1eb7c9cf21f788dab60b903ca3fa5e71d1c24c68dd28c88f0760); /* branch */ 

            // Otherwise, apply fraction to both and interpolated final amount.
c_0x9395db55(0x54b1b08fde901432336426578f92eb9d072047adff0120973ad51a254034c731); /* line */ 
            c_0x9395db55(0x2580fff519ab5e62a299fc93d34cc2425b7adf59ee62acc03b7f1ecf074b73ed); /* statement */ 
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
function c_0x152e536c(bytes32 c__0x152e536c) pure {}


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
function c_0x6c0749ad(bytes32 c__0x6c0749ad) pure {}


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
function c_0x3cecb806(bytes32 c__0x3cecb806) internal pure {}

    /**
     * @dev Derive and set hashes, reference chainId, and associated domain
     *      separator during deployment.
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     */
    constructor(address conduitController) OrderFulfiller(conduitController) {c_0x3cecb806(0x8f025a03805f5c8b53eeeb32cc1fd675de8c90c0b8656195594bb4a028c88bab); /* function */ 
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
    {c_0x3cecb806(0x53bdef3b32c60e6f43e78a80d3aaea414349d710b18fb5a46a0065513edc51f5); /* function */ 

        // Validate orders, apply amounts, & determine if they utilize conduits.
c_0x3cecb806(0x961dddf90c0325d2e8701248961f55822c51dbdbd20791e1a7a3d9a1be999da9); /* line */ 
        c_0x3cecb806(0x06df28fb373c1fd59f2262c194b76867ed4d330b4fe4611ed389fb5d70c24be3); /* statement */ 
_validateOrdersAndPrepareToFulfill(
            advancedOrders,
            criteriaResolvers,
            false, // Signifies that invalid orders should NOT revert.
            maximumFulfilled,
            recipient
        );

        // Aggregate used offer and consideration items and execute transfers.
c_0x3cecb806(0x7d65e84f857960d1e37312a8a4cfc739fd23f764e2d543e4694d1a59d9895a2a); /* line */ 
        c_0x3cecb806(0xea7b2f76543624596eb52ed306078fc589d005a11d85a6930ce8e601f6a09ee9); /* statement */ 
(availableOrders, executions) = _executeAvailableFulfillments(
            advancedOrders,
            offerFulfillments,
            considerationFulfillments,
            fulfillerConduitKey,
            recipient
        );

        // Return order fulfillment details and executions.
c_0x3cecb806(0x40c582a92a40ea31c33c52a8902dc409a11316177bf357f7fc5e3f7b287f9894); /* line */ 
        c_0x3cecb806(0x755bc99b7c005d065797bfd2808af032c8dd5541d8193856c00a719ef146e4d2); /* statement */ 
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
    ) internal {c_0x3cecb806(0x9674ba8f1dc244eb6f49517e7033b8da3c1941880f4f31505e63319d60d9bf94); /* function */ 

        // Ensure this function cannot be triggered during a reentrant call.
c_0x3cecb806(0x610daa513a5d61ddf3b468a98dca297843e702723ff5f0b5e8b26a57099c299d); /* line */ 
        c_0x3cecb806(0xe926e38d323147a2e1fd0d36a962350101a0492d9c50d4272855b02da7686301); /* statement */ 
_setReentrancyGuard();

        // Read length of orders array and place on the stack.
c_0x3cecb806(0xeccf85629d4e8cd26d4e6005fec4dc354fa24447fb9d2a3bfba470bb7fc07307); /* line */ 
        c_0x3cecb806(0xeffb72fa500b6b5e86dc7e57576b30ac4078aaaa960be57c5e27ff46aca22446); /* statement */ 
uint256 totalOrders = advancedOrders.length;

        // Track the order hash for each order being fulfilled.
c_0x3cecb806(0xe1c189a934c284dcd70ebe4e230df40a43d8c1a34bd667bcad7d3a1c9b25ebd9); /* line */ 
        c_0x3cecb806(0x5895931b9c130dd504c692b10a0988fd3e85ae0f1b31171b136e729a807c319a); /* statement */ 
bytes32[] memory orderHashes = new bytes32[](totalOrders);

        // Override orderHashes length to zero after memory has been allocated.
c_0x3cecb806(0x7dc6f8813458065242ebdc76081557e5313bac21439802e375c8d6bb365f8678); /* line */ 
        assembly {
            mstore(orderHashes, 0)
        }

        // Declare an error buffer indicating status of any native offer items.
        // {00} == 0 => In a match function, no native offer items: allow.
        // {01} == 1 => In a match function, some native offer items: allow.
        // {10} == 2 => Not in a match function, no native offer items: allow.
        // {11} == 3 => Not in a match function, some native offer items: THROW.
c_0x3cecb806(0x6ef6be131c2d3754030d585d3a1dfe1b5d2f9c5cb41980765b8681ac082556cd); /* line */ 
        c_0x3cecb806(0x8cb97d881230e45c2a1243a434143c4c7a900d953a069777a5ac79bab5df6143); /* statement */ 
uint256 invalidNativeOfferItemErrorBuffer;

        // Use assembly to set the value for the second bit of the error buffer.
c_0x3cecb806(0xc140a24ef9915a28d263028fcc02c8c5697d17ad079f47893b558f75abc04cab); /* line */ 
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
c_0x3cecb806(0xfa3d2b797f8e8c172f01f1f9656bd754762d6d51500dab6cd3fe98bfb1d8891d); /* line */ 
        unchecked {
            // Iterate over each order.
c_0x3cecb806(0xf80da04ce2e121ba93bf7d4ced3cac788537ff8b5f03961f852bb68c7f7fe218); /* line */ 
            c_0x3cecb806(0x961f437bb2278d54a2d794e6b6ba95174d0ada5cf5b054df5fd0dc44cc981861); /* statement */ 
for (uint256 i = 0; i < totalOrders; ++i) {
                // Retrieve the current order.
c_0x3cecb806(0x9c82daeb0002112bc9602d2f23a769b03a19326cc95a43ed838185ec1d284e46); /* line */ 
                c_0x3cecb806(0x89d05b0691b35db6d36a36ebcff40f7e8caa13dff868edf47675bb61281f3170); /* statement */ 
AdvancedOrder memory advancedOrder = advancedOrders[i];

                // Determine if max number orders have already been fulfilled.
c_0x3cecb806(0x3128a67934229e35d583091cc11d257ccf3dc6b6ae9a8de85071765f154856d3); /* line */ 
                c_0x3cecb806(0x53be4b987f804919009b34d9d2364100dfc35a6d46fa5a7800719ebc221b77ac); /* statement */ 
if (maximumFulfilled == 0) {c_0x3cecb806(0xe342694ecb4dc8be32d72eba1fc6ebd1a3f0e838605949fbcf3b74bade96b60b); /* branch */ 

                    // Mark fill fraction as zero as the order will not be used.
c_0x3cecb806(0x7e95f8f3011591348c5b94e95315b17c81c1db8ff2c11993b0a4cd9778b25742); /* line */ 
                    c_0x3cecb806(0x65e85cd5cede0b62621471146459281c0d33d58a98e2fd04f688837c2a11acc2); /* statement */ 
advancedOrder.numerator = 0;

                    // Update the length of the orderHashes array.
c_0x3cecb806(0xde49c263df88d213d4a5eff258765763ad7a80e52fc2f73eaa1af8778ba8be25); /* line */ 
                    assembly {
                        mstore(orderHashes, add(i, 1))
                    }

                    // Continue iterating through the remaining orders.
c_0x3cecb806(0x29f68a75b28bfdf0b4ad7e59459a87bc37f5a2b0f970893b9777a0bad83f8f2b); /* line */ 
                    continue;
                }else { c_0x3cecb806(0x39984c178a6f41231116de2fd3b90ca314cbec58d002db3accc96d16f2d5b214); /* branch */ 
}

                // Validate it, update status, and determine fraction to fill.
c_0x3cecb806(0x355d121ed1c1b65fe5c1bcc73c676e7d2abbb8d54e861b2810307be7f3316617); /* line */ 
                c_0x3cecb806(0x009c5859f524e3178e113c63ba4138f51cc2e98c069de9853faf036dd52c954a); /* statement */ 
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
c_0x3cecb806(0x7244b0a619a75943c6f7305cd34e7b2232bb3026990efddb316146e28feb6e53); /* line */ 
                assembly {
                    mstore(orderHashes, add(i, 1))
                }

                // Do not track hash or adjust prices if order is not fulfilled.
c_0x3cecb806(0x2426efb9c27e7607a53f49760694ba097590c7551731333cb17f00d7acdf9ad1); /* line */ 
                c_0x3cecb806(0x26d2d953347d666eff1c3a6228f879ca5275f02481933969a63b7a559ac29355); /* statement */ 
if (numerator == 0) {c_0x3cecb806(0x679d486af451480f2d9d6e133cb3f6c984ab09679fd10bf9eae5333a51cdac07); /* branch */ 

                    // Mark fill fraction as zero if the order is not fulfilled.
c_0x3cecb806(0xc0accff82e17460c475c01075e12311b1d72ff0d9b453578d0dc2ec8ec4bbcdd); /* line */ 
                    c_0x3cecb806(0x54a09737611bc5e144a6da2dc3461fbe18cbd975f28440cd5c0ec6d5ee484d66); /* statement */ 
advancedOrder.numerator = 0;

                    // Continue iterating through the remaining orders.
c_0x3cecb806(0x9d3a45a9f313beb59581f63f61d13f72bdb39cf150536b3d30919f0b46836db7); /* line */ 
                    continue;
                }else { c_0x3cecb806(0xcede5237edef0ad44db264be665ba73d5b9426dde02abbea6871ec376fe5a024); /* branch */ 
}

                // Otherwise, track the order hash in question.
c_0x3cecb806(0xe598cc8b91dd47d3929c00a047c34eb0444ddc9a55377d18cc9fd444eec2cf3b); /* line */ 
                c_0x3cecb806(0xcbab6746e6f4a3b4c10de07e6d48c0120f2df6917c05bbe8a11c03c63e91c182); /* statement */ 
orderHashes[i] = orderHash;

                // Decrement the number of fulfilled orders.
                // Skip underflow check as the condition before
                // implies that maximumFulfilled > 0.
c_0x3cecb806(0x7bdd6794afb756e0a0c0e11509594118ae35a8fd0717ce9e61458eaeb04c9d6d); /* line */ 
                maximumFulfilled--;

                // Place the start time for the order on the stack.
c_0x3cecb806(0x8cbdba3d5dd561677c3d49f7153374af1466676c81cd86c5d258695426815a08); /* line */ 
                c_0x3cecb806(0x16c64f1dbbc2ffb3452a910a4307232c1771a05f87836bbf5195159124108089); /* statement */ 
uint256 startTime = advancedOrder.parameters.startTime;

                // Place the end time for the order on the stack.
c_0x3cecb806(0x3d25b5554c49943809bfbdf9aa23e743777b801bd5f163e66cba072d3c04fec8); /* line */ 
                c_0x3cecb806(0x18800524f01b215e48fe449aa2ba38b885eea0bd9881c40a3152bcb36d7e50e9); /* statement */ 
uint256 endTime = advancedOrder.parameters.endTime;

                // Retrieve array of offer items for the order in question.
c_0x3cecb806(0xb861f17cfa0989f9d844477ca7cec573e07709685cce192b1492b6774f92cd6c); /* line */ 
                c_0x3cecb806(0xabd878b705f4708b23e51bc6a0182880ad2a5ce1e46047154331b4714eec3ebc); /* statement */ 
OfferItem[] memory offer = advancedOrder.parameters.offer;

                // Read length of offer array and place on the stack.
c_0x3cecb806(0xed66bef4168384049cd4b229e408c3b2cbc9cbd49ab448128baaa23ad1d70ba9); /* line */ 
                c_0x3cecb806(0xb8efa6df8a0c79143aa31558867fe175beebbe0566110a1f3b3b28ebc0d309f4); /* statement */ 
uint256 totalOfferItems = offer.length;

                // Iterate over each offer item on the order.
c_0x3cecb806(0x82b1d3fb208034086f066a58f94b37c0aaeb67a7ad7da8922390b49106957bbd); /* line */ 
                c_0x3cecb806(0x75a772ff7a565be0af9d8bd25f05a2e8a2ee5b6696877d631276af642619e269); /* statement */ 
for (uint256 j = 0; j < totalOfferItems; ++j) {
                    // Retrieve the offer item.
c_0x3cecb806(0xb7efc525ce9ec00caf6762aff545f589bd36acdf07c01aa5830fed8828bf8280); /* line */ 
                    c_0x3cecb806(0x664340ac1f522b35a1b2b551937ce06fcff848f502158ca305645e8702d6da0e); /* statement */ 
OfferItem memory offerItem = offer[j];

c_0x3cecb806(0x4c8f7ad8a4b0f949571b4f14a9bd8a8c4abcb54fbc616feaded557010a0b30ca); /* line */ 
                    assembly {
                        // If the offer item is for the native token, set the
                        // first bit of the error buffer to true.
                        invalidNativeOfferItemErrorBuffer := or(
                            invalidNativeOfferItemErrorBuffer,
                            iszero(mload(offerItem))
                        )
                    }

                    // Apply order fill fraction to offer item end amount.
c_0x3cecb806(0xb83609b141036944acb500127deaf3cfc968caeabeb29d971268621fb9493990); /* line */ 
                    c_0x3cecb806(0x99ee89a9ccc3b916c9eba961e115833055f9363e43a9931560902f4d33a6d28b); /* statement */ 
uint256 endAmount = _getFraction(
                        numerator,
                        denominator,
                        offerItem.endAmount
                    );

                    // Reuse same fraction if start and end amounts are equal.
c_0x3cecb806(0xfefd38cf6b677d5fcabeca7bcd572b5d61e7fd1e5ee4d11f99308a29187d5b83); /* line */ 
                    c_0x3cecb806(0x6f4ce50ebc0b917bca8df0138a002457646928e36822b650a8d8e1070a4a0cc4); /* statement */ 
if (offerItem.startAmount == offerItem.endAmount) {c_0x3cecb806(0x41141971463a8ca01836bf0669c6a06969302e6f441bd8e6fa9df9e255aad44f); /* branch */ 

                        // Apply derived amount to both start and end amount.
c_0x3cecb806(0x1c452cc830dce7ab29d78666418016cc57af92d0ccd3f5f84a246ac7958411c9); /* line */ 
                        c_0x3cecb806(0xd9d58a5fe444aeba0e90777e744409081e9a459321bdff7cde65f98f912aebb9); /* statement */ 
offerItem.startAmount = endAmount;
                    } else {c_0x3cecb806(0x0913bd186609505b28345024bdfc839d8fafe6d5ee3b5c061bf0d72503c28ada); /* branch */ 

                        // Apply order fill fraction to offer item start amount.
c_0x3cecb806(0x2b1e0099222dd0bd7e8e96b6ab47f83a86097ab681aa29dbe07ee09abf625e31); /* line */ 
                        c_0x3cecb806(0xb58eded775b14a83f5f25c2600e57db96347bf661223ab2e1c78528e6e4cae55); /* statement */ 
offerItem.startAmount = _getFraction(
                            numerator,
                            denominator,
                            offerItem.startAmount
                        );
                    }

                    // Update end amount in memory to match the derived amount.
c_0x3cecb806(0xbdbb0877dd9e63e0a1cf7c2e45956a7cec0761726b557c5500ae4aa41e8e736b); /* line */ 
                    c_0x3cecb806(0x7541604d7be4aef6bfa961d3a474e3ac85e249f2d7cf6e51c5f1f46e7625c52e); /* statement */ 
offerItem.endAmount = endAmount;

                    // Adjust offer amount using current time; round down.
c_0x3cecb806(0x5fc78d4114e012d75e6554b491962e4f2d0df821d6e620961ebb341111121359); /* line */ 
                    c_0x3cecb806(0x860ad673e5e6633ab70b7d2065575ccefc5e9cf36ff6e845f2c95131c683f624); /* statement */ 
offerItem.startAmount = _locateCurrentAmount(
                        offerItem.startAmount,
                        offerItem.endAmount,
                        startTime,
                        endTime,
                        false // round down
                    );
                }

                // Retrieve array of consideration items for order in question.
c_0x3cecb806(0x68ea0529e1e157ce995151ce92f12f3538cd986f8cfcca4fbb80ad7ecdada846); /* line */ 
                c_0x3cecb806(0xff5a4406402187f2e874b78dacee81c1996f901fc0d044dad18c09012987e93a); /* statement */ 
ConsiderationItem[] memory consideration = (
                    advancedOrder.parameters.consideration
                );

                // Read length of consideration array and place on the stack.
c_0x3cecb806(0x4998a1f2296391b2dbad8e47a27093030c8425c2d104ee83bc1827d862775a30); /* line */ 
                c_0x3cecb806(0x848a31bdbe898769d0c45a4318bb667e25bb13afd578c61ecc07b6edb9c7f89a); /* statement */ 
uint256 totalConsiderationItems = consideration.length;

                // Iterate over each consideration item on the order.
c_0x3cecb806(0xaaa50f926cb40568d9c8917ccce1857470b5f960c2561559b68b02ee47fc0d77); /* line */ 
                c_0x3cecb806(0xa7e1b093faa5d02b81ff8dbbccd37cb747a8b66e4e5fab014e23f94a0733efb5); /* statement */ 
for (uint256 j = 0; j < totalConsiderationItems; ++j) {
                    // Retrieve the consideration item.
c_0x3cecb806(0x400d63fb5a9137322b4de3540f41d8bda1a96808ce431572130adfd8a3ee9de5); /* line */ 
                    c_0x3cecb806(0x280de3ebbaf703923ec13a88ee1c691161eb2c15b2f8ee78ecaee5b30c930dc1); /* statement */ 
ConsiderationItem memory considerationItem = (
                        consideration[j]
                    );

                    // Apply fraction to consideration item end amount.
c_0x3cecb806(0x0be29d7688acb500707a63ec6bb8589b089c5fbd03ea3366006d8159a3c18c74); /* line */ 
                    c_0x3cecb806(0x78ca3c0885788c1901843b39189e5f3679b369333c1a39691e0de283b7a36451); /* statement */ 
uint256 endAmount = _getFraction(
                        numerator,
                        denominator,
                        considerationItem.endAmount
                    );

                    // Reuse same fraction if start and end amounts are equal.
c_0x3cecb806(0xce3fa651621f450eda64575152f6161b7e8c145c4ff815c5bc979bce6061410c); /* line */ 
                    c_0x3cecb806(0x424563fd25c52ff40d28441c38cd8150dd7bc91a6beff5f86e8fa0b5c530735e); /* statement */ 
if (
                        considerationItem.startAmount ==
                        considerationItem.endAmount
                    ) {c_0x3cecb806(0xe97c02de9a048bcd84ccee92f938d18dafcffaef0bc4f968679e2d1174ff54c1); /* branch */ 

                        // Apply derived amount to both start and end amount.
c_0x3cecb806(0x05b7af3af2e4dffc20af5b2b746c6e32c9a0662bd6c3f7202ae3995619521d03); /* line */ 
                        c_0x3cecb806(0x58ca34e3f21ae2a342d084ff2061e77e94ce6734e8526f6513312d47c005c4bc); /* statement */ 
considerationItem.startAmount = endAmount;
                    } else {c_0x3cecb806(0x924d323c72dfcaad17df79f93708cf098a27e3889f8304810224a181ab8b00a1); /* branch */ 

                        // Apply fraction to consideration item start amount.
c_0x3cecb806(0x65cecd217dccdc8d835a9d0b9e7780e765e27432048f591184838e73541d4db6); /* line */ 
                        c_0x3cecb806(0xce58e6083c2c5f11141c0d6175195b000d48f681ecc02a3d74e12793a42ed0f7); /* statement */ 
considerationItem.startAmount = _getFraction(
                            numerator,
                            denominator,
                            considerationItem.startAmount
                        );
                    }

                    // Update end amount in memory to match the derived amount.
c_0x3cecb806(0xc0bbd10eea0affea43a797b128ec2e72b0f2301745f6da570265bc1ca9c7e097); /* line */ 
                    c_0x3cecb806(0x4cb34712438e0c6f4df803d4989093ab4165c7e09c2141d2febdb59bd9d4d9c5); /* statement */ 
considerationItem.endAmount = endAmount;

                    // Adjust consideration amount using current time; round up.
c_0x3cecb806(0xf52eee0d8c7b1c1d1af2572dc4e09788bf19f793305281f22e8245b3d7a81f18); /* line */ 
                    c_0x3cecb806(0xbe743dedabdce63be63928afb29f9c3ad53e7ef79e897cbc8c233ea43221f001); /* statement */ 
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
c_0x3cecb806(0x45d588ecdf33c739ecca3e429d38b561c9da70fd07f8263c15e4bab743666699); /* line */ 
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
c_0x3cecb806(0x7dd330cb099e7963218adda89987278be8adce88d48110f36c30af944aa1897a); /* line */ 
        c_0x3cecb806(0xa77f4a38db7592d071d65f77a0cd339dee7a0a4bd6a01ee6c18b21f53899524f); /* statement */ 
if (invalidNativeOfferItemErrorBuffer == 3) {c_0x3cecb806(0xf32d5c2b49c827319ec39a5ab2341aae42835637d01acc724ae1329d8eddff92); /* branch */ 

c_0x3cecb806(0x274aa000ff33a19e3d2203b7b2fc020b8dac24d9e50f7858a567dabb874025fd); /* line */ 
            revert InvalidNativeOfferItem();
        }else { c_0x3cecb806(0xe580839baf8992d230ac9daae2f4e2a12df6d0650de91120bd107786b8f621c5); /* branch */ 
}

        // Apply criteria resolvers to each order as applicable.
c_0x3cecb806(0x122c673b423886f3fa5e7de7478fdfc18d63e68a061c69ff6cd7cab2aa9d3cef); /* line */ 
        c_0x3cecb806(0x092b30940eb3d526a18636c16b06d350e81dea56ebb4609517abfd4fe073d801); /* statement */ 
_applyCriteriaResolvers(advancedOrders, criteriaResolvers);

        // Emit an event for each order signifying that it has been fulfilled.
        // Skip overflow checks as all for loops are indexed starting at zero.
c_0x3cecb806(0x26cae3ff7addf91f4f0663b6e9236929c7df82cda68ef080feb89c5492e95561); /* line */ 
        unchecked {
            // Iterate over each order.
c_0x3cecb806(0x398c2f6527b379f50a7fb4d444e93edbef553f9197ae4be6d4547f065a87a807); /* line */ 
            c_0x3cecb806(0xa04e2ec705fb9111e50a678cc4d706a52b5357c0996bafca7c554cb2f1a8d6d0); /* statement */ 
for (uint256 i = 0; i < totalOrders; ++i) {
                // Do not emit an event if no order hash is present.
c_0x3cecb806(0xf7e847d1f001cbf7d3847ce767f270559746bab77877ce2d4074e01c732a8f6c); /* line */ 
                c_0x3cecb806(0xc31a65799df3fd8eb47bcd58e3234330516158af0f236cfa6133b1a716639ed0); /* statement */ 
if (orderHashes[i] == bytes32(0)) {c_0x3cecb806(0xc22ed8ab1163ef597aa927e30301731d2f9c1e34b3def5c4eb33b935e1246577); /* branch */ 

c_0x3cecb806(0x47a04be47d85702b8f2d8417e6d27cc688524f2f2bda1c306fcf14017c9bc087); /* line */ 
                    continue;
                }else { c_0x3cecb806(0x5587eeb2eabc7587a70df6796374f5a952460582690121562f3e61eea78eaec3); /* branch */ 
}

                // Retrieve parameters for the order in question.
c_0x3cecb806(0xf061c61be05f493ffa34256e3604c175d237a64c3c849e1d6402716f39dd15ac); /* line */ 
                c_0x3cecb806(0x415851dc971b76dc207fe3ada41cad885cd8ab743022912fdd5dc3c0de8608d3); /* statement */ 
OrderParameters memory orderParameters = (
                    advancedOrders[i].parameters
                );

                // Emit an OrderFulfilled event.
c_0x3cecb806(0x04df077896a7c47f383b1871b78b3ddf14a02f23748599158db8ad1d258486b2); /* line */ 
                c_0x3cecb806(0xae9b5df1c464624452f50d60992ccd890fde19dc0ee5d37886b8eca0e88839b2); /* statement */ 
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
    {c_0x3cecb806(0xe5fd1008c33cc765ee5f8490cbb16aa0e9ce0d001721fa39a7c47a6f344a2481); /* function */ 

        // Retrieve length of offer fulfillments array and place on the stack.
c_0x3cecb806(0x1a7178d9db8ba9d96f47ffa20af9197b3cba0f6d3ae648ff5452ce82e938acae); /* line */ 
        c_0x3cecb806(0x70ee0d69dbabe61ab1ce658c18fb3dc017ef717a8e74d55cdc73b1202f9c1d6b); /* statement */ 
uint256 totalOfferFulfillments = offerFulfillments.length;

        // Retrieve length of consideration fulfillments array & place on stack.
c_0x3cecb806(0x95dd94a3fd02150a40ad89b5965bdebaeb871f16e8f8cf9bb3e6f0ae444306d7); /* line */ 
        c_0x3cecb806(0xd6a0d5a898482df8032dfffef7238ef9ea410c696c0b3c22006a535c4152862d); /* statement */ 
uint256 totalConsiderationFulfillments = (
            considerationFulfillments.length
        );

        // Allocate an execution for each offer and consideration fulfillment.
c_0x3cecb806(0x0c8595c8666a7af55d226806863a1e64508410df068f3488ce4ce248424c8aa8); /* line */ 
        c_0x3cecb806(0xfc0ca2a2283130031f1b12d517e1e1ebed3006c6ad88f7b1dbaec0d5bf687e38); /* statement */ 
executions = new Execution[](
            totalOfferFulfillments + totalConsiderationFulfillments
        );

        // Skip overflow checks as all for loops are indexed starting at zero.
c_0x3cecb806(0x00d4e3f397c02b939303b550d16545544e5d905092e9d65d15cad277a304e0f5); /* line */ 
        unchecked {
            // Track number of filtered executions.
c_0x3cecb806(0xbb280fe5a80c1b0adb61c2b3b1830aacc49129ab52442b13c1e0dc78d802639a); /* line */ 
            c_0x3cecb806(0xb2442ceed0ef0d6e30b92c882d9e45cdbba7e6fe8e870ba29f65b2811a841a79); /* statement */ 
uint256 totalFilteredExecutions = 0;

            // Iterate over each offer fulfillment.
c_0x3cecb806(0x538f3367800c682747e2c81f368b881afceee5e02c6cd1ca91746c4166eb11f0); /* line */ 
            c_0x3cecb806(0xc88a15d9c1df1fa2b0b1cf56c2bfe51fba385b4e9629520a52fa450d253119c8); /* statement */ 
for (uint256 i = 0; i < totalOfferFulfillments; ++i) {
                /// Retrieve the offer fulfillment components in question.
c_0x3cecb806(0x2c67ba12466b5ce59d6bedaf710dd0d43928b388839f73f42ad12939bcf0ba59); /* line */ 
                c_0x3cecb806(0x803b7fb4450f63b5d6ed578d5c88483656d0b3cfd0fba9c71493a3a602965992); /* statement */ 
FulfillmentComponent[] memory components = (
                    offerFulfillments[i]
                );

                // Derive aggregated execution corresponding with fulfillment.
c_0x3cecb806(0xd62b98b2d422ec5aba2e142705b7c324cb89556fbf2e0efb7ff5cb6e7c729904); /* line */ 
                c_0x3cecb806(0xb60411483c663a25373e244a4dd7168ebbe2c8acbc8f634804727407df84494c); /* statement */ 
Execution memory execution = _aggregateAvailable(
                    advancedOrders,
                    Side.OFFER,
                    components,
                    fulfillerConduitKey,
                    recipient
                );

                // If offerer and recipient on the execution are the same...
c_0x3cecb806(0x549e3ff2d438eaff0d54f6fcb4619084dcfc447bf882eb630ca7b1e70ebf9bcc); /* line */ 
                c_0x3cecb806(0x8e78f71ede68a58579d6cb48f3065e3f96458c56b9f72af995cab31f5a3ca751); /* statement */ 
if (execution.item.recipient == execution.offerer) {c_0x3cecb806(0xbe666af2e5986f9d56185b3fdee9aa7e57272a98cdde3806425ccba32d787bdf); /* branch */ 

                    // Increment total filtered executions.
c_0x3cecb806(0x809df33e800974b909da72b6dffe9af6517b0fa98311a132aa87f27cebc8c87f); /* line */ 
                    ++totalFilteredExecutions;
                } else {c_0x3cecb806(0xe5ec8595057a166757ad9eb9a5c6a52ba1a317b91806236bc184ca8a694bc022); /* branch */ 

                    // Otherwise, assign the execution to the executions array.
c_0x3cecb806(0xfe168d6255ae370de23cd4c35fe0c6917053ea3ed7ddd81d293e34d1a62eb0cf); /* line */ 
                    c_0x3cecb806(0x3631759482b81a13cc10796ed646e5beae0b272419d94347d29a00ee1bc40901); /* statement */ 
executions[i - totalFilteredExecutions] = execution;
                }
            }

            // Iterate over each consideration fulfillment.
c_0x3cecb806(0xf8a90e991953c194f4beb1dc6d7c67c88f000b249b2810538abda767500aefbd); /* line */ 
            c_0x3cecb806(0x5d5d18707eb7bddd4c6a650a6f406c6dd4743dbb91974f07f98ef41fe78ea946); /* statement */ 
for (uint256 i = 0; i < totalConsiderationFulfillments; ++i) {
                /// Retrieve consideration fulfillment components in question.
c_0x3cecb806(0x84019689ed149f01901e5d6b8b9d6989a30c46f802295a3f9bfbb969bcbc880a); /* line */ 
                c_0x3cecb806(0xcf5a05e5fefde677f580ada85fa82f2d7f6f67c6308ae7084d29f18795346351); /* statement */ 
FulfillmentComponent[] memory components = (
                    considerationFulfillments[i]
                );

                // Derive aggregated execution corresponding with fulfillment.
c_0x3cecb806(0x26645084395a6bdd4d1dcd409da3ac37e70bffa2c7e309b424179c83ac28192f); /* line */ 
                c_0x3cecb806(0x08d4af32f95201b08c20c0c11ef6d8bfe3142ffba46b34b5ff14be86243d2594); /* statement */ 
Execution memory execution = _aggregateAvailable(
                    advancedOrders,
                    Side.CONSIDERATION,
                    components,
                    fulfillerConduitKey,
                    address(0) // unused
                );

                // If offerer and recipient on the execution are the same...
c_0x3cecb806(0x36368ea3edb3d363f9eab5e60495b569df6c1e2dd2fb572676b1e2574a91a92e); /* line */ 
                c_0x3cecb806(0x6769ae4871af16dd219d9c102a469ab04e3e387122727664aaed19dfa9297178); /* statement */ 
if (execution.item.recipient == execution.offerer) {c_0x3cecb806(0x35890104f16454345e001cf6f09d79a02154c17f00d935499e12577a50df5e64); /* branch */ 

                    // Increment total filtered executions.
c_0x3cecb806(0xa8c745ae9261903d3a53869fe09ffcdb181a0df3079e642e06dcf4c7251ed33e); /* line */ 
                    ++totalFilteredExecutions;
                } else {c_0x3cecb806(0xd3d66143c3ff2a2f63894efeceec8e4d6f1c988945ad10b4dd1b02cbcd958c6d); /* branch */ 

                    // Otherwise, assign the execution to the executions array.
c_0x3cecb806(0x26986e6ae69fecbc7616cb7aa03ceee8be51d5c5e2c3f2909b9dd79ece46d564); /* line */ 
                    c_0x3cecb806(0xfdbdd9ccaf8a668efb92286d368ce0db9915e6113aabc7c244e3bb67d7f64589); /* statement */ 
executions[
                        i + totalOfferFulfillments - totalFilteredExecutions
                    ] = execution;
                }
            }

            // If some number of executions have been filtered...
c_0x3cecb806(0xdc969a5f8dac84ce2f684f8b0f513ffbe5e374890ec37793f1c5a6115c1448ac); /* line */ 
            c_0x3cecb806(0x203553203ba02834be68a69c44df237b2035141a9464698ae8afdb06519695a9); /* statement */ 
if (totalFilteredExecutions != 0) {c_0x3cecb806(0x06779ccb259540b0e3b4a81e8af70eb441a9d5385007dffa8e47ac68e74c497c); /* branch */ 

                // reduce the total length of the executions array.
c_0x3cecb806(0xc04f6bae49f8fe4d0cb0c75cf2f0effda680ffd3f15bf61ab1c0ef1f04940346); /* line */ 
                assembly {
                    mstore(
                        executions,
                        sub(mload(executions), totalFilteredExecutions)
                    )
                }
            }else { c_0x3cecb806(0xb048fcca3b7289ca97abc5f4f23d470510170db25c78068776177215b7bcc4cb); /* branch */ 
}
        }

        // Revert if no orders are available.
c_0x3cecb806(0xb108ddc6e43f7ec937de348654201903d082ddcb3816235562a42d285d884de4); /* line */ 
        c_0x3cecb806(0xcb99498cfe2edae283be0d716258820adfdea49246647838e99ba1c991390b01); /* statement */ 
if (executions.length == 0) {c_0x3cecb806(0xf482e65139d8ce48c014d94f7d346b58b16e6278885fe36ae93fddb1214ba373); /* branch */ 

c_0x3cecb806(0x15dcef4fcc7559a7afbce6b9f7ede376a4331cefa76b4054217b23e82f87fca8); /* line */ 
            revert NoSpecifiedOrdersAvailable();
        }else { c_0x3cecb806(0xdbe30571a746b107312d2f08e72e78038730f216b85cf026da0c24a56c036d6a); /* branch */ 
}

        // Perform final checks and return.
c_0x3cecb806(0xa38427638414fd5b1ca7329e334e1b940555227fc6e31d3770f564729b3aa313); /* line */ 
        c_0x3cecb806(0xd893be05a0260863499f0318038ede311747a688f42e5ae83be5ef4763c3b6c8); /* statement */ 
availableOrders = _performFinalChecksAndExecuteOrders(
            advancedOrders,
            executions
        );

c_0x3cecb806(0x16b2797017e81100615921191c1501f5b65b5975d0f79f9cd5382b0a0d240fc7); /* line */ 
        c_0x3cecb806(0xb6676baaff3efa3a5955c33251538c1b92fa3dacd5961d76a2ca548d1b3a8435); /* statement */ 
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
    ) internal returns (bool[] memory availableOrders) {c_0x3cecb806(0xb0535e9857ddb21290f34a80f4b574084477a45041bf923a6adb755cf067329e); /* function */ 

        // Retrieve the length of the advanced orders array and place on stack.
c_0x3cecb806(0x9472e98604610c7bb6e445b68ed53255d20ed8e05bfbdff110a5656d6722890a); /* line */ 
        c_0x3cecb806(0xfd9e69d789aab2cc69e9fb3212119b955786086b931d3c1d6676b379c96c24fa); /* statement */ 
uint256 totalOrders = advancedOrders.length;

        // Initialize array for tracking available orders.
c_0x3cecb806(0x9cc637ce1dfabf0fa4f5c7eabf80158c0b54ff6aceed1b8048e82bb7e278dc64); /* line */ 
        c_0x3cecb806(0x9234376c2c5a55e5e55c9451d428521f40526cc1c393384982757722cef88150); /* statement */ 
availableOrders = new bool[](totalOrders);

        // Skip overflow checks as all for loops are indexed starting at zero.
c_0x3cecb806(0xe41ae1a394435f2b2dd044a587f0110facc3e6e4eb012b4af4b0b25b614ddc59); /* line */ 
        unchecked {
            // Iterate over orders to ensure all considerations are met.
c_0x3cecb806(0x2c60088a16ac5737b5f4db5ac44d34c98a510f309d7abbc5623d86e685783e7a); /* line */ 
            c_0x3cecb806(0x732fafb0379414f95c6ed1257a16ca7b60947a570795c68739711f5dab4211dd); /* statement */ 
for (uint256 i = 0; i < totalOrders; ++i) {
                // Retrieve the order in question.
c_0x3cecb806(0x37e02af0e6b1d9c1d13a06a1c8c832325ae96fd1eb81f5f5748bc664b4f3694d); /* line */ 
                c_0x3cecb806(0xc86f9e0dfab6f9cc021b53b8185a9beeaf5e577b8c5c69a59580e3776805e7e6); /* statement */ 
AdvancedOrder memory advancedOrder = advancedOrders[i];

                // Skip consideration item checks for order if not fulfilled.
c_0x3cecb806(0x2581e8952b13f356cad4cf6c68038b28ea3e52ade04fa36aa92a2488d773c4f7); /* line */ 
                c_0x3cecb806(0x3fc9a947bafdc00a1867182de81b3e20ed269c5433ad8e8011d8d39b94ed8308); /* statement */ 
if (advancedOrder.numerator == 0) {c_0x3cecb806(0x7181ddfedc6cf91fb7edaf836b37c2c27c056e216e07864adbd4e7df74a2f13f); /* branch */ 

                    // Note: orders do not need to be marked as unavailable as a
                    // new memory region has been allocated. Review carefully if
                    // altering compiler version or managing memory manually.
c_0x3cecb806(0xbdf4965573a17b694917edf2e78926955af4f6df72533c905eb92fe95b3689a9); /* line */ 
                    continue;
                }else { c_0x3cecb806(0x1a9f1c759450113a1ee353bd08b57e9e5788900496ee508e7cfa51e359170488); /* branch */ 
}

                // Mark the order as available.
c_0x3cecb806(0x12bd595e031d9b1483ad2c05ed4e256672cdb9f6af4b71428c48f09f460565e7); /* line */ 
                c_0x3cecb806(0x670b766b761489685888fcfd5025a5aa7a8c6ddb1a109102afe4a372325df30d); /* statement */ 
availableOrders[i] = true;

                // Retrieve consideration items to ensure they are fulfilled.
c_0x3cecb806(0x7abb08d94f1341191521255ba268b96be5dc7980b8e0b516eb330693035d8cdd); /* line */ 
                c_0x3cecb806(0x6c1dfa5368b23c7e7401d2b7ec35f11471aa09427b4d91ecdf464da1cdd22f49); /* statement */ 
ConsiderationItem[] memory consideration = (
                    advancedOrder.parameters.consideration
                );

                // Read length of consideration array and place on the stack.
c_0x3cecb806(0x9313eb37eef3b2d3095ef27ef8daedb42f417369551763d4fecf1e4fd72d29c1); /* line */ 
                c_0x3cecb806(0x6376fba4f318fdd2cc171031d3370d4b86a9e0483e768d0fea38b6f5baa3b9c1); /* statement */ 
uint256 totalConsiderationItems = consideration.length;

                // Iterate over each consideration item to ensure it is met.
c_0x3cecb806(0xb166d08a369204cb457da3123490728b31d9aa2ced2bdc67286a0b48096c04cc); /* line */ 
                c_0x3cecb806(0x66d0a3542dfecb0503cc0f172532bb3b54bad3702ba5893612bf8f4571142338); /* statement */ 
for (uint256 j = 0; j < totalConsiderationItems; ++j) {
                    // Retrieve remaining amount on the consideration item.
c_0x3cecb806(0xfc8492345e43ed742339f6d13fac3148f92681c95fbaf12b15d2087ff86473df); /* line */ 
                    c_0x3cecb806(0x8a3c55d312d57988a75b91e0a65304d8daecd72f84ffba3c1767f2d3220c85b3); /* statement */ 
uint256 unmetAmount = consideration[j].startAmount;

                    // Revert if the remaining amount is not zero.
c_0x3cecb806(0xe5982644727c4df1ebbdf0f4852a1b2fe195d86f0307debad465b9d7527adc14); /* line */ 
                    c_0x3cecb806(0xabf2cbfdd36b86a88b620b8fcc0c867cac5f78880c02c1f60231ff25cd05c433); /* statement */ 
if (unmetAmount != 0) {c_0x3cecb806(0xf5e27d8f8d866e5ee5899a3c0ddfba049ebef4081d5dfcd13cd2dc3182d4cce5); /* branch */ 

c_0x3cecb806(0x049af53763b760177b1ad3e1f684e1460a5755418fa8435e4dc5196b682f6e4a); /* line */ 
                        revert ConsiderationNotMet(i, j, unmetAmount);
                    }else { c_0x3cecb806(0xddbb66cd68d1ddd3e032c5216b82e55c52b6971058caaa73a338bc343472d662); /* branch */ 
}
                }
            }
        }

        // Put ether value supplied by the caller on the stack.
c_0x3cecb806(0x4c30fde9ce24fa70d6d1918899a31358f2cbaecdc3b33a871de3fed4224217a2); /* line */ 
        c_0x3cecb806(0x87e2045f15e30b2c5dc31aaa1839f66b9309b4a64d72561206718c096778bc75); /* statement */ 
uint256 etherRemaining = msg.value;

        // Initialize an accumulator array. From this point forward, no new
        // memory regions can be safely allocated until the accumulator is no
        // longer being utilized, as the accumulator operates in an open-ended
        // fashion from this memory pointer; existing memory may still be
        // accessed and modified, however.
c_0x3cecb806(0x0146df00a739aec7c880405aa183a3f39c60f7b6f35dc074f23feca3bee77481); /* line */ 
        c_0x3cecb806(0x7e32a8e526d330330a9c9e64f3cf80a8e834f1472ca9dafd78c4a2711f56a02e); /* statement */ 
bytes memory accumulator = new bytes(AccumulatorDisarmed);

        // Retrieve the length of the executions array and place on stack.
c_0x3cecb806(0xfc2e369992ab295f3b3989bbe685fa94332bbf14a4a815e8a5659aca34b7b192); /* line */ 
        c_0x3cecb806(0x0b38963b900add295d6e487a072bea6e772ab0e828eb56c178c29b08c7931ac6); /* statement */ 
uint256 totalExecutions = executions.length;

        // Iterate over each execution.
c_0x3cecb806(0xa6256b8ad47f1053efd23611099d35aac779a1f01a2fb5b7c0a36964225b2883); /* line */ 
        c_0x3cecb806(0x30861ec28536097dde07ede97e7522a9274fdb7b1755ed7b61cc4a0c1148f12e); /* statement */ 
for (uint256 i = 0; i < totalExecutions; ) {
            // Retrieve the execution and the associated received item.
c_0x3cecb806(0x683f70db272981674099ea74726c3357c005c7a300dbd38842bff1176cceea7b); /* line */ 
            c_0x3cecb806(0x275fb9bcee447a6c59bfc32fdf54bb448c61b66be707136100414fc5cbdde864); /* statement */ 
Execution memory execution = executions[i];
c_0x3cecb806(0xbf464d91b4e33d37d058561247c03a45a85d9a2c66b954bf1752d9d6dab737f7); /* line */ 
            c_0x3cecb806(0xd1f90362e6a7482c6a4f35dd181928aaada820b894c056471bddb1da9dbc0ebc); /* statement */ 
ReceivedItem memory item = execution.item;

            // If execution transfers native tokens, reduce value available.
c_0x3cecb806(0x2c0a8b7efb0311847eeee343fc9ca228c642b5a39a7f9313ea183e748ec5f17e); /* line */ 
            c_0x3cecb806(0xd00f88a1f5d47193e81ec0de3941d73501aa05b8033d635b76bbbaf5214d104a); /* statement */ 
if (item.itemType == ItemType.NATIVE) {c_0x3cecb806(0xb88f0ed86d98170fb869d552a30fa693d59153bf5b05ef21ebdbe11e227096fe); /* branch */ 

                // Ensure that sufficient native tokens are still available.
c_0x3cecb806(0x113cd15fc4240e993003e137f8972c0cefee4bfffbd9f33ca1894eb1b95419ed); /* line */ 
                c_0x3cecb806(0xc2f966a7e788c4c383f3c7ddda4c6669a71ac6a020dcc565ba2bb744e3978ecb); /* statement */ 
if (item.amount > etherRemaining) {c_0x3cecb806(0xbd4e4aeeb694eb44588b14b50a814c2514827a3b1aa5d5265f6c8824798e339a); /* branch */ 

c_0x3cecb806(0x09b17dd1e81f001f076967868d7808416187ac23f94aede8cf3333631963bc75); /* line */ 
                    revert InsufficientEtherSupplied();
                }else { c_0x3cecb806(0xcf04bab62909e6de45429a462f38f9b472485e8bd3cd73d821391aa79498f4b0); /* branch */ 
}

                // Skip underflow check as amount is less than ether remaining.
c_0x3cecb806(0xb2f1c97f50dc9811ea598926d46f404b01742427e8db6db410fb9f83f405f970); /* line */ 
                unchecked {
c_0x3cecb806(0x87e7d775baf757436fdcde25bbb386dd1038cff6814e40e9fb18316e9bb11816); /* line */ 
                    c_0x3cecb806(0x096c5d063d4915bde6341cf3ef963c99194486423bcf9732ad4b13ded124a1e6); /* statement */ 
etherRemaining -= item.amount;
                }
            }else { c_0x3cecb806(0xf06d4bcfea7907dd2bd1f8d11955858064aa64cab1ee9d0fcc8afc83b67c23e6); /* branch */ 
}

            // Transfer the item specified by the execution.
c_0x3cecb806(0xc7088cc625fbd11b0d54b89e9f33cc5ad22941768dd6d3f34b6a606b12c2c8cf); /* line */ 
            c_0x3cecb806(0x3aefa4a473a8ff4a6e3f338ee36d4fb0a353cf30b83df1102d327af964f70aa6); /* statement */ 
_transfer(
                item,
                execution.offerer,
                execution.conduitKey,
                accumulator
            );

            // Skip overflow check as for loop is indexed starting at zero.
c_0x3cecb806(0x66ffd3fdb50ecc968cd0427482880db0f6e515d2ce218567af026cd926681430); /* line */ 
            unchecked {
c_0x3cecb806(0xe65020ca1e320b4c920ae3db271beb4eb19cbb027beb71f18f03192adbd1e38b); /* line */ 
                ++i;
            }
        }

        // Trigger any remaining accumulated transfers via call to the conduit.
c_0x3cecb806(0xfefdfdf794900875370fdd15da985da3be01ea62aaad8725fe151952bea10b59); /* line */ 
        c_0x3cecb806(0x61dd36520f9e0855b9ee90455180e366c450de85cbd9cd80147b024316eed375); /* statement */ 
_triggerIfArmed(accumulator);

        // If any ether remains after fulfillments, return it to the caller.
c_0x3cecb806(0x1dc3a0ed27252f48f7f634c843a8952b5b74ed519c0ffc24ce389968e11c88cf); /* line */ 
        c_0x3cecb806(0x51f1db1a1c98438de143f954ee561e9e63d3c0cdbbfcfe2331b84d0e94e939d0); /* statement */ 
if (etherRemaining != 0) {c_0x3cecb806(0x09b3f96376ceb1bb4092cf6d258dde267c5cb692ed7d9d7025dce0257202f966); /* branch */ 

c_0x3cecb806(0xf56d8f7a46e2912d77b1d4f9da8ef5175f2fc66b9b5035cec1f3c02680536575); /* line */ 
            c_0x3cecb806(0xd4f8ee56cf066bfb9d5c765b81ff72030f37e3227767b2f5999992104cba5926); /* statement */ 
_transferEth(payable(msg.sender), etherRemaining);
        }else { c_0x3cecb806(0xe4c587a24c6322fa3a699156952fff66ef90d03cc9329f280e2d08313bdd1389); /* branch */ 
}

        // Clear the reentrancy guard.
c_0x3cecb806(0xa758a338a98380a9a4ceffc04840910df777e40f7cdf35573d80fcb783c4fc39); /* line */ 
        c_0x3cecb806(0x52e8a2e09ff57b50712d612cd22812478804a7d6c8ad17918ca95aa232ce1f0a); /* statement */ 
_clearReentrancyGuard();

        // Return the array containing available orders.
c_0x3cecb806(0x402a9ad51e15fbabe6885522e58ad7c801d213688726c3e39bfb394e5cf9c1da); /* line */ 
        c_0x3cecb806(0xe00d587e5c831b7675ab7c12795871b111d5c096ca1036c35918d273ac74a4dc); /* statement */ 
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
    ) internal returns (Execution[] memory executions) {c_0x3cecb806(0xf7924193e611e7115ca7f9b83b235427944b67d383d81acf0578c873b5d26939); /* function */ 

        // Validate orders, update order status, and determine item amounts.
c_0x3cecb806(0xb1607efac7c5987b032a658f9647df6c28092af0f8e5c1a4d1c4d2ca3a3901c3); /* line */ 
        c_0x3cecb806(0x65999878486198c0845e560d72f94c79b50215bf753cabc86b304c9a17aa9be1); /* statement */ 
_validateOrdersAndPrepareToFulfill(
            advancedOrders,
            criteriaResolvers,
            true, // Signifies that invalid orders should revert.
            advancedOrders.length,
            address(0) // OrderFulfilled event has no recipient when matching.
        );

        // Fulfill the orders using the supplied fulfillments.
c_0x3cecb806(0x8387b78f9e2904eb3a74890f505752264a254c2cbfc6cc149bf6c488cd69faac); /* line */ 
        c_0x3cecb806(0xeed3b043bcc29d4b4ac8bc0deb622211fd71c5e81ac1571eac614cd80e54ecf0); /* statement */ 
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
    ) internal returns (Execution[] memory executions) {c_0x3cecb806(0x004d7d0352aa5c86352e11713f2e732209115d91647ae338ad7adb3bfc810e1a); /* function */ 

        // Retrieve fulfillments array length and place on the stack.
c_0x3cecb806(0x87566d618b8c456f84b121a208099d1aa391c01e57b16a14e86d096a6661b1b4); /* line */ 
        c_0x3cecb806(0x0a018756ea4835cd74d722baa953596af3cba78e994c2168d95a664effe8eb5c); /* statement */ 
uint256 totalFulfillments = fulfillments.length;

        // Allocate executions by fulfillment and apply them to each execution.
c_0x3cecb806(0x79baa3c744c12738fea0cc6a48b234b9c9b6a31500ad6648c079f83a62acc0a3); /* line */ 
        c_0x3cecb806(0x1b869d2ad92ffb42473e5182c86bc1388a7b07ff4d521045713744014412b51a); /* statement */ 
executions = new Execution[](totalFulfillments);

        // Skip overflow checks as all for loops are indexed starting at zero.
c_0x3cecb806(0xf9b1b14502959c8138fd01b2dc8e40e3862455e3299f809a07fe40c49047c4b6); /* line */ 
        unchecked {
            // Track number of filtered executions.
c_0x3cecb806(0x020be804d38283cc7078fe7457febdba8430163285ee2e69d4d4f8ef7876d48f); /* line */ 
            c_0x3cecb806(0x6ab8ad6d683da7b604bd8bc15f917c4281862450a7b91404c915cdee3d5cb704); /* statement */ 
uint256 totalFilteredExecutions = 0;

            // Iterate over each fulfillment.
c_0x3cecb806(0x2913cbfc6aed57aed82997e22bd2e31d894fa9e431fd6c436ae4f2349c33a882); /* line */ 
            c_0x3cecb806(0x231918521d8fc47f35a8d4792c2d349350fb45c95a32b9602857ea80332131e0); /* statement */ 
for (uint256 i = 0; i < totalFulfillments; ++i) {
                /// Retrieve the fulfillment in question.
c_0x3cecb806(0x2f3e43801ab7cbe297b19988ed2ac77a4dd240a98ce318f4223d89001952ac3e); /* line */ 
                c_0x3cecb806(0x959912cbf373ab7f43afbdfc6462a8e9ac651de5ac1bf0c3cc819a722dc19669); /* statement */ 
Fulfillment calldata fulfillment = fulfillments[i];

                // Derive the execution corresponding with the fulfillment.
c_0x3cecb806(0x1e2c1702ccfe1c096ccaae7375f91110450c9150cb840a58dc53f7ead46b8e4e); /* line */ 
                c_0x3cecb806(0x2b1b42eca95ce908b8036f3bf93d88ccd7004136175d5198470c94060a93602b); /* statement */ 
Execution memory execution = _applyFulfillment(
                    advancedOrders,
                    fulfillment.offerComponents,
                    fulfillment.considerationComponents
                );

                // If offerer and recipient on the execution are the same...
c_0x3cecb806(0xd50569fce1fafdc7891042de766e45ae11b1e73cc9ea7000fcc01df66a84fe5c); /* line */ 
                c_0x3cecb806(0xda5f60310555a9ae82c04a9db136acc789923ff79f208e541a6d6de531c140dd); /* statement */ 
if (execution.item.recipient == execution.offerer) {c_0x3cecb806(0x6afd9c3b3066b304544cb1620380c12b8a773257357f14e1c96250dc239bc3e6); /* branch */ 

                    // Increment total filtered executions.
c_0x3cecb806(0x5860aeb3d47000292f0f538bfd835e3d548272d97b2534e2d3ad458793056ece); /* line */ 
                    ++totalFilteredExecutions;
                } else {c_0x3cecb806(0x195383b2641130fe086b2691fa082e0a748193b16db5899e99f2a3fb7609d013); /* branch */ 

                    // Otherwise, assign the execution to the executions array.
c_0x3cecb806(0x4b925dd84ff11a11dc045eb8b60e3f12886079913bda5c8f0244b746bf36a345); /* line */ 
                    c_0x3cecb806(0x3b264c9b2cc7354e858de5009606696911a810b98840e20176599f29e879f372); /* statement */ 
executions[i - totalFilteredExecutions] = execution;
                }
            }

            // If some number of executions have been filtered...
c_0x3cecb806(0x589223127c18329401b00c9547a12263a2a06dd33b3f029fde85a9734e7a60c3); /* line */ 
            c_0x3cecb806(0x4b50de585c4a51f51ccbdfa368d47bfe8d89884a1fe88c05c776270bdb8a089b); /* statement */ 
if (totalFilteredExecutions != 0) {c_0x3cecb806(0xc602080f02e3800a95422e4cee577c7c9a0d65412654eed2aeafdccb754c986f); /* branch */ 

                // reduce the total length of the executions array.
c_0x3cecb806(0x1b4f93d5e09b72d8c80ce237a6224f1c10c4c44bf739fc222eaf135b6c3dde77); /* line */ 
                assembly {
                    mstore(
                        executions,
                        sub(mload(executions), totalFilteredExecutions)
                    )
                }
            }else { c_0x3cecb806(0xcf88451da17f0053b378c4423218d011befebbb6f4d362926971e05353031e35); /* branch */ 
}
        }

        // Perform final checks and execute orders.
c_0x3cecb806(0xaea96d02b486fb2cf4840b219aab22ec3921bfb7b6e4a8b496de033271d9bdad); /* line */ 
        c_0x3cecb806(0x5b464a587077c2b2ce0d71abd0e3406b4dfc1adee3e60db18cecec752b2f663e); /* statement */ 
_performFinalChecksAndExecuteOrders(advancedOrders, executions);

        // Return the executions array.
c_0x3cecb806(0xaf7508fcaed0bfaacbfe58839725b577024acb70380cc1845a6259cd211cb3bc); /* line */ 
        c_0x3cecb806(0xb15b6cc5ad319912a38e468932f1cefcfeb90b950500f3fd11b8305ab961b6c3); /* statement */ 
return (executions);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
function c_0xe8040558(bytes32 c__0xe8040558) pure {}


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
function c_0x6a7eb606(bytes32 c__0x6a7eb606) internal pure {}

    /**
     * @notice Derive and set hashes, reference chainId, and associated domain
     *         separator during deployment.
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     */
    constructor(address conduitController) OrderCombiner(conduitController) {c_0x6a7eb606(0x5239214bb228a08ce72b3384a9fe98a40aab99d2b5ef84710dbcb88cddf40191); /* function */ 
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
    {c_0x6a7eb606(0xe8fcb3b8a6b6fc7d3c51e960056e220cc7f9dd1b7e811e846f264202ff0afcfc); /* function */ 

        // Validate and fulfill the basic order.
c_0x6a7eb606(0xad45ed1fd1ef7634c4fcb71c9185833ba905493376b675a25808cdc5216f2b57); /* line */ 
        c_0x6a7eb606(0x34afee5a8b7842ed9339181e5ee85483eb4b587048dc4d819ceb5ff9909b40ab); /* statement */ 
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
    {c_0x6a7eb606(0x5013023bba6347df3de9c2170238022380b55b7b724fb23867d541f2d0785194); /* function */ 

        // Convert order to "advanced" order, then validate and fulfill it.
c_0x6a7eb606(0xa5f2e7d615743134e8f5e1ee09357c0152eaeada720111c8884858585fa65035); /* line */ 
        c_0x6a7eb606(0xfcbb0a5fb42d16806b45d3d3ad9f316244aa15a1c6731cffc74571a452263829); /* statement */ 
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
    ) external payable override returns (bool fulfilled) {c_0x6a7eb606(0xcf57745403187f300c1c27cb02cf029c394739b29d2dc3db87dfc5036bd409e8); /* function */ 

        // Validate and fulfill the order.
c_0x6a7eb606(0xd41dd320d4bba5e788675d7b19490c36e8874e5f83068b12a016c9e83863e439); /* line */ 
        c_0x6a7eb606(0x58f1da284294ea915cf537636a4e3a46c4f4ae433989fb7ae67b101165024a59); /* statement */ 
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
    {c_0x6a7eb606(0x59925e1163e60018bc6cf1d4c30f1eca2c412512c7a628bcf9a1801b1e4b6d77); /* function */ 

        // Convert orders to "advanced" orders and fulfill all available orders.
c_0x6a7eb606(0xc5f7ead44e11cb29e12ccf72f7d069310b24523a9fd43103eaed9ddf047b48e5); /* line */ 
        c_0x6a7eb606(0x8f6c28e569fcacd849c8069c92e0b570cb70b334f8cf1e79a3eebb8359b719d7); /* statement */ 
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
    {c_0x6a7eb606(0x209b22f970e2aa9c818a4af9b1b9c83b7338b8c24a04851eb54fc0a51a24ac1f); /* function */ 

        // Fulfill all available orders.
c_0x6a7eb606(0x824e43d9ce97d26aad4867d6ec06be011295c9ad26561ab19e807198af2d3e26); /* line */ 
        c_0x6a7eb606(0xf7dad9e60920fcf476d2042992a8b9349668166fb56471ea69b953343e5d54b2); /* statement */ 
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
    ) external payable override returns (Execution[] memory executions) {c_0x6a7eb606(0x9cf7531acd084403daeadf87366445b67f73a99499ebd6bc4165c15afdbbc469); /* function */ 

        // Convert to advanced, validate, and match orders using fulfillments.
c_0x6a7eb606(0x5a4e31ba5bf6d06111a65b10cecd53d92a92dc9fd42e708d65f1e64f71a16663); /* line */ 
        c_0x6a7eb606(0x7f33180b420daeb9444d56b9ac2d7fdc674080106ba036ec4a87e132b0514764); /* statement */ 
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
    ) external payable override returns (Execution[] memory executions) {c_0x6a7eb606(0x5ecf86df1f51199b12c079b7e3ca1762054d2dc6af2497b808f7e51a395741b8); /* function */ 

        // Validate and match the advanced orders using supplied fulfillments.
c_0x6a7eb606(0x1f53fcea3b9726aecc280e07638a8f57b47eda660d5f44126ec11dda49dbe9d8); /* line */ 
        c_0x6a7eb606(0xcf3fcd92b3d6e3d74f1d4a1016415170c5730c1e20142d614282010175e8787b); /* statement */ 
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
    {c_0x6a7eb606(0x51711b658d2c37b93f94eadca1544da6cf5c55c45fa49e261ff0469be213b566); /* function */ 

        // Cancel the orders.
c_0x6a7eb606(0x762b5f128e5d4ad8ec5ef6c21f4fe9e90ca7aeb934fd4a00c9fdc2845472ef69); /* line */ 
        c_0x6a7eb606(0x513139834bd888245a49549e018c9b8583fc3715695f0b0520f3dfdf43d702c1); /* statement */ 
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
    {c_0x6a7eb606(0x282f500b72114c3f60e4208b444785f9111ab5181481b127fb0d6d91a4986f99); /* function */ 

        // Validate the orders.
c_0x6a7eb606(0x50470cfd3ce1f02d9664aa45e4fb13dd40e6dfbe68c62a3a29a37ee6caa575c3); /* line */ 
        c_0x6a7eb606(0x447dce5a164b88de3814b5c55cdaa475f82df3dc48a2743042e8391b1af277db); /* statement */ 
validated = _validate(orders);
    }

    /**
     * @notice Cancel all orders from a given offerer with a given zone in bulk
     *         by incrementing a counter. Note that only the offerer may
     *         increment the counter.
     *
     * @return newCounter The new counter.
     */
    function incrementCounter() external override returns (uint256 newCounter) {c_0x6a7eb606(0x6e54125c326e50715643d1daf10f895c18c258d6904c5c214b052f991eda860f); /* function */ 

        // Increment current counter for the supplied offerer.
c_0x6a7eb606(0x1a3046616af926e6d3df1b4f190b97ed610405f82a6732427771175f77f13e16); /* line */ 
        c_0x6a7eb606(0xbe6c58211789917706ee49a58daa1019c3898dfed5a9e24220ea818423291946); /* statement */ 
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
    {c_0x6a7eb606(0x3e33dbcf62955e656f06d09b667a2284163379cccfd341f4ab1a2bfdaf504a5f); /* function */ 

        // Derive order hash by supplying order parameters along with counter.
c_0x6a7eb606(0x01a6eec108e262d9f23a0f8c83ee2304f732f06722d1fba7313e98bac84e4430); /* line */ 
        c_0x6a7eb606(0x5cd73301e98fff01d9396d790602b3b169a4850a5c995505104771a9dadbeebb); /* statement */ 
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
    {c_0x6a7eb606(0x41280a05bf421e366178ea9715eb8abd7525a81b0daa488968cc267e58f982e8); /* function */ 

        // Retrieve the order status using the order hash.
c_0x6a7eb606(0x35efc9014f7fe9442478b69e1018218724a5fd00d85b2bb2aa029d1de0e546b3); /* line */ 
        c_0x6a7eb606(0x18f4e6154a2285063f4e72294dbaca0c3dd166cf4d37f9b02599da3c1d22e823); /* statement */ 
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
    {c_0x6a7eb606(0x2c368e448598f1038ba0bb0723799e4227a4f33c0515e4b6505c81cbcce9e007); /* function */ 

        // Return the counter for the supplied offerer.
c_0x6a7eb606(0xd86d220f939633a659d5244c727fea04a0918837f062268b913a0c23c255df1a); /* line */ 
        c_0x6a7eb606(0xe906733ae273eafcfe92c16bcc0ec668c913b5783cbdfbd43ca06fcda366d165); /* statement */ 
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
    {c_0x6a7eb606(0x06ac792d32dc3e44e534c18e5b99417f3634a79add45060b889e4bdf3b55f667); /* function */ 

        // Return the information for this contract.
c_0x6a7eb606(0x57a40dff3237f58318f671525e6e4ab0e7eb7b8d5cb398d817d1cbdd330019e4); /* line */ 
        c_0x6a7eb606(0xec02006eeebf953a3d4f5ab87606466a30e541f8c59f5051937edf906e4c8b9f); /* statement */ 
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
    {c_0x6a7eb606(0xbe4724629e213f0300e6be998de8e66df4e51b902603be4a81f5b0093638542e); /* function */ 

        // Return the name of the contract.
c_0x6a7eb606(0x95c38aaabefc6b5644b346d6889d9b17addf878f46ad02dc01e676a30bcd3d06); /* line */ 
        c_0x6a7eb606(0xc66e67d5be0c96e4a3f9e7aeec976fcb01927e88c80f801a1b24e849f2c94c1d); /* statement */ 
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
function c_0xa2a118df(bytes32 c__0xa2a118df) pure {}


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
function c_0x9ef19017(bytes32 c__0x9ef19017) internal pure {}

    /**
     * @notice Derive and set hashes, reference chainId, and associated domain
     *         separator during deployment.
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     */
    constructor(address conduitController) Consideration(conduitController) {c_0x9ef19017(0xb0736b2a5e31ee9fed64e1df0a0b6b4d0e588e3d58d2849be75552406f3ca5c7); /* function */ 
}

    /**
     * @dev Internal pure function to retrieve and return the name of this
     *      contract.
     *
     * @return The name of this contract.
     */
    function _name() internal pure override returns (string memory) {c_0x9ef19017(0x7a13697383fe167b205925ee99c308c76a58b787e56197cc6445430eaf295b24); /* function */ 

        // Return the name of the contract.
c_0x9ef19017(0xa8babc69b2e14b75e27ad22ab1d5d77eff89b8f1d37e2c445b4f0e85024ad74a); /* line */ 
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
    function _nameString() internal pure override returns (string memory) {c_0x9ef19017(0x953c7db55302c4acfdff2ecdc351514f66f7ab67e950c7f88e6771f32b195396); /* function */ 

        // Return the name of the contract.
c_0x9ef19017(0xe19f99f5ecd69f30d761b33c1afeb17dd79b00ce30a1275c8c2eda29eec711a1); /* line */ 
        c_0x9ef19017(0xfd92c23d35a78146174b785b3d923f7da7c642860b642ea6d2865a38df2b6054); /* statement */ 
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
function c_0xa44b853d(bytes32 c__0xa44b853d) pure {}


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