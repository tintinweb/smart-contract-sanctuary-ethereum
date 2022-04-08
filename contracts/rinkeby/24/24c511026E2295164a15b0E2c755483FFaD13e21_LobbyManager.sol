// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../interfaces/IHeroManager.sol";
import "../interfaces/IVersusBattle.sol";
import "../libraries/UnsafeMath.sol";

/** lobby management */
contract LobbyManager is Ownable, Multicall {
  using UnsafeMath for uint256;

  struct Lobby {
    bytes32 name;
    bytes32 avatar;
    address host;
    address client;
    uint256 id;
    uint256 capacity;
    uint256 startedAt;
    uint256 finishedAt;
    uint256 winner; // 1: host, 2 : client, 0: in-progress
    uint256 fee;
    uint256 rewards;
  }

  uint256 public totalLobbies;

  address public nodePoolAddress;
  IHeroManager public heroManager;
  uint256 public benefitMultiplier = 180;

  uint256 public totalPlayers;
  mapping(uint256 => address) public uniquePlayers;
  mapping(address => bool) public registeredPlayers;
  mapping(address => uint256) public playersFees;
  mapping(address => uint256) public playersRewards;

  mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
    public lobbyHeroes;
  mapping(uint256 => Lobby) public lobbies;
  mapping(uint256 => uint256) public lobbyFees;

  mapping(uint256 => IVersusBattle) public battles;
  mapping(uint256 => mapping(address => uint256)) public powerHistory;

  event BattleFinished(
    uint256 indexed lobbyId,
    address indexed host,
    address indexed client
  );

  constructor(address npAddr) {
    lobbyFees[1] = 50000 * 10**18;
    lobbyFees[3] = 125000 * 10**18;
    lobbyFees[5] = 175000 * 10**18;
    nodePoolAddress = npAddr;
  }

  function createLobby(
    bytes32 name,
    bytes32 avatar,
    uint256 capacity,
    uint256[] calldata heroIds
  ) external {
    address host = msg.sender;
    uint256 fee = lobbyFees[capacity];
    heroManager.validateHeroIds(heroIds, host);
    heroManager.validateHeroEnergies(heroIds);
    IERC20 token = IERC20(heroManager.token());

    require(capacity == heroIds.length, "LobbyManager: wrong parameters");
    require(fee > 0, "LobbyManager: wrong lobby capacity");
    require(
      token.transferFrom(host, address(this), fee),
      "LobbyManager: not enough fee"
    );

    registerUniquePlayers(host);

    // Sum up total fees
    playersFees[host] = playersFees[host].add(fee);

    uint256 lobbyId = totalLobbies.add(1);
    totalLobbies = lobbyId;

    Lobby memory lobby = Lobby(
      name,
      avatar,
      host,
      address(0),
      lobbyId,
      capacity,
      block.timestamp,
      0,
      0,
      fee,
      0
    );

    lobbies[lobbyId] = lobby;

    for (uint256 i = 0; i < heroIds.length; i = i.add(1)) {
      lobbyHeroes[lobbyId][host][i] = heroIds[i];
      heroManager.spendHeroEnergy(heroIds[i]);
    }
  }

  function joinLobby(uint256 lobbyId, uint256[] calldata heroIds) external {
    address client = msg.sender;
    address host = lobbies[lobbyId].host;
    uint256 capacity = lobbies[lobbyId].capacity;

    heroManager.validateHeroIds(heroIds, client);
    heroManager.validateHeroEnergies(heroIds);

    require(
      lobbies[lobbyId].id == lobbyId,
      "LobbyManager: lobby doesn't exist"
    );
    require(capacity == heroIds.length, "LobbyManager: wrong heroes");
    require(lobbies[lobbyId].finishedAt == 0, "LobbyManager: already finished");

    IERC20 token = IERC20(heroManager.token());
    uint256 fee = lobbyFees[capacity];
    require(
      token.transferFrom(client, address(this), fee),
      "LobbyManager: not enough fee"
    );

    // Register player address on unique players table
    registerUniquePlayers(client);

    // Sum up total fees
    playersFees[client] = playersFees[client].add(fee);

    lobbies[lobbyId].client = client;
    lobbies[lobbyId].finishedAt = block.timestamp;

    uint256[] memory hostHeroes = getPlayerHeroesOnLobby(lobbyId, host);

    // Save heroes' power
    powerHistory[lobbyId][host] = getHeroesPower(hostHeroes);
    powerHistory[lobbyId][client] = getHeroesPower(heroIds);

    // Reward calculation
    uint256 reward = fee.mul(benefitMultiplier).div(100);
    lobbies[lobbyId].rewards = reward;

    IVersusBattle battle = battles[capacity];
    uint256 winner = battle.contest(hostHeroes, heroIds);
    lobbies[lobbyId].winner = winner;

    battleResultProcess(lobbyId, winner, hostHeroes, heroIds, client);

    address winnerAddress = winner == 1 ? host : client;

    // Send tokens
    token.transfer(winnerAddress, reward);
    token.transfer(nodePoolAddress, fee.mul(200 - benefitMultiplier).div(100));

    playersRewards[winnerAddress] = playersRewards[winnerAddress].add(reward);

    emit BattleFinished(lobbyId, host, client);
  }

  function registerUniquePlayers(address player) internal {
    if (!registeredPlayers[player]) {
      uniquePlayers[totalPlayers] = player;
      registeredPlayers[player] = true;
      totalPlayers = totalPlayers.add(1);
    }
  }

  function battleResultProcess(
    uint256 lobbyId,
    uint256 winner,
    uint256[] memory hostHeroes,
    uint256[] memory clientHeroes,
    address client
  ) internal {
    for (uint256 i = 0; i < hostHeroes.length; i = i.add(1)) {
      heroManager.expUp(hostHeroes[i], winner == 1);
      heroManager.expUp(clientHeroes[i], winner == 2);
      heroManager.spendHeroEnergy(clientHeroes[i]);
      lobbyHeroes[lobbyId][client][i] = clientHeroes[i];
    }
  }

  function getPlayerHeroesOnLobby(uint256 lobbyId, address player)
    public
    view
    returns (uint256[] memory)
  {
    uint256 count = 0;
    while (lobbyHeroes[lobbyId][player][count] > 0) {
      count++;
    }
    uint256[] memory heroes = new uint256[](count);

    for (uint256 i = 0; i < count; i = i.add(1)) {
      heroes[i] = lobbyHeroes[lobbyId][player][i];
    }
    return heroes;
  }

  function getHeroesPower(uint256[] memory heroes)
    public
    view
    returns (uint256)
  {
    uint256 power;
    for (uint256 i = 0; i < heroes.length; i = i.add(1)) {
      power = power.add(heroManager.heroPower(heroes[i]));
    }
    return power;
  }

  function setHeroManager(address hmAddr) external onlyOwner {
    heroManager = IHeroManager(hmAddr);
  }

  function setLobbyFee(uint256 capacity, uint256 fee) external onlyOwner {
    lobbyFees[capacity] = fee;
  }

  function setBenefitMultiplier(uint256 multiplier) external onlyOwner {
    require(multiplier < 200, "LobbyManager: too high multiplier");
    benefitMultiplier = multiplier;
  }

  function setBattleAddress(uint256 capacity, address battleAddress)
    external
    onlyOwner
  {
    battles[capacity] = IVersusBattle(battleAddress);
  }

  function setNodePool(address npAddr) external onlyOwner {
    nodePoolAddress = npAddr;
  }

  function withdrawReserves(uint256 amount) external onlyOwner {
    IERC20 token = IERC20(heroManager.token());
    token.transfer(msg.sender, amount);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IHeroManager {
  function heroPower(uint256 heroId) external view returns (uint256);

  function heroPrimaryAttribute(uint256 heroId) external view returns (uint256);

  function heroLevel(uint256 heroId) external view returns (uint256);

  function bulkExpUp(uint256[] calldata heroIds, bool won) external;

  function heroEnergy(uint256 heroId) external view returns (uint256);

  function spendHeroEnergy(uint256 heroId) external;

  function expUp(uint256 heroId, bool won) external;

  function token() external view returns (address);

  function nft() external view returns (address);

  function validateHeroIds(uint256[] calldata heroIds, address owner)
    external
    view
    returns (bool);

  function validateHeroEnergies(uint256[] calldata heroIds)
    external
    view
    returns (bool);

  function rewardsPayeer() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IVersusBattle {
  function contest(uint256[] memory hostHeroes, uint256[] memory clientHeroes)
    external
    view
    returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

library UnsafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    unchecked {
      return a + b;
    }
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    unchecked {
      return a - b;
    }
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    unchecked {
      return a * b;
    }
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    unchecked {
      return a / b;
    }
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