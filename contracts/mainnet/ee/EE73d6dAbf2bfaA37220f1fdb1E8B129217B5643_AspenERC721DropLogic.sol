// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "./lib/CurrencyTransferLib.sol";
import "./lib/MerkleProof.sol";
import "./errors/IErrors.sol";
import "./types/DropERC721DataTypes.sol";
import "./../api/standard/IERC1155.sol";
import "./../api/royalties/IRoyalty.sol";

library AspenERC721DropLogic {
    using StringsUpgradeable for uint256;
    using AspenERC721DropLogic for DropERC721DataTypes.ClaimData;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    uint256 private constant MAX_UINT256 = 2**256 - 1;
    /// @dev Max basis points (bps) in Aspen system.
    uint256 public constant MAX_BPS = 10_000;
    /// @dev Offset for token IDs.
    uint8 public constant TOKEN_INDEX_OFFSET = 1;

    struct InternalClaim {
        bool validMerkleProof;
        uint256 merkleProofIndex;
        bool toVerifyMaxQuantityPerTransaction;
        uint256 activeConditionId;
        uint256 tokenIdToClaim;
        bytes32 phaseId;
    }

    function setClaimConditions(
        DropERC721DataTypes.ClaimData storage claimData,
        IDropClaimConditionV1.ClaimCondition[] calldata _phases,
        bool _resetClaimEligibility
    ) public {
        uint256 existingStartIndex = claimData.claimCondition.currentStartId;
        uint256 existingPhaseCount = claimData.claimCondition.count;

        uint256 newStartIndex = existingStartIndex;
        if (_resetClaimEligibility) {
            newStartIndex = existingStartIndex + existingPhaseCount;
        }

        claimData.claimCondition.count = _phases.length;
        claimData.claimCondition.currentStartId = newStartIndex;

        uint256 lastConditionStartTimestamp;
        bytes32[] memory phaseIds = new bytes32[](_phases.length);
        for (uint256 i = 0; i < _phases.length; i++) {
            if (!(i == 0 || lastConditionStartTimestamp < _phases[i].startTimestamp)) revert ST();

            for (uint256 j = 0; j < phaseIds.length; j++) {
                if (phaseIds[j] == _phases[i].phaseId) revert InvalidPhaseId(_phases[i].phaseId);
                if (i == j) phaseIds[i] = _phases[i].phaseId;
            }

            uint256 supplyClaimedAlready = claimData.claimCondition.phases[newStartIndex + i].supplyClaimed;

            if (_isOutOfLimits(_phases[i].maxClaimableSupply, supplyClaimedAlready))
                revert CrossedLimitMaxClaimableSupply();

            claimData.claimCondition.phases[newStartIndex + i] = _phases[i];
            claimData.claimCondition.phases[newStartIndex + i].supplyClaimed = supplyClaimedAlready;
            if (_phases[i].maxClaimableSupply == 0)
                claimData.claimCondition.phases[newStartIndex + i].maxClaimableSupply = MAX_UINT256;

            lastConditionStartTimestamp = _phases[i].startTimestamp;
        }

        /**
         *  Gas refunds (as much as possible)
         *
         *  If `_resetClaimEligibility == true`, we assign completely new UIDs to the claim
         *  conditions in `_phases`. So, we delete claim conditions with UID < `newStartIndex`.
         *
         *  If `_resetClaimEligibility == false`, and there are more existing claim conditions
         *  than in `_phases`, we delete the existing claim conditions that don't get replaced
         *  by the conditions in `_phases`.
         */
        if (_resetClaimEligibility) {
            for (uint256 i = existingStartIndex; i < newStartIndex; i++) {
                delete claimData.claimCondition.phases[i];
            }
        } else {
            if (existingPhaseCount > _phases.length) {
                for (uint256 i = _phases.length; i < existingPhaseCount; i++) {
                    delete claimData.claimCondition.phases[newStartIndex + i];
                }
            }
        }
    }

    function executeClaim(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction,
        address msgSender
    ) public returns (uint256[] memory tokens, InternalClaim memory internalData) {
        internalData.tokenIdToClaim = claimData.nextTokenIdToClaim;

        // Get the claim conditions.
        internalData.activeConditionId = getActiveClaimConditionId(claimData);
        internalData.phaseId = claimData.claimCondition.phases[internalData.activeConditionId].phaseId;

        /**
         *  We make allowlist checks (i.e. verifyClaimMerkleProof) before verifying the claim's general
         *  validity (i.e. verifyClaim) because we give precedence to the check of allow list quantity
         *  restriction over the check of the general claim condition's quantityLimitPerTransaction
         *  restriction.
         */

        // Verify inclusion in allowlist.
        (internalData.validMerkleProof, internalData.merkleProofIndex) = verifyClaimMerkleProof(
            claimData,
            internalData.activeConditionId,
            msgSender,
            _quantity,
            _proofs,
            _proofMaxQuantityPerTransaction
        );

        // Verify claim validity. If not valid, revert.
        // when there's allowlist present --> verifyClaimMerkleProof will verify the _proofMaxQuantityPerTransaction value with hashed leaf in the allowlist
        // when there's no allowlist, this check is true --> verifyClaim will check for _quantity being less/equal than the limit
        internalData.toVerifyMaxQuantityPerTransaction =
            _proofMaxQuantityPerTransaction == 0 ||
            claimData.claimCondition.phases[internalData.activeConditionId].merkleRoot == bytes32(0);

        verifyClaim(
            claimData,
            internalData.activeConditionId,
            msgSender,
            _quantity,
            _currency,
            _pricePerToken,
            internalData.toVerifyMaxQuantityPerTransaction
        );

        // If there's a price, collect price.
        claimData.collectClaimPrice(_quantity, _currency, _pricePerToken, msgSender);

        // Book-keeping before the calling contract does the actual transfer and mint the relevant NFTs to claimer.
        tokens = recordTransferClaimedTokens(claimData, internalData.activeConditionId, _quantity, msgSender);
    }

    function verifyClaimMerkleProof(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        address _claimer,
        uint256 _quantity,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    ) public view returns (bool validMerkleProof, uint256 merkleProofIndex) {
        IDropClaimConditionV1.ClaimCondition memory currentClaimPhase = claimData.claimCondition.phases[_conditionId];

        if (currentClaimPhase.merkleRoot != bytes32(0)) {
            (validMerkleProof, merkleProofIndex) = MerkleProof.verify(
                _proofs,
                currentClaimPhase.merkleRoot,
                keccak256(abi.encodePacked(_claimer, _proofMaxQuantityPerTransaction))
            );

            if (!validMerkleProof) revert InvalidMerkleProof();
            if (
                !(_proofMaxQuantityPerTransaction == 0 ||
                    _quantity <=
                    _proofMaxQuantityPerTransaction -
                        claimData.claimCondition.userClaims[_conditionId][_claimer].claimedBalance)
            ) revert InvalidMaxQuantityProof();
        }
    }

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        address _claimer,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) public view {
        IDropClaimConditionV1.ClaimCondition memory currentClaimPhase = claimData.claimCondition.phases[_conditionId];

        if (!(_currency == currentClaimPhase.currency && _pricePerToken == currentClaimPhase.pricePerToken)) {
            revert InvalidPrice();
        }
        // If we're checking for an allowlist quantity restriction, ignore the general quantity restriction.
        if (
            !(_quantity > 0 &&
                (!verifyMaxQuantityPerTransaction || _quantity <= currentClaimPhase.quantityLimitPerTransaction))
        ) {
            revert CrossedLimitQuantityPerTransaction();
        }
        if (!(currentClaimPhase.supplyClaimed + _quantity <= currentClaimPhase.maxClaimableSupply)) {
            revert CrossedLimitMaxClaimableSupply();
        }
        // nextTokenIdToMint is the supremum of all tokens currently lazy minted so this is just checking we are no
        // trying to claim a token that has not yet been lazyminted (therefore has no URI)
        if (!(claimData.nextTokenIdToClaim + _quantity <= claimData.nextTokenIdToMint)) {
            revert CrossedLimitLazyMintedTokens();
        }
        if (_isOutOfLimits(claimData.maxTotalSupply, claimData.nextTokenIdToClaim - TOKEN_INDEX_OFFSET + _quantity)) {
            revert CrossedLimitMaxTotalSupply();
        }
        if (_isOutOfLimits(claimData.maxWalletClaimCount, claimData.walletClaimCount[_claimer] + _quantity)) {
            revert CrossedLimitMaxWalletClaimCount();
        }
        (uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp) = getClaimTimestamp(
            claimData,
            _conditionId,
            _claimer
        );
        if (!(lastClaimTimestamp == 0 || block.timestamp >= nextValidClaimTimestamp)) revert InvalidTime();
    }

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function collectClaimPrice(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken,
        address msgSender
    ) internal {
        if (_pricePerToken == 0) {
            return;
        }

        uint256 totalPrice = _quantityToClaim * _pricePerToken;
        uint256 platformFees = (totalPrice * claimData.platformFeeBps) / MAX_BPS;

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN && !(msg.value == totalPrice)) revert InvalidPaymentAmount();

        CurrencyTransferLib.transferCurrency(_currency, msgSender, claimData.platformFeeRecipient, platformFees);
        CurrencyTransferLib.transferCurrency(
            _currency,
            msgSender,
            claimData.primarySaleRecipient,
            totalPrice - platformFees
        );
    }

    /// @dev Book-keeping before the calling contract does the actual transfer and mint the relevant NFTs to claimer.
    function recordTransferClaimedTokens(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        uint256 _quantityBeingClaimed,
        address msgSender
    ) public returns (uint256[] memory tokenIds) {
        // Update the supply minted under mint condition.
        claimData.claimCondition.phases[_conditionId].supplyClaimed += _quantityBeingClaimed;

        // if transfer claimed tokens is called when `to != msg.sender`, it'd use msg.sender's limits.
        // behavior would be similar to `msg.sender` mint for itself, then transfer to `_to`.
        claimData.claimCondition.userClaims[_conditionId][msgSender].lastClaimTimestamp = block.timestamp;
        claimData.claimCondition.userClaims[_conditionId][msgSender].claimedBalance += _quantityBeingClaimed;
        claimData.walletClaimCount[msgSender] += _quantityBeingClaimed;

        tokenIds = transferTokens(claimData, _quantityBeingClaimed);
    }

    function verifyIssue(DropERC721DataTypes.ClaimData storage claimData, uint256 _quantity)
        public
        returns (uint256[] memory tokenIds)
    {
        if (_quantity == 0) {
            revert InvalidQuantity();
        }
        uint256 nextNextTokenIdToMint = claimData.nextTokenIdToClaim + _quantity;
        if (nextNextTokenIdToMint > claimData.nextTokenIdToMint) {
            revert CrossedLimitLazyMintedTokens();
        }
        if (claimData.maxTotalSupply != 0 && nextNextTokenIdToMint - TOKEN_INDEX_OFFSET > claimData.maxTotalSupply) {
            revert CrossedLimitMaxTotalSupply();
        }
        tokenIds = transferTokens(claimData, _quantity);
    }

    function setTokenURI(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        string memory _tokenURI,
        bool _isPermanent
    ) public {
        // Interpret empty string as unsetting tokenURI
        if (bytes(_tokenURI).length == 0) {
            claimData.tokenURIs[_tokenId].sequenceNumber = 0;
            return;
        }
        // Bump the sequence first
        claimData.uriSequenceCounter.increment();
        claimData.tokenURIs[_tokenId].uri = _tokenURI;
        claimData.tokenURIs[_tokenId].sequenceNumber = claimData.uriSequenceCounter.current();
        claimData.tokenURIs[_tokenId].isPermanent = _isPermanent;
    }

    function tokenURI(DropERC721DataTypes.ClaimData storage claimData, uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        // Try to fetch possibly overridden tokenURI
        DropERC721DataTypes.SequencedURI storage _tokenURI = claimData.tokenURIs[_tokenId];

        for (uint256 i = 0; i < claimData.baseURIIndices.length; i += 1) {
            if (_tokenId < claimData.baseURIIndices[i] + TOKEN_INDEX_OFFSET) {
                DropERC721DataTypes.SequencedURI storage _baseURI = claimData.baseURI[
                    claimData.baseURIIndices[i] + TOKEN_INDEX_OFFSET
                ];
                if (_tokenURI.sequenceNumber > _baseURI.sequenceNumber || _tokenURI.isPermanent) {
                    // If the specifically set tokenURI is fresher than the baseURI OR
                    // if the tokenURI is permanet then return that (it is in-force)
                    return _tokenURI.uri;
                }
                // Otherwise either there is no override (sequenceNumber == 0) or the baseURI is fresher, so return the
                // baseURI-derived tokenURI
                return string(abi.encodePacked(_baseURI.uri, _tokenId.toString()));
            }
        }
        return "";
    }

    function lazyMint(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _amount,
        string calldata _baseURIForTokens
    ) public returns (uint256 startId, uint256 baseURIIndex) {
        if (_amount == 0) revert InvalidNoOfTokenIds();
        claimData.uriSequenceCounter.increment();
        startId = claimData.nextTokenIdToMint;
        baseURIIndex = startId + _amount;

        claimData.nextTokenIdToMint = baseURIIndex;
        claimData.baseURI[baseURIIndex].uri = _baseURIForTokens;
        claimData.baseURI[baseURIIndex].sequenceNumber = claimData.uriSequenceCounter.current();
        claimData.baseURI[baseURIIndex].amountOfTokens = _amount;
        claimData.baseURIIndices.push(baseURIIndex - TOKEN_INDEX_OFFSET);
    }

    function transferTokens(DropERC721DataTypes.ClaimData storage claimData, uint256 _quantityBeingClaimed)
        public
        returns (uint256[] memory tokenIds)
    {
        uint256 tokenIdToClaim = claimData.nextTokenIdToClaim;

        tokenIds = new uint256[](_quantityBeingClaimed);

        for (uint256 i = 0; i < _quantityBeingClaimed; i += 1) {
            tokenIds[i] = tokenIdToClaim;
            tokenIdToClaim += 1;
        }

        claimData.nextTokenIdToClaim = tokenIdToClaim;
    }

    function getActiveClaimConditions(DropERC721DataTypes.ClaimData storage claimData)
        public
        view
        returns (
            IDropClaimConditionV1.ClaimCondition memory condition,
            uint256 conditionId,
            uint256 walletMaxClaimCount,
            uint256 maxTotalSupply
        )
    {
        conditionId = getActiveClaimConditionId(claimData);
        condition = claimData.claimCondition.phases[conditionId];
        walletMaxClaimCount = claimData.maxWalletClaimCount;
        maxTotalSupply = claimData.maxTotalSupply;
    }

    /// @dev Returns the claim condition at the given uid.
    function getClaimConditionById(DropERC721DataTypes.ClaimData storage claimData, uint256 _conditionId)
        external
        view
        returns (IDropClaimConditionV1.ClaimCondition memory condition)
    {
        condition = claimData.claimCondition.phases[_conditionId];
    }

    /// @dev Returns the user specific limits related to the current active claim condition
    function getUserClaimConditions(DropERC721DataTypes.ClaimData storage claimData, address _claimer)
        public
        view
        returns (
            uint256 conditionId,
            uint256 walletClaimedCount,
            uint256 walletClaimedCountInPhase,
            uint256 lastClaimTimestamp,
            uint256 nextValidClaimTimestamp
        )
    {
        conditionId = getActiveClaimConditionId(claimData);
        (lastClaimTimestamp, nextValidClaimTimestamp) = getClaimTimestamp(claimData, conditionId, _claimer);
        walletClaimedCount = claimData.walletClaimCount[_claimer];
        walletClaimedCountInPhase = claimData.claimCondition.userClaims[conditionId][_claimer].claimedBalance;
    }

    /// @dev Returns the current active claim condition ID.
    function getActiveClaimConditionId(DropERC721DataTypes.ClaimData storage claimData) public view returns (uint256) {
        for (
            uint256 i = claimData.claimCondition.currentStartId + claimData.claimCondition.count;
            i > claimData.claimCondition.currentStartId;
            i--
        ) {
            if (block.timestamp >= claimData.claimCondition.phases[i - 1].startTimestamp) {
                return i - 1;
            }
        }

        revert NoActiveMintCondition();
    }

    /// @dev Returns the timestamp for when a claimer is eligible for claiming NFTs again.
    function getClaimTimestamp(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        address _claimer
    ) public view returns (uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp) {
        lastClaimTimestamp = claimData.claimCondition.userClaims[_conditionId][_claimer].lastClaimTimestamp;

        unchecked {
            nextValidClaimTimestamp =
                lastClaimTimestamp +
                claimData.claimCondition.phases[_conditionId].waitTimeInSecondsBetweenClaims;

            if (nextValidClaimTimestamp < lastClaimTimestamp) {
                nextValidClaimTimestamp = type(uint256).max;
            }
        }
    }

    /// @dev Returns the royalty recipient and bps for a particular token Id.
    function getRoyaltyInfoForToken(DropERC721DataTypes.ClaimData storage claimData, uint256 _tokenId)
        public
        view
        returns (address, uint16)
    {
        IRoyaltyV0.RoyaltyInfo memory royaltyForToken = claimData.royaltyInfoForToken[_tokenId];

        return
            royaltyForToken.recipient == address(0)
                ? (claimData.royaltyRecipient, uint16(claimData.royaltyBps))
                : (royaltyForToken.recipient, uint16(royaltyForToken.bps));
    }

    /// @dev See ERC-2891 - Returns the royalty recipient and amount, given a tokenId and sale price.
    function royaltyInfo(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        (address recipient, uint256 bps) = getRoyaltyInfoForToken(claimData, tokenId);
        receiver = recipient;
        royaltyAmount = (salePrice * bps) / MAX_BPS;
    }

    function setDefaultRoyaltyInfo(
        DropERC721DataTypes.ClaimData storage claimData,
        address _royaltyRecipient,
        uint256 _royaltyBps
    ) external {
        if (!(_royaltyBps <= MAX_BPS)) revert MaxBps();
        claimData.royaltyRecipient = _royaltyRecipient;
        claimData.royaltyBps = uint16(_royaltyBps);
    }

    function setRoyaltyInfoForToken(
        DropERC721DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) external {
        if (!(_bps <= MAX_BPS)) revert MaxBps();
        claimData.royaltyInfoForToken[_tokenId] = IRoyaltyV0.RoyaltyInfo({recipient: _recipient, bps: _bps});
    }

    /// @dev Checks if a value is outside of a limit.
    /// @param _limit The limit to check against.
    /// @param _value The value to check.
    /// @return True if the value is there is a limit and it's outside of that limit.
    function _isOutOfLimits(uint256 _limit, uint256 _value) internal pure returns (bool) {
        return _limit != 0 && !(_value <= _limit);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

// Helper interfaces
import {IWETH} from "../interfaces/IWETH.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library CurrencyTransferLib {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev The address interpreted as native token of the chain.
    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Transfers a given amount of currency.
    function transferCurrency(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            return;
        }

        if (_currency == NATIVE_TOKEN) {
            safeTransferNativeToken(_to, _amount);
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    /// @dev Transfers a given amount of currency. (With native token wrapping)
    function transferCurrencyWithWrapper(
        address _currency,
        address _from,
        address _to,
        uint256 _amount,
        address _nativeTokenWrapper
    ) internal {
        if (_amount == 0) {
            return;
        }

        if (_currency == NATIVE_TOKEN) {
            if (_from == address(this)) {
                // withdraw from weth then transfer withdrawn native token to recipient
                IWETH(_nativeTokenWrapper).withdraw(_amount);
                safeTransferNativeTokenWithWrapper(_to, _amount, _nativeTokenWrapper);
            } else if (_to == address(this)) {
                // store native currency in weth
                require(_amount == msg.value, "msg.value != amount");
                IWETH(_nativeTokenWrapper).deposit{value: _amount}();
            } else {
                safeTransferNativeTokenWithWrapper(_to, _amount, _nativeTokenWrapper);
            }
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    /// @dev Transfer `amount` of ERC20 token from `from` to `to`.
    function safeTransferERC20(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_from == _to) {
            return;
        }

        if (_from == address(this)) {
            IERC20Upgradeable(_currency).safeTransfer(_to, _amount);
        } else {
            IERC20Upgradeable(_currency).safeTransferFrom(_from, _to, _amount);
        }
    }

    /// @dev Transfers `amount` of native token to `to`.
    function safeTransferNativeToken(address to, uint256 value) internal {
        // solhint-disable avoid-low-level-calls
        // slither-disable-next-line low-level-calls
        (bool success, ) = to.call{value: value}("");
        require(success, "native token transfer failed");
    }

    /// @dev Transfers `amount` of native token to `to`. (With native token wrapping)
    function safeTransferNativeTokenWithWrapper(
        address to,
        uint256 value,
        address _nativeTokenWrapper
    ) internal {
        // solhint-disable avoid-low-level-calls
        // slither-disable-next-line low-level-calls
        (bool success, ) = to.call{value: value}("");
        if (!success) {
            IWETH(_nativeTokenWrapper).deposit{value: value}();
            IERC20Upgradeable(_nativeTokenWrapper).safeTransfer(to, value);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

error InvalidPermission();
error InvalidIndex();
error NothingToReveal();
error Bot();
error ST();
error CrossedLimitLazyMintedTokens();
error CrossedLimitMinTokenIdGreaterThanMaxTotalSupply();
error CrossedLimitQuantityPerTransaction();
error CrossedLimitMaxClaimableSupply();
error CrossedLimitMaxTotalSupply();
error CrossedLimitMaxWalletClaimCount();
error InvalidPrice();
error InvalidPaymentAmount();
error InvalidQuantity();
error InvalidTime();
error InvalidGating();
error InvalidMerkleProof();
error InvalidMaxQuantityProof();
error MaxBps();
error ClaimPaused();
error NoActiveMintCondition();
error TermsNotAccepted(address caller, string termsURI, uint8 acceptedVersion);
error BaseURIEmpty();
error FrozenTokenMetadata(uint256 tokenId);
error InvalidTokenId(uint256 tokenId);
error InvalidNoOfTokenIds();
error InvalidPhaseId(bytes32 phaseId);

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "../../api/issuance/IDropClaimCondition.sol";
import "../../api/royalties/IRoyalty.sol";

interface DropERC721DataTypes {
    struct SequencedURI {
        /// @dev The URI with the token metadata.
        string uri;
        /// @dev The high-watermark sequence number a URI - used to tell if one URI is fresher than a another
        /// taken from the current value of uriSequenceCounter after it is incremented.
        uint256 sequenceNumber;
        /// @dev Indicates if a uri is permanent or not.
        bool isPermanent;
        /// @dev Indicates the number of tokens in this batch.
        uint256 amountOfTokens;
    }

    struct ClaimData {
        /// @dev The set of all claim conditions, at any given moment.
        IDropClaimConditionV1.ClaimConditionList claimCondition;
        /// @dev The next token ID of the NFT that can be claimed.
        uint256 nextTokenIdToClaim;
        /// @dev Mapping from address => total number of NFTs a wallet has claimed.
        mapping(address => uint256) walletClaimCount;
        /// @dev The next token ID of the NFT to "lazy mint".
        uint256 nextTokenIdToMint;
        /// @dev Global max total supply of NFTs.
        uint256 maxTotalSupply;
        /// @dev The max number of NFTs a wallet can claim.
        uint256 maxWalletClaimCount;
        /// @dev The address that receives all primary sales value.
        address primarySaleRecipient;
        /// @dev The address that receives all platform fees from all sales.
        address platformFeeRecipient;
        /// @dev The % of primary sales collected as platform fees.
        uint16 platformFeeBps;
        /// @dev The recipient of who gets the royalty.
        address royaltyRecipient;
        /// @dev The (default) address that receives all royalty value.
        uint16 royaltyBps;
        /// @dev Mapping from token ID => royalty recipient and bps for tokens of the token ID.
        mapping(uint256 => IRoyaltyV0.RoyaltyInfo) royaltyInfoForToken;
        /// @dev Sequence number counter for the synchronisation of per-token URIs and baseURIs relative base on which
        /// was set most recently. Incremented on each URI-mutating action.
        CountersUpgradeable.Counter uriSequenceCounter;
        /// @dev One more than the Largest tokenId of each batch of tokens with the same baseURI
        uint256[] baseURIIndices;
        /// @dev Mapping from the 'base URI index' defined as the tokenId one more than the largest tokenId a batch of
        /// tokens which all same the same baseURI.
        /// Suppose we have two batches (and two baseURIs), with 3 and 4 tokens respectively, then in pictures we have:
        /// [baseURI1 | baseURI2]
        /// [ 0, 1, 2 | 3, 4, 5, 6]
        /// The baseURIIndices would be:
        /// [ 3, 7]
        mapping(uint256 => SequencedURI) baseURI;
        // Optional mapping for token URIs
        mapping(uint256 => SequencedURI) tokenURIs;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IERC1155V0 is IERC1155Upgradeable {}

interface IERC1155V1 is IERC1155Upgradeable {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;
}

interface IERC1155V2 is IERC1155V1 {
    function name() external returns (string memory);

    function symbol() external returns (string memory);
}

interface IERC1155SupplyV0 is IERC1155V0 {
    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) external view returns (bool);
}

interface IERC1155SupplyV1 is IERC1155SupplyV0 {
    /**
     * @dev Amount of unique tokens minted.
     */
    function getLargestTokenId() external view returns (uint256);
}

interface IERC1155SupplyV2 is IERC1155V1 {
    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) external view returns (bool);

    /**
     * @dev Amount of unique tokens minted.
     */
    function getLargestTokenId() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "../standard/IERC2981.sol";

interface IRoyaltyV0 is IERC2981V0 {
    struct RoyaltyInfo {
        address recipient;
        uint256 bps;
    }

    /// @dev Returns the royalty recipient and fee bps.
    function getDefaultRoyaltyInfo() external view returns (address, uint16);

    /// @dev Lets a module admin update the royalty bps and recipient.
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) external;

    /// @dev Lets a module admin set the royalty recipient for a particular token Id.
    function setRoyaltyInfoForToken(
        uint256 tokenId,
        address recipient,
        uint256 bps
    ) external;

    /// @dev Returns the royalty recipient for a particular token Id.
    function getRoyaltyInfoForToken(uint256 tokenId) external view returns (address, uint16);

    /// @dev Emitted when royalty info is updated.
    event DefaultRoyalty(address newRoyaltyRecipient, uint256 newRoyaltyBps);

    /// @dev Emitted when royalty recipient for tokenId is set
    event RoyaltyForToken(uint256 indexed tokenId, address royaltyRecipient, uint256 royaltyBps);
}

interface IPublicRoyaltyV0 is IERC2981V0 {
    struct RoyaltyInfo {
        address recipient;
        uint256 bps;
    }

    /// @dev Returns the royalty recipient and fee bps.
    function getDefaultRoyaltyInfo() external view returns (address, uint16);

    /// @dev Returns the royalty recipient for a particular token Id.
    function getRoyaltyInfoForToken(uint256 tokenId) external view returns (address, uint16);
}

interface IRestrictedRoyaltyV0 {
    /// @dev Lets a module admin update the royalty bps and recipient.
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) external;

    /// @dev Lets a module admin set the royalty recipient for a particular token Id.
    function setRoyaltyInfoForToken(
        uint256 tokenId,
        address recipient,
        uint256 bps
    ) external;
}

interface IRestrictedRoyaltyV1 is IRestrictedRoyaltyV0 {
    /// @dev Emitted when royalty info is updated.
    event DefaultRoyalty(address newRoyaltyRecipient, uint256 newRoyaltyBps);
    /// @dev Emitted when royalty recipient for tokenId is set
    event RoyaltyForToken(uint256 indexed tokenId, address royaltyRecipient, uint256 royaltyBps);
}

interface IRestrictedRoyaltyV2 is IRestrictedRoyaltyV1 {
    /// @dev Emitted when the operator filter is updated.
    event OperatorFilterStatusUpdated(bool enabled);

    /// @dev allows an admin to enable / disable the operator filterer.
    function setOperatorFiltererStatus(bool _enabled) external;
}

// SPDX-License-Identifier: MIT
// Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/utils/cryptography/MerkleProof.sol
// Copied from https://github.com/ensdomains/governance/blob/master/contracts/MerkleProof.sol

pragma solidity ^0.8;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * Source: https://github.com/ensdomains/governance/blob/master/contracts/MerkleProof.sol
 */
library MerkleProof {
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
    ) internal pure returns (bool, uint256) {
        bytes32 computedHash = leaf;
        uint256 index = 0;

        for (uint256 i = 0; i < proof.length; i++) {
            index *= 2;
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
                index += 1;
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return (computedHash == root, index);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";

/**
 *  Cedar's 'Drop' contracts are distribution mechanisms for tokens.
 *
 *  A contract admin (i.e. a holder of `DEFAULT_ADMIN_ROLE`) can set a series of claim conditions,
 *  ordered by their respective `startTimestamp`. A claim condition defines criteria under which
 *  accounts can mint tokens. Claim conditions can be overwritten or added to by the contract admin.
 *  At any moment, there is only one active claim condition.
 */

interface IDropClaimConditionV0 {
    /**
     *  @notice The criteria that make up a claim condition.
     *
     *  @param startTimestamp                 The unix timestamp after which the claim condition applies.
     *                                        The same claim condition applies until the `startTimestamp`
     *                                        of the next claim condition.
     *
     *  @param maxClaimableSupply             The maximum total number of tokens that can be claimed under
     *                                        the claim condition.
     *
     *  @param supplyClaimed                  At any given point, the number of tokens that have been claimed
     *                                        under the claim condition.
     *
     *  @param quantityLimitPerTransaction    The maximum number of tokens that can be claimed in a single
     *                                        transaction.
     *
     *  @param waitTimeInSecondsBetweenClaims The least number of seconds an account must wait after claiming
     *                                        tokens, to be able to claim tokens again.
     *
     *  @param merkleRoot                     The allowlist of addresses that can claim tokens under the claim
     *                                        condition.
     *
     *  @param pricePerToken                  The price required to pay per token claimed.
     *
     *  @param currency                       The currency in which the `pricePerToken` must be paid.
     */
    struct ClaimCondition {
        uint256 startTimestamp;
        uint256 maxClaimableSupply;
        uint256 supplyClaimed;
        uint256 quantityLimitPerTransaction;
        uint256 waitTimeInSecondsBetweenClaims;
        bytes32 merkleRoot;
        uint256 pricePerToken;
        address currency;
    }

    /**
     *  @notice The set of all claim conditions, at any given moment.
     *  Claim Phase ID = [currentStartId, currentStartId + length - 1];
     *
     *  @param currentStartId           The uid for the first claim condition amongst the current set of
     *                                  claim conditions. The uid for each next claim condition is one
     *                                  more than the previous claim condition's uid.
     *
     *  @param count                    The total number of phases / claim conditions in the list
     *                                  of claim conditions.
     *
     *  @param phases                   The claim conditions at a given uid. Claim conditions
     *                                  are ordered in an ascending order by their `startTimestamp`.
     *
     *  @param claimDetails             Map from an account and uid for a claim condition, to the claim
     *                                  records an account has done.
     *
     */
    struct ClaimConditionList {
        uint256 currentStartId;
        uint256 count;
        mapping(uint256 => ClaimCondition) phases;
        mapping(uint256 => mapping(address => ClaimDetails)) userClaims;
    }

    /**
     *  @notice Claim detail for a user claim.
     *
     *  @param lastClaimTimestamp    The timestamp at which the last token was claimed.
     *
     *  @param claimedBalance        The number of tokens claimed.
     *
     */
    struct ClaimDetails {
        uint256 lastClaimTimestamp;
        uint256 claimedBalance;
    }
}

interface IDropClaimConditionV1 {
    /**
     *  @notice The criteria that make up a claim condition.
     *
     *  @param startTimestamp                 The unix timestamp after which the claim condition applies.
     *                                        The same claim condition applies until the `startTimestamp`
     *                                        of the next claim condition.
     *
     *  @param maxClaimableSupply             The maximum total number of tokens that can be claimed under
     *                                        the claim condition.
     *
     *  @param supplyClaimed                  At any given point, the number of tokens that have been claimed
     *                                        under the claim condition.
     *
     *  @param quantityLimitPerTransaction    The maximum number of tokens that can be claimed in a single
     *                                        transaction.
     *
     *  @param waitTimeInSecondsBetweenClaims The least number of seconds an account must wait after claiming
     *                                        tokens, to be able to claim tokens again.
     *
     *  @param merkleRoot                     The allowlist of addresses that can claim tokens under the claim
     *                                        condition.
     *
     *  @param pricePerToken                  The price required to pay per token claimed.
     *
     *  @param currency                       The currency in which the `pricePerToken` must be paid.
     */
    struct ClaimCondition {
        uint256 startTimestamp;
        uint256 maxClaimableSupply;
        uint256 supplyClaimed;
        uint256 quantityLimitPerTransaction;
        uint256 waitTimeInSecondsBetweenClaims;
        bytes32 merkleRoot;
        uint256 pricePerToken;
        address currency;
        bytes32 phaseId;
    }

    /**
     *  @notice The set of all claim conditions, at any given moment.
     *  Claim Phase ID = [currentStartId, currentStartId + length - 1];
     *
     *  @param currentStartId           The uid for the first claim condition amongst the current set of
     *                                  claim conditions. The uid for each next claim condition is one
     *                                  more than the previous claim condition's uid.
     *
     *  @param count                    The total number of phases / claim conditions in the list
     *                                  of claim conditions.
     *
     *  @param phases                   The claim conditions at a given uid. Claim conditions
     *                                  are ordered in an ascending order by their `startTimestamp`.
     *
     *  @param claimDetails             Map from an account and uid for a claim condition, to the claim
     *                                  records an account has done.
     *
     */
    struct ClaimConditionList {
        uint256 currentStartId;
        uint256 count;
        mapping(uint256 => ClaimCondition) phases;
        mapping(uint256 => mapping(address => ClaimDetails)) userClaims;
    }

    /**
     *  @notice Claim detail for a user claim.
     *
     *  @param lastClaimTimestamp    The timestamp at which the last token was claimed.
     *
     *  @param claimedBalance        The number of tokens claimed.
     *
     */
    struct ClaimDetails {
        uint256 lastClaimTimestamp;
        uint256 claimedBalance;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMapsUpgradeable {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

interface IERC2981V0 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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