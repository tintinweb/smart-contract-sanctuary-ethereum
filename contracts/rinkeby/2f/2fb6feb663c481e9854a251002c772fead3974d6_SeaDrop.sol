// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { ISeaDrop } from "./interfaces/ISeaDrop.sol";

import {
    AllowListData,
    Conduit,
    MintParams,
    PaymentValidation,
    PublicDrop,
    TokenGatedDropStage,
    TokenGatedMintParams
} from "./lib/SeaDropStructs.sol";

import { IERC721SeaDrop } from "./interfaces/IERC721SeaDrop.sol";

import { ERC20, SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";

import { MerkleProofLib } from "solady/utils/MerkleProofLib.sol";

import {
    IERC721
} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {
    IERC165
} from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

import {
    ECDSA
} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import { ConduitTransfer } from "seaport/conduit/lib/ConduitStructs.sol";

import { ConduitItemType } from "seaport/conduit/lib/ConduitEnums.sol";

import {
    ConduitControllerInterface
} from "seaport/interfaces/ConduitControllerInterface.sol";

import { ConduitInterface } from "seaport/interfaces/ConduitInterface.sol";

contract SeaDrop is ISeaDrop {
    using ECDSA for bytes32;

    // Track the public drops.
    mapping(address => PublicDrop) private _publicDrops;

    // Track the drop URIs.
    mapping(address => string) private _dropURIs;

    // Track the sale tokens.
    mapping(address => ERC20) private _saleTokens;

    // Track the creator payout addresses.
    mapping(address => address) private _creatorPayoutAddresses;

    // Track the allow list merkle roots.
    mapping(address => bytes32) private _allowListMerkleRoots;

    // Track the allowed fee recipients.
    mapping(address => mapping(address => bool)) private _allowedFeeRecipients;

    // Track the allowed signers for server side drops.
    mapping(address => mapping(address => bool)) private _signers;

    // Track the signers for each server side drop.
    mapping(address => address[]) private _enumeratedSigners;

    // Track token gated drop stages.
    mapping(address => mapping(address => TokenGatedDropStage))
        private _tokenGatedDrops;

    // Track the tokens for token gated drops.
    mapping(address => address[]) private _enumeratedTokenGatedTokens;

    // Track redeemed token IDs for token gated drop stages.
    mapping(address => mapping(address => mapping(uint256 => bool)))
        private _tokenGatedRedeemed;

    // EIP-712: Typed structured data hashing and signing
    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public immutable MINT_DATA_TYPEHASH;

    /**
     * @notice Ensure only tokens implementing IERC721SeaDrop can
     *         call the update methods.
     */
    modifier onlyIERC721SeaDrop() virtual {
        if (
            !IERC165(msg.sender).supportsInterface(
                type(IERC721SeaDrop).interfaceId
            )
        ) {
            revert OnlyIERC721SeaDrop(msg.sender);
        }
        _;
    }

    /**
     * @notice Constructor for the contract deployment.
     */
    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("SeaDrop")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        MINT_DATA_TYPEHASH = keccak256(
            "MintParams(address minter, uint256 mintPrice, uint256 maxTotalMintableByWallet, uint256 startTime, uint256 endTime, uint256 dropStageIndex, uint256 feeBps, bool restrictFeeRecipients)"
        );
    }

    /**
     * @notice Mint a public drop.
     *
     * @param nftContract The nft contract to mint.
     * @param feeRecipient The fee recipient.
     * @param numToMint The number of tokens to mint.
     * @param conduit If paying with an ERC20 token,
     *                optionally specify a conduit to use.
     */
    function mintPublic(
        address nftContract,
        address feeRecipient,
        uint256 numToMint,
        Conduit calldata conduit
    ) external payable override {
        // Get the public drop data.
        PublicDrop memory publicDrop = _publicDrops[nftContract];

        // Ensure that the drop has started.
        if (block.timestamp < publicDrop.startTime) {
            revert NotActive(
                block.timestamp,
                publicDrop.startTime,
                type(uint64).max
            );
        }

        // Validate correct payment.
        address conduitAddress;
        // Use the conduit if provided.
        if (conduit.conduitController != address(0)) {
            conduitAddress = _getConduit(conduit);
        }
        PaymentValidation[] memory payments = new PaymentValidation[](1);
        payments[0] = PaymentValidation(numToMint, publicDrop.mintPrice);
        _checkCorrectPayment(nftContract, payments, conduitAddress);

        // Check that the wallet is allowed to mint the desired quantity.
        _checkNumberToMint(
            nftContract,
            numToMint,
            publicDrop.maxMintsPerWallet,
            0
        );

        // Check that the fee recipient is allowed if restricted.
        _checkFeeRecipientIsAllowed(
            nftContract,
            feeRecipient,
            publicDrop.restrictFeeRecipients
        );

        // Split the payout, mint the token, emit an event.
        _payAndMint(
            nftContract,
            numToMint,
            publicDrop.mintPrice,
            0,
            publicDrop.feeBps,
            feeRecipient,
            conduitAddress
        );
    }

    /**
     * @notice Mint from an allow list.
     *
     * @param nftContract The nft contract to mint.
     * @param feeRecipient The fee recipient.
     * @param numToMint The number of tokens to mint.
     * @param mintParams The mint parameters.
     * @param proof The proof for the leaf of the allow list.
     * @param conduit If paying with an ERC20 token,
     *                optionally specify a conduit to use.
     */
    function mintAllowList(
        address nftContract,
        address feeRecipient,
        uint256 numToMint,
        MintParams calldata mintParams,
        bytes32[] calldata proof,
        Conduit calldata conduit
    ) external payable override {
        // Check that the drop stage is active.
        _checkActive(mintParams.startTime, mintParams.endTime);

        // Validate correct payment.
        address conduitAddress;
        // Use the conduit if provided.
        if (conduit.conduitController != address(0)) {
            conduitAddress = _getConduit(conduit);
        }
        PaymentValidation[] memory payments = new PaymentValidation[](1);
        payments[0] = PaymentValidation(numToMint, mintParams.mintPrice);
        _checkCorrectPayment(nftContract, payments, conduitAddress);

        // Check that the wallet is allowed to mint the desired quantity.
        _checkNumberToMint(
            nftContract,
            numToMint,
            mintParams.maxTotalMintableByWallet,
            mintParams.maxTokenSupplyForStage
        );

        // Check that the fee recipient is allowed if restricted.
        _checkFeeRecipientIsAllowed(
            nftContract,
            feeRecipient,
            mintParams.restrictFeeRecipients
        );

        // Verify the proof.
        if (
            !MerkleProofLib.verify(
                proof,
                _allowListMerkleRoots[nftContract],
                keccak256(abi.encode(msg.sender, mintParams))
            )
        ) {
            revert InvalidProof();
        }

        // Split the payout, mint the token, emit an event.
        _payAndMint(
            nftContract,
            numToMint,
            mintParams.mintPrice,
            mintParams.dropStageIndex,
            mintParams.feeBps,
            feeRecipient,
            conduitAddress
        );
    }

    /**
     * @notice Mint with a server side signature.
     *
     * @param nftContract The nft contract to mint.
     * @param feeRecipient The fee recipient.
     * @param numToMint The number of tokens to mint.
     * @param mintParams The mint parameters.
     * @param signature The server side signature, must be an allowed signer.
     * @param conduit If paying with an ERC20 token,
     *                optionally specify a conduit to use.
     */
    function mintSigned(
        address nftContract,
        address feeRecipient,
        uint256 numToMint,
        MintParams calldata mintParams,
        bytes calldata signature,
        Conduit calldata conduit
    ) external payable override {
        // Check that the drop stage is active.
        _checkActive(mintParams.startTime, mintParams.endTime);

        // Validate correct payment.
        address conduitAddress;
        // Use the conduit if provided.
        if (conduit.conduitController != address(0)) {
            conduitAddress = _getConduit(conduit);
        }
        PaymentValidation[] memory payments = new PaymentValidation[](1);
        payments[0] = PaymentValidation(numToMint, mintParams.mintPrice);
        _checkCorrectPayment(nftContract, payments, conduitAddress);

        // Check that the wallet is allowed to mint the desired quantity.
        _checkNumberToMint(
            nftContract,
            numToMint,
            mintParams.maxTotalMintableByWallet,
            mintParams.maxTokenSupplyForStage
        );

        // Check that the fee recipient is allowed if restricted.
        _checkFeeRecipientIsAllowed(
            nftContract,
            feeRecipient,
            mintParams.restrictFeeRecipients
        );

        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.
        bytes32 digest = keccak256(
            abi.encodePacked(
                bytes2(0x1901),
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(MINT_DATA_TYPEHASH, msg.sender, mintParams)
                )
            )
        );

        // Use the recover method to see what address was used to create
        // the signature on this data.
        // Note that if the digest doesn't exactly match what was signed we'll
        // get a random recovered address.
        address recoveredAddress = digest.recover(signature);
        if (!_signers[nftContract][recoveredAddress]) {
            revert InvalidSignature(recoveredAddress);
        }

        // Split the payout, mint the token, emit an event.
        _payAndMint(
            nftContract,
            numToMint,
            mintParams.mintPrice,
            mintParams.dropStageIndex,
            mintParams.feeBps,
            feeRecipient,
            conduitAddress
        );
    }

    /**
     * @notice Mint as an allowed token holder.
     *         This will mark the token id as reedemed and will revert if the
     *         same token id is attempted to be redeemed twice.
     *
     * @param nftContract The nft contract to mint.
     * @param feeRecipient The fee recipient.
     * @param tokenGatedMintParams The token gated mint params.
     * @param conduit If paying with an ERC20 token,
     *                optionally specify a conduit to use.
     */
    function mintAllowedTokenHolder(
        address nftContract,
        address feeRecipient,
        TokenGatedMintParams[] calldata tokenGatedMintParams,
        Conduit calldata conduit
    ) external payable override {
        // Track total mint cost to compare against value sent with tx.
        PaymentValidation[] memory totalPayments = new PaymentValidation[](
            tokenGatedMintParams.length
        );

        address conduitAddress;
        // Use the conduit if provided.
        if (conduit.conduitController != address(0)) {
            conduitAddress = _getConduit(conduit);
        }

        // Iterate through each allowedNftToken.
        for (uint256 i = 0; i < tokenGatedMintParams.length; ) {
            // Set the mintParams to a variable.
            TokenGatedMintParams calldata mintParams = tokenGatedMintParams[i];

            // Set the dropStage to a variable.
            TokenGatedDropStage storage dropStage = _tokenGatedDrops[
                nftContract
            ][mintParams.allowedNftToken];

            // Validate that the dropStage is active.
            _checkActive(dropStage.startTime, dropStage.endTime);

            // Put the number of items to mint on the stack.
            uint256 numToMint = mintParams.allowedNftTokenIds.length;

            // Add to totalPayments.
            totalPayments[i] = PaymentValidation(
                numToMint,
                dropStage.mintPrice
            );

            // Check that the wallet is allowed to mint the desired quantity.
            _checkNumberToMint(
                nftContract,
                numToMint,
                dropStage.maxTotalMintableByWallet,
                dropStage.maxTokenSupplyForStage
            );

            // Check that the fee recipient is allowed if restricted.
            _checkFeeRecipientIsAllowed(
                nftContract,
                feeRecipient,
                dropStage.restrictFeeRecipients
            );

            // Iterate through each allowedNftTokenId
            // to ensure it is not already reedemed.
            for (uint256 j = 0; j < numToMint; ) {
                // Put the tokenId on the stack.
                uint256 tokenId = mintParams.allowedNftTokenIds[j];

                // Check that the sender is the owner of the allowedNftTokenId.
                if (
                    IERC721(mintParams.allowedNftToken).ownerOf(tokenId) !=
                    msg.sender
                ) {
                    revert TokenGatedNotTokenOwner(
                        nftContract,
                        mintParams.allowedNftToken,
                        tokenId
                    );
                }

                // Check that the token id has not already
                // been used to be redeemed.
                bool redeemed = _tokenGatedRedeemed[nftContract][
                    mintParams.allowedNftToken
                ][tokenId];

                if (redeemed == true) {
                    revert TokenGatedTokenIdAlreadyRedeemed(
                        nftContract,
                        mintParams.allowedNftToken,
                        tokenId
                    );
                }

                // Mark the token id as reedemed.
                redeemed = true;

                unchecked {
                    ++j;
                }
            }

            // Split the payout, mint the token, emit an event.
            _payAndMint(
                nftContract,
                numToMint,
                dropStage.mintPrice,
                dropStage.dropStageIndex,
                dropStage.feeBps,
                feeRecipient,
                conduitAddress
            );

            unchecked {
                ++i;
            }
        }

        // Validate correct payment.
        _checkCorrectPayment(nftContract, totalPayments, conduitAddress);
    }

    /**
     * @notice Returns the conduit address from controller and key.
     *
     * @param conduit The conduit.
     */
    function _getConduit(Conduit calldata conduit)
        internal
        view
        returns (address conduitAddress)
    {
        (conduitAddress, ) = ConduitControllerInterface(
            conduit.conduitController
        ).getConduit(conduit.conduitKey);
    }

    /**
     * @notice Check that the wallet is allowed to mint the desired quantity.
     *
     * @param numberToMint The number of tokens to mint.
     * @param maxMintsPerWallet The allowed max mints per wallet.
     * @param nftContract The nft contract.
     */
    function _checkNumberToMint(
        address nftContract,
        uint256 numberToMint,
        uint256 maxMintsPerWallet,
        uint256 maxTokenSupplyForStage
    ) internal view {
        // Get the mint stats.
        (
            uint256 minterNumMinted,
            uint256 currentTotalSupply,
            uint256 maxSupply
        ) = IERC721SeaDrop(nftContract).getMintStats(msg.sender);

        // Ensure amount doesn't exceed maxMintsPerWallet.
        if (numberToMint + minterNumMinted > maxMintsPerWallet) {
            revert AmountExceedsMaxMintedPerWallet(
                numberToMint + minterNumMinted,
                maxMintsPerWallet
            );
        }

        // Ensure amount doesn't exceed maxSupply.
        if (numberToMint + currentTotalSupply > maxSupply) {
            revert AmountExceedsMaxSupply(
                numberToMint + currentTotalSupply,
                maxSupply
            );
        }

        // Ensure amount doesn't exceed maxTokenSupplyForStage (if provided).
        if (maxTokenSupplyForStage != 0) {
            if (numberToMint + currentTotalSupply > maxTokenSupplyForStage) {
                revert AmountExceedsMaxTokenSupplyForStage(
                    numberToMint + currentTotalSupply,
                    maxTokenSupplyForStage
                );
            }
        }
    }

    /**
     * @notice Check that the fee recipient is allowed.
     *
     * @param nftContract The nft contract.
     * @param feeRecipient The fee recipient.
     * @param restrictFeeRecipients If the fee recipients are restricted.
     */
    function _checkFeeRecipientIsAllowed(
        address nftContract,
        address feeRecipient,
        bool restrictFeeRecipients
    ) internal view {
        // Ensure the fee recipient is not the zero address.
        if (feeRecipient == address(0)) {
            revert FeeRecipientCannotBeZeroAddress();
        }

        // Revert if the fee recipient is restricted and not allowed.
        if (
            restrictFeeRecipients == true &&
            _allowedFeeRecipients[nftContract][feeRecipient] == false
        ) {
            revert FeeRecipientNotAllowed();
        }
    }

    /**
     * @notice For native sale token, check that the correct payment
     *         was sent with the tx. For ERC20 sale token, check
     *         that the sender has sufficient balance and allowance.
     *
     * @param nftContract The nft contract.
     * @param payments The payments to validate.
     * @param conduitAddress If paying with an ERC20 token,
     *                       optionally specify a conduit address to use.
     */
    function _checkCorrectPayment(
        address nftContract,
        PaymentValidation[] memory payments,
        address conduitAddress
    ) internal view {
        // Keep track of the total cost of payments.
        uint256 totalCost;

        // Iterate through the payments and add to total cost.
        for (uint256 i = 0; i < payments.length; ) {
            totalCost += payments[i].numberToMint * payments[i].mintPrice;
            unchecked {
                ++i;
            }
        }

        // Retrieve the sale token.
        ERC20 saleToken = _saleTokens[nftContract];

        // The zero address means the sale token is the native token.
        if (address(saleToken) == address(0)) {
            // Revert if the tx's value doesn't match the total cost.
            if (msg.value != totalCost) {
                revert IncorrectPayment(msg.value, totalCost);
            }
        } else {
            // Revert if msg.value > 0 when payment is in a saleToken.
            if (msg.value > 0) {
                revert MsgValueNonZeroForERC20SaleToken();
            }

            // Revert if the sender does not have sufficient token balance.
            uint256 balance = saleToken.balanceOf(msg.sender);
            if (balance < totalCost) {
                revert InsufficientSaleTokenBalance(
                    address(saleToken),
                    balance,
                    totalCost
                );
            }

            // Revert if the sender does not have sufficient token allowance.
            // Use the conduit if provided.
            address allowanceFor = conduitAddress != address(0)
                ? conduitAddress
                : address(this);
            uint256 allowance = saleToken.allowance(msg.sender, allowanceFor);
            if (allowance < totalCost) {
                revert InsufficientSaleTokenAllowance(
                    address(saleToken),
                    allowance,
                    totalCost
                );
            }
        }
    }

    /**
     * @notice Check that the drop stage is active.
     *
     * @param startTime The drop stage start time.
     * @param endTime The drop stage end time.
     */
    function _checkActive(uint256 startTime, uint256 endTime) internal view {
        if (block.timestamp < startTime || block.timestamp > endTime) {
            // Revert if the drop stage is not active.
            revert NotActive(block.timestamp, startTime, endTime);
        }
    }

    /**
     * @notice Splits the payment, mints a number of tokens,
     *         and emits an event.
     *
     * @param nftContract The nft contract.
     * @param numToMint The number of tokens to mint.
     * @param mintPrice The mint price.
     * @param dropStageIndex The drop stage index.
     * @param feeBps The fee basis points.
     * @param feeRecipient The fee recipient.
     * @param conduitAddress If paying with an ERC20 token,
     *                       optionally specify a conduit address to use.
     */
    function _payAndMint(
        address nftContract,
        uint256 numToMint,
        uint256 mintPrice,
        uint256 dropStageIndex,
        uint256 feeBps,
        address feeRecipient,
        address conduitAddress
    ) internal {
        // Get the sale token.
        ERC20 saleToken = _saleTokens[nftContract];

        // Split the payment between the creator and fee recipient.
        _splitPayout(
            nftContract,
            feeRecipient,
            feeBps,
            address(saleToken),
            conduitAddress
        );

        // Mint the token(s).
        IERC721SeaDrop(nftContract).mintSeaDrop(msg.sender, numToMint);

        // Emit an event for the mint.
        emit SeaDropMint(
            nftContract,
            msg.sender,
            feeRecipient,
            numToMint,
            mintPrice,
            address(saleToken),
            feeBps,
            dropStageIndex
        );
    }

    /**
     * @notice Split the payment payout for the creator and fee recipient.
     *
     * @param nftContract The nft contract.
     * @param feeRecipient The fee recipient.
     * @param feeBps The fee basis points.
     * @param saleToken Optionally, the ERC20 sale token.
     * @param conduitAddress If paying with an ERC20 token,
     *                       optionally specify a conduit addressto use.
     */
    function _splitPayout(
        address nftContract,
        address feeRecipient,
        uint256 feeBps,
        address saleToken,
        address conduitAddress
    ) internal {
        // Get the creator payout address.
        address creatorPayoutAddress = _creatorPayoutAddresses[nftContract];

        // Ensure the creator payout address is not the zero address.
        if (creatorPayoutAddress == address(0)) {
            revert CreatorPayoutAddressCannotBeZeroAddress();
        }

        // Get the fee amount.
        uint256 feeAmount = (msg.value * feeBps) / 10000;

        // Get the creator payout amount.
        uint256 payoutAmount = msg.value - feeAmount;

        // If the saleToken is the zero address, transfer the
        // native chain currency.
        if (saleToken == address(0)) {
            // Transfer native currency to the fee recipient.
            SafeTransferLib.safeTransferETH(feeRecipient, feeAmount);

            // Transfer native currency to the creator.
            SafeTransferLib.safeTransferETH(creatorPayoutAddress, payoutAmount);
        } else {
            // Use the conduit if specified.
            if (conduitAddress != address(0)) {
                // Initialize an array for the conduit transfers.
                ConduitTransfer[]
                    memory conduitTransfers = new ConduitTransfer[](2);

                // Set ERC20 conduit transfer for the fee recipient.
                conduitTransfers[0] = ConduitTransfer(
                    ConduitItemType.ERC20,
                    saleToken,
                    msg.sender,
                    feeRecipient,
                    0,
                    feeAmount
                );

                // Set ERC20 conduit transfer for the creator.
                conduitTransfers[1] = ConduitTransfer(
                    ConduitItemType.ERC20,
                    saleToken,
                    msg.sender,
                    creatorPayoutAddress,
                    0,
                    payoutAmount
                );

                // Execute the conduit transfers.
                ConduitInterface(conduitAddress).execute(conduitTransfers);
            } else {
                // Transfer ERC20 to the fee recipient.
                SafeTransferLib.safeTransferFrom(
                    ERC20(saleToken),
                    msg.sender,
                    feeRecipient,
                    feeAmount
                );

                // Transfer ERC20 to the creator.
                SafeTransferLib.safeTransferFrom(
                    ERC20(saleToken),
                    msg.sender,
                    creatorPayoutAddress,
                    payoutAmount
                );
            }
        }
    }

    /**
     * @notice Returns the drop URI for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getDropURI(address nftContract)
        external
        view
        returns (string memory)
    {
        return _dropURIs[nftContract];
    }

    /**
     * @notice Returns the public drop data for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPublicDrop(address nftContract)
        external
        view
        returns (PublicDrop memory)
    {
        return _publicDrops[nftContract];
    }

    /**
     * @notice Update the sale token for the nft contract
     *         and emit an event.
     *         A zero address means the sale token is denominated
     *         in the chain's native currency (e.g. ETH, MATIC, etc.)
     *
     * @param saleToken The ERC20 token address.
     */
    function updateSaleToken(address saleToken) external onlyIERC721SeaDrop {
        // Set the sale token.
        _saleTokens[msg.sender] = ERC20(saleToken);

        // Emit an event with the update.
        emit SaleTokenUpdated(msg.sender, saleToken);
    }

    /**
     * @notice Returns the sale token for the nft contract.
     *         A zero address means the sale token is denominated
     *         in the chain's native currency (e.g. ETH, MATIC, etc.)
     *
     * @param nftContract The nft contract.
     */
    function getSaleToken(address nftContract) external view returns (address) {
        return address(_saleTokens[nftContract]);
    }

    /**
     * @notice Returns the creator payout address for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getCreatorPayoutAddress(address nftContract)
        external
        view
        returns (address)
    {
        return _creatorPayoutAddresses[nftContract];
    }

    /**
     * @notice Returns the allow list merkle root for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getAllowListMerkleRoot(address nftContract)
        external
        view
        returns (bytes32)
    {
        return _allowListMerkleRoots[nftContract];
    }

    /**
     * @notice Returns if the specified fee recipient is allowed
     *         for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getFeeRecipientIsAllowed(address nftContract, address feeRecipient)
        external
        view
        returns (bool)
    {
        return _allowedFeeRecipients[nftContract][feeRecipient];
    }

    /**
     * @notice Returns the server side signers for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getSigners(address nftContract)
        external
        view
        returns (address[] memory)
    {
        return _enumeratedSigners[nftContract];
    }

    /**
     * @notice Updates the public drop for the nft contract and emits an event.
     *
     * @param publicDrop The public drop data.
     */
    function updatePublicDrop(PublicDrop calldata publicDrop)
        external
        override
        onlyIERC721SeaDrop
    {
        // Set the public drop data.
        _publicDrops[msg.sender] = publicDrop;

        // Emit an event with the update.
        emit PublicDropUpdated(msg.sender, publicDrop);
    }

    /**
     * @notice Updates the allow list merkle root for the nft contract
     *         and emits an event.
     *
     * @param allowListData The allow list data.
     */
    function updateAllowList(AllowListData calldata allowListData)
        external
        override
        onlyIERC721SeaDrop
    {
        // Track the previous root.
        bytes32 prevRoot = _allowListMerkleRoots[msg.sender];

        // Update the merkle root.
        _allowListMerkleRoots[msg.sender] = allowListData.merkleRoot;

        // Emit an event with the update.
        emit AllowListUpdated(
            msg.sender,
            prevRoot,
            allowListData.merkleRoot,
            allowListData.publicKeyURIs,
            allowListData.allowListURI
        );
    }

    /**
     * @notice Updates the token gated drop stage for the nft contract
     *         and emits an event.
     *
     * @param nftContract The nft contract.
     * @param allowedNftToken The token gated nft token.
     * @param dropStage The token gated drop stage data.
     */
    function updateTokenGatedDrop(
        address nftContract,
        address allowedNftToken,
        TokenGatedDropStage calldata dropStage
    ) external override onlyIERC721SeaDrop {
        // Set the drop stage.
        _tokenGatedDrops[nftContract][allowedNftToken] = dropStage;

        // If the maxTotalMintableByWallet is greater than zero
        // then we are setting an active drop stage.
        if (dropStage.maxTotalMintableByWallet > 0) {
            // Add allowedNftToken to enumerated list if not present.
            bool allowedNftTokenExistsInEnumeration = false;

            // Iterate through enumerated token gated tokens for nft contract.
            for (
                uint256 i = 0;
                i < _enumeratedTokenGatedTokens[nftContract].length;

            ) {
                if (
                    _enumeratedTokenGatedTokens[nftContract][i] ==
                    allowedNftToken
                ) {
                    // Set the bool to true if found.
                    allowedNftTokenExistsInEnumeration = true;
                }
                unchecked {
                    ++i;
                }
            }

            // Add allowedNftToken to enumerated list if not present.
            if (allowedNftTokenExistsInEnumeration == false) {
                _enumeratedTokenGatedTokens[nftContract].push(allowedNftToken);
            }
        }

        // Emit an event with the update.
        emit TokenGatedDropStageUpdated(
            nftContract,
            allowedNftToken,
            dropStage
        );
    }

    /**
     * @notice Returns the allowed token gated drop tokens for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getTokenGatedAllowedTokens(address nftContract)
        external
        view
        returns (address[] memory)
    {
        return _enumeratedTokenGatedTokens[nftContract];
    }

    /**
     * @notice Returns the token gated drop data for the nft contract
     *         and token gated nft.
     *
     * @param nftContract The nft contract.
     * @param allowedNftToken The token gated nft token.
     */
    function getTokenGatedDrop(address nftContract, address allowedNftToken)
        external
        view
        returns (TokenGatedDropStage memory)
    {
        return _tokenGatedDrops[nftContract][allowedNftToken];
    }

    /**
     * @notice Updates the drop URI and emits an event.
     *
     * @param newDropURI The new drop URI.
     */
    function updateDropURI(string calldata newDropURI)
        external
        onlyIERC721SeaDrop
    {
        // Set the new drop URI.
        _dropURIs[msg.sender] = newDropURI;

        // Emit an event with the update.
        emit DropURIUpdated(msg.sender, newDropURI);
    }

    /**
     * @notice Updates the creator payout address and emits an event.
     *
     * @param _payoutAddress The creator payout address.
     */
    function updateCreatorPayoutAddress(address _payoutAddress)
        external
        onlyIERC721SeaDrop
    {
        // Set the creator payout address.
        _creatorPayoutAddresses[msg.sender] = _payoutAddress;

        // Emit an event with the update.
        emit CreatorPayoutAddressUpdated(msg.sender, _payoutAddress);
    }

    /**
     * @notice Updates the allowed fee recipient and emits an event.
     *
     * @param feeRecipient The fee recipient.
     * @param allowed If the fee recipient is allowed.
     */
    function updateAllowedFeeRecipient(address feeRecipient, bool allowed)
        external
        onlyIERC721SeaDrop
    {
        // Set the allowed fee recipient.
        _allowedFeeRecipients[msg.sender][feeRecipient] = allowed;

        // Emit an event with the update.
        emit AllowedFeeRecipientUpdated(msg.sender, feeRecipient, allowed);
    }

    /**
     * @notice Updates the allowed server side signers and emits an event.
     *
     * @param newSigners The new list of signers.
     */
    function updateSigners(address[] calldata newSigners)
        external
        onlyIERC721SeaDrop
    {
        // Track the enumerated storage.
        address[] storage enumeratedStorage = _enumeratedSigners[msg.sender];

        // Track the old signers.
        address[] memory oldSigners = enumeratedStorage;

        // Delete old enumeration.
        delete _enumeratedSigners[msg.sender];

        // Add new enumeration.
        for (uint256 i = 0; i < newSigners.length; ) {
            enumeratedStorage.push(newSigners[i]);
            unchecked {
                ++i;
            }
        }

        // Create a mapping of the signers.
        mapping(address => bool) storage signersMap = _signers[msg.sender];

        // Delete old signers.
        for (uint256 i = 0; i < oldSigners.length; ) {
            signersMap[oldSigners[i]] = false;
            unchecked {
                ++i;
            }
        }
        // Add new signers.
        for (uint256 i = 0; i < newSigners.length; ) {
            signersMap[newSigners[i]] = true;
            unchecked {
                ++i;
            }
        }

        // Emit an event with the update.
        emit SignersUpdated(msg.sender, oldSigners, newSigners);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {
    AllowListData,
    Conduit,
    MintParams,
    PublicDrop,
    TokenGatedDropStage,
    TokenGatedMintParams
} from "../lib/SeaDropStructs.sol";

import { SeaDropErrorsAndEvents } from "../lib/SeaDropErrorsAndEvents.sol";

interface ISeaDrop is SeaDropErrorsAndEvents {
    /**
     * @notice Mint a public drop.
     *
     * @param nftContract The nft contract to mint.
     * @param feeRecipient The fee recipient.
     * @param numToMint The number of tokens to mint.
     * @param conduit If paying with an ERC20 token,
     *                optionally specify a conduit to use.
     */
    function mintPublic(
        address nftContract,
        address feeRecipient,
        uint256 numToMint,
        Conduit calldata conduit
    ) external payable;

    /**
     * @notice Mint from an allow list.
     *
     * @param nftContract The nft contract to mint.
     * @param feeRecipient The fee recipient.
     * @param numToMint The number of tokens to mint.
     * @param mintParams The mint parameters.
     * @param proof The proof for the leaf of the allow list.
     * @param conduit If paying with an ERC20 token,
     *                optionally specify a conduit to use.
     */
    function mintAllowList(
        address nftContract,
        address feeRecipient,
        uint256 numToMint,
        MintParams calldata mintParams,
        bytes32[] calldata proof,
        Conduit calldata conduit
    ) external payable;

    /**
     * @notice Mint with a server side signature.
     *
     * @param nftContract The nft contract to mint.
     * @param feeRecipient The fee recipient.
     * @param numToMint The number of tokens to mint.
     * @param mintParams The mint parameters.
     * @param signature The server side signature, must be an allowed signer.
     * @param conduit If paying with an ERC20 token,
     *                optionally specify a conduit to use.
     */
    function mintSigned(
        address nftContract,
        address feeRecipient,
        uint256 numToMint,
        MintParams calldata mintParams,
        bytes calldata signature,
        Conduit calldata conduit
    ) external payable;

    /**
     * @notice Mint as an allowed token holder.
     *         This will mark the token id as reedemed and will revert if the
     *         same token id is attempted to be redeemed twice.
     *
     * @param nftContract The nft contract to mint.
     * @param feeRecipient The fee recipient.
     * @param tokenGatedMintParams The token gated mint params.
     * @param conduit If paying with an ERC20 token,
     *                optionally specify a conduit to use.
     */
    function mintAllowedTokenHolder(
        address nftContract,
        address feeRecipient,
        TokenGatedMintParams[] calldata tokenGatedMintParams,
        Conduit calldata conduit
    ) external payable;

    /**
     * @notice Returns the drop URI for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getDropURI(address nftContract)
        external
        view
        returns (string memory);

    /**
     * @notice Returns the public drop data for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPublicDrop(address nftContract)
        external
        view
        returns (PublicDrop memory);

    /**
     * @notice Returns the creator payout address for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getCreatorPayoutAddress(address nftContract)
        external
        view
        returns (address);

    /**
     * @notice Returns the allow list merkle root for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getAllowListMerkleRoot(address nftContract)
        external
        view
        returns (bytes32);

    /**
     * @notice Returns if the specified fee recipient is allowed
     *         for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getFeeRecipientIsAllowed(address nftContract, address feeRecipient)
        external
        view
        returns (bool);

    /**
     * @notice Returns the server side signers for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getSigners(address nftContract)
        external
        view
        returns (address[] memory);

    /**
     * The following methods assume msg.sender is an nft contract
     * and its ERC165 interface id matches IERC721SeaDrop.
     */

    /**
     * @notice Updates the public drop data for the nft contract
     *         and emits an event.
     *
     * @param publicDrop The public drop data.
     */
    function updatePublicDrop(PublicDrop calldata publicDrop) external;

    /**
     * @notice Updates the allow list merkle root for the nft contract
     *         and emits an event.
     *
     * @param allowListData The allow list data.
     */
    function updateAllowList(AllowListData calldata allowListData) external;

    /**
     * @notice Updates the drop URI and emits an event.
     *
     * @param dropURI The new drop URI.
     */
    function updateDropURI(string calldata dropURI) external;

    /**
     * @notice Updates the creator payout address and emits an event.
     *
     * @param payoutAddress The creator payout address.
     */
    function updateCreatorPayoutAddress(address payoutAddress) external;

    /**
     * @notice Updates the allowed fee recipient and emits an event.
     *
     * @param feeRecipient The fee recipient.
     * @param allowed If the fee recipient is allowed.
     */
    function updateAllowedFeeRecipient(address feeRecipient, bool allowed)
        external;

    /**
     * @notice Updates the allowed server side signers and emits an event.
     *
     * @param newSigners The new list of signers.
     */
    function updateSigners(address[] calldata newSigners) external;

    /**
     * @notice Updates the token gated drop stage for the nft contract
     *         and emits an event.
     *
     * @param nftContract The nft contract.
     * @param allowedNftToken The token gated nft token.
     * @param dropStage The token gated drop stage data.
     */
    function updateTokenGatedDrop(
        address nftContract,
        address allowedNftToken,
        TokenGatedDropStage calldata dropStage
    ) external;

    /**
     * @notice Returns the allowed token gated drop tokens for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getTokenGatedAllowedTokens(address nftContract)
        external
        view
        returns (address[] memory);

    /**
     * @notice Returns the token gated drop data for the nft contract
     *         and token gated nft.
     *
     * @param nftContract The nft contract.
     * @param allowedNftToken The token gated nft token.
     */
    function getTokenGatedDrop(address nftContract, address allowedNftToken)
        external
        view
        returns (TokenGatedDropStage memory);

    /**
     * @notice Update the sale token for the nft contract.
     *         A zero address means the sale token is denominated
     *         in the chain's native currency (e.g. ETH, MATIC, etc.)
     *
     * @param saleToken The ERC20 token address.
     */
    function updateSaleToken(address saleToken) external;

    /**
     * @notice Returns the sale token for the nft contract.
     *         A zero address means the sale token is denominated
     *         in the chain's native currency (e.g. ETH, MATIC, etc.)
     *
     * @param nftContract The nft contract.
     */
    function getSaleToken(address nftContract) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @notice A struct defining public drop data.
 *         Designed to fit efficiently in one storage slot.
 */
struct PublicDrop {
    // Up to 1.2m of native token, e.g.: ETH, MATIC
    uint80 mintPrice; // 80/256 bits
    // Ensure this is not zero.
    uint64 startTime; // 144/256 bits
    // Maximum total number of mints a user is allowed.
    uint40 maxMintsPerWallet; // 184/256 bits
    // Fee out of 10,000 basis points to be collected.
    uint16 feeBps; // 200/256 bits
    // If false, allow any fee recipient; if true, check fee recipient is allowed.
    bool restrictFeeRecipients; // 208/256 bits
}

/**
 * @notice Stages from dropURI are strictly for front-end consumption,
 *         and are trusted to match information in the
 *         PublicDrop, AllowLists or TokenGatedDropStage
 *         (we may want to surface discrepancies on the front-end)
 */

/**
 * @notice A struct defining token gated drop stage data.
 *         Designed to fit efficiently in one storage slot.
 */
struct TokenGatedDropStage {
    uint80 mintPrice;
    uint16 maxTotalMintableByWallet;
    uint48 startTime;
    uint48 endTime;
    uint8 dropStageIndex;
    uint40 maxTokenSupplyForStage;
    uint16 feeBps;
    bool restrictFeeRecipients;
}

/**
 * @notice A struct defining mint params for an allow list.
 *         An allow list leaf will be composed of `msg.sender` and
 *         the following params.
 * 
 *         Note: Since feeBps is encoded in the leaf, backend should ensure
 *         that feeBps is acceptable before generating a proof.
 */
struct MintParams {
    uint256 mintPrice;
    uint256 maxTotalMintableByWallet;
    uint256 startTime;
    uint256 endTime;
    uint256 dropStageIndex;
    uint256 maxTokenSupplyForStage;
    uint256 feeBps;
    bool restrictFeeRecipients;
}

/**
 * @notice A struct defining token gated mint params.
 */
struct TokenGatedMintParams {
    address allowedNftToken;
    uint256[] allowedNftTokenIds;
}

/**
 * @notice A struct defining allow list data (for minting an allow list).
 */
struct AllowListData {
    bytes32 merkleRoot;
    string[] publicKeyURIs;
    string allowListURI;
}

/**
 * @notice A struct for validating payment for the mint.
 */
struct PaymentValidation {
    uint256 numberToMint;
    uint256 mintPrice;
}

/**
 * @notice A struct for using a conduit when paying with an ERC20 sale token.
 */
struct Conduit {
    address conduitController;
    bytes32 conduitKey;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {
    IERC721ContractMetadata
} from "../interfaces/IERC721ContractMetadata.sol";

import {
    AllowListData,
    PublicDrop,
    TokenGatedDropStage
} from "../lib/SeaDropStructs.sol";

import {
    IERC165
} from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

interface IERC721SeaDrop is IERC721ContractMetadata, IERC165 {
    /**
     * @dev Revert with an error if a contract other than an allowed
     *      SeaDrop address calls an update function.
     */
    error OnlySeaDrop();

    /**
     * @dev Emit an event when allowed SeaDrop contracts are updated.
     */
    event AllowedSeaDropUpdated(address[] allowedSeaDrop);

    /**
     * @notice Update the allowed SeaDrop contracts.
     *
     * @param allowedSeaDrop The allowed SeaDrop addresses.
     */
    function updateAllowedSeaDrop(address[] calldata allowedSeaDrop) external;

    /**
     * @notice Mint tokens, restricted to the SeaDrop contract.
     *
     * @param minter The address to mint to.
     * @param amount The number of tokens to mint.
     */
    function mintSeaDrop(address minter, uint256 amount) external payable;

    /**
     * @notice Returns a set of mint stats for the address.
     *         This assists SeaDrop in enforcing maxSupply,
     *         maxMintsPerWallet, and maxTokenSupplyForStage checks.
     *
     * @param minter The minter address.
     */
    function getMintStats(address minter)
        external
        view
        returns (
            uint256 minterNumMinted,
            uint256 currentTotalSupply,
            uint256 maxSupply
        );

    /**
     * @notice Update public drop data for this nft contract on SeaDrop.
     *         Use `updatePublicDropFee` to update the fee recipient or feeBps.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param publicDrop The public drop data.
     */
    function updatePublicDrop(
        address seaDropImpl,
        PublicDrop calldata publicDrop
    ) external;

    /**
     * @notice Update allow list data for this nft contract on SeaDrop.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param allowListData The allow list data.
     */
    function updateAllowList(
        address seaDropImpl,
        AllowListData calldata allowListData
    ) external;

    /**
     * @notice Update token gated drop stage data for this nft contract
     *         on SeaDrop.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param allowedNftToken The allowed nft token.
     * @param dropStage The token gated drop stage data.
     */
    function updateTokenGatedDrop(
        address seaDropImpl,
        address allowedNftToken,
        TokenGatedDropStage calldata dropStage
    ) external;

    /**
     * @notice Update the drop URI for this nft contract on SeaDrop.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param dropURI The new drop URI.
     */
    function updateDropURI(address seaDropImpl, string calldata dropURI)
        external;

    /**
     * @notice Update the creator payout address for this nft contract on SeaDrop.
     *         Only the owner can set the creator payout address.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param payoutAddress The new payout address.
     */
    function updateCreatorPayoutAddress(
        address seaDropImpl,
        address payoutAddress
    ) external;

    /**
     * @notice Update the allowed fee recipient for this nft contract
     *         on SeaDrop.
     *         Only the administrator can set the allowed fee recipient.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param feeRecipient The new fee recipient.
     */
    function updateAllowedFeeRecipient(
        address seaDropImpl,
        address feeRecipient,
        bool allowed
    ) external;

    /**
     * @notice Update the server side signers for this nft contract
     *         on SeaDrop.
     *         Only the owner or administrator can update the signers.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param newSigners The new signers.
     */
    function updateSigners(address seaDropImpl, address[] calldata newSigners)
        external;

    /**
     * @notice Update the sale token for the nft contract.
     *         A zero address means the sale token is denominated
     *         in the chain's native currency (e.g. ETH, MATIC, etc.)
     *         Only the owner or administrator can update the sale token.
     *
     * @param saleToken The ERC20 token address.
     */
    function updateSaleToken(address seaDropImpl, address saleToken) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
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
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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

enum ConduitItemType {
    NATIVE, // unused
    ERC20,
    ERC721,
    ERC1155
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
pragma solidity ^0.8.11;

import { PublicDrop, TokenGatedDropStage } from "./SeaDropStructs.sol";

interface SeaDropErrorsAndEvents {
    /**
     * @dev Revert with an error if the drop stage is not active.
     */
    error NotActive(
        uint256 currentTimestamp,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    /**
     * @dev Revert with an error if amount exceeds the max allowed
     *      per transaction.
     */
    error AmountExceedsMaxPerTransaction(uint256 amount, uint256 allowed);

    /**
     * @dev Revert with an error if amount exceeds the max allowed
     *      to be minted per wallet.
     */
    error AmountExceedsMaxMintedPerWallet(uint256 total, uint256 allowed);

    /**
     * @dev Revert with an error if amount exceeds the max token supply.
     */
    error AmountExceedsMaxSupply(uint256 total, uint256 maxSupply);

    /**
     * @dev Revert with an error if amount exceeds the max token supply for the stage.
     */
    error AmountExceedsMaxTokenSupplyForStage(uint256 total, uint256 maxTokenSupplyForStage);
    
    /**
     * @dev Revert if the fee recipient is the zero address.
     */
    error FeeRecipientCannotBeZeroAddress();

    /**
     * @dev Revert if the fee recipient is restricted and not allowe.
     */
    error FeeRecipientNotAllowed();

    /**
     * @dev Revert if the creator payout address is the zero address.
     */
    error CreatorPayoutAddressCannotBeZeroAddress();

    /**
     * @dev Revert with an error if the allow list is already redeemed.
     *      TODO should you only be able to redeem from an allow list once?
     *           would otherwise be capped by maxTotalMintableByWallet
     */
    error AllowListRedeemed(address minter);

    /**
     * @dev Revert with an error if the received payment is incorrect.
     */
    error IncorrectPayment(uint256 got, uint256 want);

    /**
     * @dev Revert with an error if the allow list proof is invalid.
     */
    error InvalidProof();

    /**
     * @dev Revert with an error if signer's signatuer is invalid.
     */
    error InvalidSignature(address recoveredSigner);

    /**
     * @dev Revert with an error if the sender does not
     *      match the IERC721SeaDrop interface.
     */
    error OnlyIERC721SeaDrop(address sender);

    /**
     * @dev Revert with an error if the sender of a token gated supplied
     *      drop stage redeem is not the owner of the token.
     */
    error TokenGatedNotTokenOwner(address nftContract, address allowedNftContract, uint256 tokenId);

    /**
     * @dev Revert with an error if the token id has already been used to
     *      redeem a token gated drop stage.
     */
    error TokenGatedTokenIdAlreadyRedeemed(address nftContract, address allowedNftContract, uint256 tokenId);

    /**
     * @dev Revert with an error if sender has insufficient
     *      sale token balance.
     */
    error InsufficientSaleTokenBalance(address saleToken, uint256 balance, uint256 totalCost);

    /**
     * @dev Revert with an error if sender has insufficient
     *      sale token allowance.
     */
    error InsufficientSaleTokenAllowance(address saleToken, uint256 allowance, uint256 totalCost);

    /**
     * @dev Revert with an error if msg.value > 0 for ERC20 saleToken payment.
     */
    error MsgValueNonZeroForERC20SaleToken();

    /**
     * @dev An event with details of a SeaDrop mint, for analytical purposes.
     */
    event SeaDropMint(
        address indexed nftContract,
        address indexed minter,
        address indexed feeRecipient,
        uint256 numberMinted,
        uint256 unitMintPrice,
        address saleToken,
        uint256 feeBps,
        uint256 dropStageIndex
    );

    /**
     * @dev An event with updated public drop data for an nft contract.
     */
    event PublicDropUpdated(address indexed nftContract, PublicDrop publicDrop);

    /**
     * @dev An event with updated token gated drop stage data
     *      for an nft contract.
     */
    event TokenGatedDropStageUpdated(
        address indexed nftContract,
        address indexed allowedNftToken,
        TokenGatedDropStage dropStage
    );

    /**
     * @dev An event with updated allow list data for an nft contract.
     */
    event AllowListUpdated(
        address indexed nftContract,
        bytes32 indexed previousMerkleRoot,
        bytes32 indexed newMerkleRoot,
        string[] publicKeyURI, // empty if unencrypted
        string allowListURI
    );

    /**
     * @dev An event with updated drop URI for an nft contract.
     */
    event DropURIUpdated(address indexed nftContract, string newDropURI);

    /**
     * @dev An event with the updated creator payout address for an nft contract.
     */
    event CreatorPayoutAddressUpdated(
        address indexed nftContract,
        address indexed newPayoutAddress
    );

    /**
     * @dev An event with the updated allowed fee recipient for an nft contract.
     */
    event AllowedFeeRecipientUpdated(
        address indexed nftContract,
        address indexed feeRecipient,
        bool indexed allowed
    );

    /**
     * @dev An event with the updated server side signers for an nft contract.
     */
    event SignersUpdated(
        address indexed nftContract,
        address[] oldSigners,
        address[] newSigners
    );

    /**
     * @dev An event with the updated sale token.
     */
    event SaleTokenUpdated(
        address indexed nftContract,
        address saleToken
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IERC721ContractMetadata {
    /**
     * @dev Emit an event when the max token supply is updated.
     */
    event MaxSupplyUpdated(uint256 newMaxSupply);

    /**
     * @dev Emit an event with the previous and new provenance hash after
     *      being updated.
     */
    event ProvenanceHashUpdated(bytes32 previousHash, bytes32 newHash);

    /**
     * @dev Emit an event when the URI for the collection-level metadata
     *      is updated.
     */
    event ContractURIUpdated(string newContractURI);

    /**
     * @dev Emit an event for partial reveals/updates.
     *      Batch update implementation should be left to contract.
     *
     * @param startTokenId The start token id.
     * @param endTokenId The end token id.
     */
    event TokenURIUpdated(
        uint256 indexed startTokenId,
        uint256 indexed endTokenId
    );

    /**
     * @dev Emit an event for full token metadata reveals/updates.
     *
     * @param baseURI The base URI.
     */
    event BaseURIUpdated(string baseURI);

    /**
     * @notice Returns the contract URI.
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice Sets the contract URI for contract metadata.
     *
     * @param newContractURI The new contract URI.
     */
    function setContractURI(string calldata newContractURI) external;

    /**
     * @notice Returns the base URI for token metadata.
     */
    function baseURI() external view returns (string memory);

    /**
     * @notice Sets the base URI for the token metadata and emits an event.
     *
     * @param tokenURI The new base URI to set.
     */
    function setBaseURI(string calldata tokenURI) external;

    /**
     * @notice Returns the max token supply.
     */
    function maxSupply() external view returns (uint256);

    /**
     * @notice Sets the max supply and emits an event.
     *
     * @param newMaxSupply The new max supply to set.
     */
    function setMaxSupply(uint256 newMaxSupply) external;

    /**
     * @notice Returns the total token supply.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Returns the provenance hash.
     *         The provenance hash is used for random reveals, which
     *         is a hash of the ordered metadata to show it is unmodified
     *         after mint has started.
     */
    function provenanceHash() external view returns (bytes32);

    /**
     * @notice Sets the provenance hash and emits an event.
     *         The provenance hash is used for random reveals, which
     *         is a hash of the ordered metadata to show it is unmodified
     *         after mint has started.
     *         This function will revert after the first item has been minted.
     *
     * @param newProvenanceHash The new provenance hash to set.
     */
    function setProvenanceHash(bytes32 newProvenanceHash) external;

    /**
     * @dev Revert with an error when attempting to set the provenance
     *      hash after the mint has started.
     */
    error ProvenanceHashCannotBeSetAfterMintStarted();
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}