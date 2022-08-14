//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMaster.sol";

/// @title NFT minter
/// @notice The contract allows you to mint new NFT as well as change the parameters of the collection
contract RoundContract is Ownable {

  /// @notice main round information
  struct RoundInfo {
    uint256 mintPrice;
    uint16 collPadding;
    uint16 blocked;
    uint16 maxSupply;
    uint16 roundTotalSupply;
    uint256 startTimestamp;
    uint256 endTimestamp;
    uint8 maxPurchase;
  }
  RoundInfo private info;

  IMaster masterContract;
  bool private _enableWhitelist;
  bool private _enablePayableWhitelist;

  mapping(address => bool) private whiteList;
  mapping(address => bool) private whiteListPayable;
  mapping(address => uint) private _userPurchase;

  event AddToWhitelist(address user);
  event RemoveFromWhitelist(address user);

  event AddToPayableWhitelist(address user);
  event RemoveFromPayableWhitelist(address user);

  constructor(
    uint256 _mintPrice,
    uint16 _blocked,
    uint16 _collPadding,
    uint16 _maxSupply,
    uint256 _startTimestamp,
    uint256 _endTimestamp,
    uint8 _maxPurchase
    ) {
      require(_maxSupply > _blocked + _collPadding, "Round: Too much blocked or too much indentation");
      info.mintPrice = _mintPrice;
      info.collPadding = _collPadding;
      info.maxSupply = _maxSupply;
      info.startTimestamp = _startTimestamp;
      info.endTimestamp = _endTimestamp;
      info.blocked = _blocked;
      info.maxPurchase = _maxPurchase;
  
      whiteList[msg.sender] = true;
      emit AddToWhitelist(msg.sender);
  }

  modifier onlyMaster() {
    require(msg.sender == address(masterContract), "Round: can call only master contract");
    _;
  }

  /// @notice max purchase of round
  function maxPurchase() view public returns(uint) {
    return info.maxPurchase;
  }

  /// @notice check user purchase
  /// @param user address
  function userPurchase(address user) view public returns(uint) {
    return _userPurchase[user];
  }

  /// @notice get contract id range
  /// @return uint[2] from to value
  function range() public view returns(uint16[2] memory) {
    return [info.collPadding, info.maxSupply];
  }

  modifier inWhitelist(address sender) {
    if (_enableWhitelist) {
      require(whiteList[sender], "Round: Account not in whitelist");
    }
    _;
  }

  /// @notice to check if we can mine now
  /// @return bool
  function canMintNow() public view returns(bool) {
    return (
      block.timestamp >= info.startTimestamp && block.timestamp < info.endTimestamp
    );
  }

  /// @notice check current round state
  /// @return bool
  function isFreeRoundNow() public view returns(bool) {
    return block.timestamp >= info.endTimestamp;
  }

  /// @notice set master contract for round
  function setMaster(address _master) external onlyOwner {
    masterContract = IMaster(_master);
  }

  /// @notice user can get master contract address
  /// @return address of master contract
  function getMaster() public view returns(address) {
    return address(masterContract);
  }

  /// @notice user in payable whitelist
  /// @param user address of user
  /// @return bool
  function checkPayableWhitList(address user) public view returns(bool) {
    if (_enablePayableWhitelist) return true;
    return whiteListPayable[user];
  }

  /// @notice function for check is the user logged into whitelist
  /// @param user - target user address
  /// @return bool if user in white list or white list disabled - true else false 
  function checkWhitelist(address user) public view returns(bool) {
    if (_enableWhitelist) return true;
    return whiteList[user];
  }

  /// @notice enable while list
  /// @param enable - true or false value
  function toggleWhitelist(bool enable) external onlyOwner {
    _enableWhitelist = enable;
  }

  /// @notice enable while list
  /// @param enable - true or false value
  function togglePayableWhitelist(bool enable) external onlyOwner {
    _enablePayableWhitelist = enable;
  }

  /// @notice add user to whitelist
  /// @param user - target user
  function addToPayableWhitelist(address user) external onlyOwner {
    whiteListPayable[user] = true;
    emit AddToPayableWhitelist(user);
  }
  
  /// @notice add array of users to whitelist
  /// @param users - array of target users
  function addToPayableWhitelistBatch(address[] calldata users) external onlyOwner {
    for (uint256 i = 0; i < users.length; i++) {
      whiteListPayable[users[i]] = true;
      emit AddToPayableWhitelist(users[i]);
    }
  }

  /// @notice remove user from whitelist
  /// @param user - target user
  function removeFromPayableWhitelist(address user) external onlyOwner {
    whiteListPayable[user] = false;
    emit RemoveFromWhitelist(user);
  }

  /// @notice add user to whitelist
  /// @param user - target user
  function addToWhitelist(address user) external onlyOwner {
    whiteList[user] = true;
    emit AddToWhitelist(user);
  }

  /// @notice add array of users to whitelist
  /// @param users - array of target users
  function addToWhitelistBatch(address[] calldata users) external onlyOwner {
    for (uint256 i = 0; i < users.length; i++) {
      whiteList[users[i]] = true;
      emit AddToWhitelist(users[i]);
    }
  }

  /// @notice remove user from whitelist
  /// @param user - target user
  function removeFromWhitelist(address user) external onlyOwner {
    whiteList[user] = false;
    emit RemoveFromWhitelist(user);
  }

  /// @notice get mint price of round
  /// @return uint - price
  function mintPrice() external view returns(uint256) {
    return info.mintPrice;
  }

  /// @notice create random number
  /// @param i - noise nonce
  /// @param from - address nonce
  /// @return uint - new random value
  function _random(uint i, address from) private view returns(uint) {
    return ((uint(keccak256(
      abi.encode(from, i, block.timestamp)
    )) % (info.maxSupply - info.collPadding)) + 1) + info.collPadding;
  }

  /// @notice Use for check the content of the element in the array
  /// @param array of uints
  /// @param value target value
  function _contain(uint[] memory array, uint value) pure private returns(bool) {
    bool contained = false;
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == value) {
        contained = true;
        break;
      }
    }
    return contained;
  }

  function setUserPurchase(uint n, address user) onlyMaster external {
    _userPurchase[user] += n;
  }

  function setRoundTotalSupply(uint16 n) onlyMaster external {
    info.roundTotalSupply += n;
  }

  function roundTotalSupply() external view returns(uint) {
    return info.roundTotalSupply;
  }

  /// @notice Create random number
  /// @dev the function accesses an external master contract and asks if the generated id is busy
  /// @dev max attemps - 1000
  /// @param nTokens => attempt
  /// @return info.collPadding <= random number <= maxSupply
  function getRandoms(address from, uint nTokens) public view inWhitelist(from) returns(uint[] memory) {
    require(nTokens > 0, "Round: The number of tokens must be greater than zero");
    require(nTokens <= info.maxSupply, "Round: too many token for mint - out of round max supply");
    require(canMintNow() || (isFreeRoundNow() && checkPayableWhitList(msg.sender)), "NFT round: you cant mint now");
    require(maxPurchase() >= nTokens, "NFT round: So many tokens are not allowed to be minted");
    require(maxPurchase() > userPurchase(from), "NFT round: you can't mint anymore");
    require(checkWhitelist(msg.sender), "NFT round: You're not in white list");
    if (isFreeRoundNow() && checkPayableWhitList(from)) {
      require(nTokens <= info.maxSupply - info.collPadding - info.roundTotalSupply, "Round: too many token for mint");
    } else {
      require(nTokens <= info.maxSupply - info.collPadding - info.blocked - info.roundTotalSupply, "Round: too many token for mint");
    }

    uint[] memory idxs = new uint[](nTokens);
    uint16 n = 0;
    uint i = 0;
    while(_contain(idxs, 0)) {
      uint idx = _random(i, from);
      if (!masterContract.idOccuped(idx) && !_contain(idxs, idx) && idx > 0) {
        idxs[i] = idx;
        i++;
      }
      if (n == 1000) {
        break;
      }
      else {
        n += 1;
      }
    }

    return idxs;
  }
}

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
pragma solidity ^0.8.2;

interface IMaster {
  enum Round {
    Legendary,
    Epic,
    SuperRare,
    Rare,
    Public
  }

  function fulfillMetaDataRequest(string memory json, uint id, uint tokenId) external;

  function setMetaDataOracleAddress(address newAddress) external;

  function getRoundPrice(Round round) external view returns(uint);

  function showMetaData(uint tokenId) external view returns(string memory);

  function mint(Round round, uint n) payable external;

  function idOccuped(uint tokenId) external view returns(bool);
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