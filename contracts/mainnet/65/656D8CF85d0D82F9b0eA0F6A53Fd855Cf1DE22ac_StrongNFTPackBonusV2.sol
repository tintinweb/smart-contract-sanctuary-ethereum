//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.9;

import "./interfaces/IERC1155Preset.sol";
import "./interfaces/INodePackV3.sol";
import "./lib/SafeMath.sol";
import "./lib/ERC1155Receiver.sol";
import "./lib/AdminAccess.sol";

contract StrongNFTPackBonusV2 is AdminAccess {

  event Staked(address indexed entity, uint tokenId, uint packType, uint timestamp);
  event Unstaked(address indexed entity, uint tokenId, uint packType, uint timestamp);
  event SetPackTypeNFTBonus(uint packType, string bonusName, uint value);

  IERC1155Preset public CERC1155;
  INodePackV3 public nodePack;

  bool public initDone;

  mapping(bytes4 => bool) private _supportedInterfaces;

  string[] public nftBonusNames;
  mapping(string => uint) public nftBonusLowerBound;
  mapping(string => uint) public nftBonusUpperBound;
  mapping(string => uint) public nftBonusEffectiveAt;
  mapping(string => uint) public nftBonusNodesLimit;
  mapping(uint => mapping(string => uint)) public packTypeNFTBonus;

  mapping(uint => address) public nftIdStakedToEntity;
  mapping(uint => uint) public nftIdStakedToPackType;

  mapping(address => uint[]) public entityStakedNftIds;

  mapping(bytes => uint[]) public entityPackStakedNftIds;
  mapping(bytes => uint) public entityPackStakedAt;
  mapping(bytes => uint) public entityPackBonusSaved;

  function init(address _nftContract) external onlyRole(adminControl.SUPER_ADMIN()) {
    require(initDone == false, "init done");

    _registerInterface(0x01ffc9a7);
    _registerInterface(
      ERC1155Receiver(address(0)).onERC1155Received.selector ^
      ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
    );

    CERC1155 = IERC1155Preset(_nftContract);
    initDone = true;
  }

  //
  // Getters
  // -------------------------------------------------------------------------------------------------------------------

  function isNftStaked(uint _nftId) public view returns (bool) {
    return nftIdStakedToPackType[_nftId] != 0;
  }

  function getStakedNftIds(address _entity) public view returns (uint[] memory) {
    return entityStakedNftIds[_entity];
  }

  function getPackStakedNftIds(address _entity, uint _packType) public view returns (uint[] memory) {
    bytes memory id = nodePack.getPackId(_entity, _packType);
    return entityPackStakedNftIds[id];
  }

  function getNftBonusNames() public view returns (string[] memory) {
    return nftBonusNames;
  }

  function getNftBonusNodesLimit(uint _nftId) public view returns (uint) {
    return nftBonusNodesLimit[getNftBonusName(_nftId)];
  }

  function getNftBonusName(uint _nftId) public view returns (string memory) {
    for (uint i = 0; i < nftBonusNames.length; i++) {
      if (_nftId >= nftBonusLowerBound[nftBonusNames[i]] && _nftId <= nftBonusUpperBound[nftBonusNames[i]]) {
        return nftBonusNames[i];
      }
    }

    return "";
  }

  function getNftBonusValue(uint _packType, string memory _bonusName) public view returns (uint) {
    return packTypeNFTBonus[_packType][_bonusName] > 0
    ? packTypeNFTBonus[_packType][_bonusName]
    : packTypeNFTBonus[0][_bonusName];
  }

  function getBonus(address _entity, uint _packType, uint _from, uint _to) public view returns (uint) {
    uint[] memory nftIds = getPackStakedNftIds(_entity, _packType);
    if (nftIds.length == 0) return 0;

    bytes memory id = nodePack.getPackId(_entity, _packType);
    if (entityPackStakedAt[id] == 0) return 0;

    uint bonus = entityPackBonusSaved[id];
    string memory bonusName = "";
    uint startFrom = 0;
    uint nftNodeLimitCount = 0;
    uint boostedNodesCount = 0;
    uint entityPackTotalNodeCount = nodePack.getEntityPackActiveNodeCount(_entity, _packType);

    for (uint i = 0; i < nftIds.length; i++) {
      if (boostedNodesCount >= entityPackTotalNodeCount) break;
      bonusName = getNftBonusName(nftIds[i]);
      if (keccak256(abi.encode(bonusName)) == keccak256(abi.encode(""))) return 0;
      if (nftBonusEffectiveAt[bonusName] == 0) continue;
      if (CERC1155.balanceOf(address(this), nftIds[i]) == 0) continue;

      nftNodeLimitCount = getNftBonusNodesLimit(nftIds[i]);
      if (boostedNodesCount + nftNodeLimitCount > entityPackTotalNodeCount) {
        nftNodeLimitCount = entityPackTotalNodeCount - boostedNodesCount;
      }

      boostedNodesCount += nftNodeLimitCount;
      startFrom = entityPackStakedAt[id] > _from ? entityPackStakedAt[id] : _from;
      if (startFrom < nftBonusEffectiveAt[bonusName]) {
        startFrom = nftBonusEffectiveAt[bonusName];
      }

      if (startFrom >= _to) continue;

      bonus += (_to - startFrom) * getNftBonusValue(_packType, bonusName) * nftNodeLimitCount;
    }

    return bonus;
  }

  //
  // Staking
  // -------------------------------------------------------------------------------------------------------------------

  function stakeNFT(uint _nftId, uint _packType) public payable {
    string memory bonusName = getNftBonusName(_nftId);
    require(keccak256(abi.encode(bonusName)) != keccak256(abi.encode("")), "not eligible");
    require(CERC1155.balanceOf(msg.sender, _nftId) != 0, "not enough");
    require(nftIdStakedToEntity[_nftId] == address(0), "already staked");
    require(nodePack.doesPackExist(msg.sender, _packType), "pack doesnt exist");

    bytes memory id = nodePack.getPackId(msg.sender, _packType);

    entityPackBonusSaved[id] = getBonus(msg.sender, _packType, entityPackStakedAt[id], block.timestamp);

    nftIdStakedToPackType[_nftId] = _packType;
    nftIdStakedToEntity[_nftId] = msg.sender;
    entityPackStakedAt[id] = block.timestamp;
    entityStakedNftIds[msg.sender].push(_nftId);
    entityPackStakedNftIds[id].push(_nftId);

    CERC1155.safeTransferFrom(msg.sender, address(this), _nftId, 1, bytes(""));

    emit Staked(msg.sender, _nftId, _packType, block.timestamp);
  }

  function unStakeNFT(uint _nftId, uint _packType, uint _timestamp) public {
    require(nftIdStakedToEntity[_nftId] != address(0), "not staked");
    require(nftIdStakedToEntity[_nftId] == msg.sender, "not staker");
    require(nftIdStakedToPackType[_nftId] == _packType, "wrong pack");

    nodePack.updatePackState(msg.sender, _packType);

    bytes memory id = nodePack.getPackId(msg.sender, _packType);

    nftIdStakedToPackType[_nftId] = 0;
    nftIdStakedToEntity[_nftId] = address(0);

    for (uint i = 0; i < entityStakedNftIds[msg.sender].length; i++) {
      if (entityStakedNftIds[msg.sender][i] == _nftId) {
        _deleteIndex(entityStakedNftIds[msg.sender], i);
        break;
      }
    }

    for (uint i = 0; i < entityPackStakedNftIds[id].length; i++) {
      if (entityPackStakedNftIds[id][i] == _nftId) {
        _deleteIndex(entityPackStakedNftIds[id], i);
        break;
      }
    }

    CERC1155.safeTransferFrom(address(this), msg.sender, _nftId, 1, bytes(""));

    emit Unstaked(msg.sender, _nftId, _packType, _timestamp);
  }

  //
  // Admin
  // -------------------------------------------------------------------------------------------------------------------

  function updateBonus(string memory _name, uint _lowerBound, uint _upperBound, uint _effectiveAt, uint _nodesLimit) public onlyRole(adminControl.SERVICE_ADMIN()) {
    bool alreadyExists = false;
    for (uint i = 0; i < nftBonusNames.length; i++) {
      if (keccak256(abi.encode(nftBonusNames[i])) == keccak256(abi.encode(_name))) {
        alreadyExists = true;
      }
    }

    if (!alreadyExists) {
      nftBonusNames.push(_name);
    }

    nftBonusLowerBound[_name] = _lowerBound;
    nftBonusUpperBound[_name] = _upperBound;
    nftBonusEffectiveAt[_name] = _effectiveAt != 0 ? _effectiveAt : block.timestamp;
    nftBonusNodesLimit[_name] = _nodesLimit;
  }

  function setPackTypeNFTBonus(uint _packType, string memory _bonusName, uint _value) external onlyRole(adminControl.SERVICE_ADMIN()) {
    packTypeNFTBonus[_packType][_bonusName] = _value;
    emit SetPackTypeNFTBonus(_packType, _bonusName, _value);
  }

  function updateNftContract(address _nftContract) external onlyRole(adminControl.SUPER_ADMIN()) {
    CERC1155 = IERC1155Preset(_nftContract);
  }

  function updateNodePackContract(address _contract) external onlyRole(adminControl.SUPER_ADMIN()) {
    nodePack = INodePackV3(_contract);
  }

  function updateEntityPackStakedAt(address _entity, uint _packType, uint _timestamp) public onlyRole(adminControl.SERVICE_ADMIN()) {
    bytes memory id = nodePack.getPackId(_entity, _packType);
    entityPackStakedAt[id] = _timestamp;
  }

  function setEntityPackBonusSaved(address _entity, uint _packType) external {
    require(msg.sender == address(nodePack), "not allowed");

    bytes memory id = nodePack.getPackId(_entity, _packType);
    entityPackBonusSaved[id] = getBonus(_entity, _packType, entityPackStakedAt[id], block.timestamp);
    entityPackStakedAt[id] = block.timestamp;
  }

  function resetEntityPackBonusSaved(bytes memory _packId) external {
    require(msg.sender == address(nodePack), "not allowed");

    entityPackBonusSaved[_packId] = 0;
  }

  //
  // ERC1155 support
  // -------------------------------------------------------------------------------------------------------------------

  function onERC1155Received(address, address, uint, uint, bytes memory) public virtual returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(address, address, uint[] memory, uint[] memory, bytes memory) public virtual returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  function supportsInterface(bytes4 interfaceId) public view returns (bool) {
    return _supportedInterfaces[interfaceId];
  }

  function _registerInterface(bytes4 interfaceId) internal virtual {
    require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
    _supportedInterfaces[interfaceId] = true;
  }

  function _deleteIndex(uint[] storage array, uint index) internal {
    uint lastIndex = array.length - 1;
    uint lastEntry = array[lastIndex];
    if (index == lastIndex) {
      array.pop();
    } else {
      array[index] = lastEntry;
      array.pop();
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Preset {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;

    function getOwnerIdByIndex(address owner, uint256 index) external view returns (uint256);

    function getOwnerIdIndex(address owner, uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface INodePackV3 {
  function doesPackExist(address entity, uint packId) external view returns (bool);

  function hasPackExpired(address entity, uint packId) external view returns (bool);

  function claim(uint packId, uint timestamp, address toStrongPool) external payable returns (uint);

//  function getBonusAt(address _entity, uint _packType, uint _timestamp) external view returns (uint);

  function getPackId(address _entity, uint _packType) external pure returns (bytes memory);

  function getEntityPackTotalNodeCount(address _entity, uint _packType) external view returns (uint);

  function getEntityPackActiveNodeCount(address _entity, uint _packType) external view returns (uint);

  function migrateNodes(address _entity, uint _nodeType, uint _nodeCount, uint _lastPaidAt, uint _rewardsDue, uint _totalClaimed) external returns (bool);

//  function addPackRewardDue(address _entity, uint _packType, uint _rewardDue) external;

  function updatePackState(address _entity, uint _packType) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    uint256 c = a + b;
    if (c < a) return (false, 0);
    return (true, c);
  }

  /**
   * @dev Returns the substraction of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b > a) return (false, 0);
    return (true, a - b);
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) return (true, 0);
    uint256 c = a * b;
    if (c / a != b) return (false, 0);
    return (true, c);
  }

  /**
   * @dev Returns the division of two unsigned integers, with a division by zero flag.
   *
   * _Available since v3.4._
   */
  function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b == 0) return (false, 0);
    return (true, a / b);
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
   *
   * _Available since v3.4._
   */
  function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b == 0) return (false, 0);
    return (true, a % b);
  }

  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   *
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    return a - b;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   *
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) return 0;
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    return a / b;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * reverting when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: modulo by zero");
    return a % b;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {trySub}.
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    return a - b;
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {tryDiv}.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a / b;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * reverting with custom message when dividing by zero.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {tryMod}.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a % b;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.9;

import "../interfaces/IERC1155Receiver.sol";
import "./ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() internal {
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector ^
            ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../interfaces/IAdminControl.sol";

abstract contract AdminAccess {

  IAdminControl public adminControl;

  modifier onlyRole(uint8 _role) {
    require(address(adminControl) == address(0) || adminControl.hasRole(_role, msg.sender), "no access");
    _;
  }

  function addAdminControlContract(IAdminControl _contract) external onlyRole(0) {
    adminControl = _contract;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.9;

import "./IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.9;

import "../interfaces/IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.9;

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

pragma solidity >=0.6.0;

interface IAdminControl {
  function hasRole(uint8 _role, address _account) external view returns (bool);

  function SUPER_ADMIN() external view returns (uint8);

  function ADMIN() external view returns (uint8);

  function SERVICE_ADMIN() external view returns (uint8);
}