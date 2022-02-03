/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2022 Coinbase, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.6;

import { RateLimit } from "./RateLimit.sol";
import { MintUtil } from "./MintUtil.sol";

/**
 * @title MintForwarder
 * @notice Forwarding contract to ERC20 tokens with mint functionality
 */
contract MintForwarder is RateLimit {
    /**
     * @dev Gets the mintable token contract address
     * @return The address of the mintable token contract
     */
    address public tokenContract;

    /**
     * @dev Indicates that the contract has been initialized
     */
    bool internal initialized;

    /**
     * @notice Emitted on mints
     * @param minter The address initiating the mint
     * @param to The address the tokens are minted to
     * @param amount The amount of tokens minted
     */
    event Mint(address indexed minter, address indexed to, uint256 amount);

    /**
     * @dev Function to initialize the contract
     * @dev Can an only be called once by the deployer of the contract
     * @dev The caller is responsible for ensuring that both the new owner and the token contract are configured correctly
     * @param newOwner The address of the new owner of the mint contract, can either be an EOA or a contract
     * @param newTokenContract The address of the token contract that is minted
     */
    function initialize(address newOwner, address newTokenContract)
        external
        onlyOwner
    {
        require(!initialized, "MintForwarder: contract is already initialized");
        require(
            newOwner != address(0),
            "MintForwarder: owner is the zero address"
        );
        require(
            newTokenContract != address(0),
            "MintForwarder: tokenContract is the zero address"
        );
        transferOwnership(newOwner);
        tokenContract = newTokenContract;
        initialized = true;
    }

    /**
     * @dev Rate limited function to mint tokens
     * @dev The _amount must be less than or equal to the allowance of the caller
     * @param _to The address that will receive the minted tokens
     * @param _amount The amount of tokens to mint
     */
    function mint(address _to, uint256 _amount) external onlyCallers {
        require(
            _to != address(0),
            "MintForwarder: cannot mint to the zero address"
        );
        require(_amount > 0, "MintForwarder: mint amount not greater than 0");

        _replenishAllowance(msg.sender);

        require(
            _amount <= allowances[msg.sender],
            "MintForwarder: mint amount exceeds caller allowance"
        );

        allowances[msg.sender] = allowances[msg.sender] - _amount;

        MintUtil.safeMint(_to, _amount, tokenContract);
        emit Mint(msg.sender, _to, _amount);
    }
}

/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2022 Coinbase, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.6;

import { Ownable } from "@openzeppelin4.2.0/contracts/access/Ownable.sol";

/**
 * @title RateLimit
 * @dev Rate limiting contract for function calls
 */
contract RateLimit is Ownable {
    /**
     * @dev Mapping denoting caller addresses
     * @return Boolean denoting whether the given address is a caller
     */
    mapping(address => bool) public callers;

    /**
     * @dev Mapping denoting caller address rate limit intervals
     * @return A time in seconds representing the duration of the given callers interval
     */
    mapping(address => uint256) public intervals;

    /**
     * @dev Mapping denoting when a given caller's allowance was last updated
     * @return The time in seconds since a given caller's allowance was last updated
     */
    mapping(address => uint256) public allowancesLastSet;

    /**
     * @dev Mapping denoting a given caller's maximum allowance
     * @return The maximum allowance of a given caller
     */
    mapping(address => uint256) public maxAllowances;

    /**
     * @dev Mapping denoting a given caller's stored allowance
     * @return The stored allowance of a given caller
     */
    mapping(address => uint256) public allowances;

    /**
     * @notice Emitted on caller configuration
     * @param caller The address configured to make rate limited calls
     * @param amount The maximum allowance for the given caller
     * @param interval The amount of time in seconds before a caller's allowance is replenished
     */
    event CallerConfigured(
        address indexed caller,
        uint256 amount,
        uint256 interval
    );

    /**
     * @notice Emitted on caller removal
     * @param caller The address of the caller being removed
     */
    event CallerRemoved(address indexed caller);

    /**
     * @notice Emitted on caller allowance replenishment
     * @param caller The address of the caller whose allowance is being replenished
     * @param allowance The current allowance for the given caller post replenishment
     * @param amountReplenished The allowance amount that was replenished for the given caller
     */
    event AllowanceReplenished(
        address indexed caller,
        uint256 allowance,
        uint256 amountReplenished
    );

    /**
     * @dev Throws if called by any account other than a caller
     * @dev Rate limited functionality in inheriting contracts must have the only caller modifier
     */
    modifier onlyCallers() {
        require(callers[msg.sender], "RateLimit: caller is not whitelisted");
        _;
    }

    /**
     * @dev Function to add/update a new caller. Also updates allowancesLastSet for that caller.
     * @param caller The address of the caller
     * @param amount The call amount allowed for the caller for a given interval
     * @param interval The interval for a given caller
     */
    function configureCaller(
        address caller,
        uint256 amount,
        uint256 interval
    ) external onlyOwner {
        require(caller != address(0), "RateLimit: caller is the zero address");
        require(amount > 0, "RateLimit: amount is zero");
        require(interval > 0, "RateLimit: interval is zero");
        callers[caller] = true;
        maxAllowances[caller] = allowances[caller] = amount;
        allowancesLastSet[caller] = block.timestamp;
        intervals[caller] = interval;
        emit CallerConfigured(caller, amount, interval);
    }

    /**
     * @dev Function to remove a caller.
     * @param caller The address of the caller
     */
    function removeCaller(address caller) external onlyOwner {
        delete callers[caller];
        delete intervals[caller];
        delete allowancesLastSet[caller];
        delete maxAllowances[caller];
        delete allowances[caller];
        emit CallerRemoved(caller);
    }

    /**
     * @dev Helper function to calculate the estimated allowance given caller address
     * @param caller The address whose call allowance is being estimated
     * @return The allowance of the given caller if their allowance were to be replenished
     */
    function estimatedAllowance(address caller)
        external
        view
        returns (uint256)
    {
        return allowances[caller] + _getReplenishAmount(caller);
    }

    /**
     * @dev Get the current caller allowance for an account
     * @param caller The address of the caller
     * @return The allowance of the given caller post replenishment
     */
    function currentAllowance(address caller) public returns (uint256) {
        _replenishAllowance(caller);
        return allowances[caller];
    }

    /**
     * @dev Helper function to replenish a caller's allowance over the interval in proportion to time elapsed, up to their maximum allowance
     * @param caller The address whose allowance is being updated
     */
    function _replenishAllowance(address caller) internal {
        if (allowances[caller] == maxAllowances[caller]) {
            return;
        }
        uint256 amountToReplenish = _getReplenishAmount(caller);
        if (amountToReplenish == 0) {
            return;
        }

        allowances[caller] = allowances[caller] + amountToReplenish;
        allowancesLastSet[caller] = block.timestamp;
        emit AllowanceReplenished(
            caller,
            allowances[caller],
            amountToReplenish
        );
    }

    /**
     * @dev Helper function to calculate the replenishment amount
     * @param caller The address whose allowance is being estimated
     * @return The allowance amount to be replenished for the given caller
     */
    function _getReplenishAmount(address caller)
        internal
        view
        returns (uint256)
    {
        uint256 secondsSinceAllowanceSet = block.timestamp -
            allowancesLastSet[caller];

        uint256 amountToReplenish = (secondsSinceAllowanceSet *
            maxAllowances[caller]) / intervals[caller];
        uint256 allowanceAfterReplenish = allowances[caller] +
            amountToReplenish;

        if (allowanceAfterReplenish > maxAllowances[caller]) {
            amountToReplenish = maxAllowances[caller] - allowances[caller];
        }
        return amountToReplenish;
    }
}

/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2022 Coinbase, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.6;

import { Address } from "@openzeppelin4.2.0/contracts/utils/Address.sol";

/**
 * @title MintUtil
 * @dev Used for safe minting
 */
library MintUtil {
    bytes4 private constant _MINT_SELECTOR = bytes4(
        keccak256("mint(address,uint256)")
    );

    /**
     * @dev Safely mints ERC20 token
     * @param to Recipient's address
     * @param value Amount to mint
     * @param tokenContract Token contract address
     */
    function safeMint(
        address to,
        uint256 value,
        address tokenContract
    ) internal {
        bytes memory data = abi.encodeWithSelector(_MINT_SELECTOR, to, value);
        Address.functionCall(tokenContract, data, "MinterUtil: mint failed");
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

pragma solidity ^0.8.0;

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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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