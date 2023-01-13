/*
    Copyright 2022 Galxe.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

import {Address} from "Address.sol";
import {SafeMath} from "SafeMath.sol";
import {IERC20} from "IERC20.sol";
import {EIP712} from "EIP712.sol";
import {ECDSA} from "ECDSA.sol";

/**
 * @title TokenReward
 * @author Galxe
 *
 * TokenReward contract that allows privileged DAOs to initiate token reward campaigns for members to claim token reward.
 */
contract TokenReward is EIP712 {
    using Address for address;
    using SafeMath for uint256;

    /* ============ Events ============ */
    event EventPausedUpdate(bool _oldStatus, bool _newStatus);
    event EventOwnerUpdate(address _oldOwner, address _newOwner);
    event EventSignerUpdate(address _oldSigner, address _newSigner);

    event EventWhitelistTokenAdd(address _token);
    event EventWhitelistTokenRemove(address _token);

    event EventActivateCampaign(
        uint256 indexed cid,
        address admin,
        address token,
        uint256 amountPerAddress,
        uint256 totalAddress,
        uint256 startTime,
        uint256 endTime
    );

    event EventCampaignAdminUpdate(uint256 indexed _cid, address _oldAdmin, address _newAdmin);
    event EventCampaignTimeUpdate(
        uint256 indexed _cid,
        uint256 _oldStartTime,
        uint256 _newStartTime,
        uint256 _oldEndTime,
        uint256 _newEndTime
    );

    event EventWithdraw(uint256 indexed _cid, address _token, uint256 _amount, address _admin);

    event EventClaim(
        uint256 indexed _cid,
        address _token,
        uint256 _amount,
        uint256 _dummyId,
        address _claimTo
    );


    /* ============ Modifiers ============ */

    /**
     * Throws if the contract paused
     */
    modifier onlyNoPaused() {
        _validateOnlyNotPaused();
        _;
    }

    /* ============ Structs ============ */

    struct CampaignConfig {
        address admin; // campaign admin, only admin can withdraw
        address token; // zero address is native token.
        uint256 amountPerAddress;
        uint64 totalAddress;
        uint64 startTime; // campaign start time
        uint64 endTime; // campaign end time
        uint64 claimed; // count of claimed the reward
    }

    /* ============ State Variables ============ */
    // Is contract paused.
    bool public paused;

    // Contract owner
    address public owner;

    // Galxe Signer
    address public signer;

    // Campaign configuration
    mapping(uint256 => CampaignConfig) public campaignConfigs;

    // hasMinted(dummyID(signature) => bool) that records if the user account has already used the dummyID(signature).
    mapping(uint256 => bool) public hasMinted;

    mapping(bytes => bool) public usedSignatures;

    /* ============ Constructor ============ */
    constructor(
        address _owner,
        address _signer
    ) EIP712("GalxeTR", "1.0.0") {
        require(_owner != address(0), "Owner address must not be null address");
        owner = _owner;
        signer = _signer;

        emit EventOwnerUpdate(address(0), _owner);
        emit EventSignerUpdate(address(0), _signer);
    }

    /* ============ External Functions ============ */

    function activateCampaign(
        uint256 _cid,
        address _token,
        uint256 _amountPerAddress,
        uint256 _totalAddress,
        uint256 _startTime,
        uint256 _endTime,
        bytes calldata _signature
    ) external payable onlyNoPaused {
        require(_amountPerAddress > 0, "Amount per address must be greater than zero");
        require(_totalAddress > 0, "Address count must be greater than zero");
        require(_startTime > 0 && _endTime > 0 && _startTime < _endTime, "Invalid campaign time");
        require(campaignConfigs[_cid].admin == address(0), "Campaign has been activated");
        require(
            _verify(
                _hashActiveCampaign(_cid, msg.sender, _token, _amountPerAddress, _totalAddress, _startTime, _endTime),
                _signature
            ),
            "Invalid signature"
        );

        campaignConfigs[_cid] = CampaignConfig(
            msg.sender,
            _token,
            _amountPerAddress,
            uint64(_totalAddress),
            uint64(_startTime),
            uint64(_endTime),
            0
        );

        uint256 totalTokenAmount = _amountPerAddress.mul(_totalAddress);
        if (_token == address(0)) {
            // use native token
            require(msg.value == totalTokenAmount, "Activate campaign fail, not enough token");
        } else {
            // use erc20
            bool deposit = IERC20(_token).transferFrom(msg.sender, address(this), totalTokenAmount);
            require(deposit, "Activate campaign fail, not enough token");
        }

        emit EventActivateCampaign(_cid, msg.sender, _token, _amountPerAddress, _totalAddress, _startTime, _endTime);
    }

    function withdraw(uint256 _cid) external {
        CampaignConfig storage config = campaignConfigs[_cid];
        require(config.endTime < block.timestamp || config.startTime > block.timestamp, "Campaign still running");
        require(config.claimed < config.totalAddress, "No more token to withdraw");
        if (config.startTime > block.timestamp) {
            // not start, only admin can withdraw
            require(config.admin == msg.sender, "Not the admin");
        }

        uint256 balance = uint256(config.totalAddress-config.claimed).mul(config.amountPerAddress);

        config.claimed = config.totalAddress;

        if (config.token == address(0)) {
            (bool success, ) = config.admin.call{value: balance}(new bytes(0));
            require(success, "Transfer failed");
        } else {
            bool success = IERC20(config.token).transfer(config.admin, balance);
            require(success, "Transfer failed");
        }

        emit EventWithdraw(_cid, config.token, balance, config.admin);
    }

    function claim(
        uint256 _cid,
        uint256 _dummyId,
        uint256 _expiredAt,
        address payable _claimTo,
        bytes calldata _signature
    ) external onlyNoPaused {
        require(!hasMinted[_dummyId], "Already claimed");
        require(_expiredAt < block.timestamp, "Signature expired");
        require(
            _verify(
                _hashClaim(_cid, _dummyId, _expiredAt, _claimTo),
                _signature
            ),
            "Invalid signature"
        );
        CampaignConfig storage config = campaignConfigs[_cid];
        require(config.endTime >= block.timestamp && config.startTime <= block.timestamp, "Not claim period");
        require(config.claimed < config.totalAddress, "No more reward available");
        
        hasMinted[_dummyId] = true;
        config.claimed = config.claimed + 1;

        if (config.token == address(0)) {
            (bool success, ) = _claimTo.call{value: config.amountPerAddress}(new bytes(0));
            require(success, "Transfer failed");
        } else {
            bool success = IERC20(config.token).transfer(_claimTo, config.amountPerAddress);
            require(success, "Transfer failed");
        }

        emit EventClaim(_cid, config.token, config.amountPerAddress, _dummyId, _claimTo);
    }

    function updateCampaignAdmin(uint256 _cid, uint256 _salt, address _admin, bytes calldata _signature) external {
        require(_admin != address(0), "Invalid address");
        CampaignConfig storage config = campaignConfigs[_cid];
        require(config.admin == msg.sender, "Not the admin");
        require(!usedSignatures[_signature], "Invalid signature");
        require(
            _verify(
                _hashUpdateCampaignAdmin(_cid, _salt, config.admin, _admin),
                _signature
            ),
            "Invalid signature"
        );

        usedSignatures[_signature] = true;

        emit EventCampaignAdminUpdate(_cid, config.admin, _admin);
        config.admin = _admin;
    }

    function updateCampaignTime(uint256 _cid, uint256 _salt, uint256 _startTime, uint256 _endTime, bytes calldata _signature) external {
        CampaignConfig storage config = campaignConfigs[_cid];
        require(config.admin == msg.sender, "Not the admin");
        require(config.endTime > _startTime, "Invalid start time");
        require(!usedSignatures[_signature], "Invalid signature");
        require(
            _verify(
                _hashUpdateCampaignTime(_cid, _salt, _startTime, _endTime),
                _signature
            ),
            "Invalid signature"
        );

        usedSignatures[_signature] = true;

        emit EventCampaignTimeUpdate(_cid, config.startTime, _startTime, config.endTime, _endTime);
        config.startTime = uint64(_startTime);
        config.endTime = uint64(_endTime);
    }

    function updateSigner(address _signer) external {
        require(msg.sender == owner, "Not the owner");
        require(_signer != address(0), "Invalid address");

        emit EventSignerUpdate(signer, _signer);
        signer = _signer;
    }

    function updateOwner(address _owner) external {
        require(msg.sender == owner, "Not the owner");
        require(owner != address(0), "Invalid address");

        emit EventOwnerUpdate(owner, _owner);
        owner = _owner;
    }

    function updatePaused(bool _paused) external {
        require(msg.sender == owner, "Not the owner");
        require(_paused != paused, "Invalid value");

        emit EventPausedUpdate(paused, _paused);
        paused = _paused;
    }

    receive() external payable {
        // anonymous transfer: to admin
        (bool success, ) = owner.call{value: msg.value}(
            new bytes(0)
        );
        require(success, "Transfer failed");
    }

    fallback() external payable {
        if (msg.value > 0) {
            // call non exist function: send to admin
            (bool success, ) = owner.call{value: msg.value}(new bytes(0));
            require(success, "Transfer failed");
        }
    }

    /* ============ Internal Functions ============ */
    function _hashActiveCampaign(
        uint256 _cid,
        address _admin,
        address _token,
        uint256 _amountPerAddress,
        uint256 _totalAddress,
        uint256 _startTime,
        uint256 _endTime
    ) private view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "ActiveCampaign(uint256 cid,address admin,address token,uint256 amountPerAddress,uint256 totalAddress,uint256 startTime,uint256 endTime)"
                    ),
                    _cid,
                    _admin,
                    _token,
                    _amountPerAddress,
                    _totalAddress,
                    _startTime,
                    _endTime
                )
            )
        );
    }

    function _hashUpdateCampaignAdmin(
        uint256 _cid,
        uint256 _salt,
        address _oldAdmin,
        address _newAdmin
    ) private view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "UpdateCampaignAdmin(uint256 cid,uint256 salt,address oldAdmin,address newAdmin)"
                    ),
                    _cid,
                    _salt,
                    _oldAdmin,
                    _newAdmin
                )
            )
        );
    }

    function _hashUpdateCampaignEndTime(
        uint256 _cid,
        uint256 _salt,
        uint256 _endTime
    ) public view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "UpdateCampaignEndTime(uint256 cid,uint256 salt,uint256 endTime)"
                    ),
                    _cid,
                    _salt,
                    _endTime
                )
            )
        );
    }

    function _hashUpdateCampaignTime(
        uint256 _cid,
        uint256 _salt,
        uint256 _startTime,
        uint256 _endTime
    ) private view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "UpdateCampaignTime(uint256 cid,uint256 salt,uint256 startTime,uint256 endTime)"
                    ),
                    _cid,
                    _salt,
                    _startTime,
                    _endTime
                )
            )
        );
    }

    function _hashWithdraw(
        uint256 _cid,
        address _admin
    ) public view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "Withdraw(uint256 cid,address admin)"
                    ),
                    _cid,
                    _admin
                )
            )
        );
    }

    function _hashClaim(
        uint256 _cid,
        uint256 _dummyId,
        uint256 _expiredAt,
        address _claimTo
    ) public view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "Claim(uint256 cid,uint256 dummyId,uint256 expiredAt,address claimTo)"
                    ),
                    _cid,
                    _dummyId,
                    _expiredAt,
                    _claimTo
                )
            )
        );
    }

    function _verify(bytes32 hash, bytes calldata signature)
    public // TODO
    view
    returns (bool)
    {
        return ECDSA.recover(hash, signature) == signer;
    }

    function _validateOnlyNotPaused() internal view {
        require(!paused, "Contract paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;
    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) internal {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = _getChainId();
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view virtual returns (bytes32) {
        if (_getChainId() == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                _getChainId(),
                address(this)
            )
        );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _getChainId() private view returns (uint256 chainId) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}