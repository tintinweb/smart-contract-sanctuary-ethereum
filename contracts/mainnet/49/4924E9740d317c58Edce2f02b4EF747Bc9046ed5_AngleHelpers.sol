// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Metadata.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @title IAgToken
/// @author Angle Labs, Inc.
/// @notice Interface for the stablecoins `AgToken` contracts
/// @dev This interface only contains functions of the `AgToken` contract which are called by other contracts
/// of this module or of the first module of the Angle Protocol
interface IAgToken is IERC20Upgradeable {
    // ======================= Minter Role Only Functions ===========================

    /// @notice Lets the `StableMaster` contract or another whitelisted contract mint agTokens
    /// @param account Address to mint to
    /// @param amount Amount to mint
    /// @dev The contracts allowed to issue agTokens are the `StableMaster` contract, `VaultManager` contracts
    /// associated to this stablecoin as well as the flash loan module (if activated) and potentially contracts
    /// whitelisted by governance
    function mint(address account, uint256 amount) external;

    /// @notice Burns `amount` tokens from a `burner` address after being asked to by `sender`
    /// @param amount Amount of tokens to burn
    /// @param burner Address to burn from
    /// @param sender Address which requested the burn from `burner`
    /// @dev This method is to be called by a contract with the minter right after being requested
    /// to do so by a `sender` address willing to burn tokens from another `burner` address
    /// @dev The method checks the allowance between the `sender` and the `burner`
    function burnFrom(
        uint256 amount,
        address burner,
        address sender
    ) external;

    /// @notice Burns `amount` tokens from a `burner` address
    /// @param amount Amount of tokens to burn
    /// @param burner Address to burn from
    /// @dev This method is to be called by a contract with a minter right on the AgToken after being
    /// requested to do so by an address willing to burn tokens from its address
    function burnSelf(uint256 amount, address burner) external;

    // ========================= Treasury Only Functions ===========================

    /// @notice Adds a minter in the contract
    /// @param minter Minter address to add
    /// @dev Zero address checks are performed directly in the `Treasury` contract
    function addMinter(address minter) external;

    /// @notice Removes a minter from the contract
    /// @param minter Minter address to remove
    /// @dev This function can also be called by a minter wishing to revoke itself
    function removeMinter(address minter) external;

    /// @notice Sets a new treasury contract
    /// @param _treasury New treasury address
    function setTreasury(address _treasury) external;

    // ========================= External functions ================================

    /// @notice Checks whether an address has the right to mint agTokens
    /// @param minter Address for which the minting right should be checked
    /// @return Whether the address has the right to mint agTokens or not
    function isMinter(address minter) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

/// @title IAngleRouter
/// @author Angle Labs, Inc.
/// @notice Interface for the `AngleRouter` contract
/// @dev This interface only contains functions of the `AngleRouter01` contract which are called by other contracts
/// of this module
interface IAngleRouter {
    function mint(
        address user,
        uint256 amount,
        uint256 minStableAmount,
        address stablecoin,
        address collateral
    ) external;

    function burn(
        address user,
        uint256 amount,
        uint256 minAmountOut,
        address stablecoin,
        address collateral
    ) external;

    function mapPoolManagers(address stableMaster, address collateral)
        external
        view
        returns (
            address poolManager,
            address perpetualManager,
            address sanToken,
            address gauge
        );
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

/// @title ICoreBorrow
/// @author Angle Labs, Inc.
/// @notice Interface for the `CoreBorrow` contract
/// @dev This interface only contains functions of the `CoreBorrow` contract which are called by other contracts
/// of this module
interface ICoreBorrow {
    /// @notice Checks if an address corresponds to a treasury of a stablecoin with a flash loan
    /// module initialized on it
    /// @param treasury Address to check
    /// @return Whether the address has the `FLASHLOANER_TREASURY_ROLE` or not
    function isFlashLoanerTreasury(address treasury) external view returns (bool);

    /// @notice Checks whether an address is governor of the Angle Protocol or not
    /// @param admin Address to check
    /// @return Whether the address has the `GOVERNOR_ROLE` or not
    function isGovernor(address admin) external view returns (bool);

    /// @notice Checks whether an address is governor or a guardian of the Angle Protocol or not
    /// @param admin Address to check
    /// @return Whether the address has the `GUARDIAN_ROLE` or not
    /// @dev Governance should make sure when adding a governor to also give this governor the guardian
    /// role by calling the `addGovernor` function
    function isGovernorOrGuardian(address admin) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "./IAgToken.sol";
import "./ICoreBorrow.sol";

/// @title IFlashAngle
/// @author Angle Labs, Inc.
/// @notice Interface for the `FlashAngle` contract
/// @dev This interface only contains functions of the contract which are called by other contracts
/// of this module
interface IFlashAngle {
    /// @notice Reference to the `CoreBorrow` contract managing the FlashLoan module
    function core() external view returns (ICoreBorrow);

    /// @notice Sends the fees taken from flash loans to the treasury contract associated to the stablecoin
    /// @param stablecoin Stablecoin from which profits should be sent
    /// @return balance Amount of profits sent
    /// @dev This function can only be called by the treasury contract
    function accrueInterestToTreasury(IAgToken stablecoin) external returns (uint256 balance);

    /// @notice Adds support for a stablecoin
    /// @param _treasury Treasury associated to the stablecoin to add support for
    /// @dev This function can only be called by the `CoreBorrow` contract
    function addStablecoinSupport(address _treasury) external;

    /// @notice Removes support for a stablecoin
    /// @param _treasury Treasury associated to the stablecoin to remove support for
    /// @dev This function can only be called by the `CoreBorrow` contract
    function removeStablecoinSupport(address _treasury) external;

    /// @notice Sets a new core contract
    /// @param _core Core contract address to set
    /// @dev This function can only be called by the `CoreBorrow` contract
    function setCore(address _core) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "./ITreasury.sol";

/// @title IOracle
/// @author Angle Labs, Inc.
/// @notice Interface for the `Oracle` contract
/// @dev This interface only contains functions of the contract which are called by other contracts
/// of this module
interface IOracle {
    /// @notice Reads the rate from the Chainlink circuit and other data provided
    /// @return quoteAmount The current rate between the in-currency and out-currency in the base
    /// of the out currency
    /// @dev For instance if the out currency is EUR (and hence agEUR), then the base of the returned
    /// value is 10**18
    function read() external view returns (uint256);

    /// @notice Changes the treasury contract
    /// @param _treasury Address of the new treasury contract
    /// @dev This function can be called by an approved `VaultManager` contract which can call
    /// this function after being requested to do so by a `treasury` contract
    /// @dev In some situations (like reactor contracts), the `VaultManager` may not directly be linked
    /// to the `oracle` contract and as such we may need governors to be able to call this function as well
    function setTreasury(address _treasury) external;

    /// @notice Reference to the `treasury` contract handling this `VaultManager`
    function treasury() external view returns (ITreasury treasury);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "./IAgToken.sol";
import "./ICoreBorrow.sol";
import "./IFlashAngle.sol";

/// @title ITreasury
/// @author Angle Labs, Inc.
/// @notice Interface for the `Treasury` contract
/// @dev This interface only contains functions of the `Treasury` which are called by other contracts
/// of this module
interface ITreasury {
    /// @notice Stablecoin handled by this `treasury` contract
    function stablecoin() external view returns (IAgToken);

    /// @notice Checks whether a given address has the  governor role
    /// @param admin Address to check
    /// @return Whether the address has the governor role
    /// @dev Access control is only kept in the `CoreBorrow` contract
    function isGovernor(address admin) external view returns (bool);

    /// @notice Checks whether a given address has the guardian or the governor role
    /// @param admin Address to check
    /// @return Whether the address has the guardian or the governor role
    /// @dev Access control is only kept in the `CoreBorrow` contract which means that this function
    /// queries the `CoreBorrow` contract
    function isGovernorOrGuardian(address admin) external view returns (bool);

    /// @notice Checks whether a given address has well been initialized in this contract
    /// as a `VaultManager`
    /// @param _vaultManager Address to check
    /// @return Whether the address has been initialized or not
    function isVaultManager(address _vaultManager) external view returns (bool);

    /// @notice Sets a new flash loan module for this stablecoin
    /// @param _flashLoanModule Reference to the new flash loan module
    /// @dev This function removes the minting right to the old flash loan module and grants
    /// it to the new module
    function setFlashLoanModule(address _flashLoanModule) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITreasury.sol";
import "./IOracle.sol";

// ========================= Key Structs and Enums =============================

/// @notice Parameters associated to a given `VaultManager` contract: these all correspond
/// to parameters which signification is detailed in the `VaultManagerStorage` file
struct VaultParameters {
    uint256 debtCeiling;
    uint64 collateralFactor;
    uint64 targetHealthFactor;
    uint64 interestRate;
    uint64 liquidationSurcharge;
    uint64 maxLiquidationDiscount;
    bool whitelistingActivated;
    uint256 baseBoost;
}

/// @notice Data stored to track someone's loan (or equivalently called position)
struct Vault {
    // Amount of collateral deposited in the vault, in collateral decimals. For example, if the collateral
    // is USDC with 6 decimals, then `collateralAmount` will be in base 10**6
    uint256 collateralAmount;
    // Normalized value of the debt (that is to say of the stablecoins borrowed). It is expressed
    // in the base of Angle stablecoins (i.e. `BASE_TOKENS = 10**18`)
    uint256 normalizedDebt;
}

/// @notice For a given `vaultID`, this encodes a liquidation opportunity that is to say details about the maximum
/// amount that could be repaid by liquidating the position
/// @dev All the values are null in the case of a vault which cannot be liquidated under these conditions
struct LiquidationOpportunity {
    // Maximum stablecoin amount that can be repaid upon liquidating the vault
    uint256 maxStablecoinAmountToRepay;
    // Collateral amount given to the person in the case where the maximum amount to repay is given
    uint256 maxCollateralAmountGiven;
    // Threshold value of stablecoin amount to repay: it is ok for a liquidator to repay below threshold,
    // but if this threshold is non null and the liquidator wants to repay more than threshold, it should repay
    // the max stablecoin amount given in this vault
    uint256 thresholdRepayAmount;
    // Discount proposed to the liquidator on the collateral
    uint256 discount;
    // Amount of debt in the vault
    uint256 currentDebt;
}

/// @notice Data stored during a liquidation process to keep in memory what's due to a liquidator and some
/// essential data for vaults being liquidated
struct LiquidatorData {
    // Current amount of stablecoins the liquidator should give to the contract
    uint256 stablecoinAmountToReceive;
    // Current amount of collateral the contract should give to the liquidator
    uint256 collateralAmountToGive;
    // Bad debt accrued across the liquidation process
    uint256 badDebtFromLiquidation;
    // Oracle value (in stablecoin base) at the time of the liquidation
    uint256 oracleValue;
    // Value of the `interestAccumulator` at the time of the call
    uint256 newInterestAccumulator;
}

/// @notice Data to track during a series of action the amount to give or receive in stablecoins and collateral
/// to the caller or associated addresses
struct PaymentData {
    // Stablecoin amount the contract should give
    uint256 stablecoinAmountToGive;
    // Stablecoin amount owed to the contract
    uint256 stablecoinAmountToReceive;
    // Collateral amount the contract should give
    uint256 collateralAmountToGive;
    // Collateral amount owed to the contract
    uint256 collateralAmountToReceive;
}

/// @notice Actions possible when composing calls to the different entry functions proposed
enum ActionType {
    createVault,
    closeVault,
    addCollateral,
    removeCollateral,
    repayDebt,
    borrow,
    getDebtIn,
    permit
}

// ========================= Interfaces =============================

/// @title IVaultManagerFunctions
/// @author Angle Labs, Inc.
/// @notice Interface for the `VaultManager` contract
/// @dev This interface only contains functions of the contract which are called by other contracts
/// of this module (without getters)
interface IVaultManagerFunctions {
    /// @notice Accrues interest accumulated across all vaults to the surplus and sends the surplus to the treasury
    /// @return surplusValue Value of the surplus communicated to the `Treasury`
    /// @return badDebtValue Value of the bad debt communicated to the `Treasury`
    /// @dev `surplus` and `badDebt` should be reset to 0 once their current value have been given to the `treasury` contract
    function accrueInterestToTreasury() external returns (uint256 surplusValue, uint256 badDebtValue);

    /// @notice Removes debt from a vault after being requested to do so by another `VaultManager` contract
    /// @param vaultID ID of the vault to remove debt from
    /// @param amountStablecoins Amount of stablecoins to remove from the debt: this amount is to be converted to an
    /// internal debt amount
    /// @param senderBorrowFee Borrowing fees from the contract which requested this: this is to make sure that people are not
    /// arbitraging difference in minting fees
    /// @param senderRepayFee Repay fees from the contract which requested this: this is to make sure that people are not arbitraging
    /// differences in repay fees
    /// @dev This function can only be called from a vaultManager registered in the same Treasury
    function getDebtOut(
        uint256 vaultID,
        uint256 amountStablecoins,
        uint256 senderBorrowFee,
        uint256 senderRepayFee
    ) external;

    /// @notice Gets the current debt of a vault
    /// @param vaultID ID of the vault to check
    /// @return Debt of the vault
    function getVaultDebt(uint256 vaultID) external view returns (uint256);

    /// @notice Gets the total debt across all vaults
    /// @return Total debt across all vaults, taking into account the interest accumulated
    /// over time
    function getTotalDebt() external view returns (uint256);

    /// @notice Sets the treasury contract
    /// @param _treasury New treasury contract
    /// @dev All required checks when setting up a treasury contract are performed in the contract
    /// calling this function
    function setTreasury(address _treasury) external;

    /// @notice Creates a vault
    /// @param toVault Address for which the va
    /// @return vaultID ID of the vault created
    /// @dev This function just creates the vault without doing any collateral or
    function createVault(address toVault) external returns (uint256);

    /// @notice Allows composability between calls to the different entry points of this module. Any user calling
    /// this function can perform any of the allowed actions in the order of their choice
    /// @param actions Set of actions to perform
    /// @param datas Data to be decoded for each action: it can include like the `vaultID` or the `stablecoinAmount` to borrow
    /// @param from Address from which stablecoins will be taken if one action includes burning stablecoins. This address
    /// should either be the `msg.sender` or be approved by the latter
    /// @param to Address to which stablecoins and/or collateral will be sent in case of
    /// @param who Address of the contract to handle in case of repayment of stablecoins from received collateral
    /// @param repayData Data to pass to the repayment contract in case of
    /// @return paymentData Struct containing the accounting changes from the protocol's perspective (like how much of collateral
    /// or how much has been received). Note that the values in the struct are not aggregated and you could have in the output
    /// a positive amount of stablecoins to receive as well as a positive amount of stablecoins to give
    /// @dev This function is optimized to reduce gas cost due to payment from or to the user and that expensive calls
    /// or computations (like `oracleValue`) are done only once
    /// @dev When specifying `vaultID` in `data`, it is important to know that if you specify `vaultID = 0`, it will simply
    /// use the latest `vaultID`. This is the default behavior, and unless you're engaging into some complex protocol actions
    /// it is encouraged to use `vaultID = 0` only when the first action of the batch is `createVault`
    function angle(
        ActionType[] memory actions,
        bytes[] memory datas,
        address from,
        address to,
        address who,
        bytes memory repayData
    ) external returns (PaymentData memory paymentData);

    /// @notice This function is a wrapper built on top of the function above. It enables users to interact with the contract
    /// without having to provide `who` and `repayData` parameters
    function angle(
        ActionType[] memory actions,
        bytes[] memory datas,
        address from,
        address to
    ) external returns (PaymentData memory paymentData);

    /// @notice Initializes the `VaultManager` contract
    /// @param _treasury Treasury address handling the contract
    /// @param _collateral Collateral supported by this contract
    /// @param _oracle Oracle contract used
    /// @param _symbol Symbol used to define the `VaultManager` name and symbol
    /// @dev The parameters and the oracle are the only elements which could be modified once the
    /// contract has been initialized
    /// @dev For the contract to be fully initialized, governance needs to set the parameters for the liquidation
    /// boost
    function initialize(
        ITreasury _treasury,
        IERC20 _collateral,
        IOracle _oracle,
        VaultParameters calldata params,
        string memory _symbol
    ) external;
}

/// @title IVaultManagerStorage
/// @author Angle Labs, Inc.
/// @notice Interface for the `VaultManager` contract
/// @dev This interface contains getters of the contract's public variables used by other contracts
/// of this module
interface IVaultManagerStorage {
    /// @notice Minimum amount of debt a vault can have, expressed in `BASE_TOKENS` that is to say the base of the agTokens
    function dust() external view returns (uint256);

    /// @notice Encodes the maximum ratio stablecoin/collateral a vault can have before being liquidated. It's what
    /// determines the minimum collateral ratio of a position
    function collateralFactor() external view returns (uint64);

    /// @notice Stablecoin handled by this contract. Another `VaultManager` contract could have
    /// the same rights as this `VaultManager` on the stablecoin contract
    function stablecoin() external view returns (IAgToken);

    /// @notice Reference to the `treasury` contract handling this `VaultManager`
    function treasury() external view returns (ITreasury);

    /// @notice Oracle contract to get access to the price of the collateral with respect to the stablecoin
    function oracle() external view returns (IOracle);

    /// @notice The `interestAccumulator` variable keeps track of the interest that should accrue to the protocol.
    /// The stored value is not necessarily the true value: this one is recomputed every time an action takes place
    /// within the protocol. It is in base `BASE_INTEREST`
    function interestAccumulator() external view returns (uint256);

    /// @notice Reference to the collateral handled by this `VaultManager`
    function collateral() external view returns (IERC20);

    /// @notice Total normalized amount of stablecoins borrowed, not taking into account the potential bad debt accumulated
    /// This value is expressed in the base of Angle stablecoins (`BASE_TOKENS = 10**18`)
    function totalNormalizedDebt() external view returns (uint256);

    /// @notice Maximum amount of stablecoins that can be issued with this contract. It is expressed in `BASE_TOKENS`
    function debtCeiling() external view returns (uint256);

    /// @notice Maps a `vaultID` to its data (namely collateral amount and normalized debt)
    function vaultData(uint256 vaultID) external view returns (uint256 collateralAmount, uint256 normalizedDebt);

    /// @notice ID of the last vault created. The `vaultIDCount` variables serves as a counter to generate a unique
    /// `vaultID` for each vault: it is like `tokenID` in basic ERC721 contracts
    function vaultIDCount() external view returns (uint256);
}

/// @title IVaultManager
/// @author Angle Labs, Inc.
/// @notice Interface for the `VaultManager` contract
interface IVaultManager is IVaultManagerFunctions, IVaultManagerStorage, IERC721Metadata {
    function isApprovedOrOwner(address spender, uint256 vaultID) external view returns (bool);
}

/// @title IVaultManagerListing
/// @author Angle Labs, Inc.
/// @notice Interface for the `VaultManagerListing` contract
interface IVaultManagerListing is IVaultManager {
    /// @notice Get the collateral owned by `user` in the contract
    /// @dev This function effectively sums the collateral amounts of all the vaults owned by `user`
    function getUserCollateral(address user) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

/// @title IAgTokenMainnet
/// @author Angle Labs, Inc.
interface IAgTokenMainnet {
    function stableMaster() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

/// @title ICore
/// @author Angle Labs, Inc.
interface ICore {
    function stablecoinList() external view returns (address[] memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

/// @title IOracleCore
/// @author Angle Labs, Inc.
interface IOracleCore {
    function readUpper() external view returns (uint256);

    function readQuoteLower(uint256 baseAmount) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

/// @title IPerpetualManager
/// @author Angle Labs, Inc.
interface IPerpetualManager {
    function totalHedgeAmount() external view returns (uint256);

    function maintenanceMargin() external view returns (uint64);

    function maxLeverage() external view returns (uint64);

    function targetHAHedge() external view returns (uint64);

    function limitHAHedge() external view returns (uint64);

    function lockTime() external view returns (uint64);

    function haBonusMalusDeposit() external view returns (uint64);

    function haBonusMalusWithdraw() external view returns (uint64);

    function xHAFeesDeposit(uint256) external view returns (uint64);

    function yHAFeesDeposit(uint256) external view returns (uint64);

    function xHAFeesWithdraw(uint256) external view returns (uint64);

    function yHAFeesWithdraw(uint256) external view returns (uint64);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

/// @title IPoolManager
/// @author Angle Labs, Inc.
interface IPoolManager {
    function feeManager() external view returns (address);

    function strategyList(uint256) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "./IPerpetualManager.sol";
import "./IOracleCore.sol";

// Struct to handle all the parameters to manage the fees
// related to a given collateral pool (associated to the stablecoin)
struct MintBurnData {
    // Values of the thresholds to compute the minting fees
    // depending on HA hedge (scaled by `BASE_PARAMS`)
    uint64[] xFeeMint;
    // Values of the fees at thresholds (scaled by `BASE_PARAMS`)
    uint64[] yFeeMint;
    // Values of the thresholds to compute the burning fees
    // depending on HA hedge (scaled by `BASE_PARAMS`)
    uint64[] xFeeBurn;
    // Values of the fees at thresholds (scaled by `BASE_PARAMS`)
    uint64[] yFeeBurn;
    // Max proportion of collateral from users that can be covered by HAs
    // It is exactly the same as the parameter of the same name in `PerpetualManager`, whenever one is updated
    // the other changes accordingly
    uint64 targetHAHedge;
    // Minting fees correction set by the `FeeManager` contract: they are going to be multiplied
    // to the value of the fees computed using the hedge curve
    // Scaled by `BASE_PARAMS`
    uint64 bonusMalusMint;
    // Burning fees correction set by the `FeeManager` contract: they are going to be multiplied
    // to the value of the fees computed using the hedge curve
    // Scaled by `BASE_PARAMS`
    uint64 bonusMalusBurn;
    // Parameter used to limit the number of stablecoins that can be issued using the concerned collateral
    uint256 capOnStableMinted;
}

// Struct to handle all the variables and parameters to handle SLPs in the protocol
// including the fraction of interests they receive or the fees to be distributed to
// them
struct SLPData {
    // Last timestamp at which the `sanRate` has been updated for SLPs
    uint256 lastBlockUpdated;
    // Fees accumulated from previous blocks and to be distributed to SLPs
    uint256 lockedInterests;
    // Max interests used to update the `sanRate` in a single block
    // Should be in collateral token base
    uint256 maxInterestsDistributed;
    // Amount of fees left aside for SLPs and that will be distributed
    // when the protocol is collateralized back again
    uint256 feesAside;
    // Part of the fees normally going to SLPs that is left aside
    // before the protocol is collateralized back again (depends on collateral ratio)
    // Updated by keepers and scaled by `BASE_PARAMS`
    uint64 slippageFee;
    // Portion of the fees from users minting and burning
    // that goes to SLPs (the rest goes to surplus)
    uint64 feesForSLPs;
    // Slippage factor that's applied to SLPs exiting (depends on collateral ratio)
    // If `slippage = BASE_PARAMS`, SLPs can get nothing, if `slippage = 0` they get their full claim
    // Updated by keepers and scaled by `BASE_PARAMS`
    uint64 slippage;
    // Portion of the interests from lending
    // that goes to SLPs (the rest goes to surplus)
    uint64 interestsForSLPs;
}

/// @title IStableMaster
/// @author Angle Labs, Inc.
interface IStableMaster {
    function agToken() external view returns (address);

    function updateStocksUsers(uint256 amount, address poolManager) external;

    function collateralMap(address poolManager)
        external
        view
        returns (
            address token,
            address sanToken,
            IPerpetualManager perpetualManager,
            IOracleCore oracle,
            uint256 stocksUsers,
            uint256 sanRate,
            uint256 collatBase,
            SLPData memory slpData,
            MintBurnData memory feeData
        );

    function paused(bytes32) external view returns (bool);

    function deposit(
        uint256 amount,
        address user,
        address poolManager
    ) external;

    function withdraw(
        uint256 amount,
        address burner,
        address dest,
        address poolManager
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IVaultManager.sol";

pragma solidity 0.8.12;

/// @title AngleBorrowHelpers
/// @author Angle Labs, Inc.
/// @notice Contract with view functions designed to facilitate integrations on the Borrow module of the Angle Protocol
/// @dev This contract only contains view functions to be queried off-chain. It was thus not optimized for gas consumption
contract AngleBorrowHelpers is Initializable {
    /// @notice Returns all the vaults owned or controlled (under the form of approval) by an address
    /// @param vaultManager VaultManager address to query vaultIDs on
    /// @param spender Address for which vault ownerships should be checked
    /// @return List of `vaultID` controlled by this address
    /// @return Count of vaults owned by the address
    /// @dev This function is never to be called on-chain since it iterates over all vaultIDs. It is here
    /// to reduce dependency on an external graph to link an ID to its owner
    function getControlledVaults(IVaultManager vaultManager, address spender)
        external
        view
        returns (uint256[] memory, uint256)
    {
        uint256 arraySize = vaultManager.vaultIDCount();
        uint256[] memory vaultsControlled = new uint256[](arraySize);
        uint256 count;
        for (uint256 i = 1; i <= arraySize; i++) {
            try vaultManager.isApprovedOrOwner(spender, i) returns (bool _isApprovedOrOwner) {
                if (_isApprovedOrOwner) {
                    vaultsControlled[count] = i;
                    count += 1;
                }
            } catch {
                continue;
            } // This happens if nobody owns the vaultID=i (if there has been a burn)
        }
        return (vaultsControlled, count);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}
}

// SPDX-License-Identifier: GPL-3.0

import "../interfaces/IAngleRouter.sol";
import "../interfaces/coreModule/IAgTokenMainnet.sol";
import "../interfaces/coreModule/ICore.sol";
import "../interfaces/coreModule/IOracleCore.sol";
import "../interfaces/coreModule/IPerpetualManager.sol";
import "../interfaces/coreModule/IPoolManager.sol";
import "../interfaces/coreModule/IStableMaster.sol";
import "./AngleBorrowHelpers.sol";

pragma solidity 0.8.12;

struct Parameters {
    SLPData slpData;
    MintBurnData feeData;
    PerpetualManagerFeeData perpFeeData;
    PerpetualManagerParamData perpParam;
}

struct PerpetualManagerFeeData {
    uint64[] xHAFeesDeposit;
    uint64[] yHAFeesDeposit;
    uint64[] xHAFeesWithdraw;
    uint64[] yHAFeesWithdraw;
    uint64 haBonusMalusDeposit;
    uint64 haBonusMalusWithdraw;
}

struct PerpetualManagerParamData {
    uint64 maintenanceMargin;
    uint64 maxLeverage;
    uint64 targetHAHedge;
    uint64 limitHAHedge;
    uint64 lockTime;
}

struct CollateralAddresses {
    address stableMaster;
    address poolManager;
    address perpetualManager;
    address sanToken;
    address oracle;
    address gauge;
    address feeManager;
    address[] strategies;
}

/// @title AngleHelpers
/// @author Angle Labs, Inc.
/// @notice Contract with view functions designed to facilitate integrations on the Core and Borrow module of the Angle Protocol
/// @dev This contract only contains view functions to be queried off-chain. It was thus not optimized for gas consumption
contract AngleHelpers is AngleBorrowHelpers {
    // =========================== HELPER VIEW FUNCTIONS ===========================

    /// @notice Gives the amount of `agToken` you'd be getting if you were executing in the same block a mint transaction
    /// with `amount` of `collateral` in the Core module of the Angle protocol as well as the value of the fees
    /// (in `BASE_PARAMS`) that would be applied during the mint
    /// @return Amount of `agToken` that would be obtained with a mint transaction in the same block
    /// @return Percentage of fees that would be taken during a mint transaction in the same block
    /// @dev This function reverts if the mint transaction was to revert in the same conditions (without taking into account
    /// potential approval problems to the `StableMaster` contract)
    function previewMintAndFees(
        uint256 amount,
        address agToken,
        address collateral
    ) external view returns (uint256, uint256) {
        return _previewMintAndFees(amount, agToken, collateral);
    }

    /// @notice Gives the amount of `collateral` you'd be getting if you were executing in the same block a burn transaction
    ///  with `amount` of `agToken` in the Core module of the Angle protocol as well as the value of the fees
    /// (in `BASE_PARAMS`) that would be applied during the burn
    /// @return Amount of `collateral` that would be obtained with a burn transaction in the same block
    /// @return Percentage of fees that would be taken during a burn transaction in the same block
    /// @dev This function reverts if the burn transaction was to revert in the same conditions (without taking into account
    /// potential approval problems to the `StableMaster` contract or agToken balance prior to the call)
    function previewBurnAndFees(
        uint256 amount,
        address agToken,
        address collateral
    ) external view returns (uint256, uint256) {
        return _previewBurnAndFees(amount, agToken, collateral);
    }

    /// @notice Returns all the addresses associated to the (`agToken`,`collateral`) pair given
    /// @return addresses A struct with all the addresses associated in the Core module
    function getCollateralAddresses(address agToken, address collateral)
        external
        view
        returns (CollateralAddresses memory addresses)
    {
        address stableMaster = IAgTokenMainnet(agToken).stableMaster();
        (address poolManager, address perpetualManager, address sanToken, address gauge) = ROUTER.mapPoolManagers(
            stableMaster,
            collateral
        );
        (, , , IOracleCore oracle, , , , , ) = IStableMaster(stableMaster).collateralMap(poolManager);
        addresses.stableMaster = stableMaster;
        addresses.poolManager = poolManager;
        addresses.perpetualManager = perpetualManager;
        addresses.sanToken = sanToken;
        addresses.gauge = gauge;
        addresses.oracle = address(oracle);
        addresses.feeManager = IPoolManager(poolManager).feeManager();

        uint256 length = 0;
        while (true) {
            try IPoolManager(poolManager).strategyList(length) returns (address) {
                length += 1;
            } catch {
                break;
            }
        }
        address[] memory strategies = new address[](length);
        for (uint256 i = 0; i < length; ++i) {
            strategies[i] = IPoolManager(poolManager).strategyList(i);
        }
        addresses.strategies = strategies;
    }

    /// @notice Gets the addresses of all the `StableMaster` contracts and their associated `AgToken` addresses
    /// @return List of the `StableMaster` addresses of the Angle protocol
    /// @return List of the `AgToken` addresses of the protocol
    /// @dev The place of an agToken address in the list is the same as the corresponding `StableMaster` address
    function getStablecoinAddresses() external view returns (address[] memory, address[] memory) {
        address[] memory stableMasterAddresses = CORE.stablecoinList();
        address[] memory agTokenAddresses = new address[](stableMasterAddresses.length);
        for (uint256 i = 0; i < stableMasterAddresses.length; ++i) {
            agTokenAddresses[i] = IStableMaster(stableMasterAddresses[i]).agToken();
        }
        return (stableMasterAddresses, agTokenAddresses);
    }

    /// @notice Returns most of the governance parameters associated to the (`agToken`,`collateral`) pair given
    /// @return params Struct with most of the parameters in the `StableMaster` and `PerpetualManager` contracts
    /// @dev Check out the struct `Parameters` for the meaning of the return values
    function getCollateralParameters(address agToken, address collateral)
        external
        view
        returns (Parameters memory params)
    {
        (address stableMaster, address poolManager) = _getStableMasterAndPoolManager(agToken, collateral);
        (
            ,
            ,
            IPerpetualManager perpetualManager,
            ,
            ,
            ,
            ,
            SLPData memory slpData,
            MintBurnData memory feeData
        ) = IStableMaster(stableMaster).collateralMap(poolManager);

        params.slpData = slpData;
        params.feeData = feeData;
        params.perpParam.maintenanceMargin = perpetualManager.maintenanceMargin();
        params.perpParam.maxLeverage = perpetualManager.maxLeverage();
        params.perpParam.targetHAHedge = perpetualManager.targetHAHedge();
        params.perpParam.limitHAHedge = perpetualManager.limitHAHedge();
        params.perpParam.lockTime = perpetualManager.lockTime();

        params.perpFeeData.haBonusMalusDeposit = perpetualManager.haBonusMalusDeposit();
        params.perpFeeData.haBonusMalusWithdraw = perpetualManager.haBonusMalusWithdraw();

        uint256 length = 0;
        while (true) {
            try perpetualManager.xHAFeesDeposit(length) returns (uint64) {
                length += 1;
            } catch {
                break;
            }
        }
        uint64[] memory data = new uint64[](length);
        uint64[] memory data2 = new uint64[](length);
        for (uint256 i = 0; i < length; ++i) {
            data[i] = perpetualManager.xHAFeesDeposit(i);
            data2[i] = perpetualManager.yHAFeesDeposit(i);
        }
        params.perpFeeData.xHAFeesDeposit = data;
        params.perpFeeData.yHAFeesDeposit = data2;

        length = 0;
        while (true) {
            try perpetualManager.xHAFeesWithdraw(length) returns (uint64) {
                length += 1;
            } catch {
                break;
            }
        }
        data = new uint64[](length);
        data2 = new uint64[](length);
        for (uint256 i = 0; i < length; ++i) {
            data[i] = perpetualManager.xHAFeesWithdraw(i);
            data2[i] = perpetualManager.yHAFeesWithdraw(i);
        }
        params.perpFeeData.xHAFeesWithdraw = data;
        params.perpFeeData.yHAFeesWithdraw = data2;
    }

    /// @notice Returns the address of the poolManager associated to an (`agToken`, `collateral`) pair
    /// in the Core module of the protocol
    function getPoolManager(address agToken, address collateral) public view returns (address poolManager) {
        (, poolManager) = _getStableMasterAndPoolManager(agToken, collateral);
    }

    // ============================= REPLICA FUNCTIONS =============================
    // These replicate what is done in the other contracts of the protocol

    function _previewBurnAndFees(
        uint256 amount,
        address agToken,
        address collateral
    ) internal view returns (uint256 amountForUserInCollat, uint256 feePercent) {
        (address stableMaster, address poolManager) = _getStableMasterAndPoolManager(agToken, collateral);
        (
            address token,
            ,
            IPerpetualManager perpetualManager,
            IOracleCore oracle,
            uint256 stocksUsers,
            ,
            uint256 collatBase,
            ,
            MintBurnData memory feeData
        ) = IStableMaster(stableMaster).collateralMap(poolManager);
        if (token == address(0) || IStableMaster(stableMaster).paused(keccak256(abi.encodePacked(STABLE, poolManager))))
            revert NotInitialized();
        if (amount > stocksUsers) revert InvalidAmount();

        if (feeData.xFeeBurn.length == 1) {
            feePercent = feeData.yFeeBurn[0];
        } else {
            bytes memory data = abi.encode(address(perpetualManager), feeData.targetHAHedge);
            uint64 hedgeRatio = _computeHedgeRatio(stocksUsers - amount, data);
            feePercent = _piecewiseLinear(hedgeRatio, feeData.xFeeBurn, feeData.yFeeBurn);
        }
        feePercent = (feePercent * feeData.bonusMalusBurn) / BASE_PARAMS;

        amountForUserInCollat = (amount * (BASE_PARAMS - feePercent) * collatBase) / (oracle.readUpper() * BASE_PARAMS);
    }

    function _previewMintAndFees(
        uint256 amount,
        address agToken,
        address collateral
    ) internal view returns (uint256 amountForUserInStable, uint256 feePercent) {
        (address stableMaster, address poolManager) = _getStableMasterAndPoolManager(agToken, collateral);
        (
            address token,
            ,
            IPerpetualManager perpetualManager,
            IOracleCore oracle,
            uint256 stocksUsers,
            ,
            ,
            ,
            MintBurnData memory feeData
        ) = IStableMaster(stableMaster).collateralMap(poolManager);
        if (token == address(0) || IStableMaster(stableMaster).paused(keccak256(abi.encodePacked(STABLE, poolManager))))
            revert NotInitialized();

        amountForUserInStable = oracle.readQuoteLower(amount);

        if (feeData.xFeeMint.length == 1) feePercent = feeData.yFeeMint[0];
        else {
            bytes memory data = abi.encode(address(perpetualManager), feeData.targetHAHedge);
            uint64 hedgeRatio = _computeHedgeRatio(amountForUserInStable + stocksUsers, data);
            feePercent = _piecewiseLinear(hedgeRatio, feeData.xFeeMint, feeData.yFeeMint);
        }
        feePercent = (feePercent * feeData.bonusMalusMint) / BASE_PARAMS;

        amountForUserInStable = (amountForUserInStable * (BASE_PARAMS - feePercent)) / BASE_PARAMS;
        if (stocksUsers + amountForUserInStable > feeData.capOnStableMinted) revert InvalidAmount();
    }

    // ============================= UTILITY FUNCTIONS =============================
    // These utility functions are taken from other contracts of the protocol

    function _computeHedgeRatio(uint256 newStocksUsers, bytes memory data) internal view returns (uint64 ratio) {
        (address perpetualManager, uint64 targetHAHedge) = abi.decode(data, (address, uint64));
        uint256 totalHedgeAmount = IPerpetualManager(perpetualManager).totalHedgeAmount();
        newStocksUsers = (targetHAHedge * newStocksUsers) / BASE_PARAMS;
        if (newStocksUsers > totalHedgeAmount) ratio = uint64((totalHedgeAmount * BASE_PARAMS) / newStocksUsers);
        else ratio = uint64(BASE_PARAMS);
    }

    function _piecewiseLinear(
        uint64 x,
        uint64[] memory xArray,
        uint64[] memory yArray
    ) internal pure returns (uint64) {
        if (x >= xArray[xArray.length - 1]) {
            return yArray[xArray.length - 1];
        } else if (x <= xArray[0]) {
            return yArray[0];
        } else {
            uint256 lower;
            uint256 upper = xArray.length - 1;
            uint256 mid;
            while (upper - lower > 1) {
                mid = lower + (upper - lower) / 2;
                if (xArray[mid] <= x) {
                    lower = mid;
                } else {
                    upper = mid;
                }
            }
            if (yArray[upper] > yArray[lower]) {
                return
                    yArray[lower] +
                    ((yArray[upper] - yArray[lower]) * (x - xArray[lower])) /
                    (xArray[upper] - xArray[lower]);
            } else {
                return
                    yArray[lower] -
                    ((yArray[lower] - yArray[upper]) * (x - xArray[lower])) /
                    (xArray[upper] - xArray[lower]);
            }
        }
    }

    function _getStableMasterAndPoolManager(address agToken, address collateral)
        internal
        view
        returns (address stableMaster, address poolManager)
    {
        stableMaster = IAgTokenMainnet(agToken).stableMaster();
        (poolManager, , , ) = ROUTER.mapPoolManagers(stableMaster, collateral);
    }

    // ========================= CONSTANTS AND INITIALIZERS ========================

    IAngleRouter public constant ROUTER = IAngleRouter(0xBB755240596530be0c1DE5DFD77ec6398471561d);
    ICore public constant CORE = ICore(0x61ed74de9Ca5796cF2F8fD60D54160D47E30B7c3);

    bytes32 public constant STABLE = keccak256("STABLE");
    uint256 public constant BASE_PARAMS = 10**9;

    error NotInitialized();
    error InvalidAmount();
}