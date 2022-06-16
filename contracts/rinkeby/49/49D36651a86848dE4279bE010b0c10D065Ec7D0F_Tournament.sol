// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

import {Auth} from "../utils/Auth.sol";
import {ITournament} from "./ITournament.sol";
import {Scholarship} from "../scholarship/Scholarship.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Tournament is ITournament, Auth {
  using SafeERC20 for IERC20;
  using SafeCast for uint256;

  // Constants
  uint256 private constant _BASIS_POINTS = 100_00;
  uint256 private constant _EXPIRATION_PERIOD = 1 weeks;
  string private constant _MANAGER = "MANAGER";
  uint32 private constant _MAX_UINT32 = type(uint32).max;

  // Address of USDC
  IERC20 public immutable usdc;
  // Address of rooster
  IERC721 public immutable rooster;
  // Address of scholarship contract
  Scholarship public scholarship;
  // Address of vault -- where fees go
  address public vault;

  // List of tournament games
  Game[] public games;
  // List of roosters (game id => rooster id => rooster state)
  // 0: not registered
  // 1 ~ 2^32 - 2: ranking of winners
  // 2^32 - 1: registered / unranked roosters
  mapping(uint256 => mapping(uint256 => uint32)) public roosters;

  constructor(
    address usdc_,
    address rooster_,
    address scholarship_,
    address vault_
  ) {
    usdc = IERC20(usdc_);
    rooster = IERC721(rooster_);
    scholarship = Scholarship(scholarship_);
    vault = vault_;
  }

  /**
   * @notice Queries state of roosters in batch
   * @param gameId Game id
   * @param roosterIds List of rooster ids
   */
  function batchQuery(uint256 gameId, uint256[] calldata roosterIds)
    external
    view
    returns (uint32[] memory)
  {
    uint32[] memory result = new uint32[](roosterIds.length);
    for (uint256 i = 0; i < roosterIds.length; i++) {
      result[i] = roosters[gameId][roosterIds[i]];
    }
    return result;
  }

  /**
   * @notice Returns total `games` created
   * @return uint256
   */
  function totalGames() external view returns (uint256) {
    return games.length;
  }

  /**
   * @notice Gets sum of distribution percentages
   * @param gameId Game id
   * @return sum uint32
   */
  function getDistributionsSum(uint256 gameId) external view returns (uint32 sum) {
    Game storage game = games[gameId];
    for (uint256 i = 1; i < game.distributions.length; i++) {
      sum += game.distributions[i];
    }
  }

  /**
   * @notice Creates new game
   * @param game Game info
   * @return gameId uint256
   */
  function createGame(Game memory game) external onlyRole(_MANAGER) returns (uint256 gameId) {
    // Param check
    require(
      game.registrationStartTimestamp < game.registrationEndTimestamp,
      "Invalid registeration time window"
    );
    require(game.registrationStartTimestamp >= block.timestamp, "Invalid registeration start time");
    require(
      game.tournamentStartTimestamp < game.tournamentEndTimestamp,
      "Invalid tournament time window"
    );
    require(
      game.tournamentStartTimestamp > game.registrationEndTimestamp,
      "Invalid tournament start time"
    );
    require(game.distributions[0] == 0, "0th index must be 0");
    require(game.fee <= _BASIS_POINTS, "Invalid fee");

    // Get game id
    gameId = games.length;

    // Initialize and create game
    game.roosters = 0;
    game.state = State.ONGOING;
    game.rankingRoot = bytes32(0);
    games.push(game);

    emit CreateGame(gameId, game.requirementId, msg.sender);
  }

  /**
   * @notice Sets state of game
   * @param action Action enum
   * @param gameId Game id
   * @param rankingRoot Merkle root of ranking
   * @param distributions Distrubtion percentages to add.
   */
  function setGame(
    Action action,
    uint256 gameId,
    bytes32 rankingRoot,
    uint16[] calldata distributions
  ) external onlyRole(_MANAGER) {
    Game storage game = games[gameId];

    if (action == Action.ADD) {
      uint256 num = distributions.length;
      require(block.timestamp < game.registrationStartTimestamp, "Registeration started");
      require(num > 0, "distrubutions not provided");

      // TODO: pre-package `distributions` and push by batch
      for (uint256 i = 0; i < num; i++) {
        game.distributions.push(distributions[i]);
      }
    } else if (action == Action.END) {
      require(game.state == State.ONGOING, "Not ongoing");
      require(block.timestamp >= game.tournamentEndTimestamp, "Not ended");
      require(rankingRoot != bytes32(0), "rankingRoot not provided");
      require(game.roosters >= game.minRoosters, "Not enough roosters");
      game.rankingRoot = rankingRoot;
      game.state = State.ENDED;
    } else if (action == Action.CANCEL) {
      require(game.state == State.ONGOING, "Not ongoing");
      game.state = State.CANCELLED;
    } else if (action == Action.PAUSE) {
      require(game.state == State.ONGOING, "Not ongoing");
      game.state = State.PAUSED;
    } else if (action == Action.UNPAUSE) {
      require(game.state == State.PAUSED, "Not paused");
      game.state = State.ONGOING;
    }

    emit SetGame(gameId, action);
  }

  /**
   * @notice Registers for the tournament game
   * @param gameId Game id
   * @param roosterIds List of roosters to register
   * @param sig Signature for tournament qualification
   */
  function register(
    uint256 gameId,
    uint256[] calldata roosterIds,
    Sig calldata sig
  ) external whenNotPaused {
    Game storage game = games[gameId];
    uint256 num = roosterIds.length;

    // Checks
    require(block.timestamp >= game.registrationStartTimestamp, "Not started");
    require(block.timestamp < game.registrationEndTimestamp, "Ended");
    require(game.state == State.ONGOING, "Paused or Cancelled");
    require(num <= game.maxRoosters - game.roosters, "Reached limit");
    require(_isOwner(msg.sender, roosterIds), "Not owner");
    require(_isQualified(gameId, game.requirementId, roosterIds, sig), "Not qualified");

    // Effects
    for (uint256 i = 0; i < num; i++) {
      require(roosters[gameId][roosterIds[i]] == 0, "Already registered");
      roosters[gameId][roosterIds[i]] = _MAX_UINT32;
    }
    game.roosters += num.toUint32();
    game.balance += (game.entranceFee * num).toUint128();

    // Interactions
    usdc.safeTransferFrom(msg.sender, address(this), game.entranceFee * num);

    emit RegisterGame(gameId, roosterIds, msg.sender);
  }

  /**
   * @notice Claims reward from tournament prize pool
   * @param gameId Game id
   * @param roosterIds List of rooster ids
   * @param rankings List of rankings
   */
  function claimReward(
    uint256 gameId,
    uint256[] calldata roosterIds,
    uint32[] calldata rankings,
    bytes32[][] memory proofs,
    address recipient
  ) external whenNotPaused returns (uint256 amount, uint256 fee) {
    Game storage game = games[gameId];

    // Checks
    require(roosterIds.length == rankings.length, "Length mismatch");
    require(game.state == State.ENDED, "Not ended");
    require(block.timestamp < game.tournamentEndTimestamp + _EXPIRATION_PERIOD, "Expired");
    require(_isOwner(msg.sender, roosterIds), "Not owner");

    // Todo: Verify multiple nodes in one go
    uint256 totalAmount = game.entranceFee * game.roosters;
    for (uint256 i = 0; i < roosterIds.length; i++) {
      bytes32 node = keccak256(abi.encodePacked(gameId, roosterIds[i], rankings[i]));
      require(MerkleProof.verify(proofs[i], game.rankingRoot, node), "Invalid proof");
      require(roosters[gameId][roosterIds[i]] == _MAX_UINT32, "Already claimed or not registered");

      // Set rooster ranking
      roosters[gameId][roosterIds[i]] = rankings[i];
      amount += (totalAmount * game.distributions[rankings[i]]) / _BASIS_POINTS;
    }
    game.balance -= amount.toUint128();

    // Interactions
    usdc.safeTransfer(vault, (fee = ((amount * game.fee) / _BASIS_POINTS)));
    usdc.safeTransfer(recipient, amount - fee);

    emit ClaimReward(gameId, roosterIds, amount, recipient);
  }

  /**
   * @notice Claims refund from cancelled tournament
   * @param gameId Game id
   * @param roosterIds List of roosters registered
   * @param recipient Recipient address
   * @return amount Amount claimed
   */
  function claimRefund(
    uint256 gameId,
    uint256[] calldata roosterIds,
    address recipient
  ) external whenNotPaused returns (uint256 amount) {
    Game storage game = games[gameId];
    uint256 num = roosterIds.length;

    // Checks
    require(game.state == State.CANCELLED, "Not cancelled");
    require(_isOwner(msg.sender, roosterIds), "Not owner");

    // Effects
    for (uint256 i = 0; i < num; i++) {
      require(roosters[gameId][roosterIds[i]] == _MAX_UINT32, "Already claimed");
      roosters[gameId][roosterIds[i]] = _MAX_UINT32 - 1;
    }
    amount = game.entranceFee * num;
    game.balance -= amount.toUint128();

    // Interactions
    usdc.safeTransfer(recipient, amount);

    emit ClaimRefund(gameId, roosterIds, amount, recipient);
  }

  function withdrawExpiredRewards(uint256 gameId)
    external
    onlyRole(_MANAGER)
    returns (uint256 amount)
  {
    Game storage game = games[gameId];

    // Checks
    require(block.timestamp >= game.tournamentEndTimestamp + _EXPIRATION_PERIOD, "Not expired");
    require(game.state == State.ENDED, "Not ended");
    require((amount = game.balance) > 0, "Nothing to withdraw");

    // Effects
    game.balance = 0;

    // Interactions
    usdc.safeTransfer(vault, amount);

    emit WithdrawExpiredRewards(gameId, amount);
  }

  function _isOwner(address owner, uint256[] calldata roosterIds) private view returns (bool) {
    for (uint256 i = 0; i < roosterIds.length; i++) {
      if (
        rooster.ownerOf(roosterIds[i]) != owner && scholarship.nft_owner(roosterIds[i]) != owner
      ) {
        return false;
      }
    }
    return true;
  }

  function _isQualified(
    uint256 gameId,
    uint16 requirementId,
    uint256[] calldata roosterIds,
    Sig calldata sig
  ) private view returns (bool) {
    bytes32 messageHash = keccak256(abi.encodePacked(gameId, requirementId, roosterIds));
    bytes32 ethSignedMessageHash = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
    );
    return hasRole("SIGNER", ecrecover(ethSignedMessageHash, sig.v, sig.r, sig.s));
  }

  /**
   * @notice Sets addresses
   * @param vault_ Vault address
   * @param scholarship_ Scholarship contract address
   */
  function setProtocol(address vault_, address scholarship_) external onlyOwner {
    if (vault_ != address(0)) {
      vault = vault_;
    }
    if (scholarship_ != address(0)) {
      scholarship = Scholarship(scholarship_);
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

library Strings {
  function toBytes32(string memory text) internal pure returns (bytes32) {
    return bytes32(bytes(text));
  }

  function toString(bytes32 text) internal pure returns (string memory) {
    return string(abi.encodePacked(text));
  }
}

contract Auth {
  //Address of current owner
  address public owner;
  //Address of new owner (Note: new owner must pull to be an owner)
  address public newOwner;
  //If paused or not
  uint256 private _paused;
  //Roles mapping (role => address => has role)
  mapping(bytes32 => mapping(address => bool)) private _roles;

  //Fires when a new owner is pushed
  event OwnerPushed(address indexed pushedOwner);
  //Fires when new owner pulled
  event OwnerPulled(address indexed previousOwner, address indexed newOwner);
  //Fires when account is granted role
  event RoleGranted(string indexed role, address indexed account, address indexed sender);
  //Fires when accoount is revoked role
  event RoleRevoked(string indexed role, address indexed account, address indexed sender);
  //Fires when pause is triggered by account
  event Paused(address account);
  //Fires when pause is lifted by account
  event Unpaused(address account);

  error Unauthorized(string role, address user);
  error IsPaused();
  error NotPaused();

  constructor() {
    owner = msg.sender;
    emit OwnerPulled(address(0), msg.sender);
  }

  modifier whenNotPaused() {
    if (paused()) revert IsPaused();
    _;
  }

  modifier whenPaused() {
    if (!paused()) revert NotPaused();
    _;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) revert Unauthorized("OWNER", msg.sender);
    _;
  }

  modifier onlyRole(string memory role) {
    if (!hasRole(role, msg.sender)) revert Unauthorized(role, msg.sender);
    _;
  }

  function hasRole(string memory role, address account) public view virtual returns (bool) {
    return _roles[Strings.toBytes32(role)][account];
  }

  function paused() public view virtual returns (bool) {
    return _paused == 1 ? true : false;
  }

  function pushOwner(address account) public virtual onlyOwner {
    require(account != address(0), "No address(0)");
    require(account != owner, "Only new owner");
    newOwner = account;
    emit OwnerPushed(account);
  }

  function pullOwner() public virtual {
    if (msg.sender != newOwner) revert Unauthorized("NEW_OWNER", msg.sender);
    address oldOwner = owner;
    owner = msg.sender;
    emit OwnerPulled(oldOwner, msg.sender);
  }

  function grantRole(string memory role, address account) public virtual onlyOwner {
    require(bytes(role).length > 0, "Role not given");
    require(account != address(0), "No address(0)");
    _grantRole(role, account);
  }

  function revokeRole(string memory role, address account) public virtual onlyOwner {
    require(hasRole(role, account), "Role not granted");
    _revokeRole(role, account);
  }

  function renounceRole(string memory role) public virtual {
    require(hasRole(role, msg.sender), "Role not granted");
    _revokeRole(role, msg.sender);
  }

  function pause() public virtual onlyRole("PAUSER") whenNotPaused {
    _paused = 1;
    emit Paused(msg.sender);
  }

  function unpause() public virtual onlyRole("PAUSER") whenPaused {
    _paused = 0;
    emit Unpaused(msg.sender);
  }

  function _grantRole(string memory role, address account) internal virtual {
    if (!hasRole(role, account)) {
      bytes32 encodedRole = Strings.toBytes32(role);
      _roles[encodedRole][account] = true;
      emit RoleGranted(role, account, msg.sender);
    }
  }

  function _revokeRole(string memory role, address account) internal virtual {
    bytes32 encodedRole = Strings.toBytes32(role);
    _roles[encodedRole][account] = false;
    emit RoleRevoked(role, account, msg.sender);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.4;

interface ITournament {
  // 5slots
  struct Game {
    uint32 registrationStartTimestamp; // Registration start date in block.timestamp [4]
    uint32 registrationEndTimestamp; // Registeration end date in block.timestamp [4]
    uint32 tournamentStartTimestamp; // Tournament start date in block.timestamp [4]
    uint32 tournamentEndTimestamp; // Tournament end date in block.timestamp [4]
    uint32 minRoosters; // Minimum roosters required to start [4]
    uint32 maxRoosters; // Maximum roosters for game [4]
    uint32 roosters; // Number of rooosters [4]
    uint128 entranceFee; // Entrance fee in USDC [16]
    uint128 balance; // Balance of tournament pool in USDC [16]
    bytes32 rankingRoot; // Merkle root of tournament ranking [32]
    uint16[] distributions; // Array of distrubution percentages in hundreds [32 + 2n]
    uint16 fee; // Protocol fee in hundreds [4]
    uint16 requirementId; // Requirement id [4]
    State state; // Event state [1]
  }

  struct Sig {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  enum State {
    ONGOING,
    ENDED,
    PAUSED,
    CANCELLED
  }

  enum Action {
    ADD,
    END,
    PAUSE,
    UNPAUSE,
    CANCEL
  }

  event CreateGame(uint256 indexed gameId, uint16 indexed requirementId, address indexed organzier);
  event SetGame(uint256 indexed gameId, Action indexed action);
  event RegisterGame(uint256 indexed gameId, uint256[] roosterIds, address indexed sender);
  event ClaimReward(
    uint256 indexed gameId,
    uint256[] roosterIds,
    uint256 amount,
    address indexed recipient
  );
  event ClaimRefund(
    uint256 indexed gameId,
    uint256[] roosterIds,
    uint256 amount,
    address indexed recipient
  );
  event WithdrawExpiredRewards(uint256 indexed gameId, uint256 amount);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Scholarship is Ownable {
  IERC721 public immutable nft_contract;
  bool public disabled;

  mapping(uint256 => address) public nft_scholar;
  mapping(uint256 => address) public nft_owner;
  mapping(address => uint256) public lended_nfts;

  event Lend(uint256 nft_id, address scholar);
  event Transfer(uint256 nft_id, address scholar);
  event Revoke(uint256 nft_id);
  event Disable();
  event Enable();

  constructor(address _nft_contract_address) {
    nft_contract = IERC721(_nft_contract_address);
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) public pure returns (bytes4) {
    return this.onERC721Received.selector;
  }

  modifier notDisabled() {
    require(!disabled, "Scholarship:CONTRACT_DISABLED");
    _;
  }

  modifier shouldBeOwner(uint256 nft_id) {
    require(nft_owner[nft_id] == msg.sender, "Scholarship:NOT_OWNER");
    _;
  }

  modifier lended(uint256 nft_id) {
    require(nft_owner[nft_id] != address(0), "Scholarship:NOT_LENDED");
    _;
  }

  function disable() public onlyOwner {
    disabled = true;

    emit Disable();
  }

  function enable() public onlyOwner {
    disabled = false;

    emit Enable();
  }

  function info(uint256 nft_id)
    public
    view
    lended(nft_id)
    returns (address owner, address scholar)
  {
    owner = nft_owner[nft_id];
    scholar = nft_scholar[nft_id];
  }

  function getOwner(uint256 nft_id) public view lended(nft_id) returns (address owner) {
    owner = nft_owner[nft_id];
  }

  function getScholar(uint256 nft_id) public view lended(nft_id) returns (address scholar) {
    scholar = nft_scholar[nft_id];
  }

  function lendNFT(uint256 nft_id, address scholar) public notDisabled {
    nft_scholar[nft_id] = scholar;
    nft_owner[nft_id] = msg.sender;
    unchecked {
      lended_nfts[msg.sender] += 1;
    }

    nft_contract.safeTransferFrom(msg.sender, address(this), nft_id);
    emit Lend(nft_id, scholar);
  }

  function transferScholar(uint256 nft_id, address scholar)
    public
    notDisabled
    shouldBeOwner(nft_id)
  {
    nft_scholar[nft_id] = scholar;

    emit Transfer(nft_id, scholar);
  }

  function revoke(uint256 nft_id) public shouldBeOwner(nft_id) {
    lended_nfts[msg.sender] = lended_nfts[msg.sender] - 1;
    nft_owner[nft_id] = address(0);
    nft_scholar[nft_id] = address(0);

    nft_contract.safeTransferFrom(address(this), msg.sender, nft_id);

    emit Revoke(nft_id);
  }

  function bulkLendNFT(uint256[] calldata nft_ids, address[] calldata scholars) public {
    require(nft_ids.length == scholars.length, "Scholarship:PARAM_MISMATCH");

    for (uint256 i = 0; i < nft_ids.length; i++) {
      lendNFT(nft_ids[i], scholars[i]);
    }
  }

  function bulkTransferScholar(uint256[] calldata nft_ids, address[] calldata scholars) public {
    require(nft_ids.length == scholars.length, "Scholarship:PARAM_MISMATCH");

    for (uint256 i = 0; i < nft_ids.length; i++) {
      transferScholar(nft_ids[i], scholars[i]);
    }
  }

  function bulkRevoke(uint256[] calldata nft_ids) public {
    for (uint256 i = 0; i < nft_ids.length; i++) {
      revoke(nft_ids[i]);
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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