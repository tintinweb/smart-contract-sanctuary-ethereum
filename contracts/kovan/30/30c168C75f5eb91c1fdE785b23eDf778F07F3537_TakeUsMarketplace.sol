// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./SafeVault/proxies/GnosisSafeProxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ITakeUsAddressRegistry {
  function vaultManager() external view returns (address);

  function proxyFactory() external view returns (address);

  function royaltyCollector() external view returns (address);
}

interface IVaultManager {
  function setLendingERC721(
    address,
    uint256,
    address,
    IERC721,
    uint256
  ) external;

  function setLendingERC1155(
    address,
    uint256,
    address,
    IERC1155,
    uint256
  ) external;
}

uint256 constant ERC721TokenType = 0;
uint256 constant ERC1155TokenType = 1;

contract TakeUsMarketplace is Ownable {
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */
  ITakeUsAddressRegistry public addressRegistry;

  uint256 public lenderFee; // Lender fee percentage from 1 to 100
  uint256 public borrowerFee; // Borrower fee percentage from 1 to 100

  struct Lending {
    uint256 duration;
    uint256 price;
    address lender;
    address paymentToken;
  }

  //nftAddress => tokenId
  mapping(IERC721 => mapping(uint256 => Lending)) public listingERC721;

  //nftAddress => tokenId
  mapping(IERC1155 => mapping(uint256 => Lending)) public listingERC1155;

  //SafeVault address
  mapping(address => bool) public isSafeRegistered;

  /* ========== EVENTS ========== */

  // type 0 = ERC721; type 1 = ERC1155

  event Listed(
    address nftAddress,
    uint256 tokenId,
    uint256 price,
    uint256 duration,
    address paymentToken,
    uint256 tokenType
  );
  event Updated(
    address nftAddress,
    uint256 tokenId,
    uint256 price,
    uint256 duration,
    address paymentToken,
    uint256 tokenType
  );
  event Canceled(address nftAddress, uint256 tokenId, uint256 tokenType);
  event Borrowed(
    address nftAddress,
    uint256 tokenId,
    uint256 price,
    uint256 duration,
    address borrower,
    address paymentToken,
    uint256 tokenType
  );

  /* ========== ADMIN FUNCTIONS ========== */

  function setFees(uint256 _newLenderFee, uint256 _newBorrowerFee)
    public
    onlyOwner
  {
    lenderFee = _newLenderFee;
    borrowerFee = _newBorrowerFee;
  }

  function updateAddressRegistry(address _addressRegistry) external onlyOwner {
    addressRegistry = ITakeUsAddressRegistry(_addressRegistry);
  }

  /* ========== MODIFIERS ========== */

  modifier onlyLenderERC721(IERC721 _nftAddress, uint256 _tokenId) {
    require(
      IERC721(_nftAddress).ownerOf(_tokenId) == msg.sender,
      "Caller does not own the item"
    );
    _;
  }

  modifier onlyLenderERC1155(IERC1155 _nftAddress, uint256 _tokenId) {
    require(
      IERC1155(_nftAddress).balanceOf(msg.sender, _tokenId) == 1,
      "Caller does not own the item"
    );
    _;
  }

  modifier eligibleListingERC721(IERC721 _nftAddress, uint256 _tokenId) {
    require(
      listingERC721[_nftAddress][_tokenId].lender != address(0),
      "Listing doesn't exist"
    );
    _;
  }

  modifier eligibleListingERC1155(IERC1155 _nftAddress, uint256 _tokenId) {
    require(
      listingERC1155[_nftAddress][_tokenId].lender != address(0),
      "Listing doesn't exist 1155"
    );
    _;
  }

  /* ========== MUTATIVE ERC721 FUNCTIONS ========== */

  function listERC721(
    IERC721 _nftAddress,
    uint256 _tokenId,
    uint256 _price,
    uint256 _duration,
    address _paymentToken
  ) public onlyLenderERC721(_nftAddress, _tokenId) {
    require(
      listingERC721[_nftAddress][_tokenId].lender == address(0),
      "Already listed"
    );
    require(
      IERC721(_nftAddress).getApproved(_tokenId) == address(this),
      "Marketplace is missing approve"
    );
    if (lenderFee > 0) {
      uint256 fee = (_price * lenderFee) / 100;

      transfer(
        msg.sender,
        addressRegistry.royaltyCollector(),
        fee,
        listingERC721[_nftAddress][_tokenId].paymentToken
      );
    }

    listingERC721[_nftAddress][_tokenId] = Lending({
      duration: _duration,
      price: _price,
      lender: msg.sender,
      paymentToken: _paymentToken
    });

    emit Listed(
      address(_nftAddress),
      _tokenId,
      _price,
      _duration,
      _paymentToken,
      ERC721TokenType
    );
  }

  function updateERC721(
    IERC721 _nftAddress,
    uint256 _tokenId,
    uint256 _price,
    uint256 _duration,
    address _paymentToken
  )
    public
    onlyLenderERC721(_nftAddress, _tokenId)
    eligibleListingERC721(_nftAddress, _tokenId)
  {
    // TODO: calc and transfer new fees if price has changed
    listingERC721[_nftAddress][_tokenId] = Lending({
      duration: _duration,
      price: _price,
      lender: msg.sender,
      paymentToken: _paymentToken
    });
    emit Updated(
      address(_nftAddress),
      _tokenId,
      _price,
      _duration,
      _paymentToken,
      ERC721TokenType
    );
  }

  function cancelERC721(IERC721 _nftAddress, uint256 _tokenId)
    public
    onlyLenderERC721(_nftAddress, _tokenId)
    eligibleListingERC721(_nftAddress, _tokenId)
  {
    delete listingERC721[_nftAddress][_tokenId];

    emit Canceled(address(_nftAddress), _tokenId, ERC721TokenType);
  }

  function borrowERC721(
    address _borrower,
    IERC721 _nftAddress,
    uint256 _tokenId
  ) public eligibleListingERC721(_nftAddress, _tokenId) {
    require(
      isSafeRegistered[_borrower],
      "Only registered SafeVaults may borrow"
    );

    if (borrowerFee > 0) {
      uint256 fee = (listingERC721[_nftAddress][_tokenId].price * borrowerFee) /
        100;
      transfer(
        msg.sender,
        addressRegistry.royaltyCollector(),
        fee,
        listingERC721[_nftAddress][_tokenId].paymentToken
      );
    }

    transfer(
      msg.sender,
      listingERC721[_nftAddress][_tokenId].lender,
      listingERC721[_nftAddress][_tokenId].price,
      listingERC721[_nftAddress][_tokenId].paymentToken
    );
    IVaultManager vaultManager = IVaultManager(addressRegistry.vaultManager());
    vaultManager.setLendingERC721(
      _borrower,
      listingERC721[_nftAddress][_tokenId].duration,
      listingERC721[_nftAddress][_tokenId].lender,
      _nftAddress,
      _tokenId
    );

    IERC721(_nftAddress).safeTransferFrom(
      listingERC721[_nftAddress][_tokenId].lender,
      address(_borrower),
      _tokenId
    );

    emit Borrowed(
      address(_nftAddress),
      _tokenId,
      listingERC721[_nftAddress][_tokenId].price,
      listingERC721[_nftAddress][_tokenId].duration,
      _borrower,
      listingERC721[_nftAddress][_tokenId].paymentToken,
      ERC721TokenType
    );
    delete listingERC721[_nftAddress][_tokenId];
  }

  /* ========== MUTATIVE ERC1155 FUNCTIONS ========== */

  function listERC1155(
    IERC1155 _nftAddress,
    uint256 _tokenId,
    uint256 _price,
    uint256 _duration,
    address _paymentToken
  ) public onlyLenderERC1155(_nftAddress, _tokenId) {
    require(
      IERC1155(_nftAddress).isApprovedForAll(msg.sender, address(this)),
      "Marketplace is missing approve"
    );
    if (lenderFee > 0) {
      uint256 fee = (_price * lenderFee) / 100;
      transfer(
        msg.sender,
        addressRegistry.royaltyCollector(),
        fee,
        listingERC1155[_nftAddress][_tokenId].paymentToken
      );
    }

    listingERC1155[_nftAddress][_tokenId] = Lending({
      duration: _duration,
      price: _price,
      lender: msg.sender,
      paymentToken: _paymentToken
    });
    emit Listed(
      address(_nftAddress),
      _tokenId,
      _price,
      _duration,
      _paymentToken,
      ERC1155TokenType
    );
  }

  function updateERC1155(
    IERC1155 _nftAddress,
    uint256 _tokenId,
    uint256 _price,
    uint256 _duration,
    address _paymentToken
  )
    public
    onlyLenderERC1155(_nftAddress, _tokenId)
    eligibleListingERC1155(_nftAddress, _tokenId)
  {
    // TODO: calc and transfer fee
    listingERC1155[_nftAddress][_tokenId] = Lending({
      duration: _duration,
      price: _price,
      lender: msg.sender,
      paymentToken: _paymentToken
    });
    emit Updated(
      address(_nftAddress),
      _tokenId,
      _price,
      _duration,
      _paymentToken,
      ERC1155TokenType
    );
  }

  function cancelERC1155(IERC1155 _nftAddress, uint256 _tokenId)
    public
    onlyLenderERC1155(_nftAddress, _tokenId)
    eligibleListingERC1155(_nftAddress, _tokenId)
  {
    delete listingERC1155[_nftAddress][_tokenId];

    emit Canceled(address(_nftAddress), _tokenId, ERC1155TokenType);
  }

  function borrowERC1155(
    address _borrower,
    IERC1155 _nftAddress,
    uint256 _tokenId
  ) public eligibleListingERC1155(_nftAddress, _tokenId) {
    require(
      isSafeRegistered[_borrower],
      "Only registered SafeVaults may borrow"
    );

    if (borrowerFee > 0) {
      uint256 fee = (listingERC1155[_nftAddress][_tokenId].price *
        borrowerFee) / 100;
      transfer(
        msg.sender,
        addressRegistry.royaltyCollector(),
        fee,
        listingERC1155[_nftAddress][_tokenId].paymentToken
      );
    }

    transfer(
      msg.sender,
      listingERC1155[_nftAddress][_tokenId].lender,
      listingERC1155[_nftAddress][_tokenId].price,
      listingERC1155[_nftAddress][_tokenId].paymentToken
    );
    IVaultManager vaultManager = IVaultManager(addressRegistry.vaultManager());
    vaultManager.setLendingERC1155(
      _borrower,
      listingERC1155[_nftAddress][_tokenId].duration,
      listingERC1155[_nftAddress][_tokenId].lender,
      _nftAddress,
      _tokenId
    );

    IERC1155(_nftAddress).safeTransferFrom(
      listingERC1155[_nftAddress][_tokenId].lender,
      address(_borrower),
      _tokenId,
      1,
      bytes("0x")
    );

    emit Borrowed(
      address(_nftAddress),
      _tokenId,
      listingERC1155[_nftAddress][_tokenId].price,
      listingERC1155[_nftAddress][_tokenId].duration,
      _borrower,
      listingERC1155[_nftAddress][_tokenId].paymentToken,
      ERC1155TokenType
    );

    delete listingERC1155[_nftAddress][_tokenId];
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  // TODO: Check that works correctly
  function transfer(
    address _from,
    address _to,
    uint256 amount,
    address _paymentToken
  ) internal {
    if (_paymentToken == address(0)) {
      (bool success, ) = payable(_to).call{value: amount}("");
      require(success, "Should transfer ethers");
    } else {
      if (_from == address(this)) {
        IERC20(_paymentToken).transfer(_to, amount);
      } else {
        IERC20(_paymentToken).transferFrom(_from, _to, amount);
      }
    }
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function setIsSafeRegistered(address _safeVault) external {
    require(
      msg.sender == addressRegistry.proxyFactory(),
      "Only TakeUs factory allowed"
    );
    isSafeRegistered[_safeVault] = true;
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title IProxy - Helper interface to access masterCopy of the Proxy on-chain
/// @author Richard Meissner - <[email protected]>
interface IProxy {
  function masterCopy() external view returns (address);
}

/// @title GnosisSafeProxy - Generic proxy contract allows to execute all transactions applying the code of a master contract.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract GnosisSafeProxy {
  // singleton always needs to be first declared variable, to ensure that it is at the same location in the contracts to which calls are delegated.
  // To reduce deployment costs this variable is internal and needs to be retrieved via `getStorageAt`
  address internal singleton;

  /// @dev Constructor function sets address of singleton contract.
  /// @param _singleton Singleton address.
  constructor(address _singleton) {
    require(_singleton != address(0), "Invalid singleton address provided");
    singleton = _singleton;
  }

  /// @dev Fallback function forwards all transactions and returns all received return data.
  fallback() external payable {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      let _singleton := and(
        sload(0),
        0xffffffffffffffffffffffffffffffffffffffff
      )
      // 0xa619486e == keccak("masterCopy()"). The value is right padded to 32-bytes with 0s
      if eq(
        calldataload(0),
        0xa619486e00000000000000000000000000000000000000000000000000000000
      ) {
        mstore(0, _singleton)
        return(0, 0x20)
      }
      calldatacopy(0, 0, calldatasize())
      let success := delegatecall(gas(), _singleton, 0, calldatasize(), 0, 0)
      returndatacopy(0, 0, returndatasize())
      if eq(success, 0) {
        revert(0, returndatasize())
      }
      return(0, returndatasize())
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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