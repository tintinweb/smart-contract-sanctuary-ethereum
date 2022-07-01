// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// mainly used for governed-owner to do infrequent sgn/cbridge owner operations,
// relatively prefer easy-to-use over gas-efficiency
contract SimpleGovernance {
    uint256 public constant THRESHOLD_DECIMAL = 100;
    uint256 public constant MIN_ACTIVE_PERIOD = 3600; // one hour
    uint256 public constant MAX_ACTIVE_PERIOD = 2419200; // four weeks

    using SafeERC20 for IERC20;

    enum ParamName {
        ActivePeriod,
        QuorumThreshold, // default threshold for votes to pass
        FastPassThreshold // lower threshold for less critical operations
    }

    enum ProposalType {
        ExternalDefault,
        ExternalFastPass,
        InternalParamChange,
        InternalVoterUpdate,
        InternalProxyUpdate,
        InternalTransferToken
    }

    mapping(ParamName => uint256) public params;

    struct Proposal {
        bytes32 dataHash; // hash(proposalType, targetAddress, calldata)
        uint256 deadline;
        mapping(address => bool) votes;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;

    address[] public voters;
    mapping(address => uint256) public voterPowers; // voter addr -> voting power

    // NOTE: proxies must be audited open-source non-upgradable contracts with following requirements:
    // 1. Truthfully pass along tx sender who called the proxy function as the governance proposer.
    // 2. Do not allow arbitrary fastpass proposal with calldata constructed by the proxy callers.
    // See ./proxies/CommonOwnerProxy.sol for example.
    mapping(address => bool) public proposerProxies;

    event Initiated(
        address[] voters,
        uint256[] powers,
        address[] proxies,
        uint256 activePeriod,
        uint256 quorumThreshold,
        uint256 fastPassThreshold
    );

    event ProposalCreated(
        uint256 proposalId,
        ProposalType proposalType,
        address target,
        bytes data,
        uint256 deadline,
        address proposer
    );
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);

    event ParamChangeProposalCreated(uint256 proposalId, ParamName name, uint256 value);
    event VoterUpdateProposalCreated(uint256 proposalId, address[] voters, uint256[] powers);
    event ProxyUpdateProposalCreated(uint256 proposalId, address[] addrs, bool[] ops);
    event TransferTokenProposalCreated(uint256 proposalId, address receiver, address token, uint256 amount);

    constructor(
        address[] memory _voters,
        uint256[] memory _powers,
        address[] memory _proxies,
        uint256 _activePeriod,
        uint256 _quorumThreshold,
        uint256 _fastPassThreshold
    ) {
        require(_voters.length > 0 && _voters.length == _powers.length, "invalid init voters");
        require(_activePeriod <= MAX_ACTIVE_PERIOD && _activePeriod >= MIN_ACTIVE_PERIOD, "invalid active period");
        require(
            _quorumThreshold < THRESHOLD_DECIMAL && _fastPassThreshold <= _quorumThreshold,
            "invalid init thresholds"
        );
        for (uint256 i = 0; i < _voters.length; i++) {
            _setVoter(_voters[i], _powers[i]);
        }
        for (uint256 i = 0; i < _proxies.length; i++) {
            proposerProxies[_proxies[i]] = true;
        }
        params[ParamName.ActivePeriod] = _activePeriod;
        params[ParamName.QuorumThreshold] = _quorumThreshold;
        params[ParamName.FastPassThreshold] = _fastPassThreshold;
        emit Initiated(_voters, _powers, _proxies, _activePeriod, _quorumThreshold, _fastPassThreshold);
    }

    /*********************************
     * External and Public Functions *
     *********************************/

    function createProposal(address _target, bytes memory _data) external returns (uint256) {
        return _createProposal(msg.sender, _target, _data, ProposalType.ExternalDefault);
    }

    // create proposal through proxy
    function createProposal(
        address _proposer,
        address _target,
        bytes memory _data,
        ProposalType _type
    ) external returns (uint256) {
        require(proposerProxies[msg.sender], "sender is not a valid proxy");
        require(_type == ProposalType.ExternalDefault || _type == ProposalType.ExternalFastPass, "invalid type");
        return _createProposal(_proposer, _target, _data, _type);
    }

    function createParamChangeProposal(ParamName _name, uint256 _value) external returns (uint256) {
        bytes memory data = abi.encode(_name, _value);
        uint256 proposalId = _createProposal(msg.sender, address(0), data, ProposalType.InternalParamChange);
        emit ParamChangeProposalCreated(proposalId, _name, _value);
        return proposalId;
    }

    function createVoterUpdateProposal(address[] calldata _voters, uint256[] calldata _powers)
        external
        returns (uint256)
    {
        require(_voters.length == _powers.length, "voters and powers length not match");
        bytes memory data = abi.encode(_voters, _powers);
        uint256 proposalId = _createProposal(msg.sender, address(0), data, ProposalType.InternalVoterUpdate);
        emit VoterUpdateProposalCreated(proposalId, _voters, _powers);
        return proposalId;
    }

    function createProxyUpdateProposal(address[] calldata _addrs, bool[] calldata _ops) external returns (uint256) {
        require(_addrs.length == _ops.length, "_addrs and _ops length not match");
        bytes memory data = abi.encode(_addrs, _ops);
        uint256 proposalId = _createProposal(msg.sender, address(0), data, ProposalType.InternalProxyUpdate);
        emit ProxyUpdateProposalCreated(proposalId, _addrs, _ops);
        return proposalId;
    }

    function createTransferTokenProposal(
        address _receiver,
        address _token,
        uint256 _amount
    ) external returns (uint256) {
        bytes memory data = abi.encode(_receiver, _token, _amount);
        uint256 proposalId = _createProposal(msg.sender, address(0), data, ProposalType.InternalTransferToken);
        emit TransferTokenProposalCreated(proposalId, _receiver, _token, _amount);
        return proposalId;
    }

    function voteProposal(uint256 _proposalId, bool _vote) external {
        require(voterPowers[msg.sender] > 0, "invalid voter");
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp < p.deadline, "deadline passed");
        p.votes[msg.sender] = _vote;
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeProposal(
        uint256 _proposalId,
        ProposalType _type,
        address _target,
        bytes calldata _data
    ) external {
        require(voterPowers[msg.sender] > 0, "only voter can execute a proposal");
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp < p.deadline, "deadline passed");
        require(keccak256(abi.encodePacked(_type, _target, _data)) == p.dataHash, "data hash not match");
        p.deadline = 0;

        p.votes[msg.sender] = true;
        (, , bool pass) = countVotes(_proposalId, _type);
        require(pass, "not enough votes");

        if (_type == ProposalType.ExternalDefault || _type == ProposalType.ExternalFastPass) {
            (bool success, bytes memory res) = _target.call(_data);
            require(success, _getRevertMsg(res));
        } else if (_type == ProposalType.InternalParamChange) {
            (ParamName name, uint256 value) = abi.decode((_data), (ParamName, uint256));
            params[name] = value;
            if (name == ParamName.ActivePeriod) {
                require(value <= MAX_ACTIVE_PERIOD && value >= MIN_ACTIVE_PERIOD, "invalid active period");
            } else if (name == ParamName.QuorumThreshold || name == ParamName.FastPassThreshold) {
                require(
                    params[ParamName.QuorumThreshold] >= params[ParamName.FastPassThreshold] &&
                        value < THRESHOLD_DECIMAL &&
                        value > 0,
                    "invalid threshold"
                );
            }
        } else if (_type == ProposalType.InternalVoterUpdate) {
            (address[] memory addrs, uint256[] memory powers) = abi.decode((_data), (address[], uint256[]));
            for (uint256 i = 0; i < addrs.length; i++) {
                if (powers[i] > 0) {
                    _setVoter(addrs[i], powers[i]);
                } else {
                    _removeVoter(addrs[i]);
                }
            }
        } else if (_type == ProposalType.InternalProxyUpdate) {
            (address[] memory addrs, bool[] memory ops) = abi.decode((_data), (address[], bool[]));
            for (uint256 i = 0; i < addrs.length; i++) {
                if (ops[i]) {
                    proposerProxies[addrs[i]] = true;
                } else {
                    delete proposerProxies[addrs[i]];
                }
            }
        } else if (_type == ProposalType.InternalTransferToken) {
            (address receiver, address token, uint256 amount) = abi.decode((_data), (address, address, uint256));
            _transfer(receiver, token, amount);
        }
        emit ProposalExecuted(_proposalId);
    }

    receive() external payable {}

    /**************************
     *  Public View Functions *
     **************************/

    function getVoters() public view returns (address[] memory, uint256[] memory) {
        address[] memory addrs = new address[](voters.length);
        uint256[] memory powers = new uint256[](voters.length);
        for (uint32 i = 0; i < voters.length; i++) {
            addrs[i] = voters[i];
            powers[i] = voterPowers[voters[i]];
        }
        return (addrs, powers);
    }

    function getVote(uint256 _proposalId, address _voter) public view returns (bool) {
        return proposals[_proposalId].votes[_voter];
    }

    function countVotes(uint256 _proposalId, ProposalType _type)
        public
        view
        returns (
            uint256,
            uint256,
            bool
        )
    {
        uint256 yesVotes;
        uint256 totalPower;
        for (uint32 i = 0; i < voters.length; i++) {
            if (getVote(_proposalId, voters[i])) {
                yesVotes += voterPowers[voters[i]];
            }
            totalPower += voterPowers[voters[i]];
        }
        uint256 threshold;
        if (_type == ProposalType.ExternalFastPass) {
            threshold = params[ParamName.FastPassThreshold];
        } else {
            threshold = params[ParamName.QuorumThreshold];
        }
        bool pass = (yesVotes >= (totalPower * threshold) / THRESHOLD_DECIMAL);
        return (totalPower, yesVotes, pass);
    }

    /**********************************
     * Internal and Private Functions *
     **********************************/

    // create a proposal and vote yes
    function _createProposal(
        address _proposer,
        address _target,
        bytes memory _data,
        ProposalType _type
    ) private returns (uint256) {
        require(voterPowers[_proposer] > 0, "only voter can create a proposal");
        uint256 proposalId = nextProposalId;
        nextProposalId += 1;
        Proposal storage p = proposals[proposalId];
        p.dataHash = keccak256(abi.encodePacked(_type, _target, _data));
        p.deadline = block.timestamp + params[ParamName.ActivePeriod];
        p.votes[_proposer] = true;
        emit ProposalCreated(proposalId, _type, _target, _data, p.deadline, _proposer);
        return proposalId;
    }

    function _setVoter(address _voter, uint256 _power) private {
        require(_power > 0, "zero power");
        if (voterPowers[_voter] == 0) {
            // add new voter
            voters.push(_voter);
        }
        voterPowers[_voter] = _power;
    }

    function _removeVoter(address _voter) private {
        require(voterPowers[_voter] > 0, "not a voter");
        uint256 lastIndex = voters.length - 1;
        for (uint256 i = 0; i < voters.length; i++) {
            if (voters[i] == _voter) {
                if (i < lastIndex) {
                    voters[i] = voters[lastIndex];
                }
                voters.pop();
                voterPowers[_voter] = 0;
                return;
            }
        }
        revert("voter not found"); // this should never happen
    }

    function _transfer(
        address _receiver,
        address _token,
        uint256 _amount
    ) private {
        if (_token == address(0)) {
            (bool sent, ) = _receiver.call{value: _amount, gas: 50000}("");
            require(sent, "failed to send native token");
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }

    // https://ethereum.stackexchange.com/a/83577
    // https://github.com/Uniswap/v3-periphery/blob/v1.0.0/contracts/base/Multicall.sol
    function _getRevertMsg(bytes memory _returnData) private pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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