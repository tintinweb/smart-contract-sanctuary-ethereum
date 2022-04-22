//SPDX-License-Identifier:996ICU AND apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

/// @title A contract for these who prepared for their last words and arrange business after their death.
/// @author huanmie<[email protected]>
/// @notice IMPORTANT: Do not save any important data direct to blockchain cause anyone can see it.
/// For any message private you should encryption it first.
contract LastWords
{
	using Address for address;

	struct Arrangements
	{
		uint120 when;
		bool only_execute_once;
		string message;
		bytes data;
	}

	struct Extra
	{
		address contract_address;
		bytes condition_data;
		bytes action_data;
	}

	// Last words for public.
	mapping (address=>string) public last_words;
	mapping (address=>mapping (address=>bool)) has_arrangements;
	mapping (address=>mapping (address=>Arrangements)) arrangements;

	event Arrangement(string message,bytes data);
	/// @param who doesn't have any arrangements for @param you.
	error DontHaveArrangements(address who,address you);
	/// After @param time (unix timestamp) you can execute arrangements.
	error NotEnoughTime(uint120 time);
	/// Failed to pass extra condition check.
	error ExtraConditionCheckFailed();
	/// Should use ExecuteArrangementsOnce instead.
	error RestrictedCall(string suggest_method);

	/// @notice extra condition check and extra process.
	/// @dev check(bytes) signature for extra condition check and only if it returns true ExecuteArrangements will allow continue execution.
	/// process(bytes) signature for extra action.
	mapping (address=>bool) has_extra;
	mapping (address=>Extra) extra;

	function SetLastWords(string calldata message) external
	{
		last_words[msg.sender]=message;
	}

	function GetLastWords(address who) external view returns(string memory)
	{
		return last_words[who];
	}

	/// @notice SetArrangements
	/// @param only_execute_once allow only success execute ExecuteArrangements once. Default value is false means you can execute any times if only you passed all the checks.
	function SetArrangements(address who,uint120 when,bool only_execute_once,string calldata message,bytes calldata data) external
	{
		has_arrangements[msg.sender][who]=true;
		arrangements[msg.sender][who]=Arrangements(when,only_execute_once,message,data);
	}

	function SetExtra(address contract_address,bytes calldata condition_data,bytes calldata action_data) external
	{
		has_extra[msg.sender]=true;
		extra[msg.sender]=Extra(contract_address,condition_data,action_data);
	}

	function ExecuteArrangements(address who) public view returns(string memory message,bytes memory data)
	{
		Arrangements storage arrangement=arrangements[who][msg.sender];
		//check conditions
		if(arrangement.only_execute_once)
			revert RestrictedCall("ExecuteArrangementsOnce");
		if(has_extra[who])
			revert RestrictedCall("ExecuteArrangementsWithExtra");
		if(!has_arrangements[who][msg.sender])
			revert DontHaveArrangements(who,msg.sender);
		if(block.timestamp<arrangement.when)
			revert NotEnoughTime(arrangement.when);

		return (arrangement.message,arrangement.data);
	}

	function ExecuteArrangementsWithExtra(address who) public returns(string memory message,bytes memory data)
	{
		if(arrangements[who][msg.sender].only_execute_once)
			revert RestrictedCall("ExecuteArrangementsOnce");

		if(has_extra[who])
		{
			bytes memory payload=abi.encodeWithSignature("check(bytes)",extra[who].condition_data);
			bytes memory stream=extra[who].contract_address.functionCall(payload);
			if(!abi.decode(stream,(bool)))
				revert ExtraConditionCheckFailed();
			
			//temporarily remove flag
			has_extra[who]=false;
			(message,data)=ExecuteArrangements(who);
			has_extra[who]=true;

			payload=abi.encodeWithSignature("process(bytes)",extra[who].action_data);
			extra[who].contract_address.functionCall(payload);
		}
		else
			(message,data)=ExecuteArrangements(who);
		emit Arrangement(message, data);
	}

	function ExecuteArrangementsOnce(address who) external returns(string memory message,bytes memory data)
	{
		if(arrangements[who][msg.sender].only_execute_once)
		{
			arrangements[who][msg.sender].only_execute_once=false;
			(message,data)=has_extra[who]?ExecuteArrangementsWithExtra(who):ExecuteArrangements(who);
			//ensure only execute once.
			has_arrangements[who][msg.sender]=false;
		}
		else
			(message,data)=has_extra[who]?ExecuteArrangementsWithExtra(who):ExecuteArrangements(who);
		emit Arrangement(message, data);
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