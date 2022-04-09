/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key)
    public
    view
    returns (int256)
    {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index)
    public
    view
    returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}


/*
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

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IBANANAToken {
  function mint(address account, uint256 amount) external;

  function transfer(address recipient, uint256 amount) external returns (bool);

  function totalSupply() external view returns (uint256);
}

contract NODERewardManagement is Ownable {
  using SafeMath for uint256;

  struct NodeEntity {
    uint256 ID;
    uint256 creationTime;
    uint256 lastClaimedTime;
    uint256 tokenValue;
    uint256 rewardAvailable;
  }

  address[] public nodeOwners;
  mapping(address => NodeEntity[]) public _nodesOfUser;

  // // real : 60 * 60 * 24, test : 60 * 3
  uint256 public DetaforDay = 60 * 3;

  address public token;

  uint256 public totalNodesCreated = 0;
  uint256 public nodePrice = 10 * (10**18);
  uint256 public rewardRate = 50;

  bool public createNodeFlag = false;

  constructor(address _token) {
    token = _token;
  }

  modifier onlySentry() {
    require(msg.sender == token, "Fuck off");
    _;
  }

  function uint2str(uint256 _i)
    internal
    pure
    returns (string memory _uintAsString)
  {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  function isNodeOwner(address account) private view returns (bool) {
    return _nodesOfUser[account].length > 0;
  }

  function _isNodeOwner(address account) external view returns (bool) {
    return _nodesOfUser[account].length > 0;
  }

  function _getNodeNumberOf(address account) public view returns (uint256) {
    return _nodesOfUser[account].length;
  }

  function setToken(address _token) external onlyOwner {
    require(_token != address(0), "Token CANNOT BE ZERO");
    token = _token;
  }

  function setDetaforDay(uint256 _DetaforDay) external onlyOwner {
    require(_DetaforDay != 0, "Deta for day CANNOT BE ZERO");
    DetaforDay = _DetaforDay;
  }

  function setRewardRate(uint256 _rewardRate) external onlyOwner {
    require(_rewardRate > 0, "Reward rate CANNOT BE ZERO");
    rewardRate = _rewardRate;
  }

  function _changeNodePrice(uint256 _nodePrice) external onlySentry {
    require(nodePrice != 0, "Node price CANNOT BE ZERO");
    nodePrice = _nodePrice;
  }

  function _upgradeRewardOfNode(address account, uint256 ID)
    external
    onlySentry
  {
    require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");

    NodeEntity storage node = _nodesOfUser[account][ID];
    node.tokenValue += node.rewardAvailable;
    node.rewardAvailable = 0;
    node.lastClaimedTime = block.timestamp;
  }

  function createNode(address account) external onlySentry {
    require(!createNodeFlag, "Creating NODE by other");

    createNodeFlag = true;

    _nodesOfUser[account].push(
      NodeEntity({
        ID: totalNodesCreated,
        creationTime: block.timestamp,
        lastClaimedTime: block.timestamp,
        tokenValue: nodePrice,
        rewardAvailable: 0
      })
    );
    nodeOwners.push(account);
    totalNodesCreated++;

    createNodeFlag = false;
  }

  function _getRewardAmountOf(address account) external view returns (uint256) {
    if (isNodeOwner(account) == false) {
      return 0;
    }
    uint256 nodesCount;
    uint256 rewardCount = 0;

    NodeEntity[] storage nodes = _nodesOfUser[account];
    nodesCount = nodes.length;

    for (uint256 i = 0; i < nodesCount; i++) {
      rewardCount += (nodes[i].rewardAvailable +
        ((((block.timestamp - nodes[i].lastClaimedTime) / DetaforDay) *
          nodes[i].tokenValue) * rewardRate) /
        10000);
    }

    return rewardCount;
  }

  function _getRewardOfNode(address account, uint256 ID)
    external
    view
    returns (uint256)
  {
    if (isNodeOwner(account) == false) {
      return 0;
    }
    uint256 rewardOfNode = 0;

    NodeEntity storage node = _nodesOfUser[account][ID];
    rewardOfNode =
      node.rewardAvailable +
      ((((block.timestamp - node.lastClaimedTime) / DetaforDay) *
        node.tokenValue) * rewardRate) /
      10000;

    return rewardOfNode;
  }

  function _cashoutNodeReward(address account, uint256 ID) external onlySentry {
    require(account != address(0), "NODE: CREATIME must be higher than zero");
    NodeEntity storage node = _nodesOfUser[account][ID];
    node.rewardAvailable = 0;
    node.lastClaimedTime = block.timestamp;
  }

  function _cashoutAllNodesReward(address account) external onlySentry {
    NodeEntity[] storage nodes = _nodesOfUser[account];
    uint256 nodesCount = nodes.length;
    require(nodesCount > 0, "NODE: CREATIME must be higher than zero");
    NodeEntity storage _node;
    for (uint256 i = 0; i < nodesCount; i++) {
      _node = nodes[i];
      _node.lastClaimedTime = block.timestamp;
      _node.rewardAvailable = 0;
    }
  }

  function _updateRewardOfNode(address account) public onlySentry {
    if (!isNodeOwner(account)) {
      return;
    }
    NodeEntity[] storage nodes = _nodesOfUser[account];
    uint256 nodesCount = nodes.length;
    NodeEntity storage _node;
    for (uint256 i = 0; i < nodesCount; i++) {
      _node = nodes[i];
      _node.rewardAvailable =
        _node.rewardAvailable +
        ((((block.timestamp - _node.lastClaimedTime) / DetaforDay) *
          _node.tokenValue) * rewardRate) /
        10000;
      _node.lastClaimedTime = block.timestamp;
    }
  }

  function _updateRewardOfAllNodes() public onlySentry {
    uint256 numberOfNodeOwners = nodeOwners.length;
    NodeEntity[] storage nodes;
    NodeEntity storage _node;
    uint256 nodesCount;
    uint256 index;
    if (numberOfNodeOwners > 0) {
      while (index < numberOfNodeOwners) {
        nodes = _nodesOfUser[nodeOwners[index]];
        index++;
        nodesCount = nodes.length;
        for (uint256 i = 0; i < nodesCount; i++) {
          _node = nodes[i];
          _node.rewardAvailable =
            _node.rewardAvailable +
            ((((block.timestamp - _node.lastClaimedTime) / DetaforDay) *
              _node.tokenValue) * rewardRate) /
            10000;
        }
      }
    }
  }
}