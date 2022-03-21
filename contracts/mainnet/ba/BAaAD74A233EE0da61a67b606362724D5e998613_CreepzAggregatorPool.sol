// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./CreepzInterfaces.sol";

//   /$$$$$$            /$$                 /$$                
//  /$$__  $$          | $$                | $$                
// | $$  \__/  /$$$$$$ | $$$$$$$   /$$$$$$ | $$  /$$$$$$       
// | $$       |____  $$| $$__  $$ |____  $$| $$ |____  $$      
// | $$        /$$$$$$$| $$  \ $$  /$$$$$$$| $$  /$$$$$$$      
// | $$    $$ /$$__  $$| $$  | $$ /$$__  $$| $$ /$$__  $$      
// |  $$$$$$/|  $$$$$$$| $$$$$$$/|  $$$$$$$| $$|  $$$$$$$      
//  \______/  \_______/|_______/  \_______/|__/ \_______/      
//   /$$$$$$                                                   
//  /$$__  $$                                                  
// | $$  \__/  /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$  /$$$$$$$$
// | $$       /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$|____ /$$/
// | $$      | $$  \__/| $$$$$$$$| $$$$$$$$| $$  \ $$   /$$$$/ 
// | $$    $$| $$      | $$_____/| $$_____/| $$  | $$  /$$__/  
// |  $$$$$$/| $$      |  $$$$$$$|  $$$$$$$| $$$$$$$/ /$$$$$$$$
//  \______/ |__/       \_______/ \_______/| $$____/ |________/
//  /$$$$$$$                     /$$       | $$                
// | $$__  $$                   | $$       | $$                
// | $$  \ $$ /$$$$$$   /$$$$$$ | $$       |__/                
// | $$$$$$$//$$__  $$ /$$__  $$| $$                           
// | $$____/| $$  \ $$| $$  \ $$| $$                           
// | $$     | $$  | $$| $$  | $$| $$                           
// | $$     |  $$$$$$/|  $$$$$$/| $$                           
// |__/      \______/  \______/ |__/                           
                                                            
// catch us at https://cabalacreepz.co

contract CreepzAggregatorPool is Context, Initializable, IERC721Receiver {
  struct Stakeholder {
    uint256 totalStaked;
    uint256 unclaimed;
    uint256 TWAP;
  }

  uint256 public totalStaked;
  uint256 public totalTaxReceived;
  uint256 public totalClaimable;
  uint256 public lastClaimedTimestamp;

  uint256 public TWAP;

  mapping(address => Stakeholder) public stakes;

  address public immutable allowedOrigin;

  ILoomi public immutable Loomi;
  ICreepz public immutable Creepz;
  IMegaShapeshifter public immutable MegaShapeshifter;

  modifier onlyFromAllowedOrigin() {
    require(_msgSender() == allowedOrigin);
    _;
  }

  constructor(
    address origin,
    address loomiAddress,
    address creepzAddress,
    address megaShapeshifterAddress
  ) {
    // set the allowed origin to the aggregator address
    allowedOrigin = origin;

    Loomi = ILoomi(loomiAddress);
    Creepz = ICreepz(creepzAddress);
    MegaShapeshifter = IMegaShapeshifter(megaShapeshifterAddress);
  }

  function initialize() external initializer {
    // allow the aggregator to flash stake creepz & unstake mega
    Creepz.setApprovalForAll(allowedOrigin, true);
    MegaShapeshifter.setApprovalForAll(allowedOrigin, true);
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function updateTWAPForTransfer(
    address from,
    address to,
    uint256 changes
  ) external onlyFromAllowedOrigin {
    // update the from's stats
    stakes[from].unclaimed += (TWAP - stakes[from].TWAP) * stakes[from].totalStaked;
    stakes[from].totalStaked -= changes;
    stakes[from].TWAP = TWAP;

    // update the to's stats
    stakes[to].unclaimed += (TWAP - stakes[to].TWAP) * stakes[to].totalStaked;
    stakes[to].totalStaked += changes;
    stakes[to].TWAP = TWAP;
  }

  function claimTaxFromCreepz(
    uint256 creepzId,
    uint256 reward,
    uint256 commissionRate,
    uint256 creepzNonce,
    bytes calldata creepzSignature
  ) external onlyFromAllowedOrigin {
    // need at least one shapeshifter staked to distribute tax
    require(totalStaked > 0);

    // claim the tax from creepz
    MegaShapeshifter.claimTax(reward, creepzNonce, creepzId, creepzSignature);

    // deduct the commission from the total tax received
    reward = (reward * commissionRate) / 1e4;

    // update the pool's stats
    TWAP += reward / totalStaked;
    totalTaxReceived += reward;
    totalClaimable += reward;

    // update the last claimed timestamp
    lastClaimedTimestamp = block.timestamp;
  }

  function claimTaxFromPool(address stakeholder) external onlyFromAllowedOrigin {
    // calculate the total reward amount
    uint256 totalReward = stakes[stakeholder].unclaimed + (TWAP - stakes[stakeholder].TWAP) * stakes[stakeholder].totalStaked;

    // update the pool's stats
    totalClaimable -= totalReward;

    // update the stakeholder's stats
    stakes[stakeholder].unclaimed = 0;
    stakes[stakeholder].TWAP = TWAP;

    // transfer the total reward to the stakeholder
    Loomi.transferLoomi(stakeholder, totalReward);
  }

  function stakeShapeshifters(address stakeholder, uint256[6] calldata shapeTypes) external onlyFromAllowedOrigin {
    // update the pool's stats
    totalStaked += shapeTypes[5];

    // update the stakeholder's stats
    stakes[stakeholder].unclaimed += (TWAP - stakes[stakeholder].TWAP) * stakes[stakeholder].totalStaked;
    stakes[stakeholder].totalStaked += shapeTypes[5];
    stakes[stakeholder].TWAP = TWAP;
  }

  function unstakeShapeshifters(address stakeholder, uint256[6] calldata shapeTypes) external onlyFromAllowedOrigin {
    // update the pool's stats
    totalStaked -= shapeTypes[5];

    // update the stakeholder's stats
    stakes[stakeholder].unclaimed += (TWAP - stakes[stakeholder].TWAP) * stakes[stakeholder].totalStaked;
    stakes[stakeholder].totalStaked -= shapeTypes[5];
    stakes[stakeholder].TWAP = TWAP;
  }

  function unstakeMegashapeshifter(address stakeholder, uint256 megaId) external onlyFromAllowedOrigin {
    // calculate the inefficiency score
    require(stakes[stakeholder].totalStaked * MegaShapeshifter.balanceOf(address(this)) >= totalStaked);

    // update the pool's stats
    totalStaked -= 5;

    // update the stakeholder's stats
    stakes[stakeholder].unclaimed += (TWAP - stakes[stakeholder].TWAP) * stakes[stakeholder].totalStaked;
    stakes[stakeholder].totalStaked -= 5;
    stakes[stakeholder].TWAP = TWAP;

    // transfer the mega shapeshifter
    MegaShapeshifter.transferFrom(address(this), stakeholder, megaId);
  }

  function mutateMegaShapeshifter(
    uint256[] calldata shapeIds,
    uint256 shapeType,
    bytes calldata signature
  ) external {
    // mutate by calling the MegaShapeshifter contract
    MegaShapeshifter.mutate(shapeIds, shapeType, signature);
  }

  function withdrawPoolEarnOwner(address withdrawAddress) external onlyFromAllowedOrigin {
    // get the loomi balance of the contract
    uint256 loomiBalance = Loomi.getUserBalance(address(this));

    // transfer the commission received to the withdraw address
    Loomi.transferLoomi(withdrawAddress, loomiBalance - totalClaimable);
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

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
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

interface ILoomi {
  function approve(address spender, uint256 amount) external;

  function transferLoomi(address to, uint256 amount) external;

  function getUserBalance(address user) external view returns (uint256);
}

interface ICreepz {
  function setApprovalForAll(address to, bool approved) external;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

interface IShapeshifter {
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

interface IMegaShapeshifter {
  function setApprovalForAll(address to, bool approved) external;

  function claimTax(
    uint256 amount,
    uint256 nonce,
    uint256 creepzId,
    bytes calldata signature
  ) external;

  function mutate(
    uint256[] memory shapeIds,
    uint256 shapeType,
    bytes calldata signature
  ) external;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function balanceOf(address account) external view returns (uint256);
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