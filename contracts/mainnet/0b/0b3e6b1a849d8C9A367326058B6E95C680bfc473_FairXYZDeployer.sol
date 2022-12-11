// SPDX-License-Identifier: MIT

// @ Fair.xyz dev

pragma solidity 0.8.17;

import "./ERC721xyzUpgradeable.sol";
import "./IFairXYZWallets.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract FairXYZDeployer is
    ERC721xyzUpgradeable,
    AccessControlUpgradeable,
    MulticallUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using ECDSAUpgradeable for bytes32;
    using StringsUpgradeable for uint256;

    struct TokensAvailableToMint {
        // Max number of tokens on sale across the whole collection
        uint128 maxTokens;
        // The creator can enforce a max mints per wallet at a global level, i.e. across all stages
        uint128 globalMintsPerWallet;
    }

    TokensAvailableToMint public tokensAvailable;

    // URI information
    string internal baseURI;
    string internal pathURI;
    string internal preRevealURI;
    string internal _overrideURI;
    bool public lockURI;

    // Bool to allow signature-less minting, in case the seller/creator wants to liberate themselves
    // from being bound to a signature generated on the Fair.xyz back-end
    bool public signatureReleased;

    // Interface into FairXYZWallets. This provides the wallet address to which the Fair.xyz fee is sent to
    address public interfaceAddress;

    // Burnable token bool
    bool public burnable;

    // Royalty information - this tells the contract where the proceeds from the primary sale should go to
    address internal _primarySaleReceiver;

    // Tightly pack the parameters that define a sale stage
    struct StageData {
        uint40 startTime;
        uint40 endTime;
        uint32 mintsPerWallet;
        uint32 phaseLimit;
        uint112 price;
        bytes32 merkleRoot;
    }

    // Mapping a stage ID to its corresponding StageData struct
    mapping(uint256 => StageData) internal stageMap;

    // Mapping to keep track of the number of mints a given wallet has done on a specific stage
    mapping(uint256 => mapping(address => uint256)) public stageMints;

    // Total number of sale stages
    uint256 public totalStages;

    // Pre-defined roles for AccessControl
    bytes32 public constant SECOND_ADMIN_ROLE = keccak256("T2A");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    // Fair.xyz address required for verifying signatures in the contract
    address internal constant FairxyzSignerAddress =
        0x7A6F5866f97034Bb7153829bdAaC1FFCb8Facb71;

    address constant DEFAULT_OPERATOR_FILTER_REGISTRY =
        0x000000000000AAeB6D7670E522A718067333cd4E;
    address constant DEFAULT_OPERATOR_FILTER_SUBSCRIPTION =
        0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

    // Events
    event Airdrop(uint256 tokenCount, uint256 newTotal, address[] recipients);
    event BurnableSet(bool burnState);
    event SignatureReleased();
    event NewMaxMintsPerWalletSet(uint128 newGlobalMintsPerWallet);
    event NewPathURI(string newPathURI);
    event NewPrimarySaleReceiver(address newPrimaryReceiver);
    event NewSecondaryRoyalties(
        address newSecondaryReceiver,
        uint96 newRoyalty
    );
    event NewStagesSet(StageData[] stages, uint256 startIndex);
    event NewTokenURI(string newTokenURI);
    event Mint(address minterAddress, uint256 stage, uint256 mintCount);
    event URILocked();

    // Errors
    error AlreadyLockedURI();
    error BurnerIsNotApproved();
    error BurningOff();
    error CannotDeleteOngoingStage();
    error CannotEditPastStages();
    error ETHSendFail();
    error EndTimeInThePast();
    error EndTimeLessThanStartTime();
    error ExceedsMintsPerWallet();
    error ExceedsNFTsOnSale();
    error IncorrectIndex();
    error InvalidNonce();
    error InvalidStartTime();
    error LessNFTsOnSaleThanBefore();
    error MerkleProofFail();
    error MerkleStage();
    error NotEnoughETH();
    error PhaseLimitEnd();
    error PhaseLimitExceedsTokenCount();
    error PhaseStartsBeforePriorPhaseEnd();
    error PublicStage();
    error ReusedHash();
    error SaleEnd();
    error SaleNotActive();
    error StageDoesNotExist();
    error StartTimeInThePast();
    error TimeLimit();
    error TokenCountExceedsPhaseLimit();
    error TokenDoesNotExist();
    error TokenLimitPerTx();
    error UnauthorisedUser();
    error UnrecognizableHash();
    error ZeroAddress();

    /**
     * @dev Returns the wallet of Fair.xyz to which primary sale fee will be
     */
    function viewWithdraw() public view returns (address) {
        address returnWithdraw = IFairXYZWallets(interfaceAddress)
            .viewWithdraw();
        return (returnWithdraw);
    }

    /**
     * @dev Intended to be called from the original implementation for the factory contract
     */
    function initialize() external initializer {
        __ERC721_init("", "");
        __AccessControl_init();
        __Multicall_init();
        __ReentrancyGuard_init();
    }

    /**
     * @dev Initialise a new Creator contract by setting variables and initialising
     * inherited contracts
     */
    function _initialize(
        uint128 maxTokens_,
        string memory name_,
        string memory symbol_,
        address interfaceAddress_,
        string[] memory URIs_,
        uint96 royaltyPercentage_,
        uint128 globalMintsPerWallet_,
        address[] memory royaltyReceivers,
        address ownerOfContract,
        StageData[] calldata stages
    ) external initializer {
        if (!(interfaceAddress_ != address(0))) revert ZeroAddress();
        require(URIs_.length == 3);
        require(royaltyReceivers.length == 2);
        __ERC721_init(name_, symbol_);
        __AccessControl_init();
        __Multicall_init();
        __ReentrancyGuard_init();
        __OperatorFilterer_init(
            DEFAULT_OPERATOR_FILTER_REGISTRY,
            DEFAULT_OPERATOR_FILTER_SUBSCRIPTION,
            true
        );
        _transferOwnership(ownerOfContract);
        tokensAvailable = TokensAvailableToMint(
            maxTokens_,
            globalMintsPerWallet_
        );
        interfaceAddress = interfaceAddress_;
        preRevealURI = URIs_[0];
        baseURI = URIs_[1];
        pathURI = URIs_[2];
        _primarySaleReceiver = royaltyReceivers[0];
        _setDefaultRoyalty(royaltyReceivers[1], royaltyPercentage_);
        _grantRole(DEFAULT_ADMIN_ROLE, ownerOfContract);
        _grantRole(SECOND_ADMIN_ROLE, ownerOfContract);
        if (stages.length > 0) {
            _setStages(stages, 0);
        }
    }

    /**
     * @dev Ensure number of minted tokens never goes above the total contract minting limit
     */
    modifier saleIsOpen() {
        if (!(_mintedTokens < tokensAvailable.maxTokens)) revert SaleEnd();
        _;
    }

    /**
     * @dev View sale parameters corresponding to a given stage
     */
    function viewStageMap(uint256 stageId)
        public
        view
        returns (StageData memory)
    {
        if (stageId >= totalStages) revert StageDoesNotExist();

        return stageMap[stageId];
    }

    /**
     * @dev View the current active sale stage for a sale based on being within the
     * time bounds for the start time and end time for the considered stage
     */
    function viewCurrentStage() public view returns (uint256) {
        for (uint256 i; i < totalStages; ) {
            if (
                block.timestamp >= stageMap[i].startTime &&
                block.timestamp <= stageMap[i].endTime
            ) {
                return i;
            }

            unchecked {
                ++i;
            }
        }

        revert SaleNotActive();
    }

    /**
     * @dev Returns the earliest stage which has not closed yet
     */
    function viewLatestStage() public view returns (uint256) {
        for (uint256 i; i < totalStages; ) {
            if (block.timestamp < stageMap[i].endTime) {
                return i;
            }
            unchecked {
                ++i;
            }
        }

        return totalStages;
    }

    /**
     * @dev See _setStages
     */
    function setStages(StageData[] calldata stages, uint256 startId) external {
        if (!hasRole(SECOND_ADMIN_ROLE, msg.sender)) revert UnauthorisedUser();
        _setStages(stages, startId);
    }

    /**
     * @dev Set the parameters for a list of sale stages, starting from startId onwards
     */
    function _setStages(StageData[] calldata stages, uint256 startId)
        internal
        returns (uint256)
    {
        uint256 currentTotalStages = totalStages;
        // Check that the stage the user is overriding from onwards is not a closed stage
        if (currentTotalStages > 0 && startId < viewLatestStage())
            revert CannotEditPastStages();

        // The startId cannot be an arbitrary number, it must follow a sequential order based on the current number of stages
        if (startId > currentTotalStages) revert IncorrectIndex();

        uint256 length = stages.length;

        uint256 startStageStartTime = stageMap[startId].startTime;

        // In order to delete a stage, calldata of length 0 must be provided. The stage referenced by the startIndex
        // and all stages after that will no longer be considered for the drop
        if (length == 0) {
            // The stage cannot have started at any point for it to be deleted
            if (startStageStartTime <= block.timestamp)
                revert CannotDeleteOngoingStage();

            // The new length of total stages is startId, as everything from there onwards is now disregarded
            totalStages = startId;
            emit NewStagesSet(stages, startId);
            return startId;
        }

        StageData memory newStage = stages[0];
        if (newStage.phaseLimit < _mintedTokens)
            revert TokenCountExceedsPhaseLimit();

        if (
            startStageStartTime <= block.timestamp && startStageStartTime != 0
        ) {
            // If the start time of the stage being replaced is in the past and exists
            // the new stage start time must match it
            if (startStageStartTime != newStage.startTime)
                revert InvalidStartTime();

            // The end time for a stage cannot be in the past
            if (newStage.endTime <= block.timestamp) revert EndTimeInThePast();
        } else {
            // the start time of the stage being replaced is in the future or doesn't exist
            // the new stage start time can't be in the past
            if (newStage.startTime <= block.timestamp)
                revert StartTimeInThePast();
        }

        unchecked {
            uint256 i = startId;
            uint256 stageCount = startId + length;

            do {
                if (i != startId) {
                    newStage = stages[i - startId];
                }

                // The number of tokens the user can mint up to in a stage cannot exceed the total supply available
                if (newStage.phaseLimit > tokensAvailable.maxTokens)
                    revert PhaseLimitExceedsTokenCount();

                // The end time cannot be less than the start time for a sale
                if (newStage.endTime <= newStage.startTime)
                    revert EndTimeLessThanStartTime();

                if (i > 0) {
                    // The number of total NFTs on sale cannot decrease from one stage to the next.
                    if (newStage.phaseLimit < stageMap[i - 1].phaseLimit)
                        revert LessNFTsOnSaleThanBefore();

                    // A sale can only start after the previous one has closed
                    if (newStage.startTime <= stageMap[i - 1].endTime)
                        revert PhaseStartsBeforePriorPhaseEnd();
                }

                // Update the variables in a given stage's stageMap with the correct indexing within the stages function input
                stageMap[i] = newStage;

                ++i;
            } while (i < stageCount);

            // The total number of stages is updated to be the startId + the length of stages added from there onwards
            totalStages = stageCount;

            emit NewStagesSet(stages, startId);
            return stageCount;
        }
    }

    /**
     * @dev Lock the token metadata forever. This action is non reversible.
     */
    function lockURIforever() external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert UnauthorisedUser();
        if (lockURI) revert AlreadyLockedURI();
        lockURI = true;
        emit URILocked();
    }

    /**
     * @dev Hash the variables to be modified for URI changes.
     */
    function hashURIChange(
        address sender,
        string memory newPathURI,
        string memory newURI,
        address address_
    ) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(sender, newPathURI, newURI, address_)
                )
            )
        );
        return hash;
    }

    /**
     * @dev Change values for the URIs. New Path URI implies a new reveal date being used.
     * newURI acts as an override for all priorly defined URIs). If lockURI() has been
     * executed, then this function will fail, as the data will have been locked forever.
     */
    function changeURI(
        bytes memory signature,
        string memory newPathURI,
        string memory newURI
    ) external {
        if (!hasRole(SECOND_ADMIN_ROLE, msg.sender)) revert UnauthorisedUser();

        // URI cannot be modified if it has been locked
        if (lockURI) revert AlreadyLockedURI();

        bytes32 messageHash = hashURIChange(
            msg.sender,
            newPathURI,
            newURI,
            address(this)
        );

        if (messageHash.recover(signature) != FairxyzSignerAddress)
            revert UnrecognizableHash();

        if (bytes(newPathURI).length != 0) {
            pathURI = newPathURI;
            emit NewPathURI(pathURI);
        }
        if (bytes(newURI).length != 0) {
            _overrideURI = newURI;
            baseURI = "";
            emit NewTokenURI(_overrideURI);
        }
    }

    /**
     * @dev Set global max mints per wallet
     */
    function setGlobalMaxMints(uint128 newGlobalMaxMintsPerWallet) external {
        if (!hasRole(SECOND_ADMIN_ROLE, msg.sender)) revert UnauthorisedUser();
        tokensAvailable.globalMintsPerWallet = newGlobalMaxMintsPerWallet;
        emit NewMaxMintsPerWalletSet(newGlobalMaxMintsPerWallet);
    }

    /**
     * @dev Toggle the burn state for NFTs in the contract
     */
    function toggleBurnable() external {
        if (!hasRole(SECOND_ADMIN_ROLE, msg.sender)) revert UnauthorisedUser();
        burnable = !burnable;
        emit BurnableSet(burnable);
    }

    /**
     * @dev Override primary royalty receiver
     */
    function changePrimarySaleReceiver(address newPrimarySaleReceiver)
        external
    {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert UnauthorisedUser();
        _primarySaleReceiver = newPrimarySaleReceiver;
        emit NewPrimarySaleReceiver(_primarySaleReceiver);
    }

    /**
     * @dev Override secondary royalty receivers
     */
    function changeSecondaryRoyaltyReceiver(
        address newSecondaryRoyaltyReceiver,
        uint96 newRoyaltyValue
    ) external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert UnauthorisedUser();
        _setDefaultRoyalty(newSecondaryRoyaltyReceiver, newRoyaltyValue);
        emit NewSecondaryRoyalties(
            newSecondaryRoyaltyReceiver,
            newRoyaltyValue
        );
    }

    /**
     * @dev Return the Base URI, used when there is no expected reveal experience
     */
    function _baseURI() public view returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Return the path URI - used for reveal experience
     */
    function _pathURI() public view returns (string memory) {
        if (bytes(_overrideURI).length == 0) {
            return IFairXYZWallets(interfaceAddress).viewPathURI(pathURI);
        } else {
            return _overrideURI;
        }
    }

    /**
     * @dev Return the pre-reveal URI, which is used when there is a reveal experience
     * and the reveal metadata has not been set yet.
     */
    function _preRevealURI() public view returns (string memory) {
        return preRevealURI;
    }

    /**
     * @dev Combines path URI, base URI and pre-reveal URI for the full metadata journey on Fair.xyz
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if(!_exists(tokenId)) revert TokenDoesNotExist();

        string memory pathURI_ = _pathURI();
        string memory baseURI_ = _baseURI();
        string memory preRevealURI_ = _preRevealURI();

        if (bytes(pathURI_).length == 0) {
            return preRevealURI_;
        } else {
            return
                string(
                    abi.encodePacked(pathURI_, baseURI_, tokenId.toString())
                );
        }
    }

    /**
     * @dev See the total mints across all stages for a wallet
     */
    function totalWalletMints(address minterAddress)
        external
        view
        returns (uint256)
    {
        return mintData[minterAddress].mintsPerWallet;
    }

    /**
     * @dev Burn a token. This requires being an owner of the NFT. The expected behaviour for a
     * burn mechanism is that the user transfers their NFT to a redemption contract which in turn
     * calls this function
     */
    function burn(uint256 tokenId) external returns (uint256) {
        if (!burnable) revert BurningOff();
        if (!(isApprovedForAll(ownerOf(tokenId), msg.sender) || msg.sender == ownerOf(tokenId) || getApproved(tokenId) == msg.sender)) revert BurnerIsNotApproved();
        _burn(tokenId);
        return tokenId;
    }

    /**
     * @dev Airdrop tokens to a list of addresses
     */
    function airdrop(address[] memory address_, uint256 tokenCount)
        external
        returns (uint256)
    {
        if (tokenCount == 0) revert TokenLimitPerTx();

        if (
            !hasRole(SECOND_ADMIN_ROLE, msg.sender) &&
            !hasRole(MINTER_ROLE, msg.sender)
        ) revert UnauthorisedUser();

        uint256 newTotal = _mintedTokens + address_.length * tokenCount;
        unchecked {
            if (newTotal > tokensAvailable.maxTokens)
                revert ExceedsNFTsOnSale();

            for (uint256 i; i < address_.length; ) {
                _safeMint(address_[i], tokenCount, 0);
                ++i;
            }

            emit Airdrop(tokenCount, newTotal, address_);
            return newTotal;
        }
    }

    /**
     * @dev Hash transaction data for minting
     */
    function hashTransaction(
        address sender,
        uint256 qty,
        uint256 nonce,
        uint256 maxMintsPerWallet,
        address address_
    ) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(
                        sender,
                        qty,
                        nonce,
                        maxMintsPerWallet,
                        address_
                    )
                )
            )
        );
        return hash;
    }

    /**
     * @dev Allow for signature-less minting on public sales
     */
    function releaseSignature() external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert UnauthorisedUser();
        require(!signatureReleased);
        signatureReleased = true;
        emit SignatureReleased();
    }

    /**
     * @dev Mint token(s) for public sales
     */
    function mint(
        bytes memory signature,
        uint256 nonce,
        uint256 numberOfTokens,
        uint256 maxMintsPerWallet,
        address recipient
    ) external payable {
        // Check the active stage - reverts if no stage is active
        uint256 presentStage = viewCurrentStage();

        // Load the minting parameters for this stage
        StageData memory dropData = stageMap[presentStage];

        // Nonce = 0 is reserved for airdrop mints, to distinguish them from other mints in the
        // _mint function on ERC721xyzUpgradeable
        if (nonce == 0) revert InvalidNonce();

        uint256 currentMintedTokens = _mintedTokens;

        // The number of minted tokens cannot exceed the number of NFTs on sale for this stage
        if (currentMintedTokens >= dropData.phaseLimit) revert PhaseLimitEnd();

        // If a Merkle Root is defined for the stage, then this is an allowlist stage. Thus the function merkleMint
        // must be used instead
        if (dropData.merkleRoot != bytes32(0)) revert MerkleStage();

        // If the contract is released from signature minting, skips this signature verification
        if (!signatureReleased) {
            // Hash the variables
            bytes32 messageHash = hashTransaction(
                recipient,
                numberOfTokens,
                nonce,
                maxMintsPerWallet,
                address(this)
            );

            // Ensure the recovered address from the signature is the Fair.xyz signer address
            if (messageHash.recover(signature) != FairxyzSignerAddress)
                revert UnrecognizableHash();

            // mintData[recipient].blockNumber is the last block (nonce) that was used to mint from the given address.
            // Nonces can only increase in number in each transaction, and are part of the signature. This ensures
            // that past signatures are not reused
            if (mintData[recipient].blockNumber >= nonce) revert ReusedHash();

            // Set a time limit of 40 blocks for the signature
            if (block.number > nonce + 40) revert TimeLimit();
        }

        // Check that enough ETH is sent for the minting quantity
        if (msg.value < dropData.price * numberOfTokens) revert NotEnoughETH();

        // At least 1 and no more than 20 tokens can be minted per transaction
        if (!((0 < numberOfTokens) && (numberOfTokens <= 20)))
            revert TokenLimitPerTx();

        // Load the total number of NFTs the user has minted across all stages
        uint256 mintsPerWallet = uint256(mintData[recipient].mintsPerWallet);

        // Load the number of NFTs the user has minted solely on the active stage
        uint256 stageMintsPerWallet = stageMints[presentStage][recipient];

        // Keep track of the user's original intent of tokens they want to mint, to be used for ETH reimbursement
        // later if necessary
        uint256 origMintCount = numberOfTokens;

        unchecked {
            // A value of 0 means there is no limit as to how many mints a wallet can do in this stage
            if (dropData.mintsPerWallet > 0) {
                // Check that the user has not reached the minting limit per wallet for this stage
                if (stageMintsPerWallet >= dropData.mintsPerWallet)
                    revert ExceedsMintsPerWallet();

                // Cap the number of tokens the user can mint so that it does not exceed the limit
                // per wallet for this stage
                if (
                    stageMintsPerWallet + numberOfTokens >
                    dropData.mintsPerWallet
                ) {
                    numberOfTokens =
                        dropData.mintsPerWallet -
                        stageMintsPerWallet;
                }
            }

            uint256 _globalMintsPerWallet = tokensAvailable
                .globalMintsPerWallet;

            // A value of 0 means there is no limit as to how many mints a wallet can do across all stages
            if (_globalMintsPerWallet > 0) {
                // Check that the user has not reached the minting limit per wallet across the whole contract
                if (mintsPerWallet >= _globalMintsPerWallet)
                    revert ExceedsMintsPerWallet();

                // Cap the number of tokens the user can mint so that it does not exceed the minting limit
                // per wallet across the whole contract
                if (mintsPerWallet + numberOfTokens > _globalMintsPerWallet) {
                    numberOfTokens = _globalMintsPerWallet - mintsPerWallet;
                }
            }

            // Cap the number of tokens the user can mint so that it does not exceed the minting limit
            // of tokens on sale for this stage
            if (currentMintedTokens + numberOfTokens > dropData.phaseLimit) {
                numberOfTokens = dropData.phaseLimit - currentMintedTokens;
            }

            // A value of 0 means there is no limit as to how many mints a wallet has been authorised to mint.
            // This form of mint authorisation is managed through pre-generated signatures - if the contract has
            // been released from signature minting then this check is omitted
            if (maxMintsPerWallet > 0 && !signatureReleased) {
                // Check that the user has not reached the minting limit per wallet they have been allowlisted for
                if (stageMintsPerWallet >= maxMintsPerWallet)
                    revert ExceedsMintsPerWallet();

                // Cap the number of tokens the user can mint so that it does not exceed the limit
                // of mints the wallet has been allowlisted for
                if (stageMintsPerWallet + numberOfTokens > maxMintsPerWallet) {
                    numberOfTokens = maxMintsPerWallet - stageMintsPerWallet;
                }
            }

            // Update the total number mints the recipient has done for this stage
            stageMintsPerWallet += numberOfTokens;
            stageMints[presentStage][recipient] = stageMintsPerWallet;
        }

        // Mint the NFTs
        _safeMint(recipient, numberOfTokens, nonce);

        // If the value for numberOfTokens is less than the origMintCount, then there is reimbursement
        // to be done
        if (numberOfTokens < origMintCount) {
            uint256 reimbursementPrice = (origMintCount - numberOfTokens) *
                dropData.price;
            (bool sent, ) = msg.sender.call{value: reimbursementPrice}("");
            if (!sent) revert ETHSendFail();
        }

        emit Mint(recipient, presentStage, numberOfTokens);
    }

    /**
     * @notice Verify merkle proof for address and address minting limit
     */
    function verifyMerkleAddress(
        bytes32[] calldata merkleProof,
        bytes32 _merkleRoot,
        address minterAddress,
        uint256 walletLimit
    ) private pure returns (bool) {
        return
            MerkleProofUpgradeable.verify(
                merkleProof,
                _merkleRoot,
                keccak256(abi.encodePacked(minterAddress, walletLimit))
            );
    }

    /**
     * @dev Mint token(s) for allowlist sales
     */
    function merkleMint(
        bytes32[] calldata _merkleProof,
        uint256 numberOfTokens,
        uint256 maxMintsPerWallet,
        address recipient
    ) external payable saleIsOpen {
        // Check the active stage - reverts if no stage is active
        uint256 presentStage = viewCurrentStage();

        // Load the minting parameters for this stage
        StageData memory dropData = stageMap[presentStage];

        // If a Merkle Root is not defined for the stage, then this is an public sale stage. Thus the function mint()
        // must be used instead
        if (dropData.merkleRoot == bytes32(0)) revert PublicStage();

        uint256 currentMintedTokens = _mintedTokens;

        // The number of minted tokens cannot exceed the number of NFTs on sale for this stage
        if (currentMintedTokens >= dropData.phaseLimit) revert PhaseLimitEnd();

        // Verify the Merkle Proof for the recipient address and the maximum number of mints the wallet has been assigned
        // on the allowlist
        if (
            !(
                verifyMerkleAddress(
                    _merkleProof,
                    dropData.merkleRoot,
                    recipient,
                    maxMintsPerWallet
                )
            )
        ) revert MerkleProofFail();

        // Check that enough ETH is sent for the minting quantity
        if (msg.value < dropData.price * numberOfTokens) revert NotEnoughETH();

        // At least 1 and no more than 20 tokens can be minted per transaction
        if (!((0 < numberOfTokens) && (numberOfTokens <= 20)))
            revert TokenLimitPerTx();

        // Load the total number of NFTs the user has minted across all stages
        uint256 mintsPerWallet = uint256(mintData[recipient].mintsPerWallet);

        // Load the number of NFTs the user has minted solely on the active stage
        uint256 stageMintsPerWallet = stageMints[presentStage][recipient];

        // Keep track of the user's original intent of tokens they want to mint, to be used for ETH reimbursement
        // later if necessary
        uint256 origMintCount = numberOfTokens;

        unchecked {
            // A value of 0 means there is no limit as to how many mints a wallet can do in this stage
            if (dropData.mintsPerWallet > 0) {
                // Check that the user has not reached the minting limit per wallet for this stage
                if (stageMintsPerWallet >= dropData.mintsPerWallet)
                    revert ExceedsMintsPerWallet();

                // Cap the number of tokens the user can mint so that it does not exceed the limit
                // per wallet for this stage
                if (
                    stageMintsPerWallet + numberOfTokens >
                    dropData.mintsPerWallet
                ) {
                    numberOfTokens =
                        dropData.mintsPerWallet -
                        stageMintsPerWallet;
                }
            }

            // A value of 0 means there is no limit as to how many mints a wallet has been allowlisted for
            if (maxMintsPerWallet > 0) {
                // Check that the user has not reached the minting limit per wallet they have been allowlisted for
                if (stageMintsPerWallet >= maxMintsPerWallet)
                    revert ExceedsMintsPerWallet();

                // Cap the number of tokens the user can mint so that it does not exceed the limit
                // of mints the wallet has been allowlisted for
                if (stageMintsPerWallet + numberOfTokens > maxMintsPerWallet) {
                    numberOfTokens = maxMintsPerWallet - stageMintsPerWallet;
                }
            }

            uint256 _globalMintsPerWallet = tokensAvailable
                .globalMintsPerWallet;

            // A value of 0 means there is no limit as to how many mints a wallet can do across all stages
            if (_globalMintsPerWallet > 0) {
                // Check that the user has not reached the minting limit per wallet across the whole contract
                if (mintsPerWallet >= _globalMintsPerWallet)
                    revert ExceedsMintsPerWallet();

                // Cap the number of tokens the user can mint so that it does not exceed the minting limit
                // per wallet across the whole contract
                if (mintsPerWallet + numberOfTokens > _globalMintsPerWallet) {
                    numberOfTokens = _globalMintsPerWallet - mintsPerWallet;
                }
            }

            // Cap the number of tokens the user can mint so that it does not exceed the minting limit
            // of tokens on sale for this stage
            if (currentMintedTokens + numberOfTokens > dropData.phaseLimit) {
                numberOfTokens = dropData.phaseLimit - currentMintedTokens;
            }

            // Update the total number mints the recipient has done for this stage
            stageMintsPerWallet += numberOfTokens;
            stageMints[presentStage][recipient] = stageMintsPerWallet;
        }

        // Mint NFTs
        _safeMint(recipient, numberOfTokens, block.number);

        // If the value for numberOfTokens is less than the origMintCount, then there is reimbursement
        // to be done
        if (numberOfTokens < origMintCount) {
            uint256 reimbursementPrice = (origMintCount - numberOfTokens) *
                dropData.price;
            (bool sent, ) = msg.sender.call{value: reimbursementPrice}("");
            if (!sent) revert ETHSendFail();
        }

        emit Mint(recipient, presentStage, numberOfTokens);
    }

    /**
     * @dev Only owner or Fair.xyz - withdraw contract balance to owner wallet. 6% primary sale fee to Fair.xyz
     */
    function withdraw() external payable nonReentrant {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                msg.sender == viewWithdraw(),
            "Not owner or Fair.xyz!"
        );
        uint256 contractBalance = address(this).balance;

        (bool sent, ) = viewWithdraw().call{value: (contractBalance * 3) / 50}(
            ""
        );
        if (!sent) revert ETHSendFail();

        uint256 remainingContractBalance = address(this).balance;
        (bool sent_, ) = _primarySaleReceiver.call{
            value: remainingContractBalance
        }("");
        if (!sent_) revert ETHSendFail();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC721xyzUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev overrides {UpdatableOperatorFilterUpgradeable} function to determine the role of operator filter admin
     */
    function _isOperatorFilterAdmin(address operator)
        internal
        view
        override
        returns (bool)
    {
        return hasRole(DEFAULT_ADMIN_ROLE, operator);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// @ Fair.xyz dev

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./UpdatableOperatorFiltererUpgradeable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, with modifications by the Fair.xyz team, thus setting the ERC721xyz standard
 */
abstract contract ERC721xyzUpgradeable is
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC721Upgradeable,
    ERC2981Upgradeable,
    IERC721MetadataUpgradeable,
    UpdatableOperatorFiltererUpgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Token mint count
    uint256 public _mintedTokens;

    // Token burnt count
    uint256 internal _burntTokens;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping from token ID to original owner address
    mapping(uint256 => address) private _origOwners;

    // Burnt tokens
    mapping(uint256 => bool) private _burnedTokens;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mint information per wallet
    struct minterData {
        uint96 balance;
        uint96 mintsPerWallet;
        uint64 blockNumber;
    }

    mapping(address => minterData) internal mintData;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981Upgradeable, ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return mintData[owner].balance;
    }

    /**
     * @dev Returns number of minted Tokens
     */
    function viewMinted() public view virtual returns (uint256) {
        return _mintedTokens;
    }

    // return all tokens
    function totalSupply() public view virtual returns (uint256) {
        return _mintedTokens - _burntTokens;
    }

    /**
     * @dev Mints a batch of `tokenIds` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     *
     * Emits {Transfer} events.
     */
    function _mint(
        address to,
        uint256 numberOfTokens,
        uint256 nonce
    ) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");

        _beforeTokenTransfer(address(0), to, _mintedTokens);

        uint256 orig_count = _mintedTokens;

        unchecked {
            uint256 new_count = orig_count + numberOfTokens;
            _mintedTokens = new_count;

            mintData[to].balance += uint96(numberOfTokens);

            // Nonce = 0 is for airdrop mints, which do not count towards wallet minting
            // limits or signature nonce updates
            if (nonce != 0) {
                mintData[to].mintsPerWallet += uint96(numberOfTokens);
                mintData[to].blockNumber = uint64(nonce);
            }

            _origOwners[new_count] = to;

            uint256 i = orig_count + 1;
            uint256 loop_ = new_count + 1;

            do {
                emit Transfer(address(0), to, i);
                ++i;
            } while (i < loop_);
        }

        _afterTokenTransfer(address(0), to, _mintedTokens);
    }

    /**
     * @dev Returns owner of token ID.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(_exists(tokenId), "ERC721xyz: Query for non existent token!");

        uint256 counter = tokenId;

        address _owner = _owners[tokenId];

        if (_owner == address(0)) {
            while (true) {
                _owner = _origOwners[counter];
                if (_owner != address(0)) {
                    return _owner;
                }
                unchecked {
                    ++counter;
                }
            }
        }

        return _owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId)
        public
        virtual
        override
        onlyAllowedOperatorApproval(to)
    {
        address owner = ERC721xyzUpgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        onlyAllowedOperatorApproval(operator)
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
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
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override onlyAllowedOperator(from) {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override onlyAllowedOperator(from) {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override onlyAllowedOperator(from) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        if (_burnedTokens[tokenId]) return false;

        return (0 < tokenId && tokenId <= _mintedTokens);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721xyzUpgradeable.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 tokenCount,
        uint256 nonce
    ) internal virtual {
        _safeMint(to, tokenCount, "", nonce);
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenCount,
        bytes memory _data,
        uint256 nonce
    ) internal virtual {
        _mint(to, tokenCount, nonce);
        require(
            _checkOnERC721Received(address(0), to, _mintedTokens, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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
    function _burn(uint256 tokenId) internal virtual {
        require(_exists(tokenId), "ERC721xyz: Query for nonexistent token!");
        address owner = ERC721xyzUpgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        unchecked {
            mintData[owner].balance -= 1;
            _burnedTokens[tokenId] = true;
            _burntTokens += 1;
        }

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721xyzUpgradeable.ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        unchecked {
            mintData[from].balance -= 1;
            mintData[to].balance += 1;
            _owners[tokenId] = to;
        }

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        address _approved = _tokenApprovals[tokenId];
        if (_approved != to) {
            _tokenApprovals[tokenId] = to;
            emit Approval(ERC721xyzUpgradeable.ownerOf(tokenId), to, tokenId);
        }
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721ReceiverUpgradeable(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return
                    retval ==
                    IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

// @ Fair.xyz dev

pragma solidity 0.8.17;

interface IFairXYZWallets {
    function viewWithdraw() external view returns (address);

    function viewPathURI(string memory pathURI_) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract MulticallUpgradeable is Initializable {
    function __Multicall_init() internal onlyInitializing {
    }

    function __Multicall_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = _functionDelegateCall(address(this), data[i]);
        }
        return results;
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981Upgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC2981Upgradeable is Initializable, IERC2981Upgradeable, ERC165Upgradeable {
    function __ERC2981_init() internal onlyInitializing {
    }

    function __ERC2981_init_unchained() internal onlyInitializing {
    }
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981Upgradeable
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT

// @author: Fair.xyz dev

pragma solidity 0.8.17;

import {IOperatorFilterRegistry} from "./OperatorFilterRegistry/IOperatorFilterRegistry.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract UpdatableOperatorFiltererUpgradeable is Initializable {
    error OnlyAdmin();
    error OperatorNotAllowed(address operator);
    error RegistryInvalid();

    event OperatorFilterDisabled(bool disabled);

    bool public operatorFilterDisabled;

    IOperatorFilterRegistry public operatorFilterRegistry;

    function __OperatorFilterer_init(
        address registry_,
        address subscriptionOrRegistrantToCopy,
        bool subscribe
    ) internal onlyInitializing {
        if (address(registry_).code.length > 0) {
            IOperatorFilterRegistry registry = IOperatorFilterRegistry(
                registry_
            );
            _registerAndSubscribe(
                registry,
                subscriptionOrRegistrantToCopy,
                subscribe
            );
            operatorFilterRegistry = registry;
        }
    }

    // * MODIFIERS * //

    modifier onlyAllowedOperator(address from) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (
            !operatorFilterDisabled &&
            address(operatorFilterRegistry).code.length > 0
        ) {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (from == msg.sender) {
                _;
                return;
            }
            if (
                !operatorFilterRegistry.isOperatorAllowed(
                    address(this),
                    msg.sender
                )
            ) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (
            !operatorFilterDisabled &&
            address(operatorFilterRegistry).code.length > 0
        ) {
            if (
                !operatorFilterRegistry.isOperatorAllowed(
                    address(this),
                    operator
                )
            ) {
                revert OperatorNotAllowed(operator);
            }
        }
        _;
    }

    modifier onlyOperatorFilterAdmin() {
        if (!_isOperatorFilterAdmin(msg.sender)) {
            revert OnlyAdmin();
        }
        _;
    }

    // * ADMIN * //

    /**
     * @notice Enable/Disable Operator Filter
     */
    function toggleOperatorFilterDisabled()
        public
        virtual
        onlyOperatorFilterAdmin
        returns (bool)
    {
        bool disabled = !operatorFilterDisabled;
        operatorFilterDisabled = disabled;
        emit OperatorFilterDisabled(disabled);
        return disabled;
    }

    /**
     * @notice Update Operator Filter Registry and optionally subscribe to registrant (if supplied)
     */
    function updateOperatorFilterRegistry(
        address newRegistry,
        address subscriptionOrRegistrantToCopy,
        bool subscribe
    ) public virtual onlyOperatorFilterAdmin {
        IOperatorFilterRegistry registry = IOperatorFilterRegistry(newRegistry);
        if (address(registry).code.length == 0) revert RegistryInvalid();

        // it is technically possible that the owner has already registered the contract with the registry directly
        // so we check before attempting to subscribe, otherwise it might revert without saving the address here
        if (!registry.isRegistered(address(this))) {
            _registerAndSubscribe(
                registry,
                subscriptionOrRegistrantToCopy,
                subscribe
            );
        }
        operatorFilterRegistry = registry;
    }

    /**
     * @notice Update Subcription at the current Operator Filter Registry
     */
    function updateRegistrySubscription(
        address subscriptionOrRegistrantToCopy,
        bool subscribe,
        bool copyEntries
    ) public virtual onlyOperatorFilterAdmin {
        IOperatorFilterRegistry registry = operatorFilterRegistry;
        if (address(registry).code.length == 0) revert RegistryInvalid();
        if (subscriptionOrRegistrantToCopy == address(0)) {
            registry.unsubscribe(address(this), copyEntries);
        } else {
            _registerAndSubscribe(
                registry,
                subscriptionOrRegistrantToCopy,
                subscribe
            );
        }
    }

    // * INTERNAL * //

    /**
     * @dev Inheriting contract is responsible for implementation
     */
    function _isOperatorFilterAdmin(address operator)
        internal
        view
        virtual
        returns (bool);

    /**
     * @dev Register and/or subscribe to/copy entries of registrant at the given registry
     */
    function _registerAndSubscribe(
        IOperatorFilterRegistry registry,
        address subscriptionOrRegistrantToCopy,
        bool subscribe
    ) internal virtual {
        if (registry.isRegistered(address(this))) {
            if (subscribe) {
                registry.subscribe(
                    address(this),
                    subscriptionOrRegistrantToCopy
                );
            } else {
                registry.copyEntriesOf(
                    address(this),
                    subscriptionOrRegistrantToCopy
                );
            }
        } else {
            if (subscribe) {
                registry.registerAndSubscribe(
                    address(this),
                    subscriptionOrRegistrantToCopy
                );
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    registry.registerAndCopyEntries(
                        address(this),
                        subscriptionOrRegistrantToCopy
                    );
                } else {
                    registry.register(address(this));
                }
            }
        }
    }

    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
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
pragma solidity 0.8.17;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator)
        external
        view
        returns (bool);

    function register(address registrant) external;

    function registerAndSubscribe(address registrant, address subscription)
        external;

    function registerAndCopyEntries(
        address registrant,
        address registrantToCopy
    ) external;

    function unregister(address addr) external;

    function updateOperator(
        address registrant,
        address operator,
        bool filtered
    ) external;

    function updateOperators(
        address registrant,
        address[] calldata operators,
        bool filtered
    ) external;

    function updateCodeHash(
        address registrant,
        bytes32 codehash,
        bool filtered
    ) external;

    function updateCodeHashes(
        address registrant,
        bytes32[] calldata codeHashes,
        bool filtered
    ) external;

    function subscribe(address registrant, address registrantToSubscribe)
        external;

    function unsubscribe(address registrant, bool copyExistingEntries) external;

    function subscriptionOf(address addr) external returns (address registrant);

    function subscribers(address registrant)
        external
        returns (address[] memory);

    function subscriberAt(address registrant, uint256 index)
        external
        returns (address);

    function copyEntriesOf(address registrant, address registrantToCopy)
        external;

    function isOperatorFiltered(address registrant, address operator)
        external
        returns (bool);

    function isCodeHashOfFiltered(address registrant, address operatorWithCode)
        external
        returns (bool);

    function isCodeHashFiltered(address registrant, bytes32 codeHash)
        external
        returns (bool);

    function filteredOperators(address addr)
        external
        returns (address[] memory);

    function filteredCodeHashes(address addr)
        external
        returns (bytes32[] memory);

    function filteredOperatorAt(address registrant, uint256 index)
        external
        returns (address);

    function filteredCodeHashAt(address registrant, uint256 index)
        external
        returns (bytes32);

    function isRegistered(address addr) external returns (bool);

    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}