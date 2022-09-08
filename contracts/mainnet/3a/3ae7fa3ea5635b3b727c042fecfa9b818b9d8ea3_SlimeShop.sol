// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import {MerkleProofLib} from "solady/utils/MerkleProofLib.sol";
import {BoundLayerableFirstComposedCutoff} from "bound-layerable/examples/BoundLayerableFirstComposedCutoff.sol";
import {CommissionWithdrawable} from "utility-contracts/withdrawable/CommissionWithdrawable.sol";
import {ConstructorArgs} from "./Structs.sol";
import {ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import {ERC721A} from "bound-layerable/token/ERC721A.sol";

// ░██████╗██╗░░░░░██╗███╗░░░███╗███████╗░██████╗██╗░░██╗░█████╗░██████╗░
// ██╔════╝██║░░░░░██║████╗░████║██╔════╝██╔════╝██║░░██║██╔══██╗██╔══██╗
// ╚█████╗░██║░░░░░██║██╔████╔██║█████╗░░╚█████╗░███████║██║░░██║██████╔╝
// ░╚═══██╗██║░░░░░██║██║╚██╔╝██║██╔══╝░░░╚═══██╗██╔══██║██║░░██║██╔═══╝░
// ██████╔╝███████╗██║██║░╚═╝░██║███████╗██████╔╝██║░░██║╚█████╔╝██║░░░░░
// ╚═════╝░╚══════╝╚═╝╚═╝░░░░░╚═╝╚══════╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░
contract SlimeShop is
    BoundLayerableFirstComposedCutoff,
    ERC2981,
    CommissionWithdrawable
{
    struct PublicMintParameters {
        uint64 publicMintPrice;
        uint64 publicSaleStartTime;
        uint64 maxMintedSetsPerWallet;
    }

    PublicMintParameters public publicMintParameters;
    bytes32 public merkleRoot;

    error IncorrectPayment(uint256 got, uint256 want);
    error InvalidProof();
    error MaxMintsExceeded(uint256 numLeft);
    error MintNotActive(uint256 startTime);

    constructor(ConstructorArgs memory args)
        BoundLayerableFirstComposedCutoff(
            args.name,
            args.symbol,
            args.vrfCoordinatorAddress,
            args.maxNumSets,
            args.numTokensPerSet,
            args.subscriptionId,
            args.metadataContractAddress,
            args.firstComposedCutoff,
            args.exclusiveLayerId,
            16,
            args.keyHash
        )
        CommissionWithdrawable(args.feeRecipient, args.feeBps)
    {
        publicMintParameters = PublicMintParameters({
            publicMintPrice: args.publicMintPrice,
            publicSaleStartTime: args.startTime,
            maxMintedSetsPerWallet: args.maxSetsPerWallet
        });

        merkleRoot = args.merkleRoot;
        _setDefaultRoyalty(
            args.royaltyInfo.receiver,
            args.royaltyInfo.royaltyFraction
        );
    }

    function mint(uint256 numSets) public payable canMint(numSets) {
        PublicMintParameters memory params = publicMintParameters;
        uint256 _publicSaleStartTime = params.publicSaleStartTime;
        if (block.timestamp < _publicSaleStartTime) {
            revert MintNotActive(_publicSaleStartTime);
        }
        uint256 price = params.publicMintPrice * numSets;
        if (msg.value != price) {
            revert IncorrectPayment(msg.value, price);
        }
        uint256 numSetsMinted = _numberMinted(msg.sender) / NUM_TOKENS_PER_SET;
        if (params.maxMintedSetsPerWallet < numSetsMinted + numSets) {
            revert MaxMintsExceeded(
                params.maxMintedSetsPerWallet - numSetsMinted
            );
        }
        _mint(msg.sender, numSets * NUM_TOKENS_PER_SET);
    }

    function mintAllowList(
        uint256 numSets,
        uint256 mintPrice,
        uint256 maxMintedSetsForWallet,
        uint256 startTime,
        bytes32[] calldata proof
    ) public payable canMint(numSets) {
        if (block.timestamp < startTime) {
            revert MintNotActive(startTime);
        }
        if (msg.value < mintPrice) {
            revert IncorrectPayment(msg.value, mintPrice);
        }
        uint256 numberMinted = _numberMinted(msg.sender) / NUM_TOKENS_PER_SET;
        if (maxMintedSetsForWallet < numberMinted + numSets) {
            revert MaxMintsExceeded(maxMintedSetsForWallet - numberMinted);
        }
        bool isValid = MerkleProofLib.verify(
            proof,
            merkleRoot,
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    mintPrice,
                    maxMintedSetsForWallet,
                    startTime
                )
            )
        );
        if (!isValid) {
            revert InvalidProof();
        }

        _mint(msg.sender, numSets * NUM_TOKENS_PER_SET);
    }

    /**
     * @notice Determine layer type by its token ID
     */
    function getLayerType(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint8 layerType)
    {
        uint256 numTokensPerSet = NUM_TOKENS_PER_SET;

        /// @solidity memory-safe-assembly
        assembly {
            layerType := mod(tokenId, numTokensPerSet)
            if gt(layerType, 5) {
                layerType := 5
            }
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        return _tokenURI(tokenId);
    }

    function getPublicSaleStartTime() public view virtual returns (uint64) {
        return publicMintParameters.publicSaleStartTime;
    }

    function getPublicMintPrice() public view virtual returns (uint64) {
        return publicMintParameters.publicMintPrice;
    }

    function getPublicMaxSetsPerWallet() public view virtual returns (uint64) {
        return publicMintParameters.maxMintedSetsPerWallet;
    }

    function getNumberMintedForAddress(address addr)
        public
        view
        virtual
        returns (uint256)
    {
        return _numberMinted(addr);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPublicSaleStartTime(uint64 startTime) public onlyOwner {
        publicMintParameters.publicSaleStartTime = startTime;
    }

    function setPublicMintPrice(uint64 price) public onlyOwner {
        publicMintParameters.publicMintPrice = price;
    }

    function setMaxMintedSetsPerWallet(uint64 maxMintedSetsPerWallet)
        public
        onlyOwner
    {
        publicMintParameters.maxMintedSetsPerWallet = maxMintedSetsPerWallet;
    }

    function setDefaultRoyalty(address receiver, uint96 royaltyFraction)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, royaltyFraction);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            interfaceId == type(ERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Gas optimized verification of proof of inclusion for a leaf in a Merkle tree.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol)
library MerkleProofLib {
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isValid) {
        assembly {
            if proof.length {
                // Left shift by 5 is equivalent to multiplying by 0x20.
                let end := add(proof.offset, shl(5, proof.length))
                // Initialize `offset` to the offset of `proof` in the calldata.
                let offset := proof.offset
                // Iterate over proof elements to compute root hash.
                // prettier-ignore
                for {} 1 {} {
                    // Slot of `leaf` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(leaf, calldataload(offset)))
                    // Store elements to hash contiguously in scratch space.
                    // Scratch space is 64 bytes (0x00 - 0x3f) and both elements are 32 bytes.
                    mstore(scratch, leaf)
                    mstore(xor(scratch, 0x20), calldataload(offset))
                    // Reuse `leaf` to store the hash to reduce stack operations.
                    leaf := keccak256(0x00, 0x40)
                    offset := add(offset, 0x20)
                    // prettier-ignore
                    if iszero(lt(offset, end)) { break }
                }
            }
            isValid := eq(leaf, root)
        }
    }

    function verifyMultiProof(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32[] calldata leafs,
        bool[] calldata flags
    ) internal pure returns (bool isValid) {
        // Rebuilds the root by consuming and producing values on a queue.
        // The queue starts with the `leafs` array, and goes into a `hashes` array.
        // After the process, the last element on the queue is verified
        // to be equal to the `root`.
        //
        // The `flags` array denotes whether the sibling
        // should be popped from the queue (`flag == true`), or
        // should be popped from the `proof` (`flag == false`).
        assembly {
            // If the number of flags is correct.
            // prettier-ignore
            for {} eq(add(leafs.length, proof.length), add(flags.length, 1)) {} {
                // Left shift by 5 is equivalent to multiplying by 0x20.
                // Compute the end calldata offset of `leafs`.
                let leafsEnd := add(leafs.offset, shl(5, leafs.length))
                // These are the calldata offsets.
                let leafsOffset := leafs.offset
                let flagsOffset := flags.offset
                let proofOffset := proof.offset

                // We can use the free memory space for the queue.
                // We don't need to allocate, since the queue is temporary.
                let hashesFront := mload(0x40)
                let hashesBack := hashesFront
                // This is the end of the memory for the queue.
                let end := add(hashesBack, shl(5, flags.length))

                // For the case where `proof.length + leafs.length == 1`.
                if iszero(flags.length) {
                    // If `proof.length` is zero, `leafs.length` is 1.
                    if iszero(proof.length) {
                        isValid := eq(calldataload(leafsOffset), root)
                        break
                    }
                    // If `leafs.length` is zero, `proof.length` is 1.
                    if iszero(leafs.length) {
                        isValid := eq(calldataload(proofOffset), root)
                        break
                    }
                }

                // prettier-ignore
                for {} 1 {} {
                    let a := 0
                    // Pops a value from the queue into `a`.
                    switch lt(leafsOffset, leafsEnd)
                    case 0 {
                        // Pop from `hashes` if there are no more leafs.
                        a := mload(hashesFront)
                        hashesFront := add(hashesFront, 0x20)
                    }
                    default {
                        // Otherwise, pop from `leafs`.
                        a := calldataload(leafsOffset)
                        leafsOffset := add(leafsOffset, 0x20)
                    }

                    let b := 0
                    // If the flag is false, load the next proof,
                    // else, pops from the queue.
                    switch calldataload(flagsOffset)
                    case 0 {
                        // Loads the next proof.
                        b := calldataload(proofOffset)
                        proofOffset := add(proofOffset, 0x20)
                    }
                    default {
                        // Pops a value from the queue into `a`.
                        switch lt(leafsOffset, leafsEnd)
                        case 0 {
                            // Pop from `hashes` if there are no more leafs.
                            b := mload(hashesFront)
                            hashesFront := add(hashesFront, 0x20)
                        }
                        default {
                            // Otherwise, pop from `leafs`.
                            b := calldataload(leafsOffset)
                            leafsOffset := add(leafsOffset, 0x20)
                        }
                    }
                    // Advance to the next flag offset.
                    flagsOffset := add(flagsOffset, 0x20)

                    // Slot of `a` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(a, b))
                    // Hash the scratch space and push the result onto the queue.
                    mstore(scratch, a)
                    mstore(xor(scratch, 0x20), b)
                    mstore(hashesBack, keccak256(0x00, 0x40))
                    hashesBack := add(hashesBack, 0x20)
                    // prettier-ignore
                    if iszero(lt(hashesBack, end)) { break }
                }
                // Checks if the last value in the queue is same as the root.
                isValid := eq(mload(sub(hashesBack, 0x20)), root)
                break
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {BoundLayerable} from '../BoundLayerable.sol';

/**
 * @notice BoundLayerable contract that automatically binds a special layer if composed (layers are bound)
 *         before the cutoff time
 */
abstract contract BoundLayerableFirstComposedCutoff is BoundLayerable {
    uint256 immutable FIRST_COMPOSED_CUTOFF;
    uint8 immutable EXCLUSIVE_LAYER_ID;

    constructor(
        string memory name,
        string memory symbol,
        address vrfCoordinatorAddress,
        uint240 maxNumSets,
        uint8 numTokensPerSet,
        uint64 subscriptionId,
        address metadataContractAddress,
        uint256 firstComposedCutoff,
        uint8 exclusiveLayerId,
        uint8 numRandomBatches,
        bytes32 keyHash
    )
        BoundLayerable(
            name,
            symbol,
            vrfCoordinatorAddress,
            maxNumSets,
            numTokensPerSet,
            subscriptionId,
            metadataContractAddress,
            numRandomBatches,
            keyHash
        )
    {
        FIRST_COMPOSED_CUTOFF = firstComposedCutoff;
        EXCLUSIVE_LAYER_ID = exclusiveLayerId;
    }

    function _setBoundLayersAndEmitEvent(uint256 baseTokenId, uint256 bindings)
        internal
        virtual
        override
    {
        // automatically bind a special layer if the base token was composed before the cutoff time
        uint256 exclusiveLayerId = EXCLUSIVE_LAYER_ID;
        uint256 firstComposedCutoff = FIRST_COMPOSED_CUTOFF;
        /// @solidity memory-safe-assembly
        assembly {
            // conditionally set the exclusive layer bit if the base token is composed before cutoff
            bindings := or(
                bindings,
                shl(
                    exclusiveLayerId,
                    // 1 if timestamp is before cutoff, 0 otherwise (ie, no-op)
                    lt(timestamp(), firstComposedCutoff)
                )
            )
        }
        super._setBoundLayersAndEmitEvent(baseTokenId, bindings);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
import {Withdrawable} from "./Withdrawable.sol";

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

///@notice Ownable helper contract to withdraw ether or tokens from the contract address balance
contract CommissionWithdrawable is Withdrawable {
    address internal immutable commissionPayoutAddress;
    uint256 internal immutable commissionBps;

    error CommissionPayoutAddressIsZeroAddress();
    error CommissionBpsTooLarge();

    constructor(address _commissionPayoutAddress, uint256 _commissionBps) {
        if (_commissionPayoutAddress == address(0)) {
            revert CommissionPayoutAddressIsZeroAddress();
        }
        if (_commissionBps > 10_000) {
            revert CommissionBpsTooLarge();
        }
        commissionPayoutAddress = _commissionPayoutAddress;
        commissionBps = _commissionBps;
    }

    ////////////////////////
    // Withdrawal methods //
    ////////////////////////

    ///@notice Withdraw Ether from contract address. OnlyOwner.
    function withdraw() external override onlyOwner {
        uint256 balance = address(this).balance;
        (
            uint256 ownerShareMinusCommission,
            uint256 commissionFee
        ) = calculateOwnerShareAndCommissionFee(balance);
        SafeTransferLib.safeTransferETH(owner(), ownerShareMinusCommission);
        SafeTransferLib.safeTransferETH(commissionPayoutAddress, commissionFee);
    }

    ///@notice Withdraw tokens from contract address. OnlyOwner.
    ///@param _token ERC20 smart contract address
    function withdrawERC20(address _token) external override onlyOwner {
        ERC20 token = ERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        (
            uint256 ownerShareMinusCommission,
            uint256 commissionFee
        ) = calculateOwnerShareAndCommissionFee(balance);
        SafeTransferLib.safeTransfer(token, owner(), ownerShareMinusCommission);
        SafeTransferLib.safeTransfer(
            token,
            commissionPayoutAddress,
            commissionFee
        );
    }

    function calculateOwnerShareAndCommissionFee(uint256 balance)
        private
        view
        returns (uint256, uint256)
    {
        uint256 commissionFee;
        // commissionBps is max 10000 which is ~2^14; will only overflow if balance is > ~2^242
        if (balance < (1 << 242)) {
            commissionFee = (balance * commissionBps) / 10000;
        } else {
            // worst case this drops 99_990_000, neglibible if balance is > 2^242
            commissionFee = (balance / 10000) * commissionBps;
        }
        uint256 ownerShareMinusCommission = balance - commissionFee;
        return (ownerShareMinusCommission, commissionFee);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

struct RoyaltyInfo {
    address receiver;
    uint96 royaltyFraction;
}

struct ConstructorArgs {
    string name;
    string symbol;
    address vrfCoordinatorAddress;
    uint240 maxNumSets;
    uint8 numTokensPerSet;
    uint64 subscriptionId;
    address metadataContractAddress;
    uint256 firstComposedCutoff;
    uint8 exclusiveLayerId;
    uint64 startTime;
    bytes32 merkleRoot;
    address feeRecipient;
    uint16 feeBps;
    RoyaltyInfo royaltyInfo;
    uint64 publicMintPrice;
    uint64 maxSetsPerWallet;
    bytes32 keyHash;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import 'ERC721A/IERC721A.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return
            (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) &
            _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return
            (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) &
            _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed =
            (packed & _BITMASK_AUX_COMPLEMENT) |
            (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId)
        internal
        view
        virtual
        returns (TokenOwnership memory)
    {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index)
        internal
        view
        virtual
        returns (TokenOwnership memory)
    {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId)
        private
        view
        returns (uint256)
    {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed)
        private
        pure
        returns (TokenOwnership memory ownership)
    {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags)
        private
        view
        returns (uint256 result)
    {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(
                owner,
                or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags)
            )
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity)
        private
        pure
        returns (uint256 result)
    {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId)
        public
        payable
        virtual
        override
    {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from)
            revert TransferFromIncorrectOwner();

        (
            uint256 approvedAddressSlot,
            address approvedAddress
        ) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (
            !_isSenderApprovedOrOwner(
                approvedAddress,
                from,
                _msgSenderERC721A()
            )
        )
            if (!isApprovedForAll(from, _msgSenderERC721A()))
                revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED |
                    _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try
            ERC721A__IERC721Receiver(to).onERC721Received(
                _msgSenderERC721A(),
                from,
                tokenId,
                _data
            )
        returns (bytes4 retval) {
            return
                retval ==
                ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] +=
                quantity *
                ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) |
                    _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            // The duplicated `log4` removes an extra check and reduces stack juggling.
            // The assembly, together with the surrounding Solidity code, have been
            // delicately arranged to nudge the compiler into producing optimized opcodes.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                // The `iszero(eq(,))` check ensures that large values of `quantity`
                // that overflows uint256 will make the loop run out of gas.
                // The compiler will optimize the `iszero` away for performance.
                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT)
            revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] +=
                quantity *
                ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) |
                    _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(
                startTokenId,
                startTokenId + quantity - 1,
                address(0),
                to
            );

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (
                        !_checkContractOnERC721Received(
                            address(0),
                            to,
                            index++,
                            _data
                        )
                    ) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    function _isBurned(uint256 tokenId) internal view returns (bool isBurned) {
        return _packedOwnerships[tokenId] & _BITMASK_BURNED != 0;
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (
            uint256 approvedAddressSlot,
            address approvedAddress
        ) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (
                !_isSenderApprovedOrOwner(
                    approvedAddress,
                    from,
                    _msgSenderERC721A()
                )
            )
                if (!isApprovedForAll(from, _msgSenderERC721A()))
                    revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) |
                    _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed =
            (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) |
            (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value)
        internal
        pure
        virtual
        returns (string memory str)
    {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {PackedByteUtility} from './lib/PackedByteUtility.sol';
import {BitMapUtility} from './lib/BitMapUtility.sol';
import {ILayerable} from './metadata/ILayerable.sol';
import {RandomTraits} from './traits/RandomTraits.sol';
import {MaxSupply, NotOwner, CannotBindBase, OnlyBase, LayerAlreadyBound, NoActiveLayers} from './interface/Errors.sol';
import {NOT_0TH_BITMASK, DUPLICATE_ACTIVE_LAYERS_SIGNATURE, LAYER_NOT_BOUND_TO_TOKEN_ID_SIGNATURE} from './interface/Constants.sol';
import {BoundLayerableEvents} from './interface/Events.sol';

abstract contract BoundLayerable is RandomTraits, BoundLayerableEvents {
    using BitMapUtility for uint256;

    // mapping from tokenID to a bitmap of bound layers, where each bit is a boolean indicating the layerId at its
    // position has been bound. Layers are bound to bases by burning them with one of the burnAndBind methods.
    // LayerID zero is not valid, but is set at mint to reduce gas cost when binding the first layers, when it is unset
    mapping(uint256 => uint256) internal _tokenIdToBoundLayers;
    // mapping from tokenID to packed array of (nonzero) bytes indicating the ordered layerIds that are active for the token
    // only layerIds bound to the base tokenId can be set as active, and duplicates are not allowed.
    mapping(uint256 => uint256) internal _tokenIdToPackedActiveLayers;

    ILayerable public metadataContract;

    modifier canMint(uint256 numSets) {
        // get number of tokens to be minted, add next token id, compare to max token id (MAX_NUM_SETS * NUM_TOKENS_PER_SET)
        if (
            numSets * uint256(NUM_TOKENS_PER_SET) + _nextTokenId() - 1 >
            MAX_TOKEN_ID
        ) {
            revert MaxSupply();
        }
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address vrfCoordinatorAddress,
        uint240 maxNumSets,
        uint8 numTokensPerSet,
        uint64 subscriptionId,
        address _metadataContractAddress,
        uint8 numRandomBatches,
        bytes32 keyHash
    )
        RandomTraits(
            name,
            symbol,
            vrfCoordinatorAddress,
            maxNumSets,
            numTokensPerSet,
            subscriptionId,
            numRandomBatches,
            keyHash
        )
    {
        metadataContract = ILayerable(_metadataContractAddress);
    }

    /////////////
    // GETTERS //
    /////////////

    /// @notice get the layerIds currently bound to a tokenId
    function getBoundLayers(uint256 tokenId)
        external
        view
        returns (uint256[] memory)
    {
        return BitMapUtility.unpackBitMap(getBoundLayerBitMap(tokenId));
    }

    /// @notice get the layerIds currently bound to a tokenId as a bit map
    function getBoundLayerBitMap(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        return _tokenIdToBoundLayers[tokenId] & NOT_0TH_BITMASK;
    }

    /// @notice get the layerIds currently active on a tokenId
    function getActiveLayers(uint256 tokenId)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        uint256 activePackedLayers = _tokenIdToPackedActiveLayers[tokenId];
        return PackedByteUtility.unpackByteArray(activePackedLayers);
    }

    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        // get the random seed for the token, which may not be revealed yet
        bytes32 retrievedRandomSeed = getRandomnessForTokenIdFromSeed(
            tokenId,
            packedBatchRandomness
        );
        return
            metadataContract.getTokenURI(
                tokenId,
                // only get layerId if token is revealed
                retrievedRandomSeed == 0x00 ? 0 : getLayerId(tokenId),
                getBoundLayerBitMap(tokenId),
                getActiveLayers(tokenId),
                retrievedRandomSeed
            );
    }

    /////////////
    // SETTERS //
    /////////////

    /// @notice set the address of the metadata contract. OnlyOwner
    /// @param _metadataContract the address of the metadata contract
    function setMetadataContract(ILayerable _metadataContract)
        external
        onlyOwner
    {
        _setMetadataContract(_metadataContract);
    }

    /**
     * @notice Bind a layer token to a base token and burn the layer token. User must own both tokens.
     * @param baseTokenId TokenID of a base token
     * @param layerTokenId TokenID of a layer token
     * @param packedActiveLayerIds Ordered layer IDs packed as bytes into uint256s to set as active on the base token
     * emits LayersBoundToToken
     * emits ActiveLayersChanged
     */
    function burnAndBindSingleAndSetActiveLayers(
        uint256 baseTokenId,
        uint256 layerTokenId,
        uint256 packedActiveLayerIds
    ) public {
        _burnAndBindSingle(baseTokenId, layerTokenId);
        _setActiveLayers(baseTokenId, packedActiveLayerIds);
    }

    /**
     * @notice Bind a layer token to a base token and burn the layer token. User must own both tokens.
     * @param baseTokenId TokenID of a base token
     * @param layerTokenIds TokenIDs of layer tokens
     * @param packedActiveLayerIds Ordered layer IDs packed as bytes into uint256s to set as active on the base token
     * emits LayersBoundToToken
     * emits ActiveLayersChanged
     */
    function burnAndBindMultipleAndSetActiveLayers(
        uint256 baseTokenId,
        uint256[] calldata layerTokenIds,
        uint256 packedActiveLayerIds
    ) public {
        _burnAndBindMultiple(baseTokenId, layerTokenIds);
        _setActiveLayers(baseTokenId, packedActiveLayerIds);
    }

    /**
     * @notice Bind a layer token to a base token and burn the layer token. User must own both tokens.
     * @param baseTokenId TokenID of a base token
     * @param layerTokenId TokenID of a layer token
     * emits LayersBoundToToken
     */
    function burnAndBindSingle(uint256 baseTokenId, uint256 layerTokenId)
        public
        virtual
    {
        _burnAndBindSingle(baseTokenId, layerTokenId);
    }

    /**
     * @notice Bind layer tokens to a base token and burn the layer tokens. User must own all tokens.
     * @param baseTokenId TokenID of a base token
     * @param layerTokenIds TokenIDs of layer tokens
     * emits LayersBoundToToken
     */
    function burnAndBindMultiple(
        uint256 baseTokenId,
        uint256[] calldata layerTokenIds
    ) public virtual {
        _burnAndBindMultiple(baseTokenId, layerTokenIds);
    }

    /**
     * @notice Set the active layer IDs for a base token. Layers must be bound to token
     * @param baseTokenId TokenID of a base token
     * @param packedLayerIds Ordered layer IDs packed as bytes into uint256s to set as active on the base token
     * emits ActiveLayersChanged
     */
    function setActiveLayers(uint256 baseTokenId, uint256 packedLayerIds)
        external
        virtual
    {
        _setActiveLayers(baseTokenId, packedLayerIds);
    }

    function _burnAndBindMultiple(
        uint256 baseTokenId,
        uint256[] calldata layerTokenIds
    ) internal virtual {
        // check owner
        if (ownerOf(baseTokenId) != msg.sender) {
            revert NotOwner();
        }

        // check base
        if (baseTokenId % NUM_TOKENS_PER_SET != 0) {
            revert OnlyBase();
        }
        bytes32 traitSeed = packedBatchRandomness;

        bytes32 baseSeed = getRandomnessForTokenIdFromSeed(
            baseTokenId,
            traitSeed
        );
        uint256 baseLayerId = getLayerId(baseTokenId, baseSeed);

        uint256 bindings = getBoundLayerBitMap(baseTokenId);
        // always bind baseLayer, since it won't be set automatically
        bindings |= baseLayerId.toBitMap();

        // todo: try to batch with arrays by LayerType, fetching distribution for type,
        unchecked {
            // todo: revisit if via_ir = true
            uint256 length = layerTokenIds.length;
            for (uint256 i; i < length; ) {
                uint256 tokenId = layerTokenIds[i];

                // check owner of layer
                if (ownerOf(tokenId) != msg.sender) {
                    revert NotOwner();
                }

                // check layer
                if (tokenId % NUM_TOKENS_PER_SET == 0) {
                    revert CannotBindBase();
                }
                bytes32 layerSeed = getRandomnessForTokenIdFromSeed(
                    tokenId,
                    traitSeed
                );
                uint256 layerId = getLayerId(tokenId, layerSeed);

                // check for duplicates
                uint256 layerIdBitMap = layerId.toBitMap();
                if (bindings & layerIdBitMap > 0) {
                    revert LayerAlreadyBound();
                }

                bindings |= layerIdBitMap;
                _burn(tokenId);
                ++i;
            }
        }
        _setBoundLayersAndEmitEvent(baseTokenId, bindings);
    }

    function _burnAndBindSingle(uint256 baseTokenId, uint256 layerTokenId)
        internal
        virtual
    {
        // check ownership
        if (
            ownerOf(baseTokenId) != msg.sender ||
            ownerOf(layerTokenId) != msg.sender
        ) {
            revert NotOwner();
        }

        // check seed
        bytes32 traitSeed = packedBatchRandomness;
        bytes32 baseSeed = getRandomnessForTokenIdFromSeed(
            baseTokenId,
            traitSeed
        );

        // check base
        if (baseTokenId % NUM_TOKENS_PER_SET != 0) {
            revert OnlyBase();
        }
        uint256 baseLayerId = getLayerId(baseTokenId, baseSeed);

        bytes32 layerSeed = getRandomnessForTokenIdFromSeed(
            layerTokenId,
            traitSeed
        );
        // check layer
        if (layerTokenId % NUM_TOKENS_PER_SET == 0) {
            revert CannotBindBase();
        }
        uint256 layerId = getLayerId(layerTokenId, layerSeed);

        uint256 bindings = getBoundLayerBitMap(baseTokenId);
        // always bind baseLayer, since it won't be set automatically
        bindings |= baseLayerId.toBitMap();
        // TODO: necessary?
        uint256 layerIdBitMap = layerId.toBitMap();
        if (bindings & layerIdBitMap > 0) {
            revert LayerAlreadyBound();
        }

        _burn(layerTokenId);
        _setBoundLayersAndEmitEvent(baseTokenId, bindings | layerIdBitMap);
    }

    function _setActiveLayers(uint256 baseTokenId, uint256 packedLayerIds)
        internal
        virtual
    {
        // TODO: explicitly test this
        if (packedLayerIds == 0) {
            revert NoActiveLayers();
        }
        // check owner
        if (ownerOf(baseTokenId) != msg.sender) {
            revert NotOwner();
        }

        // check base
        if (baseTokenId % NUM_TOKENS_PER_SET != 0) {
            revert OnlyBase();
        }

        // unpack layers into a single bitmap and check there are no duplicates
        (
            uint256 unpackedLayers,
            uint256 numLayers
        ) = _unpackLayersToBitMapAndCheckForDuplicates(packedLayerIds);

        // check new active layers are all bound to baseTokenId
        uint256 boundLayers = getBoundLayerBitMap(baseTokenId);
        _checkUnpackedIsSubsetOfBound(unpackedLayers, boundLayers);

        // clear all bytes after last non-zero bit on packedLayerIds,
        // since unpacking to bitmap short-circuits on first zero byte
        uint256 maskedPackedLayerIds;
        // num layers can never be >32, so 256 - (numLayers * 8) can never negative-oveflow
        unchecked {
            maskedPackedLayerIds =
                packedLayerIds &
                (type(uint256).max << (256 - (numLayers * 8)));
        }

        _tokenIdToPackedActiveLayers[baseTokenId] = maskedPackedLayerIds;
        emit ActiveLayersChanged(msg.sender, baseTokenId, maskedPackedLayerIds);
    }

    function _setBoundLayersAndEmitEvent(uint256 baseTokenId, uint256 bindings)
        internal
        virtual
    {
        // 0 is not a valid layerId, so make sure it is not set on bindings.
        bindings = bindings & NOT_0TH_BITMASK;
        _tokenIdToBoundLayers[baseTokenId] = bindings;
        emit LayersBoundToToken(msg.sender, baseTokenId, bindings);
    }

    /**
     * @notice Unpack bytepacked layerIds and check that there are no duplicates
     * @param bytePackedLayers uint256 of packed layerIds
     * @return bitMap uint256 of unpacked layerIds
     */
    function _unpackLayersToBitMapAndCheckForDuplicates(
        uint256 bytePackedLayers
    ) internal virtual returns (uint256 bitMap, uint256 numLayers) {
        /// @solidity memory-safe-assembly
        assembly {
            for {

            } lt(numLayers, 32) {
                numLayers := add(1, numLayers)
            } {
                let layer := byte(numLayers, bytePackedLayers)
                if iszero(layer) {
                    break
                }
                // put copy of bitmap on stack
                let lastBitMap := bitMap
                // OR layer into bitmap
                bitMap := or(bitMap, shl(layer, 1))
                // check equality - if equal, layer is a duplicate
                if eq(lastBitMap, bitMap) {
                    mstore(
                        0,
                        // revert DuplicateActiveLayers()
                        DUPLICATE_ACTIVE_LAYERS_SIGNATURE
                    )
                    revert(0, 4)
                }
            }
        }
    }

    function _checkUnpackedIsSubsetOfBound(uint256 subset, uint256 superset)
        internal
        pure
        virtual
    {
        // superset should be superset of subset, compare union to superset

        /// @solidity memory-safe-assembly
        assembly {
            if iszero(eq(or(superset, subset), superset)) {
                mstore(
                    0,
                    // revert LayerNotBoundToTokenId()
                    LAYER_NOT_BOUND_TO_TOKEN_ID_SIGNATURE
                )
                let disjoint := xor(superset, subset)
                let notBound := and(disjoint, subset)
                mstore(4, notBound)
                revert(0, 36)
            }
        }
    }

    function _setMetadataContract(ILayerable _metadataContract)
        internal
        virtual
    {
        metadataContract = _metadataContract;
    }

    /////////////
    // HELPERS //
    /////////////

    /// @dev set 0th bit to 1 in order to make first binding cost cheaper for user
    function _setPlaceholderBinding(uint256 tokenId) internal {
        _tokenIdToBoundLayers[tokenId] = 1;
    }

    function _setPlaceholderActiveLayers(uint256 tokenId) internal {
        _tokenIdToPackedActiveLayers[tokenId] = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
import {TwoStepOwnable} from "../TwoStepOwnable.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {IWithdrawable} from "./IWithdrawable.sol";

///@notice Ownable helper contract to withdraw ether or tokens from the contract address balance
contract Withdrawable is TwoStepOwnable, IWithdrawable {
    ///@notice Withdraw Ether from contract address. OnlyOwner.
    function withdraw() external virtual onlyOwner {
        uint256 balance = address(this).balance;
        SafeTransferLib.safeTransferETH(owner(), balance);
    }

    ///@notice Withdraw tokens from contract address. OnlyOwner.
    ///@param _token ERC20 smart contract address
    function withdrawERC20(address _token) external virtual onlyOwner {
        ERC20 token = ERC20(_token);
        uint256 balance = ERC20(_token).balanceOf(address(this));
        SafeTransferLib.safeTransfer(token, owner(), balance);
    }

    ///@notice Withdraw tokens from contract address. OnlyOwner.
    ///@param _token ERC721 smart contract address
    function withdrawERC721(address _token, uint256 tokenId)
        external
        virtual
        onlyOwner
    {
        ERC721 token = ERC721(_token);
        token.transferFrom(address(this), owner(), tokenId);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '../interface/Constants.sol';

library PackedByteUtility {
    /**
     * @notice get the byte value of a right-indexed byte within a uint256
     * @param  index right-indexed location of byte within uint256
     * @param  packedBytes uint256 of bytes
     * @return result the byte at right-indexed index within packedBytes
     */
    function getPackedByteFromRight(uint256 packedBytes, uint256 index)
        internal
        pure
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := byte(sub(31, index), packedBytes)
        }
    }

    /**
     * @notice get the byte value of a left-indexed byte within a uint256
     * @param  index left-indexed location of byte within uint256
     * @param  packedBytes uint256 of bytes
     * @return result the byte at left-indexed index within packedBytes
     */
    function getPackedByteFromLeft(uint256 packedBytes, uint256 index)
        internal
        pure
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := byte(index, packedBytes)
        }
    }

    function packShortAtIndex(
        uint256 packedShorts,
        uint256 shortToPack,
        uint256 index
    ) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let shortOffset := sub(240, shl(4, index))
            let mask := xor(MAX_INT, shl(shortOffset, 0xffff))
            result := and(packedShorts, mask)
            result := or(result, shl(shortOffset, shortToPack))
        }
    }

    function getPackedShortFromRight(uint256 packed, uint256 index)
        internal
        pure
        returns (uint256 result)
    {
        assembly {
            let shortOffset := shl(4, index)
            result := shr(shortOffset, packed)
            result := and(result, 0xffff)
        }
    }

    function getPackedNFromRight(
        uint256 packed,
        uint256 bitsPerIndex,
        uint256 index
    ) internal pure returns (uint256 result) {
        assembly {
            let offset := mul(bitsPerIndex, index)
            let mask := sub(shl(bitsPerIndex, 1), 1)
            result := shr(offset, packed)
            result := and(result, mask)
        }
    }

    function packNAtRightIndex(
        uint256 packed,
        uint256 bitsPerIndex,
        uint256 toPack,
        uint256 index
    ) internal pure returns (uint256 result) {
        assembly {
            // left-shift offset
            let offset := mul(bitsPerIndex, index)
            // mask for 2**n uint
            let nMask := sub(shl(bitsPerIndex, 1), 1)
            // mask to clear bits at offset
            let mask := xor(MAX_INT, shl(offset, nMask))
            // clear bits at offset
            result := and(packed, mask)
            // shift toPack to offset, then pack
            result := or(result, shl(offset, toPack))
        }
    }

    function getPackedShortFromLeft(uint256 packed, uint256 index)
        internal
        pure
        returns (uint256 result)
    {
        assembly {
            let shortOffset := sub(240, shl(4, index))
            result := shr(shortOffset, packed)
            result := and(result, 0xffff)
        }
    }

    /**
     * @notice unpack elements of a packed byte array into a bitmap. Short-circuits at first 0-byte.
     * @param  packedBytes uint256 of bytes
     * @return unpacked - 1-indexed bitMap of all byte values contained in packedBytes up until the first 0-byte
     */
    function unpackBytesToBitMap(uint256 packedBytes)
        internal
        pure
        returns (uint256 unpacked)
    {
        /// @solidity memory-safe-assembly
        assembly {
            for {
                let i := 0
            } lt(i, 32) {
                i := add(i, 1)
            } {
                // this is the ID of the layer, eg, 1, 5, 253
                let byteVal := byte(i, packedBytes)
                // don't count zero bytes
                if iszero(byteVal) {
                    break
                }
                // byteVals are 1-indexed because we're shifting 1 by the value of the byte
                unpacked := or(unpacked, shl(byteVal, 1))
            }
        }
    }

    /**
     * @notice pack byte values into a uint256. Note: *will not* short-circuit on first 0-byte
     * @param  arrayOfBytes uint256[] of byte values
     * @return packed uint256 of packed bytes
     */
    function packArrayOfBytes(uint256[] memory arrayOfBytes)
        internal
        pure
        returns (uint256 packed)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let arrayOfBytesIndexPtr := add(arrayOfBytes, 0x20)
            let arrayOfBytesLength := mload(arrayOfBytes)
            if gt(arrayOfBytesLength, 32) {
                arrayOfBytesLength := 32
            }
            let finalI := shl(3, arrayOfBytesLength)
            let i
            for {

            } lt(i, finalI) {
                arrayOfBytesIndexPtr := add(0x20, arrayOfBytesIndexPtr)
                i := add(8, i)
            } {
                packed := or(
                    packed,
                    shl(sub(248, i), mload(arrayOfBytesIndexPtr))
                )
            }
        }
    }

    function packArrayOfShorts(uint256[] memory shorts)
        internal
        pure
        returns (uint256[2] memory packed)
    {
        packed = [uint256(0), uint256(0)];
        for (uint256 i; i < shorts.length; i++) {
            if (i == 32) {
                break;
            }
            uint256 j = i / 16;
            uint256 index = i % 16;
            packed[j] = packShortAtIndex(packed[j], shorts[i], index);
        }
    }

    /**
     * @notice Unpack a packed uint256 of bytes into a uint256 array of byte values. Short-circuits on first 0-byte.
     * @param  packedByteArray The packed uint256 of bytes to unpack
     * @return unpacked uint256[] The unpacked uint256 array of bytes
     */
    function unpackByteArray(uint256 packedByteArray)
        internal
        pure
        returns (uint256[] memory unpacked)
    {
        /// @solidity memory-safe-assembly
        assembly {
            unpacked := mload(0x40)
            let unpackedIndexPtr := add(0x20, unpacked)
            let maxUnpackedIndexPtr := add(unpackedIndexPtr, shl(5, 32))
            let numBytes
            for {

            } lt(unpackedIndexPtr, maxUnpackedIndexPtr) {
                unpackedIndexPtr := add(0x20, unpackedIndexPtr)
                numBytes := add(1, numBytes)
            } {
                let byteVal := byte(numBytes, packedByteArray)
                if iszero(byteVal) {
                    break
                }
                mstore(unpackedIndexPtr, byteVal)
            }
            // store the number of layers at the pointer to unpacked array
            mstore(unpacked, numBytes)
            // update free mem pointer to be old mem ptr + 0x20 (32-byte array length) + 0x20 * numLayers (each 32-byte element)
            mstore(0x40, add(unpacked, add(0x20, shl(5, numBytes))))
        }
    }

    /**
     * @notice given a uint256 packed array of bytes, pack a byte at an index from the left
     * @param packedBytes existing packed bytes
     * @param byteToPack byte to pack into packedBytes
     * @param index index to pack byte at
     * @return newPackedBytes with byteToPack at index
     */
    function packByteAtIndex(
        uint256 packedBytes,
        uint256 byteToPack,
        uint256 index
    ) internal pure returns (uint256 newPackedBytes) {
        /// @solidity memory-safe-assembly
        assembly {
            // calculate left-indexed bit offset of byte within packedBytes
            let byteOffset := sub(248, shl(3, index))
            // create a mask to clear the bits we're about to overwrite
            let mask := xor(MAX_INT, shl(byteOffset, 0xff))
            // copy packedBytes to newPackedBytes, clearing the relevant bits
            newPackedBytes := and(packedBytes, mask)
            // shift the byte to the offset and OR it into newPackedBytes
            newPackedBytes := or(newPackedBytes, shl(byteOffset, byteToPack))
        }
    }

    /// @dev less efficient logic for packing >32 bytes into >1 uint256
    function packArraysOfBytes(uint256[] memory arrayOfBytes)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256 arrayOfBytesLength = arrayOfBytes.length;
        uint256[] memory packed = new uint256[](
            (arrayOfBytesLength - 1) / 32 + 1
        );
        uint256 workingWord = 0;
        for (uint256 i = 0; i < arrayOfBytesLength; ) {
            // OR workingWord with this byte shifted by byte within the word
            workingWord |= uint256(arrayOfBytes[i]) << (8 * (31 - (i % 32)));

            // if we're on the last byte of the word, store in array
            if (i % 32 == 31) {
                uint256 j = i / 32;
                packed[j] = workingWord;
                workingWord = 0;
            }
            unchecked {
                ++i;
            }
        }
        if (arrayOfBytesLength % 32 != 0) {
            packed[packed.length - 1] = workingWord;
        }

        return packed;
    }

    /// @dev less efficient logic for unpacking >1 uint256s into >32 byte values
    function unpackByteArrays(uint256[] memory packedByteArrays)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256 packedByteArraysLength = packedByteArrays.length;
        uint256[] memory unpacked = new uint256[](packedByteArraysLength * 32);
        for (uint256 i = 0; i < packedByteArraysLength; ) {
            uint256 packedByteArray = packedByteArrays[i];
            uint256 j = 0;
            for (; j < 32; ) {
                uint256 unpackedByte = getPackedByteFromLeft(
                    j,
                    packedByteArray
                );
                if (unpackedByte == 0) {
                    break;
                }
                unpacked[i * 32 + j] = unpackedByte;
                unchecked {
                    ++j;
                }
            }
            if (j < 32) {
                break;
            }
            unchecked {
                ++i;
            }
        }
        return unpacked;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '../interface/Constants.sol';

library BitMapUtility {
    /**
     * @notice Convert a byte value into a bitmap, where the bit at position val is set to 1, and all others 0
     * @param  val byte value to convert to bitmap
     * @return bitmap of val
     */
    function toBitMap(uint256 val) internal pure returns (uint256 bitmap) {
        /// @solidity memory-safe-assembly
        assembly {
            bitmap := shl(val, 1)
        }
    }

    /**
     * @notice get the intersection of two bitMaps by ANDing them together
     * @param  target first bitmap
     * @param  test second bitmap
     * @return result bitmap with only bits active in both bitmaps set to 1
     */
    function intersect(uint256 target, uint256 test)
        internal
        pure
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := and(target, test)
        }
    }

    /**
     * @notice check if bitmap has byteVal set to 1
     * @param  target first bitmap
     * @param  byteVal bit position to check in target
     * @return result true if bitmap contains byteVal
     */
    function contains(uint256 target, uint256 byteVal)
        internal
        pure
        returns (bool result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := and(shr(byteVal, target), 1)
        }
    }

    /**
     * @notice check if union of two bitmaps is equal to the first
     * @param  superset first bitmap
     * @param  subset second bitmap
     * @return result true if superset is a superset of subset, false otherwise
     */
    function isSupersetOf(uint256 superset, uint256 subset)
        internal
        pure
        returns (bool result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := eq(superset, or(superset, subset))
        }
    }

    /**
     * @notice unpack a bitmap into an array of included byte values
     * @param  bitMap bitMap to unpack into byte values
     * @return unpacked array of byte values included in bitMap, sorted from smallest to largest
     */
    function unpackBitMap(uint256 bitMap)
        internal
        pure
        returns (uint256[] memory unpacked)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(bitMap) {
                let freePtr := mload(0x40)
                mstore(0x40, add(freePtr, 0x20))
                return(freePtr, 0x20)
            }
            function lsb(x) -> r {
                x := and(x, add(not(x), 1))
                r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
                r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
                r := or(r, shl(5, lt(0xffffffff, shr(r, x))))

                x := shr(r, x)
                x := or(x, shr(1, x))
                x := or(x, shr(2, x))
                x := or(x, shr(4, x))
                x := or(x, shr(8, x))
                x := or(x, shr(16, x))

                r := or(
                    r,
                    byte(
                        and(31, shr(27, mul(x, 0x07C4ACDD))),
                        0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f
                    )
                )
            }

            // set unpacked ptr to free mem
            unpacked := mload(0x40)
            // get ptr to first index of array
            let unpackedIndexPtr := add(unpacked, 0x20)

            let numLayers
            for {

            } bitMap {
                unpackedIndexPtr := add(unpackedIndexPtr, 0x20)
            } {
                // store the index of the lsb at the index in the array
                mstore(unpackedIndexPtr, lsb(bitMap))
                // drop the lsb from the bitMap
                bitMap := and(bitMap, sub(bitMap, 1))
                // increment numLayers
                numLayers := add(numLayers, 1)
            }
            // store the number of layers at the pointer to unpacked array
            mstore(unpacked, numLayers)
            // update free mem pointer to first free slot after unpacked array
            mstore(0x40, unpackedIndexPtr)
        }
    }

    /**
     * @notice pack an array of byte values into a bitmap
     * @param  uints array of byte values to pack into bitmap
     * @return bitMap of byte values
     */
    function uintsToBitMap(uint256[] memory uints)
        internal
        pure
        returns (uint256 bitMap)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // get pointer to first index of array
            let uintsIndexPtr := add(uints, 0x20)
            // get pointer to first word after final index of array
            let finalUintsIndexPtr := add(uintsIndexPtr, shl(5, mload(uints)))
            // loop until we reach the end of the array
            for {

            } lt(uintsIndexPtr, finalUintsIndexPtr) {
                uintsIndexPtr := add(uintsIndexPtr, 0x20)
            } {
                // set the bit at left-index 'uint' to 1
                bitMap := or(bitMap, shl(mload(uintsIndexPtr), 1))
            }
        }
    }

    /**
     * @notice Finds the zero-based index of the first one (right-indexed) in the binary representation of x.
     * @param x The uint256 number for which to find the index of the most significant bit.
     * @return r The index of the most significant bit as an uint256.
     * from: https://gist.github.com/Vectorized/6e5d4271162c931988b385f1fd5a298f
     */
    function msb(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))

            x := shr(r, x)
            x := or(x, shr(1, x))
            x := or(x, shr(2, x))
            x := or(x, shr(4, x))
            x := or(x, shr(8, x))
            x := or(x, shr(16, x))

            r := or(
                r,
                byte(
                    and(31, shr(27, mul(x, 0x07C4ACDD))),
                    0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f
                )
            )
        }
    }

    /**
     * @notice Finds the zero-based index of the first one (left-indexed) in the binary representation of x
     * @param x The uint256 number for which to find the index of the least significant bit.
     * @return r The index of the least significant bit as an uint256.
     * from: // from https://gist.github.com/Atarpara/d6d3773d0ce8958b95804fd36981825f

     */
    function lsb(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            x := and(x, add(not(x), 1))
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))

            x := shr(r, x)
            x := or(x, shr(1, x))
            x := or(x, shr(2, x))
            x := or(x, shr(4, x))
            x := or(x, shr(8, x))
            x := or(x, shr(16, x))

            r := or(
                r,
                byte(
                    and(31, shr(27, mul(x, 0x07C4ACDD))),
                    0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f
                )
            )
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILayerable {
    function getLayerImageURI(uint256 layerId)
        external
        view
        returns (string memory);

    function getLayeredTokenImageURI(uint256[] calldata activeLayers)
        external
        view
        returns (string memory);

    function getBoundLayerTraits(uint256 bindings)
        external
        view
        returns (string memory);

    function getActiveLayerTraits(uint256[] calldata activeLayers)
        external
        view
        returns (string memory);

    function getBoundAndActiveLayerTraits(
        uint256 bindings,
        uint256[] calldata activeLayers
    ) external view returns (string memory);

    function getTokenURI(
        uint256 tokenId,
        uint256 layerId,
        uint256 bindings,
        uint256[] calldata activeLayers,
        bytes32 layerSeed
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {BAD_DISTRIBUTIONS_SIGNATURE} from '../interface/Constants.sol';
import {BadDistributions, InvalidLayerType, ArrayLengthMismatch, BatchNotRevealed} from '../interface/Errors.sol';
import {BatchVRFConsumer} from '../vrf/BatchVRFConsumer.sol';

abstract contract RandomTraits is BatchVRFConsumer {
    // 32 possible traits per layerType given uint16 distributions
    // except final trait type, which has 31, because 0 is not a valid layerId.
    // Function getLayerId will check if layerSeed is less than the distribution,
    // so traits distribution cutoffs should be sorted left-to-right
    // ie smallest packed 16-bit segment should be the leftmost 16 bits
    // TODO: does this mean for N < 32 traits, there should be N-1 distributions?
    mapping(uint8 => uint256[2]) layerTypeToPackedDistributions;

    constructor(
        string memory name,
        string memory symbol,
        address vrfCoordinatorAddress,
        uint240 maxNumSets,
        uint8 numTokensPerSet,
        uint64 subscriptionId,
        uint8 numRandomBatches,
        bytes32 keyHash
    )
        BatchVRFConsumer(
            name,
            symbol,
            vrfCoordinatorAddress,
            maxNumSets,
            numTokensPerSet,
            subscriptionId,
            numRandomBatches,
            keyHash
        )
    {}

    /////////////
    // SETTERS //
    /////////////

    /**
     * @notice Set the probability distribution for up to 32 different layer traitIds
     * @param layerType layer type to set distribution for
     * @param distribution a uint256[2] comprised of sorted, packed shorts
     *  that will be compared against a random short to determine the layerId
     *  for a given tokenId
     */
    function setLayerTypeDistribution(
        uint8 layerType,
        uint256[2] calldata distribution
    ) public virtual onlyOwner {
        _setLayerTypeDistribution(layerType, distribution);
    }

    /**
     * @notice Set layer type distributions for multiple layer types
     * @param layerTypes layer types to set distribution for
     * @param distributions an array of uint256[2]s comprised of sorted, packed shorts
     *  that will be compared against a random short to determine the layerId
     *  for a given tokenId
     */
    function setLayerTypeDistributions(
        uint8[] calldata layerTypes,
        uint256[2][] calldata distributions
    ) public virtual onlyOwner {
        if (layerTypes.length != distributions.length) {
            revert ArrayLengthMismatch(layerTypes.length, distributions.length);
        }
        for (uint8 i = 0; i < layerTypes.length; i++) {
            _setLayerTypeDistribution(layerTypes[i], distributions[i]);
        }
    }

    /**
     * @notice calculate the 16-bit seed for a layer by hashing the packedBatchRandomness, tokenId, and layerType together
     * and truncating to 16 bits
     * @param tokenId tokenId to get seed for
     * @param layerType layer type to get seed for
     * @param seed packedBatchRandomness
     * @return layerSeed - 16-bit seed for the given tokenId and layerType
     */
    function getLayerSeed(
        uint256 tokenId,
        uint8 layerType,
        bytes32 seed
    ) internal pure returns (uint16 layerSeed) {
        /// @solidity memory-safe-assembly
        assembly {
            // store seed in first slot of scratch memory
            mstore(0x00, seed)
            // pack tokenId and layerType into one 32-byte slot by shifting tokenId to the left 1 byte
            // tokenIds are sequential and MAX_NUM_SETS * NUM_TOKENS_PER_SET is guaranteed to be < 2**248
            let combinedIdType := or(shl(8, tokenId), layerType)
            mstore(0x20, combinedIdType)
            layerSeed := keccak256(0x00, 0x40)
        }
    }

    /**
     * @notice Determine layer type by its token ID
     */
    function getLayerType(uint256 tokenId)
        public
        view
        virtual
        returns (uint8 layerType);

    /**
     * @notice Get the layerId for a given tokenId by hashing tokenId with its layer type and random seed,
     * and then comparing the final short against the appropriate distributions
     */
    function getLayerId(uint256 tokenId) public view virtual returns (uint256) {
        return
            getLayerId(
                tokenId,
                getRandomnessForTokenIdFromSeed(tokenId, packedBatchRandomness)
            );
    }

    /**
     * @dev perform fewer SLOADs by passing seed as parameter
     */
    function getLayerId(uint256 tokenId, bytes32 seed)
        internal
        view
        virtual
        returns (uint256)
    {
        if (seed == 0) {
            revert BatchNotRevealed();
        }
        uint8 layerType = getLayerType(tokenId);
        uint256 layerSeed = getLayerSeed(tokenId, layerType, seed);
        uint256[2] storage distributions = layerTypeToPackedDistributions[
            layerType
        ];
        return getLayerId(layerType, layerSeed, distributions);
    }

    /**
     * @notice calculate the layerId for a given layerType, seed, and distributions.
     * @param layerType of layer
     * @param layerSeed uint256 random seed for layer (in practice will be truncated to 8 bits)
     * @param distributionsArray uint256[2] packed distributions of layerIds
     * @return layerId limited to 8 bits
     *
     * @dev If the last packed short is <65535, any seed larger than the last packed short
     *      will be assigned to the index after the last packed short, unless the last
     *      packed short is index 31, in which case, it will default to 31.
     *      LayerId is calculated like: index + 1 + 32 * layerType
     *
     * examples:
     * LayerSeed: 0x00
     * Distributions: [01 02 03 04 05 06 07 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00]
     * Calculated index: 0 (LayerId: 0 + 1 + 32 * layerType)
     *
     * LayerSeed: 0x01
     * Distributions: [01 02 03 04 05 06 07 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00]
     * Calculated index: 1 (LayerId: 1 + 1 + 32 * layerType)
     *
     * LayerSeed: 0xFF
     * Distributions: [01 02 03 04 05 06 07 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00]
     * Calculated index: 7 (LayerId: 7 + 1 + 32 * layerType)
     *
     * LayerSeed: 0xFF
     * Distributions: [01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f 20]
     * Calculated index: 31 (LayerId: 31 + 1 + 32 * layerType)
     */
    function getLayerId(
        uint8 layerType,
        uint256 layerSeed,
        uint256[2] storage distributionsArray
    ) internal view returns (uint256 layerId) {
        /// @solidity memory-safe-assembly
        assembly {
            function revertWithBadDistributions() {
                mstore(0, BAD_DISTRIBUTIONS_SIGNATURE)
                revert(0, 4)
            }
            function getPackedShortFromLeft(index, packed) -> short {
                let shortOffset := sub(240, shl(4, index))
                short := shr(shortOffset, packed)
                short := and(short, 0xffff)
            }

            let j
            // declare i outside of loop in case final distribution val is less than seed
            let i
            let jOffset
            let indexOffset

            // iterate over distribution values until we find one that our layer seed is less than
            for {

            } lt(j, 2) {
                j := add(1, j)
                indexOffset := add(indexOffset, 0x20)
                i := 0
            } {
                // lazily load each half of distributions from storage, since we might not need the second half
                let distributions := sload(add(distributionsArray.slot, j))
                jOffset := shl(4, j)

                for {

                } lt(i, 16) {
                    i := add(1, i)
                } {
                    let dist := getPackedShortFromLeft(i, distributions)
                    if iszero(dist) {
                        if iszero(i) {
                            if iszero(j) {
                                // first element should never be 0; distributions are invalid
                                revertWithBadDistributions()
                            }
                        }
                        // if we've reached end of distributions, check layer type != 7
                        // otherwise if layerSeed is less than the last distribution,
                        // the layerId calculation will evaluate to 256 (overflow)
                        if eq(layerType, 7) {
                            if eq(add(i, jOffset), 31) {
                                revertWithBadDistributions()
                            }
                        }
                        // if distribution is 0, and it's not the first, we've reached the end of the list
                        // return i + 1 + 32 * layerType
                        layerId := add(
                            // add 1 if j == 0
                            // add 17 if j == 1
                            add(i, add(1, jOffset)),
                            shl(5, layerType)
                        )
                        break
                    }
                    if lt(layerSeed, dist) {
                        // if i+jOffset is 31 here, math will overflow here if layerType == 7
                        // 31 + 1 + 32 * 7 = 256, which is too large for a uint8
                        if eq(layerType, 7) {
                            if eq(add(i, jOffset), 31) {
                                revertWithBadDistributions()
                            }
                        }

                        // layerIds are 1-indexed, so add 1 to i+j
                        layerId := add(
                            // add 1 if j == 0
                            // add 17 if j == 1
                            add(i, add(1, jOffset)),
                            shl(5, layerType)
                        )
                        break
                    }
                }
                // if layerId has been set, we don't need to increment j
                if gt(layerId, 0) {
                    break
                }
            }
            // if i+j is 32, we've reached the end of the list and should default to the last id
            if iszero(layerId) {
                if eq(j, 2) {
                    // math will overflow here if layerType == 7
                    // 32 + 32 * 7 = 256, which is too large for a uint8
                    if eq(layerType, 7) {
                        revertWithBadDistributions()
                    }
                    // return previous layerId
                    layerId := add(32, shl(5, layerType))
                }
            }
        }
    }

    function _setLayerTypeDistribution(
        uint8 layerType,
        uint256[2] calldata distribution
    ) internal {
        if (layerType > 7) {
            revert InvalidLayerType();
        }
        layerTypeToPackedDistributions[layerType] = distribution;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error TradingAlreadyDisabled();
error IncorrectPayment();
error ArrayLengthMismatch(uint256 length1, uint256 length2);
error LayerNotBoundToTokenId();
error DuplicateActiveLayers();
error MultipleVariationsEnabled();
error InvalidLayer(uint256 layer);
error BadDistributions();
error NotOwner();
error BatchNotRevealed();
error LayerAlreadyBound();
error CannotBindBase();
error OnlyBase();
error InvalidLayerType();
error MaxSupply();
error MaxRandomness();
error OnlyCoordinatorCanFulfill(address have, address want);
error UnsafeReveal();
error NoActiveLayers();
error InvalidInitialization();
error NumRandomBatchesMustBePowerOfTwo();
error NumRandomBatchesMustBeGreaterThanOne();
error NumRandomBatchesMustBeLessThanOrEqualTo16();
error RevealPending();
error NoBatchesToReveal();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

uint256 constant NOT_0TH_BITMASK = 2**256 - 2;
uint256 constant MAX_INT = 2**256 - 1;
uint136 constant _2_128 = 2**128;
uint72 constant _2_64 = 2**64;
uint40 constant _2_32 = 2**32;
uint24 constant _2_16 = 2**16;
uint16 constant _2_8 = 2**8;
uint8 constant _2_4 = 2**4;
uint8 constant _2_2 = 2**2;
uint8 constant _2_1 = 2**1;

uint128 constant _128_MASK = 2**128 - 1;
uint64 constant _64_MASK = 2**64 - 1;
uint32 constant _32_MASK = 2**32 - 1;
uint16 constant _16_MASK = 2**16 - 1;
uint8 constant _8_MASK = 2**8 - 1;
uint8 constant _4_MASK = 2**4 - 1;
uint8 constant _2_MASK = 2**2 - 1;
uint8 constant _1_MASK = 2**1 - 1;

bytes4 constant DUPLICATE_ACTIVE_LAYERS_SIGNATURE = 0x6411ce75;
bytes4 constant LAYER_NOT_BOUND_TO_TOKEN_ID_SIGNATURE = 0xa385f805;
bytes4 constant BAD_DISTRIBUTIONS_SIGNATURE = 0x338096f7;
bytes4 constant MULTIPLE_VARIATIONS_ENABLED_SIGNATURE = 0x4d2e9396;
bytes4 constant BATCH_NOT_REVEALED_SIGNATURE = 0x729b0f75;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface BoundLayerableEvents {
    event LayersBoundToToken(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed boundLayersBitmap
    );

    event ActiveLayersChanged(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed activeLayersBytearray
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {ConstructorInitializable} from "./ConstructorInitializable.sol";

/**
@notice A two-step extension of Ownable, where the new owner must claim ownership of the contract after owner initiates transfer
Owner can cancel the transfer at any point before the new owner claims ownership.
Helpful in guarding against transferring ownership to an address that is unable to act as the Owner.
*/
abstract contract TwoStepOwnable is ConstructorInitializable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    address internal potentialOwner;

    event PotentialOwnerUpdated(address newPotentialAdministrator);

    error NewOwnerIsZeroAddress();
    error NotNextOwner();
    error OnlyOwner();

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    constructor() {
        _initialize();
    }

    function _initialize() private onlyConstructor {
        _transferOwnership(msg.sender);
    }

    ///@notice Initiate ownership transfer to newPotentialOwner. Note: new owner will have to manually acceptOwnership
    ///@param newPotentialOwner address of potential new owner
    function transferOwnership(address newPotentialOwner)
        public
        virtual
        onlyOwner
    {
        if (newPotentialOwner == address(0)) {
            revert NewOwnerIsZeroAddress();
        }
        potentialOwner = newPotentialOwner;
        emit PotentialOwnerUpdated(newPotentialOwner);
    }

    ///@notice Claim ownership of smart contract, after the current owner has initiated the process with transferOwnership
    function acceptOwnership() public virtual {
        address _potentialOwner = potentialOwner;
        if (msg.sender != _potentialOwner) {
            revert NotNextOwner();
        }
        delete potentialOwner;
        emit PotentialOwnerUpdated(address(0));
        _transferOwnership(_potentialOwner);
    }

    ///@notice cancel ownership transfer
    function cancelOwnershipTransfer() public virtual onlyOwner {
        delete potentialOwner;
        emit PotentialOwnerUpdated(address(0));
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (_owner != msg.sender) {
            revert OnlyOwner();
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

///@notice Ownable helper contract to withdraw ether or tokens from the contract address balance
interface IWithdrawable {
    function withdraw() external;

    function withdrawERC20(address _tokenAddress) external;

    function withdrawERC721(address _tokenAddress, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {VRFConsumerBaseV2} from 'chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import {VRFCoordinatorV2Interface} from 'chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import {TwoStepOwnable} from 'utility-contracts/TwoStepOwnable.sol';
import {ERC721A} from '../token/ERC721A.sol';
import {_32_MASK, BATCH_NOT_REVEALED_SIGNATURE} from '../interface/Constants.sol';
import {MaxRandomness, NumRandomBatchesMustBeLessThanOrEqualTo16, NoBatchesToReveal, RevealPending, OnlyCoordinatorCanFulfill, UnsafeReveal, NumRandomBatchesMustBePowerOfTwo, NumRandomBatchesMustBeGreaterThanOne} from '../interface/Errors.sol';
import {BitMapUtility} from '../lib/BitMapUtility.sol';
import {PackedByteUtility} from '../lib/PackedByteUtility.sol';

contract BatchVRFConsumer is ERC721A, TwoStepOwnable {
    // VRF config
    uint256 public immutable NUM_RANDOM_BATCHES;
    uint256 public immutable BITS_PER_RANDOM_BATCH;
    uint256 immutable BITS_PER_BATCH_SHIFT;
    uint256 immutable BATCH_RANDOMNESS_MASK;

    uint16 constant NUM_CONFIRMATIONS = 7;
    uint32 constant CALLBACK_GAS_LIMIT = 500_000;
    uint64 public subscriptionId;
    VRFCoordinatorV2Interface public coordinator;

    // token config
    // use uint240 to ensure tokenId can never be > 2**248 for efficient hashing
    uint240 immutable MAX_NUM_SETS;
    uint8 immutable NUM_TOKENS_PER_SET;
    uint248 immutable NUM_TOKENS_PER_RANDOM_BATCH;
    uint256 immutable MAX_TOKEN_ID;

    bytes32 public packedBatchRandomness;
    uint248 revealBatch;
    bool public pendingReveal;
    bytes32 public keyHash;

    // allow unsafe revealing of an uncompleted batch, ie, in the case of a stalled mint
    bool forceUnsafeReveal;

    constructor(
        string memory name,
        string memory symbol,
        address vrfCoordinatorAddress,
        uint240 maxNumSets,
        uint8 numTokensPerSet,
        uint64 _subscriptionId,
        uint8 numRandomBatches,
        bytes32 _keyHash
    ) ERC721A(name, symbol) {
        if (numRandomBatches < 2) {
            revert NumRandomBatchesMustBeGreaterThanOne();
        } else if (numRandomBatches > 16) {
            revert NumRandomBatchesMustBeLessThanOrEqualTo16();
        }
        // store immutables to allow for configurable number of random batches
        // (which must be a power of two), with inversely proportional amounts of
        // entropy per batch.
        // 16 batches (16 bits of entropy per batch) is the max recommended
        // 2 batches is the minimum
        NUM_RANDOM_BATCHES = numRandomBatches;
        BITS_PER_RANDOM_BATCH = uint8(uint256(256) / NUM_RANDOM_BATCHES);
        BITS_PER_BATCH_SHIFT = uint8(
            BitMapUtility.msb(uint256(BITS_PER_RANDOM_BATCH))
        );
        bool powerOfTwo = uint256(BITS_PER_RANDOM_BATCH) *
            uint256(NUM_RANDOM_BATCHES) ==
            256;
        if (!powerOfTwo) {
            revert NumRandomBatchesMustBePowerOfTwo();
        }
        BATCH_RANDOMNESS_MASK = ((1 << BITS_PER_RANDOM_BATCH) - 1);

        MAX_NUM_SETS = maxNumSets;
        NUM_TOKENS_PER_SET = numTokensPerSet;

        // ensure that the last batch includes the very last token ids
        uint248 numSetsPerRandomBatch = uint248(MAX_NUM_SETS) /
            uint248(NUM_RANDOM_BATCHES);
        uint256 recoveredNumSets = (numSetsPerRandomBatch * NUM_RANDOM_BATCHES);
        if (recoveredNumSets != MAX_NUM_SETS) {
            ++numSetsPerRandomBatch;
        }
        // use numSetsPerRandomBatch to calculate the number of tokens per batch
        // to avoid revealing only some tokens in a set
        NUM_TOKENS_PER_RANDOM_BATCH =
            numSetsPerRandomBatch *
            NUM_TOKENS_PER_SET;

        MAX_TOKEN_ID =
            _startTokenId() +
            uint256(MAX_NUM_SETS) *
            uint256(NUM_TOKENS_PER_SET) -
            1;

        coordinator = VRFCoordinatorV2Interface(vrfCoordinatorAddress);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
    }

    /**
     * @notice when true, allow revealing the rest of a batch that has not completed minting yet
     *         This is "unsafe" because it becomes possible to know the layerIds of unminted tokens from the batch
     */
    function setForceUnsafeReveal(bool force) external onlyOwner {
        forceUnsafeReveal = force;
    }

    /**
     * @notice set the key hash corresponding to a max gas price for a chainlink VRF request,
     *         to be used in requestRandomWords()
     */
    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    /**
     * @notice set the ChainLink VRF Subscription ID
     */
    function setSubscriptionId(uint64 _subscriptionId) external onlyOwner {
        subscriptionId = _subscriptionId;
    }

    /**
     * @notice set the ChainLink VRF Coordinator address
     */
    function setCoordinator(address _coordinator) external onlyOwner {
        coordinator = VRFCoordinatorV2Interface(_coordinator);
    }

    /**
     * @notice Clear the pending reveal flag, allowing requestRandomWords() to be called again
     */
    function clearPendingReveal() external onlyOwner {
        pendingReveal = false;
    }

    /**
     * @notice request random words from the chainlink vrf for each unrevealed batch
     */
    function requestRandomWords() external returns (uint256) {
        if (pendingReveal) {
            revert RevealPending();
        }
        (uint32 numBatches, ) = _checkAndReturnNumBatches();
        if (numBatches == 0) {
            revert NoBatchesToReveal();
        }

        // Will revert if subscription is not set and funded.
        uint256 _pending = coordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            NUM_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            1
        );
        pendingReveal = true;
        return _pending;
    }

    /**
     * @notice get the random seed of the batch that a given token ID belongs to
     */
    function getRandomnessForTokenId(uint256 tokenId)
        internal
        view
        returns (bytes32 randomness)
    {
        return getRandomnessForTokenIdFromSeed(tokenId, packedBatchRandomness);
    }

    /**
     * @notice Get the randomness for a given tokenId, if it's been set
     * @param tokenId tokenId of the token to get the randomness for
     * @param seed bytes32 seed containing all batches randomness
     * @return randomness as bytes32 for the given tokenId
     */
    function getRandomnessForTokenIdFromSeed(uint256 tokenId, bytes32 seed)
        internal
        view
        returns (bytes32 randomness)
    {
        // put immutable variable onto stack
        uint256 numTokensPerRandomBatch = NUM_TOKENS_PER_RANDOM_BATCH;
        uint256 shift = BITS_PER_BATCH_SHIFT;
        uint256 mask = BATCH_RANDOMNESS_MASK;

        /// @solidity memory-safe-assembly
        assembly {
            // use mask to get last N bits of shifted packedBatchRandomness
            randomness := and(
                // shift packedBatchRandomness right by batchNum * bits per batch
                shr(
                    // get batch number of token, multiply by bits per batch
                    shl(shift, div(tokenId, numTokensPerRandomBatch)),
                    seed
                ),
                mask
            )
        }
    }

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        if (msg.sender != address(coordinator)) {
            revert OnlyCoordinatorCanFulfill(msg.sender, address(coordinator));
        }
        fulfillRandomWords(requestId, randomWords);
    }

    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param
     * @param randomWords the VRF output expanded to the requested number of words
     */
    function fulfillRandomWords(uint256, uint256[] memory randomWords)
        internal
        virtual
    {
        (uint32 numBatches, uint32 _revealBatch) = _checkAndReturnNumBatches();
        uint256 currSeed = uint256(packedBatchRandomness);
        uint256 randomness = randomWords[0];

        // we have revealed N batches; mask the bottom bits out
        uint256 mask;
        uint256 bitShift = BITS_PER_RANDOM_BATCH * _revealBatch;
        //  solidity will overflow and throw arithmetic error without this check
        if (bitShift != 256) {
            // will be 0 if bitshift == 256 (and would not overflow)
            mask = type(uint256).max ^ ((1 << bitShift) - 1);
        }
        // we need only need to reveal up to M batches; mask the top bits out
        bitShift = (BITS_PER_RANDOM_BATCH * (numBatches + _revealBatch));
        if (bitShift != 256) {
            mask = mask & ((1 << bitShift) - 1);
        }

        uint256 newRandomness = randomness & mask;
        currSeed = currSeed | newRandomness;

        _revealBatch += numBatches;

        // coerce any 0-slots to 1
        for (uint256 i; i < numBatches; ) {
            uint256 retrievedRandomness = PackedByteUtility.getPackedNFromRight(
                uint256(currSeed),
                BITS_PER_RANDOM_BATCH,
                i
            );
            if (retrievedRandomness == 0) {
                currSeed = PackedByteUtility.packNAtRightIndex(
                    uint256(currSeed),
                    BITS_PER_RANDOM_BATCH,
                    1,
                    i
                );
            }
            unchecked {
                ++i;
            }
        }

        packedBatchRandomness = bytes32(currSeed);
        revealBatch = _revealBatch;
        pendingReveal = false;
    }

    /**
     * @notice calculate how many batches need to be revealed, and also get next batch number
     * @return (uint32 numMissingBatches, uint32 _revealBatch) - number missing batches, and the current _revealBatch
     *         index (current batch revealed + 1, or 0 if none)
     */
    function _checkAndReturnNumBatches()
        internal
        view
        returns (uint32, uint32)
    {
        // get next unminted token ID
        uint256 nextTokenId_ = _nextTokenId();
        // get number of fully completed batches
        uint256 numCompletedBatches = nextTokenId_ /
            NUM_TOKENS_PER_RANDOM_BATCH;

        // if NUM_TOKENS_PER_RANDOM_BATCH doesn't divide evenly into total number of tokens,
        // increment the numCompleted batches if the next token ID is greater than the max
        // ie, the very last batch is completed
        // NUM_TOKENS_PER_RANDOM_BATCH * NUM_RANDOM_BATCHES / NUM_TOKENS_PER_SET will always
        // either be greater than or equal to MAX_NUM_SETS, never less-than
        bool unevenBatches = ((NUM_TOKENS_PER_RANDOM_BATCH *
            NUM_RANDOM_BATCHES) / NUM_TOKENS_PER_SET) != MAX_NUM_SETS;
        if (unevenBatches && nextTokenId_ > MAX_TOKEN_ID) {
            ++numCompletedBatches;
        }

        uint32 _revealBatch = uint32(revealBatch);
        // reveal is complete if _revealBatch is >= 8
        if (_revealBatch >= NUM_RANDOM_BATCHES) {
            revert MaxRandomness();
        }

        // if equal, next batch has not started minting yet
        bool batchIsInProgress = nextTokenId_ >
            numCompletedBatches * NUM_TOKENS_PER_RANDOM_BATCH &&
            numCompletedBatches != NUM_RANDOM_BATCHES;
        bool batchInProgressAlreadyRevealed = _revealBatch >
            numCompletedBatches;
        uint32 numMissingBatches = batchInProgressAlreadyRevealed
            ? 0
            : uint32(numCompletedBatches) - _revealBatch;

        // don't ever reveal batches from which no tokens have been minted
        if (
            batchInProgressAlreadyRevealed ||
            (numMissingBatches == 0 && !batchIsInProgress)
        ) {
            revert UnsafeReveal();
        }
        // increment if batch is in progress
        if (batchIsInProgress && forceUnsafeReveal) {
            ++numMissingBatches;
        }

        return (numMissingBatches, _revealBatch);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * @author emo.eth
 * @notice Abstract smart contract that provides an onlyUninitialized modifier which only allows calling when
 *         from within a constructor of some sort, whether directly instantiating an inherting contract,
 *         or when delegatecalling from a proxy
 */
abstract contract ConstructorInitializable {
    error AlreadyInitialized();

    modifier onlyConstructor() {
        if (address(this).code.length != 0) {
            revert AlreadyInitialized();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}