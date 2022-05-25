// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./interfaces/IBattlefield.sol";
import "./interfaces/IGloryGameNFT.sol";
import "./interfaces/IGloryToken.sol";
import "./interfaces/ISacrificedGold.sol";

import "./libraries/TimelineUtils.sol";
import "./libraries/RewardRateList.sol";

// solhint-disable not-rely-on-time, reason-string, max-states-count

contract Battlefield is AccessControlUpgradeable, IBattlefield {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using RewardRateList for RewardRateList.PeriodList;

  event TokenStaked(address indexed owner, uint256 indexed tokenId, bool isLord);
  event KnightClaimed(address indexed owner, uint256 indexed tokenId, bool unstake);
  event LordClaimed(address indexed owner, uint256 indexed tokenId, bool unstake);

  event UpdateKnightClaimTax(uint256 _tax);
  event UpdateKnightUnstakeTakeAllProb(uint256 _prob);
  event UpdateGoldRewardRate(uint256 _start, uint256 _dailyRate);
  event UpdateGloryRewardRate(uint256 indexed _peerage, uint256 _start, uint256 _dailyRate);

  struct KnightState {
    // The owner of the NFT.
    address owner;
    // The token id of the NFT, max 50000 supply, `uint24` should be enough.
    uint24 tokenId;
    // The index in `knights` list in AccountState.
    uint24 indexOfAccountState;
    // The timestamp when last claim/unstake for this NFT.
    uint48 lastClaimTime;
  }

  struct LordStateHint {
    address owner;
    // The token id of the NFT, max 50000 supply, `uint32` should be enough.
    uint32 tokenId;
    // The index in `lords` list in AccountState.
    uint32 indexOfAccountState;
    // The index in lordStates
    uint32 indexOfLordState;
  }

  struct LordState {
    // The accumulated $GOLD per rank paid.
    // amount * PRECISION / totalRakeStaked, `uint160` should be enough.
    uint160 accGoldPerRankPaid;
    // The token id of the NFT, max 50000 supply, `uint32` should be enough.
    uint32 tokenId;
    // The timestamp when last claim/unstake for this NFT.
    uint64 lastClaimTime;
  }

  struct AccountState {
    // The list of staked knights.
    uint256[] knights;
    // The list of staked lords.
    uint256[] lords;
  }

  bytes32 public constant GAME_PROXY_ROLE = keccak256("GAME_PROXY_ROLE");

  // The smallest prime number larger than 1e38
  uint256 private constant MAGIC_PRIME = uint256(100000000000000000000000000000000000133);
  // The precision for boost rate, tax percentage, probability.
  uint256 private constant PRECISION = 10**9;
  // eligible to unstake when two days passed (accumulated $GOLD has reached at least 40)
  uint256 private constant MIN_GOLD_TO_UNSTAKE = 40 ether;

  /// @notice The address of $GOLD token.
  address public goldToken;
  /// @notice The address of sacrificed gold contract.
  address public sGold;
  /// @notice The address of $GLORY token.
  address public gloryToken;
  /// @notice The address of Glory Game NFT
  address public gloryNFT;
  /// @notice The address of Glory Game Pass
  address public gloryGamePass;

  /// @notice The percentage of tax of $GLORY accumulated by Knight, default is 20%.
  uint256 public knightClaimTax;
  /// @notice The chance of all of accumulated $GLORY being seized by the Lords, default is 50%.
  uint256 public knightUnstakeTakeAllProb;

  /// @notice The number of Knight staked.
  uint256 public knightStakedCount;
  /// @notice The sum of rank of lord staked.
  uint256 public lordRankStakedCount;
  /// @notice The amount of undistributed $GLORY tax from knight
  uint256 public undistributedGoldReward;
  /// @notice The accumulated $GOLD per rank.
  uint256 public accGoldPerRank;

  /// @dev Mapping from token id to Knight State.
  mapping(uint256 => KnightState) private battlefield;
  /// @dev Mapping from account address to Account State.
  mapping(address => AccountState) private accountStates;
  /// @dev Mapping from lord peerage to a list of staked lord.
  mapping(uint256 => LordState[]) private lordStates;
  /// @dev Mapping from lord token id to index in peerageStates.
  mapping(uint256 => LordStateHint) private council;

  /// @dev The list of knight $GOLD reward rate.
  RewardRateList.PeriodList private knightGoldRewardRateList;

  /// @dev Mapping from peerage to loard $GLORY reward rate.
  mapping(uint256 => RewardRateList.PeriodList) private lordGloryRewardRateList;

  function initialize(
    address _goldToken,
    address _sGold,
    address _gloryToken,
    address _gloryNFT,
    address _gloryGamePass
  ) external initializer {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

    goldToken = _goldToken;
    sGold = _sGold;
    gloryToken = _gloryToken;
    gloryNFT = _gloryNFT;
    gloryGamePass = _gloryGamePass;

    IERC20Upgradeable(_goldToken).safeApprove(_sGold, type(uint256).max);

    knightClaimTax = 2e8; // 20%
    knightUnstakeTakeAllProb = 5e8; // 50%

    unchecked {
      uint32 _timestamp = uint32(block.timestamp);
      knightGoldRewardRateList.add(_timestamp, uint112(20 ether / TimelineUtils.SECONDS_IN_DAY));
      lordGloryRewardRateList[1].add(_timestamp, uint112(2 ether / TimelineUtils.SECONDS_IN_DAY)); // Baron
      lordGloryRewardRateList[2].add(_timestamp, uint112(2.5 ether / TimelineUtils.SECONDS_IN_DAY)); // Viscount
      lordGloryRewardRateList[3].add(_timestamp, uint112(3 ether / TimelineUtils.SECONDS_IN_DAY)); // Earl
      lordGloryRewardRateList[4].add(_timestamp, uint112(3.5 ether / TimelineUtils.SECONDS_IN_DAY)); // Marquess
      lordGloryRewardRateList[5].add(_timestamp, uint112(4 ether / TimelineUtils.SECONDS_IN_DAY)); // Duke
    }
  }

  /**************************************** View Function ****************************************/

  /// @notice Return the actual owner of the staked NFT.
  /// @param _tokenId The token id to query.
  function tokenOwner(uint256 _tokenId) public view override returns (address) {
    IGloryGameNFT.Traits memory _traits = IGloryGameNFT(gloryNFT).getTokenTraits(_tokenId);
    if (_traits.isLord) {
      LordStateHint memory _hint = council[_tokenId];
      return _hint.owner;
    } else {
      KnightState memory _knight = battlefield[_tokenId];
      return _knight.owner;
    }
  }

  /// @notice Return the pending reward for the staked NFT.
  /// @param _tokenId The token id to query.
  function pendingReward(uint256 _tokenId) external view override returns (uint256, uint256) {
    IGloryGameNFT.Traits memory _traits = IGloryGameNFT(gloryNFT).getTokenTraits(_tokenId);
    if (_traits.isLord) {
      LordStateHint memory _hint = council[_tokenId];
      // not in council, no rewards
      if (_hint.owner == address(0)) return (0, 0);
      LordState memory _lord = lordStates[_traits.peerage][_hint.indexOfLordState];

      return (
        _traits.peerage * (accGoldPerRank - _lord.accGoldPerRankPaid), // gold tax
        lordGloryRewardRateList[_traits.peerage].rewards(_lord.lastClaimTime, block.timestamp) // glory rewards
      );
    } else {
      KnightState memory _knight = battlefield[_tokenId];
      // not in battlefield, no rewards
      if (_knight.owner == address(0)) return (0, 0);
      return (knightGoldRewardRateList.rewards(_knight.lastClaimTime, block.timestamp), 0);
    }
  }

  /// @notice Return the list of token ids of NFT staked.
  /// @param _account The address of account to query.
  function depositsOf(address _account) external view returns (uint256[] memory) {
    AccountState storage _accountState = accountStates[_account];
    uint256[] memory _tokenIds = new uint256[](_accountState.knights.length + _accountState.lords.length);

    uint256 _offset;
    uint256 _length = _accountState.knights.length;
    for (uint256 i; i < _length; i++) {
      _tokenIds[_offset] = _accountState.knights[i];
      _offset += 1;
    }
    _length = _accountState.lords.length;
    for (uint256 i; i < _length; i++) {
      _tokenIds[_offset] = _accountState.lords[i];
      _offset += 1;
    }

    return _tokenIds;
  }

  /// @notice Return the address of random selected Lord owner with the given seed.
  /// @param _seed The seed used to random select lord.
  function randomSelectLord(uint256 _seed) external view returns (address) {
    if (lordRankStakedCount == 0) {
      return address(0);
    }
    uint256 _sum;
    unchecked {
      for (uint256 _peerage = 1; _peerage <= 5; _peerage++) {
        _sum += (_peerage + 7) * lordStates[_peerage].length;
      }
      uint256 _rem = _seed % _sum;
      _sum = 0;
      for (uint256 _peerage = 1; _peerage <= 5; _peerage++) {
        _sum = (_peerage + 7) * lordStates[_peerage].length;
        if (_rem < _sum) {
          // now, we have the index
          _rem /= (_peerage + 7);
          uint256 _tokenId = lordStates[_peerage][_rem].tokenId;
          return council[_tokenId].owner;
        } else {
          _rem -= _sum;
        }
      }
    }
    return address(0);
  }

  /**************************************** Mutate Function ****************************************/

  /// @notice Stake Knights/Lords NFT to Battlefield Contract.
  /// @param _account The address of account to stake.
  /// @param _tokenIds The list to tokens to stake
  function join(address _account, uint256[] calldata _tokenIds) external onlyRole(GAME_PROXY_ROLE) {
    address _gloryNFT = gloryNFT;
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      if (_tokenIds[i] == 0) continue;
      address _owner = IERC721Upgradeable(_gloryNFT).ownerOf(_tokenIds[i]);

      // a mint + stake will send directly to the staking contract
      if (_owner != address(this)) {
        require(_owner == _account, "Battlefield: token not owned");
        IERC721Upgradeable(_gloryNFT).transferFrom(_account, address(this), _tokenIds[i]);
      } else {
        require(tokenOwner(_tokenIds[i]) == address(0), "Battlefield: token already staked");
      }

      IGloryGameNFT.Traits memory _traits = IGloryGameNFT(gloryNFT).getTokenTraits(_tokenIds[i]);
      if (_traits.isLord) {
        _addLordToCouncil(_account, _tokenIds[i], _traits.peerage);
      } else {
        _addKnightToBattlefield(_account, _tokenIds[i]);
      }
    }
  }

  /// @notice Claim rewards for the given NFT tokens.
  /// @param _seed The seed used to random tax.
  /// @param _owner The address of the owner to claim/unstake.
  /// @param _tokenIds The list to tokens to claim/unstake.
  /// @param _unstake Whether to unstake the NFT.
  function claim(
    uint256 _seed,
    address _owner,
    uint256[] calldata _tokenIds,
    bool _unstake
  ) external onlyRole(GAME_PROXY_ROLE) {
    uint256 _gloryReward;
    uint256 _goldReward;
    uint256 _goldToLock;
    address _gloryNFT = gloryNFT;
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      IGloryGameNFT.Traits memory _traits = IGloryGameNFT(_gloryNFT).getTokenTraits(_tokenIds[i]);
      if (_traits.isLord) {
        (uint256 _gold, uint256 _glory) = _claimLordFromCouncil(_owner, _tokenIds[i], _traits.peerage, _unstake);
        unchecked {
          _gloryReward += _glory;
          _goldReward += _gold;
        }
      } else {
        _seed = uint256(keccak256(abi.encodePacked(_seed, _owner, _tokenIds[i])));
        (uint256 _gold, uint256 _toLock) = _claimKnightFromBattlefield(_seed, _owner, _tokenIds[i], _unstake);
        unchecked {
          _goldReward += _gold;
          _goldToLock += _toLock;
        }
      }
    }

    if (_gloryReward > 0) {
      IGloryToken(gloryToken).mint(_owner, _gloryReward);
    }

    if (_goldReward > 0) {
      IGloryToken(goldToken).mint(_owner, _goldReward);
    }

    if (_goldToLock > 0) {
      IGloryToken(goldToken).mint(address(this), _goldToLock);
      // lock $GOLD as sGOLD for 16 weeks.
      ISacrificedGold(sGold).lockFor(_owner, _goldToLock, 16);
    }
  }

  /// @notice Cleaning battlefield.
  /// @param _account The address of account.
  /// @param _seed The seed used to random rewards.
  function clean(address _account, uint256 _seed) external onlyRole(GAME_PROXY_ROLE) {
    uint256 _reminder = _seed % MAGIC_PRIME;
    uint256 _mintAmount;
    if (_reminder < 10**36 * 5) {
      // 5% chance mint 20 GLORY
      _mintAmount = 20 ether;
    } else if (_reminder < 10**36 * 20) {
      // 15% chance mint 10 GLORY
      _mintAmount = 10 ether;
    } else if (_reminder < 10**36 * 50) {
      // 30% chance mint 5 GLORY
      _mintAmount = 5 ether;
    } else if (_reminder < 10**36 * 90) {
      // 40% chance mint 1 GLORY
      _mintAmount = 1 ether;
    }
    // @todo weapon pass
    // @todo limit total GLORY amount
    if (_mintAmount > 0) {
      IGloryToken(gloryToken).mint(_account, _mintAmount);
    }
  }

  /**************************************** Restrict Function ****************************************/

  /// @notice Update the tax charge by lord when claiming rewards.
  /// @param _tax The tax percentage to update.
  function updateKnightClaimTax(uint256 _tax) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_tax <= PRECISION, "Battlefield: tax exceed 100%");
    knightClaimTax = _tax;

    emit UpdateKnightClaimTax(_tax);
  }

  /// @notice Update the probability to take all rewards when knight unstake.
  /// @param  _prob The probability to update.
  function updateKnightUnstakeTakeAllProb(uint256 _prob) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_prob <= PRECISION, "Battlefield: probability exceed 100%");
    knightUnstakeTakeAllProb = _prob;

    emit UpdateKnightUnstakeTakeAllProb(_prob);
  }

  /// @notice Update the daily reward rate for $GOLD token.
  /// @param _start The timestamp when the change take affect.
  /// @param _dailyRate The daily reward rate to update.
  function updateGoldRewardRate(uint32 _start, uint112 _dailyRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_start >= block.timestamp, "Battlefield: timestamp too small");

    knightGoldRewardRateList.add(_start, uint112(_dailyRate / TimelineUtils.SECONDS_IN_DAY));

    emit UpdateGoldRewardRate(_start, _dailyRate);
  }

  /// @notice Update the daily reward rate for $GLORY token.
  /// @param _peerage The peerage to update.
  /// @param _start The timestamp when the change take affect.
  /// @param _dailyRate The daily reward rate to update.
  function updateGloryRewardRate(
    uint256 _peerage,
    uint32 _start,
    uint112 _dailyRate
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_start >= block.timestamp, "Battlefield: timestamp too small");
    require(1 <= _peerage && _peerage <= 5, "Battlefield: invalid peerage");

    lordGloryRewardRateList[_peerage].add(_start, uint112(_dailyRate / TimelineUtils.SECONDS_IN_DAY));

    emit UpdateGloryRewardRate(_peerage, _start, _dailyRate);
  }

  /**************************************** Internal Function ****************************************/

  function _payTaxToLord(uint256 _amount) internal {
    uint256 _lordRankStakedCount = lordRankStakedCount;
    if (_lordRankStakedCount == 0) {
      // no staked lord, keep track of unaccounted rewards
      unchecked {
        undistributedGoldReward += _amount;
      }
    } else {
      uint256 _undistributedGoldReward = undistributedGoldReward;
      unchecked {
        _amount += _undistributedGoldReward;
        accGoldPerRank += (_amount * PRECISION) / _lordRankStakedCount;
      }
      if (_undistributedGoldReward != 0) {
        undistributedGoldReward = 0;
      }
    }
  }

  function _addKnightToBattlefield(address _owner, uint256 _tokenId) internal {
    uint256[] storage _knights = accountStates[_owner].knights;
    battlefield[_tokenId] = KnightState({
      owner: _owner,
      tokenId: uint24(_tokenId),
      indexOfAccountState: uint24(_knights.length),
      lastClaimTime: uint48(block.timestamp)
    });
    _knights.push(_tokenId);

    unchecked {
      knightStakedCount += 1;
    }

    emit TokenStaked(_owner, _tokenId, false);
  }

  function _addLordToCouncil(
    address _owner,
    uint256 _tokenId,
    uint256 _peerage
  ) internal {
    uint256[] storage _lords = accountStates[_owner].lords;
    LordState[] storage _list = lordStates[_peerage];
    council[_tokenId] = LordStateHint({
      owner: _owner,
      tokenId: uint32(_tokenId),
      indexOfAccountState: uint32(_lords.length),
      indexOfLordState: uint32(_list.length)
    });
    _lords.push(_tokenId);

    uint256 _accGoldPerRank = accGoldPerRank;
    require(_accGoldPerRank <= type(uint160).max, "Battlefield: value not fit uint160");
    _list.push(
      LordState({
        accGoldPerRankPaid: uint160(_accGoldPerRank),
        tokenId: uint32(_tokenId),
        lastClaimTime: uint64(block.timestamp)
      })
    );

    unchecked {
      lordRankStakedCount += _peerage;
    }

    emit TokenStaked(_owner, _tokenId, true);
  }

  function _claimKnightFromBattlefield(
    uint256 _seed,
    address _owner,
    uint256 _tokenId,
    bool _unstake
  ) internal returns (uint256, uint256) {
    KnightState memory _knight = battlefield[_tokenId];
    require(_knight.owner != address(0), "Battlefield: token not staked");
    require(_knight.owner == _owner, "Battlefield: token not owned");

    uint256 _rewards = knightGoldRewardRateList.rewards(_knight.lastClaimTime, block.timestamp);
    if (_unstake) {
      require(_rewards >= MIN_GOLD_TO_UNSTAKE, "Battlefield: unable to unstake");
    }
    uint256 _toLock;
    if (_unstake) {
      // 50% change to lose all
      if ((_seed % MAGIC_PRIME) % PRECISION <= knightUnstakeTakeAllProb) {
        _payTaxToLord(_rewards);
        _rewards = 0;
      }
      unchecked {
        knightStakedCount -= 1;
      }

      // remove from knights list
      unchecked {
        uint256[] storage _knights = accountStates[_owner].knights;
        uint256 _length = _knights.length;
        // swap to last if it is not the last element.
        if (_length - 1 != _knight.indexOfAccountState) {
          uint256 _last = _knights[_length - 1];
          battlefield[_last].indexOfAccountState = _knight.indexOfAccountState;
          _knights[_knight.indexOfAccountState] = _last;
        }
        _knights.pop();
      }
      delete battlefield[_tokenId];

      IERC721Upgradeable(gloryNFT).transferFrom(address(this), _owner, _tokenId);
    } else {
      unchecked {
        uint256 _tax = (_rewards * _getTaxPercent(_owner)) / PRECISION;
        _payTaxToLord(_tax);
        _rewards -= _tax;
      }
      _toLock = _rewards;
      _rewards = 0;
      _knight.lastClaimTime = uint48(block.timestamp);
      battlefield[_tokenId] = _knight;
    }

    emit KnightClaimed(_owner, _tokenId, _unstake);

    return (_rewards, _toLock);
  }

  function _claimLordFromCouncil(
    address _owner,
    uint256 _tokenId,
    uint256 _peerage,
    bool _unstake
  ) internal returns (uint256, uint256) {
    LordStateHint memory _hint = council[_tokenId];
    require(_hint.owner != address(0), "Battlefield: not staked");
    require(_hint.owner == _owner, "Battlefield: not owned by caller");
    LordState[] storage _list = lordStates[_peerage];
    LordState memory _lord = _list[_hint.indexOfLordState];
    uint256 _accGoldPerRank = accGoldPerRank;
    uint256 _gloryReward = lordGloryRewardRateList[_peerage].rewards(_lord.lastClaimTime, block.timestamp);
    uint256 _goldReward = (_peerage * (_accGoldPerRank - _lord.accGoldPerRankPaid)) / PRECISION;

    if (_unstake) {
      unchecked {
        lordRankStakedCount -= _peerage;
      }

      // remove from lordStates
      unchecked {
        uint256 _length = _list.length;
        // swap to last if it is not the last element.
        if (_length - 1 != _hint.indexOfLordState) {
          LordState memory _last = _list[_length - 1];
          council[_last.tokenId].indexOfLordState = _hint.indexOfLordState;
          _list[_hint.indexOfLordState] = _last;
        }
        _list.pop();
      }

      // remove from lords
      unchecked {
        uint256[] storage _lords = accountStates[_owner].lords;
        uint256 _length = _lords.length;
        // swap to last if it is not the last element.
        if (_length - 1 != _hint.indexOfAccountState) {
          uint256 _last = _lords[_length - 1];
          council[_last].indexOfAccountState = _hint.indexOfAccountState;
          _lords[_hint.indexOfAccountState] = _last;
        }
        _lords.pop();
      }
      delete council[_tokenId];

      IERC721Upgradeable(gloryNFT).transferFrom(address(this), _owner, _tokenId);
    } else {
      require(_accGoldPerRank <= type(uint160).max, "Battlefield: value not fit uint160");
      _lord.accGoldPerRankPaid = uint160(_accGoldPerRank);
      _lord.lastClaimTime = uint64(block.timestamp);
      lordStates[_peerage][_hint.indexOfLordState] = _lord;
    }

    emit LordClaimed(_owner, _tokenId, _unstake);

    return (_goldReward, _gloryReward);
  }

  function _getTaxPercent(address) internal view returns (uint256) {
    return knightClaimTax;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

pragma solidity ^0.8.12;

interface IBattlefield {
  function tokenOwner(uint256 _tokenId) external view returns (address);

  function pendingReward(uint256 _tokenId) external view returns (uint256, uint256);

  function join(address _tokenOwner, uint256[] calldata _tokenIds) external;

  function claim(
    uint256 _seed,
    address _tokenOwner,
    uint256[] calldata _tokenIds,
    bool _leave
  ) external;

  function clean(address _account, uint256 _seed) external;

  function randomSelectLord(uint256 _seed) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IGloryGameNFT {
  struct Traits {
    bool isLord;
    uint8 peerage;
  }

  function getTokenTraits(uint256 _tokenId) external view returns (Traits memory);

  function mint(address _recipient, uint256 _seed) external returns (uint256);

  function burn(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGloryToken is IERC20 {
  function mint(address to, uint256 amount) external;

  function burn(uint256 amount) external;

  function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface ISacrificedGold {
  function balanceOf(address _account) external view returns (uint256);

  function lock(uint256 _amount, uint256 _weeks) external;

  function lockFor(
    address _recipient,
    uint256 _amount,
    uint256 _weeks
  ) external;

  function withdraw() external;

  function requestLeavePenaty(address _account) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

// solhint-disable not-rely-on-time

library TimelineUtils {
  /// @dev The number of seconds in 1 day.
  uint256 internal constant SECONDS_IN_DAY = 86400;
  /// @dev The number of seconds in 1 week.
  uint256 internal constant SECONDS_IN_WEEK = SECONDS_IN_DAY * 7;
  /// @dev The timestamp offset of the cycle beginning in seconds.
  /// The start of cycle (Sunday 1:00:00 PM Eastern Standard Time) will be
  ///       block.timestamp / SECONDS_IN_WEEK * SECONDS_IN_WEEK + CYCLE_TIMESTAMP_OFFSET
  /// The start of day off (Saturday 1:00:00 PM Eastern Standard Time) will be
  ///       block.timestamp / SECONDS_IN_WEEK * SECONDS_IN_WEEK + CYCLE_TIMESTAMP_OFFSET + SECONDS_IN_DAY * 6
  uint256 internal constant CYCLE_TIMESTAMP_OFFSET = 324000;
  uint256 internal constant DAY_TIMESTAMP_OFFSET = CYCLE_TIMESTAMP_OFFSET % SECONDS_IN_DAY;

  function week(uint256 _timestamp) internal pure returns (uint256) {
    return (_timestamp - CYCLE_TIMESTAMP_OFFSET) / SECONDS_IN_WEEK;
  }

  function currentCycleStartTimestamp(uint256 _timestamp) internal pure returns (uint256) {
    uint256 _reminder = _timestamp % SECONDS_IN_WEEK;
    if (_reminder < CYCLE_TIMESTAMP_OFFSET) {
      return _timestamp - _reminder - SECONDS_IN_WEEK + CYCLE_TIMESTAMP_OFFSET;
    } else {
      return _timestamp - _reminder + CYCLE_TIMESTAMP_OFFSET;
    }
  }

  function currentCycleDayoffTimestamp(uint256 _timestamp) internal pure returns (uint256) {
    unchecked {
      return currentCycleStartTimestamp(_timestamp) + SECONDS_IN_DAY * 6;
    }
  }

  function nextCycleStartTimestamp(uint256 _timestamp) internal pure returns (uint256) {
    unchecked {
      return currentCycleStartTimestamp(_timestamp) + SECONDS_IN_WEEK;
    }
  }

  function currentDayStartTimestamp(uint256 _timestamp) internal pure returns (uint256) {
    uint256 _reminder = _timestamp % SECONDS_IN_DAY;
    if (_reminder < SECONDS_IN_DAY) {
      return _timestamp - _reminder - SECONDS_IN_DAY + DAY_TIMESTAMP_OFFSET;
    } else {
      return _timestamp - _reminder + DAY_TIMESTAMP_OFFSET;
    }
  }

  function nextDayStartTimestamp(uint256 _timestamp) internal pure returns (uint256) {
    return currentDayStartTimestamp(_timestamp) + SECONDS_IN_DAY;
  }

  function isDayOff(uint256 _timestamp) internal pure returns (bool) {
    return _timestamp >= currentCycleDayoffTimestamp(_timestamp);
  }

  function dayOffSecondsBetween(uint256 _start, uint256 _end) internal pure returns (uint256) {
    // empty interval, no dayoff
    if (_start >= _end) return 0;

    uint256 _cycle0 = currentCycleStartTimestamp(_start);
    uint256 _dayOff0 = _cycle0 + SECONDS_IN_DAY * 6;
    uint256 _cycle1 = currentCycleStartTimestamp(_end);
    uint256 _seconds;
    unchecked {
      if (_cycle0 == _cycle1) {
        if (_start <= _dayOff0) {
          if (_dayOff0 < _end) _seconds = _end - _dayOff0;
        } else {
          _seconds = _end - _start;
        }
      } else {
        if (_start <= _dayOff0) _seconds = SECONDS_IN_DAY;
        else _seconds = _dayOff0 + SECONDS_IN_DAY - _start;
        _seconds += ((_cycle1 - _cycle0) / SECONDS_IN_WEEK) * SECONDS_IN_DAY - SECONDS_IN_DAY;
        uint256 _dayOff1 = _cycle1 + SECONDS_IN_DAY * 6;
        if (_dayOff1 < _end) _seconds += _end - _dayOff1;
      }
    }
    return _seconds;
  }

  function rewardSecondsBetween(uint256 _start, uint256 _end) internal pure returns (uint256) {
    if (_start >= _end) return 0;
    return _end - _start - dayOffSecondsBetween(_start, _end);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./TimelineUtils.sol";

library RewardRateList {
  struct RewardRate {
    // The start timestamp of current reward period
    uint32 timestamp;
    // The reward rate per second of current reward period.
    uint112 rate;
    // The accumulated rewards of since very first period.
    uint112 accumulated;
  }

  struct PeriodList {
    RewardRate[] periods;
  }

  function add(
    PeriodList storage _list,
    uint32 _timestamp,
    uint112 _rate
  ) internal {
    uint256 _length = _list.periods.length;
    if (_length > 0) {
      RewardRate memory _last;
      unchecked {
        _last = _list.periods[_length - 1];
      }
      // solhint-disable-next-line reason-string
      require(_timestamp > _last.timestamp, "RewardRateList: timestamp not increasing");
      // solhint-disable-next-line reason-string
      require(_rate != _last.rate, "RewardRateList: rate not changing");
      uint32 _rewardSeconds = uint32(TimelineUtils.rewardSecondsBetween(_last.timestamp, _timestamp));
      unchecked {
        _list.periods.push(RewardRate(_timestamp, _rate, _last.accumulated + _last.rate * _rewardSeconds));
      }
    } else {
      _list.periods.push(RewardRate(_timestamp, _rate, 0));
    }
  }

  function rewards(
    PeriodList storage _list,
    uint256 _start,
    uint256 _end
  ) internal view returns (uint256) {
    if (_start >= _end) return 0;

    uint256 _length = _list.periods.length;
    uint256 _indexStart = _searchIndex(_list.periods, _length, _start);
    uint256 _indexEnd = _searchIndex(_list.periods, _length, _end);

    if (_indexStart == _indexEnd) {
      uint256 _rewardSeconds = TimelineUtils.rewardSecondsBetween(_start, _end);
      RewardRate memory _rate = _list.periods[_indexStart];
      unchecked {
        return _rewardSeconds * _rate.rate;
      }
    } else {
      RewardRate memory _startRate = _list.periods[_indexStart];
      RewardRate memory _midRate;
      RewardRate memory _endRate = _list.periods[_indexEnd];
      unchecked {
        if (_indexStart + 1 == _indexEnd) {
          _midRate = _endRate;
        } else {
          _midRate = _list.periods[_indexStart + 1];
        }
        uint256 _totalRewards = TimelineUtils.rewardSecondsBetween(_start, _midRate.timestamp) * _startRate.rate;
        _totalRewards += TimelineUtils.rewardSecondsBetween(_endRate.timestamp, _end) * _endRate.rate;
        if (_indexStart + 1 < _indexEnd) {
          _totalRewards += _endRate.accumulated - _midRate.accumulated;
        }
        return _totalRewards;
      }
    }
  }

  function _searchIndex(
    RewardRate[] storage _periods,
    uint256 _length,
    uint256 _timestamp
  ) private view returns (uint256) {
    if (_length == 1) return 0;

    // using binary search, find first index with RewardRate.timestamp <= _timestamp
    unchecked {
      uint256 _left = 0;
      uint256 _right = _length - 1;
      while (_left < _right) {
        uint256 _mid = (_left + _right + 1) >> 1;
        if (_periods[_mid].timestamp <= _timestamp) {
          _left = _mid;
        } else {
          _right = _mid - 1;
        }
      }
      return _length - 1;
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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