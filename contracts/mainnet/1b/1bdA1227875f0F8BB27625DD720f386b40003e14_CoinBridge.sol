// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./AbstractBridge.sol";
import "./mint/IMint.sol";
import "../Mutex.sol";

contract CoinBridge is AbstractBridge, Mutex {
    uint256 constant DIVIDER = 10 ** 12;

    mapping(uint128 => BindingInfo) public bindings;
    uint256 public fees;
    uint256 public balance;

    event LockTokens(
        uint16 feeChainId,
        uint256 amount,
        string recipient,
        uint256 gaslessReward,
        string referrer,
        uint256 referrerFee,
        uint256 fee
    );
    event ReleaseTokens(
        uint256 amount,
        address recipient,
        uint256 gaslessReward,
        address caller
    );
    event Fee(uint16 feeChainId, uint256 amount, string recipient);

    function lockTokens(
        uint16 executionChainId_,
        string calldata recipient_,
        string calldata referrer_,
        uint256 gaslessReward_
    ) external payable mutex whenNotPaused whenInitialized {
        require(chains[executionChainId_], "execution chain is disable");
        BindingInfo memory binding = bindings[executionChainId_];
        require(binding.enabled, "token is disabled");
        require(msg.value >= binding.minAmount, "less than min amount");
        uint128 percent = msg.value > binding.thresholdFee
            ? binding.afterPercentFee
            : binding.beforePercentFee;
        uint256 fee = binding.minFee + (msg.value * percent) / PERCENT_FACTOR;
        require(msg.value > fee, "fee more than amount");
        uint256 amount;
        unchecked {
            amount = msg.value - fee;
        }
        require(amount > gaslessReward_, "gassless reward more than amount");
        uint256 referrerFee = (fee *
            referrersFeeInPercent[executionChainId_][referrer_]) /
            PERCENT_FACTOR;
        fees += fee - referrerFee;
        balance += amount + referrerFee;
        emit LockTokens(
            executionChainId_,
            amount,
            recipient_,
            gaslessReward_,
            referrer_,
            referrerFee,
            fee - referrerFee
        );
        IMint(adapter).mintTokens(
            executionChainId_,
            binding.executionAsset,
            amount / DIVIDER,
            recipient_,
            gaslessReward_ / DIVIDER,
            referrer_,
            referrerFee / DIVIDER
        );
    }

    function releaseTokens(
        bytes32 callerContract_,
        address payable recipient_,
        uint256 amount_,
        uint256 gaslessReward_
    ) external mutex whenNotPaused whenInitialized onlyExecutor {
        require(callerContract == callerContract_, "only caller contract");

        uint256 balance_ = balance;
        amount_ *= DIVIDER;
        gaslessReward_ *= DIVIDER;
        require(balance_ >= amount_, "insufficient funds");
        unchecked {
            balance = balance_ - amount_;
        }

        // slither-disable-start tx-origin
        emit ReleaseTokens(amount_, recipient_, gaslessReward_, tx.origin);
        if (gaslessReward_ > 0 && recipient_ != tx.origin) {
            recipient_.transfer(amount_ - gaslessReward_);
            payable(tx.origin).transfer(gaslessReward_);
        } else {
            recipient_.transfer(amount_);
        }
        // slither-disable-end tx-origin
    }

    function transferFee() external mutex whenNotPaused whenInitialized {
        uint16 feeChainId_ = feeChainId;
        require(chains[feeChainId_], "chain is disable");
        BindingInfo memory binding = bindings[feeChainId_];
        require(binding.enabled, "token is disabled");
        uint256 fee_ = fees;
        require(fee_ >= binding.minAmount, "less than min amount");
        balance += fee_;
        fees = 0;
        fee_ /= DIVIDER;
        string memory feeRecipient_ = feeRecipient;

        emit Fee(feeChainId_, fee_, feeRecipient_);
        IMint(adapter).mintTokens(
            feeChainId_,
            binding.executionAsset,
            fee_,
            feeRecipient_,
            0,
            "",
            0
        );
    }

    function updateBindingInfo(
        uint16 executionChainId_,
        string calldata executionAsset_,
        uint256 minAmount_,
        uint256 minFee_,
        uint256 thresholdFee_,
        uint128 beforePercentFee_,
        uint128 afterPercentFee_,
        bool enabled_
    ) external onlyAdmin {
        bindings[executionChainId_] = BindingInfo(
            executionAsset_,
            minAmount_,
            minFee_,
            thresholdFee_,
            beforePercentFee_,
            afterPercentFee_,
            enabled_
        );
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../Pausable.sol";
import "../Initializable.sol";

abstract contract AbstractBridge is Initializable, Pausable {
    struct BindingInfo {
        string executionAsset;
        uint256 minAmount;
        uint256 minFee;
        uint256 thresholdFee;
        uint128 beforePercentFee;
        uint128 afterPercentFee;
        bool enabled;
    }

    event ExecutionChainUpdated(uint128 feeChainId, address caller);
    event FeeChainUpdated(uint128 feeChainId, address caller);
    event CallerContractUpdated(bytes32 executorContract, address caller);
    event FeeRecipientUpdated(string feeRecipient, address caller);
    event SignerUpdated(address caller, address oldSigner, address signer);
    event ReferrerFeeUpdated(
        uint128 chainId,
        string referrer,
        uint128 feeInPercent
    );

    uint128 constant PERCENT_FACTOR = 10 ** 6;

    uint16 public feeChainId;
    string public feeRecipient;
    address public adapter;
    address public executor;
    bytes32 callerContract;
    mapping(uint128 => bool) public chains;
    mapping(uint128 => mapping(string => uint128)) public referrersFeeInPercent;

    modifier onlyExecutor() {
        require(msg.sender == executor, "only executor");
        _;
    }

    function init(
        address admin_,
        address adapter_,
        uint16 feeChainId_,
        string calldata feeRecipient_,
        address executor_,
        bytes32 callerContract_
    ) external whenNotInitialized {
        require(admin_ != address(0), "zero address");
        require(adapter_ != address(0), "zero address");
        require(executor_ != address(0), "zero address");
        feeChainId = feeChainId_;
        pauser = admin_;
        admin = admin_;
        feeRecipient = feeRecipient_;
        adapter = adapter_;
        executor = executor_;
        callerContract = callerContract_;
        isInited = true;
    }

    function updateExecutionChain(
        uint128 executionChainId_,
        bool enabled
    ) external onlyAdmin {
        emit ExecutionChainUpdated(executionChainId_, msg.sender);
        chains[executionChainId_] = enabled;
    }

    function updateFeeChain(uint16 feeChainId_) external onlyAdmin {
        emit FeeChainUpdated(feeChainId_, msg.sender);
        feeChainId = feeChainId_;
    }

    function updateCallerContract(bytes32 callerContract_) external onlyAdmin {
        emit CallerContractUpdated(callerContract_, msg.sender);
        callerContract_ = callerContract_;
    }

    function updateFeeRecipient(
        string calldata feeRecipient_
    ) external onlyAdmin {
        emit FeeRecipientUpdated(feeRecipient_, msg.sender);
        feeRecipient = feeRecipient_;
    }

    function updateReferrer(
        uint128 executionChainId_,
        string calldata referrer_,
        uint128 percentFee_
    ) external onlyAdmin {
        require(percentFee_ <= 2e5); // up 20% max
        require(chains[executionChainId_], "execution chain is disable");
        emit ReferrerFeeUpdated(executionChainId_, referrer_, percentFee_);
        referrersFeeInPercent[executionChainId_][referrer_] = percentFee_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IMint {
    function mintTokens(
        uint16 executionChainId_,
        string calldata token_,
        uint256 amount_,
        string calldata recipient_,
        uint256 gaslessClaimReward_,
        string calldata referrer_,
        uint256 referrerFee_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Mutex {
    bool private _lock;

    modifier mutex() {
        require(!_lock, "mutex lock");
        _lock = true;
        _;
        _lock = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Adminable.sol";

abstract contract Pausable is Adminable {
    event Paused(address account);
    event Unpaused(address account);
    event PauserUpdated(address sender, address oldPauser, address pauser);

    bool public isPaused;
    address public pauser;

    constructor() {
        isPaused = false;
    }

    modifier whenNotPaused() {
        require(!isPaused, "paused");
        _;
    }

    modifier whenPaused() {
        require(isPaused, "not paused");
        _;
    }

    modifier onlyPauser() {
        require(pauser == msg.sender, "only pauser");
        _;
    }

    function pause() external whenNotPaused onlyPauser {
        isPaused = true;
        emit Paused(msg.sender);
    }

    function unpause() external whenPaused onlyPauser {
        isPaused = false;
        emit Unpaused(msg.sender);
    }

    function updatePauser(address pauser_) external onlyAdmin {
        require(pauser_ != address(0), "zero address");
        emit PauserUpdated(msg.sender, pauser, pauser_);
        pauser = pauser_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Initializable {
    bool internal isInited;

    modifier whenInitialized() {
        require(isInited, "not initialized");
        _;
    }

    modifier whenNotInitialized() {
        require(!isInited, "already initialized");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Adminable {
    event AdminUpdated(address sender, address oldAdmin, address admin);

    address public admin;

    modifier onlyAdmin() {
        require(admin == msg.sender, "only admin");
        _;
    }

    function updateAdmin(address admin_) external onlyAdmin {
        require(admin_ != address(0), "zero address");
        emit AdminUpdated(msg.sender, admin, admin_);
        admin = admin_;
    }
}