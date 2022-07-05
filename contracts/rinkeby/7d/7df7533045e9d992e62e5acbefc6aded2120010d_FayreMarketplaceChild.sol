// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "./FayreMultichainBaseUpgradable.sol";
import "./interfaces/IERC20UpgradeableExtended.sol";
import "./interfaces/IFayreMembershipCard721.sol";
import "./interfaces/IFayreTokenLocker.sol";

contract FayreMarketplaceChild is FayreMultichainBaseUpgradable {
    /**
        E#1: membership card address not found
        E#2: membership card address already present
        E#3: unable to send to creator
        E#4: token locker address not found 
        E#5: unable to send to treasury
        E#6: token locker address already present
        E#7: unable to send to sale owner
        E#8: multichain membership card data already processed
        E#9: not the owner of the multichain tokens locked
        E#10: not the owner of the multichain membership card
    */

    enum AssetType {
        ERC20,
        ERC721,
        ERC1155
    }
    
    struct TokenData {
        address creator;
        AssetType assetType;
        uint256 royaltiesPct;
    }

    struct MultichainTransactionData {
        AssetType assetType;
        address collectionAddress;
        uint256 tokenId;
        uint256 nftAmount;
        address tokenAddress;
        uint256 amount;
        address seller;
        address buyer;
        uint256 saleId;
        uint256 bidId;
        MultichainMembershipCardData[3] multichainMembershipCardsData;
        MultichainTokenLockerData multichainTokenLockerData;
    }

    struct MultichainMembershipCardData {
        address owner;
        uint256 tokenId;
        uint256 volume;
        uint256 nftPriceCap;
        uint256 blockNumber;
    }

    struct MultichainTokenLockerData {
        address owner;
        uint256 amount;
        uint256 blockNumber;
    }

    event ERC20Transfer(address indexed tokenAddress, address indexed from, address indexed to, uint256 amount);
    event ERC721Transfer(address indexed collectionAddress, address indexed from, address indexed to, uint256 tokenId);
    event ERC1155Transfer(address indexed collectionAddress, address indexed from, address indexed to, uint256 tokenId, uint256 amount);
    event ExecuteSale(uint256 indexed saleId, MultichainTransactionData multichainTransactionData, uint256 blockNumber);
    event ExecuteFreeOffer(uint256 indexed bidId, MultichainTransactionData multichainTransactionData, uint256 blockNumber);

    uint256 public tradeFeePct;
    address public treasuryAddress;
    address[] public membershipCardsAddresses;
    address public tokenLockerAddress;  
    uint256 public tokenLockerRequiredAmount;
    mapping(bytes32 => bool) public isMultichainMembershipCardDataMessageHashProcessed;

    mapping(address => mapping(uint256 => TokenData)) private _tokensData;

    function setTradeFee(uint256 newTradeFeePct) external onlyOwner {
        tradeFeePct = newTradeFeePct;
    }

    function setTreasury(address newTreasuryAddress) external onlyOwner {
        treasuryAddress = newTreasuryAddress;
    }

    function addMembershipCardAddress(address membershipCardsAddress) external onlyOwner {
        for (uint256 i = 0; i < membershipCardsAddresses.length; i++)
            if (membershipCardsAddresses[i] == membershipCardsAddress)
                revert("E#2");

        membershipCardsAddresses.push(membershipCardsAddress);
    }

    function removeMembershipCardAddress(address membershipCardsAddress) external onlyOwner {
        uint256 indexToDelete = type(uint256).max;

        for (uint256 i = 0; i < membershipCardsAddresses.length; i++)
            if (membershipCardsAddresses[i] == membershipCardsAddress)
                indexToDelete = i;

        require(indexToDelete != type(uint256).max, "E#1");

        membershipCardsAddresses[indexToDelete] = membershipCardsAddresses[membershipCardsAddresses.length - 1];

        membershipCardsAddresses.pop();
    }

    function setTokenLockerAddress(address newTokenLockerAddress) external onlyOwner {
        tokenLockerAddress = newTokenLockerAddress;
    }

    function setTokenLockerRequiredAmount(uint256 newTokenLockerRequiredAmount) external onlyOwner {
        tokenLockerRequiredAmount = newTokenLockerRequiredAmount;
    }

    function initialize() public initializer {
        __FayreMultichainBaseUpgradable_init();
    }

    function _executeFunctionWithSignedData(FayreMultichainMessage memory fayreMultichainMessage) internal override {
        if (fayreMultichainMessage.functionIndex == 1)
            _executeSale(fayreMultichainMessage);
        else if (fayreMultichainMessage.functionIndex == 2)
            _executeFreeOffer(fayreMultichainMessage);     
    }

    function _executeSale(FayreMultichainMessage memory fayreMultichainMessage) internal {
        MultichainTransactionData memory multichainTransactionData = abi.decode(fayreMultichainMessage.data, (MultichainTransactionData));

        _transferAssets(multichainTransactionData);

        emit ExecuteSale(multichainTransactionData.saleId, multichainTransactionData, block.number);
    }

    function _executeFreeOffer(FayreMultichainMessage memory fayreMultichainMessage) internal {
        MultichainTransactionData memory multichainTransactionData = abi.decode(fayreMultichainMessage.data, (MultichainTransactionData));

        _transferAssets(multichainTransactionData);

        emit ExecuteFreeOffer(multichainTransactionData.bidId, multichainTransactionData, block.number);
    }

    function _transferAssets(MultichainTransactionData memory multichainTransactionData) internal {
        _sendAmountToSeller(multichainTransactionData);

        _transferAsset(multichainTransactionData.assetType, multichainTransactionData.collectionAddress, multichainTransactionData.seller, multichainTransactionData.buyer, multichainTransactionData.tokenId, multichainTransactionData.nftAmount, "");
    }

    function _sendAmountToSeller(MultichainTransactionData memory multichainTransactionData) private {
        uint256 creatorRoyalties = 0;

        if (_tokensData[multichainTransactionData.collectionAddress][multichainTransactionData.tokenId].royaltiesPct > 0)
            creatorRoyalties = (multichainTransactionData.amount * _tokensData[multichainTransactionData.collectionAddress][multichainTransactionData.tokenId].royaltiesPct) / 10 ** 20;

        uint256 saleFee = (multichainTransactionData.amount * tradeFeePct) / 10 ** 20;

        uint256 remainingSaleFee = 0;

        remainingSaleFee = _processFee(multichainTransactionData.seller, multichainTransactionData.multichainMembershipCardsData, multichainTransactionData.multichainTokenLockerData, saleFee * 10 ** (18 - IERC20UpgradeableExtended(multichainTransactionData.tokenAddress).decimals()), multichainTransactionData.amount * 10 ** (18 - IERC20UpgradeableExtended(multichainTransactionData.tokenAddress).decimals())) / 10 ** (18 - IERC20UpgradeableExtended(multichainTransactionData.tokenAddress).decimals());

        _transferAsset(AssetType.ERC20, multichainTransactionData.tokenAddress, multichainTransactionData.buyer, multichainTransactionData.seller, 0, multichainTransactionData.amount - remainingSaleFee - creatorRoyalties, "E#7");

        if (remainingSaleFee > 0)
            _transferAsset(AssetType.ERC20, multichainTransactionData.tokenAddress, multichainTransactionData.buyer, treasuryAddress, 0, remainingSaleFee, "E#5");

        address creator = _tokensData[multichainTransactionData.collectionAddress][multichainTransactionData.tokenId].creator;

        if (creatorRoyalties > 0)
            _transferAsset(AssetType.ERC20, multichainTransactionData.tokenAddress, multichainTransactionData.buyer, creator, 0, creatorRoyalties, "E#3");
    }

    function _transferAsset(AssetType assetType, address contractAddress, address from, address to, uint256 tokenId, uint256 amount, string memory errorCode) private {
        if (assetType == AssetType.ERC20) {
            if (!IERC20UpgradeableExtended(contractAddress).transferFrom(from, to, amount))
                revert(errorCode);

            emit ERC20Transfer(contractAddress, from, to, amount);
        }
        else if (assetType == AssetType.ERC721) {
            IERC721Upgradeable(contractAddress).safeTransferFrom(from, to, tokenId);

            emit ERC721Transfer(contractAddress, from, to, tokenId);
        } 
        else if (assetType == AssetType.ERC1155) {
            IERC1155Upgradeable(contractAddress).safeTransferFrom(from, to, tokenId, amount, '');

            emit ERC1155Transfer(contractAddress, from, to, tokenId, amount);
        }      
    }

    function _processFee(address owner, MultichainMembershipCardData[3] memory multichainMembershipCardData, MultichainTokenLockerData memory multichainTokenLockerData, uint256 fee, uint256 nftPrice) private returns(uint256) {
        if (fee > 0) {
            //Process multichain locked tokens
            if (multichainTokenLockerData.blockNumber > 0)
            {
                require(multichainTokenLockerData.owner == owner, "E#9");

                if (multichainTokenLockerData.amount >= tokenLockerRequiredAmount)
                    return 0;
            }

            //Process multichain membership cards
            for (uint256 i = 0; i < multichainMembershipCardData.length; i++) {
                if(multichainMembershipCardData[i].tokenId == 0)
                    continue;

                require(multichainMembershipCardData[i].owner == owner, "E#10");

                bytes32 generatedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encode(multichainMembershipCardData[i].tokenId, multichainMembershipCardData[i].volume, multichainMembershipCardData[i].nftPriceCap, multichainMembershipCardData[i].blockNumber))));

                require(!isMultichainMembershipCardDataMessageHashProcessed[generatedHash], "E#8");

                isMultichainMembershipCardDataMessageHashProcessed[generatedHash] = true;

                bool canProcessVolume = true;

                if (multichainMembershipCardData[i].nftPriceCap > 0)
                    if (nftPrice > multichainMembershipCardData[i].nftPriceCap)
                        canProcessVolume = false;

                if (multichainMembershipCardData[i].volume > 0 && canProcessVolume) {
                    uint256 amountToDeduct = fee;

                    if (multichainMembershipCardData[i].volume < amountToDeduct)
                        amountToDeduct = multichainMembershipCardData[i].volume;

                    fee -= amountToDeduct;

                    if (fee == 0)
                        return 0;
                }
            }

            //Process locked tokens
            if (tokenLockerAddress != address(0)) {
                IFayreTokenLocker.LockData memory lockData = IFayreTokenLocker(tokenLockerAddress).usersLockData(owner);

                if (lockData.amount >= tokenLockerRequiredAmount && lockData.expiration > block.timestamp)
                    return 0;
            }

            //Process membership cards     
            for (uint256 i = 0; i < membershipCardsAddresses.length; i++) {
                uint256 membershipCardsAmount = IFayreMembershipCard721(membershipCardsAddresses[i]).balanceOf(owner);

                if (membershipCardsAmount <= 0)
                    continue;

                for (uint256 j = 0; j < membershipCardsAmount; j++) {
                    uint256 currentTokenId = IFayreMembershipCard721(membershipCardsAddresses[i]).tokenOfOwnerByIndex(owner, j);

                    (uint256 volume, uint256 nftPriceCap,) = IFayreMembershipCard721(membershipCardsAddresses[i]).membershipCardsData(currentTokenId);

                    bool canProcessVolume = true;

                    if (nftPriceCap > 0)
                        if (nftPrice > nftPriceCap)
                            canProcessVolume = false;

                    if (volume > 0 && canProcessVolume) {
                        uint256 amountToDeduct = fee;

                        if (volume < amountToDeduct)
                            amountToDeduct = volume;

                        IFayreMembershipCard721(membershipCardsAddresses[i]).decreaseMembershipCardVolume(currentTokenId, amountToDeduct);

                        fee -= amountToDeduct;

                        if (fee == 0)
                            return 0;
                    }
                }
            }
        }

        return fee;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
pragma solidity 0.8.9;

import "./ERC2771ContextUpgradeable.sol";

abstract contract FayreMultichainBaseUpgradable is ERC2771ContextUpgradeable {
    struct FayreMultichainMessage {
        uint256 destinationNetworkId;
        address destinationContractAddress;
        uint256 functionIndex;
        uint256 blockNumber;
        bytes data;
    }

    mapping(address => bool) public isValidator;
    mapping(address => bool) public isFayreValidator;
    uint256 public validationChecksRequired;
    uint256 public fayreValidationChecksRequired;
    mapping(bytes32 => bool) public isMessageHashProcessed;

    uint256 internal _networkId;

    function setValidationChecksRequired(uint256 newValidationChecksRequired) external onlyOwner {
        validationChecksRequired = newValidationChecksRequired;
    }

    function changeAddressIsValidator(address validatorAddress, bool state) external onlyOwner {
        isValidator[validatorAddress] = state;
    }

    function setFayreValidationChecksRequired(uint256 newFayreValidationChecksRequired) external onlyOwner {
        fayreValidationChecksRequired = newFayreValidationChecksRequired;
    }

    function changeAddressIsFayreValidator(address fayreValidatorAddress, bool state) external onlyOwner {
        require(isValidator[fayreValidatorAddress], "Must be a validator");

        isFayreValidator[fayreValidatorAddress] = state;
    }

    function processSignedData(FayreMultichainMessage memory fayreMultichainMessage, uint8[] calldata v, bytes32[] calldata r, bytes32[] calldata s) external {
        _verifySignedMessage(fayreMultichainMessage, v, r, s);

        require(fayreMultichainMessage.destinationContractAddress == address(this), "Wrong destination contract address");
        require(fayreMultichainMessage.destinationNetworkId == _networkId, "Wrong destination network id");

        _executeFunctionWithSignedData(fayreMultichainMessage);
    }

    function _executeFunctionWithSignedData(FayreMultichainMessage memory fayreMultichainMessage) internal virtual {}

    function __FayreMultichainBaseUpgradable_init() internal onlyInitializing {
        __Ownable_init();

        __FayreMultichainBaseUpgradable_init_unchained();
    }

    function __FayreMultichainBaseUpgradable_init_unchained() internal onlyInitializing {
        _networkId = block.chainid;
    }

    function _verifySignedMessage(FayreMultichainMessage memory fayreMultichainMessage, uint8[] memory v, bytes32[] memory r, bytes32[] memory s) internal {
        bytes32 generatedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encode(fayreMultichainMessage.destinationNetworkId, fayreMultichainMessage.destinationContractAddress, fayreMultichainMessage.functionIndex, fayreMultichainMessage.blockNumber, fayreMultichainMessage.data))));
        
        uint256 validationChecks = 0;
        uint256 fayreValidationChecks = 0;

        for (uint256 i = 0; i < v.length; i++) {
            address signer = ecrecover(generatedHash, v[i], r[i], s[i]);

            if (isValidator[signer]) {
                if (isFayreValidator[signer])
                    fayreValidationChecks++;

                validationChecks++;
            }
        }

        require(validationChecks >= validationChecksRequired, "Not enough validation checks");
        require(fayreValidationChecks >= fayreValidationChecksRequired, "Not enough fayre validation checks");
        require(!isMessageHashProcessed[generatedHash], "Message already processed");

        isMessageHashProcessed[generatedHash] = true;
    }

    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20UpgradeableExtended is IERC20Upgradeable {
    function decimals() external view returns(uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC721EnumerableUpgradeable.sol";

interface IFayreMembershipCard721 is IERC721EnumerableUpgradeable {
    function symbol() external view returns(string memory);

    function membershipCardsData(uint256 tokenId) external view returns(uint256 volume, uint256 nftPriceCap, uint256 freeMultiAssetSwapCount);

    function decreaseMembershipCardVolume(uint256 tokenId, uint256 amount) external;

    function decreaseMembershipCardFreeMultiAssetSwapCount(uint256 tokenId, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IFayreTokenLocker {
    struct LockData {
        uint256 lockId;
        address owner;
        uint256 amount;
        uint256 start;
        uint256 expiration;
    }

    function usersLockData(address owner) external returns(LockData calldata);
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
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract ERC2771ContextUpgradeable is OwnableUpgradeable {
    address private _trustedForwarder;

    function setTrustedForwarder(address newTrustedForwarder) external onlyOwner {
        _trustedForwarder = newTrustedForwarder;
    }

    function isTrustedForwarder(address trustedForwarder) public view returns (bool) {
        return trustedForwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    function __ERC2771ContextUpgradeable_init() internal onlyInitializing {
        __Ownable_init();

        __ERC2771ContextUpgradeable_init_unchained();
    }

    function __ERC2771ContextUpgradeable_init_unchained() internal onlyInitializing {
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
    uint256[49] private __gap;
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}