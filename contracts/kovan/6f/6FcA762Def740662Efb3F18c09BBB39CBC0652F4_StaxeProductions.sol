//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IStaxeProductionToken.sol";
import "./interfaces/IProductionEscrow.sol";
import "./interfaces/IStaxeMembers.sol";
import "./interfaces/IEscrowFactory.sol";
import "./interfaces/IStaxeProductions.sol";

contract StaxeProductions is Ownable, IStaxeProductions {
  // ------- Contract state

  IStaxeProductionToken public token;
  address public treasury;
  mapping(uint256 => ProductionData) public productionData;

  IEscrowFactory private escrowFactory;
  IStaxeMembers private members;

  constructor(
    IStaxeProductionToken _token,
    IEscrowFactory _escrowFactory,
    IStaxeMembers _members,
    address _treasury
  ) Ownable() {
    token = _token;
    escrowFactory = _escrowFactory;
    members = _members;
    treasury = _treasury;
  }

  function setEscrowFactory(IEscrowFactory _escrowFactory) external onlyOwner {
    escrowFactory = _escrowFactory;
  }

  function setMembers(IStaxeMembers _members) external onlyOwner {
    members = _members;
  }

  function setTreasury(address _treasury) external onlyOwner {
    treasury = _treasury;
  }

  function getProductionData(uint256 id) external view override returns (ProductionData memory) {
    return productionData[id];
  }

  function getProductionDataForProductions(uint256[] memory ids)
    external
    view
    override
    returns (ProductionData[] memory)
  {
    ProductionData[] memory result = new ProductionData[](ids.length);
    for (uint256 i = 0; i < ids.length; i++) {
      result[i] = productionData[ids[i]];
    }
    return result;
  }

  function getWithdrawableFunds(uint256 id) external view override returns (uint256) {
    require(productionData[id].id > 0, "NOT_EXIST");
    return productionData[id].deposits.getWithdrawableFunds();
  }

  function getWithdrawableProceeds(uint256 id) external view returns (uint256) {
    require(productionData[id].id > 0, "NOT_EXIST");
    if (!members.isInvestor(msg.sender)) {
      return 0;
    }
    return productionData[id].deposits.getWithdrawableProceeds(msg.sender);
  }

  function getNextTokenPrice(uint256 id, uint256 tokensToBuy) external view returns (uint256) {
    require(productionData[id].id > 0, "NOT_EXIST");
    return productionData[id].deposits.getNextTokenPrice(msg.sender, tokensToBuy);
  }

  // ------- Lifecycle

  function createNewProduction(CreateProduction calldata newProduction) external override {
    require(members.isOrganizer(msg.sender), "NOT_ORGANIZER");
    require(newProduction.id > 0, "ID_0_NOT_ALLOWED");
    require(newProduction.tokenInvestorSupply > 0, "ZERO_TOKEN_SUPPLY");
    require(newProduction.tokenPrice > 0, "ZERO_TOKEN_PRICE");
    require(productionData[newProduction.id].id == 0, "PRODUCTION_EXISTS");
    emit ProductionCreated(
      newProduction.id,
      msg.sender,
      newProduction.tokenInvestorSupply,
      newProduction.tokenOrganizerSupply,
      newProduction.tokenTreasurySupply
    );
    ProductionData storage data = productionData[newProduction.id];
    data.id = newProduction.id;
    data.creator = msg.sender;
    data.tokenSupply =
      newProduction.tokenInvestorSupply +
      newProduction.tokenOrganizerSupply +
      newProduction.tokenTreasurySupply;
    data.tokenPrice = newProduction.tokenPrice;
    data.state = ProductionState.CREATED;
    data.maxTokensUnknownBuyer = newProduction.maxTokensUnknownBuyer;
    data.tokensSoldCounter = newProduction.tokenOrganizerSupply + newProduction.tokenTreasurySupply;
    data.dataHash = newProduction.dataHash;
    data.deposits = escrowFactory.newEscrow(token, this, newProduction.id);
    token.mintToken(data.deposits, newProduction.id, newProduction.tokenInvestorSupply);
    token.mintToken(
      [msg.sender, treasury],
      newProduction.id,
      [newProduction.tokenOrganizerSupply, newProduction.tokenTreasurySupply]
    );
  }

  function approveProduction(uint256 id) external override {
    require(members.isApprover(msg.sender), "NOT_APPROVER");
    require(productionData[id].id > 0, "NOT_EXIST");
    require(productionData[id].state == ProductionState.CREATED, "NOT_CREATED");
    productionData[id].state = ProductionState.OPEN;
  }

  function declineProduction(uint256 id) external override {
    require(members.isApprover(msg.sender), "NOT_APPROVER");
    require(productionData[id].id > 0, "NOT_EXIST");
    require(productionData[id].state == ProductionState.CREATED, "NOT_CREATED");
    productionData[id].state = ProductionState.DECLINED;
  }

  // ------- Investment

  function getNextTokensPrice(uint256 id, uint256 numTokens) external view returns (uint256) {
    require(productionData[id].id > 0, "NOT_EXIST");
    return productionData[id].deposits.getNextTokenPrice(msg.sender, numTokens);
  }

  function buyTokens(
    uint256 id,
    uint256 numTokens,
    address investor
  ) external payable override {
    // checks
    require(numTokens > 0, "ZERO_TOKEN");
    ProductionData storage data = productionData[id];
    require(data.id > 0, "NOT_EXIST");
    require(data.state == ProductionState.OPEN, "NOT_OPEN");
    require(
      data.maxTokensUnknownBuyer == 0 || members.isInvestor(msg.sender) || numTokens <= data.maxTokensUnknownBuyer,
      "MAX_TOKENS_EXCEEDED_FOR_NON_INVESTOR"
    );
    require(data.tokensSoldCounter + numTokens <= data.tokenSupply, "NOT_ENOUGH_TOKENS");
    uint256 price = data.deposits.getNextTokenPrice(investor, numTokens);
    require(price <= msg.value, "NOT_ENOUGH_FUNDS_SENT");
    // update state
    emit ProductionTokenBought(id, investor, numTokens, price);
    data.tokensSoldCounter = numTokens + productionData[id].tokensSoldCounter;
    data.deposits.investorBuyToken{value: price}(investor, numTokens);
    uint256 exceed = msg.value - price;
    if (exceed > 0) {
      payable(msg.sender).transfer(exceed);
    }
  }

  function withdrawFunds(uint256 id, uint256 amount) external override {
    require(members.isOrganizer(msg.sender), "NOT_ORGANIZER");
    require(productionData[id].id > 0, "NOT_EXIST");
    require(productionData[id].state == ProductionState.OPEN, "NOT_OPEN");
    require(amount > 0, "NOT_ZERO");
    emit FundsWithdrawn(id, msg.sender, amount);
    productionData[id].deposits.withdrawFunds(msg.sender, amount);
  }

  function withdrawProceeds(uint256 id) external override {
    require(members.isInvestor(msg.sender), "NOT_INVESTOR");
    ProductionData memory data = productionData[id];
    require(data.id > 0, "NOT_EXIST");
    uint256 amount = data.deposits.getWithdrawableProceeds(msg.sender);
    emit ProceedsWithdrawn(id, msg.sender, amount);
    data.deposits.withdrawProceeds(msg.sender);
  }

  function proceeds(uint256 id) external payable override {
    // checks
    require(members.isOrganizer(msg.sender), "NOT_ORGANIZER");
    require(msg.value > 0, "ZERO_VALUE");
    ProductionData storage data = productionData[id];
    require(data.id > 0, "NOT_EXIST");
    require(data.state == ProductionState.OPEN, "NOT_OPEN");
    // forward to escrow
    emit ProceedsSent(id, msg.sender, msg.value);
    data.deposits.proceeds{value: msg.value}(msg.sender);
  }

  function finish(uint256 id) external payable override {
    // checks
    require(members.isOrganizer(msg.sender), "NOT_ORGANIZER");
    ProductionData storage data = productionData[id];
    require(data.id > 0, "NOT_EXIST");
    require(data.state == ProductionState.OPEN, "NOT_OPEN");
    require(msg.sender == data.creator, "NOT_CREATOR");
    // update state
    if (msg.value > 0) {
      emit ProceedsSent(id, msg.sender, msg.value);
      data.deposits.proceeds{value: msg.value}(msg.sender);
    }
    emit ProductionFinished(id);
    data.state = ProductionState.FINISHED;
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IProductionTokenTracker.sol";

interface IStaxeProductionToken is IERC1155 {
  function mintToken(
    IProductionTokenTracker owner,
    uint256 id,
    uint256 totalAmount
  ) external;

  function mintToken(
    address[2] memory owners,
    uint256 id,
    uint256[2] memory totalAmounts
  ) external;

  function canTransfer(
    uint256 id,
    address from,
    address to,
    uint256 amount
  ) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IProductionTokenTracker.sol";

interface IProductionEscrow is IProductionTokenTracker {
  // ---- Events

  event FundsDeposit(address indexed payer, uint256 amount);
  event ProceedsDeposit(address indexed payer, uint256 amount);
  event FundsPayout(address indexed receiver, uint256 amount);
  event ProceedsPayout(address indexed receiver, uint256 amount);

  // -- Functions

  function investorBuyToken(address investor, uint256 numTokens) external payable;

  function withdrawFunds(address organizer, uint256 amount) external;

  function proceeds(address organizer) external payable;

  function withdrawProceeds(address investor) external;

  function getWithdrawableFunds() external view returns (uint256);

  function getWithdrawableProceeds(address investor) external view returns (uint256);

  function getNextTokenPrice(address investor, uint256 tokensToBuy) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IStaxeMembers {
  function isOrganizer(address sender) external view returns (bool);

  function isApprover(address sender) external view returns (bool);

  function isInvestor(address sender) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IProductionEscrow.sol";
import "./IStaxeProductions.sol";

interface IEscrowFactory {
  function newEscrow(
    IERC1155 token,
    IStaxeProductions productions,
    uint256 productionId
  ) external returns (IProductionEscrow);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IProductionEscrow.sol";

interface IStaxeProductions {
  // ------- Data structures

  enum ProductionState {
    EMPTY,
    CREATED,
    OPEN,
    FINISHED,
    DECLINED
  }

  struct ProductionData {
    uint256 id;
    address creator;
    uint256 tokenSupply;
    uint256 tokensSoldCounter;
    uint256 tokenPrice;
    uint256 maxTokensUnknownBuyer;
    ProductionState state;
    string dataHash;
    IProductionEscrow deposits;
  }

  struct CreateProduction {
    uint256 id;
    uint256 tokenInvestorSupply;
    uint256 tokenOrganizerSupply;
    uint256 tokenTreasurySupply;
    uint256 tokenPrice;
    uint256 maxTokensUnknownBuyer;
    string dataHash;
  }

  // ------- Events

  event ProductionCreated(
    uint256 indexed id,
    address indexed creator,
    uint256 tokenInvestorSupply,
    uint256 tokenOrganizerSupply,
    uint256 tokenTreasurySupply
  );
  event ProductionFinished(uint256 indexed id);
  event ProductionTokenBought(uint256 indexed id, address indexed buyer, uint256 tokens, uint256 tokenPrice);
  event FundsWithdrawn(uint256 indexed id, address indexed organizer, uint256 amount);
  event ProceedsSent(uint256 indexed id, address indexed organizer, uint256 amount);
  event ProceedsWithdrawn(uint256 indexed id, address indexed investor, uint256 amount);

  // ------- Functions

  // Read production data

  function getProductionData(uint256 id) external view returns (ProductionData memory);

  function getProductionDataForProductions(uint256[] memory ids) external view returns (ProductionData[] memory);

  function getWithdrawableFunds(uint256 id) external view returns (uint256);

  function getWithdrawableProceeds(uint256 id) external view returns (uint256);

  function getNextTokenPrice(uint256 id, uint256 tokensToBuy) external view returns (uint256);

  // Lifecycle actions

  function createNewProduction(CreateProduction calldata newProduction) external;

  function approveProduction(uint256 id) external;

  function declineProduction(uint256 id) external;

  function finish(uint256 id) external payable;

  // Financial actions

  function buyTokens(
    uint256 id,
    uint256 numTokens,
    address investor
  ) external payable;

  function withdrawFunds(uint256 id, uint256 amount) external;

  function withdrawProceeds(uint256 id) external;

  function proceeds(uint256 id) external payable;
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IProductionTokenTracker {
  function tokenTransfer(
    IERC1155 tokenContract,
    uint256 tokenId,
    address currentOwner,
    address newOwner,
    uint256 numTokens
  ) external;

  function canTransfer(
    IERC1155 tokenContract,
    uint256 tokenId,
    address currentOwner,
    address newOwner,
    uint256 numTokens
  ) external view returns (bool);
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