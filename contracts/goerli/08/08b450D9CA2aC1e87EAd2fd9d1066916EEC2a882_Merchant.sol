/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: witch_merchant/contracts/Merchant.sol


pragma solidity 0.8.16;





// 함수명 통합에 관한 고찰 
// 1. 일반적으로 ether, erc20, erc721, erc1155 등 여러종류가 사용되는 경우엔 명시적으로 표현
// approveERC20, approveNFT 에서 nft는 721이나 1155나 둘다 setApprovalForAll 쓰니까 nft로 뭉뚱그려서 사용
// 단 token을 사용하는 경우는 없었음 why? erc20, erc721, erc1155 다 token이라서 그런듯
// 2. NFT, nft, Token, TK 같은 경우 
// 함수명에 약어로 드가는 경우 camel case에선 nft or NFT 사용 Nft 없음
// TK 사용하는 경우는 예시가 없었다.

contract Merchant is ERC721Holder, Initializable {
  address private admin;
  uint256 public ERC20WithdrawReportCount;    // 출금횟수 기록. (0)
  uint256 public ERC721WithdrawReportCount;   // 출금횟수 기록. (0)
  bool public lock;                           // 전체잠금 (false)
  bool public lock_ERC721_to_ERC20;           // ERC721 -> ERC20 Lock (false)
  bool public lock_ERC20_to_ERC721;           // ERC20 -> ERC721 Lock (false)
  uint256 public commission_ERC721_to_ERC20;  // 10000 == 100% (0)
  uint256 public commission_ERC20_to_ERC721;  // 10000 == 100% (0)

  // constructor() {
  //   admin = msg.sender;
  // }
  function initialize() public initializer {
    admin = msg.sender;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin, "Not authorized");
    _;
  }

  modifier mutex() {
    require(!lock, "Currently Locked All");
    lock = true;
    _;
    lock = false;
  }

  modifier swapERC20toERC721Mutex() { 
    require(!lock_ERC20_to_ERC721, "Currently Locked");
    lock_ERC20_to_ERC721 = true;
    _;
    lock_ERC20_to_ERC721 = false;
  }

  modifier swapERC721toERC20Mutex() { 
    require(!lock_ERC721_to_ERC20, "Currently Locked");
    lock_ERC721_to_ERC20 = true;
    _;
    lock_ERC721_to_ERC20 = false;
  }

  // =============================================================
  //                      Data Stored Structure
  // ============================================================= 

  mapping(address => bool) public ERC20WhiteList;
  mapping(address => bool) public ERC721WhiteList;
  mapping(address => mapping(address => mapping(uint256 => uint256))) public priceList;  // [NFTAdrs][tokenAdrs][tokenId] => Price;

  // =============================================================
  //                      Event
  // =============================================================
  
  // ERC 20 출금 이벤트
  event WithdrawERC20 (
    uint256 indexed idx,
    address indexed ERC20Address,
    uint256 amountOut,
    uint256 timestamp,
    address indexed txCaller
  );

  // ERC 721 출금 이벤트
  event WithdrawERC721 (
    uint256 indexed idx,
    address indexed ERC721Address,
    uint256[] tokenIds,
    uint256 timestamp,
    address indexed txCaller
  );

  // 스왑 이벤트
  event Swap (
    uint256 indexed swapType, 
    address ERC20Address,
    address indexed ERC721Address,
    uint256[] amountIn, 
    uint256[] amountOut,
    uint256 timestamp,
    address indexed txCaller
  );

  // =============================================================
  //                       Swap 기능
  // ============================================================= 
  // [Feat : 스왑 (Token -> NFT)] Tx-Caller : Anyone; ✅
  // SWP_TK_TO_NFT -> swapTokenToNFT or swapERC20ToERC721
  function swapERC20ToERC721(address _tkAddr, address _nftAddr, uint256[] memory _tokenIds) mutex swapERC20toERC721Mutex external {
    // @ Checks
    require(ERC20WhiteList[_tkAddr], "Unlisted For Sale");
    require(ERC721WhiteList[_nftAddr], "Unlisted For Sale");

    // @ Interaction
    uint256 totalPrice = 0;
    uint256 index = _tokenIds.length;
    
    for(uint256 i=0; i < index;) {
      require(priceList[_nftAddr][_tkAddr][_tokenIds[i]] != 0, "Not for Sale");
      totalPrice += priceList[_nftAddr][_tkAddr][_tokenIds[i]];
      IERC721(_nftAddr).safeTransferFrom(address(this), msg.sender, _tokenIds[i]);
      unchecked {
        i+=1;
      }
    }

    totalPrice += (totalPrice * commission_ERC20_to_ERC721) / 10000;

    uint256[] memory _totalPrice = new uint256[](1);
    _totalPrice[0] = totalPrice;

    // 수수료 + 가격 차감 으로 진행?
    require(IERC20(_tkAddr).transferFrom(msg.sender, address(this), totalPrice), "Not Enough Balance");
    
    emit Swap (
      0,
      _tkAddr,
      _nftAddr,
      _totalPrice,
      _tokenIds,
      block.timestamp,
      msg.sender
    );
  }

  // [Feat : 스왑 (NFT -> Token)] Tx-Caller : Anyone; ✅
  // SWP_NFT_TO_TK -> swapNFTToToken or swapER721ToERC20
  function swapERC721ToERC20(address _tkAddr, address _nftAddr, uint256[] memory _tokenIds) mutex swapERC721toERC20Mutex external {
    // @Checks
    require(ERC721WhiteList[_nftAddr], "Unlisted For Sale");
    require(ERC20WhiteList[_tkAddr], "Unlisted For Sale");

    // 1. NFT Batch Deposit 진행; NFT를 받는다. 단일 입금도 가능하며, Batch 입금도 가능하다.
    uint256 totalPrice = 0; // 1
    uint256 index = _tokenIds.length;

    for(uint256 i=0; i < index;) {
      require(priceList[_nftAddr][_tkAddr][_tokenIds[i]] != 0, "Not for Sale");
      totalPrice += priceList[_nftAddr][_tkAddr][_tokenIds[i]];
      // Transfer ERC721 (MSG.SENDER -> Merchant)
      IERC721(_nftAddr).safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
      unchecked {
        i+=1;
      }
    }

    totalPrice -= (totalPrice * commission_ERC721_to_ERC20) / 10000;
    // Transfer ERC 20 (Merchant -> Msg.sender);
    require(IERC20(_tkAddr).transfer(msg.sender, totalPrice), "Not Enough Balance");
    
    // 3. 이벤트 발생.
    uint256[] memory _totalPrice = new uint256[](1);
    _totalPrice[0] = totalPrice;

    emit Swap(
      1,
      _tkAddr,
      _nftAddr,
      _tokenIds,
      _totalPrice,
      block.timestamp,
      msg.sender
    );
  }

  // =============================================================
  //                      ERC - 20
  // ============================================================= 
  
  // [Feat : ERC-20 출금] Tx Caller : Admin; ✅ 전체출금 시, AmountOut에 0을 주세요!
  // WITHDRAW_TK -> withdrawToken or withdrawERC20
  function withdrawERC20(address _tokenAddr, uint256 _amountOut) onlyAdmin mutex external {
    // @Checks
    ERC20WithdrawReportCount++;

    uint256 balance = IERC20(_tokenAddr).balanceOf(address(this)); 
    require(balance >= _amountOut, "Not Enough Balance");

    // @Interaction
    // 전체출금 시, 동작
    if(_amountOut == 0) {
      require(IERC20(_tokenAddr).transfer(admin, balance), "Failed to Transfer");
    }

    // 부분출금 시, 동작
    require(IERC20(_tokenAddr).transfer(admin, _amountOut), "Not Enough Balance");
 
    emit WithdrawERC20(
      ERC20WithdrawReportCount,
      _tokenAddr,
      _amountOut,
      block.timestamp,
      msg.sender
    );
  }

  // =============================================================
  //                      ERC - 721
  // ============================================================= 
  bytes4 private constant MINT = bytes4(keccak256(bytes("mint(address,uint256)")));

  // [Feat : 치치 NFT 빼오는 함수] Tx-Caller : Admin; ✅
  // MINT_NFT -> mint or mintERC721 
  function mintERC721(address _nftAddr, uint256 _amount) onlyAdmin external {
    // if (_nftAddr.code.length == 0) revert NoContract(_nftAddr);
    require(_nftAddr.code.length != 0, "Not Valid Address");
    require(ERC721WhiteList[_nftAddr], "Unlisted For Sale"); // 얘 에러 메세지 통합

    (bool ok, bytes memory data) = _nftAddr.call(abi.encodeWithSelector(MINT, address(this), _amount));
    
    // if (!ok) revert TokenMintGenericFailure(_nftAddr, address(this), _amount);
    require(ok, "Fail To Mint ERC721s");
    if (data.length != 0 && data.length >= 32) {
      // if(!abi.decode(data, (bool))) revert BadReturnValueFromERC721Mint(_nftAddr, address(this), _amount);
      require(abi.decode(data, (bool)), "Fail To Mint ERC721s");
    }
  }

  // =============================================================
  //                      ETC
  // ============================================================= 
  // 🛠 [Feat : 단일 가격조회] 개별 가격 조회; Tx-Caller : AnyOne; ✅
  // PRICE_NFT -> getPrice
  function getPrice(address _nftAddr, address _tokenAddr, uint256 _tokenId) external view returns (uint256) {
    return priceList[_nftAddr][_tokenAddr][_tokenId];
  }

  // 🛠 [Feat : 대량 가격 조회]; Tx-Caller : AnyOne; ✅
  // PRICE_NFTS -> getPrices
  function getPrices(address _nftAddr, address _tokenAddr, uint256 _stIdx, uint256 _edIdx) public view returns(uint256[] memory) {
    uint256[] memory prices = new uint256[](_edIdx);

    for (uint256 i = 0; i < _edIdx; i++) {
        prices[i] = priceList[_nftAddr][_tokenAddr][_stIdx + i];
    }

    return prices;
  }

  // =============================================================
  //                      운영자 전용함수
  // ============================================================= 
  // [Feat : WITHDRAW_NFT] Tx Caller : Admin; ✅
  // WITHDRAW_NFT -> withdrawERC721
  function withdrawERC721(address _nftAddr, uint256[] memory tokenIds) onlyAdmin external {
    // @Interaction
    ERC721WithdrawReportCount++;

    uint256 index = tokenIds.length;
    for(uint256 i=0; i < index;) {
      IERC721(_nftAddr).safeTransferFrom(address(this), msg.sender, tokenIds[i]);
      unchecked {
        i+=1;
      }
    }
   
    emit WithdrawERC721(
      ERC721WithdrawReportCount,
      _nftAddr,
      tokenIds,
      block.timestamp,
      msg.sender
    );
  }

  // [Feat : ERC-721 개별 가격설정] Tx-Caller : Admin; ✅
  // SET_PRICE -> setPrice
  function setPrice(address _nftAddr, address _tokenAddr, uint256 _tokenId, uint256 _price) onlyAdmin external {
    priceList[_nftAddr][_tokenAddr][_tokenId] = _price;
  }

  // [Feat : ERC-721 대량 가격설정] Tx-Caller : Admin; ✅
  // SET_PRICES -> setPrices
  function setPrices(address _nftAddr, address _tokenAddr, uint256 _stIdx, uint256 _edIdx, uint256 _price) onlyAdmin external {
    for(uint256 i=_stIdx; i <= _edIdx; i++){
      priceList[_nftAddr][_tokenAddr][i] = _price;
    }
  }

  // 🛠 [Feat : Token WhiteList 추가] Tx Caller : Admin; ✅
  // ADDLIST_TK -> addTokenList
  function addERC20List(address _tokenAddr) onlyAdmin external {
    ERC20WhiteList[_tokenAddr] = !ERC20WhiteList[_tokenAddr];
  }

  // [Feat : NFT WhiteList 추가] Tx Caller : Admin; ✅
  // ADDLIST_NFT -> addERC721List
  function addERC721List(address _nftAddr) onlyAdmin external {
    ERC721WhiteList[_nftAddr] = !ERC721WhiteList[_nftAddr];
  }

  // [Feat : NFT -> Witch Swap 함수 수수료 설정 (MAX : 10000)] Tx Caller : Admin; ✅
  // SET_COMMISSION_NFT_TO_TK -> setCommissionERC721ToERC20
  function setCommissionERC721ToERC20(uint256 _newCommission) onlyAdmin external {
    require(_newCommission <= 10000, "Only can 0 to 10000");
    commission_ERC721_to_ERC20 = _newCommission;
  }

  // [Feat : Witch -> NFT Swap 함수 수수료 설정 (MAX : 10000)] Tx Caller : Admin; ✅
  // SET_COMMISSION_TK_TO_NFT -> setCommissionTokenToERC721
  function setCommissionERC20ToERC721(uint256 _newCommission) onlyAdmin external {
    // must be less than 100%. or Failed to change commission
    require(_newCommission <= 10000, "Only can 0 to 10000"); // Comission cannot exceed 100%
    commission_ERC20_to_ERC721 = _newCommission;
  }

  // [Feat : NFT -> Witch Swap 잠금기능] Tx Caller : Admin; ✅
  // SET_LOCK_NFT_TO_TK -> setLockERC721ToTokenSwap
  function setLockERC721ToERC20Swap() onlyAdmin external {
    lock_ERC721_to_ERC20 = !lock_ERC721_to_ERC20;
  }

  // [Feat : SET_LOCK_TK_TO_NFT 단일 기능 잠금 함수] Tx Caller : Admin; ✅
  // SET_LOCK_TK_TO_NFT -> setLockTokenToERC721Swap
  function setLockERC20ToERC721Swap() onlyAdmin external {
    lock_ERC20_to_ERC721 = !lock_ERC20_to_ERC721;
  }
  
  // [Feat : transfer 관련 모든 기능 잠금 함수] Tx Caller : Admin; ✅
  // SET_LOCK_ALL -> setLockAll
  function setLockAll() onlyAdmin external {
    lock = !lock;
  }

  // =============================================================
  //                    Role OPERATIONS
  // =============================================================

  // [Feat : Admin 변경함수] Tx Caller : Admin; ✅
  // SET_NEW_ADMIN -> setNewAdmin or transferAdminRigths
  function setNewAdmin(address _newAdmin) onlyAdmin external {
    admin = _newAdmin;
  }
}