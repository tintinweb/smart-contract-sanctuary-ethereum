//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../BaseTradeExecutor.sol";
import "./PerpPositionHandler.sol";
import "../../interfaces/IVault.sol";

/// @title PerpTradeExecutor
/// @author 0xAd1
/// @notice A contract to execute manage a Perp Position Handler on Optimism
contract PerpTradeExecutor is BaseTradeExecutor, PerpPositionHandler {
    /// @notice Constructor of the Trade Executor
    /// @param vault Address of the Vault contract
    /// @param _wantTokenL2 address of wantToken equivalent on L2
    /// @param _l2HandlerAddress address of PerpHandler on L2
    /// @param _L1CrossDomainMessenger address of optimism gateway cross domain messenger
    /// @param _socketRegistry address of socketRegistry on L1
    constructor(
        address vault,
        address _wantTokenL2,
        address _l2HandlerAddress,
        address _L1CrossDomainMessenger,
        address _socketRegistry
    ) BaseTradeExecutor(vault) {
        _initHandler(
            vaultWantToken(),
            _wantTokenL2,
            _l2HandlerAddress,
            _L1CrossDomainMessenger,
            _socketRegistry
        );
    }

    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns total wantTokens present in PerpHandler L2 and this Trade Executor
    /// @return posValue total want token amount
    /// @return lastUpdatedBlock block number of last pos update on L1
    function totalFunds()
        public
        view
        override
        returns (uint256 posValue, uint256 lastUpdatedBlock)
    {
        return (
            positionInWantToken.posValue +
                IERC20(vaultWantToken()).balanceOf(address(this)),
            positionInWantToken.lastUpdatedBlock
        );
    }

    /*///////////////////////////////////////////////////////////////
                        STATE MODIFICATION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice L2 position value setter, called by keeper
    /// @param _posValue new position value retrived from L2
    function setPosValue(uint256 _posValue) public keeperOrGovernance {
        PerpPositionHandler._setPosValue(_posValue);
    }

    /// @notice Socket registry setter, called by keeper
    /// @param _socketRegistry address of new socket registry
    function setSocketRegistry(address _socketRegistry) public onlyGovernance {
        socketRegistry = _socketRegistry;
    }

    /// @notice Method to update handler info, called by keeper
    /// @param _wantTokenL2 address of wantToken equivalent on L2
    /// @param _l2HandlerAddress address of PerpHandler on L2
    /// @param _L1CrossDomainMessenger address of optimism gateway cross domain messenger
    /// @param _socketRegistry address of socketRegistry on L1
    function setHandler(
        address _wantTokenL2,
        address _l2HandlerAddress,
        address _L1CrossDomainMessenger,
        address _socketRegistry
    ) public onlyGovernance {
        _initHandler(
            vaultWantToken(),
            _wantTokenL2,
            _l2HandlerAddress,
            _L1CrossDomainMessenger,
            _socketRegistry
        );
    }

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT / WITHDRAW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice To initiate transfer of want tokens to L2
    /// @param _data DepositParams encoded in bytes
    function _initateDeposit(bytes calldata _data) internal override {
        PerpPositionHandler._deposit(_data);
    }

    /// @notice To confirm transfer of want tokens to L2
    /// @dev Handle anything related to deposit confirmation
    function _confirmDeposit() internal override {}

    /// @notice To initiate transfer of want tokens from L2 to this address
    /// @param _data WithdrawParams encoded in bytes
    function _initiateWithdraw(bytes calldata _data) internal override {
        PerpPositionHandler._withdraw(_data);
    }

    /// @notice To confirm transfer of want tokens to L2
    /// @dev Handle anything related to deposit confirmation
    function _confirmWithdraw() internal override {}

    /*///////////////////////////////////////////////////////////////
                        OPEN / CLOSE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice To initiate open position on L2
    /// @param _data OpenPositionParams encoded in bytes
    function openPosition(bytes calldata _data) public onlyKeeper {
        PerpPositionHandler._openPosition(_data);
    }

    /// @notice To initiate close position on L2
    /// @param _data ClosePositionParams encoded in bytes
    function closePosition(bytes calldata _data) public onlyKeeper {
        PerpPositionHandler._closePosition(_data);
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/ITradeExecutor.sol";
import "../interfaces/IVault.sol";

abstract contract BaseTradeExecutor is ITradeExecutor {
    uint256 internal constant MAX_INT = type(uint256).max;

    ActionStatus public override depositStatus;
    ActionStatus public override withdrawalStatus;

    address public override vault;

    constructor(address _vault) {
        vault = _vault;
        IERC20(vaultWantToken()).approve(vault, MAX_INT);
    }

    function vaultWantToken() public view returns (address) {
        return IVault(vault).wantToken();
    }

    function governance() public view returns (address) {
        return IVault(vault).governance();
    }

    function keeper() public view returns (address) {
        return IVault(vault).keeper();
    }

    modifier onlyGovernance() {
        require(msg.sender == governance(), "ONLY_GOV");
        _;
    }

    modifier onlyKeeper() {
        require(msg.sender == keeper(), "ONLY_KEEPER");
        _;
    }

    modifier keeperOrGovernance() {
        require(
            msg.sender == keeper() || msg.sender == governance(),
            "ONLY_KEEPER_OR_GOVERNANCE"
        );
        _;
    }

    function sweep(address _token) public onlyGovernance {
        IERC20(_token).transfer(
            governance(),
            IERC20(_token).balanceOf(address(this))
        );
    }

    function initiateDeposit(bytes calldata _data) public override onlyKeeper {
        require(!depositStatus.inProcess, "DEPOSIT_IN_PROGRESS");
        depositStatus.inProcess = true;
        _initateDeposit(_data);
    }

    function confirmDeposit() public override onlyKeeper {
        require(depositStatus.inProcess, "DEPOSIT_COMPLETED");
        depositStatus.inProcess = false;
        _confirmDeposit();
    }

    function initiateWithdraw(bytes calldata _data) public override onlyKeeper {
        require(!withdrawalStatus.inProcess, "WITHDRAW_IN_PROGRESS");
        withdrawalStatus.inProcess = true;
        _initiateWithdraw(_data);
    }

    function confirmWithdraw() public override onlyKeeper {
        require(withdrawalStatus.inProcess, "WITHDRAW_COMPLETED");
        withdrawalStatus.inProcess = false;
        _confirmWithdraw();
    }

    /// Internal Funcs

    function _initateDeposit(bytes calldata _data) internal virtual;

    function _confirmDeposit() internal virtual;

    function _initiateWithdraw(bytes calldata _data) internal virtual;

    function _confirmWithdraw() internal virtual;
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./OptimismWrapper.sol";
import "./SocketV1Controller.sol";
import "../../interfaces/BasePositionHandler.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../PerpL2/interfaces/IPositionHandler.sol";

/// @title PerpPositionHandlerL1
/// @author 0xAd1
/// @notice Used to control the short position handler deployed on Optimism which interacts with PerpV2
contract PerpPositionHandler is
    BasePositionHandler,
    OptimismWrapper,
    SocketV1Controller
{
    /*///////////////////////////////////////////////////////////////
                          STRUCTS FOR DECODING
  //////////////////////////////////////////////////////////////*/

    /// @notice Params required to open a position
    /// @dev send these params encoded in bytes
    /// @param _amount Amount of quoteTokens to open position
    /// @param _isShort true if short, false if long
    /// @param _slippage slippage in 10^4 BPS
    /// @param _gasLimit gaslimit for relaying txn on optimism
    struct OpenPositionParams {
        uint256 _amount;
        bool _isShort;
        uint24 _slippage;
        uint32 _gasLimit;
    }

    /// @notice Params required to close a position
    /// @dev send these params encoded in bytes
    /// @param _slippage slippage in 10^4 BPS
    /// @param _gasLimit gaslimit for relaying txn on optimism
    struct ClosePositionParams {
        uint24 _slippage;
        uint32 _gasLimit;
    }

    /// @notice Params required to send wantToken to PerpHandler on L2
    /// @dev send these params encoded in bytes. Calldata sent to socketRegistry will be decoded and verified
    /// @param _amount Amount of wantToken to send
    /// @param _allowanceTarget Address to provide allowance to
    /// @param _socketRegistry Socket registry to send txn to
    /// @param _socketData calldata of txn to send
    struct DepositParams {
        uint256 _amount;
        address _allowanceTarget;
        address _socketRegistry;
        bytes _socketData;
    }

    /// @notice Params required to send wantToken from PerpHandler on L2 to this contract
    /// @dev send these params encoded in bytes. Calldata sent to socketRegistry will be decoded and verified
    /// @param _amount Amount of wantToken to send
    /// @param _allowanceTarget Address to provide allowance to
    /// @param _socketRegistry Socket registry to send txn to
    /// @param _socketData calldata of txn to send
    /// @param _gasLimit gaslimit for relaying txn on optimism
    struct WithdrawParams {
        uint256 _amount;
        address _allowanceTarget;
        address _socketRegistry;
        bytes _socketData;
        uint32 _gasLimit;
    }

    /*///////////////////////////////////////////////////////////////
                           STATE VARIABLES
  //////////////////////////////////////////////////////////////*/

    /// @notice returns address of wantToken of vault
    address public wantTokenL1;

    /// @notice returns address of wantToken equivalent on L2
    address public wantTokenL2;

    /// @notice returns address of PerpHandler on L2
    address public positionHandlerL2Address;

    /// @notice returns address of socketRegistry on L1
    address public socketRegistry;

    /// @notice returns details of position on PerpHandler on L2
    Position public override positionInWantToken;

    /// @notice Struct to store deposit related stats
    /// @param lastDeposit amount of want tokens sent to PerpHandler on L2
    /// @param totalDeposit total amount deposited to L2 contract yet
    struct DepositStats {
        uint256 lastDeposit;
        uint256 totalDeposit;
    }

    /// @notice returns deposit stats for position handler on L1
    DepositStats public depositStats;

    /*///////////////////////////////////////////////////////////////
                          INITIALIZING
  //////////////////////////////////////////////////////////////*/

    /// @notice Required to init variables in Trade Executor constructor
    /// @param _wantTokenL1 address of wantToken of vault
    /// @param _wantTokenL2 address of wantToken equivalent on L2
    /// @param _positionHandlerL2Address address of PerpHandler on L2
    /// @param _L1CrossDomainMessenger address of optimism gateway cross domain messenger
    /// @param _socketRegistry address of socketRegistry on L1
    function _initHandler(
        address _wantTokenL1,
        address _wantTokenL2,
        address _positionHandlerL2Address,
        address _L1CrossDomainMessenger,
        address _socketRegistry
    ) internal {
        wantTokenL1 = _wantTokenL1;
        wantTokenL2 = _wantTokenL2;
        positionHandlerL2Address = _positionHandlerL2Address;
        L1CrossDomainMessenger = _L1CrossDomainMessenger;
        socketRegistry = _socketRegistry;
    }

    /*///////////////////////////////////////////////////////////////
                      DEPOSIT / WITHDRAW LOGIC
  //////////////////////////////////////////////////////////////*/

    /// @notice Sends tokens to positionHandlerL2 using Socket
    /// @dev Check `sendTokens` implementation in SocketV1Controller for more info
    /// @param data Encoded DepositParams as data
    function _deposit(bytes calldata data) internal override {
        DepositParams memory depositParams = abi.decode(data, (DepositParams));
        require(
            depositParams._socketRegistry == socketRegistry,
            "INVALID_SOCKET_REGISTRY"
        );
        depositStats.lastDeposit = depositParams._amount;
        depositStats.totalDeposit += depositParams._amount;
        sendTokens(
            wantTokenL1,
            depositParams._allowanceTarget,
            depositParams._socketRegistry,
            positionHandlerL2Address,
            depositParams._amount,
            10,
            depositParams._socketData
        );

        emit Deposit(depositParams._amount);
    }

    /// @notice Sends message to SPHL2 to send tokens back to strategy using Socket
    /// @dev Check `withdraw` implementation in SPHL2 for more info
    /// @param data Encoded WithdrawParams as data
    function _withdraw(bytes calldata data) internal override {
        WithdrawParams memory withdrawParams = abi.decode(
            data,
            (WithdrawParams)
        );
        bytes memory L2calldata = abi.encodeWithSelector(
            IPositionHandler.withdraw.selector,
            withdrawParams._amount,
            withdrawParams._allowanceTarget,
            withdrawParams._socketRegistry,
            withdrawParams._socketData
        );
        sendMessageToL2(
            positionHandlerL2Address,
            L2calldata,
            withdrawParams._gasLimit
        );
        emit Withdraw(withdrawParams._amount);
    }

    /*///////////////////////////////////////////////////////////////
                      OPEN / CLOSE LOGIC
  //////////////////////////////////////////////////////////////*/

    /// @notice Sends message to SPHL2 to open a position on PerpV2
    /// @dev Check `openPosition` implementation in SPHL2 for more info
    /// @param data Encoded OpenPositionParams as data
    function _openPosition(bytes calldata data) internal override {
        OpenPositionParams memory openPositionParams = abi.decode(
            data,
            (OpenPositionParams)
        );
        bytes memory L2calldata = abi.encodeWithSelector(
            IPositionHandler.openPosition.selector,
            openPositionParams._isShort,
            openPositionParams._amount,
            openPositionParams._slippage
        );

        sendMessageToL2(
            positionHandlerL2Address,
            L2calldata,
            openPositionParams._gasLimit
        );
    }

    /// @notice Sends message to SPHL2 to close existing position on PerpV2
    /// @dev Check `closePosition` implementation in SPHL2 for more info
    /// @param data Encoded ClosePositionParams as data
    function _closePosition(bytes calldata data) internal override {
        ClosePositionParams memory closePositionParams = abi.decode(
            data,
            (ClosePositionParams)
        );
        bytes memory L2calldata = abi.encodeWithSelector(
            IPositionHandler.closePosition.selector,
            closePositionParams._slippage
        );
        sendMessageToL2(
            positionHandlerL2Address,
            L2calldata,
            closePositionParams._gasLimit
        );
    }

    /// @dev No rewards to claim on Perp
    function _claimRewards(bytes calldata _data) internal override {
        /// Nothing to claim
    }

    /// @notice L2 position value setter, called by keeper
    /// @param _posValue new position value on L2
    function _setPosValue(uint256 _posValue) internal {
        positionInWantToken.posValue = _posValue;
        positionInWantToken.lastUpdatedBlock = block.number;
    }
}

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IVault {
    function keeper() external view returns (address);

    function governance() external view returns (address);

    function wantToken() external view returns (address);

    function deposit(uint256 amountIn, address receiver)
        external
        returns (uint256 shares);

    function withdraw(uint256 sharesIn, address receiver)
        external
        returns (uint256 amountOut);
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

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

interface ITradeExecutor {
    struct ActionStatus {
        bool inProcess;
        address from;
    }

    function vault() external view returns (address);

    function depositStatus() external returns (bool, address);

    function withdrawalStatus() external returns (bool, address);

    function initiateDeposit(bytes calldata _data) external;

    function confirmDeposit() external;

    function initiateWithdraw(bytes calldata _data) external;

    function confirmWithdraw() external;

    function totalFunds()
        external
        view
        returns (uint256 posValue, uint256 lastUpdatedBlock);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./interfaces/CrossDomainMessenger.interface.sol";

/// @title OptimismWrapper
/// @author 0xAd1
/// @notice Is used to send messages to contracts on Optimism
contract OptimismWrapper {
    /// @notice Address of Optimism L1CrossDomainMessenger
    address public L1CrossDomainMessenger;

    /// @notice Returns the true sender of transaction sent from Optimism L2CrossDomainMessenger
    /// @return address of sender
    function messageSender() internal view returns (address) {
        ICrossDomainMessenger optimismMessenger = ICrossDomainMessenger(
            L1CrossDomainMessenger
        );
        return optimismMessenger.xDomainMessageSender();
    }

    /// @notice Function to send txn to contract on Optimism
    /// @param _target address of recipient contract
    /// @param _message calldata of the txn
    /// @param _gasLimit gasLimit of the txn
    function sendMessageToL2(
        address _target,
        bytes memory _message,
        uint32 _gasLimit
    ) internal {
        ICrossDomainMessenger optimismMessenger = ICrossDomainMessenger(
            L1CrossDomainMessenger
        );
        optimismMessenger.sendMessage(_target, _message, _gasLimit);
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title SocketV1Controller
/// @author 0xAd1
/// @notice Used to bridge ERC20 tokens cross chain
contract SocketV1Controller {
    /// @notice Struct encoded in Bungee calldata
    /// @dev Derived from socket registry contract
    struct MiddlewareRequest {
        uint256 id;
        uint256 optionalNativeAmount;
        address inputToken;
        bytes data;
    }

    /// @notice Struct encoded in Bungee calldata
    /// @dev Derived from socket registry contract
    struct BridgeRequest {
        uint256 id;
        uint256 optionalNativeAmount;
        address inputToken;
        bytes data;
    }

    /// @notice Struct encoded in Bungee calldata
    /// @dev Derived from socket registry contract
    struct UserRequest {
        address receiverAddress;
        uint256 toChainId;
        uint256 amount;
        MiddlewareRequest middlewareRequest;
        BridgeRequest bridgeRequest;
    }

    /// @notice Decode the socket request calldata
    /// @dev Currently not in use due to undertainity in bungee api response
    /// @param _data Bungee txn calldata
    /// @return userRequest parsed calldata
    function decodeSocketRegistryCalldata(bytes memory _data)
        internal
        pure
        returns (UserRequest memory userRequest)
    {
        bytes memory callDataWithoutSelector = slice(
            _data,
            4,
            _data.length - 4
        );
        (userRequest) = abi.decode(callDataWithoutSelector, (UserRequest));
    }

    /// @notice Decodes and verifies socket calldata
    /// @param _data Bungee txn calldata
    /// @param _chainId chainId to check in bungee calldata
    /// @param _inputToken inputWantToken to check in bungee calldata
    /// @param _receiverAddress receiving address to check in bungee calldata
    function verifySocketCalldata(
        bytes memory _data,
        uint256 _chainId,
        address _inputToken,
        address _receiverAddress
    ) internal pure {
        UserRequest memory userRequest;
        (userRequest) = decodeSocketRegistryCalldata(_data);
        if (userRequest.toChainId != _chainId) {
            revert("Invalid chainId");
        }
        if (userRequest.receiverAddress != _receiverAddress) {
            revert("Invalid receiver address");
        }
        if (userRequest.bridgeRequest.inputToken != _inputToken) {
            revert("Invalid input token");
        }
    }

    /// @notice Sends tokens using Bungee middleware. Assumes tokens already present in contract. Manages allowance and transfer.
    /// @dev Currently not verifying the middleware request calldata. Use very carefully
    /// @param token address of IERC20 token to be sent
    /// @param allowanceTarget address to allow tokens to swipe
    /// @param socketRegistry address to send bridge txn to
    /// @param destinationAddress address of receiver
    /// @param amount amount of tokens to bridge
    /// @param destinationChainId chain Id of receiving chain
    /// @param data calldata of txn to be sent
    function sendTokens(
        address token,
        address allowanceTarget,
        address socketRegistry,
        address destinationAddress,
        uint256 amount,
        uint256 destinationChainId,
        bytes memory data
    ) internal {
        verifySocketCalldata(
            data,
            destinationChainId,
            token,
            destinationAddress
        );
        IERC20(token).approve(allowanceTarget, amount);
        (bool success, ) = socketRegistry.call(data);
        require(success, "Failed to call socketRegistry");
    }

    /*
     * @notice Helper to slice memory bytes
     * @author Gonçalo Sá <[email protected]>
     *
     * @dev refer https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
     */
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
}

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

abstract contract BasePositionHandler {
    /// @notice To be emitted when a deposit is made by position handler
    /// @param amount The amount of tokens deposited
    event Deposit(uint256 indexed amount);

    /// @notice To be emitted when a withdraw is made by position handler
    /// @param amount The amount of tokens withdrawn
    event Withdraw(uint256 indexed amount);

    /// @notice To be emitted with rewards are claimed by position handler
    /// @param amount The amount that was withdrawn
    event Claim(uint256 indexed amount);

    /// @notice struct to store data related to position
    /// @param posValue The value of the position in vault wantToken
    /// @param lastUpdatedBlock The block number of last update in position value
    struct Position {
        uint256 posValue;
        uint256 lastUpdatedBlock;
    }

    function positionInWantToken()
        external
        view
        virtual
        returns (uint256, uint256);

    function _openPosition(bytes calldata _data) internal virtual;

    function _closePosition(bytes calldata _data) internal virtual;

    function _deposit(bytes calldata _data) internal virtual;

    function _withdraw(bytes calldata _data) internal virtual;

    function _claimRewards(bytes calldata _data) internal virtual;
}

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6 <0.9.0;

interface IPositionHandler {
    struct PerpPosition {
        uint256 entryMarkPrice;
        uint256 entryIndexPrice;
        uint256 entryAmount;
        bool isShort;
        bool isActive;
    }

    function openPosition(
        bool _isShort,
        uint256 _amount,
        uint24 _slippage
    ) external;

    function closePosition(uint24 _slippage) external;

    function withdraw(
        uint256 amountOut,
        address allowanceTarget,
        address socketRegistry,
        bytes calldata socketData
    ) external;

    function sweep(address _token) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @title ICrossDomainMessenger
 */
interface ICrossDomainMessenger {
    /**********
     * Events *
     **********/

    event SentMessage(bytes message);
    event RelayedMessage(bytes32 msgHash);
    event FailedRelayedMessage(bytes32 msgHash);

    event TransactionEnqueued(
        address indexed _l1TxOrigin,
        address indexed _target,
        uint256 _gasLimit,
        bytes _data,
        uint256 indexed _queueIndex,
        uint256 _timestamp
    );

    event QueueBatchAppended(
        uint256 _startingQueueIndex,
        uint256 _numQueueElements,
        uint256 _totalElements
    );

    event SequencerBatchAppended(
        uint256 _startingQueueIndex,
        uint256 _numQueueElements,
        uint256 _totalElements
    );

    event TransactionBatchAppended(
        uint256 indexed _batchIndex,
        bytes32 _batchRoot,
        uint256 _batchSize,
        uint256 _prevTotalElements,
        bytes _extraData
    );

    /********************
     * View Functions *
     ********************/

    function receivedMessages(bytes32 messageHash) external view returns (bool);

    function sentMessages(bytes32 messageHash) external view returns (bool);

    function targetMessengerAddress() external view returns (address);

    function messageNonce() external view returns (uint256);

    function xDomainMessageSender() external view returns (address);

    /********************
     * Public Functions *
     ********************/

    /**
     * Sets the target messenger address.
     * @param _targetMessengerAddress New messenger address.
     */
    function setTargetMessengerAddress(address _targetMessengerAddress)
        external;

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes memory _message,
        uint32 _gasLimit
    ) external;
}