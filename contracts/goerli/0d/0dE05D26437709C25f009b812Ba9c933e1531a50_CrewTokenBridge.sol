// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../lib/access/Manageable.sol";
import "../interfaces/ICrewToken.sol";
import "../interfaces/ICrewTokenV2.sol";
import "../interfaces/IStarknetCore.sol";

contract CrewTokenBridge is Ownable, Manageable {
  ICrewToken public l1TokenContractV1;
  ICrewTokenV2 public l1TokenContractV2;
  IStarknetCore public starknetCore;
  uint256 public l2BridgeContract;
  uint256 public l2BridgeSelector;
  uint256 public l2Dispatcher;
  uint256 constant BRIDGE_MODE_WITHDRAW = 1;
  mapping (address => bool) private _managers;

  // l2BridgeSelector
  // ex: 1635796221232717607866836569175184652572886567842554055902470647001643998800 Crewmate_bridgeFromL1

  constructor(
    address _starknetCore,
    address _l1TokenContractV1,
    address _l1TokenContractV2,
    uint256 _l2BridgeContract,
    uint256 _l2BridgeSelector,
    uint256 _l2Dispatcher
  ) {
    require(_starknetCore != address(0), "Bridge/invalid-starknet-core-address");
    require(_l1TokenContractV1 != address(0), "Bridge/invalid-l1-token-address");
    require(_l1TokenContractV2 != address(0), "Bridge/invalid-l1-token-v2-address");
    require(_l2BridgeContract != 0, "Bridge/invalid-l2-bridge-address");
    require(_l2BridgeSelector != 0, "Bridge/invalid-l2-bridge-selector");
    require(_l2Dispatcher != 0, "Bridge/invalid-l2-dispatcher");

    starknetCore = IStarknetCore(_starknetCore);
    l1TokenContractV1 = ICrewToken(_l1TokenContractV1);
    l1TokenContractV2 = ICrewTokenV2(_l1TokenContractV2);
    l2BridgeContract = _l2BridgeContract;
    l2BridgeSelector = _l2BridgeSelector;
    l2Dispatcher = _l2Dispatcher;
  }

  // Utils
  function addressToUint(address value) internal pure returns (uint256 convertedValue) {
    convertedValue = uint256(uint160(address(value)));
  }

  // Events
  event BridgeToStarknet(
    address l1Contract,
    address l1Account,
    uint256 l2Account,
    uint256 tokenId
  );

  event BridgeFromStarknet(
    uint256 l2Account,
    address l1Contract,
    address l1Account,
    uint256 tokenId
  );

  // Management
  function addManager(address _manager) public override onlyOwner {
    _addManager(_manager);
  }

  function removeManager(address _manager) public override onlyOwner {
    _removeManager(_manager);
  }

  // setters
  function setL1TokenContract(address _l1TokenContractV1) external onlyManagers {
    l1TokenContractV1 = ICrewToken(_l1TokenContractV1);
  }

  function setL1TokenContractV2(address _l1TokenContractV2) external onlyManagers {
    l1TokenContractV2 = ICrewTokenV2(_l1TokenContractV2);
  }

  function setL2BridgeContract(uint256 _l2BridgeContract) external onlyManagers {
    l2BridgeContract = _l2BridgeContract;
  }

  function setL2Dispatcher(uint256 _l2Dispatcher) external onlyManagers {
    l2Dispatcher = _l2Dispatcher;
  }

  // getters
  function getL1TokenContract() public view returns (address) {
    return address(l1TokenContractV1);
  }

  function getL1TokenContractV2() public view returns (address) {
    return address(l1TokenContractV2);
  }

  function getL2BridgeContract() public view returns (uint256) {
    return l2BridgeContract;
  }

  function getL2Dispatcher() public view returns (uint256) {
    return l2Dispatcher;
  }

  // Bridging to Starknet
  function bridgeToStarknet(uint256[] calldata tokenIds, uint256 l2AccountAddress) external {
    require(l2AccountAddress != 0, "Bridge/invalid-account-address");

    // build payload
    uint256[] memory payload = new uint256[](2 + tokenIds.length);
    payload[0] = l2AccountAddress;
    payload[1] = tokenIds.length;

    // check ownership, burn or transfer
    for (uint i = 0; i < tokenIds.length; i++) {
      address _contract;

      if (l1TokenContractV1.ownerOf(tokenIds[i]) == msg.sender) {
        l1TokenContractV1.burn(tokenIds[i]);
        _contract = address(l1TokenContractV1);
      } else if (l1TokenContractV2.ownerOf(tokenIds[i]) == msg.sender) {
        l1TokenContractV2.burn(tokenIds[i]);
        _contract = address(l1TokenContractV2);
      } else {
        revert('Invalid token');
      }

      payload[2 + i] = tokenIds[i];

      emit BridgeToStarknet(_contract, msg.sender, l2AccountAddress, tokenIds[i]);
    }

    // send message to L2
    starknetCore.sendMessageToL2(l2Dispatcher, l2BridgeSelector, payload);
  }

  // Bridging back from Starknet
  function bridgeFromStarknet(uint256[] calldata tokenIds, uint256 l2AccountAddress) external {
    uint256[] memory payload = new uint256[](4 + tokenIds.length);

    // build withdraw message payload
    payload[0] = BRIDGE_MODE_WITHDRAW;
    payload[1] = l2BridgeContract;
    payload[2] = l2AccountAddress;
    payload[3] = addressToUint(msg.sender);

    for (uint256 i = 0; i < tokenIds.length; i++) {
      address currentOwner = l1TokenContractV1.ownerOf(tokenIds[i]);
      if (currentOwner != address(0)) {
        revert('Bridge/token-exists-on-v1');
      }

      l1TokenContractV2.mint(msg.sender, tokenIds[i]);
      payload[4 + i] = tokenIds[i];

      emit BridgeFromStarknet(l2AccountAddress, address(l1TokenContractV2), msg.sender, tokenIds[i]);
    }

    // consume withdraw message
    starknetCore.consumeMessageFromL2(l2BridgeContract, payload);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Manageable is Context {
  mapping (address => bool) private _managers;

  modifier onlyManagers {
    require(isManager(_msgSender()), "Only managers can call this function");
    _;
  }

  /**
   * @dev Add a new manager
   * @param _manager Address of the new manager
   */
  function addManager(address _manager) public virtual {
    _addManager(_manager);
  }

  function _addManager(address _manager) internal virtual {
    _managers[_manager] = true;
  }

  /**
   * @dev Remove a current manager
   * @param _manager Address of the manager to be removed
   */
  function removeManager(address _manager) public virtual {
    _removeManager(_manager);
  }

  function _removeManager(address _manager) internal virtual {
    _managers[_manager] = false;
  }

  function isManager(address _manager) public view virtual returns (bool) {
    return _isManager(_manager);
  }

  function _isManager(address _manager) internal view virtual returns (bool) {
    return _managers[_manager];
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

interface IStarknetCore {
    /**
      Sends a message to an L2 contract.
    */
    function sendMessageToL2(
        uint256 to_address,
        uint256 selector,
        uint256[] calldata payload
    ) external;

    /**
      Consumes a message that was sent from an L2 contract.
    */
    function consumeMessageFromL2(
        uint256 fromAddress,
        uint256[] calldata payload
    ) external;

    /**
      Message registry
     */
    function l2ToL1Messages(bytes32 msgHash) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ICrewTokenV2 is IERC721 {
  function mint(address _to, uint _tokenId) external;

  function burn(uint _tokenId) external;

  function ownerOf(uint256 tokenId) external override view returns (address);

  function transferFrom(address from, address to, uint256 tokenId) external override;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


interface ICrewToken is IERC721 {

  function mint(address _to) external returns (uint);

  function burn(uint _tokenId) external;

  function ownerOf(uint256 tokenId) external override view returns (address);

  function transferFrom(address from, address to, uint256 tokenId) external override;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}