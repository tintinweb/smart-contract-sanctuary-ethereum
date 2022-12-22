// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interfaces/IArbitrumL1GatewayRouter.sol";
import "./interfaces/IL2Deposit.sol";
import "./interfaces/IOptimismL1StandardBridge.sol";
import "./interfaces/IPermanentStorage.sol";
import "./interfaces/ISpender.sol";
import "./utils/StrategyBase.sol";
import "./utils/BaseLibEIP712.sol";
import "./utils/Ownable.sol";
import "./utils/L2DepositLibEIP712.sol";
import "./utils/SignatureValidator.sol";

/// @title L2Deposit Contract
/// @author imToken Labs
contract L2Deposit is IL2Deposit, StrategyBase, ReentrancyGuard, BaseLibEIP712, SignatureValidator {
    using SafeERC20 for IERC20;

    // Bridges
    IArbitrumL1GatewayRouter public immutable arbitrumL1GatewayRouter;
    IOptimismL1StandardBridge public immutable optimismL1StandardBridge;

    constructor(
        address _owner,
        address _userProxy,
        address _weth,
        address _permStorage,
        address _spender,
        IArbitrumL1GatewayRouter _arbitrumL1GatewayRouter,
        IOptimismL1StandardBridge _optimismL1StandardBridge
    ) StrategyBase(_owner, _userProxy, _weth, _permStorage, _spender) {
        arbitrumL1GatewayRouter = _arbitrumL1GatewayRouter;
        optimismL1StandardBridge = _optimismL1StandardBridge;
    }

    /// @inheritdoc IL2Deposit
    function deposit(IL2Deposit.DepositParams calldata _params) external payable override nonReentrant onlyUserProxy {
        require(_params.deposit.expiry > block.timestamp, "L2Deposit: Deposit is expired");

        bytes32 depositHash = getEIP712Hash(L2DepositLibEIP712._getDepositHash(_params.deposit));
        require(isValidSignature(_params.deposit.sender, depositHash, bytes(""), _params.depositSig), "L2Deposit: Invalid deposit signature");

        // PermanentStorage will revert when L2 deposit hash is already seen
        permStorage.setL2DepositSeen(depositHash);

        // Transfer token from sender to this contract
        spender.spendFromUser(_params.deposit.sender, _params.deposit.l1TokenAddr, _params.deposit.amount);

        _deposit(_params.deposit);
    }

    function _deposit(L2DepositLibEIP712.Deposit memory _depositParams) internal {
        bytes memory response;

        if (_depositParams.l2Identifier == L2DepositLibEIP712.L2Identifier.Arbitrum) {
            response = _depositArbitrum(_depositParams);
        } else if (_depositParams.l2Identifier == L2DepositLibEIP712.L2Identifier.Optimism) {
            response = _depositOptimism(_depositParams);
        } else {
            revert("L2Deposit: Unknown L2 identifer");
        }

        emit Deposited(
            _depositParams.l2Identifier,
            _depositParams.l1TokenAddr,
            _depositParams.l2TokenAddr,
            _depositParams.sender,
            _depositParams.recipient,
            _depositParams.amount,
            _depositParams.data,
            response
        );
    }

    function _depositArbitrum(L2DepositLibEIP712.Deposit memory _depositParams) internal returns (bytes memory response) {
        // Ensure L2 token address assigned by sender matches that one recorded on Arbitrum gateway
        address expectedL2TokenAddr = arbitrumL1GatewayRouter.calculateL2TokenAddress(_depositParams.l1TokenAddr);
        require(_depositParams.l2TokenAddr == expectedL2TokenAddr, "L2Deposit: Incorrect L2 token address");

        (address refundAddr, uint256 maxSubmissionCost, uint256 maxGas, uint256 gasPriceBid) = abi.decode(
            _depositParams.data,
            (address, uint256, uint256, uint256)
        );

        // Approve token to underlying token gateway
        address l1TokenGatewayAddr = arbitrumL1GatewayRouter.getGateway(_depositParams.l1TokenAddr);
        IERC20(_depositParams.l1TokenAddr).safeApprove(l1TokenGatewayAddr, _depositParams.amount);

        // Deposit token through gateway router
        response = arbitrumL1GatewayRouter.outboundTransferCustomRefund{ value: msg.value }(
            _depositParams.l1TokenAddr,
            refundAddr,
            _depositParams.recipient,
            _depositParams.amount,
            maxGas,
            gasPriceBid,
            abi.encode(maxSubmissionCost, bytes(""))
        );

        // Clear token approval to underlying token gateway
        IERC20(_depositParams.l1TokenAddr).safeApprove(l1TokenGatewayAddr, 0);

        return response;
    }

    function _depositOptimism(L2DepositLibEIP712.Deposit memory _depositParams) internal returns (bytes memory response) {
        uint32 l2Gas = abi.decode(_depositParams.data, (uint32));

        // Approve token to bridge
        IERC20(_depositParams.l1TokenAddr).safeApprove(address(optimismL1StandardBridge), _depositParams.amount);

        // Deposit token through bridge
        optimismL1StandardBridge.depositERC20To(
            _depositParams.l1TokenAddr,
            _depositParams.l2TokenAddr,
            _depositParams.recipient,
            _depositParams.amount,
            l2Gas,
            bytes("")
        );

        // Clear token approval to underlying token gateway
        IERC20(_depositParams.l1TokenAddr).safeApprove(address(optimismL1StandardBridge), 0);

        return bytes("");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
abstract contract ReentrancyGuard {
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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IArbitrumL1GatewayRouter {
    // DepositInitiated actually is not fired by gateway router, but by underlying token gateway (ERC20, Custom, or others).
    // Put it here since we would only interact with gateway router.
    event DepositInitiated(address l1Token, address indexed from, address indexed to, uint256 indexed sequenceNumber, uint256 amount);

    function outboundTransferCustomRefund(
        address _l1Token,
        address _refundTo,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable returns (bytes memory);

    function getGateway(address _l1TokenAddr) external view returns (address gateway);

    function calculateL2TokenAddress(address _l1TokenAddr) external view returns (address l2TokenAddr);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
pragma abicoder v2;

import "./IStrategyBase.sol";
import "../utils/L2DepositLibEIP712.sol";

interface IL2Deposit is IStrategyBase {
    /// @notice Emitted when deposit tokens to L2 successfully
    /// @param l2Identifier The identifier of which L2 chain the deposit is sent to
    /// @param l1TokenAddr The token contract address on L1
    /// @param l2TokenAddr The token contract address on L2
    /// @param sender The sender's address on L1
    /// @param recipient The recipient's address on L2
    /// @param amount The amount of token to be sent
    /// @param data The specific data related to different L2
    /// @param bridgeResponse The response from L2 bridge
    event Deposited(
        L2DepositLibEIP712.L2Identifier indexed l2Identifier,
        address indexed l1TokenAddr,
        address l2TokenAddr,
        address indexed sender,
        address recipient,
        uint256 amount,
        bytes data,
        bytes bridgeResponse
    );

    struct DepositParams {
        L2DepositLibEIP712.Deposit deposit;
        bytes depositSig;
    }

    /// @notice Deposit user's fund into L2 bridge
    /// @param _params The deposit data that sends token to L2
    function deposit(DepositParams calldata _params) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IOptimismL1StandardBridge {
    event ERC20DepositInitiated(address indexed l1Token, address indexed l2Token, address indexed from, address to, uint256 amount, bytes data);

    /**
     * @dev deposit an amount of ERC20 to a recipient's balance on L2.
     * @param _l1Token Address of the L1 ERC20 we are depositing
     * @param _l2Token Address of the L1 respective L2 ERC20
     * @param _to L2 address to credit the deposit to.
     * @param _amount Amount of the ERC20 to deposit.
     * @param _l2Gas Gas limit required to complete the deposit on L2.
     * @param _data Optional data to forward to L2. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function depositERC20To(
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint32 _l2Gas,
        bytes calldata _data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IPermanentStorage {
    // Operator events
    event TransferOwnership(address newOperator);
    event SetPermission(bytes32 storageId, address role, bool enabled);
    event UpgradeAMMWrapper(address newAMMWrapper);
    event UpgradeRFQ(address newRFQ);
    event UpgradeLimitOrder(address newLimitOrder);
    event UpgradeL2Deposit(address newL2Deposit);
    event UpgradeWETH(address newWETH);
    event SetCurvePoolInfo(address makerAddr, address[] underlyingCoins, address[] coins, bool supportGetD);
    event SetRelayerValid(address relayer, bool valid);

    function hasPermission(bytes32 _storageId, address _role) external view returns (bool);

    function ammWrapperAddr() external view returns (address);

    function rfqAddr() external view returns (address);

    function limitOrderAddr() external view returns (address);

    function l2DepositAddr() external view returns (address);

    function wethAddr() external view returns (address);

    function getCurvePoolInfo(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr
    )
        external
        view
        returns (
            int128 takerAssetIndex,
            int128 makerAssetIndex,
            uint16 swapMethod,
            bool supportGetDx
        );

    function setCurvePoolInfo(
        address _makerAddr,
        address[] calldata _underlyingCoins,
        address[] calldata _coins,
        bool _supportGetDx
    ) external;

    function isAMMTransactionSeen(bytes32 _transactionHash) external view returns (bool);

    function isRFQTransactionSeen(bytes32 _transactionHash) external view returns (bool);

    function isLimitOrderTransactionSeen(bytes32 _transactionHash) external view returns (bool);

    function isLimitOrderAllowFillSeen(bytes32 _allowFillHash) external view returns (bool);

    function isL2DepositSeen(bytes32 _l2DepositHash) external view returns (bool);

    function isRelayerValid(address _relayer) external view returns (bool);

    function setAMMTransactionSeen(bytes32 _transactionHash) external;

    function setRFQTransactionSeen(bytes32 _transactionHash) external;

    function setLimitOrderTransactionSeen(bytes32 _transactionHash) external;

    function setLimitOrderAllowFillSeen(bytes32 _allowFillHash) external;

    function setL2DepositSeen(bytes32 _l2DepositHash) external;

    function setRelayersValid(address[] memory _relayers, bool[] memory _isValids) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface ISpender {
    // System events
    event TimeLockActivated(uint256 activatedTimeStamp);
    // Owner events
    event SetAllowanceTarget(address allowanceTarget);
    event SetNewSpender(address newSpender);
    event SetConsumeGasERC20Token(address token);
    event TearDownAllowanceTarget(uint256 tearDownTimeStamp);
    event BlackListToken(address token, bool isBlacklisted);
    event AuthorizeSpender(address spender, bool isAuthorized);

    function spendFromUser(
        address _user,
        address _tokenAddr,
        uint256 _amount
    ) external;

    function spendFromUserTo(
        address _user,
        address _tokenAddr,
        address _receiverAddr,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./Ownable.sol";
import "./LibConstant.sol";
import "../interfaces/IWeth.sol";
import "../interfaces/IStrategyBase.sol";
import "../interfaces/ISpender.sol";
import "../interfaces/IPermanentStorage.sol";

/// @title StrategyBase Abstract Contract
/// @author imToken Labs
/// @dev This contract is shared by every Tokenlon strategy contracts
abstract contract StrategyBase is IStrategyBase, Ownable {
    using SafeERC20 for IERC20;

    address public immutable userProxy;
    IWETH public immutable weth;
    IPermanentStorage public immutable permStorage;
    ISpender public spender;

    constructor(
        address _owner,
        address _userProxy,
        address _weth,
        address _permStorage,
        address _spender
    ) Ownable(_owner) {
        userProxy = _userProxy;
        weth = IWETH(_weth);
        permStorage = IPermanentStorage(_permStorage);
        spender = ISpender(_spender);
    }

    modifier onlyUserProxy() {
        require(address(userProxy) == msg.sender, "Strategy: not from UserProxy contract");
        _;
    }

    /// @inheritdoc IStrategyBase
    function upgradeSpender(address _newSpender) external override onlyOwner {
        require(_newSpender != address(0), "Strategy: spender can not be zero address");
        spender = ISpender(_newSpender);

        emit UpgradeSpender(_newSpender);
    }

    /// @inheritdoc IStrategyBase
    function setAllowance(address[] calldata _tokenList, address _spender) external override onlyOwner {
        for (uint256 i = 0; i < _tokenList.length; i++) {
            IERC20(_tokenList[i]).safeApprove(_spender, LibConstant.MAX_UINT);

            emit AllowTransfer(_spender, _tokenList[i]);
        }
    }

    /// @inheritdoc IStrategyBase
    function closeAllowance(address[] calldata _tokenList, address _spender) external override onlyOwner {
        for (uint256 i = 0; i < _tokenList.length; i++) {
            IERC20(_tokenList[i]).safeApprove(_spender, 0);

            emit DisallowTransfer(_spender, _tokenList[i]);
        }
    }

    /// @inheritdoc IStrategyBase
    function depositETH() external override onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            weth.deposit{ value: balance }();

            emit DepositETH(balance);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

abstract contract BaseLibEIP712 {
    // EIP-191 Header
    string public constant EIP191_HEADER = "\x19\x01";

    // EIP712Domain
    string public constant EIP712_DOMAIN_NAME = "Tokenlon";
    string public constant EIP712_DOMAIN_VERSION = "v5";

    // EIP712Domain Separator
    bytes32 public immutable EIP712_DOMAIN_SEPARATOR =
        keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(EIP712_DOMAIN_NAME)),
                keccak256(bytes(EIP712_DOMAIN_VERSION)),
                getChainID(),
                address(this)
            )
        );

    /**
     * @dev Return `chainId`
     */
    function getChainID() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    function getEIP712Hash(bytes32 structHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(EIP191_HEADER, EIP712_DOMAIN_SEPARATOR, structHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

/// @title Ownable Contract
/// @author imToken Labs
abstract contract Ownable {
    address public owner;
    address public nominatedOwner;

    event OwnerNominated(address indexed newOwner);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    constructor(address _owner) {
        require(_owner != address(0), "owner should not be 0");
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    /// @notice Activate new ownership
    /// @notice Only nominated owner can call
    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "not nominated");
        emit OwnerChanged(owner, nominatedOwner);

        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    /// @notice Give up the ownership
    /// @notice Only owner can call
    /// @notice Ownership cannot be recovered
    function renounceOwnership() external onlyOwner {
        emit OwnerChanged(owner, address(0));
        owner = address(0);
    }

    /// @notice Nominate new owner
    /// @notice Only owner can call
    /// @param newOwner The address of the new owner
    function nominateNewOwner(address newOwner) external onlyOwner {
        nominatedOwner = newOwner;
        emit OwnerNominated(newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

library L2DepositLibEIP712 {
    enum L2Identifier {
        Arbitrum,
        Optimism
    }

    struct Deposit {
        L2Identifier l2Identifier;
        address l1TokenAddr;
        address l2TokenAddr;
        address sender;
        address recipient;
        uint256 amount;
        uint256 salt;
        uint256 expiry;
        bytes data;
    }
    /*
        keccak256(
            abi.encodePacked(
                "Deposit(",
                "uint8 l2Identifier,",
                "address l1TokenAddr,",
                "address l2TokenAddr,",
                "address sender,",
                "address recipient,",
                "uint256 amount,",
                "uint256 salt,",
                "uint256 expiry,",
                "bytes data",
                ")"
            )
        );
    */
    bytes32 public constant DEPOSIT_TYPEHASH = 0xcb01777a6a26e7a311d06c0d9a55950903d8d51be8a9b7d62cc1b6099cda5a1c;

    function _getDepositHash(Deposit memory _deposit) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    DEPOSIT_TYPEHASH,
                    _deposit.l2Identifier,
                    _deposit.l1TokenAddr,
                    _deposit.l2TokenAddr,
                    _deposit.sender,
                    _deposit.recipient,
                    _deposit.amount,
                    _deposit.salt,
                    _deposit.expiry,
                    keccak256(_deposit.data)
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../interfaces/IERC1271Wallet.sol";
import "./LibBytes.sol";

interface IWallet {
    /// @dev Verifies that a signature is valid.
    /// @param hash Message hash that is signed.
    /// @param signature Proof of signing.
    /// @return isValid Validity of order signature.
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bool isValid);
}

/**
 * @dev Contains logic for signature validation.
 * Signatures from wallet contracts assume ERC-1271 support (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1271.md)
 * Notes: Methods are strongly inspired by contracts in https://github.com/0xProject/0x-monorepo/blob/development/
 */
contract SignatureValidator {
    using LibBytes for bytes;

    /***********************************|
  |             Variables             |
  |__________________________________*/

    // bytes4(keccak256("isValidSignature(bytes,bytes)"))
    bytes4 internal constant ERC1271_MAGICVALUE = 0x20c13b0b;

    // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
    bytes4 internal constant ERC1271_MAGICVALUE_BYTES32 = 0x1626ba7e;

    // Allowed signature types.
    enum SignatureType {
        Illegal, // 0x00, default value
        Invalid, // 0x01
        EIP712, // 0x02
        EthSign, // 0x03
        WalletBytes, // 0x04  standard 1271 wallet type
        WalletBytes32, // 0x05  standard 1271 wallet type
        Wallet, // 0x06  0x wallet type for signature compatibility
        NSignatureTypes // 0x07, number of signature types. Always leave at end.
    }

    /***********************************|
  |        Signature Functions        |
  |__________________________________*/

    /**
     * @dev Verifies that a hash has been signed by the given signer.
     * @param _signerAddress  Address that should have signed the given hash.
     * @param _hash           Hash of the EIP-712 encoded data
     * @param _data           Full EIP-712 data structure that was hashed and signed
     * @param _sig            Proof that the hash has been signed by signer.
     *      For non wallet signatures, _sig is expected to be an array tightly encoded as
     *      (bytes32 r, bytes32 s, uint8 v, uint256 nonce, SignatureType sigType)
     * @return isValid True if the address recovered from the provided signature matches the input signer address.
     */
    function isValidSignature(
        address _signerAddress,
        bytes32 _hash,
        bytes memory _data,
        bytes memory _sig
    ) public view returns (bool isValid) {
        require(_sig.length > 0, "SignatureValidator#isValidSignature: length greater than 0 required");

        require(_signerAddress != address(0x0), "SignatureValidator#isValidSignature: invalid signer");

        // Pop last byte off of signature byte array.
        uint8 signatureTypeRaw = uint8(_sig.popLastByte());

        // Ensure signature is supported
        require(signatureTypeRaw < uint8(SignatureType.NSignatureTypes), "SignatureValidator#isValidSignature: unsupported signature");

        // Extract signature type
        SignatureType signatureType = SignatureType(signatureTypeRaw);

        // Variables are not scoped in Solidity.
        uint8 v;
        bytes32 r;
        bytes32 s;
        address recovered;

        // Always illegal signature.
        // This is always an implicit option since a signer can create a
        // signature array with invalid type or length. We may as well make
        // it an explicit option. This aids testing and analysis. It is
        // also the initialization value for the enum type.
        if (signatureType == SignatureType.Illegal) {
            revert("SignatureValidator#isValidSignature: illegal signature");

            // Signature using EIP712
        } else if (signatureType == SignatureType.EIP712) {
            require(_sig.length == 65 || _sig.length == 97, "SignatureValidator#isValidSignature: length 65 or 97 required");
            r = _sig.readBytes32(0);
            s = _sig.readBytes32(32);
            v = uint8(_sig[64]);
            recovered = ecrecover(_hash, v, r, s);
            isValid = _signerAddress == recovered;
            return isValid;

            // Signed using web3.eth_sign() or Ethers wallet.signMessage()
        } else if (signatureType == SignatureType.EthSign) {
            require(_sig.length == 65 || _sig.length == 97, "SignatureValidator#isValidSignature: length 65 or 97 required");
            r = _sig.readBytes32(0);
            s = _sig.readBytes32(32);
            v = uint8(_sig[64]);
            recovered = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)), v, r, s);
            isValid = _signerAddress == recovered;
            return isValid;

            // Signature verified by wallet contract with data validation.
        } else if (signatureType == SignatureType.WalletBytes) {
            isValid = ERC1271_MAGICVALUE == IERC1271Wallet(_signerAddress).isValidSignature(_data, _sig);
            return isValid;

            // Signature verified by wallet contract without data validation.
        } else if (signatureType == SignatureType.WalletBytes32) {
            isValid = ERC1271_MAGICVALUE_BYTES32 == IERC1271Wallet(_signerAddress).isValidSignature(_hash, _sig);
            return isValid;
        } else if (signatureType == SignatureType.Wallet) {
            isValid = isValidWalletSignature(_hash, _signerAddress, _sig);
            return isValid;
        }

        // Anything else is illegal (We do not return false because
        // the signature may actually be valid, just not in a format
        // that we currently support. In this case returning false
        // may lead the caller to incorrectly believe that the
        // signature was invalid.)
        revert("SignatureValidator#isValidSignature: unsupported signature");
    }

    /// @dev Verifies signature using logic defined by Wallet contract.
    /// @param hash Any 32 byte hash.
    /// @param walletAddress Address that should have signed the given hash
    ///                      and defines its own signature verification method.
    /// @param signature Proof that the hash has been signed by signer.
    /// @return isValid True if signature is valid for given wallet..
    function isValidWalletSignature(
        bytes32 hash,
        address walletAddress,
        bytes memory signature
    ) internal view returns (bool isValid) {
        bytes memory _calldata = abi.encodeWithSelector(IWallet(walletAddress).isValidSignature.selector, hash, signature);
        bytes32 magic_salt = bytes32(bytes4(keccak256("isValidWalletSignature(bytes32,address,bytes)")));
        assembly {
            if iszero(extcodesize(walletAddress)) {
                // Revert with `Error("WALLET_ERROR")`
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000c57414c4c45545f4552524f5200000000000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
            }

            let cdStart := add(_calldata, 32)
            let success := staticcall(
                gas(), // forward all gas
                walletAddress, // address of Wallet contract
                cdStart, // pointer to start of input
                mload(_calldata), // length of input
                cdStart, // write output over input
                32 // output size is 32 bytes
            )

            if iszero(eq(returndatasize(), 32)) {
                // Revert with `Error("WALLET_ERROR")`
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000c57414c4c45545f4552524f5200000000000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
            }

            switch success
            case 0 {
                // Revert with `Error("WALLET_ERROR")`
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000c57414c4c45545f4552524f5200000000000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
            }
            case 1 {
                // Signature is valid if call did not revert and returned true
                isValid := eq(
                    and(mload(cdStart), 0xffffffff00000000000000000000000000000000000000000000000000000000),
                    and(magic_salt, 0xffffffff00000000000000000000000000000000000000000000000000000000)
                )
            }
        }
        return isValid;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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
pragma solidity >=0.7.0;

/// @title IStrategyBase Interface
/// @author imToken Labs
interface IStrategyBase {
    /// @notice Emitted when Tokenlon spender address is updated
    /// @param newSpender The address of the new Tokenlon spender
    event UpgradeSpender(address newSpender);

    /// @notice Emitted when allowing another account to spend assets
    /// @param spender The address that is allowed to transfer tokens
    event AllowTransfer(address indexed spender, address token);

    /// @notice Emitted when disallowing an account to spend assets
    /// @param spender The address that is removed from allow list
    event DisallowTransfer(address indexed spender, address token);

    /// @notice Emitted when ETH converted to WETH
    /// @param amount The amount of converted ETH
    event DepositETH(uint256 amount);

    /// @notice Update the address of Tokenlon spender
    /// @notice Only owner can call
    /// @param _newSpender The address of the new spender
    function upgradeSpender(address _newSpender) external;

    /// @notice Set allowance of tokens to an address
    /// @notice Only owner can call
    /// @param _tokenList The list of tokens
    /// @param _spender The address that will be allowed
    function setAllowance(address[] calldata _tokenList, address _spender) external;

    /// @notice Clear allowance of tokens to an address
    /// @notice Only owner can call
    /// @param _tokenList The list of tokens
    /// @param _spender The address that will be cleared
    function closeAllowance(address[] calldata _tokenList, address _spender) external;

    /// @notice Convert ETH in this contract to WETH
    /// @notice Only owner can call
    function depositETH() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

library LibConstant {
    int256 internal constant MAX_INT = 2**255 - 1;
    uint256 internal constant MAX_UINT = 2**256 - 1;
    uint16 internal constant BPS_MAX = 10000;
    address internal constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant ZERO_ADDRESS = address(0);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IWETH {
    function balanceOf(address account) external view returns (uint256);

    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IERC1271Wallet {
    /**
     * @notice Verifies whether the provided signature is valid with respect to the provided data
     * @dev MUST return the correct magic value if the signature provided is valid for the provided data
     *   > The bytes4 magic value to return when signature is valid is 0x20c13b0b : bytes4(keccak256("isValidSignature(bytes,bytes)")
     *   > This function MAY modify Ethereum's state
     * @param _data       Arbitrary length data signed on the behalf of address(this)
     * @param _signature  Signature byte array associated with _data
     * @return magicValue Magic value 0x20c13b0b if the signature is valid and 0x0 otherwise
     *
     */
    function isValidSignature(bytes calldata _data, bytes calldata _signature) external view returns (bytes4 magicValue);

    /**
     * @notice Verifies whether the provided signature is valid with respect to the provided hash
     * @dev MUST return the correct magic value if the signature provided is valid for the provided hash
     *   > The bytes4 magic value to return when signature is valid is 0x20c13b0b : bytes4(keccak256("isValidSignature(bytes,bytes)")
     *   > This function MAY modify Ethereum's state
     * @param _hash       keccak256 hash that was signed
     * @param _signature  Signature byte array associated with _data
     * @return magicValue Magic value 0x20c13b0b if the signature is valid and 0x0 otherwise
     */
    function isValidSignature(bytes32 _hash, bytes calldata _signature) external view returns (bytes4 magicValue);
}

/*
  Copyright 2018 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  This is a truncated version of the original LibBytes.sol library from ZeroEx.
*/
// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.6;

library LibBytes {
    using LibBytes for bytes;

    /***********************************|
  |        Pop Bytes Functions        |
  |__________________________________*/

    /**
     * @dev Pops the last byte off of a byte array by modifying its length.
     * @param b Byte array that will be modified.
     * @return result The byte that was popped off.
     */
    function popLastByte(bytes memory b) internal pure returns (bytes1 result) {
        require(b.length > 0, "LibBytes#popLastByte: greater than zero length required");

        // Store last byte.
        result = b[b.length - 1];

        assembly {
            // Decrement length of byte array.
            let newLen := sub(mload(b), 1)
            mstore(b, newLen)
        }
        return result;
    }

    /// @dev Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return result address from byte array.
    function readAddress(bytes memory b, uint256 index) internal pure returns (address result) {
        require(
            b.length >= index + 20, // 20 is length of address
            "LibBytes#readAddress greater or equal to 20 length required"
        );

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Read address from array memory
        assembly {
            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 20-byte mask to obtain address
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    /***********************************|
  |        Read Bytes Functions       |
  |__________________________________*/

    /**
     * @dev Reads a bytes32 value from a position in a byte array.
     * @param b Byte array containing a bytes32 value.
     * @param index Index in byte array of bytes32 value.
     * @return result bytes32 value from byte array.
     */
    function readBytes32(bytes memory b, uint256 index) internal pure returns (bytes32 result) {
        require(b.length >= index + 32, "LibBytes#readBytes32 greater or equal to 32 length required");

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, index))
        }
        return result;
    }

    /// @dev Reads an unpadded bytes4 value from a position in a byte array.
    /// @param b Byte array containing a bytes4 value.
    /// @param index Index in byte array of bytes4 value.
    /// @return result bytes4 value from byte array.
    function readBytes4(bytes memory b, uint256 index) internal pure returns (bytes4 result) {
        require(b.length >= index + 4, "LibBytes#readBytes4 greater or equal to 4 length required");

        // Arrays are prefixed by a 32 byte length field
        index += 32;

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, index))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }

    function readBytes2(bytes memory b, uint256 index) internal pure returns (bytes2 result) {
        require(b.length >= index + 2, "LibBytes#readBytes2 greater or equal to 2 length required");

        // Arrays are prefixed by a 32 byte length field
        index += 32;

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, index))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFF000000000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }
}