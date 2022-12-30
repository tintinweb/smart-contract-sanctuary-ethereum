// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IJudiciary {
    function escrowFactoryContractAddress() external view returns (address);

    function treasuryAddress() external view returns (address);

    function feesPermyriad() external view returns (uint8);
}

/**
 * @title The Escrow Contract
 * @author [email protected]
 * @notice Contract that holds the funds of the participants and releases them when the conditions are met
 */
contract Escrow is Initializable, ReentrancyGuardUpgradeable {
    address public treasuryAddress;
    address public mainContractAddress;
    uint8 public feesPermyriad;

    constructor() {
        //
    }

    bool public isFreezed;
    bool public blockNewParticipants;
    address public judge;

    address[] public participants;
    mapping(address => bool) public participantExists;

    /**
     * @notice Get an array of all the participants in the Escrow Wallet
     * @return _participants All the participants in the Escrow Wallet.
     */
    function getParticipants()
        public
        view
        returns (address[] memory _participants)
    {
        return participants;
    }

    /**
     * @notice Get number of participants in the Escrow Wallet
     * @return _totalParticipants Number of participants in the Escrow Wallet.
     */
    function totalParticipants()
        external
        view
        returns (uint256 _totalParticipants)
    {
        return participants.length;
    }

    // mappings to store the balances of the participants
    // amount of money an address has deposited in the contract
    mapping(address => mapping(address => uint256))
        public getEscrowRemainingInput; // [tokenAddress][participantAddress] => amount

    // amount of money an address can withdraw from the contract
    mapping(address => mapping(address => uint256))
        public getWithdrawableBalance; // [tokenAddress][participantAddress] => amount

    // amount of money an address can refund to a particular participant in the contract
    mapping(address => mapping(address => uint256)) public getRefundableBalance; // [tokenAddress][participantAddress] => amount

    /**
     * @notice Constructor function for the Escrow Contract Instances
     * @param _participants The array of addresses that will be the participants in the Escrow Wallet
     * @param _judge The address of the judge of the Escrow Wallet
     * @param _blockNewParticipants A boolean that determines if new participants can be added to the Escrow Wallet
     */
    function initialize(
        address[] memory _participants,
        address _judge,
        bool _blockNewParticipants
    ) public initializer {
        require(
            _participants.length >= 2,
            "at least two participants required"
        );

        // the Judiciary contract (so the Judiciary contract can pay this Escrow contract directly without being a participant)
        mainContractAddress = msg.sender;

        // no signatory should be a judge & make them participants
        for (uint256 i = 0; i < _participants.length; i++) {
            address _participant = _participants[i];
            require(
                _participant != _judge &&
                    _participant != address(0) &&
                    _participant != mainContractAddress,
                "corrupt participant found"
            );
            _addParticipant(_participant);
        }

        judge = _judge;
        isFreezed = false;
        blockNewParticipants = _blockNewParticipants;

        IJudiciary _mainContract = IJudiciary(mainContractAddress);
        treasuryAddress = _mainContract.treasuryAddress();
        feesPermyriad = _mainContract.feesPermyriad();
    }

    /**
     * @notice Get the tokens balance of the Escrow Wallet
     * @return _balance The tokens balance of the Escrow Wallet
     */
    function getBalance() public view returns (uint256 _balance) {
        return address(this).balance;
    }

    // Events
    event Deposit(
        address indexed depositor,
        address indexed recipient,
        address indexed token,
        uint256 amount,
        uint32 timestamp
    );
    event Freeze(uint32 timestamp);
    event Unfreeze(uint32 timestamp);
    event BlockNewParticipants(uint32 timestamp);
    event UnblockNewParticipants(uint32 timestamp);
    event NewParticipant(address indexed participant, uint32 timestamp);
    event Approve(
        address indexed from,
        address indexed by,
        address indexed to,
        address token,
        uint256 amount,
        uint32 timestamp
    );
    event Refund(
        address indexed from,
        address indexed by,
        address indexed to,
        address token,
        uint256 amount,
        uint32 timestamp
    );
    event Withdraw(
        address indexed by,
        address _token,
        uint256 amount,
        uint32 timestamp
    );

    // Fallbacks
    fallback() external payable virtual {
        deposit(address(0), address(this), msg.value);
    }

    receive() external payable virtual {
        deposit(address(0), address(this), msg.value);
    }

    // Modifiers
    modifier freezeCheck() {
        require(isFreezed == false, "escrow freezed");
        _;
    }
    modifier participantCheck() {
        require(
            blockNewParticipants == false ||
                participantExists[msg.sender] == true ||
                msg.sender == mainContractAddress, // so the Judiciary contract can pay this Escrow contract directly without being a participant
            "new participants blocked"
        );
        _;
    }
    modifier judgeCheck() {
        require(msg.sender == judge, "only for judge");
        _;
    }

    /**
     * @dev Internal function to add a participant to the Escrow Wallet if they are not already a participant
     */
    function _addParticipant(address _participant) internal {
        if (
            participantExists[_participant] != true &&
            _participant != judge &&
            _participant != address(0) &&
            _participant != mainContractAddress
        ) {
            participants.push(_participant);
            participantExists[_participant] = true;
            emit NewParticipant(_participant, uint32(block.timestamp));
        }

        // TODO: if they are a judge or the Judiciary contract, this function should probably revert?
    }

    /**
     * @dev Internal function that deposits funds/tokens into the Escrow Wallet
     */
    function _deposit(
        address _to,
        address _token,
        uint256 _amount
    ) internal {
        // sender becomes a participant and their input gets recorded
        _addParticipant(msg.sender);
        getEscrowRemainingInput[_token][msg.sender] =
            getEscrowRemainingInput[_token][msg.sender] +
            _amount;

        // get beneficiary
        address beneficiary = _to != address(0)
            ? _to
            : (
                participants[0] == msg.sender
                    ? participants[1]
                    : participants[0]
            );

        // if there are only 2 participants, then the other participant is the intended beneficiary unless specified
        if (participants.length == 2) {
            getRefundableBalance[_token][beneficiary] =
                getRefundableBalance[_token][beneficiary] +
                _amount;
        } else {
            // if there are more than 2 participants, then the beneficiary must be specified
            require(_to != address(0), "beneficiary not specified");

            // if the beneficiary is not a participant, then add them as a participant
            _addParticipant(_to);

            // add the amount to the beneficiary's refundable balance
            getRefundableBalance[_token][beneficiary] =
                getRefundableBalance[_token][beneficiary] +
                _amount;
        }

        emit Deposit(
            msg.sender,
            beneficiary,
            _token,
            _amount,
            uint32(block.timestamp)
        );
    }

    /**
     * @notice Deposit tokens to the Escrow Wallet
     * @param _to The address of the participant to whom the tokens is to be deposited
     * @param _token The address of the ERC20 smart contract of the token to be deposited
     * @param _amount The amount of tokens to be deposited
     * @return _success A boolean that determines if the deposit was successful
     */
    function deposit(
        address _to,
        address _token,
        uint256 _amount
    )
        public
        payable
        freezeCheck
        participantCheck
        nonReentrant
        returns (bool _success)
    {
        require(msg.sender != _to, "cant deposit yourself");

        uint256 treasuryAmount;

        if (msg.value > 0) {
            require(
                _token == address(this),
                "cant send tokens with native currency"
            ); // if tokens is being sent, then the token address must be the address of the contract

            // pay fees to treasury in native currency
            uint256 totalAmount = msg.value;
            treasuryAmount = (totalAmount * feesPermyriad) / 10000;
            if (treasuryAmount != 0) {
                (bool treasurySuccess, ) = payable(treasuryAddress).call{
                    value: treasuryAmount
                }("");
                require(treasurySuccess, "treasury payment failed");
            }

            _deposit(_to, address(this), totalAmount - treasuryAmount);

            return true;
        }

        // verify if _token is a valid erc20 token using interfaces
        require(
            IERC20(_token).totalSupply() > 0 && _token != address(this),
            "not a valid erc20 token"
        );

        // pay fees to treasury in tokens
        treasuryAmount = (_amount * feesPermyriad) / 10000;
        if (treasuryAmount != 0) {
            require(
                IERC20(_token).transferFrom(
                    msg.sender,
                    treasuryAddress,
                    treasuryAmount
                ),
                "treasury payment failed"
            );
        }

        // transfer tokens to the contract if this contract has the approval to transfer the tokens
        require(
            IERC20(_token).transferFrom(
                msg.sender,
                address(this),
                _amount - treasuryAmount
            ),
            "token transfer failed"
        );

        // run depository chores
        _deposit(_to, _token, _amount - treasuryAmount);

        return true;
    }

    /**
     * @notice For the buyer to approve the funds they sent into the contract, for the other party (usually the seller) to withdraw.
     * @param _from The address of the participant from whom the tokens is to be approved
     * @param _to The address of the participant to whom the tokens is to be approved
     * @param _token The address of the ERC20 smart contract of the token to be approved
     * @param _amount The amount of tokens to be approved
     * @param _attemptPayment A boolean that determines if the `_to` participant should be paid immediately
     * @return _success A boolean that determines if the approval was successful.
     */
    function approve(
        address _from,
        address _to,
        address _token,
        uint256 _amount,
        bool _attemptPayment
    ) external nonReentrant freezeCheck returns (bool _success) {
        require(
            msg.sender != _to &&
                _to != _from &&
                (msg.sender == _from || msg.sender == judge),
            "unauthorized approve"
        );
        require(
            _amount <= getEscrowRemainingInput[_token][_from],
            "insufficient escrow input"
        );

        require(
            _amount <= getRefundableBalance[_token][_to],
            "undeserving recipient"
        );

        // delete from remaining input
        getEscrowRemainingInput[_token][_from] =
            getEscrowRemainingInput[_token][_from] -
            _amount;

        // delete from refundable balance
        getRefundableBalance[_token][_to] =
            getRefundableBalance[_token][_to] -
            _amount;

        _addParticipant(_from);
        _addParticipant(_to);

        if (_attemptPayment) {
            if (_token == address(this)) {
                (bool success, ) = payable(_to).call{value: _amount}("");
                require(success, "payment failed");
            } else {
                IERC20(_token).transfer(_to, _amount);
            }
        } else {
            // add to beneficiary's withdrawable balance
            getWithdrawableBalance[_token][_to] =
                getWithdrawableBalance[_token][_to] +
                _amount;
        }

        emit Approve(
            _from,
            msg.sender,
            _to,
            _token,
            _amount,
            uint32(block.timestamp)
        );

        return true;
    }

    /**
     * @notice Withdraw your balance from the Escrow Contract
     * @param _token The address of the ERC20 smart contract of the token to be withdrawn
     * @param _amount The amount of tokens to be withdrawn
     * @return _success A boolean that determines if the approval was successful.
     */
    function withdraw(address _token, uint256 _amount)
        external
        nonReentrant
        freezeCheck
        returns (bool _success)
    {
        require(
            _amount <= getWithdrawableBalance[_token][msg.sender],
            "insufficient balance"
        );

        getWithdrawableBalance[_token][msg.sender] =
            getWithdrawableBalance[_token][msg.sender] -
            _amount;

        if (_token == address(this)) {
            (bool success, ) = payable(msg.sender).call{value: _amount}("");
            require(success, "withdraw failed");
        } else {
            IERC20(_token).transfer(msg.sender, _amount);
        }

        emit Withdraw(msg.sender, _token, _amount, uint32(block.timestamp));

        return true;
    }

    /**
     * @notice For the buyer to approve the funds they sent into the contract, for the other party (usually the seller) to withdraw.
     * @param _from The address of the participant from whom the tokens is to be refunded
     * @param _to The address of the participant to whom the tokens is to be refunded
     * @param _token The address of the ERC20 smart contract of the token to be refunded
     * @param _amount The amount of tokens to be refunded
     * @param _attemptPayment A boolean that determines if the `_to` participant should be paid immediately
     * @return _success A boolean that determines if the approval was successful.
     */
    function refund(
        address _from,
        address _to,
        address _token,
        uint256 _amount,
        bool _attemptPayment
    ) external nonReentrant freezeCheck returns (bool _success) {
        require(
            msg.sender != _to &&
                _to != _from &&
                (msg.sender == _from || msg.sender == judge),
            "unauthorized refund"
        );

        require(
            _amount <= getRefundableBalance[_token][_from],
            "insufficient refundable balance"
        );

        require(
            _amount <= getEscrowRemainingInput[_token][_to],
            "undeserving refund recipient"
        );

        // delete from remaining input
        getEscrowRemainingInput[_token][_to] =
            getEscrowRemainingInput[_token][_to] -
            _amount;

        // delete from refundable balance of msg.sender
        getRefundableBalance[_token][_from] =
            getRefundableBalance[_token][_from] -
            _amount;

        if (_attemptPayment) {
            if (_token == address(this)) {
                (bool success, ) = payable(_to).call{value: _amount}("");
                require(success, "refund failed");
            } else {
                IERC20(_token).transfer(_to, _amount);
            }
        } else {
            getWithdrawableBalance[_token][_to] =
                getWithdrawableBalance[_token][_to] +
                _amount;
        }

        emit Refund(
            _from,
            msg.sender,
            _to,
            _token,
            _amount,
            uint32(block.timestamp)
        );

        return true;
    }

    /**
     * @notice This function can be called by the judge to freeze the contract deposits, withdrawals, approvals and refunds.
     * @return _isFreezed A boolean that determines if the contract is freezed.
     */
    function toggleFreeze()
        external
        nonReentrant
        judgeCheck
        returns (bool _isFreezed)
    {
        if (isFreezed) {
            isFreezed = false;
            emit Unfreeze(uint32(block.timestamp));
        } else {
            isFreezed = true;
            emit Freeze(uint32(block.timestamp));
        }

        return isFreezed;
    }

    /**
     * @notice This function can be called by the judge to block new participants from joining the escrow.
     * @return _blockNewParticipants A boolean that determines if new participants can join the escrow.
     */
    function toggleParticipantBlock()
        external
        nonReentrant
        freezeCheck
        judgeCheck
        returns (bool _blockNewParticipants)
    {
        if (blockNewParticipants) {
            blockNewParticipants = false;
            emit UnblockNewParticipants(uint32(block.timestamp));
        } else {
            blockNewParticipants = true;
            emit BlockNewParticipants(uint32(block.timestamp));
        }

        return blockNewParticipants;
    }

    // TODO: Allow change of judge if all the participants agree
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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