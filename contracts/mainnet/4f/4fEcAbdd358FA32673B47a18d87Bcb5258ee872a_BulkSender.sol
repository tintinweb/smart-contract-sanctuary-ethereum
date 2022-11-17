// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BulkSender is Ownable {
  // Events
  event WithdrawEther(address indexed account, uint256 amount);
  event WithdrawToken(address indexed token, address indexed account, uint256 amount);

  event RegisterVIP(address indexed account);
  event RemoveFromVIPList(address[] indexed adresses);
  event AddToVipList(address[] indexed adresses);

  event SetReceiverAddress(address indexed Address);

  event SetVipFee(uint256 newVipFee);
  event SetTxFee(uint256 newTransactionFee);

  event SetMaxAdresses(uint maxAddresses);

  event EthSendSameValue(address indexed sender, address payable[] indexed receiver, uint256 value);
  event EthSendDifferentValue(
    address indexed sender,
    address[] indexed receivers,
    uint256[] values
  );
  event ERC20BulksendSameValue(
    address indexed sender,
    address indexed tokenAddress,
    address[] indexed receivers,
    uint256 value,
    uint256 sendAmount
  );
  event ERC20BulksendDiffValue(
    address indexed sender,
    address indexed tokenAddress,
    address[] indexed receivers,
    uint256[] values,
    uint256 sendAmount
  );
  event ERC721Bulksend(
    address indexed sender,
    address indexed tokenAddress,
    address[] indexed receivers,
    uint256[] values,
    uint256 sendAmount
  );
  event ERC1155Bulksend(
    address indexed sender,
    address indexed tokenAddress,
    address[] indexed receivers,
    uint256[] tokenId,
    uint256[] amount
  );

  // Variables
  address payable public receiverAddress;
  uint256 public txFee = 0.01 ether;
  uint256 public VIPFee = 1 ether;
  uint public maxAddresses = 255;

  bool internal locked;

  // Modifiers
  modifier noReentrant() {
    require(!locked, "No re-entrancy");
    locked = true;
    _;
    locked = false;
  }

  // Functions

  // VIP List
  mapping(address => bool) public vipList;

  // Withdraw Ether
  function withdrawEth() external onlyOwner noReentrant {
    address _receiverAddress = getReceiverAddress();
    uint256 balance = address(this).balance;
    (bool success, ) = _receiverAddress.call{value: balance}("");
    require(success, "Bulksender: failed to send ETH");
    emit WithdrawEther(_receiverAddress, balance);
  }

  // Withdraw ERC20
  function withdrawToken(address _tokenAddress, address _receiverAddress)
    external
    onlyOwner
    noReentrant
  {
    IERC20 token = IERC20(_tokenAddress);
    uint256 balance = token.balanceOf(address(this));
    token.transfer(_receiverAddress, balance);

    emit WithdrawToken(_tokenAddress, _receiverAddress, balance);
  }

  // Register VIP
  function registerVIP() external payable {
    require(vipList[msg.sender] == false, "Bulksender: already vip");
    require(msg.value >= VIPFee, "Bulksender: invalid vip fee");

    address _receiverAddress = getReceiverAddress();
    (bool success, ) = _receiverAddress.call{value: msg.value}("");
    require(success, "Bulksender: failed to send ETH");

    vipList[msg.sender] = true;

    emit RegisterVIP(msg.sender);
  }

  // VIP list
  function addToVIPList(address[] calldata _vipList) external onlyOwner {
    uint256 len = _vipList.length;

    for (uint256 i = 0; i < len; ) {
      vipList[_vipList[i]] = true;
      unchecked {
        ++i;
      }
    }

    emit AddToVipList(_vipList);
  }

  // Remove address from VIP List by Owner
  function removeFromVIPList(address[] calldata _vipList) external onlyOwner {
    uint256 len = _vipList.length;

    for (uint256 i = 0; i < len; ) {
      vipList[_vipList[i]] = false;
      unchecked {
        ++i;
      }
    }

    emit RemoveFromVIPList(_vipList);
  }

  // Check isVIP
  function isVIP(address _addr) public view returns (bool) {
    return _addr == owner() || vipList[_addr];
  }

  // Set receiver address
  function setReceiverAddress(address payable _addr) external onlyOwner {
    require(_addr != address(0), "Bulksender: zero address");
    receiverAddress = _addr;
    emit SetReceiverAddress(_addr);
  }

  // Get receiver address
  function getReceiverAddress() public view returns (address) {
    if (receiverAddress == address(0)) {
      return owner();
    }

    return receiverAddress;
  }

  // Set vip fee
  function setVIPFee(uint256 _fee) external onlyOwner {
    VIPFee = _fee;
    emit SetVipFee(_fee);
  }

  // Set tx fee
  function setTxFee(uint256 _fee) external onlyOwner {
    txFee = _fee;
    emit SetTxFee(_fee);
  }

  // Set max addresses
  function setMaxAdresses(uint _maxAddresses) external onlyOwner {
    require(_maxAddresses > 0, "Bulksender: zero maxAddresses");
    maxAddresses = _maxAddresses;
    emit SetMaxAdresses(_maxAddresses);
  }

  // Sum total values from an array
  function _sumTotalValues(uint256[] calldata _value) internal pure returns (uint256) {
    uint256 sum = 0;
    uint256 len = _value.length;
    for (uint256 i = 0; i < len; ) {
      sum += _value[i];
      unchecked {
        ++i;
      }
    }

    return sum;
  }

  // Send ETH (same value)
  function bulkSendETHWithSameValue(address payable[] calldata _to, uint256 _value) external payable {
    uint256 sendAmount = (_to.length) * _value;
    uint256 remainingValue = msg.value;

    bool vip = isVIP(msg.sender);

    if (vip) {
      require(remainingValue >= sendAmount, "Bulksender: insufficient ETH");
    } else {
      require(remainingValue >= sendAmount + txFee, "Bulksender: invalid txFee");
    }
    require(_to.length <= maxAddresses, "Bulksender: max number of addresses");

    uint256 len = _to.length;

    for (uint256 i = 0; i < len; ) {
      assert(remainingValue >= _value);
      remainingValue -= _value;

      (bool success, ) = _to[i].call{value: _value}("");
      require(success, "Bulksender: failed to send ETH");

      unchecked {
        i++;
      }
    }

    emit EthSendSameValue(msg.sender, _to, _value);
  }

  // Send ETH (different value)
  function bulkSendETHWithDifferentValue(address[] calldata _to, uint256[] calldata _value)
    external payable
  {
    uint256 sendAmount = _sumTotalValues(_value);
    uint256 remainingValue = msg.value;

    bool vip = isVIP(msg.sender);
    if (vip) {
      require(remainingValue >= sendAmount, "Bulksender: invalid eth send");
    } else {
      require(remainingValue >= sendAmount + txFee, "Bulksender: invalid txFee");
    }

    require(_to.length == _value.length, "Bulksender: diff arrays length");
    require(_to.length <= maxAddresses, "Bulksender: max number of addresses");

    uint256 len = _to.length;
    for (uint256 i = 0; i < len; ) {
      assert(remainingValue >= _value[i]);
      remainingValue -= _value[i];

      (bool success, ) = _to[i].call{value: _value[i]}("");
      require(success, "Bulksender: failed to send ETH");

      unchecked {
        ++i;
      }
    }
    emit EthSendDifferentValue(msg.sender, _to, _value);
  }

  // Send ERC20 (same value)
  function bulkSendERC20SameValue(
    address _tokenAddress,
    address[] calldata _to,
    uint256 _value
  ) external payable {
    uint256 sendValue = msg.value;
    bool vip = isVIP(msg.sender);
    if (!vip) {
      require(sendValue >= txFee, "Bulksender: invalid txFee");
    }
    require(_to.length <= maxAddresses, "Bulksender: max number of addresses");

    address from = msg.sender;
    uint256 sendAmount = _to.length * _value;

    IERC20 token = IERC20(_tokenAddress);
    uint256 len = _to.length;
    for (uint256 i = 0; i < len; ) {
      token.transferFrom(from, _to[i], _value);
      unchecked {
        ++i;
      }
    }

    emit ERC20BulksendSameValue(msg.sender, _tokenAddress, _to, _value, sendAmount);
  }

  // Send ERC20 (diff value)
  function bulkSendERC20DiffValue(
    address _tokenAddress,
    address[] calldata _to,
    uint256[] calldata _value
  ) external payable {
    uint256 sendValue = msg.value;
    bool vip = isVIP(msg.sender);

    if (!vip) {
      require(sendValue >= txFee, "Bulksender: invalid txFee");
    }

    require(_to.length == _value.length, "Bulksender: diff arrays length");
    require(_to.length <= maxAddresses, "Bulksender: max number of addresses");

    uint256 sendAmount = _sumTotalValues(_value);
    IERC20 token = IERC20(_tokenAddress);

    uint256 len = _to.length;
    for (uint256 i = 0; i < len; ) {
      token.transferFrom(msg.sender, _to[i], _value[i]);
      unchecked {
        ++i;
      }
    }
    emit ERC20BulksendDiffValue(msg.sender, _tokenAddress, _to, _value, sendAmount);
  }

  //Send ERC721 tokens
  function bulkSendERC721(
    address _tokenAddress,
    address[] calldata _to,
    uint256[] calldata _value
  ) external payable {
    uint256 sendValue = msg.value;
    bool vip = isVIP(msg.sender);

    if (!vip) {
      require(sendValue >= txFee, "Bulksender: invalid txFee");
    }

    require(_to.length == _value.length, "Bulksender: diff arrays length");
    require(_to.length <= maxAddresses, "Bulksender: max number of addresses");

    uint256 sendAmount = _sumTotalValues(_value);
    IERC721 token = IERC721(_tokenAddress);

    uint256 len = _to.length;
    for (uint256 i = 0; i < len; ) {
      token.transferFrom(msg.sender, _to[i], _value[i]);
      unchecked {
        ++i;
      }
    }
    emit ERC721Bulksend(msg.sender, _tokenAddress, _to, _value, sendAmount);
  }

  //Send ERC1155 tokens
  function bulkSendERC1155(
    address _tokenAddress,
    address[] calldata _to,
    uint256[] calldata _tokenId,
    uint256[] calldata _amount
  ) external payable {
    uint256 sendValue = msg.value;
    bool vip = isVIP(msg.sender);
    if (!vip) {
      require(sendValue >= txFee, "Bulksender: invalid txFee");
    }

    require(_to.length == _tokenId.length, "Bulksender: different length of inputs");
    require(_to.length <= maxAddresses, "Bulksender: max number of addresses");

    IERC1155 token = IERC1155(_tokenAddress);

    uint256 len = _to.length;
    for (uint256 i = 0; i < len; ) {
      token.safeTransferFrom(msg.sender, _to[i], _tokenId[i], _amount[i], "0x");
      unchecked {
        ++i;
      }
    }

    emit ERC1155Bulksend(msg.sender, _tokenAddress, _to, _tokenId, _amount);
  }
}