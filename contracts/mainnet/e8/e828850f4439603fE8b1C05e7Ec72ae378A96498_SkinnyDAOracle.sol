// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import "../vendor/uma/SkinnyOptimisticOracleInterface.sol";

import "./DAOracleHelpers.sol";
import "./vault/IVestingVault.sol";
import "./pool/StakingPool.sol";
import "./pool/SponsorPool.sol";

/**
 * @title SkinnyDAOracle
 * @dev This contract is the core of the Volatility Protocol DAOracle System.
 * It is responsible for rewarding stakers and issuing staker-backed bonds
 * which act as a decentralized risk pool for DAOracle Indexes. Bonds and rewards
 * are authorized, issued and funded by the Volatility DAO for qualified oracle
 * proposals, and stakers provide insurance against lost bonds. In exchange for
 * backstopping risk, stakers receive rewards for the data assurances they help
 * provide. In cases where a proposal is disputed, the DAOracle leverages UMA's
 * Data Validation Mechanism (DVM) to arbitrate and resolve by determining the
 * correct value through a community-led governance vote.
 */
contract SkinnyDAOracle is AccessControl, EIP712 {
  using SafeERC20 for IERC20;
  using DAOracleHelpers for Index;

  event Relayed(
    bytes32 indexed indexId,
    bytes32 indexed proposalId,
    Proposal proposal,
    address relayer,
    uint256 bondAmount
  );

  event Disputed(
    bytes32 indexed indexId,
    bytes32 indexed proposalId,
    address disputer
  );

  event Settled(
    bytes32 indexed indexId,
    bytes32 indexed proposalId,
    int256 proposedValue,
    int256 settledValue
  );

  event IndexConfigured(bytes32 indexed indexId, IERC20 bondToken);
  event Rewarded(address rewardee, IERC20 token, uint256 amount);

  /**
   * @dev Indexes are backed by bonds which are insured by stakers who receive
   * rewards for backstopping the risk of those bonds being slashed. The reward
   * token is the same as the bond token for simplicity. Whenever a bond is
   * resolved, any delta between the initial bond amount and tokens received is
   * "slashed" from the staking pool. A portion of rewards are distributed to
   * two groups: Stakers and Reporters. Every time targetFrequency elapses, the
   * weight shifts from Stakers to Reporters until it reaches the stakerFloor.
   */
  struct Index {
    IERC20 bondToken; // The token to be used for bonds
    uint32 lastUpdated; // The timestamp of the last successful update
    uint256 bondAmount; // The quantity of tokens to be put up for each bond
    uint256 bondsOutstanding; // The total amount of tokens outstanding for bonds
    uint256 disputesOutstanding; // The total number of requests currently in dispute
    uint256 drop; // The reward token drip rate (in wei)
    uint64 floor; // The minimum reward weighting for reporters (in wei, 1e18 = 100%)
    uint64 ceiling; // The maximum reward weighting for reporters (in wei, 1e18 = 100%)
    uint64 tilt; // The rate of change per second from floor->ceiling (in wei, 1e18 = 100%)
    uint64 creatorAmount; // The percentage of the total reward payable to the methodologist
    uint32 disputePeriod; // The dispute window for proposed values
    address creatorAddress; // The recipient of the methodologist rewards
    address sponsor; // The source of funding for the index's bonds and rewards
  }

  /**
   * @dev Proposals are used to validate index updates to be relayed to the UMA
   * OptimisticOracle. The ancillaryData field supports arbitrary byte arrays,
   * but we are compressing down to bytes32 which exceeds the capacity needed
   * for all currently known use cases.
   */
  struct Proposal {
    bytes32 indexId; // The index identifier
    uint32 timestamp; // The timestamp of the value
    int256 value; // The proposed value
    bytes32 data; // Any other data needed to reproduce the proposed value
  }

  // UMA's SkinnyOptimisticOracle and registered identifier
  SkinnyOptimisticOracleInterface public immutable oracle;
  bytes32 public externalIdentifier;

  // Vesting Vault (for Rewards)
  IVestingVault public immutable vault;

  // Indexes and Proposals
  mapping(bytes32 => Index) public index;
  mapping(bytes32 => Proposal) public proposal;
  mapping(bytes32 => bool) public isDisputed;
  uint32 public defaultDisputePeriod = 10 minutes;
  uint32 public maxOutstandingDisputes = 3;

  // Staking Pools (bond insurance)
  mapping(IERC20 => StakingPool) public pool;

  // Roles (for AccessControl)
  bytes32 public constant ORACLE = keccak256("ORACLE");
  bytes32 public constant MANAGER = keccak256("MANAGER");
  bytes32 public constant PROPOSER = keccak256("PROPOSER");

  // Proposal type hash (for EIP-712 signature verification)
  bytes32 public constant PROPOSAL_TYPEHASH =
    keccak256(
      abi.encodePacked(
        "Proposal(bytes32 indexId,uint32 timestamp,int256 value,bytes32 data)"
      )
    );

  /**
   * @dev Ensures that a given EIP-712 signature matches the hashed proposal
   * and was issued by an authorized signer. Accepts signatures from both EOAs
   * and contracts that support the EIP-712 standard.
   * @param relayed a proposal that was provided by the caller
   * @param signature an EIP-712 signature (raw bytes)
   * @param signer the address that provided the signature
   */
  modifier onlySignedProposals(
    Proposal calldata relayed,
    bytes calldata signature,
    address signer
  ) {
    require(
      SignatureChecker.isValidSignatureNow(
        signer,
        _hashTypedDataV4(
          keccak256(
            abi.encode(
              PROPOSAL_TYPEHASH,
              relayed.indexId,
              relayed.timestamp,
              relayed.value,
              relayed.data
            )
          )
        ),
        signature
      ),
      "bad signature"
    );

    require(hasRole(PROPOSER, signer), "unauthorized signer");

    _;
  }

  constructor(
    bytes32 _ooIdentifier,
    SkinnyOptimisticOracleInterface _optimisticOracle,
    IVestingVault _vault
  ) EIP712("DAOracle", "1") {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(PROPOSER, msg.sender);
    _setupRole(MANAGER, msg.sender);
    _setupRole(ORACLE, address(_optimisticOracle));

    externalIdentifier = _ooIdentifier;
    oracle = _optimisticOracle;
    vault = _vault;
  }

  /**
   * @dev Returns the currently claimable rewards for a given index.
   * @param indexId The index identifier
   * @return total The total reward token amount
   * @return poolAmount The pool's share of the rewards
   * @return reporterAmount The reporter's share of the rewards
   * @return residualAmount The methodologist's share of the rewards
   * @return vestingTime The amount of time the reporter's rewards must vest (in seconds)
   */
  function claimableRewards(bytes32 indexId)
    public
    view
    returns (
      uint256 total,
      uint256 poolAmount,
      uint256 reporterAmount,
      uint256 residualAmount,
      uint256 vestingTime
    )
  {
    return index[indexId].claimableRewards();
  }

  /**
   * @dev Relay an index update that has been signed by an authorized proposer.
   * The signature provided must satisfy two criteria:
   * (1) the signature must be a valid EIP-712 signature for the proposal; and
   * (2) the signer must have the "PROPOSER" role.
   * @notice See https://docs.ethers.io/v5/api/signer/#Signer-signTypedData
   * @param relayed The relayed proposal
   * @param signature An EIP-712 signature for the proposal
   * @param signer The address of the EIP-712 signature provider
   * @return bond The bond amount claimable via successful dispute
   * @return proposalId The unique ID of the proposal
   * @return expiresAt The time at which the proposal is no longer disputable
   */
  function relay(
    Proposal calldata relayed,
    bytes calldata signature,
    address signer
  )
    external
    onlySignedProposals(relayed, signature, signer)
    returns (
      uint256 bond,
      bytes32 proposalId,
      uint32 expiresAt
    )
  {
    proposalId = _proposalId(relayed.timestamp, relayed.value, relayed.data);
    require(proposal[proposalId].timestamp == 0, "duplicate proposal");

    Index storage _index = index[relayed.indexId];
    require(_index.disputesOutstanding < 3, "index ineligible for proposals");
    require(
      _index.lastUpdated < relayed.timestamp,
      "must be later than most recent proposal"
    );

    bond = _index.bondAmount;
    expiresAt = uint32(block.timestamp) + _index.disputePeriod;

    proposal[proposalId] = relayed;
    _index.lastUpdated = relayed.timestamp;

    _issueRewards(relayed.indexId, msg.sender);
    emit Relayed(relayed.indexId, proposalId, relayed, msg.sender, bond);
  }

  /**
   * @dev Disputes a proposal prior to its expiration. This causes a bond to be
   * posted on behalf of DAOracle stakers and an equal amount to be pulled from
   * the caller.
   * @notice This actually requests, proposes, and disputes with UMA's SkinnyOO
   * which sends the bonds and disputed proposal to UMA's DVM for settlement by
   * way of governance vote. Voters follow the specification of the DAOracle's
   * approved UMIP to determine the correct value. Once the outcome is decided,
   * the SkinnyOO will callback to this contract's `priceSettled` function.
   * @param proposalId the identifier of the proposal being disputed
   */
  function dispute(bytes32 proposalId) external {
    Proposal storage _proposal = proposal[proposalId];
    Index storage _index = index[_proposal.indexId];

    require(proposal[proposalId].timestamp != 0, "proposal doesn't exist");
    require(
      !isDisputed[proposalId] &&
        block.timestamp < proposal[proposalId].timestamp + _index.disputePeriod,
      "proposal already disputed or expired"
    );
    isDisputed[proposalId] = true;

    _index.dispute(_proposal, oracle, externalIdentifier);
    emit Disputed(_proposal.indexId, proposalId, msg.sender);
  }

  /**
   * @dev External callback for UMA's SkinnyOptimisticOracle. Fired whenever a
   * disputed proposal has been settled by the DVM, regardless of outcome.
   * @notice This is always called by the UMA SkinnyOO contract, not an EOA.
   * @param - identifier, ignored
   * @param timestamp The timestamp of the proposal
   * @param ancillaryData The data field from the proposal
   * @param request The entire SkinnyOptimisticOracle Request object
   */
  function priceSettled(
    bytes32, /** identifier */
    uint32 timestamp,
    bytes calldata ancillaryData,
    SkinnyOptimisticOracleInterface.Request calldata request
  ) external onlyRole(ORACLE) {
    bytes32 id = _proposalId(
      timestamp,
      request.proposedPrice,
      bytes32(ancillaryData)
    );
    Proposal storage relayed = proposal[id];
    Index storage _index = index[relayed.indexId];

    _index.bondsOutstanding -= request.bond;
    _index.disputesOutstanding--;
    isDisputed[id] = false;

    if (relayed.value != request.resolvedPrice) {
      // failed proposal, slash pool to recoup lost bond
      pool[request.currency].slash(_index.bondAmount, address(this));
    } else {
      // successful proposal, return bond to sponsor
      request.currency.safeTransfer(_index.sponsor, request.bond);

      // sends the rest of the funds received to the staking pool
      request.currency.safeTransfer(
        address(pool[request.currency]),
        request.currency.balanceOf(address(this))
      );
    }

    emit Settled(relayed.indexId, id, relayed.value, request.resolvedPrice);
  }

  /**
   * @dev Adds or updates a index. Can only be called by managers.
   * @param bondToken The token to be used for bonds
   * @param bondAmount The quantity of tokens to offer for bonds
   * @param indexId The price index identifier
   * @param disputePeriod The proposal dispute window
   * @param floor The starting portion of rewards payable to reporters
   * @param ceiling The maximum portion of rewards payable to reporters
   * @param tilt The rate of change from floor to ceiling per second
   * @param drop The number of reward tokens to drip (per second)
   * @param creatorAmount The portion of rewards payable to the methodologist
   * @param creatorAddress The recipient of the methodologist's rewards
   * @param sponsor The provider of funding for bonds and rewards
   */
  function configureIndex(
    IERC20 bondToken,
    uint256 bondAmount,
    bytes32 indexId,
    uint32 disputePeriod,
    uint64 floor,
    uint64 ceiling,
    uint64 tilt,
    uint256 drop,
    uint64 creatorAmount,
    address creatorAddress,
    address sponsor
  ) external onlyRole(MANAGER) {
    Index storage _index = index[indexId];

    _index.bondToken = bondToken;
    _index.bondAmount = bondAmount;
    _index.lastUpdated = _index.lastUpdated == 0
      ? uint32(block.timestamp)
      : _index.lastUpdated;

    _index.drop = drop;
    _index.ceiling = ceiling;
    _index.tilt = tilt;
    _index.floor = floor;
    _index.creatorAmount = creatorAmount;
    _index.creatorAddress = creatorAddress;
    _index.disputePeriod = disputePeriod == 0
      ? defaultDisputePeriod
      : disputePeriod;
    _index.sponsor = sponsor == address(0)
      ? address(_index.deploySponsorPool())
      : sponsor;

    if (address(pool[bondToken]) == address(0)) {
      _createPool(_index);
    }

    emit IndexConfigured(indexId, bondToken);
  }

  /**
   * @dev Update the global default disputePeriod. Can only be called by managers.
   * @param disputePeriod The new disputePeriod, in seconds
   */
  function setdefaultDisputePeriod(uint32 disputePeriod)
    external
    onlyRole(MANAGER)
  {
    defaultDisputePeriod = disputePeriod;
  }

  function setExternalIdentifier(bytes32 identifier)
    external
    onlyRole(MANAGER)
  {
    externalIdentifier = identifier;
  }

  /**
   * @dev Update the global default maxOutstandingDisputes. Can only be called by managers.
   * @param outstandingDisputes The new maxOutstandingDisputes
   */
  function setMaxOutstandingDisputes(uint32 outstandingDisputes)
    external
    onlyRole(MANAGER)
  {
    maxOutstandingDisputes = outstandingDisputes;
  }

  /**
   * @dev Update the fees for a token's staking pool. Can only be called by managers.
   * @notice Fees must be scaled by 10**18 (1e18 = 100%). Example: 1000 DAI deposit * (0.1 * 10**18) = 100 DAI fee
   * @param mintFee the tax applied to new deposits
   * @param burnFee the tax applied to withdrawals
   * @param payee the recipient of fees
   */
  function setPoolFees(
    IERC20 token,
    uint256 mintFee,
    uint256 burnFee,
    address payee
  ) external onlyRole(MANAGER) {
    pool[token].setFees(mintFee, burnFee, payee);
  }

  function _proposalId(
    uint32 timestamp,
    int256 value,
    bytes32 data
  ) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(timestamp, value, data));
  }

  function _createPool(Index storage _index) internal returns (StakingPool) {
    pool[_index.bondToken] = new StakingPool(
      ERC20(address(_index.bondToken)),
      0,
      0,
      address(this)
    );

    _index.bondToken.safeApprove(address(vault), 2**256 - 1);
    _index.bondToken.safeApprove(address(oracle), 2**256 - 1);

    return pool[_index.bondToken];
  }

  function _issueRewards(bytes32 indexId, address reporter) internal {
    Index storage _index = index[indexId];

    (
      uint256 total,
      uint256 poolAmount,
      uint256 reporterAmount,
      uint256 residualAmount,
      uint256 vestingTime
    ) = _index.claimableRewards();

    // Pull in reward money from the sponsor
    _index.bondToken.safeTransferFrom(_index.sponsor, address(this), total);

    // Push rewards to pool and methodologist
    _index.bondToken.safeTransfer(address(pool[_index.bondToken]), poolAmount);
    _index.bondToken.safeTransfer(_index.creatorAddress, residualAmount);

    // Push relayer's reward to the vault for vesting
    vault.issue(
      reporter,
      _index.bondToken,
      reporterAmount,
      block.timestamp,
      0,
      vestingTime
    );

    emit Rewarded(reporter, _index.bondToken, reporterAmount);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Financial contract facing Oracle interface.
 * @dev Interface used by financial contracts to interact with the Oracle. Voters will use a different interface.
 */
abstract contract OptimisticOracleInterface {
  // Struct representing the state of a price request.
  enum State {
    Invalid, // Never requested.
    Requested, // Requested, no other actions taken.
    Proposed, // Proposed, but not expired or disputed yet.
    Expired, // Proposed, not disputed, past liveness.
    Disputed, // Disputed, but no DVM price returned yet.
    Resolved, // Disputed and DVM price is available.
    Settled // Final price has been set in the contract (can get here from Expired or Resolved).
  }

  // Struct representing a price request.
  struct Request {
    address proposer; // Address of the proposer.
    address disputer; // Address of the disputer.
    IERC20 currency; // ERC20 token used to pay rewards and fees.
    bool settled; // True if the request is settled.
    bool refundOnDispute; // True if the requester should be refunded their reward on dispute.
    int256 proposedPrice; // Price that the proposer submitted.
    int256 resolvedPrice; // Price resolved once the request is settled.
    uint256 expirationTime; // Time at which the request auto-settles without a dispute.
    uint256 reward; // Amount of the currency to pay to the proposer on settlement.
    uint256 finalFee; // Final fee to pay to the Store upon request to the DVM.
    uint256 bond; // Bond that the proposer and disputer must pay on top of the final fee.
    uint256 customLiveness; // Custom liveness value set by the requester.
  }

  // This value must be <= the Voting contract's `ancillaryBytesLimit` value otherwise it is possible
  // that a price can be requested to this contract successfully, but cannot be disputed because the DVM refuses
  // to accept a price request made with ancillary data length over a certain size.
  uint256 public constant ancillaryBytesLimit = 8192;

  /**
   * @notice Requests a new price.
   * @param identifier price identifier being requested.
   * @param timestamp timestamp of the price being requested.
   * @param ancillaryData ancillary data representing additional args being passed with the price request.
   * @param currency ERC20 token used for payment of rewards and fees. Must be approved for use with the DVM.
   * @param reward reward offered to a successful proposer. Will be pulled from the caller. Note: this can be 0,
   *               which could make sense if the contract requests and proposes the value in the same call or
   *               provides its own reward system.
   * @return totalBond default bond (final fee) + final fee that the proposer and disputer will be required to pay.
   * This can be changed with a subsequent call to setBond().
   */
  function requestPrice(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    IERC20 currency,
    uint256 reward
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Set the proposal bond associated with a price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param bond custom bond amount to set.
   * @return totalBond new bond + final fee that the proposer and disputer will be required to pay. This can be
   * changed again with a subsequent call to setBond().
   */
  function setBond(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    uint256 bond
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Sets the request to refund the reward if the proposal is disputed. This can help to "hedge" the caller
   * in the event of a dispute-caused delay. Note: in the event of a dispute, the winner still receives the other's
   * bond, so there is still profit to be made even if the reward is refunded.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   */
  function setRefundOnDispute(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external virtual;

  /**
   * @notice Sets a custom liveness value for the request. Liveness is the amount of time a proposal must wait before
   * being auto-resolved.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param customLiveness new custom liveness.
   */
  function setCustomLiveness(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    uint256 customLiveness
  ) external virtual;

  /**
   * @notice Proposes a price value on another address' behalf. Note: this address will receive any rewards that come
   * from this proposal. However, any bonds are pulled from the caller.
   * @param proposer address to set as the proposer.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param proposedPrice price being proposed.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the proposer once settled if the proposal is correct.
   */
  function proposePriceFor(
    address proposer,
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    int256 proposedPrice
  ) public virtual returns (uint256 totalBond);

  /**
   * @notice Proposes a price value for an existing price request.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param proposedPrice price being proposed.
   * @return totalBond the amount that's pulled from the proposer's wallet as a bond. The bond will be returned to
   * the proposer once settled if the proposal is correct.
   */
  function proposePrice(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    int256 proposedPrice
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Disputes a price request with an active proposal on another address' behalf. Note: this address will
   * receive any rewards that come from this dispute. However, any bonds are pulled from the caller.
   * @param disputer address to set as the disputer.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the disputer once settled if the dispute was value (the proposal was incorrect).
   */
  function disputePriceFor(
    address disputer,
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public virtual returns (uint256 totalBond);

  /**
   * @notice Disputes a price value for an existing price request with an active proposal.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return totalBond the amount that's pulled from the disputer's wallet as a bond. The bond will be returned to
   * the disputer once settled if the dispute was valid (the proposal was incorrect).
   */
  function disputePrice(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Retrieves a price that was previously requested by a caller. Reverts if the request is not settled
   * or settleable. Note: this method is not view so that this call may actually settle the price request if it
   * hasn't been settled.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return resolved price.
   */
  function settleAndGetPrice(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external virtual returns (int256);

  /**
   * @notice Attempts to settle an outstanding price request. Will revert if it isn't settleable.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return payout the amount that the "winner" (proposer or disputer) receives on settlement. This amount includes
   * the returned bonds as well as additional rewards.
   */
  function settle(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external virtual returns (uint256 payout);

  /**
   * @notice Gets the current data structure containing all information about a price request.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return the Request data structure.
   */
  function getRequest(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public view virtual returns (Request memory);

  /**
   * @notice Returns the state of a price request.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return the State enum value.
   */
  function getState(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public view virtual returns (State);

  /**
   * @notice Checks if a given request has resolved or been settled (i.e the optimistic oracle has a price).
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return true if price has resolved or settled, false otherwise.
   */
  function hasPrice(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public view virtual returns (bool);

  function stampAncillaryData(bytes memory ancillaryData, address requester)
    public
    view
    virtual
    returns (bytes memory);
}

/**
 * @title Interface for the gas-cost-reduced version of the OptimisticOracle.
 * @notice Differences from normal OptimisticOracle:
 * - refundOnDispute: flag is removed, by default there are no refunds on disputes.
 * - customizing request parameters: In the OptimisticOracle, parameters like `bond` and `customLiveness` can be reset
 *   after a request is already made via `requestPrice`. In the SkinnyOptimisticOracle, these parameters can only be
 *   set in `requestPrice`, which has an expanded input set.
 * - settleAndGetPrice: Replaced by `settle`, which can only be called once per settleable request. The resolved price
 *   can be fetched via the `Settle` event or the return value of `settle`.
 * - general changes to interface: Functions that interact with existing requests all require the parameters of the
 *   request to modify to be passed as input. These parameters must match with the existing request parameters or the
 *   function will revert. This change reflects the internal refactor to store hashed request parameters instead of the
 *   full request struct.
 * @dev Interface used by financial contracts to interact with the Oracle. Voters will use a different interface.
 */
abstract contract SkinnyOptimisticOracleInterface {
  event RequestPrice(
    address indexed requester,
    bytes32 indexed identifier,
    uint32 timestamp,
    bytes ancillaryData,
    Request request
  );

  event ProposePrice(
    address indexed requester,
    bytes32 indexed identifier,
    uint32 timestamp,
    bytes ancillaryData,
    Request request
  );

  event DisputePrice(
    address indexed requester,
    bytes32 indexed identifier,
    uint32 timestamp,
    bytes ancillaryData,
    Request request
  );

  event Settle(
    address indexed requester,
    bytes32 indexed identifier,
    uint32 timestamp,
    bytes ancillaryData,
    Request request
  );

  // Struct representing a price request. Note that this differs from the OptimisticOracleInterface's Request struct
  // in that refundOnDispute is removed.
  struct Request {
    address proposer; // Address of the proposer.
    address disputer; // Address of the disputer.
    IERC20 currency; // ERC20 token used to pay rewards and fees.
    bool settled; // True if the request is settled.
    int256 proposedPrice; // Price that the proposer submitted.
    int256 resolvedPrice; // Price resolved once the request is settled.
    uint256 expirationTime; // Time at which the request auto-settles without a dispute.
    uint256 reward; // Amount of the currency to pay to the proposer on settlement.
    uint256 finalFee; // Final fee to pay to the Store upon request to the DVM.
    uint256 bond; // Bond that the proposer and disputer must pay on top of the final fee.
    uint256 customLiveness; // Custom liveness value set by the requester.
  }

  /**
   * @notice Requests a new price.
   * @param identifier price identifier being requested.
   * @param timestamp timestamp of the price being requested.
   * @param ancillaryData ancillary data representing additional args being passed with the price request.
   * @param currency ERC20 token used for payment of rewards and fees. Must be approved for use with the DVM.
   * @param reward reward offered to a successful proposer. Will be pulled from the caller. Note: this can be 0,
   *               which could make sense if the contract requests and proposes the value in the same call or
   *               provides its own reward system.
   * @param bond custom proposal bond to set for request. If set to 0, defaults to the final fee.
   * @param customLiveness custom proposal liveness to set for request.
   * @return totalBond default bond + final fee that the proposer and disputer will be required to pay.
   */
  function requestPrice(
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    IERC20 currency,
    uint256 reward,
    uint256 bond,
    uint256 customLiveness
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Proposes a price value on another address' behalf. Note: this address will receive any rewards that come
   * from this proposal. However, any bonds are pulled from the caller.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters whose hash must match the request that the caller wants to
   * propose a price for.
   * @param proposer address to set as the proposer.
   * @param proposedPrice price being proposed.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the proposer once settled if the proposal is correct.
   */
  function proposePriceFor(
    address requester,
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request,
    address proposer,
    int256 proposedPrice
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Proposes a price value where caller is the proposer.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters whose hash must match the request that the caller wants to
   * propose a price for.
   * @param proposedPrice price being proposed.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the proposer once settled if the proposal is correct.
   */
  function proposePrice(
    address requester,
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request,
    int256 proposedPrice
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Combines logic of requestPrice and proposePrice while taking advantage of gas savings from not having to
   * overwrite Request params that a normal requestPrice() => proposePrice() flow would entail. Note: The proposer
   * will receive any rewards that come from this proposal. However, any bonds are pulled from the caller.
   * @dev The caller is the requester, but the proposer can be customized.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param currency ERC20 token used for payment of rewards and fees. Must be approved for use with the DVM.
   * @param reward reward offered to a successful proposer. Will be pulled from the caller. Note: this can be 0,
   *               which could make sense if the contract requests and proposes the value in the same call or
   *               provides its own reward system.
   * @param bond custom proposal bond to set for request. If set to 0, defaults to the final fee.
   * @param customLiveness custom proposal liveness to set for request.
   * @param proposer address to set as the proposer.
   * @param proposedPrice price being proposed.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the proposer once settled if the proposal is correct.
   */
  function requestAndProposePriceFor(
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    IERC20 currency,
    uint256 reward,
    uint256 bond,
    uint256 customLiveness,
    address proposer,
    int256 proposedPrice
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Disputes a price request with an active proposal on another address' behalf. Note: this address will
   * receive any rewards that come from this dispute. However, any bonds are pulled from the caller.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters whose hash must match the request that the caller wants to
   * dispute.
   * @param disputer address to set as the disputer.
   * @param requester sender of the initial price request.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the disputer once settled if the dispute was valid (the proposal was incorrect).
   */
  function disputePriceFor(
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request,
    address disputer,
    address requester
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Disputes a price request with an active proposal where caller is the disputer.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters whose hash must match the request that the caller wants to
   * dispute.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the disputer once settled if the dispute was valid (the proposal was incorrect).
   */
  function disputePrice(
    address requester,
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Attempts to settle an outstanding price request. Will revert if it isn't settleable.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters whose hash must match the request that the caller wants to
   * settle.
   * @return payout the amount that the "winner" (proposer or disputer) receives on settlement. This amount includes
   * the returned bonds as well as additional rewards.
   * @return resolvedPrice the price that the request settled to.
   */
  function settle(
    address requester,
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request
  ) external virtual returns (uint256 payout, int256 resolvedPrice);

  /**
   * @notice Computes the current state of a price request. See the State enum for more details.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters.
   * @return the State.
   */
  function getState(
    address requester,
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request
  ) external virtual returns (OptimisticOracleInterface.State);

  /**
   * @notice Checks if a given request has resolved, expired or been settled (i.e the optimistic oracle has a price).
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters. The hash of these parameters must match with the request hash that is
   * associated with the price request unique ID {requester, identifier, timestamp, ancillaryData}, or this method
   * will revert.
   * @return boolean indicating true if price exists and false if not.
   */
  function hasPrice(
    address requester,
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request
  ) external virtual returns (bool);

  /**
   * @notice Generates stamped ancillary data in the format that it would be used in the case of a price dispute.
   * @param ancillaryData ancillary data of the price being requested.
   * @param requester sender of the initial price request.
   * @return the stamped ancillary bytes.
   */
  function stampAncillaryData(bytes memory ancillaryData, address requester)
    external
    pure
    virtual
    returns (bytes memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./SkinnyDAOracle.sol";
import "./pool/SponsorPool.sol";

library DAOracleHelpers {
  using SafeERC20 for IERC20;

  function claimableRewards(SkinnyDAOracle.Index storage index)
    public
    view
    returns (
      uint256 total,
      uint256 poolAmount,
      uint256 reporterAmount,
      uint256 residualAmount,
      uint256 vestingTime
    )
  {
    // multiplier = distance between last proposal and current time (in seconds)
    uint256 multiplier = block.timestamp - index.lastUpdated;

    // minimum multiplier = 1
    if (multiplier == 0) multiplier = 1;

    // reporter's share starts at floor and moves toward ceiling by tilt % per tick
    uint256 reporterShare = index.floor + (index.tilt * multiplier);
    if (reporterShare > index.ceiling) reporterShare = index.ceiling;

    total = index.drop * multiplier;
    reporterAmount = (total * reporterShare) / 1e18;
    residualAmount = ((total - reporterAmount) * index.creatorAmount) / 1e18;
    poolAmount = total - residualAmount - reporterAmount;
    vestingTime = 0;
  }

  function dispute(
    SkinnyDAOracle.Index storage index,
    SkinnyDAOracle.Proposal storage proposal,
    SkinnyOptimisticOracleInterface oracle,
    bytes32 externalIdentifier
  ) public {
    IERC20 token = index.bondToken;

    // Pull in funds from sponsor to cover the proposal bond
    token.safeTransferFrom(index.sponsor, address(this), index.bondAmount);

    // Pull in funds from disputer to match the bond
    token.safeTransferFrom(msg.sender, address(this), index.bondAmount);

    // Create the request + proposal via UMA's OO
    uint256 bond = oracle.requestAndProposePriceFor(
      externalIdentifier,
      proposal.timestamp,
      abi.encodePacked(proposal.data),
      token,
      0,
      index.bondAmount,
      index.disputePeriod,
      address(this),
      proposal.value
    );

    // Build the OO request object for the above proposal
    SkinnyOptimisticOracleInterface.Request memory request;
    request.currency = token;
    request.finalFee = bond - index.bondAmount;
    request.bond = bond - request.finalFee;
    request.proposer = address(this);
    request.proposedPrice = proposal.value;
    request.expirationTime = block.timestamp + index.disputePeriod;
    request.customLiveness = index.disputePeriod;

    // Initiate the dispute on disputer's behalf
    oracle.disputePriceFor(
      externalIdentifier,
      proposal.timestamp,
      abi.encodePacked(proposal.data),
      request,
      msg.sender,
      address(this)
    );

    // Keep track of the outstanding bond and dispute
    index.bondsOutstanding += bond;
    index.disputesOutstanding++;
  }

  function deploySponsorPool(SkinnyDAOracle.Index storage index)
    public
    returns (SponsorPool)
  {
    return new SponsorPool(ERC20(address(index.bondToken)));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title VestingVault
 * @dev A token vesting contract that will release tokens gradually like a
 * standard equity vesting schedule, with a cliff and vesting period but no
 * arbitrary restrictions on the frequency of claims. Optionally has an initial
 * tranche claimable immediately after the cliff expires (in addition to any
 * amounts that would have vested up to that point but didn't due to a cliff).
 */
interface IVestingVault {
  event Issued(
    address indexed beneficiary,
    IERC20 token,
    uint256 amount,
    uint256 start,
    uint256 cliff,
    uint256 duration
  );

  event Released(
    address indexed beneficiary,
    uint256 indexed allocationId,
    IERC20 token,
    uint256 amount,
    uint256 remaining
  );

  event Revoked(
    address indexed beneficiary,
    uint256 indexed allocationId,
    IERC20 token,
    uint256 allocationAmount,
    uint256 revokedAmount
  );

  struct Allocation {
    IERC20 token;
    uint256 start;
    uint256 cliff;
    uint256 duration;
    uint256 total;
    uint256 claimed;
  }

  /**
   * @dev Creates a new allocation for a beneficiary. Tokens are released
   * linearly over time until a given number of seconds have passed since the
   * start of the vesting schedule. Callable only by issuers.
   * @param _beneficiary The address to which tokens will be released
   * @param _amount The amount of the allocation (in wei)
   * @param _startAt The unix timestamp at which the vesting may begin
   * @param _cliff The number of seconds after _startAt before which no vesting occurs
   * @param _duration The number of seconds after which the entire allocation is vested
   */
  function issue(
    address _beneficiary,
    IERC20 _token,
    uint256 _amount,
    uint256 _startAt,
    uint256 _cliff,
    uint256 _duration
  ) external;

  /**
   * @dev Revokes an existing allocation. Any unclaimed tokens are recalled
   * and sent to the caller. Callable only be issuers.
   * @param _beneficiary The address whose allocation is to be revoked
   * @param _id The allocation ID to revoke
   */
  function revoke(
    address _beneficiary,
    uint256 _id
  ) external;

  /**
   * @dev Transfers vested tokens from any number of allocations to their beneficiary. Callable by anyone. May be gas-intensive.
   * @param _beneficiary The address that has vested tokens
   * @param _ids The vested allocation indexes
   */
  function release(
    address _beneficiary, 
    uint256[] calldata _ids
  ) external;

  /**
   * @dev Gets the number of allocations issued for a given address.
   * @param _beneficiary The address to check for allocations
   */
  function allocationCount(
    address _beneficiary
  ) external view returns (
    uint256 count
  );

  /**
   * @dev Gets details about a given allocation.
   * @param _beneficiary Address to check
   * @param _id The allocation index
   * @return allocation The allocation
   * @return vested The total amount vested to date
   * @return releasable The amount currently releasable
   */
  function allocationSummary(
    address _beneficiary,
    uint256 _id
  ) external view returns (
    Allocation memory allocation,
    uint256 vested,
    uint256 releasable
  );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

import "./ManagedPool.sol";
import "./Slashable.sol";

/**
 * @title StakingPool
 * @dev The DAOracle Network relies on decentralized risk pools. This is a
 * simple implementation of a staking pool which wraps a single arbitrary token
 * and provides a mechanism for recouping losses incurred by the deployer of
 * the staking pool. Pool ownership is represented as ERC20 tokens that can be
 * freely used as the holder sees fit. Holders of pool shares may make claims
 * proportional to their stake on the underlying token balance of the pool. Any
 * rewards or penalties applied to the pool will thus impact all holders.
 */
contract StakingPool is ERC20, ERC20Permit, ManagedPool, Slashable {
  using SafeERC20 for IERC20;

  constructor(
    ERC20 _token,
    uint256 _mintFee,
    uint256 _burnFee,
    address _feePayee
  )
    ERC20(
      _concat("StakingPool: ", _token.name()),
      _concat("dp", _token.symbol())
    )
    ERC20Permit(_concat("StakingPool: ", _token.name()))
  {
    stakedToken = IERC20(_token);
    mintFee = _mintFee;
    burnFee = _burnFee;
    feePayee = _feePayee;

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MANAGER, msg.sender);
    _setupRole(SLASHER, msg.sender);

    stakedToken.safeApprove(msg.sender, 2**256 - 1);

    emit Created(address(this), stakedToken);
  }

  function underlying() public view override returns (IERC20) {
    return stakedToken;
  }

  function _concat(string memory a, string memory b)
    internal
    pure
    returns (string memory)
  {
    return string(bytes.concat(bytes(a), bytes(b)));
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

import "./ManagedPool.sol";

/**
 * @title SponsorPool
 */
contract SponsorPool is ERC20, ERC20Permit, ManagedPool {
  using SafeERC20 for IERC20;

  constructor(ERC20 _token)
    ERC20(
      _concat("SponsorPool: ", _token.name()),
      _concat("f", _token.symbol())
    )
    ERC20Permit(_concat("SponsorPool: ", _token.name()))
  {
    stakedToken = IERC20(_token);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MANAGER, msg.sender);

    stakedToken.safeApprove(msg.sender, 2**256 - 1);
    emit Created(address(this), stakedToken);
  }

  function _concat(string memory a, string memory b)
    internal
    pure
    returns (string memory)
  {
    return string(bytes.concat(bytes(a), bytes(b)));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title ManagedPool
 * @dev The DAOracle Network relies on decentralized risk pools. This is a
 * simple implementation of a staking pool which wraps a single arbitrary token
 * and provides a mechanism for recouping losses incurred by the deployer of
 * the underlying. Pool ownership is represented as ERC20 tokens that can be
 * freely used as the holder sees fit. Holders of pool shares may make claims
 * proportional to their stake on the underlying token balance of the pool. Any
 * rewards or penalties applied to the pool will thus impact all holders.
 */
abstract contract ManagedPool is AccessControl, ERC20 {
  using SafeERC20 for IERC20;

  bytes32 public immutable MANAGER = keccak256("MANAGER");

  /// @dev The token being staked in this pool
  IERC20 public stakedToken;

  /**
   * @dev The mint/burn fee config. Fees must be scaled by 10**18 (1e18 = 100%)
   * Formula: fee = tokens * mintOrBurnFee / 1e18
   * Example: 1000 DAI deposit * (0.1 * 10**18) / 10**18 = 100 DAI fee
   */
  uint256 public mintFee;
  uint256 public burnFee;
  address public feePayee;

  event Created(address pool, IERC20 underlying);
  event FeesChanged(uint256 mintFee, uint256 burnFee, address payee);
  event Fee(uint256 feeAmount);

  event Deposit(
    address indexed depositor,
    uint256 underlyingAmount,
    uint256 tokensMinted
  );

  event Payout(
    address indexed beneficiary,
    uint256 underlyingAmount,
    uint256 tokensBurned
  );

  /**
   * @dev Mint pool shares for a given stake amount
   * @param _stakeAmount The amount of underlying to stake
   * @return shares The number of pool shares minted
   */
  function mint(uint256 _stakeAmount) external returns (uint256 shares) {
    require(
      stakedToken.allowance(msg.sender, address(this)) >= _stakeAmount,
      "mint: insufficient allowance"
    );

    // Grab the pre-deposit balance and shares for comparison
    uint256 oldBalance = stakedToken.balanceOf(address(this));
    uint256 oldShares = totalSupply();

    // Pull user's tokens into the pool
    stakedToken.safeTransferFrom(msg.sender, address(this), _stakeAmount);

    // Calculate the fee for minting
    uint256 fee = (_stakeAmount * mintFee) / 1e18;
    if (fee != 0) {
      stakedToken.safeTransfer(feePayee, fee);
      _stakeAmount -= fee;
      emit Fee(fee);
    }

    // Calculate the pool shares for the new deposit
    if (oldShares != 0) {
      // shares = stake * oldShares / oldBalance
      shares = (_stakeAmount * oldShares) / oldBalance;
    } else {
      // if no shares exist, just assign 1,000 shares (it's arbitrary)
      shares = 10**3;
    }

    // Transfer shares to caller
    _mint(msg.sender, shares);
    emit Deposit(msg.sender, _stakeAmount, shares);
  }

  /**
   * @dev Burn some pool shares and claim the underlying tokens
   * @param _shareAmount The number of shares to burn
   * @return tokens The number of underlying tokens returned
   */
  function burn(uint256 _shareAmount) external returns (uint256 tokens) {
    require(balanceOf(msg.sender) >= _shareAmount, "burn: insufficient shares");

    // TODO: Extract
    // Calculate the user's share of the underlying balance
    uint256 balance = stakedToken.balanceOf(address(this));
    tokens = (_shareAmount * balance) / totalSupply();

    // Burn the caller's shares before anything else
    _burn(msg.sender, _shareAmount);

    // Calculate the fee for burning
    uint256 fee = getBurnFee(tokens);
    if (fee != 0) {
      tokens -= fee;
      stakedToken.safeTransfer(feePayee, fee);
      emit Fee(fee);
    }

    // Transfer underlying tokens back to caller
    stakedToken.safeTransfer(msg.sender, tokens);
    emit Payout(msg.sender, tokens, _shareAmount);
  }

  /**
   * @dev Calculate the minting fee
   * @param _amount The number of tokens being staked
   * @return fee The calculated fee value
   */
  function getMintFee(uint256 _amount) public view returns (uint256 fee) {
    fee = (_amount * mintFee) / 1e18;
  }

  /**
   * @dev Calculate the burning fee
   * @param _amount The number of pool tokens being burned
   * @return fee The calculated fee value
   */
  function getBurnFee(uint256 _amount) public view returns (uint256 fee) {
    fee = (_amount * burnFee) / 1e18;
  }

  /**
   * @dev Update fee configuration
   * @param _mintFee The new minting fee
   * @param _burnFee The new burning fee
   * @param _feePayee The new payee
   */
  function setFees(
    uint256 _mintFee,
    uint256 _burnFee,
    address _feePayee
  ) external onlyRole(MANAGER) {
    mintFee = _mintFee;
    burnFee = _burnFee;
    feePayee = _feePayee;
    emit FeesChanged(_mintFee, _burnFee, _feePayee);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract Slashable is AccessControl, IERC20 {
  using SafeERC20 for IERC20;

  /// @dev Precomputed hash for "SLASHER" role ID
  bytes32 public immutable SLASHER = keccak256("SLASHER");

  /// @dev Slash event
  event Slash(address indexed slasher, IERC20 token, uint256 amount);

  /// @dev The slashable asset
  function underlying() public view virtual returns (IERC20);

  /**
   * @dev Slash the pool by a given amount. Callable by the owner.
   * @param amount The amount of tokens to slash
   * @param receiver The recipient of the slashed assets
   */
  function slash(uint256 amount, address receiver) external onlyRole(SLASHER) {
    IERC20 token = underlying();
    require(
      token.balanceOf(address(this)) >= amount,
      "slash: insufficient balance"
    );

    token.safeTransfer(receiver, amount);
    emit Slash(msg.sender, token, amount);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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