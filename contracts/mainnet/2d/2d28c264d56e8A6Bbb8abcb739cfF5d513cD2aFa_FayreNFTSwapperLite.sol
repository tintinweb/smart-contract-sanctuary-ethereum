// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IFayreMembershipCard721.sol";
import "./interfaces/IFayreTokenLocker.sol";


contract FayreNFTSwapperLite is Ownable, IERC721Receiver, IERC1155Receiver {
    enum SwapAssetType {
        LIQUIDITY,
        ERC20,
        ERC721,
        ERC1155
    }

    struct SwapAssetData {
        address contractAddress;
        SwapAssetType assetType;
        uint256 id;
        uint256 amount;
    }

    struct SwapRequest {
        address creator;
        address counterpart;
        SwapAssetData[] creatorAssetData;
        SwapAssetData[] counterpartAssetData;
    }

    struct SwapData {
        SwapRequest swapRequest;
        uint256 creatorFee;
        uint256 end;
    }

    struct TokenLockerSwapFeeData {
        uint256 lockedTokensAmount;
        uint256 fee;
    }

    struct ContractStatusData {
        address contractAddress;
        bool isWhitelisted;
    }

    event CreateSwap(uint256 indexed swapId, address indexed creator, address indexed counterpart);
    event FinalizeSwap(uint256 indexed swapId, address indexed creator, address indexed counterpart);
    event CancelSwap(uint256 indexed swapId, address indexed creator, address indexed counterpart);
    event RejectSwap(uint256 indexed swapId, address indexed creator, address indexed counterpart);

    mapping(uint256 => SwapData) public swapsData;
    address[] public membershipCardsAddresses;
    uint256 public membershipCardsAddressesCount;
    address public tokenLockerAddress;
    address public treasuryAddress;
    uint256 public swapFee;
    uint256 public currentSwapId;
    mapping(string => uint256) public cardsSwapFee;
    mapping(string => uint256) public cardsExpirationDeltaTime;
    TokenLockerSwapFeeData[] public tokenLockerSwapFeesData;
    uint256 public tokenLockerSwapFeesCount;
    mapping(address => uint256[]) public usersSwapsIds;
    mapping(address => uint256) public usersSwapsCount;
    mapping(address => bool) public isContractWhitelisted;

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
 
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == 0x01ffc9a7 || interfaceID == type(IERC721Receiver).interfaceId || interfaceID == type(IERC1155Receiver).interfaceId;
    }

    function setTreasury(address newTreasuryAddress) external onlyOwner {
        treasuryAddress = newTreasuryAddress;
    }

    function setSwapFee(uint256 newSwapFee) external onlyOwner {
        swapFee = newSwapFee;
    }

    function addMembershipCardAddress(address membershipCardsAddress) external onlyOwner {
        for (uint256 i = 0; i < membershipCardsAddresses.length; i++)
            if (membershipCardsAddresses[i] == membershipCardsAddress)
                revert("Membership card address already present");

        membershipCardsAddresses.push(membershipCardsAddress);

        membershipCardsAddressesCount++;
    }

    function removeMembershipCardAddress(address membershipCardsAddress) external onlyOwner {
        uint256 indexToDelete = type(uint256).max;

        for (uint256 i = 0; i < membershipCardsAddresses.length; i++)
            if (membershipCardsAddresses[i] == membershipCardsAddress)
                indexToDelete = i;

        require(indexToDelete != type(uint256).max, "Membership card address not found");

        membershipCardsAddresses[indexToDelete] = membershipCardsAddresses[membershipCardsAddresses.length - 1];

        membershipCardsAddresses.pop();

        membershipCardsAddressesCount--;
    }

    function setTokenLockerAddress(address newTokenLockerAddress) external onlyOwner {
        tokenLockerAddress = newTokenLockerAddress;
    }

    function addTokenLockerSwapFeeData(uint256 lockedTokensAmount, uint256 fee) external onlyOwner {
        for (uint256 i = 0; i < tokenLockerSwapFeesData.length; i++)
            if (tokenLockerSwapFeesData[i].lockedTokensAmount == lockedTokensAmount)
                revert("E#17");

        tokenLockerSwapFeesData.push(TokenLockerSwapFeeData(lockedTokensAmount, fee));

        tokenLockerSwapFeesCount++;
    }

    function removeTokenLockerSwapFeeData(uint256 lockedTokensAmount) external onlyOwner {
        uint256 indexToDelete = type(uint256).max;

        for (uint256 i = 0; i < tokenLockerSwapFeesData.length; i++)
            if (tokenLockerSwapFeesData[i].lockedTokensAmount == lockedTokensAmount)
                indexToDelete = i;

        require(indexToDelete != type(uint256).max, "Wrong token locker swap fee data");

        tokenLockerSwapFeesData[indexToDelete] = tokenLockerSwapFeesData[tokenLockerSwapFeesData.length - 1];

        tokenLockerSwapFeesData.pop();

        tokenLockerSwapFeesCount--;
    }

    function setCardSwapFee(string calldata symbol, uint256 newCardSwapFee) external onlyOwner {
        cardsSwapFee[symbol] = newCardSwapFee;
    }

    function setCardExpirationDeltaTime(string calldata symbol, uint256 newCardExpirationDeltaTime) external onlyOwner {
        cardsExpirationDeltaTime[symbol] = newCardExpirationDeltaTime;
    }

    function setContractsStatuses(ContractStatusData[] calldata contractsStatusesData) external onlyOwner {
        for (uint256 i = 0; i < contractsStatusesData.length; i++)
            isContractWhitelisted[contractsStatusesData[i].contractAddress] = contractsStatusesData[i].isWhitelisted;
    }

    function createSwap(SwapRequest calldata swapRequest) external payable {
        require(swapRequest.creator == _msgSender(), "Only creator can create the swap");
        require(swapRequest.creator != swapRequest.counterpart, "Creator and counterpart cannot be the same address");

        bool creatorAssetNFTFound = _processAssetData(swapRequest.creatorAssetData);

        bool counterpartAssetNFTFound = _processAssetData(swapRequest.counterpartAssetData);

        require(creatorAssetNFTFound || counterpartAssetNFTFound, "At least one basket must contains one nft");

        uint256 swapId = currentSwapId++;

        swapsData[swapId].swapRequest = swapRequest;

        uint256 processedFee = _processFee(_msgSender(), swapFee);

        _checkProvidedLiquidity(swapRequest.creatorAssetData, processedFee);

        swapsData[swapId].creatorFee = processedFee;

        _transferAsset(swapRequest.creator, address(this), swapsData[swapId].swapRequest.creatorAssetData);

        usersSwapsIds[swapRequest.creator].push(swapId);
        usersSwapsCount[swapRequest.creator]++;

        usersSwapsIds[swapRequest.counterpart].push(swapId);
        usersSwapsCount[swapRequest.counterpart]++;

        emit CreateSwap(swapId, swapRequest.creator, swapRequest.counterpart);
    }

    function finalizeSwap(uint256 swapId, bool rejectSwap) external payable {
        SwapData storage swapData = swapsData[swapId];

        require(swapData.end == 0, "Swap already finalized");
        require(swapData.swapRequest.counterpart == _msgSender() || swapData.swapRequest.creator == _msgSender() || owner() == _msgSender() , "Only counterpart/creator/owner can conclude/reject the swap");

        swapData.end = block.timestamp;

        if (rejectSwap) {
            _cancelSwap(swapData);

            emit RejectSwap(swapId, swapData.swapRequest.creator, swapData.swapRequest.counterpart);

            return;
        }

        require(swapData.swapRequest.counterpart == _msgSender(), "Only the counterpart can conclude the swap");

        uint256 processedFee = _processFee(_msgSender(), swapFee);

        _checkProvidedLiquidity(swapData.swapRequest.counterpartAssetData, processedFee);

        uint256 mergedFees = swapData.creatorFee + processedFee;

        if (mergedFees > 0) {
            (bool feeSendToTreasurySuccess, ) = treasuryAddress.call{value: mergedFees}("");

            require(feeSendToTreasurySuccess, "Unable to send fees to treasury");
        }

        _transferAsset(swapData.swapRequest.counterpart, swapData.swapRequest.creator, swapData.swapRequest.counterpartAssetData);

        _transferAsset(address(this), swapData.swapRequest.counterpart, swapData.swapRequest.creatorAssetData);

        emit FinalizeSwap(swapId, swapData.swapRequest.creator, swapData.swapRequest.counterpart);
    }

    function _cancelSwap(SwapData storage swapData) private {
        swapData.end = block.timestamp;

        _transferAsset(address(this), swapData.swapRequest.creator, swapData.swapRequest.creatorAssetData);

        if (swapData.creatorFee > 0) {
            (bool creatorFeeRefundSuccess, ) = swapData.swapRequest.creator.call{value: swapData.creatorFee }("");

            require(creatorFeeRefundSuccess, "Unable to refund fee to creator");
        }
    }

    function _transferAsset(address from, address to, SwapAssetData[] storage assetData) private {
        for (uint256 i = 0; i < assetData.length; i++) {
            if (assetData[i].assetType == SwapAssetType.LIQUIDITY) {
                if (to != address(this)) {
                    (bool liquiditySendSuccess, ) = to.call{value: assetData[i].amount}("");

                    require(liquiditySendSuccess, "Unable to transfer liquidity");
                }
            }
            else if (assetData[i].assetType == SwapAssetType.ERC20) {
                if (from == address(this)) {
                    require(IERC20(assetData[i].contractAddress).transfer(to, assetData[i].amount), "ERC20 transfer failed");
                } else {
                    require(IERC20(assetData[i].contractAddress).transferFrom(from, to, assetData[i].amount), "ERC20 transfer failed");
                }
            }
            else if (assetData[i].assetType == SwapAssetType.ERC721) {
                IERC721(assetData[i].contractAddress).safeTransferFrom(from, to, assetData[i].id, "");
            }
            else if (assetData[i].assetType == SwapAssetType.ERC1155) {
                IERC1155(assetData[i].contractAddress).safeTransferFrom(from, to, assetData[i].id, assetData[i].amount, "");
            }
        }
    }

    function _processFee(address owner, uint256 fee) private returns(uint256) {
        //Process locked tokens
        if (tokenLockerAddress != address(0)) {
            uint256 minLockDuration = IFayreTokenLocker(tokenLockerAddress).minLockDuration();

            IFayreTokenLocker.LockData memory lockData = IFayreTokenLocker(tokenLockerAddress).usersLockData(owner);

            if (lockData.amount > 0)
                if (lockData.start + minLockDuration <= lockData.expiration && lockData.start + minLockDuration >= block.timestamp)
                    for (uint256 j = 0; j < tokenLockerSwapFeesData.length; j++)
                        if (lockData.amount >= tokenLockerSwapFeesData[j].lockedTokensAmount)
                            if (fee > tokenLockerSwapFeesData[j].fee)
                                fee = tokenLockerSwapFeesData[j].fee;
        }

        //Process on-chain membership cards
        if (fee > 0)
            for (uint256 i = 0; i < membershipCardsAddresses.length; i++) {
                uint256 membershipCardsAmount = IFayreMembershipCard721(membershipCardsAddresses[i]).balanceOf(owner);

                if (membershipCardsAmount <= 0)
                    continue;

                string memory membershipCardSymbol = IFayreMembershipCard721(membershipCardsAddresses[i]).symbol();

                if (cardsExpirationDeltaTime[membershipCardSymbol] > 0) {
                    for (uint256 j = 0; j < membershipCardsAmount; j++) {
                        uint256 currentTokenId = IFayreMembershipCard721(membershipCardsAddresses[i]).tokenOfOwnerByIndex(owner, j);

                        if (IFayreMembershipCard721(membershipCardsAddresses[i]).membershipCardMintTimestamp(currentTokenId) + cardsExpirationDeltaTime[membershipCardSymbol] >= block.timestamp) {
                            uint256 cardSwapFee = cardsSwapFee[membershipCardSymbol];

                            if (fee > cardSwapFee)
                                fee = cardSwapFee;
                        }
                    }
                } else {
                    uint256 cardSwapFee = cardsSwapFee[membershipCardSymbol];

                    if (fee > cardSwapFee)
                        fee = cardSwapFee;
                }
            }

        return fee;
    }

    function _processAssetData(SwapAssetData[] calldata assetData) private view returns(bool nftFound) {
        for (uint256 i = 0; i < assetData.length; i++) {
            if (assetData[i].assetType == SwapAssetType.ERC721 || assetData[i].assetType == SwapAssetType.ERC1155)
                nftFound = true;

            if (assetData[i].assetType == SwapAssetType.ERC20 || assetData[i].assetType == SwapAssetType.ERC721 || assetData[i].assetType == SwapAssetType.ERC1155)
                require(isContractWhitelisted[assetData[i].contractAddress], "Contract not whitelisted");
        }
    }

    function _checkProvidedLiquidity(SwapAssetData[] memory assetData, uint256 fee) private {
        require(msg.value >= fee, "Liquidity below fee");

        uint256 providedLiquidityForAsset = msg.value - fee;

        for (uint256 i = 0; i < assetData.length; i++)
            if (assetData[i].assetType == SwapAssetType.LIQUIDITY)
                require(providedLiquidityForAsset == assetData[i].amount, "Wrong liquidity provided");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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

import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";

interface IFayreMembershipCard721 is IERC721Enumerable {
    function symbol() external view returns(string memory);

    function membershipCardMintTimestamp(uint256 tokenId) external view returns(uint256);
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

    function minLockDuration() external returns(uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Enumerable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}