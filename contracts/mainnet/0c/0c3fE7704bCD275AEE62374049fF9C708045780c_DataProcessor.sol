// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IHeroManager.sol";
import "../interfaces/ILobbyManager.sol";

contract DataProcessor is Multicall, Ownable {
  IHeroManager public heroManager;
  ILobbyManager public lobbyManager;

  constructor(address hmAddr, address lmAddr) {
    heroManager = IHeroManager(hmAddr);
    lobbyManager = ILobbyManager(lmAddr);
  }

  function getPlayerHeroesOnLobby(uint256 lobbyId, address player)
    public
    view
    returns (uint256[] memory)
  {
    return lobbyManager.getPlayerHeroesOnLobby(lobbyId, player);
  }

  function getLobbyHeroes(uint256 lobbyId)
    external
    view
    returns (
      address,
      uint256[] memory,
      address,
      uint256[] memory
    )
  {
    (, , address host, address client, , , , , , , ) = lobbyManager.lobbies(
      lobbyId
    );
    return (
      host,
      getPlayerHeroesOnLobby(lobbyId, host),
      client,
      getPlayerHeroesOnLobby(lobbyId, client)
    );
  }

  function getLobbyPower(uint256 lobbyId)
    external
    view
    returns (
      address,
      uint256,
      address,
      uint256
    )
  {
    (, , address host, address client, , , , , , , ) = lobbyManager.lobbies(
      lobbyId
    );
    uint256 hostPower = lobbyManager.powerHistory(lobbyId, host);
    uint256 clientPower = lobbyManager.powerHistory(lobbyId, client);

    return (host, hostPower, client, clientPower);
  }

  function getHeroesPower(uint256[] memory heroes)
    public
    view
    returns (uint256)
  {
    return lobbyManager.getHeroesPower(heroes);
  }

  function getActiveLobbies(address myAddr, uint256 lobbyCapacity)
    external
    view
    returns (uint256[] memory)
  {
    uint256 count;

    uint256 totalLobbies = lobbyManager.totalLobbies();
    for (uint256 i = 1; i <= totalLobbies; i++) {
      (
        ,
        ,
        address host,
        ,
        ,
        uint256 capacity,
        ,
        uint256 finishedAt,
        ,
        ,

      ) = lobbyManager.lobbies(i);
      if (finishedAt == 0 && capacity == lobbyCapacity && host != myAddr) {
        count++;
      }
    }

    uint256 baseIndex = 0;
    uint256[] memory result = new uint256[](count);
    for (uint256 i = 1; i <= totalLobbies; i++) {
      (
        ,
        ,
        address host,
        ,
        ,
        uint256 capacity,
        ,
        uint256 finishedAt,
        ,
        ,

      ) = lobbyManager.lobbies(i);
      if (finishedAt == 0 && capacity == lobbyCapacity && host != myAddr) {
        result[baseIndex] = i;
        baseIndex++;
      }
    }

    return result;
  }

  function getMyLobbies(address myAddr, uint256 lobbyCapacity)
    external
    view
    returns (uint256[] memory)
  {
    uint256 count;

    uint256 totalLobbies = lobbyManager.totalLobbies();
    for (uint256 i = 1; i <= totalLobbies; i++) {
      (
        ,
        ,
        address host,
        ,
        ,
        uint256 capacity,
        ,
        uint256 finishedAt,
        ,
        ,

      ) = lobbyManager.lobbies(i);
      if (finishedAt == 0 && capacity == lobbyCapacity && host == myAddr) {
        count++;
      }
    }

    uint256 baseIndex = 0;
    uint256[] memory result = new uint256[](count);
    for (uint256 i = 1; i <= totalLobbies; i++) {
      (
        ,
        ,
        address host,
        ,
        ,
        uint256 capacity,
        ,
        uint256 finishedAt,
        ,
        ,

      ) = lobbyManager.lobbies(i);
      if (finishedAt == 0 && capacity == lobbyCapacity && host == myAddr) {
        result[baseIndex] = i;
        baseIndex++;
      }
    }

    return result;
  }

  function getMyHistory(address myAddr, uint256 lobbyCapacity)
    external
    view
    returns (uint256[] memory)
  {
    uint256 count;

    uint256 totalLobbies = lobbyManager.totalLobbies();
    for (uint256 i = 1; i <= totalLobbies; i++) {
      (
        ,
        ,
        address host,
        address client,
        ,
        uint256 capacity,
        ,
        uint256 finishedAt,
        ,
        ,

      ) = lobbyManager.lobbies(i);
      if (
        finishedAt > 0 &&
        capacity == lobbyCapacity &&
        (host == myAddr || client == myAddr)
      ) {
        count++;
      }
    }

    uint256 baseIndex = 0;
    uint256[] memory result = new uint256[](count);
    for (uint256 i = 1; i <= totalLobbies; i++) {
      (
        ,
        ,
        address host,
        address client,
        ,
        uint256 capacity,
        ,
        uint256 finishedAt,
        ,
        ,

      ) = lobbyManager.lobbies(i);
      if (
        finishedAt > 0 &&
        capacity == lobbyCapacity &&
        (host == myAddr || client == myAddr)
      ) {
        result[baseIndex] = i;
        baseIndex++;
      }
    }

    return result;
  }

  function getAllHistory(uint256 lobbyCapacity)
    external
    view
    returns (uint256[] memory)
  {
    uint256 count;

    uint256 totalLobbies = lobbyManager.totalLobbies();
    for (uint256 i = 1; i <= totalLobbies; i++) {
      (, , , , , uint256 capacity, , uint256 finishedAt, , , ) = lobbyManager
        .lobbies(i);
      if (finishedAt > 0 && capacity == lobbyCapacity) {
        count++;
      }
    }

    uint256 baseIndex = 0;
    uint256[] memory result = new uint256[](count);
    for (uint256 i = 1; i <= totalLobbies; i++) {
      (, , , , , uint256 capacity, , uint256 finishedAt, , , ) = lobbyManager
        .lobbies(i);
      if (finishedAt > 0 && capacity == lobbyCapacity) {
        result[baseIndex] = i;
        baseIndex++;
      }
    }

    return result;
  }

  function setHeroManager(address hmAddr) external onlyOwner {
    heroManager = IHeroManager(hmAddr);
  }

  function setLobbyManager(address lmAddr) external onlyOwner {
    lobbyManager = ILobbyManager(lmAddr);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface ILobbyManager {
  function lobbies(uint256 lobbyId)
    external
    view
    returns (
      bytes32 name,
      bytes32 avatar,
      address host,
      address client,
      uint256 id,
      uint256 capacity,
      uint256 startedAt,
      uint256 finishedAt,
      uint256 winner,
      uint256 fee,
      uint256 rewards
    );

  function lobbyHeroes(
    uint256 lobbyId,
    address player,
    uint256 index
  ) external view returns (uint256);

  function powerHistory(uint256 lobbyId, address player)
    external
    view
    returns (uint256);

  function getPlayerHeroesOnLobby(uint256 lobbyId, address player)
    external
    view
    returns (uint256[] memory);

  function getHeroesPower(uint256[] memory heroes)
    external
    view
    returns (uint256);

  function totalLobbies() external view returns (uint256);
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