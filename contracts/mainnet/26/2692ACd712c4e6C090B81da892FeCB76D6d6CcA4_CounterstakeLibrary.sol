/**
 *Submitted for verification at Etherscan.io on 2023-03-09
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



// File: contracts/CounterstakeLibrary.sol

// The purpose of the library is to separate some of the code out of the Export/Import contracts and keep their sizes under the 24KiB limit



library CounterstakeLibrary {

	using SafeERC20 for IERC20;

	enum Side {no, yes}

	// small values (bool, uint32, ...) are grouped together in order to be packed efficiently
	struct Claim {
		uint amount;
	//	int reward;

		address payable recipient_address; // 20 bytes, 12 bytes left
		uint32 txts;
		uint32 ts;
		
		address payable claimant_address;
		uint32 expiry_ts;
		uint16 period_number;
		Side current_outcome;
		bool is_large;
		bool withdrawn;
		bool finished;
		
		string sender_address;
	//	string txid;
		string data;
		uint yes_stake;
		uint no_stake;
	//	uint challenging_target;
	}

	struct Settings {
		address tokenAddress;
		uint16 ratio100;// = 100;
		uint16 counterstake_coef100;// = 150;
		uint32 min_tx_age;
		uint min_stake;
		uint[] challenging_periods;// = [12 hours, 3 days, 1 weeks, 30 days];
		uint[] large_challenging_periods;// = [3 days, 1 weeks, 30 days];
		uint large_threshold;
	}

	event NewClaim(uint indexed claim_num, address author_address, string sender_address, address recipient_address, string txid, uint32 txts, uint amount, int reward, uint stake, string data, uint32 expiry_ts);
	event NewChallenge(uint indexed claim_num, address author_address, uint stake, Side outcome, Side current_outcome, uint yes_stake, uint no_stake, uint32 expiry_ts, uint challenging_target);
	event FinishedClaim(uint indexed claim_num, Side outcome);


	struct ClaimRequest {
		string txid;
		uint32 txts;
		uint amount;
		int reward;
		uint stake;
		uint required_stake;
		address payable recipient_address;
		string sender_address;
		string data;
	}

	function claim(
		Settings storage settings,
		mapping(string => uint) storage claim_nums,
		mapping(uint => Claim) storage claims,
		mapping(uint => mapping(Side => mapping(address => uint))) storage stakes,
		uint claim_num,
		ClaimRequest memory req
	) external {
		require(req.amount > 0, "0 claim");
		require(req.stake >= req.required_stake, "the stake is too small");
		require(block.timestamp >= req.txts + settings.min_tx_age, "too early");
		if (req.recipient_address == address(0))
			req.recipient_address = payable(msg.sender);
		if (req.reward < 0)
			require(req.recipient_address == payable(msg.sender), "the sender disallowed third-party claiming by setting a negative reward");
		string memory claim_id = getClaimId(req.sender_address, req.recipient_address, req.txid, req.txts, req.amount, req.reward, req.data);
		require(claim_nums[claim_id] == 0, "this transfer has already been claimed");
		bool is_large = (settings.large_threshold > 0 && req.stake >= settings.large_threshold);
		uint32 expiry_ts = uint32(block.timestamp + getChallengingPeriod(settings, 0, is_large)); // might wrap
		claim_nums[claim_id] = claim_num;
	//	uint challenging_target = req.stake * settings.counterstake_coef100/100;
		claims[claim_num] = Claim({
			amount: req.amount,
		//	reward: req.reward,
			recipient_address: req.recipient_address,
			claimant_address: payable(msg.sender),
			sender_address: req.sender_address,
		//	txid: req.txid,
			data: req.data,
			yes_stake: req.stake,
			no_stake: 0,
			current_outcome: Side.yes,
			is_large: is_large,
			period_number: 0,
			txts: req.txts,
			ts: uint32(block.timestamp),
			expiry_ts: expiry_ts,
		//	challenging_target: req.stake * settings.counterstake_coef100/100,
			withdrawn: false,
			finished: false
		});
		stakes[claim_num][Side.yes][msg.sender] = req.stake;
		emit NewClaim(claim_num, msg.sender, req.sender_address, req.recipient_address, req.txid, req.txts, req.amount, req.reward, req.stake, req.data, expiry_ts);
	//	return claim_id;
	}


	function challenge(
		Settings storage settings, 
		Claim storage c,
		mapping(uint => mapping(Side => mapping(address => uint))) storage stakes, 
		uint claim_num, 
		Side stake_on, 
		uint stake
	) external {
		require(block.timestamp < c.expiry_ts, "the challenging period has expired");
		require(stake_on != c.current_outcome, "this outcome is already current");
		uint excess;
		uint challenging_target = (c.current_outcome == Side.yes ? c.yes_stake : c.no_stake) * settings.counterstake_coef100/100;
		{ // circumvent stack too deep
			uint stake_on_proposed_outcome = (stake_on == Side.yes ? c.yes_stake : c.no_stake) + stake;
			bool would_override_current_outcome = stake_on_proposed_outcome >= challenging_target;
			excess = would_override_current_outcome ? stake_on_proposed_outcome - challenging_target : 0;
			uint accepted_stake = stake - excess;
			if (stake_on == Side.yes)
				c.yes_stake += accepted_stake;
			else
				c.no_stake += accepted_stake;
			if (would_override_current_outcome){
				c.period_number++;
				c.current_outcome = stake_on;
				c.expiry_ts = uint32(block.timestamp + getChallengingPeriod(settings, c.period_number, c.is_large));
				challenging_target = challenging_target * settings.counterstake_coef100/100;
			}
			stakes[claim_num][stake_on][msg.sender] += accepted_stake;
		}
		emit NewChallenge(claim_num, msg.sender, stake, stake_on, c.current_outcome, c.yes_stake, c.no_stake, c.expiry_ts, challenging_target);
		if (excess > 0){
			if (settings.tokenAddress == address(0))
				payable(msg.sender).transfer(excess);
			else
				IERC20(settings.tokenAddress).safeTransfer(msg.sender, excess);
		}
	}



	function finish(
		Claim storage c,
		mapping(uint => mapping(Side => mapping(address => uint))) storage stakes, 
		uint claim_num, 
		address payable to_address
	) external 
	returns (bool, bool, uint)
	{
		require(block.timestamp > c.expiry_ts, "challenging period is still ongoing");
		if (to_address == address(0))
			to_address = payable(msg.sender);
		
		bool is_winning_claimant = (to_address == c.claimant_address && c.current_outcome == Side.yes);
		require(!(is_winning_claimant && c.withdrawn), "already withdrawn");
		uint won_stake;
		{ // circumvent stack too deep
			uint my_stake = stakes[claim_num][c.current_outcome][to_address];
			require(my_stake > 0 || is_winning_claimant, "you are not the recipient and you didn't stake on the winning outcome or you have already withdrawn");
			uint winning_stake = c.current_outcome == Side.yes ? c.yes_stake : c.no_stake;
			if (my_stake > 0)
				won_stake = (c.yes_stake + c.no_stake) * my_stake / winning_stake;
		}
		if (is_winning_claimant)
			c.withdrawn = true;
		bool finished;
		if (!c.finished){
			finished = true;
			c.finished = true;
		//	Side losing_outcome = outcome == Side.yes ? Side.no : Side.yes;
		//	delete stakes[claim_id][losing_outcome]; // can't purge the stakes that will never be claimed
			emit FinishedClaim(claim_num, c.current_outcome);
		}
		delete stakes[claim_num][c.current_outcome][to_address];
		return (finished, is_winning_claimant, won_stake);
	}



	function getChallengingPeriod(Settings storage settings, uint16 period_number, bool bLarge) public view returns (uint) {
		uint[] storage periods = bLarge ? settings.large_challenging_periods : settings.challenging_periods;
		if (period_number > periods.length - 1)
			period_number = uint16(periods.length - 1);
		return periods[period_number];
	}

	function validateChallengingPeriods(uint[] memory periods) pure external {
		require(periods.length > 0, "empty periods");
		uint prev_period = 0;
		for (uint i = 0; i < periods.length; i++) {
			require(periods[i] < 3 * 365 days, "some periods are longer than 3 years");
			require(periods[i] >= prev_period, "subsequent periods cannot get shorter");
			prev_period = periods[i];
		}
	}

	function getClaimId(string memory sender_address, address recipient_address, string memory txid, uint32 txts, uint amount, int reward, string memory data) public pure returns (string memory){
		return string(abi.encodePacked(sender_address, '_', toAsciiString(recipient_address), '_', txid, '_', uint2str(txts), '_', uint2str(amount), '_', int2str(reward), '_', data));
	}


	function uint2str(uint256 _i) private pure returns (string memory) {
		if (_i == 0)
			return "0";
		uint256 j = _i;
		uint256 length;
		while (j != 0) {
			length++;
			j /= 10;
		}
		bytes memory bstr = new bytes(length);
		uint256 k = length;
		j = _i;
		while (j != 0) {
			bstr[--k] = bytes1(uint8(48 + j % 10));
			j /= 10;
		}
		return string(bstr);
	}

	function int2str(int256 _i) private pure returns (string memory) {
		require(_i < type(int).max, "int too large");
		return _i >= 0 ? uint2str(uint(_i)) : string(abi.encodePacked('-', uint2str(uint(-_i))));
	}

	function toAsciiString(address x) private pure returns (string memory) {
		bytes memory s = new bytes(40);
		for (uint i = 0; i < 20; i++) {
			bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
			bytes1 hi = bytes1(uint8(b) / 16);
			bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
			s[2*i] = char(hi);
			s[2*i+1] = char(lo);            
		}
		return string(s);
	}

	function char(bytes1 b) private pure returns (bytes1 c) {
		if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
		else return bytes1(uint8(b) + 0x57);
	}

	function isContract(address _addr) public view returns (bool){
		uint32 size;
		assembly {
			size := extcodesize(_addr)
		}
		return (size > 0);
	}
}