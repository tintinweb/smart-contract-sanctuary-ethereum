/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// File: contracts/libraries/LibAppStorage.sol


pragma solidity ^0.8.0;

struct AppStorage {
    string name;
    string symbol;
    uint8 decimals;
    string currency;
    uint256 totalSupply;
    bool paused;
    address blacklister;
    address pauser;
    address rescuer;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => bool) minters;
    mapping(address => uint256) minterAllowed;
    mapping(address => bool) blacklisted;
    mapping(address => uint256) permitNonces;
    mapping(address => mapping(bytes32 => bool)) _authorizationStates;
}

// File: contracts/interfaces/IDiamondCut.sol


pragma solidity ^0.8.0;

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// File: contracts/libraries/ECRecover.sol



pragma solidity ^0.8.0;

library ECRecover {
    function recover(
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert("Invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("Invalid signature 'v' value");
        }

        address signer = ecrecover(digest, v, r, s);
        require(signer != address(0), "Invalid signature");

        return signer;
    }
}

// File: contracts/libraries/EIP712.sol



pragma solidity ^0.8.0;


library EIP712 {
    event RecoverDebug(bytes data);
    event RecoverDebug32(bytes32 data);

    function recover(
        bytes32 domainSeparator,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes memory typeHashAndData
    ) internal pure returns (address) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(typeHashAndData)
            )
        );

        return ECRecover.recover(digest, v, r, s);
    }
}

// File: contracts/libraries/LibDiamond.sol


pragma solidity ^0.8.0;



library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        mapping(bytes4 => bytes32) facets;
        mapping(uint256 => bytes32) selectorSlots;
        uint16 selectorCount;
        mapping(bytes4 => bool) supportedInterfaces;
        address contractOwner;
        mapping(address => bool) isOwner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(
            msg.sender == diamondStorage().contractOwner,
            "Must be contract owner"
        );
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    bytes32 constant CLEAR_ADDRESS_MASK =
        bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        if (selectorCount & 7 > 0) {
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        if (selectorCount & 7 > 0) {
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(_selectors.length > 0, "No selectors in facet to cut");
        if (_action == IDiamondCut.FacetCutAction.Add) {
            enforceHasContractCode(_newFacetAddress, "Add facet has no code");
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(
                    address(bytes20(oldFacet)) == address(0),
                    "Can't add function that already exists"
                );
                ds.facets[selector] =
                    bytes20(_newFacetAddress) |
                    bytes32(_selectorCount);
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                _selectorSlot =
                    (_selectorSlot &
                        ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
                    (bytes32(selector) >> selectorInSlotPosition);
                if (selectorInSlotPosition == 224) {
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;
            }
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(
                _newFacetAddress,
                "Replace facet has no code"
            );
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                require(
                    oldFacetAddress != address(this),
                    "Can't replace immutable function"
                );
                require(
                    oldFacetAddress != _newFacetAddress,
                    "Can't replace function with same function"
                );
                require(
                    oldFacetAddress != address(0),
                    "Can't replace function that doesn't exist"
                );
                ds.facets[selector] =
                    (oldFacet & CLEAR_ADDRESS_MASK) |
                    bytes20(_newFacetAddress);
            }
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {
            require(
                _newFacetAddress == address(0),
                "Remove facet address must be address(0)"
            );
            uint256 selectorSlotCount = _selectorCount >> 3;
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                if (_selectorSlot == 0) {
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(
                        address(bytes20(oldFacet)) != address(0),
                        "Can't remove function that doesn't exist"
                    );
                    require(
                        address(bytes20(oldFacet)) != address(this),
                        "Can't remove immutable function"
                    );
                    lastSelector = bytes4(
                        _selectorSlot << (selectorInSlotIndex << 5)
                    );
                    if (lastSelector != selector) {
                        ds.facets[lastSelector] =
                            (oldFacet & CLEAR_ADDRESS_MASK) |
                            bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[
                        oldSelectorsSlotCount
                    ];
                    oldSelectorSlot =
                        (oldSelectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    _selectorSlot =
                        (_selectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "_init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "_calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(_init, "_init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    revert(string(error));
                } else {
                    revert("_init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// File: contracts/libraries/Address.sol


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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

// File: contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// File: contracts/libraries/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File: contracts/facets/TokenFacet.sol



pragma solidity ^0.8.0;






contract TokenFacet is IERC20 {
    AppStorage internal s;

    using SafeERC20 for IERC20;
    bool internal _initialized;

    event TokenSetup(
        address indexed initiator,
        string _name,
        string _token,
        uint8 decimals
    );
    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 amount);
    event MinterConfigured(address indexed minter, uint256 minterAllowedAmount);
    event MinterRemoved(address indexed oldMinter);

    bytes32 internal constant _DOMAIN_SEPARATOR =
        0xf235a3a1324700fca428abea7e3ccf9edb374d9c399878216a0ef4af02815cde;

    /* keccak256("Permit(address _owner,address _spender,uint256 _value,uint256 _nonce,uint256 _deadline)") */
    bytes32 internal constant _PERMIT_TYPEHASH =
        0x283ef5f1323e8965c0333bc5843eb0b8d7ffe23b9c2eab15c3e3ffcc75ae8134;

    /* keccak256("TransferWithAuthorization(address _from,address _to,uint256 _value,uint256 _validAfter,uint256 _validBefore,bytes32 _nonce)")*/
    bytes32 internal constant _TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
        0x310777934f929c98189a844bb5f21f2844db2a576625365b824861540a319f79;

    /* keccak256("ReceiveWithAuthorization(address _from,address _to,uint256 _value,uint256 _validAfter,uint256 _validBefore,bytes32 _nonce)")*/
    bytes32 internal constant _RECEIVE_WITH_AUTHORIZATION_TYPEHASH =
        0x58ac3df019d91fe0955489460a6a1c370bec91d993d7efbc0925fe3d403653eb;

    /* keccak256("CancelAuthorization(address _authorizer,bytes32 _nonce)")*/
    bytes32 internal constant _CANCEL_AUTHORIZATION_TYPEHASH =
        0xf523c75f846f1f78c4e7be3cf73d7e9c0b2a8d15cd65153faae8afa14f91c341;

    function name() external view returns (string memory name_) {
        name_ = s.name;
    }

    function symbol() external view returns (string memory symbol_) {
        symbol_ = s.symbol;
    }

    function decimals() external view returns (uint8 decimals_) {
        decimals_ = s.decimals;
    }

    function DOMAIN_SEPARATOR() external pure returns (bytes32 ds_) {
        ds_ = _DOMAIN_SEPARATOR;
    }

    function PERMIT_TYPEHASH() external pure returns (bytes32 pth_) {
        pth_ = _PERMIT_TYPEHASH;
    }

    function TRANSFER_WITH_AUTHORIZATION_TYPEHASH()
        external
        pure
        returns (bytes32 twath_)
    {
        twath_ = _TRANSFER_WITH_AUTHORIZATION_TYPEHASH;
    }

    function RECEIVE_WITH_AUTHORIZATION_TYPEHASH()
        external
        pure
        returns (bytes32 rwath_)
    {
        rwath_ = _RECEIVE_WITH_AUTHORIZATION_TYPEHASH;
    }

    function CANCEL_AUTHORIZATION_TYPEHASH()
        external
        pure
        returns (bytes32 cath_)
    {
        cath_ = _CANCEL_AUTHORIZATION_TYPEHASH;
    }

    constructor() {
        _initialized = false;
    }

    function setup(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external {
        require(!_initialized);
        LibDiamond.enforceIsContractOwner();

        s.name = _name;
        s.symbol = _symbol;
        s.decimals = _decimals;

        _initialized = true;
        emit TokenSetup(msg.sender, _name, _symbol, _decimals);
    }

    modifier onlyMinters() {
        require(s.minters[msg.sender], "Caller is not a minter");
        _;
    }

    function mint(address _to, uint256 _amount)
        external
        whenNotPaused
        onlyMinters
        notBlacklisted(msg.sender)
        notBlacklisted(_to)
        returns (bool)
    {
        require(_to != address(0), "Mint to the zero address");
        require(_amount > 0, "Mint amount not greater than 0");

        uint256 mintingAllowedAmount = s.minterAllowed[msg.sender];
        require(
            _amount <= mintingAllowedAmount,
            "Mint amount exceeds minterAllowance"
        );

        s.totalSupply = s.totalSupply + _amount;
        s.balances[_to] = s.balances[_to] + _amount;
        s.minterAllowed[msg.sender] = mintingAllowedAmount - _amount;
        emit Mint(msg.sender, _to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function minterAllowance(address _minter)
        external
        view
        returns (uint256 amount_)
    {
        amount_ = s.minterAllowed[_minter];
    }

    function isMinter(address _account) external view returns (bool isMinter_) {
        isMinter_ = s.minters[_account];
    }

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 amount_)
    {
        amount_ = s.allowed[_owner][_spender];
    }

    function totalSupply() external view returns (uint256 amount_) {
        amount_ = s.totalSupply;
    }

    function balanceOf(address _account)
        external
        view
        returns (uint256 amount_)
    {
        amount_ = s.balances[_account];
    }

    function approve(address _spender, uint256 _value)
        external
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(_spender)
        returns (bool)
    {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _value
    ) internal {
        require(_owner != address(0), "Approve from the zero address");
        require(_spender != address(0), "Approve to the zero address");
        s.allowed[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        external
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(_from)
        notBlacklisted(_to)
        returns (bool)
    {
        require(
            _value <= s.allowed[_from][msg.sender],
            "Transfer amount exceeds allowance"
        );
        _transfer(_from, _to, _value);
        s.allowed[_from][msg.sender] = s.allowed[_from][msg.sender] - _value;
        return true;
    }

    function transfer(address _to, uint256 _value)
        external
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(_to)
        returns (bool)
    {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(_from != address(0), "Transfer from the zero address");
        require(_to != address(0), "Transfer to the zero address");
        require(_value <= s.balances[_from], "Transfer amount exceeds balance");

        s.balances[_from] = s.balances[_from] - _value;
        s.balances[_to] = s.balances[_to] + _value;
        emit Transfer(_from, _to, _value);
    }

    function configureMinter(address _minter, uint256 _minterAllowedAmount)
        external
        whenNotPaused
        returns (bool)
    {
        LibDiamond.enforceIsContractOwner();

        s.minters[_minter] = true;
        s.minterAllowed[_minter] = _minterAllowedAmount;
        emit MinterConfigured(_minter, _minterAllowedAmount);
        return true;
    }

    function removeMinter(address _minter) external returns (bool) {
        LibDiamond.enforceIsContractOwner();

        s.minters[_minter] = false;
        s.minterAllowed[_minter] = 0;
        emit MinterRemoved(_minter);
        return true;
    }

    function burn(uint256 _amount)
        external
        whenNotPaused
        notBlacklisted(msg.sender)
    {
        uint256 balance = s.balances[msg.sender];
        require(_amount > 0, "Burn amount not greater than 0");
        require(balance >= _amount, "Burn amount exceeds balance");

        s.totalSupply = s.totalSupply - _amount;
        s.balances[msg.sender] = balance - _amount;
        emit Burn(msg.sender, _amount);
        emit Transfer(msg.sender, address(0), _amount);
    }

    function increaseAllowance(address _spender, uint256 _increment)
        external
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(_spender)
        returns (bool)
    {
        _increaseAllowance(msg.sender, _spender, _increment);
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _decrement)
        external
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(_spender)
        returns (bool)
    {
        _decreaseAllowance(msg.sender, _spender, _decrement);
        return true;
    }

    function transferWithAuthorization(
        address _from,
        address _to,
        uint256 _value,
        uint256 _validAfter,
        uint256 _validBefore,
        bytes32 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external whenNotPaused notBlacklisted(_from) notBlacklisted(_to) {
        _transferWithAuthorization(
            _from,
            _to,
            _value,
            _validAfter,
            _validBefore,
            _nonce,
            _v,
            _r,
            _s
        );
    }

    function receiveWithAuthorization(
        address _from,
        address _to,
        uint256 _value,
        uint256 _validAfter,
        uint256 _validBefore,
        bytes32 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external whenNotPaused notBlacklisted(_from) notBlacklisted(_to) {
        _receiveWithAuthorization(
            _from,
            _to,
            _value,
            _validAfter,
            _validBefore,
            _nonce,
            _v,
            _r,
            _s
        );
    }

    function cancelAuthorization(
        address _authorizer,
        bytes32 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external whenNotPaused {
        _cancelAuthorization(_authorizer, _nonce, _v, _r, _s);
    }

    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external whenNotPaused notBlacklisted(_owner) notBlacklisted(_spender) {
        _permit(_owner, _spender, _value, _deadline, _v, _r, _s);
    }

    function _increaseAllowance(
        address _owner,
        address _spender,
        uint256 _increment
    ) internal {
        _approve(_owner, _spender, s.allowed[_owner][_spender] + _increment);
    }

    function _decreaseAllowance(
        address _owner,
        address _spender,
        uint256 _decrement
    ) internal {
        _approve(_owner, _spender, s.allowed[_owner][_spender] - _decrement);
    }

    function nonces(address _owner) external view returns (uint256 nonce_) {
        nonce_ = s.permitNonces[_owner];
    }

    function _permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal {
        require(_deadline >= block.timestamp, "Permit is expired");

        bytes memory data = abi.encode(
            _PERMIT_TYPEHASH,
            _owner,
            _spender,
            _value,
            s.permitNonces[_owner]++,
            _deadline
        );
        require(
            EIP712.recover(_DOMAIN_SEPARATOR, _v, _r, _s, data) == _owner,
            "Invalid signature"
        );

        _approve(_owner, _spender, _value);
    }

    mapping(address => mapping(bytes32 => bool)) private _authorizationStates;

    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);
    event AuthorizationCanceled(
        address indexed authorizer,
        bytes32 indexed nonce
    );

    function authorizationState(address _authorizer, bytes32 _nonce)
        external
        view
        returns (bool state_)
    {
        state_ = _authorizationStates[_authorizer][_nonce];
    }

    function _transferWithAuthorization(
        address _from,
        address _to,
        uint256 _value,
        uint256 _validAfter,
        uint256 _validBefore,
        bytes32 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal {
        _requireValidAuthorization(_from, _nonce, _validAfter, _validBefore);

        bytes memory data = abi.encode(
            _TRANSFER_WITH_AUTHORIZATION_TYPEHASH,
            _from,
            _to,
            _value,
            _validAfter,
            _validBefore,
            _nonce
        );
        require(
            EIP712.recover(_DOMAIN_SEPARATOR, _v, _r, _s, data) == _from,
            "Invalid signature"
        );

        _markAuthorizationAsUsed(_from, _nonce);
        _transfer(_from, _to, _value);
    }

    function _receiveWithAuthorization(
        address _from,
        address _to,
        uint256 _value,
        uint256 _validAfter,
        uint256 _validBefore,
        bytes32 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal {
        require(_to == msg.sender, "Caller must be the payee");
        _requireValidAuthorization(_from, _nonce, _validAfter, _validBefore);

        bytes memory data = abi.encode(
            _RECEIVE_WITH_AUTHORIZATION_TYPEHASH,
            _from,
            _to,
            _value,
            _validAfter,
            _validBefore,
            _nonce
        );
        require(
            EIP712.recover(_DOMAIN_SEPARATOR, _v, _r, _s, data) == _from,
            "Invalid signature"
        );

        _markAuthorizationAsUsed(_from, _nonce);
        _transfer(_from, _to, _value);
    }

    function _cancelAuthorization(
        address _authorizer,
        bytes32 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal {
        _requireUnusedAuthorization(_authorizer, _nonce);

        bytes memory data = abi.encode(
            _CANCEL_AUTHORIZATION_TYPEHASH,
            _authorizer,
            _nonce
        );
        require(
            EIP712.recover(_DOMAIN_SEPARATOR, _v, _r, _s, data) == _authorizer,
            "Invalid signature"
        );

        _authorizationStates[_authorizer][_nonce] = true;
        emit AuthorizationCanceled(_authorizer, _nonce);
    }

    function _requireUnusedAuthorization(address _authorizer, bytes32 _nonce)
        private
        view
    {
        require(
            !_authorizationStates[_authorizer][_nonce],
            "Authorization is used or canceled"
        );
    }

    function _requireValidAuthorization(
        address _authorizer,
        bytes32 _nonce,
        uint256 _validAfter,
        uint256 _validBefore
    ) private view {
        require(
            block.timestamp > _validAfter,
            "Authorization is not yet valid"
        );
        require(block.timestamp < _validBefore, "Authorization is expired");
        _requireUnusedAuthorization(_authorizer, _nonce);
    }

    function _markAuthorizationAsUsed(address _authorizer, bytes32 _nonce)
        private
    {
        _authorizationStates[_authorizer][_nonce] = true;
        emit AuthorizationUsed(_authorizer, _nonce);
    }

    event RescuerChanged(address indexed _newRescuer);

    modifier onlyRescuer() {
        require(msg.sender == s.rescuer, "Caller is not the rescuer");
        _;
    }

    function rescueERC20(
        IERC20 _tokenContract,
        address _to,
        uint256 _amount
    ) external onlyRescuer {
        _tokenContract.safeTransfer(_to, _amount);
    }

    function updateRescuer(address _newRescuer) external {
        require(_newRescuer != address(0), "New rescuer is the zero address");

        LibDiamond.enforceIsContractOwner();

        s.rescuer = _newRescuer;
        emit RescuerChanged(s.rescuer);
    }

    event Pause();
    event Unpause();
    event PauserChanged(address indexed newAddress);

    modifier whenNotPaused() {
        require(!s.paused, "Paused");
        _;
    }

    modifier onlyPauser() {
        require(msg.sender == s.pauser, "Caller is not the pauser");
        _;
    }

    function pause() external onlyPauser {
        s.paused = true;
        emit Pause();
    }

    function unpause() external onlyPauser {
        s.paused = false;
        emit Unpause();
    }

    function updatePauser(address _newPauser) external {
        require(_newPauser != address(0), "New pauser is the zero address");

        LibDiamond.enforceIsContractOwner();

        s.pauser = _newPauser;
        emit PauserChanged(s.pauser);
    }

    event Blacklisted(address indexed _account);
    event UnBlacklisted(address indexed _account);
    event BlacklisterChanged(address indexed _newBlacklister);

    modifier onlyBlacklister() {
        require(msg.sender == s.blacklister, "Caller is not the blacklister");
        _;
    }

    modifier notBlacklisted(address _account) {
        require(!s.blacklisted[_account], "Account is blacklisted");
        _;
    }

    function isBlacklisted(address _account) external view returns (bool) {
        return s.blacklisted[_account];
    }

    function blacklist(address _account) external onlyBlacklister {
        s.blacklisted[_account] = true;
        emit Blacklisted(_account);
    }

    function unBlacklist(address _account) external onlyBlacklister {
        s.blacklisted[_account] = false;
        emit UnBlacklisted(_account);
    }

    function updateBlacklister(address _newBlacklister) external {
        require(
            _newBlacklister != address(0),
            "New blacklister is the zero address"
        );

        LibDiamond.enforceIsContractOwner();

        s.blacklister = _newBlacklister;
        emit BlacklisterChanged(s.blacklister);
    }
}