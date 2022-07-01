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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

/// @notice create opcode failed
error CreateError();
/// @notice create2 opcode failed
error Create2Error();

library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     *
     * init: 0x3d605d80600a3d3981f3
     * 3d   returndatasize  0
     * 605d push1 0x5d      0x5d 0
     * 80   dup1            0x5d 0x5d 0
     * 600a push1 0x0a      0x0a 0x5d 0x5d 0
     * 3d   returndatasize  0 0x0a 0x5d 0x5d 0
     * 39   codecopy        0x5d 0                      destOffset offset length     memory[destOffset:destOffset+length] = address(this).code[offset:offset+length]       copy executing contracts bytecode
     * 81   dup2            0 0x5d 0
     * f3   return          0                           offset length                return memory[offset:offset+length]                                                   returns from this contract call
     *
     * contract: 0x36603057343d52307f830d2d700a97af574b186c80d40429385d24241565b08a7c559ba283a964d9b160203da23d3df35b3d3d3d3d363d3d37363d73bebebebebebebebebebebebebebebebebebebebe5af43d3d93803e605b57fd5bf3
     *     0x000     36       calldatasize      cds
     *     0x001     6030     push1 0x30        0x30 cds
     * ,=< 0x003     57       jumpi
     * |   0x004     34       callvalue         cv
     * |   0x005     3d       returndatasize    0 cv
     * |   0x006     52       mstore
     * |   0x007     30       address           addr
     * |   0x008     7f830d.. push32 0x830d..   id addr
     * |   0x029     6020     push1 0x20        0x20 id addr
     * |   0x02b     3d       returndatasize    0 0x20 id addr
     * |   0x02c     a2       log2
     * |   0x02d     3d       returndatasize    0
     * |   0x02e     3d       returndatasize    0 0
     * |   0x02f     f3       return
     * `-> 0x030     5b       jumpdest
     *     0x031     3d       returndatasize    0
     *     0x032     3d       returndatasize    0 0
     *     0x033     3d       returndatasize    0 0 0
     *     0x034     3d       returndatasize    0 0 0 0
     *     0x035     36       calldatasize      cds 0 0 0 0
     *     0x036     3d       returndatasize    0 cds 0 0 0 0
     *     0x037     3d       returndatasize    0 0 cds 0 0 0 0
     *     0x038     37       calldatacopy      0 0 0 0
     *     0x039     36       calldatasize      cds 0 0 0 0
     *     0x03a     3d       returndatasize    0 cds 0 0 0 0
     *     0x03b     73bebe.. push20 0xbebe..   0xbebe 0 cds 0 0 0 0
     *     0x050     5a       gas               gas 0xbebe 0 cds 0 0 0 0
     *     0x051     f4       delegatecall      suc 0 0
     *     0x052     3d       returndatasize    rds suc 0 0
     *     0x053     3d       returndatasize    rds rds suc 0 0
     *     0x054     93       swap4             0 rds suc 0 rds
     *     0x055     80       dup1              0 0 rds suc 0 rds
     *     0x056     3e       returndatacopy    suc 0 rds
     *     0x057     605b     push1 0x5b        0x5b suc 0 rds
     * ,=< 0x059     57       jumpi             0 rds
     * |   0x05a     fd       revert
     * `-> 0x05b     5b       jumpdest          0 rds
     *     0x05c     f3       return
     *
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d605d80600a3d3981f336603057343d52307f00000000000000000000000000
            )
            mstore(
                add(ptr, 0x13),
                0x830d2d700a97af574b186c80d40429385d24241565b08a7c559ba283a964d9b1
            )
            mstore(
                add(ptr, 0x33),
                0x60203da23d3df35b3d3d3d3d363d3d37363d7300000000000000000000000000
            )
            mstore(add(ptr, 0x46), shl(0x60, implementation))
            mstore(
                add(ptr, 0x5a),
                0x5af43d3d93803e605b57fd5bf300000000000000000000000000000000000000
            )
            instance := create(0, ptr, 0x67)
        }
        if (instance == address(0)) revert CreateError();
    }

    function cloneDeterministic(address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d605d80600a3d3981f336603057343d52307f00000000000000000000000000
            )
            mstore(
                add(ptr, 0x13),
                0x830d2d700a97af574b186c80d40429385d24241565b08a7c559ba283a964d9b1
            )
            mstore(
                add(ptr, 0x33),
                0x60203da23d3df35b3d3d3d3d363d3d37363d7300000000000000000000000000
            )
            mstore(add(ptr, 0x46), shl(0x60, implementation))
            mstore(
                add(ptr, 0x5a),
                0x5af43d3d93803e605b57fd5bf300000000000000000000000000000000000000
            )
            instance := create2(0, ptr, 0x67, salt)
        }
        if (instance == address(0)) revert Create2Error();
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d605d80600a3d3981f336603057343d52307f00000000000000000000000000
            )
            mstore(
                add(ptr, 0x13),
                0x830d2d700a97af574b186c80d40429385d24241565b08a7c559ba283a964d9b1
            )
            mstore(
                add(ptr, 0x33),
                0x60203da23d3df35b3d3d3d3d363d3d37363d7300000000000000000000000000
            )
            mstore(add(ptr, 0x46), shl(0x60, implementation))
            mstore(
                add(ptr, 0x5a),
                0x5af43d3d93803e605b57fd5bf3ff000000000000000000000000000000000000
            )
            mstore(add(ptr, 0x68), shl(0x60, deployer))
            mstore(add(ptr, 0x7c), salt)
            mstore(add(ptr, 0x9c), keccak256(ptr, 0x67))
            predicted := keccak256(add(ptr, 0x67), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";

import "./Clones.sol";

contract FlairFactory {
    event ProxyCreated(address indexed deployer, address indexed proxyAddress);

    function cloneDeterministicSimple(
        address implementation,
        bytes32 salt,
        bytes calldata data
    ) external returns (address deployedProxy) {
        bytes32 _salt = keccak256(abi.encodePacked(msg.sender, salt));
        deployedProxy = Clones.cloneDeterministic(implementation, _salt);

        if (data.length > 0) {
            (bool success, bytes memory returndata) = deployedProxy.call(data);

            if (!success) {
                // Look for revert reason and bubble it up if present
                if (returndata.length > 0) {
                    // The easiest way to bubble the revert reason is using memory via assembly
                    assembly {
                        let returndata_size := mload(returndata)
                        revert(add(32, returndata), returndata_size)
                    }
                } else {
                    revert("FAILED_TO_CLONE");
                }
            }
        }

        emit ProxyCreated(msg.sender, deployedProxy);
    }

    function predictDeterministicSimple(address implementation, bytes32 salt)
        external
        view
        returns (address deployedProxy)
    {
        bytes32 _salt = keccak256(abi.encodePacked(msg.sender, salt));
        deployedProxy = Clones.predictDeterministicAddress(
            implementation,
            _salt
        );
    }
}