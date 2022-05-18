// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/INFTVillageCards.sol";
import "../interfaces/ICardHandler.sol";
import "../interfaces/IProjectHandler.sol";
import "../general/BaseStructs.sol";

contract CardHandler is BaseStructs, Ownable, ERC721Holder, ERC1155Holder, ICardHandler {
  address public nftVillageChief;
  address public projectHandler;

  bool _inDeposit;

  event ProjectHandlerUpdated(address indexed oldProjectHandler, address indexed newProjectHandler);

  modifier inDeposit() {
    _inDeposit = true;
    _;
    _inDeposit = false;
  }
  modifier onlyProjectHandler() {
    require(msg.sender == projectHandler, "CardHandler: Only ProjectHandler!");
    _;
  }
  modifier onlyNFTVillageChief() {
    require(msg.sender == nftVillageChief, "CardHandler: Only NFTVillageCard!");
    _;
  }

  INFTVillageCards[] public poolcards;
  mapping(uint256 => mapping(uint256 => mapping(address => NftDepositInfo))) userNftInfo;
  mapping(uint256 => mapping(uint256 => NftDeposit[])) public poolRequiredCards;
  // projectId => poolId => tokenId => amount
  mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) public validRequiredCardAmount;
  // projectId => poolId => user => tokenId => bool (true if card is deposited)
  mapping(uint256 => mapping(uint256 => mapping(address => mapping(uint256 => bool)))) public requiredCardDeposited;

  constructor(address _chief) {
    require(_chief != address(0), "CardHandler: NFTVillageChief zero address");
    nftVillageChief = _chief;
  }

  function setProjectHandler(address _projectHandler) external override onlyNFTVillageChief {
    emit ProjectHandlerUpdated(projectHandler, _projectHandler);
    projectHandler = _projectHandler;
  }

  function ERC721Transferfrom(
    address token,
    address from,
    address to,
    uint256 tokenId
  ) external override onlyNFTVillageChief {
    IERC721(token).safeTransferFrom(from, to, tokenId);
  }

  function ERC1155Transferfrom(
    address token,
    address from,
    address to,
    uint256 tokenId,
    uint256 amount
  ) external override onlyNFTVillageChief {
    IERC1155(token).safeTransferFrom(from, to, tokenId, amount, "");
  }

  function getUserCardsInfo(
    uint256 projectId,
    uint256 poolId,
    address account
  ) external view override returns (NftDepositInfo memory) {
    return userNftInfo[projectId][poolId][account];
  }

  function getPoolRequiredCards(uint256 projectId, uint256 poolId)
    external
    view
    override
    returns (NftDeposit[] memory)
  {
    return poolRequiredCards[projectId][poolId];
  }

  function setPoolCard(uint256 _projectId, INFTVillageCards _poolcard) external override onlyProjectHandler {
    if (poolcards.length > _projectId) poolcards[_projectId] = _poolcard;
    else poolcards.push(_poolcard);
  }

  function addPoolRequiredCards(
    uint256 _projectId,
    uint256 _poolId,
    NftDeposit[] calldata _requiredCards
  ) external override onlyProjectHandler {
    PoolInfo memory _pool = IProjectHandler(projectHandler).getPoolInfo(_projectId, _poolId);
    require(
      _pool.minRequiredCards <= _requiredCards.length + poolRequiredCards[_projectId][_poolId].length,
      "CardHandler: required card length must be equal to or greater than min required cards!"
    );
    for (uint256 i = 0; i < _requiredCards.length; i++) {
      require(_requiredCards[i].amount > 0, "CardHandler: Invalid required card amount!");
      require(
        validRequiredCardAmount[_projectId][_poolId][_requiredCards[i].tokenId] == 0,
        "CardHandler: Duplicate required card!"
      );
      poolRequiredCards[_projectId][_poolId].push(_requiredCards[i]);
      validRequiredCardAmount[_projectId][_poolId][_requiredCards[i].tokenId] = _requiredCards[i].amount;
    }
  }

  function removePoolRequiredCard(
    uint256 _projectId,
    uint256 _poolId,
    uint256 _tokenId
  ) external override onlyProjectHandler {
    PoolInfo memory _pool = IProjectHandler(projectHandler).getPoolInfo(_projectId, _poolId);
    NftDeposit[] storage _requiredCards = poolRequiredCards[_projectId][_poolId];
    require(
      _pool.minRequiredCards <= _requiredCards.length - 1,
      "CardHandler: required card length must be equal to or greater than min required cards!"
    );
    for (uint256 i = 0; i < _requiredCards.length; i++) {
      if (_requiredCards[i].tokenId == _tokenId) {
        poolRequiredCards[_projectId][_poolId][i] = poolRequiredCards[_projectId][_poolId][_requiredCards.length - 1];
        poolRequiredCards[_projectId][_poolId].pop();
        delete validRequiredCardAmount[_projectId][_poolId][_tokenId];
        return;
      }
    }
    revert("CardHandler: _tokenId not found");
  }

  function useCard(
    address user,
    uint8 cardType,
    uint256 projectId,
    uint256 poolId,
    NftDeposit[] calldata cards
  ) external override onlyNFTVillageChief inDeposit returns (uint256) {
    if (CardType(cardType) == CardType.REQUIRED) useRequiredCard(user, projectId, poolId, cards);
    else if (CardType(cardType) == CardType.FEE_DISCOUNT) return useFeeCard(user, projectId, poolId, cards);
    else if (CardType(cardType) == CardType.HARVEST_RELIEF) return useHarvestCard(user, projectId, poolId, cards);
    else if (CardType(cardType) == CardType.MULTIPLIER) return useMultiplierCard(user, projectId, poolId, cards);
    return 0;
  }

  function withdrawCard(
    address user,
    uint8 cardType,
    uint256 projectId,
    uint256 poolId,
    NftDeposit[] calldata cards
  ) external override onlyNFTVillageChief returns (uint256) {
    if (CardType(cardType) == CardType.REQUIRED) withdrawRequiredCard(user, projectId, poolId);
    else if (CardType(cardType) == CardType.FEE_DISCOUNT) withdrawFeeCard(user, projectId, poolId);
    else if (CardType(cardType) == CardType.HARVEST_RELIEF) return withdrawHarvestCard(user, projectId, poolId, cards);
    else if (CardType(cardType) == CardType.MULTIPLIER) return withdrawMultiplierCard(user, projectId, poolId, cards);
    return 0;
  }

  function useRequiredCard(
    address user,
    uint256 projectId,
    uint256 poolId,
    NftDeposit[] memory cards
  ) private {
    INFTVillageCards poolCards = poolcards[projectId];

    PoolInfo memory _pool = IProjectHandler(projectHandler).getPoolInfo(projectId, poolId);
    NftDeposit[] storage _userNft = userNftInfo[projectId][poolId][user].required;
    if (_userNft.length == _pool.minRequiredCards) return; // required cards are already deposited, we can move on
    require(cards.length == _pool.minRequiredCards, "CardHandler: Invalid required cards length");
    for (uint256 i = 0; i < cards.length; i++) {
      require(
        !requiredCardDeposited[projectId][poolId][user][cards[i].tokenId],
        "CardHandler: Duplicate required card"
      );
      cards[i].amount = validRequiredCardAmount[projectId][poolId][cards[i].tokenId];
      require(cards[i].amount > 0, "CardHandler: Invalid required card token id");
      poolCards.safeTransferFrom(user, address(this), cards[i].tokenId, cards[i].amount, "");
      _userNft.push(cards[i]);
      requiredCardDeposited[projectId][poolId][user][cards[i].tokenId] = true;
    }
  }

  function useFeeCard(
    address user,
    uint256 projectId,
    uint256 poolId,
    NftDeposit[] memory cards
  ) private returns (uint256) {
    INFTVillageCards poolCards = poolcards[projectId];

    uint256 feeDiscount;
    NftDeposit[] storage _userNft = userNftInfo[projectId][poolId][user].feeDiscount;
    for (uint256 i = 0; i < cards.length; i++) {
      poolCards.safeTransferFrom(user, address(this), cards[i].tokenId, cards[i].amount, "");
      _userNft.push(cards[i]);
      feeDiscount += poolCards.getFeeDiscount(cards[i].tokenId) * cards[i].amount;
    }
    return feeDiscount;
  }

  function useHarvestCard(
    address user,
    uint256 projectId,
    uint256 poolId,
    NftDeposit[] memory cards
  ) private returns (uint256) {
    INFTVillageCards poolCards = poolcards[projectId];

    NftDeposit[] storage _userNft = userNftInfo[projectId][poolId][user].harvest;
    uint256 harvestRelief;
    for (uint256 i = 0; i < cards.length; i++) {
      poolCards.safeTransferFrom(user, address(this), cards[i].tokenId, cards[i].amount, "");
      _userNft.push(cards[i]);
      harvestRelief += poolCards.getHarvestRelief(cards[i].tokenId) * cards[i].amount;
    }
    return harvestRelief;
  }

  function useMultiplierCard(
    address user,
    uint256 projectId,
    uint256 poolId,
    NftDeposit[] memory cards
  ) private returns (uint256) {
    INFTVillageCards poolCards = poolcards[projectId];

    NftDeposit[] storage _userNft = userNftInfo[projectId][poolId][user].multiplier;
    uint256 multiplier;
    for (uint256 i = 0; i < cards.length; i++) {
      poolCards.safeTransferFrom(user, address(this), cards[i].tokenId, cards[i].amount, "");
      _userNft.push(cards[i]);
      multiplier += poolCards.getMultiplier(cards[i].tokenId) * cards[i].amount;
    }
    return multiplier;
  }

  function withdrawRequiredCard(
    address user,
    uint256 projectId,
    uint256 poolId
  ) private {
    INFTVillageCards poolCards = poolcards[projectId];

    NftDeposit[] storage cards = userNftInfo[projectId][poolId][user].required;
    for (uint256 i = 0; i < cards.length; i++) {
      poolCards.safeTransferFrom(address(this), user, cards[i].tokenId, cards[i].amount, "");
      delete requiredCardDeposited[projectId][poolId][user][cards[i].tokenId];
    }
    delete userNftInfo[projectId][poolId][user].required;
  }

  function withdrawFeeCard(
    address user,
    uint256 projectId,
    uint256 poolId
  ) private returns (uint256) {
    INFTVillageCards poolCards = poolcards[projectId];

    NftDeposit[] storage cards = userNftInfo[projectId][poolId][user].feeDiscount;
    uint256 feeDiscount;
    for (uint256 i = 0; i < cards.length; i++) {
      feeDiscount += poolCards.getFeeDiscount(cards[i].tokenId) * cards[i].amount;
      poolCards.safeTransferFrom(address(this), user, cards[i].tokenId, cards[i].amount, "");
    }
    delete userNftInfo[projectId][poolId][user].feeDiscount;
    return feeDiscount;
  }

  function withdrawHarvestCard(
    address user,
    uint256 projectId,
    uint256 poolId,
    NftDeposit[] memory cards
  ) private returns (uint256) {
    INFTVillageCards poolCards = poolcards[projectId];

    uint256 harvestRelief;
    NftDeposit[] storage harvestCards = userNftInfo[projectId][poolId][user].harvest;
    if (harvestCards.length == 0) return 0;
    uint256 i = harvestCards.length - 1;
    while (true) {
      require(cards[i].tokenId == harvestCards[i].tokenId, "CardHandler: Invalid Card Id");
      require(
        harvestCards[i].amount >= cards[i].amount,
        "CardHandler: Card amount should not be greater than deposited amount!"
      );
      if (cards[i].amount > 0) {
        harvestRelief += poolCards.getHarvestRelief(cards[i].tokenId) * cards[i].amount;
        poolCards.safeTransferFrom(address(this), user, cards[i].tokenId, cards[i].amount, "");
        harvestCards[i].amount -= cards[i].amount;
        if (harvestCards[i].amount == 0) {
          // all cards are withdrawn, so we can delete the record
          harvestCards[i] = harvestCards[harvestCards.length - 1];
          harvestCards.pop();
        }
      }
      if (i == 0) break;
      i--;
    }
    return harvestRelief;
  }

  function withdrawMultiplierCard(
    address user,
    uint256 projectId,
    uint256 poolId,
    NftDeposit[] memory cards
  ) private returns (uint256) {
    INFTVillageCards poolCards = poolcards[projectId];

    NftDeposit[] storage multiplierCards = userNftInfo[projectId][poolId][user].multiplier;
    if (multiplierCards.length == 0) return 0;
    uint256 multiplier;
    uint256 i = multiplierCards.length - 1;
    while (true) {
      require(cards[i].tokenId == multiplierCards[i].tokenId, "CardHandler: Invalid Card Id");
      require(
        multiplierCards[i].amount >= cards[i].amount,
        "CardHandler: Card amount should not be greater than deposited amount!"
      );
      if (cards[i].amount > 0) {
        multiplier += poolCards.getMultiplier(cards[i].tokenId) * cards[i].amount;
        poolCards.safeTransferFrom(address(this), user, cards[i].tokenId, cards[i].amount, "");
        multiplierCards[i].amount -= cards[i].amount;
        if (multiplierCards[i].amount == 0) {
          // all cards are withdrawn, so we can delete the record
          multiplierCards[i] = multiplierCards[multiplierCards.length - 1];
          multiplierCards.pop();
        }
      }
      if (i == 0) break;
      i--;
    }
    return multiplier;
  }

  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) public view override returns (bytes4) {
    require(_inDeposit, "CardHandler: Invalid ERC1155 Deposit!");
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) public view override returns (bytes4) {
    require(_inDeposit, "CardHandler: Invalid ERC1155 Deposit!");
    return this.onERC1155BatchReceived.selector;
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) public view override returns (bytes4) {
    require(_inDeposit, "CardHandler: Invalid ERC721 Deposit!");
    return this.onERC721Received.selector;
  }

  function drainAccidentallySentTokens(
    IERC20 token,
    address recipient,
    uint256 amount
  ) external onlyOwner {
    token.transfer(recipient, amount);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./INFTVillageCardFeatures.sol";

abstract contract INFTVillageCards is INFTVillageCardFeatures, IERC1155 {}

// SPDX-License-Identifier: MIT

import "./INFTVillageCards.sol";
import "../general/BaseStructs.sol";

pragma solidity ^0.8.0;

interface ICardHandler is BaseStructs {
  function setProjectHandler(address _projectHandler) external;

  function ERC721Transferfrom(
    address token,
    address from,
    address to,
    uint256 amount
  ) external;

  function ERC1155Transferfrom(
    address token,
    address from,
    address to,
    uint256 tokenId,
    uint256 amount
  ) external;

  function getUserCardsInfo(
    uint256 projectId,
    uint256 poolId,
    address account
  ) external view returns (NftDepositInfo memory);

  function getPoolRequiredCards(uint256 projectId, uint256 poolId) external view returns (NftDeposit[] memory);

  function setPoolCard(uint256 _projectId, INFTVillageCards _poolcard) external;

  function addPoolRequiredCards(
    uint256 _projectId,
    uint256 _poolId,
    NftDeposit[] calldata _requiredCards
  ) external;

  function removePoolRequiredCard(
    uint256 _projectId,
    uint256 _poolId,
    uint256 _tokenId
  ) external;

  function useCard(
    address user,
    uint8 cardType,
    uint256 projectId,
    uint256 poolId,
    NftDeposit[] calldata cards
  ) external returns (uint256);

  function withdrawCard(
    address user,
    uint8 cardType,
    uint256 projectId,
    uint256 poolId,
    NftDeposit[] calldata cards
  ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ICardHandler.sol";
import "./IFeeReceiver.sol";
import "../general/BaseStructs.sol";

interface IProjectHandler is BaseStructs {
  function setCardHandler(ICardHandler _cardHandler) external;

  function initializeProject(uint256 projectId) external;

  function getRewardInfo(uint256 projectId, uint256 poolId) external returns (RewardInfo[] calldata);

  function projectFeeRecipient() external returns (IFeeReceiver);

  function poolFeeRecipient() external returns (IFeeReceiver);

  function rewardFeeRecipient() external returns (IFeeReceiver);

  function projectFee() external returns (uint256);

  function poolFee() external returns (uint256);

  function rewardFee() external returns (uint256);

  function getProjectInfo(uint256 projectId) external returns (ProjectInfo memory);

  function projectLength() external view returns (uint256);

  function projectPoolLength(uint256 projectId) external view returns (uint256);

  function getPoolInfo(uint256 projectId, uint256 poolId) external view returns (PoolInfo memory);

  function addProject(
    address _admin,
    uint256 _adminReward,
    uint256 _referralFee,
    uint256 _startBlock,
    INFTVillageCards _poolCards
  ) external payable;

  function setProject(
    uint256 projectId,
    address _admin,
    uint256 _adminReward,
    uint256 _referralFee,
    INFTVillageCards _poolCards
  ) external;

  function addPool(
    uint256 projectId,
    PoolInfo memory _pool,
    RewardInfo[] memory _rewardInfo,
    NftDeposit[] calldata _requiredCards
  ) external payable;

  function setPool(
    uint256 projectId,
    uint256 poolId,
    PoolInfo calldata _pool,
    RewardInfo[] memory _rewardInfo
  ) external;

  function setPoolShares(
    uint256 projectId,
    uint256 poolId,
    uint256 shares
  ) external;

  function setStakedAmount(
    uint256 projectId,
    uint256 poolId,
    uint256 amount
  ) external;

  function setRewardPerBlock(
    uint256 projectId,
    uint256 poolId,
    uint256 rewardId,
    uint256 rewardPerBlock
  ) external;

  function setLastRewardBlock(
    uint256 projectId,
    uint256 poolId,
    uint256 rewardId,
    uint256 lastRewardBlock
  ) external;

  function setRewardPerShare(
    uint256 projectId,
    uint256 poolId,
    uint256 rewardId,
    uint256 accRewardPerShare
  ) external;

  function setRewardSupply(
    uint256 projectId,
    uint256 poolId,
    uint256 rewardId,
    uint256 supply
  ) external;

  function pendingRewards(
    uint256 projectId,
    uint256 poolId,
    UserInfo memory user,
    UserRewardInfo[] calldata userReward
  ) external view returns (uint256[] calldata);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IERC20Mintable.sol";
import "../interfaces/INFTVillageCards.sol";

interface BaseStructs {
  enum CardType {
    REQUIRED,
    FEE_DISCOUNT,
    HARVEST_RELIEF,
    MULTIPLIER
  }

  enum TokenStandard {
    ERC20,
    ERC721,
    ERC1155,
    NONE
  }

  struct NftDeposit {
    uint256 tokenId;
    uint256 amount;
  }

  struct NftDepositInfo {
    NftDeposit[] required;
    NftDeposit[] feeDiscount;
    NftDeposit[] harvest;
    NftDeposit[] multiplier;
  }

  struct ProjectInfo {
    address admin;
    uint256 adminReward;
    uint256 referralFee;
    uint256 rewardFee;
    uint256 startBlock;
    bool initialized;
    bool paused;
    INFTVillageCards cards;
    PoolInfo[] pools;
  }

  struct PoolInfo {
    address stakedToken;
    bool lockDeposit;
    uint8 stakedTokenStandard;
    uint256 stakedTokenId;
    uint256 stakedAmount;
    uint256 totalShares;
    uint16 depositFee;
    uint16 minWithdrawlFee;
    uint16 maxWithdrawlFee;
    uint16 withdrawlFeeReliefInterval;
    uint256 minDeposit;
    uint256 harvestInterval;
    uint256 minRequiredCards;
  }

  struct RewardInfo {
    IERC20Mintable token;
    bool paused;
    bool mintable;
    uint256 rewardPerBlock;
    uint256 lastRewardBlock;
    uint256 accRewardPerShare;
    uint256 supply;
  }

  struct UserInfo {
    uint256 amount;
    uint256 shares;
    uint256 shareMultiplier;
    uint256 canHarvestAt;
    uint256 harvestRelief;
    uint256 withdrawFeeDiscount;
    uint256 depositFeeDiscount;
    uint256 stakedTimestamp;
  }

  struct UserRewardInfo {
    uint256 rewardDebt;
    uint256 rewardLockedUp;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

abstract contract INFTVillageCardFeatures {
  function addHarvestReliefCard(uint256 _tokenId, uint256 _harvestRelief) external virtual;

  function addFeeDiscountCard(uint256 _tokenId, uint256 _feeDiscount) external virtual;

  function addMultiplierCard(uint256 _tokenId, uint256 _multiplier) external virtual;

  function removeHarvestReliefCard(uint256 _tokenId) external virtual;

  function removeFeeDiscountCard(uint256 _tokenId) external virtual;

  function removeMultiplierCard(uint256 _tokenId) external virtual;

  function getHarvestReliefCards() external view virtual returns (uint256[] memory);

  function getFeeDiscountCards() external view virtual returns (uint256[] memory);

  function getMultiplierCards() external view virtual returns (uint256[] memory);

  function getHarvestRelief(uint256 id) external virtual returns (uint256);

  function getFeeDiscount(uint256 id) external virtual returns (uint256);

  function getMultiplier(uint256 id) external virtual returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Mintable is IERC20 {
  function mint(address to, uint256 amount) external;

  function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFeeReceiver {
  function onFeeReceived(address token, uint256 amount) external payable;
}