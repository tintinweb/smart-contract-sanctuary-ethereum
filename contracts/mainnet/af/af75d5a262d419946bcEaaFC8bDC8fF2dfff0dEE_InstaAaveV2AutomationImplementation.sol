// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma abicoder v2;

import "./helpers.sol";

contract InstaAutomationHelper is Helpers {
    using SafeERC20 for IERC20;

    constructor(address aavePoolAddressesProvider_, address instaList_)
        Helpers(aavePoolAddressesProvider_, instaList_)
    {}

    modifier onlyOwner() {
        require(msg.sender == _owner, "not-an-owner");
        _;
    }

    modifier onlyExecutor() {
        require(_executors[msg.sender], "not-an-executor");
        _;
    }

    modifier onlyDSA(address user_) {
        require(instaList.accountID(user_) != 0, "not-a-dsa");
        _;
    }

    function changeOwner(address newOwner_) public onlyOwner {
        require(newOwner_ != address(0), "invalid-owner");
        require(newOwner_ != _owner, "same-owner");

        address[] memory owners_ = new address[](2);
        bool[] memory status_ = new bool[](2);

        (owners_[0], owners_[1]) = (_owner, newOwner_);
        (status_[0], status_[1]) = (false, true);
        _executors[_owner] = false;
        _executors[newOwner_] = true;

        _owner = newOwner_;
        emit LogChangedOwner(owners_[0], owners_[1]);
        emit LogFlippedExecutors(owners_, status_);
    }

    function flipExecutor(address[] memory executor_, bool[] memory status_)
        public
        onlyOwner
    {
        uint256 length_ = executor_.length;
        for (uint256 i; i < length_; i++) {
            require(
                executor_[i] != _owner,
                "owner-cant-be-removed-as-executor"
            );
            _executors[executor_[i]] = status_[i];
        }
        emit LogFlippedExecutors(executor_, status_);
    }

    function updateBufferHf(uint128 newBufferHf_) public onlyOwner {
        emit LogUpdatedBufferHf(_bufferHf, newBufferHf_);
        _bufferHf = newBufferHf_;
    }

    function updateMinimunHf(uint128 newMinimumThresholdHf_) public onlyOwner {
        emit LogUpdatedMinHf(_minimumThresholdHf, newMinimumThresholdHf_);
        _minimumThresholdHf = newMinimumThresholdHf_;
    }

    function updateAutomationFee(uint16 newAutomationFee_) public onlyOwner {
        emit LogUpdatedAutomationFee(_automationFee, newAutomationFee_);
        _automationFee = newAutomationFee_;
    }

    function transferFee(address[] memory tokens_, address recipient_)
        public
        onlyOwner
    {
        uint256 length_ = tokens_.length;
        address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        uint256[] memory amounts_ = new uint256[](length_);
        for (uint256 i; i < length_; i++) {
            bool isNative = tokens_[i] == native;
            uint256 amount_;
            if (isNative) {
                amount_ = address(this).balance;
                (bool sent, ) = recipient_.call{value: amount_}("");
                require(sent, "native-token-transfer-failed");
            } else {
                amount_ = IERC20(tokens_[i]).balanceOf(address(this));
                IERC20(tokens_[i]).safeTransfer(recipient_, amount_);
            }
            amounts_[i] = amount_;
        }

        emit LogFeeTransferred(recipient_, tokens_, amounts_);
    }

    function systemCall(string calldata actionId_, bytes memory metadata_)
        public
        onlyExecutor
    {
        emit LogSystemCall(msg.sender, actionId_, metadata_);
    }
}

contract InstaAaveV2AutomationImplementation is InstaAutomationHelper {
    constructor(address aavePoolAddressesProvider_, address instaList_)
        InstaAutomationHelper(aavePoolAddressesProvider_, instaList_)
    {}

    function initialize(
        address owner_,
        uint16 automationFee_,
        uint128 minimumThresholdHf_,
        uint128 bufferHf_
    ) public {
        require(_status == 0, "already-initialized");
        _status = 1;
        _owner = owner_;
        _minimumThresholdHf = minimumThresholdHf_;
        _bufferHf = bufferHf_;
        _automationFee = automationFee_;
        _id = 1;

        _executors[owner_] = true;
    }

    function submitAutomationRequest(
        uint256 safeHealthFactor_,
        uint256 thresholdHealthFactor_
    ) external onlyDSA(msg.sender) {
        require(
            safeHealthFactor_ < type(uint72).max,
            "safe-health-factor-too-large"
        );
        require(
            thresholdHealthFactor_ < safeHealthFactor_ &&
                thresholdHealthFactor_ >= _minimumThresholdHf,
            "thresholdHealthFactor-out-of-range"
        );

        uint32 userLatestId = _userLatestId[msg.sender];
        require(
            userLatestId == 0 ||
                _userAutomationConfigs[userLatestId].status != Status.AUTOMATED,
            "position-already-in-protection"
        );

        uint256 healthFactor_ = getHealthFactor(msg.sender);
        require(
            healthFactor_ < type(uint128).max,
            "current-health-factor-too-large-for-automation-request"
        );

        emit LogSubmittedAutomation(
            msg.sender,
            _id,
            uint128(safeHealthFactor_),
            uint128(thresholdHealthFactor_),
            uint128(healthFactor_)
        );

        _userAutomationConfigs[_id] = Automation({
            user: msg.sender,
            nonce: 0,
            status: Status.AUTOMATED,
            safeHF: uint128(safeHealthFactor_),
            thresholdHF: uint128(thresholdHealthFactor_)
        });

        _userLatestId[msg.sender] = _id;
        _id++;
    }

    function _cancelAutomation(
        address user_,
        uint8 errorCode_,
        uint32 id_,
        bool isSystem_
    ) internal onlyDSA(user_) {
        require(_userLatestId[user_] == id_, "not-valid-id");
        Automation storage _userAutomationConfig = _userAutomationConfigs[id_];

        require(
            user_ != address(0) && _userAutomationConfig.user == user_,
            "automation-user-not-valid"
        );

        require(
            _userAutomationConfig.status == Status.AUTOMATED,
            "already-executed-or-canceled"
        );

        if (isSystem_) {
            emit LogSystemCancelledAutomation(
                user_,
                id_,
                _userAutomationConfig.nonce,
                errorCode_
            );
            _userAutomationConfig.status = Status.DROPPED;
        } else {
            emit LogCancelledAutomation(
                user_,
                id_,
                _userAutomationConfig.nonce
            );
            _userAutomationConfig.status = Status.CANCELLED;
        }
        _userLatestId[user_] = 0;
    }

    function cancelAutomationRequest() external {
        _cancelAutomation(msg.sender, 0, _userLatestId[msg.sender], false);
    }

    function systemCancel(
        address[] memory users_,
        uint32[] memory ids_,
        uint8[] memory errorCodes_
    ) external onlyExecutor {
        uint256 length_ = users_.length;
        require(length_ == ids_.length, "invalid-inputs");
        require(length_ == errorCodes_.length, "invalid-inputs");

        for (uint256 i; i < length_; i++)
            _cancelAutomation(users_[i], errorCodes_[i], ids_[i], true);
    }

    function executeAutomation(
        address user_,
        uint32 id_,
        uint32 nonce_,
        bool onCastRevert_,
        ExecutionParams memory params_,
        bytes calldata metadata_
    ) external onlyDSA(user_) onlyExecutor {
        require(_userLatestId[user_] == id_, "not-valid-id");
        Automation storage _userAutomationConfig = _userAutomationConfigs[id_];

        require(
            user_ != address(0) && _userAutomationConfig.user == user_,
            "automation-user-not-valid"
        );

        require(
            _userAutomationConfig.status == Status.AUTOMATED,
            "canceled-or-dropped"
        );

        require(_userAutomationConfig.nonce == nonce_, "not-valid-nonce");

        Spell memory spells_ = _buildSpell(params_);

        uint128 initialHf_ = uint128(getHealthFactor(user_));

        require(
            ((_userAutomationConfig.thresholdHF + _bufferHf) >= initialHf_) ||
                (
                    (_userAutomationConfig.safeHF >= (initialHf_ + _bufferHf) &&
                        _userAutomationConfig.nonce > 0)
                ),
            "position-not-ready-for-automation"
        );

        bool success_ = cast(AccountInterface(user_), spells_);

        if (!success_) {
            if (!onCastRevert_)
                emit LogExecutionFailedAutomation(
                    user_,
                    id_,
                    nonce_,
                    params_,
                    metadata_,
                    initialHf_
                );
            else revert("automation-cast-failed");
        } else {
            uint128 finalHf_ = uint128(getHealthFactor(user_));

            require(
                finalHf_ > initialHf_,
                "automation-failed: Final-Health-Factor <= Initial-Health-factor"
            );

            bool isSafe_ = finalHf_ >=
                (_userAutomationConfig.safeHF - _bufferHf);

            params_.swap.callData = "0x"; // Making it 0x, so it will reduce gas cost for event emission

            emit LogExecutedAutomation(
                user_,
                id_,
                nonce_,
                params_,
                isSafe_,
                _automationFee,
                metadata_,
                finalHf_,
                initialHf_
            );
        }
        _userAutomationConfig.nonce++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma abicoder v2;

import "./events.sol";

contract Helpers is Events {
    constructor(address aavePoolAddressesProvider_, address instaList_)
        Variables(aavePoolAddressesProvider_, instaList_)
    {}

    function _buildSpell(ExecutionParams memory params_)
        internal
        view
        returns (Spell memory spells)
    {
        bool isSameToken_ = params_.collateralToken == params_.debtToken;
        uint256 id_ = 7128943279;
        uint256 index_;

        /**
            The packing of route will be like as follows:
                - param.route = (flashloanFeeInBps_ << 9) | route_
            The unpacking will be as follows: 
                - route_ = params_.route % (2**8);
                - flashloanFeeInBps_ = params_.route >> 9
         */
        uint256 route_ = params_.route % (2**8);
        uint256 flashloanFeeInBps_ = params_.route >> 9;
        uint256 loanAmtWithFee_ = params_.collateralAmount +
            ((params_.collateralAmount * flashloanFeeInBps_) / 1e4);
        uint256 totalFee_ = params_.collateralAmountWithTotalFee -
            loanAmtWithFee_;

        if (route_ > 0) {
            /**
             * if we are taking the flashloan, then this case
             * This case if the user is doesn't have enough collateral to payback the debt
             * will be used most of the time
             * flashBorrowAndCast: Take the flashloan of collateral token
             * swap: swap the collateral token into the debt token
             * payback: payback the debt
             * withdraw: withdraw the collateral
             * flashPayback: payback the flashloan
             */
            Spell memory flashloanSpell_;

            (flashloanSpell_._targets, flashloanSpell_._datas) = (
                new string[](isSameToken_ ? 4 : 5),
                new bytes[](isSameToken_ ? 4 : 5)
            );

            (spells._targets, spells._datas) = (
                new string[](1),
                new bytes[](1)
            );

            if (!isSameToken_) {
                (
                    flashloanSpell_._targets[index_],
                    flashloanSpell_._datas[index_++]
                ) = (
                    "1INCH-A",
                    abi.encodeWithSignature(
                        "sell(address,address,uint256,uint256,bytes,uint256)",
                        params_.swap.buyToken, // debt token
                        params_.swap.sellToken, // collateral token
                        params_.swap.sellAmt, // amount of collateral withdrawn to swap
                        params_.swap.unitAmt,
                        params_.swap.callData,
                        id_
                    )
                );
            } else id_ = 0;

            (
                flashloanSpell_._targets[index_],
                flashloanSpell_._datas[index_++]
            ) = (
                "AAVE-V2-A",
                abi.encodeWithSignature(
                    "payback(address,uint256,uint256,uint256,uint256)",
                    params_.debtToken, // debt
                    params_.debtAmount,
                    params_.rateMode,
                    id_,
                    0
                )
            );

            (
                flashloanSpell_._targets[index_],
                flashloanSpell_._datas[index_++]
            ) = (
                "AAVE-V2-A",
                abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    params_.collateralToken, // withdraw the collateral now
                    params_.collateralAmountWithTotalFee, // the amount of collateral token to withdraw
                    0,
                    0
                )
            );

            (
                flashloanSpell_._targets[index_],
                flashloanSpell_._datas[index_++]
            ) = (
                "INSTAPOOL-C",
                abi.encodeWithSignature(
                    "flashPayback(address,uint256,uint256,uint256)",
                    params_.collateralToken, // collateral token
                    loanAmtWithFee_,
                    0,
                    0
                )
            );

            (
                flashloanSpell_._targets[index_],
                flashloanSpell_._datas[index_++]
            ) = (
                "BASIC-A",
                abi.encodeWithSignature(
                    "withdraw(address,uint256,address,uint256,uint256)",
                    params_.collateralToken, // transfer the collateral
                    totalFee_, // the automation fee,
                    address(this),
                    0,
                    0
                )
            );

            bytes memory encodedFlashData_ = abi.encode(
                flashloanSpell_._targets,
                flashloanSpell_._datas
            );

            (spells._targets[0], spells._datas[0]) = (
                "INSTAPOOL-C",
                abi.encodeWithSignature(
                    "flashBorrowAndCast(address,uint256,uint256,bytes,bytes)",
                    params_.collateralToken,
                    params_.collateralAmount,
                    route_,
                    encodedFlashData_,
                    "0x"
                )
            );
        } else {
            (spells._targets, spells._datas) = (
                new string[](isSameToken_ ? 3 : 4),
                new bytes[](isSameToken_ ? 3 : 4)
            );

            /**
             * This case if the user have enough collateral to payback the debt
             */
            (spells._targets[index_], spells._datas[index_++]) = (
                "AAVE-V2-A",
                abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    params_.collateralToken, // collateral token to withdraw
                    params_.collateralAmountWithTotalFee, // amount to withdraw
                    0,
                    0
                )
            );

            if (!isSameToken_) {
                (spells._targets[index_], spells._datas[index_++]) = (
                    "1INCH-A",
                    abi.encodeWithSignature(
                        "sell(address,address,uint256,uint256,bytes,uint256)",
                        params_.swap.buyToken, // debt token
                        params_.swap.sellToken, // collateral that we withdrawn
                        params_.swap.sellAmt, // amount of collateral withdrawn to swap
                        params_.swap.unitAmt,
                        params_.swap.callData,
                        id_
                    )
                );
            } else id_ = 0;

            (spells._targets[index_], spells._datas[index_++]) = (
                "AAVE-V2-A",
                abi.encodeWithSignature(
                    "payback(address,uint256,uint256,uint256,uint256)",
                    params_.debtToken,
                    params_.debtAmount,
                    params_.rateMode,
                    id_,
                    0
                )
            );

            (spells._targets[index_], spells._datas[index_++]) = (
                "BASIC-A",
                abi.encodeWithSignature(
                    "withdraw(address,uint256,address,uint256,uint256)",
                    params_.collateralToken, // transfer the collateral
                    totalFee_, // the automation fee,
                    address(this),
                    0,
                    0
                )
            );
        }
    }

    function cast(AccountInterface dsa_, Spell memory spells_)
        internal
        returns (bool success_)
    {
        (success_, ) = address(dsa_).call(
            abi.encodeWithSignature(
                "cast(string[],bytes[],address)",
                spells_._targets,
                spells_._datas,
                address(this)
            )
        );
    }


    function getHealthFactor(address user_)
        public
        view
        returns (uint256 healthFactor_)
    {
        (, , , , , healthFactor_) = aave.getUserAccountData(user_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma abicoder v2;

import "./variables.sol";

abstract contract Events is Variables {
    event LogSubmittedAutomation(
        address indexed user,
        uint32 indexed id,
        uint128 safeHF,
        uint128 thresholdHF,
        uint128 currentHf
    );

    event LogCancelledAutomation(
        address indexed user,
        uint32 indexed id,
        uint32 indexed nonce
    );

    event LogExecutedAutomation(
        address indexed user,
        uint32 indexed id,
        uint32 indexed nonce,
        ExecutionParams params,
        bool isSafe,
        uint16 automationFee,
        bytes metadata,
        uint128 finalHf,
        uint128 initialHf
    );

    event LogExecutionFailedAutomation(
        address indexed user,
        uint32 indexed id,
        uint32 indexed nonce,
        ExecutionParams params,
        bytes metadata,
        uint128 initialHf
    );

    event LogSystemCancelledAutomation(
        address indexed user,
        uint32 indexed id,
        uint32 indexed nonce,
        uint8 errorCode
    );

    event LogFlippedExecutors(address[] executors, bool[] status);

    event LogUpdatedBufferHf(uint128 oldBufferHf, uint128 newBufferHf);

    event LogUpdatedMinHf(uint128 oldMinHf, uint128 newMinHf);

    event LogUpdatedAutomationFee(
        uint16 oldAutomationFee,
        uint16 newAutomationFee
    );

    event LogFeeTransferred(
        address indexed recipient,
        address[] tokens,
        uint256[] amount
    );

    event LogChangedOwner(address indexed oldOnwer, address indexed newOnwer);

    event LogSystemCall(
        address indexed sender,
        string actionId,
        bytes metadata
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma abicoder v2;

import "./interfaces.sol";

contract ConstantVariables {
    AaveInterface internal immutable aave;

    AavePoolProviderInterface internal immutable aavePoolAddressProvider;

    ListInterface internal immutable instaList;

    constructor(address aavePoolAddressesProvider_, address instaList_) {
        aavePoolAddressProvider = AavePoolProviderInterface(
            aavePoolAddressesProvider_
        );

        aave = AaveInterface(
            AavePoolProviderInterface(aavePoolAddressesProvider_)
                .getLendingPool()
        );

        instaList = ListInterface(instaList_);
    }
}

contract Structs {
    enum Status {
        NOT_INITIATED, // no automation enabled for user
        AUTOMATED, // User enabled automation
        DROPPED, // Automation dropped by system
        CANCELLED // user cancelled the automation
    }

    struct Spell {
        string[] _targets;
        bytes[] _datas;
    }

    struct Swap {
        address buyToken;
        address sellToken;
        uint256 sellAmt;
        uint256 unitAmt;
        bytes callData;
    }

    struct Automation {
        address user;
        Status status;
        uint32 nonce;
        uint128 safeHF;
        uint128 thresholdHF;
    }

    struct ExecutionParams {
        address collateralToken;
        address debtToken;
        uint256 collateralAmount;
        uint256 debtAmount;
        uint256 collateralAmountWithTotalFee;
        Swap swap;
        uint256 route;
        uint256 rateMode;
    }
}

contract Variables is ConstantVariables, Structs {
    address public _owner; // The owner of address(this)

    uint8 public _status; // initialise status check
    uint16 public _automationFee; // Automation fees in BPS
    uint32 public _id; // user automation id
    uint128 public _minimumThresholdHf; // minimum threshold Health required for enabled automation
    uint128 public _bufferHf; // buffer health factor for next automaion check

    mapping(uint32 => Automation) public _userAutomationConfigs; // user automation config

    mapping(address => uint32) public _userLatestId; // user latest automation id

    mapping(address => bool) public _executors; // executors enabled by _owner

    constructor(address aavePoolAddressesProvider_, address instaList_)
        ConstantVariables(aavePoolAddressesProvider_, instaList_)
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface AaveInterface {
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}

interface AavePoolProviderInterface {
    function getLendingPool() external view returns (address);
}

interface AccountInterface {
    function cast(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    ) external payable returns (bytes32);
}

interface ListInterface {
    function accountID(address) external returns (uint64);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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