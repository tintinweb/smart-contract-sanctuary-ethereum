/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

// File: contracts/studentmanager/interfaces/IAccessControl.sol



pragma solidity >=0.8.0;

interface IAccessControl {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 role;
    }
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(bytes32 indexed role, address indexed account);

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function getRoleExist(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role) external;

    function addNewRoleAdmin(bytes32 role) external;

    function removeNewRoleAdmin(bytes32 role) external;
}

// File: contracts/studentmanager/interfaces/ISubjectContract.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface ISubjectContract {
    struct Subject {
        string Id;
        string urlMetadata;
        uint256 maxEntrant;
        address personInCharge;
        uint256 startTime;
        uint256 endTimeToRegister;
        uint256 endTime;
        uint256 endTimeToConfirm;
    }

    enum ScoreColumn {
        QT,
        GK,
        TH,
        CK,
        All
    }

    struct Student {
        address studentAddress;
        bool participantToTrue;
    }

    enum Status {
        Lock,
        Open,
        Close
    }

    event CreatedNewMission(uint256 indexed id);
    event Register(address _student);
    event CancelRegister(address _student);
    event Confirm(uint256 studentsAmount, uint256 timestamp);
    event UnConfirm(uint256 studentsAmount, uint256 timestamp);
    event Close(uint256 timestamp);

    function setBasicForSubject(
        string memory _subjectId,
        string memory _urlMetadata,
        uint256 _maxEntrant,
        address _persionInCharge,
        uint256 _startTime,
        uint256 _endTimeToRegister,
        uint256 _endTime,
        uint256 _endTimeToConfirm
    ) external;

    function start() external;

    function lock() external;

    function setScoreColumn(
        uint256 QT,
        uint256 GK,
        uint256 TH,
        uint256 CK
    ) external;

    function addStudentToSubject(address[] memory _students) external;

    function register() external;

    function cancelRegister() external;

    // function confirmCompletedAddress(
    //     address[] calldata _student,
    //     uint256[] calldata _score,
    //     ScoreColumn _column
    // ) external;

    function unConfirmCompletedAddress(address[] calldata _students) external;

    function close() external;
}

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// File: contracts/studentmanager/SubjectContract.sol

pragma solidity >=0.8.0;





contract SubjectContract is ISubjectContract, Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address public owner;
    Subject public subject;
    Status public status = Status.Lock;

    IAccessControl public accessControll;

    address[] public student;
    mapping(address => Student) public addressToStudent;
    mapping(address => mapping(ScoreColumn => uint256)) public score;
    uint256 public amount;
    mapping(address => bool) public completedAddress;

    mapping(ScoreColumn => uint256) public rate;
    // ti le diem, giua ki, cuoi ki, qua trinh

    modifier onlyLock() {
        require(status == Status.Lock, "SC: Only Lock");
        _;
    }

    modifier onlyOpen() {
        require(status == Status.Open, "SC: Only Open");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyRoleLecturer() {
        require(
            accessControll.hasRole(keccak256("LECTURER"), msg.sender),
            "MC: Only Lecturer"
        );
        _;
    }

    modifier onlyRoleStudent() {
        require(
            accessControll.hasRole(keccak256("STUDENT"), msg.sender),
            "MC: Only Student"
        );
        _;
    }

    constructor(
        address _owner,
        address _accessControll
    ) {
        owner = _owner;
        accessControll = IAccessControl(_accessControll);
    }

    function initialize(
        address _owner,
        address _accessControll
    ) public initializer{
        require(
            owner == address(0) 
            && address(accessControll) == address(0), "Initializable: contract is already initialized");
        owner = _owner;
        accessControll = IAccessControl(_accessControll);
    }

    function setBasicForSubject(
        string memory _subjectId,
        string memory _urlMetadata,
        uint256 _maxEntrant,
        address _persionInCharge,
        uint256 _startTime,
        uint256 _endTimeToRegister,
        uint256 _endTime,
        uint256 _endTimeToConfirm
    ) external override onlyOwner onlyLock {
        if (block.timestamp > _startTime) _startTime = block.timestamp;
        require(
                _startTime < _endTimeToRegister &&
                _endTimeToRegister < _endTime &&
                _endTime < _endTimeToConfirm,
            "SC: Time is invalid"
        );

        subject = Subject(
            _subjectId,
            _urlMetadata,
            _maxEntrant,
            _persionInCharge,
            _startTime,
            _endTimeToRegister,
            _endTime,
            _endTimeToConfirm
        );
    }

    function setScoreColumn(
        uint256 QT,
        uint256 GK,
        uint256 TH,
        uint256 CK
    ) external override {
        require(QT + GK + TH + CK == 10000, "SC: rate invalid");
        rate[ScoreColumn.QT] = QT;
        rate[ScoreColumn.GK] = GK;
        rate[ScoreColumn.TH] = TH;
        rate[ScoreColumn.CK] = CK;
    }

    function start() external override onlyOwner onlyLock {
        status = Status.Open;
    }

    function lock() external override onlyOwner onlyOpen {
        status = Status.Lock;
    }

    function addStudentToSubject(address[] calldata _students)
        external
        override
        onlyRoleLecturer
        onlyOpen
    {
        require(
            msg.sender == subject.personInCharge,
            "MC: Only the person in charge"
        );
        for (uint256 i = 0; i < _students.length; i++) {
            require(
                accessControll.hasRole(keccak256("STUDENT"), _students[i]),
                "Should only add student"
            );
            _register(_students[i]);
        }
    }

    function register() external override onlyOpen onlyRoleStudent {
        _register(msg.sender);
    }

    function _register(address _student) private {
        Student storage instance = addressToStudent[_student];
        if (!instance.participantToTrue) {
            amount++;
        if (instance.studentAddress != address(0)) {
            instance.participantToTrue = true;
        } else {
            Student memory st = Student({
                studentAddress: _student,
                participantToTrue: true
            });
            addressToStudent[_student] = st;
            student.push(_student);
        }

        require(amount <= subject.maxEntrant, "Reach out limit");
        emit Register(_student);
        } 
    }

    function cancelRegister() external override onlyOpen onlyRoleStudent {
        Student storage instance = addressToStudent[msg.sender];
        require(instance.participantToTrue, "SC: cancel error");
        amount--;
        instance.participantToTrue = false;
        emit CancelRegister(msg.sender);
    }

    struct Score{
        uint256[] score;
    }

    function confirmCompletedAddress(
        address[] calldata _students, Score[] memory _score
    ) external onlyOpen onlyRoleLecturer {
        require(block.timestamp < subject.endTimeToConfirm);
        require(_students.length == _score.length);
        for (uint256 i = 0; i < _students.length; i++) {
            _register(_students[i]);
            score[_students[i]][ScoreColumn.QT] = _score[i].score[0];
            score[_students[i]][ScoreColumn.GK] = _score[i].score[1];
            score[_students[i]][ScoreColumn.TH] = _score[i].score[2];
            score[_students[i]][ScoreColumn.CK] = _score[i].score[3];
            uint256 finalScore = getFinalScore(_students[i]);
            if (finalScore >= 50000)
                completedAddress[_students[i]] = true;
        }
        emit Confirm(_students.length, block.timestamp);
    }

    function unConfirmCompletedAddress(address[] calldata _students)
        external
        onlyRoleLecturer
        onlyOpen
        override
    {
        require(
            block.timestamp > subject.endTime &&
                block.timestamp < subject.endTimeToConfirm
        );
        for (uint256 i = 0; i < _students.length; i++) {
            require(completedAddress[_students[i]], "SC: cancel error");
            completedAddress[_students[i]] = false;
        }

        emit UnConfirm(_students.length, block.timestamp);
    }

    function close() external override onlyOwner onlyOpen {
        status = Status.Close;
        require(block.timestamp > subject.endTimeToConfirm);
        emit Close(block.timestamp);
    }

    function isReadyToClose() external view returns (bool) {
        return (block.timestamp > subject.endTimeToConfirm);
    }

    function getParticipantList()
        public
        view
        onlyOpen
        returns (address[] memory)
    {
        address[] memory _student = new address[](amount);
        uint256 index;
        for (uint256 i = 0; i < student.length; i++) {
            if (
                addressToStudent[student[i]].participantToTrue &&
                addressToStudent[student[i]].studentAddress != address(0)
            ) {
                _student[index] = addressToStudent[student[i]].studentAddress;
                index++;
            }
        }
        return _student;
    }

    function getParticipantListCompleted()
        public
        view
        returns (address[] memory)
    {
        address[] memory _student = new address[](amount);
        uint256 index;
        for (uint256 i = 0; i < student.length; i++) {
            if (completedAddress[student[i]] && student[i] != address(0)) {
                _student[index] = student[i];
                index++;
            }
        }
        return _student;
    }

    function getFinalScore(address _student) public view returns (uint256) {
        return
            (score[_student][ScoreColumn.QT] *
                rate[ScoreColumn.QT] +
                score[_student][ScoreColumn.GK] *
                rate[ScoreColumn.GK] +
                score[_student][ScoreColumn.TH] *
                rate[ScoreColumn.TH] +
                score[_student][ScoreColumn.CK] *
                rate[ScoreColumn.CK])/10000;
    }

    function getScore(address _student) public view returns(uint256[] memory) {
        uint256[] memory list = new uint256[](5);
        list[0]=score[_student][ScoreColumn.QT];
        list[1]=score[_student][ScoreColumn.GK];
        list[2]=score[_student][ScoreColumn.TH];
        list[3]=score[_student][ScoreColumn.CK];
        list[4]=getFinalScore(_student);
        return list;
    }

    function getScoreList() public view returns(address[] memory, Score[] memory) {
        address[] memory list = getParticipantList();
        Score[] memory scoreList = new Score[](list.length);
        for (uint256 i=0; i< list.length; i++) {
            uint256[] memory _score = new uint256[](4);
            _score[0]=score[list[i]][ScoreColumn.QT];
            _score[1]=score[list[i]][ScoreColumn.GK];
            _score[2]=score[list[i]][ScoreColumn.TH];
            _score[3]=score[list[i]][ScoreColumn.CK];
            _score[4]=getFinalScore(list[i]);
            scoreList[i].score = _score;
        }
        return (list, scoreList);
    }
}