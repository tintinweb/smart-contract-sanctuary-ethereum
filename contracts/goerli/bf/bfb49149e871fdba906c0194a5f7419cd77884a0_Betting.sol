/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

/**
 *Submitted for verification at BscScan.com on 2022-11-17
*/

/**
 *Submitted for verification at BscScan.com on 2022-11-17
*/

/**
 *Submitted for verification at BscScan.com on 2022-10-19
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-05
*/
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

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.8.7;

contract Betting{
    using SafeERC20 for IERC20;

    address public adminAddress; // address of the admin
    address public tokenAddress; // address of the USDC token

    bool public pause;
    
    uint256 public status;
    uint256 public winningResult;
    uint256 public betAmount;
    string public teamA;
    string public teamB;

    uint256 public totalBetAmount;
    uint256 public teamABetAmount;
    uint256 public teamBBetAmount;
    uint256 betsInSystem = 0;

    struct BetInfo {
        uint256 amount;
        bool withdraw;
        bool paidOut;
    }

    struct Bet {
        address bettorAddr;
        bool rewarded;
        string teamName; 
        uint256 betAmount;
    }

    struct BetDetailsPerTeam {
        uint256[] bets;
    }

    mapping(address => BetInfo) public teamALedger;
    mapping(address => BetInfo) public teamBLedger;
    mapping(uint256 => Bet) public betIdToBet;
    mapping(string => BetDetailsPerTeam) internal betPerTeam;

    address payable public ecoSystemWallet;
    uint256 public ecoSystemFeePercentage;    

    constructor(address payable _ecoSystemAddress, uint256 _ecoSystemFeePercentage, address _tokenAddress, uint256 _betAmount, string memory _teamA, string memory _teamB){
        ecoSystemWallet = _ecoSystemAddress;
        ecoSystemFeePercentage= _ecoSystemFeePercentage;
        adminAddress = msg.sender;
        tokenAddress = _tokenAddress;
        pause = false;
        status = 0;
        winningResult = 0;
        betAmount = _betAmount;
        teamA = _teamA;
        teamB = _teamB;
        totalBetAmount = 0;
        teamABetAmount = 0;
        teamBBetAmount = 0;

        uint256[] memory bets;
        betPerTeam[_teamA] = BetDetailsPerTeam(bets);
        betPerTeam[_teamB] = BetDetailsPerTeam(bets);
    }

    modifier whenNotPaused() {
        require(pause == false, "Contract is pause");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Not admin");
        _;
    }

    function findContractStatus() public view returns(string memory) {
        string memory _status;
        if(status == 0) {
            _status = "Not Open";
        } else if(status == 1) {
            _status = "Open";
        } else if(status == 2) {
            _status = "In Progress";
        } else if(status == 4) {
            _status = "closed";
        }

        return _status;
    }

    function updateContractStatus(uint256 _status) public onlyAdmin {
        status = _status;
    }

    function updateDAOWallet(address payable _ecoSystemAddress) public onlyAdmin {
        ecoSystemWallet = _ecoSystemAddress;
    }

    function updateBetComission(uint256 _ecoSystemFeePercentage) public onlyAdmin {
        ecoSystemFeePercentage= _ecoSystemFeePercentage;
    }

    function PlaceBet(string memory _teamName, uint256 _betAmount) public {
        require(betAmount == _betAmount, "price is wrong");
        require(status == 1, "contract is not accepting any bet");
        bool exists = false;
        if(keccak256(abi.encodePacked(_teamName)) == keccak256(abi.encodePacked(teamA)) || keccak256(abi.encodePacked(_teamName)) == keccak256(abi.encodePacked(teamB))) {
            exists = true;
        }
        require(exists, "invalid team");
        require(teamALedger[msg.sender].amount == 0, "you already place a bet on this match");
        require(teamBLedger[msg.sender].amount == 0, "you already place a bet on this match");

        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), _betAmount);

        betsInSystem++;
        uint256 newBetId = (betsInSystem);

        betIdToBet[newBetId] = Bet(msg.sender, false, _teamName, _betAmount);

        if(keccak256(abi.encodePacked(_teamName)) == keccak256(abi.encodePacked(teamA))) { 
            BetInfo storage betInfo = teamALedger[msg.sender];
            betInfo.amount = _betAmount;
            betInfo.withdraw = false;
            betInfo.paidOut = false;
            teamABetAmount += _betAmount; 
        }
        if(keccak256(abi.encodePacked(_teamName)) == keccak256(abi.encodePacked(teamB))) { 
            BetInfo storage betInfo = teamBLedger[msg.sender];
            betInfo.amount = _betAmount;
            betInfo.withdraw = false;
            betInfo.paidOut = false;

            teamBBetAmount += _betAmount; 
        }
        
        totalBetAmount += _betAmount;
        betPerTeam[_teamName].bets.push(newBetId);
    }

    function finaliseMatch(uint256 _winnerIndex ) public onlyAdmin {
        require(status == 2, "Match is not inProgress yet");
        require((_winnerIndex == 1 || _winnerIndex == 2 || _winnerIndex == 3 || _winnerIndex == 0), "invalid winning Flag");

        if( _winnerIndex == 1 || _winnerIndex == 2 || _winnerIndex == 3) {
            uint256 _ecoSystemBalance = (totalBetAmount * ecoSystemFeePercentage) > 100 ? (totalBetAmount * ecoSystemFeePercentage) / 100 : 0;
            uint256 _remainingBalance = totalBetAmount - _ecoSystemBalance;

            IERC20(tokenAddress).transfer(ecoSystemWallet, _ecoSystemBalance);
        
            if(_winnerIndex == 1) {
                uint256 _totalWinnerTeamBet = teamABetAmount;
                if( (betPerTeam[teamA].bets.length > 0) && (_totalWinnerTeamBet > 0) ){
                    uint256 _multiplierPercentage = (_remainingBalance * 100) /  _totalWinnerTeamBet;
                    for(uint256 i = 0; i < betPerTeam[teamA].bets.length; i++){
                        Bet memory tempBet = betIdToBet[betPerTeam[teamA].bets[i]];
                        if(keccak256(abi.encodePacked(tempBet.teamName)) == keccak256(abi.encodePacked(teamA))) {
                            uint256 _betAmount = tempBet.betAmount;
                            uint256 winAmount = (_betAmount * _multiplierPercentage) > 100 ? (_betAmount * _multiplierPercentage) / 100 : 0;
                            require(IERC20(tokenAddress).balanceOf(address(this)) >= winAmount, "Not enough funds to reward bettor");
                            IERC20(tokenAddress).transfer(tempBet.bettorAddr, winAmount);
                            teamALedger[tempBet.bettorAddr].paidOut = true;
                            tempBet.rewarded = true;
                        }
                    }
                }
            }
            if(_winnerIndex == 2) {
                uint256 _totalWinnerTeamBet = teamBBetAmount;
                if( (betPerTeam[teamB].bets.length > 0) && (_totalWinnerTeamBet > 0) ){
                    uint256 _multiplierPercentage = (_remainingBalance * 100) /  _totalWinnerTeamBet;
                    for(uint256 i = 0; i < betPerTeam[teamB].bets.length; i++){
                        Bet memory tempBet = betIdToBet[betPerTeam[teamB].bets[i]];
                        if(keccak256(abi.encodePacked(tempBet.teamName)) == keccak256(abi.encodePacked(teamB))) {
                            uint256 _betAmount = tempBet.betAmount;
                            uint256 winAmount = (_betAmount * _multiplierPercentage) > 100 ? (_betAmount * _multiplierPercentage) / 100 : 0;
                            require(IERC20(tokenAddress).balanceOf(address(this)) >= winAmount, "Not enough funds to reward bettor");
                            IERC20(tokenAddress).transfer(tempBet.bettorAddr, winAmount);
                            teamBLedger[tempBet.bettorAddr].paidOut = true;
                            tempBet.rewarded = true;
                        }
                    }
                }
            }
        
        }

        winningResult = _winnerIndex;
        status = 4;
    }

    function claimBetAmt() public {
        require(winningResult == 0, "race is not yet cancelled");
        require((teamALedger[msg.sender].amount > 0 || teamBLedger[msg.sender].amount > 0), " no bet is placed in this match");

        uint256 _betAmt;
        string memory _teamName;
        if(teamALedger[msg.sender].amount > 0) {
            _betAmt = teamALedger[msg.sender].amount;
            _teamName = teamA;
            require(!teamALedger[msg.sender].withdraw, "amount already withdrawn");
        }
        if(teamBLedger[msg.sender].amount > 0) {
            _betAmt = teamBLedger[msg.sender].amount;
            _teamName = teamB;
            require(!teamBLedger[msg.sender].withdraw, "amount already withdrawn");
        }
        
        IERC20(tokenAddress).transfer(msg.sender, _betAmt);

        if(keccak256(abi.encodePacked(_teamName)) == keccak256(abi.encodePacked(teamA))) {
            teamALedger[msg.sender].withdraw = true;
        }

        if(keccak256(abi.encodePacked(_teamName)) == keccak256(abi.encodePacked(teamB))) {
            teamBLedger[msg.sender].withdraw = true;
        }
    }

    function teamAbetCount() public view returns(uint256) {
        return betPerTeam[teamA].bets.length;
    }

    function teamBbetCount() public view returns(uint256) {
        return betPerTeam[teamB].bets.length;
    }    

    function teamAbetValue() public view returns(uint256) {
        return teamABetAmount;
    }
   
    function teamBbetValue() public view returns(uint256) {
        return teamBBetAmount;
    }

    function totalPotValue() public view returns(uint256) {
        return totalBetAmount;
    }

    function pauseContract(bool _status) public onlyAdmin {
        pause = _status;
    }

    function GetUnStuckBalance(address receiver) public onlyAdmin{
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(receiver, balance);
    }

  receive() payable external {}
}