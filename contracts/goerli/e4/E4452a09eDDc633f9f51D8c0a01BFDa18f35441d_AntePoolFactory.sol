// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./libraries/StorageSlot.sol";

/// @title Ante V0.6 Ante Pool Proxy smart contract
contract AntePool is Proxy {
    /// @dev Storage slot with the address of the current implementation.
    /// This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 internal constant _IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

    /// @param _antePoolLogicAddr The address where the implementation contract is deployed
    constructor(address _antePoolLogicAddr) {
        require(Address.isContract(_antePoolLogicAddr), "ANTE: implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = _antePoolLogicAddr;
    }

    /// @inheritdoc Proxy
    function _implementation() internal view override returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.8.0;

import "./AntePool.sol";
import "./interfaces/IAnteTest.sol";
import "./interfaces/IAntePool.sol";
import "./interfaces/IAntePoolFactory.sol";
import "./interfaces/IAntePoolFactoryController.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Ante V0.6 Ante Pool Factory smart contract
/// @notice Contract that creates an AntePool wrapper for an AnteTest
contract AntePoolFactory is IAntePoolFactory, ReentrancyGuard {
    struct TestStateInfo {
        bool hasFailed;
        address verifier;
        uint256 failedBlock;
        uint256 failedTimestamp;
    }

    mapping(address => TestStateInfo) private stateByTest;

    // Stores all the pools associated with a test
    mapping(address => address[]) public poolsByTest;
    /// @inheritdoc IAntePoolFactory
    mapping(bytes32 => address) public override poolByConfig;
    /// @inheritdoc IAntePoolFactory
    address[] public override allPools;

    /// @dev The maximum number of pools allowed to be created for an Ante Test
    uint256 public constant MAX_POOLS_PER_TEST = 10;

    /// @inheritdoc IAntePoolFactory
    IAntePoolFactoryController public override controller;

    /// @param _controller The address of the Ante Factory Controller
    constructor(address _controller) {
        controller = IAntePoolFactoryController(_controller);
    }

    /// @inheritdoc IAntePoolFactory
    function createPool(
        address testAddr,
        address tokenAddr,
        uint256 payoutRatio,
        uint256 decayRate,
        uint256 authorRewardRate
    ) external override returns (address testPool) {
        // Checks that a non-zero AnteTest address is passed in and that
        // an AntePool has not already been created for that AnteTest
        require(testAddr != address(0), "ANTE: Test address is 0");
        require(!stateByTest[testAddr].hasFailed, "ANTE: Test has previously failed");
        require(controller.isTokenAllowed(tokenAddr), "ANTE: Token not allowed");
        require(poolsByTest[testAddr].length < MAX_POOLS_PER_TEST, "ANTE: Max pools per test reached");

        uint256 tokenMinimum = controller.getTokenMinimum(tokenAddr);
        bytes32 configHash = keccak256(
            abi.encodePacked(testAddr, tokenAddr, tokenMinimum, payoutRatio, decayRate, authorRewardRate)
        );
        address poolAddr = poolByConfig[configHash];
        require(poolAddr == address(0), "ANTE: Pool with the same config already exists");

        IAnteTest anteTest = IAnteTest(testAddr);

        testPool = address(new AntePool{salt: configHash}(controller.antePoolLogicAddr()));

        require(testPool != address(0), "ANTE: Pool creation failed");

        poolsByTest[testAddr].push(testPool);
        poolByConfig[configHash] = testPool;
        allPools.push(testPool);

        IAntePool(testPool).initialize(
            anteTest,
            IERC20(tokenAddr),
            tokenMinimum,
            decayRate,
            payoutRatio,
            authorRewardRate
        );

        emit AntePoolCreated(
            testAddr,
            tokenAddr,
            tokenMinimum,
            payoutRatio,
            decayRate,
            authorRewardRate,
            testPool,
            msg.sender
        );
    }

    /// @inheritdoc IAntePoolFactory
    function hasTestFailed(address testAddr) external view override returns (bool) {
        return stateByTest[testAddr].hasFailed;
    }

    /// @inheritdoc IAntePoolFactory
    function checkTestWithState(
        bytes memory _testState,
        address verifier,
        bytes32 poolConfig
    ) public override nonReentrant {
        address poolAddr = poolByConfig[poolConfig];
        require(poolAddr == msg.sender, "ANTE: Must be called by a pool");

        IAntePool pool = IAntePool(msg.sender);
        (, , uint256 claimableShares, ) = pool.getChallengerInfo(verifier);
        require(claimableShares > 0, "ANTE: Only confirmed challengers can checkTest");
        require(
            pool.getCheckTestAllowedBlock(verifier) < block.number,
            "ANTE: must wait 12 blocks after challenging to call checkTest"
        );
        IAnteTest anteTest = pool.anteTest();
        bool hasFailed = stateByTest[address(anteTest)].hasFailed;
        require(!hasFailed, "ANTE: Test already failed.");

        pool.updateVerifiedState(verifier);
        if (!_checkTestNoRevert(anteTest, _testState)) {
            _setFailureStateForTest(address(anteTest), verifier);
        }
    }

    /// @inheritdoc IAntePoolFactory
    function getPoolsByTest(address testAddr) external view override returns (address[] memory) {
        return poolsByTest[testAddr];
    }

    /// @inheritdoc IAntePoolFactory
    function getNumPoolsByTest(address testAddr) external view override returns (uint256) {
        return poolsByTest[testAddr].length;
    }

    /// @inheritdoc IAntePoolFactory
    function numPools() external view override returns (uint256) {
        return allPools.length;
    }

    /*****************************************************
     * =============== INTERNAL HELPERS ================ *
     *****************************************************/

    /// @notice Checks the connected Ante Test, also returns true if
    /// setStateAndCheckTestPasses or checkTestPasses reverts
    /// @return passes bool if the Ante Test passed
    function _checkTestNoRevert(IAnteTest anteTest, bytes memory _testState) internal returns (bool) {
        // This condition replicates the logic from AnteTest(v0.6).setStateAndCheckTestPasses
        // It is used for backward compatibility with v0.5 tests
        if (_testState.length > 0) {
            try anteTest.setStateAndCheckTestPasses(_testState) returns (bool passes) {
                return passes;
            } catch {
                return true;
            }
        }

        try anteTest.checkTestPasses() returns (bool passes) {
            return passes;
        } catch {
            return true;
        }
    }

    function _setFailureStateForTest(address testAddr, address verifier) internal {
        TestStateInfo storage testState = stateByTest[testAddr];
        testState.hasFailed = true;
        testState.failedBlock = block.number;
        testState.failedTimestamp = block.timestamp;
        testState.verifier = verifier;

        address[] memory pools = poolsByTest[testAddr];
        uint256 numPoolsByTest = pools.length;
        for (uint256 i = 0; i < numPoolsByTest; i++) {
            try IAntePool(pools[i]).updateFailureState(verifier) {} catch {
                emit PoolFailureReverted();
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IAnteTest.sol";

/// @title The interface for Ante V0.6 Ante Pool
/// @notice The Ante Pool handles interactions with connected Ante Test
interface IAntePool {
    /// @notice Emitted when a user adds to the stake pool
    /// @param staker The address of user
    /// @param amount Amount being added in wei
    /// @param commitTime The minimum staking time commitment
    event Stake(address indexed staker, uint256 amount, uint256 commitTime);

    /// @notice Emitted when a user extends his stake commitment
    /// @param staker The address of user
    /// @param additionalTime The additional commitment time
    /// @param commitTime The new minimum staking time commitment
    event ExtendStake(address indexed staker, uint256 additionalTime, uint256 commitTime);

    /// @notice Emitted when a user adds to the challenge pool
    /// @param challenger The address of user
    /// @param amount Amount being added in wei
    event RegisterChallenge(address indexed challenger, uint256 amount);

    /// @notice Emitted when a challenging user confirms their challenge
    /// @param challenger The address of user
    /// @param confirmedShares The amount of shares that were confirmed in wei
    event ConfirmChallenge(address indexed challenger, uint256 confirmedShares);

    /// @notice Emitted when a user removes from the stake or challenge pool
    /// @param staker The address of user
    /// @param amount Amount being removed in wei
    /// @param isChallenger Whether or not this is removed from the challenger pool
    event Unstake(address indexed staker, uint256 amount, bool indexed isChallenger);

    /// @notice Emitted when the connected Ante Test's invariant gets verified
    /// @param checker The address of challenger who called the verification
    event TestChecked(address indexed checker);

    /// @notice Emitted when the connected Ante Test has failed test verification
    /// @param checker The address of challenger who called the verification
    event FailureOccurred(address indexed checker);

    /// @notice Emitted when a challenger claims their payout for a failed test
    /// @param claimer The address of challenger claiming their payout
    /// @param amount Amount being claimed in wei
    event ClaimPaid(address indexed claimer, uint256 amount);

    /// @notice Emitted when the test author claims their reward for a test
    /// @param author The address of auther claiming their reward
    /// @param amount Amount being claimed in wei
    event RewardPaid(address indexed author, uint256 amount);

    /// @notice Emitted when a staker has withdrawn their stake after the 24 hour wait period
    /// @param staker The address of the staker removing their stake
    /// @param amount Amount withdrawn in wei
    event WithdrawStake(address indexed staker, uint256 amount);

    /// @notice Emitted when a staker cancels their withdraw action before the 24 hour wait period
    /// @param staker The address of the staker cancelling their withdraw
    /// @param amount Amount cancelled in wei
    event CancelWithdraw(address indexed staker, uint256 amount);

    /// @notice emited when decay paid to stakers is updated
    /// @param decayThisUpdate total decay accrued to stakers this update
    /// @param challengerMultiplier new challenger decay multiplier
    /// @param stakerMultiplier new staker decay multiplier
    event DecayUpdated(uint256 decayThisUpdate, uint256 challengerMultiplier, uint256 stakerMultiplier);

    /// @notice emited when decay starts to accumulate
    event DecayStarted();

    /// @notice emited when decay stops being accumulated
    event DecayPaused();

    /// @notice Initializes Ante Pool with the connected Ante Test
    /// @param _anteTest The Ante Test that will be connected to the Ante Pool
    /// @param _token The ERC20 token used for transacting with the Ante Pool
    /// @param _decayRate The annualized challenger decay rate expressed as precentage (x%) of total challenge
    /// @param _payoutRatio The minimum totalStake:totalChallenge ratio allowed for the Ante Pool
    /// @param _testAuthorRewardRate The test author reward rate expressed as a percentage (x%) of the decay
    /// @dev This function requires that the Ante Test address is valid and that
    /// the invariant validation currently passes
    function initialize(
        IAnteTest _anteTest,
        IERC20 _token,
        uint256 _tokenMinimum,
        uint256 _decayRate,
        uint256 _payoutRatio,
        uint256 _testAuthorRewardRate
    ) external;

    /// @notice Cancels a withdraw action of a staker
    /// @dev This is called when a staker has initiated a withdraw stake action but
    /// then decides to cancel that withdraw
    function cancelPendingWithdraw() external;

    /// @notice Runs the verification of the invariant of the connected Ante Test
    /// without updating the state
    /// @dev Can only be called by a challenger who has challenged the Ante Test
    function checkTest() external;

    /// @notice Runs the verification of the invariant of the connected Ante Test
    /// @param _testState The encoded data required to set the test state
    /// @dev Can only be called by a challenger who has challenged the Ante Test
    function checkTestWithState(bytes memory _testState) external;

    /// @notice Claims the payout of a failed Ante Test
    /// @dev To prevent double claiming, the challenger balance is checked before
    /// claiming and that balance is zeroed out once the claim is done
    function claim() external;

    /// @notice Claims the reward for an Ante Test
    /// @dev To prevent double claiming, the author reward is checked before
    /// claiming and that balance is zeroed out once the claim is done
    function claimReward() external;

    /// @notice Adds a users's stake to the staker pool
    /// @param amount Amount to stake
    /// @param commitTime Time in seconds before the stake can be unstaked again
    function stake(uint256 amount, uint256 commitTime) external;

    /// @notice Extend a staker commitment time by additional time
    /// @param additionalTime Time in seconds to add to the current commitment lock
    function extendStakeLock(uint256 additionalTime) external;

    /// @notice Registers a user's challenge to the challenger pool
    /// @dev confirmChallenge() must be called after MIN_CHALLENGER_DELAY to confirm
    /// the challenge.
    /// @param amount The amount to challenge, denominated in the ERC20 Token of the AntePool
    function registerChallenge(uint256 amount) external;

    /// @notice Confirms a challenger's previously registered challenge
    /// @dev Must be called after at least MIN_CHALLENGER_DELAY seconds to confirm
    /// the challenge.
    function confirmChallenge() external;

    /// @notice Removes a user's stake or challenge from the staker or challenger pool
    /// @param amount Amount being removed in wei
    /// @param isChallenger Flag for if this is a challenger
    function unstake(uint256 amount, bool isChallenger) external;

    /// @notice Removes all of a user's stake or challenge from the respective pool
    /// @param isChallenger Flag for if this is a challenger
    function unstakeAll(bool isChallenger) external;

    /// @notice Updates the decay multipliers and amounts for the total staked and challenged pools
    /// @dev This function is called in most other functions as well to keep the
    /// decay amounts and pools accurate
    function updateDecay() external;

    /// @notice Updates the verified state of this pool when a verification is triggered
    /// @param _verifier The address of who called the test verification
    /// @dev This function is called from the AntePoolFactory to set the pool's verification state.
    function updateVerifiedState(address _verifier) external;

    /// @notice Updates the failure state of this pool after the associated ante test has failed
    /// @param _verifier The address of who called the test verification
    /// @dev This function is called from the AntePoolFactory to propagate the failure state to
    /// all linked ante pools as soon as a checkTest() call has failed on a single AntePool
    function updateFailureState(address _verifier) external;

    /// @notice Initiates the withdraw process for a staker, starting the 24 hour waiting period
    /// @dev During the 24 hour waiting period, the value is locked to prevent
    /// users from removing their stake when a challenger is going to verify test
    function withdrawStake() external;

    /// @notice Returns the Ante Test connected to this Ante Pool
    /// @return IAnteTest The Ante Test interface
    function anteTest() external view returns (IAnteTest);

    /// @notice Returns the annualized challenger decay rate expressed as a precentage (x%) of challenger pool
    /// @return The decay rate of the challenger side
    function decayRate() external view returns (uint256);

    /// @notice Returns the minimum totalStake:totalChallenge ratio allowed for the Ante Pool
    /// @return The challenger payout ratio
    function challengerPayoutRatio() external view returns (uint256);

    /// @notice Returns the test author reward rate on this Ante Pool, expressed as a percentage (x%) of the decay
    /// @return The test author reward rate
    function testAuthorRewardRate() external view returns (uint256);

    /// @notice Returns the available rewards to be claimed by the test author
    /// @return The amount of tokens available to be claimed
    function getTestAuthorReward() external view returns (uint256);

    /// @notice Get the info for the challenger pool
    /// @return numUsers The total number of challengers in the challenger pool
    ///         totalAmount The total value locked in the challenger pool in wei
    ///         decayMultiplier The current multiplier for decay
    function challengerInfo() external view returns (uint256 numUsers, uint256 totalAmount, uint256 decayMultiplier);

    /// @notice Get the info for the staker pool
    /// @return numUsers The total number of stakers in the staker pool
    ///         totalAmount The total value locked in the staker pool in wei
    ///         decayMultiplier The current multiplier for decay
    function stakingInfo() external view returns (uint256 numUsers, uint256 totalAmount, uint256 decayMultiplier);

    /// @notice Get the total value eligible for payout
    /// @dev This is used so that challengers must have challenged for at least
    /// 12 blocks to receive payout, this is to mitigate other challengers
    /// from trying to stick in a challenge right before the verification
    /// @return eligibleAmount Total value eligible for payout in wei
    function eligibilityInfo() external view returns (uint256 eligibleAmount);

    /// @notice Returns the Ante Pool factory address that created this Ante Pool
    /// @return Address of Ante Pool factory
    function factory() external view returns (address);

    /// @notice Returns the block at which the connected Ante Test failed
    /// @dev This is only set when a verify test action is taken, so the test could
    /// have logically failed beforehand, but without having a user initiating
    /// the verify test action
    /// @return Block number where Ante Test failed
    function failedBlock() external view returns (uint256);

    /// @notice Returns the timestamp at which the connected Ante Test failed
    /// @dev This is only set when a verify test action is taken, so the test could
    /// have logically failed beforehand, but without having a user initiating
    /// the verify test action
    /// @return Seconds since epoch when Ante Test failed
    function failedTimestamp() external view returns (uint256);

    /// @notice Returns info for a specific challenger
    /// @param challenger Address of challenger
    function getChallengerInfo(
        address challenger
    )
        external
        view
        returns (
            uint256 startAmount,
            uint256 lastStakedTimestamp,
            uint256 claimableShares,
            uint256 claimableSharesStartMultiplier
        );

    /// @notice Returns the payout amount for a specific challenger
    /// @param challenger Address of challenger
    /// @dev If this is called before an Ante Test has failed, then it's return
    /// value is an estimate
    /// @return Amount that could be claimed by challenger in wei
    function getChallengerPayout(address challenger) external view returns (uint256);

    /// @notice Returns the timestamp for when the staker's 24 hour wait period is over
    /// @param _user Address of withdrawing staker
    /// @dev This is timestamp is 24 hours after the time when the staker initaited the
    /// withdraw process
    /// @return Timestamp for when the value is no longer locked and can be removed
    function getPendingWithdrawAllowedTime(address _user) external view returns (uint256);

    /// @notice Returns the timestamp for when the staker's time commitment expires
    /// @param _user Address of staker
    /// @dev This timestamp is the commitTime after the time the staker initially staked
    /// @return Timestamp for when the stake is no longer locked and can be unstaked
    function getUnstakeAllowedTime(address _user) external view returns (uint256);

    /// @notice Returns the amount a staker is attempting to withdraw
    /// @param _user Address of withdrawing staker
    /// @return Amount which is being withdrawn in wei
    function getPendingWithdrawAmount(address _user) external view returns (uint256);

    /// @notice Returns the stored balance of a user in their respective pool
    /// @param _user Address of user
    /// @param isChallenger Flag if user is a challenger
    /// @dev This function calculates decay and returns the stored value after the
    /// decay has been either added (staker) or subtracted (challenger)
    /// @return Balance that the user has currently in wei
    function getStoredBalance(address _user, bool isChallenger) external view returns (uint256);

    /// @notice Returns total value of eligible payout for challengers
    /// @return Amount eligible for payout in wei
    function getTotalChallengerEligibleBalance() external view returns (uint256);

    /// @notice Returns total value locked of all challengers
    /// @return Total amount challenged in wei
    function getTotalChallengerStaked() external view returns (uint256);

    /// @notice Returns total value of all stakers who are withdrawing their stake
    /// @return Total amount waiting for withdraw in wei
    function getTotalPendingWithdraw() external view returns (uint256);

    /// @notice Returns total value locked of all stakers
    /// @return Total amount staked in wei
    function getTotalStaked() external view returns (uint256);

    /// @notice Returns a user's starting amount added in their respective pool
    /// @param _user Address of user
    /// @param isChallenger Flag if user is a challenger
    /// @dev This value is updated as decay is caluclated or additional value
    /// added to respective side
    /// @return User's starting amount in wei
    function getUserStartAmount(address _user, bool isChallenger) external view returns (uint256);

    /// @notice Returns a user's starting decay multiplier
    /// @param _user Address of user
    /// @param isChallenger Flag if user is a challenger
    /// @dev This value is updated as decay is calculated or additional value
    /// added to respective side
    /// @return User's starting decay multiplier
    function getUserStartDecayMultiplier(address _user, bool isChallenger) external view returns (uint256);

    /// @notice Returns the verifier bounty amount
    /// @dev Currently this is 5% of the total staked amount
    /// @return Bounty amount rewarded to challenger who verifies test in wei
    function getVerifierBounty() external view returns (uint256);

    /// @notice Returns the cutoff block when challenger can call verify test
    /// @dev This is currently 12 blocks after a challenger has challenged the test
    /// @return Block number of when verify test can be called by challenger
    function getCheckTestAllowedBlock(address _user) external view returns (uint256);

    /// @notice Returns the most recent block number where decay was updated
    /// @dev This is generally updated on most actions that interact with the Ante
    /// Pool contract
    /// @return Block number of when contract was last updated
    function lastUpdateBlock() external view returns (uint256);

    /// @notice Returns the most recent timestamp where decay was updated
    /// @dev This is generally updated on most actions that interact with the Ante
    /// Pool contract
    /// @return Number of seconds since epoch of when contract was last updated
    function lastUpdateTimestamp() external view returns (uint256);

    /// @notice Returns the minimum allowed challenger stake
    /// @dev Minimum challenger stake is token based and is configured in AntePoolFactoryController
    /// @return The minimum amount that a challenger can stake
    function minChallengerStake() external view returns (uint256);

    /// @notice Returns the minimum allowed support stake
    /// @dev Minimum support stake is derived from the challengerPayoutRatio and minChallengerStake
    /// @return The minimum amount that a supporter can stake
    function minSupporterStake() external view returns (uint256);

    /// @notice Returns the most recent block number where a challenger verified test
    /// @dev This is updated whenever the verify test is activated, whether or not
    /// the Ante Test fails
    /// @return Block number of last verification attempt
    function lastVerifiedBlock() external view returns (uint256);

    /// @notice Returns the most recent timestamp when a challenger verified test
    /// @dev This is updated whenever the verify test is activated, whether or not
    /// the Ante Test fails
    /// @return Seconds since epoch of last verification attempt
    function lastVerifiedTimestamp() external view returns (uint256);

    /// @notice Returns the number of challengers that have claimed their payout
    /// @return Number of challengers
    function numPaidOut() external view returns (uint256);

    /// @notice Returns the number of times that the Ante Test has been verified
    /// @return Number of verifications
    function numTimesVerified() external view returns (uint256);

    /// @notice Returns if the connected Ante Test has failed
    /// @return True if the connected Ante Test has failed, False if not
    function pendingFailure() external view returns (bool);

    /// @notice Returns the total value of payout to challengers that have been claimed
    /// @return Value of claimed payouts in wei
    function totalPaidOut() external view returns (uint256);

    /// @notice Returns the ERC20 token used for transacting with the pool
    /// @return IERC20 interface of the token
    function token() external view returns (IERC20);

    /// @notice Returns if the decay accumulation is active
    /// @return True if decay accumulation is active
    function isDecaying() external view returns (bool);

    /// @notice Returns the address of verifier who successfully activated verify test
    /// @dev This is the user who will receive the verifier bounty
    /// @return Address of verifier challenger
    function verifier() external view returns (address);

    /// @notice Returns the total value of stakers who are withdrawing
    /// @return totalAmount total amount pending to be withdrawn in wei
    function withdrawInfo() external view returns (uint256 totalAmount);
}

// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.8.0;

import "../interfaces/IAntePoolFactoryController.sol";

/// @title The interface for the Ante V0.6 Ante Pool Factory
/// @notice The Ante V0.6 Ante Pool Factory programmatically generates an AntePool for a given AnteTest
interface IAntePoolFactory {
    /// @notice Emitted when an AntePool is created from an AnteTest
    /// @param testAddr The address of the AnteTest used to create the AntePool
    /// @param tokenAddr The address of the ERC20 Token used to stake
    /// @param tokenMinimum The minimum allowed stake amount
    /// @param payoutRatio The payout ratio of the pool
    /// @param decayRate The decay rate of the pool
    /// @param authorRewardRate The test writer reward rate
    /// @param testPool The address of the AntePool created by the factory
    /// @param poolCreator address which created the pool (msg.sender on createPool)
    event AntePoolCreated(
        address indexed testAddr,
        address tokenAddr,
        uint256 tokenMinimum,
        uint256 payoutRatio,
        uint256 decayRate,
        uint256 authorRewardRate,
        address testPool,
        address poolCreator
    );

    /// @notice Emitted when pushing the fail state to a pool reverts.
    event PoolFailureReverted();

    /// @notice Creates an AntePool for an AnteTest and returns the AntePool address
    /// @param testAddr The address of the AnteTest to create an AntePool for
    /// @param tokenAddr The address of the ERC20 Token used to stake
    /// @param payoutRatio The payout ratio of the pool
    /// @param decayRate The decay rate of the pool
    /// @param authorRewardRate The test writer reward rate
    /// @return testPool - The address of the generated AntePool
    function createPool(
        address testAddr,
        address tokenAddr,
        uint256 payoutRatio,
        uint256 decayRate,
        uint256 authorRewardRate
    ) external returns (address testPool);

    /// @notice Returns the historic failure state of a given ante test
    /// @param testAddr Address of the test to check
    function hasTestFailed(address testAddr) external view returns (bool);

    /// @notice Runs the verification of the invariant of the connected Ante Test, called by a pool
    /// @param _testState The encoded data required to set the test state
    /// @param verifier The address of who called the test verification
    /// @param poolConfig config hash of the AntePool calling the method. Used for gas effective authorization
    function checkTestWithState(
        bytes memory _testState,
        address verifier,
        bytes32 poolConfig
    ) external;

    /// @notice Returns a single address in the allPools array
    /// @param i The array index of the address to return
    /// @return The address of the i-th AntePool created by this factory
    function allPools(uint256 i) external view returns (address);

    /// @notice Returns the address of the AntePool corresponding to a given AnteTest
    /// @param testAddr address of the AnteTest to look up
    /// @return The addresses of the corresponding AntePools
    function getPoolsByTest(address testAddr) external view returns (address[] memory);

    /// @notice Returns the number of AntePools corresponding to a given AnteTest
    /// @param testAddr address of the AnteTest to look up
    /// @return The number of pools for a specified AnteTest
    function getNumPoolsByTest(address testAddr) external view returns (uint256);

    /// @notice Returns the address of the AntePool corresponding to a given config hash
    /// @param configHash config hash of the AntePool to look up
    /// @return The address of the corresponding AntePool
    function poolByConfig(bytes32 configHash) external view returns (address);

    /// @notice Returns the number of pools created by this factory
    /// @return Number of pools created.
    function numPools() external view returns (uint256);

    /// @notice Returns the Factory Controller used for whitelisting tokens
    /// @return IAntePoolFactoryController The Ante Factory Controller interface
    function controller() external view returns (IAntePoolFactoryController);
}

// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.8.0;

/// @title Ante V0.6 Ante Pool Factory Controller smart contract
/// @notice Contract that handles the whitelisted ERC20 tokens
interface IAntePoolFactoryController {
    /// @notice Emitted when a new token is added to whitelist.
    /// @param tokenAddr The ERC20 token address that was added
    /// @param min The minimum allowed stake amount expressed in the token's decimals
    event TokenAdded(address indexed tokenAddr, uint256 min);

    /// @notice Emitted when a token is removed from whitelist.
    /// @param tokenAddr The ERC20 token address that was added
    event TokenRemoved(address indexed tokenAddr);

    /// @notice Emitted when a token minimum stake is updated.
    /// @param tokenAddr The ERC20 token address that was added
    /// @param min The minimum allowed stake amount expressed in the token's decimals
    event TokenMinimumUpdated(address indexed tokenAddr, uint256 min);

    /// @notice Emitted when the ante pool implementation contract address is updated.
    /// @param oldImplAddress The address of the old implementation contract
    /// @param implAddress The address of the new implementation contract
    event AntePoolImplementationUpdated(address oldImplAddress, address implAddress);

    /// @notice Adds the provided token to the whitelist
    /// @param _tokenAddr The ERC20 token address to be added
    /// @param _min The minimum allowed stake amount expressed in the token's decimals
    function addToken(address _tokenAddr, uint256 _min) external;

    /// @notice Adds multiple tokens to the whitelist only if they do not already exist
    /// It reverts only if no token was added
    /// @param _tokenAddresses An array of ERC20 token addresses
    /// @param _mins An array of minimum allowed stake amount expressed in the token's decimals
    function addTokens(address[] memory _tokenAddresses, uint256[] memory _mins) external;

    /// @notice Removes the provided token address from the whitelist
    /// @param _tokenAddr The ERC20 token address to be removed
    function removeToken(address _tokenAddr) external;

    /// @notice Sets the address of AntePool implementation contract
    /// This is used by the factory when creating a new pool
    /// @param _antePoolLogicAddr The address of the new implementation contract
    function setPoolLogicAddr(address _antePoolLogicAddr) external;

    /// @notice Check if the provided token address exists in the whitelist
    /// @param _tokenAddr The ERC20 token address to be checked
    /// @return true if the provided token is in the whitelist
    function isTokenAllowed(address _tokenAddr) external view returns (bool);

    /// @notice Set the minimum allowed stake amount for a token in the whitelist
    /// @param _tokenAddr The ERC20 token address to be modified
    /// @param _min The minimum allowed stake amount expressed in the token's decimals
    function setTokenMinimum(address _tokenAddr, uint256 _min) external;

    /// @notice Get the minimum allowed stake amount for a token in the whitelist
    /// @param _tokenAddr The ERC20 token address to be checked
    /// @return The minimum stake amount, expressed in the token's decimals
    function getTokenMinimum(address _tokenAddr) external view returns (uint256);

    /// @notice Retrieves an array of all whitelisted tokens
    /// @return A list of ERC20 tokens that are allowed to be used by the factory.
    function getAllowedTokens() external view returns (address[] memory);

    /// @notice Returns the address of AntePool implementation contract
    /// @return Address of the AntePool implementation contract
    function antePoolLogicAddr() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.8.0;

/// @title The interface for the Ante V0.6 Ante Test
/// @notice The Ante V0.6 Ante Test wraps test logic for verifying fundamental invariants of a protocol
interface IAnteTest {
    /// @notice Emitted when the test author is changed
    /// @param previousAuthor The address of the previous author
    /// @param newAuthor The address of the new author
    event TestAuthorChanged(address indexed previousAuthor, address indexed newAuthor);

    /// @notice Function containing the logic to set the AnteTest state and call checkTestPasses
    /// @param _state The encoded data required to set the test state
    /// @return A single bool indicating if the Ante Test passes/fails
    function setStateAndCheckTestPasses(bytes memory _state) external returns (bool);

    /// @notice Function containing test logic to inspect the protocol invariant
    /// @dev This should usually return True
    /// @return A single bool indicating if the Ante Test passes/fails
    function checkTestPasses() external returns (bool);

    /// @notice Returns the author of the Ante Test
    /// @dev This overrides the auto-generated getter for testAuthor as a public var
    /// @return The address of the test author
    function testAuthor() external view returns (address);

    /// @notice Sets the author of the Ante Test
    /// @dev This can only be called by the current author, which is the deployer initially
    /// @param _testAuthor The address of the test author
    function setTestAuthor(address _testAuthor) external;

    /// @notice Returns the name of the protocol the Ante Test is testing
    /// @dev This overrides the auto-generated getter for protocolName as a public var
    /// @return The name of the protocol in string format
    function protocolName() external view returns (string memory);

    /// @notice Returns a single address in the testedContracts array
    /// @dev This overrides the auto-generated getter for testedContracts [] as a public var
    /// @param i The array index of the address to return
    /// @return The address of the i-th element in the list of tested contracts
    function testedContracts(uint256 i) external view returns (address);

    /// @notice Returns the name of the Ante Test
    /// @dev This overrides the auto-generated getter for testName as a public var
    /// @return The name of the Ante Test in string format
    function testName() external view returns (string memory);

    /// @notice Returns a string of comma delimited types used for setting the AnteTest state
    /// @return The types of the state variables
    function getStateTypes() external pure returns (string memory);

    /// @notice Returns a string of comma delimited names used for setting the AnteTest state
    /// @return The names of the state variables
    function getStateNames() external pure returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/StorageSlot.sol

pragma solidity ^0.8.0;

library StorageSlot {
    struct AddressSlot {
        address value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}