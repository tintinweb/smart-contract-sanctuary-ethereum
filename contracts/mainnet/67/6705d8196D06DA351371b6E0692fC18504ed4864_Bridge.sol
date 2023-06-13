// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Multicall.sol';

import './interfaces/IVerifier.sol';
import './libraries/SafeToken.sol';

contract Bridge is Multicall {
  using Address for address;
  using Address for address payable;
  using SafeToken for address;

  bytes32 public immutable DOMAIN_SEPARATOR;
  // keccak256('Out(bytes16 uuid,address token,uint256 amount,uint256 gas,address to,bytes data)')
  bytes32 public constant OUT_TYPEHASH = 0x128db24430fa2fc5b7de9305b8518573b5e9ed0bde3a71ed68fc27427fcdac9b;
  // keccak256('SetVerifier(address newVerifier,uint256 deadline)')
  bytes32 public constant SET_VERIFIER_TYPEHASH = 0x83ff2829503e6b25933e0c1d0422aeb9b68fe6259418bffd98b105c4ef89c4d4;

  mapping(bytes16 => uint256) public used;
  mapping(bytes16 => uint256) public usedPay;
  IVerifier public verifier;

  event Payed(bytes16 indexed uuid, address token, uint256 amount, address payer);
  event Outed(bytes16 indexed uuid, address token, uint256 amount, address to);

  modifier notUsed(bytes16 uuid) {
    require(used[uuid] == 0, 'Bridge: uuid already used');
    _;
    used[uuid] = block.number;
  }

  modifier notUsedPay(bytes16 uuid) {
    require(usedPay[uuid] == 0, 'Bridge: uuid already used');
    _;
    usedPay[uuid] = block.number;
  }

  constructor() {
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
        keccak256('Bridge'),
        keccak256('1'),
        block.chainid,
        address(this)
      )
    );
  }

  function pay(
    bytes16 uuid,
    address token,
    uint256 amount
  ) external payable notUsedPay(uuid) {
    if (token == address(0)) {
      amount = msg.value;
    } else {
      amount = token.move(msg.sender, address(this), amount);
    }

    emit Payed(uuid, token, amount, msg.sender);
  }

  function out(
    bytes16 uuid,
    address token,
    uint256 amount,
    uint256 gas,
    address payable to,
    bytes calldata data,
    bytes[] calldata signatures
  ) external notUsed(uuid) {
    bytes32 structHash = keccak256(abi.encode(OUT_TYPEHASH, uuid, token, amount, gas, to, keccak256(data)));
    require(verifier.verify(DOMAIN_SEPARATOR, structHash, signatures), 'Bridge: invalid signatures');

    if (token == address(0)) {
      if (data.length > 0) {
        to.functionCallWithValue(data, amount + gas);
      } else {
        to.sendValue(amount + gas);
      }
    } else {
      if (data.length > 0) {
        token.approve(to, amount);
        to.functionCallWithValue(data, gas);
        token.approve(to, 0);
      } else {
        token.move(address(this), to, amount);
        if (gas > 0) {
          to.sendValue(gas);
        }
      }
    }

    emit Outed(uuid, token, amount, to);
  }

  function setVerifier(
    IVerifier newVerifier,
    uint256 deadline,
    bytes[] calldata newSigs,
    bytes[] calldata oldSigs
  ) external {
    require(block.timestamp <= deadline, 'Bridge: expired');

    bytes32 structHash = keccak256(abi.encode(SET_VERIFIER_TYPEHASH, newVerifier, deadline));
    require(newVerifier.verify(DOMAIN_SEPARATOR, structHash, newSigs), 'Bridge: invalid signature for new verifier');

    if (address(verifier) != address(0)) {
      require(verifier.verify(DOMAIN_SEPARATOR, structHash, oldSigs), 'Bridge: invalid signature for old verifier');
    }

    verifier = newVerifier;
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

pragma solidity ^0.8.0;

interface IVerifier {
  function verify(bytes32 domain, bytes32 structHash, bytes[] calldata signatures) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Token {
  function balanceOf(address wallet) external view returns (uint);
  function approve(address spender, uint amount) external;
  function transfer(address to, uint amount) external;
  function transferFrom(address from, address to, uint amount) external;
}

library SafeToken {
  function approve(address token, address spender, uint amount) internal {
    require(Token(token).balanceOf(address(this)) >= amount, 'SafeToken: insufficient balance for approve');
    Token(token).approve(spender, amount);
  }

  function move(address token, address from, address to, uint amount) internal returns (uint) {
    require(Token(token).balanceOf(from) >= amount, 'SafeToken: insufficient balance for move');

    uint before = Token(token).balanceOf(to);
    if (from == address(this)) {
      Token(token).transfer(to, amount);
    } else {
      Token(token).transferFrom(from, to, amount);
    }
    return Token(token).balanceOf(to) - before;
  }
}