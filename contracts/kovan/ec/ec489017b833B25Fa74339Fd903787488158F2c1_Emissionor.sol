// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;

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
        require(
            address(this).balance >= amount,
            'Address: insufficient balance'
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(
            success,
            'Address: unable to send value, recipient may have reverted'
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, 'Address: low-level call failed');
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
                'Address: low-level call with value failed'
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
            'Address: insufficient balance for call'
        );
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
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
                'Address: low-level static call failed'
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
        require(isContract(target), 'Address: static call to non-contract');

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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                'Address: low-level delegate call failed'
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
        require(isContract(target), 'Address: delegate call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeERC20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
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
            'SafeERC20: low-level call failed'
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                'SafeERC20: ERC20 operation did not succeed'
            );
        }
    }
}

interface IOwnable {
    function owner() external view returns (address);

    function renounceManagement(string memory confirm) external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;
}

contract Ownable is IOwnable {
    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipPulled(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipPulled(address(0), _owner);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    function renounceManagement(string memory confirm)
        public
        virtual
        override
        onlyOwner
    {
        require(
            keccak256(abi.encodePacked(confirm)) ==
                keccak256(abi.encodePacked('confirm renounce')),
            "Ownable: renouce needs 'confirm renounce' as input"
        );
        emit OwnershipPushed(_owner, address(0));
        _owner = address(0);
        _newOwner = address(0);
    }

    function pushManagement(address newOwner_)
        public
        virtual
        override
        onlyOwner
    {
        require(
            newOwner_ != address(0),
            'Ownable: new owner is the zero address'
        );
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, 'Ownable: must be new owner to pull');
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
    }
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function mint(address account_, uint256 amount_) external;

    function decimals() external view returns (uint8);

    function burnFrom(address account_, uint256 amount_) external;
}

interface IRewardReceiver {
    function receiveReward(uint256 amount) external;
}

abstract contract RewardReceiver is IRewardReceiver, Ownable {
    event Log(uint256 value);
    address public rewardToken;

    function receiveReward(uint256 amount) external override {
        IERC20(rewardToken).transferFrom(msg.sender, address(this), amount);
        onRewardReceived(amount);
    }

    function onRewardReceived(uint256 amount) internal virtual;

    function setRewardToken(address _rewardToken) external onlyOwner {
        require(rewardToken == address(0) && _rewardToken != address(0));
        rewardToken = _rewardToken;
    }
}

interface ITreasury {
    function mintRewards(address _recipient, uint256 _amount) external;
}

contract Emissionor is Ownable {
    using SafeERC20 for IERC20;

    struct EmissionInfo {
        uint256 amount;
        bool isActive;
    }

    /* ====== VARIABLES ====== */
    address public rewardToken;
    address public treasury;
    IRewardReceiver public splitter;

    uint256 totalSentToSplitter; //Tracking rewards sent to splitter contract
    uint8 constant DAYS_IN_A_WEEK = 7; //number of days reward accumulated

    uint256 public distributionRemainingTime;

    mapping(uint256 => EmissionInfo) public emissions; //first second of every week as the key, the value includes the amount and status
    uint256[] public emissionBegins; //emssions' begin timestamp
    uint256 lastEmittedTimestamp; //last emitReward timestamp

    event RewardsDistributed(
        address indexed caller,
        address indexed recipient,
        uint256 amount
    );

    constructor(
        address _treasury,
        address _splitter,
        address _rewardToken
    ) {
        require(_treasury != address(0));
        treasury = _treasury;

        require(_splitter != address(0));
        splitter = IRewardReceiver(_splitter);

        require(_rewardToken != address(0));
        rewardToken = _rewardToken;
    }

    /* ====== PUBLIC FUNCTIONS ====== */

    /* ====== INTERNAL FUNCTIONS ====== */

    function initialize(
        uint256 startTimestamp,
        uint256[] memory amounts,
        uint256 checkSum
    ) external onlyOwner {
        require(
            startTimestamp > block.timestamp,
            'Start timestamp should be in the future'
        );

        uint256 secondsOfWeek = startTimestamp % 7 days;
        uint256 begin = startTimestamp - secondsOfWeek;
        uint256 length = amounts.length;
        uint256 sum = 0;

        for (uint256 i = 0; i < length; i++) {
            uint256 amount = amounts[i];
            require(amount > 0, 'Invalid amount');

            EmissionInfo storage info = emissions[begin];
            require(info.amount == 0 || info.isActive, 'Already initialized');

            if (info.amount == 0) {
                emissionBegins.push(begin);
                info.isActive = true;
            }
            info.amount = amount;

            begin += 7 days;
            sum += amount;
        }

        require(sum == checkSum, 'Incorrect check sum');
    }

    function emitReward() external onlyOwner {
        uint256 reward = 0;

        uint256 length = emissionBegins.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 begin = emissionBegins[i];

            if (begin > lastEmittedTimestamp && begin <= block.timestamp) {
                EmissionInfo storage info = emissions[begin];

                if (info.isActive) {
                    info.isActive = false;
                    reward += info.amount;
                }
            }
        }

        if (reward > 0) {
            //mint rewards from treasury
            ITreasury(treasury).mintRewards(address(this), reward);

            require(
                IERC20(rewardToken).balanceOf(address(this)) > 0,
                'No reward to distribute'
            );

            IERC20(rewardToken).approve(address(splitter), reward);

            //send rewards to splitter
            IRewardReceiver(splitter).receiveReward(reward);

            emit RewardsDistributed(msg.sender, address(splitter), reward);

            //Reset reward
            totalSentToSplitter += reward;
        }

        lastEmittedTimestamp = block.timestamp;
        distributionRemainingTime = getEndTime();
    }

    /* ====== VIEW FUNCTIONS ====== */

    function isEmissionActive(uint256 timestamp) external view returns (bool) {
        uint256 secondsOfWeek = timestamp % 7 days;
        uint256 begin = timestamp - secondsOfWeek;

        return emissions[begin].isActive;
    }

    function getBeginTime() public view returns (uint256) {
        uint256 time = block.timestamp;
        uint256 secondsOfWeek = time % 7 days;
        uint256 begin = time - secondsOfWeek;

        return begin;
    }

    function getEndTime() public view returns (uint256) {
        uint256 time = block.timestamp;
        uint256 secondsOfWeek = time % 7 days;
        uint256 begin = time - secondsOfWeek;
        uint256 end = begin + 7 days - 1;

        return end;
    }

    /* ====== POLICY FUNCTIONS ====== */

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0));
        treasury = _treasury;
    }

    function setSplitterContract(address _splitter) external onlyOwner {
        require(_splitter != address(0));
        splitter = IRewardReceiver(_splitter);
    }

    function setRewardToken(address _rewardToken) external onlyOwner {
        require(_rewardToken != address(0));
        rewardToken = _rewardToken;
    }
}